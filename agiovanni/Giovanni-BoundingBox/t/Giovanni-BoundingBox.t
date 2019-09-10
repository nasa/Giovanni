#$Id: Giovanni-BoundingBox.t,v 1.7 2014/10/07 14:07:20 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-BoundingBox.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 67;
BEGIN { use_ok('Giovanni::BoundingBox') }

use strict;
use warnings;

#########################

my ( $bbox1, $bbox2, $bbox3, @intersections );

# test the constructor
$bbox1 = Giovanni::BoundingBox->new( STRING => '-180,-90,180,90' );
is( $bbox1->west(),  -180, 'correct west 1' );
is( $bbox1->south(), -90,  'correct south 1' );
is( $bbox1->east(),  180,  'correct east 1' );
is( $bbox1->north(), 90,   'correct north 1' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '180W, 90S, 180E, 90N' );
is( $bbox1->west(),  -180, 'correct west 2' );
is( $bbox1->south(), -90,  'correct south 2' );
is( $bbox1->east(),  180,  'correct east 2' );
is( $bbox1->north(), 90,   'correct north 2' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '10E, 10N, 180E, 90N' );
is( $bbox1->west(),  10,  'correct west 3' );
is( $bbox1->south(), 10,  'correct south 3' );
is( $bbox1->east(),  180, 'correct east 3' );
is( $bbox1->north(), 90,  'correct north 3' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '100W, 10S, 90W, 5.5S' );
is( $bbox1->west(),  -100, 'correct west 4' );
is( $bbox1->south(), -10,  'correct south 4' );
is( $bbox1->east(),  -90,  'correct east 4' );
is( $bbox1->north(), -5.5, 'correct north 4' );
is( $bbox1->getString(), "-100,-10,-90,-5.5",
    'correct string bounding box string' );

$bbox1 = Giovanni::BoundingBox->new( STRING => ' 100W , 10S,90W,5.5S ' );
is( $bbox1->getString(), "-100,-10,-90,-5.5" , "weird whitespace");

$bbox1 = Giovanni::BoundingBox->new( STRING => '-100, -10,-90 ,-5.5 ' );
is( $bbox1->getString(), "-100,-10,-90,-5.5" , "more weird whitespace");

# try invalid bounding boxes
is( eval('Giovanni::BoundingBox->new(STRING=>"lkan")'),
    (), "not a valid bounding box" );
is( eval('Giovanni::BoundingBox->new(STRING=>"-180W,-90E,180E,90N")'),
    (), "not a valid bounding box" );

# test the bounding box intersection
$bbox1 = Giovanni::BoundingBox->new( STRING => '160.0,10,150,20' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '175,-50.0,-160,15' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['175,10,-160,15'], 'both over dateline, one region' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '170,-5,150,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '140,-5,-170,5' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply(
    [ sort( map( $_->getString(), @intersections ) ) ],
    [ '140,-5,150,5', '170,-5,-170,5' ],
    'first box wraps around'
);

$bbox1 = Giovanni::BoundingBox->new( STRING => '170,-11,-171,10' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '175,-3,-160,4' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['175,-3,-171,4'], 'both cross 180 meridian' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '160,-80,-160,80' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-190,-5,170,5' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['160,-5,-160,5'],
    'both cross 180 meridian, weird seam for second bounding box' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '160,-80,-160,80' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '185,-5,-175,5' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['160,-5,-160,5'],
    'both cross 180 meridian, weird seam for second bounding box' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '160,-80,-160,80' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '170,-5,170,5' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['170,-5,170,5'], 'very thin box' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '-5,-5,5,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-10,-10,10,10' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['-5,-5,5,5'], 'inside' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '-5,-10,5,10' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-10,-3,10,3' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['-5,-3,5,3'], 'overlap' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '170,-10,-170,10' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-175,-10,-160,10' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['-175,-10,-170,10'],
    'first box over dateline, second box in western hemisphere' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '170,-10,-170,10' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '160,-10,175,10' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['170,-10,175,10'],
    'first box over dateline, second box in eastern hemisphere' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '160,-14,-140,23' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-150,-80,175,76' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply(
    [ sort( map( $_->getString(), @intersections ) ) ],
    [ '-150,-14,-140,23', '160,-14,175,23' ],
    'second box wraps around, but doesn\'t cross the date line'
);

$bbox1 = Giovanni::BoundingBox->new( STRING => '-180.0,-90,180.0,90' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-150,-80,175,76' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ sort( map( $_->getString(), @intersections ) ) ],
    ['-150,-80,175,76'], 'one box is the full globe' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '-180,-10,180,10' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-179,-40,180,40' );
@intersections = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['-179,-10,180,10'], 'both boxes end at 180' );

# Test intersection of more than 2 bounding boxes
$bbox1 = Giovanni::BoundingBox->new( STRING => '-5,-5,5,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-10,-10,10,10' );
$bbox3 = Giovanni::BoundingBox->new( STRING => '0,0,3,4' );
@intersections
    = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2, $bbox3 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['0,0,3,4'], 'three boxes' );

