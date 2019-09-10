#$Id: Giovanni-UnitsConversion_monthlyAccum.t,v 1.1 2015/03/20 21:10:15 csmit Exp $
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

######################
# Test the non-linear monthly accumulation
#####################

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

my $converter = Giovanni::UnitsConversion->new( config => $cfg, );

$converter->addConversion(
    sourceUnits      => 'mm/hr',
    destinationUnits => 'mm/month',
    variable         => 'TRMM_3B43_007_precipitation',
    type             => "float",
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
netcdf subsetted.TRMM_3B43_007_precipitation.20030101000000 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
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
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-01T00:00:00Z" ;
        :end_time = "2003-01-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :history = "Fri Mar 20 20:24:49 2015: ncks -d lat,30.,32. -d lon,-77.,-75. scrubbed.TRMM_3B43_007_precipitation.20030101000000.nc subsetted.TRMM_3B43_007_precipitation.20030101000000.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.1935484, 0.1493548, 0.2169758, 0.1646371, 0.1130645, 0.1256049, 
    0.1791935, 0.239758,
  0.2160081, 0.2454435, 0.2130645, 0.2706855, 0.2152822, 0.1144758, 0.174637, 
    0.1496774,
  0.2345967, 0.2394758, 0.25625, 0.1916129, 0.2262096, 0.2272177, 0.2196371, 
    0.2046371,
  0.1861694, 0.2237903, 0.2035484, 0.2125, 0.1922983, 0.2316128, 0.2521774, 
    0.2764516,
  0.2030242, 0.2309274, 0.1951613, 0.1847984, 0.1695968, 0.1889113, 
    0.2616532, 0.2675403,
  0.1658064, 0.217258, 0.2341532, 0.1769758, 0.2118145, 0.2470565, 0.3009274, 
    0.2822178,
  0.1446371, 0.162258, 0.1447177, 0.1417339, 0.1510081, 0.2327016, 0.2850403, 
    0.2698387,
  0.1590323, 0.1825806, 0.148629, 0.1675, 0.1703226, 0.2367339, 0.2171774, 
    0.2148387 ;

 datamonth = 200301 ;

 lat = 30.125, 30.375, 30.625, 30.875, 31.125, 31.375, 31.625, 31.875 ;

 lon = -76.875, -76.625, -76.375, -76.125, -75.875, -75.625, -75.375, -75.125 ;

 time = 1041379200 ;
}
netcdf out {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 8 ;
    lon = 8 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
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
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-01T00:00:00Z" ;
        :end_time = "2003-01-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  144, 111.12, 161.43, 122.49, 84.11999, 93.45004, 133.32, 178.38,
  160.71, 182.61, 158.52, 201.39, 160.17, 85.17, 129.9299, 111.36,
  174.5399, 178.17, 190.65, 142.56, 168.2999, 169.05, 163.41, 152.25,
  138.51, 166.5, 151.44, 158.1, 143.0699, 172.3199, 187.62, 205.68,
  151.05, 171.81, 145.2, 137.49, 126.18, 140.55, 194.67, 199.05,
  123.36, 161.64, 174.21, 131.67, 157.59, 183.81, 223.89, 209.97,
  107.61, 120.7199, 107.67, 105.45, 112.35, 173.13, 212.07, 200.76,
  118.32, 135.84, 110.58, 124.62, 126.72, 176.13, 161.58, 159.84 ;

 datamonth = 200301 ;

 lat = 30.125, 30.375, 30.625, 30.875, 31.125, 31.375, 31.625, 31.875 ;

 lon = -76.875, -76.625, -76.375, -76.125, -75.875, -75.625, -75.375, -75.125 ;

 time = 1041379200 ;
}


