#$Id: get_lat_lon_dimnames.t,v 1.2 2014/06/27 20:38:48 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 5;
BEGIN { use_ok('Giovanni::Data::NcFile') }

# GDS Case
my ( $lat_dim, $lon_dim )
    = Giovanni::Data::NcFile::get_lat_lon_dimnames(
    "http://disc2.gesdisc.eosdis.nasa.gov/opendap/TRMM_L3/TRMM_3B42.7/2016/213/3B42.20160731.21.7.HDF", 0 );
is( $lat_dim, "nlat", "Lat from GDS" );
is( $lon_dim, "nlon", "Lon from GDS" );

# Local file case
my $cleanup = defined( $ENV{'CLEANUP'} ) ? $ENV{'CLEANUP'} : 1;
my $dir     = File::Temp::tempdir( CLEANUP => $cleanup );
my $outfile = "$dir/t_lat_lon_dimnames.nc";
my $ra_cdl  = Giovanni::Data::NcFile::read_cdl_data_block();
Giovanni::Data::NcFile::write_netcdf_file( $outfile, $ra_cdl->[0] )
    or die "Could not write netcdf file\n";
my ( $lat_dim, $lon_dim )
    = Giovanni::Data::NcFile::get_lat_lon_dimnames( $outfile, 0 );
is( $lat_dim, "lat", "Lat from static file" );
is( $lon_dim, "lon", "Lon from static file" );
exit(0);

__DATA__
netcdf timeAvg.aod.20091231-20100102.116E_28N_118E_44N.SEASON_DJF {
dimensions:
        lat = 5 ;
        lon = 2 ;
variables:
        double lat(lat) ;
                lat:long_name = "Latitude" ;
                lat:units = "degrees_north" ;
        double lon(lon) ;
                lon:long_name = "Longitude" ;
                lon:units = "degrees_east" ;
        double aod(lat, lon) ;
                aod:coordinates = "time lat lon" ;

// global attributes:
                :title = "Aod Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43.5, 42.5, 41.5, 40.5, 39.5 ;

 lon = 116.5, 117.5 ;

 aod =
  _, _,
  _, _,
  0.138, 0.17,
  0.139, 0.132,
  0.707, 0.632 ;
}
