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
    <query>session=AA5F1D6A-D58E-11E5-9D82-D0AF4906A655&amp;service=ArAvTs&amp;starttime=2003-01-01T00:00:00Z&amp;endtime=2003-01-03T23:59:59Z&amp;bbox=-180,-50,180,50&amp;data=TRMM_3B42_daily_precipitation_V7&amp;portal=GIOVANNI&amp;format=json</query>
    <title>Time Series, Area-Averaged</title>
    <description>Time series of area-averaged values from 2003-01-01T00:00:00Z to 2003-01-03T23:59:59Z over -180,-50,180,50</description>
    <bbox>-180,-50,180,50</bbox>
    <data>TRMM_3B42_daily_precipitation_V7</data>
    <endtime>2003-01-03T23:59:59Z</endtime>
    <portal>GIOVANNI</portal>
    <service>ArAvTs</service>
    <starttime>2003-01-01T00:00:00Z</starttime>
</input>
XML
my $inputFile = "$dir/input.xml";
open( FILE, '>', $inputFile );
print FILE $inputXML;
close(FILE);

# data field info file
my $dataFieldInfoXML = << 'XML';
<varList>
    <var id="TRMM_3B42_daily_precipitation_V7" long_name="Precipitation Rate" dataProductTimeFrequency="1" accessFormat="netCDF" north="50.0" accessMethod="HTTP_Services_HDF_TO_NetCDF" endTime="2015-01-31T22:29:59Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Daily%20TRMM%20and%20Others%20Rainfall%20Estimate%20(3B42%20V7%20derived)%20V7;agent_id=HTTP_Services_HDF_TO_NetCDF;variables=TRMM_3B42_daily_precipitation_V7" startTime="1997-12-31T00:00:00Z" responseFormat="netCDF" south="-50.0" dataProductTimeInterval="daily" dataProductVersion="7" sampleFile="" east="180.0" osdd="" dataProductShortName="TRMM_3B42_daily" resolution="0.25 deg." dataProductPlatformInstrument="TRMM" quantity_type="Precipitation" dataFieldStandardName="" dataProductEndDateTime="2015-01-31T22:29:59Z" dataFieldUnitsValue="mm/day" latitudeResolution="0.25" accessName="TRMM_3B42_daily_precipitation_V7" fillValueFieldName="" valuesDistribution="linear" accumulatable="true" spatialResolutionUnits="deg." longitudeResolution="0.25" dataProductStartTimeOffset="-5400" dataProductEndTimeOffset="-5401" west="-180.0" sdsName="precipitation" dataProductBeginDateTime="1997-12-31T00:00:00Z">
    </var>
</varList>
XML
my $dataFieldInfoFile = "$dir/data_field_info.xml";
open( FILE, '>', $dataFieldInfoFile );
print FILE $dataFieldInfoXML;
close(FILE);

my $csvFile = Giovanni::Serializer::TimeSeries::serialize(
    input   => $inputFile,
    outDir  => $dir,
    ncFile  => $inNcFile,
    catalog => $dataFieldInfoFile,

);

ok( -f $csvFile, "Created serialization" );

# read out the csv
open( FILE, "<", $csvFile );
my @lines = <FILE>;
close(FILE);
my $csvOut = join('',@lines);

my $csvCorrect = <<'CSV';
Title:,Time Series, Area-Averaged of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily ()
User Start Date:,2003-01-01T00:00:00Z
User End Date:,2003-01-03T23:59:59Z
Bounding Box:,"-180,-50,180,50"
URL to Reproduce Results:,"http://some.url.com/giovanni/#service=ArAvTs&starttime=2003-01-01T00:00:00Z&endtime=2003-01-03T23:59:59Z&bbox=-180,-50,180,50&data=TRMM_3B42_daily_precipitation_V7&portal=GIOVANNI&format=json"
Fill Value (mean_TRMM_3B42_daily_precipitation_V7): -9999.9,Fill Value (stddev_TRMM_3B42_daily_precipitation_V7): -9999.9,Fill Value (min_TRMM_3B42_daily_precipitation_V7): -9999.9,Fill Value (max_TRMM_3B42_daily_precipitation_V7): -9999.9,Fill Value (count_TRMM_3B42_daily_precipitation_V7): -999

time, mean_TRMM_3B42_daily_precipitation_V7, stddev_TRMM_3B42_daily_precipitation_V7, min_TRMM_3B42_daily_precipitation_V7, max_TRMM_3B42_daily_precipitation_V7, count_TRMM_3B42_daily_precipitation_V7
2002-12-31,3.18305898,10.8299704,0,265.440002,576000
2003-01-01,2.80873108,9.47843647,0,277.094696,576000
2003-01-02,3.07061601,10.2266197,0,313.5,576000
CSV

is( $csvOut, $csvCorrect, "Got the correct csv" );

