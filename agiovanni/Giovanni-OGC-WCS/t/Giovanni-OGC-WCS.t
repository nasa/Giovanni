# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-OGC-WMS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use URI;
use URI::QueryParam;
use Test::More tests => 3;
BEGIN { use_ok('Giovanni::OGC::WCS') }

# Define WCS getCoverage request
my $ogcRequest
   = "http://dev.gesdisc.eosdis.nasa.gov/giovanni/daac-bin/wcs_ag4?service=WCS&version=1.0.0&request=GetCoverage&coverage=Time-Averaged.MOD08_D3_6_Deep_Blue_Aerosol_Optical_Depth_550_Land_Mean&crs=epsg:4326&bbox=-180,-90,180,90&width=360&height=180&format=netCDF&time=2004-01-01T00:00:00Z/2004-01-03T23:59:59Z";

# Test Case: genearate a map file for getCoverage request

# Reference
#my $smRequest
#   = "http://dev.gesdisc.eosdis.nasa.gov/giovanni/daac-bin/service_manager.pl?service=TmAvMp&data=MOD08_D3_6_Deep_Blue_Aerosol_Optical_Depth_550_Land_Mean&starttime=2004-01-01T00:00:00Z&endtime=2004-01-03T23:59:59Z&bbox=-180,-90,180,90&portal=GIOVANNI&format=xml";

my $url     = URI->new($ogcRequest);
my $wcsHash = {};
$wcsHash->{'baseUrl'} = $url->host;
$wcsHash->{'options'} = $url->query_form_hash;
my @timeString = split( "/", $wcsHash->{"time"} );
my $startTime  = $timeString[0];
my $endTime    = defined $timeString[1] ? $timeString[1] : $timeString[0];
delete $wcsHash->{'time'};
$wcsHash->{'starttime'} = $startTime;
$wcsHash->{'endtime'} = $endTime;
my @tString = split( /\./, $wcsHash->{'coverage'} );
my $data = $tString[1];
my $service = $tString[0] =~ m/Time-Averaged/i ? "TmAvMp" : $tString[0];
$wcsHash->{'data'} = $service;
$wcsHash->{'data'} = $data;
my $ogcWcs = Giovanni::OGC::WCS::getCoverage($wcsHash);;

ok ( -f $ogcWcs, "generation of coverage map file");


# Test Case: generate a map file for getCapabilities or describeCoverage request
$ogcRequest = "http://dev.gesdisc.eosdis.nasa.gov/giovanni/daac-bin/wcs_ag4?service=WCS&version=1.0.0&request=GetCapabilities";
my $resultDir = $GIOVANNI::SESSION_LOCATION;
my $wcsCapabilities = File::Temp->new(
        TEMPLATE => 'agwcs' . '_XXXX',
        DIR      => $resultDir,
        SUFFIX   => '.map'
    );
my $mapResult = Giovanni::OGC::WCS::generateMapFile($wcsCapabilities);
is( $mapReqult, 1, "Map file is generated for getMap or describeCoverage");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

