# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Metrics.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Time::Local;
use POSIX;
use lib 'lib';
use Test::More qw(no_plan);

#########################
## to test library can import and create
BEGIN { use_ok('Giovanni::Metrics') }
can_ok( 'Giovanni::Metrics', ('new') );

#########################
## to test constructor
my $metrics = Giovanni::Metrics->new( sessiondir => '.' );
isa_ok( $metrics, 'Giovanni::Metrics' );

#########################
my $filename = "";
while (<DATA>) {
    if ( $_ =~ /^FILE=/ ) {
        $filename = $_;
        $filename =~ s/^FILE=//;
        chomp($filename);
        open HTMLFH, ">", "$filename";
        next;
    }
    if ( $_ =~ /^ENDFILE/ ) {
        close(HTMLFH);
        ok( ( -f "$filename" ), "Create \"$filename\"" );
        next;
    }
    print HTMLFH $_;
}
my $lineageFile = "./Lineage.xml";
my $sessionLog  = "./sessionLog4j.log";

#########################
## to test parseLineageStepNames from Lineage.xml
my @names     = $metrics->parseLineageStepNames(".");
my $nameCount = @names;
ok( $nameCount eq 6, "parseLineageStepNames - $nameCount" );

#########################
## to test extractDateTimeString()
my $line
    = "2012-02-06 15:32:17,938 - Pad Bounding Box - STATUS:START_FIRE 1/1";
my $time = $metrics->extractDateTimeString($line);
ok( $time eq "2012-02-06 15:32:17,938", "extractDateTimeString got wrong" );

#########################
## to test converStringToDate()
my $startstr = "2012-02-06 15:32:17,938";
my $endstr   = "2012-02-06 15:32:20,999";
my $expected = "3.061";
my $start    = $metrics->convertStringToDate($startstr);
my $date     = timelocal( 17, 32, 15, 06, 01, 112 ) + 0.938;
ok( $start eq $date, "convertStringToDate" );

#########################
# to test calcElapseTime()
my $end = $metrics->convertStringToDate($endstr);
my $elapse = $metrics->calcElapseTime( $start, $end );
## $elapse would be equal to "3.06100010871887"
ok( $elapse =~ /^$expected/, "calcElapseTime failed $elapse" );

#########################
## to test extractRealStepName
my $stepline
    = "2012-02-14 21:12:56,897 - [INFO ] - block_to_l3 - STEP_NAME \"Subset and grid data\"";
my $stepname = $metrics->extractRealStepName($stepline);
ok( $stepname eq "block_to_l3 ", "extractRealStepName-$stepname" );

#########################
## to test printMetricsInfo()
my $ret = $metrics->printMetricsInfo();
ok( $ret eq "1", "printMetricsInfo()=$ret" );

unlink $lineageFile if ( -e $lineageFile );
unlink $sessionLog  if ( -e $sessionLog );

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

