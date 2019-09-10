# Use modules
use strict;
use Test::More tests => 4;
use Giovanni::Testing;
use Giovanni::Algorithm::Wrapper;
BEGIN { use_ok('Giovanni::Algorithm::Wrapper::Test'); }

# Find path for $program
my $program = 'g4_area_avg_diff_time_series.pl';
my ($script_path) = Giovanni::Testing::find_script_paths($program);
ok( ( -e $script_path ), "Find script path for $program" )
    or die "No point going further";

# The actual call to run the test
# Note that diff-exclude is used to exclude potentially spurious differences
# In real life, we will want to take the out of the diff-exclude, once we settle
# on title formats and contents
my ( $out_nc, $diff_rc ) = run_test(
    'program'      => $script_path,
    'comparison'   => "minus",
    'name'         => 'Area Averaged Difference Time Series',
    'units'        => 'mm/day,mm/day',
    'time-axis'    => 1,
    'temp_res'    => 'monthly',
    'diff-exclude' => [
        qw(/title /plot_title /plot_subtitle /long_name /temporal_resolution)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" )
    or die "No point diffing files";
is( $diff_rc, '', "Outcome of diff" );
exit(0);
__DATA__
netcdf ss.regrid.TRMM_3B43_007_precipitation.20140501000000 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 2 ;
    lon = 4 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:missing_value = -9999.9f ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:units = "degrees_north" ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:standard_name = "time" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :calendar = "standard" ;
        :model = "geos/das" ;
        :center = "gsfc" ;
        :history = "Mon Mar 16 21:31:06 2015: ncks -d lat,37.793,39.1992 -d lon,-97.5586,-95.625 regrid.TRMM_3B43_007_precipitation.20140501000000.nc ss.regrid.TRMM_3B43_007_precipitation.20140501000000.nc\n",
            "Mon Mar 16 21:18:33 2015: ncks -A -v time /var/tmp/www/TS1/giovanni/794F2714-CC21-11E4-AEC8-674CBC8D8F68/F8117E58-CC21-11E4-86B0-B3E0BB8D8F68/F81319B6-CC21-11E4-86B0-B3E0BB8D8F68//subsetted.TRMM_3B43_007_precipitation.20140501000000.nc /var/tmp/www/TS1/giovanni/794F2714-CC21-11E4-AEC8-674CBC8D8F68/F8117E58-CC21-11E4-86B0-B3E0BB8D8F68/F81319B6-CC21-11E4-86B0-B3E0BB8D8F68/regrid.TRMM_3B43_007_precipitation.20140501000000.nc\n",
            "Mon Mar 16 21:18:33 2015: ncrename -O -v z,TRMM_3B43_007_precipitation /var/tmp/www/TS1/giovanni/794F2714-CC21-11E4-AEC8-674CBC8D8F68/F8117E58-CC21-11E4-86B0-B3E0BB8D8F68/F81319B6-CC21-11E4-86B0-B3E0BB8D8F68/regrid.TRMM_3B43_007_precipitation.20140501000000.nc /var/tmp/www/TS1/giovanni/794F2714-CC21-11E4-AEC8-674CBC8D8F68/F8117E58-CC21-11E4-86B0-B3E0BB8D8F68/F81319B6-CC21-11E4-86B0-B3E0BB8D8F68/regrid.TRMM_3B43_007_precipitation.20140501000000.nc.rename" ;
        :start_time = "2014-05-01T00:00:00Z" ;
        :end_time = "2014-05-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :nco_openmp_thread_number = 1 ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.1389903, 0.1244354, 0.1264184, 0.117425,
  0.1468763, 0.1164602, 0.1080665, 0.1097916 ;

 datamonth = 201405 ;

 lat = 38.25, 38.75 ;

 lon = -97.25, -96.75, -96.25, -95.75 ;

 time = 1398902400 ;
}
netcdf ss.regrid.TRMM_3B43_007_precipitation.20140601000000 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 2 ;
    lon = 4 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:missing_value = -9999.9f ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:coordinates = "time lat lon" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:units = "degrees_north" ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:standard_name = "time" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :calendar = "standard" ;
        :model = "geos/das" ;
        :center = "gsfc" ;
        :history = "Mon Mar 16 21:31:06 2015: ncks -d lat,37.793,39.1992 -d lon,-97.5586,-95.625 regrid.TRMM_3B43_007_precipitation.20140601000000.nc ss.regrid.TRMM_3B43_007_precipitation.20140601000000.nc\n",
            "Mon Mar 16 21:18:33 2015: ncks -A -v time /var/tmp/www/TS1/giovanni/794F2714-CC21-11E4-AEC8-674CBC8D8F68/F8117E58-CC21-11E4-86B0-B3E0BB8D8F68/F81319B6-CC21-11E4-86B0-B3E0BB8D8F68//subsetted.TRMM_3B43_007_precipitation.20140601000000.nc /var/tmp/www/TS1/giovanni/794F2714-CC21-11E4-AEC8-674CBC8D8F68/F8117E58-CC21-11E4-86B0-B3E0BB8D8F68/F81319B6-CC21-11E4-86B0-B3E0BB8D8F68/regrid.TRMM_3B43_007_precipitation.20140601000000.nc\n",
            "Mon Mar 16 21:18:33 2015: ncrename -O -v z,TRMM_3B43_007_precipitation /var/tmp/www/TS1/giovanni/794F2714-CC21-11E4-AEC8-674CBC8D8F68/F8117E58-CC21-11E4-86B0-B3E0BB8D8F68/F81319B6-CC21-11E4-86B0-B3E0BB8D8F68/regrid.TRMM_3B43_007_precipitation.20140601000000.nc /var/tmp/www/TS1/giovanni/794F2714-CC21-11E4-AEC8-674CBC8D8F68/F8117E58-CC21-11E4-86B0-B3E0BB8D8F68/F81319B6-CC21-11E4-86B0-B3E0BB8D8F68/regrid.TRMM_3B43_007_precipitation.20140601000000.nc.rename" ;
        :start_time = "2014-06-01T00:00:00Z" ;
        :end_time = "2014-06-30T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :nco_openmp_thread_number = 1 ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.3486162, 0.2925101, 0.2598479, 0.2587324,
  0.2989419, 0.2634667, 0.2599379, 0.272741 ;

 datamonth = 201406 ;

 lat = 38.25, 38.75 ;

 lon = -97.25, -96.75, -96.25, -95.75 ;

 time = 1401580800 ;
}
netcdf ss.scrubbed.TRMM_3A12_007_surfacePrecipitation.20140501000000 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 2 ;
    lon = 4 ;
