use strict;
use Test::More tests => 4;
use Giovanni::Testing;
use Giovanni::Algorithm::Wrapper;
BEGIN { use_ok('Giovanni::Algorithm::Wrapper::Test'); }

# Find path for $program
my $program = 'g4_time_avg_diff_map.pl';
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
    'bbox'         => "-79.,36.,-75.,40.",
    'name'         => 'Difference of Time Averaged Maps',
    'units'        => ',mm/hr',
    'diff-exclude' => [
        qw(/title /plot_title /plot_subtitle /temporal_resolution
            /grid_name /grid_type /level_description /standard_name
            /time_statistic /calendar /model /center
            /end_time /missing_value lat/long_name
            time_matched_difference/Description
            time_matched_difference/long_name
            time_matched_difference/product_short_name
            time_matched_difference/product_version)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" )
    or die "No point diffing files";
is( $diff_rc, '', "Outcome of diff" );
exit(0);
__DATA__
netcdf ss.regrid.TRMM_3B43_007_precipitation.20090101 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 6 ;
	lon = 6 ;
variables:
	float TRMM_3B43_007_precipitation(time, lat, lon) ;
		TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
		TRMM_3B43_007_precipitation:units = "mm/hr" ;
		TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
		TRMM_3B43_007_precipitation:grid_type = "linear" ;
		TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
		TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
		TRMM_3B43_007_precipitation:missing_value = -9999.9f ;
		TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
		TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
		TRMM_3B43_007_precipitation:product_version = "007" ;
		TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
		TRMM_3B43_007_precipitation:standard_name = "pcp" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:long_name = "Latitude" ;
		lat:standard_name = "latitude" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:long_name = "Longitude" ;
		lon:standard_name = "longitude" ;
	int time(time) ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:standard_name = "time" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:calendar = "standard" ;
		:model = "geos/das" ;
		:center = "gsfc" ;
		:NCO = "4.4.4" ;
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
data:

 TRMM_3B43_007_precipitation =
  0.07907127, 0.08237258, 0.0840648, 0.06933828, 0.05139146, 0.2062767,
  0.1216598, 0.1177462, 0.1314009, 0.08024239, 0.07994625, 0.1651037,
  0.1107367, 0.08783454, 0.08660243, 0.07536867, 0.08152296, 0.1681478,
  0.1517488, 0.0939211, 0.08724182, 0.08726538, 0.08066292, 0.1193738,
  0.1428505, 0.08105046, 0.09106281, 0.1038019, 0.1115014, 0.1227205,
  0.1115268, 0.06202921, 0.07351294, 0.08999461, 0.1107703, 0.1491157 ;

 datamonth = 200901 ;

 lat = 35.5, 36.5, 37.5, 38.5, 39.5, 40.5 ;

 lon = -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 time = 1230768001 ;
}
netcdf ss.regrid.TRMM_3B43_007_precipitation.20090201 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 6 ;
	lon = 6 ;
variables:
	float TRMM_3B43_007_precipitation(time, lat, lon) ;
		TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
		TRMM_3B43_007_precipitation:units = "mm/hr" ;
		TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
		TRMM_3B43_007_precipitation:grid_type = "linear" ;
		TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
		TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
		TRMM_3B43_007_precipitation:missing_value = -9999.9f ;
		TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
		TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
		TRMM_3B43_007_precipitation:product_version = "007" ;
		TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
		TRMM_3B43_007_precipitation:standard_name = "pcp" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:long_name = "Latitude" ;
		lat:standard_name = "latitude" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:long_name = "Longitude" ;
		lon:standard_name = "longitude" ;
	int time(time) ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:standard_name = "time" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:calendar = "standard" ;
		:model = "geos/das" ;
		:center = "gsfc" ;
		:NCO = "4.4.4" ;
		:start_time = "2009-02-01T00:00:00Z" ;
		:end_time = "2009-02-28T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
data:

 TRMM_3B43_007_precipitation =
  0.08664367, 0.09580958, 0.09641992, 0.09534102, 0.1210626, 0.19653,
  0.06370815, 0.08696826, 0.1061928, 0.07988068, 0.06767421, 0.1026043,
  0.04689573, 0.04439229, 0.05689064, 0.05619369, 0.03403486, 0.06685052,
  0.04853316, 0.02376428, 0.02581565, 0.04025715, 0.02513852, 0.03306742,
  0.06756121, 0.02767262, 0.0324594, 0.03357318, 0.03186373, 0.03657717,
  0.08887033, 0.05357726, 0.05024466, 0.05909279, 0.06796505, 0.04773903 ;

 datamonth = 200902 ;

 lat = 35.5, 36.5, 37.5, 38.5, 39.5, 40.5 ;

 lon = -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 time = 1233446401 ;
}
netcdf ss.regrid.TRMM_3B43_007_precipitation.20090301 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 6 ;
	lon = 6 ;
