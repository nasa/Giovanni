# This tests area-averaged scatter with units conversion and z-level.
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
my $ncInput = "$tmpdir/ncInput.nc";

my $ncOutputCorrect = "$tmpdir/ncOutputCorrect";

Giovanni::Data::NcFile::write_netcdf_file( $ncInput, $cdlInput )
    or die "Unable to write input file";

Giovanni::Data::NcFile::write_netcdf_file( $ncOutputCorrect,
    $cdlOutputCorrect )
    or die "Unable to write correct output file";

# Write the two data field info files
my $dataFieldInfoFileA = "$tmpdir/mfst.data_field_info_A.xml";
Giovanni::Util::writeFile(
    $dataFieldInfoFileA,
    <<INFO
<varList>
  <var id="AIRX3STD_006_Temperature_A" zDimUnits="hPa" long_name="Air Temperature (Daytime/Ascending)" sampleOpendap="http://acdisc.gsfc.nasa.gov/opendap/hyrax/ncml/Aqua_AIRS_Level3/AIRX3STD.006/2002/AIRS.2002.08.31.L3.RetStd001.v6.0.9.0.G13208034313.hdf.ncml.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Aqua%20AIRS%20Level%203%20Daily%20Standard%20Physical%20Retrieval%20(AIRS%2BAMSU)%20V006;agent_id=OPeNDAP;variables=Temperature_A,TempPrsLvls_A" startTime="2002-08-31T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="daily" dataProductVersion="006" sampleFile="" east="180.0" dataProductShortName="AIRX3STD" osdd="" resolution="1 deg." dataProductPlatformInstrument="AIRS" quantity_type="Air Temperature" zDimName="TempPrsLvls_A" dataFieldStandardName="air_temperature" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="K" latitudeResolution="1.0" accessName="Temperature_A,TempPrsLvls_A" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="1.0" dataProductEndTimeOffset="-1" west="-180.0" zDimValues="1000 925 850 700 600 500 400 300 250 200 150 100 70 50 30 20 15 10 7 5 3 2 1.5 1" sdsName="Temperature_A" dataProductBeginDateTime="2002-08-31T00:00:00Z" />
</varList>
INFO
) or die "Unable to write input file";

my $dataFieldInfoFileD = "$tmpdir/mfst.data_field_info_D.xml";
Giovanni::Util::writeFile(
    $dataFieldInfoFileD,
    <<INFO
<varList>
  <var id="AIRX3STD_006_Temperature_D" zDimUnits="hPa" long_name="Air Temperature (Nighttime/Descending)" sampleOpendap="http://acdisc.gsfc.nasa.gov/opendap/hyrax/ncml/Aqua_AIRS_Level3/AIRX3STD.006/2002/AIRS.2002.08.31.L3.RetStd001.v6.0.9.0.G13208034313.hdf.ncml.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Aqua%20AIRS%20Level%203%20Daily%20Standard%20Physical%20Retrieval%20(AIRS%2BAMSU)%20V006;agent_id=OPeNDAP;variables=Temperature_D,TempPrsLvls_D" startTime="2002-08-31T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="daily" dataProductVersion="006" sampleFile="" east="180.0" dataProductShortName="AIRX3STD" osdd="" resolution="1 deg." dataProductPlatformInstrument="AIRS" quantity_type="Air Temperature" zDimName="TempPrsLvls_D" dataFieldStandardName="air_temperature" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="K" latitudeResolution="1.0" accessName="Temperature_D,TempPrsLvls_D" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="1.0" dataProductEndTimeOffset="-1" west="-180.0" zDimValues="1000 925 850 700 600 500 400 300 250 200 150 100 70 50 30 20 15 10 7 5 3 2 1.5 1" sdsName="Temperature_D" dataProductBeginDateTime="2002-08-31T00:00:00Z" />
</varList>
INFO
) or die "Unable to write input file";

# Write the data field slice files
my $dataFieldSliceFileA = "$tmpdir/mfst.data_field_slice_A.xml";
Giovanni::Util::writeFile(
    $dataFieldSliceFileA,
    qq(<manifest><data zValue="400" units="C">AIRX3STD_006_Temperature_A</data></manifest>),

) or die "Unable to write input file";
my $dataFieldSliceFileD = "$tmpdir/mfst.data_field_slice_D.xml";
Giovanni::Util::writeFile(
    $dataFieldSliceFileD,
    qq(<manifest><data zValue="400" units="C">AIRX3STD_006_Temperature_D</data></manifest>),

) or die "Unable to write input file";

# Write the input manifest file
my $mfstInput = "$tmpdir/mfst.in.xml";
Giovanni::Util::writeFile(
    $mfstInput,
    <<IN
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
 <fileList>
  <file>
    $ncInput
  </file>
 </fileList>
</manifest>
IN
) or die "Unable to write input file";

# Run Post-Process Procedure
my $mfstOutput  = "$tmpdir/mfstOutput.xml";
my $unitsConfig = "$FindBin::Bin/../../cfg/unitsCfg.xml";