variables:
    float TRMM_3A12_007_surfacePrecipitation(time, lat, lon) ;
        TRMM_3A12_007_surfacePrecipitation:_FillValue = -9999.9f ;
        TRMM_3A12_007_surfacePrecipitation:coordinates = "time lat lon" ;
        TRMM_3A12_007_surfacePrecipitation:long_name = "Precipitation Rate" ;
        TRMM_3A12_007_surfacePrecipitation:product_short_name = "TRMM_3A12" ;
        TRMM_3A12_007_surfacePrecipitation:product_version = "7" ;
        TRMM_3A12_007_surfacePrecipitation:quantity_type = "Precipitation" ;
        TRMM_3A12_007_surfacePrecipitation:standard_name = "surfaceprecipitation" ;
        TRMM_3A12_007_surfacePrecipitation:units = "mm/hr" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:units = "degrees_east" ;
        lon:standard_name = "longitude" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2014-05-01T00:00:00Z" ;
        :end_time = "2014-05-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :nco_openmp_thread_number = 1 ;
        :history = "Mon Mar 16 21:29:14 2015: ncks -d lat,37.793,39.1992 -d lon,-97.5586,-95.625 scrubbed.TRMM_3A12_007_surfacePrecipitation.20140501000000.nc ss.scrubbed.TRMM_3A12_007_surfacePrecipitation.20140501000000.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3A12_007_surfacePrecipitation =
  0.09132101, 0.01078044, 0.07538927, 0.2046115,
  0.4476324, 0.06808757, 0.05292237, 0.1079066 ;

 datamonth = 201405 ;

 lat = 38.25, 38.75 ;

 lon = -97.25, -96.75, -96.25, -95.75 ;

 time = 1398902400 ;
}
netcdf ss.scrubbed.TRMM_3A12_007_surfacePrecipitation.20140601000000 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 2 ;
    lon = 4 ;
