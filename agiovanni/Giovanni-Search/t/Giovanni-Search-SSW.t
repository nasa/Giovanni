#$Id: Giovanni-Search-SSW.t,v 1.4 2015/06/30 17:10:25 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Search.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Giovanni::Search::SSW') }

#########################

use strict;
use File::Temp qw/ tempfile tempdir /;

use Giovanni::Util;

my $dir = tempdir( CLEANUP => 1 );
my $sessionDir = "$dir/session";
mkdir($sessionDir) or die "Unable to make directory $sessionDir, $!";

my @chunks = Giovanni::Util::chunkDataTimeRange(
    dataStartTime          => "2004-10-01T00:00:00Z",
    dataEndTime            => "2016-01-01T23:59:59Z",
    dataStartTimeOffset    => "1",
    dataEndTimeOffset      => "0",
    searchStartTime        => "2004-10-01T00:00:00Z",
    searchEndTime          => "2004-10-02T23:59:59Z",
    searchIntervalDays     => "365",
    dataTemporalResolution => 'daily',
);

my @startTimes = map( $_->{start}, @chunks );
my @endTimes   = map( $_->{end},   @chunks );
my @isPartial = map( $_->{overlap} =~ /partial/ ? 1 : 0, @chunks );

my $dataId = "OMAERUVd_003_FinalAerosolAbsOpticalDepth388";
my $baseUrl
    = 'https://giovanni-test.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=OMI%2FAura%20Near%20UV%20Aerosol%20Optical%20Depth%20and%20Single%20Scattering%20Albedo%20Daily%20L3%20Global%201x1%20deg%20Lat%2FLon%20Grid%20V003;agent_id=OPeNDAP;variables=FinalAerosolAbsOpticalDepth388&output_type=xml';

# create the search object
my $searcher = Giovanni::Search::SSW->new(
    sessionDir => $sessionDir,
    dataId     => $dataId
);

my ( $resultUrlsRef, $resultFilenamesRef ) = $searcher->search(
    startTime => \@startTimes,
    endTime   => \@endTimes,
    isPartial => \@isPartial,
    baseUrl   => $baseUrl
);

is( scalar( @{$resultUrlsRef} ), 2, "Got 2 URLs" );

1;
