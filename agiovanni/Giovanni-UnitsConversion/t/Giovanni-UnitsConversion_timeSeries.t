#$Id: Giovanni-UnitsConversion_timeSeries.t,v 1.1 2015/03/26 18:10:31 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-UnitsConversion.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::UnitsConversion') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use warnings;
use strict;
use Giovanni::Data::NcFile;
use File::Temp qq/tempdir/;

##################
# Do a test with a time series file, just to make sure that the monthly
# accumulation code can handle a variable that just has a time dimension.
##################

my $dir = tempdir( CLEANUP => 1 );

my ( $inCdl, $correctCdl ) = readCdlData();

my $dataFile
    = "$dir/timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N.nc";
Giovanni::Data::NcFile::write_netcdf_file( $dataFile, $inCdl )
    or die "Unable to write input file.";

my $conversionCfg = <<XML;
<units>
    <linearConversions>
        <linearUnit source="mm/day" destination="mm/hr" scale_factor="1.0/24.0"
            add_offset="0" />
        <linearUnit source="mm/day" destination="inch/day"
            scale_factor="1.0/25.4" add_offset="0" />
    </linearConversions>
    <nonLinearConversions>
        <timeDependentUnit source="mm/hr" destination="mm/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="24.0" />
        <timeDependentUnit source="mm/hr" destination="inch/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="24.0/25.4" />
        <timeDependentUnit source="mm/hr" destination="inch/month"
         class="Giovanni::UnitsConversion::MonthlyAccumulation"
         to_days_scale_factor="86400.0" />
    </nonLinearConversions>
</units>
XML
my $cfg = "$dir/cfg.xml";
open( CFG, ">", $cfg );
print CFG $conversionCfg;
close(CFG);

my $converter = Giovanni::UnitsConversion->new( config => $cfg );
$converter->addConversion(
    sourceUnits      => 'mm/hr',
    destinationUnits => 'mm/month',
    variable         => 'TRMM_3B43_007_precipitation',
    type             => 'float',
);

my $destFile = "$dir/out.nc";
my $ret      = $converter->ncConvert(
    sourceFile      => $dataFile,
    destinationFile => $destFile
);

ok( $ret, "conversion returned true" );

# remove the history from the output file
my $cmd = "ncatted -O -h -a 'history,global,d,,,' $destFile $destFile";
$ret = system($cmd);

if ( $ret != 0 ) {
    die "Unable to remove history";
}

# write the correct output CDL to a file
my $correctNc = "$dir/correct.nc";
Giovanni::Data::NcFile::write_netcdf_file( $correctNc, $correctCdl )
    or die "Unable to write comparison output file.";

my $out = Giovanni::Data::NcFile::diff_netcdf_files( $destFile, $correctNc )
    ;

is( $out, '', "Same output: $out" );

sub readCdlData {

    # read block at __DATA__ and write to a CDL file
    #(stolen from Chris...)
    my @cdldata;
    while (<DATA>) {
        push @cdldata, $_;
    }
    my $allCdf = join( '', @cdldata );

    # now divide up
    my @cdl = ( $allCdf =~ m/(netcdf .*?\}\n)/gs );
    return @cdl;
}

