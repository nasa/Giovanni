#$Id: Giovanni-Search_Climatology.t,v 1.1 2014/12/11 15:36:31 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Search.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::Search') }

#########################

use File::Temp qw/ tempfile tempdir /;
use File::Basename;
use XML::LibXML;

# create a temporary directory for a session directory
my $tempDir = tempdir( "session_XXXX", CLEANUP => 1 );

# create a catalog file
my $catalogFile = $tempDir . "/" . "catalog.xml";
open( VARFILE, ">$catalogFile" )
    or die("unable to create/open catalog file $catalogFile");
print VARFILE <<VARINFO;
<varList>
  <var id="SWDB_L3MC10_004_aerosol_optical_thickness_550_land_ocean" long_name="Climatology of Aerosol Optical Depth 550 nm" sampleOpendap="http://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2010-12-31T23:59:59.999Z" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=SeaWiFS%20Deep%20Blue%20Aerosol%20Optical%20Thickness%20Monthly%20Level%203%20Climatology%20Data%20Gridded%20at%201.0%20Degrees%20V004;agent_id=OPeNDAP;variables=aerosol_optical_thickness_550_land_ocean" startTime="1997-09-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="monthly" dataProductVersion="004" nominalMin="0.0" sampleFile="ftp://measures.gsfc.nasa.gov/data/s4pa/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5" east="180.0" dataProductShortName="SWDB_L3MC10" osdd="http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_SWDB_L3MC10.004.xml" resolution="1 deg." dataProductPlatformInstrument="SeaWiFS" quantity_type="Total Aerosol Optical Depth" nominalMax="1.0" dataFieldStandardName="atmosphere_optical_thickness_due_to_ambient_aerosol" dataProductEndDateTime="2010-12-31T23:59:59.999Z" dataFieldUnitsValue="1" latitudeResolution="1.0" accessName="aerosol_optical_thickness_550_land_ocean" fillValueFieldName="_FillValue" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="1.0" dataProductEndTimeOffset="0" oddxDims="&lt;opt&gt;&#10;  &lt;_LAT_DIMS name=&quot;latitude&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;180&quot; /&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;179&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;359&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LONG_DIMS name=&quot;longitude&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;360&quot; /&gt;&#10;  &lt;_VARIABLE_DIMS&gt;&#10;    &lt;aerosol_optical_thickness_550_land_ocean maxind=&quot;179&quot; name=&quot;latitude&quot; /&gt;&#10;    &lt;aerosol_optical_thickness_550_land_ocean maxind=&quot;359&quot; name=&quot;longitude&quot; /&gt;&#10;  &lt;/_VARIABLE_DIMS&gt;&#10;&lt;/opt&gt;&#10;" west="-180.0" sdsName="aerosol_optical_thickness_550_land_ocean" climatology="true" dataProductBeginDateTime="1997-09-01T00:00:00Z">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/no2_sld.xml" label="Yellow-Orange-Brown (Seq), 65"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/buylrd_div_12_panoply_sld.xml" label="Blue-Yellow-Red (Div), 12 (Source: Panoply)"/>
    </slds>
  </var>
</varList>
VARINFO
close(VARFILE) or die("unable to close catalog file $catalogFile");

my $outFile
    = "mfst.data_search+dSWDB_L3MC10_004_aerosol_optical_thickness_550_land_ocean+t19970901000000_19970930235959.xml";

# do the search
my $search = Giovanni::Search->new(
    session_dir => $tempDir,
    catalog     => $catalogFile,
    out_file    => $outFile,
);

my $manifestFile
    = $search->search( '1997-09-01T00:00:01Z', '1997-09-30T23:59:59Z' );

# make sure the manifest file was created
ok( -e $manifestFile, "manifest file created" );

# make sure it has the right name
my ($name) = fileparse($manifestFile);
is( $name, $outFile, "manifest files has the correct name" );

# parse the XML
my $parser = XML::LibXML->new();
my $dom    = $parser->parse_file($manifestFile);
my $xpc    = XML::LibXML::XPathContext->new($dom);

# first variable results
my @nodes
    = $xpc->findnodes(
    qq(searchList/search[\@id="SWDB_L3MC10_004_aerosol_optical_thickness_550_land_ocean"]/result)
    );
my @urls      = map { $_->getAttribute("url"); } @nodes;
my @filenames = map { $_->getAttribute("filename"); } @nodes;

#is_deeply(
#    \@urls,
#    [   "http://ladsweb.nascom.nasa.gov/opendap/allData/51/MOD08_D3/2003/001/MOD08_D3.A2003001.051.2010313162627.hdf.nc?Angstrom_Exponent_1_Ocean_QA_Mean[0:179][0:359],XDim[0:359],YDim[0:179]",
#        "http://ladsweb.nascom.nasa.gov/opendap/allData/51/MOD08_D3/2003/002/MOD08_D3.A2003002.051.2010313162127.hdf.nc?Angstrom_Exponent_1_Ocean_QA_Mean[0:179][0:359],XDim[0:359],YDim[0:179]",
#
#    ],
#    "correct URLs"
#);
#is_deeply(
#    \@filenames,
#    [   "MOD08_D3.A2003001.051.2010313162627.hdf.nc",
#        "MOD08_D3.A2003002.051.2010313162127.hdf.nc",
#    ],
#    "correct filenames"
#);
