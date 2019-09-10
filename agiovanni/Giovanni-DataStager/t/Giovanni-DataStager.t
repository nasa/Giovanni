#$Id: Giovanni-DataStager.t,v 1.12 2014/12/23 20:08:02 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-DataStager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use Test::More tests => 10;
BEGIN { use_ok('Giovanni::DataStager') }
use File::Temp qw/tempdir/;
use Cwd 'abs_path';
use Giovanni::Cache;
use Giovanni::Logger;
use Giovanni::Data::NcFile;

#########################

my $topDir = tempdir( "test_XXXX", CLEANUP => 1, DIR => $ENV{"TMPDIR"} );

my $sessionDir = "$topDir/session";
mkdir($sessionDir);

# variable we are testing
my $id = "GSSTFM_3_SET1_INT_ST_mag";

# setup data field info and search manifest files

my $dataInfoFile
    = "$sessionDir/mfst.data_field_info+dGSSTFM_3_SET1_INT_ST_mag.xml";
my $dataInfo = <<'DATAINFO';
<varList>
  <var id="GSSTFM_3_SET1_INT_ST_mag" long_name="Wind Stress Magnitude" sampleOpendap="http://measures.gsfc.nasa.gov/opendap/hyrax/GSSTF/GSSTFM.3/1987/GSSTFM.3.1987.07.01.he5.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2008-12-31T23:59:59Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Goddard%20Satellite-Based%20Surface%20Turbulent%20Fluxes%2C%200.25x0.25%20deg%2C%20Monthly%20Grid%2C%20V3%2C%20(GSSTFM)%2C%20at%20GES%20DISC%20V3;agent_id=OPeNDAP;variables=SET1_INT_STu,SET1_INT_STv" startTime="1987-07-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="monthly" dataProductVersion="3" nominalMin="0.0" sampleFile="" east="180.0" dataProductShortName="GSSTFM" osdd="" resolution="0.25 deg." dataProductPlatformInstrument="SSMI" quantity_type="Wind" nominalMax="0.4" dataFieldStandardName="" dataProductEndDateTime="2008-12-31T23:59:59Z" dataFieldUnitsValue="N/m^2" latitudeResolution="0.25" accessName="SET1_INT_STu,SET1_INT_STv" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="0.25" dataProductEndTimeOffset="0" oddxDims="&lt;opt&gt;&#10;  &lt;_LAT_DIMS name=&quot;lat&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;720&quot; /&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;719&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;1439&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LONG_DIMS name=&quot;lon&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;1440&quot; /&gt;&#10;  &lt;_VARIABLE_DIMS&gt;&#10;    &lt;SET1_INT_STu maxind=&quot;719&quot; name=&quot;lat&quot; /&gt;&#10;    &lt;SET1_INT_STu maxind=&quot;1439&quot; name=&quot;lon&quot; /&gt;&#10;    &lt;SET1_INT_STv maxind=&quot;719&quot; name=&quot;lat&quot; /&gt;&#10;    &lt;SET1_INT_STv maxind=&quot;1439&quot; name=&quot;lon&quot; /&gt;&#10;  &lt;/_VARIABLE_DIMS&gt;&#10;&lt;/opt&gt;&#10;" west="-180.0" virtualDataFieldGenerator="GSSTFM_3_SET1_INT_ST_mag=sqrt(SET1_INT_STu*SET1_INT_STu+SET1_INT_STv*SET1_INT_STv)" sdsName="SET1_INT_ST_mag" timeIntvRepPos="start" dataProductBeginDateTime="1987-07-01T00:00:00Z">
    <slds>
      <sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_rd_9_sld.xml" label="Reds (Seq), 9"/>
    </slds>
  </var>
</varList>
DATAINFO
open DATAINFO, ">$dataInfoFile";
print DATAINFO $dataInfo;
close DATAINFO;

my $searchUrlsFile
    = "$sessionDir/mfst.data_search+dGSSTFM_3_SET1_INT_ST_mag+t20030101000000_20030331235959.xml";
