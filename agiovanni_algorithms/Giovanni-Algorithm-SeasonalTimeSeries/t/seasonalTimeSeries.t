#$Id: seasonalTimeSeries.t,v 1.1 2015/04/17 18:34:22 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-SeasonalTimeSeries.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::Algorithm::SeasonalTimeSeries') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Giovanni::Data::NcFile;
use File::Temp qw/tempdir/;
use FindBin qw($Bin);

# find the executible
my $script = findScript("seasonalTimeSeries.pl");
if ( !( -e $script ) ) {
    die "Unable to find seasonalTimeSeries.pl: $script";
}

# create a temporary working directory
my $dir = tempdir( "working_XXXX", CLEANUP => 1, TMPDIR => 1 );

# read in the CDL at the end of this file
my $cdls = Giovanni::Data::NcFile::read_cdl_data_block();

# write out the netcdf to files in the temp directory.
my @inFiles = ();
for my $cdl ( @{$cdls} ) {
    my ($netcdf) = ( $cdl =~ /^netcdf\s*(\S*)/ );
    $netcdf = "$dir/$netcdf.nc";
    push( @inFiles, $netcdf );
    Giovanni::Data::NcFile::write_netcdf_file( $netcdf, $cdl );
}

# create a file with all these files
my $inFilesFile = "$dir/inFiles.txt";
open( FILE, ">", $inFilesFile ) or die "Unable to create file: $inFilesFile";
for my $file (@inFiles) {
    print FILE $file . "\n";
}
close(FILE);

my $bbox  = "-0.5,-0.5,0.5,0.5";
my $outNc = "$dir/out.nc";

# build the command
my $cmd = "$script -b '$bbox' -f $inFilesFile -o $outNc "
    . "-v TRMM_3B43_007_precipitation -g 'SEASON=DJF'";

my $ret = system($cmd);
is( $ret, 0, "Command returned zero: $cmd" );
ok( -e $outNc, "Output file exists" );

