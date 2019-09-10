# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Map-Info.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use File::Temp qw/ tempdir /;
use Test::More tests => 2;

use Giovanni::Data::NcFile;

BEGIN { use_ok('Giovanni::Map::Info') }

#########################

my $dir = tempdir( CLEANUP => 1 );

# http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/#service=TmAvOvMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T23:59:59Z&bbox=-180,-90,180,90&data=AIRX3STD_006_GPHeight_A%28z%3D1000%29&dataKeyword=AIRS
my $inputXML = <<'INPUT';
<?xml version="1.0" encoding="UTF-8"?>
<input>
   <referer>http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/</referer>
   <query>session=EF3FEE28-0720-11E6-BAAD-E9D0F1651532&amp;service=TmAvOvMp&amp;starttime=2003-01-01T00:00:00Z&amp;endtime=2003-01-01T23:59:59Z&amp;bbox=-180,-90,180,90&amp;data=AIRX3STD_006_GPHeight_A(z%3D1000)&amp;dataKeyword=AIRS&amp;portal=GIOVANNI&amp;format=json</query>
   <title>Time Averaged Overlay Map</title>
   <description>Interactive Overlay map of average over time at each grid cell from 2003-01-01T00:00:00Z to 2003-01-01T23:59:59Z over -180,-90,180,90</description>
   <result id="F28296DA-0720-11E6-987F-23D1F1651532">
      <dir>/var/giovanni/session/EF3FEE28-0720-11E6-BAAD-E9D0F1651532/F2827B32-0720-11E6-987F-23D1F1651532/F28296DA-0720-11E6-987F-23D1F1651532/</dir>
   </result>
   <bbox>-80.2441,27.3486,-77.6953,29.5459</bbox>
   <data zValue="1000">AIRX3STD_006_GPHeight_A</data>
   <dataKeyword>AIRS</dataKeyword>
   <endtime>2003-01-01T23:59:59Z</endtime>
   <portal>GIOVANNI</portal>
   <service>TmAvOvMp</service>
   <session>EF3FEE28-0720-11E6-BAAD-E9D0F1651532</session>
   <starttime>2003-01-01T00:00:00Z</starttime>
</input>
INPUT

my $inputFile = "$dir/input.xml";
open( FILE, ">", $inputFile );
print FILE $inputXML;
close(FILE);

my $dataFieldInfo = <<'INFO';
<varList>
  <var id="AIRX3STD_006_GPHeight_A" zDimUnits="hPa" long_name="Geopotential Height (Daytime/Ascending)" sampleOpendap="http://acdisc.gsfc.nasa.gov/opendap/hyrax/ncml/Aqua_AIRS_Level3/AIRX3STD.006/2002/AIRS.2002.08.31.L3.RetStd001.v6.0.9.0.G13208034313.hdf.ncml.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Aqua%20AIRS%20Level%203%20Daily%20Standard%20Physical%20Retrieval%20(AIRS%2BAMSU)%20V006;agent_id=OPeNDAP;variables=GPHeight_A,TempPrsLvls_A" startTime="2002-08-31T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="daily" dataProductVersion="006" sampleFile="" east="180.0" dataProductShortName="AIRX3STD" osdd="" resolution="1 deg." dataProductPlatformInstrument="AIRS" quantity_type="Geopotential" zDimName="TempPrsLvls_A" dataFieldStandardName="geopotential_height" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="m" latitudeResolution="1.0" accessName="GPHeight_A,TempPrsLvls_A" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="1.0" dataProductEndTimeOffset="-1" west="-180.0" zDimValues="1000 925 850 700 600 500 400 300 250 200 150 100 70 50 30 20 15 10 7 5 3 2 1.5 1" sdsName="GPHeight_A" dataProductBeginDateTime="2002-08-31T00:00:00Z">
    <slds>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/divergent_rdbu_10_sld.xml" label="Red-Blue (Div), 10"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/spectral_div_10_inv_sld.xml" label="Spectral, Inverted (Div), 10"/>
    </slds>
  </var>
</varList>
INFO

