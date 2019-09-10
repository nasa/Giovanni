#$Id: BoundingBox.pm,v 1.9 2014/10/16 19:33:46 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::BoundingBox;

use 5.008008;
use strict;
use warnings;
use POSIX;

use List::Util qw(max min);
use Scalar::Util qw(looks_like_number);
our $VERSION = '0.01';

# Constructor
sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    if ( exists( $params{"STRING"} ) ) {
        $self->_initialize_from_string();
    }
    elsif (exists( $params{"NORTH"} )
        && exists( $params{"SOUTH"} )
        && exists( $params{"EAST"} )
        && exists( $params{"WEST"} ) )
    {
        $params{"STRING"}
            = $params{"WEST"} . ","
            . $params{"SOUTH"} . ","
            . $params{"EAST"} . ","
            . $params{"NORTH"};
    }
    else {
        die
            "Constructor requires either STRING or all four directions (NORTH, SOUTH, EAST, WEST).";
    }

    return $self;

}

#
# The bounding box can take one of two forms:
#
# 1. -4.2187,24.0235,52.7344,50.7422
# 2. 4.2187W, 24.0235N, 52.7344E, 50.7422N
#
# This function initializes the WEST, SOUTH, EAST, and NORTH parameters to be
# decimal values, which means converting from northing/easting if necessary.
#
sub _initialize_from_string {
    my ($self) = @_;

    my ( $west, $south, $east, $north );

    if ( $self->{"STRING"}
        =~ /^\s*(.*)([WE])\s*,\s*(.*)([NS])\s*,\s*(.*)([WE])\s*,\s*(.*)([NS])\s*$/
        )
    {

        # This is the northing/easting case. Convert each to degrees north/
        # degrees east.
        $west  = $2 eq 'E' ? $1 : '-' . $1;
        $south = $4 eq 'N' ? $3 : '-' . $3;
        $east  = $6 eq 'E' ? $5 : '-' . $5;
        $north = $8 eq 'N' ? $7 : '-' . $7;

    }
    elsif (
        $self->{"STRING"} =~ /^\s*(.*?)\s*,\s*(.*?)\s*,\s*(.*?)\s*,\s*(.*?)\s*$/ )
    {

        # Already in degrees north/degrees east
        $west  = $1;
        $south = $2;
        $east  = $3;
        $north = $4;
    }
    else {

        # don't recognize the format
        die( "Unable to parse bounding box " . $self->{"STRING"} );
    }

    if (!(     looks_like_number($west)
            && looks_like_number($south)
            && looks_like_number($east)
            && looks_like_number($north)
        )
        )
    {

        # This is not a valid bounding box.
        die( "Unable to parse bounding box " . $self->{"STRING"} );
    }
    else {

        # Looks good
        $self->{"WEST"}  = $west;
        $self->{"SOUTH"} = $south;
        $self->{"EAST"}  = $east;
        $self->{"NORTH"} = $north;

    }
}

sub north {
    my ($self) = @_;
    return $self->{"NORTH"};
}

sub south {
    my ($self) = @_;
    return $self->{"SOUTH"};
}

sub east {
    my ($self) = @_;
    return $self->{"EAST"};
}

sub west {
    my ($self) = @_;
    return $self->{"WEST"};
}

sub getPrettyNorth {
    my ($self) = @_;
    return _convertNorthSouth( $self->{"NORTH"} );
}

sub getPrettySouth {
    my ($self) = @_;
    return _convertNorthSouth( $self->{"SOUTH"} );
}

sub getPrettyEast {
    my ($self) = @_;
    return _convertEastWest( $self->{"EAST"} );
}

sub getPrettyWest {
    my ($self) = @_;
    return _convertEastWest( $self->{"WEST"} );
}

# converts a number to a 'E' or 'W' string
sub _convertEastWest {
    my ($val) = @_;

    # remove trailing zeros
    $val =~ s/[.][0]*$//;

    if ( $val < 0 ) {
        return substr( $val, 1 ) . "W";
    }
    else {
        return $val . "E";
    }
}

# Creates a pretty version of the bounding box string.
# E.g. - "5W, 5.36S, 5E, 5N"
sub getPrettyString {
    my ($self) = @_;

    if (    ( $self->west() == $self->east() )
        and ( $self->north() == $self->south() ) )
    {
        return $self->getPrettyWest() . ", " . $self->getPrettySouth();
    }
    return
          $self->getPrettyWest() . ", "
        . $self->getPrettySouth() . ", "
        . $self->getPrettyEast() . ", "
        . $self->getPrettyNorth();
}

