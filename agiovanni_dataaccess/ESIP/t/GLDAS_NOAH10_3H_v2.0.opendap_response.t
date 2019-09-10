#!/usr/bin/perl

use XML::LibXML;

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
ok( $author eq "GES DISC", "found:$author" );

my $package = ESIP::ResponseParser::V1_2->new(
    XML  => $dom,
    TYPE => "application/x-hdf",
    sampleFile =>
        "http://hydro1.sci.gsfc.nasa.gov/data/s4pa/GLDAS/GLDAS_NOAH10_M.2.0/1948/GLDAS_NOAH10_M.A194801.020.nc4",
    sampleOpendap =>
        "http://hydro1.sci.gsfc.nasa.gov/opendap/GLDAS/GLDAS_NOAH10_M.2.0/1948/GLDAS_NOAH10_M.A194801.020.nc4.html",
    dataFieldIdRegex => ".+L3m_MO_SST4_sst4_4km.*"

);

my @results;
my @tmp = $package->getOPeNDAPUrls();

push @results, @{ $tmp[0] };

ok( scalar @results == 4, "number of urls:" . scalar @results );

my @test = (
    'http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4'
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
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:esipdiscovery="http://commons.esipfed.org/ns/discovery/1.2/" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns:georss="http://www.georss.org/georss" xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" esipdiscovery:version="1.2">
  <title>GLDAS_NOAH10_M Files (search provided by Mirador)</title>
  <subtitle type="html">GLDAS Noah Land Surface Model L4 monthly 1.0 x 1.0 degree (distributed by GES DISC)
          Total Results: 130
          Max Items Per Page:4</subtitle>
  <updated>2009-07-16T18:30:02Z</updated>
  <author>
    <name>GES DISC</name>
    <email>gsfc-mirador-disc@lists.nasa.gov</email>
  </author>
  <id>http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl</id>
  <opensearch:totalResults>130</opensearch:totalResults>
  <opensearch:itemsPerPage>4</opensearch:itemsPerPage>
  <opensearch:startPage>1</opensearch:startPage>
  <link rel="first" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=1&amp;dataSet=GLDAS_NOAH10_M.2.0&amp;format=atom&amp;osLocation=&amp;endTime=2015-04-01T00%3A00%3A00Z&amp;order=a&amp;startTime=Sat+Apr+01+00%3A00%3A00+2000&amp;newtime=&amp;maxgranules=4"/>
  <link rel="next" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=2&amp;dataSet=GLDAS_NOAH10_M.2.0&amp;format=atom&amp;osLocation=&amp;endTime=2015-04-01T00%3A00%3A00Z&amp;order=a&amp;startTime=Sat+Apr+01+00%3A00%3A00+2000&amp;newtime=Mon+Jul+31+23%3A59%3A59+2000&amp;maxgranules=4"/>
  <link rel="last" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=32&amp;last=1&amp;dataSet=GLDAS_NOAH10_M.2.0&amp;format=atom&amp;osLocation=&amp;endTime=2015-04-01T00%3A00%3A00Z&amp;order=d&amp;startTime=Sat+Apr+01+00%3A00%3A00+2000&amp;newtime=2015-04-01T00%3A00%3A00Z&amp;maxgranules=4&amp;os_altorder=asc"/>
  <link rel="opensearch:search" type="application/opensearchdescription+xml" href="http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_GLDAS_NOAH10_M.2.0.xml"/>
  <entry>
    <title>.NoahModel10Monthly2.2000.04.01.000000Z.2.0.nc4</title>
    <updated>2000-04-01T00:00:00Z</updated>
    <id>http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="2091199" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="2091199" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4.xml.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200004.020.nc4.ddx"/>
    <georss:box>-60 -180 90 180</georss:box>
    <time:start>2000-04-01T00:00:00Z</time:start>
    <time:end>2000-04-30T23:59:59Z</time:end>
    <dc:date>2000-04-01T00:00:00Z/2000-04-30T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2000-04-01T00:00:00Z, end:2000-04-30T23:59:59Z, size:2091199  (1)</content>
  </entry>
  <entry>
    <title>.NoahModel10Monthly2.2000.05.01.000000Z.2.0.nc4</title>
    <updated>2000-05-01T00:00:00Z</updated>
    <id>http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="2093669" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="2093669" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4.xml.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200005.020.nc4.ddx"/>
    <georss:box>-60 -180 90 180</georss:box>
    <time:start>2000-05-01T00:00:00Z</time:start>
    <time:end>2000-05-31T23:59:59Z</time:end>
    <dc:date>2000-05-01T00:00:00Z/2000-05-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2000-05-01T00:00:00Z, end:2000-05-31T23:59:59Z, size:2093669  (2)</content>
  </entry>
  <entry>
    <title>.NoahModel10Monthly2.2000.06.01.000000Z.2.0.nc4</title>
    <updated>2000-06-01T00:00:00Z</updated>
    <id>http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="2071435" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="2071435" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4.xml.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200006.020.nc4.ddx"/>
    <georss:box>-60 -180 90 180</georss:box>
    <time:start>2000-06-01T00:00:00Z</time:start>
    <time:end>2000-06-30T23:59:59Z</time:end>
    <dc:date>2000-06-01T00:00:00Z/2000-06-30T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2000-06-01T00:00:00Z, end:2000-06-30T23:59:59Z, size:2071435  (3)</content>
  </entry>
  <entry>
    <title>.NoahModel10Monthly2.2000.07.01.000000Z.2.0.nc4</title>
    <updated>2000-07-01T00:00:00Z</updated>
    <id>http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="2039795" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="2039795" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4.xml.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/GLDAS/GLDAS_NOAH10_M.2.0/2000/GLDAS_NOAH10_M.A200007.020.nc4.ddx"/>
    <georss:box>-60 -180 90 180</georss:box>
    <time:start>2000-07-01T00:00:00Z</time:start>
    <time:end>2000-07-31T23:59:59Z</time:end>
    <dc:date>2000-07-01T00:00:00Z/2000-07-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2000-07-01T00:00:00Z, end:2000-07-31T23:59:59Z, size:2039795  (4)</content>
  </entry>
</feed>

