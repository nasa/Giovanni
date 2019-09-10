#!/usr/bin/perl


=head1 NAME

convertEDDAtoTSV - Convert an EDDA product or variable xml file to a tab-separated text format

=head1 PROJECT

AESIR EDDA

=head1 SYNOPSIS

convertEDDAtoTSV --outdir <output file directory> filename

=head1 DESCRIPTION

Convert an EDDA product or variable file to a tab-separated text format

=head1 OPTIONS

=over 4

=item format

Default is tsv (tab-separated values)

=back

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=cut

#my ($rootPath);
#BEGIN {
#    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
#    if (defined $rootPath) {
#	unshift( @INC, $rootPath . 'share/perl5' );
#    }
#}

use strict;
use XML::LibXML;
use XML::Simple;
use File::Basename;
use Getopt::Long;
use Safe;

my $usage = "Usage: $0 outputDirectory inputDirectory or inputFile1 inputFile2... \n";
my $help;
my $outDir;

Getopt::Long::GetOptions( 'help'     => \$help );
if ($help) {
    print $usage;
    exit 0;
}

$outDir = shift @ARGV;
die "First argument must be a writeable directory\n$usage" unless -d $outDir && -w $outDir;
my @inputArgs = @ARGV;
die "Arguments after the first must be a readable directory or a list of readable files\n$usage" unless -r $inputArgs[0];
die "Output directory must not be the same as the input directory\n$usage" if ($outDir eq $inputArgs[0]);

#my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
#my $cpt = Safe->new('CFG');
#unless ( $cpt->rdo($cfgFile) ) {
#    die "Could not read EDDA configuration file $cfgFile\n";
#}

my @inFiles;
my $outFile;
if (-d $inputArgs[0]) {
    my $inputDir = $inputArgs[0];
    die "Could not open directory $inputDir for reading: $!\n"
	unless opendir(DIR, $inputDir);
    @inFiles = grep { !/^\./ && -f "$inputDir/$_" } readdir(DIR);
    closedir(DIR);
    @inFiles = map("$inputDir/$_", @inFiles);
} else {
    @inFiles = @inputArgs;
    foreach (@inFiles) {
	die "Arguments after the first must be a readable directory or a list of readable files\n$usage" unless -r $_;	
    }
}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);
my $header;
my $prevHeader;
   
my $hSep = "\t";
#my $vSep = "\x0A";  # new line
#my $vSep = "\x0B";  # vertical tab
#my $vSep = "\x0C";  # form feed
#my $vSep = "\x0D";  # carriage return
my $vSep = '|';

foreach my $inFile (@inFiles) {
    my ($dom, $doc);
    eval { $dom = $parser->parse_file($inFile); };
    if ($@) {
	print STDERR "Error parsing $inFile: $@\n";
	next;
    }
    $doc = $dom->documentElement();
    my $type;

    my @fieldNames;
    my @outVals;
    
    extract($doc, $vSep, \@fieldNames, \@outVals);

    # Distinguish type from the name of the first element
    if ($fieldNames[0] =~ /^dataField/) {
	$type = 'dataField';
    } elsif ($fieldNames[0] =~ /^dataProduct/) {
	$type = 'dataProduct';
    } else {
	print STDERR "Unrecognized field name $fieldNames[0], ignoring $inFile\n";
	next;
    }
    my $header = join($hSep, @fieldNames);

    unless ($outFile) {
	my $outName = $type . '_' . time . '.tab';
        $outFile = "$outDir/$outName";
	unless (open(OUT, "> $outFile")) {
	    print STDERR "Could not open $outFile for writing\n";
	    exit 0;
	}
	print OUT $header, "\n";
    }
    if ($prevHeader && ($header ne $prevHeader)) {
	print STDERR "ERROR: header changed from\n$prevHeader\nto\n$header\n";
	exit 1;
    }
    $prevHeader = $header;

    my $outLine = join($hSep, @outVals);
    print OUT $outLine, "\n";

    print STDERR "Converted ", basename($inFile), "\n";
}
close(OUT);

exit 0;

sub extract {
    my ($doc, $vSep, $fieldNames, $outVals) = @_;

    foreach my $node ($doc->childNodes) {
	my $field = XMLin($node->toString);
	my $type = $field->{type};
#	my $multiplicity = $field->{multiplicity};
	my $value = $field->{value};
	if ($type eq 'container') {

	    # A container conatins other fields, and has a field name we will
	    # not include in the list of field names. Recursively call extract()
	    # the extract field information from the container's value node
	    (my $childNode) = $node->getChildrenByTagName('value');
	    extract($childNode, $vSep, $fieldNames, $outVals);
	} else {
	    if (ref($value) eq 'HASH') {

		# This should only happen if value has attributes.
		# Expect attributes only for longId in dataProduct.
		push @$outVals, $value->{longId};
	    } elsif (ref($value) eq 'ARRAY') {

		# Multi-valued fields are converted to a string of values
		# separated by $vSep.
		my @vals;
		foreach my $val (@$value) {
		    if (ref($val) eq 'HASH') {

			# This should only happen if value has attributes.
			# Expect attributes only for longId in dataProduct.
		        push @vals, $val->{longId};
		    } else {
			push @vals, $val;
		    }
		}
		push @$outVals, join($vSep, @vals);
	    } else {

		# Single-valued field
		push @$outVals, $value;
	    }
	    push @$fieldNames, $node->nodeName;
	}
    }
}
