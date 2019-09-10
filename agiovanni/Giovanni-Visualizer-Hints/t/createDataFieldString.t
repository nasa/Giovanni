#$Id: createDataFieldString.t,v 1.1 2014/03/28 16:00:08 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 SYNOPIS
This tests the createDataFieldString code
=cut

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Giovanni::Visualizer::Hints') }

is( Giovanni::Visualizer::Hints::createDataFieldString(
        LONG_NAME           => "Aerosol Optical Depth 550 nm (Ocean-only)",
        TIME_RESOLUTION     => "Daily",
        SPATIAL_RESOLUTION  => "0.5",
        PLATFORM_INSTRUMENT => "SeaWiFS",
        PRODUCT_SHORTNAME   => "SWDB_L3M05",
        VERSION             => "004",
        UNITS               => "1"
    ),
    "Aerosol Optical Depth 550 nm (Ocean-only) Daily 0.5 [SeaWiFS SWDB_L3M05 v004]",
    "James Johnson's example"
);

is( Giovanni::Visualizer::Hints::createDataFieldString(
        LONG_NAME           => "Aerosol Optical Depth 550 nm (Ocean-only)",
        TIME_RESOLUTION     => "Daily",
        SPATIAL_RESOLUTION  => "0.5",
        PLATFORM_INSTRUMENT => "SeaWiFS",
        PRODUCT_SHORTNAME   => "SWDB_L3M05",
        VERSION             => "004",
        UNITS               => "mm"
    ),
    "Aerosol Optical Depth 550 nm (Ocean-only) Daily 0.5 [SeaWiFS SWDB_L3M05 v004] mm",
    "example with units"
);

is( Giovanni::Visualizer::Hints::createDataFieldString(
        LONG_NAME           => "Aerosol Optical Depth 550 nm (Ocean-only)",
        TIME_RESOLUTION     => "Daily",
        SPATIAL_RESOLUTION  => "0.5",
        PLATFORM_INSTRUMENT => "SeaWiFS",
        PRODUCT_SHORTNAME   => "SWDB_L3M05",
        VERSION             => "004",
        UNITS               => "1",
        THIRD_DIM_VALUE     => "1000",
        THIRD_DIM_UNITS     => "hPa",
    ),
    "Aerosol Optical Depth 550 nm (Ocean-only) Daily 0.5 \@1000hPa [SeaWiFS SWDB_L3M05 v004]",
    "example with 3rd dimension"
);

1;
