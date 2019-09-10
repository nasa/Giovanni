#!/usr/bin/perl -T

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use strict;
use Safe;
use URI;
use File::Temp;
use File::Basename;
use XML::LibXML;
use Giovanni::Plot;
use Giovanni::Util;
use Giovanni::CGI;

# Disable output buffering
$| = 1;

## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };
 
# Configuration file for Giovanni: contains environment variables and input validation rules
my $cfgFile = ( defined $rootPath ? $rootPath : '/opt/giovanni4/' )
    . 'cfg/giovanni.cfg';
my $error = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Get user input
my $cgi = Giovanni::CGI->new(
   INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
   TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
   REQUIRED_PARAMS =>
        [ 'data','format' ]
    ,
);

# # Get data layer list
my @dataLayerList = ();
foreach my $val ( $cgi->param('data') ) {
    push( @dataLayerList, $val );
}

# Get format
my $format = $cgi->param('format');

# output
my ( $outFile, $outType, $outName );

if ( $format =~ /tif/i ) {
    exit_with_error("data layer is not found")
        unless defined $dataLayerList[0];
    my $uri     = URI->new( $dataLayerList[0] );
    print STDERR "uri is $dataLayerList[0]\n";
    my $q       = Giovanni::CGI->new(
        INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
        TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
        QUERY           => $uri->query() );
    my $session = $q->param('SESSION');
    my $rset = $q->param('RESULTSET');
    my $result = $q->param('RESULT');
    my $dataFile = $q->param('DATAFILE');
    my $dLayer = $q->param('LAYERS');
    #ignore contour layer
    $dLayer =~ s/_contour//i;
    #set data file path
    my $dataDir = qq($GIOVANNI::SESSION_LOCATION/$session/$rset/$result/);
    $dataFile = $dataDir . $dataFile;
    #if the data file is not in current session directory, get data file location from the manifest file
    unless (-f $dataFile) {
       my @resultFiles = glob ($dataDir."mfst.result*".$dLayer."*.xml");
       foreach my $rFile(@resultFiles) {
          my $fileContent = Giovanni::Util::parseXMLDocument($rFile);
          $dataFile = $fileContent->findvalue('/manifest/fileList/file');
          $dataFile =~ s/^\s+|\s+$//g;
          last if -f $dataFile;
       }
    }
    my ( $fname, $dirname, $suffix ) = fileparse( $dataFile, qr/\.[^.]+$/ );
    $outFile = "$dirname/$fname.tif";
    #tif file is not pregenerated
    unless (-f $outFile) {
       #append variable name
       $dataFile = "NETCDF:\"$dataFile\":$dLayer";
       unless ( -f $outFile) {
         my $rc
           = system("gdalwarp -t_srs EPSG:4326 $dataFile $outFile >/dev/null");
         if ($rc) {
           exit_with_error("gdalwarp command is failed");
         }
       }
    }
    $outType = 'image/tiff';
    $outName = 'GIOVANNI-' . $fname;
    $outName = $outName . '.tif' unless ( $outName =~ /\.tif$/i );
}

else {

    # Get overlay list
    my @overlayLayerList = ();
    foreach my $val ( $cgi->param('overlay') ) {
        push( @overlayLayerList, $val );
    }

    # Get caption
    my $caption = $cgi->param('caption');

    # Get title
    my $title = $cgi->param('title');
    my $subTitle = $cgi->param('subtitle');

    # Make sure that layers are fully qualified URLs
    foreach my $layer (@dataLayerList) {
        $layer = Giovanni::Util::createAbsUrl($layer);
        $layer =~ s/(daac-bin\/)+/daac-bin\//;
    }
    foreach my $layer (@overlayLayerList) {
        $layer = Giovanni::Util::createAbsUrl($layer);
        $layer =~ s/(daac-bin\/)+/daac-bin\//;
    }

    exit_with_error("Need at least a data layer; none found.")
        unless @dataLayerList;

    # Validate layers
    foreach my $layer ( ( @dataLayerList, @overlayLayerList ) ) {
        my $uri = URI->new($layer);

        # Check for trusted servers
        my $trustServerFlag = 0;
        foreach my $server (@GIOVANNI::TRUSTED_SERVERS) {
            if ( $uri->host() =~ /$server/ ) {
                $trustServerFlag = 1;
            }
        }
        unless ($trustServerFlag) {
            print STDERR "$layer not trusted\n";
            exit_with_error("Layer not trusted.");
        }
    }

    # Create a plot
    my $plot = Giovanni::Plot->new();

    # Add caption
    if ( $caption =~ /\S+/ ) {
       $caption =~ s/\+/\n/g;
       $plot->addCaption($caption);
    }
    # Add title
    $title =~ s/^\s+//;
    $title =~ s/\+/\n/g;
    $title =~ s/^\n//;
    $title =~ s/over/\nover/g;
    $plot->addTitle($title) if ( $title =~ /\S+/ );

    # Add sub-titles
    $plot->addSubTitle($subTitle) if ( $title =~ /\S+/ );

    # Add layers and overlays
    $plot->addWmsLayers(
        layers   => \@dataLayerList,
        overlays => \@overlayLayerList
    );

    if ( uc($format) eq 'PNG' ) {
        $outFile = $plot->renderPNG();
        $outType = 'image/png';
        my ( $fname, $dirname, $suffix )
            = fileparse( $outFile, qr/\.[^.]+$/ );
        $outName = 'GIOVANNI-' . $fname;
        $outName = $outName . '.png' unless ( $outName =~ /\.png$/i );
    }
    elsif ( uc($format) eq 'KMZ' ) {
        my $newUri  = URI->new( $dataLayerList[0] );
        my $dataCgi = Giovanni::CGI->new( 
           INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
           TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
           QUERY           => $newUri->query() );
        $dataCgi->param( 'TRANSPARENT', 'true' );
        $newUri->query( $dataCgi->query_string() );
        $dataLayerList[0] = $newUri->as_string();
        my $bbox      = $dataCgi->param('BBOX');
        my $timeStamp = $dataCgi->param('TIME');
        my $layerName = $dataCgi->param('LAYERS');
        $outType = 'application/vnd.google-earth.kmz';
        $outFile = $plot->renderKMZ( $layerName, $bbox, $timeStamp );
        my ($fname);

        if ( defined $outFile ) {
            $fname = fileparse( $outFile, qr/\.[^.]+$/ );
        }
        else {
            exit_with_error("Unable to assign a file name");
        }
        $outName = 'GIOVANNI-' . $fname;
        $outName = $outName . '.kmz' unless ( $outName =~ /\.kmz$/i );
    }
}
exit_with_error("Unable to download: failed to create output")
    unless ( -f $outFile );
print $cgi->header(
    -status                      => 200,
    -type                        => $outType,
    -cache_control               => 'no-cache',
    -'Content-Disposition'       => 'attachment; filename="' . $outName . '"',
    -'Content-Transfer-Encoding' => 'binary',
    -'Accept-Ranges'             => 'bytes'
);
print Giovanni::Util::readFile($outFile);
exit;

# A method to exit with 404 HTTP header with appropriate message
sub exit_with_error {
    my ($message) = @_;
    print $cgi->header(
        -status        => 404,
        -type          => 'text/plain',
        -cache_control => 'no-cache'
    );
    print $message;
    exit;
}

