#!/usr/bin/perl
#$Id: seasonalTimeSeries.pl,v 1.3 2015/04/24 14:08:16 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

seasonalTimeSeries.pl

=head1 SYNOPSIS

  seasonalTimeSeries.pl -b -113.2031,2.9297,-43.5937,38.7891 \
     -s 2000-01-01T00:00:00Z -e 2002-12-31T23:59:59Z -g MONTH=01 \
     -v TRMM_3B43_007_precipitation -f ./filesufY2T.txt \
     -o ints.TRMM_3B43_007_precipitation.20000101-20021231.MONTH_01.113W_2N_43W_38N.nc \
     -S shape


=head1 DESCRIPTION

Calculates a seasonal (interannual) time series. Averages over a bounding box in
each season.

=head2 ARGUMENTS

These are standard Giovanni::Wrapper::Algorithm arguments.


=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use 5.008008;
use strict;
use warnings;

use Giovanni::Algorithm::SeasonalTimeSeries;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename;
use File::Temp qw/tempfile/;

my @args = @ARGV;

# get the command line options
my $bbox;
my $inputFilesFile;
my $outputFile;
my $helpFlag;
my $variableName;
my $zSlice;
my $group;
my $shape;
my $dontcare;

GetOptions(
    "b=s" => \$bbox,
    "f=s" => \$inputFilesFile,
    "o=s" => \$outputFile,
    "v=s" => \$variableName,
    "z=s" => \$zSlice,
    "g=s" => \$group,
    "S=s" => \$shape,
    "s=s" => \$dontcare,
    "e=s" => \$dontcare,
    "l=s" => \$dontcare,
    "h"   => \$helpFlag,
);

# if this is the help flag, print out the command line arguments
if ( defined($helpFlag) ) {
    die "$0 -b <bounding box> -f <input file list file> "
        . "-o <output file> -v <variable name> -z <z-slice> -g <group>";
}

if ( !defined($bbox) ) {
    die "Missing required option 'b'";
}
if ( !defined($inputFilesFile) ) {
    die "Missing required option 'f'";
}
if ( !defined($outputFile) ) {
    die "Missing required option 'o'";
}
if ( !defined($variableName) ) {
    die "Missing required option 'v'";
}

if ( !defined($group) ) {
    die "Missing required option 'g'";
}

print STDERR "DEBUG seasonal time series call: $0";
for my $arg (@args) {
    print STDERR " $arg";
}
print STDERR "\n";

# read the input files file
open( FILE, "<", $inputFilesFile ) or die $!;
my @inFiles = <FILE>;
close(FILE);
chomp(@inFiles);

# parse the zslice
my $zVar;
my $zValue;
if ( defined($zSlice) ) {
    if ( $zSlice =~ /(.*)=(.*)/ ) {
        $zVar   = $1;
        $zValue = $2;
    }
    else {
        die "Unable to parse z-slice $zSlice";
    }
}

# parse the group
my $groupType;
my $groupValue;
if ( $group =~ /(.*)=(.*)/ ) {
    $groupType  = $1;
    $groupValue = $2;
}
else {
    die "Unable to parse group $group";
}

my $averager = Giovanni::Algorithm::SeasonalTimeSeries->new();
my %params = (
    bbox       => $bbox,
    inFiles    => \@inFiles,
    outFile    => $outputFile,
    groupValue => $groupValue,
    groupType  => $groupType,
    variable   => $variableName
);

if ( defined($zSlice) ) {
    $params{zValue} = $zValue;
    $params{zVar} = $zVar;
}

if ( defined($shape) ) {
    $params{shape} = $shape;
}

my $success = $averager->calculate(%params);

if ( !$success ) {
    die "Unable to complete seasonal average";
}

1;