__DATA__
FILE=./Lineage.xml
<?xml version="1.0" encoding="UTF-8"?><lineage><step DISPLAY="true" LABEL="Pad bounding box by a fixed number of degrees in all directions." NAME="Pad bounding box"><input LABEL="bounding box in 'west, south, east , north' order" NAME="bounding box" TYPE="PARAMETER">-99.84375,26.71875,-65.390625,37.96875</input><input LABEL="The amount of padding (degrees)" NAME="Padding factor" TYPE="PARAMETER">5.00000</input><output LABEL="bounding box in 'west, south, east , north' order" NAME="bounding box" TYPE="PARAMETER">-104.843750,21.718750,-60.390625,42.968750</output></step><step DISPLAY="true" LABEL="Pad time by a fixed number of minutes" NAME="Pad start time"><input LABEL="Time in ISO 8601 format" NAME="Time" TYPE="PARAMETER">2003-01-01</input><input LABEL="Time padding (minutes)" NAME="Padding" TYPE="PARAMETER">-60</input><output LABEL="Time in ISO 8601 format" NAME="Time" TYPE="PARAMETER">2002-12-31T23:00:00Z</output></step><step DISPLAY="true" LABEL="Pad time by a fixed number of minutes" NAME="Pad end time"><input LABEL="Time in ISO 8601 format" NAME="Time" TYPE="PARAMETER">2003-01-03T23:59:59Z</input><input LABEL="Time padding (minutes)" NAME="Padding" TYPE="PARAMETER">60</input><output LABEL="Time in ISO 8601 format" NAME="Time" TYPE="PARAMETER">2003-01-04T00:59:59Z</output></step><step DISPLAY="true" LABEL="Search using time and location constraints." NAME="Search"><input LABEL="start time in ISO 8601 format" NAME="start time" TYPE="PARAMETER">2002-12-31T23:00:00Z</input><input LABEL="end time in ISO 8601 format" NAME="end time" TYPE="PARAMETER">2003-01-04T00:59:59Z</input><input LABEL="data set" NAME="data set" TYPE="PARAMETER">MIL2ASAE.002</input><input LABEL="bounding box in 'west, south, east , north' order" NAME="bounding box" TYPE="PARAMETER">-104.843750,21.718750,-60.390625,42.968750</input><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf</output><output LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.04/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf</output></step><step DISPLAY="true" LABEL="Adjust bias" NAME="Adjust bias"><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="URL">ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.04/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf</input><input LABEL="data set" NAME="data set" TYPE="PARAMETER">MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None]</input><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf
</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf
</output></step><step DISPLAY="true" LABEL="Put data on a regular grid" NAME="Subset and grid data"><input LABEL="start time" NAME="start time" TYPE="PARAMETER">2003-01-01</input><input LABEL="end time" NAME="end time" TYPE="PARAMETER">2003-01-03T23:59:59Z</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf</input><input LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf</input><input LABEL="bounding box" NAME="bounding box" TYPE="PARAMETER">-99.84375,26.71875,-65.390625,37.96875</input><input LABEL="data set" NAME="data set" TYPE="PARAMETER">MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None]</input><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030101-20120215201010-20211.nc</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030102-20120215201010-20211.nc</output><output LABEL="data file" NAME="data file" TYPE="FILE">/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030103-20120215201011-20211.nc</output></step></lineage>
ENDFILE
FILE=./sessionLog4j.log
2012-02-15 20:06:05 - [INFO ] - ServiceManager - STATUS:INFO Preparing to perform requested service
2012-02-15 20:06:05 - [INFO ] - ServiceManager - STATUS:INFO Preparing to perform requested service: created workflow
2012-02-15 20:06:08,564 - [INFO ] - DataXPath - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,565 - [INFO ] - DataXPath - STEP_NAME "Read data input"
2012-02-15 20:06:08,565 - [INFO ] - StartTimeXPath - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,565 - [INFO ] - StartTimeXPath - STEP_NAME "Read start time"
2012-02-15 20:06:08,565 - [INFO ] - EndTimeXPath - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,565 - [INFO ] - EndTimeXPath - STEP_NAME "Read end time"
2012-02-15 20:06:08,565 - [INFO ] - BBoxXPath - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,565 - [INFO ] - BBoxXPath - STEP_NAME "Read bounding box"
2012-02-15 20:06:08,565 - [INFO ] - Break data up by product - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,566 - [INFO ] - Break data up by product - STEP_NAME "Break up data by product"
2012-02-15 20:06:08,566 - [INFO ] - Open search - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,567 - [INFO ] - Open search - STEP_NAME "Search"
2012-02-15 20:06:08,567 - [INFO ] - block_to_l3 - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,567 - [INFO ] - block_to_l3 - STEP_NAME "Subset and grid data"
2012-02-15 20:06:08,569 - [INFO ] - KeplerResponseActor - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,569 - [INFO ] - KeplerResponseActor - STEP_NAME "Write response file"
2012-02-15 20:06:08,570 - [INFO ] - DataFetcherActor - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,570 - [INFO ] - DataFetcherActor - STEP_NAME "Fetch data"
2012-02-15 20:06:08,570 - [INFO ] - Plot Hints - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,570 - [INFO ] - Plot Hints - STEP_NAME "Add plot hints to the data"
2012-02-15 20:06:08,571 - [INFO ] - Pad Bounding Box - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,571 - [INFO ] - Pad Bounding Box - STEP_NAME "Pad bounding box"
2012-02-15 20:06:08,571 - [INFO ] - Start TimePaddingActor - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,571 - [INFO ] - Start TimePaddingActor - STEP_NAME "Pad start time"
2012-02-15 20:06:08,572 - [INFO ] - End TimePaddingActor - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,572 - [INFO ] - End TimePaddingActor - STEP_NAME "Pad end time"
2012-02-15 20:06:08,573 - [INFO ] - dir_to_block - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,573 - [INFO ] - dir_to_block - STEP_NAME "Subset and grid data"
2012-02-15 20:06:08,574 - [INFO ] - Make Data Directory - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,574 - [INFO ] - Make Data Directory - STEP_NAME "Make data directory"
2012-02-15 20:06:08,575 - [INFO ] - Adjust Bias - STATUS:START_WORKFLOW 
2012-02-15 20:06:08,575 - [INFO ] - Adjust Bias - STEP_NAME "Adjust bias"
2012-02-15 20:06:08,579 - [INFO ] - DataXPath - STATUS:START_FIRE
2012-02-15 20:06:08,587 - [INFO ] - DataXPath - STATUS:END_FIRE
2012-02-15 20:06:08,587 - [INFO ] - StartTimeXPath - STATUS:START_FIRE
2012-02-15 20:06:08,591 - [INFO ] - StartTimeXPath - STATUS:END_FIRE
2012-02-15 20:06:08,591 - [INFO ] - EndTimeXPath - STATUS:START_FIRE
2012-02-15 20:06:08,594 - [INFO ] - EndTimeXPath - STATUS:END_FIRE
2012-02-15 20:06:08,595 - [INFO ] - BBoxXPath - STATUS:START_FIRE
2012-02-15 20:06:08,598 - [INFO ] - BBoxXPath - STATUS:END_FIRE
2012-02-15 20:06:08,598 - [INFO ] - Break data up by product - STATUS:START_FIRE
2012-02-15 20:06:08,599 - [INFO ] - Break data up by product - Break up data by product: Product 'MIL2ASAE.002' contains 'MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None]'
2012-02-15 20:06:08,599 - [INFO ] - Break data up by product - STATUS:END_FIRE
2012-02-15 20:06:08,648 - [INFO ] - Pad Bounding Box - STATUS:START_FIRE 1/1
2012-02-15 20:06:08,648 - [INFO ] - Pad Bounding Box - STATUS:INFO Pad bounding box: Padding bounding box
2012-02-15 20:06:08,648 - [INFO ] - Pad Bounding Box - Input bounding box=-99.84375,26.71875,-65.390625,37.96875 [label=bounding box in 'west, south, east , north' order][type=PARAMETER]
2012-02-15 20:06:08,648 - [INFO ] - Pad Bounding Box - Input Padding factor=5.00000 [label=The amount of padding (degrees)][type=PARAMETER]
2012-02-15 20:06:08,648 - [INFO ] - Pad Bounding Box - STATUS:INFO Pad bounding box: Padded bounding box: (-99.84375,26.71875,-65.390625,37.96875) --> (-104.843750,21.718750,-60.390625,42.968750)
2012-02-15 20:06:08,649 - [INFO ] - Pad Bounding Box - Output bounding box=-104.843750,21.718750,-60.390625,42.968750 [label=bounding box in 'west, south, east , north' order][type=PARAMETER]
2012-02-15 20:06:08,649 - [INFO ] - Pad Bounding Box - STATUS:END_FIRE 1/1
2012-02-15 20:06:08,652 - [INFO ] - Start TimePaddingActor - STATUS:START_FIRE 1/1
2012-02-15 20:06:08,653 - [INFO ] - Start TimePaddingActor - Input Time=2003-01-01 [label=Time in ISO 8601 format][type=PARAMETER]
2012-02-15 20:06:08,653 - [INFO ] - Start TimePaddingActor - Input Padding=-60 [label=Time padding (minutes)][type=PARAMETER]
2012-02-15 20:06:08,653 - [INFO ] - Start TimePaddingActor - STATUS:INFO Pad start time: Padded time '2003-01-01' by '-60' minutes to '2002-12-31T23:00:00Z'
2012-02-15 20:06:08,653 - [INFO ] - Start TimePaddingActor - Output Time=2002-12-31T23:00:00Z [label=Time in ISO 8601 format][type=PARAMETER]
2012-02-15 20:06:08,653 - [INFO ] - Start TimePaddingActor - STATUS:END_FIRE 1/1
2012-02-15 20:06:08,658 - [INFO ] - End TimePaddingActor - STATUS:START_FIRE 1/1
2012-02-15 20:06:08,658 - [INFO ] - End TimePaddingActor - Input Time=2003-01-03T23:59:59Z [label=Time in ISO 8601 format][type=PARAMETER]
2012-02-15 20:06:08,658 - [INFO ] - End TimePaddingActor - Input Padding=60 [label=Time padding (minutes)][type=PARAMETER]
2012-02-15 20:06:08,659 - [INFO ] - End TimePaddingActor - STATUS:INFO Pad end time: Padded time '2003-01-03T23:59:59Z' by '60' minutes to '2003-01-04T00:59:59Z'
2012-02-15 20:06:08,659 - [INFO ] - End TimePaddingActor - Output Time=2003-01-04T00:59:59Z [label=Time in ISO 8601 format][type=PARAMETER]
2012-02-15 20:06:08,659 - [INFO ] - End TimePaddingActor - STATUS:END_FIRE 1/1
2012-02-15 20:06:08,663 - [INFO ] - Open search - STATUS:START_FIRE 1/1
2012-02-15 20:06:08,664 - [INFO ] - Open search - STATUS:INFO Search: Searching for [data set = MIL2ASAE.002][start time = 2002-12-31T23:00:00Z][end time = 2003-01-04T00:59:59Z][bounding box = -104.843750,21.718750,-60.390625,42.968750]
2012-02-15 20:06:08,664 - [INFO ] - Open search - Input start time=2002-12-31T23:00:00Z [label=start time in ISO 8601 format][type=PARAMETER]
2012-02-15 20:06:08,664 - [INFO ] - Open search - Input end time=2003-01-04T00:59:59Z [label=end time in ISO 8601 format][type=PARAMETER]
2012-02-15 20:06:08,664 - [INFO ] - Open search - Input data set=MIL2ASAE.002 [label=data set][type=PARAMETER]
2012-02-15 20:06:08,664 - [INFO ] - Open search - Input bounding box=-104.843750,21.718750,-60.390625,42.968750 [label=bounding box in 'west, south, east , north' order][type=PARAMETER]
2012-02-15 20:06:08,665 - [INFO ] - Open search - Search: Using URL 'http://s4ptu-ts2.ecs.nasa.gov/giovanni/MISR_OSDD_no_bbox.xml' for data set 'MIL2ASAE.002'
2012-02-15 20:06:08,665 - [INFO ] - Open search - Search: Using filter '.*F12_0022.hdf' for data set 'MIL2ASAE.002'
2012-02-15 20:06:08,672 - [DEBUG] - Open search - Search: Full search URL: https://api.echo.nasa.gov:443/echo-esip/search/granule.atom?startTime=2002-12-31T23%3A00%3A00Z&cursor=0&numberOfResults=1000000&versionId=2&dataCenter=LARC&endTime=2003-01-04T00%3A59%3A59Z&shortName=MIL2ASAE&spatialType=ORBIT&clientId=AgileGiovanni
2012-02-15 20:06:08,721 - [INFO ] - Open search - Search: Number of Entries:47
2012-02-15 20:06:08,722 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,723 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,724 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,724 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,725 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,726 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,727 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,728 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,729 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,729 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,730 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,731 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,732 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,732 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,733 - [INFO ] - Open search - Search: Number of data rels in this entry:0
2012-02-15 20:06:08,733 - [INFO ] - Open search - Search: Number of URLs found:0
2012-02-15 20:06:08,734 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,735 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,736 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,737 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,738 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,738 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,739 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,740 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,741 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,741 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,742 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,743 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,744 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,744 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,745 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,746 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,747 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,748 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,749 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,749 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,750 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,751 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,752 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,753 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,754 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,754 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,755 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,756 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,757 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,757 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,758 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,759 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,760 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,761 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,762 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,762 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,763 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,764 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,765 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,765 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,766 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,767 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,768 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,769 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,770 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,770 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,771 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,772 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,773 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,773 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,774 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,775 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,776 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,776 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,777 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,778 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,779 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,780 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,781 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,781 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,782 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,783 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,784 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,784 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,785 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,786 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,787 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,787 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,789 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,789 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,790 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,791 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,792 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,792 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,793 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,794 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,795 - [INFO ] - Open search - Search: Number of data rels in this entry:1
2012-02-15 20:06:08,795 - [INFO ] - Open search - Search: Number of URLs found:1
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found 46 granules
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf
2012-02-15 20:06:08,796 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf
2012-02-15 20:06:08,797 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf
2012-02-15 20:06:08,798 - [INFO ] - Open search - STATUS:INFO Search: Found granule ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.04/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,799 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,800 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,801 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,802 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,802 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,802 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,802 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,802 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,802 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,802 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,802 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,802 - [INFO ] - Open search - Output data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.04/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:08,803 - [INFO ] - Open search - STATUS:END_FIRE 1/1
2012-02-15 20:06:08,811 - [INFO ] - Make Data Directory - STATUS:START_FIRE 1/1
2012-02-15 20:06:08,811 - [INFO ] - Make Data Directory - Make data directory: Creating directory: /var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data
2012-02-15 20:06:08,811 - [INFO ] - Make Data Directory - STATUS:END_FIRE 1/1
2012-02-15 20:06:08,812 - [INFO ] - DataFetcherActor - STATUS:START_FIRE 1/1
2012-02-15 20:06:08,813 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 1: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf
2012-02-15 20:06:08,813 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 1 of 46. (This may take a while...)
2012-02-15 20:06:09,062 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 1 of 46.
2012-02-15 20:06:09,062 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 2: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf
2012-02-15 20:06:09,062 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 2 of 46. (This may take a while...)
2012-02-15 20:06:09,367 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 2 of 46.
2012-02-15 20:06:09,367 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 3: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf
2012-02-15 20:06:09,367 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 3 of 46. (This may take a while...)
2012-02-15 20:06:09,733 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 3 of 46.
2012-02-15 20:06:09,733 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 4: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf
2012-02-15 20:06:09,733 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 4 of 46. (This may take a while...)
2012-02-15 20:06:10,083 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 4 of 46.
2012-02-15 20:06:10,083 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 5: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf
2012-02-15 20:06:10,083 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 5 of 46. (This may take a while...)
2012-02-15 20:06:10,505 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 5 of 46.
2012-02-15 20:06:10,505 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 6: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf
2012-02-15 20:06:10,505 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 6 of 46. (This may take a while...)
2012-02-15 20:06:10,794 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 6 of 46.
2012-02-15 20:06:10,794 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 7: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf
2012-02-15 20:06:10,794 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 7 of 46. (This may take a while...)
2012-02-15 20:06:11,118 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 7 of 46.
2012-02-15 20:06:11,118 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 8: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf
2012-02-15 20:06:11,118 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 8 of 46. (This may take a while...)
2012-02-15 20:06:11,423 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 8 of 46.
2012-02-15 20:06:11,423 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 9: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf
2012-02-15 20:06:11,423 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 9 of 46. (This may take a while...)
2012-02-15 20:06:11,750 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 9 of 46.
2012-02-15 20:06:11,750 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 10: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf
2012-02-15 20:06:11,750 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 10 of 46. (This may take a while...)
2012-02-15 20:06:11,992 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 10 of 46.
2012-02-15 20:06:11,992 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 11: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf
2012-02-15 20:06:11,992 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 11 of 46. (This may take a while...)
2012-02-15 20:06:12,209 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 11 of 46.
2012-02-15 20:06:12,209 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 12: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf
2012-02-15 20:06:12,209 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 12 of 46. (This may take a while...)
2012-02-15 20:06:12,458 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 12 of 46.
2012-02-15 20:06:12,458 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 13: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf
2012-02-15 20:06:12,458 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 13 of 46. (This may take a while...)
2012-02-15 20:06:12,756 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 13 of 46.
2012-02-15 20:06:12,756 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 14: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf
2012-02-15 20:06:12,756 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 14 of 46. (This may take a while...)
2012-02-15 20:06:13,075 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 14 of 46.
2012-02-15 20:06:13,075 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 15: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf
2012-02-15 20:06:13,075 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 15 of 46. (This may take a while...)
2012-02-15 20:06:13,330 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 15 of 46.
2012-02-15 20:06:13,330 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 16: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf
2012-02-15 20:06:13,330 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 16 of 46. (This may take a while...)
2012-02-15 20:06:13,571 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 16 of 46.
2012-02-15 20:06:13,571 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 17: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf
2012-02-15 20:06:13,571 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 17 of 46. (This may take a while...)
2012-02-15 20:06:13,862 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 17 of 46.
2012-02-15 20:06:13,862 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 18: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf
2012-02-15 20:06:13,862 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 18 of 46. (This may take a while...)
2012-02-15 20:06:14,218 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 18 of 46.
2012-02-15 20:06:14,218 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 19: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf
2012-02-15 20:06:14,218 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 19 of 46. (This may take a while...)
2012-02-15 20:06:14,543 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 19 of 46.
2012-02-15 20:06:14,543 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 20: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf
2012-02-15 20:06:14,543 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 20 of 46. (This may take a while...)
2012-02-15 20:06:14,941 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 20 of 46.
2012-02-15 20:06:14,941 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 21: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf
2012-02-15 20:06:14,941 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 21 of 46. (This may take a while...)
2012-02-15 20:06:15,363 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 21 of 46.
2012-02-15 20:06:15,679 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 22: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf
2012-02-15 20:06:15,679 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 22 of 46. (This may take a while...)
2012-02-15 20:06:16,205 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 22 of 46.
2012-02-15 20:06:16,206 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 23: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf
2012-02-15 20:06:16,206 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 23 of 46. (This may take a while...)
2012-02-15 20:06:16,576 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 23 of 46.
2012-02-15 20:06:16,576 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 24: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf
2012-02-15 20:06:16,576 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 24 of 46. (This may take a while...)
2012-02-15 20:06:16,953 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 24 of 46.
2012-02-15 20:06:16,953 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 25: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf
2012-02-15 20:06:16,953 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 25 of 46. (This may take a while...)
2012-02-15 20:06:17,262 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 25 of 46.
2012-02-15 20:06:17,262 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 26: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf
2012-02-15 20:06:17,262 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 26 of 46. (This may take a while...)
2012-02-15 20:06:17,545 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 26 of 46.
2012-02-15 20:06:17,545 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 27: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf
2012-02-15 20:06:17,546 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 27 of 46. (This may take a while...)
2012-02-15 20:06:17,834 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 27 of 46.
2012-02-15 20:06:17,834 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 28: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf
2012-02-15 20:06:17,834 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 28 of 46. (This may take a while...)
2012-02-15 20:06:18,169 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 28 of 46.
2012-02-15 20:06:18,170 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 29: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf
2012-02-15 20:06:18,170 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 29 of 46. (This may take a while...)
2012-02-15 20:06:18,462 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 29 of 46.
2012-02-15 20:06:18,462 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 30: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf
2012-02-15 20:06:18,462 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 30 of 46. (This may take a while...)
2012-02-15 20:06:18,954 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 30 of 46.
2012-02-15 20:06:18,954 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 31: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf
2012-02-15 20:06:18,955 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 31 of 46. (This may take a while...)
2012-02-15 20:06:19,325 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 31 of 46.
2012-02-15 20:06:19,325 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 32: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf
2012-02-15 20:06:19,325 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 32 of 46. (This may take a while...)
2012-02-15 20:06:19,734 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 32 of 46.
2012-02-15 20:06:19,734 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 33: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf
2012-02-15 20:06:19,734 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 33 of 46. (This may take a while...)
2012-02-15 20:06:20,079 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 33 of 46.
2012-02-15 20:06:20,079 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 34: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf
2012-02-15 20:06:20,079 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 34 of 46. (This may take a while...)
2012-02-15 20:06:20,485 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 34 of 46.
2012-02-15 20:06:20,562 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 35: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf
2012-02-15 20:06:20,563 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 35 of 46. (This may take a while...)
2012-02-15 20:06:21,016 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 35 of 46.
2012-02-15 20:06:21,017 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 36: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf
2012-02-15 20:06:21,017 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 36 of 46. (This may take a while...)
2012-02-15 20:06:21,445 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 36 of 46.
2012-02-15 20:06:21,445 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 37: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf
2012-02-15 20:06:21,445 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 37 of 46. (This may take a while...)
2012-02-15 20:06:21,940 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 37 of 46.
2012-02-15 20:06:21,940 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 38: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf
2012-02-15 20:06:21,940 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 38 of 46. (This may take a while...)
2012-02-15 20:06:22,404 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 38 of 46.
2012-02-15 20:06:22,404 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 39: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf
2012-02-15 20:06:22,405 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 39 of 46. (This may take a while...)
2012-02-15 20:06:22,763 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 39 of 46.
2012-02-15 20:06:22,763 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 40: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf
2012-02-15 20:06:22,763 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 40 of 46. (This may take a while...)
2012-02-15 20:06:23,061 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 40 of 46.
2012-02-15 20:06:23,061 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 41: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf
2012-02-15 20:06:23,061 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 41 of 46. (This may take a while...)
2012-02-15 20:06:23,435 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 41 of 46.
2012-02-15 20:06:23,436 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 42: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf
2012-02-15 20:06:23,436 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 42 of 46. (This may take a while...)
2012-02-15 20:06:23,728 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 42 of 46.
2012-02-15 20:06:23,728 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 43: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf
2012-02-15 20:06:23,729 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 43 of 46. (This may take a while...)
2012-02-15 20:06:24,128 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 43 of 46.
2012-02-15 20:06:24,128 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 44: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf
2012-02-15 20:06:24,128 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 44 of 46. (This may take a while...)
2012-02-15 20:06:24,436 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 44 of 46.
2012-02-15 20:06:24,437 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 45: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf
2012-02-15 20:06:24,437 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 45 of 46. (This may take a while...)
2012-02-15 20:06:24,748 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 45 of 46.
2012-02-15 20:06:24,748 - [INFO ] - DataFetcherActor - Fetch data: Fetching URL 46: ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.04/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf
2012-02-15 20:06:24,748 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Fetching data file 46 of 46. (This may take a while...)
2012-02-15 20:06:25,044 - [INFO ] - DataFetcherActor - STATUS:INFO Fetch data: Got data file 46 of 46.
2012-02-15 20:06:25,046 - [INFO ] - DataFetcherActor - STATUS:END_FIRE 1/1
2012-02-15 20:06:25,055 - [INFO ] - Adjust Bias - STATUS:START_FIRE 1/1
2012-02-15 20:06:25,056 - [INFO ] - Adjust Bias - Adjust bias: About to run command: perl /tools/gdaac/TS2//bin/aGiovanni_satellite_bias_correction_wrapper.pl  -f "/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/dataFiles.txt" -B "/tools/gdaac/TS2/"  -D "MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None]"
2012-02-15 20:06:25,058 - [INFO ] - Adjust Bias - Adjust bias: Started command: [perl][/tools/gdaac/TS2//bin/aGiovanni_satellite_bias_correction_wrapper.pl][-f][/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/dataFiles.txt][-B][/tools/gdaac/TS2/][-D][MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None]]
2012-02-15 20:06:25,263 - [INFO ] - Adjust Bias - STATUS:INFO Adjust bias: No Bias correction will be done on this data: MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None] 
2012-02-15 20:06:25,264 - [INFO ] - Adjust Bias - Adjust bias: Finished running command.
2012-02-15 20:06:25,265 - [INFO ] - Adjust Bias - Adjust bias: Step label set to 'Adjust bias'
2012-02-15 20:06:25,265 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,265 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2002.12.31/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,265 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,265 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,265 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,265 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.01/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,266 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.02/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,267 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.03/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data file=ftp://l4ftl01.larc.nasa.gov/misrl2l3/MISR/MIL2ASAE.002/2003.01.04/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf [label=data file][type=URL]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Input data set=MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None] [label=data set][type=PARAMETER]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,268 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,269 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,270 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,271 - [INFO ] - Adjust Bias - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf
 [label=data file][type=FILE]
