# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl EDDA-Compare.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 20;
use File::Temp qw/ tempfile tempdir /;
BEGIN { use_ok('EDDA::Compare') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Read _DATA_ section into temporary files
my $workingdir = tempdir(CLEANUP => 1);
ok((-e $workingdir), "Working directory $workingdir created");
my $filename;
while (<DATA>) {
    if ($_ =~ /^FILE=/) {
        $filename = $_;
        $filename =~ s/^FILE=//;
        chomp($filename);
        $filename = "$workingdir/$filename";
        open FH, ">", "$filename";
        next;
    }
    if ($_ =~ /^ENDFILE/) {
        close(FH);
        ok ((-f $filename), "Created \"$filename\"");
        next;
    }
    my $line = $_;
    $line =~ s/WORKINGDIR/$workingdir/;
    print FH $line;
}

my $originalFile = "$workingdir/AIRX3STD_006_TotCO_A_original";
my $updatedFile  = "$workingdir/AIRX3STD_006_TotCO_A_updated";

# Test object creation and detection of missing parameters.
# Object should be created, and methods onError and errorMessage should
# return values.
my $comparer = EDDA::Compare->new();
ok($comparer, "Created Compare object with no parameters");
ok($comparer->onError, "Missing parameters detected when object created");
ok($comparer->errorMessage, "Has error message: " . $comparer->errorMessage);
$comparer = EDDA::Compare->new(ORIGINAL_XML_FILE => $originalFile);
ok($comparer, "Created Compare object with one parameter");
ok($comparer->onError, "Missing parameter detected when object created");
ok($comparer->errorMessage, "Has error message: " . $comparer->errorMessage);

# Test object creation with required set of parameters.
$comparer = EDDA::Compare->new(ORIGINAL_XML_FILE => $originalFile, UPDATED_XML_FILE => $updatedFile);
ok($comparer, "Created Compare object with two parameters");
ok(!$comparer->onError, "No error detected when object created");

# Test comparison of values for xpath where the values are known to differ
my $xpath = '/dataField/dataFieldLongName';
ok($comparer->originalHasXpath($xpath), "Found $xpath in original");
ok($comparer->updatedHasXpath($xpath), "Found $xpath in update");
my @differences = $comparer->compareSingleValues($xpath);
ok(@differences, "Found differences in $xpath");
ok(@differences == 2, "Differences in $xpath returned 2 values");

# Test comparison of values for xpath where the values are known to be the same
my $xpath2 = '/dataField/dataFieldSdsName';
ok($comparer->originalHasXpath($xpath), "Found $xpath2 in original");
ok($comparer->updatedHasXpath($xpath), "Found $xpath2 in update");
@differences = $comparer->compareSingleValues($xpath2);
ok(!@differences, "Found no differences in $xpath2");

# Test comparison of all values
my $allDifferences = $comparer->compareAll;
my $str;
#my $str = join("\n", @allDifferences);
foreach my $key (sort keys %$allDifferences) {
    $str .= "$key: " . join("\n", @{$allDifferences->{$key}}) . "\n";
}
ok($allDifferences, "Found all differences: \n$str");

1;

###########################################################################
__DATA__
FILE=AIRX3STD_006_TotCO_A_original
<?xml version="1.0"?>
<dataField>
  <dataFieldId>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
      <regex>[a-zA-Z0-9_]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores.</validationText>
    </constraints>
    <value>AIRX3STD_006_TotCO_A</value>
  </dataFieldId>
  <dataFieldG3Id>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
      <regex>[a-zA-Z0-9_]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores.</validationText>
    </constraints>
    <value/>
  </dataFieldG3Id>
  <dataFieldActive>
    <type>boolean</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
      <regex>^true$|^false$</regex>
      <validationText>The value must be either 'true' or 'false'</validationText>
    </constraints>
    <value>true</value>
  </dataFieldActive>
  <dataFieldProductId>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
      <regex>[a-zA-Z0-9_.-]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores, periods, and hyphens.</validationText>
    </constraints>
    <value>AIRX3STD.006</value>
  </dataFieldProductId>
  <dataFieldSdsName>
    <type>text</type>
    <label>G3 SDS Name</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
      <regex>[a-zA-Z0-9_-]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores, and hyphens.</validationText>
    </constraints>
    <example>Angstrom_Exponent_1_Ocean_QA_Mean</example>
    <value>TotCO_A</value>
  </dataFieldSdsName>
  <dataFieldShortName>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
      <regex><![CDATA[[a-zA-Z0-9 _.,)(@/%+-]+$]]></regex>
      <validationText>The value must consist only of letters, digits, spaces, underscores, periods, commas, parentheses, @, slashes, percents, pluses, and hyphens.</validationText>
    </constraints>
    <value/>
  </dataFieldShortName>
  <dataFieldLongName>
    <type>text</type>
    <label>Long Name</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
      <regex><![CDATA[[a-zA-Z0-9 _.,:)(&/%><=+-]+$]]></regex>
      <validationText>The value must consist only of letters, digits, spaces, underscores, periods, commas, colons, parentheses, ampersands, slashes, percents, less-thans, greater-thans, equals, pluses, and hyphens.</validationText>
    </constraints>
    <example>Aerosol Optical Depth 550 nm (Dark Target), MODIS-Aqua, 1 x 1 deg.</example>
    <value>Carbon Monoxide, Total Column, daytime (ascending), AIRS, 1 x 1 deg.</value>
  </dataFieldLongName>
  <dataFieldAccessName>
    <type>text</type>
    <label>Variable Name</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
      <regex>[a-zA-Z0-9_/\[\]-]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores, left brackets, right brackets, and hyphens.</validationText>
    </constraints>
    <example>Angstrom_Exponent_1_Ocean_QA_Mean</example>
    <value>TotCO_A</value>
  </dataFieldAccessName>
  <dataFieldAccessFormat>
    <type>list</type>
    <label/>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>binary</valid>
      <valid>hdf</valid>
      <valid>native</valid>
      <valid>netCDF</valid>
      <valid>text</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value/>
  </dataFieldAccessFormat>
  <dataFieldAccessFormatVersion>
    <type>list</type>
    <!--
    <label>Variable Format Version</label>
-->
    <label/>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>1</valid>
      <valid>3</valid>
      <valid>4</valid>
      <valid>5</valid>
      <valid>CF-1.0</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value/>
  </dataFieldAccessFormatVersion>
  <dataFieldAccessMethod>
    <type>list</type>
    <label/>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>AIRNOW</valid>
      <valid>HTTP_Services_HDF_TO_NetCDF</valid>
      <valid>OPeNDAP</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value>OPeNDAP</value>
  </dataFieldAccessMethod>
  <!--
  <dataFieldSldUrl>
    <type>url</type>
    <label>Description URL</label>
    <multiplicity>many</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <example></example>
    <value></value>
  </dataFieldSldUrl>
-->
  <!--
  <dataFieldSld>
    <type>container</type>
    <label>Color Palettes</label>
    <multiplicity>many</multiplicity>
    <value>
      <dataFieldSldUrl>
        <type>url</type>
        <label>Description URL</label>
        <multiplicity>one</multiplicity>
        <constraints>
          <required>false</required>
          <editable>true</editable>
        </constraints>
        <example></example>
        <value></value>
      </dataFieldSldUrl>
      <dataFieldSldLabel>
        <type>text</type>
        <label>Description URL label</label>
        <multiplicity>one</multiplicity>
        <constraints>
          <required>false</required>
          <editable>true</editable>
        </constraints>
        <example></example>
        <value></value>
      </dataFieldSldLabel>
    </value>
  </dataFieldSld>
-->
  <dataFieldSld>
    <type>colorPaletteList</type>
    <label>Color Palettes</label>
    <multiplicity>many</multiplicity>
    <valids>
      <valid>absorption_aod_panoply_diff_sld</valid>
      <valid>absorption_aod_sld</valid>
      <valid>aerosol_index_panoply_diff_sld</valid>
      <valid>aerosol_index_sld</valid>
      <valid>airnow_sld</valid>
      <valid>angstrom_exponent_panoply_diff_sld</valid>
      <valid>angstrom_exponent_sld</valid>
      <valid>aod_gocart_blackcarbon_panoply_diff_sld</valid>
      <valid>aod_gocart_blackcarbon_sld</valid>
      <valid>aod_gocart_dust_panoply_diff_sld</valid>
      <valid>aod_gocart_dust_sld</valid>
      <valid>aod_gocart_organic_panoply_diff_sld</valid>
      <valid>aod_gocart_sea_salt_panoply_diff_sld</valid>
      <valid>aod_gocart_sea_salt_sld</valid>
      <valid>aod_panoply_diff_sld</valid>
      <valid>aod_pixel_counts_sld</valid>
      <valid>aod_sld</valid>
      <valid>atmospheric_temperature_sld</valid>
      <valid>correlation_n_counts_sld</valid>
      <valid>correlation_sld</valid>
      <valid>divergent_rdbu_10_sld</valid>
      <valid>divergent_rdylbu_10_sld</valid>
      <valid>evapotranspiration_sld</valid>
      <valid>latent_heat_flux_sld</valid>
      <valid>nldas_soil_moisture_0_100_sld</valid>
      <valid>nldas_soil_moisture_0_10_sld</valid>
      <valid>nldas_soil_moisture_0_200_sld</valid>
      <valid>nldas_soil_moisture_0_40_sld</valid>
      <valid>nldas_soil_moisture_100_200_sld</valid>
      <valid>nldas_soil_moisture_10_40_sld</valid>
      <valid>nldas_soil_moisture_40_100_sld</valid>
      <valid>nldas_soil_moisture_40_200_sld</valid>
      <valid>nldas_surface_runoff_sld</valid>
      <valid>relative_humidity_sld</valid>
      <valid>sensible_heat_flux_sld</valid>
      <valid>sequential_ylgnbu_9_sld</valid>
      <valid>soil_moisture_sld</valid>
      <valid>time_matched_difference_sld</valid>
      <valid>trmm_precipitation_panoply_diff_sld</valid>
      <valid>trmm_precipitation_sld</valid>
      <valid>wind_magnitude_sld</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>sequential_ylgnbu_9_sld</value>
  </dataFieldSld>
  <dataFieldMeasurement>
    <type>list</type>
    <label>Measurements</label>
    <multiplicity>many</multiplicity>
    <valids>
      <valid>Aerosol Index</valid>
      <valid>Aerosol Optical Depth</valid>
      <valid>Air Pressure</valid>
      <valid>Air Temperature</valid>
      <valid>Albedo</valid>
      <valid>Altitude</valid>
      <valid>Angstrom Exponent</valid>
      <valid>Buoyancy</valid>
      <valid>Canopy Water Storage</valid>
      <valid>Cloud Fraction</valid>
      <valid>Cloud Properties</valid>
      <valid>ClO</valid>
      <valid>CO</valid>
      <valid>CH4</valid>
      <valid>Component Aerosol Optical Depth</valid>
      <valid>Deuterium</valid>
      <valid>Diffusivity</valid>
      <valid>Emissivity</valid>
      <valid>Energy</valid>
      <valid>Erythemal UV</valid>
      <valid>Evaporation</valid>
      <valid>Evapotranspiration</valid>
      <valid>Geopotential</valid>
      <valid>Grid Std Dev</valid>
      <valid>Ground Heat</valid>
      <valid>HCl</valid>
      <valid>HCN</valid>
      <valid>Heat Flux</valid>
      <valid>Height, Level</valid>
      <valid>HNO3</valid>
      <valid>Humidity</valid>
      <valid>Incident Radiation</valid>
      <valid>Irradiance</valid>
      <valid>Latent Heat</valid>
      <valid>Latent Heat Flux</valid>
      <valid>Mass Flux</valid>
      <valid>N2O</valid>
      <valid>NO2</valid>
      <valid>Obs Time</valid>
      <valid>OH</valid>
      <valid>OLR</valid>
      <valid>Oxygen, Odd</valid>
      <valid>Ozone</valid>
      <valid>Particulate Matter</valid>
      <valid>Pixel Counts</valid>
      <valid>Precipitation</valid>
      <valid>Quality Info</valid>
      <valid>Radiation, Net</valid>
      <valid>Reflectivity</valid>
      <valid>Runoff</valid>
      <valid>Scattering Angle</valid>
      <valid>Sea Ice</valid>
      <valid>Sensible Heat</valid>
      <valid>Sensible Heat Flux</valid>
      <valid>SO2</valid>
      <valid>Soil moisture</valid>
      <valid>Soil Temperature</valid>
      <valid>Statistics</valid>
      <valid>Surface runoff</valid>
      <valid>Surface Temperature</valid>
      <valid>Total Aerosol Optical Depth</valid>
      <valid>UV Exposure</valid>
      <valid>Vegetation</valid>
      <valid>Viewing Geometry</valid>
      <valid>Vorticity</valid>
      <valid>Water, Atmos.</valid>
      <valid>Water Storage</valid>
      <valid>Water Vapor</valid>
      <valid>Wind</valid>
      <valid>Wind Stress Direction</valid>
      <valid>Wind Stress Magnitude</valid>
      <valid>Wind Velocity</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>CO</value>
  </dataFieldMeasurement>
  <dataFieldDescriptionUrl>
    <type>url</type>
    <label>Description URL</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
      <regex>^(?:http|ftp)://[\w.-]+(?::\d+)?/[-\w\d/.#\?]+$</regex>
      <validationText>The value must have the form of a URL.</validationText>
    </constraints>
    <example>http://disc.sci.gsfc.nasa.gov/techlab/giovanni/G3_manual_parameter_appendix.shtml#Angstrom_ocean</example>
    <value>http://disc.gsfc.nasa.gov/techlab/giovanni/G3_manual_parameter_appendix.shtml#tot_col_CO</value>
  </dataFieldDescriptionUrl>
  <dataFieldDiscipline>
    <type>list</type>
    <label>Disciplines</label>
    <multiplicity>many</multiplicity>
    <valids>
      <valid>Aerosols</valid>
      <valid>Atmospheric Chemistry</valid>
      <valid>Atmospheric Dynamics</valid>
      <valid>Hydrology</valid>
      <valid>Water and Energy Cycle</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>Atmospheric Chemistry</value>
  </dataFieldDiscipline>
  <dataFieldKeywords>
    <type>text</type>
    <label>Keywords</label>
    <multiplicity>many</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>CO</value>
    <value>Carbon Monoxide</value>
    <value>AIRS</value>
    <value>Aqua</value>
  </dataFieldKeywords>
  <dataFieldTags>
    <type>list</type>
    <label>Tags</label>
    <multiplicity>many</multiplicity>
    <valids>
      <valid>Atmospheric Composition Portal</valid>
      <valid>Basic</valid>
      <valid>Omnibus</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <value>Atmospheric Composition Portal</value>
    <value>Basic</value>
    <value>Omnibus</value>
  </dataFieldTags>
  <dataFieldStandardName>
    <type>text</type>
    <label>CF-1 Standard Name</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>air_temperature</example>
    <value/>
  </dataFieldStandardName>
  <dataFieldFillValueFieldName>
    <type>text</type>
    <label>Name of fill value attribute</label>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>_FillValue</valid>
      <valid>h4__FillValue</valid>
      <valid>h5__FillValue</valid>
      <valid>missing_value</valid>
      <valid>(none)</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <value>_FillValue</value>
  </dataFieldFillValueFieldName>
  <dataFieldUnits>
    <type>text</type>
    <label>Units</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>m/s</example>
    <value>10E18 molecules/cm2</value>
  </dataFieldUnits>
  <dataFieldDeflationLevel>
    <type>number</type>
    <label>Deflation Level</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>1</example>
    <value>1</value>
  </dataFieldDeflationLevel>
  <virtualDataFieldGenerator>
    <type>text</type>
    <label>Virtual data field generator</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>MAT1NXSLV_5_2_0_SLP=SLP/100.</example>
    <value/>
  </virtualDataFieldGenerator>
  <dataFieldVectorComponentNames>
    <type>text</type>
    <label>Vector Component Names</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>N10-m_above_ground_Zonal_wind_speed,N10-m_above_ground_Meridional_wind_speed</example>
    <value/>
  </dataFieldVectorComponentNames>
  <dataFieldInternal>
    <type>boolean</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <value>true</value>
  </dataFieldInternal>
  <dataFieldInDb>
    <type>boolean</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <value>false</value>
  </dataFieldInDb>
  <dataFieldState>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>Private</valid>
      <valid>Updated</valid>
      <valid>SubmittedPrivate</valid>
      <valid>SubmittedUpdated</valid>
      <valid>Published</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <value>Published</value>
  </dataFieldState>
  <dataFieldLastExtracted>
    <type>datetime</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value/>
  </dataFieldLastExtracted>
  <dataFieldLastModified>
    <type>datetime</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <value>2013-12-06T19:26:12.817Z</value>
  </dataFieldLastModified>
  <dataFieldLastPublished>
    <type>datetime</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value/>
  </dataFieldLastPublished>
  <dataFieldMinValid>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>-100.1</example>
    <multiplicity>one</multiplicity>
    <label>Minimum Valid Value</label>
    <type>number</type>
    <value/>
  </dataFieldMinValid>
  <dataFieldMaxValid>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>1000.1</example>
    <multiplicity>one</multiplicity>
    <label>Maximum Valid Value</label>
    <type>number</type>
    <value/>
  </dataFieldMaxValid>
  <dataFieldWavelengths>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>550</example>
    <multiplicity>many</multiplicity>
    <label>Wavelengths</label>
    <type>number</type>
    <value/>
  </dataFieldWavelengths>
  <dataFieldWavelengthUnits>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>nm</example>
    <multiplicity>one</multiplicity>
    <label>Wavelength Units</label>
    <type>text</type>
    <value/>
  </dataFieldWavelengthUnits>
  <dataFieldDepths>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>10-40</example>
    <multiplicity>many</multiplicity>
    <label>Depths</label>
    <type>number</type>
    <value/>
  </dataFieldDepths>
  <dataFieldDepthUnits>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>cm</example>
    <multiplicity>one</multiplicity>
    <label>Depth Units</label>
    <type>text</type>
    <value/>
  </dataFieldDepthUnits>
  <dataFieldZDimensionName>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>TempPrsLvls_A</example>
    <multiplicity>one</multiplicity>
    <label>Z-dimension name (if any)</label>
    <type>text</type>
    <value/>
  </dataFieldZDimensionName>
  <dataFieldZDimensionType>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>pressure</example>
    <multiplicity>one</multiplicity>
    <label>Z-dimension type (if any)</label>
    <type>text</type>
    <value/>
  </dataFieldZDimensionType>
  <dataFieldZDimensionUnits>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>hPa</example>
    <multiplicity>one</multiplicity>
    <label>Z-dimension units (if any)</label>
    <type>text</type>
    <value/>
  </dataFieldZDimensionUnits>
  <dataFieldZDimensionValues>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>1000 500 100 50 30 10 5 1</example>
    <multiplicity>one</multiplicity>
    <label>Z-dimension values (space-separated, if any)</label>
    <type>text</type>
    <value/>
  </dataFieldZDimensionValues>
</dataField>
ENDFILE
FILE=AIRX3STD_006_TotCO_A_updated
<?xml version="1.0"?>
<dataField>
  <dataFieldId>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
      <regex>[a-zA-Z0-9_]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores.</validationText>
    </constraints>
    <value>AIRX3STD_006_TotCO_A</value>
  </dataFieldId>
  <dataFieldG3Id>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
      <regex>[a-zA-Z0-9_]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores.</validationText>
    </constraints>
    <value/>
  </dataFieldG3Id>
  <dataFieldActive>
    <type>boolean</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
      <regex>^true$|^false$</regex>
      <validationText>The value must be either 'true' or 'false'</validationText>
    </constraints>
    <value>true</value>
  </dataFieldActive>
  <dataFieldProductId>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
      <regex>[a-zA-Z0-9_.-]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores, periods, and hyphens.</validationText>
    </constraints>
    <value>AIRX3STD.006</value>
  </dataFieldProductId>
  <dataFieldSdsName>
    <type>text</type>
    <label>G3 SDS Name</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
      <regex>[a-zA-Z0-9_-]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores, and hyphens.</validationText>
    </constraints>
    <example>Angstrom_Exponent_1_Ocean_QA_Mean</example>
    <value>TotCO_A</value>
  </dataFieldSdsName>
  <dataFieldShortName>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
      <regex><![CDATA[[a-zA-Z0-9 _.,)(@/%+-]+$]]></regex>
      <validationText>The value must consist only of letters, digits, spaces, underscores, periods, commas, parentheses, @, slashes, percents, pluses, and hyphens.</validationText>
    </constraints>
    <value>Here is a new value for testing purposes</value>
  </dataFieldShortName>
  <dataFieldLongName>
    <type>text</type>
    <label>Long Name</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
      <regex><![CDATA[[a-zA-Z0-9 _.,:)(&/%><=+-]+$]]></regex>
      <validationText>The value must consist only of letters, digits, spaces, underscores, periods, commas, colons, parentheses, ampersands, slashes, percents, less-thans, greater-thans, equals, pluses, and hyphens.</validationText>
    </constraints>
    <example>Aerosol Optical Depth 550 nm (Dark Target), MODIS-Aqua, 1 x 1 deg.</example>
    <!--
    <value>Carbon Monoxide, Total Column, daytime (ascending), AIRS, 1 x 1 deg.</value>
    -->
    <value>Here is a new value for testing purposes</value>
  </dataFieldLongName>
  <dataFieldAccessName>
    <type>text</type>
    <label>Variable Name</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
      <regex>[a-zA-Z0-9_/\[\]-]+$</regex>
      <validationText>The value must consist only of letters, digits, underscores, left brackets, right brackets, and hyphens.</validationText>
    </constraints>
    <example>Angstrom_Exponent_1_Ocean_QA_Mean</example>
    <value>TotCO_A</value>
  </dataFieldAccessName>
  <dataFieldAccessFormat>
    <type>list</type>
    <label/>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>binary</valid>
      <valid>hdf</valid>
      <valid>native</valid>
      <valid>netCDF</valid>
      <valid>text</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value/>
  </dataFieldAccessFormat>
  <dataFieldAccessFormatVersion>
    <type>list</type>
    <!--
    <label>Variable Format Version</label>
-->
    <label/>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>1</valid>
      <valid>3</valid>
      <valid>4</valid>
      <valid>5</valid>
      <valid>CF-1.0</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value/>
  </dataFieldAccessFormatVersion>
  <dataFieldAccessMethod>
    <type>list</type>
    <label/>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>AIRNOW</valid>
      <valid>HTTP_Services_HDF_TO_NetCDF</valid>
      <valid>OPeNDAP</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value>OPeNDAP</value>
  </dataFieldAccessMethod>
  <!--
  <dataFieldSldUrl>
    <type>url</type>
    <label>Description URL</label>
    <multiplicity>many</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <example></example>
    <value></value>
  </dataFieldSldUrl>
-->
  <!--
  <dataFieldSld>
    <type>container</type>
    <label>Color Palettes</label>
    <multiplicity>many</multiplicity>
    <value>
      <dataFieldSldUrl>
        <type>url</type>
        <label>Description URL</label>
        <multiplicity>one</multiplicity>
        <constraints>
          <required>false</required>
          <editable>true</editable>
        </constraints>
        <example></example>
        <value></value>
      </dataFieldSldUrl>
      <dataFieldSldLabel>
        <type>text</type>
        <label>Description URL label</label>
        <multiplicity>one</multiplicity>
        <constraints>
          <required>false</required>
          <editable>true</editable>
        </constraints>
        <example></example>
        <value></value>
      </dataFieldSldLabel>
    </value>
  </dataFieldSld>
-->
  <dataFieldSld>
    <type>colorPaletteList</type>
    <label>Color Palettes</label>
    <multiplicity>many</multiplicity>
    <valids>
      <valid>absorption_aod_panoply_diff_sld</valid>
      <valid>absorption_aod_sld</valid>
      <valid>aerosol_index_panoply_diff_sld</valid>
      <valid>aerosol_index_sld</valid>
      <valid>airnow_sld</valid>
      <valid>angstrom_exponent_panoply_diff_sld</valid>
      <valid>angstrom_exponent_sld</valid>
      <valid>aod_gocart_blackcarbon_panoply_diff_sld</valid>
      <valid>aod_gocart_blackcarbon_sld</valid>
      <valid>aod_gocart_dust_panoply_diff_sld</valid>
      <valid>aod_gocart_dust_sld</valid>
      <valid>aod_gocart_organic_panoply_diff_sld</valid>
      <valid>aod_gocart_sea_salt_panoply_diff_sld</valid>
      <valid>aod_gocart_sea_salt_sld</valid>
      <valid>aod_panoply_diff_sld</valid>
      <valid>aod_pixel_counts_sld</valid>
      <valid>aod_sld</valid>
      <valid>atmospheric_temperature_sld</valid>
      <valid>correlation_n_counts_sld</valid>
      <valid>correlation_sld</valid>
      <valid>divergent_rdbu_10_sld</valid>
      <valid>divergent_rdylbu_10_sld</valid>
      <valid>evapotranspiration_sld</valid>
      <valid>latent_heat_flux_sld</valid>
      <valid>nldas_soil_moisture_0_100_sld</valid>
      <valid>nldas_soil_moisture_0_10_sld</valid>
      <valid>nldas_soil_moisture_0_200_sld</valid>
      <valid>nldas_soil_moisture_0_40_sld</valid>
      <valid>nldas_soil_moisture_100_200_sld</valid>
      <valid>nldas_soil_moisture_10_40_sld</valid>
      <valid>nldas_soil_moisture_40_100_sld</valid>
      <valid>nldas_soil_moisture_40_200_sld</valid>
      <valid>nldas_surface_runoff_sld</valid>
      <valid>relative_humidity_sld</valid>
      <valid>sensible_heat_flux_sld</valid>
      <valid>sequential_ylgnbu_9_sld</valid>
      <valid>soil_moisture_sld</valid>
      <valid>time_matched_difference_sld</valid>
      <valid>trmm_precipitation_panoply_diff_sld</valid>
      <valid>trmm_precipitation_sld</valid>
      <valid>wind_magnitude_sld</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>sequential_ylgnbu_9_sld</value>
  </dataFieldSld>
  <dataFieldMeasurement>
    <type>list</type>
    <label>Measurements</label>
    <multiplicity>many</multiplicity>
    <valids>
      <valid>Aerosol Index</valid>
      <valid>Aerosol Optical Depth</valid>
      <valid>Air Pressure</valid>
      <valid>Air Temperature</valid>
      <valid>Albedo</valid>
      <valid>Altitude</valid>
      <valid>Angstrom Exponent</valid>
      <valid>Buoyancy</valid>
      <valid>Canopy Water Storage</valid>
      <valid>Cloud Fraction</valid>
      <valid>Cloud Properties</valid>
      <valid>ClO</valid>
      <valid>CO</valid>
      <valid>CH4</valid>
      <valid>Component Aerosol Optical Depth</valid>
      <valid>Deuterium</valid>
      <valid>Diffusivity</valid>
      <valid>Emissivity</valid>
      <valid>Energy</valid>
      <valid>Erythemal UV</valid>
      <valid>Evaporation</valid>
      <valid>Evapotranspiration</valid>
      <valid>Geopotential</valid>
      <valid>Grid Std Dev</valid>
      <valid>Ground Heat</valid>
      <valid>HCl</valid>
      <valid>HCN</valid>
      <valid>Heat Flux</valid>
      <valid>Height, Level</valid>
      <valid>HNO3</valid>
      <valid>Humidity</valid>
      <valid>Incident Radiation</valid>
      <valid>Irradiance</valid>
      <valid>Latent Heat</valid>
      <valid>Latent Heat Flux</valid>
      <valid>Mass Flux</valid>
      <valid>N2O</valid>
      <valid>NO2</valid>
      <valid>Obs Time</valid>
      <valid>OH</valid>
      <valid>OLR</valid>
      <valid>Oxygen, Odd</valid>
      <valid>Ozone</valid>
      <valid>Particulate Matter</valid>
      <valid>Pixel Counts</valid>
      <valid>Precipitation</valid>
      <valid>Quality Info</valid>
      <valid>Radiation, Net</valid>
      <valid>Reflectivity</valid>
      <valid>Runoff</valid>
      <valid>Scattering Angle</valid>
      <valid>Sea Ice</valid>
      <valid>Sensible Heat</valid>
      <valid>Sensible Heat Flux</valid>
      <valid>SO2</valid>
      <valid>Soil moisture</valid>
      <valid>Soil Temperature</valid>
      <valid>Statistics</valid>
      <valid>Surface runoff</valid>
      <valid>Surface Temperature</valid>
      <valid>Total Aerosol Optical Depth</valid>
      <valid>UV Exposure</valid>
      <valid>Vegetation</valid>
      <valid>Viewing Geometry</valid>
      <valid>Vorticity</valid>
      <valid>Water, Atmos.</valid>
      <valid>Water Storage</valid>
      <valid>Water Vapor</valid>
      <valid>Wind</valid>
      <valid>Wind Stress Direction</valid>
      <valid>Wind Stress Magnitude</valid>
      <valid>Wind Velocity</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>CO</value>
  </dataFieldMeasurement>
  <dataFieldDescriptionUrl>
    <type>url</type>
    <label>Description URL</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
      <regex>^(?:http|ftp)://[\w.-]+(?::\d+)?/[-\w\d/.#\?]+$</regex>
      <validationText>The value must have the form of a URL.</validationText>
    </constraints>
    <example>http://disc.sci.gsfc.nasa.gov/techlab/giovanni/G3_manual_parameter_appendix.shtml#Angstrom_ocean</example>
    <value>http://disc.gsfc.nasa.gov/techlab/giovanni/G3_manual_parameter_appendix.shtml#tot_col_CO</value>
  </dataFieldDescriptionUrl>
  <dataFieldDiscipline>
    <type>list</type>
    <label>Disciplines</label>
    <multiplicity>many</multiplicity>
    <valids>
      <valid>Aerosols</valid>
      <valid>Atmospheric Chemistry</valid>
      <valid>Atmospheric Dynamics</valid>
      <valid>Hydrology</valid>
      <valid>Water and Energy Cycle</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>Atmospheric Chemistry</value>
  </dataFieldDiscipline>
  <dataFieldKeywords>
    <type>text</type>
    <label>Keywords</label>
    <multiplicity>many</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>CO</value>
    <value>Carbon Monoxide</value>
    <value>AIRS</value>
    <value>Aqua</value>
  </dataFieldKeywords>
  <dataFieldTags>
    <type>list</type>
    <label>Tags</label>
    <multiplicity>many</multiplicity>
    <valids>
      <valid>Atmospheric Composition Portal</valid>
      <valid>Basic</valid>
      <valid>Omnibus</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <value>Atmospheric Composition Portal</value>
    <value>Basic</value>
    <value>Omnibus</value>
  </dataFieldTags>
  <dataFieldStandardName>
    <type>text</type>
    <label>CF-1 Standard Name</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>air_temperature</example>
    <value/>
  </dataFieldStandardName>
  <dataFieldFillValueFieldName>
    <type>text</type>
    <label>Name of fill value attribute</label>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>_FillValue</valid>
      <valid>h4__FillValue</valid>
      <valid>h5__FillValue</valid>
      <valid>missing_value</valid>
      <valid>(none)</valid>
    </valids>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <value>_FillValue</value>
  </dataFieldFillValueFieldName>
  <dataFieldUnits>
    <type>text</type>
    <label>Units</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>m/s</example>
    <value>10E18 molecules/cm2</value>
  </dataFieldUnits>
  <dataFieldDeflationLevel>
    <type>number</type>
    <label>Deflation Level</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>1</example>
    <value>1</value>
  </dataFieldDeflationLevel>
  <virtualDataFieldGenerator>
    <type>text</type>
    <label>Virtual data field generator</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>MAT1NXSLV_5_2_0_SLP=SLP/100.</example>
    <value/>
  </virtualDataFieldGenerator>
  <dataFieldVectorComponentNames>
    <type>text</type>
    <label>Vector Component Names</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>N10-m_above_ground_Zonal_wind_speed,N10-m_above_ground_Meridional_wind_speed</example>
    <value/>
  </dataFieldVectorComponentNames>
  <dataFieldInternal>
    <type>boolean</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <value>true</value>
  </dataFieldInternal>
  <dataFieldInDb>
    <type>boolean</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <value>false</value>
  </dataFieldInDb>
  <dataFieldState>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <valids>
      <valid>Private</valid>
      <valid>Updated</valid>
      <valid>SubmittedPrivate</valid>
      <valid>SubmittedUpdated</valid>
      <valid>Published</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <value>Published</value>
  </dataFieldState>
  <dataFieldLastExtracted>
    <type>datetime</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value/>
  </dataFieldLastExtracted>
  <dataFieldLastModified>
    <type>datetime</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <value>2013-12-06T19:26:12.817Z</value>
  </dataFieldLastModified>
  <dataFieldLastPublished>
    <type>datetime</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
    </constraints>
    <value/>
  </dataFieldLastPublished>
  <dataFieldMinValid>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>-100.1</example>
    <multiplicity>one</multiplicity>
    <label>Minimum Valid Value</label>
    <type>number</type>
    <value/>
  </dataFieldMinValid>
  <dataFieldMaxValid>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>1000.1</example>
    <multiplicity>one</multiplicity>
    <label>Maximum Valid Value</label>
    <type>number</type>
    <value/>
  </dataFieldMaxValid>
  <dataFieldWavelengths>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>550</example>
    <multiplicity>many</multiplicity>
    <label>Wavelengths</label>
    <type>number</type>
    <value/>
  </dataFieldWavelengths>
  <dataFieldWavelengthUnits>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>nm</example>
    <multiplicity>one</multiplicity>
    <label>Wavelength Units</label>
    <type>text</type>
    <value/>
  </dataFieldWavelengthUnits>
  <dataFieldDepths>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>10-40</example>
    <multiplicity>many</multiplicity>
    <label>Depths</label>
    <type>number</type>
    <value/>
  </dataFieldDepths>
  <dataFieldDepthUnits>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>cm</example>
    <multiplicity>one</multiplicity>
    <label>Depth Units</label>
    <type>text</type>
    <value/>
  </dataFieldDepthUnits>
  <dataFieldZDimensionName>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>TempPrsLvls_A</example>
    <multiplicity>one</multiplicity>
    <label>Z-dimension name (if any)</label>
    <type>text</type>
    <value/>
  </dataFieldZDimensionName>
  <dataFieldZDimensionType>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>pressure</example>
    <multiplicity>one</multiplicity>
    <label>Z-dimension type (if any)</label>
    <type>text</type>
    <value/>
  </dataFieldZDimensionType>
  <dataFieldZDimensionUnits>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>hPa</example>
    <multiplicity>one</multiplicity>
    <label>Z-dimension units (if any)</label>
    <type>text</type>
    <value/>
  </dataFieldZDimensionUnits>
  <dataFieldZDimensionValues>
    <constraints>
      <required>false</required>
      <editable>true</editable>
    </constraints>
    <example>1000 500 100 50 30 10 5 1</example>
    <multiplicity>one</multiplicity>
    <label>Z-dimension values (space-separated, if any)</label>
    <type>text</type>
    <value/>
  </dataFieldZDimensionValues>
</dataField>
ENDFILE
