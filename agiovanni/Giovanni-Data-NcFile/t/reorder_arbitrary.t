#$Id: reorder_arbitrary.t,v 1.1 2014/04/10 14:36:34 rstrub Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 5;
BEGIN { use_ok('Giovanni::Data::NcFile') }
my $cleanup = defined( $ENV{'CLEANUP'} ) ? $ENV{'CLEANUP'} : 1;
my $dir     = File::Temp::tempdir( CLEANUP => $cleanup );
my $outfile = "$dir/t_lat_lon_dimnames.nc";
my $ra_cdl  = Giovanni::Data::NcFile::read_cdl_data_block();
Giovanni::Data::NcFile::write_netcdf_file( $outfile, $ra_cdl->[0] )
    or die "Could not write netcdf file\n";
my $snow   = `ncdump -h $outfile | /bin/grep "float snow"`;
my $coords = `ncdump -h $outfile | /bin/grep "snow:coordinates"`;
$snow   =~ s/^\s+//g;
$snow   =~ s/\s+$//g;
$coords =~ s/^\s+//g;
$coords =~ s/\s+$//g;
Giovanni::Data::NcFile::reorder_dimension( $outfile, "nlayer", 2, 0 );
my $snowafter   = `ncdump -h $outfile | /bin/grep "float snow"`;
my $coordsafter = `ncdump -h $outfile | /bin/grep "snow:coordinates"`;
$snowafter   =~ s/^\s+//g;
$snowafter   =~ s/\s+$//g;
$coordsafter =~ s/^\s+//g;
$coordsafter =~ s/\s+$//g;
is( $snow,        "float snow(nlayer, nlon, nlat) ;" );
is( $snowafter,   "float snow(nlat, nlon, nlayer) ;" );
is( $coords,      qq(snow:coordinates = "nlayer nlon nlat" ;) );
is( $coordsafter, qq(snow:coordinates = "nlat nlon nlayer" ;) );
exit(0);

__DATA__
netcdf \3A12.20090501.7.HDF.Z.ncml.TRMM_3A12_007_snow {
dimensions:
	nlayer = 28 ;
	nlon = 720 ;
	nlat = 160 ;
variables:
	float snow(nlayer, nlon, nlat) ;
		snow:long_name = "snow" ;
		snow:units = "g/m^3" ;
		snow:coordinates = "nlayer nlon nlat" ;
		snow:_FillValue = -9999.9f ;
	float nlat(nlat) ;
		nlat:units = "degrees_north" ;
		nlat:standard_name = "latitude" ;
	float nlon(nlon) ;
		nlon:units = "degrees_east" ;
		nlon:standard_name = "longitude" ;
	float nlayer(nlayer) ;
		nlayer:standard_name = "height" ;
		nlayer:units = "km" ;


data:

 nlat = 43.5, 42.5, 41.5, 40.5, 39.5 ;

 nlon = 116.5, 117.5 ;

 nlayer = 116.5, 117.5 ;

 snow =
  _, _,
  _, _,
  0.138, 0.17,
  0.139, 0.132,
  0.707, 0.632 ;
}
