# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Catalog.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::Catalog') }

# Define the URL for GIOVANNI catalog
my $catalogUrl = $ENV{GIOVANNI_CATALOG}
    || 'http://aesir.gesdisc.eosdis.nasa.gov/aesir_solr/TS1';
my $catalog = Giovanni::Catalog->new( { URL => $catalogUrl } );

# Test Case: Get info for five data fields that exist
my @fields
    = qw(GSSTFM_3_SET1_INT_ST_vec MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean NLDAS_NOAH0125_H_002_soilm0_10cm MAT3CPRAD_5_2_0_CLOUD);

# Reference result
my $refField = {
    'GSSTFM_3_SET1_INT_ST_vec' => {
        'accessName' => 'SET1_INT_STu,SET1_INT_STv',
        'sampleOpendap' =>
            'http://measures.gsfc.nasa.gov/opendap/hyrax/GSSTF/GSSTFM.3/1987/GSSTFM.3.1987.07.01.he5',
        'dataProductEndDateTime'     => '2008-12-31T23:59:59Z',
        'long_name'                  => 'Wind Stress Vector',
        'dataFieldUnitsValue'        => 'N/m^^2',
        'fillValueFieldName'         => '_FillValue',
        'accessFormat'               => 'netCDF',
        'north'                      => '90.0',
        'accessMethod'               => 'OPeNDAP',
        'endTime'                    => '2008-12-31T23:59:59Z',
        'dataProductStartTimeOffset' => '1',
        'url' =>
            'http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Goddard%20Satellite-Based%20Surface%20Turbulent%20Fluxes%2C%200.25x0.25%20deg%2C%20Monthly%20Grid%2C%20V3%2C%20(GSSTFM)%2C%20at%20GES%20DISC%20V3;agent_id=OPeNDAP;variables=SET1_INT_STu,SET1_INT_STv',
        'startTime'                     => '1987-07-01T00:00:00Z',
        'responseFormat'                => 'netCDF',
        'dataProductEndTimeOffset'      => '0',
        'south'                         => '-90.0',
        'dataProductTimeInterval'       => 'monthly',
        'dataProductTimeFrequency'      => 1,
        'west'                          => '-180.0',
        'dataProductVersion'            => '3',
        'east'                          => '180.0',
        'vectorComponents'              => 'SET1_INT_STu,SET1_INT_STv',
        'sdsName'                       => 'SET1_INT_ST_vec',
        'searchIntervalDays'            => '10000.0',
        'dataProductShortName'          => 'GSSTFM',
        'resolution'                    => '0.25 deg.',
        'quantity_type'                 => 'Wind',
        'dataProductBeginDateTime'      => '1987-07-01T00:00:00Z',
        'dataFieldStandardName'         => '',
        'dataProductPlatformInstrument' => 'SSMI',
        'accumulatable'                 => 'false',
        'latitudeResolution'            => '0.25',
        'longitudeResolution'           => '0.25',
        'spatialResolutionUnits'        => 'deg.',
        'timeIntvRepPos'                => 'start',
        'valuesDistribution'            => 'linear',
        'oddxDims'                      => '<opt>
  <_LAT_DIMS name="lat" offset="0" scaleFactor="1" size="720" />
  <_LAT_LONG_INDEXES>0</_LAT_LONG_INDEXES>
  <_LAT_LONG_INDEXES>719</_LAT_LONG_INDEXES>
  <_LAT_LONG_INDEXES>0</_LAT_LONG_INDEXES>
  <_LAT_LONG_INDEXES>1439</_LAT_LONG_INDEXES>
  <_LONG_DIMS name="lon" offset="0" scaleFactor="1" size="1440" />
  <_VARIABLE_DIMS>
    <SET1_INT_STu maxind="719" name="lat" />
    <SET1_INT_STu maxind="1439" name="lon" />
    <SET1_INT_STv maxind="719" name="lat" />
    <SET1_INT_STv maxind="1439" name="lon" />
  </_VARIABLE_DIMS>
</opt>
',
    },
    'MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean' => {
        'accessName' => 'Optical_Depth_Land_And_Ocean_Mean',
        'sampleOpendap' =>
            'http://ladsweb.nascom.nasa.gov/opendap/allData/51/MYD08_D3/2002/185/MYD08_D3.A2002185.051.2008316015433.hdf.html',
        'nominalMin'             => '0.0',
        'nominalMax'             => '1.0',
        'dataProductEndDateTime' => '2038-01-19T03:14:07Z',
        'long_name'           => 'Aerosol Optical Depth 550 nm (Dark Target)',
        'dataFieldUnitsValue' => '1',
        'fillValueFieldName'  => '_FillValue',
        'accessFormat'        => 'netCDF',
        'north'               => '90.0',
        'accessMethod'        => 'OPeNDAP',
        'endTime'             => '2038-01-19T03:14:07Z',
        'dataProductStartTimeOffset' => '1',
        'url' =>
            'http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MODIS%2FAqua%20Aerosol%20Cloud%20Water%20Vapor%20Ozone%20Daily%20L3%20Global%201Deg%20CMG%20V051;agent_id=OPeNDAP;variables=Optical_Depth_Land_And_Ocean_Mean',
        'startTime'                => '2002-07-04T00:00:00Z',
        'responseFormat'           => 'netCDF',
        'dataProductEndTimeOffset' => '0',
        'south'                    => '-90.0',
        'dataProductTimeInterval'  => 'daily',
        'dataProductTimeFrequency' => 1,
        'searchIntervalDays'       => '365.0',
        'west'                     => '-180.0',
        'dataProductVersion'       => '051',
        'east'                     => '180.0',
        'sdsName'                  => 'Optical_Depth_Land_And_Ocean_Mean',
        'dataProductShortName'     => 'MYD08_D3',
        'resolution'               => '1 deg.',
        'quantity_type'            => 'Total Aerosol Optical Depth',
        'dataProductBeginDateTime' => '2002-07-04T00:00:00Z',
        'sld' =>
            '<slds><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_ylorbr_9_sld.xml" label="Yellow-Orange-Brown (Seq), 9"/><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/buylrd_div_12_panoply_sld.xml" label="Blue-Yellow-Red (Div), 12 (Source: Panoply)"/></slds>',
        'dataFieldStandardName'         => '',
        'dataProductPlatformInstrument' => 'MODIS-Aqua',
        'accumulatable'                 => 'false',
        'latitudeResolution'            => '1.0',
        'longitudeResolution'           => '1.0',
        'spatialResolutionUnits'        => 'deg.',
        'sampleFile'                    => '',
        'osdd'                          => '',
        'timeIntvRepPos'                => 'start',
        'valuesDistribution'            => 'linear',
    },
    'MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean' => {
        'accessName' => 'Optical_Depth_Land_And_Ocean_Mean',
        'sampleOpendap' =>
            'http://ladsweb.nascom.nasa.gov/opendap/allData/51/MOD08_D3/2000/061/MOD08_D3.A2000061.051.2010273210218.hdf.html',
        'nominalMin'             => '0.0',
        'nominalMax'             => '1.0',
        'dataProductEndDateTime' => '2038-01-19T03:14:07Z',
        'long_name'           => 'Aerosol Optical Depth 550 nm (Dark Target)',
        'dataFieldUnitsValue' => '1',
        'fillValueFieldName'  => '_FillValue',
        'accessFormat'        => 'netCDF',
        'north'               => '90.0',
        'accessMethod'        => 'OPeNDAP',
        'endTime'             => '2038-01-19T03:14:07Z',
        'dataProductStartTimeOffset' => '1',
        'url' =>
            'http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MODIS%2FTerra%20Aerosol%20Cloud%20Water%20Vapor%20Ozone%20Daily%20L3%20Global%201Deg%20CMG%20V051;agent_id=OPeNDAP;variables=Optical_Depth_Land_And_Ocean_Mean',
        'startTime'                => '2000-03-01T00:00:00Z',
        'responseFormat'           => 'netCDF',
        'dataProductEndTimeOffset' => '0',
        'south'                    => '-90.0',
        'dataProductTimeInterval'  => 'daily',
        'dataProductTimeFrequency' => 1,
        'searchIntervalDays'       => '365.0',
        'west'                     => '-180.0',
        'dataProductVersion'       => '051',
        'east'                     => '180.0',
        'sdsName'                  => 'Optical_Depth_Land_And_Ocean_Mean',
        'dataProductShortName'     => 'MOD08_D3',
        'resolution'               => '1 deg.',
        'quantity_type'            => 'Total Aerosol Optical Depth',
        'dataProductBeginDateTime' => '2000-03-01T00:00:00Z',
        'sld' =>
            '<slds><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_ylorbr_9_sld.xml" label="Yellow-Orange-Brown (Seq), 9"/></slds>',
        'dataFieldStandardName'         => '',
        'dataProductPlatformInstrument' => 'MODIS-Terra',
        'accumulatable'                 => 'false',
        'latitudeResolution'            => '1.0',
        'longitudeResolution'           => '1.0',
        'spatialResolutionUnits'        => 'deg.',
        'valuesDistribution'            => 'linear',
        'sampleFile'                    => '',
        'timeIntvRepPos'                => 'start',
        'osdd'                          => '',
    },
    'MAT3CPRAD_5_2_0_CLOUD' => {
        'accessFormat'          => 'netCDF',
        'accessMethod'          => 'OPeNDAP_TIMESPLIT',
        'accessName'            => 'CLOUD',
        'accumulatable'         => 'false',
        'dataFieldStandardName' => 'cloud_area_fraction_in_atmosphere_layer',
        'dataFieldUnitsValue'   => 'fraction',
        'dataProductBeginDateTime'      => '1979-01-01T00:00:00Z',
        'dataProductEndDateTime'        => '2038-01-19T03:14:07Z',
        'dataProductEndTimeOffset'      => '0',
        'dataProductPlatformInstrument' => 'MERRA Model',
        'dataProductShortName'          => 'MAT3CPRAD',
        'dataProductStartTimeOffset'    => '1',
        'dataProductTimeFrequency'      => '1',
        'dataProductTimeInterval'       => '3-hourly',
        'dataProductVersion'            => '5.2.0',
        'east'                          => '180.0',
        'endTime'                       => '2038-01-19T03:14:07Z',
        'fillValueFieldName'            => '_FillValue',
        'latitudeResolution'            => '1.25',
        'long_name'                     => '3D Cloud Fraction, time average',
        'longitudeResolution'           => '1.25',
        'north'                         => '90.0',
        'oddxDims'                      => '<opt _TIME_SPLITTABLE_DIMENSION="TIME">
  <_LAT_DIMS name="YDim" offset="0" scaleFactor="1" size="144" />
  <_LAT_LONG_INDEXES>0</_LAT_LONG_INDEXES>
  <_LAT_LONG_INDEXES>143</_LAT_LONG_INDEXES>
  <_LAT_LONG_INDEXES>0</_LAT_LONG_INDEXES>
  <_LAT_LONG_INDEXES>287</_LAT_LONG_INDEXES>
  <_LONG_DIMS name="XDim" offset="0" scaleFactor="1" size="288" />
  <_TIME_DIMS>
    <TIME boundsVarName="TIME_bnds" boundsVarSize="8" boundsVarUnits="minutes since 1979-01-01 01:30:00" size="8" units="minutes since 1979-01-01 01:30:00" />
  </_TIME_DIMS>
  <_TIME_INDEXES>
    <TIME>
      <indexes>0</indexes>
      <indexes>0</indexes>
      <labels>MERRA100.prod.assim.tavg3_3d_rad_Cp.19790101.hdf.ncml.19790101013000.nc</labels>
    </TIME>
  </_TIME_INDEXES>
  <_VARIABLE_DIMS>
    <CLOUD maxind="7" name="TIME" />
    <CLOUD maxind="41" name="Height" />
    <CLOUD maxind="143" name="YDim" />
    <CLOUD maxind="287" name="XDim" />
  </_VARIABLE_DIMS>
</opt>
',
        'osdd'                          => '',
        'quantity_type'                 => 'Cloud Fraction',
        'resolution'                    => '1.25 deg.',
        'responseFormat'                => 'netCDF',
        'sampleFile'                    => '',
        'sampleOpendap' =>
            'http://goldsmr3.sci.gsfc.nasa.gov/opendap/ncml/MERRA/MAT3CPRAD.5.2.0/1979/01/MERRA100.prod.assim.tavg3_3d_rad_Cp.19790101.hdf.ncml.html',
        'sdsName' => 'CLOUD',
        'searchIntervalDays'     => '31.0',
        'sld' =>
            '<slds><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/spectral_div_11_inv_sld.xml" label="Spectral, Inverted (Div), 11"/></slds>',
        'south'                  => '-90.0',
        'spatialResolutionUnits' => 'deg.',
        'startTime'              => '1979-01-01T00:00:00Z',
        'timeIntvRepPos'         => 'middle',
        'url' =>
            'http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MERRA%203D%20IAU%20Diagnostic%2C%20Radiation%2C%20Time%20average%203-hourly%20(1.25x1.25L42)%20V5.2.0;agent_id=OPeNDAP_TIMESPLIT;variables=CLOUD',
        'valuesDistribution' => 'linear',
        'west'               => '-180.0',
        'zDimName'           => 'Height',
        'zDimUnits'          => 'hPa',
        'zDimValues' =>
            '1000 975 950 925 900 875 850 825 800 775 750 725 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 40 30 20 10 7 5 4 3 2 1 0.7 0.5 0.4 0.3 0.1'
    },
    'NLDAS_NOAH0125_H_002_soilm0_10cm' => {
        'accessName' =>
            'Soil_moisture_content/layer_between_two_depths_below_surface[0]',
        'sampleOpendap' =>
            'https://hydro1.sci.gsfc.nasa.gov/thredds/dodsC/NLDAS_NOAH0125_H.002/1979/002/NLDAS_NOAH0125_H.A19790102.0100.002.grb.html',
        'deflationLevel'         => 1,
        'dataProductEndDateTime' => '2038-01-19T03:14:07Z',
        'searchIntervalDays'     => '30.0',
        'long_name'              => 'Soil Moisture Content Layer 1 (0-10 cm)',
        'dataFieldUnitsValue'    => 'kg/m^2',
        'fillValueFieldName'     => 'missing_value',
        'accessFormat'           => 'native',
        'north'                  => '53.0',
        'accessMethod'           => 'OPeNDAP',
        'endTime'                => '2038-01-19T03:14:07Z',
        'dataProductStartTimeOffset' => '1',
        'url' =>
            'http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=native;dataset_id=NLDAS%20Noah%20Land%20Surface%20Model%20L4%20Hourly%200.125%20x%200.125%20degree%20V002;agent_id=OPeNDAP;variables=Soil_moisture_content/layer_between_two_depths_below_surface[0]',
        'startTime'                => '1979-01-02T00:00:00Z',
        'parameterDepth'           => '0-10',
        'responseFormat'           => 'DAP',
        'dataProductEndTimeOffset' => '0',
        'south'                    => '25.0',
        'dataProductTimeInterval'  => 'hourly',
        'dataProductTimeFrequency' => 1,
        'west'                     => '-125.0',
        'dataProductVersion'       => '002',
        'east'                     => '-67.0',
        'sdsName'                  => 'soilm0_10cm',
        'dataProductShortName'     => 'NLDAS_NOAH0125_H',
        'parameterDepthUnit'       => 'cm',
        'resolution'               => '0.125 deg.',
        'quantity_type'            => 'Soil Moisture 0-10',
        'dataProductBeginDateTime' => '1979-01-02T00:00:00Z',
        'sld' =>
            '<slds><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_ylgnbu_9_sld.xml" label="Yellow-Green-Blue (Seq), 9"/><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_ylgn_9_sld.xml" label="Yellow-Green (Seq), 9"/><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/time_matched_difference_sld.xml" label="Blue-Yellow-Red (Div), 12"/><sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/outgoing_longwave_radiation_sld.xml" label="White-Blue-Red-Yellow (Seq), 65"/></slds>',
        'dataFieldStandardName'         => '',
        'dataProductPlatformInstrument' => 'NLDAS Model',
        'accumulatable'                 => 'false',
        'latitudeResolution'            => '0.125',
        'longitudeResolution'           => '0.125',
        'spatialResolutionUnits'        => 'deg.',
        'valuesDistribution'            => 'linear',
        'sampleFile'                    => '',
        'timeIntvRepPos'                => 'start',
        'osdd'                          => '',
        'oddxDims'                      => '<opt>
  <_LAT_DIMS name="lat" offset="0" scaleFactor="1" size="224" />
  <_LAT_LONG_INDEXES>0</_LAT_LONG_INDEXES>
  <_LAT_LONG_INDEXES>223</_LAT_LONG_INDEXES>
  <_LAT_LONG_INDEXES>0</_LAT_LONG_INDEXES>
  <_LAT_LONG_INDEXES>463</_LAT_LONG_INDEXES>
  <_LONG_DIMS name="lon" offset="0" scaleFactor="1" size="464" />
  <_TIME_DIMS>
    <time size="1" units="hours since 1979-01-02T01:00:00Z" />
    <time1 boundsVarName="time1_bounds" boundsVarSize="1" boundsVarUnits="hours since 1979-01-02T01:00:00Z" size="1" units="hours since 1979-01-02T01:00:00Z" />
  </_TIME_DIMS>
  <_TIME_INDEXES>
    <time>
      <indexes>0</indexes>
      <indexes>0</indexes>
    </time>
    <time1>
      <indexes>0</indexes>
      <indexes>0</indexes>
    </time1>
  </_TIME_INDEXES>
  <_VARIABLE_DIMS>
    <Soil_moisture_content maxind="0" name="time" />
    <Soil_moisture_content maxind="5" name="layer_between_two_depths_below_surface" selectedIndexes="[0]" />
    <Soil_moisture_content maxind="223" name="lat" />
    <Soil_moisture_content maxind="463" name="lon" />
  </_VARIABLE_DIMS>
</opt>
'
     }
};

# Get the data field info
my $field = $catalog->getDataFieldInfo( { FIELDS => \@fields } );

# Compare structures
is_deeply( $field, $refField,
    "Comparison of data field records (all exist) from Giovanni catalog" );

# Test Case: Only one of the two data fields exists
@fields = qw(MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean xyz);

# Reference result
foreach my $key ( keys %$refField ) {
    delete $refField->{$key}
        unless $key eq 'MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean';
}

# Get the data field info
$field = $catalog->getDataFieldInfo( { FIELDS => \@fields } );

# Compare structures
is_deeply( $field, $refField,
    "Comparison of data field records (one of the two non-existent) from Giovanni catalog"
);
