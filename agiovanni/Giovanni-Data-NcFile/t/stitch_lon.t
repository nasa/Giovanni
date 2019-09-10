#$Id: stitch_lon.t,v 1.3 2014/03/03 01:11:37 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 7;
BEGIN { use_ok('Giovanni::Data::NcFile') }
my $cleanup = defined( $ENV{'CLEANUP'} ) ? $ENV{'CLEANUP'} : 1;
my $dir = File::Temp::tempdir( CLEANUP => $cleanup );
my $ra_cdl = Giovanni::Data::NcFile::read_cdl_data_block();
foreach my $run ( 0 .. 1 ) {
    my $west_nc  = "$dir/west$run.nc";
    my $east_nc  = "$dir/east$run.nc";
    my $outfile  = "$dir/stitched$run.nc";
    my $ref_file = "$dir/ref$run.nc";
    Giovanni::Data::NcFile::write_netcdf_file( $west_nc,
        $ra_cdl->[ $run * 3 + 0 ] )
        or die "Could not write netcdf file\n";
    Giovanni::Data::NcFile::write_netcdf_file( $east_nc,
        $ra_cdl->[ $run * 3 + 1 ] )
        or die "Could not write netcdf file\n";
    Giovanni::Data::NcFile::write_netcdf_file( $ref_file,
        $ra_cdl->[ $run * 3 + 2 ] )
        or die "Could not write netcdf file\n";
    ok( Giovanni::Data::NcFile::stitch_lon( 1, $west_nc, $east_nc, $outfile ),
        "Stitch on longitude"
    );
    ok( -e $outfile, "Output file $outfile exists" );
    is( Giovanni::Data::NcFile::diff_netcdf_files( $ref_file, $outfile ),'', 
        "Compare output file to reference" );
}
exit(0);

