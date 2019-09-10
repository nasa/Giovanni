#$Id: Giovanni-UrlDownloader.t,v 1.7 2013/08/28 19:24:10 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-UrlDownloader.t'
# This script expects the environment variables GIOVANNI_DOWNLOAD_USER and
# GIOVANNI_DOWNLOAD_PWD to be set to the Earthdata login username and
# password for a user that has been registered in Earthdata login
#########################

use Test::More tests => 22;
BEGIN { use_ok('Giovanni::UrlDownloader') }

use File::Temp qw/tempdir/;

#########################

# create a downloader
my $downloader = Giovanni::UrlDownloader->new(
    TIME_OUT        => 10,
    MAX_RETRY_COUNT => 1,
    RETRY_INTERVAL  => 0
);

# create a temporary directory for these files
my $dir = tempdir( CLEANUP => 1 );

# try a slightly wrong TRMM
$response = $downloader->download(
    URL =>
        "http://disc2.nascom.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fftp%2Fdata%2Fs4pa%2FTRMM_L3%2FTRMM_3B42_daily.6%2F2002%2F365%2F3B42_daily.2003.01.01.6.bin&FORMAT=bmV0Q0RGLw&LABEL=3B42_daily.2003.01.01.6.nc&SHORTNAME=TRMM_3B42_daily&SERVICE=HDF_TO_NetCDFasldknf&VERSION=1.02&DATASET_VERSION=6",
    DIRECTORY       => $dir,
    FILENAME        => "3B42_daily.2003.01.01.6.nc",
    RESPONSE_FORMAT => "netCDF",
);
ok( $response->{ERROR}, "Error message for weird TRMM URL" );
ok( !( -f "$dir/3B42_daily.2003.01.01.6.nc" ),
    "File doesn't exist because nothing to download"
);

# try a crazy URL that doesn't exist
my $response = $downloader->download(
    URL             => "lknasdlfknasdfl09j23409jafk.com",
    DIRECTORY       => $dir,
    FILENAME        => "notreal.txt",
    RESPONSE_FORMAT => "netCDF",
);

ok( $response->{ERROR}, "Error message for weird URL" );
ok( !( -f "$dir/notreal.txt" ),
    "File doesn't exist because nothing to download" );

# try getting a regular TRMM URL (nothing special...)
$response = $downloader->download(
    URL =>
         "https://disc2.gesdisc.eosdis.nasa.gov/opendap/TRMM_L3/TRMM_3B42_Daily.7/2003/01/3B42_Daily.20030101.7.nc4.nc?precipitation[0:1439][0:399],lat[0:399],lon[0:1439]",
    DIRECTORY       => $dir,
    FILENAME        => "3B42_Daily.20030101.7.nc4.nc",
    RESPONSE_FORMAT => "netCDF",
);

ok( !$response->{ERROR}, "No error message" );
is( $response->{FILEPATH},
    $dir . "/3B42_Daily.20030101.7.nc4.nc",
    "File path correct"
);
ok( -f $response->{FILEPATH},  "TRMM file exists" );
ok( !$response->{USED_NCCOPY}, "Didn't use nccopy" );

# now try and NLDAS URL, which does use nccopy
$response = $downloader->download(
    URL =>
        "http://hydro1.sci.gsfc.nasa.gov/thredds/dodsC/NLDAS_FORA0125_H.002/2004/001/NLDAS_FORA0125_H.A20040101.0000.002.grb?N2-m_above_ground_Temperature[0:0][0:0][0:223][0:463],lat[0:223],time[0:0],height_above_ground,lon[0:463]",
    DIRECTORY       => $dir,
    FILENAME        => "NLDAS_FORA0125_H.A20030101.0000.002.grb",
    RESPONSE_FORMAT => "DAP",
);

ok( !$response->{ERROR}, "No error message" );
is( $response->{FILEPATH},
    $dir . "/NLDAS_FORA0125_H.A20030101.0000.002.grb",
    "File path correct"
);
ok( -f $response->{FILEPATH}, "NLDAS file exists" );
ok( $response->{USED_NCCOPY}, "Used nccopy" );

