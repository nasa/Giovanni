
use Test::More tests => 4;
BEGIN { use_ok('Giovanni::PostProcess') }

use warnings;
use strict;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FindBin;
use Giovanni::Data::NcFile;
use Giovanni::Util;

# Write contents of __DATA__ to disk
my $tmpdir = tempdir( CLEANUP => 1 );
my ( $cdlInput, $cdlOutputCorrect ) = getCdlData();
my $ncInput         = "$tmpdir/ncInput.nc";
my $ncOutputCorrect = "$tmpdir/ncOutputCorrect";

Giovanni::Data::NcFile::write_netcdf_file( $ncInput, $cdlInput )
    or die "Unable to write input file";
Giovanni::Data::NcFile::write_netcdf_file( $ncOutputCorrect,
    $cdlOutputCorrect )
    or die "Unable to write correct output file";

# Run Post-Process Procedure
my $mfstDataFieldInfo = getDataFieldInfo("$tmpdir/mfst.data_field_info.xml");
my $mfstDataFieldSlice
    = getDataFieldSlice("$tmpdir/mfst.data_field_slice.xml");
my $mfstInput   = getMfstInput( "$tmpdir/mfstInput.xml", $ncInput );
my $mfstOutput  = "$tmpdir/mfstOutput.xml";
my $unitsConfig = "$FindBin::Bin/../../cfg/unitsCfg.xml";

my $rc = Giovanni::PostProcess::run(
    'bbox'        => '5.0,5.0,10.0,10.0',
    'endtime'     => '2012-10-29T02:59:59Z',
    'infile'      => $mfstInput,
    'name'        => 'Time Averaged Map',
    'outfile'     => $mfstOutput,
    'session-dir' => $tmpdir,
    'service'     => 'TmAvMp',
    'starttime'   => '2012-10-29T00:00:00Z',
    'units'       => "NA,$unitsConfig",
    'varfiles'    => $mfstDataFieldInfo,
    'variables'   => 'MAI3CPASM_5_2_0_UV',
    'zfiles'      => $mfstDataFieldSlice
);

is( 0, $rc, "Got return code 0 from run()" );

# Compare Results
my $mfstRead = Giovanni::Util::getDataFilesFromManifest($mfstOutput);
is( 1, scalar @{ $mfstRead->{data} }, "Got one output file" );
my $ncOutputGot = $mfstRead->{data}->[0];

my $out = Giovanni::Data::NcFile::diff_netcdf_files( $ncOutputGot,
    $ncOutputCorrect );
is( $out, '', "Same output: $out" );

sub getMfstInput {
    my ( $fname, $ncInput ) = @_;

    open( MFST, ">$fname" );
    print MFST "<?xml version='1.0' encoding='UTF-8'?>\n";
    print MFST "<manifest>\n";
    print MFST "  <fileList>\n";
    print MFST "    <file>" . abs_path($ncInput) . "</file>\n";
    print MFST "  </fileList>\n";
    print MFST "</manifest>\n";
    close(MFST);

    return $fname;
}

sub getDataFieldInfo {
    my ($fname) = @_;

    open( FH, ">$fname" );
    print FH <<EOF;
<varList>
  <var id="MAI3CPASM_5_2_0_UV" zDimUnits="hPa" long_name="Wind Vector" searchIntervalDays="183.0" sampleOpendap="http://goldsmr3.sci.gsfc.nasa.gov/opendap/hyrax/MERRA/MAI3CPASM.5.2.0/1979/01/MERRA100.prod.assim.inst3_3d_asm_Cp.19790101.hdf.html" dataProductTimeFrequency="3" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP_TIMESPLIT" endTime="2038-01-19T03:14:07Z" url="http://dev-ts2.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MERRA%203D%20IAU%20State%2C%20Meteorology%20Instantaneous%203-hourly%20(p-coord%2C%201.25x1.25L42)%20V5.2.0;agent_id=OPeNDAP_TIMESPLIT;variables=U,V" startTime="1979-01-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="3-hourly" dataProductVersion="5.2.0" sampleFile="" east="180.0" vectorComponents="U,V" dataProductShortName="MAI3CPASM" osdd="" resolution="1.25 deg." dataProductPlatformInstrument="MERRA Model" quantity_type="Wind" zDimName="Height" dataFieldStandardName="wind_vector" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="m/s" latitudeResolution="1.25" accessName="U,V" fillValueFieldName="_FillValue" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="0" longitudeResolution="1.25" dataProductEndTimeOffset="0" west="-180.0" zDimValues="1000 975 950 925 900 875 850 825 800 775 750 725 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 40 30 20 10 7 5 4 3 2 1 0.7 0.5 0.4 0.3 0.1" sdsName="" dataProductBeginDateTime="1979-01-01T00:00:00Z">
    <slds>
      <sld url="http://dev-ts2.gesdisc.eosdis.nasa.gov/giovanni/sld/spectral_div_11_inv_sld.xml" label="Spectral, Inverted (Div), 11"/>
    </slds>
  </var>
</varList>
EOF
    close(FH);
    return $fname;
}

