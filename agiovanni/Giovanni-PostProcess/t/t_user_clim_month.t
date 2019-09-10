
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
    'bbox'        => '-82.9687,34.5703,-78.0469,40.1953',
    'endtime'     => '2010-02-28T23:59:59Z',
    'group'       => 'MONTH=02',
    'time-axis'   => 0,
    'infile'      => $mfstInput,
    'name'        => 'User Defined Climatology',
    'outfile'     => $mfstOutput,
    'session-dir' => $tmpdir,
    'service'     => 'QuCl',
    'starttime'   => '2007-02-01T00:00:00',
    'units'       => "hPa,$unitsConfig",
    'varfiles'    => $mfstDataFieldInfo,
    'variables'   => 'AIRX3STM_006_TropPres_A',
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
  <var id="AIRX3STM_006_TropPres_A" long_name="Tropopause Pressure (Daytime/Ascending)" sampleOpendap="http://acdisc.gsfc.nasa.gov/opendap/hyrax/ncml/Aqua_AIRS_Level3/AIRX3STM.006/2002/AIRS.2002.09.01.L3.RetStd030.v6.0.9.0.G13208054216.hdf.ncml.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Aqua%20AIRS%20Level%203%20Monthly%20Standard%20Physical%20Retrieval%20(AIRS%2BAMSU)%20V006;agent_id=OPeNDAP;variables=TropPres_A" startTime="2002-09-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="monthly" dataProductVersion="006" sampleFile="" east="180.0" dataProductShortName="AIRX3STM" osdd="" resolution="1 deg." dataProductPlatformInstrument="AIRS" quantity_type="Air Pressure" dataFieldStandardName="tropopause_air_pressure" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="hPa" latitudeResolution="1.0" accessName="TropPres_A" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." longitudeResolution="1.0" dataProductStartTimeOffset="1" dataProductEndTimeOffset="-1" west="-180.0" sdsName="TropPres_A" timeIntvRepPos="start" dataProductBeginDateTime="2002-09-01T00:00:00Z">
    <slds>
      <sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/divergent_rdylbu_11_sld.xml" label="Red-Yellow-Blue (Div), 11"/>
      <sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/spectral_div_10_inv_sld.xml" label="Spectral, Inverted (Div), 10"/>
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
        '<manifest><data zValue="NA" units="NA">AIRX3STM_006_TropPres_A</data></manifest>';
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


# Query: service=QuCl&starttime=2007-01-01T00:00:00Z&endtime=2010-12-31T23:59:59Z&months=02&bbox=-82.9687,34.5703,-78.0469,40.1953&data=AIRX3STM_006_TropPres_A&variableFacets=dataFieldMeasurement%3AAir%20Pressure%3B&portal=GIOVANNI&format=json