2012-02-15 20:06:25,273 - [INFO ] - Adjust Bias - STATUS:END_FIRE 1/1
2012-02-15 20:06:25,283 - [INFO ] - dir_to_block - STATUS:START_FIRE 1/1
2012-02-15 20:06:25,283 - [INFO ] - dir_to_block - Subset and grid data: About to run command: /opt/as3/TS2/bin/aGiovanni_as2dir_to_block.pl -f "/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/biasFiles.txt" -s "/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510" -b "2002-12-31T23:00:00Z" -e "2003-01-04T00:59:59Z" -L "/opt/as3/TS2/lib64;/opt/as3/TS2/lib" -P "/opt/as3/TS2/bin/as2dir_to_block" -o "MIL2ASAE.002" -B "/tools/gdaac/TS2/" -D "MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None]"
2012-02-15 20:06:25,285 - [INFO ] - dir_to_block - Subset and grid data: Started command: [/opt/as3/TS2/bin/aGiovanni_as2dir_to_block.pl][-f][/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/biasFiles.txt][-s][/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510][-b][2002-12-31T23:00:00Z][-e][2003-01-04T00:59:59Z][-L][/opt/as3/TS2/lib64;/opt/as3/TS2/lib][-P][/opt/as3/TS2/bin/as2dir_to_block][-o][MIL2ASAE.002][-B][/tools/gdaac/TS2/][-D][MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None]]
2012-02-15 20:06:25,491 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data: Preprocess data files... 
2012-02-15 20:06:25,803 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data: ec /opt/as3/TS2/bin/as2dir_to_block misr_ae2 /var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/ 2002-12-31T23:00:00Z 2003-01-04T00:59:59Z /var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/MIL2ASAE.002 3  
2012-02-15 20:06:25,803 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data: as2dir_to_block AS3_MOD_DATE: 20120202_163421 AS3_COMPILE_DATE: 20120207_180437 AS3_TARBALL_DATE: 20120207_180519
2012-02-15 20:06:25,803 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data: Binning file MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf (1 out of 46)
2012-02-15 20:06:30,400 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file        2 (       46 ) 
2012-02-15 20:06:35,243 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file        3 (       46 ) 
2012-02-15 20:06:40,041 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file        4 (       46 ) 
2012-02-15 20:06:44,941 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file        5 (       46 ) 
2012-02-15 20:06:49,854 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file        6 (       46 ) 
2012-02-15 20:06:54,751 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file        7 (       46 ) 
2012-02-15 20:06:59,444 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file        8 (       46 ) 
2012-02-15 20:07:03,222 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file        9 (       46 ) 
2012-02-15 20:07:08,121 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       10 (       46 ) 
2012-02-15 20:07:12,918 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       11 (       46 ) 
2012-02-15 20:07:17,818 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       12 (       46 ) 
2012-02-15 20:07:22,617 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       13 (       46 ) 
2012-02-15 20:07:27,620 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       14 (       46 ) 
2012-02-15 20:07:32,521 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       15 (       46 ) 
2012-02-15 20:07:37,422 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       16 (       46 ) 
2012-02-15 20:07:42,221 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       17 (       46 ) 
2012-02-15 20:07:47,017 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       18 (       46 ) 
2012-02-15 20:07:51,916 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       19 (       46 ) 
2012-02-15 20:07:56,920 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       20 (       46 ) 
2012-02-15 20:08:01,923 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       21 (       46 ) 
2012-02-15 20:08:06,822 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       22 (       46 ) 
2012-02-15 20:08:11,725 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       23 (       46 ) 
2012-02-15 20:08:16,524 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       24 (       46 ) 
2012-02-15 20:08:21,424 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       25 (       46 ) 
2012-02-15 20:08:26,427 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       26 (       46 ) 
2012-02-15 20:08:31,328 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       27 (       46 ) 
2012-02-15 20:08:36,332 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       28 (       46 ) 
2012-02-15 20:08:41,131 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       29 (       46 ) 
2012-02-15 20:08:46,032 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       30 (       46 ) 
2012-02-15 20:08:51,037 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       31 (       46 ) 
2012-02-15 20:08:55,947 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       32 (       46 ) 
2012-02-15 20:09:00,849 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       33 (       46 ) 
2012-02-15 20:09:05,749 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       34 (       46 ) 
2012-02-15 20:09:10,648 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       35 (       46 ) 
2012-02-15 20:09:15,647 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       36 (       46 ) 
2012-02-15 20:09:20,550 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       37 (       46 ) 
2012-02-15 20:09:25,450 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       38 (       46 ) 
2012-02-15 20:09:30,347 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       39 (       46 ) 
2012-02-15 20:09:35,248 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       40 (       46 ) 
2012-02-15 20:09:40,150 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       41 (       46 ) 
2012-02-15 20:09:44,946 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       42 (       46 ) 
2012-02-15 20:09:49,947 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       43 (       46 ) 
2012-02-15 20:09:54,849 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       44 (       46 ) 
2012-02-15 20:09:59,750 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       45 (       46 ) 
2012-02-15 20:10:04,549 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data:   Binning file       46 (       46 ) 
2012-02-15 20:10:09,451 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data: In total,        46 files have beeen processed
2012-02-15 20:10:09,451 - [INFO ] - dir_to_block - STATUS:INFO Subset and grid data: among them         0 files were ignored
2012-02-15 20:10:09,962 - [INFO ] - dir_to_block - Subset and grid data: Finished running command.
2012-02-15 20:10:09,963 - [INFO ] - dir_to_block - STATUS:END_FIRE 1/1
2012-02-15 20:10:09,965 - [INFO ] - block_to_l3 - STATUS:START_FIRE 1/1
2012-02-15 20:10:09,966 - [INFO ] - block_to_l3 - Subset and grid data: About to run command: /opt/as3/TS2/bin/as3_gridder.pl --remove_block_dir "yes"  --grid "LSOT" -m "map"  -f "/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/directories.txt" -b "-99.84375,26.71875,-65.390625,37.96875" -s "2003-01-01" -e "2003-01-03T23:59:59Z" -d "MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None]" -o "/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002"
2012-02-15 20:10:09,968 - [INFO ] - block_to_l3 - Subset and grid data: Started command: [/opt/as3/TS2/bin/as3_gridder.pl][--remove_block_dir][yes][--grid][LSOT][-m][map][-f][/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/directories.txt][-b][-99.84375,26.71875,-65.390625,37.96875][-s][2003-01-01][-e][2003-01-03T23:59:59Z][-d][MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None]][-o][/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002]
2012-02-15 20:10:10,071 - [INFO ] - block_to_l3 - STATUS:INFO Subset and grid data: Useless use of subtraction (-) in void context at /opt/as3/TS2/bin/as3_gridder.pl line 634.
2012-02-15 20:10:10,071 - [INFO ] - block_to_l3 - STATUS:INFO Subset and grid data: B0  FILTER None 
2012-02-15 20:10:10,584 - [INFO ] - block_to_l3 - STATUS:INFO Subset and grid data:   j6 =            1  surface_type = L          -1           8
2012-02-15 20:10:10,992 - [INFO ] - block_to_l3 - STATUS:INFO Subset and grid data:   j6 =            1  surface_type = L          -1           8
2012-02-15 20:10:11,299 - [INFO ] - block_to_l3 - STATUS:INFO Subset and grid data:   j6 =            1  surface_type = L          -1           8
2012-02-15 20:10:11,299 - [INFO ] - block_to_l3 - STATUS:INFO Subset and grid data: merge_to_l3ser finished processing the data           
2012-02-15 20:10:11,401 - [INFO ] - block_to_l3 - Subset and grid data: Finished running command.
2012-02-15 20:10:11,403 - [INFO ] - block_to_l3 - Subset and grid data: Step label set to 'Put data on a regular grid'
2012-02-15 20:10:11,404 - [INFO ] - block_to_l3 - Input start time=2003-01-01 [label=start time][type=PARAMETER]
2012-02-15 20:10:11,404 - [INFO ] - block_to_l3 - Input end time=2003-01-03T23:59:59Z [label=end time][type=PARAMETER]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P075_O016158_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P091_O016159_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P107_O016160_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P123_O016161_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P139_O016162_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P155_O016163_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P171_O016164_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P187_O016165_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P203_O016166_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P219_O016167_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P002_O016168_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P018_O016169_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P034_O016170_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,405 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P050_O016171_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P066_O016172_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P082_O016173_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P098_O016174_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P114_O016175_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P130_O016176_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P146_O016177_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P162_O016178_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P178_O016179_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P194_O016180_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P210_O016181_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P226_O016182_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P009_O016183_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P025_O016184_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P041_O016185_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,406 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P057_O016186_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P073_O016187_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P089_O016188_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P105_O016189_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P121_O016190_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P137_O016191_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P153_O016192_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P169_O016193_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P185_O016194_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P201_O016195_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P217_O016196_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P233_O016197_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P016_O016198_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P032_O016199_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P048_O016200_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,407 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P064_O016201_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,408 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P080_O016202_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,408 - [INFO ] - block_to_l3 - Input data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/data/MISR_AM1_AS_AEROSOL_P096_O016203_F12_0022.hdf [label=data file][type=FILE]
2012-02-15 20:10:11,408 - [INFO ] - block_to_l3 - Input bounding box=-99.84375,26.71875,-65.390625,37.96875 [label=bounding box][type=PARAMETER]
2012-02-15 20:10:11,408 - [INFO ] - block_to_l3 - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030101-20120215201010-20211.nc [label=data file][type=FILE]
2012-02-15 20:10:11,408 - [INFO ] - block_to_l3 - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030102-20120215201010-20211.nc [label=data file][type=FILE]
2012-02-15 20:10:11,408 - [INFO ] - block_to_l3 - Output data file=/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030103-20120215201011-20211.nc [label=data file][type=FILE]
2012-02-15 20:10:11,408 - [INFO ] - block_to_l3 - Input data set=MIL2ASAE.002:RegBestEstimateSpectralOptDepth:1(446 nm):mean[None] [label=data set][type=PARAMETER]
2012-02-15 20:10:11,408 - [INFO ] - block_to_l3 - STATUS:END_FIRE 1/1
2012-02-15 20:10:11,419 - [INFO ] - Plot Hints - STATUS:START_FIRE 1/1
2012-02-15 20:10:11,419 - [INFO ] - Plot Hints - Add plot hints to the data: About to run command: perl /tools/gdaac/TS2//bin/aerostat_map_hints.pl /var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030101-20120215201010-20211.nc,/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030102-20120215201010-20211.nc,/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030103-20120215201011-20211.nc
2012-02-15 20:10:11,422 - [INFO ] - Plot Hints - Add plot hints to the data: Started command: [perl][/tools/gdaac/TS2//bin/aerostat_map_hints.pl][/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030101-20120215201010-20211.nc,/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030102-20120215201010-20211.nc,/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030103-20120215201011-20211.nc]
2012-02-15 20:10:11,525 - [INFO ] - Plot Hints - Add plot hints to the data: Finished running command.
2012-02-15 20:10:11,526 - [INFO ] - Plot Hints - STATUS:END_FIRE 1/1
2012-02-15 20:10:11,527 - [INFO ] - KeplerResponseActor - STATUS:START_FIRE 1/1
2012-02-15 20:10:11,527 - [INFO ] - KeplerResponseActor - Write response file: Added data: '/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030101-20120215201010-20211.nc,/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030102-20120215201010-20211.nc,/var/tmp/www/TS2/giovanni/C30B3340-57F6-11E1-BAAD-6F8C0773A510/7DC7291E-5810-11E1-A87F-18C90773A510/7DC7412E-5810-11E1-A87F-18C90773A510/output_MIL2ASAE.002/AEROSTAT_MISR_AM1_AS-AERO_MAP-20030103-20120215201011-20211.nc'
2012-02-15 20:10:11,528 - [INFO ] - KeplerResponseActor - STATUS:END_FIRE 1/1
2012-02-15 20:10:11,528 - [INFO ] - DataXPath - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,529 - [INFO ] - StartTimeXPath - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,529 - [INFO ] - EndTimeXPath - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,530 - [INFO ] - BBoxXPath - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,530 - [INFO ] - Break data up by product - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,531 - [INFO ] - Open search - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,531 - [INFO ] - block_to_l3 - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,536 - [INFO ] - KeplerResponseActor - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,536 - [INFO ] - DataFetcherActor - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,537 - [INFO ] - Plot Hints - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,538 - [INFO ] - Pad Bounding Box - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,539 - [INFO ] - Start TimePaddingActor - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,539 - [INFO ] - End TimePaddingActor - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,540 - [INFO ] - dir_to_block - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,541 - [INFO ] - Make Data Directory - STATUS:END_WORKFLOW 
2012-02-15 20:10:11,542 - [INFO ] - Adjust Bias - STATUS:END_WORKFLOW 
2012-02-15 20:10:12 - [INFO ] - ServiceManager - STATUS:INFO Completed requested service
ENDFILE