variables:
    float TRMM_3A12_007_surfacePrecipitation(time, lat, lon) ;
        TRMM_3A12_007_surfacePrecipitation:_FillValue = -9999.9f ;
        TRMM_3A12_007_surfacePrecipitation:coordinates = "time lat lon" ;
        TRMM_3A12_007_surfacePrecipitation:long_name = "Precipitation Rate" ;
        TRMM_3A12_007_surfacePrecipitation:product_short_name = "TRMM_3A12" ;
        TRMM_3A12_007_surfacePrecipitation:product_version = "7" ;
        TRMM_3A12_007_surfacePrecipitation:quantity_type = "Precipitation" ;
        TRMM_3A12_007_surfacePrecipitation:standard_name = "surfaceprecipitation" ;
        TRMM_3A12_007_surfacePrecipitation:units = "mm/hr" ;
    int datamonth(time) ;
        datamonth:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:units = "degrees_east" ;
        lon:standard_name = "longitude" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2014-06-01T00:00:00Z" ;
        :end_time = "2014-06-30T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :nco_openmp_thread_number = 1 ;
        :history = "Mon Mar 16 21:29:48 2015: ncks -d lat,37.793,39.1992 -d lon,-97.5586,-95.625 scrubbed.TRMM_3A12_007_surfacePrecipitation.20140601000000.nc ss.scrubbed.TRMM_3A12_007_surfacePrecipitation.20140601000000.nc" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3A12_007_surfacePrecipitation =
  1.158518, 0.8916645, 0.5567843, 0.4425415,
  1.278165, 1.311995, 0.4712992, 0.3079286 ;

 datamonth = 201406 ;

 lat = 38.25, 38.75 ;

 lon = -97.25, -96.75, -96.25, -95.75 ;

 time = 1401580800 ;
}
netcdf testAlgorithm.TRMM_3B43_007_precipitation+TRMM_3A12_007_surfacePrecipitation.20140501-20140630.97W_38N_95W_39N {
dimensions:
    time = UNLIMITED ; // (2 currently)
variables:
    int count_difference(time) ;
        count_difference:_FillValue = -999 ;
        count_difference:product_short_name = "TRMM_3A12" ;
        count_difference:product_version = "7" ;
        count_difference:quantity_type = "Precipitation" ;
        count_difference:standard_name = "surfaceprecipitation" ;
        count_difference:units = "mm/day" ;
        count_difference:long_name = "count of Precipitation Rate minus Precipitation Rate" ;
        count_difference:coordinates = "time" ;
    float difference(time) ;
        difference:_FillValue = -9999.9f ;
        difference:product_short_name = "TRMM_3A12" ;
        difference:product_version = "7" ;
        difference:quantity_type = "Precipitation" ;
        difference:standard_name = "surfaceprecipitation" ;
        difference:units = "mm/day" ;
        difference:cell_methods = "lat,lon: mean" ;
        difference:long_name = "Precipitation Rate minus Precipitation Rate" ;
        difference:coordinates = "time" ;
    float max_difference(time) ;
        max_difference:_FillValue = -9999.9f ;
        max_difference:long_name = "Precipitation Rate minus Precipitation Rate" ;
        max_difference:product_short_name = "TRMM_3A12" ;
        max_difference:product_version = "7" ;
        max_difference:quantity_type = "Precipitation" ;
        max_difference:standard_name = "surfaceprecipitation" ;
        max_difference:units = "mm/day" ;
        max_difference:cell_methods = "lat,lon: minimum" ;
        max_difference:coordinates = "time" ;
    float min_difference(time) ;
        min_difference:_FillValue = -9999.9f ;
        min_difference:long_name = "Precipitation Rate minus Precipitation Rate" ;
        min_difference:product_short_name = "TRMM_3A12" ;
        min_difference:product_version = "7" ;
        min_difference:quantity_type = "Precipitation" ;
        min_difference:standard_name = "surfaceprecipitation" ;
        min_difference:units = "mm/day" ;
        min_difference:cell_methods = "lat,lon: minimum" ;
        min_difference:coordinates = "time" ;
    float std_difference(time) ;
        std_difference:_FillValue = -9999.9f ;
        std_difference:long_name = "Precipitation Rate minus Precipitation Rate" ;
        std_difference:product_short_name = "TRMM_3A12" ;
        std_difference:product_version = "7" ;
        std_difference:quantity_type = "Precipitation" ;
        std_difference:standard_name = "surfaceprecipitation" ;
        std_difference:units = "mm/day" ;
        std_difference:cell_methods = "lat,lon: standard_deviation" ;
        std_difference:coordinates = "time" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :temporal_resolution = "monthly" ;
        :nco_openmp_thread_number = 1 ;
        :NCO = "\"4.5.3\"" ;
        :nco_input_file_number = 2 ;
        :nco_input_file_list = "/tmp/O_9LrxJciL/testAlgorithm.TRMM_3B43_007_precipitation+TRMM_3A12_007_surfacePrecipitation.20140501-20140630.97W_38N_95W_39N.nc.0 /tmp/O_9LrxJciL/testAlgorithm.TRMM_3B43_007_precipitation+TRMM_3A12_007_surfacePrecipitation.20140501-20140630.97W_38N_95W_39N.nc.1" ;
        :start_time = "2014-05-01T00:00:00Z" ;
        :end_time = "2014-06-30T23:59:59Z" ;
        :userstartdate = "2014-05-01T00:00:00Z" ;
        :userenddate = "2014-06-30T23:59:59Z" ;
data:

 count_difference = 8, 8 ;

 difference = 0.2072251, 12.4883 ;

 max_difference = 7.218146, 25.16468 ;

 min_difference = -2.727719, 0.8445024 ;

 std_difference = 2.944196, 8.784003 ;

 time = 1398902400, 1401580800 ;
}
