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
    'bbox'         => '118.,8.,119.,9.',
    'diff-exclude' => [
        qw( /title /plot_hint_title /plot_hint_subtitle
            /latitude_resolution /longitude_resolution)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" );
is( $diff_rc, '', "Outcome of diff" );

__DATA__
netcdf ss.scrubbed.TRMM_3B42_007_precipitation.20090101T0300 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 4 ;
variables:
	float TRMM_3B42_007_precipitation(time, lat, lon) ;
		TRMM_3B42_007_precipitation:long_name = "Precipitation" ;
		TRMM_3B42_007_precipitation:units = "mm/hr" ;
		TRMM_3B42_007_precipitation:_FillValue = -9999.9f ;
		TRMM_3B42_007_precipitation:standard_name = "precipitation" ;
		TRMM_3B42_007_precipitation:quantity_type = "Precipitation" ;
		TRMM_3B42_007_precipitation:product_short_name = "TRMM_3B42" ;
		TRMM_3B42_007_precipitation:product_version = "7" ;
		TRMM_3B42_007_precipitation:coordinates = "time lat lon" ;
	float lat(lat) ;
		lat:long_name = "Latitude" ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	float lon(lon) ;
		lon:long_name = "Longitude" ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2009-01-01T01:30:00" ;
		:end_time = "2009-01-01T04:30:00" ;
		:temporal_resolution = "3-hourly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon May 12 19:34:07 2014: ncks -d lat,8.,9. -d lon,118.,119. -O scrubbed.TRMM_3B42_007_precipitation.20090101T0300.nc ss.scrubbed.TRMM_3B42_007_precipitation.20090101T0300.nc" ;
		:NCO = "4.3.1" ;
data:

 TRMM_3B42_007_precipitation =
  1.90931, 1.801539, 2.065059, 5.377283,
  1.747478, 1.1461, 2.154932, 13.87643,
  0, 0.5846593, 1.879681, 4.376833,
  0, 0.6708565, 2.243164, 0.8528147 ;

 lat = 8.125, 8.375, 8.625, 8.875 ;

 lon = 118.125, 118.375, 118.625, 118.875 ;

 time = 1230778800 ;
}
netcdf ss.scrubbed.TRMM_3B42_007_precipitation.20090101T0600 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 4 ;
variables:
	float TRMM_3B42_007_precipitation(time, lat, lon) ;
		TRMM_3B42_007_precipitation:long_name = "Precipitation" ;
		TRMM_3B42_007_precipitation:units = "mm/hr" ;
		TRMM_3B42_007_precipitation:_FillValue = -9999.9f ;
		TRMM_3B42_007_precipitation:standard_name = "precipitation" ;
		TRMM_3B42_007_precipitation:quantity_type = "Precipitation" ;
		TRMM_3B42_007_precipitation:product_short_name = "TRMM_3B42" ;
		TRMM_3B42_007_precipitation:product_version = "7" ;
		TRMM_3B42_007_precipitation:coordinates = "time lat lon" ;
	float lat(lat) ;
		lat:long_name = "Latitude" ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	float lon(lon) ;
		lon:long_name = "Longitude" ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2009-01-01T04:30:00" ;
		:end_time = "2009-01-01T07:30:00" ;
		:temporal_resolution = "3-hourly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon May 12 19:34:07 2014: ncks -d lat,8.,9. -d lon,118.,119. -O scrubbed.TRMM_3B42_007_precipitation.20090101T0600.nc ss.scrubbed.TRMM_3B42_007_precipitation.20090101T0600.nc" ;
		:NCO = "4.3.1" ;
data:

 TRMM_3B42_007_precipitation =
  6.951372, 14.64844, 15.22571, 14.79578,
  13.91196, 14.94083, 15.69905, 14.91716,
  6.259605, 13.80125, 16.86017, 17.52379,
  1.924705, 2.507326, 2.725656, 9.046525 ;

 lat = 8.125, 8.375, 8.625, 8.875 ;

 lon = 118.125, 118.375, 118.625, 118.875 ;

 time = 1230789600 ;
}
netcdf ref {
dimensions:
	lat = 4 ;
	lon = 4 ;
variables:
	float TRMM_3B42_007_precipitation(lat, lon) ;
		TRMM_3B42_007_precipitation:_FillValue = -9999.9f ;
 		TRMM_3B42_007_precipitation:coordinates = "lat lon" ;
 		TRMM_3B42_007_precipitation:long_name = "Precipitation" ;
 		TRMM_3B42_007_precipitation:product_short_name = "TRMM_3B42" ;
 		TRMM_3B42_007_precipitation:product_version = "7" ;
 		TRMM_3B42_007_precipitation:quantity_type = "Precipitation" ;
 		TRMM_3B42_007_precipitation:standard_name = "precipitation" ;
 		TRMM_3B42_007_precipitation:units = "mm" ;
	float lat(lat) ;
		lat:long_name = "Latitude" ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	float lon(lon) ;
		lon:long_name = "Longitude" ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2009-01-01T01:30:00" ;
		:end_time = "2009-01-01T07:30:00" ;
		:temporal_resolution = "3-hourly" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.3.1" ;
		:nco_input_file_number = 2 ;
		:nco_input_file_list = "working/Zyj9sDdcG0/ss.scrubbed.TRMM_3B42_007_precipitation.20090101T0300.nc working/Zyj9sDdcG0/ss.scrubbed.TRMM_3B42_007_precipitation.20090101T0600.nc" ;
		:userstartdate = "2009-01-01T01:30:00" ;
		:userenddate = "2009-01-01T07:30:00" ;
		:title = "Accumulation Map of Precipitation 3-hourly 1 x 1 deg. [TRMM TRMM_3B42 v7] mm/hr over 2009-01-01 01:30Z - 2009-01-01 07:30:00Z, Region 118E, 8N, 119E, 9N" ;
		:plot_hint_title = "Accumulation Map of Precipitation 3-hourly 1 x 1 deg. [TRMM TRMM_3B42 v7] mm/hr" ;
		:plot_hint_subtitle = "over 2009-01-01 01:30Z - 2009-01-01 07:30:00Z, Region 118E, 8N, 119E, 9N" ;
data:

 TRMM_3B42_007_precipitation =
  26.58205, 49.34994, 51.87231, 60.51919,
  46.97831, 48.26079, 53.56194, 86.38077,
  18.77881, 43.15773, 56.21955, 65.70187,
  5.774115, 9.534547, 14.90646, 29.69802 ;

 lat = 8.125, 8.375, 8.625, 8.875 ;

 lon = 118.125, 118.375, 118.625, 118.875 ;
}
