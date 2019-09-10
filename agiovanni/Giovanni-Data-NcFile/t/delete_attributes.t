#$Id: delete_attributes.t,v 1.4 2015/03/19 15:00:57 rstrub Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 3;
BEGIN { use_ok('Giovanni::Data::NcFile') }
my $cleanup = defined( $ENV{'CLEANUP'} ) ? $ENV{'CLEANUP'} : 1;
my $dir     = File::Temp::tempdir( CLEANUP => $cleanup );
my $outfile = "$dir/t_lat_lon_dimnames.nc";
my $ra_cdl  = Giovanni::Data::NcFile::read_cdl_data_block();
Giovanni::Data::NcFile::write_netcdf_file( $outfile, $ra_cdl->[0] )
    or die "Could not write netcdf file\n";
my $validrange = `ncdump -h $outfile | /bin/grep valid_range`;
$validrange =~ s/^\s+//g;
$validrange =~ s/\s+$//g;

my $nc = Giovanni::Data::NcFile->new( NCFILE => $outfile, verbose => 0 );
$nc->delete_attribute( "valid_range", "UVAerosolIndex" );

is( $validrange, "UVAerosolIndex:valid_range = -30.f, 30.f ;" );
$validrange = `ncdump -h $outfile | /bin/grep valid_range`;
is( $validrange, "" );
exit(0);

__DATA__
netcdf OMI-Aura_L3-OMTO3d_2007m0109_v003-2012m0405t195243.he5 {
dimensions:
    lat = 180 ;
    lon = 360 ;
variables:
    float UVAerosolIndex(lat, lon) ;
        UVAerosolIndex:h5__FillValue = -1.267651e+30f ;
        UVAerosolIndex:units = "NoUnits" ;
        UVAerosolIndex:title = "UV Aerosol Index" ;
        UVAerosolIndex:UniqueFieldDefinition = "TOMS-OMI-Shared" ;
        UVAerosolIndex:scale_factor = 1. ;
        UVAerosolIndex:add_offset = 0. ;
        UVAerosolIndex:valid_range = -30.f, 30.f ;
        UVAerosolIndex:missing_value = -1.267651e+30f ;
        UVAerosolIndex:origname = "UVAerosolIndex" ;
        UVAerosolIndex:fullnamepath = "/HDFEOS/GRIDS/OMI Column Amount O3/Data Fields/UVAerosolIndex" ;
        UVAerosolIndex:orig_dimname_list = "XDim " ;
    float lon(lon) ;
        lon:units = "degrees_east" ;
    float lat(lat) ;
        lat:units = "degrees_north" ;


data:

 lat = 43.5, 42.5, 41.5, 40.5, 39.5 ;

 lon = 116.5, 117.5 ;

 UVAerosolIndex =
  .4, .4,
  .4, .4,
  0.138, 0.17,
  0.139, 0.132,
  0.707, 0.632 ;
}
