#!/usr/bin/perl

#$Id: plotHintsWrapper.pl,v 1.8 2014/01/16 18:51:06 csmit Exp $
#-@@@ GIOVANNI,Version $Name:  $

=head1 Name 

addPlotHits.pl

=head1 DESCRIPTION

plotHintsWrapper.pl is a wrapper calling Giovanni::Visualizer::Hints.

Arguments:

mfst - path to input manifest file

varinfo - path to data info file

service - type of service  (see Hints.pm for list of services)

bbox - bounding box

stime - user start time

etime - user end time

outfile - full path of output file

group-type (optional) - grouping type. E.g. SEASON

group-value (optional) - grouping value. E.g. JJA


=head1 MODULE REQUIRED

Giovanni::Visualizer::Hints

=head1 SYNOPSIS

#>perl plotHintsWrapper.pl --mfst path_to_manifest.xml 
--varinfo path_to_varinfo_xml_file --service service_name 
--bbox -180,-90,180,90 --stime start_datetime --etime end_datetime 
--outfile outputfile

=head1 AUTHOR

Xiaopeng Hu <Xiaopeng.Hu@nasa.gov>

Date Created: 2012-04-05

=cut

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use XML::LibXML;
use Date::Parse;
use Data::Dumper;
use DateTime;
use Time::HiRes qw (sleep);
use File::Temp qw/ tempfile tempdir /;
use Date::Manip;
use POSIX;
use Giovanni::Visualizer::Hints;
use Giovanni::Logger;

my $verbose = 0;
my ($ncfile,  $manifestfile, $varinfo,   $outfile,
    $service, $dataField,    $starttime, $endtime,
    $bbox,    $groupType,    $groupValue
);
if ( @ARGV < 2 ) {
    usage();
    exit(1);
}
GetOptions(
    'mfst=s'        => \$manifestfile,
    'varinfo=s'     => \$varinfo,
    'stime=s'       => \$starttime,
    'etime=s'       => \$endtime,
    'service=s'     => \$service,
    'outfile=s'     => \$outfile,
    'bbox=s'        => \$bbox,
    'group-type=s'  => \$groupType,
    'group-value=s' => \$groupValue,
);
if ( !defined $manifestfile ) {
    print STDERR "USER_ERROR the input manifest file not defined\n";
    print STDERR "ERROR the input manifest file is required\n";
    exit(1);
}
if ( !-e $manifestfile ) {
    print STDERR "USER_ERROR the input manifest file not exist\n";
    print STDERR "ERROR the input manifest file is required\n";
    exit(1);
}
if ( !defined $varinfo ) {
    print STDERR "USER_ERROR the input catalog file not defined\n";
    print STDERR "ERROR the input varInfo.xml file is required\n";
    exit(1);
}
my @varInfoFiles = split( ",", $varinfo );
for my $varInfoFile (@varInfoFiles) {
    if ( !-e $varInfoFile ) {
        print STDERR "USER_ERROR the input catalog manifest file not exist\n";
        print STDERR "ERROR the input catalog manifest file is required\n";
        exit(1);
    }
}
if ( !defined $outfile ) {
    print STDERR "USER_ERROR outfile not defined\n";
    exit(1);
}

## to validate inputs
if ( !( defined $service ) || $service !~ /[\-\w]+/ ) {
    print STDERR "USER_ERROR invalid service\n";
    print STDERR
        "ERROR the service name is either not defined or unsafe: $service\n";
    exit(1);
}

if ( !defined $starttime ) {
    print STDERR "USER_ERROR start timestamp is required\n";
    print STDERR "ERROR missing the datetime at the Plot Hints step\n";
    exit(1);
}
if ( !defined $endtime ) {
    print STDERR "USER_ERROR end timestamp is required\n";
    print STDERR "ERROR missing the endtime at the Plot Hints step\n";
    exit(1);
}