$bbox1 = Giovanni::BoundingBox->new( STRING => '10,-10,170,60' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-170,10,160,70' );
$bbox3 = Giovanni::BoundingBox->new( STRING => '150,-80,-160,80' );
@intersections
    = Giovanni::BoundingBox::getIntersection( $bbox1, $bbox2, $bbox3 );
is_deeply( [ map( $_->getString(), @intersections ) ],
    ['150,10,160,60'], 'three boxes with wrap around' );

# These tests make sure that the bounding box parser works.
$bbox1 = Giovanni::BoundingBox->new( STRING => '-20,-10,-4,-2' );
is( $bbox1->getPrettyString(),
    "20W, 10S, 4W, 2S",
    "All negative values bounding box"
);

$bbox1 = Giovanni::BoundingBox->new( STRING => '20,10,4,2' );
is( $bbox1->getPrettyString(),
    "20E, 10N, 4E, 2N",
    "All positive values bounding box"
);

$bbox1 = Giovanni::BoundingBox->new( STRING => '45.23,-1.345,50.2,12.94' );
is( $bbox1->getPrettyString(),
    "45.23E, 1.345S, 50.2E, 12.94N",
    "Floating point test for bounding box"
);

# These tests are for the isSameBox function
$bbox1 = Giovanni::BoundingBox->new( STRING => '-5,-5,5,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-5.0,-5.00,5.0000,5.0' );
ok( Giovanni::BoundingBox::isSameBox( $bbox1, $bbox2 ), "Same bounding box" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '-5,-5,5,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-5.0,-5.00,5.0010,5.0' );
ok( !Giovanni::BoundingBox::isSameBox( $bbox1, $bbox2 ),
    "Different bounding boxes" );

# Test canoncial longitude
is( Giovanni::BoundingBox::getCanonicalLongitude(-200.44),
    159.56, "Changed longitude" );
is( Giovanni::BoundingBox::getCanonicalLongitude(203.57),
    -156.43, "Changed longitude" );
is( Giovanni::BoundingBox::getCanonicalLongitude(0.34),
    0.34, "Unchanged longitude" );

# Test the canonical bounding box code
$bbox1 = Giovanni::BoundingBox->new( STRING => '-181,-5,5,79' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '179,-5,5,79' );
is( $bbox1->getCanonicalBbox()->getString(),
    $bbox2->getString(), "Canonical correct,change" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '170,-5,5,79' );
is( $bbox1->getCanonicalBbox()->getString(),
    $bbox1->getString(), "Canonical correct, no change" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '185,-5,195,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-175,-5,-165,5' );
is( $bbox1->getCanonicalBbox()->getString(),
    $bbox2->getString(), "Canonical correct,change" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '-185.5,-5,174.5,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-180,-5,180,5' );
is( $bbox1->getCanonicalBbox()->getString(),
    $bbox2->getString(), "Bounding box seam is not at 180/-180" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '185,-5,540,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-175,-5,180,5' );
is( $bbox1->getCanonicalBbox()->getString(),
    $bbox2->getString(), "Bounding box ends at 540" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '-175,-5,180,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-175,-5,180,5' );
is( $bbox1->getCanonicalBbox()->getString(),
    $bbox2->getString(), "Bounding box ends at 180" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '180,-5,190,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-180,-5,-170,5' );
is( $bbox1->getCanonicalBbox()->getString(),
    $bbox2->getString(), "Bounding box ends after 180" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '180,-5,-180,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-180,-5,180,5' );
is( $bbox1->getCanonicalBbox()->getString(),
    $bbox2->getString(), "Bounding box from 180 to -180" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '180,-5,-170,5' );
$bbox2 = Giovanni::BoundingBox->new( STRING => '-180,-5,-170,5' );
is( $bbox1->getCanonicalBbox()->getString(),
    $bbox2->getString(), "Bounding box starts at 180" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '-180,-90,90,180' );
ok( !$bbox1->crosses180(), "Does not cross 180" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '0,-90,90,10' );
ok( !$bbox1->crosses180(), "Does not cross 180" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '170,-90,90,-170' );
ok( $bbox1->crosses180(), "Crosses 180" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '-160,-90,-170,90' );
ok( $bbox1->crosses180(), "Crosses 180" );

$bbox1 = Giovanni::BoundingBox->new( STRING => '0,-90,185,90' );
ok( $bbox1->crosses180(), "Crosses 180" );

# Test the width and height
$bbox1 = Giovanni::BoundingBox->new( STRING => '90,-10,-90,-5' );
is( $bbox1->getWidth(),  180, "Correct width over 180" );
is( $bbox1->getHeight(), 5,   "Correct height" );
$bbox1 = Giovanni::BoundingBox->new( STRING => '-10,-90,30,90' );
is( $bbox1->getWidth(),  40,  "Correct width over 0" );
is( $bbox1->getHeight(), 180, "Correct height" );
$bbox1 = Giovanni::BoundingBox->new( STRING => '175,6,-180,7' );
is( $bbox1->getWidth(),  5, "Correct width on 180" );
is( $bbox1->getHeight(), 1, "Correct height" );
$bbox1 = Giovanni::BoundingBox->new( STRING => '10,6,20,7' );
is( $bbox1->getWidth(),  10, "Correct width" );
is( $bbox1->getHeight(), 1,  "Correct height" );
1;
