#$Id: Giovanni-Workflow_getStatus.t,v 1.4 2013/09/30 17:52:57 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# tests the Giovanni::Workflow::getStatus().

#########################

use Test::More tests => 2;
use File::Temp qw(tempdir);
use Date::Parse;
use strict;

BEGIN { use_ok('Giovanni::Workflow') }

#########################

# create a temporary directory
my $dir = tempdir( CLEANUP => 1 );

# name the target
my $target
    = "mfst.data_fetch+dMOD11C3_006_LST_Day_CMG+t20010101000000_20061231235959.xml";
my $log
    = "mfst.data_fetch+dMOD11C3_006_LST_Day_CMG+t20010101000000_20061231235959.log";

my $logText = <<LOG_TEXT;
2018-07-17 14:46:12,352 - [INFO ] - data_fetch - USER_MSG Updating metadata in file
2018-07-17 14:46:12,353 - [INFO ] - data_fetch - About to run command "ncScrubber.pl --catalog '/var/giovanni/session/2EED6F54-89CF-11E8-B6B0-F9F17DC1AD7A/384FE7A2-89CF-11E8-925B-B8F77DC1AD7A/38554F76-89CF-11E8-925B-B8F77DC1AD7A//mfst.data_field_info+dMOD11C3_006_LST_Day_CMG.xml' --outDir '/var/giovanni/session/2EED6F54-89CF-11E8-B6B0-F9F17DC1AD7A/384FE7A2-89CF-11E8-925B-B8F77DC1AD7A/38554F76-89CF-11E8-925B-B8F77DC1AD7A//' --input '/var/giovanni/session/2EED6F54-89CF-11E8-B6B0-F9F17DC1AD7A/384FE7A2-89CF-11E8-925B-B8F77DC1AD7A/38554F76-89CF-11E8-925B-B8F77DC1AD7A///scrubberInput_0_mfst.data_fetch+dMOD11C3_006_LST_Day_CMG+t20010101000000_20061231235959.xml'"
2018-07-17 14:46:12,901 - [INFO ] - data_fetch - Unrecognized message: STEP_DESCRIPTION Preparing data for processing
2018-07-17 14:46:12,903 - [INFO ] - data_fetch - USER_MSG Preparing file 1 / 20: MOD11C3.A2001001.006.2015112224542.hdf.MOD11C3_006_LST_Day_CMG.nc
2018-07-17 14:46:26,067 - [INFO ] - data_fetch - datestring for MODIS = 2001-01-01
2018-07-17 14:46:26,491 - [INFO ] - data_fetch - [STDOUT message] ncrename: In total renamed 0 attributes, 1 dimension, 0 groups, and 0 variables
2018-07-17 14:46:33,000 - [INFO ] - data_fetch - Unrecognized message: ncatted: ERROR File contains no variables or groups that match name gregorian so attribute calendar cannot be changed
2018-07-17 14:46:33,141 - [INFO ] - data_fetch - [STDOUT message] ncrename: In total renamed 0 attributes, 0 dimensions, 0 groups, and 1 variable
2018-07-17 14:46:54,134 - [INFO ] - data_fetch - Unrecognized message: No reordering of dimensions was necessary <time,lat,lon> == <time,lat,lon> at /opt/giovanni4/share/perl5/Giovanni/Data/NcFile.pm line 2276.
2018-07-17 14:46:54,416 - [INFO ] - data_fetch - No padding/shifting performed
LOG_TEXT

writeTempFile( "$dir/$log", $logText );

my ( $status, $percentDone, $time )
    = Giovanni::Workflow::getStatusOneTarget( $dir, $target );

# make sure we go the USER_MSG even though ncatted put ERROR in the log
is( $status,
    "Preparing file 1 / 20: MOD11C3.A2001001.006.2015112224542.hdf.MOD11C3_006_LST_Day_CMG.nc",
    "Got user message"
);

sub writeTempFile {
    my ( $fileName, $string ) = @_;
    open( FILE, ">", $fileName ) or die $?;
    print FILE $string or die $?;
    close(FILE);
}
