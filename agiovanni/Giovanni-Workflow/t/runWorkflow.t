use Test::More tests => 8;
use File::Temp qw(tempdir);
use File::Path;
use FindBin qw($Bin);

# Find the runWorkflow.pl script
my $script = findScript("runWorkflow.pl");
ok( -r $script, "Found script" );

doSuccessfulTest(
    "http://giovanni.gsfc.nasa.gov/beta/giovanni/#service=StSc&starttime=2015-10-01T00:00:00Z&endtime=2015-10-01T00:59:59Z&bbox=-116.7187,21.211,-65.3906,53.5547&data=GPM_3IMERGHH_03_precipitationCal%2CGPM_3IMERGHHE_03_randomError&dataKeyword=GPM&portal=GIOVANNI&format=json",
    $script, "URL with portal"
);

# Pick a service that should work
doSuccessfulTest(
    "http://giovanni.gsfc.nasa.gov/giovanni/#service=TmAvMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T23:59:59Z&bbox=-180,-50,180,50&data=TRMM_3B42_Daily_7_precipitation&dataKeyword=TRMM_3B42",
    $script, "Simple"
);

# Test with unit conversion, a z-slice, and a shape
doSuccessfulTest(
    "http://giovanni.gsfc.nasa.gov/giovanni/#service=TmAvMp&starttime=2004-01-01T00:00:00Z&endtime=2004-01-01T23:59:59Z&shape=tl_2014_us_state/shp_55&bbox=-114.816591,31.332176999999998,-109.045223,37.004259999999995&data=AIRX3STD_006_Temperature_A(z%3D250%3Aunits%3DC)&dataKeyword=AIRS",
    $script, "unit conversion, z-slice, and shape"
);

# Run a test that should fail.
my $dir = tempdir( CLEANUP => 1 );

# A URL for a variable that doesn't exist
$url
    = "http://giovanni.gsfc.nasa.gov/giovanni/#service=TmAvMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T23:59:59Z&bbox=-180,-50,180,50&data=NOT_A_VARIABLE";
@cmd = ( $script, "--url", $url, "--out", $dir );
$ret = system(@cmd);
ok( $ret != 0, "Command failed for invalid variable, which is correct" )
    or die;

sub doSuccessfulTest {
    my ( $url, $script, $test ) = @_;

    my $dir = tempdir( CLEANUP => 1 );
    @cmd = ( $script, "--url", $url, "--out", $dir );

    my $ret = system(@cmd);

    is( $ret, 0, "Command returned 0" ) or die;

    # make sure the output log was created
    ok( -f "$dir/session/resultset/result/make.log",
        "$test workflow finished" );

}

sub findScript {
    my ($scriptName) = @_;

    # see if this is just next door (Christine's eclipse configuration)
    my $script = "../scripts/$scriptName";

    unless ( -f $script ) {

        # see if we can find the script relative to our current location
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }

    return $script;
}
