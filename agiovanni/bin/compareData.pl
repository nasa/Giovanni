#!/usr/bin/perl -w

=head1 NAME

compareData.pl - Data comparison test script

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

compareData.pl [--help] [--verbose] --file <in.txt>

=head1 DESCRIPTION

This program compares pairs of files listed in in.txt and report differences
in data.

=head1 OPTIONS

=over 4

=item --help
Print a usage information

=item --verbose
Turn on verbose mode

=item --bbox
Bounding box in "west,south,east,north" for which the comparison will be limited to.

=item --file <in.txt>
Input list file pairs to be compared, with each record contains the following information:
varA|fileA|varB|fileB
url1|url2

=back

=head1 AUTHOR

Jianfu Pan (jianfu.pan@nasa.gov)

=head1 DATE
2/4/2013, Initial version

=cut

use lib ".";

use strict;
use Getopt::Long;
use File::Basename;

our $mydir           = dirname($0);
our $cmd_getvarnames = "$mydir/getNcVarList.py";
our $cmd_ncCompare   = "$mydir/ncCompare.py";
our $cmd_downloadG4
    = "perl -I /tools/gdaac/TS2/lib/perl5/site_perl/5.8.8 /tools/gdaac/TS2/bin/downloadRequestData.pl --lineage";

my $help;
my $debug_level = 0;
my $verbose;
my $bbox = "";
my $infile;
my $opts = GetOptions(
    "help"      => \$help,
    "h"         => \$help,
    "verbose=s" => \$verbose,
    "bbox=s"    => \$bbox,
    "b=s"       => \$bbox,
    "file=s"    => \$infile,
    "f=s"       => \$infile
);

my $usage
    = "Usage: $0 [--help] [--verbose] --file <in.txt>\n"
    . "    [--help]         Print this help info\n"
    . "    [--verbose]      Print out lot of messages\n"
    . "    [--bbox]         Bounding box (w,s,e,n)\n"
    . "    --file           in.txt A text file listing pairs of files to be compared (varA|fileA|varB|fileB)\n";

# Print usage and exit if that's all asked for
if ($help) {
    print STDERR $usage;
    exit(0);
}

# Check required options
die("ERROR Input file missing") unless defined($infile) and -f $infile;
print STDERR "INFO Comparing data from input file $infile\n";

#
# Convert records in infile to pairs
#

my $infile_paired = create_pairs($infile);
die "ERROR Fail to create pairs from $infile ($infile_paired)\n"
    unless -s $infile_paired;

#
# Go through list of pairs and compare data
#

if ( !-s $infile_paired ) {
    print STDERR
        "ERROR Paired input file ($infile_paired) not found or empty\n";
    exit(0);
}

open( IN, "<$infile_paired" ) || die;

my $cnt_skipped = 0;
while ( my $pair = <IN> ) {
    chomp($pair);
    my ( $varA, $fileA, $varB, $fileB ) = split( '\|', $pair, 4 );
    if ( $varA eq "" or $fileA eq "" or $varB eq "" or $fileB eq "" ) {
        print STDERR "WARN invalid pair ($pair) ... skip\n";
        $cnt_skipped = $cnt_skipped + 1;
    }
    else {
        my $max_abs_err = compare_data( $varA, $fileA, $varB, $fileB, $bbox );
        if ( !defined($max_abs_err) ) {
            print "Failed to compare $pair\n";
            next;
        }

        # TBD Using 10e-6 for error tolerance, but this can be improved by
        #     dynamically determining order of magnitudes.
        if ( $max_abs_err < 1.0e-06 ) {
            print "$pair MaxError=$max_abs_err (OK)\n";
        }
        else {
            print "$pair MaxError=$max_abs_err (NOT OK)\n";
        }
    }
}
close(IN);

exit(0);