# try a slightly wrong OPenDAP
$response = $downloader->download(
    URL =>
        "http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2005/OMI-Aura_L3-OMAERUVd_2005m0101_v003-2012m0325t101640.he5.nc?FinalAerosolAbsOpticalDepth3882,lat,lon",
    DIRECTORY       => $dir,
    FILENAME        => "wrong.nc",
    RESPONSE_FORMAT => "netCDF",
);
ok( $response->{ERROR}, "Error message for weird OPeNDAP URL" );

# try a slightly wrong OPenDAP, but don't do checks. This will actually
# download a file with an error message in it.
$response = $downloader->download(
    URL =>
        "http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMAERUVd.003/2005/OMI-Aura_L3-OMAERUVd_2005m0101_v003-2012m0325t101640.he5.nc?FinalAerosolAbsOpticalDepth3882,lat,lon",
    DIRECTORY       => $dir,
    FILENAME        => "wrong.nc",
    RESPONSE_FORMAT => "NO_CHECK",
);
ok( !$response->{ERROR}, "Didn't check file." );

# Try a case where an OPeNDAP granule requires credentials without providing
# the credentials
$response = $downloader->download(
    URL =>
        "https://opendap.cr.usgs.gov/opendap/hyrax//MODIS_Composites/MOLA/MYD11C3.005/2016.12.01/MYD11C3.A2016336.005.2017009020411.hdf.nc?LST_Night_CMG[0:3599][0:7199],Longitude[0:7199],Latitude[0:3599]",
    DIRECTORY       => $dir,
    FILENAME        => "MYD11C3.A2016336.005.2017009020411.hdf.MYD11C3_005_LST_Night_CMG.nc",
    RESPONSE_FORMAT => "netCDF",
);
ok( $response->{ERROR}, "Error message for OPeNDAP with missing credentials" );
ok( !( -f "$dir/MYD11C3.A2016336.005.2017009020411.hdf.MYD11C3_005_LST_Night_CMG.nc" ),
    "File doesn't exist because nothing to download"
);

# Try a case where an OPeNDAP granule requires credentials and credentials are
# provided
ok ($ENV{GIOVANNI_DOWNLOAD_USER}, "GIOVANNI_DOWNLOAD_USER environment variable set before running test");
ok ($ENV{GIOVANNI_DOWNLOAD_PWD}, "GIOVANNI_DOWNLOAD_PWD environment variable set before running test");
my $credentialsRef = {
  # Basic authentication credentials, grouped by location and realm
  'urs.earthdata.nasa.gov:443' => {
    "Please enter your Earthdata Login credentials. If you do not have a Earthdata Login; create one at https://urs.earthdata.nasa.gov//users/new" => {
      DOWNLOAD_USER => $ENV{GIOVANNI_DOWNLOAD_USER},
      DOWNLOAD_CRED => $ENV{GIOVANNI_DOWNLOAD_PWD},
    },
    "Please enter your Earthdata Login credentials. If you do not have a Earthdata Login, create one at https://urs.earthdata.nasa.gov//users/new" => {
      DOWNLOAD_USER => $ENV{GIOVANNI_DOWNLOAD_USER},
      DOWNLOAD_CRED => $ENV{GIOVANNI_DOWNLOAD_PWD},
    }
  }
};
my $downloaderCred = Giovanni::UrlDownloader->new(
    TIME_OUT        => 60,
    MAX_RETRY_COUNT => 1,
    RETRY_INTERVAL  => 0,
    CREDENTIALS     => $credentialsRef,
);
$response = $downloaderCred->download(
    URL =>
        "https://opendap.cr.usgs.gov/opendap/hyrax//MODIS_Composites/MOLA/MYD11C3.005/2016.12.01/MYD11C3.A2016336.005.2017009020411.hdf.nc?LST_Night_CMG[0:3599][0:7199],Longitude[0:7199],Latitude[0:3599]",
    DIRECTORY       => $dir,
    FILENAME        => "MYD11C3.A2016336.005.2017009020411.hdf.MYD11C3_005_LST_Night_CMG.nc",
    RESPONSE_FORMAT => "netCDF",
);
ok( !$response->{ERROR}, "No error message for OPeNDAP with credentials" );
is( $response->{FILEPATH},
    $dir . "/MYD11C3.A2016336.005.2017009020411.hdf.MYD11C3_005_LST_Night_CMG.nc",
    "File path correct"
);
ok( -f $response->{FILEPATH},  "MYD11C3 file exists" );
