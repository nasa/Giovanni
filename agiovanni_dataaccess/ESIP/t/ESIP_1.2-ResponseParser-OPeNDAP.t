#!/usr/bin/perl

use XML::LibXML;
use Test::More tests => 3;

BEGIN {
    use_ok('ESIP::ResponseParser::V1_2');
}
use strict;

my $atomNS = 'http://www.w3.org/2005/Atom';
my $osNS   = 'http://a9.com/-/spec/opensearch/1.1/';
my $esipNS = 'http://esipfed.org/ns/fedsearch/1.0/';
my $xml;

while (<DATA>) {
    $xml .= $_;
}

my $dom = getDocument($xml);
my $doc = $dom->documentElement();

my ($authorNode) = $doc->getChildrenByTagNameNS( $atomNS, 'author' );
my ($authorNameNode) = $authorNode->getChildrenByTagNameNS( $atomNS, 'name' );
ok( $authorNameNode->textContent() eq "GES DISC" );

#my $package = ESIP::ResponseParser::V1_2->new( XML  => $dom, TYPE => "application/x-hdf");

my $package = ESIP::ResponseParser::V1_2->new(
    XML  => $dom,
    TYPE => "application/x-hdf",
    sampleOpendap =>
        "https://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.html",
    searchFilter => "OMI-Aura_L3-OMAERUVd.+he5.html"
);

my $urlList = $package->getOPeNDAPUrls();

