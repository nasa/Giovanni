#!/usr/bin/perl

# $Id: getDataFieldInfo.pl,v 1.14 2014/11/26 16:11:11 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

use strict;
use XML::LibXML;
use Giovanni::Catalog;
use Giovanni::Util;
use Giovanni::Logger;
use Giovanni::Logger::InputOutput;
use Getopt::Long;
use File::Basename;

# Variables to hold command line arguments
my ( $opt_h, $aesirBaseUrl, $dataFieldInfoFile, $inXmlFile, $verbose )
    = ( '', '', '', '', 0 );
my ( $userName, $userDir );
my @varList = ();

# Get command line options
Getopt::Long::GetOptions(
    'aesir=s'               => \$aesirBaseUrl,
    'in-xml-file=s'         => \$inXmlFile,
    'datafield-info-file=s' => \$dataFieldInfoFile,
    'verbose=i'             => \$verbose,
    'user=s'                => \$userName,
    'user-dir=s'            => \$userDir,
    'h'                     => \$opt_h
);

# If -h is specified, provide synopsis
die "$0\n"
    . " --aesir 'URL for AESIR'\n"
    . " --in-xml-file 'Giovanni input.xml'\n"
    . " --datafield-info-file 'Data field information file'\n"
    . " --verbose 0-1\n"
    if ( $opt_h
    or $aesirBaseUrl      eq ''
    or $dataFieldInfoFile eq ''
    or $inXmlFile         eq '' );

# Create log file in the same directory as the data field information file
my $outDir = dirname($dataFieldInfoFile);
die "Directory, $outDir, doesn't exist" unless ( -d $outDir );
my $loggerName = basename($dataFieldInfoFile);
my $logger     = Giovanni::Logger->new(
    session_dir       => $outDir,
    manifest_filename => $loggerName
);
die "Failed to create logger" unless defined $logger;
my $provInput = Giovanni::Logger::InputOutput->new(
    'name' => 'Catalog',
    value  => $aesirBaseUrl,
    type   => 'URL'
);

$logger->info("Using $aesirBaseUrl as the data catalog") if $verbose;

unless ( $aesirBaseUrl =~ /\S+/ ) {
    my $msg = "Specify AESIR base URL";
    $logger->error($msg);
    $logger->perecent_done(100);
    exit(1);
}
unless ( $dataFieldInfoFile =~ /\S+/ ) {
    my $msg = "Specify data field info file";
    $logger->error($msg);
    $logger->perecent_done(100);
    exit(1);
}
if ( -f $inXmlFile ) {

    # Extract data field names
    my $inDoc = Giovanni::Util::parseXMLDocument($inXmlFile);
    if ( defined $inDoc ) {
        foreach my $varNode ( $inDoc->findnodes('//data') ) {
            my $varName = $varNode->textContent();
            $varName =~ s/^\s+|\s+$//g;
            push( @varList, $varName ) if ( $varName =~ /\S+/ );
        }
    }
}
else {
    $logger->error("File containing data fields, $inXmlFile, not found");
    exit(1);
}
unless (@varList) {
    $logger->error("Failed to find any data fields");
    exit(1);
}

# Create a DOM for output
my $xmlParser = XML::LibXML->new();
my $outDom    = $xmlParser->parse_string('<varList />');
my $outDoc    = $outDom->documentElement();
$logger->user_msg( "Locating "
        . ( @varList == 1 ? $varList[0] : "requested variables" )
        . " in our data catalog" )
    if defined $logger;
my $catalog = Giovanni::Catalog->new( { URL => $aesirBaseUrl } );

# Look for user supplied data first
my $userVar = {};
if ( defined $userDir and defined $userName ) {
    $userVar = findUserData(
        USER_DIR   => $userDir,
        USER       => $userName,
        DATA_FIELD => \@varList
    );
}

# Find variables not found in user supplied data
my @nonUserVarList = map { $_ unless exists $userVar->{$_} } @varList;

# Query to get variable metdata
my $var = {};
if (@nonUserVarList) {
    $var = $catalog->getDataFieldInfo( { FIELDS => \@nonUserVarList } );
}

# Merge user supplied variable and AESIR variables
foreach my $key ( keys %$userVar ) {
    $var->{$key} = $userVar->{$key};
}

