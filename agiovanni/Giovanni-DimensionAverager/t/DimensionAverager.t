#! /usr/bin/perl -w

#########################

use Test::More tests => 7;
use POSIX;
use Giovanni::Logger;
use Giovanni::DimensionAverager;

my $vname = "FinalAerosolAbsOpticalDepth500";

my $tmp_mfst    = POSIX::tmpnam();
my $tmp_nc1     = POSIX::tmpnam() . ".$vname.20060101.nc";
my $tmp_nc2     = POSIX::tmpnam() . ".$vname.20060101.nc";
my $tmp_nc3     = POSIX::tmpnam() . ".$vname.20060101.nc";
my $tmp_outfile = POSIX::tmpnam();

my $err = 0;
my $log = Giovanni::Logger->new(
    session_dir       => '.',
    manifest_filename => $tmp_mfst
);

# Temporary files
my $files = [ $tmp_nc1, $tmp_nc2, $tmp_nc3 ];
my $outfile = $tmp_outfile;

# Create test data
my $rc = create_test_data($files);

ok( ( -f $files->[0] ), "Created test nc file 1/3" ) || $err++;
ok( ( -f $files->[1] ), "Created test nc file 2/3" ) || $err++;
ok( ( -f $files->[2] ), "Created test nc file 3/3" ) || $err++;

# Test dimension averager
my $dims = [ "lat", "lon" ];
my $miss = "-1.267651e+30";
my $bbox = "71.5,-0.5,88.5,8.5";

# Latitude average
$outfile
    = Giovanni::DimensionAverager::average_dimension( $files, $vname, $bbox,
    "lat", "daily", ".", $log, undef, undef );

ok( ( -f $outfile ), "Results file created ($outfile)" ) || $err++;

# Test results
my $output = `ncdump -v FinalAerosolAbsOpticalDepth500 $outfile`;
my ($result) = ( $output =~ /FinalAerosolAbsOpticalDepth500\s*=\s*(.*);/mgs );
$result =~ s/\s//g;
ok( $result eq
        "_,0,0.002194747,_,_,0.0282,0.0005,0.0087,0.01177564,0.004332937,0.0006661732,_,_,_,_,0.0166,0.02685434,0.0499,_,0.0003342379,0.0006273683,_,_,_,0.008217904,_,0,0.03335002,0.008212782,0.03905,_,0.0722,0.0407,_,_,_,_,_,0.02096494,0.01095075,_,0,_,0,0,0,0,_,_,_,_,_,_,_",
    "Checking data results"
) || $err++;

# Longitude average
$outfile
    = Giovanni::DimensionAverager::average_dimension( $files, $vname, $bbox,
    "lon", "daily", ".", $log );
ok( ( -f $outfile ), "Results file created ($outfile)" ) || $err++;
$output = `ncdump -v FinalAerosolAbsOpticalDepth500 $outfile`;
($result) = ( $output =~ /FinalAerosolAbsOpticalDepth500\s*=\s*(.*);/mgs );
$result =~ s/\s//g;
ok( $result eq
        "_,_,_,0,0,0,0.0089,0.0045,0.013575,0.01587143,0.0699,0.01143333,0.00775,0.0044,0.00145,0,0.004025,0.00516,0,0.02483333,_,0.0126,0.0125,0.0093,_,_,0,0,0.007375,0",
    "Checking data results"
) || $err++;

# Clean up
unlink( $tmp_nc1, $tmp_nc2, $tmp_nc3 );

#-unlink ($outfile, $ncfile) unless $ENV{'SAVE_TEST_FILES'};

exit($err);

#########################

sub create_test_data {
    my ($ncfiles) = @_;

    # Read block at __DATA__ and write to a CDL file
    local ($/) = undef;
    my $cdldata = <DATA>;

    # Split the DATA text into three separate files
    my @cdl = ( $cdldata =~ m/(netcdf .*?\}\n)/gs );

    # Create nc files
    my $k = 0;
    foreach my $ncdump (@cdl) {
        open( NC, ">ncdump.cdl" ) || die("ERROR Fail to create tmp cdl file");
        print NC $ncdump;
        `ncgen -b -o $ncfiles->[$k] ncdump.cdl`;
        close(NC);
        $k++;
    }
    unlink("ncdump.cdl");

    return 1;
}

