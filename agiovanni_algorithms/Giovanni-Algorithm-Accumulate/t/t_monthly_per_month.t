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
netcdf uc.ss.scrubbed.TRMM_3B43_007_precipitation.20090101 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 8 ;
variables:
	float TRMM_3B43_007_precipitation(time, lat, lon) ;
		TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
		TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
		TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
		TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
		TRMM_3B43_007_precipitation:grid_type = "linear" ;
		TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
		TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
		TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
		TRMM_3B43_007_precipitation:product_version = "007" ;
		TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
		TRMM_3B43_007_precipitation:standard_name = "pcp" ;
		TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
		TRMM_3B43_007_precipitation:units = "mm/month" ;
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
		:history = "Fri Apr  3 22:07:17 2015: ncap2 -O -s TRMM_3B43_007_precipitation = TRMM_3B43_007_precipitation * 31.f*24.f; TRMM_3B43_007_precipitation@units=\"mm/month\" ss.scrubbed.TRMM_3B43_007_precipitation.20090101.nc uc.ss.scrubbed.TRMM_3B43_007_precipitation.20090101.nc\n",
			"Mon May  5 21:34:25 2014: ncks -d lat,36.,37. -d lon,-118.,-116. scrubbed.TRMM_3B43_007_precipitation.20090101.nc ss.scrubbed.TRMM_3B43_007_precipitation.20090101.nc" ;
data:

 TRMM_3B43_007_precipitation =
  9.414078, 5.98439, 2.699755, 13.88259, 3.041024, 2.999036, 2.798934, 
    3.192686,
  9.360249, 5.153949, 2.766032, 3.896692, 2.970685, 2.83041, 4.051426, 
    5.564623,
  17.8342, 4.381046, 9.809513, 9.865559, 4.417367, 3.130332, 3.11936, 3.287069,
  8.551573, 3.725569, 2.233837, 5.559412, 3.317468, 3.704885, 11.90434, 
    15.59119 ;

 datamonth = 200901 ;

 lat = 36.125, 36.375, 36.625, 36.875 ;

 lon = -117.875, -117.625, -117.375, -117.125, -116.875, -116.625, -116.375, 
    -116.125 ;

 time = 1230768001 ;
}
netcdf uc.ss.scrubbed.TRMM_3B43_007_precipitation.20090201 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 8 ;
variables:
	float TRMM_3B43_007_precipitation(time, lat, lon) ;
		TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
		TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
		TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
		TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
		TRMM_3B43_007_precipitation:grid_type = "linear" ;
		TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
		TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
		TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
		TRMM_3B43_007_precipitation:product_version = "007" ;
		TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
		TRMM_3B43_007_precipitation:standard_name = "pcp" ;
		TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
		TRMM_3B43_007_precipitation:units = "mm/month" ;
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
		:history = "Fri Apr  3 22:06:45 2015: ncap2 -O -s TRMM_3B43_007_precipitation = TRMM_3B43_007_precipitation * 28.f*24.f; TRMM_3B43_007_precipitation@units=\"mm/month\" ss.scrubbed.TRMM_3B43_007_precipitation.20090201.nc uc.ss.scrubbed.TRMM_3B43_007_precipitation.20090201.nc\n",
			"Mon May  5 21:34:25 2014: ncks -d lat,36.,37. -d lon,-118.,-116. scrubbed.TRMM_3B43_007_precipitation.20090201.nc ss.scrubbed.TRMM_3B43_007_precipitation.20090201.nc" ;
data:

 TRMM_3B43_007_precipitation =
  33.28811, 24.72333, 17.78224, 31.07278, 20.0928, 23.07391, 23.0038, 21.41204,
  25.55497, 20.00549, 15.20391, 19.272, 18.43147, 21.78607, 25.4921, 21.05465,
  25.73132, 20.37089, 14.61322, 18.09425, 19.02486, 20.10163, 22.70859, 
    24.95131,
  22.30329, 16.50392, 17.3187, 19.56341, 19.04132, 21.64188, 21.32753, 
    21.95273 ;

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
  42.70219, 30.70772, 20.48199, 44.95537, 23.13382, 26.07295, 25.80273, 
    24.60473,
  34.91522, 25.15944, 17.96994, 23.16869, 21.40216, 24.61648, 29.54353, 
    26.61927,
  43.56552, 24.75194, 24.42273, 27.95981, 23.44223, 23.23196, 25.82795, 
    28.23838,
  30.85486, 20.22949, 19.55254, 25.12282, 22.35879, 25.34677, 33.23187, 
    37.54392 ;

 lat = 36.125, 36.375, 36.625, 36.875 ;

 lon = -117.875, -117.625, -117.375, -117.125, -116.875, -116.625, -116.375, 
    -116.125 ;
}
