#$Id: read_cdl_data_block.t,v 1.1 2014/02/25 22:34:43 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 2;
BEGIN { use_ok('Giovanni::Data::NcFile') }
my $ra_cdl = Giovanni::Data::NcFile::read_cdl_data_block();
my @cdl    = @$ra_cdl;
is( scalar(@cdl), 2, "Read 2 CDLs" );
exit(0);

__DATA__
netcdf timeAvg.aod.20091231-20100102.116E_28N_118E_44N.SEASON_DJF {
dimensions:
        lat = 16 ;
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
                aod:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
                aod:valid_range = -100s, 5000s ;
                aod:_FillValue = -9999. ;

// global attributes:
                :title = "Aod Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43.5, 42.5, 41.5, 40.5, 39.5, 38.5, 37.5, 36.5, 35.5, 34.5, 33.5,
    32.5, 31.5, 30.5, 29.5, 28.5 ;

 lon = 116.5, 117.5 ;

 aod =
  _, _,
  _, _,
  0.138, 0.17,
  0.139, 0.132,
  0.283, 1.455,
  0.253, 0.247,
  0.459, 0.4585,
  0.481, 0.455,
  0.4675, 0.308,
  0.46, 0.477,
  0.4655, 0.443,
  0.515, 0.498,
  0.4645, 0.547,
  0.5895, 0.5015,
  0.676, 0.626,
  0.707, 0.632 ;
}
netcdf timeAvg.aod.20091231-20100102.116E_28N_118E_29N.SEASON_DJF {
dimensions:
        lat = 1 ;
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
                aod:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
                aod:valid_range = -100s, 5000s ;
                aod:_FillValue = -9999. ;

// global attributes:
                :title = "Aod Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43.5 ;

 lon = 116.5, 117.5 ;

 aod =
  0.707, 0.632 ;
}
