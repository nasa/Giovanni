# Use modules
use strict;
use Test::More tests => 4;
use Giovanni::Testing;
use Giovanni::Algorithm::Wrapper;
BEGIN { use_ok('Giovanni::Algorithm::Wrapper::Test'); }

# Find path for $program
my $program = 'g4_area_avg_scatter.pl';
my ($script_path) = Giovanni::Testing::find_script_paths($program);
ok( ( -e $script_path ), "Find script path for $program" )
    or die "No point going further";

# The actual call to run the test
# Note that diff-exclude is used to exclude potentially spurious differences
# In real life, we will want to take the out of the diff-exclude, once we settle
# on title formats and contents
my ( $out_nc, $diff_rc ) = run_test(
    'program'      => $script_path,
    'comparison'   => "minus",
    'z-slice'      => [ 850, 850 ],
    'temp_res'     => 'daily',
    'jobs'         => 5,
    'name'         => 'Area Averaged Difference Time Series',
    'diff-exclude' => [
        qw(/title /plot_title /plot_subtitle /temporal_resolution)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" )
    or die "No point diffing files";
is( $diff_rc, '', "Outcome of diff" );
exit(0);
__DATA__
netcdf scrubbed.AIRX3STD_006_Temperature_A.20090117 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_A = 24 ;
	lat = 2 ;
	lon = 2 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:long_name = "Air Temperature (Daytime/Ascending)" ;
		AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
		AIRX3STD_006_Temperature_A:units = "K" ;
	float TempPrsLvls_A(TempPrsLvls_A) ;
		TempPrsLvls_A:long_name = "Pressure" ;
		TempPrsLvls_A:format = "F7.2" ;
		TempPrsLvls_A:standard_name = "stdpressurelev" ;
		TempPrsLvls_A:units = "hPa" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
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
		:start_time = "2009-01-17T00:00:00Z" ;
		:end_time = "2009-01-17T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Nov 15 00:14:54 2016: ncks -d lon,-147.5,-146.5 -d lat,47.5,48.5 scrubbed.AIRX3STD_006_Temperature_A.20090117.nc scrubbed.AIRX3STD_006_Temperature_A.20090117.nc" ;
data:

 AIRX3STD_006_Temperature_A =
  _, _,
  _, _,
  278.125, 278.5625,
  278.1875, 278.4375,
  275.1875, 275.5,
  275.25, 275.6875,
  267.0625, 267.875,
  268.125, 268.4375,
  261.0625, 262.25,
  262.625, 263.3125,
  252.5938, 254.25,
  254.0938, 255.3438,
  242.8125, 244.0938,
  243.5312, 244.9688,
  236, 234.6875,
  235.125, 235.0938,
  234.7812, 233.5938,
  233.75, 233.3438,
  232.125, 232.125,
  231.4688, 231.2812,
  224.625, 224.2812,
  224.5312, 223.9375,
  215.875, 214.625,
  215.7812, 214.875,
  215.0312, 214.1562,
  214.9375, 214.25,
  216.9688, 216.5312,
  216.9062, 216.375,
  218.0625, 217.8125,
  218.5938, 218.125,
  220.6562, 220.25,
  220.6562, 220.4375,
  222.7812, 222.375,
  222.25, 221.9688,
  226.4688, 226.3438,
  225.6875, 225.25,
  231.8438, 231.9375,
  230.8125, 230.4375,
  238.375, 238.5,
  237.6875, 237.5,
  247.25, 247.0938,
  247.2812, 247.1875,
  253.5312, 252.875,
  253.8125, 253.1875,
  253.375, 252.6875,
  253.125, 252.625,
  248.2812, 248.0312,
  247.3438, 247.5312 ;

 TempPrsLvls_A = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009017 ;

 lat = 47.5, 48.5 ;

 lat_bnds =
  47, 48,
  48, 49 ;

 lon = -147.5, -146.5 ;

 lon_bnds =
  -148, -147,
  -147, -146 ;

 time = 1232150400 ;

 time_bnds =
  1232150400, 1232236799 ;
}
netcdf scrubbed.AIRX3STD_006_Temperature_A.20090118 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_A = 24 ;
	lat = 2 ;
	lon = 2 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:long_name = "Air Temperature (Daytime/Ascending)" ;
		AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
		AIRX3STD_006_Temperature_A:units = "K" ;
	float TempPrsLvls_A(TempPrsLvls_A) ;
		TempPrsLvls_A:long_name = "Pressure" ;
		TempPrsLvls_A:format = "F7.2" ;
		TempPrsLvls_A:standard_name = "stdpressurelev" ;
		TempPrsLvls_A:units = "hPa" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
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
		:start_time = "2009-01-18T00:00:00Z" ;
		:end_time = "2009-01-18T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Nov 15 00:15:14 2016: ncks -d lon,-147.5,-146.5 -d lat,47.5,48.5 scrubbed.AIRX3STD_006_Temperature_A.20090118.nc scrubbed.AIRX3STD_006_Temperature_A.20090118.nc" ;
data:

 AIRX3STD_006_Temperature_A =
  279.25, 279.75,
  278.375, 280.1875,
  274.625, 274.5,
  274.25, 275.75,
  272.5, 271.875,
  272.4375, 274,
  263.625, 263.5625,
  264.4375, 265.4375,
  254.125, 254.9688,
  254.5, 255.9375,
  244.9062, 245.6875,
  244.8438, 246.4688,
  236.875, 237.3438,
  237.2812, 237.5938,
  232.2812, 232.375,
  233.1875, 233.125,
  232.4688, 232.7812,
  232.6875, 233.75,
  231.7812, 231.9062,
  231.5, 232.3125,
  226.5, 226.125,
  226.1562, 225.25,
  219.7188, 219.0625,
  219.9375, 218.25,
  218.0938, 217.5312,
  218.1875, 217.1562,
  218.1562, 217.5,
  218.2812, 217.875,
  217.6875, 217.1875,
  217.4062, 217.25,
  218.1562, 217.6875,
  217.9375, 217.4062,
  219.5, 219,
  219.4375, 218.5938,
  223.8438, 223.375,
  223.8438, 222.6875,
  230.8125, 230.5312,
  230.8438, 230.2812,
  239.25, 239.1875,
  238.8125, 239.4062,
  247.4375, 247.5938,
  246.5938, 246.75,
  249.5, 249.0312,
  248.75, 248.25,
  248.625, 248.1562,
  248.0938, 247.625,
  244.875, 244.875,
  244.6875, 244.4375 ;

 TempPrsLvls_A = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009018 ;

 lat = 47.5, 48.5 ;

 lat_bnds =
  47, 48,
  48, 49 ;

 lon = -147.5, -146.5 ;

 lon_bnds =
  -148, -147,
  -147, -146 ;

 time = 1232236800 ;

 time_bnds =
  1232236800, 1232323199 ;
}
netcdf scrubbed.AIRX3STD_006_Temperature_A.20090119 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_A = 24 ;
	lat = 2 ;
	lon = 2 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:long_name = "Air Temperature (Daytime/Ascending)" ;
		AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
		AIRX3STD_006_Temperature_A:units = "K" ;
	float TempPrsLvls_A(TempPrsLvls_A) ;
		TempPrsLvls_A:long_name = "Pressure" ;
		TempPrsLvls_A:format = "F7.2" ;
		TempPrsLvls_A:standard_name = "stdpressurelev" ;
		TempPrsLvls_A:units = "hPa" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
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
		:start_time = "2009-01-19T00:00:00Z" ;
		:end_time = "2009-01-19T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Nov 15 00:15:26 2016: ncks -d lon,-147.5,-146.5 -d lat,47.5,48.5 scrubbed.AIRX3STD_006_Temperature_A.20090119.nc scrubbed.AIRX3STD_006_Temperature_A.20090119.nc" ;
data:

 AIRX3STD_006_Temperature_A =
  277.25, 277.4375,
  277.5625, 276.5625,
  272.25, 272.75,
  272.5625, 271.4375,
  269.625, 270.4375,
  269.6875, 269.4375,
  262.9375, 263.1875,
  262.4375, 263.0625,
  253.8438, 253.9688,
  253.6875, 254.4062,
  244.1875, 244.1875,
  243.375, 243.625,
  234.5625, 234.3438,
  233.75, 233.5625,
  230.6562, 231.0625,
  231.0938, 231.2812,
  229.5, 230.5938,
  229.8438, 230.875,
  229.3438, 230.375,
  229.5312, 230.4062,
  226.0312, 226.25,
  226.2188, 226.4375,
  218.6875, 218.0625,
  219.375, 218.7188,
  217.125, 216.5625,
  217.7812, 216.8125,
  217.4688, 216.9375,
  217.5625, 216.7812,
  217.1562, 216.5312,
  216.9062, 216.5625,
  217.75, 217.0312,
  218.0312, 217.25,
  219.125, 218.375,
  219.6875, 218.5938,
  222.8125, 222.3125,
  223.5, 222.625,
  229.0938, 228.25,
  229.9688, 228.5,
  236.5938, 235.5,
  236.9688, 235.25,
  241.375, 240.625,
  240.0938, 239.7812,
  241.0312, 240.6562,
  239.0625, 239.5938,
  240.6875, 240.625,
  238.8125, 239.5,
  240.9688, 241.1562,
  239.8438, 240.4062 ;

 TempPrsLvls_A = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009019 ;

 lat = 47.5, 48.5 ;

 lat_bnds =
  47, 48,
  48, 49 ;

 lon = -147.5, -146.5 ;

 lon_bnds =
  -148, -147,
  -147, -146 ;

 time = 1232323200 ;

 time_bnds =
  1232323200, 1232409599 ;
}
netcdf scrubbed.AIRX3STD_006_Temperature_D.20090117 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_D = 24 ;
	lat = 2 ;
	lon = 2 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STD_006_Temperature_D(time, TempPrsLvls_D, lat, lon) ;
		AIRX3STD_006_Temperature_D:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_D:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_D:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_D:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_D:product_version = "006" ;
		AIRX3STD_006_Temperature_D:long_name = "Air Temperature (Nighttime/Descending)" ;
		AIRX3STD_006_Temperature_D:coordinates = "time TempPrsLvls_D lat lon" ;
		AIRX3STD_006_Temperature_D:units = "K" ;
	float TempPrsLvls_D(TempPrsLvls_D) ;
		TempPrsLvls_D:long_name = "Pressure" ;
		TempPrsLvls_D:format = "F7.2" ;
		TempPrsLvls_D:standard_name = "stdpressurelev" ;
		TempPrsLvls_D:units = "hPa" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
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
		:start_time = "2009-01-17T00:00:00Z" ;
		:end_time = "2009-01-17T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Nov 15 00:15:52 2016: ncks -d lon,-147.5,-146.5 -d lat,47.5,48.5 scrubbed.AIRX3STD_006_Temperature_D.20090117.nc scrubbed.AIRX3STD_006_Temperature_D.20090117.nc" ;
data:

 AIRX3STD_006_Temperature_D =
  _, _,
  _, _,
  280.5, 281.125,
  280.4375, 280.1875,
  276.6875, 276.8125,
  276.6875, 275.375,
  267.75, 269.6875,
  268.0625, 269,
  260.375, 263.625,
  260.5, 262.8125,
  251.5312, 254.9375,
  251.1875, 253.9062,
  239.5938, 241.9062,
  239.5312, 241.6562,
  232.9375, 232.6562,
  232.5938, 232.9375,
  234.4062, 234.3125,
  233.7812, 234.0625,
  233.9688, 234.3125,
  233.9375, 233.9062,
  226, 225.9062,
  226.5938, 225.5312,
  214.5312, 213.4062,
  214.6562, 213.7188,
  214, 213.1562,
  214.0938, 213.5312,
  215.9688, 215.5312,
  216.2188, 215.5312,
  218.5, 218.3438,
  218.6875, 218.2188,
  221.3125, 220.9062,
  221.5625, 220.9688,
  222.75, 222.1562,
  222.9375, 222.2188,
  225.4375, 224.9062,
  225.0938, 224.4375,
  229.875, 230.125,
  229.0312, 228.7812,
  236.2812, 236.7812,
  234.9062, 235,
  245.3125, 245,
  244.5312, 244.2188,
  252.9375, 252.375,
  252.9062, 252.25,
  252.6875, 252.125,
  252.6562, 252.1875,
  246.4062, 245.9375,
  246.0312, 245.9062 ;

 TempPrsLvls_D = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009017 ;

 lat = 47.5, 48.5 ;

 lat_bnds =
  47, 48,
  48, 49 ;

 lon = -147.5, -146.5 ;

 lon_bnds =
  -148, -147,
  -147, -146 ;

 time = 1232150400 ;

 time_bnds =
  1232150400, 1232236799 ;
}
netcdf scrubbed.AIRX3STD_006_Temperature_D.20090118 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_D = 24 ;
	lat = 2 ;
	lon = 2 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STD_006_Temperature_D(time, TempPrsLvls_D, lat, lon) ;
		AIRX3STD_006_Temperature_D:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_D:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_D:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_D:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_D:product_version = "006" ;
		AIRX3STD_006_Temperature_D:long_name = "Air Temperature (Nighttime/Descending)" ;
		AIRX3STD_006_Temperature_D:coordinates = "time TempPrsLvls_D lat lon" ;
		AIRX3STD_006_Temperature_D:units = "K" ;
	float TempPrsLvls_D(TempPrsLvls_D) ;
		TempPrsLvls_D:long_name = "Pressure" ;
		TempPrsLvls_D:format = "F7.2" ;
		TempPrsLvls_D:standard_name = "stdpressurelev" ;
		TempPrsLvls_D:units = "hPa" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
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
		:start_time = "2009-01-18T00:00:00Z" ;
		:end_time = "2009-01-18T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Nov 15 00:16:06 2016: ncks -d lon,-147.5,-146.5 -d lat,47.5,48.5 scrubbed.AIRX3STD_006_Temperature_D.20090118.nc scrubbed.AIRX3STD_006_Temperature_D.20090118.nc" ;
data:

 AIRX3STD_006_Temperature_D =
  _, _,
  _, _,
  276.625, 277.3125,
  276.1875, 277.25,
  273.0625, 273.8125,
  273.25, 274.125,
  265.375, 264.9375,
  265.875, 265.5625,
  255.8438, 255.875,
  256.625, 256.625,
  246, 247.375,
  246.6875, 248.1562,
  237.375, 239.0625,
  238.0312, 240.25,
  235.2812, 234.5,
  235.1875, 234.75,
  235.8125, 235.3125,
  235.375, 234.625,
  233.3438, 233.8125,
  233.2188, 232.5938,
  226, 225.6562,
  225.9062, 225.4375,
  218.5938, 217.5,
  218.3438, 217.625,
  218.0938, 216.8438,
  218.0312, 216.7812,
  217.7812, 217.2188,
  217.75, 217.0625,
  218.4062, 218.3438,
  218.2188, 217.6875,
  218.9375, 218.375,
  218.9062, 218.625,
  219.8125, 218.9688,
  219.875, 219.7188,
  224.625, 223.9375,
  224.5938, 223.8438,
  230.9375, 231.3125,
  230.3125, 229.875,
  239.2188, 239.9375,
  238.2188, 238.1875,
  250.0312, 249.3125,
  249.625, 249.6562,
  251.5312, 250.4062,
  252.0312, 251.0312,
  249.1562, 248.1875,
  249.8125, 248.5312,
  243.375, 243,
  243.625, 243.0938 ;

 TempPrsLvls_D = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009018 ;

 lat = 47.5, 48.5 ;

 lat_bnds =
  47, 48,
  48, 49 ;

 lon = -147.5, -146.5 ;

 lon_bnds =
  -148, -147,
  -147, -146 ;

 time = 1232236800 ;

 time_bnds =
  1232236800, 1232323199 ;
}
netcdf scrubbed.AIRX3STD_006_Temperature_D.20090119 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_D = 24 ;
	lat = 2 ;
	lon = 2 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STD_006_Temperature_D(time, TempPrsLvls_D, lat, lon) ;
		AIRX3STD_006_Temperature_D:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_D:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_D:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_D:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_D:product_version = "006" ;
		AIRX3STD_006_Temperature_D:long_name = "Air Temperature (Nighttime/Descending)" ;
		AIRX3STD_006_Temperature_D:coordinates = "time TempPrsLvls_D lat lon" ;
		AIRX3STD_006_Temperature_D:units = "K" ;
	float TempPrsLvls_D(TempPrsLvls_D) ;
		TempPrsLvls_D:long_name = "Pressure" ;
		TempPrsLvls_D:format = "F7.2" ;
		TempPrsLvls_D:standard_name = "stdpressurelev" ;
		TempPrsLvls_D:units = "hPa" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
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
		:start_time = "2009-01-19T00:00:00Z" ;
		:end_time = "2009-01-19T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Nov 15 00:16:17 2016: ncks -d lon,-147.5,-146.5 -d lat,47.5,48.5 scrubbed.AIRX3STD_006_Temperature_D.20090119.nc scrubbed.AIRX3STD_006_Temperature_D.20090119.nc" ;
