# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Plot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Giovanni::Plot') }

# Case of Title+Plot
my $plot = Giovanni::Plot->new();

# Case of Title+Plot+Legend
# Case of Title+Plot+Legend+Caption

__DATA__
P3
4 4
255
0  0  0   100 0  0       0  0  0    255   0 255 
0  0  0    0 255 175     0  0  0     0    0  0
0  0  0    0  0  0       0 15 175    0    0  0
255 0 255  0  0  0       0  0  0    255  255 255 
