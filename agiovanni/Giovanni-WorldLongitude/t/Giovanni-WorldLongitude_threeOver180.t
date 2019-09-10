#$Id: Giovanni-WorldLongitude_threeOver180.t,v 1.1 2014/09/05 18:49:08 csmit Exp $
#-@@@ GIOVANNI,Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-GridNormalizer.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::WorldLongitude') }

#########################

use File::Temp qw/ tempdir /;
use Giovanni::Data::NcFile;
use Giovanni::Logger;

# create a working directory
my $dir = tempdir( CLEANUP => 1 );

# create the input data file
my ( $inCdl, $correctCdl ) = readCdlData();

my $dataFile
    = "$dir/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc";
Giovanni::Data::NcFile::write_netcdf_file( $dataFile, $inCdl )
    or die "Unable to write input file.";

# create a logger
my $logger = Giovanni::Logger->new(
    session_dir       => $dir,
    manifest_filename => "mfst.blah+whatever.xml"
);

my $outFile = "$dir/out.nc";
Giovanni::WorldLongitude::normalize(
    logger       => $logger,
    in           => [$dataFile],
    out          => [$outFile],
    startPercent => 50,
    endPercent   => 100,
    sessionDir   => $dir,
);

ok( -e $outFile, "Output file exists" ) or die;

# write the correct data file
my $correctNc = "$dir/correct.nc";
Giovanni::Data::NcFile::write_netcdf_file( $correctNc, $correctCdl )
    or die "Unable to write test output file.";

my $out
    = Giovanni::Data::NcFile::diff_netcdf_files( $outFile, $correctNc, $dir,
    "history" );

is( $out, 0, "Same output: $out" );

sub readCdlData {

    # read block at __DATA__ and write to a CDL file
    #(stolen from Chris...)
    my @cdldata;
    while (<DATA>) {
        push @cdldata, $_;
    }
    my $allCdf = join( '', @cdldata );

    # now divide up
    my @cdl = ( $allCdf =~ m/(netcdf .*?\}\n)/gs );
    return @cdl;
}

