# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ESIP-OpenSearch.t'
#$Id: ESIP-Response_Echo.t,v 1.3 2014/12/10 20:05:32 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

#########################

use XML::LibXML;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('ESIP::Response') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $response = ESIP::Response->new();
my @data     = <DATA>;
my $raw      = XML::LibXML->new()->parse_string( join( "", @data ) );
$response->appendResponse($raw);
$response->appendResponse($raw);
$response->appendResponse($raw);

# DATA URLS
my @dataUrlList = $response->getDataUrls();
is( @dataUrlList, 9, "Data URL count" );

# OPENDAP no test yet:

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/terms/" xmlns:echo="http://www.echo.nasa.gov/esip" xmlns:esipdiscovery="http://commons.esipfed.org/ns/discovery/1.2/" xmlns:georss="http://www.georss.org/georss/10" xmlns:gml="http://www.opengis.net/gml" xmlns:os="http://a9.com/-/spec/opensearch/1.1/" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/" esipdiscovery:version="1.2">
  <updated>2014-11-21T18:22:47.981Z</updated>
  <id>https://api.echo.nasa.gov:443/opensearch/granules.atom</id>
  <author>
    <name>ECHO</name>
    <email>support@echo.nasa.gov</email>
  </author>
  <title type="text">ECHO granule metadata</title>
  <os:totalResults>9</os:totalResults>
  <os:itemsPerPage>400</os:itemsPerPage>
  <os:startPage>1</os:startPage>
  <os:Query xmlns:echo="http://www.echo.nasa.gov/esip" xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/" echo:dataCenter="LAADS" echo:shortName="MOD08_D3" echo:versionId="5.1" geo:box="" geo:geometry="" geo:uid="" role="request"/>

  <subtitle type="text">Search parameters: shortName =&gt; MOD08_D3 versionId =&gt; 5.1 dataCenter =&gt; LAADS boundingBox =&gt;  geometry =&gt;  placeName =&gt;  startTime =&gt; 2005-11-22T00:00:01Z endTime =&gt; 2005-11-30T23:59:59Z uid =&gt; </subtitle>
  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MOD08_D3&amp;versionId=5.1&amp;dataCenter=LAADS&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2005-11-22T00%3A00%3A01Z&amp;endTime=2005-11-30T23%3A59%3A59Z&amp;cursor=1&amp;numberOfResults=400&amp;uid=&amp;clientId=SSW" hreflang="en-US" rel="self" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MOD08_D3&amp;versionId=5.1&amp;dataCenter=LAADS&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2005-11-22T00%3A00%3A01Z&amp;endTime=2005-11-30T23%3A59%3A59Z&amp;numberOfResults=400&amp;uid=&amp;clientId=SSW&amp;cursor=1" hreflang="en-US" rel="last" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MOD08_D3&amp;versionId=5.1&amp;dataCenter=LAADS&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2005-11-22T00%3A00%3A01Z&amp;endTime=2005-11-30T23%3A59%3A59Z&amp;numberOfResults=400&amp;uid=&amp;clientId=SSW&amp;cursor=1" hreflang="en-US" rel="first" type="application/atom+xml"/>

  <link href="https://wiki.earthdata.nasa.gov/display/echo/Open+Search+API+release+information" hreflang="en-US" rel="describedBy" title="Release Notes" type="text/html"/>

  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G191650374-LAADS</id>
    <dc:identifier>G191650374-LAADS</dc:identifier>
    <title type="text">LAADS:672615316</title>
    <updated>2011-11-30T08:12:42.720Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2005326.051.2010302110729.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2005/326/MOD08_D3.A2005326.051.2010302110729.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G191650374-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2005-11-22T00:00:00.000Z/2005-11-23T00:00:00.000Z</dc:date>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G191654851-LAADS</id>
    <dc:identifier>G191654851-LAADS</dc:identifier>
    <title type="text">LAADS:672645499</title>
    <updated>2011-11-30T08:12:52.041Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2005327.051.2010302125751.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2005/327/MOD08_D3.A2005327.051.2010302125751.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G191654851-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2005-11-23T00:00:00.000Z/2005-11-24T00:00:00.000Z</dc:date>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G191652460-LAADS</id>
    <dc:identifier>G191652460-LAADS</dc:identifier>
    <title type="text">LAADS:672629364</title>
    <updated>2011-11-30T08:12:47.880Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2005328.051.2010302115448.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2005/328/MOD08_D3.A2005328.051.2010302115448.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G191652460-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2005-11-24T00:00:00.000Z/2005-11-25T00:00:00.000Z</dc:date>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G191657966-LAADS</id>
    <dc:identifier>G191657966-LAADS</dc:identifier>
    <title type="text">LAADS:672670356</title>
    <updated>2011-11-30T08:12:58.794Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2005329.051.2010302143908.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2005/329/MOD08_D3.A2005329.051.2010302143908.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G191657966-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2005-11-25T00:00:00.000Z/2005-11-26T00:00:00.000Z</dc:date>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G191657968-LAADS</id>
    <dc:identifier>G191657968-LAADS</dc:identifier>
    <title type="text">LAADS:672670357</title>
    <updated>2011-11-30T08:12:58.794Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2005330.051.2010302143900.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2005/330/MOD08_D3.A2005330.051.2010302143900.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G191657968-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2005-11-26T00:00:00.000Z/2005-11-27T00:00:00.000Z</dc:date>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G191511460-LAADS</id>
    <dc:identifier>G191511460-LAADS</dc:identifier>
    <title type="text">LAADS:673866021</title>
    <updated>2011-11-30T08:20:43.794Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2005331.051.2010305161515.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2005/331/MOD08_D3.A2005331.051.2010305161515.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G191511460-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2005-11-27T00:00:00.000Z/2005-11-28T00:00:00.000Z</dc:date>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G191340023-LAADS</id>
    <dc:identifier>G191340023-LAADS</dc:identifier>
    <title type="text">LAADS:672758856</title>
    <updated>2011-11-30T08:13:24.752Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2005332.051.2010302191237.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2005/332/MOD08_D3.A2005332.051.2010302191237.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G191340023-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2005-11-28T00:00:00.000Z/2005-11-29T00:00:00.000Z</dc:date>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G191340024-LAADS</id>
    <dc:identifier>G191340024-LAADS</dc:identifier>
    <title type="text">LAADS:672760614</title>
    <updated>2011-11-30T08:13:24.752Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2005333.051.2010302191502.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2005/333/MOD08_D3.A2005333.051.2010302191502.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G191340024-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2005-11-29T00:00:00.000Z/2005-11-30T00:00:00.000Z</dc:date>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G191340025-LAADS</id>
    <dc:identifier>G191340025-LAADS</dc:identifier>
    <title type="text">LAADS:672760795</title>
    <updated>2011-11-30T08:13:24.752Z</updated>
    <echo:datasetId>MODIS/Terra Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V5.1</echo:datasetId>
    <echo:producerGranuleId>MOD08_D3.A2005334.051.2010302191740.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <georss:box>-90.0 -180.0 90.0 180.0</georss:box>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/51/MOD08_D3/2005/334/MOD08_D3.A2005334.051.2010302191740.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Data Products (ECSCollGuide)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)">
      <echo:inherited/>

    </link>
    <link href="https://api.echo.nasa.gov:443/catalog-rest/echo_catalog/granules/G191340025-LAADS.xml" hreflang="en-US" rel="alternate" title="Product metadata" type="application/xml"/>

    <dc:date>2005-11-30T00:00:00.000Z/2005-12-01T00:00:00.000Z</dc:date>
  </entry>
</feed>

