# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ESIP-OpenSearch.t'
#$Id: ESIP-Response_Echo-2.t,v 1.4 2014/12/10 20:05:32 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

#########################

use XML::LibXML;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('ESIP::Response') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $response
    = ESIP::Response->new( sampleFile =>
        "ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2003/001/MOD08_D3.A2003001.051.2010313162627.hdf"
    );
my @data = <DATA>;
my $raw = XML::LibXML->new()->parse_string( join( "", @data ) );
$response->appendResponse($raw);
$response->appendResponse($raw);
$response->appendResponse($raw);

# DATA URLS
my @opendapUrlList
    = $response->getOPeNDAPUrls(); #  there are no opendap URLS under __DATA__
is( @opendapUrlList, 0, "Case of OPeNDAP URL count=0 & data URL count = 2" );
my @dataUrlList = $response->getDataUrls();
is( @dataUrlList, 2, "Case of OPeNDAP URL count=0 & data URL count = 2" );

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/terms/" xmlns:echo="http://www.echo.nasa.gov/esip" xmlns:esipdiscovery="http://commons.esipfed.org/ns/discovery/1.2/" xmlns:georss="http://www.georss.org/georss/10" xmlns:gml="http://www.opengis.net/gml" xmlns:os="http://a9.com/-/spec/opensearch/1.1/" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/" esipdiscovery:version="1.2">
  <updated>2014-11-25T17:53:41.385Z</updated>
  <id>https://api.echo.nasa.gov:443/opensearch/granules.atom</id>
  <author>
    <name>ECHO</name>
    <email>support@echo.nasa.gov</email>
  </author>
  <title type="text">ECHO granule metadata</title>
  <os:totalResults>2</os:totalResults>
  <os:itemsPerPage>400</os:itemsPerPage>
  <os:startPage>1</os:startPage>
  <os:Query xmlns:echo="http://www.echo.nasa.gov/esip" xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/" echo:dataCenter="LAADS" echo:shortName="MOD08_D3" echo:versionId="5.1" geo:box="" geo:geometry="" geo:uid="" role="request"/>

  <subtitle type="text">Search parameters: shortName =&gt; MOD08_D3 versionId =&gt; 5.1 dataCenter =&gt; LAADS boundingBox =&gt;  geometry =&gt;  placeName =&gt;  startTime =&gt; 2003-01-01T00:00:01Z endTime =&gt; 2003-01-02T23:59:59Z uid =&gt; </subtitle>
  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MOD08_D3&amp;versionId=5.1&amp;dataCenter=LAADS&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2003-01-01T00%3A00%3A01Z&amp;endTime=2003-01-02T23%3A59%3A59Z&amp;cursor=1&amp;numberOfResults=400&amp;uid=&amp;clientId=SSW" hreflang="en-US" rel="self" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MOD08_D3&amp;versionId=5.1&amp;dataCenter=LAADS&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2003-01-01T00%3A00%3A01Z&amp;endTime=2003-01-02T23%3A59%3A59Z&amp;numberOfResults=400&amp;uid=&amp;clientId=SSW&amp;cursor=1" hreflang="en-US" rel="last" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MOD08_D3&amp;versionId=5.1&amp;dataCenter=LAADS&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2003-01-01T00%3A00%3A01Z&amp;endTime=2003-01-02T23%3A59%3A59Z&amp;numberOfResults=400&amp;uid=&amp;clientId=SSW&amp;cursor=1" hreflang="en-US" rel="first" type="application/atom+xml"/>

  <link href="https://wiki.earthdata.nasa.gov/display/echo/Open+Search+API+release+information" hreflang="en-US" rel="describedBy" title="Release Notes" type="text/html"/>

  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G192369823-LAADS</id>
    <dc:identifier>G192369823-LAADS</dc:identifier>
    <title type="text">LAADS:676960345</title>
    <updated>2011-12-02T01:52:43.365Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2003001.051.2010313162627.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2003/001/MOD08_D3.A2003001.051.2010313162627.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G192369823-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2003-01-01T00:00:00.000Z/2003-01-02T00:00:00.000Z</dc:date>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G192369820-LAADS</id>
    <dc:identifier>G192369820-LAADS</dc:identifier>
    <title type="text">LAADS:676959828</title>
    <updated>2011-12-02T01:52:43.365Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2003002.051.2010313162127.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2003/002/MOD08_D3.A2003002.051.2010313162127.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G192369820-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2003-01-02T00:00:00.000Z/2003-01-03T00:00:00.000Z</dc:date>
  </entry>
</feed>