sub getDataFieldSlice {
    my ($fname) = @_;

    open( FH, ">$fname" );
    print FH
        '<manifest><data zValue="950" units="NA">MAI3CPASM_5_2_0_UV</data></manifest>';
    close(FH);

    return $fname;
}

sub getCdlData {

    # read block at __DATA__ and write to a CDL file
    #(stolen from Christine who stole from Chris...)
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
netcdf timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N {
dimensions:
    lat = 4 ;
    lon = 4 ;
variables:
    double Height ;
        Height:long_name = "vertical level" ;
        Height:units = "hPa" ;
        Height:positive = "down" ;
        Height:coordinate = "PLE" ;
        Height:standard_name = "PLE_level" ;
        Height:formula_term = "unknown" ;
        Height:fullpath = "Height:EOSGRID" ;
        Height:cell_methods = "Height: mean" ;
    float MAI3CPASM_5_2_0_UV_u(lat, lon) ;
        MAI3CPASM_5_2_0_UV_u:_FillValue = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_u:long_name = "Wind Vector" ;
        MAI3CPASM_5_2_0_UV_u:standard_name = "wind_vector" ;
        MAI3CPASM_5_2_0_UV_u:units = "m/s" ;
        MAI3CPASM_5_2_0_UV_u:missing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_u:fmissing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_u:vmin = -1.e+30f ;
        MAI3CPASM_5_2_0_UV_u:vmax = 1.e+30f ;
        MAI3CPASM_5_2_0_UV_u:coordinates = "lat lon" ;
        MAI3CPASM_5_2_0_UV_u:fullpath = "/EOSGRID/Data Fields/U" ;
        MAI3CPASM_5_2_0_UV_u:cell_methods = "record: mean time: mean Height: mean time: mean" ;
        MAI3CPASM_5_2_0_UV_u:vectorComponents = "u of MAI3CPASM_5_2_0_UV" ;
        MAI3CPASM_5_2_0_UV_u:quantity_type = "Wind" ;
        MAI3CPASM_5_2_0_UV_u:product_short_name = "MAI3CPASM" ;
        MAI3CPASM_5_2_0_UV_u:product_version = "5.2.0" ;
        MAI3CPASM_5_2_0_UV_u:z_slice = "950hPa" ;
        MAI3CPASM_5_2_0_UV_u:z_slice_type = "pressure" ;
        MAI3CPASM_5_2_0_UV_u:latitude_resolution = 1.25 ;
        MAI3CPASM_5_2_0_UV_u:longitude_resolution = 1.25 ;
    float MAI3CPASM_5_2_0_UV_v(lat, lon) ;
        MAI3CPASM_5_2_0_UV_v:_FillValue = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_v:long_name = "Wind Vector" ;
        MAI3CPASM_5_2_0_UV_v:standard_name = "wind_vector" ;
        MAI3CPASM_5_2_0_UV_v:units = "m/s" ;
        MAI3CPASM_5_2_0_UV_v:missing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_v:fmissing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_v:vmin = -1.e+30f ;
        MAI3CPASM_5_2_0_UV_v:vmax = 1.e+30f ;
        MAI3CPASM_5_2_0_UV_v:coordinates = "lat lon" ;
        MAI3CPASM_5_2_0_UV_v:fullpath = "/EOSGRID/Data Fields/V" ;
        MAI3CPASM_5_2_0_UV_v:cell_methods = "record: mean time: mean Height: mean time: mean" ;
        MAI3CPASM_5_2_0_UV_v:vectorComponents = "v of MAI3CPASM_5_2_0_UV" ;
        MAI3CPASM_5_2_0_UV_v:quantity_type = "Wind" ;
        MAI3CPASM_5_2_0_UV_v:product_short_name = "MAI3CPASM" ;
        MAI3CPASM_5_2_0_UV_v:product_version = "5.2.0" ;
        MAI3CPASM_5_2_0_UV_v:z_slice = "950hPa" ;
        MAI3CPASM_5_2_0_UV_v:z_slice_type = "pressure" ;
        MAI3CPASM_5_2_0_UV_v:latitude_resolution = 1.25 ;
        MAI3CPASM_5_2_0_UV_v:longitude_resolution = 1.25 ;
    double lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:units = "degrees_north" ;
        lat:fullpath = "YDim:EOSGRID" ;
        lat:standard_name = "latitude" ;
    double lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:units = "degrees_east" ;
        lon:fullpath = "XDim:EOSGRID" ;
        lon:standard_name = "longitude" ;
    double time ;
        time:begin_date = 20121029 ;
        time:begin_time = 0 ;
        time:fullpath = "TIME:EOSGRID" ;
        time:long_name = "time" ;
        time:standard_name = "time" ;
        time:time_increment = 30000 ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2012-10-29T00:00:00Z" ;
        :end_time = "2012-10-29T02:59:59Z" ;
        :history = "Thu Jul 23 18:38:13 2015: ncatted -a valid_range,,d,, -O -o timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc\n",
            "Thu Jul 23 18:38:13 2015: ncatted -O -a title,global,o,c,MAI3CPASM_5_2_0_UV Averaged over 2012-10-29 to 2012-10-29 timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc\n",
            "Thu Jul 23 18:38:13 2015: ncks -x -v time -o timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc -O timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc\n",
            "Thu Jul 23 18:38:13 2015: ncwa -o timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc -a time -O timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc\n",
            "Thu Jul 23 18:38:13 2015: ncra -D 2 -H -O -o timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc -d lat,5.000000,10.000000 -d lon,5.000000,10.000000 -d Height,950.000000,950.000000" ;
        :NCO = "4.4.4" ;
        :title = "MAI3CPASM_5_2_0_UV Averaged over 2012-10-29 to 2012-10-29" ;
        :userstartdate = "2012-10-29T00:00:00Z" ;
        :userenddate = "2012-10-29T00:59:59Z" ;
data:

 Height = 950 ;

 MAI3CPASM_5_2_0_UV_u =
  4.281162, 3.917881, 3.003818, _,
  4.851474, 3.874912, 2.605381, 1.443271,
  4.421787, 2.492099, 0.8368258, 0.05879547,
  3.230381, 0.295322, _, _ ;

 MAI3CPASM_5_2_0_UV_v =
  2.205571, 2.592289, 2.424321, _,
  1.71143, 2.629399, 2.33643, 1.156743,
  0.2368206, 1.053471, 1.097661, 0.2749066,
  -1.583492, -0.5288044, _, _ ;

 lat = 5.625, 6.875, 8.125, 9.375 ;

 lon = 5.625, 6.875, 8.125, 9.375 ;

 time = 1351468800 ;
}
netcdf g4.ncInput {
dimensions:
    lat = 4 ;
    lon = 4 ;
variables:
    double Height ;
        Height:long_name = "vertical level" ;
        Height:units = "hPa" ;
        Height:positive = "down" ;
        Height:coordinate = "PLE" ;
        Height:standard_name = "PLE_level" ;
        Height:formula_term = "unknown" ;
        Height:fullpath = "Height:EOSGRID" ;
        Height:cell_methods = "Height: mean" ;
    float MAI3CPASM_5_2_0_UV_u(lat, lon) ;
        MAI3CPASM_5_2_0_UV_u:_FillValue = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_u:long_name = "Wind Vector" ;
        MAI3CPASM_5_2_0_UV_u:standard_name = "wind_vector" ;
        MAI3CPASM_5_2_0_UV_u:units = "m/s" ;
        MAI3CPASM_5_2_0_UV_u:missing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_u:fmissing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_u:vmin = -1.e+30f ;
        MAI3CPASM_5_2_0_UV_u:vmax = 1.e+30f ;
        MAI3CPASM_5_2_0_UV_u:coordinates = "lat lon" ;
        MAI3CPASM_5_2_0_UV_u:fullpath = "/EOSGRID/Data Fields/U" ;
        MAI3CPASM_5_2_0_UV_u:cell_methods = "record: mean time: mean Height: mean time: mean" ;
        MAI3CPASM_5_2_0_UV_u:vectorComponents = "u of MAI3CPASM_5_2_0_UV" ;
        MAI3CPASM_5_2_0_UV_u:quantity_type = "Wind" ;
        MAI3CPASM_5_2_0_UV_u:product_short_name = "MAI3CPASM" ;
        MAI3CPASM_5_2_0_UV_u:product_version = "5.2.0" ;
        MAI3CPASM_5_2_0_UV_u:z_slice = "950hPa" ;
        MAI3CPASM_5_2_0_UV_u:z_slice_type = "pressure" ;
        MAI3CPASM_5_2_0_UV_u:latitude_resolution = 1.25 ;
        MAI3CPASM_5_2_0_UV_u:longitude_resolution = 1.25 ;
    float MAI3CPASM_5_2_0_UV_v(lat, lon) ;
        MAI3CPASM_5_2_0_UV_v:_FillValue = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_v:long_name = "Wind Vector" ;
        MAI3CPASM_5_2_0_UV_v:standard_name = "wind_vector" ;
        MAI3CPASM_5_2_0_UV_v:units = "m/s" ;
        MAI3CPASM_5_2_0_UV_v:missing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_v:fmissing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_v:vmin = -1.e+30f ;
        MAI3CPASM_5_2_0_UV_v:vmax = 1.e+30f ;
        MAI3CPASM_5_2_0_UV_v:coordinates = "lat lon" ;
        MAI3CPASM_5_2_0_UV_v:fullpath = "/EOSGRID/Data Fields/V" ;
        MAI3CPASM_5_2_0_UV_v:cell_methods = "record: mean time: mean Height: mean time: mean" ;
        MAI3CPASM_5_2_0_UV_v:vectorComponents = "v of MAI3CPASM_5_2_0_UV" ;
        MAI3CPASM_5_2_0_UV_v:quantity_type = "Wind" ;
        MAI3CPASM_5_2_0_UV_v:product_short_name = "MAI3CPASM" ;
        MAI3CPASM_5_2_0_UV_v:product_version = "5.2.0" ;
        MAI3CPASM_5_2_0_UV_v:z_slice = "950hPa" ;
        MAI3CPASM_5_2_0_UV_v:z_slice_type = "pressure" ;
        MAI3CPASM_5_2_0_UV_v:latitude_resolution = 1.25 ;
        MAI3CPASM_5_2_0_UV_v:longitude_resolution = 1.25 ;
    double lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:units = "degrees_north" ;
        lat:fullpath = "YDim:EOSGRID" ;
        lat:standard_name = "latitude" ;
    double lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:units = "degrees_east" ;
        lon:fullpath = "XDim:EOSGRID" ;
        lon:standard_name = "longitude" ;
    double time ;
        time:begin_date = 20121029 ;
        time:begin_time = 0 ;
        time:fullpath = "TIME:EOSGRID" ;
        time:long_name = "time" ;
        time:standard_name = "time" ;
        time:time_increment = 30000 ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2012-10-29T00:00:00Z" ;
        :end_time = "2012-10-29T02:59:59Z" ;
        :history = "Thu Jul 23 18:38:13 2015: ncatted -a valid_range,,d,, -O -o timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc\n",
            "Thu Jul 23 18:38:13 2015: ncatted -O -a title,global,o,c,MAI3CPASM_5_2_0_UV Averaged over 2012-10-29 to 2012-10-29 timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc\n",
            "Thu Jul 23 18:38:13 2015: ncks -x -v time -o timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc -O timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc\n",
            "Thu Jul 23 18:38:13 2015: ncwa -o timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc -a time -O timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc\n",
            "Thu Jul 23 18:38:13 2015: ncra -D 2 -H -O -o timeAvgMap.MAI3CPASM_5_2_0_UV.950hPa.20121029-20121029.5E_5N_10E_10N.nc -d lat,5.000000,10.000000 -d lon,5.000000,10.000000 -d Height,950.000000,950.000000" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Wind Vector 3-hourly 1.25 deg. @950hPa [MERRA Model MAI3CPASM v5.2.0] m/s over 2012-10-29 00Z - 2012-10-29 02Z, Region 5E, 5N, 10E, 10N" ;
        :userstartdate = "2012-10-29T00:00:00Z" ;
        :userenddate = "2012-10-29T00:59:59Z" ;
        :plot_hint_title = "Time Averaged Map of Wind Vector 3-hourly 1.25 deg. @950hPa [MERRA Model MAI3CPASM v5.2.0] m/s" ;
        :plot_hint_subtitle = "over 2012-10-29 00Z - 2012-10-29 02Z, Region 5E, 5N, 10E, 10N" ;
data:

 Height = 950 ;

 MAI3CPASM_5_2_0_UV_u =
  4.281162, 3.917881, 3.003818, _,
  4.851474, 3.874912, 2.605381, 1.443271,
  4.421787, 2.492099, 0.8368258, 0.05879547,
  3.230381, 0.295322, _, _ ;

 MAI3CPASM_5_2_0_UV_v =
  2.205571, 2.592289, 2.424321, _,
  1.71143, 2.629399, 2.33643, 1.156743,
  0.2368206, 1.053471, 1.097661, 0.2749066,
  -1.583492, -0.5288044, _, _ ;

 lat = 5.625, 6.875, 8.125, 9.375 ;

 lon = 5.625, 6.875, 8.125, 9.375 ;

 time = 1351468800 ;
}
