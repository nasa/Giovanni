#$Id: dump_var_1d.t,v 1.1 2014/09/15 00:07:33 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 2;
BEGIN { use_ok('Giovanni::Data::NcFile') }
my $dir
    = ( exists $ENV{SAVEDIR} )
    ? $ENV{SAVEDIR}
    : File::Temp::tempdir( CLEANUP => 1 );
my $file   = "$dir/t_get_variable_type.nc";
my $ra_cdl = Giovanni::Data::NcFile::read_cdl_data_block();
Giovanni::Data::NcFile::write_netcdf_file( $file, $ra_cdl->[0] )
    or die "Could not write netcdf file\n";

# Now execute test
Giovanni::Data::NcFile::dump_var_1d( $file, 0, 'lat', "lat.txt" );
my @lat = `cat lat.txt`;
map { chomp $lat[$_] } 0 .. 4;
is( $lat[4], 39 ) and unlink('lat.txt');

exit(0);

__DATA__
netcdf timeAvg.aod.20091231-20100102.116E_28N_118E_44N.SEASON_DJF {
dimensions:
        lat = 5 ;
        lon = 2 ;
variables:
        int lat(lat) ;
                lat:long_name = "Latitude" ;
                lat:units = "degrees_north" ;
        float lon(lon) ;
                lon:long_name = "Longitude" ;
                lon:units = "degrees_east" ;
        double aod(lat, lon) ;
                aod:coordinates = "time lat lon" ;

// global attributes:
                :title = "Aod Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43, 42, 41, 40, 39 ;

 lon = 116.5, 117.5 ;

 aod =
  _, _,
  _, _,
  0.138, 0.17,
  0.139, 0.132,
  0.707, 0.632 ;
}
