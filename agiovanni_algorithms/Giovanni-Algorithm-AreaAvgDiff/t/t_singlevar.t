# Use modules
use strict;
use Test::More tests => 4;
use Giovanni::Testing;
use Giovanni::Algorithm::Wrapper;
BEGIN { use_ok('Giovanni::Algorithm::Wrapper::Test'); }

# Find path for $program
my $program = 'g4_area_avg_diff_time_series.pl';
my ($script_path) = Giovanni::Testing::find_script_paths($program);
ok( ( -e $script_path ), "Find script path for $program" )
    or die "No point going further";

# The actual call to run the test
# Note that diff-exclude is used to exclude potentially spurious differences
# In real life, we will want to take the out of the diff-exclude, once we settle
# on title formats and contents
my ( $out_nc, $diff_rc ) = run_test(
    'program'      => $script_path,
    'z-slice'      => [850],
    'name'         => 'Area Averaged Time Series',
    'time-axis'    => 1,
    'jobs'         => 5,
    'diff-exclude' => [
        qw(/title /plot_title /plot_subtitle /temporal_resolution)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" )
    or die "No point diffing files";
is( $diff_rc, '', "Outcome of diff" );
exit(0);
__DATA__
netcdf ss.scrubbed.AIRX3STD_006_Temperature_A.20090117 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    TempPrsLvls_A = 24 ;
    lat = 2 ;
    lon = 2 ;
variables:
    float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
        AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
        AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
        AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
        AIRX3STD_006_Temperature_A:units = "K" ;
        AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
        AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
        AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
        AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
        AIRX3STD_006_Temperature_A:product_version = "006" ;
        AIRX3STD_006_Temperature_A:Serializable = "True" ;
    float TempPrsLvls_A(TempPrsLvls_A) ;
        TempPrsLvls_A:standard_name = "Pressure" ;
        TempPrsLvls_A:long_name = "Pressure Levels Temperature Profile, daytime (ascending) node" ;
        TempPrsLvls_A:units = "hPa" ;
        TempPrsLvls_A:positive = "down" ;
        TempPrsLvls_A:_CoordinateAxisType = "GeoZ" ;
    int dataday(time) ;
        dataday:standard_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:_FillValue = -9999.f ;
        lat:long_name = "Latitude" ;
        lat:missing_value = -9999.f ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:_FillValue = -9999.f ;
        lon:long_name = "Longitude" ;
        lon:missing_value = -9999.f ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2009-01-17T00:00:00Z" ;
        :end_time = "2009-01-17T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :NCO = "4.2.1" ;
        :history = "Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_A.20090117.nc ss.scrubbed.AIRX3STD_006_Temperature_A.20090117.nc" ;
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

 lon = -147.5, -146.5 ;

 time = 1232150400 ;
}
netcdf ss.scrubbed.AIRX3STD_006_Temperature_A.20090118 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    TempPrsLvls_A = 24 ;
    lat = 2 ;
    lon = 2 ;
variables:
    float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
        AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
        AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
        AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
        AIRX3STD_006_Temperature_A:units = "K" ;
        AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
        AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
        AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
        AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
        AIRX3STD_006_Temperature_A:product_version = "006" ;
        AIRX3STD_006_Temperature_A:Serializable = "True" ;
    float TempPrsLvls_A(TempPrsLvls_A) ;
        TempPrsLvls_A:standard_name = "Pressure" ;
        TempPrsLvls_A:long_name = "Pressure Levels Temperature Profile, daytime (ascending) node" ;
        TempPrsLvls_A:units = "hPa" ;
        TempPrsLvls_A:positive = "down" ;
        TempPrsLvls_A:_CoordinateAxisType = "GeoZ" ;
    int dataday(time) ;
        dataday:standard_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:_FillValue = -9999.f ;
        lat:long_name = "Latitude" ;
        lat:missing_value = -9999.f ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:_FillValue = -9999.f ;
        lon:long_name = "Longitude" ;
        lon:missing_value = -9999.f ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2009-01-18T00:00:00Z" ;
        :end_time = "2009-01-18T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :NCO = "4.2.1" ;
        :history = "Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_A.20090118.nc ss.scrubbed.AIRX3STD_006_Temperature_A.20090118.nc" ;
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

 lon = -147.5, -146.5 ;

 time = 1232236800 ;
}
netcdf ss.scrubbed.AIRX3STD_006_Temperature_A.20090119 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    TempPrsLvls_A = 24 ;
    lat = 2 ;
    lon = 2 ;
