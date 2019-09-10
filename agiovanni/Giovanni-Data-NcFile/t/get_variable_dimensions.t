#$Id: get_variable_dimensions.t,v 1.3 2014/09/14 23:33:04 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 4;
BEGIN { use_ok('Giovanni::Data::NcFile') }
my $cleanup = defined( $ENV{'CLEANUP'} ) ? $ENV{'CLEANUP'} : 1;
my $dir     = File::Temp::tempdir( CLEANUP => $cleanup );
my $outfile = "$dir/t_get_variable_dimensions.nc";
my $ra_cdl  = Giovanni::Data::NcFile::read_cdl_data_block();
Giovanni::Data::NcFile::write_netcdf_file( $outfile, $ra_cdl->[0] )
    or die "Could not write netcdf file\n";

# Now execute tests
my $shape
    = Giovanni::Data::NcFile::get_variable_dimensions( $outfile, 0, 'aod' );
is( $shape, "lat lon", "Got shape $shape" );

# Closely related function:  set_variable_coordinates
ok( Giovanni::Data::NcFile::set_variable_coordinates(
        $outfile, $outfile, 0, 'aod'
    ),
    "set variable coordinates"
);
my ( $rh_attrs, $ra_attrs )
    = Giovanni::Data::NcFile::get_variable_attributes( $outfile, 0, 'aod' );
is( $rh_attrs->{coordinates}, "lat lon", "compare output coordinates attr" );

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
