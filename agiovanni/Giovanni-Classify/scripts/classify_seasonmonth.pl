#!/usr/bin/perl
#$Id: classify_seasonmonth.pl,v 1.4 2014/01/21 20:14:02 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

use 5.008008;
use strict;
use warnings;

use Getopt::Long;
use File::Basename;
use Giovanni::Classify;
use Switch;

my $outputFile;
my $inputFile;
my $groupType;
my $helpFlag;
GetOptions(
    "out-file=s"   => \$outputFile,
    "in-file=s"    => \$inputFile,
    "group-type=s" => \$groupType,
    "h"            => \$helpFlag,
);

# if this is the help flag, print out the command line arguments
if ( defined($helpFlag) ) {
    die "$0 --out-file 'path to output file'"
        . " --in-file 'path to input file'"
        . " --group-type 'group type'";
}

switch ($groupType) {
    case 'SEASON' {
        Giovanni::Classify::classify_seasons(
            INPUT  => $inputFile,
            OUTPUT => $outputFile,
        );
    }
    case 'MONTH' {
        Giovanni::Classify::classify_months(
            INPUT  => $inputFile,
            OUTPUT => $outputFile,
        );
    }
    else {
        die "Unrecognised group-type '$groupType'";
    }
}

1;

__END__

=head1 NAME

classify_seasonmonth.pl

=head1 SYNOPSIS

  classify_seasonmonth.pl --in-file "/path/to/inputmanifest.xml" --out-file "/path/to/outputmanifest.xml" --group-type "SEASON"  

=head1 DESCRIPTION
Classifies data into months or seasons. The input file should be from data 
staging. The output file is the same format, but each file entry has a 'group'
attribute. Valid group types are SEASON and MONTH.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.gov<gt>

=cut
