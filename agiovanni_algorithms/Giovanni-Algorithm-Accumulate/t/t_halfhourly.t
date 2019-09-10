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
    'bbox'         => '-81.2,42,-81,42.2',
    'diff-exclude' => [
        qw( /title /latitude_resolution /longitude_resolution)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" );
is( $diff_rc, '', "Outcome of diff" );

__DATA__
netcdf ss.scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902000000 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 2 ;
	lon = 2 ;
variables:
	float GPM_3IMERGHH_03_precipitationCal(time, lat, lon) ;
		GPM_3IMERGHH_03_precipitationCal:DimensionNames = "lon,lat" ;
		GPM_3IMERGHH_03_precipitationCal:Units = "mm/hr" ;
		GPM_3IMERGHH_03_precipitationCal:units = "mm/hr" ;
		GPM_3IMERGHH_03_precipitationCal:coordinates = "time lat lon" ;
		GPM_3IMERGHH_03_precipitationCal:_FillValue = -9999.9f ;
		GPM_3IMERGHH_03_precipitationCal:CodeMissingValue = "-9999.9" ;
		GPM_3IMERGHH_03_precipitationCal:origname = "precipitationCal" ;
		GPM_3IMERGHH_03_precipitationCal:fullnamepath = "/Grid/precipitationCal" ;
		GPM_3IMERGHH_03_precipitationCal:standard_name = "precipitationcal" ;
		GPM_3IMERGHH_03_precipitationCal:quantity_type = "Precipitation" ;
		GPM_3IMERGHH_03_precipitationCal:product_short_name = "GPM_3IMERGHH" ;
		GPM_3IMERGHH_03_precipitationCal:product_version = "03" ;
		GPM_3IMERGHH_03_precipitationCal:long_name = "Instantaneous Precipitation - Calibrated" ;
	float lat(lat) ;
		lat:DimensionNames = "lat" ;
		lat:Units = "degrees_north" ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:_FillValue = -9999.9f ;
		lat:CodeMissingValue = "-9999.9" ;
		lat:CLASS = "DIMENSION_SCALE" ;
		lat:origname = "lat" ;
		lat:fullnamepath = "/Grid/lat" ;
		lat:long_name = "Latitude" ;
	float lon(lon) ;
		lon:DimensionNames = "lon" ;
		lon:Units = "degrees_east" ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
		lon:_FillValue = -9999.9f ;
		lon:CodeMissingValue = "-9999.9" ;
		lon:CLASS = "DIMENSION_SCALE" ;
		lon:origname = "lon" ;
		lon:fullnamepath = "/Grid/lon" ;
		lon:long_name = "Longitude" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2014-09-02T00:00:00Z" ;
		:end_time = "2014-09-02T00:29:59Z" ;
		:temporal_resolution = "half-hourly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb  7 00:11:29 2015: ncks -d lat,42.,42.2 -d lon,-81.2,-81. -O scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902000000.nc ss.scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902000000.nc" ;
		:NCO = "4.4.4" ;
data:

 GPM_3IMERGHH_03_precipitationCal =
  0.3884034, 0.3955216,
  0.3445966, 0.3672789 ;

 lat = 42.05, 42.15 ;

 lon = -81.15, -81.05 ;

 time = 1409616000 ;
}
netcdf ss.scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902003000 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 2 ;
	lon = 2 ;
