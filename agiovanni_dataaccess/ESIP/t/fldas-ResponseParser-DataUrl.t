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
ok( $author eq "GES DISC", "found:$author" );

my $package = ESIP::ResponseParser::V1_2->new(
    XML  => $dom,
    TYPE => "application/x-hdf",
    sampleFile =>
        "http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/1981/FLDAS_NOAH01_B_SA_M.A198102.001.nc",
    sampleOpendap =>
        "http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/1981/FLDAS_NOAH01_B_SA_M.A198101.001.nc.html"

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
    'http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A198101.001.nc.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A198101.001.nc.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A198101.001.nc.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A198101.001.nc.html',
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
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:esipdiscovery="http://commons.esipfed.org/ns/discovery/1.2/" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns:georss="http://www.georss.org/georss" xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" esipdiscovery:version="1.2">
  <title>FLDAS_NOAH01_B_SA_M Files (search provided by Mirador)</title>
  <subtitle type="html">FLDAS Noah Land Surface Model L4 monthly 0.1 x 0.1 degree for Southern Africa (MERRA and CHIRPS) (distributed by GES DISC)
          Total Results: 4
          Max Items Per Page:4</subtitle>
  <updated>2009-07-16T18:30:02Z</updated>
  <author>
    <name>GES DISC</name>
    <email>gsfc-mirador-disc@lists.nasa.gov</email>
  </author>
  <id>http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl</id>
  <opensearch:totalResults>4</opensearch:totalResults>
  <opensearch:itemsPerPage>4</opensearch:itemsPerPage>
  <opensearch:startPage>1</opensearch:startPage>
  <link rel="first" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=1&amp;dataSet=FLDAS_NOAH01_B_SA_M.001&amp;format=atom&amp;osLocation=&amp;endTime=2005-09-30T23%3A59%3A59Z&amp;order=d&amp;startTime=2005-06-01T00%3A00%3A01Z&amp;newtime=&amp;maxgranules=1024"/>
  <link rel="last" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=0&amp;last=1&amp;dataSet=FLDAS_NOAH01_B_SA_M.001&amp;format=atom&amp;osLocation=&amp;endTime=2005-09-30T23%3A59%3A59Z&amp;order=d&amp;startTime=2005-06-01T00%3A00%3A01Z&amp;newtime=2005-09-30T23%3A59%3A59Z&amp;maxgranules=1024&amp;os_altorder=asc"/>
  <link rel="opensearch:search" type="application/opensearchdescription+xml" href="http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_FLDAS_NOAH01_B_SA_M.001.xml"/>
  <entry>
    <title>FLDAS.FLDAS_NOAH01_B_SA_M.2005.06.01.000000Z.001.nc</title>
    <updated>2005-06-01T00:00:00Z</updated>
    <id>http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="21549860" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="21549860" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc.xml.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200506.001.nc.ddx"/>
    <georss:box>-37.9 6 6.4 54.6</georss:box>
    <time:start>2005-06-01T00:00:00Z</time:start>
    <time:end>2005-06-30T23:59:59Z</time:end>
    <dc:date>2005-06-01T00:00:00Z/2005-06-30T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2005-06-01T00:00:00Z, end:2005-06-30T23:59:59Z, size:21549860  (1)</content>
  </entry>
  <entry>
    <title>FLDAS.FLDAS_NOAH01_B_SA_M.2005.07.01.000000Z.001.nc</title>
    <updated>2005-07-01T00:00:00Z</updated>
    <id>http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="21549860" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="21549860" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc.xml.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200507.001.nc.ddx"/>
    <georss:box>-37.9 6 6.4 54.6</georss:box>
    <time:start>2005-07-01T00:00:00Z</time:start>
    <time:end>2005-07-31T23:59:59Z</time:end>
    <dc:date>2005-07-01T00:00:00Z/2005-07-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2005-07-01T00:00:00Z, end:2005-07-31T23:59:59Z, size:21549860  (2)</content>
  </entry>
  <entry>
    <title>FLDAS.FLDAS_NOAH01_B_SA_M.2005.08.01.000000Z.001.nc</title>
    <updated>2005-08-01T00:00:00Z</updated>
    <id>http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="21549860" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="21549860" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc.xml.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200508.001.nc.ddx"/>
    <georss:box>-37.9 6 6.4 54.6</georss:box>
    <time:start>2005-08-01T00:00:00Z</time:start>
    <time:end>2005-08-31T23:59:59Z</time:end>
    <dc:date>2005-08-01T00:00:00Z/2005-08-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2005-08-01T00:00:00Z, end:2005-08-31T23:59:59Z, size:21549860  (3)</content>
  </entry>
  <entry>
    <title>FLDAS.FLDAS_NOAH01_B_SA_M.2005.09.01.000000Z.001.nc</title>
    <updated>2005-09-01T00:00:00Z</updated>
    <id>http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="21549860" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="21549860" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="http://hydro1.sci.gsfc.nasa.gov/data/s4pa//FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc.xml.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://hydro1.sci.gsfc.nasa.gov/opendap/hyrax/FLDAS/FLDAS_NOAH01_B_SA_M.001/2005/FLDAS_NOAH01_B_SA_M.A200509.001.nc.ddx"/>
    <georss:box>-37.9 6 6.4 54.6</georss:box>
    <time:start>2005-09-01T00:00:00Z</time:start>
    <time:end>2005-09-30T23:59:59Z</time:end>
    <dc:date>2005-09-01T00:00:00Z/2005-09-30T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2005-09-01T00:00:00Z, end:2005-09-30T23:59:59Z, size:21549860  (4)</content>
  </entry>
</feed>
