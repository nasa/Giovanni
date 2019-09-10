#$Id: Giovanni-UnitsConversion.t,v 1.7 2015/03/26 18:10:31 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-UnitsConversion.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::UnitsConversion') }

#########################

########################
# Test basic linear conversion
########################

use warnings;
use strict;
use Giovanni::Data::NcFile;
use File::Temp qq/tempdir/;

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
            class="Giovanni::UnitsConversion::MonthlyAccumulation" />
    </nonLinearConversions>
</units>
XML
my $cfg = "$dir/cfg.xml";
open( CFG, ">", $cfg );
print CFG $conversionCfg;
close(CFG);

my $converter = Giovanni::UnitsConversion->new( config => $cfg, );

$converter->addConversion(
    sourceUnits      => 'mm/day',
    destinationUnits => 'mm/hr',
    variable         => 'TRMM_3B42_daily_precipitation_V7',
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
netcdf timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N {
dimensions:
    lat = 10 ;
    lon = 10 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V7:cell_methods = "time: mean time: mean" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:plot_hint_legend_label = "TRMM_3B42_daily_precipitation_V7" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2002-12-31T22:30:00Z" ;
        :end_time = "2003-01-01T22:29:59Z" ;
        :history = "Fri Mar  6 21:49:39 2015: ncatted -a valid_range,,d,, -O -o timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N.nc timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N.nc\n",
            "Fri Mar  6 21:49:39 2015: ncatted -O -a title,global,o,c,TRMM_3B42_daily_precipitation_V7 Averaged over 2003-01-01 to 2003-01-01 ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc\n",
            "Fri Mar  6 21:49:39 2015: ncks -x -v time -o ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc -O ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc\n",
            "Fri Mar  6 21:49:39 2015: ncwa -o ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc -a time -O ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc\n",
            "Fri Mar  6 21:49:39 2015: ncra -D 2 -H -O -o ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc -d lat,29.077100,31.406300 -d lon,-80.581100,-77.988300" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day over 2002-12-31 22:30Z - 2003-01-01 22:29Z, Region 80.5811W, 29.0771N, 77.9883W, 31.4063N " ;
        :userstartdate = "2003-01-01T00:00:00Z" ;
        :userenddate = "2003-01-01T23:59:59Z" ;
        :plot_hint_title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day" ;
        :plot_hint_subtitle = "over 2002-12-31 22:30Z - 2003-01-01 22:29Z, Region 80.5811W, 29.0771N, 77.9883W, 31.4063N " ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-01. Title reflects the date range of the granules that went into making this result." ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  27.25473, 27.12524, 33.99, 141.24, 49.92, 81.27, 50.64, 162.51, 116.73, 
    132.3,
  19.70452, 21.51545, 28.68, 112.17, 140.46, 123, 34.95, 40.41, 99.84, 155.01,
  20.72279, 15.43937, 22.89, 54.39, 126.18, 128.25, 83.06999, 65.22, 111.48, 
    158.34,
  16.50453, 18.0936, 25.44, 28.35, 49.29, 105.24, 136.53, 69.53999, 65.73, 
    100.53,
  44.82, 53.88, 25.5, 21.21, 18.12, 26.16, 122.67, 78.78, 50.52, 109.53,
  38.4, 55.05, 34.53, 22.47, 16.47, 17.88, 55.08, 95.37, 76.56001, 40.95,
  33.48, 50.49, 24.18, 22.23, 16.17, 16.92, 68.55, 144, 69.89999, 25.35,
  41.31, 44.01, 26.76, 18.12, 13.62, 21.57, 52.41, 108.24, 41.58, 30.69,
  11.49, 9.246, 25.17, 23.19, 21.72, 17.67, 19.89, 51.72, 38.93999, 24.78,
  8.604, 9.791999, 30.18, 31.98, 26.19, 28.23, 18.99, 65.49, 59.25, 39.39 ;

 lat = 29.125, 29.375, 29.625, 29.875, 30.125, 30.375, 30.625, 30.875, 
    31.125, 31.375 ;

 lon = -80.375, -80.125, -79.875, -79.625, -79.375, -79.125, -78.875, 
    -78.625, -78.375, -78.125 ;

 time = 1041373800 ;
}
netcdf out {
dimensions:
    lat = 10 ;
    lon = 10 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:cell_methods = "time: mean time: mean" ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:plot_hint_legend_label = "TRMM_3B42_daily_precipitation_V7" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm/hr" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2002-12-31T22:30:00Z" ;
        :end_time = "2003-01-01T22:29:59Z" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day over 2002-12-31 22:30Z - 2003-01-01 22:29Z, Region 80.5811W, 29.0771N, 77.9883W, 31.4063N " ;
        :userstartdate = "2003-01-01T00:00:00Z" ;
        :userenddate = "2003-01-01T23:59:59Z" ;
        :plot_hint_title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day" ;
        :plot_hint_subtitle = "over 2002-12-31 22:30Z - 2003-01-01 22:29Z, Region 80.5811W, 29.0771N, 77.9883W, 31.4063N " ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-01. Title reflects the date range of the granules that went into making this result." ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  1.135614, 1.130218, 1.41625, 5.885, 2.08, 3.38625, 2.11, 6.77125, 4.86375, 
    5.5125,
  0.8210216, 0.896477, 1.195, 4.67375, 5.8525, 5.125, 1.45625, 1.68375, 4.16, 
    6.45875,
  0.8634496, 0.6433071, 0.95375, 2.26625, 5.2575, 5.34375, 3.46125, 2.7175, 
    4.645, 6.5975,
  0.6876888, 0.7539, 1.06, 1.18125, 2.05375, 4.385, 5.68875, 2.8975, 2.73875, 
    4.18875,
  1.8675, 2.245, 1.0625, 0.88375, 0.7550001, 1.09, 5.11125, 3.2825, 2.105, 
    4.56375,
  1.6, 2.29375, 1.43875, 0.93625, 0.68625, 0.7449999, 2.295, 3.97375, 
    3.190001, 1.70625,
  1.395, 2.10375, 1.0075, 0.92625, 0.67375, 0.705, 2.85625, 6, 2.912499, 
    1.05625,
  1.72125, 1.83375, 1.115, 0.7550001, 0.5675, 0.89875, 2.18375, 4.51, 1.7325, 
    1.27875,
  0.47875, 0.38525, 1.04875, 0.96625, 0.905, 0.73625, 0.82875, 2.155, 1.6225, 
    1.0325,
  0.3585, 0.408, 1.2575, 1.3325, 1.09125, 1.17625, 0.79125, 2.72875, 2.46875, 
    1.64125 ;

 lat = 29.125, 29.375, 29.625, 29.875, 30.125, 30.375, 30.625, 30.875, 
    31.125, 31.375 ;

 lon = -80.375, -80.125, -79.875, -79.625, -79.375, -79.125, -78.875, 
    -78.625, -78.375, -78.125 ;

 time = 1041373800 ;
}