__DATA__
netcdf formatted_OMI-Aura_L3-OMAERUVd_2009m0101_v003-2011m1203t141114.he5 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lon = 25 ;
	lat = 18 ;
variables:
	int time(time) ;
		time:startValue = "2009-01-01T00:00:00Z" ;
		time:endValue = "2009-01-01T23:59:59Z" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float lon(lon) ;
		lon:grads_dim = "x" ;
		lon:grads_mapping = "linear" ;
		lon:grads_size = "360" ;
		lon:units = "degrees_east" ;
		lon:minimum = -180.f ;
		lon:maximum = 180.f ;
		lon:resolution = 1.f ;
	float lat(lat) ;
		lat:grads_dim = "y" ;
		lat:grads_mapping = "linear" ;
		lat:grads_size = "180" ;
		lat:units = "degrees_north" ;
		lat:long_name = "latitude" ;
		lat:minimum = -90.f ;
		lat:maximum = 90.f ;
		lat:resolution = 1.f ;
	float FinalAerosolAbsOpticalDepth500(time, lat, lon) ;
		FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
		FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
		FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
		FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
		FinalAerosolAbsOpticalDepth500:fonc_original_name = "_HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth500" ;
		FinalAerosolAbsOpticalDepth500:structureType = "Grid" ;
		FinalAerosolAbsOpticalDepth500:scale_factor = 1.f ;
		FinalAerosolAbsOpticalDepth500:add_offset = 0.f ;

// global attributes:
		:title = "NASA HDFEOS5 Grid" ;
		:Conventions = "CF-1.4" ;
		:dataType = "Grid" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon Apr 16 20:16:15 2012: ncatted -O -a history,global,d,c,, /var/scratch/hxiaopen/hegde_temp//formatted_OMI-Aura_L3-OMAERUVd_2009m0101_v003-2011m1203t141114.he5.nc" ;
data:

 time = 1230768000 ;

 lon = 69.5, 70.5, 71.5, 72.5, 73.5, 74.5, 75.5, 76.5, 77.5, 78.5, 79.5, 
    80.5, 81.5, 82.5, 83.5, 84.5, 85.5, 86.5, 87.5, 88.5, 89.5, 90.5, 91.5, 
    92.5, 93.5 ;

 lat = -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 
    10.5, 11.5, 12.5, 13.5, 14.5 ;

 FinalAerosolAbsOpticalDepth500 =
  0.0709, 0.0769, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _,
  0.0534, _, 0.0632, 0.0726, 0.0452, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, 0.0719,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    0.0133, 0.0087,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, 0, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, 0, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0.0087, _, _, 
    _, _,
  _, _, _, 0, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, 0.0002, _, _, _, _, _, _, 0.0061, _, _, _, _, _, 0.0166, 
    0.0127, _, _, _, _, _, _,
  _, 0.0073, _, _, 0.0064, _, _, _, _, _, 0, 0.0109, 0.0007, _, _, _, _, _, 
    _, _, 0.0137, _, _, _, _,
  _, 0.0076, _, _, _, _, _, _, _, _, 0.0041, 0.0003, 0, _, _, _, _, _, _, 
    0.0499, 0.0604, 0.0751, _, _, _,
  _, 0.028, _, _, _, _, _, 0.0282, 0.0005, 0.0087, 0.0313, 0, 0.0013, _, _, 
    _, _, _, 0.0411, _, _, 0.0147, _, _, _,
  _, _, _, _, _, _, _, 0.0203, 0, 0, 0.012, 0.0071, _, 0.0852, _, _, _, _, _, 
    _, _, 0.0549, 0.0582, 0.0987, _,
  0.0101, _, 0.0335, 0.0338, _, _, _, 0.0037, 0, 0, 0, _, _, _, _, _, _, _, 
    _, _, _, 0.01, 0.0428, 0.0514, 0.0159,
  0.0078, _, 0.0117, 0.031, _, _, 0.041, 0.0009, 0.0001, 0, 0, _, _, _, _, _, 
    _, _, _, _, _, 0.0428, 0.0386, 0.0099, 0.0096,
  0.0082, _, 0.0114, 0.0121, _, _, 0.0047, 0, 0.0015, 0, 0, 0, _, _, _, _, _, 
    _, _, _, _, _, 0.0426, 0.0128, _,
  0.0074, 0.0096, 0.034, 0.0146, _, 0.0059, 0, 0, 0, 0.0001, 0, 0, _, _, _, 
    _, _, _, _, _, _, _, _, _, 0.0111,
  _, 0.0371, 0.0453, _, _, 0.0026, 0.0004, 0.0005, 0, 0.0004, 0, 0, _, _, _, 
    _, _, _, _, _, _, _, _, _, _ ;
}
netcdf formatted_OMI-Aura_L3-OMAERUVd_2009m0102_v003-2011m1203t141117.he5 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lon = 25 ;
	lat = 18 ;