# Get the standard aG-style string in "W,S,E,N" format.
# E.g. - "-5.0,-5.23,5,5"
sub getString {
    my ($self) = @_;
    return
          $self->west() . ","
        . $self->south() . ","
        . $self->east() . ","
        . $self->north();
}

sub crosses180 {
    my ($self) = @_;

    my $bbox = $self->getCanonicalBbox();
    if ( $bbox->east() == -180 || $bbox->west() == -180 ) {

        # if we are right on the merridian, we aren't crossing it
        return 0;
    }
    elsif ( $bbox->east() < $bbox->west() ) {
        return 1;
    }
    else {
        return 0;
    }
}

# The purpose of this function is to get a bounding box whose east and west
# edges fall between -180 and 180. If the bounding box wraps around the
# entire globe at least once, the east and west edges are set to -180 and 180.
sub getCanonicalBbox {
    my ($self) = @_;

    my $west;
    my $east;
    my $westCanonical = getCanonicalLongitude( $self->west() );
    my $eastCanonical = getCanonicalLongitude( $self->east() );

    if ( ( $self->east() - $self->west() ) >= 360 ) {

# the box wraps around the globe at least once
# This includes both -180.333xxxx -> 179.666xxxx (original MERRA case) FEDGIANNI-3138
# And the currently hypothetical -179.666 -> 180.333 case (other side of dateline)
        $west = -180;
        $east = 180;
    }
    elsif ($eastCanonical == $westCanonical
        && $self->east() != $self->west() )
    {

        # This is the case where the bounding box wraps the entire way
        # around the globe, but the seam is not at the 180 meridian
        $west = -180;
        $east = 180;
    }
    elsif ( $eastCanonical == -180 && $self->west() < $self->east() ) {

# This is the (nominal) case where we have something like -175 --> 180 or
# 185 --> 540. 180 + n*360 gets mapped to -180, but we actually want
# 180 in this case.
# This fixes the unintended this strip issue FEDGIANNI-3088 (though not 1 deg lon regridding)
        $west = $westCanonical;
        $east = 180;
    }
    else {
        $west = $westCanonical;
        $east = $eastCanonical;
    }

    return Giovanni::BoundingBox->new(
        WEST  => $west,
        SOUTH => $self->south(),
        EAST  => $east,
        NORTH => $self->north()
    );
}

sub getCanonicalLongitude {
    my ($lon) = @_;

    if ( $lon >= 180 || $lon < -180 ) {

        # figure out how to get n such that
        # $lon + n*360 >= -180
        my $n = ceil( -0.5 - $lon / 360.0 );
        return $lon + $n * 360;
    }
    else {
        return $lon;
    }
}

# Checks to see if two bounding boxes are numerically the same
sub isSameBox {
    my ( $first, $second ) = @_;

    return
           ( $first->west() == $second->west() )
        && ( $first->south() == $second->south() )
        && ( $first->east() == $second->east() )
        && ( $first->north() == $second->north() );
}

# Checks to see if north == south or east == west
sub isEmptyBox {
    my ($self) = @_;
    return (   $self->north() == $self->south()
            || $self->east() == $self->west() );
}

# Get the width in degrees
sub getWidth {
    my ($self) = @_;
    if ( $self->west() > $self->east() ) {
        return 360 - $self->west() + $self->east();
    }
    else {
        return $self->east() - $self->west();
    }
}

# Get the height in degrees
sub getHeight {
    my ($self) = @_;
    return $self->north() - $self->south();
}

# get the intersection of bounding boxes
sub getIntersection {
    my @bboxes   = @_;
    my $numBoxes = scalar(@bboxes);
    if ( $numBoxes == 0 ) {
        return undef;
    }
    elsif ( $numBoxes == 1 ) {

        # take care of the degenerate case
        return $bboxes[0];
    }
    if ( $numBoxes == 2 ) {
        return _getIntersectionOfTwoBoxes(@bboxes);
    }

    # Otherwise, recurse. First get the interesection of the last N-1 boxes
    my @intersections = getIntersection( @bboxes[ 1 .. $numBoxes - 1 ] );

    # now, intersect the result with the first box
    my @allIntersections = ();
    for my $box (@intersections) {
        my @moreIntersections
            = _getIntersectionOfTwoBoxes( $bboxes[0], $box );
        if ( scalar(@moreIntersections) > 0 ) {
            push( @allIntersections, @moreIntersections );
        }
    }
    return @allIntersections;
}