my @foundVarList = defined $var ? keys(%$var) : ();
$logger->info(
    @foundVarList
    ? "Found " . join( ",", @foundVarList ) . " in catalog"
    : "Didn't find any variable"
) if $verbose;
if ( @varList == 1 ) {
    $logger->user_msg( ( @foundVarList ? "Found " : "Could not find " )
        . "$foundVarList[0] in our data catalog" );
}
else {
    my $msg
        = "Found "
        . @foundVarList
        . " variable"
        . ( @foundVarList > 1 ? "s" : "" );
    $logger->user_msg($msg);
}

# Case of no variable info not found
exit(2) unless @foundVarList;

foreach my $key (@varList) {
    next unless defined $var->{$key};
    my $elem = XML::LibXML::Element->new('var');
    $elem->setAttribute( 'id', $key );
    foreach my $attr ( keys %{ $var->{$key} } ) {
        if ( $attr eq 'sld' ) {
            eval {

                # Create a DOM parser for XML
                my $xmlParser = XML::LibXML->new();
                my $inDom = $xmlParser->parse_string( $var->{$key}{$attr} );
                my $inDoc = $inDom->documentElement();

                # append the XML to this element
                $elem->appendChild($inDoc);
            } or do {

                # this isn't XML, so just put in the single SLD
                my $slds = XML::LibXML::Element->new('slds');
                $elem->appendChild($slds);
                my $sld = XML::LibXML::Element->new('sld');
                $sld->setAttribute( 'url',   $var->{$key}{$attr} );
                $sld->setAttribute( 'label', "Default" );
                $slds->appendChild($sld);
            };
        }
        else {
            $elem->setAttribute( $attr, $var->{$key}{$attr} );
        }
    }
    $outDoc->appendChild($elem);
}
if ( open( FH, ">$dataFieldInfoFile" ) ) {
    print FH $outDoc->toString(1);
    close(FH);
    $logger->user_msg("Completed generation of data field information");
    my $provOutput = Giovanni::Logger::InputOutput->new(
        name  => 'Metadata from data catalog',
        value => $dataFieldInfoFile,
        type  => 'FILE'
    );
    $logger->write_lineage(
        name    => 'Data Catalog Query',
        inputs  => [$provInput],
        outputs => [$provOutput]
    );
}
else {
    $logger->error("Failed to generate data field information");
    exit(1);
}

# Finds user data: DATA_FIELD=>[array of data field ids], USER_DIR => user dir, USER=>user name
sub findUserData {
    my (%input) = @_;

    my $var = {};
    foreach my $dataField ( @{ $input{DATA_FIELD} } ) {
        my $file
            = "$input{USER_DIR}/$input{USER}/data/$dataField/$dataField.xml";
        my $doc = Giovanni::Util::parseXMLDocument($file);
        next unless defined $doc;
        foreach my $varNode ( $doc->findnodes('/varList/var') ) {
            my $key = $varNode->getAttribute('id');
            foreach my $attr ( $varNode->attributes() ) {
                my $name = $attr->getName();
                $var->{$key}{$name} = $attr->getValue();
            }
        }
    }
    return $var;
}

__END__

=head1 NAME

getDataFieldInfo.pl - Script to get Giovanni data field information from AESIR catalog

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

getDataFieldInfo.pl
[B<--in-xml-file> Giovanni data field manifest file]
[B<--aesir> AESIR catalog base URL]
[B<--datafield-info-file> data field information file]
[B<--verbose> verbose flag (0 or 1)]
[B<-h>] 

=head1 DESCRIPTION

Given manifest file and the AESIR location (root URL), produces manifest file with data field attributes from AESIR catalog for use with make based workflows.

=head1 OPTIONS

=over 4

=item B<h>

Prints command synposis

=item B<in-xml-file>

Giovanni input.xml file

=item B<aesir>

Base URL for AESIR

=item B<datafield-info-file>

Name of the file to hold data field information.

=item B<verbose>

Verbose flag to indicate the level of logging detail. Valids are 0 or 1. 0 indicates turns of detailed logging.

=back

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

None

=head1 EXAMPLES

perl getDataFieldInfo.pl --aesir  "http://s4ptu-ts2.ecs.nasa.gov/solr/" --in-xml-file "input.xml" --datafield-info-file "mfst.info.xml"

=head1 AUTHOR

M. Hegde (Mahabaleshwa.S.Hegde@nasa.gov)

=head1 SEE ALSO

=cut

