#$Id: Giovanni-Algorithm-CorrelationWrapper.t,v 1.19 2014/05/01 13:53:20 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-CorrelationWrapper.t'

#########################
use strict;
use warnings;
use File::Temp qw/tempdir/;
use File::Path;
use Test::More tests => 19;
BEGIN { use_ok('Giovanni::Algorithm::CorrelationWrapper') }

#########################

my $timestamp
    = Giovanni::Algorithm::CorrelationWrapper::dataday2timestamp( '2001',
    '31' );
is( $timestamp, "2001-01-31T00:00:00Z" );

my ( $var, $zdim, $zval, $zunits )
    = Giovanni::Algorithm::CorrelationWrapper::parse_data_field(
    "Optical_Depth");
is( $var, "Optical_Depth", "parse 2D field" );

( $var, $zdim, $zval, $zunits )
    = Giovanni::Algorithm::CorrelationWrapper::parse_data_field(
    "Temperature_A,TempPrsLvls_A=500hPa");
is( $var,  "Temperature_A", "parse 3D field" );
is( $zval, 500,             "parse 3D field for value" );

my $dir = tempdir( CLEANUP => 0 );

############  Daily File Matchup Test ###################
my $dailyFileListFile = daily_file_info($dir);
ok( -e $dailyFileListFile, "Input file written" ) or die;
my ( $dailyVarInfoX, $dailyVarInfoY ) = daily_var_info($dir);
ok( -e $dailyVarInfoX, "First var info written" )  or die;
ok( -e $dailyVarInfoY, "Second var info written" ) or die;

# Run the command
my $fileListFile = "$dir/files.txt";
my $x_field      = "SWDB_L310_004_aerosol_optical_thickness_550_land_ocean";
my $y_field      = "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean";
my @variables    = ( $x_field, $y_field );
my ( $vartext, $use_time )
    = Giovanni::Algorithm::CorrelationWrapper::mk_file_list(
    $dailyFileListFile, $x_field, $dailyVarInfoX, $y_field, $dailyVarInfoY,
    $fileListFile );
is( $vartext,
    'Aerosol Optical Depth 550 nm daily 1 deg. [SeaWiFS SWDB_L310 v004] vs. Aerosol Optical Depth 550 nm (Dark Target) daily 1 deg. [MODIS-Aqua MYD08_D3 v051]'
);
my $outfile
    = Giovanni::Algorithm::CorrelationWrapper::mk_output_filename( $dir,
    \@variables, '2011-12-31', '2012-01-04T23:59:59Z', $use_time );
is( $outfile,
    "$dir/correlation.SWDB_L310_004_aerosol_optical_thickness_550_land_ocean+MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20111231-20120104.nc"
);

# Check to see if we got output
ok( $fileListFile && -s $fileListFile, "Got file_list file" );

# Check the output itself
open IN, $fileListFile or die "Cannot open $fileListFile: $!";
local ($/) = undef;
my $gotFileList = <IN>;
close IN;
is( $gotFileList, daily_file_list() );

############  Hourly File Matchup Test ###################

$x_field   = "NLDAS_FORA0125_H_002_apcpsfc";
$y_field   = "NLDAS_NOAH0125_H_002_evpsfc";
@variables = ( $x_field, $y_field );
my $hourlyFileListFile = hourly_file_info($dir);
ok( -e $hourlyFileListFile, "Input file written" );
my ( $hourlyVarInfoX, $hourlyVarInfoY ) = hourly_var_info($dir);
ok( -e $hourlyVarInfoX, "First var info written" )  or die;
ok( -e $hourlyVarInfoY, "Second var info written" ) or die;

# Run the command
$fileListFile = "$dir/files.txt";
( $vartext, $use_time )
    = Giovanni::Algorithm::CorrelationWrapper::mk_file_list(
    $hourlyFileListFile, $x_field, $hourlyVarInfoX, $y_field, $hourlyVarInfoY,
    $fileListFile );
