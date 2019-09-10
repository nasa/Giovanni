#$Id: seasonalTimeSeries.t,v 1.1 2015/04/17 18:34:22 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-SeasonalTimeSeries.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Giovanni::Algorithm::SeasonalTimeSeries') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Giovanni::Data::NcFile;
use File::Temp qw/tempdir/;
use FindBin qw($Bin);

# find the executible
my $script = findScript("seasonalTimeSeries.pl");
if ( !( -e $script ) ) {
    die "Unable to find seasonalTimeSeries.pl: $script";
}

# create a temporary working directory
my $dir = tempdir( "working_XXXX", CLEANUP => 1, TMPDIR => 1 );

# read in the CDL at the end of this file
my $cdls = Giovanni::Data::NcFile::read_cdl_data_block();
my $outCdl = pop(@{$cdls});

# write out the netcdf to files in the temp directory.
my @inFiles = ();
for my $cdl ( @{$cdls} ) {
    my ($netcdf) = ( $cdl =~ /^netcdf\s*(\S*)/ );
    $netcdf = "$dir/$netcdf.nc";
    push( @inFiles, $netcdf );
    Giovanni::Data::NcFile::write_netcdf_file( $netcdf, $cdl );
}

# create a file with all these files
my $inFilesFile = "$dir/inFiles.txt";
open( FILE, ">", $inFilesFile ) or die "Unable to create file: $inFilesFile";
for my $file (@inFiles) {
    print FILE $file . "\n";
}
close(FILE);

# write the output file somewhere
my $correctOutFile = "$dir/correct.nc";
Giovanni::Data::NcFile::write_netcdf_file($correctOutFile,$outCdl);

my $bbox  = "-180,-90,180,90";
my $outNc = "$dir/out.nc";

# build the command
my $cmd = "$script -b '$bbox' -f $inFilesFile -o $outNc "
    . "-v AIRX3STM_006_TotCO_A -g 'SEASON=DJF' -S shape";

my $ret = system($cmd);
is( $ret, 0, "Command returned zero: $cmd" );
ok( -e $outNc, "Output file exists" );

$ret = Giovanni::Data::NcFile::diff_netcdf_files( $outNc, $correctOutFile );
ok( $ret eq '', "Output file is correct: $ret" );


sub findScript {
    my ($scriptName) = @_;

    # see if this is just next door (Christine's eclipse configuration)
    $script = "../scripts/$scriptName";

    if ( !( -e $script ) ) {

        # see if we can find the script relative to our current location
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }
    return $script;
}

