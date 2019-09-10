#!/usr/bin/env perl
#-@@@ Giovanni, Version $Name:  $

use strict;
use File::Temp qw/ tempdir /;
use Test::More tests => 3;

use Giovanni::Data::NcFile;
BEGIN { use_ok('Giovanni::Serializer::TimeSeries') }

my $dir = tempdir( CLEANUP => 1, DIR => $ENV{TMPDIR} );

# write out the test file
my $cdl     = Giovanni::Data::NcFile::read_cdl_data_block();
my $cdlFile = "$dir/in.cdl";
open( FILE, '>', $cdlFile );
print FILE $cdl->[0];
close(FILE);
my $inNcFile = "$dir/in.nc";
my @cmd      = ( 'ncgen', '-o', $inNcFile, $cdlFile );
my $ret      = system(@cmd);
if ( $ret != 0 ) {
    die "Unable to create netcdf file: " . join( " ", @cmd );
}

# input.xml
my $inputXML = <<'XML';
<input>
    <referer>http://some.url.com/giovanni/</referer>
    <query>session=5B0F1BA0-F692-11E5-853A-A4B8F1651532&amp;service=DiArAvTs&amp;starttime=2001-01-01T00:00:00Z&amp;endtime=2001-12-31T23:59:59Z&amp;bbox=-135,0,-45,52&amp;data=NLDAS_NOAH0125_M_002_snodsfc%2CGLDAS_NOAH10_M_2_0_SnowDepth_inst&amp;portal=GIOVANNI&amp;format=json</query>
    <title>Time Series, Area-Averaged Differences</title>
    <description>Time series of area averages of differences between two variables at each spatial grid point from 2001-01-01T00:00:00Z to 2001-12-31T23:59:59Z over -135,0,-45,52</description>
    <result id="5CCBE5AE-F692-11E5-9D14-CFB8F1651532">
        <dir>/var/giovanni/session/5B0F1BA0-F692-11E5-853A-A4B8F1651532/5CCBB3C2-F692-11E5-9D14-CFB8F1651532/5CCBE5AE-F692-11E5-9D14-CFB8F1651532/</dir>
    </result>
    <bbox>-135,0,-45,52</bbox>
    <data>NLDAS_NOAH0125_M_002_snodsfc</data>
    <data>GLDAS_NOAH10_M_2_0_SnowDepth_inst</data>
    <endtime>2001-12-31T23:59:59Z</endtime>
    <portal>GIOVANNI</portal>
    <service>DiArAvTs</service>
    <session>5B0F1BA0-F692-11E5-853A-A4B8F1651532</session>
    <starttime>2001-01-01T00:00:00Z</starttime>
</input>
XML
my $inputFile = "$dir/input.xml";
open( FILE, '>', $inputFile );
print FILE $inputXML;
close(FILE);



my $csvFile = Giovanni::Serializer::TimeSeries::serialize(
    input   => $inputFile,
    outDir  => $dir,
    ncFile  => $inNcFile,

);

ok( -f $csvFile, "Created serialization" );

# read out the csv
open( FILE, "<", $csvFile );
my @lines = <FILE>;
close(FILE);
my $csvOut = join('',@lines);

my $csvCorrect = <<'CSV';
Title:,Time Series, Area-Averaged Differences over 2001-Jan - 2001-Dec, Region 125W, 25N, 67W, 52N  of Snow depth monthly ()
User Start Date:,2001-01-01T00:00:00Z
User End Date:,2001-12-31T23:59:59Z
Bounding Box:,"-135,0,-45,52"
URL to Reproduce Results:,"http://some.url.com/giovanni/#service=DiArAvTs&starttime=2001-01-01T00:00:00Z&endtime=2001-12-31T23:59:59Z&bbox=-135,0,-45,52&data=NLDAS_NOAH0125_M_002_snodsfc%2CGLDAS_NOAH10_M_2_0_SnowDepth_inst&portal=GIOVANNI&format=json"
Fill Value (difference): -9999,Fill Value (stddev_difference): -9999,Fill Value (min_difference): -9999,Fill Value (max_difference): -9999,Fill Value (count_difference): -999

time, difference, stddev_difference, min_difference, max_difference, count_difference
2001-01-01 00:00:00,-0.0180745907,0.114478402,-0.770151615,0.686725497,1149
2001-02-01 00:00:00,-0.02475309,0.144914702,-1.17067099,1.14102697,1149
2001-03-01 00:00:00,-0.0392068289,0.123148002,-0.947481573,1.01121795,1149
2001-04-01 00:00:00,-0.0251715593,0.0816430524,-0.878709614,0.766414225,1149
2001-05-01 00:00:00,-0.00323102903,0.0271524601,-0.408758014,0.429312915,1149
2001-06-01 00:00:00,-0.000134170798,0.00201614993,-0.0500166304,0.00256426097,1149
2001-07-01 00:00:00,-3.99627886e-08,4.46990407e-06,-2.81790108e-05,0.000100403202,1149
2001-08-01 00:00:00,-6.04496392e-07,4.80176595e-06,-8.96554629e-05,1.24217104e-05,1149
2001-09-01 00:00:00,1.36746503e-05,0.000175207693,-0.00119941495,0.00282295002,1149
2001-10-01 00:00:00,9.33363699e-05,0.00624866318,-0.110313103,0.0336440094,1149
2001-11-01 00:00:00,-0.00246084807,0.0213878192,-0.409048706,0.258473694,1149
2001-12-01 00:00:00,-0.0303586107,0.0890273899,-0.893914878,0.726749778,1149
CSV