__DATA__
netcdf timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S {
dimensions:
    lat = 4 ;
    lon = 3 ;
variables:
    float G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550(lat, lon) ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:_FillValue = -9999.f ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:standard_name = "atmosphere_optical_thickness_due_to_black_carbon_ambient_aerosol" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:long_name = "Aerosol Optical Depth of Black Carbon 550 nm" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:units = "1" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:cell_methods = "time: mean" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:coordinates = "time lat lon" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:quantity_type = "Component Aerosol Optical Depth" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:product_short_name = "G4P0_1DA_2D_cc_aot" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:product_version = "006" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:latitude_resolution = 2. ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:longitude_resolution = 2.5 ;
    float lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:borders = "ilat" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:borders = "ilon" ;
        lon:units = "degrees_east" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :nco_openmp_thread_number = 1 ;
        :start_time = "2004-01-01T00:00:00Z" ;
        :end_time = "2004-01-09T23:59:59Z" ;
        :history = "Fri Sep  5 17:05:39 2014: ncatted -a valid_range,,d,, -O -o /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc\n",
            "Fri Sep  5 17:05:39 2014: ncatted -O -a title,global,o,c,G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550 Averaged over 2004-01-01 to 2004-01-09 /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc\n",
            "Fri Sep  5 17:05:39 2014: ncks -x -v time -o /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc -O /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc\n",
            "Fri Sep  5 17:05:39 2014: ncwa -o /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc -a time -O /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc\n",
            "Fri Sep  5 17:05:39 2014: ncra -D 2 -H -O -o /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc -d lat,-20.302700,-13.974600 -d lon,175.605500,-177.363300" ;
        :title = "G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550 Averaged over 2004-01-01 to 2004-01-09" ;
data:

 G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550 =
  0.0009132327, 0.0009364591, 0.000932778,
  0.0008033698, 0.000845145, 0.0008558528,
  0.0006723349, 0.000718848, 0.0007356462,
  0.0006152941, 0.0006431715, 0.0006710087 ;

 lat = -20, -18, -16, -14 ;

 lon = 177.5, -180, -177.5 ;
}
netcdf out {
dimensions:
    lat = 4 ;
    lon = 144 ;
variables:
    float G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550(lat, lon) ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:_FillValue = -9999.f ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:cell_methods = "time: mean" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:coordinates = "time lat lon" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:latitude_resolution = 2. ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:long_name = "Aerosol Optical Depth of Black Carbon 550 nm" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:longitude_resolution = 2.5 ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:product_short_name = "G4P0_1DA_2D_cc_aot" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:product_version = "006" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:quantity_type = "Component Aerosol Optical Depth" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:standard_name = "atmosphere_optical_thickness_due_to_black_carbon_ambient_aerosol" ;
        G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550:units = "1" ;
    float lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:borders = "ilat" ;
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
        :start_time = "2004-01-01T00:00:00Z" ;
        :end_time = "2004-01-09T23:59:59Z" ;
        :history = "Fri Sep  5 17:05:39 2014: ncatted -a valid_range,,d,, -O -o /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc\n",
            "Fri Sep  5 17:05:39 2014: ncatted -O -a title,global,o,c,G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550 Averaged over 2004-01-01 to 2004-01-09 /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc\n",
            "Fri Sep  5 17:05:39 2014: ncks -x -v time -o /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc -O /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc\n",
            "Fri Sep  5 17:05:39 2014: ncwa -o /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc -a time -O /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc\n",
            "Fri Sep  5 17:05:39 2014: ncra -D 2 -H -O -o /var/tmp/www/TS2/giovanni/D2E9F60E-351E-11E4-9535-EB51CA790440/D7B80928-351E-11E4-AF77-83B26B193920/D7B824BC-351E-11E4-AE86-9FA8D52F19D5/timeAvg.G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550.20040101-20040109.176E_20S_177W_14S.nc -d lat,-20.302700,-13.974600 -d lon,175.605500,-177.363300" ;
        :title = "G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550 Averaged over 2004-01-01 to 2004-01-09" ;
data:

 G4P0_1DA_2D_cc_aot_006_tau2d_bc_00550 =
  0.0009364591, 0.000932778, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, 0.0009132327,
  0.000845145, 0.0008558528, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, 0.0008033698,
  0.000718848, 0.0007356462, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, 0.0006723349,
  0.0006431715, 0.0006710087, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, 0.0006152941 ;

 lat = -20, -18, -16, -14 ;

 lon = -180, -177.5, -175, -172.5, -170, -167.5, -165, -162.5, -160, -157.5, 
    -155, -152.5, -150, -147.5, -145, -142.5, -140, -137.5, -135, -132.5, 
    -130, -127.5, -125, -122.5, -120, -117.5, -115, -112.5, -110, -107.5, 
    -105, -102.5, -100, -97.5, -95, -92.5, -90, -87.5, -85, -82.5, -80, 
    -77.5, -75, -72.5, -70, -67.5, -65, -62.5, -60, -57.5, -55, -52.5, -50, 
    -47.5, -45, -42.5, -40, -37.5, -35, -32.5, -30, -27.5, -25, -22.5, -20, 
    -17.5, -15, -12.5, -10, -7.5, -5, -2.5, 0, 2.5, 5, 7.5, 10, 12.5, 15, 
    17.5, 20, 22.5, 25, 27.5, 30, 32.5, 35, 37.5, 40, 42.5, 45, 47.5, 50, 
    52.5, 55, 57.5, 60, 62.5, 65, 67.5, 70, 72.5, 75, 77.5, 80, 82.5, 85, 
    87.5, 90, 92.5, 95, 97.5, 100, 102.5, 105, 107.5, 110, 112.5, 115, 117.5, 
    120, 122.5, 125, 127.5, 130, 132.5, 135, 137.5, 140, 142.5, 145, 147.5, 
    150, 152.5, 155, 157.5, 160, 162.5, 165, 167.5, 170, 172.5, 175, 177.5 ;
}

