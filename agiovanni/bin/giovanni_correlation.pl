#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

=head1 NAME

giovanni_correlation.pl - A workflow wrapper for running the correlation algorithm wrapper script

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

giovanni_correlation.pl
B<--inputfilelist> I<stage.xml>
B<--bbox> I<bbox>
B<--zfile> I<z-file1.xml,z-file2.xml>
B<--datafield-info-file> I<varInfo1.xml,varInfo2.xml>
B<--outfile> I<output-mfst-file>
[B<-M> I<min-sample-size>]
B<-s> I<begintime>
B<-e> I<endtime>
[B<--debug> 0|1]

Sample stage.xml:
  <manifest>
  <fileList id="MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean">
    <file>/var/temp/scrubbed.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101.nc</file>
    <file>/var/temp/scrubbed.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030102.nc</file>
  </fileList>
  <fileList id="MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean">
    <file>/var/temp/scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101.nc</file>
    <file>/var/temp/scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030102.nc</file>
  </fileList>
  </manifest>

=head1 DESCRIPTION

A workflow wrapper for running the correlation algorithm wrapper script.

=head1 OPTIONS

=over 4

=item B<--inputfilelist>

Xml file containing a list of input file pathnames for each of the two variables to be correlated. The lists should be of equal size.

=item B<--bbox>

Spatial bounding box (comma separated list of west,south,east,north coordinates in degrees)

=item B<--zfile>

Comma-separated list of names of xml files containing the z-dimension value and units for each of the two variables being correlated

=item B<--datafield-info-file>

Comma-separated list of names of xml files containing the data catalog information for each of the two variables being correlated

=item B<--outfile>

Xml file containing a list of the file pathname for the output correlation file

=item B<-M>

Minimum sample size required for computing the correlation

=item B<-s>

Start date time in ISO8601 format

=item B<-e>

End date time in ISO8601 format

=item B<--debug>

Set to 1 to include debugging information

=back

=head1 AUTHOR

Jianfu Pan

Date Created: 2013-07-10

=cut

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use XML::LibXML;
use Giovanni::ScienceCommand;
use Giovanni::Logger;
use Giovanni::Data::NcFile;

my $stepname = "Correlation";

#
# Command line options
#

my ( $stagefile, $bbox, $outfile, $varinfo_file, $begintime, $endtime );
my $debug           = 0;
my $zfile           = undef;
my $min_sample_size = undef;

GetOptions(
    'inputfilelist=s'       => \$stagefile,
    'bbox=s'                => \$bbox,
    'outfile=s'             => \$outfile,
    'zfile=s'               => \$zfile,
    'datafield-info-file=s' => \$varinfo_file,
    'M=s'                   => \$min_sample_size,
    's=s'                   => \$begintime,
    'e=s'                   => \$endtime,
    'debug=i'               => \$debug
);

# Check for required options
die "ERROR Required outfile missing\n" unless $outfile;

# Looking for two varinfo files
$varinfo_file =~ s/\s//g;
my ( $varinfo_file1, $varinfo_file2 ) = split( ',', $varinfo_file, 2 );
die "ERROR Needs two varinfo files got $varinfo_file\n"
    unless -s $varinfo_file1 and -s $varinfo_file2;

# Looking for two z files
# ASSUMING z files always used even for 2D
$zfile =~ s/\s//g;
my ( $zfile1, $zfile2 ) = split( ',', $zfile, 2 );
die "ERROR Needs two stage files got $zfile\n"
    unless -s $zfile1 and -s $zfile2;

# Derived parts from $outfile name
my $outdir = dirname($outfile);
my $logger = Giovanni::Logger->new(
    session_dir       => $outdir,
    manifest_filename => $outfile
);
$logger->info("StageFile: $stagefile");
$logger->info("VarinfoFile: $varinfo_file");

#
# Parse stage file
#

my ( $vname1, $files1, $vname2, $files2 ) = parse_stage_file($stagefile);

# get lat/lon resolution
my ( $latres, $lonres )
    = Giovanni::Data::NcFile::spatial_resolution( $files1->[0], "lat",
    "lon" );
if ( !( defined($latres) ) || !( defined($lonres) ) ) {
    die "Unable to get latitude and longitude resolution from $files1->[0]";
}

#
# Parse varinfo file
# varinfo : { vname => {'resolution', 'zname', 'zunits'} }
#

my $varinfo = {};
$varinfo = parse_varinfo( $varinfo_file1, $varinfo );
$varinfo = parse_varinfo( $varinfo_file2, $varinfo );
die "ERROR var info missing for $vname1\n"
    unless exists( $varinfo->{$vname1} );
die "ERROR var info missing for $vname2\n"
    unless exists( $varinfo->{$vname2} );