sub findScript {
    my ($scriptName) = @_;

    # see if this is just next door (Christine's eclipse configuration)
    $script = "../scripts/$scriptName";

    if ( !( -e $script ) ) {

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

__DATA__
netcdf scrubbed.TRMM_3B43_007_precipitation.19991201000000_sub {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "1999-12-01T00:00:00Z" ;
        :end_time = "1999-12-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Tue Apr 14 18:44:03 2015: ncks -d lat,-1.,1. -d lon,-1.,1. scrubbed.TRMM_3B43_007_precipitation.19991201000000.nc scrubbed.TRMM_3B43_007_precipitation.19991201000000_sub.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.1892339, 0.2311694, 0.2045968, 0.1708502, 0.1219433, 0.1177328, 
    0.1453036, 0.1465992,
  0.1602016, 0.1808871, 0.1784274, 0.1508502, 0.1228745, 0.1078543, 
    0.1173279, 0.1118624,
  0.1123387, 0.1405645, 0.1183065, 0.1359109, 0.1286639, 0.1150607, 
    0.1002834, 0.11583,
  0.1000403, 0.09129033, 0.09012098, 0.1169231, 0.1314979, 0.1104048, 
    0.0968421, 0.1307692,
  0.1291532, 0.1003629, 0.08274195, 0.07457491, 0.09769229, 0.1095142, 
    0.1106073, 0.1191093,
  0.1494355, 0.1067339, 0.1157661, 0.1015385, 0.07396761, 0.08805666, 
    0.1082591, 0.08943321,
  0.09580646, 0.0910484, 0.1499597, 0.1874899, 0.1338056, 0.1006883, 
    0.08906883, 0.08311742,
  0.1050403, 0.1451613, 0.1421371, 0.1683806, 0.1434008, 0.1123887, 
    0.09275305, 0.07846155 ;

 datamonth = 199912 ;

 lat = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 lon = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 time = 944006400 ;
}
netcdf scrubbed.TRMM_3B43_007_precipitation.20000101000000_sub {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2000-01-01T00:00:00Z" ;
        :end_time = "2000-01-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Tue Apr 14 18:44:03 2015: ncks -d lat,-1.,1. -d lon,-1.,1. scrubbed.TRMM_3B43_007_precipitation.20000101000000.nc scrubbed.TRMM_3B43_007_precipitation.20000101000000_sub.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.3080645, 0.3435887, 0.3085483, 0.2733468, 0.217379, 0.2697983, 0.3862904, 
    0.3791129,
  0.454879, 0.4642338, 0.3720565, 0.3397177, 0.2212903, 0.2528226, 0.30625, 
    0.3396774,
  0.4679031, 0.5302823, 0.436129, 0.3459677, 0.2766935, 0.2818952, 0.24375, 
    0.2740322,
  0.415, 0.4319758, 0.4670161, 0.449758, 0.3569758, 0.3359275, 0.3266532, 
    0.3299192,
  0.3113306, 0.2699999, 0.2908466, 0.3535484, 0.3407661, 0.423871, 0.446613, 
    0.3374598,
  0.3060484, 0.2337903, 0.2666532, 0.3616531, 0.2404032, 0.3619758, 
    0.3384273, 0.2852016,
  0.3112097, 0.2909274, 0.323629, 0.3829033, 0.2418952, 0.2747984, 0.2793951, 
    0.2177016,
  0.2595565, 0.2590726, 0.3179435, 0.3974597, 0.3018145, 0.2952419, 
    0.2020161, 0.2156855 ;

 datamonth = 200001 ;

 lat = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 lon = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 time = 946684800 ;
}
netcdf scrubbed.TRMM_3B43_007_precipitation.20000201000000_sub {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2000-02-01T00:00:00Z" ;
        :end_time = "2000-02-29T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Tue Apr 14 18:44:03 2015: ncks -d lat,-1.,1. -d lon,-1.,1. scrubbed.TRMM_3B43_007_precipitation.20000201000000.nc scrubbed.TRMM_3B43_007_precipitation.20000201000000_sub.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.2255172, 0.2540086, 0.2246983, 0.2517672, 0.2571552, 0.27875, 0.2999569, 
    0.3128017,
  0.2498706, 0.25125, 0.2339224, 0.2505603, 0.2553879, 0.3003017, 0.2465517, 
    0.2607759,
  0.2076293, 0.2767241, 0.3012069, 0.3206034, 0.2932327, 0.3049138, 
    0.2615086, 0.2470259,
  0.2383189, 0.2596983, 0.2922845, 0.2863362, 0.2959914, 0.2846121, 
    0.2310345, 0.2215086,
  0.2150862, 0.2093104, 0.2608621, 0.2684914, 0.2659052, 0.2195258, 
    0.1959914, 0.2138793,
  0.1986207, 0.1998707, 0.2469827, 0.2576293, 0.1635345, 0.153319, 0.1757328, 
    0.2153879,
  0.2246552, 0.2406035, 0.2655604, 0.2953017, 0.2184052, 0.2199569, 0.217069, 
    0.225431,
  0.1797845, 0.1865948, 0.2350862, 0.2848276, 0.2038793, 0.19125, 0.2361207, 
    0.2487931 ;

 datamonth = 200002 ;

 lat = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 lon = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 time = 949363200 ;
}
netcdf scrubbed.TRMM_3B43_007_precipitation.20001201000000_sub {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2000-12-01T00:00:00Z" ;
        :end_time = "2000-12-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Tue Apr 14 18:44:03 2015: ncks -d lat,-1.,1. -d lon,-1.,1. scrubbed.TRMM_3B43_007_precipitation.20001201000000.nc scrubbed.TRMM_3B43_007_precipitation.20001201000000_sub.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.02056452, 0.01665322, 0.02032258, 0.02879032, 0.03270161, 0.05060484, 
    0.03846774, 0.04612903,
  0.008911289, 0.02020161, 0.02403225, 0.04040323, 0.04012096, 0.04169355, 
    0.05987903, 0.07020162,
  0.02004032, 0.03576613, 0.04241935, 0.06379032, 0.03346774, 0.04120968, 
    0.04971774, 0.07729839,
  0.05891129, 0.06427418, 0.06217742, 0.07116935, 0.05568548, 0.07338709, 
    0.07274194, 0.08475805,
  0.0714113, 0.08209678, 0.108629, 0.1299597, 0.1235887, 0.1215322, 
    0.1062097, 0.1075403,
  0.1070564, 0.14375, 0.186371, 0.1869758, 0.1590323, 0.1452419, 0.1848387, 
    0.1695968,
  0.1421371, 0.1706452, 0.179879, 0.2252822, 0.1702016, 0.1989113, 0.2099194, 
    0.152379,
  0.1904033, 0.1746371, 0.2215323, 0.2491532, 0.1708871, 0.2117742, 
    0.2095968, 0.1749194 ;

 datamonth = 200012 ;

 lat = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 lon = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 time = 975628800 ;
}
netcdf scrubbed.TRMM_3B43_007_precipitation.20010101000000_sub {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2001-01-01T00:00:00Z" ;
        :end_time = "2001-01-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Tue Apr 14 18:44:03 2015: ncks -d lat,-1.,1. -d lon,-1.,1. scrubbed.TRMM_3B43_007_precipitation.20010101000000.nc scrubbed.TRMM_3B43_007_precipitation.20010101000000_sub.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.07342741, 0.0819758, 0.07270162, 0.08096773, 0.08423387, 0.07318549, 
    0.07012098, 0.08790323,
  0.1062097, 0.1122581, 0.1141129, 0.1180242, 0.09431452, 0.09903226, 
    0.08278227, 0.09487905,
  0.1687097, 0.1885081, 0.168629, 0.1245565, 0.1037097, 0.1119355, 0.1306855, 
    0.1422178,
  0.1964516, 0.1899596, 0.1746371, 0.1610887, 0.1784274, 0.154879, 0.2215726, 
    0.1543145,
  0.2175403, 0.2362903, 0.2609274, 0.209879, 0.2077016, 0.1854838, 0.1954839, 
    0.1869355,
  0.2525806, 0.2489919, 0.2288709, 0.1991935, 0.2180242, 0.1833871, 
    0.1495968, 0.1756048,
  0.1992339, 0.2182661, 0.2081452, 0.1830242, 0.1972581, 0.1962903, 
    0.1789516, 0.1914113,
  0.1934677, 0.1697983, 0.1737097, 0.1582661, 0.1779032, 0.158629, 0.1821774, 
    0.1714113 ;

 datamonth = 200101 ;

 lat = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 lon = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 time = 978307200 ;
}
netcdf scrubbed.TRMM_3B43_007_precipitation.20010201000000_sub {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2001-02-01T00:00:00Z" ;
        :end_time = "2001-02-28T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Tue Apr 14 18:44:04 2015: ncks -d lat,-1.,1. -d lon,-1.,1. scrubbed.TRMM_3B43_007_precipitation.20010201000000.nc scrubbed.TRMM_3B43_007_precipitation.20010201000000_sub.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.1359821, 0.1574554, 0.1342411, 0.1225446, 0.1566072, 0.1378572, 
    0.1289286, 0.1134375,
  0.04624999, 0.05040178, 0.07294642, 0.1066071, 0.1546875, 0.1458929, 
    0.147366, 0.1298214,
  0.03209821, 0.031875, 0.06517857, 0.07513393, 0.1211161, 0.1196875, 
    0.1467411, 0.1986607,
  0.05495536, 0.05334821, 0.05709821, 0.06839286, 0.06129464, 0.1453571, 
    0.1688839, 0.1669196,
  0.1165179, 0.1062054, 0.09808035, 0.0842857, 0.07705359, 0.1651786, 
    0.1232589, 0.05736607,
  0.08209821, 0.09821428, 0.08683038, 0.08080357, 0.1386161, 0.08870535, 
    0.070625, 0.1038393,
  0.06392856, 0.07959821, 0.1132589, 0.1023661, 0.1553125, 0.06790178, 
    0.07892858, 0.1314732,
  0.08852679, 0.1271429, 0.1607143, 0.1461161, 0.1466964, 0.06183035, 
    0.08111607, 0.1152232 ;

 datamonth = 200102 ;

 lat = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 lon = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 time = 980985600 ;
}
netcdf scrubbed.TRMM_3B43_007_precipitation.20011201000000_sub {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2001-12-01T00:00:00Z" ;
        :end_time = "2001-12-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Tue Apr 14 18:44:04 2015: ncks -d lat,-1.,1. -d lon,-1.,1. scrubbed.TRMM_3B43_007_precipitation.20011201000000.nc scrubbed.TRMM_3B43_007_precipitation.20011201000000_sub.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.0004435484, 0.0007258065, 0.003629032, 0.002016129, 0.001290323, 
    0.001814516, 0.001854839, 0.007298387,
  0, 0.001854839, 0.002943548, 0.001814516, 0.0005241935, 0.0007661289, 
    0.002056451, 0.003266129,
  4.032258e-05, 0.0008064516, 0.00157258, 0.001209677, 0.0005645161, 
    0.0006048387, 0.001612903, 0.007137096,
  0.0006048387, 0.0006854839, 0.002379032, 0.001814516, 0.001491935, 
    0.003346774, 0.006048386, 0.008185484,
  0.03870967, 0.006370967, 0.0009677419, 0.001693548, 0.00483871, 
    0.009677419, 0.03258064, 0.02112903,
  0.01096774, 0.0006854839, 0.00641129, 0.002701613, 0.003790322, 0.01463709, 
    0.0225, 0.02395161,
  0.003104839, 0.003548387, 0.002943548, 0.002903226, 0.008951612, 
    0.01818549, 0.02173387, 0.02084678,
  0.006975806, 0.01125, 0.01620967, 0.007459676, 0.01068548, 0.03725807, 
    0.02903226, 0.02584678 ;

 datamonth = 200112 ;

 lat = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 lon = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 time = 1007164800 ;
}
netcdf scrubbed.TRMM_3B43_007_precipitation.20020101000000_sub {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2002-01-01T00:00:00Z" ;
        :end_time = "2002-01-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Tue Apr 14 18:44:04 2015: ncks -d lat,-1.,1. -d lon,-1.,1. scrubbed.TRMM_3B43_007_precipitation.20020101000000.nc scrubbed.TRMM_3B43_007_precipitation.20020101000000_sub.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.1059756, 0.08373983, 0.1129675, 0.1348988, 0.1371255, 0.05412955, 
    0.03761134, 0.04327935,
  0.06922764, 0.05703253, 0.06825203, 0.08890687, 0.06663968, 0.07797572, 
    0.07789472, 0.07246964,
  0.0756504, 0.1314228, 0.2068293, 0.2063967, 0.08368421, 0.05963562, 
    0.08987852, 0.08720649,
  0.08768293, 0.1617886, 0.2384146, 0.205749, 0.1205263, 0.07514172, 
    0.1036437, 0.11,
  0.1154065, 0.1487398, 0.2028455, 0.1452632, 0.1384616, 0.1054656, 
    0.1137652, 0.1267207,
  0.1869106, 0.1647561, 0.1381377, 0.2601619, 0.2144939, 0.2124697, 
    0.1651822, 0.15417,
  0.3119105, 0.2628862, 0.2797571, 0.3284615, 0.2634008, 0.3010121, 
    0.2479352, 0.2265587,
  0.2788211, 0.3169512, 0.3815789, 0.4200405, 0.404494, 0.3141295, 0.2909716, 
    0.2998785 ;

 datamonth = 200201 ;

 lat = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 lon = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 time = 1009843200 ;
}
netcdf scrubbed.TRMM_3B43_007_precipitation.20020201000000_sub {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2002-02-01T00:00:00Z" ;
        :end_time = "2002-02-28T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Tue Apr 14 18:44:04 2015: ncks -d lat,-1.,1. -d lon,-1.,1. scrubbed.TRMM_3B43_007_precipitation.20020201000000.nc scrubbed.TRMM_3B43_007_precipitation.20020201000000_sub.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.04504464, 0.05459822, 0.09267856, 0.1163393, 0.1805803, 0.2036161, 
    0.2165625, 0.2254464,
  0.0478125, 0.06955357, 0.1249553, 0.1413393, 0.1817411, 0.2219196, 
    0.2019643, 0.1947768,
  0.04758928, 0.1161161, 0.1423214, 0.1820982, 0.1936607, 0.2202678, 
    0.1819643, 0.1528572,
  0.05254465, 0.12, 0.1425, 0.1526786, 0.1728125, 0.1882143, 0.1299107, 
    0.1421875,
  0.04977679, 0.09508927, 0.1464732, 0.1270536, 0.1455357, 0.1778125, 
    0.1637946, 0.2263393,
  0.05053572, 0.08214285, 0.1181696, 0.1106697, 0.1202232, 0.1612947, 
    0.1619196, 0.2341072,
  0.1020089, 0.1484821, 0.1585268, 0.1564286, 0.1370089, 0.1517411, 
    0.1860714, 0.2228125,
  0.1510268, 0.166875, 0.2312054, 0.2285268, 0.2245089, 0.1805804, 0.2036161, 
    0.2517411 ;

 datamonth = 200202 ;

 lat = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 lon = -0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875 ;

 time = 1012521600 ;
}
