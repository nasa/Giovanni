#$Id: get_data_bounding_box.t,v 1.1 2014/10/15 20:33:06 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 3;
BEGIN { use_ok('Giovanni::Data::NcFile') }

use File::Temp;

my @correct_bboxes = ( "-94.75,29.5,-89.25,34.5", "-11.25,-11,11.25,11" );

# write out all the sample files to a temporary directory
my $dir     = File::Temp::tempdir( CLEANUP => 1 );
my $cdl_ref = Giovanni::Data::NcFile::read_cdl_data_block();
my @ncfiles = ();
my $i       = 0;
for my $cdl ( @{$cdl_ref} ) {
    my $ncfile = "$dir/sample_" . $i . ".nc";
    Giovanni::Data::NcFile::write_netcdf_file( $ncfile, $cdl )
        or die "Could not write netcdf file\n";
    push( @ncfiles, $ncfile );
    $i++;
}
if ( scalar(@ncfiles) != scalar(@correct_bboxes) ) {
    die "Need one bbox per ncfile";
}

# now run the tests
for ( my $i = 0; $i < scalar(@correct_bboxes); $i++ ) {
    my $bbox = Giovanni::Data::NcFile::get_data_bounding_box( $ncfiles[$i] );
    is( $bbox, $correct_bboxes[$i],
        "Bounding box matches for sample file $i" );

}

1;

__DATA__
netcdf timeAvg.TRMM_3B42_daily_precipitation_V6.20030101-20030101.95W_30N_89W_34N {
dimensions:
    lat = 20 ;
    lon = 22 ;
variables:
    float TRMM_3B42_daily_precipitation_V6(lat, lon) ;
        TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
        TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V6:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
        TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V6:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V6:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V6:longitude_resolution = 0.25 ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :end_time = "2002-12-31T22:29:59Z" ;
        :nco_openmp_thread_number = 1 ;
        :start_time = "2002-12-31T21:00:00Z" ;
        :title = "TRMM_3B42_daily_precipitation_V6 Averaged over 2003-01-01 to 2003-01-01" ;
        :plot_hint_title = "Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v6] mm/day for 2002-12-31 21Z - 2002-12-31 22:29Z" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-01. Title reflects the date range of the granules that went into making this result.\n",
            "" ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.6959022, 0, 0, 
    0.5249148,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.659492,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3.153505,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3.415936,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4.74, 22.08, 22.86245, 
    14.12219, 0, 22.87707, 18.83256,
  0.06, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21.38368, 26.94029, 
    13.88832, 6.793421, 25.85691, 22.89595,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8.16, 12.99917, 14.22724, 
    46.83324, 27.28796, 23.81903,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22.08, 26.93577, 
    32.56054, 38.36112, 23.23981,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 31.47744, 
    32.48201, 13.62761,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30.53009, 
    32.16543, 33.78295 ;

 lat = 29.625, 29.875, 30.125, 30.375, 30.625, 30.875, 31.125, 31.375, 
    31.625, 31.875, 32.125, 32.375, 32.625, 32.875, 33.125, 33.375, 33.625, 
    33.875, 34.125, 34.375 ;

 lon = -94.625, -94.375, -94.125, -93.875, -93.625, -93.375, -93.125, 
    -92.875, -92.625, -92.375, -92.125, -91.875, -91.625, -91.375, -91.125, 
    -90.875, -90.625, -90.375, -90.125, -89.875, -89.625, -89.375 ;
}
netcdf timeAvg.G4P0_1DA_2D_du_aot_006_tauf2d_du_00550.20030101-20030101.10W_10S_10E_10N {
dimensions:
    lat = 11 ;
    lon = 9 ;
variables:
    float G4P0_1DA_2D_du_aot_006_tauf2d_du_00550(lat, lon) ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:_FillValue = -9999.f ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:long_name = "Aerosol Optical Depth of Dust (Fine) 550 nm" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:units = "1" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:cell_methods = "time: mean" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:coordinates = "time lat lon" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:standard_name = "tauf2d_du_00550" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:quantity_type = "Component Aerosol Optical Depth" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:product_short_name = "G4P0_1DA_2D_du_aot" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:product_version = "006" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:latitude_resolution = 2. ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:longitude_resolution = 2.5 ;
    float lat(lat) ;
        lat:borders = "ilat" ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:borders = "ilon" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :nco_openmp_thread_number = 1 ;
        :start_time = "2003-01-01T00:00:00Z" ;
        :end_time = "2003-01-01T23:59:59Z" ;
        :title = "G4P0_1DA_2D_du_aot_006_tauf2d_du_00550 Averaged over 2003-01-01 to 2003-01-01" ;
        :plot_hint_title = "Aerosol Optical Depth of Dust (Fine) 550 nm daily 2.0 x 2.5 deg. [GOCART Model G4P0_1DA_2D_du_aot v006] for 2003-01-01" ;
data:

 G4P0_1DA_2D_du_aot_006_tauf2d_du_00550 =
  0.004731739, 0.004677636, 0.004441806, 0.003854955, 0.003382318, 
    0.003519088, 0.004841156, 0.005931096, 0.006096079,
  0.006529969, 0.006765421, 0.006932499, 0.006563613, 0.00563114, 
    0.005854781, 0.006322985, 0.006221608, 0.006752924,
  0.009645352, 0.009539553, 0.009383478, 0.009033325, 0.008639606, 
    0.007889345, 0.006955417, 0.006659159, 0.008357984,
  0.01220163, 0.0118413, 0.01053926, 0.009452236, 0.008711359, 0.007721494, 
    0.007013377, 0.007880594, 0.01021252,
  0.01411061, 0.01427595, 0.01295645, 0.01012703, 0.008935171, 0.00893839, 
    0.009294957, 0.009927775, 0.01125808,
  0.01781929, 0.01886799, 0.01813324, 0.01435012, 0.01104989, 0.01102732, 
    0.01139594, 0.0117224, 0.01242724,
  0.02301269, 0.02569713, 0.02638747, 0.02303728, 0.01539264, 0.01532786, 
    0.01703383, 0.01722548, 0.01565664,
  0.03234752, 0.03543527, 0.03799509, 0.03563454, 0.02667158, 0.0234684, 
    0.0260794, 0.02870325, 0.02214899,
  0.04475038, 0.04995521, 0.05358628, 0.05053166, 0.04124472, 0.03599145, 
    0.03997223, 0.04722374, 0.03393931,
  0.07553687, 0.07894965, 0.0811554, 0.07008664, 0.06027232, 0.05640505, 
    0.05432779, 0.04920416, 0.04180774,
  0.07137626, 0.07484421, 0.07736498, 0.07317983, 0.06901498, 0.05937326, 
    0.05250651, 0.04346381, 0.04085295 ;

 lat = -10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10 ;

 lon = -10, -7.5, -5, -2.5, 0, 2.5, 5, 7.5, 10 ;
}
