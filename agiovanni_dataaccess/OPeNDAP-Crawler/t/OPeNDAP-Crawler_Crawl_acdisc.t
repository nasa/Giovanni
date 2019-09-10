# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OPeNDAP-Crawler_Crawl_acdisc.t

no warnings "all";

#########################
use Test::More tests => 3;
use XML::LibXML;

BEGIN {
    use_ok("OPeNDAP::Crawler");
}

my $crawler = OPeNDAP::Crawler->new(
    datasetID => 'AIRH3STD.006',
    catalog   => 'http://acdisc.sci.gsfc.nasa.gov/opendap/'
        . 'hyrax/Aqua_AIRS_Level3/AIRH3STD.006/catalog.xml',
);

# Check results against how many were expected at the time
# of writing.
my $numExpected = 157;

# Check return value of crawl()
my $numGotCrawl = $crawler->crawl();
ok( ( $numGotCrawl >= $numExpected ),
    "Got at least $numExpected granules from crawl() (found $numGotCrawl)" );

# Check number of <doc> elements in createSolrDoc()
my $xml       = $crawler->createSolrDoc();
my $xmlDoc    = XML::LibXML->load_xml( string => $xml );
my $numGotXml = 0;
$numGotXml++ for @{ $xmlDoc->findnodes('.//doc') };

ok( ( $numGotXml >= $numExpected ),
    "Found at least $numExpected <doc> elements in createSolrDoc() (found $numGotXml)"
);
