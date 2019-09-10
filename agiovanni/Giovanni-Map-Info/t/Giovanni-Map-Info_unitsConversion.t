# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Map-Info.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use File::Temp qw/ tempdir /;

use Test::More tests => 2;
BEGIN { use_ok('Giovanni::Map::Info') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dir = tempdir( CLEANUP => 1 );

# http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/#service=TmAvMp&starttime=2005-01-01T00:00:00Z&endtime=2005-01-01T23:59:59Z&bbox=-127.2656,-49.1015,-4.2187,74.6485&data=AIRX3STD_006_TropTemp_D%28units%3DC%29&dataKeyword=AIRS
my $inputXML = <<'INPUT';
<?xml version="1.0" encoding="UTF-8"?>
<input>
   <referer>http://giovanni-test.gesdisc.eosdis.nasa.gov/giovanni/</referer>
   <query>session=024E2092-CAAA-11E5-BE8A-5D39EAABE979&amp;service=TmAvMp&amp;starttime=2005-01-01T00:00:00Z&amp;endtime=2005-01-01T23:59:59Z&amp;bbox=-127.2656,-49.1015,-4.2187,74.6485&amp;data=AIRX3STD_006_TropTemp_D(units%3DC)&amp;dataKeyword=AIRS&amp;portal=GIOVANNI&amp;format=json</query>
   <title>Time Averaged Map</title>
   <description>Interactive map of average over time at each grid cell from 2005-01-01T00:00:00Z to 2005-01-01T23:59:59Z over -127.2656,-49.1015,-4.2187,74.6485</description>
   <result id="5D2BCC14-CAC1-11E5-B8BB-A351EAABE979">
      <dir>/var/giovanni/session/024E2092-CAAA-11E5-BE8A-5D39EAABE979/5D2B9A28-CAC1-11E5-B8BB-A351EAABE979/5D2BCC14-CAC1-11E5-B8BB-A351EAABE979/</dir>
   </result>
   <bbox>-127.2656,-49.1015,-4.2187,74.6485</bbox>
   <data units="C">AIRX3STD_006_GPHeight_A</data>
   <dataKeyword>AIRS</dataKeyword>
   <endtime>2005-01-01T23:59:59Z</endtime>
   <portal>GIOVANNI</portal>
   <service>TmAvMp</service>
   <session>024E2092-CAAA-11E5-BE8A-5D39EAABE979</session>
   <starttime>2005-01-01T00:00:00Z</starttime>
</input>
INPUT

my $inputFile = "$dir/input.xml";
open( FILE, ">", $inputFile );
print FILE $inputXML;
close(FILE);

my $dataFieldInfo = <<'INFO';
<varList>
  <var id="AIRX3STD_006_GPHeight_A" long_name="Geopotential Height (Daytime/Ascending)" sampleOpendap="http://acdisc.gsfc.nasa.gov/opendap/hyrax/ncml/Aqua_AIRS_Level3/AIRX3STD.006/2002/AIRS.2002.08.31.L3.RetStd001.v6.0.9.0.G13208034313.hdf.ncml.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Aqua%20AIRS%20Level%203%20Daily%20Standard%20Physical%20Retrieval%20(AIRS%2BAMSU)%20V006;agent_id=OPeNDAP;variables=GPHeight_A,TempPrsLvls_A" startTime="2002-08-31T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="daily" dataProductVersion="006" sampleFile="" east="180.0" dataProductShortName="AIRX3STD" osdd="" resolution="1 deg." dataProductPlatformInstrument="AIRS" quantity_type="Geopotential" zDimName="TempPrsLvls_A" dataFieldStandardName="geopotential_height" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="m" latitudeResolution="1.0" accessName="GPHeight_A,TempPrsLvls_A" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="1.0" dataProductEndTimeOffset="-1" west="-180.0" zDimValues="1000 925 850 700 600 500 400 300 250 200 150 100 70 50 30 20 15 10 7 5 3 2 1.5 1" sdsName="GPHeight_A" dataProductBeginDateTime="2002-08-31T00:00:00Z">
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

my %info = Giovanni::Map::Info::gatherVariableInfo(
    DATA_FIELD_INFO => $dataFieldFile,
    INPUT           => $inputFile,
);

is_deeply(
    \%info,
    {   'BBOX' => '127.2656W, 49.1015S, 4.2187W, 74.6485N',
        'FULL_NAME' =>
            'Geopotential Height (Daytime/Ascending) daily 1 deg. [AIRS AIRX3STD v006] C',
        'LONG_NAME'           => 'Geopotential Height (Daytime/Ascending)',
        'PLATFORM_INSTRUMENT' => 'AIRS',
        'PRODUCT_SHORTNAME'   => 'AIRX3STD',
        'SPATIAL_RESOLUTION'  => '1 deg.',
        'TIME_RANGE'          => '2005-01-01',
        'UNITS'               => 'C',
        'VERSION'             => '006',
        'ZUNITS'              => undef,
        'ZVALUE' => undef,
    },
    'Correct info'
);
