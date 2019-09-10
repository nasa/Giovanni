#$Id: Giovanni-WorldLongitude_Hovmoller.t,v 1.3 2014/02/27 21:53:23 csmit Exp $
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
    = "$dir/dimensionAveraged.G4P0_1DA_2D_du_aot_006_tauf2d_du_00550.20030101-20030102.159E_50S_170W_28S.nc";
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
my $correctNc
    = "$dir/dimensionAveragedWorldLon.G4P0_1DA_2D_du_aot_006_tauf2d_du_00550.20030101-20030102.159E_50S_170W_28S.nc";
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

#http://s4ptu-ts2.ecs.nasa.gov/giovanni/#service=HOV_LON&starttime=2003-01-01T00:00:00Z&endtime=2003-01-02T23:59:59Z&bbox=159.7852,-50.4141,-170.6836,-28.6172&data=G4P0_1DA_2D_du_aot_006_tauf2d_du_00550&dataKeyword=GOCART
__DATA__
netcdf dimensionAveraged.G4P0_1DA_2D_du_aot_006_tauf2d_du_00550.20030101-20030102.159E_50S_170W_28S {
dimensions:
    time = UNLIMITED ; // (2 currently)
    lon = 12 ;
variables:
    float G4P0_1DA_2D_du_aot_006_tauf2d_du_00550(time, lon) ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:_FillValue = -9999.f ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:long_name = "Aerosol Optical Depth of Dust (fine) 550 nm, GOCART model, 2.0 x 2.5 deg." ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:units = "1" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:cell_methods = "time: mean" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:coordinates = "time lat lon" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:standard_name = "tauf2d_du_00550" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:quantity_type = "Component Aerosol Optical Depth" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:product_short_name = "G4P0_1DA_2D_du_aot" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:product_version = "006" ;
    float lon(lon) ;
        lon:borders = "ilon" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:calendar = "gregorian" ;
        time:long_name = "time" ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :nco_openmp_thread_number = 1 ;
        :start_time = "2003-01-01T00:00:00Z" ;
        :end_time = "2003-01-02T23:59:59Z" ;
        :temporal_resolution = "daily" ;
data:

 G4P0_1DA_2D_du_aot_006_tauf2d_du_00550 =
  0.001584754, 0.001307213, 0.001276372, 0.001546797, 0.00204906, 
    0.002626914, 0.003268781, 0.0039548, 0.004756321, 0.005428692, 
    0.00581046, 0.005942333,
  0.0009925751, 0.0007078457, 0.000617906, 0.0007796062, 0.001323624, 
    0.002019172, 0.00233187, 0.002673671, 0.003261904, 0.004015641, 
    0.004748738, 0.005167267 ;

 lon = 160, 162.5, 165, 167.5, 170, 172.5, 175, 177.5, -180, -177.5, -175, 
    -172.5 ;

 time = 1041379200, 1041465600 ;
}
netcdf dimensionAveragedWorldLon.G4P0_1DA_2D_du_aot_006_tauf2d_du_00550.20030101-20030102.159E_50S_170W_28S {
dimensions:
    time = UNLIMITED ; // (2 currently)
    lon = 144 ;
variables:
    float G4P0_1DA_2D_du_aot_006_tauf2d_du_00550(time, lon) ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:_FillValue = -9999.f ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:cell_methods = "time: mean" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:coordinates = "time lat lon" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:long_name = "Aerosol Optical Depth of Dust (fine) 550 nm, GOCART model, 2.0 x 2.5 deg." ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:product_short_name = "G4P0_1DA_2D_du_aot" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:product_version = "006" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:quantity_type = "Component Aerosol Optical Depth" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:standard_name = "tauf2d_du_00550" ;
        G4P0_1DA_2D_du_aot_006_tauf2d_du_00550:units = "1" ;
    float lon(lon) ;
        lon:borders = "ilon" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:calendar = "gregorian" ;
        time:long_name = "time" ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :nco_openmp_thread_number = 1 ;
        :start_time = "2003-01-01T00:00:00Z" ;
        :end_time = "2003-01-02T23:59:59Z" ;
        :temporal_resolution = "daily" ;
data:

 G4P0_1DA_2D_du_aot_006_tauf2d_du_00550 =
  0.004756321, 0.005428692, 0.00581046, 0.005942333, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, 0.001584754, 0.001307213, 0.001276372, 0.001546797, 
    0.00204906, 0.002626914, 0.003268781, 0.0039548,
  0.003261904, 0.004015641, 0.004748738, 0.005167267, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, 0.0009925751, 0.0007078457, 0.000617906, 0.0007796062, 
    0.001323624, 0.002019172, 0.00233187, 0.002673671 ;

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

 time = 1041379200, 1041465600 ;
}