variables:
	float GPM_3IMERGHH_03_precipitationCal(time, lat, lon) ;
		GPM_3IMERGHH_03_precipitationCal:DimensionNames = "lon,lat" ;
		GPM_3IMERGHH_03_precipitationCal:Units = "mm/hr" ;
		GPM_3IMERGHH_03_precipitationCal:units = "mm/hr" ;
		GPM_3IMERGHH_03_precipitationCal:coordinates = "time lat lon" ;
		GPM_3IMERGHH_03_precipitationCal:_FillValue = -9999.9f ;
		GPM_3IMERGHH_03_precipitationCal:CodeMissingValue = "-9999.9" ;
		GPM_3IMERGHH_03_precipitationCal:origname = "precipitationCal" ;
		GPM_3IMERGHH_03_precipitationCal:fullnamepath = "/Grid/precipitationCal" ;
		GPM_3IMERGHH_03_precipitationCal:standard_name = "precipitationcal" ;
		GPM_3IMERGHH_03_precipitationCal:quantity_type = "Precipitation" ;
		GPM_3IMERGHH_03_precipitationCal:product_short_name = "GPM_3IMERGHH" ;
		GPM_3IMERGHH_03_precipitationCal:product_version = "03" ;
		GPM_3IMERGHH_03_precipitationCal:long_name = "Instantaneous Precipitation - Calibrated" ;
	float lat(lat) ;
		lat:DimensionNames = "lat" ;
		lat:Units = "degrees_north" ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:_FillValue = -9999.9f ;
		lat:CodeMissingValue = "-9999.9" ;
		lat:CLASS = "DIMENSION_SCALE" ;
		lat:origname = "lat" ;
		lat:fullnamepath = "/Grid/lat" ;
		lat:long_name = "Latitude" ;
	float lon(lon) ;
		lon:DimensionNames = "lon" ;
		lon:Units = "degrees_east" ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
		lon:_FillValue = -9999.9f ;
		lon:CodeMissingValue = "-9999.9" ;
		lon:CLASS = "DIMENSION_SCALE" ;
		lon:origname = "lon" ;
		lon:fullnamepath = "/Grid/lon" ;
		lon:long_name = "Longitude" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2014-09-02T00:30:00Z" ;
		:end_time = "2014-09-02T00:59:59Z" ;
		:temporal_resolution = "half-hourly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb  7 00:11:29 2015: ncks -d lat,42.,42.2 -d lon,-81.2,-81. -O scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902003000.nc ss.scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902003000.nc" ;
		:NCO = "4.4.4" ;
data:

 GPM_3IMERGHH_03_precipitationCal =
  4.272438, 0.1977608,
  3.790562, 0.1836395 ;

 lat = 42.05, 42.15 ;

 lon = -81.15, -81.05 ;

 time = 1409617800 ;
}
netcdf ss.scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902010000 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 2 ;
	lon = 2 ;
variables:
	float GPM_3IMERGHH_03_precipitationCal(time, lat, lon) ;
		GPM_3IMERGHH_03_precipitationCal:DimensionNames = "lon,lat" ;
		GPM_3IMERGHH_03_precipitationCal:Units = "mm/hr" ;
		GPM_3IMERGHH_03_precipitationCal:units = "mm/hr" ;
		GPM_3IMERGHH_03_precipitationCal:coordinates = "time lat lon" ;
		GPM_3IMERGHH_03_precipitationCal:_FillValue = -9999.9f ;
		GPM_3IMERGHH_03_precipitationCal:CodeMissingValue = "-9999.9" ;
		GPM_3IMERGHH_03_precipitationCal:origname = "precipitationCal" ;
		GPM_3IMERGHH_03_precipitationCal:fullnamepath = "/Grid/precipitationCal" ;
		GPM_3IMERGHH_03_precipitationCal:standard_name = "precipitationcal" ;
		GPM_3IMERGHH_03_precipitationCal:quantity_type = "Precipitation" ;
		GPM_3IMERGHH_03_precipitationCal:product_short_name = "GPM_3IMERGHH" ;
		GPM_3IMERGHH_03_precipitationCal:product_version = "03" ;
		GPM_3IMERGHH_03_precipitationCal:long_name = "Instantaneous Precipitation - Calibrated" ;
	float lat(lat) ;
		lat:DimensionNames = "lat" ;
		lat:Units = "degrees_north" ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:_FillValue = -9999.9f ;
		lat:CodeMissingValue = "-9999.9" ;
		lat:CLASS = "DIMENSION_SCALE" ;
		lat:origname = "lat" ;
		lat:fullnamepath = "/Grid/lat" ;
		lat:long_name = "Latitude" ;
	float lon(lon) ;
		lon:DimensionNames = "lon" ;
		lon:Units = "degrees_east" ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
		lon:_FillValue = -9999.9f ;
		lon:CodeMissingValue = "-9999.9" ;
		lon:CLASS = "DIMENSION_SCALE" ;
		lon:origname = "lon" ;
		lon:fullnamepath = "/Grid/lon" ;
		lon:long_name = "Longitude" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2014-09-02T01:00:00Z" ;
		:end_time = "2014-09-02T01:29:59Z" ;
		:temporal_resolution = "half-hourly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb  7 00:11:29 2015: ncks -d lat,42.,42.2 -d lon,-81.2,-81. -O scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902010000.nc ss.scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902010000.nc" ;
		:NCO = "4.4.4" ;