# Get the intersection of two bounding boxes
sub _getIntersectionOfTwoBoxes {
    my ( $first, $second ) = @_;
    $first  = $first->getCanonicalBbox();
    $second = $second->getCanonicalBbox();

    # break up the boxes across the 180 merridian
    my @bboxes = ();
    push( @bboxes, _breakUpBbox($first) );
    push( @bboxes, _breakUpBbox($second) );

    # calculate all intersections between boxes
    my @intersections = ();
    for ( my $i = 0; $i < scalar(@bboxes); $i++ ) {
        for ( my $j = $i + 1; $j < scalar(@bboxes); $j++ ) {
            my $intersection
                = _getBboxIntersectionSimple( $bboxes[$i], $bboxes[$j] );

            if ( defined($intersection) ) {

                # only care about bounding boxes that actually intersected.
                push( @intersections, $intersection );
            }
        }
    }

    # we potentially have two boxes we need to stitch together over the 180
    # meridian
    my $west180;
    my $east180;
    my @retBboxes = ();
    for my $bbox (@intersections) {
        if ( $bbox->west() == -180 ) {
            $west180 = $bbox;
        }
        elsif ( $bbox->east() == 180 ) {
            $east180 = $bbox;
        }
        else {
            push( @retBboxes, $bbox );
        }
    }

    if ( defined($west180) && defined($east180) ) {

        # need to stitch together
        push(
            @retBboxes,
            Giovanni::BoundingBox->new(
                WEST  => $east180->west(),
                SOUTH => $west180->south(),
                EAST  => $west180->east(),
                NORTH => $west180->north()
            )
        );
    }
    elsif ( defined $west180 ) {

        # push it as is
        push( @retBboxes, $west180 );
    }
    elsif ( defined $east180 ) {

        # push it as is
        push( @retBboxes, $east180 );
    }

    return @retBboxes;

}

# Calculates the bounding box intersection of two bounding boxes that
# do not cross the 180 meridian
sub _getBboxIntersectionSimple {
    my ( $first, $second ) = @_;

    # make sure there is some kind of intersection
    if (_rangesOverlap(
            $first->west(),  $first->east(),
            $second->west(), $second->east()
        )
        && _rangesOverlap(
            $first->south(),  $first->north(),
            $second->south(), $second->north()
        )
        )
    {
        return Giovanni::BoundingBox->new(
            WEST  => max( $first->west(),  $second->west() ),
            SOUTH => max( $first->south(), $second->south() ),
            EAST  => min( $first->east(),  $second->east() ),
            NORTH => min( $first->north(), $second->north() )
        );
    }
    else {
        return undef;
    }

}

# Checks to make sure that range [$left_1, $right_1] overlaps
#[$left_2,$right_2]
sub _rangesOverlap {
    my ( $left_1, $right_1, $left_2, $right_2 ) = @_;

    if ( $right_1 < $left_2 || $right_2 < $left_1 ) {
        return 0;
    }
    else {
        return 1;
    }
}

# Breaks up bounding boxes over the 180 meridian. If the box doesn't go
# over the meridian, it only returns one box.
sub _breakUpBbox {
    my ($bbox) = @_;

    if ( $bbox->east() < $bbox->west() ) {

        # goes over the 180 meridian
        return (
            Giovanni::BoundingBox->new(
                WEST  => -180,
                SOUTH => $bbox->south(),
                EAST  => $bbox->east(),
                NORTH => $bbox->north()
            ),
            Giovanni::BoundingBox->new(
                WEST  => $bbox->west,
                SOUTH => $bbox->south,
                EAST  => 180,
                NORTH => $bbox->north
            )
        );
    }
    else {
        return ($bbox);
    }
}

# converts a number to a 'N' or 'S' string
sub _convertNorthSouth {
    my ($val) = @_;

    # remove trailing zeros
    $val =~ s/[.][0]*$//;

    if ( $val < 0 ) {
        return substr( $val, 1 ) . "S";
    }
    else {
        return $val . "N";
    }
}