variables:
    float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
        AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
        AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
        AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
        AIRX3STD_006_Temperature_A:units = "K" ;
        AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
        AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
        AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
        AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
        AIRX3STD_006_Temperature_A:product_version = "006" ;
        AIRX3STD_006_Temperature_A:Serializable = "True" ;
    float TempPrsLvls_A(TempPrsLvls_A) ;
        TempPrsLvls_A:standard_name = "Pressure" ;
        TempPrsLvls_A:long_name = "Pressure Levels Temperature Profile, daytime (ascending) node" ;
        TempPrsLvls_A:units = "hPa" ;
        TempPrsLvls_A:positive = "down" ;
        TempPrsLvls_A:_CoordinateAxisType = "GeoZ" ;
    int dataday(time) ;
        dataday:standard_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:_FillValue = -9999.f ;
        lat:long_name = "Latitude" ;
        lat:missing_value = -9999.f ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:_FillValue = -9999.f ;
        lon:long_name = "Longitude" ;
        lon:missing_value = -9999.f ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2009-01-19T00:00:00Z" ;
        :end_time = "2009-01-19T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :NCO = "4.2.1" ;
        :history = "Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_A.20090119.nc ss.scrubbed.AIRX3STD_006_Temperature_A.20090119.nc" ;
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

 lon = -147.5, -146.5 ;

 time = 1232323200 ;
}
netcdf testAlgorithm.AIRX3STD_006_Temperature_A.850hPa.20090117-20090119.148W_47N_146W_49N {
dimensions:
	time = UNLIMITED ; // (3 currently)
variables:
	float AIRX3STD_006_Temperature_A(time) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_A:units = "K" ;
		AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
		AIRX3STD_006_Temperature_A:coordinates = "time" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:Serializable = "True" ;
		AIRX3STD_006_Temperature_A:cell_methods = "lat,lon: mean" ;
	int count_AIRX3STD_006_Temperature_A(time) ;
		count_AIRX3STD_006_Temperature_A:_FillValue = -999 ;
		count_AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		count_AIRX3STD_006_Temperature_A:long_name = "count of Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
		count_AIRX3STD_006_Temperature_A:units = "1" ;
		count_AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
		count_AIRX3STD_006_Temperature_A:coordinates = "time" ;
		count_AIRX3STD_006_Temperature_A:quantity_type = "count of Air Temperature" ;
		count_AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		count_AIRX3STD_006_Temperature_A:product_version = "006" ;
		count_AIRX3STD_006_Temperature_A:Serializable = "True" ;
	float max_AIRX3STD_006_Temperature_A(time) ;
		max_AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		max_AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		max_AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
		max_AIRX3STD_006_Temperature_A:units = "K" ;
		max_AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
		max_AIRX3STD_006_Temperature_A:coordinates = "time" ;
		max_AIRX3STD_006_Temperature_A:quantity_type = "maximum of Air Temperature" ;
		max_AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		max_AIRX3STD_006_Temperature_A:product_version = "006" ;
		max_AIRX3STD_006_Temperature_A:Serializable = "True" ;
		max_AIRX3STD_006_Temperature_A:cell_methods = "lat,lon: maximum" ;
	float min_AIRX3STD_006_Temperature_A(time) ;
		min_AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		min_AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		min_AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
		min_AIRX3STD_006_Temperature_A:units = "K" ;
		min_AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
		min_AIRX3STD_006_Temperature_A:coordinates = "time" ;
		min_AIRX3STD_006_Temperature_A:quantity_type = "minimum of Air Temperature" ;
		min_AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		min_AIRX3STD_006_Temperature_A:product_version = "006" ;
		min_AIRX3STD_006_Temperature_A:Serializable = "True" ;
		min_AIRX3STD_006_Temperature_A:cell_methods = "lat,lon: minimum" ;
	float stddev_AIRX3STD_006_Temperature_A(time) ;
		stddev_AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		stddev_AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		stddev_AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
		stddev_AIRX3STD_006_Temperature_A:units = "K" ;
		stddev_AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
		stddev_AIRX3STD_006_Temperature_A:coordinates = "time" ;
		stddev_AIRX3STD_006_Temperature_A:quantity_type = "standard deviation of Air Temperature" ;
		stddev_AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		stddev_AIRX3STD_006_Temperature_A:product_version = "006" ;
		stddev_AIRX3STD_006_Temperature_A:Serializable = "True" ;
		stddev_AIRX3STD_006_Temperature_A:cell_methods = "lat,lon: standard deviation" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2009-01-17T00:00:00Z" ;
		:end_time = "2009-01-19T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "\"4.5.3\"" ;
		:nco_input_file_number = 3 ;
		:nco_input_file_list = "/tmp/huO4XxFY0B/testAlgorithm.AIRX3STD_006_Temperature_A.850hPa.20090117-20090119.148W_47N_146W_49N.nc.0 /tmp/huO4XxFY0B/testAlgorithm.AIRX3STD_006_Temperature_A.850hPa.20090117-20090119.148W_47N_146W_49N.nc.1 /tmp/huO4XxFY0B/testAlgorithm.AIRX3STD_006_Temperature_A.850hPa.20090117-20090119.148W_47N_146W_49N.nc.2" ;
		:userstartdate = "2009-01-17T00:00:00Z" ;
		:userenddate = "2009-01-19T23:59:59Z" ;
data:

 AIRX3STD_006_Temperature_A = 275.4056, 272.6981, 269.7991 ;

 count_AIRX3STD_006_Temperature_A = 4, 4, 4 ;

 max_AIRX3STD_006_Temperature_A = 275.6875, 274, 270.4375 ;

 min_AIRX3STD_006_Temperature_A = 275.1875, 271.875, 269.4375 ;

 stddev_AIRX3STD_006_Temperature_A = 0.1998127, 0.7857248, 0.3820767 ;

 time = 1232150400, 1232236800, 1232323200 ;
}



