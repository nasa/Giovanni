use strict;
use Test::More tests => 3;
use Giovanni::Testing;
use Giovanni::Data::NcFile;
use File::Temp;

# This tests to see if getUnitsArg.pl can handle units with white space.
my $dir = $ENV{SAVEDIR} || File::Temp::tempdir( CLEANUP => 1 );

# Find path for $program
my $program = 'getUnitsArg.pl';
my ($script_path) = Giovanni::Testing::find_script_paths($program);
ok( ( -e $script_path ), "Find script path for $program" );

# Write the manifest with destination units
my $data_info = <<'STR';
<manifest><data zValue="NA" units="kg m-2 s-1">M2T1NXFLX_5_12_4_PRECTOTCORR</data></manifest>
STR

my $data_info_file = "$dir/manifest.xml";
open( FILE, ">", $data_info_file )
    or die "Unable to write $data_info_file";
print FILE $data_info;
close(FILE);

# Write the units configuration file
my $units_cfg = <<'STR';
<units>
    <linearConversions>
        <linearUnit add_offset="0" destination="mm/day"
            scale_factor="24" source="mm/hr"/>
        <linearUnit add_offset="0" destination="inch/hr"
            scale_factor="1.0/25.4" source="mm/hr"/>
        <linearUnit add_offset="0" destination="inch/day"
            scale_factor="24.0/25.4" source="mm/hr"/>
        <linearUnit add_offset="0" destination="mm/hr"
            scale_factor="1.0/24.0" source="mm/day"/>
        <linearUnit add_offset="0" destination="inch/day"
            scale_factor="1.0/25.4" source="mm/day"/>
        <linearUnit add_offset="0" destination="mm" scale_factor="1" source="kg/m^2"/>
        <linearUnit add_offset="-273.15" destination="C"
            scale_factor="1" source="K"/>
        <linearUnit add_offset="0" destination="mm/s" scale_factor="1" source="kg/m^2/s"/>
        <linearUnit add_offset="0" destination="mm/hr"
            scale_factor="3600" source="kg/m^2/s"/>
        <linearUnit add_offset="0" destination="DU"
            scale_factor="1.0/2.6868755e+16" source="molecules/cm^2"/>
        <linearUnit add_offset="0" destination="mm/month"
            scale_factor="1.0" source="kg/m^2"/>
        <linearUnit add_offset="0" destination="mm/day"
            scale_factor="86400" source="kg/m^2/s"/>
        <linearUnit add_offset="0" destination="mm/s" scale_factor="1" source="kg m-2 s-1"/>
        <linearUnit add_offset="0" destination="mm/hr"
            scale_factor="3600" source="kg m-2 s-1"/>
        <linearUnit add_offset="0" destination="mm/day"
            scale_factor="86400" source="kg m-2 s-1"/>
        <linearUnit add_offset="0" destination="mm/hr"
            scale_factor="1.0/3600.0" source="kg/m^2/s"/>
        <linearUnit add_offset="0" destination="kg m-2 s-1"
            scale_factor="1.0" source="kg/m^2/s"/>
        <linearUnit add_offset="0" destination="kg/m^2/s"
            scale_factor="1.0" source="kg m-2 s-1"/>                      
    </linearConversions>
    <nonLinearConversions>
        <timeDependentUnit
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            destination="mm/month" source="mm/hr"
            temporal_resolutions="monthly" to_days_scale_factor="24.0"/>
        <timeDependentUnit
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            destination="inch/month" source="mm/hr"
            temporal_resolutions="monthly" to_days_scale_factor="24.0/25.4"/>
        <timeDependentUnit
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            destination="mm/month" source="kg/m^2/s"
            temporal_resolutions="monthly" to_days_scale_factor="86400"/>
        <timeDependentUnit
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            destination="mm/month" source="mm/day"
            temporal_resolutions="monthly" to_days_scale_factor="1"/>
        <timeDependentUnit
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            destination="inch/month" source="mm/day"
            temporal_resolutions="monthly" to_days_scale_factor="1/25.4"/>
        <timeDependentUnit
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            destination="mm/month" source="kg m-2 s-1"
            temporal_resolutions="monthly" to_days_scale_factor="86400"/>
    </nonLinearConversions>
    <fileFriendlyStrings>
        <destinationUnit file="mmPday" original="mm/day"/>
        <destinationUnit file="inPhr" original="inch/hr"/>
        <destinationUnit file="inPday" original="inch/day"/>
        <destinationUnit file="mmPhr" original="mm/hr"/>
        <destinationUnit file="mm" original="mm"/>
        <destinationUnit file="mmPs" original="mm/s"/>
        <destinationUnit file="DU" original="DU"/>
        <destinationUnit file="mmPmon" original="mm/month"/>
        <destinationUnit file="inPmon" original="inch/month"/>
        <destinationUnit file="C" original="C"/>
        <destinationUnit file="kgSm-2Ss-1" original="kg m-2 s-1" />
        <destinationUnit file="kgPmmPs" original="kg/m^2/s" />
    </fileFriendlyStrings>
