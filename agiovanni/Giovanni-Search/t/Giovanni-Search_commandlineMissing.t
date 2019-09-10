#$Id: Giovanni-Search_commandlineMissing.t,v 1.6 2014/12/15 22:20:48 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# This test checks to make sure that the search checks the missing URL file.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('Giovanni::Search') }

#########################

use File::Temp qw/ tempfile tempdir /;
use File::Basename;
use FindBin qw($Bin);

# create a temporary directory for a session directory
my $tempDir = tempdir( "session_XXXX", CLEANUP => 1 );

# create a catalog file
my $catalogFile = $tempDir . "/" . "catalog.xml";
open( VARFILE, ">$catalogFile" )
    or die("unable to create/open catalog file $catalogFile");
print VARFILE <<VARINFO;
<varList>
  <var id="MOD08_D3_6_1_Deep_Blue_Angstrom_Exponent_Land_Mean" long_name="Deep Blue Angstrom Exponent for land (0.412-0.47 micron): Mean of Daily Mean" searchIntervalDays="365.0" sampleOpendap="https://ladsweb.modaps.eosdis.nasa.gov/opendap/allData/61/MOD08_D3/2000/055/MOD08_D3.A2000055.061.2017276160246.hdf.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="https://giovanni-test.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MODIS%2FTerra%20Aerosol%20Cloud%20Water%20Vapor%20Ozone%20Daily%20L3%20Global%201Deg%20CMG%20V6.1;agent_id=OPeNDAP;variables=Deep_Blue_Angstrom_Exponent_Land_Mean" startTime="2000-02-24T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="daily" dataProductVersion="6.1" nominalMin="0.0" sampleFile="https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/61/MOD08_D3/2000/055/MOD08_D3.A2000055.061.2017276160246.hdf" east="180.0" validMin="-0.5" dataProductShortName="MOD08_D3" osdd="https://cmr.earthdata.nasa.gov/opensearch/granules/descriptor_document.xml?dataCenter=LAADS&amp;shortName=MOD08_D3&amp;versionId=6.1&amp;clientId=giovanni" resolution="1 deg." dataProductPlatformInstrument="MODIS-Terra" quantity_type="Angstrom Exponent" nominalMax="1.0" dataFieldStandardName="Angstrom Exponent" dataProductEndDateTime="2038-01-19T03:14:07Z" searchFilter="https:\/\/ladsweb\.modaps\.eosdis\.nasa\.gov\/archive\/allData\/61\/MOD08_D3" dataFieldUnitsValue="" latitudeResolution="1.0" accessName="Deep_Blue_Angstrom_Exponent_Land_Mean" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="1.0" validMax="5.0" dataProductEndTimeOffset="0" oddxDims="&lt;opt&gt;&#10;  &lt;_LAT_DIMS name=&quot;YDim&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;180&quot; /&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;179&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;359&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LONG_DIMS name=&quot;XDim&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;360&quot; /&gt;&#10;  &lt;_VARIABLE_DIMS&gt;&#10;    &lt;Deep_Blue_Angstrom_Exponent_Land_Mean maxind=&quot;179&quot; name=&quot;YDim&quot; /&gt;&#10;    &lt;Deep_Blue_Angstrom_Exponent_Land_Mean maxind=&quot;359&quot; name=&quot;XDim&quot; /&gt;&#10;  &lt;/_VARIABLE_DIMS&gt;&#10;&lt;/opt&gt;&#10;" west="-180.0" sdsName="Deep_Blue_Angstrom_Exponent_Land_Mean" timeIntvRepPos="start" dataProductBeginDateTime="2000-02-24T00:00:00Z">
    <slds>
      <sld url="https://dev.gesdisc.eosdis.nasa.gov/giovanni/sld/land_surface_temp_sld.xml" label="Cyan-Red-Yellow (Seq), 65"/>
      <sld url="https://dev.gesdisc.eosdis.nasa.gov/giovanni/sld/co_sld.xml" label="Yellow-Orange-Red (Seq), 65"/>
    </slds>
  </var>
</varList>
VARINFO
close(VARFILE) or die("unable to close catalog file $catalogFile");

# create a missing url file
my $missingFile = $tempDir . "/missing.txt";
open( MISSINGFILE, ">$missingFile" );
print MISSINGFILE
    "https://ladsweb.modaps.eosdis.nasa.gov:443/opendap/allData/61/MOD08_D3/2003/001/MOD08_D3.A2003001.061.2017281195411.hdf.nc?Deep_Blue_Angstrom_Exponent_Land_Mean[0:179][0:359],XDim[0:359],YDim[0:179]\n";
close(MISSINGFILE);

my $script = find_script("search.pl");
ok( -r $script, "Found script" );

my $manifestFile = $tempDir
    . "/mfst.search+dMOD08_D3_6_Angstrom_Exponent_1_Ocean_QA_Mean" .
    "+dMOD08_D3_6_Optical_Depth_Land_And_Ocean_Mean+t20030101000000_20030102235959.xml";

my $cmd
    = qq(perl $script --catalog $catalogFile )
    . qq(--outFile $manifestFile )
    . qq(--missingUrl $missingFile )
    . qq(--stime '2003-01-01' )
    . qq(--etime '2003-01-02' );

`$cmd`;

is( $?, 0, "returned 0" );

# make sure the manifest file was created
ok( -e $manifestFile, "manifest file created" );

# read in the log file and make sure there is only one result
# parse the XML
my $parser = XML::LibXML->new();
my $dom    = $parser->parse_file($manifestFile);
my $xpc    = XML::LibXML::XPathContext->new($dom);

# first variable results
my @nodes
    = $xpc->findnodes(
    qq(searchList/search[\@id="MOD08_D3_6_1_Deep_Blue_Angstrom_Exponent_Land_Mean"]/result/\@url)
    );
is( 1, scalar(@nodes), 'one result' );
is( $nodes[0]->value(),
    "https://ladsweb.modaps.eosdis.nasa.gov:443/opendap/allData/61/MOD08_D3/2003/002/MOD08_D3.A2003002.061.2017281200142.hdf.nc?Deep_Blue_Angstrom_Exponent_Land_Mean[0:179][0:359],XDim[0:359],YDim[0:179]",
    "correct result"
);

# make sure the log file was created
my $logFile
    = $tempDir . "/"
    . "mfst.search+dMOD08_D3_6_Angstrom_Exponent_1_Ocean_QA_Mean+dMOD08_D3_6_Optical_Depth_Land_And_Ocean_Mean+t20030101000000_20030102235959.log";
ok( -e $logFile, "log file created" );

sub find_script {
    my ($scriptName) = @_;

    # see if we can find the script relative to our current location
    my $script = "blib/script/$scriptName";
    foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
        next if ( $dir =~ /^\s*$/ );
        last if ( -f $script );
        $script = "../$script";
    }

    unless ( -f $script ) {

        # see if this is just next door (Christine's eclipse configuration)
        $script = "../scripts/$scriptName";
    }

    return $script;
}
