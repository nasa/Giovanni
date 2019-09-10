# This tests to make sure the output time metadata in files is correct.

use Test::More tests => 8;
use File::Temp qw/tempdir/;
use File::Path;
use FindBin;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use XML::LibXML;

use Giovanni::Data::NcFile;

BEGIN { use_ok('Giovanni::Algorithm::CorrelationWrapper') }

# Test that we can find the script by its appropriate name
my $script      = 'correlation_wrapper.pl';
my $script_path = "blib/script/$script";
foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
    next if ( $dir =~ /^\s*$/ );
    last if ( -f $script_path );
    $script_path = "../$script_path";
}
ok( ( -f $script_path ), "find $script" );

my $tempdir = tempdir( CLEANUP => 1 );

my $inXml    = "$tempdir/in.xml";
my $inPaired = "$tempdir/paired.txt";
createInputFiles( $inXml, $inPaired );

# test that we can get the correct start and end time
my ( $start_time, $end_time )
    = Giovanni::Algorithm::CorrelationWrapper::get_start_end_times($inPaired);
is( $start_time, "2004-03-15T00:00:00Z", "Start time correct." );
is( $end_time,   "2004-03-15T08:59:59Z", "End time correct." );

####
## http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/index-debug.html#service=CoMp&starttime=2004-03-15T00:00:00Z&endtime=2004-03-15T08:59:59Z&bbox=177.7148,-15.6152,-178.2422,-11.3965&data=MAI3CPASM_5_2_0_RH(z%3D700)%2CMAT3CPRAD_5_2_0_CLOUD(z%3D700)
####

my $dataInfoX = "$tempdir/dataInfoX.xml";
open OUT, ">", $dataInfoX or die "Could not open $dataInfoX: $!\n";
print OUT << "XML";
<varList>
  <var id="MAI3CPASM_5_2_0_RH" zDimUnits="hPa" long_name="Relative Humidity, Instantaneous" searchIntervalDays="183.0" sampleOpendap="http://goldsmr3.sci.gsfc.nasa.gov/opendap/ncml/MERRA/MAI3CPASM.5.2.0/1979/01/MERRA100.prod.assim.inst3_3d_asm_Cp.19790101.hdf.ncml.html" dataProductTimeFrequency="3" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP_TIMESPLIT" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MERRA%203D%20IAU%20State%2C%20Meteorology%20Instantaneous%203-hourly%20(p-coord%2C%201.25x1.25L42)%20V5.2.0;agent_id=OPeNDAP_TIMESPLIT;variables=RH" startTime="1979-01-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="3-hourly" dataProductVersion="5.2.0" sampleFile="" east="180.0" dataProductShortName="MAI3CPASM" osdd="" resolution="1.25 deg." dataProductPlatformInstrument="MERRA Model" quantity_type="Atmospheric Moisture" zDimName="Height" deflationLevel="1" dataFieldStandardName="relative_humidity" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="fraction" latitudeResolution="1.25" accessName="RH" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="0" longitudeResolution="1.25" dataProductEndTimeOffset="0" west="-180.0" zDimValues="1000 975 950 925 900 875 850 825 800 775 750 725 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 40 30 20 10 7 5 4 3 2 1 0.7 0.5 0.4 0.3 0.1" sdsName="RH" timeIntvRepPos="start" dataProductBeginDateTime="1979-01-01T00:00:00Z">
    <slds>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/divergent_burd_11_sld.xml" label="Blue-Red (Div), 11"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/spectral_div_11_inv_sld.xml" label="Spectral, Inverted (Div), 11"/>
    </slds>
  </var>
</varList>
XML
close OUT;

