#$Id: Giovanni-Search_GLDAS_search_bug.t,v 1.2 2015/06/30 17:10:25 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Search.t'

#########################

# TICKET: http://discette-internal.gsfc.nasa.gov/tt/show_bug.cgi?id=28046

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::Search') }

#########################

use File::Temp qw/ tempfile tempdir /;
use File::Basename;
use XML::LibXML;

# create a temporary directory for a session directory
my $tempDir = tempdir( "session_XXXX", CLEANUP => 1 );

# create a catalog file
# This catalog file is all SSW-based URLs.
my $catalogFile = $tempDir . "/" . "catalog.xml";
open( VARFILE, ">$catalogFile" )
    or die("unable to create/open catalog file $catalogFile");

# <varList>
#   <var id="GLDAS_NOAH10_M_020_avgsurft" long_name="Average surface temperature" dataProductTimeFrequency="1" accessFormat="native" north="90.0" accessMethod="OPeNDAP" endTime="2010-12-31T23:59:59Z" url="http://giovanni-test.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=native;dataset_id=GLDAS%20Noah%20Land%20Surface%20Model%20L4%20monthly%201.0%20x%201.0%20degree%20Version%202.0%20V020;agent_id=OPeNDAP;variables=band_12" startTime="1948-01-01T00:00:00Z" responseFormat="DAP" south="-60.0" dataProductTimeInterval="monthly" dataProductVersion="020" sampleFile="" east="180.0" osdd="" dataProductShortName="GLDAS_NOAH10_M" resolution="1 deg." dataProductPlatformInstrument="GLDAS Model" quantity_type="Surface Temperature" dataFieldStandardName="" dataProductEndDateTime="2010-12-31T23:59:59Z" dataFieldUnitsValue="K" latitudeResolution="1.0" accessName="band_12" fillValueFieldName="missing_value" accumulatable="false" spatialResolutionUnits="deg." longitudeResolution="1.0" dataProductStartTimeOffset="1" oddxDims="&lt;opt&gt;&#10;  &lt;_LAT_DIMS name=&quot;lat&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;180&quot; /&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;179&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;359&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LONG_DIMS name=&quot;lon&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;360&quot; /&gt;&#10;  &lt;_VARIABLE_DIMS&gt;&#10;    &lt;RadiativeCloudFraction maxind=&quot;179&quot; name=&quot;lat&quot; /&gt;&#10;    &lt;RadiativeCloudFraction maxind=&quot;359&quot; name=&quot;lon&quot; /&gt;&#10;  &lt;/_VARIABLE_DIMS&gt;&#10;&lt;/opt&gt;&#10;" west="-180.0" sdsName="avgsurft" dataProductBeginDateTime="1948-01-01T00:00:00Z">
#     <slds>
#       <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_rd_9_sld.xml" label="Reds (Seq), 9"/>
#       <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/time_matched_difference_sld.xml" label="Blue-Yellow-Red (Div), 13"/>
#       <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/net_radiation_sld.xml" label="Blue-Yellow-Red (Div), 65"/>
#       <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/burd_div_10_sld.xml" label="Blue-Red (Div), 10"/>
#     </slds>
#   </var>
# </varList>
print VARFILE <<VARINFO;
<varList>
  <var id="GLDAS_NOAH10_M_2_0_AvgSurfT_inst" long_name="Average Surface Skin temperature" sampleOpendap="http://hydro1.sci.gsfc.nasa.gov/opendap/GLDAS/GLDAS_NOAH10_M.2.0/1948/GLDAS_NOAH10_M.A194801.020.nc4.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2012-12-31T23:59:59.999Z" url="http://giovanni-test.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=GLDAS%20Noah%20Land%20Surface%20Model%20L4%20monthly%201.0%20x%201.0%20degree%20V2.0;agent_id=OPeNDAP;variables=AvgSurfT_inst" startTime="1948-01-01T00:00:00Z" responseFormat="netCDF" south="-60.0" dataProductTimeInterval="monthly" dataProductVersion="2.0" sampleFile="http://hydro1.sci.gsfc.nasa.gov/data/s4pa/GLDAS/GLDAS_NOAH10_M.2.0/1948/GLDAS_NOAH10_M.A194801.020.nc4" east="180.0" dataProductShortName="GLDAS_NOAH10_M" osdd="http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_GLDAS_NOAH10_M.2.0.xml" resolution="1 deg." dataProductPlatformInstrument="GLDAS Model" quantity_type="Surface Temperature" dataFieldStandardName="surface_temperature" dataProductEndDateTime="2012-12-31T23:59:59.999Z" dataFieldUnitsValue="K" latitudeResolution="1.0" accessName="AvgSurfT_inst" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." longitudeResolution="1.0" dataProductStartTimeOffset="1" dataProductEndTimeOffset="0" oddxDims="&lt;opt&gt;&#10;  &lt;_LAT_DIMS name=&quot;lat&quot; offset=&quot;0.000000000&quot; scaleFactor=&quot;1.000000000&quot; size=&quot;150&quot; /&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;149&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;359&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LONG_DIMS name=&quot;lon&quot; offset=&quot;0.000000000&quot; scaleFactor=&quot;1.000000000&quot; size=&quot;360&quot; /&gt;&#10;  &lt;_TIME_DIMS&gt;&#10;    &lt;time size=&quot;1&quot; units=&quot; days since 1948-01-01 00:00:00&quot; /&gt;&#10;  &lt;/_TIME_DIMS&gt;&#10;  &lt;_TIME_INDEXES&gt;&#10;    &lt;time&gt;&#10;      &lt;indexes&gt;0&lt;/indexes&gt;&#10;      &lt;indexes&gt;0&lt;/indexes&gt;&#10;    &lt;/time&gt;&#10;  &lt;/_TIME_INDEXES&gt;&#10;  &lt;_VARIABLE_DIMS&gt;&#10;    &lt;AvgSurfT_inst maxind=&quot;0&quot; name=&quot;time&quot; /&gt;&#10;    &lt;AvgSurfT_inst maxind=&quot;149&quot; name=&quot;lat&quot; /&gt;&#10;    &lt;AvgSurfT_inst maxind=&quot;359&quot; name=&quot;lon&quot; /&gt;&#10;  &lt;/_VARIABLE_DIMS&gt;&#10;&lt;/opt&gt;&#10;" west="-180.0" sdsName="AvgSurfT_inst" dataProductBeginDateTime="1948-01-01T00:00:00Z">
    <slds>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/spectral_div_10_inv_sld.xml" label="Spectral, Inverted (Div), 10"/>
    </slds>
  </var>
</varList>
VARINFO
close(VARFILE) or die("unable to close catalog file $catalogFile");

# do the search
#my $outFile = "mfst.data_search+dGLDAS_NOAH10_M_020_avgsurft"
#    . "+t19480101000000_19490131235959.xml";
my $outFile = "mfst.data_search+dGLDAS_NOAH10_M_2_0_AvgSurfT_inst"
    . "+t19480101000000_19490131235959.xml";
my $search = Giovanni::Search->new(
    session_dir => $tempDir,
    catalog     => $catalogFile,
    out_file    => $outFile,
);

my $manifestFile
    = $search->search( ' 1948-01-01T00:00:00Z', '1949-01-31T23:59:59Z' );

# make sure the manifest file was created
ok( -e $manifestFile, "manifest file created" ) or die;

# parse the XML
my $parser = XML::LibXML->new();
my $dom    = $parser->parse_file($manifestFile);
my $xpc    = XML::LibXML::XPathContext->new($dom);

# make sure there are the correct number of results
my @nodes = $xpc->findnodes(qq(searchList/search/result));
is( scalar(@nodes), 13, "Correct number of results" )
