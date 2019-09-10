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

# http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/#service=TmAvOvMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T23:59:59Z&bbox=-99.8437,32.461,-85.7812,43.0078&data=NLDAS_FORA0125_H_002_pressfc&dataKeyword=nldas
my $inputXML = <<'INPUT';
<input>
  <referer>http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/</referer>
  <query>session=118BFA52-0718-11E6-AFD5-B578F2651532&amp;service=TmAvOvMp&amp;starttime=2003-01-01T00:00:00Z&amp;endtime=2003-01-01T23:59:59Z&amp;bbox=-99.8437,32.461,-85.7812,43.0078&amp;data=NLDAS_FORA0125_H_002_pressfc&amp;dataKeyword=nldas&amp;portal=GIOVANNI&amp;format=json</query>
  <title>Time Averaged Overlay Map</title>
  <description>Interactive Overlay map of average over time at each grid cell from 2003-01-01T00:00:00Z to 2003-01-01T23:59:59Z over -99.8437,32.461,-85.7812,43.0078</description>
  <result id="1653F378-0718-11E6-80CD-FA78F2651532">
    <dir>/var/giovanni/session/118BFA52-0718-11E6-AFD5-B578F2651532/164F229E-0718-11E6-80CD-FA78F2651532/1653F378-0718-11E6-80CD-FA78F2651532/
    </dir>
  </result>
  <bbox>-99.8437,32.461,-85.7812,43.0078</bbox><data>NLDAS_FORA0125_H_002_pressfc</data>
  <dataKeyword>nldas</dataKeyword>
  <endtime>2003-01-01T23:59:59Z</endtime>
  <portal>GIOVANNI</portal>
  <service>TmAvOvMp</service>
  <session>118BFA52-0718-11E6-AFD5-B578F2651532</session>
  <starttime>2003-01-01T00:00:00Z</starttime>
</input>
INPUT

my $inputFile = "$dir/input.xml";
open( FILE, ">", $inputFile );
print FILE $inputXML;
close(FILE);

my $dataFieldInfo = <<'INFO';
<varList>
  <var id="NLDAS_FORA0125_H_002_pressfc" long_name="Surface Pressure" searchIntervalDays="30.0" sampleOpendap="http://hydro1.sci.gsfc.nasa.gov/thredds/dodsC/NLDAS_FORA0125_H.002/1979/001/NLDAS_FORA0125_H.A19790101.1300.002.grb" dataProductTimeFrequency="1" accessFormat="native" north="53.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=native;dataset_id=NLDAS%20Primary%20Forcing%20Data%20L4%20Hourly%200.125%20x%200.125%20degree%20V002;agent_id=OPeNDAP;variables=Pressure" startTime="1979-01-01T00:00:00Z" responseFormat="DAP" south="25.0" dataProductTimeInterval="hourly" dataProductVersion="002" sampleFile="" east="-67.0" dataProductShortName="NLDAS_FORA0125_H" osdd="" resolution="0.125 deg." dataProductPlatformInstrument="NLDAS Model" quantity_type="Air Pressure" dataFieldStandardName="" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="Pa" latitudeResolution="0.125" accessName="Pressure" fillValueFieldName="missing_value" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." longitudeResolution="0.125" dataProductStartTimeOffset="1" dataProductEndTimeOffset="0" west="-125.0" sdsName="pressfc" dataProductBeginDateTime="1979-01-01T00:00:00Z">
    <slds>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/divergent_burd_11_sld.xml" label="Blue-Red (Div), 11"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/time_matched_difference_sld.xml" label="Blue-Yellow-Red (Div), 13"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_ylgn_9_sld.xml" label="Yellow-Green (Seq), 9"/>
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
    {   'BBOX' => '99.8437W, 32.461N, 85.7812W, 43.0078N',
        'FULL_NAME' =>
            'Surface Pressure hourly 0.125 deg. [NLDAS Model NLDAS_FORA0125_H v002] Pa',
        'LONG_NAME'           => 'Surface Pressure',
        'PLATFORM_INSTRUMENT' => 'NLDAS Model',
        'PRODUCT_SHORTNAME'   => 'NLDAS_FORA0125_H',
        'SPATIAL_RESOLUTION'  => '0.125 deg.',
        'TIME_RANGE'          => '2003-01-01 00Z - 2003-01-01 23Z',
        'UNITS'               => 'Pa',
        'VERSION'             => '002',
        'ZUNITS'              => undef,
        'ZVALUE'              => undef,
    },
    'Correct info'
);
