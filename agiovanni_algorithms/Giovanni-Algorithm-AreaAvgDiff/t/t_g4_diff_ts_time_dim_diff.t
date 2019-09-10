##
# This tests to make sure g4_area_avg_diff_time_series can handle variables
# where the time values are different and bounds are the same.
##

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
    'program'      => "$script_path -a",
    'comparison'   => "minus",
    'name'         => 'Area Averaged Difference Time Series',
    'time-axis'    => 1,
    'temp_res'    => '3-hourly',
    'jobs'         => 5,
    'diff-exclude' => [
        qw(/calendar /center /model difference/grid_name difference/grid_type difference/level_description difference/product_short_name difference/time_statistic difference/vmax)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" )
    or die "No point diffing files";
is( $diff_rc, '', "Outcome of diff" );
exit(0);
__DATA__
netcdf sub.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 17 ;
	lon = 18 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float GLDAS_NOAH10_3H_2_0_RootMoist_inst(time, lat, lon) ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:_FillValue = -9999.f ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:fullnamepath = "/RootMoist_inst" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:long_name = "Root zone soil moisture" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:missing_value = -9999.f ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:origname = "RootMoist_inst" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:product_short_name = "GLDAS_NOAH10_3H" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:product_version = "2.0" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:quantity_type = "Soil Moisture" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:standard_name = "root_zone_soil_moisture" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:vmax = 918.21f ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:vmin = 2.f ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:coordinates = "time lat lon" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:units = "kg m-2" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	float lon(lon) ;
		lon:units = "degrees_east" ;
		lon:missing_value = -9999.f ;
		lon:_FillValue = -9999.f ;
		lon:vmin = -179.5f ;
		lon:vmax = 179.5f ;
		lon:origname = "lon" ;
		lon:fullnamepath = "/lon" ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	double time(time) ;
		time:begin_date = "20000101" ;
		time:begin_time = "000000" ;
		time:fullnamepath = "/time" ;
		time:long_name = "time" ;
		time:origname = "time" ;
		time:standard_name = "time" ;
		time:time_increment = "180" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2000-01-01T00:00:00Z" ;
		:end_time = "2000-01-01T02:59:59Z" ;
		:temporal_resolution = "3-hourly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Nov 16 15:16:57 2016: ncks -O -d lat,30.,47. -d lon,-92.0,-74.0 scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc sub.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc" ;
data:

 GLDAS_NOAH10_3H_2_0_RootMoist_inst =
  476.117, 499.337, 496.849, 501.407, 446.136, 385.926, 325.971, 404.886, 
    263.114, 342.332, 316.918, _, _, _, _, _, _, _,
  503.709, 510.614, 362.764, 446.579, 464.602, 429.015, 302.742, 261.69, 
    209.999, 335.445, 375.038, _, _, _, _, _, _, _,
  284.767, 397.194, 389.269, 418.414, 422.958, 374.657, 432.635, 342.822, 
    302.675, 295.583, 316.888, 423.232, _, _, _, _, _, _,
  412.267, 294.117, 460.966, 369.268, 442.897, 494.188, 401.286, 342.602, 
    443.133, 327.468, 130.183, 240.958, 338.45, _, _, _, _, _,
  312.406, 270.421, 427.078, 388.236, 353.72, 380.96, 424.985, 528.016, 
    484.781, 366.587, 356.31, 295.348, 285.895, 425.8, 526.578, _, _, _,
  361.704, 253.438, 276.461, 377.316, 404.554, 340.915, 429.482, 520.35, 
    564.858, 537.262, 408.586, 317.219, 529.415, 252.373, 329.93, 538.071, _, _,
  356.947, 283.545, 272.947, 334.897, 363.617, 319.076, 391.597, 478.982, 
    469.804, 459.454, 492.685, 478.654, 439.92, 461.4, 453.826, 434.539, _, _,
  441.535, 394.363, 293.333, 286.77, 328.726, 364.376, 337.038, 312.896, 
    500.449, 479.861, 497.247, 601.521, 460.781, 384.342, 589.325, 603.179, 
    _, _,
  315.49, 250.682, 231.824, 263.894, 276.513, 364.085, 347.545, 348.925, 
    345.791, 499.395, 560.81, 631.11, 498.844, 531.128, 334.759, 495.234, 
    331.57, _,
  180.134, 180.012, 240.864, 244.736, 209.247, 280.96, 225.332, 201.437, 
    227.041, 363.921, 476.818, 612.688, 567.95, 544.879, 374.287, 304.201, 
    314.63, 443.177,
  169.313, 196.608, 232.045, 258.62, 217.561, 206.718, 205.905, 211.481, 
    218.422, 251.363, 308.861, 412.285, 493.043, 538.414, 506.523, 454.694, 
    380.625, 223.946,
  187.541, 184.668, 241.583, 266.286, 191.271, 179.023, 167.912, 221.985, 
    231.807, _, 271.753, 381.578, 537.826, 537.061, 490.804, 509.948, 
    541.816, 555.36,
  180.924, 139.83, 205.723, 252.156, _, _, 174.76, 145.628, 128.56, 249.941, 
    _, _, 357.805, 416.8, 376.009, 386.028, 450.325, 500.44,
  175.319, 180.57, 226.6, 208.825, _, _, 228.042, 159.404, 166.679, _, 271.1, 
    250.893, 162.999, _, _, 459.51, 469.093, 516.597,
  200.555, 301.559, 215.5, 131.881, _, _, 158.188, 147.863, 319.21, _, _, 
    290.224, 379.077, 440.69, 489.055, 464.53, 462.85, 507.03,
  401.976, 479.059, 456.769, 417.986, 336.183, _, _, 178.827, _, _, _, _, 
    582.149, 567.774, 542.881, 554.48, 611.783, 453.805,
  397.765, 596.273, 488.32, 557.229, 477.351, 473.64, 344.67, 525.499, 
    498.748, 520.828, 549.632, 558.007, 568.553, 563.7, 459.528, 468.109, 
    610.97, 569.737 ;

 lat = 30.5, 31.5, 32.5, 33.5, 34.5, 35.5, 36.5, 37.5, 38.5, 39.5, 40.5, 
    41.5, 42.5, 43.5, 44.5, 45.5, 46.5 ;

 lat_bnds =
  30, 31,
  31, 32,
  32, 33,
  33, 34,
  34, 35,
  35, 36,
  36, 37,
  37, 38,
  38, 39,
  39, 40,
  40, 41,
  41, 42,
  42, 43,
  43, 44,
  44, 45,
  45, 46,
  46, 47 ;

 lon = -91.5, -90.5, -89.5, -88.5, -87.5, -86.5, -85.5, -84.5, -83.5, -82.5, 
    -81.5, -80.5, -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 lon_bnds =
  -92, -91,
  -91, -90,
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
  -77, -76,
  -76, -75,
  -75, -74 ;

 time = 946684800 ;

 time_bnds =
  946684800, 946695599 ;
}
netcdf sub.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010300 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 17 ;
	lon = 18 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float GLDAS_NOAH10_3H_2_0_RootMoist_inst(time, lat, lon) ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:_FillValue = -9999.f ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:fullnamepath = "/RootMoist_inst" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:long_name = "Root zone soil moisture" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:missing_value = -9999.f ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:origname = "RootMoist_inst" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:product_short_name = "GLDAS_NOAH10_3H" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:product_version = "2.0" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:quantity_type = "Soil Moisture" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:standard_name = "root_zone_soil_moisture" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:vmax = 918.979f ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:vmin = 2.f ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:coordinates = "time lat lon" ;
		GLDAS_NOAH10_3H_2_0_RootMoist_inst:units = "kg m-2" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	float lon(lon) ;
		lon:units = "degrees_east" ;
		lon:missing_value = -9999.f ;
		lon:_FillValue = -9999.f ;
		lon:vmin = -179.5f ;
		lon:vmax = 179.5f ;
		lon:origname = "lon" ;
		lon:fullnamepath = "/lon" ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	double time(time) ;
		time:begin_date = "20000101" ;
		time:begin_time = "030000" ;
		time:fullnamepath = "/time" ;
		time:long_name = "time" ;
		time:origname = "time" ;
		time:standard_name = "time" ;
		time:time_increment = "180" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2000-01-01T03:00:00Z" ;
		:end_time = "2000-01-01T05:59:59Z" ;
		:temporal_resolution = "3-hourly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Nov 16 15:17:15 2016: ncks -O -d lat,30.,47. -d lon,-92.0,-74.0 scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010300.nc sub.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010300.nc" ;
