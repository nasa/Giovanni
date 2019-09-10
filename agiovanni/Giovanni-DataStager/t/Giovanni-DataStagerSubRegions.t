#$Id: Giovanni-DataStagerSubRegions.t,v 1.5 2014/12/23 20:08:02 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-DataStager.t'

#########################

# This test is to make sure that we can successfully do sub-regions and loop over them
# correctly when putting them in the cache.

use Test::More tests => 7;
BEGIN { use_ok('Giovanni::DataStager') }
use File::Temp qw/tempdir/;
use Cwd 'abs_path';
use Giovanni::Cache;
use Giovanni::Logger;

#########################

my $sessionDir = tempdir( CLEANUP => 1 );

# setup data field info and search manifest files

my $dataInfoFile
    = "$sessionDir/mfst.data_field_info+dTRMM_3B42_daily_precipitation_V6.xml";
my $dataInfo = <<'DATAINFO';
<varList>
  <var id="TRMM_3B42_Daily_7_precipitation" long_name="Precipitation Rate" sampleOpendap="http://disc2.gesdisc.eosdis.nasa.gov/opendap/TRMM_L3/TRMM_3B42_Daily.7/1998/01/3B42_Daily.19980101.7.nc4.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="50.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=TRMM%20(TMPA)%20L3%20Daily%2025%20x%2025%20km%20V7%20(TRMM_3B42_Daily)%20at%20GES%20DISC;agent_id=OPeNDAP;variables=precipitation" startTime="1998-01-01T00:00:00Z" responseFormat="netCDF" south="-50.0" dataProductTimeInterval="daily" dataProductVersion="7" sampleFile="http://disc2.gesdisc.eosdis.nasa.gov/data/TRMM_L3/TRMM_3B42_Daily.7/1998/01/3B42_Daily.19980101.7.nc4" east="180.0" dataProductShortName="TRMM_3B42_Daily" osdd="http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_TRMM_3B42_Daily.7.xml" resolution="0.25 deg." dataProductPlatformInstrument="TRMM" quantity_type="Precipitation" dataFieldStandardName="" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="mm/day" latitudeResolution="0.25" accessName="precipitation" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="true" spatialResolutionUnits="deg." longitudeResolution="0.25" dataProductStartTimeOffset="5400" dataProductEndTimeOffset="5399" oddxDims="&lt;opt&gt;&#10;  &lt;_LAT_DIMS name=&quot;lat&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;400&quot; /&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;399&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;1439&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LONG_DIMS name=&quot;lon&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;1440&quot; /&gt;&#10;  &lt;_VARIABLE_DIMS&gt;&#10;    &lt;precipitation maxind=&quot;1439&quot; name=&quot;lon&quot; /&gt;&#10;    &lt;precipitation maxind=&quot;399&quot; name=&quot;lat&quot; /&gt;&#10;  &lt;/_VARIABLE_DIMS&gt;&#10;&lt;/opt&gt;&#10;" west="-180.0" sdsName="precipitation" timeIntvRepPos="start" dataProductBeginDateTime="1998-01-01T00:00:00Z">
    <slds>
      <sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/buylrd_div_12_panoply_sld.xml" label="Blue-Yellow-Red (Div), 12 (Source: Panoply)"/>
      <sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
    </slds>
  </var>
</varList>
DATAINFO
open DATAINFO, ">$dataInfoFile";
print DATAINFO $dataInfo;
close DATAINFO;

my $searchUrlsFile
    = "$sessionDir/mfst.data_search+dTRMM_3B42_Daily_7_precipitation+t20031231000000_20040101235959.xml";
my $searchUrls = <<'SEARCH';
<?xml version="1.0"?>
<searchList><search id="TRMM_3B42_Daily_7_precipitation"><result url="https://disc2.gesdisc.eosdis.nasa.gov/opendap/TRMM_L3/TRMM_3B42_Daily.7/2003/12/3B42_Daily.20031231.7.nc4.nc?precipitation[0:1439][0:399],lat[0:399],lon[0:1439]" filename="3B42_Daily.20031231.7.nc4.nc"/><result url="https://disc2.gesdisc.eosdis.nasa.gov/opendap/TRMM_L3/TRMM_3B42_Daily.7/2004/01/3B42_Daily.20040101.7.nc4.nc?precipitation[0:1439][0:399],lat[0:399],lon[0:1439]" filename="3B42_Daily.20040101.7.nc4.nc"/></search></searchList>
SEARCH
open SEARCH, ">$searchUrlsFile";
print SEARCH $searchUrls;
close SEARCH;

# create a cache
my $cacheDir
    = abs_path( tempdir( "stagercache_XXXX", CLEANUP => 1 ) );
my $cacher
    = Giovanni::Cache->getCacher( TYPE => "file", CACHE_DIR => $cacheDir );

my $outfilename
    = "mfst.data_fetch+dTRMM_3B42_Daily_7_precipitation+t20031231000000_20040101235959.xml";

# create a logger
my $logger = Giovanni::Logger->new(
    manifest_filename => $outfilename,
    session_dir       => $sessionDir,
    no_stderr         => 1,
);

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

# check to make sure the output file exists
ok( -f "$sessionDir/$outfilename", "Output file created" );

# check to make sure the provenance file exists
my $provFilename = $outfilename;
$provFilename =~ s/mfst/prov/;
ok( -f "$sessionDir/$provFilename", "Provenance file created" );

# read the manifest file in and see what the output files are
my $doc   = XML::LibXML->load_xml( location => "$sessionDir/$outfilename" );
my @nodes = $doc->findnodes("/manifest/fileList/file");
my @files = map( $_->firstChild()->nodeValue(), @nodes );

is( scalar(@files), 2, "Two files created." );
for my $file (@files) {
    ok( -f $file, "File exists: $file" );
}

my $region = "TRMM_3B42_Daily_7_precipitation";

# check to make sure we can get out the files
my $anotherDir = tempdir();
my @keys       = (
    "file://disc2.gesdisc.eosdis.nasa.gov/opendap/TRMM_L3/TRMM_3B42_Daily.7/2004/01/3B42_Daily.20040101.7.nc4.nc?precipitation[0:1439][0:399],lat[0:399],lon[0:1439]",
    "file://disc2.gesdisc.eosdis.nasa.gov/opendap/TRMM_L3/TRMM_3B42_Daily.7/2003/12/3B42_Daily.20031231.7.nc4.nc?precipitation[0:1439][0:399],lat[0:399],lon[0:1439]",
);

my $out = $cacher->get(
    DIRECTORY      => $anotherDir,
    REGION_LEVEL_1 => $region,
    KEYS           => \@keys,
);

is( scalar( keys( %{$out} ) ), 2, "Got 2 files" );