__DATA__
netcdf shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201 {
dimensions:
	time = UNLIMITED ; // (1 currently)
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
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
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
	double shape_mask(lat, lon) ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2003-12-01T00:00:00Z" ;
		:end_time = "2003-12-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Jan 11 22:11:16 2017: ncks -d lat,36.886605,40.723037 -d lon,-80.487651,-73.986282 /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2///scrubbed.AIRX3STM_006_TotCO_A.20031201.nc /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20031201.nc" ;
data:

 AIRX3STM_006_TotCO_A =
  2.016065e+18, 2.112892e+18, 2.184668e+18, 2.182557e+18, 2.172987e+18, 
    2.197053e+18,
  1.895452e+18, 2.038864e+18, 2.173691e+18, 2.212675e+18, 2.212112e+18, 
    2.212956e+18,
  1.98088e+18, 2.058849e+18, 2.155676e+18, 2.202823e+18, 2.21366e+18, 
    2.229986e+18,
  2.039568e+18, 2.02085e+18, 2.131329e+18, 2.162854e+18, 2.176365e+18, 
    2.213238e+18 ;

 datamonth = 200312 ;

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

 time = 1070236800 ;

 time_bnds =
  1070236800, 1072915199 ;

 shape_mask =
  0, 0, 0, 0.0991691675364044, 0.0991691675364044, 0,
  0, 0, 0.293478058819655, 0.782608156852414, 0.58695611763931, 
    0.0489130098032759,
  0.241132682308662, 0.241132682308662, 0.530491901079058, 0.57871843754079, 
    0.19290614584693, 0,
  0, 0, 0, 0, 0, 0 ;
}
netcdf shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20040101 {
dimensions:
	time = UNLIMITED ; // (1 currently)
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
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
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
	double shape_mask(lat, lon) ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2004-01-01T00:00:00Z" ;
		:end_time = "2004-01-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Jan 11 22:11:16 2017: ncks -d lat,36.886605,40.723037 -d lon,-80.487651,-73.986282 /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2///scrubbed.AIRX3STM_006_TotCO_A.20040101.nc /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20040101.nc" ;
data:

 AIRX3STM_006_TotCO_A =
  2.273896e+18, 2.359042e+18, 2.381278e+18, 2.390004e+18, 2.384656e+18, 
    2.383812e+18,
  2.084604e+18, 2.267422e+18, 2.384656e+18, 2.397885e+18, 2.386626e+18, 
    2.394226e+18,
  2.119647e+18, 2.237445e+18, 2.325828e+18, 2.362982e+18, 2.371145e+18, 
    2.391411e+18,
  2.200149e+18, 2.181431e+18, 2.231252e+18, 2.299369e+18, 2.317383e+18, 
    2.367205e+18 ;

 datamonth = 200401 ;

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

 time = 1072915200 ;

 time_bnds =
  1072915200, 1075593599 ;

 shape_mask =
  0, 0, 0, 0.0991691675364044, 0.0991691675364044, 0,
  0, 0, 0.293478058819655, 0.782608156852414, 0.58695611763931, 
    0.0489130098032759,
  0.241132682308662, 0.241132682308662, 0.530491901079058, 0.57871843754079, 
    0.19290614584693, 0,
  0, 0, 0, 0, 0, 0 ;
}
netcdf shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20040201 {
dimensions:
	time = UNLIMITED ; // (1 currently)
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
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
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
	double shape_mask(lat, lon) ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2004-02-01T00:00:00Z" ;
		:end_time = "2004-02-29T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Jan 11 22:11:16 2017: ncks -d lat,36.886605,40.723037 -d lon,-80.487651,-73.986282 /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2///scrubbed.AIRX3STM_006_TotCO_A.20040201.nc /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20040201.nc" ;
data:

 AIRX3STM_006_TotCO_A =
  2.350035e+18, 2.466284e+18, 2.533556e+18, 2.514134e+18, 2.475291e+18, 
    2.468817e+18,
  2.220838e+18, 2.396759e+18, 2.527645e+18, 2.519764e+18, 2.52849e+18, 
    2.470224e+18,
  2.282903e+18, 2.359042e+18, 2.47895e+18, 2.513572e+18, 2.537497e+18, 
    2.501468e+18,
  2.393945e+18, 2.323294e+18, 2.421811e+18, 2.469098e+18, 2.491616e+18, 
    2.528208e+18 ;

 datamonth = 200402 ;

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

 time = 1075593600 ;

 time_bnds =
  1075593600, 1078099199 ;

 shape_mask =
  0, 0, 0, 0.0991691675364044, 0.0991691675364044, 0,
  0, 0, 0.293478058819655, 0.782608156852414, 0.58695611763931, 
    0.0489130098032759,
  0.241132682308662, 0.241132682308662, 0.530491901079058, 0.57871843754079, 
    0.19290614584693, 0,
  0, 0, 0, 0, 0, 0 ;
}
netcdf shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20041201 {
dimensions:
	time = UNLIMITED ; // (1 currently)
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
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
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
	double shape_mask(lat, lon) ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2004-12-01T00:00:00Z" ;
		:end_time = "2004-12-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Jan 11 22:11:16 2017: ncks -d lat,36.886605,40.723037 -d lon,-80.487651,-73.986282 /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2///scrubbed.AIRX3STM_006_TotCO_A.20041201.nc /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20041201.nc" ;
data:

 AIRX3STM_006_TotCO_A =
  2.046042e+18, 2.139069e+18, 2.150187e+18, 2.14315e+18, 2.158209e+18, 
    2.17749e+18,
  1.930074e+18, 2.091922e+18, 2.173409e+18, 2.174957e+18, 2.172002e+18, 
    2.175239e+18,
  1.975673e+18, 2.082633e+18, 2.152298e+18, 2.16975e+18, 2.19832e+18, 
    2.212393e+18,
  2.058567e+18, 2.027464e+18, 2.111344e+18, 2.153565e+18, 2.167639e+18, 
    2.219712e+18 ;

 datamonth = 200412 ;

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

 time = 1101859200 ;

 time_bnds =
  1101859200, 1104537599 ;

 shape_mask =
  0, 0, 0, 0.0991691675364044, 0.0991691675364044, 0,
  0, 0, 0.293478058819655, 0.782608156852414, 0.58695611763931, 
    0.0489130098032759,
  0.241132682308662, 0.241132682308662, 0.530491901079058, 0.57871843754079, 
    0.19290614584693, 0,
  0, 0, 0, 0, 0, 0 ;
}
netcdf shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20050101 {
dimensions:
	time = UNLIMITED ; // (1 currently)
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
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
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
	double shape_mask(lat, lon) ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2005-01-01T00:00:00Z" ;
		:end_time = "2005-01-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Jan 11 22:11:16 2017: ncks -d lat,36.886605,40.723037 -d lon,-80.487651,-73.986282 /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2///scrubbed.AIRX3STM_006_TotCO_A.20050101.nc /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20050101.nc" ;
data:

 AIRX3STM_006_TotCO_A =
  2.210282e+18, 2.338494e+18, 2.377619e+18, 2.355664e+18, 2.346657e+18, 
    2.317102e+18,
  2.0687e+18, 2.248e+18, 2.364953e+18, 2.371708e+18, 2.326954e+18, 
    2.340183e+18,
  2.106418e+18, 2.227452e+18, 2.34919e+18, 2.36439e+18, 2.373678e+18, 
    2.34525e+18,
  2.238852e+18, 2.184668e+18, 2.276429e+18, 2.298102e+18, 2.311473e+18, 
    2.350316e+18 ;

 datamonth = 200501 ;

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

 time = 1104537600 ;

 time_bnds =
  1104537600, 1107215999 ;

 shape_mask =
  0, 0, 0, 0.0991691675364044, 0.0991691675364044, 0,
  0, 0, 0.293478058819655, 0.782608156852414, 0.58695611763931, 
    0.0489130098032759,
  0.241132682308662, 0.241132682308662, 0.530491901079058, 0.57871843754079, 
    0.19290614584693, 0,
  0, 0, 0, 0, 0, 0 ;
}
netcdf shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20050201 {
dimensions:
	time = UNLIMITED ; // (1 currently)
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
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
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
	double shape_mask(lat, lon) ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2005-02-01T00:00:00Z" ;
		:end_time = "2005-02-28T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Jan 11 22:11:16 2017: ncks -d lat,36.886605,40.723037 -d lon,-80.487651,-73.986282 /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2///scrubbed.AIRX3STM_006_TotCO_A.20050201.nc /var/giovanni/session/4900BC5E-D844-11E6-AD5F-C8C01C155322/D3A3867E-D84A-11E6-97AE-CB184FDBE183/D3A423D6-D84A-11E6-8E61-9054B00CEFD2/shapeMasked.scrubbed.AIRX3STM_006_TotCO_A.20050201.nc" ;
data:

 AIRX3STM_006_TotCO_A =
  2.4235e+18, 2.549319e+18, 2.604206e+18, 2.583659e+18, 2.546223e+18, 
    2.558608e+18,
  2.275725e+18, 2.460654e+18, 2.610117e+18, 2.596888e+18, 2.574652e+18, 
    2.548474e+18,
  2.340183e+18, 2.446299e+18, 2.525393e+18, 2.54566e+18, 2.568741e+18, 
    2.561704e+18,
  2.43504e+18, 2.382123e+18, 2.482891e+18, 2.519483e+18, 2.519201e+18, 
    2.561704e+18 ;

 datamonth = 200502 ;

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

 time = 1107216000 ;

 time_bnds =
  1107216000, 1109635199 ;

 shape_mask =
  0, 0, 0, 0.0991691675364044, 0.0991691675364044, 0,
  0, 0, 0.293478058819655, 0.782608156852414, 0.58695611763931, 
    0.0489130098032759,
  0.241132682308662, 0.241132682308662, 0.530491901079058, 0.57871843754079, 
    0.19290614584693, 0,
  0, 0, 0, 0, 0, 0 ;
}
netcdf algorithm {
dimensions:
	time = UNLIMITED ; // (2 currently)
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	int datayear(time) ;
		datayear:long_name = "Data year" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float AIRX3STM_006_TotCO_A(time) ;
		AIRX3STM_006_TotCO_A:_FillValue = -9999.f ;
		AIRX3STM_006_TotCO_A:standard_name = "atmosphere_mass_content_of_carbon_monoxide" ;
		AIRX3STM_006_TotCO_A:quantity_type = "CO" ;
		AIRX3STM_006_TotCO_A:product_short_name = "AIRX3STM" ;
		AIRX3STM_006_TotCO_A:product_version = "006" ;
		AIRX3STM_006_TotCO_A:long_name = "Carbon Monoxide Total Column (Daytime/Ascending)" ;
		AIRX3STM_006_TotCO_A:coordinates = "time" ;
		AIRX3STM_006_TotCO_A:units = "mol/cm2" ;
		AIRX3STM_006_TotCO_A:cell_methods = "lat, lon: mean time: mean" ;
		AIRX3STM_006_TotCO_A:group_type = "SEASON" ;
		AIRX3STM_006_TotCO_A:group_value = "DJF" ;
	double lat_bnds(time, latv) ;
		lat_bnds:units = "degrees_north" ;
		lat_bnds:cell_methods = "lat: mean" ;
	double lon_bnds(time, lonv) ;
		lon_bnds:units = "degrees_east" ;
		lon_bnds:cell_methods = "lon: mean" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;
		time_bnds:cell_methods = "time: mean" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2003-12-01T00:00:00Z" ;
		:end_time = "2003-12-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:geospatial_lat_max = "40.5" ;
 		:geospatial_lat_min = "37.5" ;
 		:geospatial_lon_max = "-74.5" ;
		:geospatial_lon_min = "-79.5" ;
data:

 datayear = 2004, 2005 ;

 time = 1070236800, 1101859200 ;

 AIRX3STM_006_TotCO_A = 2.33643e+18, 2.34281e+18 ;

 lat_bnds =
  38.5, 39.5,
  38.5, 39.5 ;

 lon_bnds =
  -77.5, -76.5,
  -77.5, -76.5 ;

 time_bnds =
  1072915200, 1075535999,
  1104537600, 1107129599 ;
}



