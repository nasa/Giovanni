#!/usr/bin/perl -w

=head1 Name 

giovanni_data_pairing.pl

=head1 DESCRIPTION

giovanni_data_pairing.pl is a wrapper calling data pairing algorithm (dataPairingNco.pl)

=head1 SYNOPSIS

scienceCommandWrapper.pl --inputfilelist <stage.xml> --bbox <bbox> --debug [0|1] -zfile <zfile1.xml,zfile2.xml> --datafield-info-file <varInfo1.xml,varInfo2.xml> --outfile <output-mfst-file>

Sample stage_data_file.xml:
<fileList id="MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean">
  <file>/var/temp/scrubbed.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101.nc</file>
  <file>/var/temp/scrubbed.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030102.nc</file>
</fileList>

=head1 AUTHOR

Jianfu Pan

Date Created: 2013-07-08

=cut

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use XML::LibXML;
use Giovanni::ScienceCommand;
use Giovanni::Logger;

my $stepname = "Data pairing";

#
# Command line options
#

my ( $stagefile, $bbox, $outfile, $varinfo_file );
my $debug = 0;
my $zfile = undef;

GetOptions(
    'inputfilelist=s'       => \$stagefile,
    'bbox=s'                => \$bbox,
    'outfile=s'             => \$outfile,
    'zfile=s'               => \$zfile,
    'datafield-info-file=s' => \$varinfo_file,
    'debug=i'               => \$debug
);

# Check for required options
die "ERROR Required outfile missing\n" unless $outfile;

# Looking for two varinfo files
my ( $varinfo_file1, $varinfo_file2 ) = split( ',', $varinfo_file, 2 );
die "ERROR Needs two varinfo files got $varinfo_file\n"
    unless -s $varinfo_file1 and -s $varinfo_file2;

# Looking for two z files
$zfile =~ s/\s//g;
my ( $zfile1, $zfile2 ) = split( ',', $zfile, 2 );
die "ERROR Needs two z files got $zfile\n" unless -s $zfile1 and -s $zfile2;

# Derived parts from $outfile name
my $outdir = dirname($outfile);
my $logger = Giovanni::Logger->new(
    session_dir       => $outdir,
    manifest_filename => $outfile
);
$logger->info("StageFile: $stagefile");

#
# Parse stage file
#

my ( $vname1, $files1, $vname2, $files2 ) = parse_stage_file($stagefile);

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
# Construct an input list file for pairing algorithm
# The list file contains list of data files to be processed by the algorithm
#

my $listfile = create_listfile( $vname1, $files1, $vname2, $files2, $varinfo,
    $zselection );

#
# Call ScienceCommand.pm
#

# --- Construct z-option ---
my $zoption = "";
if ( exists( $zselection->{$vname1} ) ) {
    my $zname1  = $varinfo->{$vname1}->{'zname'};
    my $zunits1 = $varinfo->{$vname1}->{'zunits'};
    my $zvalue1 = $zselection->{$vname1}->{'zvalue'};
    $zoption .= "-x $vname1,$zname1=$zvalue1$zunits1";
}
if (    exists( $zselection->{$vname2} )
    and exists( $varinfo->{$vname2}->{'zname'} ) )
{
    my $zname2  = $varinfo->{$vname2}->{'zname'};
    my $zunits2 = $varinfo->{$vname2}->{'zunits'};
    my $zvalue2 = $zselection->{$vname2}->{'zvalue'};
    $zoption .= " -y $vname2,$zname2=$zvalue2$zunits2";
}

# Call science command
die("ERROR No input files for data pairing\n") unless -e $listfile;

my $scienceAlgorithm
    = "dataPairingNco.pl -f $listfile -o $outdir -b $bbox $zoption";
print STDERR "INFO science algorithm: $scienceAlgorithm \n";
$logger->info("ScienceAlgorithm: $scienceAlgorithm");
my $scienceCommand = Giovanni::ScienceCommand->new(
    sessionDir => $outdir,
    logger     => $logger
);
my ( $outputs, $messages ) = $scienceCommand->exec($scienceAlgorithm);

$logger->error("No output file found") if scalar(@$outputs) < 1;

#
$logger->info("Paired file: $outputs->[0]");

#
# Create a new manifest file
#

open( OUT, ">$outfile" ) || die;
print OUT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print OUT "<manifest>\n";
print OUT "<fileList id=\"$vname1,$vname2\">\n";
print OUT "<file>$outputs->[0]</file>\n";
print OUT "</fileList>\n";
print OUT "</manifest>\n";
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
    my $reso1 = $varinfo->{$vname1}->{'resolution'};
    my $reso2 = $varinfo->{$vname2}->{'resolution'};

    my $dataFileList1 = "";
    foreach my $f (@$files1) {
        $dataFileList1 .= "<dataFile>$f</dataFile>\n";
    }
    my $dataFileList2 = "";
    foreach my $f (@$files2) {
        $dataFileList2 .= "<dataFile>$f</dataFile>\n";
    }
    my $listfile_content = <<EOF;
<data>
<dataFileList id="$vname1" resolution="$reso1" sdsName="$vname1">
$dataFileList1
</dataFileList>
<dataFileList id="$vname2" resolution="$reso2" sdsName="$vname2">
$dataFileList2
</dataFileList>
</data>
EOF

    my $listfile = "in_pair.$$.xml";
    open( FH, ">$listfile" ) || die;
    print FH "$listfile_content";
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
