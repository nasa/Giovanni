# Use modules
use strict;
use Test::More tests => 4;
use Giovanni::Testing;
use Giovanni::Algorithm::Wrapper;
BEGIN { use_ok('Giovanni::Algorithm::Wrapper::Test'); }

# Find path for $program
my $program = 'g4_ex_time_averager.pl';
my ($script_path) = Giovanni::Testing::find_script_paths($program);
ok( ( -e $script_path ), "Find script path for $program" );

my $parent_dir = $ENV{'SAVEDIR'} || $ENV{'TMPDIR'} || '.';
my $dir = File::Temp::tempdir(
    DIR     => $parent_dir,
    CLEANUP => not exists( $ENV{SAVEDIR} )
);
my $units_cfg = write_config_file($dir);

# The actual call to run the test
# Note that diff-exclude is used to exclude potentially spurious differences
# In real life, we will want to take the out of the diff-exclude, once we settle
# on title formats and contents
my ( $out_nc, $diff_rc ) = run_test(
    'program'      => $script_path,
    'name'         => 'Time Averaged Map',
    'units'        => "mm/month,$units_cfg",
    'bbox'         => '-87.5391,35.5664,-86.9687,36.4336',
    'diff-exclude' => [
        qw( /title /plot_title /plot_subtitle /temporal_resolution /coordinates)
    ]
);
ok( $out_nc, "Algorithm returned file $out_nc" );
is( $diff_rc, "", "Outcome of diff" ) or exit(1);

unlink($out_nc) unless ( exists( $ENV{CLEANUP} ) && ( $ENV{CLEANUP} == 0 ) );
exit(0);

sub write_config_file {
    my $dir     = shift;
    my $outfile = "$dir/units-cfg.xml";
    open OUT, ">$outfile";
    print OUT << 'EOF';
<units>
        <linearConversions>
                <linearUnit source="mm/hr" destination="inch/hr"
                        scale_factor="1.0/25.4" add_offset="0" />
                <linearUnit source="molecules/cm^2" destination="DU"
                        scale_factor="1.0/2.6868755e+16" add_offset="0" />
        </linearConversions>
        <nonLinearConversions>
                <nonLinearUnit source="mm/hr" destination="mm/month"
                        to_days_scale_factor="24.0" function="monthlyRate" />
        </nonLinearConversions>
</units>
EOF
    close(OUT);
    warn "Wrote units cfg $outfile\n";
    return $outfile;
}
__DATA__
netcdf ss.scrubbed.TRMM_3B43_007_precipitation.20090101000000 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 2 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
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
        :start_time = "2009-01-01T00:00:00Z" ;
        :end_time = "2009-01-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.1528704, 0.1583169,
  0.1488519, 0.1491447,
  0.2029244, 0.1786936,
  0.1768123, 0.1636766 ;

 datamonth = 200901 ;

 lat = 35.625, 35.875, 36.125, 36.375 ;

 lon = -87.375, -87.125 ;

 time = 1230768000 ;
}
netcdf ss.scrubbed.TRMM_3B43_007_precipitation.20090201000000 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 2 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
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
        :start_time = "2009-02-01T00:00:00Z" ;
        :end_time = "2009-02-28T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.1569936, 0.1435182,
  0.1446232, 0.1771801,
  0.1264216, 0.1461473,
  0.1193615, 0.1266966 ;

 datamonth = 200902 ;

 lat = 35.625, 35.875, 36.125, 36.375 ;

 lon = -87.375, -87.125 ;

 time = 1233446400 ;
}
netcdf ss.scrubbed.TRMM_3B43_007_precipitation.20090301000000 {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 2 ;
variables:
    float TRMM_3B43_007_precipitation(time, lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
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
        :start_time = "2009-03-01T00:00:00Z" ;
        :end_time = "2009-03-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :NCO = "4.4.4" ;
data:

 TRMM_3B43_007_precipitation =
  0.1671359, 0.1543174,
  0.1519185, 0.1646968,
  0.146679, 0.1537044,
  0.1300158, 0.1261446 ;

 datamonth = 200903 ;

 lat = 35.625, 35.875, 36.125, 36.375 ;

 lon = -87.375, -87.125 ;

 time = 1235865600 ;
}
netcdf inPhr.timeAvgMap.TRMM_3B43_007_precipitation.20090101-20090331.87W_35N_82W_39N {
dimensions:
    lat = 4 ;
    lon = 2 ;
variables:
    float TRMM_3B43_007_precipitation(lat, lon) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:coordinates = "lat lon" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/month" ;
        TRMM_3B43_007_precipitation:cell_methods = "time: mean" ;
    int datamonth ;
        datamonth:long_name = "Standardized Date Label" ;
        datamonth:cell_methods = "time: mean" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2009-01-01T00:00:00Z" ;
        :end_time = "2009-03-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :NCO = "\"4.5.3\"" ;
        :nco_input_file_number = 3 ;
        :nco_input_file_list = "uc.ss.scrubbed.TRMM_3B43_007_precipitation.20090101000000.nc uc.ss.scrubbed.TRMM_3B43_007_precipitation.20090201000000.nc uc.ss.scrubbed.TRMM_3B43_007_precipitation.20090301000000.nc" ;
        :userstartdate = "2009-01-01T00:00:00Z" ;
        :userenddate = "2009-03-31T23:59:59Z" ;
data:

 TRMM_3B43_007_precipitation =
  114.5281, 109.6814,
  106.9867, 117.521,
  115.0201, 115.1717,
  102.8303, 100.2557 ;

 datamonth = 200902 ;

 lat = 35.625, 35.875, 36.125, 36.375 ;

 lon = -87.375, -87.125 ;
}

