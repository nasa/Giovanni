#!/usr/bin/perl

use OPeNDAP::Crawler;
use Getopt::Long;
use Giovanni::Util;

my $dataSetId      = undef;
my $catalogUrl     = undef;
my $threadCount    = OPeNDAP::Crawler::DEFAULT_NUM_THREADS;
my $grepPattern    = undef;
my $solrDocFile    = undef;
my $rollingUpload  = undef;
my $solrApiPrefix  = undef;
my $solrCollection = undef;

Getopt::Long::GetOptions(
    'datasetId=s'      => \$dataSetId,
    'catalog=s'        => \$catalogUrl,
    'maxThreads=i'     => \$threadCount,
    'grepPattern=s'    => \$grepPattern,
    'solrDocFile=s'    => \$solrDocFile,
    'rollingUpload=s'  => \$rollingUpload,
    'solrApiPrefix=s'  => \$solrApiPrefix,
    'solrCollection=s' => \$solrCollection
);

my $crawler = OPeNDAP::Crawler->new(
    datasetID   => $dataSetId,
    catalog     => $catalogUrl,
    numThreads  => $threadCount,
    grepPattern => $grepPattern
);

my $urlCount = $crawler->crawl(
    rollingUpload  => $rollingUpload,
    solrApiPrefix  => $solrApiPrefix,
    solrCollection => $solrCollection
);

die "Failed to find any OPeNDAP file URL" unless defined $urlCount;

if ( defined $solrDocFile ) {
    my $solrDoc = $crawler->createSolrDoc();
    Giovanni::Util::writeFile( $solrDocFile, $solrDoc )
        or die "Failed to write $solrDocFile";
}

