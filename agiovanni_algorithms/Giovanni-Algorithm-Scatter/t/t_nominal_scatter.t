# Use modules
use strict;
use Test::More tests => 2;
use Giovanni::Testing;
use Giovanni::Algorithm::Wrapper;
use Giovanni::Algorithm::Wrapper::Test;

# Find path for $program
my $program = 'g4_scatterplot.pl';
my ($script_path) = Giovanni::Testing::find_script_paths($program);

# The actual call to run the test
# Note that diff-exclude is used to exclude potentially spurious differences
# In real life, we will want to take the out of the diff-exclude, once we settle
# on title formats and contents
my ( $out_nc, $diff_rc ) = run_test(
    'program'      => "$script_path -y ttl",
    'name'         => 'Static Scatter',
    'comparison'   => "vs",
    'bbox'         => '-96.4922, 33.4102, -90.1641, 35.5195',
    'diff-exclude' => [
        qw(/latitude_resolution /longitude_resolution)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" );
is( $diff_rc, '', "Outcome of diff" );

__DATA__
netcdf scrubbed.AIRX3STD_006_TotO3_A.20080101 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 3 ;
	lon = 6 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STD_006_TotO3_A(time, lat, lon) ;
		AIRX3STD_006_TotO3_A:_FillValue = -9999.f ;
		AIRX3STD_006_TotO3_A:standard_name = "toto3_a" ;
		AIRX3STD_006_TotO3_A:quantity_type = "Ozone" ;
		AIRX3STD_006_TotO3_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_TotO3_A:product_version = "006" ;
		AIRX3STD_006_TotO3_A:long_name = "Ozone Total Column (Daytime/Ascending)" ;
		AIRX3STD_006_TotO3_A:coordinates = "time lat lon" ;
		AIRX3STD_006_TotO3_A:units = "DU" ;
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
		:start_time = "2008-01-01T00:00:00Z" ;
		:end_time = "2008-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Nov 15 20:53:52 2016: ncks -d lon,-96.000,-90.1641 -d lat,33.4102,35.5195 scrubbed.AIRX3STD_006_TotO3_A.20080101.nc scrubbed.AIRX3STD_006_TotO3_A.20080101.nc" ;
data:

 AIRX3STD_006_TotO3_A =
  293, 296.5, 300.5, 302.5, 307.5, 307.75,
  300, 300.25, 307.25, 315.25, 319.75, 325,
  317.75, 329.5, 351, 360.5, 364.75, 366.5 ;

 dataday = 2008001 ;

 lat = 33.5, 34.5, 35.5 ;

 lat_bnds =
  33, 34,
  34, 35,
  35, 36 ;

 lon = -95.5, -94.5, -93.5, -92.5, -91.5, -90.5 ;

 lon_bnds =
  -96, -95,
  -95, -94,
  -94, -93,
  -93, -92,
  -92, -91,
  -91, -90 ;

 time = 1199145600 ;

 time_bnds =
  1199145600, 1199231999 ;
}
netcdf scrubbed.OMTO3d_003_ColumnAmountO3.20080101 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 3 ;
	lon = 6 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float OMTO3d_003_ColumnAmountO3(time, lat, lon) ;
		OMTO3d_003_ColumnAmountO3:_FillValue = -1.267651e+30f ;
		OMTO3d_003_ColumnAmountO3:title = "Best Total Ozone Solution" ;
		OMTO3d_003_ColumnAmountO3:UniqueFieldDefinition = "TOMS-OMI-Shared" ;
		OMTO3d_003_ColumnAmountO3:missing_value = -1.267651e+30f ;
		OMTO3d_003_ColumnAmountO3:origname = "ColumnAmountO3" ;
		OMTO3d_003_ColumnAmountO3:fullnamepath = "/HDFEOS/GRIDS/OMI Column Amount O3/Data Fields/ColumnAmountO3" ;
		OMTO3d_003_ColumnAmountO3:orig_dimname_list = "YDim XDim" ;
		OMTO3d_003_ColumnAmountO3:standard_name = "columnamounto3" ;
		OMTO3d_003_ColumnAmountO3:quantity_type = "Ozone" ;
		OMTO3d_003_ColumnAmountO3:product_short_name = "OMTO3d" ;
		OMTO3d_003_ColumnAmountO3:product_version = "003" ;
		OMTO3d_003_ColumnAmountO3:long_name = "Ozone Total Column (TOMS-like)" ;
		OMTO3d_003_ColumnAmountO3:coordinates = "time lat lon" ;
		OMTO3d_003_ColumnAmountO3:units = "DU" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	float lon(lon) ;
		lon:units = "degrees_east" ;
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
		:start_time = "2008-01-01T00:00:00Z" ;
		:end_time = "2008-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Nov 15 21:09:08 2016: ncks -d lon,-96.000,-90.1641 -d lat,33.4102,35.5195 scrubbed.OMTO3d_003_ColumnAmountO3.20080101.nc scrubbed.OMTO3d_003_ColumnAmountO3.20080101.nc" ;
data:

 OMTO3d_003_ColumnAmountO3 =
  285.9, 288.2, 289.2, 290.9, 291.7, 291.8,
  297.1, 298.7, 299.8, 303.7, 306.3, 307.3,
  312.4, 321.5, 331.5, 342, 346.1, 344.3 ;

 dataday = 2008001 ;

 lat = 33.5, 34.5, 35.5 ;

 lat_bnds =
  33, 34,
  34, 35,
  35, 36 ;

 lon = -95.5, -94.5, -93.5, -92.5, -91.5, -90.5 ;

 lon_bnds =
  -96, -95,
  -95, -94,
  -94, -93,
  -93, -92,
  -92, -91,
  -91, -90 ;

 time = 1199145600 ;

 time_bnds =
  1199145600, 1199231999 ;
}
netcdf ref {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 3 ;
	lon = 6 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float x_AIRX3STD_006_TotO3_A(time, lat, lon) ;
		x_AIRX3STD_006_TotO3_A:_FillValue = -9999.f ;
		x_AIRX3STD_006_TotO3_A:standard_name = "toto3_a" ;
		x_AIRX3STD_006_TotO3_A:quantity_type = "Ozone" ;
		x_AIRX3STD_006_TotO3_A:product_short_name = "AIRX3STD" ;
		x_AIRX3STD_006_TotO3_A:product_version = "006" ;
		x_AIRX3STD_006_TotO3_A:long_name = "Ozone Total Column (Daytime/Ascending)" ;
		x_AIRX3STD_006_TotO3_A:coordinates = "time lat lon" ;
		x_AIRX3STD_006_TotO3_A:units = "DU" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
	double lat(lat) ;
		lat:bounds = "lat_bnds" ;
		lat:format = "F5.1" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	double lon(lon) ;
		lon:bounds = "lon_bnds" ;
		lon:format = "F6.1" ;
		lon:missing_value = -9999.f ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	int time(time) ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;
	float y_OMTO3d_003_ColumnAmountO3(time, lat, lon) ;
		y_OMTO3d_003_ColumnAmountO3:_FillValue = -1.267651e+30f ;
		y_OMTO3d_003_ColumnAmountO3:title = "Best Total Ozone Solution" ;
		y_OMTO3d_003_ColumnAmountO3:UniqueFieldDefinition = "TOMS-OMI-Shared" ;
		y_OMTO3d_003_ColumnAmountO3:missing_value = -1.267651e+30f ;
		y_OMTO3d_003_ColumnAmountO3:origname = "ColumnAmountO3" ;
		y_OMTO3d_003_ColumnAmountO3:fullnamepath = "/HDFEOS/GRIDS/OMI Column Amount O3/Data Fields/ColumnAmountO3" ;
		y_OMTO3d_003_ColumnAmountO3:orig_dimname_list = "YDim XDim" ;
		y_OMTO3d_003_ColumnAmountO3:standard_name = "columnamounto3" ;
		y_OMTO3d_003_ColumnAmountO3:quantity_type = "Ozone" ;
		y_OMTO3d_003_ColumnAmountO3:product_short_name = "OMTO3d" ;
		y_OMTO3d_003_ColumnAmountO3:product_version = "003" ;
		y_OMTO3d_003_ColumnAmountO3:long_name = "Ozone Total Column (TOMS-like)" ;
		y_OMTO3d_003_ColumnAmountO3:coordinates = "time lat lon" ;
		y_OMTO3d_003_ColumnAmountO3:units = "DU" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2008-01-01T00:00:00Z" ;
		:end_time = "2008-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:matched_start_time = "2008-01-01T00:00:00Z" ;
		:matched_end_time = "2008-01-01T23:59:59Z" ;
		:userstartdate = "2008-01-01T00:00:00Z" ;
		:userenddate = "2008-01-01T23:59:59Z" ;
data:

 x_AIRX3STD_006_TotO3_A =
  293, 296.5, 300.5, 302.5, 307.5, 307.75,
  300, 300.25, 307.25, 315.25, 319.75, 325,
  317.75, 329.5, 351, 360.5, 364.75, 366.5 ;

 dataday = 2008001 ;

 lat = 33.5, 34.5, 35.5 ;

 lat_bnds =
  33, 34,
  34, 35,
  35, 36 ;

 lon = -95.5, -94.5, -93.5, -92.5, -91.5, -90.5 ;

 lon_bnds =
  -96, -95,
  -95, -94,
  -94, -93,
  -93, -92,
  -92, -91,
  -91, -90 ;

 time = 1199145600 ;

 time_bnds =
  1199145600, 1199231999 ;

 y_OMTO3d_003_ColumnAmountO3 =
  285.9, 288.2, 289.2, 290.9, 291.7, 291.8,
  297.1, 298.7, 299.8, 303.7, 306.3, 307.3,
  312.4, 321.5, 331.5, 342, 346.1, 344.3 ;
}
