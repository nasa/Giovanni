#$Id: get_vertical_dim_var.t,v 1.1 2014/09/14 15:33:17 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 2;
BEGIN { use_ok('Giovanni::Data::NcFile') }
my $cleanup = exists( $ENV{'SAVEDIR'} ) ? 0 : 1;
my $dir = (
    exists( $ENV{SAVEDIR} )
    ? $ENV{SAVEDIR}
    : File::Temp::tempdir( CLEANUP => 1 )
);
my $outfile = "$dir/t_get_vertical_dim_var.nc";
my $ra_cdl  = Giovanni::Data::NcFile::read_cdl_data_block();
Giovanni::Data::NcFile::write_netcdf_file( $outfile, $ra_cdl->[0] )
    or die "Could not write netcdf file\n";
my ( $var, $rh_attrs )
    = Giovanni::Data::NcFile::get_vertical_dim_var( $outfile, 0,
    'AIRX3STD_006_Temperature_A' );
is( $var, "TempPrsLvls_A", "Got vertical dimension variable" );

exit(0);

__DATA__
netcdf averaged.AIRX3STD_006_Temperature_A.20030101-20030101.106W_35N_92W_46N {
dimensions:
	bnds = 2 ;
	TempPrsLvls_A = 24 ;
variables:
	int time_bnds(bnds) ;
		time_bnds:long_name = "Time Bounds" ;
	double AIRX3STD_006_Temperature_A(TempPrsLvls_A) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999. ;
		AIRX3STD_006_Temperature_A:coordinates = "TempPrsLvls_A bnds" ;
		AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature (3D), daytime (ascending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:units = "K" ;
	float TempPrsLvls_A(TempPrsLvls_A) ;
		TempPrsLvls_A:standard_name = "Pressure" ;
		TempPrsLvls_A:long_name = "Pressure Levels Temperature Profile, daytime (ascending) node" ;
		TempPrsLvls_A:units = "hPa" ;
		TempPrsLvls_A:positive = "down" ;
		TempPrsLvls_A:_CoordinateAxisType = "GeoZ" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2003-01-01T00:00:00Z" ;
		:end_time = "2003-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.3.1" ;
		:bounding_box = "-106.1719,35.5078,-92.8125,46.0547" ;
		:title = "Vertical Profile(106.1719W - 92.8125W, 35.5078N - 46.0547N)" ;
		:plot_hint_title = "Atmospheric Temperature (3D), daytime (ascending), AIRS, 1 x 1 deg. daily 1 deg. [AIRS AIRX3STD v006]" ;
		:plot_hint_subtitle = "Area-Averaged (106.1719W, 35.5078N, 92.8125W, 46.0547N)\n",
			"2003-01-01" ;
		:plot_hint_y_axis_label = "Pressure Levels Temperature Profile, daytime (ascending) node (hPa)" ;
		:plot_hint_x_axis_label = "K" ;
data:

 time_bnds = 1041379200, 1041465599 ;

 AIRX3STD_006_Temperature_A = _, 274.541986515399, 271.859577079682, 
    264.447892812366, 258.103501684722, 249.468493714116, 237.870895539968, 
    224.043796500132, 219.242036108687, 220.440964107411, 220.571947754998, 
    216.46623589976, 214.76724884602, 213.978090471014, 214.933499710226, 
    217.372762340902, 219.094732522949, 221.710962687314, 224.047729793229, 
    226.608635904311, 229.505123442072, 231.306437239417, 237.345571730636, 
    248.550143430771 ;

 TempPrsLvls_A = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;
}
