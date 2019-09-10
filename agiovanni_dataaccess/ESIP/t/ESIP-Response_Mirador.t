# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ESIP-OpenSearch.t'
#$Id: ESIP-Response_Mirador.t,v 1.9 2014/12/10 20:05:32 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

#########################

use XML::LibXML;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
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

my @dataUrlList = $response->getDataUrls();
is( @dataUrlList, 2, "Data URL count verification" );

is_deeply(
    \@dataUrlList,
    [   {   title =>
                "MYD08_D3.A2003001.051.2008331021851.pscs_000500350277.hdf",
            url =>
                "ftp://acdisc.gsfc.nasa.gov/data/s4pa///Aqua_MODIS_Level3/MYD08_D3.051/2003/MYD08_D3.A2003001.051.2008331021851.pscs_000500350277.hdf",
            startTime => '2003-01-01T00:00:00Z',
            endTime   => '2003-01-01T23:59:59Z'
        },
        {   title =>
                "MYD08_D3.A2003002.051.2008331004443.pscs_000500350277.hdf",
            url =>
                "ftp://acdisc.gsfc.nasa.gov/data/s4pa///Aqua_MODIS_Level3/MYD08_D3.051/2003/MYD08_D3.A2003002.051.2008331004443.pscs_000500350277.hdf",
            startTime => '2003-01-02T00:00:00Z',
            endTime   => '2003-01-02T23:59:59Z'
        },
    ],
    "Verified data URLs"
);

__DATA__
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:esipdiscovery="http://commons.esipfed.org/ns/discovery/1.2/" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns:georss="http://www.georss.org/georss" xmlns:geo="http://a9.com/-/opensearch/extensions/geo/1.0/" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:time="http://a9.com/-/opensearch/extensions/time/1.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" esipdiscovery:version="1.2">
  <title>MYD08_D3 Files (search provided by Mirador)</title>
  <subtitle type="html"> (distributed by GES DISC)
          Total Results: 6
          Max Items Per Page:2</subtitle>
  <updated>2009-07-16T18:30:02Z</updated>
  <author>
    <name>GES DISC</name>
    <email>gsfc-mirador-disc@lists.nasa.gov</email>
  </author>
  <id>http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl</id>
  <opensearch:totalResults>6</opensearch:totalResults>
  <opensearch:itemsPerPage>2</opensearch:itemsPerPage>
  <opensearch:startPage>1</opensearch:startPage>
  <link rel="first" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=1&amp;dataSet=MYD08_D3.051&amp;granulePresentation=ungrouped&amp;format=atom&amp;osLocation=&amp;endTime=2003-01-5T23%3A59%3A59Z&amp;order=a&amp;startTime=Wed+Jan+01+00%3A00%3A00+2003&amp;newtime=&amp;maxgranules=2"/>
  <link rel="next" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=2&amp;dataSet=MYD08_D3.051&amp;granulePresentation=ungrouped&amp;format=atom&amp;osLocation=&amp;endTime=2003-01-5T23%3A59%3A59Z&amp;order=a&amp;startTime=Wed+Jan+01+00%3A00%3A00+2003&amp;newtime=Thu+Jan+02+23%3A59%3A59+2003&amp;maxgranules=2"/>
  <link rel="last" href="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?page=1&amp;last=1&amp;dataSet=MYD08_D3.051&amp;granulePresentation=ungrouped&amp;format=atom&amp;osLocation=&amp;endTime=2003-01-5T23%3A59%3A59Z&amp;order=d&amp;startTime=Wed+Jan+01+00%3A00%3A00+2003&amp;newtime=2003-01-5T23%3A59%3A59Z&amp;maxgranules=2&amp;os_altorder=asc"/>
  <link rel="opensearch:search" type="application/opensearchdescription+xml" href="http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_MYD08_D3.051.xml"/>
  <entry>
    <title>MYD08_D3.A2003001.051.2008331021851.pscs_000500350277.hdf</title>
    <updated>2003-01-01T00:00:00Z</updated>
    <id>ftp://acdisc.gsfc.nasa.gov/data/s4pa///Aqua_MODIS_Level3/MYD08_D3.051/2003/MYD08_D3.A2003001.051.2008331021851.pscs_000500350277.hdf</id>
    <link rel="enclosure" type="application/x-hdf" length="81162877" href="ftp://acdisc.gsfc.nasa.gov/data/s4pa///Aqua_MODIS_Level3/MYD08_D3.051/2003/MYD08_D3.A2003001.051.2008331021851.pscs_000500350277.hdf"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="ftp://acdisc.gsfc.nasa.gov/data/s4pa///Aqua_MODIS_Level3/MYD08_D3.051/2003/MYD08_D3.A2003001.051.2008331021851.pscs_000500350277.hdf.xml.xml"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>2003-01-01T00:00:00Z/2003-01-01T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2003-01-01T00:00:00Z, end:2003-01-01T23:59:59Z, size:81162877  (1)</content>
  </entry>
  <entry>
    <title>MYD08_D3.A2003002.051.2008331004443.pscs_000500350277.hdf</title>
    <updated>2003-01-02T00:00:00Z</updated>
    <id>ftp://acdisc.gsfc.nasa.gov/data/s4pa///Aqua_MODIS_Level3/MYD08_D3.051/2003/MYD08_D3.A2003002.051.2008331004443.pscs_000500350277.hdf</id>
    <link rel="enclosure" type="application/x-hdf" length="82272409" href="ftp://acdisc.gsfc.nasa.gov/data/s4pa///Aqua_MODIS_Level3/MYD08_D3.051/2003/MYD08_D3.A2003002.051.2008331004443.pscs_000500350277.hdf"/>
    <link rel="describedBy" type="text/xml" title="Metadata" length="10001" href="ftp://acdisc.gsfc.nasa.gov/data/s4pa///Aqua_MODIS_Level3/MYD08_D3.051/2003/MYD08_D3.A2003002.051.2008331004443.pscs_000500350277.hdf.xml.xml"/>
    <georss:box>-90 -180 90 180</georss:box>
    <dc:date>2003-01-02T00:00:00Z/2003-01-02T23:59:59Z</dc:date>
    <content type="html">format:HDF, start:2003-01-02T00:00:00Z, end:2003-01-02T23:59:59Z, size:82272409  (2)</content>
  </entry>
</feed>