my $dataInfoY = "$tempdir/dataInfoY.xml";
open OUT, ">", $dataInfoY or die "Could not open $dataInfoY: $!\n";
print OUT << "XML";
<varList>
  <var id="MAT3CPRAD_5_2_0_CLOUD" zDimUnits="hPa" long_name="3D Cloud Fraction, time average" sampleOpendap="http://goldsmr3.sci.gsfc.nasa.gov/opendap/ncml/MERRA/MAT3CPRAD.5.2.0/1979/01/MERRA100.prod.assim.tavg3_3d_rad_Cp.19790101.hdf.ncml.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP_TIMESPLIT" endTime="2038-01-19T03:14:07Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MERRA%203D%20IAU%20Diagnostic%2C%20Radiation%2C%20Time%20average%203-hourly%20(1.25x1.25L42)%20V5.2.0;agent_id=OPeNDAP_TIMESPLIT;variables=CLOUD" startTime="1979-01-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="3-hourly" dataProductVersion="5.2.0" sampleFile="" east="180.0" dataProductShortName="MAT3CPRAD" osdd="" resolution="1.25 deg." dataProductPlatformInstrument="MERRA Model" quantity_type="Cloud Fraction" zDimName="Height" dataFieldStandardName="cloud_area_fraction_in_atmosphere_layer" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="fraction" latitudeResolution="1.25" accessName="CLOUD" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." dataProductStartTimeOffset="1" longitudeResolution="1.25" dataProductEndTimeOffset="0" west="-180.0" zDimValues="1000 975 950 925 900 875 850 825 800 775 750 725 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 40 30 20 10 7 5 4 3 2 1 0.7 0.5 0.4 0.3 0.1" sdsName="CLOUD" timeIntvRepPos="middle" dataProductBeginDateTime="1979-01-01T00:00:00Z">
    <slds>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/spectral_div_11_inv_sld.xml" label="Spectral, Inverted (Div), 11"/>
    </slds>
  </var>
</varList>
XML
close OUT;

my $start = "2004-03-15T00:00:00Z";
my $end   = "2004-03-15T08:59:59Z";

# Use a small bbox over the 180 meridian
my $bbox    = '177.7148,-15.6152,-178.2422,-11.3965';
my $outfile = "$tempdir/out_correlation_wrapper.nc";
my $cmd
    = "$script_path -v 2 -O $outfile -f $inXml -b $bbox -s $start -e $end -d $dataInfoX,$dataInfoY";

$cmd .= " -x MAI3CPASM_5_2_0_RH";
$cmd .= " -y MAT3CPRAD_5_2_0_CLOUD";
my $rc = system($cmd);
is( $rc, 0, "Execute $cmd" ) or die "Couldn't correlate";

# check to make sure output looks good
ok( -e $outfile, "Output file created" );
my $xpc = Giovanni::Data::NcFile::get_xml_header($outfile);
my ($startNode)
    = $xpc->findnodes(
    qq(/nc:netcdf/nc:attribute[\@name="matched_start_time"]/\@value));
is( $startNode->getValue(), $start, "Correct start time" );
my ($endNode) = $xpc->findnodes(
    qq(/nc:netcdf/nc:attribute[\@name="matched_end_time"]/\@value)
);
is( $endNode->getValue(), $end, "Correct end time" );

#=====================================================

sub createInputFiles {
    my ( $inXml, $inPaired ) = @_;
    my $ncDir = dirname( abs_path(__FILE__) ) . "/nc";
    my @ids   = ( "MAT3CPRAD_5_2_0_CLOUD", "MAI3CPASM_5_2_0_RH" );
    my @files = (
        [   "$ncDir/scrubbed.MAT3CPRAD_5_2_0_CLOUD.200403150000.nc",
            "$ncDir/scrubbed.MAT3CPRAD_5_2_0_CLOUD.200403150300.nc",
            "$ncDir/scrubbed.MAT3CPRAD_5_2_0_CLOUD.200403150600.nc"
        ],
        [   "$ncDir/scrubbed.MAI3CPASM_5_2_0_RH.200403150000.nc",
            "$ncDir/scrubbed.MAI3CPASM_5_2_0_RH.200403150300.nc",
            "$ncDir/scrubbed.MAI3CPASM_5_2_0_RH.200403150600.nc"
        ]
    );

    my $dom  = XML::LibXML::Document->createDocument();
    my $root = $dom->createElement("data");
    $dom->setDocumentElement($root);

    for ( my $i = 0; $i < scalar(@ids); $i++ ) {
        my $dataFileList = $dom->createElement("dataFileList");
        $root->appendChild($dataFileList);
        $dataFileList->setAttribute( "id", $ids[$i] );
        for my $file ( @{ $files[$i] } ) {
            my $dataFile = $dom->createElement("dataFile");
            $dataFileList->appendChild($dataFile);
            $dataFile->appendText($file);
        }
    }

    open( FILE, ">", $inXml ) or die "Unable to open $inXml";
    print FILE $dom->toString();
    close(FILE);

    # and created the paired file
    open( FILE, ">", $inPaired ) or die "Unable to open $inPaired";
    for ( my $i = 0; $i < 3; $i++ ) {
        print FILE $files[0]->[$i] . " " . $files[1]->[$i] . "\n";
    }
    close(FILE);

}


