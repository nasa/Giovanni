#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

#$Id: giovanni_area_averager.pl,v 1.15 2013/09/03 14:49:37 hxiaopen Exp $
#-@@@ GIOVANNI,Version $Name:  $

=head1 Name 

giovanni_area_averager.pl

=head1 DESCRIPTION

giovanni_area_averager.pl is a wrapper calling Giovanni::ScienceCommand.   It can take 3 arguments:

1. input -- required.   a stage data manifest file

2. bbox  -- required.   a bounding box in the order of west, south, east, north

3. debug -- optional.   for debugging purpose.  no debug msg output to screen if 0; print debug msg to screen if 1

=head1 SYNOPSIS

scienceCommandWrapper.pl --inputfilelist [stage.xml] --bbox [bounding_box_values] --debug [0|1] --zfile <z-file.xml> --datafield-info-file <varInfo.xml> --outfile <output-mfst-file>

Sample stage_data_file.xml looks like below:

<fileList id="MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean">

  <file>/var/temp/scrubbed.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101.nc</file>
  
  <file>/var/temp/scrubbed.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030102.nc</file>

</fileList>

=head1 AUTHOR

Xiaopeng Hu <Xiaopeng.Hu@nasa.gov>

Date Created: 2013-05-013

=cut

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use XML::LibXML;
use Giovanni::ScienceCommand;
use Giovanni::Util;
use Giovanni::Logger;

my $stepname = "Area averaging";

my ( $stagefile, $outdir, $bbox, $debug, $outfile, $varinfo_file, $starttime,
    $endtime );
my $zfile = undef;

GetOptions(
    'inputfilelist=s'       => \$stagefile,
    'bbox=s'                => \$bbox,
    'outfile=s'             => \$outfile,
    'zfile=s'               => \$zfile,
    'datafield-info-file=s' => \$varinfo_file,
    's=s'                   => \$starttime,
    'e=s'                   => \$endtime,
    'debug=i'               => \$debug
);

## to validate the input file is defined and exist
die "ERROR Required stage file missing or empty: $stagefile\n"
    unless $stagefile and -s $stagefile;
die "ERROR Required bbox missing\n" unless $bbox;
die "ERROR Required z-file missing or empty: $zfile\n"
    unless $zfile and -s $zfile;
die "ERROR Required datafield-info-file missing or empty\n"
    unless $varinfo_file and -s $varinfo_file;
die "ERROR Required start time\n" unless ( defined $starttime );
die "ERROR Required end time\n"   unless ( defined $endtime );

my @latlon = split( /\,/, $bbox );
my $ll = @latlon;
if ( $ll != 4 ) {
    print STDERR "USER_ERROR invalid bounding box(PH)\n";
    print STDERR "ERROR the bbox values are not correct at Plot Hints step\n";
    exit(1);
}
my $index      = 0;
my $bboxString = "";
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
print STDERR "INFO: bbox = $bboxString\n" if ($debug);

$outdir = dirname($outfile);
my $logger = Giovanni::Logger->new(
    session_dir       => $outdir,
    manifest_filename => $outfile
);
$logger->info("StageFile: $stagefile");

my @fparts = split( /\./, $stagefile );
my $timeString = "";
foreach my $part (@fparts) {
    if ( $part =~ /^t\d{4}/ ) {
        $timeString = $part;
    }
}
print STDERR "INFO: time string = $timeString\n" if ($debug);

#
# Parse stage file
#

my ( $vname, $files ) = parse_stage_file($stagefile);

## to crop the date time range
my ($timedfiles)
    = Giovanni::Util::cropRecordsByTime( $files, $starttime, $endtime );

#
# Construct an input list file for area averager algorithm
# The list file contains list of data files to be processed by the algorithm
#

my $listfile = create_text_listfile($timedfiles);
die "ERROR Fail to create list file $listfile\n" unless -s $listfile;

#
# Parse varinfo file
# varinfo : { vname => {'resolution', 'zname', 'zunits'} }
#

my $varinfo = {};
$varinfo = parse_varinfo( $varinfo_file, $varinfo );
die "ERROR var info missing for $vname\n" unless exists( $varinfo->{$vname} );

#
# Extract z-selection
#

# Extract from zfile for {'vname' => {'zvalue' => <zvalue>}}
my $zselection = {};
$zselection = parse_zfile($zfile) if defined($zfile);

#
# Call ScienceCommand.pm
#

# --- Construct z-option ---
# LIMITATION: We only consider a single variable here
my @vnames_with_z = keys(%$zselection);
print STDERR "WARN Too many variables found @vnames_with_z\n"
    if scalar(@vnames_with_z) > 1;

# Make z-option for science command
my $zoption = "";
if (@vnames_with_z) {
    my $vname  = $vnames_with_z[0];
    my $zvalue = $zselection->{$vname}->{'zvalue'};
    my $zname  = $varinfo->{$vname}->{'zname'};
    my $zunits = $varinfo->{$vname}->{'zunits'};
    $zoption = "-z $zname=${zvalue}${zunits}";
}

