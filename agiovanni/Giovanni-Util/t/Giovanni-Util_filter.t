# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl bbox.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::Util') }

my @arr = ( 1, 2, 3, 4, 5, 6, 7 );

my @out = Giovanni::Util::filterArray( \@arr, [ 0, 1, 0, 1, 0, 1, 0 ] );
is_deeply( \@out, [ 2, 4, 6 ], "Got just the even numbers" );

@out = Giovanni::Util::filterArray( \@arr, [ 1, 1, 1, 1, 1, 1, 1 ] );
is_deeply( \@out, [ 1, 2, 3, 4, 5, 6, 7 ], "Got everything" );