my $dataFieldFile = "$dir/data_field_info.xml";
open( FILE, ">", $dataFieldFile );
print FILE $dataFieldInfo;
close(FILE);

my $cdl    = Giovanni::Data::NcFile::read_cdl_data_block();
my $ncFile = "$dir/file.nc";
Giovanni::Data::NcFile::write_netcdf_file( $ncFile, $cdl->[0] );

my %info = Giovanni::Map::Info::gatherVariableInfo(
    DATA_FIELD_INFO => $dataFieldFile,
    INPUT           => $inputFile,
    DATA            => $ncFile,
);

is_deeply(
    \%info,
    {   'BBOX' => '80.2441W, 27.3486N, 77.6953W, 29.5459N',
        'FULL_NAME' =>
            'Geopotential Height (Daytime/Ascending) daily 1 deg. @1000hPa [AIRS AIRX3STD v006] m',
        'LONG_NAME'           => 'Geopotential Height (Daytime/Ascending)',
        'PLATFORM_INSTRUMENT' => 'AIRS',
        'PRODUCT_SHORTNAME'   => 'AIRX3STD',
        'SPATIAL_RESOLUTION'  => '1 deg.',

   # NOTE: I artificially changed the data time range in the __DATA__
        'TIME_RANGE' => '2002-12-31 22:30Z - 2003-01-01 22:29Z',
        'UNITS'      => 'm',
        'VERSION'    => '006',
        'ZUNITS'     => 'hPa',
        'ZVALUE'     => 1000,
    },
    'Correct info'
);

__DATA__
netcdf g4.timeAvgOverlayMap.AIRX3STD_006_GPHeight_A.1000hPa.20030101-20030101.80W_27N_77W_29N {
dimensions:
    lat = 3 ;
    lon = 2 ;
variables:
    float AIRX3STD_006_GPHeight_A(lat, lon) ;
        AIRX3STD_006_GPHeight_A:_FillValue = -9999.f ;
        AIRX3STD_006_GPHeight_A:standard_name = "geopotential_height" ;
        AIRX3STD_006_GPHeight_A:long_name = "Geopotential Height (Daytime/Ascending)" ;
        AIRX3STD_006_GPHeight_A:units = "m" ;
        AIRX3STD_006_GPHeight_A:coordinates = "lat lon" ;
        AIRX3STD_006_GPHeight_A:quantity_type = "Geopotential" ;
        AIRX3STD_006_GPHeight_A:product_short_name = "AIRX3STD" ;
        AIRX3STD_006_GPHeight_A:product_version = "006" ;
        AIRX3STD_006_GPHeight_A:cell_methods = "time: mean TempPrsLvls_A: mean" ;
        AIRX3STD_006_GPHeight_A:z_slice = "1000hPa" ;
        AIRX3STD_006_GPHeight_A:z_slice_type = "pressure" ;
        AIRX3STD_006_GPHeight_A:latitude_resolution = 1. ;
        AIRX3STD_006_GPHeight_A:longitude_resolution = 1. ;
    double lat(lat) ;
        lat:units = "degrees_north" ;
        lat:format = "F5.1" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
        lat:missing_value = -9999.f ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:format = "F6.1" ;
        lon:standard_name = "longitude" ;
        lon:long_name = "Longitude" ;
        lon:missing_value = -9999.f ;

// global attributes:
        :NCO = "\"4.5.3\"" ;
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2002-12-31T22:30:00Z" ;
        :end_time = "2003-01-01T22:29:59Z" ;
        :userstartdate = "2003-01-01T00:00:00Z" ;
        :userenddate = "2003-01-01T23:59:59Z" ;
        :plot_hint_title = "Time Averaged Overlay Map of Geopotential Height (Daytime/Ascending) daily 1 deg. @1000hPa [AIRS AIRX3STD v006] m" ;
        :plot_hint_subtitle = "over 2003-01-01, Region 80.2441W, 27.3486N, 77.6953W, 29.5459N " ;
data:

 AIRX3STD_006_GPHeight_A =
  114, 115,
  103, 106,
  95, 96 ;

 lat = 27.5, 28.5, 29.5 ;

 lon = -79.5, -78.5 ;
}
