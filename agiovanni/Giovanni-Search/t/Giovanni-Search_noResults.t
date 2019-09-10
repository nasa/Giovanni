# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Search.t'

#########################

# This tests the code to make sure it can handle search URLs that don't return
# any results.

use Test::More tests => 2;
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
  <var id="TRMM_3B42_daily_precipitation_V6" long_name="Precipitation Rate" dataProductTimeFrequency="1" accessFormat="netCDF" north="50.0" accessMethod="HTTP_Services_HDF_TO_NetCDF" endTime="2011-06-29T22:29:59Z" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Daily%20TRMM%20and%20Others%20Rainfall%20Estimate%20(3B42%20V6%20derived)%20V6;agent_id=HTTP_Services_HDF_TO_NetCDF" startTime="1800-12-31T22:30:00Z" responseFormat="netCDF" south="-50.0" dataProductTimeInterval="daily" dataProductVersion="6" east="180.0" dataProductShortName="TRMM_3B42_daily" dataProductPlatformInstrument="TRMM" resolution="0.25 deg." quantity_type="Precipitation" deflationLevel="1" dataFieldStandardName="" dataProductEndDateTime="2011-06-29T22:29:59Z" dataFieldUnitsValue="mm/day" latitudeResolution="0.25" fillValueFieldName="" accumulatable="true" spatialResolutionUnits="deg." longitudeResolution="0.25" dataProductStartTimeOffset="-5400" dataProductEndTimeOffset="-5401" oddxDims="&lt;opt&gt;&#10;  &lt;_LAT_DIMS name=&quot;YDim&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;180&quot; /&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;179&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;359&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LONG_DIMS name=&quot;XDim&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;360&quot; /&gt;&#10;  &lt;_VARIABLE_DIMS&gt;&#10;    &lt;Deep_Blue_Aerosol_Optical_Depth_550_Land_Mean_Mean maxind=&quot;179&quot; name=&quot;YDim&quot; /&gt;&#10;    &lt;Deep_Blue_Aerosol_Optical_Depth_550_Land_Mean_Mean maxind=&quot;359&quot; name=&quot;XDim&quot; /&gt;&#10;  &lt;/_VARIABLE_DIMS&gt;&#10;&lt;/opt&gt;&#10;" west="-180.0" sdsName="precipitation" dataProductBeginDateTime="1800-12-31T22:30:00Z">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/buylrd_div_12_panoply_sld.xml" label="Blue-Yellow-Red (Div), 12 (Source: Panoply)"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/rainfall_sld.xml" label="Green-Blue (Seq), 65"/>
    </slds>
  </var>
</varList>
VARINFO
close(VARFILE) or die("unable to close catalog file $catalogFile");

# do the search
my $search = Giovanni::Search->new(
    session_dir => $tempDir,
    catalog     => $catalogFile,
    out_file    => "mfst.search+dwhatever.xml",
);

# this should die
eval { $search->search( '1900-01-01T00:00:00Z', '1901-01-01T23:59:59Z' ) };
ok( $@, "search died" );