variables:
	float TRMM_3B43_007_precipitation(time, lat, lon) ;
		TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
		TRMM_3B43_007_precipitation:units = "mm/hr" ;
		TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
		TRMM_3B43_007_precipitation:grid_type = "linear" ;
		TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
		TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
		TRMM_3B43_007_precipitation:missing_value = -9999.9f ;
		TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
		TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
		TRMM_3B43_007_precipitation:product_version = "007" ;
		TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
		TRMM_3B43_007_precipitation:standard_name = "pcp" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:long_name = "Latitude" ;
		lat:standard_name = "latitude" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:long_name = "Longitude" ;
		lon:standard_name = "longitude" ;
	int time(time) ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:standard_name = "time" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:calendar = "standard" ;
		:model = "geos/das" ;
		:center = "gsfc" ;
		:NCO = "4.4.4" ;
		:start_time = "2009-03-01T00:00:00Z" ;
		:end_time = "2009-03-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
data:

 TRMM_3B43_007_precipitation =
  0.1662094, 0.1558307, 0.1438209, 0.105038, 0.1086976, 0.278335,
  0.1670693, 0.1956702, 0.2318265, 0.1776105, 0.1557775, 0.1974059,
  0.1382998, 0.1340592, 0.1698825, 0.1528826, 0.1472093, 0.1978644,
  0.08940803, 0.08142778, 0.08016421, 0.07400347, 0.06959103, 0.0793689,
  0.0733968, 0.05100505, 0.06677965, 0.06604419, 0.04802773, 0.06637133,
  0.079674, 0.04954478, 0.04820096, 0.05280615, 0.06301077, 0.04780921 ;

 datamonth = 200903 ;

 lat = 35.5, 36.5, 37.5, 38.5, 39.5, 40.5 ;

 lon = -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 time = 1235865601 ;
}
netcdf ss.scrubbed.GLDAS_NOAH10_M_020_rainf.200901010000 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 6 ;
	lon = 6 ;
variables:
	double GLDAS_NOAH10_M_020_rainf(time, lat, lon) ;
		GLDAS_NOAH10_M_020_rainf:_FillValue = 9999. ;
		GLDAS_NOAH10_M_020_rainf:Description = "0[-] SFC (Ground or water surface)" ;
		GLDAS_NOAH10_M_020_rainf:long_name = "Rainfall rate" ;
		GLDAS_NOAH10_M_020_rainf:product_short_name = "GLDAS_NOAH10_M" ;
		GLDAS_NOAH10_M_020_rainf:product_version = "020" ;
		GLDAS_NOAH10_M_020_rainf:quantity_type = "Precipitation" ;
		GLDAS_NOAH10_M_020_rainf:standard_name = "rainf.band_7" ;
		GLDAS_NOAH10_M_020_rainf:coordinates = "time lat lon" ;
		GLDAS_NOAH10_M_020_rainf:units = "kg/m^2/s" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	double lat(lat) ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	float lon(lon) ;
		lon:standard_name = "longitude" ;
		lon:long_name = "Longitude" ;
		lon:units = "degrees_east" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Mar 11 13:15:30 2015: ncks -d lat,35.,41. -d lon,-80.,-74. scrubbed.GLDAS_NOAH10_M_020_rainf.200901010000.nc ss.scrubbed.GLDAS_NOAH10_M_020_rainf.200901010000.nc" ;
		:NCO = "4.4.4" ;
data:

 GLDAS_NOAH10_M_020_rainf =
  2.34e-05, 2.05e-05, 2.32e-05, 1.78e-05, _, _,
  1.93e-05, 1.45e-05, 2.28e-05, 1.98e-05, _, _,
  1.21e-05, 1.32e-05, 0, 2.09e-05, _, _,
  6.2e-06, 9.9e-06, 1.34e-05, 1.79e-05, 1.47e-05, _,
  2.3e-06, 2.6e-06, 5.5e-06, 4.9e-06, 4e-06, 8.7e-06,
  2.3e-06, 1.1e-06, 5e-07, 1.2e-06, 7e-07, 1.1e-06 ;

 datamonth = 200901 ;

 lat = 35.5, 36.5, 37.5, 38.5, 39.5, 40.5 ;

 lon = -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 time = 1230768000 ;
}
netcdf ss.scrubbed.GLDAS_NOAH10_M_020_rainf.200902010000 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 6 ;
	lon = 6 ;
