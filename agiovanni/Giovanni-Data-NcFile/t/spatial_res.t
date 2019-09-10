#$Id: spatial_res.t,v 1.1 2014/04/19 21:35:21 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 19;
BEGIN { use_ok('Giovanni::Data::NcFile') }
my $cleanup = defined( $ENV{'CLEANUP'} ) ? $ENV{'CLEANUP'} : 1;
my $dir = File::Temp::tempdir( CLEANUP => $cleanup );
my @outfiles = map { "$dir/t_spatial_res" . $_ . '.nc' } 0 .. 2;
my $ra_cdl = Giovanni::Data::NcFile::read_cdl_data_block();
map {
    Giovanni::Data::NcFile::write_netcdf_file( $outfiles[$_], $ra_cdl->[$_] )
} 0 .. 2;
my $ra_boxes = [
    [ 116., 39., 118., 44. ],
    [ 116., 42., 119., 44. ],
    [ 116., 42., 118., 44. ],
];

foreach my $i ( 0 .. 2 ) {
    my ( $latres, $lonres )
        = Giovanni::Data::NcFile::spatial_resolution( $outfiles[$i] );
    is( $latres, 1., "Latitude resolution for file $i" );
    is( $lonres, 1., "Longitude resolution for file $i" );
    my $bbox = Giovanni::Data::NcFile::data_bbox( $outfiles[$i] );
    my @bbox = split( ',', $bbox );
    foreach my $j ( 0 .. 3 ) {
        ok( $bbox[$j] == $ra_boxes->[$i]->[$j],
            "Compare bbox $i: $bbox[$j] vs $ra_boxes->[$i]->[$j]" );
    }
}
exit(0);

__DATA__
netcdf test1 {
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
netcdf test2 {
dimensions:
        lat = 2 ;
        lon = 3 ;
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

 lat = 43.5, 42.5 ;

 lon = 116.5, 117.5, 118.5 ;

 aod =
  0.138, 0.17, 0.146,
  0.139, 0.707, 0.632 ;
}
netcdf test3 {
dimensions:
        lat = 2 ;
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

 lat = 43.5, 42.5 ;

 lon = 116.5, 117.5 ;

 aod =
  0.138, 0.17, 
  0.139, 0.632 ;
}
