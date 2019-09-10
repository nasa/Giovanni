##
## Tests that code works with 3D variables
##


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-SeasonalTimeSeries.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
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
my @ncFiles = ();
for my $cdl ( @{$cdls} ) {
    my ($netcdf) = ( $cdl =~ /^netcdf\s*(\S*)/ );
    $netcdf = "$dir/$netcdf.nc";
    push( @ncFiles, $netcdf );
    Giovanni::Data::NcFile::write_netcdf_file( $netcdf, $cdl );
}

my $correctOut = pop(@ncFiles);
my @inFiles = @ncFiles;

# create a file with all these files
my $inFilesFile = "$dir/inFiles.txt";
open( FILE, ">", $inFilesFile ) or die "Unable to create file: $inFilesFile";
for my $file (@inFiles) {
    print FILE $file . "\n";
}
close(FILE);

my $bbox  = "-89.2969,29.1328,-78.75,35.9766";
my $outNc = "$dir/out.nc";

# build the command
my $cmd
    = "$script -b '$bbox' -f $inFilesFile -o $outNc "
    . "-v AIRX3STM_006_Temperature_D -g 'MONTH=01' "
    . "-z 'TempPrsLvls_D=70hPa'";

my $ret = system($cmd);
is( $ret, 0, "Command returned zero: $cmd" ) or die;
ok( -e $outNc, "Output file exists" ) or die;

