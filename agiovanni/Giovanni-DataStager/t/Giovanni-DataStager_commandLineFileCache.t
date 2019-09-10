#$Id: Giovanni-DataStager_commandLineFileCache.t,v 1.6 2014/12/23 20:08:02 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-DataStager.t'

#########################

# Tests stageGiovanniData with the file cache.

use Test::More tests => 7;
BEGIN { use_ok('Giovanni::DataStager') }
use File::Temp qw/tempdir/;
use Giovanni::Cache;
use Giovanni::Logger;
use FindBin qw($Bin);

#########################

my $sessionDir = tempdir( CLEANUP => 1 );

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
    = "$sessionDir/mfst.data_search%2BdGSSTFM_3_SET1_INT_ST_mag%2Bt20030301000000_20030331235959.xml";
my $searchUrls = <<'SEARCH';
<?xml version="1.0"?>
<searchList><search id="GSSTFM_3_SET1_INT_ST_mag"><result url="http://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.03.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]" filename="GSSTFM.3.2003.03.01.he5.nc" starttime="" endtime=""/></search></searchList>
SEARCH
open SEARCH, ">$searchUrlsFile";
print SEARCH $searchUrls;
close SEARCH;

# Create a giovanni.cfg with the correct columns. We don't need any
# environment variables set, so leave that blank.
my $cfgStr = <<'CFG';
@CACHE_COLUMNS = ("STARTTIME", "ENDTIME", "TIME", "DATAPERIOD");
%ENV=();
CFG
my $giovanniCfg = "$sessionDir/giovanni.cfg";
open CFG, ">$giovanniCfg";
print CFG $cfgStr;
close CFG;

my $outfilename = "mfst.data_field+dGSSTFM_3_SET1_INT_ST_mag.xml";

# create a directory for the file cache
my $cacheRoot = tempdir( CLEANUP => 1 );

########
# call stageGiovanniData.pl
########

my $script = find_script("stageGiovanniData.pl");
ok( -r $script, "Found script: $script" );

my $cmd
    = "$script --datafield-info-file $dataInfoFile "
    . "--data-url-file $searchUrlsFile "
    . "--output $sessionDir/$outfilename "
    . "--chunk-size 10 --cache-root-path $cacheRoot --no-stderr "
    . "--giovanni-cfg $giovanniCfg";

my @out = `$cmd`;

is( $?, 0,
    "Command returned 0 (and text '" . join( "\n", @out ) . "'): $cmd" )
    or die $!;

# check to make sure the output file exists
ok( -f "$sessionDir/$outfilename", "Output file created" );

# read the manifest file in and see what the output files are
my $doc   = XML::LibXML->load_xml( location => "$sessionDir/$outfilename" );
my @nodes = $doc->findnodes("/manifest/fileList/file");
my @files = map( $_->firstChild()->nodeValue(), @nodes );

is( scalar(@files), 1, "File created." );
for my $file (@files) {
    ok( -f $file, "File exists: $file" );
}

# make sure we put metadata in the cache entry
my $tempOutDir = tempdir( CLEANUP => 1 );
my $cacher = Giovanni::Cache->getCacher(
    TYPE      => "file",
    CACHE_DIR => $cacheRoot,
    COLUMNS   => [ "STARTTIME", "ENDTIME", "TIME", "DATAPERIOD" ]
);
my $key
    = 'file://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3//2003/GSSTFM.3.2003.03.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]#GSSTFM_3_SET1_INT_ST_mag';
my $outHash = $cacher->get(
    DIRECTORY      => $tempOutDir,
    REGION_LEVEL_1 => 'GSSTFM_3_SET1_INT_ST_mag',
    KEYS           => [$key],
);

my $metadata = $outHash->{$key}->{METADATA};
is_deeply(
    $metadata,
    {   TIME       => '1046476800',
        ENDTIME    => '1049155199',
        STARTTIME  => '1046476800',
        DATAPERIOD => '200303'
    },
    "Got the metadata out of the cache"
);

sub find_script {
    my ($scriptName) = @_;

    # see if we can find the script relative to our current location
    $script = "";
    if ( -f "../scripts/$scriptName" ) {

        # Christine's eclipse configuration...
        $script = "../scripts/$scriptName";
    }
    else {
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }
    return $script;
}
