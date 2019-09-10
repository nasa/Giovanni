#!/usr/bin/perl

use XML::LibXML;

#use ESIP::Response::V1_2;
use Test::More tests => 17;

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
        "http://hydro1.sci.gsfc.nasa.gov/data/GLDAS/GLDAS_NOAH10_M.2.0/1948/GLDAS_NOAH10_M.A194801.020.nc4",
    sampleOpendap =>
        "http://hydro1.sci.gsfc.nasa.gov/opendap/GLDAS/GLDAS_NOAH10_M.2.0/1948/GLDAS_NOAH10_M.A194801.020.nc4.html"

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

ok( scalar @results == 12, "number of urls:" . scalar @results );

my @test = (
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199710-201010_v004-20130614T144207Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199711-201011_v004-20130614T144209Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199712-201012_v004-20130614T144211Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199801-201001_v004-20130614T144149Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199803-201003_v004-20130614T144153Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199804-201004_v004-20130614T144155Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199805-201005_v004-20130614T144157Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199806-201006_v004-20130614T144159Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199807-201007_v004-20130614T144201Z.h5.html',
    'http://hydro1.sci.gsfc.nasa.gov/opendap/DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5.html'
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
  <title>SWDB_L3MC10 Files (search provided by Mirador)</title>
  <subtitle type="html">SeaWiFS Deep Blue Aerosol Optical Thickness Monthly Level 3 Climatology Data Gridded at 1.0 Degrees (distributed by GES DISC)
          Total Results: 12
          Max Items Per Page:12</subtitle>
  <updated>2009-07-16T18:30:02Z</updated>
  <author>
    <name>GES DISC</name>
    <email>gsfc-mirador-disc@lists.nasa.gov</email>
  </author>
  <id>http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl</id>
  <opensearch:totalResults>12</opensearch:totalResults>
  <opensearch:itemsPerPage>12</opensearch:itemsPerPage>
  <opensearch:startPage>1</opensearch:startPage>
  <link rel="first" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=1&amp;dataSet=SWDB_L3MC10.004&amp;format=atom&amp;osLocation=&amp;endTime=2010-12-31T23%3A59%3A59Z&amp;order=a&amp;startTime=1997-09-01T00%3A00%3A00Z&amp;newtime=&amp;maxgranules=1024"/>
  <link rel="last" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=0&amp;last=1&amp;dataSet=SWDB_L3MC10.004&amp;format=atom&amp;osLocation=&amp;endTime=2010-12-31T23%3A59%3A59Z&amp;order=d&amp;startTime=1997-09-01T00%3A00%3A00Z&amp;newtime=2010-12-31T23%3A59%3A59Z&amp;maxgranules=1024&amp;os_altorder=asc"/>
  <link rel="opensearch:search" type="application/opensearchdescription+xml" href="http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_SWDB_L3MC10.004.xml"/>
  <entry>
    <title>.SWDB_L3MC10.1997.09.01.000000Z.004.h5</title>
    <updated>1997-09-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="5023026" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199709-201009_v004-20130614T144205Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1997-09-01T00:00:00Z/2010-09-30T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1997-09-01T00:00:00Z, end:2010-09-30T23:59:59Z, size:5023026  (1)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1997.10.01.000000Z.004.h5</title>
    <updated>1997-10-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199710-201010_v004-20130614T144207Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4728091" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199710-201010_v004-20130614T144207Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199710-201010_v004-20130614T144207Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199710-201010_v004-20130614T144207Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199710-201010_v004-20130614T144207Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199710-201010_v004-20130614T144207Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199710-201010_v004-20130614T144207Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1997-10-01T00:00:00Z/2010-10-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1997-10-01T00:00:00Z, end:2010-10-31T23:59:59Z, size:4728091  (2)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1997.11.01.000000Z.004.h5</title>
    <updated>1997-11-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199711-201011_v004-20130614T144209Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4432890" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199711-201011_v004-20130614T144209Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199711-201011_v004-20130614T144209Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199711-201011_v004-20130614T144209Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199711-201011_v004-20130614T144209Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199711-201011_v004-20130614T144209Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199711-201011_v004-20130614T144209Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1997-11-01T00:00:00Z/2010-11-30T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1997-11-01T00:00:00Z, end:2010-11-30T23:59:59Z, size:4432890  (3)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1997.12.01.000000Z.004.h5</title>
    <updated>1997-12-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199712-201012_v004-20130614T144211Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4355572" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199712-201012_v004-20130614T144211Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199712-201012_v004-20130614T144211Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199712-201012_v004-20130614T144211Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199712-201012_v004-20130614T144211Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199712-201012_v004-20130614T144211Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199712-201012_v004-20130614T144211Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1997-12-01T00:00:00Z/2010-12-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1997-12-01T00:00:00Z, end:2010-12-31T23:59:59Z, size:4355572  (4)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1998.01.01.000000Z.004.h5</title>
    <updated>1998-01-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199801-201001_v004-20130614T144149Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4452303" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199801-201001_v004-20130614T144149Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199801-201001_v004-20130614T144149Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199801-201001_v004-20130614T144149Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199801-201001_v004-20130614T144149Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199801-201001_v004-20130614T144149Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199801-201001_v004-20130614T144149Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1998-01-01T00:00:00Z/2010-01-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1998-01-01T00:00:00Z, end:2010-01-31T23:59:59Z, size:4452303  (5)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1998.02.01.000000Z.004.h5</title>
    <updated>1998-02-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4641074" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1998-02-01T00:00:00Z/2010-02-28T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1998-02-01T00:00:00Z, end:2010-02-28T23:59:59Z, size:4641074  (6)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1998.03.01.000000Z.004.h5</title>
    <updated>1998-03-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199803-201003_v004-20130614T144153Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4809051" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199803-201003_v004-20130614T144153Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199803-201003_v004-20130614T144153Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199803-201003_v004-20130614T144153Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199803-201003_v004-20130614T144153Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199803-201003_v004-20130614T144153Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199803-201003_v004-20130614T144153Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1998-03-01T00:00:00Z/2010-03-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1998-03-01T00:00:00Z, end:2010-03-31T23:59:59Z, size:4809051  (7)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1998.04.01.000000Z.004.h5</title>
    <updated>1998-04-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199804-201004_v004-20130614T144155Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4706921" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199804-201004_v004-20130614T144155Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199804-201004_v004-20130614T144155Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199804-201004_v004-20130614T144155Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199804-201004_v004-20130614T144155Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199804-201004_v004-20130614T144155Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199804-201004_v004-20130614T144155Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1998-04-01T00:00:00Z/2010-04-30T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1998-04-01T00:00:00Z, end:2010-04-30T23:59:59Z, size:4706921  (8)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1998.05.01.000000Z.004.h5</title>
    <updated>1998-05-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199805-201005_v004-20130614T144157Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4554326" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199805-201005_v004-20130614T144157Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199805-201005_v004-20130614T144157Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199805-201005_v004-20130614T144157Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199805-201005_v004-20130614T144157Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199805-201005_v004-20130614T144157Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199805-201005_v004-20130614T144157Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1998-05-01T00:00:00Z/2010-05-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1998-05-01T00:00:00Z, end:2010-05-31T23:59:59Z, size:4554326  (9)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1998.06.01.000000Z.004.h5</title>
    <updated>1998-06-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199806-201006_v004-20130614T144159Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4516098" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199806-201006_v004-20130614T144159Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199806-201006_v004-20130614T144159Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199806-201006_v004-20130614T144159Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199806-201006_v004-20130614T144159Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199806-201006_v004-20130614T144159Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199806-201006_v004-20130614T144159Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1998-06-01T00:00:00Z/2010-06-30T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1998-06-01T00:00:00Z, end:2010-06-30T23:59:59Z, size:4516098  (10)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1998.07.01.000000Z.004.h5</title>
    <updated>1998-07-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199807-201007_v004-20130614T144201Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4603941" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199807-201007_v004-20130614T144201Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199807-201007_v004-20130614T144201Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199807-201007_v004-20130614T144201Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199807-201007_v004-20130614T144201Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199807-201007_v004-20130614T144201Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199807-201007_v004-20130614T144201Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1998-07-01T00:00:00Z/2010-07-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1998-07-01T00:00:00Z, end:2010-07-31T23:59:59Z, size:4603941  (11)</content>
  </entry>
  <entry>
    <title>.SWDB_L3MC10.1998.08.01.000000Z.004.h5</title>
    <updated>1998-08-01T00:00:00Z</updated>
    <id>http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5</id>
    <link rel="enclosure" type="application/x-hdf" length="4928610" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://measures.gesdisc.eosdis.nasa.gov/data//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5.xml"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://measures.gesdisc.eosdis.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>1998-08-01T00:00:00Z/2010-08-31T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:1998-08-01T00:00:00Z, end:2010-08-31T23:59:59Z, size:4928610  (12)</content>
  </entry>
</feed>