variables:
	int time(time) ;
		time:startValue = "2009-01-02T00:00:00Z" ;
		time:endValue = "2009-01-02T23:59:59Z" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float lon(lon) ;
		lon:grads_dim = "x" ;
		lon:grads_mapping = "linear" ;
		lon:grads_size = "360" ;
		lon:units = "degrees_east" ;
		lon:minimum = -180.f ;
		lon:maximum = 180.f ;
		lon:resolution = 1.f ;
	float lat(lat) ;
		lat:grads_dim = "y" ;
		lat:grads_mapping = "linear" ;
		lat:grads_size = "180" ;
		lat:units = "degrees_north" ;
		lat:long_name = "latitude" ;
		lat:minimum = -90.f ;
		lat:maximum = 90.f ;
		lat:resolution = 1.f ;
	float FinalAerosolAbsOpticalDepth500(time, lat, lon) ;
		FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
		FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
		FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
		FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
		FinalAerosolAbsOpticalDepth500:fonc_original_name = "_HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth500" ;
		FinalAerosolAbsOpticalDepth500:structureType = "Grid" ;
		FinalAerosolAbsOpticalDepth500:scale_factor = 1.f ;
		FinalAerosolAbsOpticalDepth500:add_offset = 0.f ;

// global attributes:
		:title = "NASA HDFEOS5 Grid" ;
		:Conventions = "CF-1.4" ;
		:dataType = "Grid" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon Apr 16 20:16:15 2012: ncatted -O -a history,global,d,c,, /var/scratch/hxiaopen/hegde_temp//formatted_OMI-Aura_L3-OMAERUVd_2009m0102_v003-2011m1203t141117.he5.nc" ;
data:

 time = 1230854400 ;

 lon = 69.5, 70.5, 71.5, 72.5, 73.5, 74.5, 75.5, 76.5, 77.5, 78.5, 79.5, 
    80.5, 81.5, 82.5, 83.5, 84.5, 85.5, 86.5, 87.5, 88.5, 89.5, 90.5, 91.5, 
    92.5, 93.5 ;

 lat = -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 
    10.5, 11.5, 12.5, 13.5, 14.5 ;

 FinalAerosolAbsOpticalDepth500 =
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, 0.0663, _, 0.0722, 0.0712, _, _, _, 
    _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, 0.0123, 0.0118, _, _, 0.0102, _, _, _, 
    _, _, _, _, _,
  _, _, _, _, 0.0034, _, _, _, _, _, _, _, 0.0121, _, _, _, _, _, _, _, _, _, 
    _, _, _,
  _, _, _, 0.0007, 0, _, _, _, 0.0085, _, _, _, 0.0084, _, _, _, _, _, _, _, 
    _, _, _, _, _,
  _, _, _, 0.0013, 0.0016, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _,
  _, _, _, 0, 0, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, 0, 0, _, _, _, 0.0161, _, _, 0, _, _, _, _, _, _, _, _, _, _, _, 
    _, _,
  _, _, _, 0, 0, _, _, _, _, _, 0, 0.0258, 0, _, _, _, _, _, _, _, _, _, _, 
    _, _,
  _, _, _, 0, 0, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, 0, _, _, _, 0, _, _, 0.0745, _, _, _, _, _, _, _, _, _, _, _, 
    _, _,
  _, _, _, _, _, _, _, 0, 0, _, 0, 0, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, 0, _, _, 0, 0, 0, _, _, _, 0.0787, _, _, _, _, _, _, _, _, _, _, 
    _, _,
  _, _, _, 0, _, _, 0, 0.001, 0.001, _, _, _, _, 0.0617, _, _, _, _, _, _, _, 
    _, _, _, _,
  _, _, _, _, _, 0, 0, 0, 0, 0.0032, _, _, 0.0681, 0.0684, 0.0333, _, _, _, 
    _, _, _, _, _, 0, _,
  _, _, _, _, _, 0.0011, 0, 0, 0, 0, _, _, _, _, 0.0292, _, 0.04, 0.0407, _, 
    _, _, _, _, 0, 0,
  _, _, _, _, _, 0.0011, 0, 0, 0, 0.0026, _, _, _, 0.0278, _, _, _, _, _, _, 
    _, _, _, _, _ ;
}
netcdf formatted_OMI-Aura_L3-OMAERUVd_2009m0103_v003-2011m1203t141111.he5 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lon = 25 ;
	lat = 18 ;
