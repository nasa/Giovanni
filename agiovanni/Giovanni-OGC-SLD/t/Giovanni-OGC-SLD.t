# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-OGC-SLD.t'

#########################

use Test::More tests => 26;
use File::Basename;
use Giovanni::Util;
BEGIN { use_ok('Giovanni::OGC::SLD') }

#########################
my $fileDir = dirname($0);

# Test a linear Giovanni SLD
my $file = $fileDir . "/linear_sld_v1_1_0.xml";
my $sld = Giovanni::OGC::SLD->new( FILE => $file );

# Test for parsing
ok( defined $sld, "SLD parsed" );

# Get "fill value" color
my $fillColor = $sld->getFillColor();
is( $fillColor, "#ff00ff", "Verified the fill color" );

# Test number of colors
my @colorNodeList = $sld->getColors();
is( @colorNodeList, 12, "12 colors found" );

# Test for data range
my @dataRange = $sld->getDataRange();
is( $dataRange[0], '0',   "Data min matches" );
is( $dataRange[1], '1.0', "Data max matches" );

# Test the layer name
my $layerName = $sld->getLayerName();
my $userStyle = $sld->getUserStyleName();
is( $layerName, 'aod_sld', "Layer name matches" );
is( $userStyle,
    'Aerosol Optical Depth Color Map',
    "User style, used as the label for SLD, matches"
);

# Test for setting layer name
$sld->setLayerName("xyz");
is( $sld->getLayerName(), "xyz", "Set layer name correctly" );

# Roll back the layer name change
$sld->setLayerName($layerName);

# Verify thresholds
my @thresholdList = $sld->getThresholds();
is( @thresholdList, 11, "Verified the threshold count" );

#Test for min/max modification
my $ret = $sld->modifyColorMap( MIN => 10, MAX => 20 );
is( $ret, 1, "Min/max modified successfully" );
@dataRange = $sld->getDataRange();
is( $dataRange[0], '10', "Data min matches after modification" );
is( $dataRange[1], '20', "Data max matches after modification" );

# Test for inverting color palettes
$ret = $sld->invertPalette();
is( $ret, 1, "Color palette reversed" );
my @colorList = $sld->getColors();
is( $colorList[-1], '#FFFFE5',
    'Inversion of palettes: verified first color' );
is( $colorList[0], '#000000', 'Inversion of palettes: verified last color' );

# Test hex to RGB conversions
is_deeply(
    [ Giovanni::OGC::SLD::hexStringToRGB('#000000') ],
    [ 0, 0, 0 ],
    'hex to rgb'
);
is_deeply(
    [ Giovanni::OGC::SLD::hexStringToRGB('#ff00ff') ],
    [ 255, 0, 255 ],
    'hex to rgb'
);

# Test SLD to GrADS conversion
my ( $settings, $bColor ) = $sld->getGrADSColorSettings();

is( $settings->[-1], 'set clevs 10 11 12 13 14 15 16 17 18 19 20',
    'set clevs' );
is( $bColor, 'set rgb 28 255 0 255', 'set background color' );

# Testing getLabels()
# Testing createThumbnail()
# Testing toString()

# Test small minimum value be registered in colorbar
$ret = $sld->modifyColorMap( MIN => 0.00001, MAX => 250 );
@dataRange = $sld->getDataRange();
is( $dataRange[0], "1e-05", "Data min matches after modification" );
is( $dataRange[1], 250,   "Data max matches after modification" );
my @labels = $sld->getLabels();
is( $labels[0],  "1e-05",       "label min matches after modification" );
is( $labels[-1], "250", "label max matches after modification" );

# Test font size be adjusted based on the amount of characters and legend width
@labels = (5.555e+255, 234567, 9);
my $labelWidth = 60;
my $fontOK = 1;
foreach my $label(@labels) {
  my $fontSize = Giovanni::Util::getFontSize( $labelWidth, $label);
  my ($labelSize) = Giovanni::Util::getLabelSize( $label,
                           ( size => $fontSize) );  
  $fontOK = 0 if $labelSize > $labelWidth;
}
is( $fontOK, 1, "font size is correct");

# Test https SLDs
$sld = Giovanni::OGC::SLD->new( URL=>'https://giovanni.gsfc.nasa.gov/beta/giovanni/sld/sequential_rd_9_sld.xml' );
is( scalar($sld->getColors()), 9, "Successfully parsed an SLD with protocol=https" );
exit(0);

