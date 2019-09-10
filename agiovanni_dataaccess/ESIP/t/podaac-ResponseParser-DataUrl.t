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
ok( $author eq "CMR" );

my $package = ESIP::ResponseParser::V1_2->new(
    XML  => $dom,
    TYPE => "application/x-hdf",
    sampleFile =>
        "ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201201.v4.0cap.nc",
    sampleOpendap =>
        "http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201201.v4.0cap.nc.html"

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

ok( $#results == 3, "number of urls" );

my @test = (
    'http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201201.v4.0cap.nc.html',
    'http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201202.v4.0cap.nc.html',
    'http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201203.v4.0cap.nc.html',
    'http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201204.v4.0cap.nc.html'
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
  <updated>2015-11-24T18:16:42.554Z</updated>
  <id>https://api.echo.nasa.gov:443/opensearch/granules.atom</id>
  <author>
    <name>CMR</name>
    <email>support@echo.nasa.gov</email>
  </author>
  <title type="text">ECHO granule metadata</title>
  <subtitle type="text">Search parameters: shortName =&gt; AQUARIUS_L3_SSS_RAINCORRECTED_CAP_MONTHLY_V4 versionId =&gt; 1 dataCenter =&gt; PODAAC boundingBox =&gt;  geometry =&gt;  placeName =&gt;  startTime =&gt; 2012-01-01T00:00:01Z endTime =&gt; 2012-04-30T23:59:59Z uid =&gt; </subtitle>
  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=AQUARIUS_L3_SSS_RAINCORRECTED_CAP_MONTHLY_V4&amp;versionId=1&amp;dataCenter=PODAAC&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2012-01-01T00%3A00%3A01Z&amp;endTime=2012-04-30T23%3A59%3A59Z&amp;cursor=1&amp;numberOfResults=1024&amp;uid=&amp;clientId=giovanni" hreflang="en-US" rel="self" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=AQUARIUS_L3_SSS_RAINCORRECTED_CAP_MONTHLY_V4&amp;versionId=1&amp;dataCenter=PODAAC&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2012-01-01T00%3A00%3A01Z&amp;endTime=2012-04-30T23%3A59%3A59Z&amp;numberOfResults=1024&amp;uid=&amp;clientId=giovanni&amp;cursor=1" hreflang="en-US" rel="last" type="application/atom+xml"/>

  <link href="https://api.echo.nasa.gov/opensearch/granules.atom?datasetId=&amp;shortName=AQUARIUS_L3_SSS_RAINCORRECTED_CAP_MONTHLY_V4&amp;versionId=1&amp;dataCenter=PODAAC&amp;boundingBox=&amp;geometry=&amp;placeName=&amp;startTime=2012-01-01T00%3A00%3A01Z&amp;endTime=2012-04-30T23%3A59%3A59Z&amp;numberOfResults=1024&amp;uid=&amp;clientId=giovanni&amp;cursor=1" hreflang="en-US" rel="first" type="application/atom+xml"/>

  <link href="https://wiki.earthdata.nasa.gov/display/echo/Open+Search+API+release+information" hreflang="en-US" rel="describedBy" title="Release Notes" type="text/html"/>

  <os:Query echo:dataCenter="PODAAC" echo:shortName="AQUARIUS_L3_SSS_RAINCORRECTED_CAP_MONTHLY_V4" echo:versionId="1" geo:box="" geo:geometry="" geo:uid="" role="request" time:end="2012-04-30T23:59:59Z" time:start="2012-01-01T00:00:01Z" xmlns:echo="http://www.echo.nasa.gov/esip" xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/"/>

  <os:totalResults>4</os:totalResults>
  <os:itemsPerPage>1024</os:itemsPerPage>
  <os:startIndex>1</os:startIndex>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205970627-PODAAC</id>
    <title type="text">sss_rc201201.v4.0cap.nc</title>
    <updated>2015-10-23T16:34:52.791Z</updated>
    <link href="http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201201.v4.0cap.nc.html" hreflang="en-US" rel="describedBy" title="The OPENDAP location for the granule." type="text/html"/>

    <link href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201201.v4.0cap.nc" hreflang="en-US" rel="enclosure" title="The FTP location for the granule."/>

    <link echo:inherited="true" href="http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/" hreflang="en-US" rel="enclosure" title="The OPeNDAP base directory location for the collection.">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/L3/mapped/CAPv4/monthly/SCI" hreflang="en-US" rel="enclosure" title="The FTP base directory location for the collection.">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/docs/CAPv4/" hreflang="en-US" rel="via" title="ATBD, Validation &amp; Uncertainty Analyses, Publications, etc (PORTAL_DOC_PROJECT_MATERIALS)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://aquarius.nasa.gov/" hreflang="en-US" rel="via" title="NASA Aquarius/SAC-D mission website (PORTAL_DOC_ADDITIONAL_SITES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://thredds.jpl.nasa.gov/thredds/catalog/ncml_aggregation/SalinityDensity/aquarius/catalog.html" hreflang="en-US" rel="describedBy" title="THREDDS SERVER (PORTAL_DA_DIRECT_ACCESS)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/docs/CAPv4/Aquarius-CAP-User-Guide-v4.0.pdf" hreflang="en-US" rel="via" title="Aquarius CAP V4.0 Algorithm and Data Users Guide (PORTAL_DOC_USERS_GUIDE)" type="application/pdf">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://podaac.jpl.nasa.gov/aquarius" hreflang="en-US" rel="via" title="Mission and Instrument Overview (PORTAL_DOC_ADDITIONAL_SITES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/sw/idl/" hreflang="en-US" rel="via" title="IDL Reader and calling routines (PORTAL_DA_READ_SOFTWARE)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/sw/matlab/" hreflang="en-US" rel="via" title="MATLAB Reader and calling routines (PORTAL_DA_READ_SOFTWARE)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://oceancolor.gsfc.nasa.gov/sdpscgi/public/aquarius_report.cgi" hreflang="en-US" rel="via" title="Information on observatory maneuvers, anomalies and other events (PORTAL_DOC_KNOWN_ISSUES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://podaac.jpl.nasa.gov/las/" hreflang="en-US" rel="via" title="Live Access Server (PORTAL_DA_TOOLS_AND_SERVICES)">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G1205970627-PODAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205970627-PODAAC</dc:identifier>
    <dc:date>2012-01-01T00:10:00.000Z/2012-01-31T23:59:59.000Z</dc:date>
    <echo:datasetId>AQUARIUS_L3_SSS_RAINCORRECTED_CAP_MONTHLY_V4:1</echo:datasetId>
    <echo:granuleSizeMB>512.91406</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>PODAAC</echo:dataCenter>
    <echo:orbitCalSpatialDomain/>

    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205970619-PODAAC</id>
    <title type="text">sss_rc201202.v4.0cap.nc</title>
    <updated>2015-10-23T16:34:50.207Z</updated>
    <link href="http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201202.v4.0cap.nc.html" hreflang="en-US" rel="describedBy" title="The OPENDAP location for the granule." type="text/html"/>

    <link href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201202.v4.0cap.nc" hreflang="en-US" rel="enclosure" title="The FTP location for the granule."/>

    <link echo:inherited="true" href="http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/" hreflang="en-US" rel="enclosure" title="The OPeNDAP base directory location for the collection.">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/L3/mapped/CAPv4/monthly/SCI" hreflang="en-US" rel="enclosure" title="The FTP base directory location for the collection.">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/docs/CAPv4/" hreflang="en-US" rel="via" title="ATBD, Validation &amp; Uncertainty Analyses, Publications, etc (PORTAL_DOC_PROJECT_MATERIALS)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://aquarius.nasa.gov/" hreflang="en-US" rel="via" title="NASA Aquarius/SAC-D mission website (PORTAL_DOC_ADDITIONAL_SITES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://thredds.jpl.nasa.gov/thredds/catalog/ncml_aggregation/SalinityDensity/aquarius/catalog.html" hreflang="en-US" rel="describedBy" title="THREDDS SERVER (PORTAL_DA_DIRECT_ACCESS)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/docs/CAPv4/Aquarius-CAP-User-Guide-v4.0.pdf" hreflang="en-US" rel="via" title="Aquarius CAP V4.0 Algorithm and Data Users Guide (PORTAL_DOC_USERS_GUIDE)" type="application/pdf">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://podaac.jpl.nasa.gov/aquarius" hreflang="en-US" rel="via" title="Mission and Instrument Overview (PORTAL_DOC_ADDITIONAL_SITES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/sw/idl/" hreflang="en-US" rel="via" title="IDL Reader and calling routines (PORTAL_DA_READ_SOFTWARE)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/sw/matlab/" hreflang="en-US" rel="via" title="MATLAB Reader and calling routines (PORTAL_DA_READ_SOFTWARE)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://oceancolor.gsfc.nasa.gov/sdpscgi/public/aquarius_report.cgi" hreflang="en-US" rel="via" title="Information on observatory maneuvers, anomalies and other events (PORTAL_DOC_KNOWN_ISSUES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://podaac.jpl.nasa.gov/las/" hreflang="en-US" rel="via" title="Live Access Server (PORTAL_DA_TOOLS_AND_SERVICES)">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G1205970619-PODAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205970619-PODAAC</dc:identifier>
    <dc:date>2012-02-01T00:10:00.000Z/2012-02-29T23:59:59.000Z</dc:date>
    <echo:datasetId>AQUARIUS_L3_SSS_RAINCORRECTED_CAP_MONTHLY_V4:1</echo:datasetId>
    <echo:granuleSizeMB>512.91406</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>PODAAC</echo:dataCenter>
    <echo:orbitCalSpatialDomain/>

    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205970613-PODAAC</id>
    <title type="text">sss_rc201203.v4.0cap.nc</title>
    <updated>2015-10-23T16:34:46.842Z</updated>
    <link href="http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201203.v4.0cap.nc.html" hreflang="en-US" rel="describedBy" title="The OPENDAP location for the granule." type="text/html"/>

    <link href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201203.v4.0cap.nc" hreflang="en-US" rel="enclosure" title="The FTP location for the granule."/>

    <link echo:inherited="true" href="http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/" hreflang="en-US" rel="enclosure" title="The OPeNDAP base directory location for the collection.">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/L3/mapped/CAPv4/monthly/SCI" hreflang="en-US" rel="enclosure" title="The FTP base directory location for the collection.">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/docs/CAPv4/" hreflang="en-US" rel="via" title="ATBD, Validation &amp; Uncertainty Analyses, Publications, etc (PORTAL_DOC_PROJECT_MATERIALS)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://aquarius.nasa.gov/" hreflang="en-US" rel="via" title="NASA Aquarius/SAC-D mission website (PORTAL_DOC_ADDITIONAL_SITES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://thredds.jpl.nasa.gov/thredds/catalog/ncml_aggregation/SalinityDensity/aquarius/catalog.html" hreflang="en-US" rel="describedBy" title="THREDDS SERVER (PORTAL_DA_DIRECT_ACCESS)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/docs/CAPv4/Aquarius-CAP-User-Guide-v4.0.pdf" hreflang="en-US" rel="via" title="Aquarius CAP V4.0 Algorithm and Data Users Guide (PORTAL_DOC_USERS_GUIDE)" type="application/pdf">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://podaac.jpl.nasa.gov/aquarius" hreflang="en-US" rel="via" title="Mission and Instrument Overview (PORTAL_DOC_ADDITIONAL_SITES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/sw/idl/" hreflang="en-US" rel="via" title="IDL Reader and calling routines (PORTAL_DA_READ_SOFTWARE)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/sw/matlab/" hreflang="en-US" rel="via" title="MATLAB Reader and calling routines (PORTAL_DA_READ_SOFTWARE)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://oceancolor.gsfc.nasa.gov/sdpscgi/public/aquarius_report.cgi" hreflang="en-US" rel="via" title="Information on observatory maneuvers, anomalies and other events (PORTAL_DOC_KNOWN_ISSUES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://podaac.jpl.nasa.gov/las/" hreflang="en-US" rel="via" title="Live Access Server (PORTAL_DA_TOOLS_AND_SERVICES)">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G1205970613-PODAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205970613-PODAAC</dc:identifier>
    <dc:date>2012-03-01T00:10:00.000Z/2012-03-31T23:59:59.000Z</dc:date>
    <echo:datasetId>AQUARIUS_L3_SSS_RAINCORRECTED_CAP_MONTHLY_V4:1</echo:datasetId>
    <echo:granuleSizeMB>512.91406</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>PODAAC</echo:dataCenter>
    <echo:orbitCalSpatialDomain/>

    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
  <entry>
    <id>https://api.echo.nasa.gov:443/opensearch/granules.atom?uid=G1205970622-PODAAC</id>
    <title type="text">sss_rc201204.v4.0cap.nc</title>
    <updated>2015-10-23T16:34:51.176Z</updated>
    <link href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201204.v4.0cap.nc" hreflang="en-US" rel="enclosure" title="The FTP location for the granule."/>

    <link href="http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/2012/sss_rc201204.v4.0cap.nc.html" hreflang="en-US" rel="describedBy" title="The OPENDAP location for the granule." type="text/html"/>

    <link echo:inherited="true" href="http://podaac-opendap.jpl.nasa.gov/opendap/allData/aquarius/L3/mapped/CAPv4/monthly/SCI/" hreflang="en-US" rel="enclosure" title="The OPeNDAP base directory location for the collection.">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/L3/mapped/CAPv4/monthly/SCI" hreflang="en-US" rel="enclosure" title="The FTP base directory location for the collection.">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/docs/CAPv4/" hreflang="en-US" rel="via" title="ATBD, Validation &amp; Uncertainty Analyses, Publications, etc (PORTAL_DOC_PROJECT_MATERIALS)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://aquarius.nasa.gov/" hreflang="en-US" rel="via" title="NASA Aquarius/SAC-D mission website (PORTAL_DOC_ADDITIONAL_SITES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://thredds.jpl.nasa.gov/thredds/catalog/ncml_aggregation/SalinityDensity/aquarius/catalog.html" hreflang="en-US" rel="describedBy" title="THREDDS SERVER (PORTAL_DA_DIRECT_ACCESS)" type="text/html">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/docs/CAPv4/Aquarius-CAP-User-Guide-v4.0.pdf" hreflang="en-US" rel="via" title="Aquarius CAP V4.0 Algorithm and Data Users Guide (PORTAL_DOC_USERS_GUIDE)" type="application/pdf">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://podaac.jpl.nasa.gov/aquarius" hreflang="en-US" rel="via" title="Mission and Instrument Overview (PORTAL_DOC_ADDITIONAL_SITES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/sw/idl/" hreflang="en-US" rel="via" title="IDL Reader and calling routines (PORTAL_DA_READ_SOFTWARE)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="ftp://podaac-ftp.jpl.nasa.gov/allData/aquarius/sw/matlab/" hreflang="en-US" rel="via" title="MATLAB Reader and calling routines (PORTAL_DA_READ_SOFTWARE)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://oceancolor.gsfc.nasa.gov/sdpscgi/public/aquarius_report.cgi" hreflang="en-US" rel="via" title="Information on observatory maneuvers, anomalies and other events (PORTAL_DOC_KNOWN_ISSUES)">
      <echo:inherited/>

    </link>
    <link echo:inherited="true" href="http://podaac.jpl.nasa.gov/las/" hreflang="en-US" rel="via" title="Live Access Server (PORTAL_DA_TOOLS_AND_SERVICES)">
      <echo:inherited/>

    </link>
    <link href="http://cmr.earthdata.nasa.gov/search/concepts/G1205970622-PODAAC.xml" hreflang="en-US" rel="via" title="Product metadata" type="application/xml"/>

    <dc:identifier>G1205970622-PODAAC</dc:identifier>
    <dc:date>2012-04-01T00:10:00.000Z/2012-04-30T23:59:59.000Z</dc:date>
    <echo:datasetId>AQUARIUS_L3_SSS_RAINCORRECTED_CAP_MONTHLY_V4:1</echo:datasetId>
    <echo:granuleSizeMB>512.91406</echo:granuleSizeMB>
    <echo:originalFormat>ECHO10</echo:originalFormat>
    <echo:dataCenter>PODAAC</echo:dataCenter>
    <echo:orbitCalSpatialDomain/>

    <echo:coordinateSystem>CARTESIAN</echo:coordinateSystem>
    <georss:box>-90 -180 90 180</georss:box>
  </entry>
</feed>