data:

 GLDAS_NOAH10_3H_2_0_RootMoist_inst =
  476.118, 499.332, 496.811, 501.349, 446.078, 385.836, 325.895, 404.779, 
    263.08, 342.296, 316.877, _, _, _, _, _, _, _,
  503.656, 510.612, 362.703, 446.551, 464.563, 428.933, 302.681, 261.543, 
    209.929, 335.389, 374.988, _, _, _, _, _, _, _,
  284.68, 397.165, 389.257, 418.403, 422.943, 374.584, 432.504, 342.748, 
    302.564, 295.497, 316.824, 423.124, _, _, _, _, _, _,
  412.248, 294.108, 460.969, 369.259, 442.852, 494.135, 401.238, 342.5, 
    443.064, 327.446, 130.157, 240.896, 338.33, _, _, _, _, _,
  314.146, 272.363, 427.04, 388.251, 353.659, 381.492, 425.56, 527.884, 
    484.888, 366.551, 356.279, 295.248, 285.762, 425.658, 526.372, _, _, _,
  361.694, 256.542, 277.76, 377.237, 404.5, 340.815, 429.428, 520.657, 
    564.785, 537.225, 408.491, 317.211, 529.351, 252.275, 329.871, 537.897, 
    _, _,
  356.989, 283.572, 272.909, 334.839, 363.555, 319.012, 391.613, 479.01, 
    469.8, 459.43, 492.675, 478.546, 439.823, 461.332, 453.736, 440.312, _, _,
  441.5, 394.415, 293.353, 286.781, 328.686, 364.304, 338.027, 312.939, 
    500.79, 479.85, 497.233, 601.472, 460.721, 384.335, 589.177, 603.01, _, _,
  315.479, 250.674, 231.856, 263.893, 276.644, 365.352, 348.979, 348.883, 
    345.773, 499.39, 560.759, 630.931, 498.832, 531.054, 334.737, 495.131, 
    331.532, _,
  180.129, 180.003, 240.874, 244.738, 209.528, 280.909, 225.303, 201.4, 
    227.016, 363.91, 476.773, 612.598, 567.813, 544.827, 374.209, 304.227, 
    314.834, 442.967,
  169.292, 196.583, 232.039, 258.597, 217.553, 206.701, 205.879, 211.452, 
    218.392, 251.351, 308.855, 412.28, 492.987, 538.352, 506.444, 454.62, 
    380.505, 223.845,
  187.527, 184.655, 241.596, 266.267, 191.206, 178.985, 167.868, 221.881, 
    231.734, _, 271.735, 381.553, 537.78, 537.017, 490.756, 509.909, 541.777, 
    555.255,
  180.912, 139.82, 205.712, 252.137, _, _, 174.689, 145.574, 128.544, 
    249.895, _, _, 357.773, 416.756, 375.973, 386.004, 450.26, 500.357,
  175.31, 180.559, 226.588, 208.808, _, _, 227.971, 159.37, 166.655, _, 
    271.074, 250.881, 162.993, _, _, 459.396, 468.95, 516.507,
  200.545, 301.539, 215.484, 131.873, _, _, 158.163, 147.831, 319.175, _, _, 
    290.216, 379.014, 440.601, 488.93, 464.412, 462.704, 506.913,
  401.953, 479.033, 456.75, 417.971, 336.159, _, _, 178.809, _, _, _, _, 
    581.956, 567.656, 542.762, 554.378, 611.722, 453.706,
  397.71, 596.218, 488.281, 557.214, 477.331, 473.615, 344.652, 525.452, 
    498.722, 520.797, 549.559, 557.899, 568.436, 563.57, 459.453, 468.021, 
    610.823, 569.597 ;

 lat = 30.5, 31.5, 32.5, 33.5, 34.5, 35.5, 36.5, 37.5, 38.5, 39.5, 40.5, 
    41.5, 42.5, 43.5, 44.5, 45.5, 46.5 ;

 lat_bnds =
  30, 31,
  31, 32,
  32, 33,
  33, 34,
  34, 35,
  35, 36,
  36, 37,
  37, 38,
  38, 39,
  39, 40,
  40, 41,
  41, 42,
  42, 43,
  43, 44,
  44, 45,
  45, 46,
  46, 47 ;

 lon = -91.5, -90.5, -89.5, -88.5, -87.5, -86.5, -85.5, -84.5, -83.5, -82.5, 
    -81.5, -80.5, -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 lon_bnds =
  -92, -91,
  -91, -90,
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
  -77, -76,
  -76, -75,
  -75, -74 ;

 time = 946695600 ;

 time_bnds =
  946695600, 946706399 ;
}
netcdf regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010000 {
dimensions:
	lon = 20 ;
	lat = 19 ;
	time = UNLIMITED ; // (1 currently)
	nv = 2 ;
	lonv = 2 ;
variables:
	float lon(lon) ;
		lon:_FillValue = -9999.f ;
		lon:bounds = "lon_bnds" ;
		lon:fullnamepath = "/lon" ;
		lon:long_name = "Longitude" ;
		lon:missing_value = -9999.f ;
		lon:origname = "lon" ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
		lon:vmax = 179.5f ;
		lon:vmin = -179.5f ;
	float lat(lat) ;
		lat:long_name = "Latitude" ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	double time(time) ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:begin_date = "20000101" ;
		time:begin_time = "000000" ;
		time:fullnamepath = "/time" ;
		time:long_name = "time" ;
		time:origname = "time" ;
		time:standard_name = "time" ;
		time:time_increment = "180" ;
		time:bounds = "time_bnds" ;
	float GLDAS_NOAH025_3H_2_0_RootMoist_inst(time, lat, lon) ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:long_name = "Root zone soil moisture" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:units = "kg m-2" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:grid_name = "grid01" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:grid_type = "linear" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:level_description = "Earth surface" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:time_statistic = "instantaneous" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:missing_value = -9999.f ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:_FillValue = -9999.f ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:fullnamepath = "/RootMoist_inst" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:origname = "RootMoist_inst" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:product_short_name = "GLDAS_NOAH025_3H" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:product_version = "2.0" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:quantity_type = "Soil Moisture" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:standard_name = "root_zone_soil_moisture" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:vmax = 918.635f ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:vmin = 2.f ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:coordinates = "time lat lon" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:calendar = "standard" ;
		:model = "geos/das" ;
		:center = "gsfc" ;
		:history = "Tue Nov 15 21:10:43 2016: ncap2 -O -s lon=lon.convert(5\n",
			");lat=lat.convert(5\n",
			"); /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010000.nc /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010000.nc\n",
			"Tue Nov 15 21:10:43 2016: ncks -A -v lon -d lon,86,105 -d lat,120,138 /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc.ref /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010000.nc\n",
			"Tue Nov 15 21:10:42 2016: ncks -A -v time /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///subsetted.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010000.nc /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010000.nc\n",
			"Tue Nov 15 21:10:42 2016: ncrename -O -v z,GLDAS_NOAH025_3H_2_0_RootMoist_inst /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010000.nc /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010000.nc.rename" ;
		:history_of_appended_files = "Tue Nov 15 21:10:43 2016: Appended file /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc.ref had following \"history\" attribute:\n",
			"Tue Nov 15 21:10:42 2016: ncap2 -O -s lon=double(lon);lat=double(lat); -o /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc.ref /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc\n",
			"Tue Nov 15 21:10:42 2016: Appended file /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///subsetted.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010000.nc had no \"history\" attribute\n",
			"" ;
		:NCO = "\"4.5.3\"" ;
		:start_time = "2000-01-01T00:00:00Z" ;
		:end_time = "2000-01-01T02:59:59Z" ;
		:temporal_resolution = "3-hourly" ;
		:nco_openmp_thread_number = 1 ;
data:

 lon = -93.5, -92.5, -91.5, -90.5, -89.5, -88.5, -87.5, -86.5, -85.5, -84.5, 
    -83.5, -82.5, -81.5, -80.5, -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 lat = 30.5, 31.5, 32.5, 33.5, 34.5, 35.5, 36.5, 37.5, 38.5, 39.5, 40.5, 
    41.5, 42.5, 43.5, 44.5, 45.5, 46.5, 47.5, 48.5 ;

 time = 946695599 ;

 GLDAS_NOAH025_3H_2_0_RootMoist_inst =
  559.0694, 498.7616, 425.9174, 417.6713, 448.8998, 407.7914, 386.1704, 
    311.0675, 293.1987, 330.2928, 281.8844, 393.5629, 385.9734, _, _, _, _, 
    _, _, _,
  461.877, 494.258, 479.595, 448.8105, 367.5264, 437.8601, 443.017, 411.9799, 
    297.7543, 249.9731, 229.6701, 295.5032, 453.2178, _, _, _, _, _, _, _,
  449.957, 449.3377, 348.3425, 382.283, 431.0203, 433.6064, 433.258, 
    361.0623, 427.8439, 354.2535, 313.5677, 295.612, 314.2398, 393.7422, 
    314.611, _, _, _, _, _,
  399.1924, 456.2437, 387.0335, 314.0029, 415.9272, 407.3031, 458.7028, 
    453.5419, 447.2235, 337.2377, 432.8198, 360.2722, 196.9346, 304.0179, 
    393.2918, 398.144, _, _, _, _,
  430.9384, 389.5103, 320.4193, 293.4889, 380.1038, 382.7614, 355.9085, 
    375.9047, 397.2992, 457.6331, 470.4546, 347.9855, 382.4843, 331.7326, 
    300.6218, 354.9655, 425.2663, 586.584, _, _,
  391.7828, 358.0446, 319.8109, 257.2134, 284.4412, 345.6278, 394.2957, 
    352.9631, 419.3008, 462.5164, 539.641, 504.6139, 408.0402, 334.7162, 
    452.5075, 265.7613, 328.2207, 536.0341, 613.7919, _,
  415.2481, 404.6093, 353.3777, 288.1545, 251.1918, 321.7308, 348.1148, 
    289.5756, 384.1416, 471.8045, 447.0453, 440.7476, 477.0534, 460.2985, 
    423.6071, 442.3401, 432.9396, 383.7368, _, _,
  332.2675, 340.2635, 414.332, 380.0703, 285.7408, 278.4196, 316.3406, 
    342.1424, 325.803, 311.9572, 470.4677, 464.2176, 514.5862, 566.8687, 
    466.4295, 427.8068, 485.3103, 485.2131, 403.1022, _,
  299.5558, 281.0648, 306.7953, 251.5442, 228.8455, 258.335, 276.2421, 
    349.5118, 307.8461, 335.9335, 346.7124, 465.2816, 527.4102, 590.9244, 
    507.484, 482.4814, 399.0612, 480.1447, 331.8036, _,
  179.9691, 167.1679, 174.9594, 185.8678, 228.0251, 242.667, 202.9167, 
    266.8036, 234.9295, 214.7305, 244.882, 362.5728, 484.8487, 558.998, 
    547.1984, 525.2299, 344.1287, 305.6722, 309.577, 410.5065,
  132.9339, 130.4127, 149.9283, 190.9943, 215.1997, 246.9207, 221.4896, 
    189.23, 207.1854, 209.9288, 208.947, 238.8282, 299.5543, 392.8488, 
    455.9022, 502.7669, 503.4745, 431.1519, 379.6583, 356.0699,
  154.1246, 181.5058, 187.8039, 179.9411, 236.6613, 238.848, 148.94, 
    147.9286, 164.0232, 202.2299, 192.3939, 191.6739, 272.1774, 357.3075, 
    503.8694, 537.3596, 500.275, 499.9948, 534.3325, 550.5068,
  178.7168, 191.7047, 190.6045, 147.1529, 196.0542, 228.7626, 130.678, 
    121.1448, 153.0071, 133.2683, 122.5997, 219.1798, 219.3282, 241.467, 
    323.682, 371.3481, 362.523, 373.2864, 441.6559, 457.9513,
  179.3707, 206.579, 173.0685, 164.9676, 186.1631, 189.2862, 130.6905, 
    119.9327, 157.6809, 151.5599, 157.3547, 182.074, 260.2308, 246.9119, 
    184.5103, 263.3462, 232.1608, 414.1247, 465.4898, 532.1227,
  148.9821, 202.8799, 181.4565, 217.7386, 170.6605, 168.9809, 142.3893, 
    114.6348, 160.3898, 155.1917, 178.3692, _, 314.2917, 296.6277, 374.2753, 
    433.9085, 457.1753, 444.8205, 461.713, 531.4354,
  134.5093, 241.5821, 351.6527, 443.8899, 355.1188, 384.2227, 311.4622, 
    325.8337, 226.827, 209.4593, 240.6332, 443.0117, 467.22, 531.0859, 
    573.0344, 565.9145, 538.5717, 550.5406, 503.2234, 475.5301,
  362.7816, 398.1735, 481.623, 515.6218, 495.1052, 468.3279, 427.7404, 
    367.9922, 380.0011, 449.4089, 491.709, 518.8583, 543.6296, 583.5173, 
    564.7752, 562.2474, 506.8027, 491.2358, 653.6041, 570.2313,
  453.3676, 518.6115, 524.0626, 525.7252, 509.498, 298.7512, _, _, _, 
    533.4583, 537.1948, 542.4022, 553.0139, 558.1187, 561.4484, 580.1319, 
    506.1474, 480.0323, 521.7584, 561.1666,
  615.9847, 504.3701, 496.6876, 505.0366, 499.6064, _, _, 519.79, 524.9065, 
    535.2687, 545.5986, 547.9318, 552.6596, 551.7307, 541.8106, 571.619, 
    566.3449, 520.7329, 581.9829, 520.5623 ;

 time_bnds =
  946684800, 946695599 ;

 lon_bnds =
  -94, -93,
  -93, -92,
  -92, -91,
  -91, -90,
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
  -77, -76,
  -76, -75,
  -75, -74 ;
}
netcdf regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010300 {
dimensions:
	lon = 20 ;
	lat = 19 ;
	time = UNLIMITED ; // (1 currently)
	nv = 2 ;
	lonv = 2 ;
variables:
	float lon(lon) ;
		lon:_FillValue = -9999.f ;
		lon:bounds = "lon_bnds" ;
		lon:fullnamepath = "/lon" ;
		lon:long_name = "Longitude" ;
		lon:missing_value = -9999.f ;
		lon:origname = "lon" ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
		lon:vmax = 179.5f ;
		lon:vmin = -179.5f ;
	float lat(lat) ;
		lat:long_name = "Latitude" ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	double time(time) ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:begin_date = "20000101" ;
		time:begin_time = "030000" ;
		time:fullnamepath = "/time" ;
		time:long_name = "time" ;
		time:origname = "time" ;
		time:standard_name = "time" ;
		time:time_increment = "180" ;
		time:bounds = "time_bnds" ;
	float GLDAS_NOAH025_3H_2_0_RootMoist_inst(time, lat, lon) ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:long_name = "Root zone soil moisture" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:units = "kg m-2" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:grid_name = "grid01" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:grid_type = "linear" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:level_description = "Earth surface" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:time_statistic = "instantaneous" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:missing_value = -9999.f ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:_FillValue = -9999.f ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:fullnamepath = "/RootMoist_inst" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:origname = "RootMoist_inst" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:product_short_name = "GLDAS_NOAH025_3H" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:product_version = "2.0" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:quantity_type = "Soil Moisture" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:standard_name = "root_zone_soil_moisture" ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:vmax = 918.484f ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:vmin = 2.f ;
		GLDAS_NOAH025_3H_2_0_RootMoist_inst:coordinates = "time lat lon" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:calendar = "standard" ;
		:model = "geos/das" ;
		:center = "gsfc" ;
		:history = "Tue Nov 15 21:10:43 2016: ncap2 -O -s lon=lon.convert(5\n",
			");lat=lat.convert(5\n",
			"); /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010300.nc /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010300.nc\n",
			"Tue Nov 15 21:10:43 2016: ncks -A -v lon -d lon,86,105 -d lat,120,138 /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc.ref /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010300.nc\n",
			"Tue Nov 15 21:10:42 2016: ncks -A -v time /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///subsetted.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010300.nc /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010300.nc\n",
			"Tue Nov 15 21:10:42 2016: ncrename -O -v z,GLDAS_NOAH025_3H_2_0_RootMoist_inst /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010300.nc /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193/regrid.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010300.nc.rename" ;
		:history_of_appended_files = "Tue Nov 15 21:10:43 2016: Appended file /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc.ref had following \"history\" attribute:\n",
			"Tue Nov 15 21:10:42 2016: ncap2 -O -s lon=double(lon);lat=double(lat); -o /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc.ref /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///scrubbed.GLDAS_NOAH10_3H_2_0_RootMoist_inst.200001010000.nc\n",
			"Tue Nov 15 21:10:42 2016: Appended file /var/giovanni/session/9CD835C2-AB72-11E6-B5A0-F58AF03E37D9/EBBEB9EA-AB77-11E6-8ADD-DDC36EBD831B/EBC1D6FC-AB77-11E6-93E3-EF0554C09193///subsetted.GLDAS_NOAH025_3H_2_0_RootMoist_inst.200001010300.nc had no \"history\" attribute\n",
			"" ;
		:NCO = "\"4.5.3\"" ;
		:start_time = "2000-01-01T03:00:00Z" ;
		:end_time = "2000-01-01T05:59:59Z" ;
		:temporal_resolution = "3-hourly" ;
		:nco_openmp_thread_number = 1 ;
data:

 lon = -93.5, -92.5, -91.5, -90.5, -89.5, -88.5, -87.5, -86.5, -85.5, -84.5, 
    -83.5, -82.5, -81.5, -80.5, -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 lat = 30.5, 31.5, 32.5, 33.5, 34.5, 35.5, 36.5, 37.5, 38.5, 39.5, 40.5, 
    41.5, 42.5, 43.5, 44.5, 45.5, 46.5, 47.5, 48.5 ;

 time = 946706399 ;

 GLDAS_NOAH025_3H_2_0_RootMoist_inst =
  559.0384, 498.7439, 425.8857, 417.6431, 448.8723, 407.7541, 386.1206, 
    310.9885, 293.1255, 330.1877, 281.8063, 393.5345, 385.9325, _, _, _, _, 
    _, _, _,
  461.8287, 494.2189, 479.5453, 448.7843, 367.4726, 437.8351, 442.9866, 
    411.9103, 297.6785, 249.8536, 229.5857, 295.4566, 453.1793, _, _, _, _, 
    _, _, _,
  450.0618, 449.3084, 348.2882, 382.2628, 431.0044, 433.5941, 433.2444, 
    360.9836, 427.7635, 354.1776, 313.4812, 295.542, 314.1818, 393.6457, 
    314.481, _, _, _, _, _,
  399.8913, 456.4647, 387.2213, 314.2034, 415.946, 407.298, 458.6812, 
    453.5633, 447.2375, 337.1814, 432.7844, 360.2491, 196.9077, 303.94, 
    393.1799, 398.0075, _, _, _, _,
  431.0149, 389.6648, 321.6173, 295.0244, 380.4084, 382.7881, 355.9075, 
    376.2541, 397.6651, 457.6696, 470.4948, 347.9716, 382.4586, 331.6502, 
    300.507, 354.8409, 425.1096, 586.44, _, _,
  391.7377, 358.0539, 320.2933, 259.2326, 285.4368, 345.7182, 394.2562, 
    352.948, 419.3662, 462.6924, 539.6492, 504.5797, 407.9881, 334.6618, 
    452.4241, 265.6547, 328.2009, 537.1062, 618.235, _,
  415.2193, 404.5926, 353.4179, 288.4907, 251.3685, 321.7222, 348.0799, 
    289.5324, 384.2346, 471.8834, 447.0567, 440.732, 477.0361, 460.216, 
    423.5219, 442.2807, 433.382, 386.7623, _, _,
  332.243, 340.2531, 414.316, 380.0847, 285.7636, 278.4376, 316.3492, 
    342.3276, 326.5239, 312.1506, 470.6179, 464.2318, 514.5668, 566.821, 
    466.3976, 427.7922, 485.2478, 485.4536, 403.0717, _,
  299.5576, 281.0536, 306.7788, 251.5266, 228.8721, 258.358, 276.476, 
    350.4715, 309.0063, 335.9935, 346.6972, 465.2742, 527.3705, 590.8372, 
    507.4587, 482.44, 399.0321, 480.057, 331.7473, _,
  179.9565, 167.1568, 174.9518, 185.8578, 228.0208, 242.6931, 203.1088, 
    266.9888, 235.1103, 214.6889, 244.8569, 362.5611, 484.8191, 558.9474, 
    547.1208, 525.1796, 344.0681, 305.5958, 309.6367, 410.3577,
  132.9459, 130.4419, 149.9087, 190.9738, 215.1924, 246.9005, 221.4842, 
    189.203, 207.1562, 209.8877, 208.9165, 238.8174, 299.5464, 392.8406, 
    455.863, 502.7173, 503.4205, 431.0854, 379.5679, 355.9356,
  154.1677, 181.5241, 187.7862, 179.9266, 236.6542, 238.8302, 148.8704, 
    147.8805, 163.9728, 202.1496, 192.3314, 191.6549, 272.1652, 357.2924, 
    503.8416, 537.3313, 500.2486, 499.9661, 534.2898, 550.4236,
  178.7161, 191.7012, 190.594, 147.1434, 196.0433, 228.7449, 130.647, 
    121.0574, 152.9361, 133.2158, 122.5758, 219.1487, 219.303, 241.4515, 
    323.6636, 371.3264, 362.4971, 373.2591, 441.6058, 457.8868,
  179.3667, 206.574, 173.0608, 164.9576, 186.1504, 189.2714, 130.6565, 
    119.8584, 157.6151, 151.5182, 157.3333, 182.0604, 260.2101, 246.901, 
    184.5005, 263.3258, 232.1227, 414.032, 465.3767, 532.0354,
  148.9825, 202.875, 181.4467, 217.7219, 170.647, 168.9701, 142.365, 
    114.6003, 160.3692, 155.1658, 178.3421, _, 314.2759, 296.618, 374.2124, 
    433.8305, 457.0787, 444.7149, 461.5864, 531.3095,
  134.5032, 241.5714, 351.6277, 443.8689, 355.0991, 384.2112, 311.4467, 
    325.824, 226.814, 209.4458, 240.6229, 443.0064, 467.2163, 530.9689, 
    572.8809, 565.7928, 538.4604, 550.4457, 503.1436, 475.4487,
  362.7731, 398.1505, 481.5801, 515.5827, 495.0822, 468.3184, 427.7335, 
    367.9825, 379.9864, 449.3854, 491.6828, 518.8265, 543.577, 583.4436, 
    564.6605, 562.1299, 506.7143, 491.1429, 653.4671, 570.0995,
  453.3466, 518.5692, 524.0062, 525.6724, 509.451, 298.7425, _, _, _, 
    533.3926, 537.1302, 542.3396, 552.9391, 558.0368, 561.3697, 580.0491, 
    506.0768, 479.9613, 521.681, 561.0757,
  615.9559, 504.3191, 496.639, 504.9939, 499.5733, _, _, 519.73, 524.8538, 
    535.2114, 545.5537, 547.878, 552.5975, 551.6638, 541.7541, 571.5536, 
    566.2731, 520.6769, 581.9194, 520.5128 ;

 time_bnds =
  946695600, 946706399 ;

 lon_bnds =
  -94, -93,
  -93, -92,
  -92, -91,
  -91, -90,
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
  -77, -76,
  -76, -75,
  -75, -74 ;
}
netcdf ref {
dimensions:
	time = UNLIMITED ; // (2 currently)
	nv = 2 ;
variables:
	float difference(time) ;
		difference:_FillValue = -9999.f ;
		difference:long_name = "Root zone soil moisture minus Root zone soil moisture" ;
		difference:units = "kg m-2" ;
		difference:grid_name = "grid01" ;
		difference:grid_type = "linear" ;
		difference:level_description = "Earth surface" ;
		difference:time_statistic = "instantaneous" ;
		difference:missing_value = -9999.f ;
		difference:fullnamepath = "/RootMoist_inst" ;
		difference:origname = "RootMoist_inst" ;
		difference:product_short_name = "GLDAS_NOAH025_3H" ;
		difference:product_version = "2.0" ;
		difference:quantity_type = "Soil Moisture" ;
		difference:standard_name = "root_zone_soil_moisture" ;
		difference:vmax = 918.635f ;
		difference:vmin = 2.f ;
		difference:coordinates = "time" ;
		difference:cell_methods = "lat,lon: mean" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	double time_GLDAS_NOAH025_3H_2_0_RootMoist_inst(time) ;
		time_GLDAS_NOAH025_3H_2_0_RootMoist_inst:begin_date = "20000101" ;
		time_GLDAS_NOAH025_3H_2_0_RootMoist_inst:begin_time = "000000" ;
		time_GLDAS_NOAH025_3H_2_0_RootMoist_inst:bounds = "time_bnds_GLDAS_NOAH025_3H_2_0_RootMoist_inst" ;
		time_GLDAS_NOAH025_3H_2_0_RootMoist_inst:fullnamepath = "/time" ;
		time_GLDAS_NOAH025_3H_2_0_RootMoist_inst:long_name = "Time for GLDAS_NOAH025_3H_2_0_RootMoist_inst" ;
		time_GLDAS_NOAH025_3H_2_0_RootMoist_inst:origname = "time" ;
		time_GLDAS_NOAH025_3H_2_0_RootMoist_inst:standard_name = "time" ;
		time_GLDAS_NOAH025_3H_2_0_RootMoist_inst:time_increment = "180" ;
		time_GLDAS_NOAH025_3H_2_0_RootMoist_inst:units = "seconds since 1970-01-01 00:00:00" ;
	double time_GLDAS_NOAH10_3H_2_0_RootMoist_inst(time) ;
		time_GLDAS_NOAH10_3H_2_0_RootMoist_inst:begin_date = "20000101" ;
		time_GLDAS_NOAH10_3H_2_0_RootMoist_inst:begin_time = "000000" ;
		time_GLDAS_NOAH10_3H_2_0_RootMoist_inst:bounds = "time_bnds_GLDAS_NOAH10_3H_2_0_RootMoist_inst" ;
		time_GLDAS_NOAH10_3H_2_0_RootMoist_inst:fullnamepath = "/time" ;
		time_GLDAS_NOAH10_3H_2_0_RootMoist_inst:long_name = "Time for GLDAS_NOAH10_3H_2_0_RootMoist_inst" ;
		time_GLDAS_NOAH10_3H_2_0_RootMoist_inst:origname = "time" ;
		time_GLDAS_NOAH10_3H_2_0_RootMoist_inst:standard_name = "time" ;
		time_GLDAS_NOAH10_3H_2_0_RootMoist_inst:time_increment = "180" ;
		time_GLDAS_NOAH10_3H_2_0_RootMoist_inst:units = "seconds since 1970-01-01 00:00:00" ;
	int time_bnds_GLDAS_NOAH025_3H_2_0_RootMoist_inst(time, nv) ;
		time_bnds_GLDAS_NOAH025_3H_2_0_RootMoist_inst:units = "seconds since 1970-01-01 00:00:00" ;
	int time_bnds_GLDAS_NOAH10_3H_2_0_RootMoist_inst(time, nv) ;
		time_bnds_GLDAS_NOAH10_3H_2_0_RootMoist_inst:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:calendar = "standard" ;
		:model = "geos/das" ;
		:center = "gsfc" ;
		:NCO = "\"4.5.3\"" ;
		:start_time = "2000-01-01T00:00:00Z" ;
		:end_time = "2000-01-01T05:59:59Z" ;
		:temporal_resolution = "3-hourly" ;
		:nco_openmp_thread_number = 1 ;
		:nco_input_file_number = 2 ;
		:nco_input_file_list = "/tmp/Zy4nNDqdug/testAlgorithm.GLDAS_NOAH10_3H_2_0_RootMoist_inst+GLDAS_NOAH025_3H_2_0_RootMoist_inst.20000101-20000101.92W_30N_74W_47N.nc.0 /tmp/Zy4nNDqdug/testAlgorithm.GLDAS_NOAH10_3H_2_0_RootMoist_inst+GLDAS_NOAH025_3H_2_0_RootMoist_inst.20000101-20000101.92W_30N_74W_47N.nc.1" ;
		:userstartdate = "2000-01-01T00:00:00Z" ;
		:userenddate = "2000-01-01T05:59:59Z" ;
data:

 difference = -12.27001, -12.2679 ;

 time = 946684800, 946695600 ;

 time_GLDAS_NOAH025_3H_2_0_RootMoist_inst = 946695599, 946706399 ;

 time_GLDAS_NOAH10_3H_2_0_RootMoist_inst = 946684800, 946695600 ;

 time_bnds_GLDAS_NOAH025_3H_2_0_RootMoist_inst =
  946684800, 946695599,
  946695600, 946706399 ;

 time_bnds_GLDAS_NOAH10_3H_2_0_RootMoist_inst =
  946684800, 946695599,
  946695600, 946706399 ;
}





