#!/usr/bin/perl
#$Id: intersectBboxes.pl,v 1.1 2014/10/07 14:07:19 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

intersectBboxes.pl

=head1 SYNOPSIS

  perl intersectBboxes.pl --bbox "-10,-10,10,10" --bbox "-5,-10,40,40" --bbox "-180,-90,45,68" 

=head1 DESCRIPTION

Calculates the intersection of two or more bounding boxes and prints out the 
result to stdout. Command line options are:

=item bbox - a bounding box. At least one must be specified. Bounding boxes are
in "w,s,e,n" format.

=item justOneResult - if this option is present, the code will fail if the
intersection produces more than one bounding box

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use 5.008008;
use strict;
use warnings;

use Getopt::Long;
use Giovanni::BoundingBox;

# get the command line options
my @bboxes;
my $justOneResult;
my $help;
GetOptions(
    "bbox=s"        => \@bboxes,
    "justOneResult" => \$justOneResult,
    "h"             => \$help,
);

if ( defined($help) ) {
    print
        "Usage: $0 --bbox '<first bbox in W,S,E,N format>' --bbox '<second bbox>'";
    exit;
}

my @bBoxObjects = ();
for my $bbox (@bboxes) {
    if ( $bbox ne '' ) {
        push( @bBoxObjects, Giovanni::BoundingBox->new( STRING => $bbox ) );
    }
}

if ( scalar(@bBoxObjects) == 0 ) {
    die("At least one bounding box is required.");
}

my @intersections = Giovanni::BoundingBox::getIntersection(@bBoxObjects);
if ( $justOneResult && scalar(@intersections) > 1 ) {
    die "Intersection resulted in more than one bounding box.";
}
for my $intersection (@intersections) {
    print $intersection->getString() . "\n";
}

1;
