# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-OGC-SLD.t'

#########################

use Test::More tests => 22;
use File::Basename;
BEGIN { use_ok('Giovanni::OGC::SLD') }

#########################

use strict;
use warnings;

use File::Temp qw/tempdir/;

my $dir = tempdir( CLEANUP => 2 );
my $sldFiles = getSlds($dir);

runTest(
    SLD_NAME   => "8 thresholds",
    MIN        => 0,
    MAX        => 10,
    INTDATA    => 0,
    SCALETYPE  => 'linear',
    THRESHOLDS => [
        "0",                "1.42857142857143",
        "2.85714285714286", "4.28571428571429",
        "5.71428571428571", "7.14285714285714",
        "8.57142857142857", "10"
    ],
    LABELS =>
        [ "0", "1.429", "2.857", "4.286", "5.714", "7.143", "8.571", "10" ],
    LEGEND_SCALE => '1',
    TEST_NAME    => "0-10, 8 thresholds",

);

runTest(
    SLD_NAME   => "8 thresholds",
    MIN        => 0,
    MAX        => 3,
    INTDATA    => 1,
    SCALETYPE  => 'linear',
    THRESHOLDS => [
        "0",                 "0.428571428571429",
        "0.857142857142857", "1.28571428571429",
        "1.71428571428571",  "2.14285714285714",
        "2.57142857142857",  "3"
    ],
    LABELS       => [ "0", "", "", "", "", "", "", "3" ],
    LEGEND_SCALE => '1',
    TEST_NAME    => "0-3, 8 integer thresholds",
);

runTest(
    SLD_NAME     => "8 thresholds",
    MIN          => 1,
    MAX          => 8,
    SCALETYPE    => 'linear',
    INTDATA      => 0,
    THRESHOLDS   => [ "1", "2", "3", "4", "5", "6", "7", "8" ],
    LABELS       => [ "1", "2", "3", "4", "5", "6", "7", "8" ],
    LEGEND_SCALE => '1',
    TEST_NAME    => "1-8, 8 thresholds",
);

runTest(
    SLD_NAME   => "Large SLD",
    MIN        => "5.91000e+17",
    MAX        => "3.36200e+18",
    SCALETYPE  => 'linear',
    INTDATA    => 0,
    THRESHOLDS => [
        "591000000000000000",   "6.34984126984127e+17",
        "6.78968253968254e+17", "7.22952380952381e+17",
        "7.66936507936508e+17", "8.10920634920635e+17",
        "8.54904761904762e+17", "8.98888888888889e+17",
        "9.42873015873016e+17", "9.86857142857143e+17",
        "1.03084126984127e+18", "1.0748253968254e+18",
        "1.11880952380952e+18", "1.16279365079365e+18",
        "1.20677777777778e+18", "1.2507619047619e+18",
        "1.29474603174603e+18", "1.33873015873016e+18",
        "1.38271428571429e+18", "1.42669841269841e+18",
        "1.47068253968254e+18", "1.51466666666667e+18",
        "1.55865079365079e+18", "1.60263492063492e+18",
        "1.64661904761905e+18", "1.69060317460317e+18",
        "1.7345873015873e+18",  "1.77857142857143e+18",
        "1.82255555555556e+18", "1.86653968253968e+18",
        "1.91052380952381e+18", "1.95450793650794e+18",
        "1.99849206349206e+18", "2.04247619047619e+18",
        "2.08646031746032e+18", "2.13044444444444e+18",
        "2.17442857142857e+18", "2.2184126984127e+18",
        "2.26239682539683e+18", "2.30638095238095e+18",
        "2.35036507936508e+18", "2.39434920634921e+18",
        "2.43833333333333e+18", "2.48231746031746e+18",
        "2.52630158730159e+18", "2.57028571428571e+18",
        "2.61426984126984e+18", "2.65825396825397e+18",
        "2.7022380952381e+18",  "2.74622222222222e+18",
        "2.79020634920635e+18", "2.83419047619048e+18",
        "2.8781746031746e+18",  "2.92215873015873e+18",
        "2.96614285714286e+18", "3.01012698412698e+18",
        "3.05411111111111e+18", "3.09809523809524e+18",
        "3.14207936507937e+18", "3.18606349206349e+18",
        "3.23004761904762e+18", "3.27403174603175e+18",
        "3.31801587301587e+18", "3.362e+18",
    ],
    LABELS => [
        "5.91", "",      "",      "",      "",      "",
        "",     "",      "",      "",      "",      "",
        "",     "11.63", "",      "",      "",      "",
        "",     "",      "",      "",      "",      "",
        "",     "",      "17.35", "",      "",      "",
        "",     "",      "",      "",      "",      "",
        "",     "",      "",      "23.06", "",      "",
        "",     "",      "",      "",      "",      "",
        "",     "",      "",      "",      "28.78", "",
        "",     "",      "",      "",      "",      "",
        "",     "",      "",      "33.62"
    ],
    LEGEND_SCALE => '1e+17',
    TEST_NAME    => "Lots of thresholds, big numbers",
);