$ret = Giovanni::Data::NcFile::diff_netcdf_files( $outNc, $correctOut );
ok( $ret eq '', "Output file is correct: $ret" );

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
netcdf scrubbed.AIRX3STM_006_Temperature_D.20100101_sub {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_D = 2 ;
	lat = 10 ;
	lon = 14 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STM_006_Temperature_D(time, TempPrsLvls_D, lat, lon) ;
		AIRX3STM_006_Temperature_D:_FillValue = -9999.f ;
		AIRX3STM_006_Temperature_D:standard_name = "air_temperature" ;
		AIRX3STM_006_Temperature_D:quantity_type = "Air Temperature" ;
		AIRX3STM_006_Temperature_D:product_short_name = "AIRX3STM" ;
		AIRX3STM_006_Temperature_D:product_version = "006" ;
		AIRX3STM_006_Temperature_D:long_name = "Air Temperature (Nighttime/Descending)" ;
		AIRX3STM_006_Temperature_D:coordinates = "time TempPrsLvls_D lat lon" ;
		AIRX3STM_006_Temperature_D:units = "K" ;
	float TempPrsLvls_D(TempPrsLvls_D) ;
		TempPrsLvls_D:standard_name = "Pressure" ;
		TempPrsLvls_D:long_name = "Pressure Levels Temperature Profile, nighttime (descending) node" ;
		TempPrsLvls_D:positive = "down" ;
		TempPrsLvls_D:_CoordinateAxisType = "GeoZ" ;
		TempPrsLvls_D:units = "hPa" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:format = "F5.1" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:format = "F6.1" ;
		lon:missing_value = -9999.f ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	int time(time) ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2010-01-01T00:00:00Z" ;
		:end_time = "2010-01-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Mar 21 20:58:51 2017: ncks -O -d lon,-90.,-76. -d lat,27.,37. -d TempPrsLvls_D,35.,75. scrubbed.AIRX3STM_006_Temperature_D.20100101.nc scrubbed.AIRX3STM_006_Temperature_D.20100101_sub.nc" ;
data:

 AIRX3STM_006_Temperature_D =
  203.1719, 202.8789, 202.5742, 202.7266, 202.6406, 202.4492, 202.3906, 
    202.125, 202.1836, 202.0664, 202.3008, 201.9336, 201.5, 201.7539,
  204.3203, 204.0234, 203.7734, 203.8359, 203.9922, 203.7812, 203.8047, 
    203.5781, 203.3984, 203.5391, 203.6953, 203.5273, 203.2188, 203.2227,
  205.1797, 205.332, 205.1133, 205.0352, 205.0547, 205.1211, 204.9531, 
    204.8164, 204.8047, 204.793, 204.7266, 204.9414, 204.6719, 204.5,
  206.2891, 206.4141, 206.2109, 206.0977, 206.3438, 205.9609, 205.9141, 
    206.1367, 206.2148, 206.1758, 206.0469, 206.3438, 205.9883, 205.7734,
  207.293, 207.2891, 207.4023, 207.0234, 207.4531, 207.3594, 207.2422, 
    207.5039, 207.7188, 207.7031, 207.3945, 207.4453, 207.4688, 207.0508,
  208.4766, 208.5352, 208.5859, 208.3633, 208.4609, 208.6758, 208.5625, 
    208.6914, 208.8672, 208.793, 208.7656, 208.5664, 208.4688, 208.4023,
  209.6406, 209.6016, 209.668, 209.5234, 209.6133, 209.8984, 209.9375, 
    210.0469, 210.1328, 209.9688, 209.8516, 209.8125, 209.6914, 209.5664,
  210.7266, 210.6602, 210.7266, 210.5742, 210.5703, 210.9141, 211.0547, 
    211.1367, 211.1719, 211.1406, 210.9844, 210.6797, 210.6875, 210.793,
  211.7305, 211.7266, 211.7656, 211.7109, 211.6602, 211.9883, 212.25, 
    212.2383, 212.3984, 212.3711, 212.1484, 211.8789, 211.9453, 211.8242,
  212.7852, 212.7461, 212.9609, 212.9062, 212.8789, 213.0547, 213.1992, 
    213.1523, 213.3945, 213.543, 213.3555, 213.2969, 213.1133, 212.9609,
  208.7969, 208.7695, 208.707, 208.8125, 208.6875, 208.7031, 208.5859, 
    208.5195, 208.4062, 208.2148, 208.2656, 208.0117, 207.7383, 208.0039,
  209.4219, 209.3086, 209.0391, 209.1328, 209.2344, 209.2969, 209.1719, 
    209.0742, 209.043, 208.9844, 208.9922, 208.8281, 208.7266, 208.8164,
  209.6211, 209.6797, 209.7031, 209.9492, 209.9336, 209.8047, 209.7227, 
    209.7578, 209.8281, 209.6133, 209.5742, 209.5312, 209.3594, 209.3281,
  210.125, 210.1094, 210.2188, 210.3945, 210.8281, 210.4727, 210.3789, 
    210.4414, 210.4648, 210.3086, 210.1172, 210.3008, 210.1055, 209.9219,
  210.6289, 210.668, 210.6289, 210.7109, 211.1602, 211.0781, 210.832, 
    210.918, 211.2188, 211.0391, 210.8398, 210.8711, 210.8789, 210.5859,
  211.1211, 211.332, 211.2656, 211.2852, 211.4531, 211.668, 211.5547, 
    211.6758, 211.8047, 211.6445, 211.4531, 211.4062, 211.4102, 211.3672,
  211.6211, 211.7539, 211.7461, 211.7383, 211.7461, 211.9805, 212.0039, 
    212.0977, 212.4414, 212.0781, 212.0273, 212.0898, 212.1094, 212.0508,
  212.2031, 212.2109, 212.3203, 212.3047, 212.3438, 212.6523, 212.707, 
    212.6914, 212.7422, 212.793, 212.8125, 212.5898, 212.6719, 212.7188,
  212.7773, 212.7148, 212.8398, 212.8594, 212.8086, 212.9766, 213.0703, 
    213.0352, 213.2734, 213.3828, 213.3438, 213.3438, 213.3633, 213.1914,
  213.2734, 213.1875, 213.2188, 213.2812, 213.332, 213.3047, 213.4023, 
    213.4492, 213.7344, 213.8594, 213.9375, 214.0547, 213.8945, 213.9023 ;

 TempPrsLvls_D = 70, 50 ;

 datamonth = 201001 ;

 lat = 27.5, 28.5, 29.5, 30.5, 31.5, 32.5, 33.5, 34.5, 35.5, 36.5 ;

 lat_bnds =
  27, 28,
  28, 29,
  29, 30,
  30, 31,
  31, 32,
  32, 33,
  33, 34,
  34, 35,
  35, 36,
  36, 37 ;

 lon = -89.5, -88.5, -87.5, -86.5, -85.5, -84.5, -83.5, -82.5, -81.5, -80.5, 
    -79.5, -78.5, -77.5, -76.5 ;

 lon_bnds =
  -90, -89,
  -89, -88,
  -88, -87,
  -87, -86,
  -86, -85,
  -85, -84,
  -84, -83,
  -83, -82,
  -82, -81,
  -81, -80,
  -80, -79,
  -79, -78,
  -78, -77,
  -77, -76 ;

 time = 1262304000 ;

 time_bnds =
  1262304000, 1264982399 ;
}
netcdf scrubbed.AIRX3STM_006_Temperature_D.20110101_sub {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_D = 2 ;
	lat = 10 ;
	lon = 14 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STM_006_Temperature_D(time, TempPrsLvls_D, lat, lon) ;
		AIRX3STM_006_Temperature_D:_FillValue = -9999.f ;
		AIRX3STM_006_Temperature_D:standard_name = "air_temperature" ;
		AIRX3STM_006_Temperature_D:quantity_type = "Air Temperature" ;
		AIRX3STM_006_Temperature_D:product_short_name = "AIRX3STM" ;
		AIRX3STM_006_Temperature_D:product_version = "006" ;
		AIRX3STM_006_Temperature_D:long_name = "Air Temperature (Nighttime/Descending)" ;
		AIRX3STM_006_Temperature_D:coordinates = "time TempPrsLvls_D lat lon" ;
		AIRX3STM_006_Temperature_D:units = "K" ;
	float TempPrsLvls_D(TempPrsLvls_D) ;
		TempPrsLvls_D:standard_name = "Pressure" ;
		TempPrsLvls_D:long_name = "Pressure Levels Temperature Profile, nighttime (descending) node" ;
		TempPrsLvls_D:positive = "down" ;
		TempPrsLvls_D:_CoordinateAxisType = "GeoZ" ;
		TempPrsLvls_D:units = "hPa" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:format = "F5.1" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:format = "F6.1" ;
		lon:missing_value = -9999.f ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	int time(time) ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2011-01-01T00:00:00Z" ;
		:end_time = "2011-01-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Mar 21 20:58:45 2017: ncks -O -d lon,-90.,-76. -d lat,27.,37. -d TempPrsLvls_D,35.,75. scrubbed.AIRX3STM_006_Temperature_D.20110101.nc scrubbed.AIRX3STM_006_Temperature_D.20110101_sub.nc" ;
data:

 AIRX3STM_006_Temperature_D =
  201.3594, 201.3828, 201.2109, 201.0938, 201.1875, 201.1758, 201.1953, 
    200.9492, 200.8086, 200.7383, 200.9062, 200.7539, 200.6172, 200.5273,
  202.2031, 202.2695, 202.2617, 202.0195, 202.2305, 202.1289, 202.0156, 
    201.8477, 201.5742, 201.6328, 201.7031, 201.5781, 201.5117, 201.4961,
  203.0078, 203.1484, 203.1641, 203.0625, 203.1445, 203.1992, 203.1914, 
    202.8281, 202.7695, 202.625, 202.6055, 202.6445, 202.625, 202.4883,
  203.9492, 204.0312, 204.0547, 204.1367, 204.2148, 204.0195, 204.0039, 
    203.9961, 203.9375, 203.9453, 203.7695, 203.793, 203.5781, 203.5469,
  204.9492, 205.0195, 205.1094, 205.1523, 205.0859, 205.2188, 205.1562, 
    205.0547, 205.1406, 205.2266, 204.9688, 204.918, 204.8164, 204.6602,
  206.0547, 206.2109, 206.3242, 206.3359, 206.3125, 206.3711, 206.3359, 
    206.1602, 206.2539, 206.2656, 206.2188, 205.9961, 206.0273, 205.7734,
  207.2344, 207.3047, 207.3789, 207.3477, 207.3828, 207.4141, 207.3633, 
    207.2344, 207.1758, 207.1875, 207.1953, 207.1406, 207.1836, 206.9688,
  208.3438, 208.3125, 208.3242, 208.3359, 208.3398, 208.332, 208.4531, 
    208.3398, 208.2812, 208.1914, 208.2227, 208.1016, 208.25, 208.082,
  209.3633, 209.3242, 209.3359, 209.3438, 209.3516, 209.4922, 209.6016, 
    209.4961, 209.4883, 209.3086, 209.1836, 209.1055, 209.0234, 209.0273,
  210.25, 210.2969, 210.3672, 210.5391, 210.4805, 210.668, 210.6055, 
    210.5664, 210.7461, 210.6211, 210.2344, 210.1602, 209.8633, 209.8516,
  206.4883, 206.5352, 206.4297, 206.5, 206.6328, 206.4688, 206.5195, 
    206.3867, 206.3594, 206.3867, 206.4219, 206.2734, 206.1445, 206.1367,
  207.0742, 207.043, 207.0547, 207.1094, 207.2617, 207.207, 207.1328, 
    207.0781, 206.9102, 206.918, 206.9844, 206.918, 206.7617, 206.6836,
  207.6328, 207.6523, 207.7148, 207.6719, 207.832, 207.9219, 207.7773, 
    207.6562, 207.6914, 207.5898, 207.5898, 207.5508, 207.4766, 207.3477,
  208.2227, 208.3789, 208.3125, 208.4023, 208.5078, 208.3867, 208.3594, 
    208.3203, 208.3867, 208.3242, 208.2539, 208.2266, 208.0625, 208.0469,
  208.8008, 208.8516, 208.9609, 208.9727, 208.9453, 208.9961, 208.9414, 
    208.832, 208.9844, 208.9961, 208.8789, 208.8398, 208.7539, 208.6836,
  209.1758, 209.4492, 209.5703, 209.6016, 209.6172, 209.6406, 209.5859, 
    209.3672, 209.4023, 209.6211, 209.5742, 209.4258, 209.5547, 209.3672,
  209.8164, 209.9141, 210.1211, 210.1133, 210.2227, 210.2188, 210.1758, 
    210.0273, 209.8125, 210.0039, 210.0352, 210.0391, 210.043, 209.9805,
  210.4141, 210.418, 210.5508, 210.5625, 210.6445, 210.7188, 210.7656, 
    210.6758, 210.7109, 210.5938, 210.5781, 210.5312, 210.5898, 210.5586,
  210.9727, 211.043, 211.1328, 211.0859, 211.1602, 211.2969, 211.3672, 
    211.3672, 211.4258, 211.2852, 211.0273, 211.0781, 211.0781, 211.1367,
  211.4414, 211.4414, 211.5703, 211.7109, 211.7773, 211.9922, 211.9492, 
    211.9648, 212.0938, 211.957, 211.7031, 211.6211, 211.5273, 211.6797 ;

 TempPrsLvls_D = 70, 50 ;

 datamonth = 201101 ;

 lat = 27.5, 28.5, 29.5, 30.5, 31.5, 32.5, 33.5, 34.5, 35.5, 36.5 ;

 lat_bnds =
  27, 28,
  28, 29,
  29, 30,
  30, 31,
  31, 32,
  32, 33,
  33, 34,
  34, 35,
  35, 36,
  36, 37 ;

 lon = -89.5, -88.5, -87.5, -86.5, -85.5, -84.5, -83.5, -82.5, -81.5, -80.5, 
    -79.5, -78.5, -77.5, -76.5 ;

 lon_bnds =
  -90, -89,
  -89, -88,
  -88, -87,
  -87, -86,
  -86, -85,
  -85, -84,
  -84, -83,
  -83, -82,
  -82, -81,
  -81, -80,
  -80, -79,
  -79, -78,
  -78, -77,
  -77, -76 ;

 time = 1293840000 ;

 time_bnds =
  1293840000, 1296518399 ;
}
netcdf g4.ints.AIRX3STM_006_Temperature_D.70hPa.20100101-20111231.MONTH_01.89W_29N_78W_35N {
dimensions:
	time = UNLIMITED ; // (2 currently)
	TempPrsLvls_D = 1 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	int datayear(time) ;
		datayear:long_name = "Data year" ;
	float AIRX3STM_006_Temperature_D(time, TempPrsLvls_D) ;
		AIRX3STM_006_Temperature_D:_FillValue = -9999.f ;
		AIRX3STM_006_Temperature_D:standard_name = "air_temperature" ;
		AIRX3STM_006_Temperature_D:quantity_type = "Air Temperature" ;
		AIRX3STM_006_Temperature_D:product_short_name = "AIRX3STM" ;
		AIRX3STM_006_Temperature_D:product_version = "006" ;
		AIRX3STM_006_Temperature_D:long_name = "Air Temperature (Nighttime/Descending)" ;
		AIRX3STM_006_Temperature_D:units = "K" ;
		AIRX3STM_006_Temperature_D:cell_methods = "lat, lon: mean" ;
		AIRX3STM_006_Temperature_D:group_type = "MONTH" ;
		AIRX3STM_006_Temperature_D:group_value = "January" ;
		AIRX3STM_006_Temperature_D:coordinates = "time" ;
	float TempPrsLvls_D(TempPrsLvls_D) ;
		TempPrsLvls_D:standard_name = "Pressure" ;
		TempPrsLvls_D:long_name = "Pressure Levels Temperature Profile, nighttime (descending) node" ;
		TempPrsLvls_D:positive = "down" ;
		TempPrsLvls_D:_CoordinateAxisType = "GeoZ" ;
		TempPrsLvls_D:units = "hPa" ;
	double lat_bnds(latv) ;
		lat_bnds:units = "degrees_north" ;
		lat_bnds:cell_methods = "lat: mean" ;
	double lon_bnds(lonv) ;
		lon_bnds:units = "degrees_east" ;
		lon_bnds:cell_methods = "lon: mean" ;
	int time(time) ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:start_time = "2010-01-01T00:00:00Z" ;
		:geospatial_lat_max = "35.5" ;
		:geospatial_lat_min = "29.5" ;
		:geospatial_lon_max = "-79.5" ;
		:geospatial_lon_min = "-88.5" ;
		:end_time = "2010-01-31T23:59:59Z" ;
		:history = "Tue Mar 21 21:02:30 2017: ncatted -a plot_hint_time_axis_values,global,c,c,1262304000,1270080000,1277942400,1285891200,1293840000,1301616000,1309478400,1317427200,1325376000 -a plot_hint_time_axis_labels,global,c,c,Jan,Apr,Jul,Oct,Jan~C~2011,Apr,Jul,Oct,Jan~C~2012 -a plot_hint_time_axis_minor,global,c,c,1264982400,1267401600,1272672000,1275350400,1280620800,1283299200,1288569600,1291161600,1296518400,1298937600,1304208000,1306886400,1312156800,1314835200,1320105600,1322697600 /var/giovanni/session/A5163350-0E79-11E7-8EA5-E35E803A1811/A8A1E596-0E79-11E7-8674-215F803A1811/A8A2BD40-0E79-11E7-8674-215F803A1811/g4.ints.AIRX3STM_006_Temperature_D.70hPa.20100101-20111231.MONTH_01.89W_29N_78W_35N.nc" ;
data:

 datayear = 2010, 2011 ;

 AIRX3STM_006_Temperature_D =
  208.506,
  206.1496 ;

 TempPrsLvls_D = 70 ;

 lat_bnds = 31.9555128114038, 32.9555128114038 ;

 lon_bnds = -84.5, -83.5 ;

 time = 1262304000, 1293840000 ;

 time_bnds =
  1262304000, 1264982399,
  1293840000, 1296518399 ;
}