is( $vartext,
    'Precipitation Total hourly 0.125 deg. [NLDAS Model NLDAS_FORA0125_H v002] kg/m^2 vs. Evapotranspiration Total hourly 0.125 deg. [NLDAS Model NLDAS_NOAH0125_H v002] kg/m^2'
);
$outfile = Giovanni::Algorithm::CorrelationWrapper::mk_output_filename( $dir,
    \@variables, '2012-01-01T00:00:00Z', '2012-01-01T05:00:00Z', $use_time );
is( $outfile,
    "$dir/correlation.NLDAS_FORA0125_H_002_apcpsfc+NLDAS_NOAH0125_H_002_evpsfc.20120101T000000-20120101T050000.nc",
    "Output filename test"
);

# Check to see if we got output
ok( $fileListFile && -s $fileListFile, "Got file_list file" );

# Check the output itself
open IN, $fileListFile or die "Cannot open $fileListFile: $!";
local ($/) = undef;
$gotFileList = <IN>;
close IN;
is( $gotFileList, hourly_file_list() );

################### Cleanup #####################
rmtree($dir) unless $ENV{'SAVE_TEST_FILES'};

sub daily_file_list {
    my $answer = << "EOF";
/var/tmp/www/TS2/giovanni/mySessionDir/formatted.SWDB_L310_HDF4_003_aerosol_optical_thickness_550_land_ocean.20111231.nc /var/tmp/www/TS2/giovanni/mySessionDir/formatted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20111231.nc
/var/tmp/www/TS2/giovanni/mySessionDir/formatted.SWDB_L310_HDF4_003_aerosol_optical_thickness_550_land_ocean.20120101.nc /var/tmp/www/TS2/giovanni/mySessionDir/formatted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20120101.nc
/var/tmp/www/TS2/giovanni/mySessionDir/formatted.SWDB_L310_HDF4_003_aerosol_optical_thickness_550_land_ocean.20120104.nc /var/tmp/www/TS2/giovanni/mySessionDir/formatted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20120104.nc
EOF
    return $answer;
}

sub daily_file_info {
    my $dir  = shift;
    my $file = "$dir/input_file_list.txt";
    open( OUT, '>', $file ) or die "Cannot open $file: $!\n";
    print OUT << "EOF";
<data>
  <dataFileList id="SWDB_L310_004_aerosol_optical_thickness_550_land_ocean" >
    <dataFile>/var/tmp/www/TS2/giovanni/mySessionDir/formatted.SWDB_L310_HDF4_003_aerosol_optical_thickness_550_land_ocean.20111231.nc</dataFile>
    <dataFile>/var/tmp/www/TS2/giovanni/mySessionDir/formatted.SWDB_L310_HDF4_003_aerosol_optical_thickness_550_land_ocean.20120101.nc</dataFile>
    <dataFile>/var/tmp/www/TS2/giovanni/mySessionDir/formatted.SWDB_L310_HDF4_003_aerosol_optical_thickness_550_land_ocean.20120103.nc</dataFile>
    <dataFile>/var/tmp/www/TS2/giovanni/mySessionDir/formatted.SWDB_L310_HDF4_003_aerosol_optical_thickness_550_land_ocean.20120104.nc</dataFile>
  </dataFileList>
  <dataFileList id="MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean" >
    <dataFile>/var/tmp/www/TS2/giovanni/mySessionDir/formatted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20111231.nc</dataFile>
    <dataFile>/var/tmp/www/TS2/giovanni/mySessionDir/formatted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20120101.nc</dataFile>
    <dataFile>/var/tmp/www/TS2/giovanni/mySessionDir/formatted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20120102.nc</dataFile>
    <dataFile>/var/tmp/www/TS2/giovanni/mySessionDir/formatted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20120104.nc</dataFile>
  </dataFileList>
</data>
EOF
    close OUT;
    return $file;
}