#
# Extract z-selection
#

# Extract from zfile for {'vname' => {'zvalue' => <zvalue>}}
my $zselection = {};
$zselection = parse_zfile( $zfile1, $zselection ) if defined($zfile1);
$zselection = parse_zfile( $zfile2, $zselection ) if defined($zfile2);

#
# Construct an input list file for regrid algorithm
# The list file contains list of data files to be processed by the algorithm
#

my $listfile = create_listfile( $vname1, $files1, $vname2, $files2, $varinfo,
    $zselection );
die "ERROR Fail to create list file $listfile\n" unless -s $listfile;

#
# Call ScienceCommand.pm
#

# --- Construct z-option ---
my $zoption = "";
if ( exists( $zselection->{$vname1} ) ) {
    my $zname1  = $varinfo->{$vname1}->{'zname'};
    my $zunits1 = $varinfo->{$vname1}->{'zunits'};
    my $zvalue1 = $zselection->{$vname1}->{'zvalue'};
    $zoption .= "-x $vname1,$zname1=$zvalue1$zunits1 ";
}
else {
    $zoption .= "-x $vname1";
}
if ( exists( $zselection->{$vname2} ) ) {
    my $zname2  = $varinfo->{$vname2}->{'zname'};
    my $zunits2 = $varinfo->{$vname2}->{'zunits'};
    my $zvalue2 = $zselection->{$vname2}->{'zvalue'};
    $zoption .= " -y $vname2,$zname2=$zvalue2$zunits2";
}
else {
    $zoption .= " -y $vname2";
}

# --- Min sample size option ---
my $M_option = "";
$M_option = "-M $min_sample_size" if defined($min_sample_size);

# Call science command
my $scienceAlgorithm
    = "correlation_wrapper.pl -f $listfile -d $varinfo_file1,$varinfo_file2 -o $outdir -b '$bbox' -s $begintime -e $endtime $M_option $zoption";
$scienceAlgorithm .= " -v $debug" if $debug;
print STDERR "INFO science algorithm: $scienceAlgorithm \n";
$logger->info("ScienceAlgorithm: $scienceAlgorithm");
my $scienceCommand = Giovanni::ScienceCommand->new(
    sessionDir => $outdir,
    logger     => $logger
);
my ( $outputs, $messages ) = $scienceCommand->exec($scienceAlgorithm);
$logger->error("No output file found") unless scalar(@$outputs) > 0;

# add lat/lon resolution
Giovanni::Data::NcFile::add_resolution_attributes( $outputs->[0], $latres,
    $lonres );

# Create output mfst file
my $doc = XML::LibXML::Document->createDocument( '1.0', 'UTF-8' );
my $rootNode = XML::LibXML::Element->new("manifest");
$doc->setDocumentElement($rootNode);
my $flNode = XML::LibXML::Element->new('fileList');
$flNode->setAttribute('id', "$vname1,$vname2");
$flNode->appendTextChild('file', $outputs->[0]);
$rootNode->addChild($flNode);
open( OUT, ">$outfile" ) || die;
print OUT $doc->toString(1);
close(OUT);
$logger->info("Created output manifest file: $outfile");

# Create lineage
my ( $inputsObj, $outputsObj )
    = create_inputs_outputs( $files1, $files2, $outputs );
$logger->write_lineage(
    name     => $stepname,
    inputs   => $inputsObj,
    outputs  => $outputsObj,
    messages => $messages
);

exit(0);

