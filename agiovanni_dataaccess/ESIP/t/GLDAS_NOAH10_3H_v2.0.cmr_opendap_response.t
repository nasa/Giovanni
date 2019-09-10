#!/usr/bin/perl

use XML::LibXML;

use Test::More tests => 14;

BEGIN {
    use_ok('ESIP::ResponseParser::V1_2');
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
ok( $author eq "CMR", "found:$author" );

my $package = ESIP::ResponseParser::V1_2->new(
    XML  => $dom,
    TYPE => "application/x-hdf",
    sampleFile =>
        "https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0300.020.nc4",
);

my @results;
my @tmp = $package->getDataUrls();

push @results, @{ $tmp[0] };

ok( scalar @results == 3, "number of urls:" . scalar @results );

my @testUrls = (
    'https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0300.020.nc4',
    'https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0600.020.nc4',
    'https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0900.020.nc4'
);
my @testDates = (
    '1948-01-01T03:00:00.000Z',
    '1948-01-01T06:00:00.000Z',
    '1948-01-01T09:00:00.000Z',
);
my $count;
for ( my $i = 0; $i <= $#results; ++$i ) {
    $count = $i + 1;
    ok( $testUrls[$i] eq $results[$i]->{url}, "url comparison $count" );
}
for ( my $i = 0; $i <= $#results; ++$i ) {
    $count = $i + 1;
    ok( $testDates[$i] eq $results[$i]->{startTime}, "has startTime $count" );
    ok( $testDates[$i] eq $results[$i]->{endTime}, "has endTime $count" );
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
<feed xmlns:os="http://a9.com/-/spec/opensearch/1.1/" xmlns:georss="http://www.georss.org/georss" xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/terms/" xmlns:echo="http://www.echo.nasa.gov/esip" xmlns:esipdiscovery="http://commons.esipfed.org/ns/discovery/1.2/" xmlns:gml="http://www.opengis.net/gml" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/" xmlns:eo="http://a9.com/-/opensearch/extensions/eo/1.0/" esipdiscovery:version="1.2">
  <updated>2018-04-13T22:25:43.361Z</updated>
  <id>https://cmr.earthdata.nasa.gov/opensearch/granules.atom</id>
  <author>
    <name>CMR</name>
    <email>echodev@echo.nasa.gov</email>
  </author>
  <title type="text">ECHO granule metadata</title>
  <subtitle type="text">Search parameters: keyword =&gt;  shortName =&gt; GLDAS_NOAH10_3H versionId =&gt; 2.0 dataCenter =&gt;  instrument =&gt;  satellite =&gt;  boundingBox =&gt;  geometry =&gt;  placeName =&gt;  startTime =&gt; 1948-01-01T00:00:00Z endTime =&gt; 1948-01-01T09:00:00Z uid =&gt; </subtitle>
  <link href="http://cmr.earthdata.nasa.gov/opensearch/granules.atom?datasetId=GLDAS Noah Land Surface Model L4 3 hourly 1.0 x 1.0 degree V2.0 (GLDAS_NOAH10_3H) at GES DISC" hreflang="en-US" type="application/atom+xml" rel="up"/>
  <link href="http://cmr.earthdata.nasa.gov/opensearch/granules.atom?utf8=%E2%9C%93&amp;clientId=our_html_ui&amp;keyword=&amp;instrument=&amp;satellite=&amp;parentIdentifier=&amp;shortName=GLDAS_NOAH10_3H&amp;versionId=2.0&amp;dataCenter=&amp;startTime=1948-01-01T00%3A00%3A00Z&amp;endTime=1948-01-01T09%3A00%3A00Z&amp;spatial_type=bbox&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;uid=&amp;numberOfResults=10&amp;cursor=1&amp;commit=Search" hreflang="en-US" type="application/atom+xml" rel="self"/>
  <link href="http://cmr.earthdata.nasa.gov/opensearch/granules.atom?utf8=%E2%9C%93&amp;clientId=our_html_ui&amp;keyword=&amp;instrument=&amp;satellite=&amp;parentIdentifier=&amp;shortName=GLDAS_NOAH10_3H&amp;versionId=2.0&amp;dataCenter=&amp;startTime=1948-01-01T00%3A00%3A00Z&amp;endTime=1948-01-01T09%3A00%3A00Z&amp;spatial_type=bbox&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;uid=&amp;numberOfResults=10&amp;commit=Search&amp;cursor=1" hreflang="en-US" type="application/atom+xml" rel="last"/>
  <link href="http://cmr.earthdata.nasa.gov/opensearch/granules.atom?utf8=%E2%9C%93&amp;clientId=our_html_ui&amp;keyword=&amp;instrument=&amp;satellite=&amp;parentIdentifier=&amp;shortName=GLDAS_NOAH10_3H&amp;versionId=2.0&amp;dataCenter=&amp;startTime=1948-01-01T00%3A00%3A00Z&amp;endTime=1948-01-01T09%3A00%3A00Z&amp;spatial_type=bbox&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;uid=&amp;numberOfResults=10&amp;commit=Search&amp;cursor=1" hreflang="en-US" type="application/atom+xml" rel="first"/>
  <link href="https://wiki.earthdata.nasa.gov/display/echo/Open+Search+API+release+information" hreflang="en-US" type="text/html" rel="describedBy" title="Release Notes"/>
  <os:Query xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" role="request" os:searchTerms="" echo:dataCenter="" echo:shortName="GLDAS_NOAH10_3H" echo:versionId="2.0" echo:instrument="" eo:platform="" geo:box="" geo:geometry="" time:start="1948-01-01T00:00:00Z" time:end="1948-01-01T09:00:00Z" geo:uid=""/>
  <os:totalResults>3</os:totalResults>
  <os:itemsPerPage>10</os:itemsPerPage>
  <os:startIndex>1</os:startIndex>
  <entry>
    <id>https://cmr.earthdata.nasa.gov/opensearch/granules.atom?uid=G1414823004-GES_DISC</id>
    <title type="text">GLDAS_NOAH10_3H.2.0:GLDAS_NOAH10_3H.A19480101.0300.020.nc4</title>
    <updated>2015-08-12T17:20:48.000Z</updated>
    <link rel="enclosure" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0300.020.nc4"/>
    <link rel="via" type="application/x-netcdf;ver=4" title="The OPENDAP location for the granule. (GET DATA : OPENDAP DATA)" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/opendap/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0300.020.nc4"/>
    <link echo:inherited="true" rel="via" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_3H.2.0/">
      <echo:inherited/>
    </link>
    <link echo:inherited="true" rel="describedBy" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/doc/README_GLDAS2.pdf" type="application/pdf">
      <echo:inherited/>
    </link>
    <link echo:inherited="true" rel="via" hreflang="en-US" href="https://ldas.gsfc.nasa.gov/gldas/">
      <echo:inherited/>
    </link>
    <link echo:inherited="true" rel="describedBy" hreflang="en-US" href="https://disc.gsfc.nasa.gov/information/howto">
      <echo:inherited/>
    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1414823004-GES_DISC.xml" hreflang="en-US" type="application/xml" rel="via" title="Product metadata"/>
    <dc:identifier>G1414823004-GES_DISC</dc:identifier>
    <dc:date>1948-01-01T03:00:00.000Z</dc:date>
    <echo:datasetId>GLDAS Noah Land Surface Model L4 3 hourly 1.0 x 1.0 degree V2.0 (GLDAS_NOAH10_3H) at GES DISC</echo:datasetId>
    <echo:producerGranuleId>GLDAS_NOAH10_3H.A19480101.0300.020.nc4</echo:producerGranuleId>
    <echo:granuleSizeMB>1.6508074</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>GES_DISC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-60 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://cmr.earthdata.nasa.gov/opensearch/granules.atom?uid=G1414823002-GES_DISC</id>
    <title type="text">GLDAS_NOAH10_3H.2.0:GLDAS_NOAH10_3H.A19480101.0600.020.nc4</title>
    <updated>2015-08-12T17:20:48.000Z</updated>
    <link rel="enclosure" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0600.020.nc4"/>
    <link rel="via" type="application/x-netcdf;ver=4" title="The OPENDAP location for the granule. (GET DATA : OPENDAP DATA)" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/opendap/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0600.020.nc4"/>
    <link echo:inherited="true" rel="via" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_3H.2.0/">
      <echo:inherited/>
    </link>
    <link echo:inherited="true" rel="describedBy" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/doc/README_GLDAS2.pdf" type="application/pdf">
      <echo:inherited/>
    </link>
    <link echo:inherited="true" rel="via" hreflang="en-US" href="https://ldas.gsfc.nasa.gov/gldas/">
      <echo:inherited/>
    </link>
    <link echo:inherited="true" rel="describedBy" hreflang="en-US" href="https://disc.gsfc.nasa.gov/information/howto">
      <echo:inherited/>
    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1414823002-GES_DISC.xml" hreflang="en-US" type="application/xml" rel="via" title="Product metadata"/>
    <dc:identifier>G1414823002-GES_DISC</dc:identifier>
    <dc:date>1948-01-01T06:00:00.000Z</dc:date>
    <echo:datasetId>GLDAS Noah Land Surface Model L4 3 hourly 1.0 x 1.0 degree V2.0 (GLDAS_NOAH10_3H) at GES DISC</echo:datasetId>
    <echo:producerGranuleId>GLDAS_NOAH10_3H.A19480101.0600.020.nc4</echo:producerGranuleId>
    <echo:granuleSizeMB>1.6666727</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>GES_DISC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-60 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://cmr.earthdata.nasa.gov/opensearch/granules.atom?uid=G1414823006-GES_DISC</id>
    <title type="text">GLDAS_NOAH10_3H.2.0:GLDAS_NOAH10_3H.A19480101.0900.020.nc4</title>
    <updated>2015-08-12T17:20:48.000Z</updated>
    <link rel="enclosure" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0900.020.nc4"/>
    <link rel="via" type="application/x-netcdf;ver=4" title="The OPENDAP location for the granule. (GET DATA : OPENDAP DATA)" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/opendap/GLDAS/GLDAS_NOAH10_3H.2.0/1948/001/GLDAS_NOAH10_3H.A19480101.0900.020.nc4"/>
    <link echo:inherited="true" rel="via" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_3H.2.0/">
      <echo:inherited/>
    </link>
    <link echo:inherited="true" rel="describedBy" hreflang="en-US" href="https://hydro1.gesdisc.eosdis.nasa.gov/data/GLDAS/GLDAS_NOAH10_3H.2.0/doc/README_GLDAS2.pdf" type="application/pdf">
      <echo:inherited/>
    </link>
    <link echo:inherited="true" rel="via" hreflang="en-US" href="https://ldas.gsfc.nasa.gov/gldas/">
      <echo:inherited/>
    </link>
    <link echo:inherited="true" rel="describedBy" hreflang="en-US" href="https://disc.gsfc.nasa.gov/information/howto">
      <echo:inherited/>
    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1414823006-GES_DISC.xml" hreflang="en-US" type="application/xml" rel="via" title="Product metadata"/>
    <dc:identifier>G1414823006-GES_DISC</dc:identifier>
    <dc:date>1948-01-01T09:00:00.000Z</dc:date>
    <echo:datasetId>GLDAS Noah Land Surface Model L4 3 hourly 1.0 x 1.0 degree V2.0 (GLDAS_NOAH10_3H) at GES DISC</echo:datasetId>
    <echo:producerGranuleId>GLDAS_NOAH10_3H.A19480101.0900.020.nc4</echo:producerGranuleId>
    <echo:granuleSizeMB>1.6884451</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>GES_DISC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-60 -180 90 180</georss:box>
  </entry>
</feed>