__DATA__
netcdf west {
dimensions:
	time = 1 ;
	lat = 5 ;
	lon = 5 ;
variables:
	float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
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
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sun Mar  2 18:46:33 2014: ncks -d lat,-30.,30. -d lon,120.,180. subsampled.nc west.nc\n",
			"Sun Mar  2 18:43:16 2014: ncks -d lat,,,12 -d lon,,,12 scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20090101.nc subsampled.nc" ;
		:NCO = "4.2.2" ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, _, _, _, _,
  _, _, _, _, _,
  _, _, _, _, 0.211,
  _, _, _, 0.075, 0.142,
  0.115, _, 0.043, 0.038, 0.055 ;

 dataday = 2009001 ;

 lat = -29.5, -17.5, -5.5, 6.5, 18.5 ;

 lon = 120.5, 132.5, 144.5, 156.5, 168.5 ;

 time = 1230768000 ;
}
netcdf east {
dimensions:
	time = 1 ;
	lat = 5 ;
	lon = 5 ;
variables:
	float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
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
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sun Mar  2 18:47:37 2014: ncks -d lat,-30.,30. -d lon,-180.,-120. subsampled.nc east.nc\n",
			"Sun Mar  2 18:43:16 2014: ncks -d lat,,,12 -d lon,,,12 scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20090101.nc subsampled.nc" ;
		:NCO = "4.2.2" ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.054, _, 0.12, _, 0.049,
  0.117, _, _, _, _,
  _, 0.074, 0.186, 0.08400001, 0.133,
  0.103, 0.144, 0.119, 0.156, _,
  0.08400001, 0.098, 0.115, 0.114, _ ;

 dataday = 2009001 ;

 lat = -29.5, -17.5, -5.5, 6.5, 18.5 ;

 lon = -179.5, -167.5, -155.5, -143.5, -131.5 ;

 time = 1230768000 ;
}
netcdf stitched {
dimensions:
	lon = 10 ;
	time = UNLIMITED ; // (1 currently)
	lat = 5 ;
variables:
	float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;
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
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon Mar  3 00:39:25 2014: ncpdq -a time,lat,lon -O -o tmp/bVZlKmWVUY/stitched.nc tmp/bVZlKmWVUY/stitched.nc\n",
			"Mon Mar  3 00:39:25 2014: ncrcat -O tmp/bVZlKmWVUY/west.nc tmp/bVZlKmWVUY/east.nc tmp/bVZlKmWVUY/stitched.nc\n",
			"Mon Mar  3 00:39:25 2014: ncks --mk_rec_dmn lon -O -o tmp/bVZlKmWVUY/west.nc tmp/bVZlKmWVUY/west.nc\n",
			"Mon Mar  3 00:39:25 2014: ncpdq -a lon,time,lat -O -o tmp/bVZlKmWVUY/west.nc tmp/bVZlKmWVUY/west.nc\n",
			"Sun Mar  2 18:46:33 2014: ncks -d lat,-30.,30. -d lon,120.,180. subsampled.nc west.nc\n",
			"Sun Mar  2 18:43:16 2014: ncks -d lat,,,12 -d lon,,,12 scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20090101.nc subsampled.nc" ;
		:NCO = "4.3.1" ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, _, _, _, _, 0.054, _, 0.12, _, 0.049,
  _, _, _, _, _, 0.117, _, _, _, _,
  _, _, _, _, 0.211, _, 0.074, 0.186, 0.08400001, 0.133,
  _, _, _, 0.075, 0.142, 0.103, 0.144, 0.119, 0.156, _,
  0.115, _, 0.043, 0.038, 0.055, 0.08400001, 0.098, 0.115, 0.114, _ ;

 dataday = 2009001 ;

 lat = -29.5, -17.5, -5.5, 6.5, 18.5 ;

 lon = 120.5, 132.5, 144.5, 156.5, 168.5, -179.5, -167.5, -155.5, -143.5, 
    -131.5 ;

 time = 1230768000 ;
}
netcdf west {
dimensions:
	lat = 5 ;
	lon = 5 ;
variables:
	float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "lat lon" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
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
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sun Mar  2 18:46:33 2014: ncks -d lat,-30.,30. -d lon,120.,180. subsampled.nc west.nc\n",
			"Sun Mar  2 18:43:16 2014: ncks -d lat,,,12 -d lon,,,12 scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20090101.nc subsampled.nc" ;
		:NCO = "4.2.2" ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, _, _, _, _,
  _, _, _, _, _,
  _, _, _, _, 0.211,
  _, _, _, 0.075, 0.142,
  0.115, _, 0.043, 0.038, 0.055 ;

 lat = -29.5, -17.5, -5.5, 6.5, 18.5 ;

 lon = 120.5, 132.5, 144.5, 156.5, 168.5 ;
}
netcdf east {
dimensions:
	lat = 5 ;
	lon = 5 ;
variables:
	float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "lat lon" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
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
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sun Mar  2 18:47:37 2014: ncks -d lat,-30.,30. -d lon,-180.,-120. subsampled.nc east.nc\n",
			"Sun Mar  2 18:43:16 2014: ncks -d lat,,,12 -d lon,,,12 scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20090101.nc subsampled.nc" ;
		:NCO = "4.2.2" ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.054, _, 0.12, _, 0.049,
  0.117, _, _, _, _,
  _, 0.074, 0.186, 0.08400001, 0.133,
  0.103, 0.144, 0.119, 0.156, _,
  0.08400001, 0.098, 0.115, 0.114, _ ;

 lat = -29.5, -17.5, -5.5, 6.5, 18.5 ;

 lon = -179.5, -167.5, -155.5, -143.5, -131.5 ;
}
netcdf stitched {
dimensions:
	lon = 10 ;
	lat = UNLIMITED ; // (5 currently)
variables:
	float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "lat lon" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
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
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon Mar  3 00:39:25 2014: ncpdq -a time,lat,lon -O -o tmp/bVZlKmWVUY/stitched.nc tmp/bVZlKmWVUY/stitched.nc\n",
			"Mon Mar  3 00:39:25 2014: ncrcat -O tmp/bVZlKmWVUY/west.nc tmp/bVZlKmWVUY/east.nc tmp/bVZlKmWVUY/stitched.nc\n",
			"Mon Mar  3 00:39:25 2014: ncks --mk_rec_dmn lon -O -o tmp/bVZlKmWVUY/west.nc tmp/bVZlKmWVUY/west.nc\n",
			"Mon Mar  3 00:39:25 2014: ncpdq -a lon,time,lat -O -o tmp/bVZlKmWVUY/west.nc tmp/bVZlKmWVUY/west.nc\n",
			"Sun Mar  2 18:46:33 2014: ncks -d lat,-30.,30. -d lon,120.,180. subsampled.nc west.nc\n",
			"Sun Mar  2 18:43:16 2014: ncks -d lat,,,12 -d lon,,,12 scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20090101.nc subsampled.nc" ;
		:NCO = "4.3.1" ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, _, _, _, _, 0.054, _, 0.12, _, 0.049,
  _, _, _, _, _, 0.117, _, _, _, _,
  _, _, _, _, 0.211, _, 0.074, 0.186, 0.08400001, 0.133,
  _, _, _, 0.075, 0.142, 0.103, 0.144, 0.119, 0.156, _,
  0.115, _, 0.043, 0.038, 0.055, 0.08400001, 0.098, 0.115, 0.114, _ ;

 lat = -29.5, -17.5, -5.5, 6.5, 18.5 ;

 lon = 120.5, 132.5, 144.5, 156.5, 168.5, -179.5, -167.5, -155.5, -143.5, 
    -131.5 ;
}
