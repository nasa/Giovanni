
# Use modules
use Test::More tests => 3;
use Giovanni::PostProcess;
BEGIN { use_ok('Giovanni::PostProcess'); }

# Check title reformatting:
my ( $plot_title, $plot_subtitle )
    = Giovanni::PostProcess::wrap_titles(
    'Area-Averaged Time Series of Soil Moisture Content Top 1 Meter (0-100 cm) hourly 0.125 deg. [NLDAS Model NLDAS_NOAH0125_H v002] kg/m^2 over 1979-02-01 00Z - 1979-02-02 23Z, Region 77.168W, 38.8103N, 76.7285W, 39.3376N'
    );
ok( $plot_title,    "wrap - title: $plot_title" );
ok( $plot_subtitle, "wrap - subtitle: $plot_subtitle" );
