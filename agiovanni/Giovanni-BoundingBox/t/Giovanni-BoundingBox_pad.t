#$Id: Giovanni-BoundingBox_pad.t,v 1.1 2014/10/06 18:42:20 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-BoundingBox.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('Giovanni::BoundingBox') }

use strict;
use warnings;

my $bbox = Giovanni::BoundingBox->new( STRING => '-10,-10,10,10' );
is( $bbox->pad( '1', '1' )->getString(), '-11,-11,11,11', 'simple' );

$bbox = Giovanni::BoundingBox->new( STRING => '0,1,10,10' );
is( $bbox->pad( '1', '1' )->getString(), '-1,0,11,11', 'simple' );

$bbox = Giovanni::BoundingBox->new( STRING => '-125.5,-80.2,-120,-60' );
is( $bbox->pad( '5', '3' )->getString(), '-130.5,-83.2,-115,-57', 'simple' );

# near the 180 merridian
$bbox = Giovanni::BoundingBox->new( STRING => '-179.5,-10,10,10' );
is( $bbox->pad( '5', '10' )->getString(), '-180,-20,15,20', 'near -180' );

$bbox = Giovanni::BoundingBox->new( STRING => '-10,-10,178,10' );
is( $bbox->pad( '5', '2' )->getString(), '-15,-12,180,12', 'near 180' );

$bbox = Giovanni::BoundingBox->new( STRING => '-10,-90,10,89' );
is( $bbox->pad( '5', '2' )->getString(), '-15,-90,15,90', 'near 90N & 90S' );

# over the 180 merridian
$bbox = Giovanni::BoundingBox->new( STRING => '170,-10,-170,10' );
is( $bbox->pad( '5', '5' )->getString(), '165,-15,-165,15', 'over 180' );

$bbox = Giovanni::BoundingBox->new( STRING => '5,-10,-5,10' );
is( $bbox->pad( '5', '5' )->getString(),
    '-180,-15,180,15', 'either side of greenwich to global and over 180 meridian' );

# full bounding box
$bbox = Giovanni::BoundingBox->new( STRING => '-180,-90,180,90' );
is( $bbox->pad( '5', '5' )->getString(), '-180,-90,180,90', 'full globe' );

1;
