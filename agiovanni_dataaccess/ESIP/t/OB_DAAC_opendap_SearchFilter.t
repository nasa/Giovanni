#!/usr/bin/perl

use XML::LibXML;

#use ESIP::Response::V1_2;
use Test::More tests => 7;

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
ok( $author eq "CMR", "found author $author" );

my $package = ESIP::ResponseParser::SearchFilter->new(
    XML  => $dom,
    TYPE => "application/x-hdf",
    sampleFile =>
        "https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022132002243.L3m_MO_SST_sst_4km.nc",
    sampleOpendap =>
        "https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2002/213/A20022132002243.L3m_MO_SST_sst_4km.nc.html",
    searchFilter => "opendap.+L3m_MO_SST4_sst4_4km"

);

my @results;
my @tmp = $package->getOPeNDAPUrls();

push @results, @{ $tmp[0] };

ok( scalar @results == 2, "number of urls:" . scalar @results );

my @test = (
    'https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/213/A20152132015243.L3m_MO_SST4_sst4_4km.nc',
    'https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/244/A20152442015273.L3m_MO_SST4_sst4_4km.nc'

);

for ( my $i = 0; $i <= $#results; ++$i ) {
    ok( $test[$i] eq $results[$i]->{url}, 'regexed opendap url comparison' );
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
  <updated>2015-12-23T15:56:58.635Z</updated>
  <id>https://api.echo.nasa.gov:443/opensearch/granules.atom</id>
  <author>
    <name>CMR</name>
    <email>support@echo.nasa.gov</email>
  </author>
  <title type="text">ECHO granule metadata</title>
  <subtitle type="text">Search parameters: shortName =&gt; MODISA_L3m_SST versionId =&gt; 2014 dataCenter =&gt; OB_DAAC boundingBox =&gt;  geometry =&gt;  placeName =&gt;  startTime =&gt; 2015-08-01T00:00:01Z endTime =&gt; 2015-09-01T23:59:59Z uid =&gt; </subtitle>
  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=MODISA_L3m_SST" hreflang="en-US" rel="up" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MODISA_L3m_SST&amp;versionId=2014&amp;dataCenter=OB_DAAC&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2015-08-01T00%3A00%3A01Z&amp;endTime=2015-09-01T23%3A59%3A59Z&amp;cursor=1&amp;numberOfResults=1024&amp;uid=&amp;clientId=giovanni" hreflang="en-US" rel="self" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MODISA_L3m_SST&amp;versionId=2014&amp;dataCenter=OB_DAAC&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2015-08-01T00%3A00%3A01Z&amp;endTime=2015-09-01T23%3A59%3A59Z&amp;numberOfResults=1024&amp;uid=&amp;clientId=giovanni&amp;cursor=1" hreflang="en-US" rel="last" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=MODISA_L3m_SST&amp;versionId=2014&amp;dataCenter=OB_DAAC&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2015-08-01T00%3A00%3A01Z&amp;endTime=2015-09-01T23%3A59%3A59Z&amp;numberOfResults=1024&amp;uid=&amp;clientId=giovanni&amp;cursor=1" hreflang="en-US" rel="first" type="application/atom+xml"/>

  <link href="https://wiki.earthdata.nasa.gov/display/echo/Open+Search+API+release+information" hreflang="en-US" rel="describedBy" title="Release Notes" type="text/html"/>

  <os:Query echo:dataCenter="OB_DAAC" echo:shortName="MODISA_L3m_SST" echo:versionId="2014" geo:box="" geo:geometry="" geo:uid="" role="request" time:end="2015-09-01T23:59:59Z" time:start="2015-08-01T00:00:01Z" xmlns:echo="https://www.echo.nasa.gov/esip" xmlns:geo="https://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:time="https://a9.com/-/opensearch/extensions/time/1.0/"/>

  <os:totalResults>312</os:totalResults>
  <os:itemsPerPage>1024</os:itemsPerPage>
  <os:startIndex>1</os:startIndex>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1201145557-OB_DAAC</id>
    <title type="text">A20152132015243.L3m_MO_SST4_sst4_9km.nc</title>
    <updated>2015-10-23T03:05:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152132015243.L3m_MO_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/213/A20152132015243.L3m_MO_SST4_sst4_9km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1201145557-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1201145557-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152132015243.L3m_MO_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.835217</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009047-OB_DAAC</id>
    <title type="text">A20021722015263.L3m_SCSU_SST4_sst4_9km.nc</title>
    <updated>2015-10-14T05:11:45.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20021722015263.L3m_SCSU_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009047-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009047-OB_DAAC</dc:identifier>
    <dc:date>2002-07-04T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20021722015263.L3m_SCSU_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.319407</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009048-OB_DAAC</id>
    <title type="text">A20021722015263.L3m_SCSU_SST_sst_4km.nc</title>
    <updated>2015-10-14T05:11:48.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20021722015263.L3m_SCSU_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009048-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009048-OB_DAAC</dc:identifier>
    <dc:date>2002-07-04T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20021722015263.L3m_SCSU_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.984547</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009049-OB_DAAC</id>
    <title type="text">A20021722015263.L3m_SCSU_SST_sst_9km.nc</title>
    <updated>2015-10-14T05:11:48.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20021722015263.L3m_SCSU_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009049-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009049-OB_DAAC</dc:identifier>
    <dc:date>2002-07-04T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20021722015263.L3m_SCSU_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.422386</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009051-OB_DAAC</id>
    <title type="text">A20021722015263.L3m_SCSU_NSST_sst_4km.nc</title>
    <updated>2015-10-14T05:11:48.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20021722015263.L3m_SCSU_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009051-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009051-OB_DAAC</dc:identifier>
    <dc:date>2002-07-04T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20021722015263.L3m_SCSU_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.85313</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009054-OB_DAAC</id>
    <title type="text">A20021722015263.L3m_SCSU_NSST_sst_9km.nc</title>
    <updated>2015-10-14T05:11:48.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20021722015263.L3m_SCSU_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009054-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009054-OB_DAAC</dc:identifier>
    <dc:date>2002-07-04T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20021722015263.L3m_SCSU_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.29022</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009061-OB_DAAC</id>
    <title type="text">A20021722015263.L3m_SCSU_SST4_sst4_4km.nc</title>
    <updated>2015-10-14T05:11:45.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20021722015263.L3m_SCSU_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009061-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009061-OB_DAAC</dc:identifier>
    <dc:date>2002-07-04T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20021722015263.L3m_SCSU_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.89758</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203393275-OB_DAAC</id>
    <title type="text">A20022132015243.L3m_MC_SST4_sst4_4km.nc</title>
    <updated>2015-09-23T02:56:46.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022132015243.L3m_MC_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203393275-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203393275-OB_DAAC</dc:identifier>
    <dc:date>2002-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022132015243.L3m_MC_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.773205</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203393276-OB_DAAC</id>
    <title type="text">A20022132015243.L3m_MC_SST4_sst4_9km.nc</title>
    <updated>2015-09-23T02:56:46.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022132015243.L3m_MC_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203393276-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203393276-OB_DAAC</dc:identifier>
    <dc:date>2002-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022132015243.L3m_MC_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.111643</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203393277-OB_DAAC</id>
    <title type="text">A20022132015243.L3m_MC_SST_sst_4km.nc</title>
    <updated>2015-09-23T02:57:02.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022132015243.L3m_MC_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203393277-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203393277-OB_DAAC</dc:identifier>
    <dc:date>2002-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022132015243.L3m_MC_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.78761</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203393278-OB_DAAC</id>
    <title type="text">A20022132015243.L3m_MC_SST_sst_9km.nc</title>
    <updated>2015-09-23T02:57:02.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022132015243.L3m_MC_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203393278-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203393278-OB_DAAC</dc:identifier>
    <dc:date>2002-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022132015243.L3m_MC_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.255896</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203399632-OB_DAAC</id>
    <title type="text">A20022132015243.L3m_MC_NSST_sst_4km.nc</title>
    <updated>2015-09-23T02:57:03.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022132015243.L3m_MC_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203399632-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203399632-OB_DAAC</dc:identifier>
    <dc:date>2002-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022132015243.L3m_MC_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.810825</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203399655-OB_DAAC</id>
    <title type="text">A20022132015243.L3m_MC_NSST_sst_9km.nc</title>
    <updated>2015-09-23T02:57:03.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022132015243.L3m_MC_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203399655-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203399655-OB_DAAC</dc:identifier>
    <dc:date>2002-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022132015243.L3m_MC_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.103071</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009294-OB_DAAC</id>
    <title type="text">A20022442015273.L3m_MC_NSST_sst_4km.nc</title>
    <updated>2015-10-21T05:53:43.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022442015273.L3m_MC_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009294-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009294-OB_DAAC</dc:identifier>
    <dc:date>2002-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022442015273.L3m_MC_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.776173</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009295-OB_DAAC</id>
    <title type="text">A20022442015273.L3m_MC_NSST_sst_9km.nc</title>
    <updated>2015-10-21T05:53:43.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022442015273.L3m_MC_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009295-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009295-OB_DAAC</dc:identifier>
    <dc:date>2002-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022442015273.L3m_MC_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.17837</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009311-OB_DAAC</id>
    <title type="text">A20022442015273.L3m_MC_SST_sst_4km.nc</title>
    <updated>2015-10-21T05:54:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022442015273.L3m_MC_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009311-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009311-OB_DAAC</dc:identifier>
    <dc:date>2002-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022442015273.L3m_MC_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.35722</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009332-OB_DAAC</id>
    <title type="text">A20022442015273.L3m_MC_SST_sst_9km.nc</title>
    <updated>2015-10-21T05:54:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022442015273.L3m_MC_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009332-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009332-OB_DAAC</dc:identifier>
    <dc:date>2002-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022442015273.L3m_MC_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.127365</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009333-OB_DAAC</id>
    <title type="text">A20022442015273.L3m_MC_SST4_sst4_4km.nc</title>
    <updated>2015-10-21T05:55:26.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022442015273.L3m_MC_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009333-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009333-OB_DAAC</dc:identifier>
    <dc:date>2002-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022442015273.L3m_MC_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.769417</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009334-OB_DAAC</id>
    <title type="text">A20022442015273.L3m_MC_SST4_sst4_9km.nc</title>
    <updated>2015-10-21T05:55:26.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022442015273.L3m_MC_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009334-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009334-OB_DAAC</dc:identifier>
    <dc:date>2002-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022442015273.L3m_MC_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.19336</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1214226039-OB_DAAC</id>
    <title type="text">A20022742015304.L3m_MC_NSST_sst_4km.nc</title>
    <updated>2015-11-25T11:01:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022742015304.L3m_MC_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1214226039-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1214226039-OB_DAAC</dc:identifier>
    <dc:date>2002-10-01T00:00:00.000Z/2015-10-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022742015304.L3m_MC_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.619507</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1214226060-OB_DAAC</id>
    <title type="text">A20022742015304.L3m_MC_NSST_sst_9km.nc</title>
    <updated>2015-11-25T11:01:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022742015304.L3m_MC_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1214226060-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1214226060-OB_DAAC</dc:identifier>
    <dc:date>2002-10-01T00:00:00.000Z/2015-10-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022742015304.L3m_MC_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.06877</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1214226062-OB_DAAC</id>
    <title type="text">A20022742015304.L3m_MC_SST_sst_4km.nc</title>
    <updated>2015-11-25T11:02:21.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022742015304.L3m_MC_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1214226062-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1214226062-OB_DAAC</dc:identifier>
    <dc:date>2002-10-01T00:00:00.000Z/2015-10-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022742015304.L3m_MC_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.01337</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1214226063-OB_DAAC</id>
    <title type="text">A20022742015304.L3m_MC_SST_sst_9km.nc</title>
    <updated>2015-11-25T11:02:21.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022742015304.L3m_MC_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1214226063-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1214226063-OB_DAAC</dc:identifier>
    <dc:date>2002-10-01T00:00:00.000Z/2015-10-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022742015304.L3m_MC_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.965591</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1214226065-OB_DAAC</id>
    <title type="text">A20022742015304.L3m_MC_SST4_sst4_4km.nc</title>
    <updated>2015-11-25T11:02:34.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022742015304.L3m_MC_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1214226065-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1214226065-OB_DAAC</dc:identifier>
    <dc:date>2002-10-01T00:00:00.000Z/2015-10-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022742015304.L3m_MC_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.666332</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1214226066-OB_DAAC</id>
    <title type="text">A20022742015304.L3m_MC_SST4_sst4_9km.nc</title>
    <updated>2015-11-25T11:02:34.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20022742015304.L3m_MC_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1214226066-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1214226066-OB_DAAC</dc:identifier>
    <dc:date>2002-10-01T00:00:00.000Z/2015-10-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20022742015304.L3m_MC_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.098349</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203393283-OB_DAAC</id>
    <title type="text">A20151722015263.L3m_SNSU_NSST_sst_4km.nc</title>
    <updated>2015-10-07T06:28:44.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151722015263.L3m_SNSU_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203393283-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203393283-OB_DAAC</dc:identifier>
    <dc:date>2015-06-21T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151722015263.L3m_SNSU_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.824726</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203393284-OB_DAAC</id>
    <title type="text">A20151722015263.L3m_SNSU_NSST_sst_9km.nc</title>
    <updated>2015-10-07T06:28:44.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151722015263.L3m_SNSU_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203393284-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203393284-OB_DAAC</dc:identifier>
    <dc:date>2015-06-21T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151722015263.L3m_SNSU_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.095598</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203393302-OB_DAAC</id>
    <title type="text">A20151722015263.L3m_SNSU_SST4_sst4_4km.nc</title>
    <updated>2015-10-07T06:28:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151722015263.L3m_SNSU_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203393302-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203393302-OB_DAAC</dc:identifier>
    <dc:date>2015-06-21T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151722015263.L3m_SNSU_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.68507</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203393303-OB_DAAC</id>
    <title type="text">A20151722015263.L3m_SNSU_SST4_sst4_9km.nc</title>
    <updated>2015-10-07T06:28:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151722015263.L3m_SNSU_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203393303-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203393303-OB_DAAC</dc:identifier>
    <dc:date>2015-06-21T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151722015263.L3m_SNSU_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.082506</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205547142-OB_DAAC</id>
    <title type="text">A20151722015263.L3m_SNSU_SST_sst_4km.nc</title>
    <updated>2015-10-07T06:28:30.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151722015263.L3m_SNSU_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205547142-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205547142-OB_DAAC</dc:identifier>
    <dc:date>2015-06-21T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151722015263.L3m_SNSU_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.362354</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205547144-OB_DAAC</id>
    <title type="text">A20151722015263.L3m_SNSU_SST_sst_9km.nc</title>
    <updated>2015-10-07T06:28:31.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151722015263.L3m_SNSU_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205547144-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205547144-OB_DAAC</dc:identifier>
    <dc:date>2015-06-21T00:00:00.000Z/2015-09-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151722015263.L3m_SNSU_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.083475</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920649-OB_DAAC</id>
    <title type="text">A20151852015216.L3m_R32_SST_sst_4km.nc</title>
    <updated>2015-08-25T11:07:49.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151852015216.L3m_R32_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920649-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920649-OB_DAAC</dc:identifier>
    <dc:date>2015-07-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151852015216.L3m_R32_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>61.31177</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920661-OB_DAAC</id>
    <title type="text">A20151852015216.L3m_R32_SST_sst_9km.nc</title>
    <updated>2015-08-25T11:07:50.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151852015216.L3m_R32_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920661-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920661-OB_DAAC</dc:identifier>
    <dc:date>2015-07-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151852015216.L3m_R32_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.38006</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920747-OB_DAAC</id>
    <title type="text">A20151852015216.L3m_R32_SST4_sst4_4km.nc</title>
    <updated>2015-08-26T03:09:00.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151852015216.L3m_R32_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920747-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920747-OB_DAAC</dc:identifier>
    <dc:date>2015-07-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151852015216.L3m_R32_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>62.756798</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920748-OB_DAAC</id>
    <title type="text">A20151852015216.L3m_R32_SST4_sst4_9km.nc</title>
    <updated>2015-08-26T03:09:00.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151852015216.L3m_R32_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920748-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920748-OB_DAAC</dc:identifier>
    <dc:date>2015-07-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151852015216.L3m_R32_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.499262</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920751-OB_DAAC</id>
    <title type="text">A20151852015216.L3m_R32_NSST_sst_9km.nc</title>
    <updated>2015-08-26T03:09:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151852015216.L3m_R32_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920751-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920751-OB_DAAC</dc:identifier>
    <dc:date>2015-07-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151852015216.L3m_R32_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.508764</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920774-OB_DAAC</id>
    <title type="text">A20151852015216.L3m_R32_NSST_sst_4km.nc</title>
    <updated>2015-08-26T03:09:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151852015216.L3m_R32_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920774-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920774-OB_DAAC</dc:identifier>
    <dc:date>2015-07-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151852015216.L3m_R32_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>62.851402</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205923807-OB_DAAC</id>
    <title type="text">A20151932015224.L3m_R32_SST_sst_4km.nc</title>
    <updated>2015-09-02T12:34:23.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151932015224.L3m_R32_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205923807-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205923807-OB_DAAC</dc:identifier>
    <dc:date>2015-07-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151932015224.L3m_R32_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>61.446033</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205923833-OB_DAAC</id>
    <title type="text">A20151932015224.L3m_R32_SST_sst_9km.nc</title>
    <updated>2015-09-02T12:34:23.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151932015224.L3m_R32_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205923833-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205923833-OB_DAAC</dc:identifier>
    <dc:date>2015-07-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151932015224.L3m_R32_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.430344</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205924028-OB_DAAC</id>
    <title type="text">A20151932015224.L3m_R32_NSST_sst_4km.nc</title>
    <updated>2015-09-02T04:38:10.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151932015224.L3m_R32_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205924028-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205924028-OB_DAAC</dc:identifier>
    <dc:date>2015-07-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151932015224.L3m_R32_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.027508</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205924029-OB_DAAC</id>
    <title type="text">A20151932015224.L3m_R32_NSST_sst_9km.nc</title>
    <updated>2015-09-02T04:38:10.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151932015224.L3m_R32_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205924029-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205924029-OB_DAAC</dc:identifier>
    <dc:date>2015-07-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151932015224.L3m_R32_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.596348</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205924060-OB_DAAC</id>
    <title type="text">A20151932015224.L3m_R32_SST4_sst4_9km.nc</title>
    <updated>2015-09-02T04:38:11.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151932015224.L3m_R32_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205924060-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205924060-OB_DAAC</dc:identifier>
    <dc:date>2015-07-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151932015224.L3m_R32_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.584263</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205924063-OB_DAAC</id>
    <title type="text">A20151932015224.L3m_R32_SST4_sst4_4km.nc</title>
    <updated>2015-09-02T04:38:11.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20151932015224.L3m_R32_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205924063-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205924063-OB_DAAC</dc:identifier>
    <dc:date>2015-07-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20151932015224.L3m_R32_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>62.90652</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205908468-OB_DAAC</id>
    <title type="text">A20152012015232.L3m_R32_SST_sst_9km.nc</title>
    <updated>2015-09-16T02:14:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152012015232.L3m_R32_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205908468-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205908468-OB_DAAC</dc:identifier>
    <dc:date>2015-07-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152012015232.L3m_R32_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.440056</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205908481-OB_DAAC</id>
    <title type="text">A20152012015232.L3m_R32_SST_sst_4km.nc</title>
    <updated>2015-09-16T02:14:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152012015232.L3m_R32_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205908481-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205908481-OB_DAAC</dc:identifier>
    <dc:date>2015-07-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152012015232.L3m_R32_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>61.441483</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205929865-OB_DAAC</id>
    <title type="text">A20152012015232.L3m_R32_SST4_sst4_4km.nc</title>
    <updated>2015-09-09T05:29:42.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152012015232.L3m_R32_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205929865-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205929865-OB_DAAC</dc:identifier>
    <dc:date>2015-07-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152012015232.L3m_R32_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.05615</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205929889-OB_DAAC</id>
    <title type="text">A20152012015232.L3m_R32_NSST_sst_4km.nc</title>
    <updated>2015-09-09T05:29:29.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152012015232.L3m_R32_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205929889-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205929889-OB_DAAC</dc:identifier>
    <dc:date>2015-07-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152012015232.L3m_R32_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.1785</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205929890-OB_DAAC</id>
    <title type="text">A20152012015232.L3m_R32_NSST_sst_9km.nc</title>
    <updated>2015-09-09T05:29:29.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152012015232.L3m_R32_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205929890-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205929890-OB_DAAC</dc:identifier>
    <dc:date>2015-07-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152012015232.L3m_R32_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.705421</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205929892-OB_DAAC</id>
    <title type="text">A20152012015232.L3m_R32_SST4_sst4_9km.nc</title>
    <updated>2015-09-09T05:29:42.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152012015232.L3m_R32_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205929892-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205929892-OB_DAAC</dc:identifier>
    <dc:date>2015-07-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152012015232.L3m_R32_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.692425</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205908466-OB_DAAC</id>
    <title type="text">A20152092015240.L3m_R32_SST_sst_9km.nc</title>
    <updated>2015-09-16T02:14:27.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015240.L3m_R32_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205908466-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205908466-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015240.L3m_R32_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.489128</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205908480-OB_DAAC</id>
    <title type="text">A20152092015240.L3m_R32_SST_sst_4km.nc</title>
    <updated>2015-09-16T02:14:27.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015240.L3m_R32_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205908480-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205908480-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015240.L3m_R32_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>61.54188</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205908696-OB_DAAC</id>
    <title type="text">A20152092015240.L3m_R32_SST4_sst4_4km.nc</title>
    <updated>2015-09-16T06:15:06.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015240.L3m_R32_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205908696-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205908696-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015240.L3m_R32_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.15221</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205908697-OB_DAAC</id>
    <title type="text">A20152092015240.L3m_R32_SST4_sst4_9km.nc</title>
    <updated>2015-09-16T06:15:06.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015240.L3m_R32_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205908697-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205908697-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015240.L3m_R32_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.795095</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205908699-OB_DAAC</id>
    <title type="text">A20152092015240.L3m_R32_NSST_sst_4km.nc</title>
    <updated>2015-09-16T06:15:32.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015240.L3m_R32_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205908699-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205908699-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015240.L3m_R32_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.299393</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205908708-OB_DAAC</id>
    <title type="text">A20152092015240.L3m_R32_NSST_sst_9km.nc</title>
    <updated>2015-09-16T06:15:32.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015240.L3m_R32_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205908708-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205908708-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015240.L3m_R32_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.806704</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915119-OB_DAAC</id>
    <title type="text">A20152092015216.L3m_8D_SST4_sst4_9km.nc</title>
    <updated>2015-08-20T02:29:27.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015216.L3m_8D_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915119-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915119-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015216.L3m_8D_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>15.804037</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915159-OB_DAAC</id>
    <title type="text">A20152092015216.L3m_8D_SST4_sst4_4km.nc</title>
    <updated>2015-08-20T02:29:27.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015216.L3m_8D_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915159-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915159-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015216.L3m_8D_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>59.643703</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915161-OB_DAAC</id>
    <title type="text">A20152092015216.L3m_8D_NSST_sst_4km.nc</title>
    <updated>2015-08-20T02:29:30.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015216.L3m_8D_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915161-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915161-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015216.L3m_8D_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>59.538513</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915162-OB_DAAC</id>
    <title type="text">A20152092015216.L3m_8D_NSST_sst_9km.nc</title>
    <updated>2015-08-20T02:29:30.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015216.L3m_8D_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915162-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915162-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015216.L3m_8D_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>15.762569</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205916245-OB_DAAC</id>
    <title type="text">A20152092015216.L3m_8D_SST_sst_4km.nc</title>
    <updated>2015-08-21T02:34:31.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015216.L3m_8D_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205916245-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205916245-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015216.L3m_8D_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>56.486263</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205916246-OB_DAAC</id>
    <title type="text">A20152092015216.L3m_8D_SST_sst_9km.nc</title>
    <updated>2015-08-21T02:34:31.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152092015216.L3m_8D_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205916246-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205916246-OB_DAAC</dc:identifier>
    <dc:date>2015-07-28T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152092015216.L3m_8D_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>15.053906</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1201145557-OB_DAAC</id>
    <title type="text">A20152132015243.L3m_MO_SST4_sst4_9km.nc</title>
    <updated>2015-10-23T03:05:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152132015243.L3m_MO_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/213/A20152132015243.L3m_MO_SST4_sst4_9km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1201145557-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1201145557-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152132015243.L3m_MO_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.835217</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1201145581-OB_DAAC</id>
    <title type="text">A20152132015243.L3m_MO_SST4_sst4_4km.nc</title>
    <updated>2015-10-23T03:05:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152132015243.L3m_MO_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/213/A20152132015243.L3m_MO_SST4_sst4_4km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1201145581-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1201145581-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152132015243.L3m_MO_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.2062</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205897682-OB_DAAC</id>
    <title type="text">A2015213.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-18T12:40:56.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015213.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205897682-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205897682-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015213.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.064777</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205897683-OB_DAAC</id>
    <title type="text">A2015213.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-18T12:40:56.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015213.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205897683-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205897683-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015213.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.588307</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205897819-OB_DAAC</id>
    <title type="text">A2015213.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-17T12:24:29.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015213.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205897819-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205897819-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015213.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.960207</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205897860-OB_DAAC</id>
    <title type="text">A2015213.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-17T12:24:29.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015213.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205897860-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205897860-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015213.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.45596</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205897862-OB_DAAC</id>
    <title type="text">A2015213.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-17T12:25:43.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015213.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205897862-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205897862-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015213.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.401943</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205897863-OB_DAAC</id>
    <title type="text">A2015213.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-17T12:25:43.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015213.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205897863-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205897863-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015213.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.002219</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205940030-OB_DAAC</id>
    <title type="text">A20152132015243.L3m_MO_NSST_sst_4km.nc</title>
    <updated>2015-09-20T04:36:48.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152132015243.L3m_MO_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/213/A20152132015243.L3m_MO_NSST_sst_4km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205940030-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205940030-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152132015243.L3m_MO_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.362785</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205940031-OB_DAAC</id>
    <title type="text">A20152132015243.L3m_MO_NSST_sst_9km.nc</title>
    <updated>2015-09-20T04:36:48.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152132015243.L3m_MO_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/213/A20152132015243.L3m_MO_NSST_sst_9km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205940031-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205940031-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152132015243.L3m_MO_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.8509</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205940043-OB_DAAC</id>
    <title type="text">A20152132015243.L3m_MO_SST_sst_4km.nc</title>
    <updated>2015-09-20T04:36:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152132015243.L3m_MO_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/213/A20152132015243.L3m_MO_SST_sst_4km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205940043-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205940043-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152132015243.L3m_MO_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>61.55374</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205940044-OB_DAAC</id>
    <title type="text">A20152132015243.L3m_MO_SST_sst_9km.nc</title>
    <updated>2015-09-20T04:36:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152132015243.L3m_MO_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/213/A20152132015243.L3m_MO_SST_sst_9km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205940044-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205940044-OB_DAAC</dc:identifier>
    <dc:date>2015-08-01T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152132015243.L3m_MO_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.494637</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205898642-OB_DAAC</id>
    <title type="text">A2015214.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-19T12:38:50.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015214.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205898642-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205898642-OB_DAAC</dc:identifier>
    <dc:date>2015-08-02T00:00:00.000Z/2015-08-02T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015214.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.843185</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205898643-OB_DAAC</id>
    <title type="text">A2015214.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-19T12:38:50.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015214.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205898643-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205898643-OB_DAAC</dc:identifier>
    <dc:date>2015-08-02T00:00:00.000Z/2015-08-02T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015214.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.514517</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205898872-OB_DAAC</id>
    <title type="text">A2015214.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-18T12:35:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015214.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205898872-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205898872-OB_DAAC</dc:identifier>
    <dc:date>2015-08-02T00:00:00.000Z/2015-08-02T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015214.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.800407</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205898873-OB_DAAC</id>
    <title type="text">A2015214.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-18T12:31:23.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015214.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205898873-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205898873-OB_DAAC</dc:identifier>
    <dc:date>2015-08-02T00:00:00.000Z/2015-08-02T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015214.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.08741</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205898891-OB_DAAC</id>
    <title type="text">A2015214.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-18T12:35:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015214.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205898891-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205898891-OB_DAAC</dc:identifier>
    <dc:date>2015-08-02T00:00:00.000Z/2015-08-02T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015214.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.061296</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205898892-OB_DAAC</id>
    <title type="text">A2015214.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-18T12:31:23.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015214.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205898892-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205898892-OB_DAAC</dc:identifier>
    <dc:date>2015-08-02T00:00:00.000Z/2015-08-02T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015214.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.728294</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205899593-OB_DAAC</id>
    <title type="text">A2015215.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-19T12:36:21.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015215.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205899593-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205899593-OB_DAAC</dc:identifier>
    <dc:date>2015-08-03T00:00:00.000Z/2015-08-03T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015215.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.607754</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205899606-OB_DAAC</id>
    <title type="text">A2015215.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-19T12:35:48.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015215.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205899606-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205899606-OB_DAAC</dc:identifier>
    <dc:date>2015-08-03T00:00:00.000Z/2015-08-03T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015215.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.50004</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205899607-OB_DAAC</id>
    <title type="text">A2015215.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-19T12:35:48.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015215.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205899607-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205899607-OB_DAAC</dc:identifier>
    <dc:date>2015-08-03T00:00:00.000Z/2015-08-03T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015215.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.019159</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205899630-OB_DAAC</id>
    <title type="text">A2015215.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-19T12:36:21.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015215.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205899630-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205899630-OB_DAAC</dc:identifier>
    <dc:date>2015-08-03T00:00:00.000Z/2015-08-03T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015215.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.996809</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205899894-OB_DAAC</id>
    <title type="text">A2015215.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-20T12:42:39.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015215.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205899894-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205899894-OB_DAAC</dc:identifier>
    <dc:date>2015-08-03T00:00:00.000Z/2015-08-03T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015215.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.871323</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205899895-OB_DAAC</id>
    <title type="text">A2015215.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-20T12:42:39.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015215.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205899895-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205899895-OB_DAAC</dc:identifier>
    <dc:date>2015-08-03T00:00:00.000Z/2015-08-03T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015215.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.512525</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205900145-OB_DAAC</id>
    <title type="text">A2015216.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-21T12:52:41.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015216.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205900145-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205900145-OB_DAAC</dc:identifier>
    <dc:date>2015-08-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015216.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.82604</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205900168-OB_DAAC</id>
    <title type="text">A2015216.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-21T12:52:41.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015216.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205900168-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205900168-OB_DAAC</dc:identifier>
    <dc:date>2015-08-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015216.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.509628</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205900358-OB_DAAC</id>
    <title type="text">A2015216.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-20T12:41:59.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015216.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205900358-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205900358-OB_DAAC</dc:identifier>
    <dc:date>2015-08-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015216.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.63804</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205900363-OB_DAAC</id>
    <title type="text">A2015216.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-20T12:41:32.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015216.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205900363-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205900363-OB_DAAC</dc:identifier>
    <dc:date>2015-08-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015216.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.465363</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205900364-OB_DAAC</id>
    <title type="text">A2015216.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-20T12:41:59.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015216.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205900364-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205900364-OB_DAAC</dc:identifier>
    <dc:date>2015-08-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015216.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.999377</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205900389-OB_DAAC</id>
    <title type="text">A2015216.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-20T12:41:32.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015216.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205900389-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205900389-OB_DAAC</dc:identifier>
    <dc:date>2015-08-04T00:00:00.000Z/2015-08-04T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015216.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.001931</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391477-OB_DAAC</id>
    <title type="text">A20152172015224.L3m_8D_NSST_sst_4km.nc</title>
    <updated>2015-08-28T05:16:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015224.L3m_8D_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391477-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391477-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015224.L3m_8D_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>59.75887</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391478-OB_DAAC</id>
    <title type="text">A20152172015224.L3m_8D_NSST_sst_9km.nc</title>
    <updated>2015-08-28T05:16:29.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015224.L3m_8D_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391478-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391478-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015224.L3m_8D_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>15.87201</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391501-OB_DAAC</id>
    <title type="text">A20152172015224.L3m_8D_SST4_sst4_4km.nc</title>
    <updated>2015-08-28T05:16:31.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015224.L3m_8D_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391501-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391501-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015224.L3m_8D_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>59.76212</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391520-OB_DAAC</id>
    <title type="text">A20152172015224.L3m_8D_SST4_sst4_9km.nc</title>
    <updated>2015-08-28T05:16:31.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015224.L3m_8D_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391520-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391520-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015224.L3m_8D_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>15.888022</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203399654-OB_DAAC</id>
    <title type="text">A20152172015248.L3m_R32_SST_sst_4km.nc</title>
    <updated>2015-09-23T02:54:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015248.L3m_R32_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203399654-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203399654-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015248.L3m_R32_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>61.667854</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203399666-OB_DAAC</id>
    <title type="text">A20152172015248.L3m_R32_SST_sst_9km.nc</title>
    <updated>2015-09-23T02:54:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015248.L3m_R32_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203399666-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203399666-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015248.L3m_R32_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.522264</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203399907-OB_DAAC</id>
    <title type="text">A20152172015248.L3m_R32_NSST_sst_9km.nc</title>
    <updated>2015-09-23T06:53:33.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015248.L3m_R32_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203399907-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203399907-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015248.L3m_R32_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.904346</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203399923-OB_DAAC</id>
    <title type="text">A20152172015248.L3m_R32_SST4_sst4_4km.nc</title>
    <updated>2015-09-23T06:53:34.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015248.L3m_R32_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203399923-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203399923-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015248.L3m_R32_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.279446</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203399924-OB_DAAC</id>
    <title type="text">A20152172015248.L3m_R32_NSST_sst_4km.nc</title>
    <updated>2015-09-23T06:53:33.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015248.L3m_R32_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203399924-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203399924-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015248.L3m_R32_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.454475</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203399940-OB_DAAC</id>
    <title type="text">A20152172015248.L3m_R32_SST4_sst4_9km.nc</title>
    <updated>2015-09-23T06:53:34.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015248.L3m_R32_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203399940-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203399940-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015248.L3m_R32_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.889235</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203496008-OB_DAAC</id>
    <title type="text">A20152172015224.L3m_8D_SST_sst_4km.nc</title>
    <updated>2015-08-29T06:12:43.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015224.L3m_8D_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203496008-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203496008-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015224.L3m_8D_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>56.355152</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203496009-OB_DAAC</id>
    <title type="text">A20152172015224.L3m_8D_SST_sst_9km.nc</title>
    <updated>2015-08-29T06:12:43.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152172015224.L3m_8D_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203496009-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203496009-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152172015224.L3m_8D_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>15.040295</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205865307-OB_DAAC</id>
    <title type="text">A2015217.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-21T12:51:27.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015217.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205865307-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205865307-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015217.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.528904</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205865308-OB_DAAC</id>
    <title type="text">A2015217.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-21T12:51:27.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015217.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205865308-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205865308-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015217.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.044106</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205865343-OB_DAAC</id>
    <title type="text">A2015217.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-21T12:48:26.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015217.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205865343-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205865343-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015217.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.633896</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205865361-OB_DAAC</id>
    <title type="text">A2015217.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-21T12:48:26.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015217.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205865361-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205865361-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015217.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.020662</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205901202-OB_DAAC</id>
    <title type="text">A2015217.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-22T12:58:34.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015217.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205901202-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205901202-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015217.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.80661</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205901203-OB_DAAC</id>
    <title type="text">A2015217.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-22T12:58:34.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015217.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205901203-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205901203-OB_DAAC</dc:identifier>
    <dc:date>2015-08-05T00:00:00.000Z/2015-08-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015217.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.497129</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205901746-OB_DAAC</id>
    <title type="text">A2015218.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-22T01:19:33.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015218.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205901746-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205901746-OB_DAAC</dc:identifier>
    <dc:date>2015-08-06T00:00:00.000Z/2015-08-06T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015218.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.633915</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205901789-OB_DAAC</id>
    <title type="text">A2015218.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-22T01:04:07.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015218.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205901789-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205901789-OB_DAAC</dc:identifier>
    <dc:date>2015-08-06T00:00:00.000Z/2015-08-06T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015218.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.513</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205901800-OB_DAAC</id>
    <title type="text">A2015218.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-22T01:04:07.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015218.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205901800-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205901800-OB_DAAC</dc:identifier>
    <dc:date>2015-08-06T00:00:00.000Z/2015-08-06T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015218.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.040764</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205901804-OB_DAAC</id>
    <title type="text">A2015218.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-22T01:19:33.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015218.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205901804-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205901804-OB_DAAC</dc:identifier>
    <dc:date>2015-08-06T00:00:00.000Z/2015-08-06T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015218.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.021427</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205902089-OB_DAAC</id>
    <title type="text">A2015218.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-23T01:03:57.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015218.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205902089-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205902089-OB_DAAC</dc:identifier>
    <dc:date>2015-08-06T00:00:00.000Z/2015-08-06T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015218.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.949013</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205902090-OB_DAAC</id>
    <title type="text">A2015218.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-23T01:03:57.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015218.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205902090-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205902090-OB_DAAC</dc:identifier>
    <dc:date>2015-08-06T00:00:00.000Z/2015-08-06T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015218.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.544888</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205902678-OB_DAAC</id>
    <title type="text">A2015219.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-23T01:02:56.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015219.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205902678-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205902678-OB_DAAC</dc:identifier>
    <dc:date>2015-08-07T00:00:00.000Z/2015-08-07T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015219.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.937566</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205902691-OB_DAAC</id>
    <title type="text">A2015219.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-23T01:02:56.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015219.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205902691-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205902691-OB_DAAC</dc:identifier>
    <dc:date>2015-08-07T00:00:00.000Z/2015-08-07T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015219.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.310703</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205902706-OB_DAAC</id>
    <title type="text">A2015219.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-23T01:03:39.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015219.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205902706-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205902706-OB_DAAC</dc:identifier>
    <dc:date>2015-08-07T00:00:00.000Z/2015-08-07T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015219.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.20556</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205902720-OB_DAAC</id>
    <title type="text">A2015219.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-23T01:03:39.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015219.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205902720-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205902720-OB_DAAC</dc:identifier>
    <dc:date>2015-08-07T00:00:00.000Z/2015-08-07T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015219.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.959114</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205902964-OB_DAAC</id>
    <title type="text">A2015219.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-24T01:14:56.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015219.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205902964-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205902964-OB_DAAC</dc:identifier>
    <dc:date>2015-08-07T00:00:00.000Z/2015-08-07T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015219.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.30058</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205903011-OB_DAAC</id>
    <title type="text">A2015219.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-24T01:14:56.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015219.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205903011-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205903011-OB_DAAC</dc:identifier>
    <dc:date>2015-08-07T00:00:00.000Z/2015-08-07T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015219.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.352206</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205903685-OB_DAAC</id>
    <title type="text">A2015220.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-25T01:22:49.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015220.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205903685-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205903685-OB_DAAC</dc:identifier>
    <dc:date>2015-08-08T00:00:00.000Z/2015-08-08T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015220.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.372913</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205903704-OB_DAAC</id>
    <title type="text">A2015220.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-25T01:22:49.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015220.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205903704-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205903704-OB_DAAC</dc:identifier>
    <dc:date>2015-08-08T00:00:00.000Z/2015-08-08T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015220.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.367941</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205903789-OB_DAAC</id>
    <title type="text">A2015220.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-24T01:14:01.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015220.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205903789-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205903789-OB_DAAC</dc:identifier>
    <dc:date>2015-08-08T00:00:00.000Z/2015-08-08T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015220.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.898537</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205903829-OB_DAAC</id>
    <title type="text">A2015220.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-24T01:24:12.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015220.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205903829-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205903829-OB_DAAC</dc:identifier>
    <dc:date>2015-08-08T00:00:00.000Z/2015-08-08T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015220.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.76834</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205903830-OB_DAAC</id>
    <title type="text">A2015220.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-24T01:24:12.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015220.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205903830-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205903830-OB_DAAC</dc:identifier>
    <dc:date>2015-08-08T00:00:00.000Z/2015-08-08T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015220.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.829232</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205903845-OB_DAAC</id>
    <title type="text">A2015220.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-24T01:14:01.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015220.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205903845-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205903845-OB_DAAC</dc:identifier>
    <dc:date>2015-08-08T00:00:00.000Z/2015-08-08T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015220.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.814727</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205904967-OB_DAAC</id>
    <title type="text">A2015221.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-25T01:33:21.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015221.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205904967-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205904967-OB_DAAC</dc:identifier>
    <dc:date>2015-08-09T00:00:00.000Z/2015-08-09T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015221.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.007374</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205904970-OB_DAAC</id>
    <title type="text">A2015221.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-25T01:21:16.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015221.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205904970-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205904970-OB_DAAC</dc:identifier>
    <dc:date>2015-08-09T00:00:00.000Z/2015-08-09T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015221.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.893118</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205904971-OB_DAAC</id>
    <title type="text">A2015221.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-26T01:21:25.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015221.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205904971-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205904971-OB_DAAC</dc:identifier>
    <dc:date>2015-08-09T00:00:00.000Z/2015-08-09T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015221.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.331479</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205904982-OB_DAAC</id>
    <title type="text">A2015221.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-25T01:33:21.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015221.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205904982-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205904982-OB_DAAC</dc:identifier>
    <dc:date>2015-08-09T00:00:00.000Z/2015-08-09T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015221.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.905902</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205904983-OB_DAAC</id>
    <title type="text">A2015221.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-25T01:21:16.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015221.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205904983-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205904983-OB_DAAC</dc:identifier>
    <dc:date>2015-08-09T00:00:00.000Z/2015-08-09T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015221.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.11525</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205904984-OB_DAAC</id>
    <title type="text">A2015221.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-26T01:21:25.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015221.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205904984-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205904984-OB_DAAC</dc:identifier>
    <dc:date>2015-08-09T00:00:00.000Z/2015-08-09T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015221.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.183987</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205905605-OB_DAAC</id>
    <title type="text">A2015222.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-26T09:43:53.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015222.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205905605-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205905605-OB_DAAC</dc:identifier>
    <dc:date>2015-08-10T00:00:00.000Z/2015-08-10T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015222.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.467785</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205905625-OB_DAAC</id>
    <title type="text">A2015222.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-26T09:43:53.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015222.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205905625-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205905625-OB_DAAC</dc:identifier>
    <dc:date>2015-08-10T00:00:00.000Z/2015-08-10T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015222.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.420218</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205905730-OB_DAAC</id>
    <title type="text">A2015222.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-26T01:21:54.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015222.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205905730-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205905730-OB_DAAC</dc:identifier>
    <dc:date>2015-08-10T00:00:00.000Z/2015-08-10T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015222.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.94301</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205905732-OB_DAAC</id>
    <title type="text">A2015222.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-26T01:22:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015222.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205905732-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205905732-OB_DAAC</dc:identifier>
    <dc:date>2015-08-10T00:00:00.000Z/2015-08-10T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015222.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.80499</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205905733-OB_DAAC</id>
    <title type="text">A2015222.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-26T01:22:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015222.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205905733-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205905733-OB_DAAC</dc:identifier>
    <dc:date>2015-08-10T00:00:00.000Z/2015-08-10T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015222.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.864875</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205905748-OB_DAAC</id>
    <title type="text">A2015222.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-26T01:21:54.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015222.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205905748-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205905748-OB_DAAC</dc:identifier>
    <dc:date>2015-08-10T00:00:00.000Z/2015-08-10T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015222.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.85462</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205906605-OB_DAAC</id>
    <title type="text">A2015223.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-26T09:39:27.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015223.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205906605-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205906605-OB_DAAC</dc:identifier>
    <dc:date>2015-08-11T00:00:00.000Z/2015-08-11T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015223.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.208946</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205906630-OB_DAAC</id>
    <title type="text">A2015223.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-26T09:39:27.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015223.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205906630-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205906630-OB_DAAC</dc:identifier>
    <dc:date>2015-08-11T00:00:00.000Z/2015-08-11T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015223.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.915194</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205906641-OB_DAAC</id>
    <title type="text">A2015223.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-26T09:37:00.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015223.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205906641-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205906641-OB_DAAC</dc:identifier>
    <dc:date>2015-08-11T00:00:00.000Z/2015-08-11T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015223.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.136806</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205906642-OB_DAAC</id>
    <title type="text">A2015223.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-26T09:37:00.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015223.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205906642-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205906642-OB_DAAC</dc:identifier>
    <dc:date>2015-08-11T00:00:00.000Z/2015-08-11T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015223.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.943615</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205906881-OB_DAAC</id>
    <title type="text">A2015223.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-27T09:25:32.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015223.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205906881-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205906881-OB_DAAC</dc:identifier>
    <dc:date>2015-08-11T00:00:00.000Z/2015-08-11T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015223.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.748917</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205906882-OB_DAAC</id>
    <title type="text">A2015223.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-27T09:25:32.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015223.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205906882-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205906882-OB_DAAC</dc:identifier>
    <dc:date>2015-08-11T00:00:00.000Z/2015-08-11T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015223.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.497289</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205907527-OB_DAAC</id>
    <title type="text">A2015224.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-27T09:25:41.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015224.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205907527-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205907527-OB_DAAC</dc:identifier>
    <dc:date>2015-08-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015224.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.493393</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205907532-OB_DAAC</id>
    <title type="text">A2015224.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-27T09:25:49.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015224.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205907532-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205907532-OB_DAAC</dc:identifier>
    <dc:date>2015-08-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015224.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.554504</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205907550-OB_DAAC</id>
    <title type="text">A2015224.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-27T09:25:49.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015224.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205907550-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205907550-OB_DAAC</dc:identifier>
    <dc:date>2015-08-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015224.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.023858</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205907561-OB_DAAC</id>
    <title type="text">A2015224.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-27T09:25:41.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015224.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205907561-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205907561-OB_DAAC</dc:identifier>
    <dc:date>2015-08-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015224.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.05615</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205907734-OB_DAAC</id>
    <title type="text">A2015224.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-28T02:20:04.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015224.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205907734-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205907734-OB_DAAC</dc:identifier>
    <dc:date>2015-08-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015224.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.588292</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205907746-OB_DAAC</id>
    <title type="text">A2015224.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-28T02:20:04.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015224.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205907746-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205907746-OB_DAAC</dc:identifier>
    <dc:date>2015-08-12T00:00:00.000Z/2015-08-12T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015224.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.04985</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205909571-OB_DAAC</id>
    <title type="text">A2015225.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-29T02:33:04.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015225.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205909571-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205909571-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015225.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.82769</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205909572-OB_DAAC</id>
    <title type="text">A2015225.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-29T02:33:04.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015225.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205909572-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205909572-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015225.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.511603</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205909703-OB_DAAC</id>
    <title type="text">A2015225.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-28T02:20:05.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015225.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205909703-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205909703-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015225.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.08219</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205909750-OB_DAAC</id>
    <title type="text">A2015225.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-28T02:20:05.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015225.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205909750-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205909750-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015225.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.646873</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205909751-OB_DAAC</id>
    <title type="text">A2015225.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-28T02:16:25.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015225.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205909751-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205909751-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015225.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.759766</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205909752-OB_DAAC</id>
    <title type="text">A2015225.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-28T02:16:25.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015225.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205909752-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205909752-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015225.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.06696</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205926285-OB_DAAC</id>
    <title type="text">A20152252015232.L3m_8D_NSST_sst_4km.nc</title>
    <updated>2015-09-05T07:00:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015232.L3m_8D_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205926285-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205926285-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015232.L3m_8D_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>60.30428</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205926286-OB_DAAC</id>
    <title type="text">A20152252015232.L3m_8D_NSST_sst_9km.nc</title>
    <updated>2015-09-05T07:00:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015232.L3m_8D_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205926286-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205926286-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015232.L3m_8D_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.060673</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205926288-OB_DAAC</id>
    <title type="text">A20152252015232.L3m_8D_SST4_sst4_4km.nc</title>
    <updated>2015-09-05T07:00:34.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015232.L3m_8D_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205926288-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205926288-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015232.L3m_8D_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>60.336937</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205926289-OB_DAAC</id>
    <title type="text">A20152252015232.L3m_8D_SST4_sst4_9km.nc</title>
    <updated>2015-09-05T07:00:34.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015232.L3m_8D_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205926289-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205926289-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015232.L3m_8D_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.088598</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205929924-OB_DAAC</id>
    <title type="text">A20152252015232.L3m_8D_SST_sst_4km.nc</title>
    <updated>2015-09-09T07:29:51.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015232.L3m_8D_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205929924-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205929924-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015232.L3m_8D_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>57.07992</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205929954-OB_DAAC</id>
    <title type="text">A20152252015232.L3m_8D_SST_sst_9km.nc</title>
    <updated>2015-09-09T07:29:51.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015232.L3m_8D_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205929954-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205929954-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015232.L3m_8D_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>15.216277</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205940795-OB_DAAC</id>
    <title type="text">A20152252015256.L3m_R32_NSST_sst_4km.nc</title>
    <updated>2015-09-30T07:44:14.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015256.L3m_R32_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205940795-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205940795-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-09-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015256.L3m_R32_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.572994</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205940804-OB_DAAC</id>
    <title type="text">A20152252015256.L3m_R32_SST4_sst4_4km.nc</title>
    <updated>2015-09-30T07:44:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015256.L3m_R32_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205940804-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205940804-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-09-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015256.L3m_R32_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.386074</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205940805-OB_DAAC</id>
    <title type="text">A20152252015256.L3m_R32_SST4_sst4_9km.nc</title>
    <updated>2015-09-30T07:44:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015256.L3m_R32_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205940805-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205940805-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-09-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015256.L3m_R32_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.958838</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205940822-OB_DAAC</id>
    <title type="text">A20152252015256.L3m_R32_NSST_sst_9km.nc</title>
    <updated>2015-09-30T07:44:14.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015256.L3m_R32_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205940822-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205940822-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-09-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015256.L3m_R32_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.980017</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205940992-OB_DAAC</id>
    <title type="text">A20152252015256.L3m_R32_SST_sst_4km.nc</title>
    <updated>2015-10-07T04:24:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015256.L3m_R32_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205940992-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205940992-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-09-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015256.L3m_R32_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>61.872185</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205941002-OB_DAAC</id>
    <title type="text">A20152252015256.L3m_R32_SST_sst_9km.nc</title>
    <updated>2015-10-07T04:24:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152252015256.L3m_R32_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205941002-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205941002-OB_DAAC</dc:identifier>
    <dc:date>2015-08-13T00:00:00.000Z/2015-09-13T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152252015256.L3m_R32_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.560347</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205910510-OB_DAAC</id>
    <title type="text">A2015226.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-29T02:31:35.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015226.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205910510-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205910510-OB_DAAC</dc:identifier>
    <dc:date>2015-08-14T00:00:00.000Z/2015-08-14T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015226.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.953089</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205910511-OB_DAAC</id>
    <title type="text">A2015226.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-29T02:29:44.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015226.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205910511-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205910511-OB_DAAC</dc:identifier>
    <dc:date>2015-08-14T00:00:00.000Z/2015-08-14T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015226.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.204433</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205910520-OB_DAAC</id>
    <title type="text">A2015226.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-29T02:31:35.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015226.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205910520-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205910520-OB_DAAC</dc:identifier>
    <dc:date>2015-08-14T00:00:00.000Z/2015-08-14T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015226.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.140053</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205910521-OB_DAAC</id>
    <title type="text">A2015226.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-29T02:29:45.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015226.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205910521-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205910521-OB_DAAC</dc:identifier>
    <dc:date>2015-08-14T00:00:00.000Z/2015-08-14T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015226.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.921341</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205910797-OB_DAAC</id>
    <title type="text">A2015226.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-31T07:38:53.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015226.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205910797-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205910797-OB_DAAC</dc:identifier>
    <dc:date>2015-08-14T00:00:00.000Z/2015-08-14T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015226.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.02002</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205910798-OB_DAAC</id>
    <title type="text">A2015226.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-31T07:38:53.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015226.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205910798-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205910798-OB_DAAC</dc:identifier>
    <dc:date>2015-08-14T00:00:00.000Z/2015-08-14T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015226.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.591124</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205911375-OB_DAAC</id>
    <title type="text">A2015227.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-08-31T03:03:07.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015227.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205911375-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205911375-OB_DAAC</dc:identifier>
    <dc:date>2015-08-15T00:00:00.000Z/2015-08-15T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015227.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.915783</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205911402-OB_DAAC</id>
    <title type="text">A2015227.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-08-31T03:03:07.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015227.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205911402-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205911402-OB_DAAC</dc:identifier>
    <dc:date>2015-08-15T00:00:00.000Z/2015-08-15T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015227.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.551453</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205911491-OB_DAAC</id>
    <title type="text">A2015227.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-31T02:44:53.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015227.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205911491-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205911491-OB_DAAC</dc:identifier>
    <dc:date>2015-08-15T00:00:00.000Z/2015-08-15T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015227.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.544186</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205911492-OB_DAAC</id>
    <title type="text">A2015227.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-31T02:45:49.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015227.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205911492-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205911492-OB_DAAC</dc:identifier>
    <dc:date>2015-08-15T00:00:00.000Z/2015-08-15T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015227.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.641068</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205911493-OB_DAAC</id>
    <title type="text">A2015227.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-31T02:45:49.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015227.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205911493-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205911493-OB_DAAC</dc:identifier>
    <dc:date>2015-08-15T00:00:00.000Z/2015-08-15T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015227.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.038805</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205911502-OB_DAAC</id>
    <title type="text">A2015227.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-31T02:44:53.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015227.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205911502-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205911502-OB_DAAC</dc:identifier>
    <dc:date>2015-08-15T00:00:00.000Z/2015-08-15T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015227.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.063939</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205912302-OB_DAAC</id>
    <title type="text">A2015228.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-08-31T02:42:21.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015228.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205912302-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205912302-OB_DAAC</dc:identifier>
    <dc:date>2015-08-16T00:00:00.000Z/2015-08-16T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015228.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.805016</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205912325-OB_DAAC</id>
    <title type="text">A2015228.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-08-31T02:42:21.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015228.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205912325-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205912325-OB_DAAC</dc:identifier>
    <dc:date>2015-08-16T00:00:00.000Z/2015-08-16T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015228.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.160954</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205912349-OB_DAAC</id>
    <title type="text">A2015228.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-08-31T02:47:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015228.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205912349-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205912349-OB_DAAC</dc:identifier>
    <dc:date>2015-08-16T00:00:00.000Z/2015-08-16T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015228.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.88414</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205912350-OB_DAAC</id>
    <title type="text">A2015228.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-08-31T02:47:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015228.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205912350-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205912350-OB_DAAC</dc:identifier>
    <dc:date>2015-08-16T00:00:00.000Z/2015-08-16T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015228.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.134167</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205912612-OB_DAAC</id>
    <title type="text">A2015228.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-01T02:44:29.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015228.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205912612-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205912612-OB_DAAC</dc:identifier>
    <dc:date>2015-08-16T00:00:00.000Z/2015-08-16T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015228.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.571289</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205912631-OB_DAAC</id>
    <title type="text">A2015228.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-01T02:44:29.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015228.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205912631-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205912631-OB_DAAC</dc:identifier>
    <dc:date>2015-08-16T00:00:00.000Z/2015-08-16T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015228.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.956066</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205913202-OB_DAAC</id>
    <title type="text">A2015229.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-02T10:55:14.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015229.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205913202-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205913202-OB_DAAC</dc:identifier>
    <dc:date>2015-08-17T00:00:00.000Z/2015-08-17T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015229.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.911602</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205913203-OB_DAAC</id>
    <title type="text">A2015229.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-02T10:55:14.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015229.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205913203-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205913203-OB_DAAC</dc:identifier>
    <dc:date>2015-08-17T00:00:00.000Z/2015-08-17T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015229.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.551615</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205913364-OB_DAAC</id>
    <title type="text">A2015229.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-01T02:45:30.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015229.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205913364-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205913364-OB_DAAC</dc:identifier>
    <dc:date>2015-08-17T00:00:00.000Z/2015-08-17T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015229.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.097142</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205913385-OB_DAAC</id>
    <title type="text">A2015229.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-01T02:45:30.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015229.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205913385-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205913385-OB_DAAC</dc:identifier>
    <dc:date>2015-08-17T00:00:00.000Z/2015-08-17T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015229.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.756443</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205913388-OB_DAAC</id>
    <title type="text">A2015229.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-01T10:48:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015229.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205913388-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205913388-OB_DAAC</dc:identifier>
    <dc:date>2015-08-17T00:00:00.000Z/2015-08-17T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015229.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.727146</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205913389-OB_DAAC</id>
    <title type="text">A2015229.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-01T10:48:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015229.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205913389-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205913389-OB_DAAC</dc:identifier>
    <dc:date>2015-08-17T00:00:00.000Z/2015-08-17T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015229.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.13836</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205914288-OB_DAAC</id>
    <title type="text">A2015230.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-03T11:01:06.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015230.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205914288-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205914288-OB_DAAC</dc:identifier>
    <dc:date>2015-08-18T00:00:00.000Z/2015-08-18T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015230.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.463649</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205914304-OB_DAAC</id>
    <title type="text">A2015230.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-03T11:01:06.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015230.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205914304-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205914304-OB_DAAC</dc:identifier>
    <dc:date>2015-08-18T00:00:00.000Z/2015-08-18T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015230.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.66657</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205914414-OB_DAAC</id>
    <title type="text">A2015230.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-02T10:54:38.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015230.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205914414-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205914414-OB_DAAC</dc:identifier>
    <dc:date>2015-08-18T00:00:00.000Z/2015-08-18T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015230.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.119451</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205914415-OB_DAAC</id>
    <title type="text">A2015230.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-02T10:54:00.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015230.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205914415-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205914415-OB_DAAC</dc:identifier>
    <dc:date>2015-08-18T00:00:00.000Z/2015-08-18T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015230.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.681465</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205914416-OB_DAAC</id>
    <title type="text">A2015230.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-02T10:54:00.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015230.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205914416-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205914416-OB_DAAC</dc:identifier>
    <dc:date>2015-08-18T00:00:00.000Z/2015-08-18T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015230.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.081105</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205914421-OB_DAAC</id>
    <title type="text">A2015230.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-02T10:54:38.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015230.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205914421-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205914421-OB_DAAC</dc:identifier>
    <dc:date>2015-08-18T00:00:00.000Z/2015-08-18T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015230.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.659107</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915259-OB_DAAC</id>
    <title type="text">A2015231.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-03T11:01:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015231.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915259-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915259-OB_DAAC</dc:identifier>
    <dc:date>2015-08-19T00:00:00.000Z/2015-08-19T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015231.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.497505</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915262-OB_DAAC</id>
    <title type="text">A2015231.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-03T11:02:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015231.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915262-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915262-OB_DAAC</dc:identifier>
    <dc:date>2015-08-19T00:00:00.000Z/2015-08-19T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015231.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.996923</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915280-OB_DAAC</id>
    <title type="text">A2015231.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-03T11:01:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015231.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915280-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915280-OB_DAAC</dc:identifier>
    <dc:date>2015-08-19T00:00:00.000Z/2015-08-19T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015231.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.057557</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915282-OB_DAAC</id>
    <title type="text">A2015231.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-03T11:02:15.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015231.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915282-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915282-OB_DAAC</dc:identifier>
    <dc:date>2015-08-19T00:00:00.000Z/2015-08-19T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015231.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.48206</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915532-OB_DAAC</id>
    <title type="text">A2015231.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-04T11:10:47.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015231.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915532-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915532-OB_DAAC</dc:identifier>
    <dc:date>2015-08-19T00:00:00.000Z/2015-08-19T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015231.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.865585</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205915533-OB_DAAC</id>
    <title type="text">A2015231.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-04T11:10:47.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015231.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205915533-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205915533-OB_DAAC</dc:identifier>
    <dc:date>2015-08-19T00:00:00.000Z/2015-08-19T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015231.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.519586</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205916319-OB_DAAC</id>
    <title type="text">A2015232.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-04T11:11:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015232.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205916319-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205916319-OB_DAAC</dc:identifier>
    <dc:date>2015-08-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015232.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.81371</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205916323-OB_DAAC</id>
    <title type="text">A2015232.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-08T03:41:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015232.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205916323-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205916323-OB_DAAC</dc:identifier>
    <dc:date>2015-08-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015232.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.529885</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205916344-OB_DAAC</id>
    <title type="text">A2015232.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-04T11:10:57.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015232.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205916344-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205916344-OB_DAAC</dc:identifier>
    <dc:date>2015-08-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015232.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.822144</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205916345-OB_DAAC</id>
    <title type="text">A2015232.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-04T11:10:57.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015232.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205916345-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205916345-OB_DAAC</dc:identifier>
    <dc:date>2015-08-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015232.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.117651</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205916346-OB_DAAC</id>
    <title type="text">A2015232.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-04T11:11:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015232.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205916346-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205916346-OB_DAAC</dc:identifier>
    <dc:date>2015-08-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015232.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.170815</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205916526-OB_DAAC</id>
    <title type="text">A2015232.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-08T03:41:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015232.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205916526-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205916526-OB_DAAC</dc:identifier>
    <dc:date>2015-08-20T00:00:00.000Z/2015-08-20T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015232.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.827084</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205917129-OB_DAAC</id>
    <title type="text">A2015233.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-08T03:38:46.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015233.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205917129-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205917129-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015233.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.437214</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205917146-OB_DAAC</id>
    <title type="text">A2015233.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-08T03:38:46.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015233.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205917146-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205917146-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015233.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.006186</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205917147-OB_DAAC</id>
    <title type="text">A2015233.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-08T03:33:22.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015233.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205917147-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205917147-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015233.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.383427</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205917148-OB_DAAC</id>
    <title type="text">A2015233.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-08T03:33:22.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015233.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205917148-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205917148-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015233.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.043414</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205917394-OB_DAAC</id>
    <title type="text">A2015233.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-08T03:40:41.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015233.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205917394-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205917394-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015233.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.868534</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205917395-OB_DAAC</id>
    <title type="text">A2015233.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-08T03:40:41.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015233.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205917395-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205917395-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015233.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.544623</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205935576-OB_DAAC</id>
    <title type="text">A20152332015240.L3m_8D_SST4_sst4_4km.nc</title>
    <updated>2015-09-13T07:54:58.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015240.L3m_8D_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205935576-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205935576-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015240.L3m_8D_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>60.227066</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205935579-OB_DAAC</id>
    <title type="text">A20152332015240.L3m_8D_SST4_sst4_9km.nc</title>
    <updated>2015-09-13T07:54:58.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015240.L3m_8D_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205935579-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205935579-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015240.L3m_8D_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.105076</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205935582-OB_DAAC</id>
    <title type="text">A20152332015240.L3m_8D_NSST_sst_4km.nc</title>
    <updated>2015-09-13T07:55:04.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015240.L3m_8D_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205935582-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205935582-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015240.L3m_8D_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>60.07075</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205935585-OB_DAAC</id>
    <title type="text">A20152332015240.L3m_8D_NSST_sst_9km.nc</title>
    <updated>2015-09-13T07:55:04.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015240.L3m_8D_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205935585-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205935585-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015240.L3m_8D_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.037455</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205936816-OB_DAAC</id>
    <title type="text">A20152332015240.L3m_8D_SST_sst_4km.nc</title>
    <updated>2015-09-14T08:01:35.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015240.L3m_8D_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205936816-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205936816-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015240.L3m_8D_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>57.16167</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205936817-OB_DAAC</id>
    <title type="text">A20152332015240.L3m_8D_SST_sst_9km.nc</title>
    <updated>2015-09-14T08:01:35.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015240.L3m_8D_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205936817-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205936817-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015240.L3m_8D_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>15.254972</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009052-OB_DAAC</id>
    <title type="text">A20152332015264.L3m_R32_SST_sst_4km.nc</title>
    <updated>2015-10-14T05:09:27.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015264.L3m_R32_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009052-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009052-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-09-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015264.L3m_R32_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>61.97753</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009053-OB_DAAC</id>
    <title type="text">A20152332015264.L3m_R32_SST_sst_9km.nc</title>
    <updated>2015-10-14T05:09:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015264.L3m_R32_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009053-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009053-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-09-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015264.L3m_R32_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.575676</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009057-OB_DAAC</id>
    <title type="text">A20152332015264.L3m_R32_SST4_sst4_4km.nc</title>
    <updated>2015-10-14T09:10:25.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015264.L3m_R32_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009057-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009057-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-09-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015264.L3m_R32_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.39804</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009058-OB_DAAC</id>
    <title type="text">A20152332015264.L3m_R32_SST4_sst4_9km.nc</title>
    <updated>2015-10-14T09:10:26.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015264.L3m_R32_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009058-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009058-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-09-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015264.L3m_R32_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.980858</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009063-OB_DAAC</id>
    <title type="text">A20152332015264.L3m_R32_NSST_sst_4km.nc</title>
    <updated>2015-10-14T09:11:13.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015264.L3m_R32_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009063-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009063-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-09-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015264.L3m_R32_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.59221</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009080-OB_DAAC</id>
    <title type="text">A20152332015264.L3m_R32_NSST_sst_9km.nc</title>
    <updated>2015-10-14T09:11:14.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152332015264.L3m_R32_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009080-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009080-OB_DAAC</dc:identifier>
    <dc:date>2015-08-21T00:00:00.000Z/2015-09-21T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152332015264.L3m_R32_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.006454</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205917843-OB_DAAC</id>
    <title type="text">A2015234.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-08T03:39:03.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015234.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205917843-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205917843-OB_DAAC</dc:identifier>
    <dc:date>2015-08-22T00:00:00.000Z/2015-08-22T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015234.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.530808</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205917866-OB_DAAC</id>
    <title type="text">A2015234.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-08T03:39:03.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015234.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205917866-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205917866-OB_DAAC</dc:identifier>
    <dc:date>2015-08-22T00:00:00.000Z/2015-08-22T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015234.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.81227</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205918029-OB_DAAC</id>
    <title type="text">A2015234.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-08T03:52:50.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015234.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205918029-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205918029-OB_DAAC</dc:identifier>
    <dc:date>2015-08-22T00:00:00.000Z/2015-08-22T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015234.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.97779</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205918032-OB_DAAC</id>
    <title type="text">A2015234.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-08T03:40:57.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015234.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205918032-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205918032-OB_DAAC</dc:identifier>
    <dc:date>2015-08-22T00:00:00.000Z/2015-08-22T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015234.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.36548</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205918050-OB_DAAC</id>
    <title type="text">A2015234.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-08T03:52:50.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015234.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205918050-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205918050-OB_DAAC</dc:identifier>
    <dc:date>2015-08-22T00:00:00.000Z/2015-08-22T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015234.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.42723</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205918053-OB_DAAC</id>
    <title type="text">A2015234.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-08T03:40:57.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015234.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205918053-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205918053-OB_DAAC</dc:identifier>
    <dc:date>2015-08-22T00:00:00.000Z/2015-08-22T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015234.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.019743</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919030-OB_DAAC</id>
    <title type="text">A2015235.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-08T03:50:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015235.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919030-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919030-OB_DAAC</dc:identifier>
    <dc:date>2015-08-23T00:00:00.000Z/2015-08-23T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015235.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.68291</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919040-OB_DAAC</id>
    <title type="text">A2015235.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-08T03:50:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015235.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919040-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919040-OB_DAAC</dc:identifier>
    <dc:date>2015-08-23T00:00:00.000Z/2015-08-23T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015235.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.488997</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919096-OB_DAAC</id>
    <title type="text">A2015235.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-08T03:41:20.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015235.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919096-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919096-OB_DAAC</dc:identifier>
    <dc:date>2015-08-23T00:00:00.000Z/2015-08-23T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015235.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.037792</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919149-OB_DAAC</id>
    <title type="text">A2015235.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-08T03:41:20.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015235.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919149-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919149-OB_DAAC</dc:identifier>
    <dc:date>2015-08-23T00:00:00.000Z/2015-08-23T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015235.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.354725</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919151-OB_DAAC</id>
    <title type="text">A2015235.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-08T03:50:36.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015235.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919151-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919151-OB_DAAC</dc:identifier>
    <dc:date>2015-08-23T00:00:00.000Z/2015-08-23T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015235.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.417973</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919152-OB_DAAC</id>
    <title type="text">A2015235.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-08T03:50:36.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015235.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919152-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919152-OB_DAAC</dc:identifier>
    <dc:date>2015-08-23T00:00:00.000Z/2015-08-23T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015235.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.997951</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919856-OB_DAAC</id>
    <title type="text">A2015236.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-09T11:47:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015236.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919856-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919856-OB_DAAC</dc:identifier>
    <dc:date>2015-08-24T00:00:00.000Z/2015-08-24T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015236.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.516687</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919901-OB_DAAC</id>
    <title type="text">A2015236.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-09T11:47:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015236.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919901-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919901-OB_DAAC</dc:identifier>
    <dc:date>2015-08-24T00:00:00.000Z/2015-08-24T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015236.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.8424</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919925-OB_DAAC</id>
    <title type="text">A2015236.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-08T03:55:14.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015236.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919925-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919925-OB_DAAC</dc:identifier>
    <dc:date>2015-08-24T00:00:00.000Z/2015-08-24T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015236.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.457153</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205919999-OB_DAAC</id>
    <title type="text">A2015236.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-08T03:41:31.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015236.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205919999-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205919999-OB_DAAC</dc:identifier>
    <dc:date>2015-08-24T00:00:00.000Z/2015-08-24T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015236.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.430855</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920002-OB_DAAC</id>
    <title type="text">A2015236.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-08T03:55:14.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015236.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920002-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920002-OB_DAAC</dc:identifier>
    <dc:date>2015-08-24T00:00:00.000Z/2015-08-24T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015236.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.018598</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920004-OB_DAAC</id>
    <title type="text">A2015236.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-08T03:41:31.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015236.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920004-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920004-OB_DAAC</dc:identifier>
    <dc:date>2015-08-24T00:00:00.000Z/2015-08-24T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015236.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.064681</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920807-OB_DAAC</id>
    <title type="text">A2015237.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-10T11:51:49.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015237.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920807-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920807-OB_DAAC</dc:identifier>
    <dc:date>2015-08-25T00:00:00.000Z/2015-08-25T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015237.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.828583</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920824-OB_DAAC</id>
    <title type="text">A2015237.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-10T11:51:49.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015237.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920824-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920824-OB_DAAC</dc:identifier>
    <dc:date>2015-08-25T00:00:00.000Z/2015-08-25T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015237.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.516973</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920958-OB_DAAC</id>
    <title type="text">A2015237.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-09T11:44:54.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015237.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920958-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920958-OB_DAAC</dc:identifier>
    <dc:date>2015-08-25T00:00:00.000Z/2015-08-25T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015237.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.453487</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920959-OB_DAAC</id>
    <title type="text">A2015237.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-09T11:44:54.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015237.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920959-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920959-OB_DAAC</dc:identifier>
    <dc:date>2015-08-25T00:00:00.000Z/2015-08-25T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015237.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.057257</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920968-OB_DAAC</id>
    <title type="text">A2015237.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-09T11:45:40.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015237.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920968-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920968-OB_DAAC</dc:identifier>
    <dc:date>2015-08-25T00:00:00.000Z/2015-08-25T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015237.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.512634</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205920969-OB_DAAC</id>
    <title type="text">A2015237.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-09T11:45:40.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015237.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205920969-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205920969-OB_DAAC</dc:identifier>
    <dc:date>2015-08-25T00:00:00.000Z/2015-08-25T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015237.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.016404</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205921739-OB_DAAC</id>
    <title type="text">A2015238.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-12T12:05:01.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015238.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205921739-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205921739-OB_DAAC</dc:identifier>
    <dc:date>2015-08-26T00:00:00.000Z/2015-08-26T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015238.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.705826</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205921760-OB_DAAC</id>
    <title type="text">A2015238.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-12T12:05:01.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015238.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205921760-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205921760-OB_DAAC</dc:identifier>
    <dc:date>2015-08-26T00:00:00.000Z/2015-08-26T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015238.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.471264</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205921850-OB_DAAC</id>
    <title type="text">A2015238.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-10T11:52:54.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015238.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205921850-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205921850-OB_DAAC</dc:identifier>
    <dc:date>2015-08-26T00:00:00.000Z/2015-08-26T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015238.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.450302</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205921852-OB_DAAC</id>
    <title type="text">A2015238.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-10T11:52:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015238.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205921852-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205921852-OB_DAAC</dc:identifier>
    <dc:date>2015-08-26T00:00:00.000Z/2015-08-26T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015238.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.335423</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205921861-OB_DAAC</id>
    <title type="text">A2015238.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-10T11:52:54.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015238.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205921861-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205921861-OB_DAAC</dc:identifier>
    <dc:date>2015-08-26T00:00:00.000Z/2015-08-26T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015238.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.984268</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205921862-OB_DAAC</id>
    <title type="text">A2015238.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-10T11:52:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015238.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205921862-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205921862-OB_DAAC</dc:identifier>
    <dc:date>2015-08-26T00:00:00.000Z/2015-08-26T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015238.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.008042</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391491-OB_DAAC</id>
    <title type="text">A2015239.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-13T12:11:07.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015239.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391491-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391491-OB_DAAC</dc:identifier>
    <dc:date>2015-08-27T00:00:00.000Z/2015-08-27T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015239.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.514447</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391521-OB_DAAC</id>
    <title type="text">A2015239.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-13T12:11:07.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015239.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391521-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391521-OB_DAAC</dc:identifier>
    <dc:date>2015-08-27T00:00:00.000Z/2015-08-27T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015239.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.762817</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391560-OB_DAAC</id>
    <title type="text">A2015239.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-12T12:00:30.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015239.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391560-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391560-OB_DAAC</dc:identifier>
    <dc:date>2015-08-27T00:00:00.000Z/2015-08-27T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015239.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.511402</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391561-OB_DAAC</id>
    <title type="text">A2015239.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-12T12:00:30.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015239.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391561-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391561-OB_DAAC</dc:identifier>
    <dc:date>2015-08-27T00:00:00.000Z/2015-08-27T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015239.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.025678</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391563-OB_DAAC</id>
    <title type="text">A2015239.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-12T12:05:02.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015239.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391563-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391563-OB_DAAC</dc:identifier>
    <dc:date>2015-08-27T00:00:00.000Z/2015-08-27T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015239.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.45091</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391564-OB_DAAC</id>
    <title type="text">A2015239.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-12T12:05:02.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015239.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391564-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391564-OB_DAAC</dc:identifier>
    <dc:date>2015-08-27T00:00:00.000Z/2015-08-27T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015239.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.05865</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203495356-OB_DAAC</id>
    <title type="text">A2015240.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-14T12:13:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015240.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203495356-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203495356-OB_DAAC</dc:identifier>
    <dc:date>2015-08-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015240.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.671597</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203495382-OB_DAAC</id>
    <title type="text">A2015240.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-14T12:13:17.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015240.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203495382-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203495382-OB_DAAC</dc:identifier>
    <dc:date>2015-08-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015240.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.489731</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922479-OB_DAAC</id>
    <title type="text">A2015240.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-13T12:06:12.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015240.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922479-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922479-OB_DAAC</dc:identifier>
    <dc:date>2015-08-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015240.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.029531</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922500-OB_DAAC</id>
    <title type="text">A2015240.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-13T12:06:12.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015240.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922500-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922500-OB_DAAC</dc:identifier>
    <dc:date>2015-08-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015240.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.49079</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922529-OB_DAAC</id>
    <title type="text">A2015240.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-13T12:05:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015240.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922529-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922529-OB_DAAC</dc:identifier>
    <dc:date>2015-08-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015240.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.40673</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922530-OB_DAAC</id>
    <title type="text">A2015240.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-13T12:05:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015240.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922530-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922530-OB_DAAC</dc:identifier>
    <dc:date>2015-08-28T00:00:00.000Z/2015-08-28T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015240.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.05864</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203390570-OB_DAAC</id>
    <title type="text">A20152412015248.L3m_8D_NSST_sst_9km.nc</title>
    <updated>2015-09-21T08:42:57.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015248.L3m_8D_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203390570-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203390570-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015248.L3m_8D_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.225985</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203390590-OB_DAAC</id>
    <title type="text">A20152412015248.L3m_8D_NSST_sst_4km.nc</title>
    <updated>2015-09-21T08:42:57.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015248.L3m_8D_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203390590-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203390590-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015248.L3m_8D_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>60.617313</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203390592-OB_DAAC</id>
    <title type="text">A20152412015248.L3m_8D_SST4_sst4_4km.nc</title>
    <updated>2015-09-21T08:42:42.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015248.L3m_8D_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203390592-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203390592-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015248.L3m_8D_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>60.682495</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203390593-OB_DAAC</id>
    <title type="text">A20152412015248.L3m_8D_SST4_sst4_9km.nc</title>
    <updated>2015-09-21T08:42:42.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015248.L3m_8D_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203390593-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203390593-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015248.L3m_8D_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.265682</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391413-OB_DAAC</id>
    <title type="text">A20152412015248.L3m_8D_SST_sst_4km.nc</title>
    <updated>2015-09-22T08:47:01.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015248.L3m_8D_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391413-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391413-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015248.L3m_8D_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>57.37754</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203391414-OB_DAAC</id>
    <title type="text">A20152412015248.L3m_8D_SST_sst_9km.nc</title>
    <updated>2015-09-22T08:47:01.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015248.L3m_8D_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203391414-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203391414-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-05T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015248.L3m_8D_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>15.299355</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203392238-OB_DAAC</id>
    <title type="text">A2015241.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-14T12:11:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015241.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203392238-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203392238-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-08-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015241.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.703953</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203392246-OB_DAAC</id>
    <title type="text">A2015241.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-14T12:13:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015241.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203392246-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203392246-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-08-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015241.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.130853</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203392248-OB_DAAC</id>
    <title type="text">A2015241.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-14T12:11:28.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015241.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203392248-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203392248-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-08-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015241.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.154406</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203392263-OB_DAAC</id>
    <title type="text">A2015241.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-14T12:13:18.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015241.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203392263-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203392263-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-08-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015241.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.81387</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203495459-OB_DAAC</id>
    <title type="text">A2015241.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-16T12:27:20.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015241.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203495459-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203495459-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-08-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015241.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.643047</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203495483-OB_DAAC</id>
    <title type="text">A2015241.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-16T12:27:20.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015241.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203495483-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203495483-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-08-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015241.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.22445</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009329-OB_DAAC</id>
    <title type="text">A20152412015272.L3m_R32_SST_sst_4km.nc</title>
    <updated>2015-10-21T05:50:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015272.L3m_R32_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009329-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009329-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015272.L3m_R32_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>62.1074</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009330-OB_DAAC</id>
    <title type="text">A20152412015272.L3m_R32_SST_sst_9km.nc</title>
    <updated>2015-10-21T05:50:37.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015272.L3m_R32_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009330-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009330-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015272.L3m_R32_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.569508</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206012147-OB_DAAC</id>
    <title type="text">A20152412015272.L3m_R32_NSST_sst_9km.nc</title>
    <updated>2015-10-21T09:51:59.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015272.L3m_R32_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206012147-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206012147-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015272.L3m_R32_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.001541</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206012272-OB_DAAC</id>
    <title type="text">A20152412015272.L3m_R32_SST4_sst4_9km.nc</title>
    <updated>2015-10-21T09:51:59.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015272.L3m_R32_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206012272-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206012272-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015272.L3m_R32_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.974327</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206012315-OB_DAAC</id>
    <title type="text">A20152412015272.L3m_R32_SST4_sst4_4km.nc</title>
    <updated>2015-10-21T09:51:59.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015272.L3m_R32_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206012315-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206012315-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015272.L3m_R32_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.386333</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206012317-OB_DAAC</id>
    <title type="text">A20152412015272.L3m_R32_NSST_sst_4km.nc</title>
    <updated>2015-10-21T09:51:59.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152412015272.L3m_R32_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206012317-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206012317-OB_DAAC</dc:identifier>
    <dc:date>2015-08-29T00:00:00.000Z/2015-09-29T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152412015272.L3m_R32_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.58604</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203495809-OB_DAAC</id>
    <title type="text">A2015242.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-18T04:47:47.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015242.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203495809-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203495809-OB_DAAC</dc:identifier>
    <dc:date>2015-08-30T00:00:00.000Z/2015-08-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015242.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.27948</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1203495810-OB_DAAC</id>
    <title type="text">A2015242.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-18T04:47:47.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015242.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1203495810-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1203495810-OB_DAAC</dc:identifier>
    <dc:date>2015-08-30T00:00:00.000Z/2015-08-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015242.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.66759</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922701-OB_DAAC</id>
    <title type="text">A2015242.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-16T12:25:47.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015242.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922701-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922701-OB_DAAC</dc:identifier>
    <dc:date>2015-08-30T00:00:00.000Z/2015-08-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015242.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.973343</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922721-OB_DAAC</id>
    <title type="text">A2015242.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-16T12:25:47.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015242.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922721-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922721-OB_DAAC</dc:identifier>
    <dc:date>2015-08-30T00:00:00.000Z/2015-08-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015242.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.23331</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922723-OB_DAAC</id>
    <title type="text">A2015242.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-16T12:26:13.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015242.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922723-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922723-OB_DAAC</dc:identifier>
    <dc:date>2015-08-30T00:00:00.000Z/2015-08-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015242.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>46.131542</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922724-OB_DAAC</id>
    <title type="text">A2015242.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-16T12:26:13.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015242.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922724-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922724-OB_DAAC</dc:identifier>
    <dc:date>2015-08-30T00:00:00.000Z/2015-08-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015242.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.221273</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1201125302-OB_DAAC</id>
    <title type="text">A2015243.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-18T05:07:55.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015243.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1201125302-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1201125302-OB_DAAC</dc:identifier>
    <dc:date>2015-08-31T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015243.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>44.25534</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1201125303-OB_DAAC</id>
    <title type="text">A2015243.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-18T05:07:55.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015243.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1201125303-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1201125303-OB_DAAC</dc:identifier>
    <dc:date>2015-08-31T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015243.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.655033</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922959-OB_DAAC</id>
    <title type="text">A2015243.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-18T04:50:32.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015243.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922959-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922959-OB_DAAC</dc:identifier>
    <dc:date>2015-08-31T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015243.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.20579</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205922993-OB_DAAC</id>
    <title type="text">A2015243.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-18T04:53:59.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015243.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205922993-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205922993-OB_DAAC</dc:identifier>
    <dc:date>2015-08-31T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015243.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.188019</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205923002-OB_DAAC</id>
    <title type="text">A2015243.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-18T04:50:32.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015243.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205923002-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205923002-OB_DAAC</dc:identifier>
    <dc:date>2015-08-31T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015243.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.92995</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205923003-OB_DAAC</id>
    <title type="text">A2015243.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-18T04:53:59.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015243.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205923003-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205923003-OB_DAAC</dc:identifier>
    <dc:date>2015-08-31T00:00:00.000Z/2015-08-31T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015243.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>46.075466</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1201797714-OB_DAAC</id>
    <title type="text">A2015244.L3m_DAY_SST4_sst4_4km.nc</title>
    <updated>2015-09-17T12:40:36.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015244.L3m_DAY_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1201797714-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1201797714-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015244.L3m_DAY_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.696728</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1201797715-OB_DAAC</id>
    <title type="text">A2015244.L3m_DAY_NSST_sst_4km.nc</title>
    <updated>2015-09-17T12:36:35.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015244.L3m_DAY_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1201797715-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1201797715-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015244.L3m_DAY_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>45.79167</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1201797736-OB_DAAC</id>
    <title type="text">A2015244.L3m_DAY_SST4_sst4_9km.nc</title>
    <updated>2015-09-17T12:40:36.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015244.L3m_DAY_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1201797736-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1201797736-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015244.L3m_DAY_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.113837</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205923837-OB_DAAC</id>
    <title type="text">A2015244.L3m_DAY_NSST_sst_9km.nc</title>
    <updated>2015-09-17T12:36:35.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015244.L3m_DAY_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205923837-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205923837-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015244.L3m_DAY_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>12.084289</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205924125-OB_DAAC</id>
    <title type="text">A2015244.L3m_DAY_SST_sst_4km.nc</title>
    <updated>2015-09-18T12:38:30.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015244.L3m_DAY_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205924125-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205924125-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015244.L3m_DAY_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>43.994972</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205924147-OB_DAAC</id>
    <title type="text">A2015244.L3m_DAY_SST_sst_9km.nc</title>
    <updated>2015-09-18T12:38:30.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A2015244.L3m_DAY_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1205924147-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205924147-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-01T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A2015244.L3m_DAY_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>11.559358</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009175-OB_DAAC</id>
    <title type="text">A20152442015273.L3m_MO_SST_sst_4km.nc</title>
    <updated>2015-10-25T08:47:03.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152442015273.L3m_MO_SST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/244/A20152442015273.L3m_MO_SST_sst_4km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009175-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009175-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152442015273.L3m_MO_SST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>62.036804</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009176-OB_DAAC</id>
    <title type="text">A20152442015273.L3m_MO_SST_sst_9km.nc</title>
    <updated>2015-10-25T08:47:03.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152442015273.L3m_MO_SST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/244/A20152442015273.L3m_MO_SST_sst_9km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009176-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009176-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152442015273.L3m_MO_SST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.543331</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009177-OB_DAAC</id>
    <title type="text">A20152442015273.L3m_MO_SST4_sst4_4km.nc</title>
    <updated>2015-10-25T08:47:03.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152442015273.L3m_MO_SST4_sst4_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/244/A20152442015273.L3m_MO_SST4_sst4_4km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009177-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009177-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152442015273.L3m_MO_SST4_sst4_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.40573</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009179-OB_DAAC</id>
    <title type="text">A20152442015273.L3m_MO_NSST_sst_4km.nc</title>
    <updated>2015-10-25T08:47:04.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152442015273.L3m_MO_NSST_sst_4km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/244/A20152442015273.L3m_MO_NSST_sst_4km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009179-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009179-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152442015273.L3m_MO_NSST_sst_4km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>63.59702</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009185-OB_DAAC</id>
    <title type="text">A20152442015273.L3m_MO_SST4_sst4_9km.nc</title>
    <updated>2015-10-25T08:47:03.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152442015273.L3m_MO_SST4_sst4_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/244/A20152442015273.L3m_MO_SST4_sst4_9km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009185-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009185-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152442015273.L3m_MO_SST4_sst4_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>16.975193</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1206009200-OB_DAAC</id>
    <title type="text">A20152442015273.L3m_MO_NSST_sst_9km.nc</title>
    <updated>2015-10-25T08:47:04.000Z</updated>
    <link href="https://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152442015273.L3m_MO_NSST_sst_9km.nc" hreflang="en-US" rel="enclosure"/>

    <link href="https://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/244/A20152442015273.L3m_MO_NSST_sst_9km.nc" hreflang="en-US" rel="via" title="(GET DATA : OPENDAP DATA (DODS))" type="application/x-netcdf"/>

    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/" hreflang="en-US" rel="via" title="Ocean Biology Processing Group (OBPG) Homepage (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/cms/data/aqua" hreflang="en-US" rel="via" title="OB.DAAC MODIS-Aqua Description Website (Home Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/data/10.5067/AQUA/MODIS/L3M/SST/2014" hreflang="en-US" rel="via" title="OB.DAAC MODIS Landing Page (Landing Page)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="https://oceancolor.gsfc.nasa.gov/forum/oceancolor/forum_show.pl    " hreflang="en-US" rel="describedBy" title="Ocean Biology Processing Group User Support Forum     (User Support)" type="text/html">
      <echo:inherited/>

    </link>
    <link href="https://cmr.earthdata.nasa.gov/search/concepts/G1206009200-OB_DAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1206009200-OB_DAAC</dc:identifier>
    <dc:date>2015-09-01T00:00:00.000Z/2015-09-30T23:59:59.000Z</dc:date>
    <echo:datasetId>MODISA_L3m_SST</echo:datasetId>
    <echo:producerGranuleId>A20152442015273.L3m_MO_NSST_sst_9km.nc</echo:producerGranuleId>
    <echo:granuleSizeMB>17.001917</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>OB_DAAC</echo:dataCenter>
    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
</feed>