__DATA__
netcdf g4.areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N {
dimensions:
    bnds = 2 ;
    time = UNLIMITED ; // (3 currently)
variables:
    int time_bnds(time, bnds) ;
    float TRMM_3B42_daily_precipitation_V7(time) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V7:cell_methods = "lat,lon: mean" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "time" ;
    int count_TRMM_3B42_daily_precipitation_V7(time) ;
        count_TRMM_3B42_daily_precipitation_V7:_FillValue = -999 ;
        count_TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        count_TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        count_TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        count_TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        count_TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        count_TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        count_TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        count_TRMM_3B42_daily_precipitation_V7:quantity_type = "count of Precipitation" ;
        count_TRMM_3B42_daily_precipitation_V7:long_name = "count of Precipitation Rate" ;
        count_TRMM_3B42_daily_precipitation_V7:coordinates = "time" ;
    float max_TRMM_3B42_daily_precipitation_V7(time) ;
        max_TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        max_TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        max_TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        max_TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        max_TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        max_TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        max_TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        max_TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        max_TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        max_TRMM_3B42_daily_precipitation_V7:cell_methods = "lat,lon: maximum" ;
        max_TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        max_TRMM_3B42_daily_precipitation_V7:coordinates = "time" ;
    float min_TRMM_3B42_daily_precipitation_V7(time) ;
        min_TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        min_TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        min_TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        min_TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        min_TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        min_TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        min_TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        min_TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        min_TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        min_TRMM_3B42_daily_precipitation_V7:cell_methods = "lat,lon: minimum" ;
        min_TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        min_TRMM_3B42_daily_precipitation_V7:coordinates = "time" ;
    float stddev_TRMM_3B42_daily_precipitation_V7(time) ;
        stddev_TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        stddev_TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        stddev_TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        stddev_TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        stddev_TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        stddev_TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        stddev_TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        stddev_TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        stddev_TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        stddev_TRMM_3B42_daily_precipitation_V7:cell_methods = "lat,lon: standard deviation" ;
        stddev_TRMM_3B42_daily_precipitation_V7:quantity_type = "standard deviation of Precipitation " ;
        stddev_TRMM_3B42_daily_precipitation_V7:coordinates = "time" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:bounds = "time_bnds" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :temporal_resolution = "daily" ;
        :NCO = "\"4.5.3\"" ;
        :nco_input_file_number = 3 ;
        :nco_input_file_list = "areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N.nc.0 areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N.nc.1 areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N.nc.2" ;
        :start_time = "2002-12-31T22:30:00Z" ;
        :end_time = "2003-01-03T22:29:59Z" ;
        :userstartdate = "2003-01-01T00:00:00Z" ;
        :userenddate = "2003-01-03T23:59:59Z" ;
        :title = "Time Series, Area-Averaged of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day over 2002-12-31 22:30Z - 2003-01-03 22:29Z, Region 180W, 50S, 180E, 50N " ;
        :plot_hint_title = "Time Series, Area-Averaged of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily" ;
        :plot_hint_subtitle = "v7] mm/day over 2002-12-31 22:30Z - 2003-01-03 22:29Z, Region 180W, 50S, 180E, 50N" ;
        :plot_hint_y_axis_label = "mm/day" ;
        :plot_hint_time_axis_values = "1041379200,1041422400,1041465600,1041508800,1041552000,1041595200,1041638400" ;
        :plot_hint_time_axis_labels = "00Z~C~1 Jan~C~2003,12Z,00Z~C~2 Jan~C~2003,12Z,00Z~C~3 Jan~C~2003,12Z,00Z~C~4 Jan~C~2003" ;
        :plot_hint_time_axis_minor = "1041400800,1041444000,1041487200,1041530400,1041573600,1041616800" ;
        :history = "Fri Feb 12 18:10:30 2016: ncatted -a bounds,time,o,c,time_bnds /var/giovanni/session/479DD722-D1B3-11E5-82CF-883FB6197530/E3AF9A42-D1B3-11E5-9FDD-9D80F9C7F971/E3AFDBBA-D1B3-11E5-AC3F-8AACCED02655/g4.areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N.nc.tmp\n",
            "Fri Feb 12 18:10:30 2016: ncatted -a plot_hint_time_axis_values,global,c,c,1041379200,1041422400,1041465600,1041508800,1041552000,1041595200,1041638400 -a plot_hint_time_axis_labels,global,c,c,00Z~C~1 Jan~C~2003,12Z,00Z~C~2 Jan~C~2003,12Z,00Z~C~3 Jan~C~2003,12Z,00Z~C~4 Jan~C~2003 -a plot_hint_time_axis_minor,global,c,c,1041400800,1041444000,1041487200,1041530400,1041573600,1041616800 /var/giovanni/session/479DD722-D1B3-11E5-82CF-883FB6197530/E3AF9A42-D1B3-11E5-9FDD-9D80F9C7F971/E3AFDBBA-D1B3-11E5-AC3F-8AACCED02655/g4.areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N.nc\n",
            "Fri Feb 12 18:10:30 2016: ncatted -a plot_hint_y_axis_label,global,o,c,mm/day /var/giovanni/session/479DD722-D1B3-11E5-82CF-883FB6197530/E3AF9A42-D1B3-11E5-9FDD-9D80F9C7F971/E3AFDBBA-D1B3-11E5-AC3F-8AACCED02655/g4.areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N.nc\n",
            "Fri Feb 12 18:10:29 2016: ncks -C -x -v lat,lon -O -o areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N.nc areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N.nc\n",
            "Fri Feb 12 18:10:28 2016: ncrcat -O -o areaAvgTimeSeries.TRMM_3B42_daily_precipitation_V7.20030101-20030103.180W_50S_180E_50N.nc" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-03. Title reflects the date range of the granules that went into making this result." ;
data:

 time_bnds =
  1041373800, 1041460200,
  1041460200, 1041546600,
  1041546600, 1041633000 ;

 TRMM_3B42_daily_precipitation_V7 = 3.183059, 2.808731, 3.070616 ;

 count_TRMM_3B42_daily_precipitation_V7 = 576000, 576000, 576000 ;

 max_TRMM_3B42_daily_precipitation_V7 = 265.44, 277.0947, 313.5 ;

 min_TRMM_3B42_daily_precipitation_V7 = 0, 0, 0 ;

 stddev_TRMM_3B42_daily_precipitation_V7 = 10.82997, 9.478436, 10.22662 ;

 time = 1041373800, 1041460200, 1041546600 ;
}
