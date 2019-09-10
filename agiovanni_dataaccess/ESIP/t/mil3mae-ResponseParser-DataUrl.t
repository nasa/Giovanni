#!/usr/bin/perl

use XML::LibXML;

#use ESIP::Response::V1_2;
use Test::More tests => 9;

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
ok( $author eq "CMR", "found:$author" );

my $package = ESIP::ResponseParser::V1_2->new(
    XML  => $dom,
    TYPE => "application/x-hdf",
    sampleFile =>
        "ftp://l5eil01.larc.nasa.gov/misrl2l3/MISR/MIL3MAE.004/2000.02.01/MISR_AM1_CGAS_FEB_2000_F15_0031.hdf",
    sampleOpendap =>
        "http://l0dup05.larc.nasa.gov/opendap/misrl2l3/MISR/MIL3MAE.004/2000.02.01/MISR_AM1_CGAS_FEB_2000_F15_0031.hdf.html"

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

ok( scalar @results == 4, "number of urls:" . scalar @results );

my @test = (
    'http://l0dup05.larc.nasa.gov/opendap/misrl2l3/MISR/MIL3MAE.004/2010.01.01/MISR_AM1_CGAS_JAN_2010_F15_0031.hdf.html',
    'http://l0dup05.larc.nasa.gov/opendap/misrl2l3/MISR/MIL3MAE.004/2010.02.01/MISR_AM1_CGAS_FEB_2010_F15_0031.hdf.html',
    'http://l0dup05.larc.nasa.gov/opendap/misrl2l3/MISR/MIL3MAE.004/2010.03.01/MISR_AM1_CGAS_MAR_2010_F15_0031.hdf.html',
    'http://l0dup05.larc.nasa.gov/opendap/misrl2l3/MISR/MIL3MAE.004/2010.04.01/MISR_AM1_CGAS_APR_2010_F15_0031.hdf.html'

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
  <updated>2015-12-30T14:14:40.210Z</updated>
  <id>https://api.echo.nasa.gov:443/opensearch/granules.atom</id>
  <author>
    <name>CMR</name>
    <email>support@echo.nasa.gov</email>
  </author>
  <title type="text">ECHO granule metadata</title>
  <subtitle type="text">Search parameters: shortName =&gt; MIL3MAE versionId =&gt; 4 dataCenter =&gt; LARC boundingBox =&gt;  geometry =&gt;  placeName =&gt;  startTime =&gt; 2010-01-01T00:00:01Z endTime =&gt; 2010-04-30T23:59:59Z uid =&gt; </subtitle>
  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=MISR Level 3 Component Global Aerosol Product covering a month V004" hreflang="en-US" rel="up" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MIL3MAE&amp;versionId=4&amp;dataCenter=LARC&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2010-01-01T00%3A00%3A01Z&amp;endTime=2010-04-30T23%3A59%3A59Z&amp;cursor=1&amp;numberOfResults=1024&amp;uid=&amp;clientId=Giovanni" hreflang="en-US" rel="self" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MIL3MAE&amp;versionId=4&amp;dataCenter=LARC&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2010-01-01T00%3A00%3A01Z&amp;endTime=2010-04-30T23%3A59%3A59Z&amp;numberOfResults=1024&amp;uid=&amp;clientId=Giovanni&amp;cursor=1" hreflang="en-US" rel="last" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MIL3MAE&amp;versionId=4&amp;dataCenter=LARC&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2010-01-01T00%3A00%3A01Z&amp;endTime=2010-04-30T23%3A59%3A59Z&amp;numberOfResults=1024&amp;uid=&amp;clientId=Giovanni&amp;cursor=1" hreflang="en-US" rel="first" type="application/atom+xml"/>

  <link href="https://wiki.earthdata.nasa.gov/display/echo/Open+Search+API+release+information" hreflang="en-US" rel="describedBy" title="Release Notes" type="text/html"/>

  <os:Query echo:dataCenter="LARC" echo:shortName="MIL3MAE" echo:versionId="4" geo:box="" geo:geometry="" geo:uid="" role="request" time:end="2010-04-30T23:59:59Z" time:start="2010-01-01T00:00:01Z" xmlns:echo="http://www.echo.nasa.gov/esip" xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/"/>

  <os:totalResults>4</os:totalResults>
  <os:itemsPerPage>1024</os:itemsPerPage>
  <os:startIndex>1</os:startIndex>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G187302388-LARC</id>
    <title type="text">SC:MIL3MAE.004:27914731</title>
    <updated>2015-12-23T06:10:55.089Z</updated>
    <link href="ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.01.01/MISR_AM1_CGAS_JAN_2010_F15_0031.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.01.01/MISR_AM1_CGAS_JAN_2010_F15_0031.hdf.xml" hreflang="en-US" rel="via" title="(METADATA)" type="text/xml"/>

    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G187302388-LARC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G187302388-LARC</dc:identifier>
    <dc:date>2010-01-01T00:00:00.000Z/2010-01-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MISR Level 3 Component Global Aerosol Product covering a month V004</echo:datasetId>
    <echo:producerGranuleId>MISR_AM1_CGAS_JAN_2010_F15_0031.hdf</echo:producerGranuleId>
    <echo:granuleSizeMB>76.4009</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LARC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G187303012-LARC</id>
    <title type="text">SC:MIL3MAE.004:27915526</title>
    <updated>2015-12-23T06:10:53.998Z</updated>
    <link href="ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.02.01/MISR_AM1_CGAS_FEB_2010_F15_0031.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.02.01/MISR_AM1_CGAS_FEB_2010_F15_0031.hdf.xml" hreflang="en-US" rel="via" title="(METADATA)" type="text/xml"/>

    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G187303012-LARC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G187303012-LARC</dc:identifier>
    <dc:date>2010-02-01T00:00:00.000Z/2010-02-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MISR Level 3 Component Global Aerosol Product covering a month V004</echo:datasetId>
    <echo:producerGranuleId>MISR_AM1_CGAS_FEB_2010_F15_0031.hdf</echo:producerGranuleId>
    <echo:granuleSizeMB>78.949</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LARC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G188745394-LARC</id>
    <title type="text">SC:MIL3MAE.004:28355002</title>
    <updated>2015-12-23T06:10:52.992Z</updated>
    <link href="ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.03.01/MISR_AM1_CGAS_MAR_2010_F15_0031.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.03.01/MISR_AM1_CGAS_MAR_2010_F15_0031.hdf.xml" hreflang="en-US" rel="via" title="(METADATA)" type="text/xml"/>

    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G188745394-LARC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G188745394-LARC</dc:identifier>
    <dc:date>2010-03-01T00:00:00.000Z/2010-03-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MISR Level 3 Component Global Aerosol Product covering a month V004</echo:datasetId>
    <echo:producerGranuleId>MISR_AM1_CGAS_MAR_2010_F15_0031.hdf</echo:producerGranuleId>
    <echo:granuleSizeMB>92.0083</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LARC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G188823591-LARC</id>
    <title type="text">SC:MIL3MAE.004:28394044</title>
    <updated>2015-12-23T06:10:55.185Z</updated>
    <link href="ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.04.01/MISR_AM1_CGAS_APR_2010_F15_0031.hdf" hreflang="en-US" rel="enclosure" type="application/x-hdfeos"/>

    <link href="ftp://l5eil01.larc.nasa.gov//misrl2l3/MISR/MIL3MAE.004/2010.04.01/MISR_AM1_CGAS_APR_2010_F15_0031.hdf.xml" hreflang="en-US" rel="via" title="(METADATA)" type="text/xml"/>

    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G188823591-LARC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G188823591-LARC</dc:identifier>
    <dc:date>2010-04-01T00:00:00.000Z/2010-04-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MISR Level 3 Component Global Aerosol Product covering a month V004</echo:datasetId>
    <echo:producerGranuleId>MISR_AM1_CGAS_APR_2010_F15_0031.hdf</echo:producerGranuleId>
    <echo:granuleSizeMB>91.4932</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>LARC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
</feed>