variables:
	double GLDAS_NOAH10_M_020_rainf(time, lat, lon) ;
		GLDAS_NOAH10_M_020_rainf:_FillValue = 9999. ;
		GLDAS_NOAH10_M_020_rainf:Description = "0[-] SFC (Ground or water surface)" ;
		GLDAS_NOAH10_M_020_rainf:long_name = "Rainfall rate" ;
		GLDAS_NOAH10_M_020_rainf:product_short_name = "GLDAS_NOAH10_M" ;
		GLDAS_NOAH10_M_020_rainf:product_version = "020" ;
		GLDAS_NOAH10_M_020_rainf:quantity_type = "Precipitation" ;
		GLDAS_NOAH10_M_020_rainf:standard_name = "rainf.band_7" ;
		GLDAS_NOAH10_M_020_rainf:coordinates = "time lat lon" ;
		GLDAS_NOAH10_M_020_rainf:units = "kg/m^2/s" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	double lat(lat) ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	float lon(lon) ;
		lon:standard_name = "longitude" ;
		lon:long_name = "Longitude" ;
		lon:units = "degrees_east" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2009-02-01T00:00:00Z" ;
		:end_time = "2009-02-28T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Mar 11 13:15:30 2015: ncks -d lat,35.,41. -d lon,-80.,-74. scrubbed.GLDAS_NOAH10_M_020_rainf.200902010000.nc ss.scrubbed.GLDAS_NOAH10_M_020_rainf.200902010000.nc" ;
		:NCO = "4.4.4" ;
data:

 GLDAS_NOAH10_M_020_rainf =
  2.33e-05, 2.47e-05, 2.45e-05, 2.71e-05, _, _,
  1.32e-05, 1.77e-05, 2.38e-05, 1.55e-05, _, _,
  9.3e-06, 9e-06, 1.18e-05, 1.39e-05, _, _,
  1.34e-05, 3.1e-06, 4.8e-06, 9.7e-06, 2e-06, _,
  1.63e-05, 7.7e-06, 7.7e-06, 6.5e-06, 3.9e-06, 5.9e-06,
  1.42e-05, 8e-06, 7.5e-06, 6.3e-06, 7e-07, 1.1e-06 ;

 datamonth = 200902 ;

 lat = 35.5, 36.5, 37.5, 38.5, 39.5, 40.5 ;

 lon = -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 time = 1233446400 ;
}
netcdf ss.scrubbed.GLDAS_NOAH10_M_020_rainf.200903010000 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 6 ;
	lon = 6 ;
variables:
	double GLDAS_NOAH10_M_020_rainf(time, lat, lon) ;
		GLDAS_NOAH10_M_020_rainf:_FillValue = 9999. ;
		GLDAS_NOAH10_M_020_rainf:Description = "0[-] SFC (Ground or water surface)" ;
		GLDAS_NOAH10_M_020_rainf:long_name = "Rainfall rate" ;
		GLDAS_NOAH10_M_020_rainf:product_short_name = "GLDAS_NOAH10_M" ;
		GLDAS_NOAH10_M_020_rainf:product_version = "020" ;
		GLDAS_NOAH10_M_020_rainf:quantity_type = "Precipitation" ;
		GLDAS_NOAH10_M_020_rainf:standard_name = "rainf.band_7" ;
		GLDAS_NOAH10_M_020_rainf:coordinates = "time lat lon" ;
		GLDAS_NOAH10_M_020_rainf:units = "kg/m^2/s" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	double lat(lat) ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	float lon(lon) ;
		lon:standard_name = "longitude" ;
		lon:long_name = "Longitude" ;
		lon:units = "degrees_east" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2009-03-01T00:00:00Z" ;
		:end_time = "2009-03-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Mar 11 13:15:30 2015: ncks -d lat,35.,41. -d lon,-80.,-74. scrubbed.GLDAS_NOAH10_M_020_rainf.200903010000.nc ss.scrubbed.GLDAS_NOAH10_M_020_rainf.200903010000.nc" ;
		:NCO = "4.4.4" ;
