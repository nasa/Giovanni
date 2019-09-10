# Use modules
use strict;
use Test::More tests => 2;
use Giovanni::Testing;
use Giovanni::Algorithm::Wrapper;
use Giovanni::Algorithm::Wrapper::Test;

# Find path for $program
my $program = 'g4_accumulate.pl';
my ($script_path) = Giovanni::Testing::find_script_paths($program);

# The actual call to run the test
# Note that diff-exclude is used to exclude potentially spurious differences
# In real life, we will want to take the out of the diff-exclude, once we settle
# on title formats and contents
my ( $out_nc, $diff_rc ) = run_test(
    'program'      => "$script_path -y ttl",
    'name'         => 'Accumulation Map',
    'bbox'         => '-118.,36.,-116.,37.',
    'diff-exclude' => [
        qw(/title /latitude_resolution /longitude_resolution)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" );
is( $diff_rc, '', "Outcome of diff" );

__DATA__
netcdf ss.scrubbed.TRMM_3B43_007_precipitation.20090101 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
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
		TRMM_3B43_007_precipitation:product_version = "007" ;
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
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	double time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:NCO = "4.3.1" ;
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon May  5 21:34:25 2014: ncks -d lat,36.,37. -d lon,-118.,-116. scrubbed.TRMM_3B43_007_precipitation.20090101.nc ss.scrubbed.TRMM_3B43_007_precipitation.20090101.nc" ;
data:

 TRMM_3B43_007_precipitation =
  0.01265333, 0.008043535, 0.003628703, 0.01865939, 0.004087398, 0.004030963, 
    0.003762008, 0.004291244,
  0.01258098, 0.006927351, 0.003717785, 0.005237489, 0.003992856, 
    0.003804315, 0.005445465, 0.007479332,
  0.0239707, 0.005888503, 0.01318483, 0.01326016, 0.005937321, 0.004207436, 
    0.004192689, 0.004418103,
  0.01149405, 0.005007486, 0.003002469, 0.007472327, 0.004458963, 
    0.004979685, 0.01600046, 0.0209559 ;

 datamonth = 200901 ;

 lat = 36.125, 36.375, 36.625, 36.875 ;

 lon = -117.875, -117.625, -117.375, -117.125, -116.875, -116.625, -116.375, 
    -116.125 ;

 time = 1230768001 ;
}
netcdf ss.scrubbed.TRMM_3B43_007_precipitation.20090201 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
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
		TRMM_3B43_007_precipitation:product_version = "007" ;
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
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	double time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:NCO = "4.3.1" ;
		:start_time = "2009-02-01T00:00:00Z" ;
		:end_time = "2009-02-28T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon May  5 21:34:25 2014: ncks -d lat,36.,37. -d lon,-118.,-116. scrubbed.TRMM_3B43_007_precipitation.20090201.nc ss.scrubbed.TRMM_3B43_007_precipitation.20090201.nc" ;
data:

 TRMM_3B43_007_precipitation =
  0.04953587, 0.03679067, 0.02646166, 0.04623926, 0.0299, 0.03433617, 
    0.03423184, 0.03186315,
  0.03802822, 0.02977008, 0.02262487, 0.02867857, 0.02742778, 0.03241974, 
    0.03793467, 0.03133133,
  0.03829065, 0.03031383, 0.02174587, 0.02692597, 0.02831081, 0.02991314, 
    0.03379254, 0.03712992,
  0.03318942, 0.02455941, 0.02577188, 0.02911221, 0.02833529, 0.03220518, 
    0.0317374, 0.03266775 ;

 datamonth = 200902 ;

 lat = 36.125, 36.375, 36.625, 36.875 ;

 lon = -117.875, -117.625, -117.375, -117.125, -116.875, -116.625, -116.375, 
    -116.125 ;

 time = 1233446401 ;
}
netcdf ref {
dimensions:
	lat = 4 ;
	lon = 8 ;
variables:
	float TRMM_3B43_007_precipitation(lat, lon) ;
		TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
 		TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
 		TRMM_3B43_007_precipitation:coordinates = "lat lon" ;
 		TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
 		TRMM_3B43_007_precipitation:grid_type = "linear" ;
 		TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
 		TRMM_3B43_007_precipitation:long_name = "Precipitation Total" ;
 		TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
 		TRMM_3B43_007_precipitation:product_version = "007" ;
 		TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
 		TRMM_3B43_007_precipitation:standard_name = "pcp" ;
 		TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
 		TRMM_3B43_007_precipitation:units = "mm" ;

	double lat(lat) ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	double lon(lon) ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:NCO = "4.3.1" ;
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-02-28T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:nco_openmp_thread_number = 1 ;
		:nco_input_file_number = 2 ;
		:nco_input_file_list = "working/aj3Ajg0WSD/tmp.15357.ss.scrubbed.TRMM_3B43_007_precipitation.20090101.nc working/aj3Ajg0WSD/tmp.15357.ss.scrubbed.TRMM_3B43_007_precipitation.20090201.nc" ;
		:userstartdate = "2009-01-01T00:00:00Z" ;
		:userenddate = "2009-02-28T23:59:59Z" ;
		:title = "Accumulation Map of Precipitation Rate monthly 1 x 1 deg. [TRMM TRMM_3B43 v007] mm/hr over 2009-Jan - 2009-Feb, Region 118W, 36N, 116W, 37N" ;
data:

 TRMM_3B43_007_precipitation =
  42.70218, 30.70772, 20.48199, 44.95537, 23.13382, 26.07294, 25.80273, 
    24.60472,
  34.91521, 25.15944, 17.96994, 23.16869, 21.40215, 24.61648, 29.54352, 
    26.61928,
  43.56552, 24.75194, 24.42274, 27.95981, 23.44223, 23.23196, 25.82795, 
    28.23837,
  30.85486, 20.22949, 19.55254, 25.12282, 22.35878, 25.34677, 33.23187, 
    37.54391 ;

 lat = 36.125, 36.375, 36.625, 36.875 ;

 lon = -117.875, -117.625, -117.375, -117.125, -116.875, -116.625, -116.375, 
    -116.125 ;
}
