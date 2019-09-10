# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Util.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 75;
use File::Temp qw/tempfile tempdir tmpnam/;
use File::Basename;
use XML::LibXML;

BEGIN { use_ok('Giovanni::Util') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Tests for Giovanni::Util::getColorbarMinMax
my ( $cbMin, $cbMax ) = Giovanni::Util::getColorbarMinMax(
    NOMINAL_MIN => 0,
    NOMINAL_MAX => 2,
    DATA_MIN    => -1,
    DATA_MAX    => 11
);
is_deeply( [ $cbMin, $cbMax ], [ 0, 2 ], "Simple min/max test" );

( $cbMin, $cbMax ) = Giovanni::Util::getColorbarMinMax(
    DATA_MIN => -1,
    DATA_MAX => 11
);
is_deeply( [ $cbMin, $cbMax ], [ -1, 11 ], "Min/max no nominal test" );

( $cbMin, $cbMax ) = Giovanni::Util::getColorbarMinMax(
    NOMINAL_MIN => -20,
    DATA_MIN    => -10,
    DATA_MAX    => -1
);
is_deeply( [ $cbMin, $cbMax ], [ -20, -1 ], "Just nominal min" );

( $cbMin, $cbMax ) = Giovanni::Util::getColorbarMinMax(
    NOMINAL_MIN => 0,
    DATA_MIN    => -10,
    DATA_MAX    => -1
);
is_deeply( [ $cbMin, $cbMax ], [ 0, 1 ], "Weird nominal min" );

( $cbMin, $cbMax ) = Giovanni::Util::getColorbarMinMax(
    NOMINAL_MAX => 2,
    DATA_MIN    => -1,
    DATA_MAX    => 11
);
is_deeply( [ $cbMin, $cbMax ], [ -1, 2 ], "Just nominal max" );

( $cbMin, $cbMax ) = Giovanni::Util::getColorbarMinMax(
    NOMINAL_MAX => -20,
    DATA_MIN    => -1,
    DATA_MAX    => 11
);
is_deeply( [ $cbMin, $cbMax ], [ -21, -20 ], "Weird nominal max" );

( $cbMin, $cbMax ) = Giovanni::Util::getColorbarMinMax(
    DATA_MIN => 0,
    DATA_MAX => 0
);
is_deeply( [ $cbMin, $cbMax ], [ 0, 1 ], "Same min/max" );

# Tests for Giovanni::Util::createXMLDocument<
my $doc = Giovanni::Util::createXMLDocument('test');
ok( $doc->nodeName eq 'test', "Root element name matches" );

#Tests for Giovanni::Util::writeFile
my $fileName = "test.txt";
my $flag = Giovanni::Util::writeFile( $fileName, "test" );
ok( $flag,        "File,$fileName, created" );
ok( -f $fileName, "File, $fileName, exists" );
$flag = Giovanni::Util::writeFile( $fileName, "xyz", '>>' );
is( $flag, 1, "File, $fileName, appended" );
my $fileContent = Giovanni::Util::readFile($fileName);
is( $fileContent, "testxyz", "File content after appending verified" );
unlink($fileName) if ( -f $fileName );
$fileName = "/test.txt";
$flag = Giovanni::Util::writeFile( $fileName, "test" );
ok( $flag == 0,    "File, $fileName, not created" );
ok( !-f $fileName, "File, $fileName, doesn't exist" );

#Tests for Giovanni::Util::convertFilePathToUrl
my ( $fh, $file ) = tempfile();
my $dir = dirname($file);

# Create a mapping of file path to URL
# Case of mapping not existing for the file in question
my %URL_LOOKUP = ( "xyz" => 'http://xyz.gov/somepath/giovanni' );
my $url = Giovanni::Util::convertFilePathToUrl( $file, \%URL_LOOKUP );
ok( !defined $url, "File-to-URL: match not found as expected" );

delete $URL_LOOKUP{xyz};
$URL_LOOKUP{$dir} = 'http://xyz.gov/somepath/giovanni';
$url = Giovanni::Util::convertFilePathToUrl( $file, \%URL_LOOKUP );
is( $url,
    $URL_LOOKUP{$dir} . '/' . basename($file),
    "File-to-URL: match found"
);
my $path = Giovanni::Util::convertUrlToFilePath( $url, \%URL_LOOKUP );
is( $path, $file, "URL-to-File: match found" );

my $portal = "abcd";
$url = Giovanni::Util::convertFilePathToUrl( $file, \%URL_LOOKUP, $portal );
is( $url,
    $URL_LOOKUP{$dir} . '/' . basename($file) . "#$portal",
    "File-to-URL: match found"
);
$path = Giovanni::Util::convertUrlToFilePath( $url, \%URL_LOOKUP );
is( $path, $file, "URL-to-File: match found" );

# Tests for relative URLs
$URL_LOOKUP{$dir} = '/session';
$ENV{SCRIPT_URI} = 'http://xyz.gov/somepath/giovanni/daac-bin/test.pl';
$url = Giovanni::Util::convertFilePathToUrl( $file, \%URL_LOOKUP );
is( $url,
    'http://xyz.gov/session/' . basename($file),
    "File-to-URL: match found in relative URL case absolute path"
);
$path = Giovanni::Util::convertUrlToFilePath( $url, \%URL_LOOKUP );
is( $path, $file, "URL-to-File: match found" );

$URL_LOOKUP{$dir} = 'session/tmp';
$url = Giovanni::Util::convertFilePathToUrl( $file, \%URL_LOOKUP );
is( $url,
    'http://xyz.gov/somepath/giovanni/session/tmp/' . basename($file),
    "File-to-URL: match found in relative URL case with relative path"
);
$path = Giovanni::Util::convertUrlToFilePath( $url, \%URL_LOOKUP );
is( $path, $file, "URL-to-File: match found" );

# Tests for creating absolute URLs from absolute or relative URLs
my $refUrl = 'http://abc.gov/session/img.png';
$url = Giovanni::Util::createAbsUrl($refUrl);
is( $url, $refUrl, "createAbsUrl: case of absolute URL as input" );

$url = Giovanni::Util::createAbsUrl('/session/xyz.png');
is( $url,
    "http://xyz.gov/session/xyz.png",
    "createAbsUrl: case of relative URL with absolute path"
);

$url = Giovanni::Util::createAbsUrl('session/xyz.png');
is( $url,
    "http://xyz.gov/somepath/giovanni/session/xyz.png",
    "createAbsUrl: case of relative URL with relative path"
);

# Case of proxied requests and URL creation
$ENV{HTTP_X_FORWARDED_HOST} = 'abc.gov';
$url = Giovanni::Util::createAbsUrl('session/xyz.png');
is( $url,
    "http://abc.gov/somepath/giovanni/session/xyz.png",
    "createAbsUrl: case of relative URL with relative path"
);
$url = Giovanni::Util::createAbsUrl('session/xyz.png');
is( $url,
    "http://abc.gov/somepath/giovanni/session/xyz.png",
    "createAbsUrl: case of relative URL with relative path"
);

ok( Giovanni::Util::isUUID('00488F96-F7AC-11E1-9A31-A48269B977CC'),
    "Validation succeeds with a correct UUID" );
ok( !Giovanni::Util::isUUID('xyz'), "Validation fails with an invalid UUID" );

# Tests for getSeasonLabels()
my @seasonList = Giovanni::Util::getSeasonLabels('01,03');
is( join( ", ", @seasonList ),
    "Jan, Mar", "Months 01, 03 converted to Jan, Mar" );

@seasonList = Giovanni::Util::getSeasonLabels('DJF,JJA');
is( join( ", ", @seasonList ),
    "Dec-Jan-Feb(DJF), Jun-Jul-Aug(JJA)",
    "Months DJF,JJA converted to Dec-Jan-Feb, Jun-Jul-Aug"
);

# Tests for getDataFilesFromManifest
my $manifestString
    = '<manifest title="Test1"><fileList><file>a</file><file>b</file></fileList></manifest>';
my ( $mfstFh1, $mfstFile1 ) = tempfile();
print $mfstFh1 $manifestString;
close($mfstFh1);
my $dataHashRef = Giovanni::Util::getDataFilesFromManifest($mfstFile1);
is( $dataHashRef->{title}, "Test1", "Verified title from manifest file" );
is( join( ",", @{ $dataHashRef->{data} } ),
    "", "Case of missing files in manifest file" );

my ( $mfstFh2, $mfstFile2 ) = tempfile();
my ( $mfstFh3, $mfstFile3 ) = tempfile();
$manifestString
    = "<manifest title='Test2'><fileList><file>$mfstFile1</file><file>$mfstFile2</file></fileList></manifest>";
print $mfstFh3 $manifestString;
close($mfstFh3);
$dataHashRef = Giovanni::Util::getDataFilesFromManifest($mfstFile3);
is( $dataHashRef->{title}, "Test2", "Verified title from manifest file" );
is( join( ",", @{ $dataHashRef->{data} } ),
    "$mfstFile1,$mfstFile2",
    "Case of valid files in manifest file"
);

# Tests for crateXMLElement
my ($refElem) = XML::LibXML::Element->new('test');
$refElem->appendTextChild( 'xyz', "kljafklajlf" );
my $newElem1
    = Giovanni::Util::createXMLElement( 'test', xyz => "kljafklajlf" );
is( $newElem1->toString(), $refElem->toString(), "Elements match" );
my $newElem2
    = Giovanni::Util::createXMLElement( 'test', xyz => "kljafklajlff" );
isnt( $newElem2->toString(), $refElem->toString(),
    "Elements don't match as expected" );
my $refElem3 = XML::LibXML::Element->new('test');
$refElem3->appendTextNode("kljafklajlff");
my $newElem3 = Giovanni::Util::createXMLElement( 'test', "kljafklajlff" );
is( $newElem3->toString(), $refElem3->toString(),
    "Elements with text content only match" );

# Tests for restTime
my $dateStr = "2012-02-28T23:30:00Z";
my $time = Giovanni::Util::resetTime( $dateStr, "START_DAY" );
is( $time, "2012-02-28", "Reset to start of the day" );

$time = Giovanni::Util::resetTime( $dateStr, "END_DAY" );
is( $time, "2012-02-28T23:59:59", "Reset to end of the day of the month" );

$time = Giovanni::Util::resetTime( $dateStr, "START_MONTH" );
is( $time, "2012-02-01", "Reset to start of the month" );

$time = Giovanni::Util::resetTime( $dateStr, "END_MONTH" );
is( $time, "2012-02-29T23:59:59", "Reset to end of the month" );

$time = Giovanni::Util::resetStartTime( $dateStr, "hourly" );
is( $time, undef, "Reset of hourly is not supported" );

$time = Giovanni::Util::resetStartTime( $dateStr, "daily" );
is( $time, "2012-02-28", "Reset to start of the day for dailies" );

$time = Giovanni::Util::resetStartTime( $dateStr, "monthly" );
is( $time, "2012-02-01", "Reset to start of the day for monthlies" );

$time = Giovanni::Util::resetEndTime( $dateStr, "daily" );
is( $time, "2012-02-28T23:59:59", "Reset to end of the day for monthlies" );
$time = Giovanni::Util::resetEndTime( $dateStr, "monthly" );
is( $time, "2012-02-29T23:59:59", "Reset to end of the day for monthlies" );

my ( $width, $height ) = Giovanni::Util::getLabelSize(1000);
is( $width,  27, "getLabelSize(): verified width" );
is( $height, 15, "getLabelSize(): verified height" );

# Case of parsing well-balanced XML
my $tmpFile = File::Temp->new();
print $tmpFile '<giovanni name="g4"><location>GSFC</location></giovanni>';
close($tmpFile)
    or die "Test for parseXMLDocument(): failed to close $tmpFile";
$doc = Giovanni::Util::parseXMLDocument( $tmpFile->filename );
is( ref $doc, 'XML::LibXML::Element', "XML document parsed successfully" );

# Case of parsing unbalanced XML
$tmpFile = File::Temp->new();
print $tmpFile '<giovanni name="g4"><location>GSFC</location>';
close($tmpFile)
    or die "Test for parseXMLDocument(): failed to close $tmpFile";
$doc = Giovanni::Util::parseXMLDocument( $tmpFile->filename );
is( $doc, undef, "Parsing invalid XML document" );

# Getting data min max in a data file for a given variable
my $cdlFile = File::Temp->new( SUFFIX => '.cdl' );
my @cdl = <::DATA>;
print $cdlFile @cdl;
close $cdlFile;
close(::DATA);
my $ncFile = File::Temp->new( SUFFIX => '.nc' );
`ncgen -o $ncFile $cdlFile`;
my ( $min, $max )
    = Giovanni::Util::getNetcdfDataRange( $ncFile,
    'OMAERUVd_003_FinalAerosolExtOpticalDepth388' );
is( sprintf( "%.4f", $min ), 0.2243, "Verified min" );
is( sprintf( "%.4f", $max ), 0.7167, "Verified max" );

# Testing cf2datetime
# Case of invalid CF-1
my $dateStr1 = Giovanni::Util::cf2datetime( 0, "xyz since 1970-01-01" );
is( $dateStr1, undef, "Case of invalid time units" );
my $dateStr2 = Giovanni::Util::cf2datetime( 0, "seconds since 1970-001" );
is( $dateStr2, undef, "Case of invalid time reference" );
my $dateStr3
    = Giovanni::Util::cf2datetime( 0, "seconds since 1980-02-28T23:59:59" );
is( $dateStr3, "1980-02-28T23:59:59Z",
    "Case of valid unit and time references" );
my $dateStr4
    = Giovanni::Util::cf2datetime( 1, "seconds since 1980-02-28T23:59:59" );
is( $dateStr4, "1980-02-29T00:00:00Z",
    "Case of valid unit (seconds) and time references" );
my $dateStr5
    = Giovanni::Util::cf2datetime( 86400, "seconds since 1980-02-28" );
is( $dateStr5, "1980-02-29T00:00:00Z",
    "Case of valid unit (seconds) and time references" );
my $dateStr6 = Giovanni::Util::cf2datetime( 1, "days since 1980-02-28" );
is( $dateStr6, "1980-02-29T00:00:00Z",
    "Case of valid unit (days) and time references" );
my $dateStr7 = Giovanni::Util::cf2datetime( 1, "months since 1980-02-01" );
is( $dateStr7, "1980-03-01T00:00:00Z",
    "Case of valid unit (months)  and time references" );
my $dateStr8 = Giovanni::Util::cf2datetime( 1, "years since 1980-02-01" );
is( $dateStr8, "1981-02-01T00:00:00Z",
    "Case of valid unit (years) and time references" );

my %chunkInput = (
    dataStartTime       => "2000-01-01T00:00:00Z",
    dataEndTime         => "2006-12-31T23:59:59Z",
    dataStartTimeOffset => 5,
    dataEndTimeOffset   => 2,
    searchStartTime     => "2003-03-01T10:00:00Z",
    searchEndTime       => "2005-06-10T23:59:59Z"
);
@tChunkList = Giovanni::Util::chunkDataTimeRange(%chunkInput);
is( @tChunkList, 3, "3 time chunks found" );
is( $tChunkList[0]->{overlap},
    'partial', "first chunk partially overlaps with nominal chunk" );
is( $tChunkList[1]->{overlap},
    'full', "second chunk fully overlaps with nominal chunk" );
is( $tChunkList[0]->{start}, "2003-03-01T10:00:05Z", "start offset applied" );
is( $tChunkList[2]->{end},   "2005-06-11T00:00:01Z", "end offset applied" );

$chunkInput{dataTemporalResolution} = 'daily';
@tChunkList = Giovanni::Util::chunkDataTimeRange(%chunkInput);
is( $tChunkList[0]->{start},
    "2003-03-01T00:00:05Z",
    "use of nominal start time for daily with applied offset" );

is( Giovanni::Util::getEarliestTime("2003-01-01T00:00:00Z"),
    "2003-01-01T00:00:00Z", "earliest time correct (one time)" );
is( Giovanni::Util::getEarliestTime(
        "2003-01-01T00:00:00Z", "2005-01-01T23:59:59Z",
        "2002-12-31T23:59:59Z", "2002-12-31T22:00:00Z"
    ),
    "2002-12-31T22:00:00Z",
    "earliest time correct (multiple times)"
);
is( Giovanni::Util::getLatestTime("2003-01-01T00:00:00Z"),
    "2003-01-01T00:00:00Z", "latest time correct (one time)" );

is( Giovanni::Util::getLatestTime(
        "2003-01-01T00:00:00Z", "2005-01-01T00:00:00Z",
        "2002-12-31T23:59:59Z", "2002-12-31T22:00:00Z"
    ),
    "2005-01-01T00:00:00Z",
    "latest time correct (multiple time)"
);


ok(Giovanni::Util::strEndsWith("hello world","world"),"Does end with");
ok(!Giovanni::Util::strEndsWith("hello world","hello"),"Does not end with");

__DATA__
netcdf .20060101-20060105.77E_6N_84E_11N {
dimensions:
    lat = 5 ;
    lon = 7 ;
variables:
    float OMAERUVd_003_FinalAerosolExtOpticalDepth388(lat, lon) ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:_FillValue = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:units = "1" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:title = "Final Aerosol Extinction Optical Depth at 388 nm" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:UniqueFieldDefinition = "OMI-Specific" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:missing_value = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:origname = "FinalAerosolExtOpticalDepth388" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolExtOpticalDepth388" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:orig_dimname_list = "XDim " ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:standard_name = "finalaerosolextopticaldepth388" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:quantity_type = "Total Aerosol Optical Depth" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:product_short_name = "OMAERUVd" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:product_version = "003" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:long_name = "Aerosol Optical Depth 388 nm" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:latitude_resolution = 1. ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth388:longitude_resolution = 1. ;
    float lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
        lat:long_name = "Latitude" ;
    float lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;

data:

 OMAERUVd_003_FinalAerosolExtOpticalDepth388 =
  _, _, _, _, _, _, _,
  _, _, _, _, _, _, _,
  0.4653, _, _, _, _, _, _,
  0.2786, 0.3159, _, 0.5497, _, _, _,
  0.2243, _, 0.7167, _, _, _, _ ;

 lat = 6.5, 7.5, 8.5, 9.5, 10.5 ;

 lon = 77.5, 78.5, 79.5, 80.5, 81.5, 82.5, 83.5 ;
}