sub daily_var_info {
    my $dir   = shift;
    my $file1 = "$dir/input_var_info1.txt";
    open( OUT, '>', $file1 ) or die "Cannot open $file1: $!\n";
    print OUT << "EOF";
<varList>
  <var id="SWDB_L310_004_aerosol_optical_thickness_550_land_ocean" dataProductEndDateTime="2010-12-11T23:59:59.999Z" long_name="Aerosol Optical Depth 550 nm" dataFieldUnitsValue="1" fillValueFieldName="_FillValue" accumulatable="false" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2010-12-11T23:59:59.999Z" dataProductStartTimeOffset="1" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=SeaWiFS%20Deep%20Blue%20Aerosol%20Optical%20Depth%20and%20Angstrom%20Exponent%20Daily%20Level%203%20Data%20Gridded%20at%201.0%20Degrees%20V004;agent_id=OPeNDAP;variables=aerosol_optical_thickness_550_land_ocean" startTime="1997-09-03T00:00:00Z" responseFormat="netCDF" dataProductEndTimeOffset="0" south="-90.0" dataProductTimeInterval="daily" west="-180.0" dataProductVersion="004" east="180.0" sdsName="aerosol_optical_thickness_550_land_ocean" dataProductShortName="SWDB_L310" dataProductPlatformInstrument="SeaWiFS" resolution="1 deg." quantity_type="Total Aerosol Optical Depth" dataProductBeginDateTime="1997-09-03T00:00:00Z" dataFieldStandardName="atmosphere_optical_thickness_due_to_ambient_aerosol status_flag">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/aod_sld.xml" label="Aerosol Optical Depth Color Map"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/aod_panoply_diff_sld.xml" label="Aerosol Optical Depth Rainbow Color Map"/>
    </slds>
  </var>
</varList>   
EOF
    close OUT;
    my $file2 = "$dir/input_var_info2.txt";
    open( OUT, '>', $file2 ) or die "Cannot open $file2: $!\n";
    print OUT << "EOF";
<varList>
  <var id="MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean" dataProductEndDateTime="2038-01-19T03:14:07Z" long_name="Aerosol Optical Depth 550 nm (Dark Target)" dataFieldUnitsValue="1" fillValueFieldName="_FillValue" accumulatable="false" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" dataProductStartTimeOffset="1" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MODIS%2FAqua%20Aerosol%20Cloud%20Water%20Vapor%20Ozone%20Daily%20L3%20Global%201Deg%20CMG%20V051;agent_id=OPeNDAP;variables=Optical_Depth_Land_And_Ocean_Mean" startTime="2002-07-04T00:00:00Z" responseFormat="netCDF" dataProductEndTimeOffset="0" south="-90.0" dataProductTimeInterval="daily" west="-180.0" dataProductVersion="051" east="180.0" sdsName="Optical_Depth_Land_And_Ocean_Mean" dataProductShortName="MYD08_D3" dataProductPlatformInstrument="MODIS-Aqua" resolution="1 deg." quantity_type="Total Aerosol Optical Depth" dataProductBeginDateTime="2002-07-04T00:00:00Z" dataFieldStandardName="">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/aod_sld.xml" label="Aerosol Optical Depth Color Map"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/aod_panoply_diff_sld.xml" label="Aerosol Optical Depth Rainbow Color Map"/>
    </slds>
  </var>
</varList>
EOF
    close OUT;
    return ( $file1, $file2 );
}

sub hourly_file_list {
    my $answer = << "EOF";
output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T000000.nc output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T000000.nc
output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T010000.nc output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T010000.nc
output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T020000.nc output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T020000.nc
output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T030000.nc output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T030000.nc
output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T040000.nc output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T040000.nc
output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T050000.nc output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T050000.nc
EOF
    return $answer;
}