sub pad {
    my ( $self, $longitude_pad, $latitude_pad ) = @_;

    if ( $self->crosses180() ) {

        # break into two bounding box
        my $westBbox = Giovanni::BoundingBox->new(
            WEST  => $self->west(),
            SOUTH => $self->south(),
            EAST  => 180,
            NORTH => $self->north()
        );
        my $eastBbox = Giovanni::BoundingBox->new(
            WEST  => -180,
            SOUTH => $self->south(),
            EAST  => $self->east(),
            NORTH => $self->north()
        );

        # pad
        my $westPadded = $westBbox->pad( $longitude_pad, $latitude_pad );
        my $eastPadded = $eastBbox->pad( $longitude_pad, $latitude_pad );

        # make sure we didn't actually wrap around on top of ourself
        my @intersections
            = Giovanni::BoundingBox::getIntersection( $westPadded,
            $eastPadded );

        if ( scalar(@intersections) == 0 ) {

            # We got the normal two halves we expected
            # (-180 and 180 do not intersect)
            return Giovanni::BoundingBox->new(
                WEST  => $westPadded->west(),
                SOUTH => $westPadded->south(),
                EAST  => $eastPadded->east(),
                NORTH => $westPadded->north()
            );

        }
        else {

            # the west bounding box wrapped around on top of the east bounding
            # box. So we want the entire globe for longitude.
            return Giovanni::BoundingBox->new(
                WEST  => -180,
                SOUTH => $westPadded->south(),
                EAST  => 180,
                NORTH => $westPadded->north()
            );
        }
    }
    else {

        # this bounding box didn't cross the 180 merridian

        # check we got sensible padding
        if ( $latitude_pad < 0 || $longitude_pad < 0 ) {
            die "Bounding box padding must be >= 0.";
        }

        my $newWest
            = $self->west() - $longitude_pad >= -180
            ? $self->west() - $longitude_pad
            : -180;

        my $newSouth
            = $self->south() - $latitude_pad >= -90
            ? $self->south() - $latitude_pad
            : -90;

        my $newEast
            = $self->east() + $longitude_pad <= 180
            ? $self->east() + $longitude_pad
            : 180;

        my $newNorth
            = $self->north() + $latitude_pad <= 90
            ? $self->north() + $latitude_pad
            : 90;

        return Giovanni::BoundingBox->new(
            WEST  => $newWest,
            SOUTH => $newSouth,
            EAST  => $newEast,
            NORTH => $newNorth
        );

    }
}

1;
__END__

=head1 NAME

Giovanni::BoundingBox - Perl extension for dealing with bounding boxes. NOTE:
this extension is designed to work with bounding boxes that are less than or
equal to 360 degrees wide.

=head1 SYNOPSIS

  use Giovanni::BoundingBox;
  
  my $bbox1 = Giovanni::BoundingBox->new( STRING => '170,-11,-171,10' );
  my $bbox2 = Giovanni::BoundingBox->new( STRING => '175,-3,-160,4' );
  my @intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
  
  for my $intersection(@intersections){
     print "Box: ".$intersection->getPrettyString();
  }
  

=head1 DESCRIPTION

=head2 CONSTRUCTOR: $bbox = Giovanni::BoundingBox->new( STRING => '-180,-90,180,90')

Constructs a bounding box. Can also be called 
Giovanni::BoundingBox->new( WEST=>"-180", SOUTH=>"-90", EAST=>"180", NORTH=>"180")

=head2 INTERSECTION: @intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 )

Gets the intersection of bounding boxes. May return more than one box.

=head2 STRING: print $bbox->getString()

Gets the nominal string respresentation for this bounding box. E.g. -
'-180.000,-90.000,5.300,1.000'

=head2 STRING: print $bbox->getPrettyString()

Gets the 'pretty' string representation for this bounding box. E.g. - 
'180W, 90S, 5.3E, 1N'

=head2 WIDTH: $width = $bbox->getWidth()

Gets the width of the bounding box in degrees.

=head2 HEIGHT: $height = $bbox->getHeight()

Gets the height in degrees.

=head2 VALUES: $bbox->north(), $bbox->south(), $bbox->east(), $bbox->west()

Gets the individual elements of the bounding box

=head2 VALUES: $bbox->getPrettyNorth(), $bbox->getPrettySouth(), 
$bbox->getPrettyEast(), $bbox->getPrettyWest

Gets the 'pretty' versions of the individual elements. E.g. - '90W'.

=head2 SAME BOX: Giovanni::BoundingBox::isSameBox($bbox1, $bbox2)

Returns true if bbox1 and bbox2 have the same north, south, east, and west
values.

=head2 EMPTY BOX: $bbox->isEmptyBox()

Returns true if the bounding box has no area.

=head2 CANONICAL BBOX: $bbox->getCanonicalBbox()

Converts the west and east components to be on [-180,180).

=head2 CANONICAL LONGITUDE: Giovanni::BoundingBox::getCanonicalLongitude(-185)

Converts a longitude to an equivalent value on [-180,180).

=head2 PAD: my $padded = $bbox->pad($longitude_pad,$latitude_pad);

Pads the bounding box by $longitude_pad and $latitude_pad. 

This function will not pad out a bounding box over the 180 merridian unless the 
input bounding box already crosses the 180 merridian.

If padding the bounding box causes it to wrap around on top of itself, the
returned bounding box will extend from -180 to 180. E.g. the bounding box
(-177,-10,175,10) padded $longitude_pad=10, $latitude_pad=10 will give you the
bounding box (-180,-20,-180,20).

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut
