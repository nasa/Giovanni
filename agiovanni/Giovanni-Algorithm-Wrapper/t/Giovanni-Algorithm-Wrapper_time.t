
# Tests the way we calculate the begin and end time. Is needs to be the union
# of the times of the input files.
#http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/index-debug.html#service=DiTmAvMp&starttime=2004-03-15T00:00:00Z&endtime=2004-03-15T02:59:59Z&bbox=-83.6719,30.3516,-77.3437,35.9766&data=MAT3CPRAD_5_2_0_CLOUD(z%3D1000)%2CMAI3CPASM_5_2_0_RH(z%3D1000)&dataKeyword=MERRA

use Test::More tests => 3;
use Giovanni::Data::NcFile;
use Giovanni::Testing;
use File::Temp;
use Cwd;
use XML::LibXML;
BEGIN { use_ok('Giovanni::Algorithm::Wrapper'); }

# create a temporary directory
my $datadir = File::Temp::tempdir( CLEANUP => 1 );

# grab the CDL at the end
my $cdl = Giovanni::Data::NcFile::read_cdl_data_block();

# write them out to the temporary directory
my $xFile = "$datadir/scrubbed.MAT3CPRAD_5_2_0_CLOUD.200403150000.nc";
my $yFile = "$datadir/scrubbed.MAI3CPASM_5_2_0_RH.200403150000.nc";
my $ref   = "$datadir/ref.nc";
Giovanni::Data::NcFile::write_netcdf_file( $xFile, $cdl->[0] );
Giovanni::Data::NcFile::write_netcdf_file( $yFile, $cdl->[1] );
Giovanni::Data::NcFile::write_netcdf_file( $ref,   $cdl->[2] );

# create the input manifest files
my $inMfstFile
    = "$datadir/mfst.merge+dMAT3CPRAD_5_2_0_CLOUD+z1000+uNA+dMAI3CPASM_5_2_0_RH+z1000+uNA+t20040315000000_20040315025959+b83.6719W30.3516N77.3437W35.9766N.xml";
my $doc  = XML::LibXML::Document->new();
my $root = $doc->createElement("manifest");
$doc->setDocumentElement($root);

# X
my $fileListNode = $doc->createElement("fileList");
$root->appendChild($fileListNode);
$fileListNode->setAttribute( "id", "MAT3CPRAD_5_2_0_CLOUD" );
my $fileNode = $doc->createElement("file");
$fileListNode->appendChild($fileNode);
$fileNode->appendText($xFile);

# Y
$fileListNode = $doc->createElement("fileList");
$root->appendChild($fileListNode);
$fileListNode->setAttribute( "id", "MAI3CPASM_5_2_0_RH" );
$fileNode = $doc->createElement("file");
$fileListNode->appendChild($fileNode);
$fileNode->appendText($yFile);

$doc->toFile($inMfstFile);

my $xZFile
    = "$datadir/mfst.data_field_slice+dMAT3CPRAD_5_2_0_CLOUD+z1000+uNA.xml";
open( FILE, ">", $xZFile ) or die "Unable to open $xZFile";
print FILE
    '<manifest><data zValue="1000" units="NA">MAT3CPRAD_5_2_0_CLOUD</data></manifest>';
close(FILE);

my $yZFile
    = "$datadir/mfst.data_field_slice+dMAI3CPASM_5_2_0_RH+z1000+uNA.xml";
open( FILE, ">", $yZFile ) or die "Unable to open $yZFile";
print FILE
    '<manifest><data zValue="1000" units="NA">MAI3CPASM_5_2_0_RH</data></manifest>';
close(FILE);

my $xInfoFile = "$datadir/mfst.data_field_info+dMAT3CPRAD_5_2_0_CLOUD.xml";
my $xInfo     = <<'INFO';
<varList><var id="MAT3CPRAD_5_2_0_CLOUD" zDimUnits="hPa" long_name="3D Cloud Fraction, time average" sampleOpendap="http://goldsmr3.sci.gsfc.nasa.gov/opendap/ncml/MERRA/MAT3CPRAD.5.2.0/1979/01/MERRA100.prod.assim.tavg3_3d_rad_Cp.19790101.hdf.ncml.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP_TIMESPLIT" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MERRA%203D%20IAU%20Diagnostic%2C%20Radiation%2C%20Time%20average%203-hourly%20(1.25x1.25L42)%20V5.2.0;agent_id=OPeNDAP_TIMESPLIT;variables=CLOUD" startTime="1979-01-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="3-hourly" dataProductVersion="5.2.0" sampleFile="" east="180.0" dataProductShortName="MAT3CPRAD" osdd="" resolution="1.25 deg." dataProductPlatformInstrument="MERRA Model" quantity_type="Cloud Fraction" zDimName="Height" dataFieldStandardName="cloud_area_fraction_in_atmosphere_layer" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="fraction" latitudeResolution="1.25" accessName="CLOUD" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="1.25" dataProductEndTimeOffset="0" west="-180.0" zDimValues="1000 975 950 925 900 875 850 825 800 775 750 725 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 40 30 20 10 7 5 4 3 2 1 0.7 0.5 0.4 0.3 0.1" sdsName="CLOUD" timeIntvRepPos="middle" dataProductBeginDateTime="1979-01-01T00:00:00Z"><slds><sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/><sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/spectral_div_11_inv_sld.xml" label="Spectral, Inverted (Div), 11"/></slds></var></varList>
INFO
open( FILE, ">", $xInfoFile ) or die "Unable to open $xInfoFile";
print FILE $xInfo;
close(FILE);

my $yInfoFile = "$datadir/mfst.data_field_info+dMAI3CPASM_5_2_0_RH.xml";
my $yInfo     = <<'INFO';
<varList><var id="MAI3CPASM_5_2_0_RH" zDimUnits="hPa" long_name="Relative Humidity, Instantaneous" searchIntervalDays="183.0" sampleOpendap="http://goldsmr3.sci.gsfc.nasa.gov/opendap/ncml/MERRA/MAI3CPASM.5.2.0/1979/01/MERRA100.prod.assim.inst3_3d_asm_Cp.19790101.hdf.ncml.html" dataProductTimeFrequency="3" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP_TIMESPLIT" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MERRA%203D%20IAU%20State%2C%20Meteorology%20Instantaneous%203-hourly%20(p-coord%2C%201.25x1.25L42)%20V5.2.0;agent_id=OPeNDAP_TIMESPLIT;variables=RH" startTime="1979-01-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="3-hourly" dataProductVersion="5.2.0" sampleFile="" east="180.0" dataProductShortName="MAI3CPASM" osdd="" resolution="1.25 deg." dataProductPlatformInstrument="MERRA Model" quantity_type="Atmospheric Moisture" zDimName="Height" deflationLevel="1" dataFieldStandardName="relative_humidity" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="fraction" latitudeResolution="1.25" accessName="RH" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="0" longitudeResolution="1.25" dataProductEndTimeOffset="0" west="-180.0" zDimValues="1000 975 950 925 900 875 850 825 800 775 750 725 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 40 30 20 10 7 5 4 3 2 1 0.7 0.5 0.4 0.3 0.1" sdsName="RH" timeIntvRepPos="start" dataProductBeginDateTime="1979-01-01T00:00:00Z"><slds><sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/divergent_burd_11_sld.xml" label="Blue-Red (Div), 11"/><sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/spectral_div_11_inv_sld.xml" label="Spectral, Inverted (Div), 11"/></slds></var></varList>
INFO
open( FILE, ">", $yInfoFile ) or die "Unable to open $yInfoFile";
print FILE $yInfo;
close(FILE);

# arguments
my $outputFileRoot = "timeAvgDiffMap";
my $program        = "g4_time_avg_diff_map.pl";
my $inputfiles     = $inMfstFile;
my $bbox           = "-83.6719,30.3516,-77.3437,35.9766";
my $outfile
    = "$datadir/mfst.result+sDiTmAvMp+dMAT3CPRAD_5_2_0_CLOUD+z1000+uNA+dMAI3CPASM_5_2_0_RH+z1000+uNA+t20040315000000_20040315025959+b83.6719W30.3516N77.3437W35.9766N.xml";
my $zfiles     = "$xZFile,$yZFile";
my $varfiles   = "$xInfoFile,$yInfoFile";
my $starttime  = "2004-03-15T00:00:00Z";
my $endtime    = "2004-03-15T02:59:59Z";
my $variables  = "MAT3CPRAD_5_2_0_CLOUD,MAI3CPASM_5_2_0_RH";
my $name       = "Map, Difference of Time Averaged";
my $comparison = "minus";
my $dateline   = "stitch";
my $debug      = "0";

my $outNc = Giovanni::Algorithm::Wrapper::run(
    'program'          => $program,
    'name'             => $name,
    'dateline'         => $dateline,
    'starttime'        => $starttime,
    'endtime'          => $endtime,
    'bbox'             => $bbox,
    'outfile'          => $outfile,
    'output-file-root' => $outputFileRoot,
    'debug'            => $debug,
    'varfiles'         => $varfiles,
    'variables'        => $variables,
    'inputfiles'       => $inputfiles,
    'session-dir'      => $datadir,
    'zfiles'           => $zfiles,
    'comparison'       => $comparison,
);
ok( -e $outNc, "Output file created" );
my $diff = Giovanni::Data::NcFile::diff_netcdf_files( $outNc, $ref );
is( $diff, '', "No differences" );

unlink($outNc);