sub create_inputs_outputs {
    my ( $files1, $files2, $outfiles ) = @_;

    # Create input file objects (one for each file)
    my $inputs = [];
    foreach my $f ( @$files1, @$files2 ) {
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

sub create_listfile {
    my ( $vname1, $files1, $vname2, $files2, $varinfo, $zselection ) = @_;
    my $long_name1 = $varinfo->{$vname1}->{'long_name'};
    my $long_name2 = $varinfo->{$vname2}->{'long_name'};
    my $reso1      = $varinfo->{$vname1}->{'resolution'};
    my $reso2      = $varinfo->{$vname2}->{'resolution'};

    my $doc = XML::LibXML::Document->createDocument( '1.0', 'UTF-8' );
    my $rootNode = XML::LibXML::Element->new("data");
    $doc->setDocumentElement($rootNode);

    my $dflNode1 = XML::LibXML::Element->new('dataFileList');
    $dflNode1->setAttribute('id', "$vname1");
    $dflNode1->setAttribute('resolution', "$reso1");
    $dflNode1->setAttribute('sdsName', "$vname1");
    $dflNode1->setAttribute('long_name', "$long_name1");
    $dflNode1->setAttribute('dataProductShortName', "$varinfo->{$vname1}->{'dataProductShortName'}");
    $dflNode1->setAttribute('dataProductVersion', "$varinfo->{$vname1}->{'dataProductVersion'}");
    foreach my $f (@$files1) {
	$dflNode1->appendTextChild('dataFile', $f);
    }
    $rootNode->addChild($dflNode1);

    my $dflNode2 = XML::LibXML::Element->new('dataFileList');
    $dflNode2->setAttribute('id', "$vname2");
    $dflNode2->setAttribute('resolution', "$reso2");
    $dflNode2->setAttribute('sdsName', "$vname2");
    $dflNode2->setAttribute('long_name', "$long_name2");
    $dflNode2->setAttribute('dataProductShortName', "$varinfo->{$vname2}->{'dataProductShortName'}");
    $dflNode2->setAttribute('dataProductVersion', "$varinfo->{$vname2}->{'dataProductVersion'}");
    foreach my $f (@$files2) {
	$dflNode2->appendTextChild('dataFile', $f);
    }
    $rootNode->addChild($dflNode2);

    my $listfile = "in_correlation.$$.xml";
    open( FH, ">$listfile" ) || die;
    print FH $doc->toString(1);
    close(FH);

    return $listfile;
}

# parse_stage_file()
sub parse_stage_file {
    my ($stagefile) = @_;

    my @files1 = ();
    my @files2 = ();

    my $parser = XML::LibXML->new();
    my $xml    = $parser->parse_file($stagefile);
    my ( $fileList_node_1, $fileList_node_2 )
        = $xml->findnodes('/manifest/fileList');
    if ( !$fileList_node_1 or !$fileList_node_2 ) {
        print "WARN Needs two fileList nodes in $stagefile\n";
        return ();
    }

    my $vname1 = $fileList_node_1->getAttribute('id');
    my $vname2 = $fileList_node_2->getAttribute('id');
    if ( !$vname1 or !$vname2 ) {
        print "WARN fileList doesn't contain an id $stagefile\n";
        return ();
    }

    my @file_nodes_1 = $fileList_node_1->findnodes('file');
    foreach my $fn (@file_nodes_1) {
        my $fpath = $fn->textContent();
        $fpath =~ s/^\s+|\s+$//g;
        push( @files1, $fpath ) if $fpath ne "";
    }
    my @file_nodes_2 = $fileList_node_2->findnodes('file');
    foreach my $fn (@file_nodes_2) {
        my $fpath = $fn->textContent();
        $fpath =~ s/^\s+|\s+$//g;
        push( @files2, $fpath ) if $fpath ne "";
    }

    return ( $vname1, \@files1, $vname2, \@files2 );
}

sub parse_varinfo {
    my ( $varinfo_file, $varinfo ) = @_;

    my $parser    = XML::LibXML->new();
    my $xml       = $parser->parse_file($varinfo_file);
    my @var_nodes = $xml->findnodes('/varList/var');
    foreach my $n (@var_nodes) {
        my $id                   = $n->getAttribute('id');
        my $zname                = $n->getAttribute('zDimName');
        my $zunits               = $n->getAttribute('zDimUnits');
        my $resolution           = $n->getAttribute('resolution');
        my $long_name            = $n->getAttribute('long_name');
        my $dataProductShortName = $n->getAttribute('dataProductShortName');
        my $dataProductVersion   = $n->getAttribute('dataProductVersion');
        if ( !$id ) {
            print STDERR "WARN The id for variable is missing\n";
            next;
        }
        $varinfo->{$id} = { 'resolution' => $resolution };
        $varinfo->{$id}->{'long_name'} = $long_name if $long_name;
        $varinfo->{$id}->{'dataProductShortName'} = $dataProductShortName
            if $dataProductShortName;
        $varinfo->{$id}->{'dataProductVersion'} = $dataProductVersion
            if $dataProductVersion;
        next unless $zname;
        $varinfo->{$id}->{'zname'} = $zname;
        $varinfo->{$id}->{'zunits'} = $zunits if $zunits;
    }

    return $varinfo;
}

sub parse_zfile {
    my ( $zfile, $zselection ) = @_;

    # Make sure zfile is not empty
    if ( !-s $zfile ) {
        print STDERR "WARN z-file $zfile empty\n";
        return {};
    }

    # Parse zfile
    my $parser     = XML::LibXML->new();
    my $xml        = $parser->parse_file($zfile);
    my @data_nodes = $xml->findnodes('/manifest/data');

    foreach my $n (@data_nodes) {
        my $zvalue = $n->getAttribute('zValue');
        my $vname  = $n->textContent();
        $vname =~ s/^\s+|\s+$//mg;
        $zselection->{$vname} = { 'zvalue' => $zvalue }
            if $zvalue and $zvalue !~ /^NA$/i;
    }

    return $zselection;
}
