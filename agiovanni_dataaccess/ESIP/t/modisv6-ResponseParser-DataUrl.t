#!/usr/bin/perl

use XML::LibXML;

#use ESIP::Response::V1_2;
use Test::More tests => 16;

BEGIN {
    use_ok('ESIP::ResponseParser::V1_2');    # PODAAC is now in CMR
    use_ok('ESIP::ResponseParser::EsipParser');
    use_ok('Giovanni::Search::OPeNDAP');
}
use strict;

my $atomNS = 'http://www.w3.org/2005/Atom';
my $osNS   = 'http://a9.com/-/spec/opensearch/1.1/';
my $esipNS = 'http://esipfed.org/ns/fedsearch/1.0/';
my $xml;

if ( $#ARGV > -1 ) {
    if ( open( FILE, $ARGV[0] ) ) {
        while (<FILE>) {
            $xml .= $_;
        }
        close FILE;
    }
}
else {
    while (<DATA>) {
        $xml .= $_;
    }
}

my $dom = getDocument($xml);
my $doc = $dom->documentElement();

my $author = ESIP::ResponseParser::EsipParser::getAuthor($doc);
ok( $author eq "CMR" );

my $package = ESIP::ResponseParser::V1_2->new(
    XML  => $dom,
    TYPE => "application/x-hdf",
    sampleFile =>
        "ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2002/185/MYD08_D3.A2002185.006.2015084200552.hdf",
    sampleOpendap =>
        "http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2002/185/MYD08_D3.A2002185.006.2015084200552.hdf.html"

);

my @results;
my $translator = DataAccess::Translator->new(
    SOURCE_URL => $package->{sampleFile},
    TARGET_URL => $package->{sampleOpendap}
);

my @tmp = $package->getDataUrls;
my @res;
push @res, @{ $tmp[0] };
my @dataUrls = map( $_->{url}, @res );
my @opendapUrls = $translator->translate(@dataUrls);

for my $i ( 0 .. scalar @opendapUrls - 1 ) {
    push(
        @results,
        {   'url'       => $opendapUrls[$i],
            'startTime' => $res[$i]->{startTime},
            'endTime'   => $res[$i]->{endTime}
        }
    );
}

ok( scalar @results == 11, "number of urls:" . scalar @results );

my @test = (
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/152/MYD08_D3.A2005152.006.2015086141725.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/153/MYD08_D3.A2005153.006.2015086141807.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/154/MYD08_D3.A2005154.006.2015086141832.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/155/MYD08_D3.A2005155.006.2015086141854.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/156/MYD08_D3.A2005156.006.2015086142152.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/157/MYD08_D3.A2005157.006.2015086142044.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/158/MYD08_D3.A2005158.006.2015086142031.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/159/MYD08_D3.A2005159.006.2015086145611.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/160/MYD08_D3.A2005160.006.2015086145954.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/161/MYD08_D3.A2005161.006.2015086144634.hdf.html',
    'http://ladsweb.nascom.nasa.gov/opendap/allData/6/MYD08_D3/2005/162/MYD08_D3.A2005162.006.2015086142147.hdf.html'
);

for ( my $i = 0; $i <= $#results; ++$i ) {
    ok( $test[$i] eq $results[$i]->{url}, 'translated url comparison' );
}

sub getDocument {
    my $xml = shift;

    my $dsDom;
    my $parser = XML::LibXML->new();
    eval { $dsDom = $parser->parse_string($xml) };
    if ($@) {
        ERROR( ( caller(0) )[3], " $@" );
    }

    return $dsDom;
}