</units>
STR

my $units_cfg_file = "$dir/units.xml";
open( FILE, ">", $units_cfg_file ) or die "Unable to write $units_cfg_file";
print FILE $units_cfg;
close(FILE);

# write the data
my $cdls      = Giovanni::Data::NcFile::read_cdl_data_block();
my $data_file = "$dir/data.nc";
Giovanni::Data::NcFile::write_netcdf_file( $data_file, $cdls->[0] );

# write the result manifest file
my $result_manifest_str = << "MANIFEST";
<manifest>
 <fileList id="M2T1NXFLX_5_12_4_PRECTOTCORR">
  <file>
   $data_file
  </file>
 </fileList>
</manifest>
MANIFEST

my $result_manifest_file = "$dir/mfst.result.xml";
open( FILE, ">", $result_manifest_file )
    or die "Unable to write $result_manifest_file";
print FILE $result_manifest_str;
close(FILE);

my $cmd = "$script_path $data_info_file POST,POST,WRAPPER "
    . "$units_cfg_file $result_manifest_file";

my @out = `$cmd`;

is( $?, 0, "Command returned zero." );

my $expected = "--units \"kg m-2 s-1,$units_cfg_file\"";
is_deeply( \@out, [$expected], "Got the units option" );

__DATA__
netcdf subset {
dimensions:
    lat = 21 ;
    lon = 17 ;
variables:
    float M2T1NXFLX_5_12_4_PRECTOTCORR(lat, lon) ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:_FillValue = 1.e+15f ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:fmissing_value = 1.e+15f ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:fullnamepath = "/PRECTOTCORR" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:long_name = "Bias corrected total surface precipitation, time average" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:missing_value = 1.e+15f ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:origname = "PRECTOTCORR" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:standard_name = "total_precipitation" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:units = "kg/m^2/s" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:vmax = 1.e+15f ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:vmin = -1.e+15f ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:cell_methods = "record: mean time: mean" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:quantity_type = "Precipitation" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:product_short_name = "M2T1NXFLX" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:product_version = "5.12.4" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:coordinates = "lat lon" ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:latitude_resolution = 0.5 ;
        M2T1NXFLX_5_12_4_PRECTOTCORR:longitude_resolution = 0.625 ;
    double lat(lat) ;
        lat:CLASS = "DIMENSION_SCALE" ;
        lat:NAME = "lat" ;
        lat:units = "degrees_north" ;
        lat:vmax = 1.e+15f ;
        lat:vmin = -1.e+15f ;
        lat:origname = "lat" ;
        lat:fullnamepath = "/lat" ;
        lat:standard_name = "latitude" ;
    double lon(lon) ;
        lon:CLASS = "DIMENSION_SCALE" ;
        lon:NAME = "lon" ;
        lon:units = "degrees_east" ;
        lon:vmax = 1.e+15f ;
        lon:vmin = -1.e+15f ;
        lon:origname = "lon" ;
        lon:fullnamepath = "/lon" ;
        lon:standard_name = "longitude" ;

// global attributes:
        :NCO = "\"4.5.3\"" ;
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-01T00:00:00Z" ;
        :end_time = "2003-01-01T02:59:59Z" ;
        :history = "Thu Aug 25 14:07:30 2016: ncks -d lat,-5.0,5.0 -d lon,-5.0,5.0 timeAvgMap.M2T1NXFLX_5_12_4_PRECTOTCORR.20030101-20030101.180W_90S_180E_90N.nc out.nc\n",
            "Tue Aug 23 18:22:34 2016: ncatted -a valid_range,,d,, -O -o timeAvgMap.M2T1NXFLX_5_12_4_PRECTOTCORR.20030101-20030101.180W_90S_180E_90N.nc timeAvgMap.M2T1NXFLX_5_12_4_PRECTOTCORR.20030101-20030101.180W_90S_180E_90N.nc\n",
            "Tue Aug 23 18:22:33 2016: ncatted -O -a title,global,o,c,M2T1NXFLX_5_12_4_PRECTOTCORR Averaged over 2003-01-01 to 2003-01-01 timeAvgMap.M2T1NXFLX_5_12_4_PRECTOTCORR.20030101-20030101.180W_90S_180E_90N.nc\n",
            "Tue Aug 23 18:22:33 2016: ncks -x -v time -o timeAvgMap.M2T1NXFLX_5_12_4_PRECTOTCORR.20030101-20030101.180W_90S_180E_90N.nc -O timeAvgMap.M2T1NXFLX_5_12_4_PRECTOTCORR.20030101-20030101.180W_90S_180E_90N.nc\n",
            "Tue Aug 23 18:22:33 2016: ncwa -o timeAvgMap.M2T1NXFLX_5_12_4_PRECTOTCORR.20030101-20030101.180W_90S_180E_90N.nc -a time -O timeAvgMap.M2T1NXFLX_5_12_4_PRECTOTCORR.20030101-20030101.180W_90S_180E_90N.nc\n",
            "Tue Aug 23 18:22:33 2016: ncra -D 2 -H -O -o timeAvgMap.M2T1NXFLX_5_12_4_PRECTOTCORR.20030101-20030101.180W_90S_180E_90N.nc -d lat,-90.000000,90.000000 -d lon,-180.000000,180.000000" ;
        :title = "M2T1NXFLX_5_12_4_PRECTOTCORR Averaged over 2003-01-01 to 2003-01-01" ;
        :userstartdate = "2003-01-01T00:00:00Z" ;
        :userenddate = "2003-01-01T02:59:59Z" ;
data:

 M2T1NXFLX_5_12_4_PRECTOTCORR =
  4.93698e-08, 2.073163e-08, 0, 0, 0, 0, 0, 1.525283e-08, 1.968389e-07, 
    2.338978e-07, 4.361694e-07, 2.579376e-07, 2.593151e-07, 1.009321e-07, 
    9.070694e-08, 8.655479e-08, 3.838601e-07,
  3.718985e-08, 8.359772e-09, 0, 0, 0, 0, 0, 4.019724e-08, 1.894465e-07, 
    3.254584e-07, 2.826564e-07, 3.49634e-07, 3.359358e-07, 2.49478e-07, 
    2.383216e-07, 2.562301e-07, 6.97483e-07,
  7.647517e-08, 4.276565e-08, 0, 0, 0, 0, 0, 4.705604e-08, 1.536682e-07, 
    2.743909e-07, 2.03688e-07, 3.511086e-07, 3.854511e-07, 3.953076e-07, 
    4.075312e-07, 4.353545e-07, 9.31245e-07,
  2.628852e-07, 1.497586e-07, 0, 0, 0, 0, 0, 2.92639e-08, 1.310254e-07, 
    1.620113e-07, 1.967419e-07, 1.903197e-07, 3.261957e-07, 6.194071e-07, 
    8.443215e-07, 7.88287e-07, 1.460159e-06,
  5.61083e-07, 3.660098e-07, 6.906824e-08, 3.87469e-08, 1.816746e-08, 
    2.915234e-09, 1.989974e-09, 3.890697e-08, 1.381462e-07, 2.121087e-07, 
    1.515145e-07, 4.48587e-07, 7.022948e-07, 9.670233e-07, 1.239125e-06, 
    1.471334e-06, 2.831531e-06,
  2.070951e-06, 2.06319e-06, 1.295858e-06, 8.339218e-07, 4.675627e-07, 
    9.57322e-08, 9.379195e-08, 1.160952e-07, 1.910958e-07, 2.809102e-07, 
    3.608099e-07, 6.32368e-07, 1.556861e-06, 3.501773e-06, 5.098681e-06, 
    5.812074e-06, 6.61177e-06,
  3.580935e-06, 5.081917e-06, 4.262353e-06, 2.900449e-06, 1.30649e-06, 
    3.168437e-07, 2.656986e-07, 2.301337e-07, 2.997695e-07, 5.243346e-07, 
    6.109088e-07, 9.783544e-07, 3.749505e-06, 7.440647e-06, 9.987503e-06, 
    1.033023e-05, 9.761502e-06,
  3.713183e-06, 5.365039e-06, 5.060186e-06, 3.996305e-06, 2.0947e-06, 
    5.997717e-07, 4.998874e-07, 5.134692e-07, 7.336494e-07, 1.181616e-06, 
    1.601099e-06, 2.115034e-06, 5.499149e-06, 9.231269e-06, 1.10666e-05, 
    1.101196e-05, 1.020978e-05,
  4.374422e-06, 5.990267e-06, 5.73943e-06, 4.646058e-06, 2.445032e-06, 
    8.488229e-07, 7.913138e-07, 9.766469e-07, 1.464505e-06, 2.172465e-06, 
    2.524505e-06, 2.918144e-06, 6.097058e-06, 9.489556e-06, 1.06059e-05, 
    1.001606e-05, 8.855015e-06,
  5.890926e-06, 7.71073e-06, 7.320195e-06, 5.993371e-06, 3.215857e-06, 
    1.618794e-06, 1.629194e-06, 2.166256e-06, 3.157804e-06, 4.388392e-06, 
    4.426266e-06, 4.881372e-06, 8.077051e-06, 1.01688e-05, 1.008684e-05, 
    8.620322e-06, 6.384527e-06,
  7.530054e-06, 9.536743e-06, 9.105851e-06, 7.639329e-06, 4.738569e-06, 
    2.854193e-06, 3.172706e-06, 3.975505e-06, 6.153559e-06, 8.667509e-06, 
    8.625289e-06, 9.431194e-06, 1.271938e-05, 1.355261e-05, 1.198053e-05, 
    1.009554e-05, 5.586073e-06,
  1.007815e-05, 1.221523e-05, 1.124541e-05, 8.51353e-06, 5.693485e-06, 
    3.670963e-06, 4.050322e-06, 4.752539e-06, 8.05594e-06, 1.215935e-05, 
    1.222889e-05, 1.388664e-05, 1.823654e-05, 1.946837e-05, 1.846999e-05, 
    1.523768e-05, 7.00665e-06,
  1.188616e-05, 1.399592e-05, 1.217549e-05, 7.655472e-06, 4.803451e-06, 
    3.212442e-06, 3.239761e-06, 3.581246e-06, 6.748363e-06, 1.170238e-05, 
    1.156951e-05, 1.449635e-05, 2.02929e-05, 2.281616e-05, 2.263983e-05, 
    1.745174e-05, 7.610147e-06,
  8.601074e-06, 1.008436e-05, 8.630876e-06, 4.932595e-06, 2.641231e-06, 
    1.77091e-06, 1.688022e-06, 1.815924e-06, 3.698592e-06, 7.88644e-06, 
    7.446855e-06, 1.061335e-05, 1.541773e-05, 1.75635e-05, 1.587346e-05, 
    1.171107e-05, 5.874162e-06,
  2.534439e-06, 3.054117e-06, 3.241003e-06, 2.33762e-06, 1.118441e-06, 
    1.747627e-06, 1.200087e-06, 1.431598e-06, 1.511847e-06, 3.948187e-06, 
    3.242555e-06, 5.565584e-06, 7.206574e-06, 7.025277e-06, 5.906448e-06, 
    4.480282e-06, 3.431924e-06,
  2.119225e-06, 2.989856e-06, 4.342447e-06, 3.484388e-06, 2.827806e-06, 
    7.099161e-06, 4.067396e-06, 4.219823e-06, 1.206839e-06, 5.355105e-06, 
    1.371528e-06, 6.335477e-06, 4.906828e-06, 3.861884e-06, 3.307437e-06, 
    2.057136e-06, 1.4926e-06,
  1.242928e-06, 3.007241e-06, 5.720804e-06, 7.68217e-06, 7.010996e-06, 
    5.121032e-06, 1.074048e-06, 2.256905e-06, 2.372855e-06, 3.781752e-07, 
    1.912316e-07, 1.997299e-07, 2.968979e-07, 4.421454e-07, 2.427259e-07, 
    3.592771e-07, 5.92001e-07,
  7.237929e-07, 1.513942e-06, 2.064121e-06, 2.061017e-06, 1.169508e-06, 
    5.859183e-07, 1.065588e-07, 2.107408e-07, 1.954807e-07, 2.663243e-08, 
    1.097457e-08, 8.634136e-09, 8.264275e-09, 4.921579e-09, 1.804011e-09, 
    2.001965e-08, 2.047379e-08,
  1.780572e-07, 4.010508e-07, 4.968218e-07, 3.912137e-07, 1.275621e-07, 
    6.079593e-10, 1.477076e-10, 3.412974e-11, 1.752198e-11, 6.449952e-12, 
    3.233858e-12, 1.122954e-12, 8.921012e-13, 8.689345e-13, 1.143826e-10, 
    8.706138e-10, 4.514268e-10,
  8.839076e-09, 4.359754e-08, 6.748208e-08, 5.320423e-08, 2.363716e-08, 
    2.122533e-10, 4.948693e-11, 1.224739e-11, 6.037541e-12, 1.91136e-12, 
    7.161678e-13, 1.308213e-13, 1.230775e-13, 1.854628e-13, 1.65266e-13, 
    5.268008e-13, 3.829529e-13,
  3.739231e-12, 6.496137e-12, 8.999616e-12, 1.439915e-11, 2.034284e-11, 
    1.687894e-11, 6.359949e-12, 2.670012e-12, 1.411019e-12, 4.857642e-13, 
    7.062869e-14, 0, 2.919251e-15, 1.792663e-14, 1.975619e-14, 1.872391e-13, 
    1.430522e-13 ;

 lat = -5, -4.5, -4, -3.5, -3, -2.5, -2, -1.5, -1, -0.5, 
    -1.7975103014118e-13, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5 ;

 lon = -5, -4.375, -3.75, -3.125, -2.5, -1.875, -1.25, -0.625, 
    -5.92030439429403e-13, 0.625, 1.25, 1.875, 2.5, 3.125, 3.75, 4.375, 5 ;
}