__DATA__
netcdf timeAvg.AIRX3STM_006_TropPres_A.20070101-20101231.MONTH_02.82W_34N_78W_40N {
dimensions:
	lat = 5 ;
	lon = 5 ;
	latv = 2 ;
	lonv = 2 ;
variables:
	float AIRX3STM_006_TropPres_A(lat, lon) ;
		AIRX3STM_006_TropPres_A:_FillValue = -9999.f ;
		AIRX3STM_006_TropPres_A:standard_name = "tropopause_air_pressure" ;
		AIRX3STM_006_TropPres_A:quantity_type = "Air Pressure" ;
		AIRX3STM_006_TropPres_A:product_short_name = "AIRX3STM" ;
		AIRX3STM_006_TropPres_A:product_version = "006" ;
		AIRX3STM_006_TropPres_A:long_name = "Tropopause Pressure (Daytime/Ascending)" ;
		AIRX3STM_006_TropPres_A:units = "hPa" ;
		AIRX3STM_006_TropPres_A:cell_methods = "time: mean" ;
		AIRX3STM_006_TropPres_A:latitude_resolution = 1. ;
		AIRX3STM_006_TropPres_A:longitude_resolution = 1. ;
		AIRX3STM_006_TropPres_A:coordinates = "lat lon" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:format = "F5.1" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:format = "F6.1" ;
		lon:missing_value = -9999.f ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:title = "AIRX3STM_006_TropPres_A Averaged over 2007-01-01 to 2010-12-31" ;
		:start_time = "2007-02-01T00:00:00Z" ;
		:end_time = "2010-02-28T23:59:59Z" ;
		:userstartdate = "2007-01-01T00:00:00Z" ;
		:userenddate = "2010-12-31T23:59:59Z" ;
data:

 AIRX3STM_006_TropPres_A =
  221.875, 220.1562, 222.3594, 223.6211, 224.0234,
  238.7188, 233.3359, 233.8789, 237.8008, 238.6094,
  244.5898, 242.1211, 243.8867, 247.332, 248.5781,
  251.9805, 254.1367, 253.3164, 254.3984, 255.918,
  262.4883, 262.2695, 263.3906, 262.8594, 262.6562 ;

 lat = 35.5, 36.5, 37.5, 38.5, 39.5 ;

 lat_bnds =
  35, 36,
  36, 37,
  37, 38,
  38, 39,
  39, 40 ;

 lon = -82.5, -81.5, -80.5, -79.5, -78.5 ;

 lon_bnds =
  -83, -82,
  -82, -81,
  -81, -80,
  -80, -79,
  -79, -78 ;
}
netcdf out {
dimensions:
	lat = 5 ;
	lon = 5 ;
	latv = 2 ;
	lonv = 2 ;
variables:
	float AIRX3STM_006_TropPres_A(lat, lon) ;
		AIRX3STM_006_TropPres_A:_FillValue = -9999.f ;
		AIRX3STM_006_TropPres_A:standard_name = "tropopause_air_pressure" ;
		AIRX3STM_006_TropPres_A:quantity_type = "Air Pressure" ;
		AIRX3STM_006_TropPres_A:product_short_name = "AIRX3STM" ;
		AIRX3STM_006_TropPres_A:product_version = "006" ;
		AIRX3STM_006_TropPres_A:long_name = "Tropopause Pressure (Daytime/Ascending)" ;
		AIRX3STM_006_TropPres_A:units = "hPa" ;
		AIRX3STM_006_TropPres_A:cell_methods = "time: mean" ;
		AIRX3STM_006_TropPres_A:latitude_resolution = 1. ;
		AIRX3STM_006_TropPres_A:longitude_resolution = 1. ;
		AIRX3STM_006_TropPres_A:coordinates = "lat lon" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:format = "F5.1" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:format = "F6.1" ;
		lon:missing_value = -9999.f ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:start_time = "2007-02-01T00:00:00Z" ;
		:end_time = "2010-02-28T23:59:59Z" ;
		:userstartdate = "2007-01-01T00:00:00Z" ;
		:userenddate = "2010-12-31T23:59:59Z" ;
		:title = "February months (2007 - 2010) Average Tropopause Pressure (Daytime/Ascending) monthly 1 deg. [AIRS AIRX3STM v006] hPa for February months 2007-Feb - 2010-Feb, Region 82.9687W, 34.5703N, 78.0469W, 40.1953N" ;
		:plot_hint_title = "February months (2007 - 2010)" ;
		:plot_hint_subtitle = "Average Tropopause Pressure (Daytime/Ascending) monthly 1 deg. [AIRS AIRX3STM v006] hPa for February months 2007-Feb - 2010-Feb, Region 82.9687W, 34.5703N, 78.0469W, 40.1953N" ;
data:

 AIRX3STM_006_TropPres_A =
  221.875, 220.1562, 222.3594, 223.6211, 224.0234,
  238.7188, 233.3359, 233.8789, 237.8008, 238.6094,
  244.5898, 242.1211, 243.8867, 247.332, 248.5781,
  251.9805, 254.1367, 253.3164, 254.3984, 255.918,
  262.4883, 262.2695, 263.3906, 262.8594, 262.6562 ;

 lat = 35.5, 36.5, 37.5, 38.5, 39.5 ;

 lat_bnds =
  35, 36,
  36, 37,
  37, 38,
  38, 39,
  39, 40 ;

 lon = -82.5, -81.5, -80.5, -79.5, -78.5 ;

 lon_bnds =
  -83, -82,
  -82, -81,
  -81, -80,
  -80, -79,
  -79, -78 ;
}
