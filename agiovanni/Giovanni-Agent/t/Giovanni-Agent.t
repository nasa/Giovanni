#!/usr/bin/env perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Agent.t'

#########################
use File::Temp qw/ tempfile tempdir /;
use File::Basename;
use Safe;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 46;
BEGIN { use_ok('Giovanni::Agent') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $agent = Giovanni::Agent->new();
ok( $agent,          "Created agent when no URL was provided" );
ok( $agent->onError, "Flagged error when no URL was provided" );
is( $agent->errorMessage,
    "No URL provided",
    "Error message when no URL was provided"
);

my $url;
$agent = Giovanni::Agent->new( URL => $url );
ok( $agent,          "Created agent when undefined URL was provided" );
ok( $agent->onError, "Flagged error when undefined URL was provided" );
is( $agent->errorMessage,
    "No URL provided",
    "Error message when undefined URL was provided"
);

$url = 'http://nonexistenthost.domain';
$agent = Giovanni::Agent->new( URL => $url );
ok( $agent,           "Created agent when bad URL was provided" );
ok( !$agent->onError, "No error when bad URL was provided" );
can_ok( $agent, qw(submit_request) );

my $response = $agent->submit_request;
ok( $response, "Got response when bad request was submitted" );
can_ok( $response, qw(is_success) );
ok( !$response->is_success,
    "Got unsuccessful response when bad request was submitted" );
can_ok( $response, qw(message) );
ok( $response->message,
    "Got error message in response when bad request was submitted" );

# Test downloaded files: for a bad request, there shouldn't be any downloaded files
my @downloadedFiles = $response->getDownloadedDataFileNames();
is( @downloadedFiles, 0, "No downloaded file paths found for a bad request" );

# Assume the following:
#   -- portal GIOVANNI exists
#   -- service INTERACTIVE_MAP exists
#   -- data field AIRX3STD_006_SurfSkinTemp_A exists
#   -- data field has data from 2012-02-02T00:00:00Z to 2012-02-02T00:59:59Z
#   -- service can be performed for global bounding box

my $LOGIN_CREDENTIALS={
  # Basic authentication credentials, grouped by location and realm
  'urs.earthdata.nasa.gov:443' => {
    "Please enter your Earthdata Login credentials. If you do not have a Earthdata Login; create one at https://urs.earthdata.nasa.gov//users/new" => {
      DOWNLOAD_USER => 'giovanniDownload',
      DOWNLOAD_CRED => 'BuildingABr1dge!',
    },
    "Please enter your Earthdata Login credentials. If you do not have a Earthdata Login, create one at https://urs.earthdata.nasa.gov//users/new" => {
      DOWNLOAD_USER => 'giovanniDownload',
      DOWNLOAD_CRED => 'BuildingABr1dge!',
    }
  }
};

my $cpt = Safe->new();
$cpt->reval($GIOVANNI::LOGIN_CREDENTIALS);
$GIOVANNI::LOGIN_CREDENTIALS = $LOGIN_CREDENTIALS;
# These credentials aren't the whole picture. You need to have the URS cookie in your .netrc file

$url="http://giovanni.gsfc.nasa.gov/giovanni/daac-bin/service_manager.pl?service=ArAvTs&starttime=2006-01-01T00:00:00Z&endtime=2006-01-03T23:59:59Z&bbox=-180,-90,180,90&data=AIRX3STD_006_SurfSkinTemp_A";
$agent = Giovanni::Agent->new( URL => $url, DEBUG => 1 );
ok( $agent,                "Created agent when valid URL was provided" );
ok( !$agent->onError,      "No error when valid URL was provided" );
ok( !$agent->errorMessage, "No error message when valid URL was provided" );
$response = $agent->submit_request;
ok( $response, "Got response when valid request was submitted" );
ok( $response->is_success,
    "Got successful response when valid request was submitted" );
ok( !$response->errorMessage,
    "No error message when valid request was submitted" );

my $working_dir = tempdir( CLEANUP => 1 );
ok((-e $working_dir), "Working directory: $working_dir");




my $downloadResponse = $response->download_data_files(
                                                      DIR => $working_dir
                                                     );
$downloadResponse = $downloadResponse->download_image_files(
                                                      DIR => $working_dir
                                                  );
can_ok($downloadResponse, qw(download_data_files));
ok ($response, "Got response when download data request was submitted");
ok ($response->is_success, "Got successful response when download data request was submitted...because my .netrc was set up for EarthData Login");
is ($response->message, "OK", "Got successful message when download data request was submitted");
# Test downloaded files: for a good request, there should be downloaded files
@downloadedFiles = $downloadResponse->getDownloadedDataFileNames();
is (@downloadedFiles, 1, "Got downloaded data file path from response");
is (dirname($downloadedFiles[0]), $working_dir, "Downloaded data file is found in the specified working directory");
ok( -f $downloadedFiles[0], "Downloaded data file exists");
my @imgFiles = $downloadResponse->getDownloadedImageFileNames();
is (@imgFiles, 1, "Got downloaded image file path from response");
is (dirname($imgFiles[0]), $working_dir, "Downloaded image file is found in the specified working directory");
ok( -f $imgFiles[0], "Downloaded image file exists");


$url = 'http://giovanni.gsfc.nasa.gov/giovanni/#service=TmAvMp&starttime=2012-02-02T00:00:00Z&endtime=2012-02-02T00:59:59Z&bbox=-180,-90,180,90&data=MOD08_D3_6_1_Deep_Blue_Aerosol_Optical_Depth_550_Land_Mean&variableFacets=dataFieldMeasurement%3AAerosol%20Optical%20Depth%3B&dataKeyword=MOD08_D3';
$agent = Giovanni::Agent->new( URL => $url, DEBUG => 1 );
ok( $agent, "Created agent when valid bookmarkable URL was provided" );
ok( !$agent->onError, "No error when valid bookmarkable URL was provided" );
ok( !$agent->errorMessage,
    "No error message when valid bookmarkable URL was provided" );
$response = $agent->submit_request;
ok( $response, "Got response when valid request was submitted" );
ok( $response->is_success,
    "Got successful response when valid request was submitted" );
ok( !$response->errorMessage,
    "No error message when valid request was submitted" );

$working_dir = tempdir( CLEANUP => 0 );
ok( ( -e $working_dir ), "Working directory: $working_dir" );

$downloadResponse = $response->download_data_files( DIR => $working_dir );
can_ok( $downloadResponse, qw(download_data_files) );
ok( $response, "Got response when download data request was submitted" );
ok( $response->is_success,
    "Got successful response when download data request was submitted" );
is( $response->message, "OK",
    "Got successful message when download data request was submitted" );

$url = 'http://disc.sci.gsfc.nasa.gov/#fragment';
$agent = Giovanni::Agent->new( URL => $url );
ok( $agent,          "Created agent when non-Giovanni URL was provided" );
ok( $agent->onError, "Error when non-Giovanni URL was provided" );

#$url = "http://s4ptu-ts2.ecs.nasa.gov/daac-bin/giovanni/service_manager.pl?session=7AF44C6A-6BDA-11E2-A226-8E797D861513&service=TIME_AVERAGED_MAP&starttime=2012-02-02T00:00:00Z&endtime=2012-02-02T00:59:59Z&bbox=-180,-90,180,90&data=MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean&variableFacets=parameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3B&portal=GIOVANNI&format=json";