sub ERROR {
    print @_;
}

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<feed esipdiscovery:version="1.2" xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/terms/" xmlns:echo="http://www.echo.nasa.gov/esip" xmlns:esipdiscovery="http://commons.esipfed.org/ns/discovery/1.2/" xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml" xmlns:os="http://a9.com/-/spec/opensearch/1.1/" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/">
  <updated>2015-12-02T14:02:19.882Z</updated>
  <id>https://api.echo.nasa.gov:443/opensearch/granules.atom</id>
  <author>
    <name>CMR</name>
    <email>support@echo.nasa.gov</email>
  </author>
  <title type="text">ECHO granule metadata</title>
  <subtitle type="text">Search parameters: shortName =&gt; MYD08_D3 versionId =&gt; 6 dataCenter =&gt; LAADS boundingBox =&gt;  geometry =&gt;  placeName =&gt;  startTime =&gt; 2005-06-01T00:00:01Z endTime =&gt; 2005-06-11T23:59:59Z uid =&gt; </subtitle>
  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MYD08_D3&amp;versionId=6&amp;dataCenter=LAADS&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2005-06-01T00%3A00%3A01Z&amp;endTime=2005-06-11T23%3A59%3A59Z&amp;numberOfResults=1024&amp;uid=&amp;clientId=SSW&amp;cursor=1" hreflang="en-US" rel="self" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MYD08_D3&amp;versionId=6&amp;dataCenter=LAADS&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2005-06-01T00%3A00%3A01Z&amp;endTime=2005-06-11T23%3A59%3A59Z&amp;numberOfResults=1024&amp;uid=&amp;clientId=SSW&amp;cursor=1" hreflang="en-US" rel="last" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MYD08_D3&amp;versionId=6&amp;dataCenter=LAADS&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2005-06-01T00%3A00%3A01Z&amp;endTime=2005-06-11T23%3A59%3A59Z&amp;numberOfResults=1024&amp;uid=&amp;clientId=SSW&amp;cursor=1" hreflang="en-US" rel="first" type="application/atom+xml"/>

  <link href="https://wiki.earthdata.nasa.gov/display/echo/Open+Search+API+release+information" hreflang="en-US" rel="describedBy" title="Release Notes" type="text/html"/>

  <os:Query echo:dataCenter="LAADS" echo:shortName="MYD08_D3" echo:versionId="6" geo:box="" geo:geometry="" geo:uid="" role="request" time:end="2005-06-11T23:59:59Z" time:start="2005-06-01T00:00:01Z" xmlns:echo="http://www.echo.nasa.gov/esip" xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/"/>

  <os:totalResults>11</os:totalResults>
  <os:itemsPerPage>1024</os:itemsPerPage>
  <os:startIndex>1</os:startIndex>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005258-LAADS</id>
    <title type="text">LAADS:1435327604</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/152/MYD08_D3.A2005152.006.2015086141725.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWSW_D3/2005/152/MYBWSW_D3.A2005152.006.2015086141730.jpg" hreflang="en-US" length="327957" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWIR_D3/2005/152/MYBWIR_D3.A2005152.006.2015086141729.jpg" hreflang="en-US" length="431116" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTT_D3/2005/152/MYBCTT_D3.A2005152.006.2015086141733.jpg" hreflang="en-US" length="475341" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTP_D3/2005/152/MYBCTP_D3.A2005152.006.2015086141732.jpg" hreflang="en-US" length="532473" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCOT_D3/2005/152/MYBCOT_D3.A2005152.006.2015086141732.jpg" hreflang="en-US" length="476813" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCIR_D3/2005/152/MYBCIR_D3.A2005152.006.2015086141731.jpg" hreflang="en-US" length="422851" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCFR_D3/2005/152/MYBCFR_D3.A2005152.006.2015086141733.jpg" hreflang="en-US" length="569841" rel="icon" type="image/jpeg"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005258-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005258-LAADS</dc:identifier>
    <dc:date>2005-06-01T00:00:00.000Z/2005-06-02T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005152.006.2015086141725.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005549-LAADS</id>
    <title type="text">LAADS:1435374060</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/153/MYD08_D3.A2005153.006.2015086141807.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTP_D3/2005/153/MYBCTP_D3.A2005153.006.2015086141819.jpg" hreflang="en-US" length="532915" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCFR_D3/2005/153/MYBCFR_D3.A2005153.006.2015086141820.jpg" hreflang="en-US" length="570179" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCOT_D3/2005/153/MYBCOT_D3.A2005153.006.2015086141819.jpg" hreflang="en-US" length="470867" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWSW_D3/2005/153/MYBWSW_D3.A2005153.006.2015086141818.jpg" hreflang="en-US" length="331238" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTT_D3/2005/153/MYBCTT_D3.A2005153.006.2015086141820.jpg" hreflang="en-US" length="475080" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCIR_D3/2005/153/MYBCIR_D3.A2005153.006.2015086141818.jpg" hreflang="en-US" length="422421" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWIR_D3/2005/153/MYBWIR_D3.A2005153.006.2015086141815.jpg" hreflang="en-US" length="429320" rel="icon" type="image/jpeg"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005549-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005549-LAADS</dc:identifier>
    <dc:date>2005-06-02T00:00:00.000Z/2005-06-03T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005153.006.2015086141807.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005450-LAADS</id>
    <title type="text">LAADS:1435346500</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/154/MYD08_D3.A2005154.006.2015086141832.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCIR_D3/2005/154/MYBCIR_D3.A2005154.006.2015086141837.jpg" hreflang="en-US" length="423363" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWSW_D3/2005/154/MYBWSW_D3.A2005154.006.2015086141837.jpg" hreflang="en-US" length="330362" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCFR_D3/2005/154/MYBCFR_D3.A2005154.006.2015086141840.jpg" hreflang="en-US" length="568902" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWIR_D3/2005/154/MYBWIR_D3.A2005154.006.2015086141836.jpg" hreflang="en-US" length="423757" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCOT_D3/2005/154/MYBCOT_D3.A2005154.006.2015086141838.jpg" hreflang="en-US" length="478642" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTT_D3/2005/154/MYBCTT_D3.A2005154.006.2015086141839.jpg" hreflang="en-US" length="481735" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTP_D3/2005/154/MYBCTP_D3.A2005154.006.2015086141838.jpg" hreflang="en-US" length="538957" rel="icon" type="image/jpeg"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005450-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005450-LAADS</dc:identifier>
    <dc:date>2005-06-03T00:00:00.000Z/2005-06-04T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005154.006.2015086141832.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005811-LAADS</id>
    <title type="text">LAADS:1435409836</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/155/MYD08_D3.A2005155.006.2015086141854.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005811-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005811-LAADS</dc:identifier>
    <dc:date>2005-06-04T00:00:00.000Z/2005-06-05T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005155.006.2015086141854.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005567-LAADS</id>
    <title type="text">LAADS:1435376335</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/156/MYD08_D3.A2005156.006.2015086142152.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005567-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005567-LAADS</dc:identifier>
    <dc:date>2005-06-05T00:00:00.000Z/2005-06-06T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005156.006.2015086142152.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005621-LAADS</id>
    <title type="text">LAADS:1435383697</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/157/MYD08_D3.A2005157.006.2015086142044.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCOT_D3/2005/157/MYBCOT_D3.A2005157.006.2015086142106.jpg" hreflang="en-US" length="478712" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWSW_D3/2005/157/MYBWSW_D3.A2005157.006.2015086142105.jpg" hreflang="en-US" length="326331" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCIR_D3/2005/157/MYBCIR_D3.A2005157.006.2015086142106.jpg" hreflang="en-US" length="424351" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTP_D3/2005/157/MYBCTP_D3.A2005157.006.2015086142107.jpg" hreflang="en-US" length="537231" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWIR_D3/2005/157/MYBWIR_D3.A2005157.006.2015086142052.jpg" hreflang="en-US" length="430708" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCFR_D3/2005/157/MYBCFR_D3.A2005157.006.2015086142112.jpg" hreflang="en-US" length="576397" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTT_D3/2005/157/MYBCTT_D3.A2005157.006.2015086142109.jpg" hreflang="en-US" length="479957" rel="icon" type="image/jpeg"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005621-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005621-LAADS</dc:identifier>
    <dc:date>2005-06-06T00:00:00.000Z/2005-06-07T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005157.006.2015086142044.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005564-LAADS</id>
    <title type="text">LAADS:1435376164</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/158/MYD08_D3.A2005158.006.2015086142031.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTP_D3/2005/158/MYBCTP_D3.A2005158.006.2015086142040.jpg" hreflang="en-US" length="536198" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWIR_D3/2005/158/MYBWIR_D3.A2005158.006.2015086142038.jpg" hreflang="en-US" length="434799" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTT_D3/2005/158/MYBCTT_D3.A2005158.006.2015086142041.jpg" hreflang="en-US" length="479237" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCFR_D3/2005/158/MYBCFR_D3.A2005158.006.2015086142042.jpg" hreflang="en-US" length="578376" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCOT_D3/2005/158/MYBCOT_D3.A2005158.006.2015086142040.jpg" hreflang="en-US" length="473334" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCIR_D3/2005/158/MYBCIR_D3.A2005158.006.2015086142039.jpg" hreflang="en-US" length="419381" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWSW_D3/2005/158/MYBWSW_D3.A2005158.006.2015086142039.jpg" hreflang="en-US" length="329617" rel="icon" type="image/jpeg"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005564-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005564-LAADS</dc:identifier>
    <dc:date>2005-06-07T00:00:00.000Z/2005-06-08T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005158.006.2015086142031.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005613-LAADS</id>
    <title type="text">LAADS:1435380803</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/159/MYD08_D3.A2005159.006.2015086145611.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCFR_D3/2005/159/MYBCFR_D3.A2005159.006.2015086145620.jpg" hreflang="en-US" length="576419" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCOT_D3/2005/159/MYBCOT_D3.A2005159.006.2015086145618.jpg" hreflang="en-US" length="476232" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCIR_D3/2005/159/MYBCIR_D3.A2005159.006.2015086145617.jpg" hreflang="en-US" length="418095" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTT_D3/2005/159/MYBCTT_D3.A2005159.006.2015086145619.jpg" hreflang="en-US" length="477181" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTP_D3/2005/159/MYBCTP_D3.A2005159.006.2015086145618.jpg" hreflang="en-US" length="534432" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWSW_D3/2005/159/MYBWSW_D3.A2005159.006.2015086145616.jpg" hreflang="en-US" length="330839" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWIR_D3/2005/159/MYBWIR_D3.A2005159.006.2015086145615.jpg" hreflang="en-US" length="431182" rel="icon" type="image/jpeg"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005613-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005613-LAADS</dc:identifier>
    <dc:date>2005-06-08T00:00:00.000Z/2005-06-09T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005159.006.2015086145611.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005035-LAADS</id>
    <title type="text">LAADS:1435278886</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/160/MYD08_D3.A2005160.006.2015086145954.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTT_D3/2005/160/MYBCTT_D3.A2005160.006.2015086150007.jpg" hreflang="en-US" length="475721" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCFR_D3/2005/160/MYBCFR_D3.A2005160.006.2015086150008.jpg" hreflang="en-US" length="576378" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCIR_D3/2005/160/MYBCIR_D3.A2005160.006.2015086150005.jpg" hreflang="en-US" length="419758" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWIR_D3/2005/160/MYBWIR_D3.A2005160.006.2015086150001.jpg" hreflang="en-US" length="432669" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCOT_D3/2005/160/MYBCOT_D3.A2005160.006.2015086150005.jpg" hreflang="en-US" length="476257" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWSW_D3/2005/160/MYBWSW_D3.A2005160.006.2015086150004.jpg" hreflang="en-US" length="330703" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTP_D3/2005/160/MYBCTP_D3.A2005160.006.2015086150006.jpg" hreflang="en-US" length="530758" rel="icon" type="image/jpeg"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005035-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005035-LAADS</dc:identifier>
    <dc:date>2005-06-09T00:00:00.000Z/2005-06-10T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005160.006.2015086145954.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005104-LAADS</id>
    <title type="text">LAADS:1435301352</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/161/MYD08_D3.A2005161.006.2015086144634.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTT_D3/2005/161/MYBCTT_D3.A2005161.006.2015086144650.jpg" hreflang="en-US" length="470154" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWIR_D3/2005/161/MYBWIR_D3.A2005161.006.2015086144642.jpg" hreflang="en-US" length="429154" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWSW_D3/2005/161/MYBWSW_D3.A2005161.006.2015086144644.jpg" hreflang="en-US" length="329454" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCFR_D3/2005/161/MYBCFR_D3.A2005161.006.2015086144652.jpg" hreflang="en-US" length="576498" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCIR_D3/2005/161/MYBCIR_D3.A2005161.006.2015086144646.jpg" hreflang="en-US" length="420548" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCOT_D3/2005/161/MYBCOT_D3.A2005161.006.2015086144647.jpg" hreflang="en-US" length="473631" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTP_D3/2005/161/MYBCTP_D3.A2005161.006.2015086144649.jpg" hreflang="en-US" length="530471" rel="icon" type="image/jpeg"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005104-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005104-LAADS</dc:identifier>
    <dc:date>2005-06-10T00:00:00.000Z/2005-06-11T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005161.006.2015086144634.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G222005040-LAADS</id>
    <title type="text">LAADS:1435282941</title>
    <updated>2015-06-12T14:45:37.075Z</updated>
    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYD08_D3/2005/162/MYD08_D3.A2005162.006.2015086142147.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTP_D3/2005/162/MYBCTP_D3.A2005162.006.2015086142154.jpg" hreflang="en-US" length="531254" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCOT_D3/2005/162/MYBCOT_D3.A2005162.006.2015086142153.jpg" hreflang="en-US" length="477341" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWIR_D3/2005/162/MYBWIR_D3.A2005162.006.2015086142151.jpg" hreflang="en-US" length="430867" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCTT_D3/2005/162/MYBCTT_D3.A2005162.006.2015086142154.jpg" hreflang="en-US" length="472342" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCIR_D3/2005/162/MYBCIR_D3.A2005162.006.2015086142152.jpg" hreflang="en-US" length="420264" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBCFR_D3/2005/162/MYBCFR_D3.A2005162.006.2015086142155.jpg" hreflang="en-US" length="574409" rel="icon" type="image/jpeg"/>

    <link href="ftp://ladsftp.nascom.nasa.gov/allData/6/MYBWSW_D3/2005/162/MYBWSW_D3.A2005162.006.2015086142152.jpg" hreflang="en-US" length="330310" rel="icon" type="image/jpeg"/>

    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_C006update.html" hreflang="en-US" rel="describedBy" title="Overview of MODIS Atmosphere Collection 6 Data Products (ECSCollGuide)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/MOD08_D3/index.html" hreflang="en-US" rel="describedBy" title="Overview of MYD08_D3 (Product Info)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/products_calendar.html" hreflang="en-US" rel="describedBy" title="MODIS Atmosphere Data Availability Calendar and Validation Level (MiscInformation)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://modis-atmos.gsfc.nasa.gov/validation.html" hreflang="en-US" rel="describedBy" title="Known Data Issues (DatasetDisclaimer)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G222005040-LAADS.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G222005040-LAADS</dc:identifier>
    <dc:date>2005-06-11T00:00:00.000Z/2005-06-12T00:00:00.000Z</dc:date>
    <echo:datasetId>MODIS/Aqua Aerosol Cloud Water Vapor Ozone Daily L3 Global 1Deg CMG V006</echo:datasetId>
    <echo:producerGranuleId>MYD08_D3.A2005162.006.2015086142147.hdf</echo:producerGranuleId>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LAADS</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
</feed>