runTest(
    SLD_NAME   => "8 thresholds",
    MIN        => 0.0000001,
    MAX        => 0.0000002,
    INTDATA    => 0,
    SCALETYPE  => 'linear',
    THRESHOLDS => [
        "1e-07",                "1.14285714285714e-07",
        "1.28571428571429e-07", "1.42857142857143e-07",
        "1.57142857142857e-07", "1.71428571428571e-07",
        "1.85714285714286e-07", "2e-07",
    ],
    LABELS =>
        [ "1", "1.143", "1.286", "1.429", "1.571", "1.714", "1.857", "2" ],
    LEGEND_SCALE => '1e-07',
    TEST_NAME    => "small thresholds",
);

runTest(
    SLD_NAME   => "8 thresholds",
    MIN        => -300,
    MAX        => 0,
    INTDATA    => 0,
    SCALETYPE  => 'linear',
    THRESHOLDS => [
        "-300",              "-257.142857142857",
        "-214.285714285714", "-171.428571428571",
        "-128.571428571429", "-85.7142857142857",
        "-42.8571428571429", "0",
    ],
    LABELS => [
        "-300",   "-257.1", "-214.3", "-171.4",
        "-128.6", "-85.71", "-42.86", "0"
    ],
    LEGEND_SCALE => '1',
    TEST_NAME    => "negative thresholds",
);

runTest(
    SLD_NAME   => "8 thresholds",
    MIN        => 0.0000001,
    MAX        => 20000000,
    INTDATA    => 0,
    SCALETYPE  => 'linear',
    THRESHOLDS => [
        "1e-07",
        "2857142.85714294",
        "5714285.71428579",
        "8571428.57142863",
        "11428571.4285715",
        "14285714.2857143",
        "17142857.1428572",
        "20000000",
    ],
    LABELS => [
        "1e-07",     "2.857e+06", "5.714e+06", "8.571e+06",
        "1.143e+07", "1.429e+07", "1.714e+07", "2e+07"
    ],
    LEGEND_SCALE => '1',
    TEST_NAME    => "sig figs",
);

sub runTest {
    my %params = @_;

    my $sld = Giovanni::OGC::SLD->new(
        FILE    => $sldFiles->{ $params{SLD_NAME} },
    );
    $sld->setIntData($params{INTDATA});
    $sld->modifyColorMap(
        MIN       => $params{MIN},
        MAX       => $params{MAX},
        SCALETYPE => $params{SCALETYPE},
    );
    my @thresholds  = $sld->getThresholds();
    my @labels      = $sld->getLabels();
    my $legendScale = $sld->getLegendScale();
    is_deeply( \@thresholds, $params{THRESHOLDS},
        $params{TEST_NAME} . " thresholds." );
    is_deeply( \@labels, $params{LABELS}, $params{TEST_NAME} . " labels." );
    is( $legendScale, $params{LEGEND_SCALE},
        $params{TEST_NAME} . " legend scale." );
}

# Read in all the SLDs in the __DATA__ section and write them to a temporary
# directory.
sub getSlds {
    my ($dir)       = @_;
    my $sldFileHash = {};
    my @lines       = <DATA>;

    # get rid of the end-of-lines
    chomp(@lines);

    # get rid of blank lines
    @lines = grep { $_ ne '' } @lines;
    my $fileHandle;
    for my $line (@lines) {
        if ( !defined($fileHandle) ) {
            my $currSldFile = "$dir/$line";
            open( $fileHandle, ">", $currSldFile )
                or die "Unable to open file $currSldFile";
            $sldFileHash->{$line} = $currSldFile;
        }
        else {
            print $fileHandle $line;
            if ( $line =~ /^<\/StyledLayerDescriptor>$/ ) {

                # this is the last line, so close the file
                close($fileHandle);
                undef $fileHandle;
            }
        }

    }

    # make sure the file handle is closed.
    if ( defined $fileHandle ) {
        close($fileHandle);
    }
    return $sldFileHash;
}

# Format of data section:
#
# sld name
# sld xml
# sld name
# sld xml
# ...
__DATA__
8 thresholds
<?xml version="1.0"?>
<StyledLayerDescriptor version="1.1.0" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd" xmlns="http://www.opengis.net/sld"  xmlns:se="http://www.opengis.net/se" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <se:Name >sequential_bu_9_sld</se:Name>
    <UserStyle>
      <se:Name >Blues, Light to Dark (Seq), 9</se:Name>
      <se:FeatureTypeStyle >
        <se:Rule>
          <se:RasterSymbolizer>
            <se:Opacity>1.0</se:Opacity>
            <se:ColorMap>
              <se:Categorize fallbackValue="#ff00ff">
                <se:LookupValue>Rasterdata</se:LookupValue>
                <se:Value>#f7fbff</se:Value>
                <se:Threshold/>
                <se:Value>#deebf7</se:Value>
                <se:Threshold/>
                <se:Value>#c6dbef</se:Value>
                <se:Threshold/>
                <se:Value>#9ecae1</se:Value>
                <se:Threshold/>
                <se:Value>#6baed6</se:Value>
                <se:Threshold/>
                <se:Value>#4292c6</se:Value>
                <se:Threshold/>
                <se:Value>#2171b5</se:Value>
                <se:Threshold/>
                <se:Value>#08519c</se:Value>
                <se:Threshold/>
                <se:Value>#08306b</se:Value>
              </se:Categorize>
            </se:ColorMap>
          </se:RasterSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