my $rc = Giovanni::PostProcess::run(
    'bbox'        => '90.7031,-18.8672,-101.25,80.2735',
    'endtime'     => '2009-01-05T23:59:59Z ',
    'infile'      => $mfstInput,
    'name'        => 'Scatter, Area Averaged (Static)',
    'outfile'     => $mfstOutput,
    'session-dir' => $tmpdir,
    'service'     => 'ArAvSc',
    'starttime'   => '2009-01-01T00:00:00Z',
    'units'       => "C,C,$unitsConfig",
    'varfiles'    => "$dataFieldInfoFileA,$dataFieldInfoFileD",
    'variables'   => 'AIRX3STD_006_Temperature_A,AIRX3STD_006_Temperature_D',
    'zfiles'      => "$dataFieldSliceFileA,$dataFieldSliceFileD",
    'comparison' => 'vs.',
);

is( 0, $rc, "Got return code 0 from run()" );

# Compare Results
my $mfstRead = Giovanni::Util::getDataFilesFromManifest($mfstOutput);
is( 1, scalar @{ $mfstRead->{data} }, "Got one output file" );
my $ncOutputGot = $mfstRead->{data}->[0];

my $out = Giovanni::Data::NcFile::diff_netcdf_files( $ncOutputGot,
    $ncOutputCorrect );
is( $out, '', "Same output: $out" );

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
netcdf areaAvgScatter.AIRX3STD_006_Temperature_A.400hPa+AIRX3STD_006_Temperature_D.400hPa.20090101-20090105.90E_18S_101W_80N {
dimensions:
    lat = 1 ;
    lon = 1 ;
    time = UNLIMITED ; // (5 currently)
variables:
    double lat(lat) ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
    float x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa(time, lat, lon) ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:_FillValue = -9999.f ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:standard_name = "air_temperature" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:long_name = "Air Temperature (Daytime/Ascending)" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:units = "K" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:coordinates = "time lat lon" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:quantity_type = "Air Temperature" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:product_short_name = "AIRX3STD" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:product_version = "006" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:cell_methods = "lat,lon: mean" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
    float y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa(time, lat, lon) ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:_FillValue = -9999.f ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:standard_name = "air_temperature" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:long_name = "Air Temperature (Nighttime/Descending)" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:units = "K" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:coordinates = "time lat lon" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:quantity_type = "Air Temperature" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:product_short_name = "AIRX3STD" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:product_version = "006" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:cell_methods = "lat,lon: mean" ;

// global attributes:
        :NCO = "\"4.5.3\"" ;
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2009-01-01T00:00:00Z" ;
        :end_time = "2009-01-05T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :userstartdate = "2009-01-01T00:00:00Z" ;
        :userenddate = "2009-01-05T23:59:59Z" ;
data:

 lat = -18.8672 ;

 lon = 90.7031 ;

 x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa =
  246.0222,
  246.4693,
  246.1749,
  246.6704,
  246.4811 ;

 time = 1230768000, 1230854400, 1230940800, 1231027200, 1231113600 ;

 y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa =
  246.0264,
  245.9593,
  246.2277,
  246.0889,
  246.5993 ;
}
netcdf g4.ncInput {
dimensions:
    time = UNLIMITED ; // (5 currently)
    lat = 1 ;
    lon = 1 ;
variables:
    float x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa(time, lat, lon) ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:_FillValue = -9999.f ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:cell_methods = "lat,lon: mean" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:coordinates = "time lat lon" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:long_name = "Air Temperature (Daytime/Ascending)" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:product_short_name = "AIRX3STD" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:product_version = "006" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:quantity_type = "Air Temperature" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:standard_name = "air_temperature" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:units = "C" ;
        x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa:plot_hint_axis_title = "Air Temperature (Daytime/Ascending) daily 1 deg. @400hPa [AIRS AIRX3STD v006] C" ;
    float y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa(time, lat, lon) ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:_FillValue = -9999.f ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:cell_methods = "lat,lon: mean" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:coordinates = "time lat lon" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:long_name = "Air Temperature (Nighttime/Descending)" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:product_short_name = "AIRX3STD" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:product_version = "006" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:quantity_type = "Air Temperature" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:standard_name = "air_temperature" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:units = "C" ;
        y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa:plot_hint_axis_title = "Air Temperature (Nighttime/Descending) daily 1 deg. @400hPa [AIRS AIRX3STD v006] C" ;
    double lat(lat) ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :NCO = "\"4.5.3\"" ;
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2009-01-01T00:00:00Z" ;
        :end_time = "2009-01-05T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :userstartdate = "2009-01-01T00:00:00Z" ;
        :userenddate = "2009-01-05T23:59:59Z" ;
        :title = "Scatter, Area Averaged (Static) of Air Temperature (Nighttime/Descending) daily 1 deg. @400hPa [AIRS AIRX3STD v006] C vs. Air Temperature (Daytime/Ascending) daily 1 deg. @400hPa [AIRS AIRX3STD v006] C" ;
        :plot_hint_title = "Scatter, Area Averaged (Static)" ;
        :plot_hint_subtitle = "2009-01-01 - 2009-01-05, Region 90.7031E, 18.8672S, 101.25W, 80.2735N" ;
data:

 x_AIRX3STD_006_Temperature_A_TempPrsLvls_A_400hPa =
  -27.1278,
  -26.6807,
  -26.9751,
  -26.4796,
  -26.66891 ;

 y_AIRX3STD_006_Temperature_D_TempPrsLvls_D_400hPa =
  -27.1236,
  -27.19069,
  -26.92229,
  -27.0611,
  -26.5507 ;

 lat = -18.8672 ;

 lon = 90.7031 ;

 time = 1230768000, 1230854400, 1230940800, 1231027200, 1231113600 ;
}
