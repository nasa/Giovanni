# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl bbox.t'

#########################

use Test::More tests => 2;
BEGIN { use_ok('Giovanni::Util') }

my @bbox = Giovanni::Util::parse_bbox('-102.3,-32.1, 24.3, 32.');
is( $bbox[0], -102.3, 'parse_bbox' );
exit(0);
