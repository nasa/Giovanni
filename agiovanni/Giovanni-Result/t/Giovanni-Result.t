#!/usr/bin/env perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Result.t'

#########################
use lib '../Giovanni-Visualizer-Preferences/lib';
use lib '../Giovanni-Util/lib';
use lib '../Giovanni-Visualizer/lib';
use lib '../Giovanni-Serializer/lib';
use lib '../Giovanni-Status/lib';
use Safe;
use File::Temp qw/ tempfile tempdir /;
use Time::Local;
use URI::Escape;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('Giovanni::Result') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $workingdir = tempdir( CLEANUP => 0 );
ok( ( -e $workingdir ), "Working directory: $workingdir" );
my $rootpath = "$workingdir/sessionid/resultsetid/resultid";
`mkdir -p $rootpath`;
ok( ( -e $rootpath ), "Root path creating" );

## to generate the source testing file, and the expected file
my $filename = "";
my $ncfile   = "";
while (<DATA>) {
    if ( $_ =~ /^FILE=/ ) {
        $filename = $_;
        $filename =~ s/^FILE=//;
        chomp($filename);
        $filename = "$rootpath/$filename";
        open FH, ">", "$filename";
        next;
    }
    if ( $_ =~ /^ENDFILE/ ) {
        close(FH);
        ok( ( -f $filename ), "Create \"$filename\"" );
        next;
    }
    my $line = $_;
    ##$line = uri_escape($line) if ($filename =~ m/giovanni.cfg$/);
    print FH $line;
}

# Read the configuration file
my $cfgFile = $rootpath . '/giovanni.cfg';

my $cpt = Safe->new('GIOVANNI');
unless ( $cpt->rdo($cfgFile) ) {
    Giovanni::Util::exit_with_error('Configuration Error');
}

## to test the timeout -- no updates in "sessionLog4j.log" over 260 seconds
my $current_epoch_time = time;    ## seconds since Epoch
$current_epoch_time -= 270;
utime( $current_epoch_time, $current_epoch_time,
    "$rootpath/sessionLog4j.log" );
my $timeout = 260;                ## seconds

## input hash
my $inputs;
my $resultset_dir = $rootpath;
$resultset_dir =~ s/resultid$//i;
$inputs->{resultset_dir} = "$resultset_dir";
$inputs->{result}        = 'resultid';
$inputs->{timeout}       = $timeout;

my $result = Giovanni::Result->new($inputs);
ok( $result->onError(), "Case of result not being created or tracked" );

$result->getStatus();
is( $result->{_STATUS}{code}, 1, "Timeout testing" );