sub hourly_file_info {
    my $dir  = shift;
    my $file = "$dir/input_file_list.txt";
    open( OUT, '>', $file ) or die "Cannot open $file: $!\n";
    print OUT << "EOF";
<?xml version="1.0" encoding="UTF-8"?>
<data>
<dataFileList id="NLDAS_FORA0125_H_002_apcpsfc" >
    <dataFile>output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T000000.nc</dataFile>
    <dataFile>output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T010000.nc</dataFile>
    <dataFile>output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T020000.nc</dataFile>
    <dataFile>output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T030000.nc</dataFile>
    <dataFile>output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T040000.nc</dataFile>
    <dataFile>output_scrub/scrubbed.NLDAS_FORA0125_H_002_Precipitation_hourly_total.20120101T050000.nc</dataFile>
</dataFileList>
<dataFileList id="NLDAS_NOAH0125_H_002_evpsfc">
  <dataFile>output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T010000.nc</dataFile>
  <dataFile>output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T020000.nc</dataFile>
  <dataFile>output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T030000.nc</dataFile>
  <dataFile>output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T040000.nc</dataFile>
  <dataFile>output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T050000.nc</dataFile>
  <dataFile>output_scrub/scrubbed.NLDAS_NOAH0125_H_002_Evaporation.20120101T000000.nc</dataFile>
</dataFileList></data>
EOF
    close OUT;
    return $file;
}

sub hourly_var_info {
    my $dir   = shift;
    my $file1 = "$dir/input_var_info1.txt";
    open( OUT, '>', $file1 ) or die "Cannot open $file1: $!\n";
    print OUT << "EOF";
<varList>
  <var id="NLDAS_FORA0125_H_002_apcpsfc" dataProductEndDateTime="2038-01-19T03:14:07Z" long_name="Precipitation Total" dataFieldUnitsValue="kg/m^2" fillValueFieldName="missing_value" accumulatable="false" accessFormat="native" north="53.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" dataProductStartTimeOffset="1" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=native;dataset_id=NLDAS%20Primary%20Forcing%20Data%20L4%20Hourly%200.125%20x%200.125%20degree%20V002;agent_id=OPeNDAP;variables=Precipitation_hourly_total" startTime="1979-01-01T00:00:00Z" responseFormat="DAP" dataProductEndTimeOffset="0" south="25.0" dataProductTimeInterval="hourly" west="-125.0" dataProductVersion="002" east="-67.0" sdsName="apcpsfc" dataProductShortName="NLDAS_FORA0125_H" dataProductPlatformInstrument="NLDAS Model" resolution="0.125 deg." quantity_type="Precipitation" dataProductBeginDateTime="1979-01-01T00:00:00Z" dataFieldStandardName="">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue, Sequential, 9-Steps"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/time_matched_difference_sld.xml" label="Correlation"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/rainfall_sld.xml" label="Rainfall"/>
    </slds>
  </var>
</varList>
EOF
    close OUT;
    my $file2 = "$dir/input_var_info2.txt";
    open( OUT, '>', $file2 ) or die "Cannot open $file2: $!\n";
    print OUT << "EOF";
<varList>
  <var id="NLDAS_NOAH0125_H_002_evpsfc" dataProductEndDateTime="2038-01-19T03:14:07Z" long_name="Evapotranspiration Total" dataFieldUnitsValue="kg/m^2" fillValueFieldName="missing_value" accumulatable="false" accessFormat="native" north="53.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" dataProductStartTimeOffset="1" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=native;dataset_id=NLDAS%20Noah%20Land%20Surface%20Model%20L4%20Hourly%200.125%20x%200.125%20degree%20V002;agent_id=OPeNDAP;variables=Evaporation" startTime="1979-01-02T00:00:00Z" responseFormat="DAP" dataProductEndTimeOffset="0" south="25.0" dataProductTimeInterval="hourly" west="-125.0" dataProductVersion="002" east="-67.0" sdsName="evpsfc" dataProductShortName="NLDAS_NOAH0125_H" dataProductPlatformInstrument="NLDAS Model" resolution="0.125 deg." quantity_type="Evapotranspiration" dataProductBeginDateTime="1979-01-02T00:00:00Z" dataFieldStandardName="">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/evapotranspiration_sld.xml" label="Evapotranspiration"/>
    </slds>
  </var>
</varList>
EOF
    close OUT;
    return ( $file1, $file2 );
}