sub create_pairs {
    my ($list_file) = @_;
    my $file_paired = "paired$$." . basename($list_file);

    my @records = `cat $list_file`;
    chomp(@records);
    open( OUT, ">$file_paired" ) || die;
    foreach my $rec (@records) {
        my @items = split( '\|', $rec );
        my $nitems = scalar(@items);
        if ( $nitems == 4 ) {
            print OUT "$rec\n";
        }
        elsif ( $nitems == 2 ) {
            my $recs_downloaded = download_records( $items[0], $items[1] );
            foreach my $p (@$recs_downloaded) {
                print OUT "$p->[0]|$p->[1]|$p->[2]|$p->[3]\n";
            }
        }
        else {
            die "ERROR Invalid record in $list_file: $rec\n";
        }
    }
    close(OUT);
    return $file_paired;
}

sub download_records {
    my ( $urlA, $urlB ) = @_;
    my $outdirA = "dataA$$";
    my $outdirB = "dataB$$";
    mkdir( $outdirA, 0755 ) || die("ERROR Fail to make session dir dataA")
        unless -d $outdirA;
    mkdir( $outdirB, 0755 ) || die("ERROR Fail to make session dir dataB")
        unless -d $outdirB;
    my $dataA = downloadG4( $urlA, $outdirA );
    my $dataB = downloadG4( $urlB, $outdirB );
    my $nA    = scalar(@$dataA);
    my $nB    = scalar(@$dataB);

    #
    # Now match up records
    #

    # --- Expect same number of data files ---
    die "ERROR Got $nA files in A and $nB in B\n" unless $nA == $nB;

    # --- Create pairs ---
    my @pairs = ();
    for ( my $k = 0; $k < $nA; $k++ ) {
        my $vnamesA     = get_varnames( $dataA->[$k] );
        my $vnamesB     = get_varnames( $dataB->[$k] );
        my $vnamesB_str = join( ',', @$vnamesB );
        foreach my $v (@$vnamesA) {
            next if $v eq "dataday" or $v eq "datamonth";
            if ( $vnamesB_str =~ /\b$v\b/ ) {
                print STDERR
                    "INFO Found matched pair for $v in $dataA->[$k] and $dataB->[$k]\n";
                push( @pairs, [ $v, $dataA->[$k], $v, $dataB->[$k] ] );
            }
        }
    }

    return \@pairs;
}

sub downloadG4 {
    my ( $g4url, $outdir ) = @_;

    my $g4info = {};

    # --- Run G4 downloader ---
    my $log = `$cmd_downloadG4 \"$g4url\" $outdir`;
    die("G4 download failed: $cmd_downloadG4 \"$g4url\" $outdir ($log)")
        if $?;

    # --- Capture downloaded files ---
    my @g4_data_tmp = `ls $outdir/*.nc $outdir/*.nc#GIOVANNI`;
    chomp(@g4_data_tmp);
    my @g4_data = ();
    foreach my $i (@g4_data_tmp) {
        my $f = "$outdir/" . basename($i);
        push( @g4_data, $f );
    }

    return \@g4_data;
}

sub get_varnames {
    my ($infile) = @_;

    my @names     = ();
    my $names_str = `$cmd_getvarnames $infile`;
    if ($?) {
        die("ERROR Failed to find variable names: $cmd_getvarnames $infile");
    }
    else {
        $names_str =~ s/^\s+|\s+$//;
        @names = split( '\s+', $names_str );
    }

    return \@names;
}

sub compare_data {
    my ( $varA, $fileA, $varB, $fileB, $bbox ) = @_;

    my $cmd = "$cmd_ncCompare $varA $fileA $varB $fileB";
    if ( $bbox ne "" ) {
        $cmd = "$cmd_ncCompare -b $bbox $varA $fileA $varB $fileB";
    }

    my $output = `$cmd`;
    if ($?) {
        print STDERR "ERROR compare failed ($cmd) $!\n";
        return undef;
    }
    chomp($output);
    my ( $min_err, $max_err )
        = ( $output =~ /^Min\/Max difference:\s*(.+)\ (.+)/ );
    if ( !$min_err or !$max_err ) {
        print STDERR "Cannot compare failed ($cmd) $!\n";
        return undef;
    }
    my $max_abs_err = abs($min_err);
    $max_abs_err = abs($max_err) if abs($max_err) > $max_abs_err;

    return $max_abs_err;
}