# Call science command
if ( $listfile ne "" && -e $listfile ) {
    my $scienceAlgorithm
        = "areaAveragerNco.pl -i $listfile -o $outdir -b $bbox $zoption";
    print STDERR "INFO science algorithm: $scienceAlgorithm \n " if ($debug);
    $logger->info("ScienceAlgorithm: $scienceAlgorithm");
    my $scienceCommand = Giovanni::ScienceCommand->new(
        sessionDir => $outdir,
        logger     => $logger
    );
    my ( $outputs, $messages ) = $scienceCommand->exec($scienceAlgorithm);
    $logger->error("No output file found") unless scalar(@$outputs) > 0;
    my $file = $outputs->[0];
    $logger->info("Averaged file: $file");

    my $rc = create_outfile( $vname, $outfile, $outputs );
    $logger->info("Created the area averager manifest file: $outfile");

    # Create lineage
    my ( $inputsObj, $outputsObj )
        = create_inputs_outputs( $files, $outputs );
    $logger->write_lineage(
        name     => $stepname,
        inputs   => $inputsObj,
        outputs  => $outputsObj,
        messages => $messages
    );

}
else {
    print STDERR "ERROR failed to find the output from area averager\n";
    exit(1);
}

exit(0);

sub create_inputs_outputs {
    my ( $files, $outfiles ) = @_;

    # Create input file objects (one for each file)
    my $inputs = [];
    foreach my $f (@$files) {
        my $in = Giovanni::Logger::InputOutput->new(
            name  => "file",
            value => $f,
            type  => "FILE"
        );
        push( @$inputs, $in );
    }

    # Create output file objects (one for each file)
    my $outputs = [];
    foreach my $f (@$outfiles) {
        my $out = Giovanni::Logger::InputOutput->new(
            name  => "file",
            value => $f,
            type  => "FILE"
        );
        push( @$outputs, $out );
    }

    return ( $inputs, $outputs );
}

sub create_outfile {
    my ( $vname, $outfile, $files ) = @_;
    my $file_string = "";
    foreach my $f (@$files) {
        $file_string .= "    <file>$f</file>\n";
    }
    open( OUT, ">$outfile" ) || die;
    print OUT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print OUT "<manifest>\n";
    print OUT "  <fileList id=\"$vname\">\n";
    print OUT $file_string;
    print OUT "  </fileList>\n</manifest>";
    close(OUT);
}

sub parse_varinfo {
    my ( $varinfo_file, $varinfo ) = @_;

    my $parser    = XML::LibXML->new();
    my $xml       = $parser->parse_file($varinfo_file);
    my @var_nodes = $xml->findnodes('/varList/var');
    foreach my $n (@var_nodes) {
        my $id         = $n->getAttribute('id');
        my $zname      = $n->getAttribute('zDimName');
        my $zunits     = $n->getAttribute('zDimUnits');
        my $resolution = $n->getAttribute('resolution');
        if ( !$id ) {
            print STDERR "WARN The id for variable is missing\n";
            next;
        }
        $varinfo->{$id} = { 'resolution' => $resolution };
        next unless $zname;
        $varinfo->{$id}->{'zname'} = $zname;
        $varinfo->{$id}->{'zunits'} = $zunits if $zunits;
    }

    return $varinfo;
}

sub parse_zfile {
    my ($zfile) = @_;

    # Make sure zfile is not empty
    if ( !-s $zfile ) {
        print STDERR "WARN z-file $zfile empty\n";
        return {};
    }

    # Parse zfile
    my $parser     = XML::LibXML->new();
    my $xml        = $parser->parse_file($zfile);
    my @data_nodes = $xml->findnodes('/manifest/data');

    my $zselection = {};
    foreach my $n (@data_nodes) {
        my $zvalue = $n->getAttribute('zValue');
        my $vname  = $n->textContent();
        $vname =~ s/^\s+|\s+$//mg;
        $zselection->{$vname} = { 'zvalue' => $zvalue }
            if $zvalue and $zvalue !~ /NA/i;
    }

    return $zselection;
}

sub parse_zfile_old {
    my ($zfile) = @_;

    # Make sure zfile is not empty
    if ( !-s $zfile ) {
        print STDERR "WARN z-file $zfile empty\n";
        return {};
    }

    # Parse zfile
    my $zstring = `cat $zfile`;
    $zstring =~ s/\s//g;
    my ( $zvalue, $vname )
        = ( $zstring =~ /<zval>(\d+)<\/zval><data>(.+)<\/data>/sm );
    if ( !$zvalue or !$vname ) {
        die "ERROR Fail to parse zfile $zfile\n";
    }

    return { $vname => { 'zvalue' => $zvalue } };
}

# parse_stage_file()
sub parse_stage_file {
    my ($stagefile) = @_;

    my @files = ();

    my $parser          = XML::LibXML->new();
    my $xml             = $parser->parse_file($stagefile);
    my ($fileList_node) = $xml->findnodes('/manifest/fileList');
    if ( !$fileList_node ) {
        print "WARN fileList node not found in $stagefile\n";
        return ();
    }

    my $vname = $fileList_node->getAttribute('id');
    if ( !$vname ) {
        print "WARN fileList doesn't contain an id $stagefile\n";
        return ();
    }

    my @file_nodes = $fileList_node->findnodes('file');
    foreach my $fn (@file_nodes) {
        my $fpath = $fn->textContent();
        $fpath =~ s/^\s+|\s+$//g;
        push( @files, $fpath ) if $fpath ne "";
    }

    return ( $vname, \@files );
}

sub create_text_listfile {
    my ($files) = @_;
    my $listfile_content = "";
    foreach my $f (@$files) {
        $listfile_content .= "$f\n";
    }

    my $listfile = "in_time_averager.$$.txt";
    open( FH, ">$listfile" ) || die;
    print FH "$listfile_content";
    close(FH);

    return $listfile;
}