Large SLD
<?xml version="1.0"?>
<StyledLayerDescriptor version="1.1.0" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd" xmlns="http://www.opengis.net/sld"  xmlns:se="http://www.opengis.net/se" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <se:Name >co_sld</se:Name>
    <UserStyle>
      <se:Name >Yellow-Orange-Red (Seq), 65</se:Name>
      <se:FeatureTypeStyle >
        <se:Rule>
          <se:RasterSymbolizer>
            <se:Opacity>1.0</se:Opacity>
            <se:ColorMap>
              <se:Categorize fallbackValue="#ff00ff">
                <se:LookupValue>Rasterdata</se:LookupValue>
                <se:Value>#FFFCC7</se:Value>
                <se:Threshold/>
                <se:Value>#FFFCAB</se:Value>
                <se:Threshold/>
                <se:Value>#FFF8A4</se:Value>
                <se:Threshold/>
                <se:Value>#FFF69C</se:Value>
                <se:Threshold/>
                <se:Value>#FFF395</se:Value>
                <se:Threshold/>
                <se:Value>#FFEF8E</se:Value>
                <se:Threshold/>
                <se:Value>#FFEC87</se:Value>
                <se:Threshold/>
                <se:Value>#FFEA80</se:Value>
                <se:Threshold/>
                <se:Value>#FFE67A</se:Value>
                <se:Threshold/>
                <se:Value>#FFE373</se:Value>
                <se:Threshold/>
                <se:Value>#FFDF6D</se:Value>
                <se:Threshold/>
                <se:Value>#FFDD68</se:Value>
                <se:Threshold/>
                <se:Value>#FFD963</se:Value>
                <se:Threshold/>
                <se:Value>#FFD65C</se:Value>
                <se:Threshold/>
                <se:Value>#FFD357</se:Value>
                <se:Threshold/>
                <se:Value>#FFD052</se:Value>
                <se:Threshold/>
                <se:Value>#FFCC4E</se:Value>
                <se:Threshold/>
                <se:Value>#FFC74A</se:Value>
                <se:Threshold/>
                <se:Value>#FFC145</se:Value>
                <se:Threshold/>
                <se:Value>#FFBB40</se:Value>
                <se:Threshold/>
                <se:Value>#FFB63C</se:Value>
                <se:Threshold/>
                <se:Value>#FFB037</se:Value>
                <se:Threshold/>
                <se:Value>#FFAA33</se:Value>
                <se:Threshold/>
                <se:Value>#FFA42F</se:Value>
                <se:Threshold/>
                <se:Value>#FF9E2B</se:Value>
                <se:Threshold/>
                <se:Value>#FF9929</se:Value>
                <se:Threshold/>
                <se:Value>#FF9428</se:Value>
                <se:Threshold/>
                <se:Value>#FF8E26</se:Value>
                <se:Threshold/>
                <se:Value>#FF8A24</se:Value>
                <se:Threshold/>
                <se:Value>#FF8423</se:Value>
                <se:Threshold/>
                <se:Value>#FF7F21</se:Value>
                <se:Threshold/>
                <se:Value>#FF7A20</se:Value>
                <se:Threshold/>
                <se:Value>#FF751F</se:Value>
                <se:Threshold/>
                <se:Value>#FF6F1D</se:Value>
                <se:Threshold/>
                <se:Value>#FF661C</se:Value>
                <se:Threshold/>
                <se:Value>#FF5E1A</se:Value>
                <se:Threshold/>
                <se:Value>#FF5618</se:Value>
                <se:Threshold/>
                <se:Value>#FF4F17</se:Value>
                <se:Threshold/>
                <se:Value>#FF4815</se:Value>
                <se:Threshold/>
                <se:Value>#FF4014</se:Value>
                <se:Threshold/>
                <se:Value>#FF3913</se:Value>
                <se:Threshold/>
                <se:Value>#FD3312</se:Value>
                <se:Threshold/>
                <se:Value>#FA2E11</se:Value>
                <se:Threshold/>
                <se:Value>#F52810</se:Value>
                <se:Threshold/>
                <se:Value>#F2240F</se:Value>
                <se:Threshold/>
                <se:Value>#EF1F0E</se:Value>
                <se:Threshold/>
                <se:Value>#EB1A0C</se:Value>
                <se:Threshold/>
                <se:Value>#E8150B</se:Value>
                <se:Threshold/>
                <se:Value>#E5110A</se:Value>
                <se:Threshold/>
                <se:Value>#E20F0A</se:Value>
                <se:Threshold/>
                <se:Value>#DC0C0B</se:Value>
                <se:Threshold/>
                <se:Value>#D6090B</se:Value>
                <se:Threshold/>
                <se:Value>#D1070B</se:Value>
                <se:Threshold/>
                <se:Value>#CD040C</se:Value>
                <se:Threshold/>
                <se:Value>#C7030D</se:Value>
                <se:Threshold/>
                <se:Value>#C2010D</se:Value>
                <se:Threshold/>
                <se:Value>#BC000E</se:Value>
                <se:Threshold/>
                <se:Value>#B6000E</se:Value>
                <se:Threshold/>
                <se:Value>#AE000E</se:Value>
                <se:Threshold/>
                <se:Value>#A6000E</se:Value>
                <se:Threshold/>
                <se:Value>#9E000E</se:Value>
                <se:Threshold/>
                <se:Value>#96000E</se:Value>
                <se:Threshold/>
                <se:Value>#8E000E</se:Value>
                <se:Threshold/>
                <se:Value>#86000E</se:Value>
                <se:Threshold/>
                <se:Value>#7F000E</se:Value>
              </se:Categorize>
            </se:ColorMap>
          </se:RasterSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>

