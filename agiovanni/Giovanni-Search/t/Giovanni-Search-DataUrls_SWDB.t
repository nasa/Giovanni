#!/usr/bin/perl
use Test::More tests => 5;
use File::Temp qw/tempdir/;

$ENV{PERL5LIB} = "../Giovanni-Logger/lib";
use Giovanni::Logger;
BEGIN { use_ok('Giovanni::Search::OPeNDAP') }

#################
# Execute Phase #
#################
my $tempDir    = tempdir( "/tmp/temp_XXXX", CLEANUP => 1 );
my $sessionDir = "$tempDir/session/";
mkdir($sessionDir);

my $id = "SWDB_L3MC10_004_aerosol_optical_thickness_550_land_ocean";
my $osddUrl
    = "http://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_SWDB_L3MC10.004.xml";
my $sampleFile
    = 'http://measures.gesdisc.eosdis.nasa.gov/data/s4pa//DeepBlueSeaWiFS_Level3/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5';
my $sampleOpendap
    = 'http://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199802-201002_v004-20130614T144151Z.h5.html';
my $accessName = 'aerosol_optical_thickness_550_land_ocean';
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

    #    searchFilter  => 'hellothere',
    timeChunks => [
        { start => "1998-08-01T00:00:00Z",
            end => "1998-12-05T23:59:59Z",
        }
    ],
);

my ( $ra_resultSet, $ra_searchUrls ) = $odSearch->search();

################
# Verify Phase #
################
# 'http://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3MC10.004/DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5.nc?aerosol_optical_thickness_550_land_ocean[0:179][0:359],longitude[0:359],latitude[0:179]' => HASH(0x473e6f0)
#       'endTime' => '2010-08-31T23:59:59Z'
#       'file' => 'DeepBlue-SeaWiFS-1.0_L3MC_199808-201008_v004-20130614T144203Z.h5.nc'
#       'startTime' => '1998-08-01T00:00:00Z'
#  Return is now a hash so urls == labels is guaranteed:
is( scalar(@$ra_resultSet), 12, "Got correct amount of OPeNDAP URLs" );
ok( scalar(@$ra_searchUrls) > 0, "Got at least one Search URL" );

my $all;

$all = 1;
foreach my $item (@$ra_resultSet) {
    $all = $all && ( $item->{url} =~ $accessName );
}
ok( $all, "All opendap URLs contain access name" );

$all = 1;
foreach my $item (@$ra_resultSet) {
    $all = $all && ( $item->{label} =~ '\.nc$' );
}

ok( $all, "All labels end in .nc" );
