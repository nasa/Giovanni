#$Id: Giovanni-UnitsConversion_scatterTwoTimeDependent.t,v 1.1 2015/04/07 17:30:55 csmit Exp $
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
# Do a test with a scatter plot file, which has two variables that can be
# converted. This test does two time-dependent conversions.
##################

my $dir = tempdir( CLEANUP => 1 );

my ( $inCdl, $correctCdl ) = readCdlData();

my $dataFile
    = "$dir/areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc";
Giovanni::Data::NcFile::write_netcdf_file( $dataFile, $inCdl )
    or die "Unable to write input file.";

my $conversionCfg = <<XML;
<units>
    <linearConversions>
        <linearUnit source="mm/hr" destination="mm/day"
            scale_factor="24" add_offset="0" />
        <linearUnit source="mm/hr" destination="inch/hr"
            scale_factor="1.0/25.4" add_offset="0" />
        <linearUnit source="mm/hr" destination="inch/day"
            scale_factor="24.0/25.4" add_offset="0" />
        <linearUnit source="mm/day" destination="mm/hr"
            scale_factor="1.0/24.0" add_offset="0" />
        <linearUnit source="mm/day" destination="inch/day"
            scale_factor="1.0/25.4" add_offset="0" />
        <linearUnit source="kg/m^2" destination="mm" scale_factor="1"
            add_offset="0" />
        <linearUnit source="K" destination="C" scale_factor="1"
            add_offset="-273.15" />
        <linearUnit source="kg/m^2/s" destination="mm/s"
            scale_factor="1" add_offset="0" />
        <linearUnit source="molecules/cm^2" destination="DU"
            scale_factor="1.0/2.6868755e+16" add_offset="0" />
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
    <fileFriendlyStrings>
        <destinationUnit original="mm/day" file="mmPday" />
        <destinationUnit original="inch/hr" file="inPhr" />
        <destinationUnit original="inch/day" file="inPday" />
        <destinationUnit original="mm/hr" file="mmPhr" />
        <destinationUnit original="mm" file="mm" />
        <destinationUnit original="mm/s" file="mmPs" />
        <destinationUnit original="DU" file="DU" />
        <destinationUnit original="mm/month" file="mmPmon" />
        <destinationUnit original="inch/month" file="inPmon" />
    </fileFriendlyStrings>
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

$converter->addConversion(
    sourceUnits      => 'mm/hr',
    destinationUnits => 'mm/month',
    variable         => 'TRMM_3B43_006_precipitation',
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

my $out
    = Giovanni::Data::NcFile::diff_netcdf_files( $destFile, $correctNc );

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
netcdf areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N {
dimensions:
    lat = 1 ;
    lon = 1 ;
    time = UNLIMITED ; // (12 currently)
variables:
    double lat(lat) ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
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
        TRMM_3B43_007_precipitation:cell_methods = "lat, lon: mean" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
    float TRMM_3B43_006_precipitation(time, lat, lon) ;
        TRMM_3B43_006_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_006_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_006_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_006_precipitation:grid_type = "linear" ;
        TRMM_3B43_006_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_006_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_006_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_006_precipitation:product_version = "6" ;
        TRMM_3B43_006_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_006_precipitation:standard_name = "pcp" ;
        TRMM_3B43_006_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_006_precipitation:units = "mm/hr" ;
        TRMM_3B43_006_precipitation:cell_methods = "lat, lon: mean" ;
        TRMM_3B43_006_precipitation:coordinates = "time lat lon" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :temporal_resolution = "monthly" ;
        :nco_input_file_number = 12 ;
        :nco_input_file_list = "areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.0 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.1 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.2 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.3 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.4 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.5 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.6 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.7 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.8 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.9 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.10 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.11" ;
        :NCO = "4.4.4" ;
        :start_time = "2006-01-01T00:00:00Z" ;
        :end_time = "2006-12-31T23:59:59Z" ;
        :userstartdate = "2006-01-01T00:00:00Z" ;
        :userenddate = "2006-12-31T23:59:59Z" ;
data:

 lat = 14.1797 ;

 lon = -100.5469 ;

 TRMM_3B43_007_precipitation =
  0.1019325,
  0.08737972,
  0.06312572,
  0.073708,
  0.1271636,
  0.1957394,
  0.1863892,
  0.1718287,
  0.1877018,
  0.1954612,
  0.1475884,
  0.153685 ;

 time = 1136073600, 1138752000, 1141171200, 1143849600, 1146441600, 
    1149120000, 1151712000, 1154390400, 1157068800, 1159660800, 1162339200, 
    1164931200 ;

 TRMM_3B43_006_precipitation =
  0.07419574,
  0.06440693,
  0.04886791,
  0.05791877,
  0.0970092,
  0.1419713,
  0.1372211,
  0.1273118,
  0.1350742,
  0.1367707,
  0.1085327,
  0.1190647 ;
}
netcdf out {
dimensions:
    time = UNLIMITED ; // (12 currently)
    lat = 1 ;
    lon = 1 ;
variables:
    float TRMM_3B43_006_precipitation(time, lat, lon) ;
        TRMM_3B43_006_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_006_precipitation:cell_methods = "lat, lon: mean" ;
        TRMM_3B43_006_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_006_precipitation:coordinates = "time lat lon" ;
        TRMM_3B43_006_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_006_precipitation:grid_type = "linear" ;
        TRMM_3B43_006_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_006_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_006_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_006_precipitation:product_version = "6" ;
        TRMM_3B43_006_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_006_precipitation:standard_name = "pcp" ;
        TRMM_3B43_006_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_006_precipitation:units = "mm/month" ;
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:cell_methods = "lat, lon: mean" ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/month" ;
    double lat(lat) ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :temporal_resolution = "monthly" ;
        :nco_input_file_number = 12 ;
        :nco_input_file_list = "areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.0 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.1 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.2 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.3 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.4 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.5 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.6 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.7 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.8 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.9 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.10 areaAvgScatter.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20060101-20061231.100W_14N_77W_40N.nc.0.11" ;
        :NCO = "4.4.4" ;
        :start_time = "2006-01-01T00:00:00Z" ;
        :end_time = "2006-12-31T23:59:59Z" ;
        :userstartdate = "2006-01-01T00:00:00Z" ;
        :userenddate = "2006-12-31T23:59:59Z" ;
data:

 TRMM_3B43_006_precipitation =
  55.20163,
  43.28146,
  36.35773,
  41.70151,
  72.17484,
  102.2193,
  102.0925,
  94.71998,
  97.25343,
  101.7574,
  78.14354,
  88.58414 ;

 TRMM_3B43_007_precipitation =
  75.83778,
  58.71917,
  46.96554,
  53.06976,
  94.60972,
  140.9324,
  138.6736,
  127.8406,
  135.1453,
  145.4231,
  106.2636,
  114.3416 ;

 lat = 14.1797 ;

 lon = -100.5469 ;

 time = 1136073600, 1138752000, 1141171200, 1143849600, 1146441600, 
    1149120000, 1151712000, 1154390400, 1157068800, 1159660800, 1162339200, 
    1164931200 ;
}


