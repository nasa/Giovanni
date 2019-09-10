use strict;
use Test::More tests => 3;
use Giovanni::Data::NcFile;
use Giovanni::Testing;
use File::Temp qw(tempdir);

BEGIN { use_ok('Giovanni::Algorithm::DimensionAverager') }

# create a temporary directory
my $currDir = my $dir = tempdir( CLEANUP => 1 );

# read in the cdl
my $cdl = Giovanni::Data::NcFile::read_cdl_data_block();

# write it to the temporary directory
my $inFile         = "$dir/in.nc";
my $correctOutFile = "$dir/correct.nc";
Giovanni::Data::NcFile::write_netcdf_file( $inFile,         $cdl->[0] );
Giovanni::Data::NcFile::write_netcdf_file( $correctOutFile, $cdl->[1] );

# Call the averager
my $outFile = "$dir/out.nc";
Giovanni::Algorithm::DimensionAverager::compute_spatial_average_with_weights(
    $inFile, $outFile, "AIRX3STM_006_TotCO_A", "shape_mask" );

ok( -f $outFile, "Output file created" );

my $diff
    = Giovanni::Data::NcFile::diff_netcdf_files( $outFile, $correctOutFile );
is( $diff, "", "Files are the same: $diff" );

__DATA__
netcdf shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201_concatSubset {
dimensions:
	time = UNLIMITED ; // (3 currently)
	lat = 4 ;
	lon = 6 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STM_006_TotCO_A(time, lat, lon) ;
		AIRX3STM_006_TotCO_A:_FillValue = -9999.f ;
		AIRX3STM_006_TotCO_A:standard_name = "atmosphere_mass_content_of_carbon_monoxide" ;
		AIRX3STM_006_TotCO_A:quantity_type = "CO" ;
		AIRX3STM_006_TotCO_A:product_short_name = "AIRX3STM" ;
		AIRX3STM_006_TotCO_A:product_version = "006" ;
		AIRX3STM_006_TotCO_A:long_name = "Carbon Monoxide Total Column (Daytime/Ascending)" ;
		AIRX3STM_006_TotCO_A:coordinates = "time lat lon" ;
		AIRX3STM_006_TotCO_A:units = "mol/cm2" ;
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
	double shape_mask(lat, lon) ;
	int time(time) ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2003-12-01T00:00:00Z" ;
		:end_time = "2003-12-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Thu Jan 12 21:51:22 2017: ncrcat -d lon,-180.0,180.0 -d lat,-90.0,90.0 /tmp/working_2KDu/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201.nc /tmp/working_2KDu/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20040101.nc /tmp/working_2KDu/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20040201.nc /tmp/seasonalTSIntermediateFiles_3dgYn/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201_concatSubset.nc\n",
			"Wed Jan 11 22:11:16 2017: ncks -d lat,36.886605,40.723037 -d lon,-80.487651,-73.986282 /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2///scrubbed.AIRX3STM_006_TotCO_A.20031201.nc /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201.nc" ;
data:

 AIRX3STM_006_TotCO_A =
  2.016065e+18, 2.112892e+18, 2.184668e+18, 2.182557e+18, 2.172987e+18, 
    2.197053e+18,
  1.895452e+18, 2.038864e+18, 2.173691e+18, 2.212675e+18, 2.212112e+18, 
    2.212956e+18,
  1.98088e+18, 2.058849e+18, 2.155676e+18, 2.202823e+18, 2.21366e+18, 
    2.229986e+18,
  2.039568e+18, 2.02085e+18, 2.131329e+18, 2.162854e+18, 2.176365e+18, 
    2.213238e+18,
  2.273896e+18, 2.359042e+18, 2.381278e+18, 2.390004e+18, 2.384656e+18, 
    2.383812e+18,
  2.084604e+18, 2.267422e+18, 2.384656e+18, 2.397885e+18, 2.386626e+18, 
    2.394226e+18,
  2.119647e+18, 2.237445e+18, 2.325828e+18, 2.362982e+18, 2.371145e+18, 
    2.391411e+18,
  2.200149e+18, 2.181431e+18, 2.231252e+18, 2.299369e+18, 2.317383e+18, 
    2.367205e+18,
  2.350035e+18, 2.466284e+18, 2.533556e+18, 2.514134e+18, 2.475291e+18, 
    2.468817e+18,
  2.220838e+18, 2.396759e+18, 2.527645e+18, 2.519764e+18, 2.52849e+18, 
    2.470224e+18,
  2.282903e+18, 2.359042e+18, 2.47895e+18, 2.513572e+18, 2.537497e+18, 
    2.501468e+18,
  2.393945e+18, 2.323294e+18, 2.421811e+18, 2.469098e+18, 2.491616e+18, 
    2.528208e+18 ;

 lat = 37.5, 38.5, 39.5, 40.5 ;

 lat_bnds =
  37, 38,
  38, 39,
  39, 40,
  40, 41 ;

 lon = -79.5, -78.5, -77.5, -76.5, -75.5, -74.5 ;

 lon_bnds =
  -80, -79,
  -79, -78,
  -78, -77,
  -77, -76,
  -76, -75,
  -75, -74 ;

 shape_mask =
  0, 0, 0, 0.0991691675364044, 0.0991691675364044, 0,
  0, 0, 0.293478058819655, 0.782608156852414, 0.58695611763931, 
    0.0489130098032759,
  0.241132682308662, 0.241132682308662, 0.530491901079058, 0.57871843754079, 
    0.19290614584693, 0,
  0, 0, 0, 0, 0, 0 ;

 time = 1070236800, 1072915200, 1075593600 ;

 time_bnds =
  1070236800, 1072915199,
  1072915200, 1075593599,
  1075593600, 1078099199 ;
}
netcdf average {
dimensions:
	time = UNLIMITED ; // (3 currently)
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float AIRX3STM_006_TotCO_A(time) ;
		AIRX3STM_006_TotCO_A:_FillValue = -9999.f ;
		AIRX3STM_006_TotCO_A:standard_name = "atmosphere_mass_content_of_carbon_monoxide" ;
		AIRX3STM_006_TotCO_A:quantity_type = "CO" ;
		AIRX3STM_006_TotCO_A:product_short_name = "AIRX3STM" ;
		AIRX3STM_006_TotCO_A:product_version = "006" ;
		AIRX3STM_006_TotCO_A:long_name = "Carbon Monoxide Total Column (Daytime/Ascending)" ;
		AIRX3STM_006_TotCO_A:coordinates = "time " ;
		AIRX3STM_006_TotCO_A:units = "mol/cm2" ;
		AIRX3STM_006_TotCO_A:cell_methods = "lat, lon: mean" ;
	double lat_bnds(latv) ;
		lat_bnds:units = "degrees_north" ;
		lat_bnds:cell_methods = "lat: mean" ;
	double lon_bnds(lonv) ;
		lon_bnds:units = "degrees_east" ;
		lon_bnds:cell_methods = "lon: mean" ;
	int time(time) ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2003-12-01T00:00:00Z" ;
		:end_time = "2003-12-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Thu Jan 12 22:00:20 2017: ncrcat -o concat.nc first_avg.nc second_avg.nc third_avg.nc\n",
			"Thu Jan 12 21:59:04 2017: ncks -x -v lat,lon -O -o first_avg.nc first_avg.nc\n",
			"Thu Jan 12 21:58:23 2017: ncwa -v AIRX3STM_006_TotCO_A -w shape_mask -a lat,lon -O -o first_avg.nc first.nc\n",
			"Thu Jan 12 21:54:20 2017: ncks -d time,0,0 shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201_concatSubset.nc first.nc\n",
			"Thu Jan 12 21:51:22 2017: ncrcat -d lon,-180.0,180.0 -d lat,-90.0,90.0 /tmp/working_2KDu/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201.nc /tmp/working_2KDu/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20040101.nc /tmp/working_2KDu/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20040201.nc /tmp/seasonalTSIntermediateFiles_3dgYn/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201_concatSubset.nc\n",
			"Wed Jan 11 22:11:16 2017: ncks -d lat,36.886605,40.723037 -d lon,-80.487651,-73.986282 /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2///scrubbed.AIRX3STM_006_TotCO_A.20031201.nc /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201.nc" ;
data:

 AIRX3STM_006_TotCO_A = 2.172776e+18, 2.348591e+18, 2.487923e+18 ;

 lat_bnds = 38.5, 39.5 ;

 lon_bnds = -77.5, -76.5 ;

 time = 1070236800, 1072915200, 1075593600 ;

 time_bnds =
  1070236800, 1072915199,
  1072915200, 1075593599,
  1075593600, 1078099199 ;
}