ok( $#$urlList == 4, "number of urls" );

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
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:esipdiscovery="http://commons.esipfed.org/ns/discovery/1.2/" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns:georss="http://www.georss.org/georss" xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" esipdiscovery:version="1.2">
  <title>OMAERUVd Files (search provided by Mirador)</title>
  <subtitle type="html">OMI/Aura Near UV Aerosol Optical Depth and Single Scattering Albedo Daily L3 Global 1x1 deg Lat/Lon Grid (distributed by GES DISC)
          Total Results: 5
          Max Items Per Page:5</subtitle>
  <updated>2009-07-16T18:30:02Z</updated>
  <author>
    <name>GES DISC</name>
    <email>gsfc-mirador-disc@lists.nasa.gov</email>
  </author>
  <id>http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl</id>
  <opensearch:totalResults>5</opensearch:totalResults>
  <opensearch:itemsPerPage>5</opensearch:itemsPerPage>
  <opensearch:startPage>1</opensearch:startPage>
  <link rel="first" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=1&amp;dataSet=OMAERUVd.003&amp;granulePresentation=ungrouped&amp;format=atom&amp;osLocation=&amp;endTime=2006-01-05T23%3A59%3A59Z&amp;order=a&amp;startTime=Sun+Jan+01+00%3A00%3A00+2006&amp;newtime=&amp;maxgranules=1000"/>
  <link rel="last" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=1&amp;last=1&amp;dataSet=OMAERUVd.003&amp;granulePresentation=ungrouped&amp;format=atom&amp;osLocation=&amp;endTime=2006-01-05T23%3A59%3A59Z&amp;order=d&amp;startTime=Sun+Jan+01+00%3A00%3A00+2006&amp;newtime=2006-01-05T23%3A59%3A59Z&amp;maxgranules=1000&amp;os_altorder=asc"/>
  <link rel="opensearch:search" type="application/opensearchdescription+xml" href="http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_OMAERUVd.003.xml"/>
  <entry>
    <title>OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5</title>
    <updated>2006-01-01T00:00:00Z</updated>
    <id>http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="349439" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="349439" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/browse#" type="image/jpeg" title="Browse Image" length="10000" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-01 00:00:00&amp;shortname=OMAERUVd"/>
    <link rel="icon" title="Browse Image" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-01 00:00:00&amp;shortname=OMAERUVd" type="image/jpeg"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/netcdf#" type="application/netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.nc"/>
    <link rel="enclosure" type="application/x-netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.nc"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0101_v003-2012m0325t115150.he5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <time:start>2006-01-01T00:00:00Z</time:start>
    <time:end>2006-01-01T23:59:59Z</time:end>
    <dc:date>2006-01-01T00:00:00Z/2006-01-01T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2006-01-01T00:00:00Z, end:2006-01-01T23:59:59Z, size:349439  (1)</content>
  </entry>
  <entry>
    <title>OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5</title>
    <updated>2006-01-02T00:00:00Z</updated>
    <id>http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="344098" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="344098" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/browse#" type="image/jpeg" title="Browse Image" length="10000" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-02 00:00:00&amp;shortname=OMAERUVd"/>
    <link rel="icon" title="Browse Image" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-02 00:00:00&amp;shortname=OMAERUVd" type="image/jpeg"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/netcdf#" type="application/netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5.nc"/>
    <link rel="enclosure" type="application/x-netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5.nc"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0102_v003-2012m0325t115114.he5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <time:start>2006-01-02T00:00:00Z</time:start>
    <time:end>2006-01-02T23:59:59Z</time:end>
    <dc:date>2006-01-02T00:00:00Z/2006-01-02T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2006-01-02T00:00:00Z, end:2006-01-02T23:59:59Z, size:344098  (2)</content>
  </entry>
  <entry>
    <title>OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5</title>
    <updated>2006-01-03T00:00:00Z</updated>
    <id>http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="348219" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="348219" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/browse#" type="image/jpeg" title="Browse Image" length="10000" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-03 00:00:00&amp;shortname=OMAERUVd"/>
    <link rel="icon" title="Browse Image" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-03 00:00:00&amp;shortname=OMAERUVd" type="image/jpeg"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/netcdf#" type="application/netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5.nc"/>
    <link rel="enclosure" type="application/x-netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5.nc"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0103_v003-2012m0325t115126.he5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <time:start>2006-01-03T00:00:00Z</time:start>
    <time:end>2006-01-03T23:59:59Z</time:end>
    <dc:date>2006-01-03T00:00:00Z/2006-01-03T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2006-01-03T00:00:00Z, end:2006-01-03T23:59:59Z, size:348219  (3)</content>
  </entry>
  <entry>
    <title>OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5</title>
    <updated>2006-01-04T00:00:00Z</updated>
    <id>http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="348904" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="348904" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/browse#" type="image/jpeg" title="Browse Image" length="10000" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-04 00:00:00&amp;shortname=OMAERUVd"/>
    <link rel="icon" title="Browse Image" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-04 00:00:00&amp;shortname=OMAERUVd" type="image/jpeg"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/netcdf#" type="application/netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5.nc"/>
    <link rel="enclosure" type="application/x-netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5.nc"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0104_v003-2012m0325t115135.he5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <time:start>2006-01-04T00:00:00Z</time:start>
    <time:end>2006-01-04T23:59:59Z</time:end>
    <dc:date>2006-01-04T00:00:00Z/2006-01-04T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2006-01-04T00:00:00Z, end:2006-01-04T23:59:59Z, size:348904  (4)</content>
  </entry>
  <entry>
    <title>OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5</title>
    <updated>2006-01-05T00:00:00Z</updated>
    <id>http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5</id>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/data#" length="357222" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/metadata#" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5.xml"/>
    <link rel="enclosure" type="application/x-hdf" length="357222" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10000" href="http://acdisc.gsfc.nasa.gov/data/s4pa/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5.xml"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/browse#" type="image/jpeg" title="Browse Image" length="10000" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-05 00:00:00&amp;shortname=OMAERUVd"/>
    <link rel="icon" title="Browse Image" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/getBrowseImage.pl?startTime=2006-01-05 00:00:00&amp;shortname=OMAERUVd" type="image/jpeg"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/netcdf#" type="application/netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5.nc"/>
    <link rel="enclosure" type="application/x-netcdf" title="Same File in NetCDF Format" length="10000000" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5.nc"/>
    <link rel="http://esipfed.org/ns/fedsearch/1.0/opendap#" type="application/opendap" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5.html"/>
    <link rel="enclosure" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" type="application/x-hdf" title="OPENDAP" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#html" title="OPeNDAP HTML Form interface access" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5.html"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#info" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5.info"/>
    <link rel="describedBy" type="text/html" xlink:type="simple" xlink:role="http://xml.opendap.org/dap/dap2.xsd" xlink:arcrole="#ddx" title="OPeNDAP information" href="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2006/OMI-Aura_L3-OMAERUVd_2006m0105_v003-2012m0325t115141.he5.ddx"/>
    <georss:box>-90 -180 90 180</georss:box>
    <time:start>2006-01-05T00:00:00Z</time:start>
    <time:end>2006-01-05T23:59:59Z</time:end>
    <dc:date>2006-01-05T00:00:00Z/2006-01-05T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2006-01-05T00:00:00Z, end:2006-01-05T23:59:59Z, size:357222  (5)</content>
  </entry>
</feed>
