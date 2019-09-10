#!/usr/bin/perl
use Test::More tests => 5;
use File::Temp qw/tempdir/;

$ENV{PERL5LIB} = "../Giovanni-Logger/lib";
use Giovanni::Logger;
BEGIN { use_ok('Giovanni::Search::OPeNDAP') }

#################
# Execute Phase #
#################
my $tempDir = tempdir( "/tmp/temp_XXXX", CLEANUP => 1 );
my $sessionDir = "$tempDir/session/";
mkdir($sessionDir);

my $id = "L3m_MO_SST4_sst4_4km.2014";

# Even though this isn't the OSDD that EarthData Search provides, if you replace OB.DAAC with OB_DAAC, it still returns an OSDD
my $osddUrl
    = "https://cmr.earthdata.nasa.gov/opensearch/granules/descriptor_document.xml?utf8=%E2%9C%93&clientId=giovanni&shortName=MODISA_L3m_SST&versionId=2014&dataCenter=OB_DAAC&commit=Generate";
my $sampleFile
    = 'http://oceandata.sci.gsfc.nasa.gov/cmr/getfile/A20152132015243.L3m_MO_SST4_sst4_4km.nc';
my $sampleOpendap
    = 'http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2015/213/A20152132015243.L3m_MO_SST4_sst4_4km.nc';
my $accessName = 'sst4';
my $logger     = Giovanni::Logger->new(
    session_dir       => $sessionDir,
    manifest_filename => 'mfst.unittest+blah.xml'
);

my $odSearch = Giovanni::Search::OPeNDAP->new(
    id            => $id,
    osddUrl       => $osddUrl,
    accessName    => $accessName,
    sampleFile    => $sampleFile,
    sampleOpendap => $sampleOpendap,
    logger        => $logger,
    dataId        => $id,
    sessionDir    => $tempDir,
    searchFilter  => "opendap.+L3m_MO_SST4_sst4_4km",

    # Only data at this point is in 2015
    timeChunks => [
        {   start => "2015-08-01T00:00:00Z",
            end   => "2015-12-05T23:59:59Z",
        }
    ],
);

my ( $ra_resultSet, $ra_searchUrls ) = $odSearch->search();

################
# Verify Phase #
################
is( scalar(@$ra_resultSet), 5, "Got same amount of labels as OPeNDAP URLs" );
ok( scalar(@$ra_searchUrls) > 0, "Got at least one Search URL" );

my $all;

$all = 1;
for my $item (@$ra_resultSet) {
    $all = $all && ( $item->{url} =~ $accessName );
}
ok( $all, "All opendap URLs contain access name" );

$all = 1;
for my $item (@$ra_resultSet) {
    $all = $all && ( $item->{label} =~ '\.nc$' );
}
ok( $all, "All labels end in .nc" );