__DATA__
FILE=actors.txt
DataXPath
StartTimeXPath
EndTimeXPath
LocationXPath
PortalXPath
ServiceXPath
ARDFlag
Plot Hints
Bias Adjusted
KeplerResponseActor2
Get Data
ENDFILE
FILE=input.txt
<input><referer>http://s4ptu-ts2.ecs.nasa.gov/~hxiaopen/aerostat/</referer><query>session=sessionid&amp;location=GSFC&amp;data=AERONET_AOD_L2.2:AOD0340:mean[nval%20%3E=%202],MIL2ASAE.0022:AOD0446b:mean[nval%20%3E=%202,QAb%3C=1]&amp;starttime=2007-01-01&amp;endtime=2007-09-09T23:59:59Z&amp;ardFlag=0&amp;service=AEROSTAT_TIME_SERIES&amp;portal=AEROSTAT</query><result id="resultid"><dir>/var/tmp/www/TS2/giovanni/sessionid/resultsetid/resultid</dir></result><ardFlag>0</ardFlag><data>AERONET_AOD_L2.2:AOD0340:mean[nval &gt;= 2]</data><data>MIL2ASAE.0022:AOD0446b:mean[nval &gt;= 2,QAb&lt;=1]</data><endtime>2007-09-09T23:59:59Z</endtime><location>GSFC</location><portal>AEROSTAT</portal><service>AEROSTAT_TIME_SERIES</service><starttime>2007-01-01</starttime></input>
ENDFILE
FILE=sessionLog4j.log
2012-05-23 19:23:46 - [INFO ] - ServiceManager - STATUS:INFO Preparing to perform requested service
2012-05-23 19:23:46 - [INFO ] - ServiceManager - STATUS:INFO Preparing to perform requested service: created workflow
2012-05-23 19:23:50,007 - [INFO ] - DataXPath - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,007 - [INFO ] - DataXPath - STEP_NAME "Get data from input"
2012-05-23 19:23:50,007 - [INFO ] - StartTimeXPath - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,007 - [INFO ] - StartTimeXPath - STEP_NAME "Get start time from input"
2012-05-23 19:23:50,007 - [INFO ] - EndTimeXPath - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,007 - [INFO ] - EndTimeXPath - STEP_NAME "Get end time from input"
2012-05-23 19:23:50,007 - [INFO ] - LocationXPath - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,008 - [INFO ] - LocationXPath - STEP_NAME "Get location from input"
2012-05-23 19:23:50,008 - [INFO ] - PortalXPath - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,008 - [INFO ] - PortalXPath - STEP_NAME "Get portal from input"
2012-05-23 19:23:50,008 - [INFO ] - ServiceXPath - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,008 - [INFO ] - ServiceXPath - STEP_NAME "Get service from input"
2012-05-23 19:23:50,008 - [INFO ] - ARDFlag - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,008 - [INFO ] - ARDFlag - STEP_NAME "Get ARD flag from input"
2012-05-23 19:23:50,008 - [INFO ] - Plot Hints - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,008 - [INFO ] - Plot Hints - STEP_NAME "Add plot hints"
2012-05-23 19:23:50,009 - [INFO ] - Bias Adjusted - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,009 - [INFO ] - Bias Adjusted - STEP_NAME "Adjust bias"
2012-05-23 19:23:50,009 - [INFO ] - KeplerResponseActor2 - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,009 - [INFO ] - KeplerResponseActor2 - STEP_NAME "Write response"
2012-05-23 19:23:50,009 - [INFO ] - Get Data - STATUS:START_WORKFLOW 
2012-05-23 19:23:50,009 - [INFO ] - Get Data - STEP_NAME "Get data"
2012-05-23 19:23:50,014 - [INFO ] - ARDFlag - STATUS:START_FIRE
2012-05-23 19:23:50,015 - [INFO ] - ARDFlag - Get ARD flag from input: Searching for required xpath '/input/ardFlag/text()'
2012-05-23 19:23:50,031 - [INFO ] - ARDFlag - Get ARD flag from input: Found values: 0
2012-05-23 19:23:50,032 - [INFO ] - ARDFlag - STATUS:END_FIRE
2012-05-23 19:23:50,032 - [INFO ] - ServiceXPath - STATUS:START_FIRE
2012-05-23 19:23:50,033 - [INFO ] - ServiceXPath - Get service from input: Searching for required xpath '/input/service/text()'
2012-05-23 19:23:50,036 - [INFO ] - ServiceXPath - Get service from input: Found values: AEROSTAT_TIME_SERIES
2012-05-23 19:23:50,036 - [INFO ] - ServiceXPath - STATUS:END_FIRE
2012-05-23 19:23:50,037 - [INFO ] - PortalXPath - STATUS:START_FIRE
2012-05-23 19:23:50,037 - [INFO ] - PortalXPath - Get portal from input: Searching for required xpath '/input/portal/text()'
2012-05-23 19:23:50,041 - [INFO ] - PortalXPath - Get portal from input: Found values: AEROSTAT
2012-05-23 19:23:50,041 - [INFO ] - PortalXPath - STATUS:END_FIRE
2012-05-23 19:23:50,041 - [INFO ] - LocationXPath - STATUS:START_FIRE
2012-05-23 19:23:50,042 - [INFO ] - LocationXPath - Get location from input: Searching for required xpath '/input/location/text()'
2012-05-23 19:23:50,046 - [INFO ] - LocationXPath - Get location from input: Found values: GSFC
2012-05-23 19:23:50,046 - [INFO ] - LocationXPath - STATUS:END_FIRE
2012-05-23 19:23:50,046 - [INFO ] - EndTimeXPath - STATUS:START_FIRE
2012-05-23 19:23:50,046 - [INFO ] - EndTimeXPath - Get end time from input: Searching for required xpath '/input/endtime/text()'
2012-05-23 19:23:50,050 - [INFO ] - EndTimeXPath - Get end time from input: Found values: 2007-09-09T23:59:59Z
2012-05-23 19:23:50,050 - [INFO ] - EndTimeXPath - STATUS:END_FIRE
2012-05-23 19:23:50,051 - [INFO ] - StartTimeXPath - STATUS:START_FIRE
2012-05-23 19:23:50,051 - [INFO ] - StartTimeXPath - Get start time from input: Searching for required xpath '/input/starttime/text()'
2012-05-23 19:23:50,055 - [INFO ] - StartTimeXPath - Get start time from input: Found values: 2007-01-01
2012-05-23 19:23:50,055 - [INFO ] - StartTimeXPath - STATUS:END_FIRE
2012-05-23 19:23:50,056 - [INFO ] - DataXPath - STATUS:START_FIRE
2012-05-23 19:23:50,056 - [INFO ] - DataXPath - Get data from input: Searching for required xpath '/input/data/text()'
2012-05-23 19:23:50,059 - [INFO ] - DataXPath - Get data from input: Found values: AERONET_AOD_L2.2:AOD0340:mean[nval >= 2] --- MIL2ASAE.0022:AOD0446b:mean[nval >= 2,QAb<=1]
2012-05-23 19:23:50,060 - [INFO ] - DataXPath - STATUS:END_FIRE
2012-05-23 19:23:50,060 - [INFO ] - Get Data - STATUS:START_FIRE
2012-05-23 19:23:50,061 - [INFO ] - Get Data - Get data: About to run command: /tools/gdaac/TS2//bin/extract_aerostat_stations_data.pl "/var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/input.xml"
2012-05-23 19:23:50,063 - [INFO ] - Get Data - Get data: Started command: [/tools/gdaac/TS2//bin/extract_aerostat_stations_data.pl][/var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/input.xml]
2012-05-23 19:23:50,678 - [INFO ] - Get Data - STATUS:INFO Get data: Preparing to query MAPSS data
2012-05-23 19:23:50,680 - [INFO ] - Get Data - STATUS:INFO Get data: Querying MAPSS data
2012-05-23 19:23:50,680 - [INFO ] - Get Data - STATUS:INFO Get data: Getting AERONET_AOD_L2.2:AOD0340:mean (may take more than a minute)
2012-05-23 19:23:55,378 - [INFO ] - Get Data - STATUS:INFO Get data: Getting MIL2ASAE.0022:AOD0446b:mean (may take more than a minute)
2012-05-23 19:23:58,038 - [INFO ] - Get Data - STATUS:INFO Get data: Getting MIL2ASAE.0022:AOD0446b:QAb (may take more than a minute)
2012-05-23 19:23:58,753 - [INFO ] - Get Data - STATUS:INFO Get data: Getting MIL2ASAE.0022:AOD0446b:nval (may take more than a minute)
2012-05-23 19:23:59,467 - [INFO ] - Get Data - Get data: Finished running command.
2012-05-23 19:23:59,470 - [INFO ] - Get Data - Get data: Step label set to 'Search for and retrieve data'
2012-05-23 19:23:59,470 - [INFO ] - Get Data - Input data=AERONET_AOD_L2.2:AOD0340:mean[nval >= 2] [label=data][type=PARAMETER]
2012-05-23 19:23:59,470 - [INFO ] - Get Data - Input data=MIL2ASAE.0022:AOD0446b:mean[nval >= 2,QAb<=1] [label=data][type=PARAMETER]
2012-05-23 19:23:59,470 - [INFO ] - Get Data - Input start time=2007-01-01 [label=start time in ISO 8601 format ][type=PARAMETER]
2012-05-23 19:23:59,470 - [INFO ] - Get Data - Input location=GSFC [label=location][type=PARAMETER]
2012-05-23 19:23:59,470 - [INFO ] - Get Data - Input portal=AEROSTAT [label=portal][type=PARAMETER]
2012-05-23 19:23:59,470 - [INFO ] - Get Data - Input service=AEROSTAT_TIME_SERIES [label=service][type=PARAMETER]
2012-05-23 19:23:59,470 - [INFO ] - Get Data - Input ard flag=0 [label=annual repeating date flag][type=PARAMETER]
2012-05-23 19:23:59,470 - [INFO ] - Get Data - Output data file=/var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/AEROSTAT_combined-AERO_TM-20122305192359.nc [label=data file][type=FILE]
2012-05-23 19:23:59,471 - [INFO ] - Get Data - Input end time=2007-09-09T23:59:59Z [label=end time in ISO 8601 format ][type=PARAMETER]
2012-05-23 19:23:59,471 - [INFO ] - Get Data - STATUS:END_FIRE
2012-05-23 19:23:59,476 - [INFO ] - Bias Adjusted - STATUS:START_FIRE
2012-05-23 19:23:59,476 - [INFO ] - Bias Adjusted - Adjust bias: About to run command: /tools/gdaac/TS2//bin/aerostat_bias_correction.pl  -f /var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/AEROSTAT_combined-AERO_TM-20122305192359.nc
2012-05-23 19:23:59,479 - [INFO ] - Bias Adjusted - Adjust bias: Started command: [/tools/gdaac/TS2//bin/aerostat_bias_correction.pl][-f][/var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/AEROSTAT_combined-AERO_TM-20122305192359.nc]
2012-05-23 19:23:59,685 - [INFO ] - Bias Adjusted - Adjust bias: Finished running command.
2012-05-23 19:23:59,686 - [INFO ] - Bias Adjusted - Adjust bias: Step label set to 'Adjust bias'
2012-05-23 19:23:59,687 - [INFO ] - Bias Adjusted - Input data file=/var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/AEROSTAT_combined-AERO_TM-20122305192359.nc [label=data file][type=FILE]
2012-05-23 19:23:59,687 - [INFO ] - Bias Adjusted - Output data file=/var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/AEROSTAT_combined-AERO_TM-20122305192359.nc [label=data file][type=FILE]
2012-05-23 19:23:59,687 - [INFO ] - Bias Adjusted - STATUS:END_FIRE
2012-05-23 19:23:59,694 - [INFO ] - Plot Hints - STATUS:START_FIRE
2012-05-23 19:23:59,695 - [INFO ] - Plot Hints - Add plot hints: About to run command: perl -I /tools/gdaac/TS2//lib/perl5/site_perl/5.8.8/ /tools/gdaac/TS2//bin/aerostat_plot_hints.pl /var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/AEROSTAT_combined-AERO_TM-20122305192359.nc
2012-05-23 19:23:59,697 - [INFO ] - Plot Hints - Add plot hints: Started command: [perl][-I][/tools/gdaac/TS2//lib/perl5/site_perl/5.8.8/][/tools/gdaac/TS2//bin/aerostat_plot_hints.pl][/var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/AEROSTAT_combined-AERO_TM-20122305192359.nc]
2012-05-23 19:23:59,800 - [INFO ] - Plot Hints - Add plot hints: Finished running command.
2012-05-23 19:23:59,801 - [INFO ] - Plot Hints - STATUS:END_FIRE
2012-05-23 19:23:59,801 - [INFO ] - KeplerResponseActor2 - STATUS:START_FIRE
2012-05-23 19:23:59,801 - [INFO ] - KeplerResponseActor2 - Write response: Added data: '/var/tmp/www/TS2/giovanni/9F7B3962-A50C-11E1-9887-E859F440FFF3/D14A7E9E-A50C-11E1-99F3-455AF440FFF3/D14AA2E8-A50C-11E1-99F3-455AF440FFF3/AEROSTAT_combined-AERO_TM-20122305192359.nc'
2012-05-23 19:23:59,801 - [INFO ] - KeplerResponseActor2 - STATUS:END_FIRE
2012-05-23 19:23:59,802 - [INFO ] - DataXPath - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,803 - [INFO ] - StartTimeXPath - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,803 - [INFO ] - EndTimeXPath - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,804 - [INFO ] - LocationXPath - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,804 - [INFO ] - PortalXPath - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,805 - [INFO ] - ServiceXPath - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,805 - [INFO ] - ARDFlag - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,806 - [INFO ] - Plot Hints - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,808 - [INFO ] - Bias Adjusted - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,816 - [INFO ] - KeplerResponseActor2 - STATUS:END_WORKFLOW 
2012-05-23 19:23:59,817 - [INFO ] - Get Data - STATUS:END_WORKFLOW 
2012-05-23 19:23:59 - [INFO ] - ServiceManager - STATUS:INFO Completed requested service
ENDFILE
FILE=giovanni.cfg
$SESSION_LOCATION='/var/tmp/www/TS2/giovanni';
\$SESSION_TIMEOUT='260';
$JAR_DIR='/tools/gdaac/TS2/jar';
%ENV=(
  JAVA_HOME => '/usr/java/jdk/',
  ANT_HOME  => '/usr/share/ant',
  PATH      => '/usr/local/bin/:/usr/bin:/bin',
  #NCL related variables
  NCARG_ROOT => '/usr/local/',
  NCARG_USRRESFILE => '/tools/gdaac/TS2/cfg/giovanni/ncl_userfile',
  NCL_SCRIPTS_DIR => '/home/hxiaopen/public_html/bin',
  TEXMFVAR => '/var/tmp'
);
%URL_LOOKUP=(
  '/var/tmp/www/TS2/giovanni' => 'http://s4ptu-ts2.ecs.nasa.gov/WWW-TMP/giovanni'
);
$LINEAGE_XSL="/tools/gdaac/TS2/cfg/giovanni/GiovanniLineage.xsl";

$DATA_CATALOG="http://giovanni4.ecs.nasa.gov/AG_solr/select/";
ENDFILE