data:

 AIRX3STD_006_Temperature_D =
  277.1875, 277.9375,
  277.5625, 277.125,
  271.875, 272.5625,
  272.375, 272.0625,
  269.625, 269.9375,
  270.3125, 269.8125,
  262.6875, 263.0625,
  263.25, 263.1875,
  254.125, 254.9688,
  254.4688, 254.9688,
  244, 245.1875,
  244.6562, 245.2812,
  233.375, 234.5,
  234.1562, 235,
  231.2188, 231.9375,
  231.2188, 232.0312,
  232.1562, 232.9688,
  231.7812, 232.4688,
  231.8438, 232.2812,
  231.4688, 231.7188,
  227.2188, 226.625,
  226.9062, 226.4375,
  219.25, 218.25,
  219.3125, 218.4375,
  217.9062, 217.3438,
  218.4688, 217.75,
  217.9062, 217.375,
  218.0938, 217.6875,
  218.2812, 217.5625,
  218.2188, 217.6562,
  218.4062, 218.0625,
  218.1875, 217.75,
  218.875, 218.7812,
  218.8438, 218.375,
  223.2188, 223.2188,
  223.0938, 222.5,
  230.0625, 230.0625,
  229.6875, 229.125,
  239.1875, 238.8125,
  238.5312, 237.9375,
  247.8125, 245.6875,
  247.1562, 246,
  247.4688, 245.375,
  247.125, 246.25,
  245.0625, 243.2812,
  244.8125, 244.0625,
  240.875, 239.9688,
  240.6875, 240.2812 ;

 TempPrsLvls_D = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009019 ;

 lat = 47.5, 48.5 ;

 lat_bnds =
  47, 48,
  48, 49 ;

 lon = -147.5, -146.5 ;

 lon_bnds =
  -148, -147,
  -147, -146 ;

 time = 1232323200 ;

 time_bnds =
  1232323200, 1232409599 ;
}
netcdf ref {
dimensions:
	time = UNLIMITED ; // (3 currently)
	nv = 2 ;
variables:
	float x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa(time) ;
		x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa:_FillValue = -9999.f ;
		x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa:standard_name = "air_temperature" ;
		x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa:quantity_type = "Air Temperature" ;
		x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa:product_short_name = "AIRX3STD" ;
		x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa:product_version = "006" ;
		x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa:long_name = "Air Temperature (Daytime/Ascending)" ;
		x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa:coordinates = "time" ;
		x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa:units = "K" ;
		x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa:cell_methods = "lat, lon: mean TempPrsLvls_A: mean" ;
	float TempPrsLvls_A ;
		TempPrsLvls_A:long_name = "Pressure" ;
		TempPrsLvls_A:format = "F7.2" ;
		TempPrsLvls_A:standard_name = "stdpressurelev" ;
		TempPrsLvls_A:units = "hPa" ;
		TempPrsLvls_A:cell_methods = "TempPrsLvls_A: mean" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
	int time(time) ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;
	float y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa(time) ;
		y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa:_FillValue = -9999.f ;
		y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa:standard_name = "air_temperature" ;
		y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa:quantity_type = "Air Temperature" ;
		y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa:product_short_name = "AIRX3STD" ;
		y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa:product_version = "006" ;
		y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa:long_name = "Air Temperature (Nighttime/Descending)" ;
		y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa:coordinates = "time" ;
		y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa:units = "K" ;
		y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa:cell_methods = "lat, lon: mean TempPrsLvls_D: mean" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2009-01-17T00:00:00Z" ;
		:end_time = "2009-01-19T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:nco_input_file_number = 1 ;
		:nco_input_file_list = "/var/scratch/rstrub/tmp/gWwTQkQE4C/file_AIRX3STD_006_Temperature_A_1_avg.nc" ;
		:geospatial_lat_min = "47" ;
		:geospatial_lon_min = "-148" ;
		:geospatial_lat_max = "49" ;
		:geospatial_lon_max = "-146" ;
		:userstartdate = "2009-01-17T00:00:00Z" ;
		:userenddate = "2009-01-19T23:59:59Z" ;
data:

 x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_850hPa = 275.4056, 272.6981, 
    269.7991 ;

 TempPrsLvls_A = 850 ;

 dataday = 2009017, 2009018, 2009019 ;

 time = 1232150400, 1232236800, 1232323200 ;

 time_bnds =
  1232150400, 1232236799,
  1232236800, 1232323199,
  1232323200, 1232409599 ;

 y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_850hPa = 276.3941, 273.5613, 
    269.9205 ;
}