my $searchUrls = <<'SEARCH';
<?xml version="1.0"?>
<searchList>
  <search id="GSSTFM_3_SET1_INT_ST_mag">
    <result
      url="http://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.01.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]"
      filename="GSSTFM.3.2003.01.01.he5.nc"
      starttime=""
      endtime=""
    />
    <result
      url="http://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.02.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]"
      filename="GSSTFM.3.2003.02.01.he5.nc"
      starttime=""
      endtime=""
    />
    <result
      url="http://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.03.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]"
      filename="GSSTFM.3.2003.03.01.he5.nc"
      starttime=""
      endtime=""
    />
    <result
      url="http://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.04.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]"
      filename="GSSTFM.3.2003.04.01.he5.nc"
      starttime=""
      endtime=""
    />
  </search>
</searchList>
SEARCH
open SEARCH, ">$searchUrlsFile";
print SEARCH $searchUrls;
close SEARCH;

# create a cache
my $cacheDir = abs_path("$topDir/cache");
mkdir($cacheDir);
my $cacher = Giovanni::Cache->getCacher(
    TYPE      => "file",
    CACHE_DIR => $cacheDir,
    COLUMNS   => [ "STARTTIME", "ENDTIME", "TIME", "DATAPERIOD" ]
);

# create two fake files for the cache

my $tempFilesDir = "$topDir/tempFiles";
mkdir($tempFilesDir);

# NOTE: these keys are derived from the first and third entries in the search

my @filenames = (
    "scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030101.nc",
    "scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030301.nc",
    "scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030401.nc"
);
my @keys = (
    "file://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.01.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]#$id",
    "file://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.03.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]#$id",
    "file://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.04.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]#$id",
);

my $cdls = Giovanni::Data::NcFile::read_cdl_data_block();

for ( my $i = 0; $i < scalar(@filenames); $i++ ) {
    my $filename = $filenames[$i];
    my $cdl      = $cdls->[$i];
    Giovanni::Data::NcFile::write_netcdf_file( "$tempFilesDir/$filename",
        $cdl );
}

# put the files in the cache
$cacher->put(
    DIRECTORY      => $tempFilesDir,
    KEYS           => \@keys,
    FILENAMES      => \@filenames,
    REGION_LEVEL_1 => $id,
    METADATA       => [
        # crazy DATAPERIOD to make sure we're getting the value from the cache
        # and not from the file.
        {   STARTTIME  => '1041379200',
            ENDTIME    => '1044057599',
            TIME       => '1041379200',
            DATAPERIOD => 'FIRST_DATA_PERIOD'
        },
        # no DATAPERIOD for this one to force the code to go with the
        # STARTTIME
        {   STARTTIME => '1046476800',
            ENDTIME   => '1049155199',
            TIME      => '1046476800',
        },
        # give no additional metadata for the last entry so we have a mixed
        # case
        {},
    ],
);

my $outfilename
    = "mfst.data_fetch+dGSSTFM_3_SET1_INT_ST_mag+t20030101000000_20030331235959.xml";

# create a logger
my $logger = Giovanni::Logger->new(
    manifest_filename => $outfilename,
    session_dir       => $sessionDir,
    no_stderr         => 1,
);

my $currDir = abs_path(".");
chdir($sessionDir);

# now call the stager
my $stager = Giovanni::DataStager->new(
    DIRECTORY       => $sessionDir,
    LOGGER          => $logger,
    CACHER          => $cacher,
    CHUNK_SIZE      => 2,
    TIME_OUT        => 10,
    MAX_RETRY_COUNT => 1,
    RETRY_INTERVAL  => 0,
);
$stager->stage(
    URLS_FILE            => $searchUrlsFile,
    DATA_FIELD_INFO_FILE => $dataInfoFile,
    MANIFEST_FILENAME    => $outfilename,
);

chdir($currDir);

# check to make sure the output file exists
ok( -f "$sessionDir/$outfilename", "Output file created" ) or die;

# check to make sure the provenance file exists
my $provFilename = $outfilename;
$provFilename =~ s/mfst/prov/;
ok( -f "$sessionDir/$provFilename", "Provenance file created" ) or die;