data:

 GLDAS_NOAH10_M_020_rainf =
  4.46e-05, 4.55e-05, 3.75e-05, 2.92e-05, _, _,
  3.66e-05, 4.11e-05, 5.49e-05, 4.89e-05, _, _,
  1.72e-05, 1.92e-05, 3.5e-05, 3.93e-05, _, _,
  1.49e-05, 1.55e-05, 1.77e-05, 1.62e-05, 1.8e-05, _,
  1.64e-05, 1.22e-05, 1.82e-05, 9e-06, 6.9e-06, 7.4e-06,
  9.8e-06, 5.5e-06, 5.9e-06, 1.13e-05, 1.31e-05, 9.4e-06 ;

 datamonth = 200903 ;

 lat = 35.5, 36.5, 37.5, 38.5, 39.5, 40.5 ;

 lon = -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 time = 1235865600 ;
}
netcdf ref {
dimensions:
	lat = 4 ;
	lon = 4 ;
variables:
	double lat(lat) ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	float lon(lon) ;
		lon:long_name = "Longitude" ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	double time_matched_difference(lat, lon) ;
		time_matched_difference:_FillValue = 9999. ;
		time_matched_difference:Description = "0[-] SFC (Ground or water surface)" ;
		time_matched_difference:cell_methods = "time: mean" ;
		time_matched_difference:coordinates = "lat lon" ;
		time_matched_difference:long_name = "Rainfall rate" ;
		time_matched_difference:product_short_name = "GLDAS_NOAH10_M" ;
		time_matched_difference:product_version = "020" ;
		time_matched_difference:quantity_type = "Precipitation" ;
		time_matched_difference:standard_name = "rainf.band_7" ;
		time_matched_difference:units = "mm/hr" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:NCO = "\"4.5.3\"" ;
		:end_time = "2009-03-31T23:59:59Z" ;
		:history = "Fri Nov  4 21:12:26 2016: ncdiff -O /tmp/ke_WyKN0l9/uc.fileswn74w.txt.1.timeavg.nc /tmp/ke_WyKN0l9/fileswn74w.txt.0.timeavg.nc /tmp/ke_WyKN0l9/testAlgorithm.TRMM_3B43_007_precipitation+GLDAS_NOAH10_M_020_rainf.20090101-20090331.79W_36N_75W_40N.nc\n",
			"Fri Nov  4 21:12:26 2016: ncrename -v GLDAS_NOAH10_M_020_rainf,time_matched_difference -O -o /tmp/ke_WyKN0l9/uc.fileswn74w.txt.1.timeavg.nc /tmp/ke_WyKN0l9/uc.fileswn74w.txt.1.timeavg.nc\n",
			"Fri Nov  4 21:12:26 2016: ncap2 -O -S /tmp/linearUnitsConversion_xfP7.ncap2 /tmp/ke_WyKN0l9/fileswn74w.txt.1.timeavg.nc /tmp/ke_WyKN0l9/uc.fileswn74w.txt.1.timeavg.nc\n",
			"Fri Nov  4 21:12:26 2016: ncra -D 2 -H -O -o /tmp/ke_WyKN0l9/fileswn74w.txt.1.timeavg.nc -d lat,36.000000,40.000000 -d lon,-79.000000,-75.000000\n",
			"Wed Mar 11 13:15:30 2015: ncks -d lat,35.,41. -d lon,-80.,-74. scrubbed.GLDAS_NOAH10_M_020_rainf.200901010000.nc ss.scrubbed.GLDAS_NOAH10_M_020_rainf.200901010000.nc" ;
		:nco_openmp_thread_number = 1 ;
		:start_time = "2009-01-01T00:00:00Z" ;
		:temporal_resolution = "monthly" ;
		:userenddate = "2009-03-31T23:59:59Z" ;
		:userstartdate = "2009-01-01T00:00:00Z" ;
data:

 lat = 36.5, 37.5, 38.5, 39.5 ;

 lon = -78.5, -77.5, -76.5, -75.5 ;

 time_matched_difference =
  -0.0455015498781204, -0.0346733982086182, -0.0115378555870056, _,
  -0.0390820151042938, -0.0482985257768631, -0.00589498599052429, _,
  -0.0321710534572601, -0.0213272294235229, -0.0146153361821175, 
    -0.0168241583263874,
  -0.0262427132129669, -0.0257539526295662, -0.0433264227104187, 
    -0.0460376229190826 ;
}