## to parse the bbox
my $bboxString = "";
if ( $bbox ) {
    my @latlon = split( /\,/, $bbox );
    my $ll = @latlon;
    if ( $ll != 4 ) {
        print STDERR "USER_ERROR invalid bounding box(PH)\n";
        print STDERR
            "ERROR the bbox values are not correct at Plot Hints step\n";
        exit(1);
    }
    my $index = 0;
    foreach my $llval (@latlon) {
        if ( $index == 0 || $index == 2 ) {
            $llval = ( $llval > 0 ) ? $llval . "E" : $llval . "W";
        }
        else {
            $llval = ( $llval > 0 ) ? $llval . "N" : $llval . "S";
        }
        $bboxString .= ( $bboxString eq "" ) ? $llval : "_$llval";
        $bboxString =~ s/\-//g;    ## to remove all '-' sign
        $index++;
    }
}

## to figure out the session directory
my $outdir      = dirname($manifestfile);
my $logfilename = basename($outfile);
my $logger      = Giovanni::Logger->new(
    session_dir       => $outdir,
    manifest_filename => $logfilename
);
$logger->info("Plot Hints input file: $manifestfile");

# figure out which ids we have in variable information files
my @dataIds = ();
for my $varInfoFile (@varInfoFiles) {

    # Create an XPath dom
    my $varInfoparser = XML::LibXML->new();
    my $varinfodom    = $varInfoparser->parse_file($varInfoFile);
    my $varinfoDom    = XML::LibXML::XPathContext->new($varinfodom);
    my @varNodes      = $varinfoDom->findnodes("//var");
    foreach my $var (@varNodes) {
        $dataField = $var->getAttribute("id");
        $logger->info("Plot Hints found data id: $dataField");
    }
    push( @dataIds, $dataField );
}

# to create an XPath dom
my $parser    = XML::LibXML->new();
my $dom       = $parser->parse_file($manifestfile);
my $xpDom     = XML::LibXML::XPathContext->new($dom);
my @fileNodes = $xpDom->findnodes("//file");

if ( scalar(@fileNodes) < 1 ) {
    $logger->error("Invalid manifest file for Plot Hints");
    exit(1);
}

my $listfile = "";
my $id       = "";
my @outfiles = ();

#### to get the input file list in flat file ready
my $numFiles = scalar(@fileNodes);
for ( my $i = 0; $i < $numFiles; $i++ ) {
    my $fileNode = $fileNodes[$i];

    # get the text node under 'file'
    $ncfile = $fileNode->getFirstChild()->getValue();
    $logger->info("Adding plot hints to file: $ncfile\n");
    eval {

        # to add the hints to the specified file
        my $plothint = new Giovanni::Visualizer::Hints(
            file          => $ncfile,
            service       => $service,
            varId         => \@dataIds,
            varInfoFile   => \@varInfoFiles,
            userStartTime => $starttime,
            userEndTime   => $endtime,
            bbox          => $bbox,
            groupType     => $groupType,
            groupValue    => $groupValue,
        );
        $plothint->addHints();
        push( @outfiles, $ncfile );
    };
    if ($@) {
        $logger->debug("ERROR occurred because $@ -- $!");
        $logger->error("Failed to add plot hints");
        exit(1);
    }

    $logger->user_msg( "Finished adding plot hints to file "
            . ( $i + 1 )
            . " of $numFiles." );
    $logger->percent_done( ( $i + 1 ) * 100.0 / $numFiles );
}

my $xmlDoc   = XML::LibXML::Document->new( '1.0', 'UTF-8' );
my $root     = $xmlDoc->createElement("manifest");
my $fileList = $xmlDoc->createElement("fileList");
$root->addChild($fileList);

foreach my $file (@outfiles) {
    my $fileNode = $xmlDoc->createElement("file");
    $fileNode->appendText($file);
    $fileList->appendChild($fileNode);
}
$xmlDoc->setDocumentElement($root);

## to create a new manifest file
eval {
    open MNFH, ">", "$outfile";
    print MNFH $xmlDoc->toString(2);
    close(MNFH);
};
if ($@) {
    $logger->error(
        "Failure occurred when creating the plot hints manifest file");
    exit(1);
}

if ( -e $outfile ) {
    $logger->info("Successfully created the plot hints manifest file");
}
else {
    $logger->error("Failed to create the plot hints manifest file");
}