# read the manifest file in and see what the output files are
my $doc   = XML::LibXML->load_xml( location => "$sessionDir/$outfilename" );
my @nodes = $doc->findnodes("/manifest/fileList/file");
my @files = map( $_->firstChild()->nodeValue(), @nodes );

is( scalar(@files), 4, "Four files created." );
for my $file (@files) {
    ok( -f $file, "File exists: $file" );
}

# check to make sure that the second file got in the cache
my $anotherDir = "$topDir/another";
mkdir($anotherDir);
my $middleKey
    = "file://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.02.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]#$id";
my $out = $cacher->get(
    DIRECTORY      => $anotherDir,
    REGION_LEVEL_1 => $id,
    KEYS           => [$middleKey],
);

ok( exists( $out->{$middleKey} ), "Second file was scrubbed and cached" );

# make sure the data pairing key is correct. This data pairing value should
# come from the cache for the first and third cases, not from the data file.
@nodes = $doc->findnodes("/manifest/fileList/file/\@datatime");
is_deeply(
    [ map( $_->value(), @nodes ) ],
    [ 'FIRST_DATA_PERIOD', '200302', '1046476800', '200304' ],
    'Got the correct time values for data pairing'
);

__DATA__
netcdf scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030101 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 3 ;
	lon = 3 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float GSSTFM_3_SET1_INT_ST_mag(time, lat, lon) ;
		GSSTFM_3_SET1_INT_ST_mag:_FillValue = -999.f ;
		GSSTFM_3_SET1_INT_ST_mag:fullnamepath = "/HDFEOS/GRIDS/SET1_INT/Data Fields/STu" ;
		GSSTFM_3_SET1_INT_ST_mag:long_name = "Wind Stress Magnitude" ;
		GSSTFM_3_SET1_INT_ST_mag:orig_dimname_list = "XDim " ;
		GSSTFM_3_SET1_INT_ST_mag:origname = "STu" ;
		GSSTFM_3_SET1_INT_ST_mag:units = "N/m^2" ;
		GSSTFM_3_SET1_INT_ST_mag:standard_name = "gsstfm_3_set1_int_st_mag" ;
		GSSTFM_3_SET1_INT_ST_mag:quantity_type = "Wind" ;
		GSSTFM_3_SET1_INT_ST_mag:product_short_name = "GSSTFM" ;
		GSSTFM_3_SET1_INT_ST_mag:product_version = "3" ;
		GSSTFM_3_SET1_INT_ST_mag:coordinates = "time lat lon" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	float lon(lon) ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
		time:long_name = "time" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:nco_openmp_thread_number = 1 ;
		:Conventions = "CF-1.4" ;
		:start_time = "2003-01-01T00:00:00Z" ;
		:end_time = "2003-01-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:history = "Mon Nov 13 22:24:03 2017: ncks -d lat,0,2 -d lon,0,2 scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030101.nc out.nc" ;
data:

 GSSTFM_3_SET1_INT_ST_mag =
  _, _, _,
  _, _, _,
  _, _, _ ;

 datamonth = 200301 ;

 lat = -89.875, -89.625, -89.375 ;

 lat_bnds =
  -90, -89.75,
  -89.75, -89.5,
  -89.5, -89.25 ;

 lon = -179.875, -179.625, -179.375 ;

 lon_bnds =
  -180, -179.75,
  -179.75, -179.5,
  -179.5, -179.25 ;

 time = 1041379200 ;

 time_bnds =
  1041379200, 1044057599 ;
}
netcdf scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030301 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 3 ;
	lon = 3 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float GSSTFM_3_SET1_INT_ST_mag(time, lat, lon) ;
		GSSTFM_3_SET1_INT_ST_mag:_FillValue = -999.f ;
		GSSTFM_3_SET1_INT_ST_mag:fullnamepath = "/HDFEOS/GRIDS/SET1_INT/Data Fields/STu" ;
		GSSTFM_3_SET1_INT_ST_mag:long_name = "Wind Stress Magnitude" ;
		GSSTFM_3_SET1_INT_ST_mag:orig_dimname_list = "XDim " ;
		GSSTFM_3_SET1_INT_ST_mag:origname = "STu" ;
		GSSTFM_3_SET1_INT_ST_mag:units = "N/m^2" ;
		GSSTFM_3_SET1_INT_ST_mag:standard_name = "gsstfm_3_set1_int_st_mag" ;
		GSSTFM_3_SET1_INT_ST_mag:quantity_type = "Wind" ;
		GSSTFM_3_SET1_INT_ST_mag:product_short_name = "GSSTFM" ;
		GSSTFM_3_SET1_INT_ST_mag:product_version = "3" ;
		GSSTFM_3_SET1_INT_ST_mag:coordinates = "time lat lon" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	float lon(lon) ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
		time:long_name = "time" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:nco_openmp_thread_number = 1 ;
		:Conventions = "CF-1.4" ;
		:start_time = "2003-03-01T00:00:00Z" ;
		:end_time = "2003-03-31T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:history = "Mon Nov 13 22:24:52 2017: ncks -d lat,0,2 -d lon,0,2 scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030301.nc out.nc" ;
