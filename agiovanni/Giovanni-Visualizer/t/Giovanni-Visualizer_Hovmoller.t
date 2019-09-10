# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Visualizer.t'

#############################################################
## 2012-05-02 X. Hu
## Need to set the paths to Preferences.pm, Util.pm, and the path to DataOutputManager.jar properly
## to run this test
#############################################################
use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;

use Giovanni::Data::NcFile;

use Test::More tests => 4;
use Safe;
BEGIN { use_ok('Giovanni::Visualizer') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# create a temporary directory for the data file
my $dir = tempdir( CLEANUP => 1 );

# write input file to temporary directory
my $cdl = Giovanni::Data::NcFile::read_cdl_data_block();
my $ncFile
    = "$dir/g4.dimensionAveraged.TRMM_3B42_Daily_7_precipitation.20030101-20030105.121W_38N_75W_44N.nc";
Giovanni::Data::NcFile::write_netcdf_file( $ncFile, $cdl->[0] )
    or die "Could not write netcdf file\n";

#https://dev.gesdisc.eosdis.nasa.gov/giovanni/#service=HvLt&starttime=2003-01-01T00:00:00Z&endtime=2003-01-05T23:59:59Z&bbox=-121,38,-75,44&data=TRMM_3B42_Daily_7_precipitation

# Write input file
my $inputXML = <<'INPUT';
<input>
<referer>https://dev.gesdisc.eosdis.nasa.gov/giovanni/</referer>
<query>

</query>
<title>Hovmoller, Longitude-Averaged</title>
<description>
Longitude-averaged Hovmoller, plotted over the selected time and latitude ranges from 2003-01-01T00:00:00Z to 2003-01-05T23:59:59Z over -121,38,-75,44
</description>
<result id="CFC01BEE-B8C3-11E7-8CF0-EE17F8F833F2">
<dir>
OURDIR
</dir>
</result>
<bbox>-121,38,-75,44</bbox>
<data>TRMM_3B42_Daily_7_precipitation</data>
<endtime>2003-01-05T23:59:59Z</endtime>
<portal>GIOVANNI</portal>
<service>HvLt</service>
<session>64957864-B8C3-11E7-8860-2606F8F833F2</session>
<starttime>2003-01-01T00:00:00Z</starttime>
</input>
INPUT

$inputXML =~ s/OURDIR/$dir/g;
my $inputFile = "$dir/input.xml";
open( FILE, ">", $inputFile );
print FILE $inputXML;
close(FILE);

# Write SLD list
my $sldXML = <<'SLD';
   <slds>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/divergent_burd_11_sld.xml" label="Blue-Red (Div), 11"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/time_matched_difference_sld.xml" label="Blue-Yellow-Red (Div), 13"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_ylgn_9_sld.xml" label="Yellow-Green (Seq), 9"/>
    </slds>
SLD

my $sldFile = "$dir/sld_list.xml";
open( FILE, ">", $sldFile );
print FILE $sldXML;
close(FILE);

# write the data field manifest
my $XML = <<'XML';
<varList>
  <var id="TRMM_3B42_Daily_7_precipitation" long_name="Precipitation Rate" 
  dataProductTimeFrequency="1" accessFormat="netCDF" north="50.0" 
  accessMethod="HTTP_Services_HDF_TO_NetCDF" endTime="2038-01-19T03:14:07Z" 
  url="http://dev-ts2.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Daily%20TRMM%20and%20Others%20Rainfall%20Estimate%20(3B42%20V7%20derived)%20V7;agent_id=HTTP_Services_HDF_TO_NetCDF;variables=precipitation" 
  startTime="1997-12-31T00:00:00Z" responseFormat="netCDF" south="-50.0" 
  dataProductTimeInterval="daily" dataProductVersion="7" nominalMin="0.1" 
  sampleFile="" east="180.0" dataProductShortName="TRMM_3B42_daily" osdd="" 
  resolution="0.25 deg." dataProductPlatformInstrument="TRMM" 
  quantity_type="Precipitation" nominalMax="10.0" 
  dataFieldStandardName="" dataProductEndDateTime="2038-01-19T03:14:07Z" 
  dataFieldUnitsValue="mm/day" latitudeResolution="0.25" 
  accessName="precipitation" fillValueFieldName="" valuesDistribution="linear" 
  accumulatable="true" spatialResolutionUnits="deg." longitudeResolution="0.25" 
  dataProductStartTimeOffset="-5400" dataProductEndTimeOffset="-5401" 
  west="-180.0" sdsName="precipitation" 
  dataProductBeginDateTime="1997-12-31T00:00:00Z">
    <slds>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/divergent_burd_11_sld.xml" label="Blue-Red (Div), 11"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/time_matched_difference_sld.xml" label="Blue-Yellow-Red (Div), 13"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_ylgn_9_sld.xml" label="Yellow-Green (Seq), 9"/>
    </slds>
  </var>
</varList>
XML

my $dataFieldInfoFile
    = "$dir/mfst.data_field_info+dTRMM_3B42_Daily_7_precipitation.xml";
open( FILE, ">", $dataFieldInfoFile )
    or die "Unable to opn $dataFieldInfoFile";
print FILE $XML;
close(FILE);

# Write JSON schema file
my $HOV_LAT_Json = <<'JSON';
{"title":"Hovmoller, Latitude-Averaged","type":"object","properties":{
"Data":{"propertyOrder":1,"type":"object","properties":{
"Label":{"propertyOrder": 1,"type":"string","readOnly":true},
"Range":{"$ref":"#/definitions/range"}}},
"Palette":{"propertyOrder":2,"type":"object","enum":[{
"label":"placeholder - palette label",
"legend":"placeholder - palette icon url",
"sld":"placeholder - sld xml url"}]}},
"definitions":{"axis":{"type":"object","properties":{"Label":{
"propertyOrder":1,"type":"string","readOnly":true},
"Range":{"propertyOrder":2,"$ref":"#/definitions/range"}}},
"lineFit":{"type":"boolean","format":"checkbox"},
"scale":{"type":"string","required":true,"enum":["Linear","Log"]},
"range":{"type":"object","properties":{
"Min":{"propertyOrder":1,"type":"number"},
"Max":{"propertyOrder":2,"type":"number"}}},
"dateRange":{"type":"object","properties":{
"From":{"propertyOrder":1,"type":"string","format":"datetime"},
"To":{"propertyOrder":2,"type":"string","format":"datetime"}}}},
"additionalProperties":false}
JSON

my $HOV_LAT_Json_File = "$dir/HOV_LAT.json";
open( FILE, ">", $HOV_LAT_Json_File )
    or die "Unable to opn $HOV_LAT_Json_File";
print FILE $HOV_LAT_Json;
close(FILE);

# Write a minimal giovanni.cfg of sorts
my $cfg = <<'CFG';

$SESSION_LOCATION='OURDIR';
%URL_LOOKUP=(
  'OURDIR' => 'OURDIR'
);
%ENV=(
  TMPDIR  => 'OURDIR',
);
$CACHE_DIR = 'OURDIR';
$SLD_LIST = "OURDIR/sld_list.xml";

$VISUALIZER = {
  # Name of an SLD to be used when no SLD specified for a variable in AESIR
  DEFAULT_SLD => "Blue-Yellow-Red (Div), 12",
  # Items stored in history under (PLOTTYPE, KEY) tuple.
  # Default key name is used when no key is provided.
  DEFAULT_VIS_KEY => "DEFAULTVISKEY",
  # Name of the file to store visualization history into
  HISTORY_FILE_NAME => "history.json",
  # What plot type to visualize with what
  VISUALIZERS => [
    { PLOT_TYPES => [qw(HOV_LAT HOV_LON)], DRIVER =>  'Hovmollers'},
  ]
};

$PLOT_OPTIONS_SCHEMAS_DIR='OURDIR';

CFG
$cfg =~ s/OURDIR/$dir/g;
my $cpt = Safe->new('GIOVANNI');
unless ( $cpt->reval($cfg) ) {
    fail("Unable to setup configuration");
}
$ENV{'TMPDIR'} = $dir;

my $visualizer;
eval {
    $visualizer = Giovanni::Visualizer->new(
        FILE       => [$ncFile],
        PLOT_TYPE  => 'HOV_LAT',
        OUTPUT_DIR => $dir,

        #OPTIONS => '[]',
    );
    $visualizer->visualize();
};

ok( !$@, "Visualizer succeeded" );
my $imageFileHash = $visualizer->getResults();

# Check there is exactly one result
is( scalar( @{$imageFileHash} ), 1, "Got an image file" );

# Check image file exists
my $filePath = ${ ${$imageFileHash}[0]->{image} }[0]->{src};
ok( -f $filePath, "Image file exists" );

__DATA__
netcdf g4.dimensionAveraged.TRMM_3B42_Daily_7_precipitation.20030101-20030105.121W_38N_75W_44N {
dimensions:
	time = UNLIMITED ; // (5 currently)
	lat = 24 ;
	latv = 2 ;
	nv = 2 ;
variables:
	float TRMM_3B42_Daily_7_precipitation(time, lat) ;
		TRMM_3B42_Daily_7_precipitation:_FillValue = -9999.9f ;
		TRMM_3B42_Daily_7_precipitation:fullnamepath = "/precipitation" ;
		TRMM_3B42_Daily_7_precipitation:long_name = "Precipitation Rate" ;
		TRMM_3B42_Daily_7_precipitation:origname = "precipitation" ;
		TRMM_3B42_Daily_7_precipitation:product_short_name = "TRMM_3B42_Daily" ;
		TRMM_3B42_Daily_7_precipitation:product_version = "7" ;
		TRMM_3B42_Daily_7_precipitation:quantity_type = "Precipitation" ;
		TRMM_3B42_Daily_7_precipitation:standard_name = "precipitation" ;
		TRMM_3B42_Daily_7_precipitation:coordinates = "time lat" ;
		TRMM_3B42_Daily_7_precipitation:units = "mm/day" ;
		TRMM_3B42_Daily_7_precipitation:cell_methods = "lon: mean" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	int time(time) ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:Conventions = "CF-1.4" ;
		:start_time = "2003-01-01T01:30:00Z" ;
		:end_time = "2003-01-06T01:29:59Z" ;
		:temporal_resolution = "daily" ;
		:history = "Tue Oct 24 14:01:25 2017: ncks -O -d lat,38.0,44.0 -d lon,-121.0,-75.0 /var/giovanni/session/64957864-B8C3-11E7-8860-2606F8F833F2/A9E7CA7A-B8C3-11E7-ADA1-7411F8F833F2/A9E8C0C4-B8C3-11E7-ADA1-7411F8F833F2///scrubbed.TRMM_3B42_Daily_7_precipitation.20030101.nc scrubbed.TRMM_3B42_Daily_7_precipitation.20030101.nc.subset" ;
		:userstartdate = "2003-01-01T00:00:00Z" ;
		:userenddate = "2003-01-05T23:59:59Z" ;
		:title = "Hovmoller, Longitude-Averaged of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_Daily v7] mm/day over 2003-01-01 01:30Z - 2003-01-06 01:29Z, Region 121W, 38N, 75W, 44N" ;
		:plot_hint_title = "Hovmoller, Longitude-Averaged of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_Daily v7] mm/day" ;
		:plot_hint_subtitle = "over 2003-01-01 01:30Z - 2003-01-06 01:29Z, Region 121W, 38N, 75W, 44N" ;
		:plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-05. Title reflects the date range of the granules that went into making this result." ;
data:

 TRMM_3B42_Daily_7_precipitation =
  6.326307, 7.784344, 8.460957, 7.972625, 7.685039, 8.478533, 8.735179, 
    8.852127, 7.563498, 6.589172, 6.578553, 6.303666, 5.584692, 5.747555, 
    8.102539, 8.686549, 8.672797, 8.493131, 7.72779, 6.007213, 5.040123, 
    4.764264, 5.893976, 5.444699,
  0.5685488, 0.6707523, 0.7399203, 0.592428, 0.7034742, 0.9083103, 0.8627295, 
    0.6258721, 0.7038553, 1.128224, 1.535444, 1.297029, 1.062263, 0.7515129, 
    1.146001, 1.418887, 1.488111, 1.217764, 1.192978, 1.697993, 1.86028, 
    1.445339, 1.479997, 1.738128,
  0.3460828, 0.504874, 0.7494389, 0.8358038, 0.8684511, 1.253209, 1.311317, 
    1.431208, 1.223804, 1.210763, 0.9923226, 0.5357966, 0.496833, 0.3513006, 
    0.1377587, 0.2935423, 0.5116147, 0.6044054, 1.268856, 1.709684, 2.177346, 
    2.244121, 2.303943, 2.07877,
  0.1977544, 0.2169473, 0.4298871, 0.4057207, 0.5277949, 0.815195, 1.121335, 
    1.165571, 0.7923931, 0.9010321, 0.8121107, 0.5491233, 0.5310274, 
    0.5290702, 0.4204357, 0.317032, 0.3094332, 0.4408596, 0.5866959, 
    0.8218652, 0.783545, 0.7253957, 1.176354, 1.161748,
  0.4219824, 0.6976871, 0.7399048, 0.7648973, 0.457005, 0.778415, 0.6182083, 
    0.9216571, 0.8641624, 0.9320704, 0.9202923, 1.151635, 0.8524142, 
    0.7811148, 0.2709362, 0.1194281, 0.2364712, 0.2428777, 0.157924, 
    0.1420953, 0.2481681, 0.113676, 0.113526, 0.2062144 ;

 lat = 38.125, 38.375, 38.625, 38.875, 39.125, 39.375, 39.625, 39.875, 
    40.125, 40.375, 40.625, 40.875, 41.125, 41.375, 41.625, 41.875, 42.125, 
    42.375, 42.625, 42.875, 43.125, 43.375, 43.625, 43.875 ;

 lat_bnds =
  38, 38.25,
  38.25, 38.5,
  38.5, 38.75,
  38.75, 39,
  39, 39.25,
  39.25, 39.5,
  39.5, 39.75,
  39.75, 40,
  40, 40.25,
  40.25, 40.5,
  40.5, 40.75,
  40.75, 41,
  41, 41.25,
  41.25, 41.5,
  41.5, 41.75,
  41.75, 42,
  42, 42.25,
  42.25, 42.5,
  42.5, 42.75,
  42.75, 43,
  43, 43.25,
  43.25, 43.5,
  43.5, 43.75,
  43.75, 44 ;

 time = 1041384600, 1041471000, 1041557400, 1041643800, 1041730200 ;

 time_bnds =
  1041384600, 1041470999,
  1041471000, 1041557399,
  1041557400, 1041643799,
  1041643800, 1041730199,
  1041730200, 1041816599 ;
}


