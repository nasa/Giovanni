# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl EDDA-Ingest.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
use File::Temp qw/ tempfile tempdir /;
BEGIN { use_ok('EDDA::Ingest') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Read _DATA_ section into temporary files
my $workingdir = tempdir(CLEANUP => 1);
ok((-e $workingdir), "Working directory $workingdir created");
my $filename;
my @filenames;
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
        push @filenames, $filename;
        next;
    }
    my $line = $_;
    $line =~ s/WORKINGDIR/$workingdir/;
    print FH $line;
}

# Create archive file from test data
my $tarname = "$workingdir/test.gz";
my $output = `/bin/gtar --create -z -f $tarname -C $workingdir .`;
ok((-f $tarname), "Test archive $tarname created");

# Test object creation and detection of missing parameters.
# Object should be created, and methods onError and errorMessage should
# return values.
my $ingest = EDDA::Ingest->new();
ok($ingest, "Created Ingest object with no parameters");
ok($ingest->onError, "Missing parameters detected when object created");
ok($ingest->errorMessage, "Has error message: " . $ingest->errorMessage);

# Test object creation with required set of parameters.
$ingest = EDDA::Ingest->new(ARCHIVE => $tarname);
ok($ingest, "Created Ingest object with two parameters");
ok(!$ingest->onError, "No error detected when object created");

# Test validation with missing parameters
ok(!$ingest->validateSchema(), "Validation failed when missing parameter");

1;

###########################################################################
__DATA__
FILE=TRMM_3B42_daily_precipitation_V7
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
    <value>TRMM_3B42_daily_precipitation_V7</value>
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
    <value>TRMM_3B42_daily_precipitation_V7</value>
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
    <value>TRMM_3B42_daily.007</value>
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
    <value>precipitation</value>
  </dataFieldSdsName>
  <dataFieldShortName>
    <type>text</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>false</required>
      <editable>false</editable>
      <regex>[a-zA-Z0-9 _.,)(@/%+-]+$</regex>
      <validationText>The value must consist only of letters, digits, spaces, underscores, periods, commas, parentheses, @, slashes, percents, pluses, and hyphens.</validationText>
    </constraints>
    <value>precipitation</value>
  </dataFieldShortName>
  <dataFieldLongName>
    <type>text</type>
    <label>Long Name</label>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
      <regex>[a-zA-Z0-9 _.,:)(&amp;/%&gt;&lt;=+-]+$</regex>
      <validationText>The value must consist only of letters, digits, spaces, underscores, periods, commas, colons, parentheses, ampersands, slashes, percents, less-thans, greater-thans, equals, pluses, and hyphens.</validationText>
    </constraints>
    <example>Aerosol Optical Depth 550 nm (Dark Target), MODIS-Aqua, 1 x 1 deg.</example>
    <value>Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg.</value>
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
    <value/>
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
    <value>netCDF</value>
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
    <value>3</value>
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
    <value>HTTP_Services_HDF_TO_NetCDF</value>
  </dataFieldAccessMethod>
  <dataFieldSld>
    <type>colorPaletteList</type>
    <label>Color Palettes</label>
    <multiplicity>many</multiplicity>
    <valids>
      <valid>absorption_aod_sld</valid>
      <valid>absorption_aod_panoply_diff_sld</valid>
      <valid>aerosol_index_sld</valid>
      <valid>aerosol_index_panoply_diff_sld</valid>
      <valid>airnow_sld</valid>
      <valid>angstrom_exponent_sld</valid>
      <valid>angstrom_exponent_panoply_diff_sld</valid>
      <valid>atmospheric_temperature_sld</valid>
      <valid>aod_gocart_blackcarbon_sld</valid>
      <valid>aod_gocart_blackcarbon_panoply_diff_sld</valid>
      <valid>aod_gocart_dust_sld</valid>
      <valid>aod_gocart_dust_panoply_diff_sld</valid>
      <valid>aod_gocart_sea_salt_sld</valid>
      <valid>aod_gocart_sea_salt_panoply_diff_sld</valid>
      <valid>aod_pixel_counts_sld</valid>
      <valid>aod_panoply_diff_sld</valid>
      <valid>aod_sld</valid>
      <valid>divergent_rdbu_10_sld</valid>
      <valid>divergent_rdylbu_10_sld</valid>
      <valid>evapotranspiration_sld</valid>
      <valid>humidity_mixing_ratio_sld</valid>
      <valid>latent_heat_flux_sld</valid>
      <valid>nldas_soil_moisture_0_100_sld</valid>
      <valid>nldas_soil_moisture_0_10_sld</valid>
      <valid>nldas_soil_moisture_0_200_sld</valid>
      <valid>nldas_soil_moisture_100_200_sld</valid>
      <valid>nldas_soil_moisture_10_40_sld</valid>
      <valid>nldas_soil_moisture_40_100_sld</valid>
      <valid>nldas_surface_runoff_sld</valid>
      <valid>relative_humidity_sld</valid>
      <valid>sensible_heat_flux_sld</valid>
      <valid>sequential_ylgnbu_9_sld</valid>
      <valid>trmm_precipitation_sld</valid>
      <valid>trmm_precipitation_panoply_diff_sld</valid>
      <valid>wind_magnitude_sld</valid>
    </valids>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>trmm_precipitation_sld</value>
    <value>trmm_precipitation_panoply_diff_sld</value>
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
    <value>Precipitation</value>
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
    <value>http://disc.sci.gsfc.nasa.gov/giovanni/documents/ag/user-manual#precipitation</value>
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
    <value>Hydrology</value>
  </dataFieldDiscipline>
  <dataFieldKeywords>
    <type>text</type>
    <label>Keywords</label>
    <multiplicity>many</multiplicity>
    <constraints>
      <required>true</required>
      <editable>true</editable>
    </constraints>
    <value>Daily</value>
    <value>Precipitation</value>
    <value>Precipitation Rate</value>
    <value>Precipitation Rate Estimate</value>
    <value>Rainfall</value>
    <value>Rainfall Rate</value>
    <value>Rainfall Rate Estimate</value>
    <value>Estimate</value>
    <value>TRMM</value>
    <value>3B42</value>
    <value>derived</value>
    <value>PR</value>
    <value>TMI</value>
    <value>VIRS</value>
    <value>TRMM_3B42_daily</value>
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
    <value>(none)</value>
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
    <value>mm/day</value>
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
    <value/>
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
    <value>true</value>
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
    <value>2013-09-07T01:32:59Z</value>
  </dataFieldLastExtracted>
  <dataFieldLastModified>
    <type>datetime</type>
    <label/>
    <multiplicity>one</multiplicity>
    <constraints>
      <required>true</required>
      <editable>false</editable>
    </constraints>
    <value>2013-09-03T20:28:58.824Z</value>
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
</dataField>
ENDFILE