data:

 GSSTFM_3_SET1_INT_ST_mag =
  _, _, _,
  _, _, _,
  _, _, _ ;

 datamonth = 200303 ;

 lat = -89.875, -89.625, -89.375 ;

 lat_bnds =
  -90, -89.75,
  -89.75, -89.5,
  -89.5, -89.25 ;

 lon = -179.875, -179.625, -179.375 ;

 lon_bnds =
  -180, -179.75,
  -179.75, -179.5,
  -179.5, -179.25 ;

 time = 1046476800 ;

 time_bnds =
  1046476800, 1049155199 ;
}
netcdf scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030401 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 3 ;
	lon = 3 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	float GSSTFM_3_SET1_INT_ST_mag(time, lat, lon) ;
		GSSTFM_3_SET1_INT_ST_mag:_FillValue = -999.f ;
		GSSTFM_3_SET1_INT_ST_mag:fullnamepath = "/HDFEOS/GRIDS/SET1_INT/Data Fields/STu" ;
		GSSTFM_3_SET1_INT_ST_mag:long_name = "Wind Stress Magnitude" ;
		GSSTFM_3_SET1_INT_ST_mag:orig_dimname_list = "XDim " ;
		GSSTFM_3_SET1_INT_ST_mag:origname = "STu" ;
		GSSTFM_3_SET1_INT_ST_mag:units = "N/m^2" ;
		GSSTFM_3_SET1_INT_ST_mag:standard_name = "gsstfm_3_set1_int_st_mag" ;
		GSSTFM_3_SET1_INT_ST_mag:quantity_type = "Wind" ;
		GSSTFM_3_SET1_INT_ST_mag:product_short_name = "GSSTFM" ;
		GSSTFM_3_SET1_INT_ST_mag:product_version = "3" ;
		GSSTFM_3_SET1_INT_ST_mag:coordinates = "time lat lon" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:units = "degrees_north" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	float lon(lon) ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
		time:long_name = "time" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:nco_openmp_thread_number = 1 ;
		:Conventions = "CF-1.4" ;
		:start_time = "2003-04-01T00:00:00Z" ;
		:end_time = "2003-04-30T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:NCO = "\"4.5.3\"" ;
		:history = "Wed Nov 15 20:13:09 2017: ncks -d lat,0,2 -d lon,0,2 scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030401.nc scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030401.nc" ;
data:

 GSSTFM_3_SET1_INT_ST_mag =
  _, _, _,
  _, _, _,
  _, _, _ ;

 datamonth = 200304 ;

 lat = -89.875, -89.625, -89.375 ;

 lat_bnds =
  -90, -89.75,
  -89.75, -89.5,
  -89.5, -89.25 ;

 lon = -179.875, -179.625, -179.375 ;

 lon_bnds =
  -180, -179.75,
  -179.75, -179.5,
  -179.5, -179.25 ;

 time = 1049155200 ;

 time_bnds =
  1049155200, 1051747199 ;
}
