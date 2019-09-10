#!/usr/bin/perl
#$Id: getBboxOutOfDatafieldInfo.pl,v 1.2 2015/02/04 21:42:03 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

getBboxOutOfDatafieldInfo get the bounding box out in 'w,s,e,n' format.

=head1 SYNOPSIS

  perl getBboxOutOfDatafieldInfo.pl --file '/path/to/file'

=head1 DESCRIPTION

Seaches for data files. Command line options are:

1. file - location of the data field info file

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use 5.008008;
use strict;
use warnings;

use Getopt::Long;
use Giovanni::DataField;

# get the command line options
my $file;
my $helpFlag;

GetOptions(
    "file=s" => \$file,
    "h"      => \$helpFlag,
);

# if this is the help flag, print out the command line arguments
if ( defined($helpFlag) ) {
    die "$0 --file '/path/to/datafieldinfo.xml";
}

if ( !defined($file) ) {
    die "The --file option is mandatory";
}

my $dataField = Giovanni::DataField->new( MANIFEST => $file );

my $west  = $dataField->get_west();
my $south = $dataField->get_south();
my $east  = $dataField->get_east();
my $north = $dataField->get_north();

print "$west,$south,$east,$north";
1;