data:

 GPM_3IMERGHH_03_precipitationCal =
  4.855042, 5.141781,
  4.307457, 4.774626 ;

 lat = 42.05, 42.15 ;

 lon = -81.15, -81.05 ;

 time = 1409619600 ;
}
netcdf ss.scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902013000 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 2 ;
	lon = 2 ;
variables:
	float GPM_3IMERGHH_03_precipitationCal(time, lat, lon) ;
		GPM_3IMERGHH_03_precipitationCal:DimensionNames = "lon,lat" ;
		GPM_3IMERGHH_03_precipitationCal:Units = "mm/hr" ;
		GPM_3IMERGHH_03_precipitationCal:units = "mm/hr" ;
		GPM_3IMERGHH_03_precipitationCal:coordinates = "time lat lon" ;
		GPM_3IMERGHH_03_precipitationCal:_FillValue = -9999.9f ;
		GPM_3IMERGHH_03_precipitationCal:CodeMissingValue = "-9999.9" ;
		GPM_3IMERGHH_03_precipitationCal:origname = "precipitationCal" ;
		GPM_3IMERGHH_03_precipitationCal:fullnamepath = "/Grid/precipitationCal" ;
		GPM_3IMERGHH_03_precipitationCal:standard_name = "precipitationcal" ;
		GPM_3IMERGHH_03_precipitationCal:quantity_type = "Precipitation" ;
		GPM_3IMERGHH_03_precipitationCal:product_short_name = "GPM_3IMERGHH" ;
		GPM_3IMERGHH_03_precipitationCal:product_version = "03" ;
		GPM_3IMERGHH_03_precipitationCal:long_name = "Instantaneous Precipitation - Calibrated" ;
	float lat(lat) ;
		lat:DimensionNames = "lat" ;
		lat:Units = "degrees_north" ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:_FillValue = -9999.9f ;
		lat:CodeMissingValue = "-9999.9" ;
		lat:CLASS = "DIMENSION_SCALE" ;
		lat:origname = "lat" ;
		lat:fullnamepath = "/Grid/lat" ;
		lat:long_name = "Latitude" ;
	float lon(lon) ;
		lon:DimensionNames = "lon" ;
		lon:Units = "degrees_east" ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
		lon:_FillValue = -9999.9f ;
		lon:CodeMissingValue = "-9999.9" ;
		lon:CLASS = "DIMENSION_SCALE" ;
		lon:origname = "lon" ;
		lon:fullnamepath = "/Grid/lon" ;
		lon:long_name = "Longitude" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2014-09-02T01:30:00Z" ;
		:end_time = "2014-09-02T01:59:59Z" ;
		:temporal_resolution = "half-hourly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb  7 00:11:29 2015: ncks -d lat,42.,42.2 -d lon,-81.2,-81. -O scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902013000.nc ss.scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902013000.nc" ;
		:NCO = "4.4.4" ;
