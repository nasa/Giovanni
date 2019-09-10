#$Id: Giovanni-UnitsConversion_monthlyAccumAndLinear.t,v 1.1 2015/03/26 18:10:31 csmit Exp $
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
# Test that we can do one variable with the monthly accumulation and one
# with a linear conversion.
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
        <linearUnit source="mm/hr" destination="mm/day"
            scale_factor="24" add_offset="0" />
    </linearConversions>
    <nonLinearConversions>
        <timeDependentUnit source="mm/hr" destination="mm/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="24.0" />
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
    variable         => 'x_TRMM_3B43_007_precipitation',
    type             => "float",
);

$converter->addConversion(
    sourceUnits      => 'mm/hr',
    destinationUnits => 'mm/day',
    variable         => 'y_TRMM_3B43_006_precipitation',
    type             => 'float'
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
netcdf pairedData.TRMM_3B43_007_precipitation+TRMM_3B43_006_precipitation.20040101-20040201.77W_38N_77W_39N {
dimensions:
    time = UNLIMITED ; // (2 currently)
    lat = 2 ;
    lon = 2 ;
variables:
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
    float x_TRMM_3B43_007_precipitation(time, lat, lon) ;
        x_TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        x_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        x_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        x_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        x_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        x_TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        x_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        x_TRMM_3B43_007_precipitation:product_version = "7" ;
        x_TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        x_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        x_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        x_TRMM_3B43_007_precipitation:units = "mm/hr" ;
        x_TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
        x_TRMM_3B43_007_precipitation:plot_hint_axis_title = "Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v7] mm/hr" ;
    float y_TRMM_3B43_006_precipitation(time, lat, lon) ;
        y_TRMM_3B43_006_precipitation:_FillValue = -9999.9f ;
        y_TRMM_3B43_006_precipitation:comments = "Unknown1 variable comment" ;
        y_TRMM_3B43_006_precipitation:grid_name = "grid-1" ;
        y_TRMM_3B43_006_precipitation:grid_type = "linear" ;
        y_TRMM_3B43_006_precipitation:level_description = "Earth surface" ;
        y_TRMM_3B43_006_precipitation:long_name = "Precipitation Rate" ;
        y_TRMM_3B43_006_precipitation:product_short_name = "TRMM_3B43" ;
        y_TRMM_3B43_006_precipitation:product_version = "6" ;
        y_TRMM_3B43_006_precipitation:quantity_type = "Precipitation" ;
        y_TRMM_3B43_006_precipitation:standard_name = "pcp" ;
        y_TRMM_3B43_006_precipitation:time_statistic = "instantaneous" ;
        y_TRMM_3B43_006_precipitation:units = "mm/hr" ;
        y_TRMM_3B43_006_precipitation:coordinates = "time lat lon" ;
        y_TRMM_3B43_006_precipitation:plot_hint_axis_title = "Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v6] mm/hr" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :temporal_resolution = "monthly" ;
        :nco_openmp_thread_number = 1 ;
        :matched_start_time = "2004-01-01T00:00:00Z" ;
        :matched_end_time = "2004-02-29T23:59:59Z" ;
        :title = "Data match (77.6074W - 77.0801W, 38.8623N - 39.3018N): TRMM_3B43.7 TRMM_3B43.6" ;
        :plot_hint_title = "Region 77.6074W, 38.8623N, 77.0801W, 39.3018N" ;
        :plot_hint_subtitle = "2004-Jan - 2004-Feb" ;
data:

 datamonth = 200401, 200402 ;

 lat = 38.875, 39.125 ;

 lon = -77.375, -77.125 ;

 time = 1072915200, 1075593600 ;

 x_TRMM_3B43_007_precipitation =
  0.06258529, 0.06518552,
  0.06596033, 0.06650973,
  0.09440108, 0.0956439,
  0.1127367, 0.1132886 ;

 y_TRMM_3B43_006_precipitation =
  0.05787018, 0.06034757,
  0.06253958, 0.06401914,
  0.07072909, 0.08151371,
  0.09512591, 0.09951203 ;
}
netcdf out {
dimensions:
    time = UNLIMITED ; // (2 currently)
    lat = 2 ;
    lon = 2 ;
variables:
    float x_TRMM_3B43_007_precipitation(time, lat, lon) ;
        x_TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        x_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        x_TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
        x_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        x_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        x_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        x_TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        x_TRMM_3B43_007_precipitation:plot_hint_axis_title = "Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v7] mm/hr" ;
        x_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        x_TRMM_3B43_007_precipitation:product_version = "7" ;
        x_TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        x_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        x_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        x_TRMM_3B43_007_precipitation:units = "mm/month" ;
    float y_TRMM_3B43_006_precipitation(time, lat, lon) ;
        y_TRMM_3B43_006_precipitation:_FillValue = -9999.9f ;
        y_TRMM_3B43_006_precipitation:comments = "Unknown1 variable comment" ;
        y_TRMM_3B43_006_precipitation:coordinates = "time lat lon" ;
        y_TRMM_3B43_006_precipitation:grid_name = "grid-1" ;
        y_TRMM_3B43_006_precipitation:grid_type = "linear" ;
        y_TRMM_3B43_006_precipitation:level_description = "Earth surface" ;
        y_TRMM_3B43_006_precipitation:long_name = "Precipitation Rate" ;
        y_TRMM_3B43_006_precipitation:plot_hint_axis_title = "Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v6] mm/hr" ;
        y_TRMM_3B43_006_precipitation:product_short_name = "TRMM_3B43" ;
        y_TRMM_3B43_006_precipitation:product_version = "6" ;
        y_TRMM_3B43_006_precipitation:quantity_type = "Precipitation" ;
        y_TRMM_3B43_006_precipitation:standard_name = "pcp" ;
        y_TRMM_3B43_006_precipitation:time_statistic = "instantaneous" ;
        y_TRMM_3B43_006_precipitation:units = "mm/day" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :temporal_resolution = "monthly" ;
        :nco_openmp_thread_number = 1 ;
        :matched_start_time = "2004-01-01T00:00:00Z" ;
        :matched_end_time = "2004-02-29T23:59:59Z" ;
        :title = "Data match (77.6074W - 77.0801W, 38.8623N - 39.3018N): TRMM_3B43.7 TRMM_3B43.6" ;
        :plot_hint_title = "Region 77.6074W, 38.8623N, 77.0801W, 39.3018N" ;
        :plot_hint_subtitle = "2004-Jan - 2004-Feb" ;
data:

 x_TRMM_3B43_007_precipitation =
  46.56345, 48.49802,
  49.07449, 49.48324,
  65.70315, 66.56815,
  78.46474, 78.84887 ;

 y_TRMM_3B43_006_precipitation =
  1.388884, 1.448342,
  1.50095, 1.536459,
  1.697498, 1.956329,
  2.283022, 2.388289 ;

 datamonth = 200401, 200402 ;

 lat = 38.875, 39.125 ;

 lon = -77.375, -77.125 ;

 time = 1072915200, 1075593600 ;
}