is( $csvOut, $csvCorrect, "Got the correct csv" );

__DATA__
netcdf g4.areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N {
dimensions:
    bnds = 2 ;
    time = UNLIMITED ; // (12 currently)
variables:
    int time_bnds(time, bnds) ;
    int count_difference(time) ;
        count_difference:_FillValue = -999 ;
        count_difference:_Netcdf4Dimid = 2 ;
        count_difference:fullnamepath = "/SnowDepth_inst" ;
        count_difference:long_name = "Snow depth monthly 1 deg. [GLDAS Model GLDAS_NOAH10_M v2.0] m minus Snow depth monthly 0.125 deg. [NLDAS Model NLDAS_NOAH0125_M v002] m" ;
        count_difference:missing_value = -9999.f ;
        count_difference:origname = "SnowDepth_inst" ;
        count_difference:product_short_name = "GLDAS_NOAH10_M" ;
        count_difference:product_version = "2.0" ;
        count_difference:quantity_type = "count of Snow/Ice" ;
        count_difference:standard_name = "surface_snow_thickness" ;
        count_difference:units = "m" ;
        count_difference:vmax = 193.6915f ;
        count_difference:vmin = 0.f ;
        count_difference:coordinates = "time" ;
        count_difference:plot_hint_legend_label = "GLDAS_NOAH10_M_2_0_SnowDepth_inst minus~C~NLDAS_NOAH0125_M_002_snodsfc" ;
    float difference(time) ;
        difference:_FillValue = -9999.f ;
        difference:_Netcdf4Dimid = 2 ;
        difference:cell_methods = "lat,lon: mean" ;
        difference:fullnamepath = "/SnowDepth_inst" ;
        difference:long_name = "Snow depth minus Snow depth" ;
        difference:missing_value = -9999.f ;
        difference:origname = "SnowDepth_inst" ;
        difference:product_short_name = "GLDAS_NOAH10_M" ;
        difference:product_version = "2.0" ;
        difference:quantity_type = "Snow/Ice" ;
        difference:standard_name = "surface_snow_thickness" ;
        difference:units = "m" ;
        difference:vmax = 193.6915f ;
        difference:vmin = 0.f ;
        difference:coordinates = "time" ;
    float max_difference(time) ;
        max_difference:_FillValue = -9999.f ;
        max_difference:_Netcdf4Dimid = 2 ;
        max_difference:cell_methods = "lat,lon: maximum" ;
        max_difference:fullnamepath = "/SnowDepth_inst" ;
        max_difference:long_name = "Snow depth minus Snow depth" ;
        max_difference:missing_value = -9999.f ;
        max_difference:origname = "SnowDepth_inst" ;
        max_difference:product_short_name = "GLDAS_NOAH10_M" ;
        max_difference:product_version = "2.0" ;
        max_difference:quantity_type = "maximum of Snow/Ice" ;
        max_difference:standard_name = "surface_snow_thickness" ;
        max_difference:units = "m" ;
        max_difference:vmax = 193.6915f ;
        max_difference:vmin = 0.f ;
        max_difference:coordinates = "time" ;
    float min_difference(time) ;
        min_difference:_FillValue = -9999.f ;
        min_difference:_Netcdf4Dimid = 2 ;
        min_difference:cell_methods = "lat,lon: minimum" ;
        min_difference:fullnamepath = "/SnowDepth_inst" ;
        min_difference:long_name = "Snow depth minus Snow depth" ;
        min_difference:missing_value = -9999.f ;
        min_difference:origname = "SnowDepth_inst" ;
        min_difference:product_short_name = "GLDAS_NOAH10_M" ;
        min_difference:product_version = "2.0" ;
        min_difference:quantity_type = "minimum of Snow/Ice" ;
        min_difference:standard_name = "surface_snow_thickness" ;
        min_difference:units = "m" ;
        min_difference:vmax = 193.6915f ;
        min_difference:vmin = 0.f ;
        min_difference:coordinates = "time" ;
    float stddev_difference(time) ;
        stddev_difference:_FillValue = -9999.f ;
        stddev_difference:_Netcdf4Dimid = 2 ;
        stddev_difference:cell_methods = "lat,lon: standard deviation" ;
        stddev_difference:fullnamepath = "/SnowDepth_inst" ;
        stddev_difference:long_name = "Snow depth minus Snow depth" ;
        stddev_difference:missing_value = -9999.f ;
        stddev_difference:origname = "SnowDepth_inst" ;
        stddev_difference:product_short_name = "GLDAS_NOAH10_M" ;
        stddev_difference:product_version = "2.0" ;
        stddev_difference:quantity_type = "standard deviation of Snow/Ice" ;
        stddev_difference:standard_name = "surface_snow_thickness" ;
        stddev_difference:units = "m" ;
        stddev_difference:vmax = 193.6915f ;
        stddev_difference:vmin = 0.f ;
        stddev_difference:coordinates = "time" ;
    double time(time) ;
        time:CLASS = "DIMENSION_SCALE" ;
        time:NAME = "time" ;
        time:_Netcdf4Dimid = 2 ;
        time:begin_date = "20010101" ;
        time:begin_time = "000000" ;
        time:fullnamepath = "/time" ;
        time:long_name = "time" ;
        time:origname = "time" ;
        time:standard_name = "time" ;
        time:time_increment = "one month" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:bounds = "time_bnds" ;

// global attributes:
        :NCO = "\"4.5.3\"" ;
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2001-01-01T00:00:00Z" ;
        :end_time = "2001-12-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :nco_input_file_number = 12 ;
        :nco_input_file_list = "areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.0 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.1 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.2 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.3 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.4 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.5 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.6 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.7 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.8 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.9 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.10 areaAvgDiffTimeSeries.NLDAS_NOAH0125_M_002_snodsfc+GLDAS_NOAH10_M_2_0_SnowDepth_inst.20010101-20011231.125W_25N_67W_52N.nc.11" ;
        :userstartdate = "2001-01-01T00:00:00Z" ;
        :userenddate = "2001-12-31T23:59:59Z" ;
        :title = "Time Series, Area-Averaged Differences over 2001-Jan - 2001-Dec, Region 125W, 25N, 67W, 52N  of Snow depth monthly 1 deg. [GLDAS Model GLDAS_NOAH10_M v2.0] m minus Snow depth monthly 0.125 deg. [NLDAS Model NLDAS_NOAH0125_M v002] m" ;
        :plot_hint_title = "Time Series, Area-Averaged Differences over 2001-Jan - 2001-Dec, Region 125W, 25N, 67W, 52N  of Snow depth monthly" ;
        :plot_hint_subtitle = "1 deg. [GLDAS Model GLDAS_NOAH10_M v2.0] m minus Snow depth monthly 0.125 deg. [NLDAS Model NLDAS_NOAH0125_M v002] m" ;
        :plot_hint_time_axis_values = "978307200,983404800,988675200,993945600,999302400,1004572800,1009843200" ;
        :plot_hint_time_axis_labels = "Jan,Mar,May,Jul,Sep,Nov,Jan~C~2002" ;
        :plot_hint_time_axis_minor = "980985600,986083200,991353600,996624000,1001894400,1007164800" ;
        :plot_hint_caption = "- Selected region was 135W, 0N, 45W, 52N. Snow depth monthly 0.125 deg. [NLDAS Model NLDAS_NOAH0125_M v002] m has a limited data extent of 125W, 25N, 67W, 53N. The region in the title reflects the data extent of the subsetted granules that went into making this result." ;
data:

 time_bnds =
  978307200, 980985600,
  980985600, 983404800,
  983404800, 986083200,
  986083200, 988675200,
  988675200, 991353600,
  991353600, 993945600,
  993945600, 996624000,
  996624000, 999302400,
  999302400, 1001894400,
  1001894400, 1004572800,
  1004572800, 1007164800,
  1007164800, 1009843200 ;

 count_difference = 1149, 1149, 1149, 1149, 1149, 1149, 1149, 1149, 1149, 
    1149, 1149, 1149 ;

 difference = -0.01807459, -0.02475309, -0.03920683, -0.02517156, 
    -0.003231029, -0.0001341708, -3.996279e-08, -6.044964e-07, 1.367465e-05, 
    9.333637e-05, -0.002460848, -0.03035861 ;

 max_difference = 0.6867255, 1.141027, 1.011218, 0.7664142, 0.4293129, 
    0.002564261, 0.0001004032, 1.242171e-05, 0.00282295, 0.03364401, 
    0.2584737, 0.7267498 ;

 min_difference = -0.7701516, -1.170671, -0.9474816, -0.8787096, -0.408758, 
    -0.05001663, -2.817901e-05, -8.965546e-05, -0.001199415, -0.1103131, 
    -0.4090487, -0.8939149 ;

 stddev_difference = 0.1144784, 0.1449147, 0.123148, 0.08164305, 0.02715246, 
    0.00201615, 4.469904e-06, 4.801766e-06, 0.0001752077, 0.006248663, 
    0.02138782, 0.08902739 ;

 time = 978307200, 980985600, 983404800, 986083200, 988675200, 991353600, 
    993945600, 996624000, 999302400, 1001894400, 1004572800, 1007164800 ;
}