variables:
	int time(time) ;
		time:startValue = "2009-01-03T00:00:00Z" ;
		time:endValue = "2009-01-03T23:59:59Z" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float lon(lon) ;
		lon:grads_dim = "x" ;
		lon:grads_mapping = "linear" ;
		lon:grads_size = "360" ;
		lon:units = "degrees_east" ;
		lon:minimum = -180.f ;
		lon:maximum = 180.f ;
		lon:resolution = 1.f ;
	float lat(lat) ;
		lat:grads_dim = "y" ;
		lat:grads_mapping = "linear" ;
		lat:grads_size = "180" ;
		lat:units = "degrees_north" ;
		lat:long_name = "latitude" ;
		lat:minimum = -90.f ;
		lat:maximum = 90.f ;
		lat:resolution = 1.f ;
	float FinalAerosolAbsOpticalDepth500(time, lat, lon) ;
		FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
		FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
		FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
		FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
		FinalAerosolAbsOpticalDepth500:fonc_original_name = "_HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth500" ;
		FinalAerosolAbsOpticalDepth500:structureType = "Grid" ;
		FinalAerosolAbsOpticalDepth500:scale_factor = 1.f ;
		FinalAerosolAbsOpticalDepth500:add_offset = 0.f ;

// global attributes:
		:title = "NASA HDFEOS5 Grid" ;
		:Conventions = "CF-1.4" ;
		:dataType = "Grid" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon Apr 16 20:16:15 2012: ncatted -O -a history,global,d,c,, /var/scratch/hxiaopen/hegde_temp//formatted_OMI-Aura_L3-OMAERUVd_2009m0103_v003-2011m1203t141111.he5.nc" ;
data:

 time = 1230940800 ;

 lon = 69.5, 70.5, 71.5, 72.5, 73.5, 74.5, 75.5, 76.5, 77.5, 78.5, 79.5, 
    80.5, 81.5, 82.5, 83.5, 84.5, 85.5, 86.5, 87.5, 88.5, 89.5, 90.5, 91.5, 
    92.5, 93.5 ;

 lat = -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 
    10.5, 11.5, 12.5, 13.5, 14.5 ;

 FinalAerosolAbsOpticalDepth500 =
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, 0.0126, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, 0.0132,
  _, _, _, _, 0.0125, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0.0165, 
    _, _, _,
  _, _, _, _, _, 0.0093, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    0.014, 0.0128, 0.0131,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0.0077, _, 
    _, 0.0144,
  _, _, _, _, _, _, _, _, _, _, _, 0, _, _, _, _, _, _, _, _, _, _, _, 0.016, _,
  _, _, _, _, _, _, _, _, _, _, _, 0, 0, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, 0.0295, _, _, _, _, _, 0, 0, 0, _, _, _, _, _, _, _, _, _, _, 
    _, _,
  _, _, _, _, _, _, _, 0, _, 0, 0, 0, 0, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, 0.0362, 0.0336, _, 0, _, _, 0, 0.002, _, _, _, _, _, _, _, _, 
    _, _, _, _, _,
  _, _, _, 0.0292, 0.0374, 0.0383, _, 0.0173, 0, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _,
  _, 0.0614, _, 0.0268, 0.0325, 0.0387, 0.0487, 0.0055, 0, 0, 0, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, 0.0427, 0.0449, 0.0236, 0, 0.0012, 0, 0, 0.0179, _, _, _, _, _, 
    _, _, 0.0154, _, _, _, _, _,
  _, _, _, 0.0327, 0.0426, 0.0464, 0.0013, 0, 0, 0, 0, 0.0014, _, _, _, _, _, 
    _, _, _, _, _, _, _, _,
  _, _, 0.0286, _, 0.0375, 0.0444, _, 0, 0, 0, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _ ;
}