__DATA__
netcdf scrubbed.MAT3CPRAD_5_2_0_CLOUD.200403150000_subset {
dimensions:
	Height = 3 ;
	time = UNLIMITED ; // (1 currently)
	lat = 12 ;
	lon = 16 ;
	latv = 2 ;
	lonv = 2 ;
	bnds = 2 ;
variables:
	double Height(Height) ;
		Height:long_name = "vertical level" ;
		Height:positive = "down" ;
		Height:coordinate = "PLE" ;
		Height:standard_name = "PLE_level" ;
		Height:formula_term = "unknown" ;
		Height:fullpath = "Height:EOSGRID" ;
		Height:units = "hPa" ;
	float MAT3CPRAD_5_2_0_CLOUD(time, Height, lat, lon) ;
		MAT3CPRAD_5_2_0_CLOUD:_FillValue = 1.e+15f ;
		MAT3CPRAD_5_2_0_CLOUD:missing_value = 1.e+15f ;
		MAT3CPRAD_5_2_0_CLOUD:fmissing_value = 1.e+15f ;
		MAT3CPRAD_5_2_0_CLOUD:vmin = -1.e+30f ;
		MAT3CPRAD_5_2_0_CLOUD:vmax = 1.e+30f ;
		MAT3CPRAD_5_2_0_CLOUD:fullpath = "/EOSGRID/Data Fields/CLOUD" ;
		MAT3CPRAD_5_2_0_CLOUD:standard_name = "cloud_area_fraction_in_atmosphere_layer" ;
		MAT3CPRAD_5_2_0_CLOUD:quantity_type = "Cloud Fraction" ;
		MAT3CPRAD_5_2_0_CLOUD:product_short_name = "MAT3CPRAD" ;
		MAT3CPRAD_5_2_0_CLOUD:product_version = "5.2.0" ;
		MAT3CPRAD_5_2_0_CLOUD:long_name = "3D Cloud Fraction, time average" ;
		MAT3CPRAD_5_2_0_CLOUD:coordinates = "time Height lat lon" ;
		MAT3CPRAD_5_2_0_CLOUD:units = "fraction" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:fullpath = "YDim:EOSGRID" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:fullpath = "XDim:EOSGRID" ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	double time(time) ;
		time:begin_date = 20040315 ;
		time:begin_time = 13000 ;
		time:bounds = "time_bnds" ;
		time:fullpath = "TIME:EOSGRID" ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:time_increment = 30000 ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	int time_bnds(time, bnds) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;
		time_bnds:standard_name = "bounds" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2004-03-15T00:00:00Z" ;
		:end_time = "2004-03-15T02:59:59Z" ;
		:temporal_resolution = "3-hourly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Fri Nov 11 19:16:08 2016: ncks -O -d lon,-90.,-70. -d lat,25.,40. -d Height,949.,1100. scrubbed.MAT3CPRAD_5_2_0_CLOUD.200403150000.nc scrubbed.MAT3CPRAD_5_2_0_CLOUD.200403150000_subset.nc" ;
data:

 Height = 1000, 975, 950 ;

 MAT3CPRAD_5_2_0_CLOUD =
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5.429684e-16, 4.253542e-15, 
    1.025222e-15,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5.529728e-10, 1.844001e-10, 0,
  0.02471924, 0.003795624, 0, 0, 0, 0, 0, 0, 0, 0, 2.106049e-11, 
    5.139736e-08, 1.156877e-08, 5.529728e-10, 1.844001e-10, 0,
  0.0567627, 0.1452637, 0.07312012, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7.599592e-06, 
    1.085922e-06, 0, 0,
  0.001832962, 0.06530762, 0.0411377, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0.0007867813, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.341105e-07, 1.026317e-06, 0, 0, 
    0, 0,
  0.0007867813, 0, 0, _, _, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, _, _, _, _, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, _, _, _, _, _, _, 0, 0, 4.327297e-05, 0.0003027916, 0, 0, 0, 0,
  0, 0, 0, _, _, _, _, _, _, 0, 0.0004644394, 0.003250122, 0.0002479553, 0, 
    0, 0,
  0, 0, 0, _, _, _, _, _, _, _, 0, 0, 0.0001728535, 0, 0, 0,
  0, 0, _, _, _, _, _, _, _, _, _, 0, 0, 0, 0, 0,
  0.004692078, 0.004203796, 0.0001556873, 0.0002856255, 4.589558e-05, 0, 
    0.0006656647, 0.004844666, 3.252607e-18, 5.421011e-18, 8.076873e-15, 
    0.0001349449, 6.401539e-05, 4.839897e-05, 2.82228e-05, 1.245644e-07,
  0, 0.001562119, 5.209446e-05, 9.536743e-05, 0, 0, 0, 0, 0, 0, 1.996756e-06, 
    4.49419e-05, 0.0002493858, 0.0002508163, 7.843971e-05, 0,
  0.02737427, 0.001752853, 0, 0, 0, 0, 0, 0, 0, 0, 1.7941e-05, 0.0004172325, 
    0.0005531311, 0.0002622604, 0.0001180172, 0.0001074076,
  0.1071777, 0.08056641, 0, 0, 0, 0, 0, 0, 4.060566e-07, 1.573563e-05, 
    3.5882e-05, 0.0001444817, 0.0006227493, 0.000159502, 6.258488e-05, 
    1.981854e-05,
  0.03302002, 0.02960205, 0, 0, 0, 0, 0, 0, 0, 1.955777e-06, 3.063679e-05, 
    0.0006542206, 0.0001161098, 1.570582e-05, 0, 2.014389e-12,
  0.006118774, 0, 0, 0, 0, 0, 0, 0, 0, 2.659857e-06, 8.320808e-05, 
    0.0008535385, 0, 4.315376e-05, 0, 3.717027e-13,
  0.006149292, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.192799e-17, 0, 0, 4.315376e-05, 
    0, 8.359979e-14,
  2.298038e-07, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7.799827e-08, 3.166497e-07, 
    3.87663e-08, 0, 8.066464e-17,
  2.834946e-06, 0, 0, 0, _, _, _, 0, 0, 0, 0, 0, 2.714805e-07, 3.87663e-08, 
    0, 0,
  2.099114e-09, 0, 0, 0, 0, _, _, _, 0, 0, 0, 0, 7.355213e-05, 0, 0, 0,
  0, 0, 0, 0, 0, 0.003944397, _, _, _, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0.002471924, 0.03399658, 0.0141449, _, _, 0, 0, 0, 0, 0, 0,
  0.03018188, 0.02877808, 0.001972198, 0.002880096, 0.001096725, 
    0.0001525879, 0.001409531, 0.03024292, 0.02288818, 0.00220871, 
    0.003185272, 0.01693726, 0.01940918, 0.008621216, 0.008239746, 0.00321579,
  6.181654e-08, 0.007164001, 0.0009098053, 0.001001358, 1.707673e-05, 
    9.849668e-06, 4.49419e-05, 0.0002865791, 8.47578e-05, 1.847411e-12, 
    0.000275135, 0.001623154, 0.002464294, 0.00258255, 0.001638412, 
    0.0002713203,
  6.961823e-05, 0.007087708, 0, 0, 1.226366e-05, 8.996576e-07, 2.611428e-06, 
    1.218915e-05, 8.951173e-16, 3.215206e-13, 0.0007572174, 0.004379272, 
    0.005096436, 0.003456116, 0.004089355, 0.002494812,
  0.001590729, 1.989305e-06, 0, 0, 4.015863e-06, 1.469161e-07, 0, 0, 
    0.0002670288, 0.001327515, 0.00202179, 0.007095337, 0.008117676, 
    0.00668335, 0.003543854, 0.001358032,
  0.0005407333, 3.880262e-05, 0, 0, 0, 0, 0, 0, 0, 0.001247406, 0.009536743, 
    0.0302124, 0.02041626, 0.003646851, 1.447916e-09, 3.133209e-10,
  0.001775742, 3.814697e-05, 7.161871e-07, 0, 0, 0, 0, 0, 0.0002851486, 
    0.01350403, 0.002571106, 0.009002686, 0.0004892349, 0.001169205, 
    2.862066e-11, 2.664819e-10,
  0.003868103, 0.003013611, 0, 0, 0, 0, 0, 0, 0.0002961159, 0.004310608, 
    2.17855e-05, 1.533772e-08, 0.0003356934, 0.002017975, 3.087308e-12, 
    2.153229e-10,
  1.496077e-05, 0.0006961823, 0, 0, 0, 0, 0, 0, 0, 0, 4.336238e-06, 
    0.0007076263, 0.001813889, 0.0001126528, 0, 1.961098e-11,
  0.0002636909, 4.678965e-05, 0, 0, 0, _, _, 0, 0, 0, 0.0001549721, 
    0.002929688, 0.01324463, 7.379055e-05, 0, 0,
  3.314018e-05, 3.504753e-05, 1.28299e-05, 1.701713e-05, 2.316665e-07, 
    0.04309082, _, _, 0, 0, 1.296401e-06, 0.000103116, 0.009765625, 
    0.000834465, 0, 0,
  0, 8.102506e-08, 1.411885e-06, 4.149973e-06, 4.628673e-07, 0.008117676, 
    0.06726074, _, _, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0.003707886, 0.06567383, 0.2192383, _, 0.0007629395, 0, 0, 
    0, 0, 0, 0 ;

 lat = 25.625, 26.875, 28.125, 29.375, 30.625, 31.875, 33.125, 34.375, 
    35.625, 36.875, 38.125, 39.375 ;

 lat_bnds =
  25, 26.25,
  26.25, 27.5,
  27.5, 28.75,
  28.75, 30,
  30, 31.25,
  31.25, 32.5,
  32.5, 33.75,
  33.75, 35,
  35, 36.25,
  36.25, 37.5,
  37.5, 38.75,
  38.75, 40 ;

 lon = -89.375, -88.125, -86.875, -85.625, -84.375, -83.125, -81.875, 
    -80.625, -79.375, -78.125, -76.875, -75.625, -74.375, -73.125, -71.875, 
    -70.625 ;

 lon_bnds =
  -90, -88.75,
  -88.75, -87.5,
  -87.5, -86.25,
  -86.25, -85,
  -85, -83.75,
  -83.75, -82.5,
  -82.5, -81.25,
  -81.25, -80,
  -80, -78.75,
  -78.75, -77.5,
  -77.5, -76.25,
  -76.25, -75,
  -75, -73.75,
  -73.75, -72.5,
  -72.5, -71.25,
  -71.25, -70 ;

 time = 1079314200 ;

 time_bnds =
  1079308800, 1079319599 ;
}
netcdf scrubbed.MAI3CPASM_5_2_0_RH.200403150000_subset {
dimensions:
	Height = 3 ;
	time = UNLIMITED ; // (1 currently)
	lat = 12 ;
	lon = 16 ;
	latv = 2 ;
	lonv = 2 ;
	bnds = 2 ;
variables:
	double Height(Height) ;
		Height:long_name = "vertical level" ;
		Height:positive = "down" ;
		Height:coordinate = "PLE" ;
		Height:standard_name = "PLE_level" ;
		Height:formula_term = "unknown" ;
		Height:fullpath = "Height:EOSGRID" ;
		Height:units = "hPa" ;
	float MAI3CPASM_5_2_0_RH(time, Height, lat, lon) ;
		MAI3CPASM_5_2_0_RH:_FillValue = 1.e+15f ;
		MAI3CPASM_5_2_0_RH:missing_value = 1.e+15f ;
		MAI3CPASM_5_2_0_RH:fmissing_value = 1.e+15f ;
		MAI3CPASM_5_2_0_RH:vmin = -1.e+30f ;
		MAI3CPASM_5_2_0_RH:vmax = 1.e+30f ;
		MAI3CPASM_5_2_0_RH:fullpath = "/EOSGRID/Data Fields/RH" ;
		MAI3CPASM_5_2_0_RH:standard_name = "relative_humidity" ;
		MAI3CPASM_5_2_0_RH:quantity_type = "Atmospheric Moisture" ;
		MAI3CPASM_5_2_0_RH:product_short_name = "MAI3CPASM" ;
		MAI3CPASM_5_2_0_RH:product_version = "5.2.0" ;
		MAI3CPASM_5_2_0_RH:long_name = "Relative Humidity, Instantaneous" ;
		MAI3CPASM_5_2_0_RH:coordinates = "time Height lat lon" ;
		MAI3CPASM_5_2_0_RH:units = "fraction" ;
		MAI3CPASM_5_2_0_RH:cell_methods = " time: point" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:fullpath = "YDim:EOSGRID" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:fullpath = "XDim:EOSGRID" ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	double time(time) ;
		time:begin_date = 20040315 ;
		time:begin_time = 0 ;
		time:bounds = "time_bnds" ;
		time:fullpath = "TIME:EOSGRID" ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:time_increment = 30000 ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	int time_bnds(time, bnds) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;
		time_bnds:standard_name = "bounds" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2004-03-15T00:00:00Z" ;
		:end_time = "2004-03-15T00:00:00Z" ;
		:temporal_resolution = "3-hourly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Fri Nov 11 19:15:30 2016: ncks -O -d lon,-90.,-70. -d lat,25.,40. -d Height,949.,1100. scrubbed.MAI3CPASM_5_2_0_RH.200403150000.nc scrubbed.MAI3CPASM_5_2_0_RH.200403150000_subset.nc" ;
data:

 Height = 1000, 975, 950 ;

 MAI3CPASM_5_2_0_RH =
  0.7851562, 0.7792969, 0.7294922, 0.7431641, 0.7666016, 0.7177734, 
    0.7265625, 0.8183594, 0.8095703, 0.7841797, 0.7832031, 0.7685547, 
    0.7617188, 0.7675781, 0.7792969, 0.7773438,
  0.8408203, 0.7734375, 0.7412109, 0.7753906, 0.7109375, 0.5810547, 
    0.6152344, 0.6767578, 0.6904297, 0.7138672, 0.7333984, 0.7275391, 
    0.7382812, 0.7451172, 0.7460938, 0.7421875,
  0.8847656, 0.8398438, 0.8300781, 0.7861328, 0.6318359, 0.5283203, 
    0.5332031, 0.65625, 0.6943359, 0.7304688, 0.7509766, 0.7587891, 
    0.7578125, 0.7392578, 0.7275391, 0.71875,
  0.8867188, 0.9404297, 0.9082031, 0.6640625, 0.5976562, 0.5419922, 0.5625, 
    0.671875, 0.6650391, 0.6611328, 0.6865234, 0.7148438, 0.7587891, 
    0.7431641, 0.7080078, 0.6982422,
  0.7539062, 0.7080078, 0.7001953, 0.5957031, 0.4790039, 0.4755859, 
    0.6396484, 0.7216797, 0.6279297, 0.6865234, 0.7861328, 0.8066406, 
    0.7919922, 0.7597656, 0.7246094, 0.6835938,
  0.7021484, 0.5927734, 0.5146484, 0.5742188, 0.5644531, 0.5810547, 
    0.6914062, 0.7900391, 0.7646484, 0.7763672, 0.7421875, 0.7431641, 
    0.7558594, 0.7470703, 0.7148438, 0.6757812,
  0.8115234, 0.6884766, 0.5527344, _, _, 0.6386719, 0.640625, 0.6777344, 
    0.7539062, 0.7148438, 0.6679688, 0.6855469, 0.7128906, 0.7197266, 
    0.6943359, 0.6699219,
  0.6923828, 0.6992188, _, _, _, _, 0.6796875, 0.6425781, 0.6738281, 
    0.6982422, 0.6933594, 0.7128906, 0.7021484, 0.6826172, 0.6503906, 
    0.6337891,
  0.6630859, 0.6679688, _, _, _, _, _, _, 0.6298828, 0.6279297, 0.6962891, 
    0.7949219, 0.7333984, 0.6621094, 0.6132812, 0.6044922,
  0.4741211, 0.578125, 0.6630859, _, _, _, _, _, _, 0.5566406, 0.5644531, 
    0.7333984, 0.7587891, 0.6621094, 0.6103516, 0.5878906,
  0.4052734, 0.4428711, 0.5234375, _, _, _, _, _, _, _, 0.5205078, 0.6904297, 
    0.7050781, 0.6005859, 0.5732422, 0.5595703,
  0.390625, 0.4145508, _, _, _, _, _, _, _, _, _, 0.6455078, 0.6289062, 
    0.5722656, 0.5634766, 0.5634766,
  0.7880859, 0.828125, 0.7871094, 0.8007812, 0.8066406, 0.7314453, 0.7822266, 
    0.8789062, 0.8730469, 0.8515625, 0.8476562, 0.8271484, 0.8183594, 
    0.8261719, 0.84375, 0.8417969,
  0.8574219, 0.8261719, 0.7958984, 0.7832031, 0.6259766, 0.6152344, 
    0.6660156, 0.7285156, 0.7431641, 0.7695312, 0.7880859, 0.7802734, 
    0.7910156, 0.7978516, 0.7998047, 0.796875,
  0.8691406, 0.8310547, 0.8095703, 0.6796875, 0.6025391, 0.5380859, 
    0.5722656, 0.7060547, 0.7451172, 0.7880859, 0.8115234, 0.8232422, 
    0.8222656, 0.8017578, 0.7880859, 0.7792969,
  0.9160156, 0.9013672, 0.7275391, 0.609375, 0.6035156, 0.5732422, 0.5927734, 
    0.7119141, 0.7148438, 0.7148438, 0.7470703, 0.7763672, 0.8173828, 
    0.8076172, 0.765625, 0.7568359,
  0.7871094, 0.7148438, 0.6347656, 0.5927734, 0.4980469, 0.5039062, 0.65625, 
    0.6992188, 0.6474609, 0.7373047, 0.8525391, 0.8808594, 0.8662109, 
    0.8251953, 0.7832031, 0.7392578,
  0.7041016, 0.6279297, 0.5253906, 0.5371094, 0.5693359, 0.6064453, 
    0.7265625, 0.7988281, 0.7988281, 0.8427734, 0.8105469, 0.8115234, 
    0.8242188, 0.8125, 0.7753906, 0.7314453,
  0.8271484, 0.6992188, 0.5166016, 0.4916992, 0.5615234, 0.6083984, 
    0.6552734, 0.7041016, 0.7998047, 0.7753906, 0.7265625, 0.7460938, 
    0.7783203, 0.7841797, 0.7558594, 0.7265625,
  0.7382812, 0.7207031, 0.6455078, 0.5664062, 0.5849609, 0.6269531, 
    0.6201172, 0.6230469, 0.6855469, 0.7304688, 0.7382812, 0.7714844, 
    0.7666016, 0.7470703, 0.7109375, 0.6904297,
  0.6992188, 0.6748047, 0.6660156, _, _, _, _, 0.5576172, 0.5751953, 
    0.6230469, 0.7128906, 0.8447266, 0.7998047, 0.7236328, 0.6689453, 
    0.6582031,
  0.4418945, 0.5458984, 0.6513672, 0.7617188, _, _, _, _, 0.5048828, 
    0.5009766, 0.5488281, 0.7021484, 0.8085938, 0.7158203, 0.6601562, 
    0.6367188,
  0.3574219, 0.3881836, 0.4619141, 0.6259766, 0.7988281, 0.8769531, _, _, _, 
    0.4658203, 0.4663086, 0.6054688, 0.6933594, 0.6298828, 0.6064453, 
    0.5947266,
  0.3535156, 0.3696289, 0.3994141, 0.4599609, 0.5966797, 0.8046875, 
    0.8896484, 0.9042969, _, _, 0.5087891, 0.5957031, 0.5771484, 0.5341797, 
    0.5654297, 0.578125,
  0.8212891, 0.875, 0.8554688, 0.859375, 0.8408203, 0.7871094, 0.8525391, 
    0.9345703, 0.9384766, 0.9228516, 0.9130859, 0.8857422, 0.8691406, 
    0.8798828, 0.9023438, 0.90625,
  0.890625, 0.8828125, 0.8574219, 0.7861328, 0.6328125, 0.6689453, 0.734375, 
    0.7978516, 0.8085938, 0.8320312, 0.8417969, 0.8300781, 0.8388672, 
    0.8427734, 0.8466797, 0.8466797,
  0.8359375, 0.8144531, 0.7949219, 0.6640625, 0.6357422, 0.5722656, 
    0.6269531, 0.7685547, 0.8007812, 0.8476562, 0.8769531, 0.8935547, 
    0.8925781, 0.8691406, 0.8535156, 0.8466797,
  0.8730469, 0.7871094, 0.7060547, 0.6416016, 0.6523438, 0.6123047, 
    0.6367188, 0.7597656, 0.7734375, 0.7763672, 0.8105469, 0.8388672, 
    0.8759766, 0.8769531, 0.8320312, 0.8203125,
  0.8212891, 0.7138672, 0.6464844, 0.625, 0.5400391, 0.5478516, 0.6845703, 
    0.7050781, 0.6855469, 0.7890625, 0.9140625, 0.9414062, 0.9326172, 
    0.8867188, 0.8417969, 0.7988281,
  0.75, 0.6845703, 0.5683594, 0.5849609, 0.6181641, 0.6582031, 0.7714844, 
    0.7871094, 0.8056641, 0.8876953, 0.8808594, 0.8837891, 0.8925781, 
    0.8740234, 0.8349609, 0.7929688,
  0.8701172, 0.7568359, 0.5566406, 0.4985352, 0.5908203, 0.6601562, 
    0.7109375, 0.7373047, 0.8271484, 0.8408203, 0.7949219, 0.8134766, 
    0.8466797, 0.8525391, 0.8183594, 0.7841797,
  0.8115234, 0.7919922, 0.6835938, 0.5224609, 0.5439453, 0.6240234, 
    0.6572266, 0.6689453, 0.7304688, 0.7880859, 0.796875, 0.8349609, 
    0.8359375, 0.8193359, 0.7763672, 0.7519531,
  0.7705078, 0.7392578, 0.7167969, 0.7509766, 0.7265625, _, _, 0.5703125, 
    0.6132812, 0.6728516, 0.7490234, 0.8808594, 0.8671875, 0.7929688, 
    0.7314453, 0.7177734,
  0.4814453, 0.5957031, 0.7070312, 0.8046875, 0.890625, 0.8847656, _, _, 
    0.4892578, 0.5205078, 0.5712891, 0.6728516, 0.8173828, 0.7695312, 
    0.7158203, 0.6894531,
  0.3808594, 0.4160156, 0.4760742, 0.6425781, 0.8232422, 0.9179688, 
    0.9003906, _, _, 0.4516602, 0.4545898, 0.5410156, 0.5517578, 0.5898438, 
    0.6279297, 0.6210938,
  0.3769531, 0.3862305, 0.3999023, 0.4306641, 0.5527344, 0.7900391, 
    0.9130859, 0.9091797, _, 0.5673828, 0.480957, 0.5458984, 0.440918, 
    0.3276367, 0.3911133, 0.4750977 ;

 lat = 25.625, 26.875, 28.125, 29.375, 30.625, 31.875, 33.125, 34.375, 
    35.625, 36.875, 38.125, 39.375 ;

 lat_bnds =
  25, 26.25,
  26.25, 27.5,
  27.5, 28.75,
  28.75, 30,
  30, 31.25,
  31.25, 32.5,
  32.5, 33.75,
  33.75, 35,
  35, 36.25,
  36.25, 37.5,
  37.5, 38.75,
  38.75, 40 ;

 lon = -89.375, -88.125, -86.875, -85.625, -84.375, -83.125, -81.875, 
    -80.625, -79.375, -78.125, -76.875, -75.625, -74.375, -73.125, -71.875, 
    -70.625 ;

 lon_bnds =
  -90, -88.75,
  -88.75, -87.5,
  -87.5, -86.25,
  -86.25, -85,
  -85, -83.75,
  -83.75, -82.5,
  -82.5, -81.25,
  -81.25, -80,
  -80, -78.75,
  -78.75, -77.5,
  -77.5, -76.25,
  -76.25, -75,
  -75, -73.75,
  -73.75, -72.5,
  -72.5, -71.25,
  -71.25, -70 ;

 time = 1079308800 ;

 time_bnds =
  1079308800, 1079308800 ;
}
netcdf ref {
dimensions:
	lat = 5 ;
	latv = 2 ;
	lon = 5 ;
	lonv = 2 ;
variables:
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:fullpath = "YDim:EOSGRID" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:fullpath = "XDim:EOSGRID" ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	float time_matched_difference(lat, lon) ;
		time_matched_difference:_FillValue = 1.e+15f ;
		time_matched_difference:missing_value = 1.e+15f ;
		time_matched_difference:fmissing_value = 1.e+15f ;
		time_matched_difference:vmin = -1.e+30f ;
		time_matched_difference:vmax = 1.e+30f ;
		time_matched_difference:fullpath = "/EOSGRID/Data Fields/RH" ;
		time_matched_difference:standard_name = "relative_humidity" ;
		time_matched_difference:quantity_type = "Atmospheric Moisture" ;
		time_matched_difference:product_short_name = "MAI3CPASM" ;
		time_matched_difference:product_version = "5.2.0" ;
		time_matched_difference:long_name = "Relative Humidity, Instantaneous" ;
		time_matched_difference:units = "fraction" ;
		time_matched_difference:cell_methods = " time: point time: mean Height: mean" ;
		time_matched_difference:coordinates = "lat lon" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:temporal_resolution = "3-hourly" ;
		:NCO = "\"4.5.3\"" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Fri Nov 11 18:21:15 2016: ncks -O -x -v time,time_bnds timeAvgDiffMap.MAT3CPRAD_5_2_0_CLOUD.1000hPa+MAI3CPASM_5_2_0_RH.1000hPa.20040315-20040315.83W_30N_77W_35N.nc timeAvgDiffMap.MAT3CPRAD_5_2_0_CLOUD.1000hPa+MAI3CPASM_5_2_0_RH.1000hPa.20040315-20040315.83W_30N_77W_35N.nc\n",
			"Fri Nov 11 18:21:15 2016: ncwa -O -o timeAvgDiffMap.MAT3CPRAD_5_2_0_CLOUD.1000hPa+MAI3CPASM_5_2_0_RH.1000hPa.20040315-20040315.83W_30N_77W_35N.nc -v time_matched_difference -a time timeAvgDiffMap.MAT3CPRAD_5_2_0_CLOUD.1000hPa+MAI3CPASM_5_2_0_RH.1000hPa.20040315-20040315.83W_30N_77W_35N.nc\n",
			"Fri Nov 11 18:21:15 2016: ncdiff -O ./fileszuePk.txt.1.timeavg.nc ./fileszuePk.txt.0.timeavg.nc timeAvgDiffMap.MAT3CPRAD_5_2_0_CLOUD.1000hPa+MAI3CPASM_5_2_0_RH.1000hPa.20040315-20040315.83W_30N_77W_35N.nc\n",
			"Fri Nov 11 18:21:15 2016: ncrename -v MAI3CPASM_5_2_0_RH,time_matched_difference -O -o ./fileszuePk.txt.1.timeavg.nc ./fileszuePk.txt.1.timeavg.nc\n",
			"Fri Nov 11 18:21:14 2016: ncra -D 2 -H -O -o ./fileszuePk.txt.1.timeavg.nc -d lat,30.351600,35.976600 -d lon,-83.671900,-77.343700 -d Height,1000.000000,1000.000000" ;
		:start_time = "2004-03-15T00:00:00Z" ;
		:end_time = "2004-03-15T02:59:59Z" ;
		:userstartdate = "2004-03-15T00:00:00Z" ;
		:userenddate = "2004-03-15T02:59:59Z" ;
data:

 lat = 30.625, 31.875, 33.125, 34.375, 35.625 ;

 lat_bnds =
  30, 31.25,
  31.25, 32.5,
  32.5, 33.75,
  33.75, 35,
  35, 36.25 ;

 lon = -83.125, -81.875, -80.625, -79.375, -78.125 ;

 lon_bnds =
  -83.75, -82.5,
  -82.5, -81.25,
  -81.25, -80,
  -80, -78.75,
  -78.75, -77.5 ;

 time_matched_difference =
  0.4755859, 0.6396484, 0.7216797, 0.6279297, 0.6865234,
  0.5810547, 0.6914062, 0.7900391, 0.7646484, 0.7763672,
  0.6386719, 0.640625, 0.6777344, 0.7539062, 0.7148438,
  _, 0.6796875, 0.6425781, 0.6738281, 0.6982422,
  _, _, _, 0.6298828, 0.6279297 ;
}
