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

my $id = "MYD08_D3.051";
my $osddUrl
    = "http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_OMTO3d.003.xml";
my $sampleFile
    = 'http://acdisc.gesdisc.eosdis.nasa.gov/data/Aura_OMI_Level3/OMTO3d.003/2004/OMI-Aura_L3-OMTO3d_2004m1001_v003-2012m0405t174138.he5';
my $sampleOpendap
    = 'http://acdisc.gesdisc.eosdis.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMTO3d.003/2004/OMI-Aura_L3-OMTO3d_2004m1001_v003-2012m0405t174138.he5.html';
my $accessName = 'UVAerosolIndex';
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
    searchFilter  => "opendap.+OMI-Aura_L3-OMTO3d.+he5.html",
    timeChunks    => [
        { start => "2005-01-01T00:00:00Z",
            end => "2005-01-05T23:59:59Z",
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
for my $item (@$resultSet) {
    $all = $all && ( $item->{file} =~ '\.nc$' );
}
ok( $all, "All labels end in .nc" );