__DATA__
netcdf areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N {
dimensions:
    bnds = 2 ;
    time = UNLIMITED ; // (36 currently)
variables:
    int time_bnds(time, bnds) ;
    float TRMM_3B43_007_precipitation(time) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:plot_hint_legend_label = "TRMM_3B43_007_precipitation" ;
        TRMM_3B43_007_precipitation:coordinates = "time" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:bounds = "time_bnds" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :temporal_resolution = "monthly" ;
        :nco_openmp_thread_number = 1 ;
        :nco_input_file_number = 36 ;
        :nco_input_file_list = "areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.0 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.1 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.2 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.3 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.4 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.5 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.6 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.7 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.8 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.9 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.10 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.11 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.12 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.13 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.14 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.15 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.16 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.17 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.18 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.19 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.20 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.21 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.22 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.23 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.24 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.25 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.26 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.27 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.28 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.29 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.30 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.31 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.32 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.33 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.34 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.35" ;
        :start_time = "2004-01-01T00:00:00Z" ;
        :end_time = "2006-12-31T23:59:59Z" ;
        :userstartdate = "2004-01-01T00:00:00Z" ;
        :userenddate = "2006-12-31T23:59:59Z" ;
        :title = "Time Series, Area-Averaged of Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v7] mm/hr over 2004-Jan - 2006-Dec, Region 100.5469W, 17.6953N, 69.6094W, 40.8985N " ;
        
data:

 time_bnds =
  1072915200, 1075593600,
  1075593600, 1078099200,
  1078099200, 1080777600,
  1080777600, 1083369600,
  1083369600, 1086048000,
  1086048000, 1088640000,
  1088640000, 1091318400,
  1091318400, 1093996800,
  1093996800, 1096588800,
  1096588800, 1099267200,
  1099267200, 1101859200,
  1101859200, 1104537600,
  1104537600, 1107216000,
  1107216000, 1109635200,
  1109635200, 1112313600,
  1112313600, 1114905600,
  1114905600, 1117584000,
  1117584000, 1120176000,
  1120176000, 1122854400,
  1122854400, 1125532800,
  1125532800, 1128124800,
  1128124800, 1130803200,
  1130803200, 1133395200,
  1133395200, 1136073600,
  1136073600, 1138752000,
  1138752000, 1141171200,
  1141171200, 1143849600,
  1143849600, 1146441600,
  1146441600, 1149120000,
  1149120000, 1151712000,
  1151712000, 1154390400,
  1154390400, 1157068800,
  1157068800, 1159660800,
  1159660800, 1162339200,
  1162339200, 1164931200,
  1164931200, 1167609600 ;

 TRMM_3B43_007_precipitation = 0.08773784, 0.1296923, 0.08735775, 0.1220523, 
    0.1238568, 0.1748544, 0.1880457, 0.1861645, 0.227451, 0.1442938, 
    0.1447496, 0.1156532, 0.09896641, 0.1086274, 0.132165, 0.1162166, 
    0.1276909, 0.2122813, 0.1927077, 0.1868115, 0.1731047, 0.2338684, 
    0.1126935, 0.1081875, 0.1107569, 0.09790798, 0.06585524, 0.09609181, 
    0.1303578, 0.1887619, 0.1821688, 0.1660251, 0.1753064, 0.1829095, 
    0.1621805, 0.1380182 ;

 time = 1072915200, 1075593600, 1078099200, 1080777600, 1083369600, 
    1086048000, 1088640000, 1091318400, 1093996800, 1096588800, 1099267200, 
    1101859200, 1104537600, 1107216000, 1109635200, 1112313600, 1114905600, 
    1117584000, 1120176000, 1122854400, 1125532800, 1128124800, 1130803200, 
    1133395200, 1136073600, 1138752000, 1141171200, 1143849600, 1146441600, 
    1149120000, 1151712000, 1154390400, 1157068800, 1159660800, 1162339200, 
    1164931200 ;

 datamonth = 200401, 200402, 200403, 200404, 200405, 200406, 200407, 200408, 
    200409, 200410, 200411, 200412, 200501, 200502, 200503, 200504, 200505, 
    200506, 200507, 200508, 200509, 200510, 200511, 200512, 200601, 200602, 
    200603, 200604, 200605, 200606, 200607, 200608, 200609, 200610, 200611, 
    200612 ;
}
netcdf out {
dimensions:
    time = UNLIMITED ; // (36 currently)
    bnds = 2 ;
variables:
    float TRMM_3B43_007_precipitation(time) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:coordinates = "time" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:plot_hint_legend_label = "TRMM_3B43_007_precipitation" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/month" ;
    int time_bnds(time, bnds) ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:bounds = "time_bnds" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :temporal_resolution = "monthly" ;
        :nco_openmp_thread_number = 1 ;
        :nco_input_file_number = 36 ;
        :nco_input_file_list = "areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.0 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.1 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.2 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.3 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.4 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.5 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.6 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.7 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.8 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.9 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.10 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.11 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.12 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.13 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.14 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.15 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.16 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.17 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.18 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.19 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.20 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.21 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.22 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.23 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.24 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.25 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.26 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.27 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.28 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.29 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.30 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.31 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.32 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.33 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.34 areaAvgTimeSeries.TRMM_3B43_007_precipitation.20040101-20061231.100W_17N_69W_40N.nc.35" ;
        :start_time = "2004-01-01T00:00:00Z" ;
        :end_time = "2006-12-31T23:59:59Z" ;
        :userstartdate = "2004-01-01T00:00:00Z" ;
        :userenddate = "2006-12-31T23:59:59Z" ;
        :title = "Time Series, Area-Averaged of Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v7] mm/hr over 2004-Jan - 2006-Dec, Region 100.5469W, 17.6953N, 69.6094W, 40.8985N " ;
        :history = "Thu Mar 26 18:02:10 2015: ncap2 -O -S /var/scratch/csmit/TMPDIR/unitsConversion_rKIr.ncap2 /var/scratch/csmit/TMPDIR/58nNhB24PB/timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N.nc /var/scratch/csmit/TMPDIR/58nNhB24PB/out.nc" ;
data:

 TRMM_3B43_007_precipitation = 65.27695, 90.26584, 64.99417, 87.87766, 
    92.14946, 125.8952, 139.906, 138.5064, 163.7647, 107.3546, 104.2197, 
    86.04598, 73.63101, 72.99761, 98.33076, 83.67595, 95.00203, 152.8425, 
    143.3745, 138.9878, 124.6354, 173.9981, 81.13932, 80.4915, 82.40313, 
    65.79417, 48.9963, 69.1861, 96.98621, 135.9086, 135.5336, 123.5227, 
    126.2206, 136.0847, 116.77, 102.6855 ;

 time_bnds =
  1072915200, 1075593600,
  1075593600, 1078099200,
  1078099200, 1080777600,
  1080777600, 1083369600,
  1083369600, 1086048000,
  1086048000, 1088640000,
  1088640000, 1091318400,
  1091318400, 1093996800,
  1093996800, 1096588800,
  1096588800, 1099267200,
  1099267200, 1101859200,
  1101859200, 1104537600,
  1104537600, 1107216000,
  1107216000, 1109635200,
  1109635200, 1112313600,
  1112313600, 1114905600,
  1114905600, 1117584000,
  1117584000, 1120176000,
  1120176000, 1122854400,
  1122854400, 1125532800,
  1125532800, 1128124800,
  1128124800, 1130803200,
  1130803200, 1133395200,
  1133395200, 1136073600,
  1136073600, 1138752000,
  1138752000, 1141171200,
  1141171200, 1143849600,
  1143849600, 1146441600,
  1146441600, 1149120000,
  1149120000, 1151712000,
  1151712000, 1154390400,
  1154390400, 1157068800,
  1157068800, 1159660800,
  1159660800, 1162339200,
  1162339200, 1164931200,
  1164931200, 1167609600 ;

 time = 1072915200, 1075593600, 1078099200, 1080777600, 1083369600, 
    1086048000, 1088640000, 1091318400, 1093996800, 1096588800, 1099267200, 
    1101859200, 1104537600, 1107216000, 1109635200, 1112313600, 1114905600, 
    1117584000, 1120176000, 1122854400, 1125532800, 1128124800, 1130803200, 
    1133395200, 1136073600, 1138752000, 1141171200, 1143849600, 1146441600, 
    1149120000, 1151712000, 1154390400, 1157068800, 1159660800, 1162339200, 
    1164931200 ;

 datamonth = 200401, 200402, 200403, 200404, 200405, 200406, 200407, 200408, 
    200409, 200410, 200411, 200412, 200501, 200502, 200503, 200504, 200505, 
    200506, 200507, 200508, 200509, 200510, 200511, 200512, 200601, 200602, 
    200603, 200604, 200605, 200606, 200607, 200608, 200609, 200610, 200611, 
    200612 ;
}
