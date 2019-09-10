# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Map-Info.t'

#########################


use warnings;
use strict;

use File::Temp qw/ tempdir /;
use Giovanni::Util;

use Test::More tests => 4;
BEGIN { use_ok('Giovanni::Map::Util') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $map = "./tMap.xml";
my $dFile = Giovanni::Map::Util::getLayerData($map, "AIRX3STD_006_Temperature_A");
is ($dFile, '\'/var/giovanni/session/30AF0090-5137-11E7-AD4C-97678171EBB9/342DC7BA-5137-11E7-9D8F-CA678171EBB9/342E85D8-5137-11E7-9D8F-CA678171EBB9/g4.timeAvgMap.AIRX3STD_006_Temperature_A.1000hPa.20040101-20040103.180W_90S_180E_90N.nc_AIRX3STD_006_Temperature_A.png\'', 'Get data file location');

$ENV{'GDAL_DATA'} = '/usr/share/gdal';
my %options = (
                   OUTWIDTH  => 1024,
                   OUTHEIGHT => 1024,
                   OUTBBOX   => '-4194304,-4194304,4194304,4194304'
              );
my $outputImg = File::Temp->new(
            TEMPLATE => 'tmp_reproject' . '_XXXX',
            DIR      => './',
            SUFFIX   => '.png'
         );
my $rc = Giovanni::Map::Util::reprojection('tData.png', "EPSG:4326", $outputImg, "EPSG:3031", %options);
ok( $rc, 'reprojection is working');
$rc = Giovanni::Map::Util::reprojection('fData.png', "EPSG:4326", $outputImg, "EPSG:3031", %options);
ok( $rc, 'reprojection is working for without NoData');