data:

 GPM_3IMERGHH_03_precipitationCal =
  2.718824, 2.768651,
  42.04078, 44.80803 ;

 lat = 42.05, 42.15 ;

 lon = -81.15, -81.05 ;

 time = 1409621400 ;
}
netcdf ref {
dimensions:
	lat = 2 ;
	lon = 2 ;
variables:
	float GPM_3IMERGHH_03_precipitationCal(lat, lon) ;
             GPM_3IMERGHH_03_precipitationCal:_FillValue = -9999.9f ;
                GPM_3IMERGHH_03_precipitationCal:CodeMissingValue = "-9999.9" ;
                GPM_3IMERGHH_03_precipitationCal:DimensionNames = "lon,lat" ;
                GPM_3IMERGHH_03_precipitationCal:coordinates = "lat lon" ;
                GPM_3IMERGHH_03_precipitationCal:fullnamepath = "/Grid/precipitationCal" ;
                GPM_3IMERGHH_03_precipitationCal:long_name = "Instantaneous Precipitation - CalibTotald" ;
                GPM_3IMERGHH_03_precipitationCal:origname = "precipitationCal" ;
                GPM_3IMERGHH_03_precipitationCal:product_short_name = "GPM_3IMERGHH" ;
                GPM_3IMERGHH_03_precipitationCal:product_version = "03" ;
                GPM_3IMERGHH_03_precipitationCal:quantity_type = "Precipitation" ;
                GPM_3IMERGHH_03_precipitationCal:standard_name = "precipitationcal" ;
                GPM_3IMERGHH_03_precipitationCal:units = "mm" ;
	float lat(lat) ;
		lat:DimensionNames = "lat" ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:_FillValue = -9999.9f ;
		lat:CodeMissingValue = "-9999.9" ;
		lat:CLASS = "DIMENSION_SCALE" ;
		lat:origname = "lat" ;
		lat:fullnamepath = "/Grid/lat" ;
		lat:long_name = "Latitude" ;
	float lon(lon) ;
		lon:DimensionNames = "lon" ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
		lon:_FillValue = -9999.9f ;
		lon:CodeMissingValue = "-9999.9" ;
		lon:CLASS = "DIMENSION_SCALE" ;
		lon:origname = "lon" ;
		lon:fullnamepath = "/Grid/lon" ;
		lon:long_name = "Longitude" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2014-09-02T00:00:00Z" ;
		:end_time = "2014-09-02T01:59:59Z" ;
		:temporal_resolution = "half-hourly" ;
		:nco_openmp_thread_number = 1 ;
		:nco_input_file_number = 4 ;
		:nco_input_file_list = "/var/tmp/www/TS1/giovanni/538481F8-AE5A-11E4-9735-23B3D2A17ADB/B6690EB8-AE5C-11E4-898D-C4CFD2A17ADB/B6692CE0-AE5C-11E4-898D-C4CFD2A17ADB//scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902000000.nc /var/tmp/www/TS1/giovanni/538481F8-AE5A-11E4-9735-23B3D2A17ADB/B6690EB8-AE5C-11E4-898D-C4CFD2A17ADB/B6692CE0-AE5C-11E4-898D-C4CFD2A17ADB//scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902003000.nc /var/tmp/www/TS1/giovanni/538481F8-AE5A-11E4-9735-23B3D2A17ADB/B6690EB8-AE5C-11E4-898D-C4CFD2A17ADB/B6692CE0-AE5C-11E4-898D-C4CFD2A17ADB//scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902010000.nc /var/tmp/www/TS1/giovanni/538481F8-AE5A-11E4-9735-23B3D2A17ADB/B6690EB8-AE5C-11E4-898D-C4CFD2A17ADB/B6692CE0-AE5C-11E4-898D-C4CFD2A17ADB//scrubbed.GPM_3IMERGHH_03_precipitationCal.20140902013000.nc" ;
		:NCO = "4.4.4" ;
		:userstartdate = "2014-09-02T00:00:00Z" ;
		:userenddate = "2014-09-02T01:59:59Z" ;
		:title = "Map, Accumulated of Instantaneous Precipitation - CalibTotald half-hourly 0.1 deg. [GPM GPM_3IMERGHH v03] mm over 2014-09-02 00:00Z - 2014-09-02 01:59Z, Region 82W, 42N, 81W, 42.5N " ;
data:

 GPM_3IMERGHH_03_precipitationCal =
  6.117353, 4.251857,
 25.2416978, 25.0667872 ;

 lat = 42.05, 42.15 ;

 lon = -81.15, -81.05 ;
}
