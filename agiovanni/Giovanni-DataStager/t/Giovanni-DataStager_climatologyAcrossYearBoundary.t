#$Id: Giovanni-DataStager_climatologyAcrossYearBoundary.t,v 1.1 2014/12/23 21:25:26 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-DataStager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('Giovanni::DataStager') }
use File::Temp qw/tempdir/;
use Cwd 'abs_path';
use Giovanni::Cache;
use Giovanni::Logger;
use File::Basename;

#########################

my $sessionDir = tempdir( "session_XXXX", CLEANUP => 1 );

# setup data field info and search manifest files

my $dataInfoFile
    = "$sessionDir/mfst.data_field_info+dSWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.xml";
my $dataInfo = <<'DATAINFO';
<varList>
  <var id="SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean" long_name="Climatology (1997-2010) of Aerosol Optical Depth 550 nm" sampleOpendap="http://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199709-201009_v004-20130624T144105Z.h5.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2010-12-31T23:59:59.999Z" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=SeaWiFS%20Deep%20Blue%20Aerosol%20Optical%20Thickness%20Monthly%20Level%203%20Climatology%20Data%20Gridded%20at%200.5%20Degrees%20V004;agent_id=OPeNDAP;variables=aerosol_optical_thickness_550_land_ocean" startTime="1997-09-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="monthly" dataProductVersion="004" nominalMin="0.0" sampleFile="ftp://measures.gsfc.nasa.gov/data/s4pa/DeepBlueSeaWiFS_Level3/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199709-201009_v004-20130624T144105Z.h5" east="180.0" dataProductShortName="SWDB_L3MC05" osdd="http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_SWDB_L3MC05.004.xml" resolution="0.5 deg." dataProductPlatformInstrument="SeaWiFS" quantity_type="Total Aerosol Optical Depth" nominalMax="1.0" dataFieldStandardName="atmosphere_optical_thickness_due_to_ambient_aerosol" dataProductEndDateTime="2010-12-31T23:59:59.999Z" dataFieldUnitsValue="1" latitudeResolution="0.5" accessName="aerosol_optical_thickness_550_land_ocean" fillValueFieldName="_FillValue" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="0.5" dataProductEndTimeOffset="0" west="-180.0" sdsName="aerosol_optical_thickness_550_land_ocean" climatology="true" dataProductBeginDateTime="1997-09-01T00:00:00Z">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/no2_sld.xml" label="Yellow-Orange-Brown (Seq), 65"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/buylrd_div_12_panoply_sld.xml" label="Blue-Yellow-Red (Div), 12 (Source: Panoply)"/>
    </slds>
  </var>
</varList>
DATAINFO
open DATAINFO, ">$dataInfoFile";
print DATAINFO $dataInfo;
close DATAINFO;

my $searchUrlsFile
    = "$sessionDir/mfst.data_search+dSWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean+t20001201000000_20030331235959.xml";
my $searchUrls = <<'SEARCH';
<?xml version="1.0" encoding="UTF-8"?>
<searchList>
  <search id="SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean">
    <result url="http://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199803-201003_v004-20130624T144009Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]" filename="DeepBlue-SeaWiFS-0.5_L3MC_199803-201003_v004-20130624T144009Z.h5.nc" />
    <result url="http://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199801-201001_v004-20130624T143951Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]" filename="DeepBlue-SeaWiFS-0.5_L3MC_199801-201001_v004-20130624T143951Z.h5.nc" />
    <result url="http://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199802-201002_v004-20130624T144000Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]" filename="DeepBlue-SeaWiFS-0.5_L3MC_199802-201002_v004-20130624T144000Z.h5.nc" />
    <result url="http://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199712-201012_v004-20130624T144135Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]" filename="DeepBlue-SeaWiFS-0.5_L3MC_199712-201012_v004-20130624T144135Z.h5.nc" />
  </search>
</searchList>
SEARCH
open SEARCH, ">$searchUrlsFile";
print SEARCH $searchUrls;
close SEARCH;

# create a cache
my $cacheDirectory
    = abs_path( tempdir( "stagercache_XXXX", CLEANUP => 1 ) );
my $cacher = Giovanni::Cache->getCacher(
    TYPE      => "file",
    CACHE_DIR => $cacheDirectory
);

# create two fake files for the cache
my $tempDir = tempdir( "files4cache_XXXX", CLEANUP => 1 );

# NOTE: put all search entries in the cache. We're not testing downloading and
# scrubbing.

my @keys = (
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199709-201009_v004-20130624T144105Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199710-201010_v004-20130624T144115Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199711-201011_v004-20130624T144125Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199712-201012_v004-20130624T144135Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199801-201001_v004-20130624T143951Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199802-201002_v004-20130624T144000Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199803-201003_v004-20130624T144009Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199804-201004_v004-20130624T144018Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199805-201005_v004-20130624T144027Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199806-201006_v004-20130624T144036Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199807-201007_v004-20130624T144045Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
    "file://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC05.004/DeepBlue-SeaWiFS-0.5_L3MC_199808-201008_v004-20130624T144055Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:359][0:719],longitude[0:719],latitude[0:359]",
);
my @filenames = (
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19970901.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19971001.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19971101.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19971201.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980101.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980201.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980301.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980401.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980501.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980601.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980701.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980801.nc',
);

for ( my $i = 0; $i < scalar(@keys); $i++ ) {
    my $filename = $filenames[$i];
    my $key      = $keys[$i];

    open DATA, ">$tempDir/$filename";
    print DATA $key;
    close(DATA);
}

my $region = "SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean";

# put the files in the cache
$cacher->put(
    DIRECTORY      => $tempDir,
    KEYS           => \@keys,
    FILENAMES      => \@filenames,
    REGION_LEVEL_1 => $region
);

my $outfilename
    = "mfst.data_fetch+dSWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean+t20000101000000_20031231235959.xml";

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
my @correctFilenames = (
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19971201.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980101.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980201.nc',
    'scrubbed.SWDB_L3MC05_004_aerosol_optical_thickness_550_land_ocean.19980301.nc',
);
for ( my $i = 0; $i < scalar(@files); $i++ ) {
    ok( -f $files[$i], "File exists: $files[$i]" );
    is( basename( $files[$i] ),
        $correctFilenames[$i], "Correct filename: " . $correctFilenames[$i] );
}

