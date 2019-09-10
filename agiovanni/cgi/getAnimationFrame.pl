#!/usr/bin/perl -T

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use strict;
use Giovanni::CGI;
use Giovanni::Util;
use File::Temp;
use LWP::UserAgent;
use File::Basename;
use URI;
use Safe;
use File::Temp qw/ tempdir /;
use Giovanni::Plot;
use LWP::UserAgent;
use XML::LibXML;
use Giovanni::Data::NcFile;
use JSON;

# Set the umask so that files/directories are group writable
umask 002;

# LWP::UserAgent is used instead of wget, so define a new instance and tie
# to environment proxy
my $ua = LWP::UserAgent->new();
$ua->env_proxy;

# Disable output buffering
$| = 1;

# Clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

# Read input
my $cgi = CGI->new();

# Configuration file for Giovanni: contains environment variables and
# input validation rules.
# Read the configuration file.
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

$cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS =>
        [
          'WIDTH', 'HEIGHT', 'SESSION', 'RESULTSET', 'RESULT', 'TIME',
          'BBOX', 'SLD'
        ],
);

my $width = $cgi->param('WIDTH');
my $height = $cgi->param('HEIGHT');

# get the session/resultset/result info and create the session tmp directory
my $sessionId = $cgi->param('SESSION');
my $resultSetId = $cgi->param('RESULTSET');
my $resultId = $cgi->param('RESULT');

# validate the input IDs
exit_with_error("Invalid session ID")
    unless Giovanni::Util::isUUID($sessionId);
exit_with_error("Invalid resultset ID")
    unless Giovanni::Util::isUUID($resultSetId);
exit_with_error("Invalid result ID") unless Giovanni::Util::isUUID($resultId);

# get the data file location
my ( $dataFile, $imgFile );
my $resultDir
    = qq($GIOVANNI::SESSION_LOCATION/$sessionId/$resultSetId/$resultId/);
my $dTime = $cgi->param('TIME');

# Get layer name
my $inputLayer = $cgi->param('LAYERS');
my $backLayer = ( $inputLayer =~ /\,(.+)$/ ) ? $1 : "coastline,countries";
($inputLayer) = split( ",", $inputLayer );

# Get animation frame information
my $jFile = $resultDir . "/" . $inputLayer . "_animation.json";
my $json_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $jFile)
      or die("Can't open \$filename\": $!\n");
   local $/;
   <$json_fh>
};
my $json = JSON->new;
my $frameInfo = $json->decode( $json_text );

my @frames = @{$frameInfo->{layers}->{layer}->[0]->{frames}};
foreach my $frame ( @frames ) {
   if ( $frame->{time} eq $dTime ) {
      $dataFile = $frame->{data};
      $imgFile  = $frame->{image};
      last;
   }
}

$dataFile = ( $dataFile =~ /^((\w|-|\/|\.|\+)+)/ ) ? $1 : '';
$imgFile = ( $imgFile =~ /^((\w|-|\/|\.|\+)+)/ ) ? $1 : '';

# Get the variable info file
my $varInfoFile
    = $resultDir . '/mfst.data_field_info+d' . $inputLayer . '.xml';

# Figure out what bounding box to use. We want to visualize the bounding box
# that is an intersection of the output data file's bounding box, the user's
# bounding box, and the data set's bounding box. This is to fix bug
# FEDGIANNI-1691.
my $bboxParam  = $cgi->param('BBOX');
my $newBbox    = $bboxParam;
my (%outParam) = adjust_bbox_for_data(
    VAR_INFO  => $varInfoFile,
    DATA_FILE => $dataFile,
    BBOX      => $newBbox,
    WIDTH     => $width,
    HEIGHT    => $height
);
$height  = $outParam{HEIGHT};
$width   = $outParam{WIDTH};
$newBbox = $outParam{BBOX};

# Get and split the BBOX if required (crosses the 180 meridian) into a BBOX LIST
# This list will be used for all data URLs, since its assumed all data layers
# are over the same region of the grid.
my @bbox = split( ',', $newBbox );
my @bboxList = splitBoundingBox(@bbox);

# For the data across 180
if ( scalar(@bboxList) == 2 ) {
   #calculate pixel size
   my $mCmd = "gdalinfo $imgFile \| grep 'Pixel Size'";
   my $pInfo = `$mCmd`;
   $pInfo = ( $pInfo =~ /\((.+)\)$/ ) ? $1: undef;
   exit_with_error("Misssing pixel size information") unless defined $pInfo;
   my ($h,$v) = split (",",$pInfo);
   my (@lWin,@rWin);
   if (defined $h) {
      $h = abs($h/2);
      $lWin[0] = $bboxList[0][0] + $h;
      $lWin[2] = $bboxList[0][2] - $h;
      $rWin[0] = $bboxList[1][0] + $h;
      $rWin[2] = $bboxList[1][2] - $h;
   }
   if (defined $v) {
      $v = abs($v/2);
      $lWin[1] = $bboxList[0][1] +$v;
      $lWin[3] = $bboxList[0][3] -$v;
      $rWin[1] = $bboxList[1][1] +$v;
      $rWin[3] = $bboxList[1][3] -$v;
   }
   my $bString = $lWin[0]." ".$lWin[3]." ".$lWin[2]." ".$lWin[1];
   my $mImage_a = File::Temp->new(
            TEMPLATE => 'mImage_a_XXXX',
            DIR      => $resultDir,
            SUFFIX   => '.png',
            UNLINK   => 1
        );
   $mCmd = "gdal_translate -of PNG -projwin $bString $imgFile $mImage_a >/dev/null";
   print STDERR $mCmd ."\n";
   my $rc = system($mCmd);
   if ($rc) {
      exit_with_error("Failed to translate image");
   }
   $bString = $rWin[0]." ".$rWin[3]." ".$rWin[2]." ".$rWin[1];
   my $mImage_b = File::Temp->new(
            TEMPLATE => 'mImage_b_XXXX',
            DIR      => $resultDir,
            SUFFIX   => '.png',
            UNLINK   => 1
        );
  $mCmd = "gdal_translate -of PNG -projwin $bString $imgFile $mImage_b >/dev/null";
  print STDERR $mCmd ."\n";
  $rc = system($mCmd);
  if ($rc) {
      exit_with_error("Failed to translate image");
   }
  my $translateImage = File::Temp->new(
            TEMPLATE => 'translateImage_XXXX',
            DIR      => $resultDir,
            SUFFIX   => '.png',
            UNLINK   => 1
        );
  $mCmd = "convert $mImage_a $mImage_b +append $translateImage >/dev/null";
  $rc = system($mCmd);
  if ($rc) {
      exit_with_error("Failed to translate image");
   }
  $imgFile = $translateImage;
}
#Resize data image based on the request
my $imgOutput = File::Temp->new(
            TEMPLATE => 'dataImage_a_XXXX',
            DIR      => $resultDir,
            SUFFIX   => '.png',
            UNLINK   => 1
        );
my $cmd = "convert $imgFile -resize " . $width . "x" . $height ."\\! $imgOutput >/dev/null";
my $rc = system($cmd);
if ($rc) {
   exit_with_error("Cannot resize data image file.");
}

# Composite image for output
my $outputFile
    = $resultDir . "/" . $inputLayer . "_" . $dTime . "_overlay.png";
# Frame with title, caption, and legend
my $outputFrame
    = $resultDir . "/" . $inputLayer . "_" . $dTime . "_overlay_frame.png";
# WMS URL for coastline, countrites and us states
my $url
    = $GIOVANNI::WMS{background_wms}."?LAYERS=".$backLayer."&FORMAT=image/png&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=&SRS=EPSG:4326";

my $baseImage = $resultDir . "/baseImage.png";

# Bounding box crosses 180 meridian.
# Download data for the split regions and join them.
if ( scalar(@bboxList) == 2 ) {
    my $width1
        = int( $width
            * ( $bboxList[0][2] - $bboxList[0][0] )
            / ( 360 + $bbox[2] - $bbox[0] ) + 0.5 );
    my $width2
        = int( $width
            * ( $bboxList[1][2] - $bboxList[1][0] )
            / ( 360 + $bbox[2] - $bbox[0] ) + 0.5 );

    # Generate base image of coastline, countries, and us states
    unless ( -f $baseImage ) {
        $url
            = $url
            . "&BBOX="
            . $bboxList[0][0] . ","
            . $bboxList[0][1] . ","
            . $bboxList[0][2] . ","
            . $bboxList[0][3];
        $url        = $url . "&WIDTH=$width1&HEIGHT=$height";
        my $tmpOutput1 = File::Temp->new(
            TEMPLATE => 'baseImage_a_XXXX',
            DIR      => $resultDir,
            SUFFIX   => '.png',
            UNLINK   => 1
        );

        # We are using LWP::UserAgent to get url; this is in favor of and
        # replaces wget.
        # Needed for cloud support of giovanni
        my $ua = LWP::UserAgent->new();
        $ua->env_proxy;
        my $response = $ua->get($url);
        if ( $response->is_success() ) {
            my $data = $response->content();
            if ( open FILE, ">", $tmpOutput1 ) {
                print FILE $data;
                close(FILE);
            }
            else {
                print STDERR "Could not write to $tmpOutput1\n";
                exit_with_error( $response->code() )
                    unless -f $tmpOutput1;
            }
        }
        else {
            print STDERR "Could not get response\n";
            exit_with_error( $response->code() );
        }

        $url
            =~ s/BBOX=$bboxList[0][0],$bboxList[0][1],$bboxList[0][2],$bboxList[0][3]/BBOX=$bboxList[1][0],$bboxList[1][1],$bboxList[1][2],$bboxList[1][3]/;
        $url =~ s/WIDTH=$width1/WIDTH=$width2/;
        my $tmpOutput2 = File::Temp->new(
            TEMPLATE => 'baseImage_b_XXXX',
            DIR      => $resultDir,
            SUFFIX   => '.png',
            UNLINK   => 1
        );
        $response = $ua->get($url);
        if ( $response->is_success() ) {
            my $data = $response->content();
            if ( open FILE, ">", $tmpOutput2 ) {
                print FILE $data;
                close(FILE);
            }
            else {
                die "Could not write to $tmpOutput2"
                    unless -f $tmpOutput2;
            }
        }
        else {
            print STDERR "Could not get response\n";
            Giovanni::Util::exit_with_error( $response->code() );
        }

        $cmd = "convert $tmpOutput1 $tmpOutput2 +append $baseImage >/dev/null";
        $rc = system($cmd);
        if ($rc) { exit_with_error("Failed to merge base iamges"); }
    }
}
else {
    unless ( -f $baseImage ) {
        $url = $url
            . "&WIDTH=$width&HEIGHT=$height&BBOX=$bbox[0],$bbox[1],$bbox[2],$bbox[3]";

        my $response = $ua->get($url);
        if ( $response->is_success() ) {
            my $data = $response->content();
            if ( open FILE, ">", $baseImage ) {
                print FILE $data;
                close(FILE);
            }
            else {
                die "Could not download $baseImage"
                    unless -f $baseImage;
            }
        }

        else {
            print STDERR "Could not get response\n";
            exit_with_error( $response->code() );
        }
    }
}

# Delete unuseful files
unlink glob("*.gs");
unlink glob("*.wld");

$cmd = "composite $imgOutput -compose Overlay $baseImage $outputFile";
$rc = system($cmd);
exit_with_error("Failed to composite data images") unless -f $outputFile;

# Combine overlay image with title, caption and legend
my $plot  = Giovanni::Plot->new();
my $title = $cgi->param('TITLE');
if ( defined $title ) {
    $title .= " $dTime";
    $plot->addTitle($title);
}
my $caption = $cgi->param('CAPTION');
if ( defined $caption ) {
    $plot->addCaption($caption);
}
my $sldUrl = $cgi->param('SLD');
my $sldFilePath
           = File::Basename::basename( URI->new($sldUrl)->path(), '.xml' );
my $legendImage = "$resultDir/$sldFilePath" . "_legend.png";
$plot->addImage( $outputFile, $legendImage )
    if ( -f $outputFile && $legendImage );
(my $frame) = $plot->renderAnimationFrame(10);
system ("cp $frame $outputFrame");
my $imgUrl = Giovanni::Util::convertFilePathToUrl( $outputFrame,
            \%GIOVANNI::URL_LOOKUP );

print $cgi->header(
    -status        => 200,
    -type          => 'image/png',
    -cache_control => 'max-age=3600'
);
print `/bin/cat $outputFile`;

##### begin subroutines #####

# input array(minx, miny, maxx, maxy)
sub splitBoundingBox {
    my @bboxList;
    print STDERR "bbox includes $_[2] and $_[0]\n";
    if ( $_[2] < $_[0] ) {
        my @bbox1 = [ $_[0], $_[1], 180, $_[3] ];
        my @bbox2 = [ -180, $_[1], $_[2], $_[3] ];
        @bboxList = ( @bbox1, @bbox2 );
    }
    else {
        @bboxList = [@_];
    }
    return @bboxList;
}

# A method to exit with 500 HTTP header with appropriate message
sub exit_with_error {
    my ($message) = @_;
    print $cgi->header(
        -status        => 500,
        -type          => 'text/plain',
        -cache_control => 'no-cache'
    );
    print $message;
    exit;
}

# This method detects cases where the user's bounding box is partially outside
# the dataset's bounding box. It then returns a new bounding box, the
# intersection of the data bounding box and the user's bounding box. It also
# returns a new height and width (in pixels) that fits within the original image
# size, and also fits the proportions of the intersection bounding box.
#
# INPUTS:
#   VAR_INFO - the data field info file
#   DATA_FILE - the data file being visualized
#   BBOX - the user's bounding box
#   WIDTH - the requested width in pixels
#   HEIGHT - the requested height in pixels
#
# OUTPUTS:
#   BBOX - the new bounding box, adjusted for the data
#   WIDTH - the new image width
#   HEIGHT - the new image height
sub adjust_bbox_for_data {
    my (%params)    = @_;
    my $varInfoFile = $params{VAR_INFO};
    my $dataFile    = $params{DATA_FILE};
    my $bboxParam   = $params{BBOX};
    my $oldWidth    = $params{WIDTH};
    my $oldHeight   = $params{HEIGHT};

    # Get the data bounding box
    my $bboxStr = Giovanni::Data::NcFile::get_data_bounding_box($dataFile);
    my $dataBbox = Giovanni::BoundingBox->new( STRING => $bboxStr );
    $dataBbox->{NORTH} = sprintf("%g",$dataBbox->{NORTH});
    $dataBbox->{SOUTH} = sprintf("%g",$dataBbox->{SOUTH});
    $dataBbox->{EAST}  = sprintf("%g",$dataBbox->{EAST});
    $dataBbox->{WEST}  = sprintf("%g",$dataBbox->{WEST});

    # Get the dataset bounding box
    my $xmlParser = XML::LibXML->new();
    my $dom       = $xmlParser->parse_file($varInfoFile);
    my $doc       = $dom->documentElement();

    my $north       = $doc->findvalue("/varList/var/\@north");
    my $south       = $doc->findvalue("/varList/var/\@south");
    my $east        = $doc->findvalue("/varList/var/\@east");
    my $west        = $doc->findvalue("/varList/var/\@west");
    my $dataSetBbox = Giovanni::BoundingBox->new(
        NORTH => $north,
        SOUTH => $south,
        EAST  => $east,
        WEST  => $west,
    );

    # Get the intersection between the data bounding box and the dataset
    # bounding box. This is to deal with TRMM data, where we scrub data
    # all the way up and down to 90S - 90N.
    ($dataBbox)
        = Giovanni::BoundingBox::getIntersection( $dataBbox, $dataSetBbox );
    # Get the user's bounding box
    my $userBbox = Giovanni::BoundingBox->new( STRING => $bboxParam );
    my ($intersection)
        = Giovanni::BoundingBox::getIntersection( $dataBbox, $userBbox );
    if ( Giovanni::BoundingBox::isSameBox( $intersection, $userBbox ) ) {

        # no need to change the bounding box, height, or width
        return (
            BBOX   => $userBbox->getString(),
            WIDTH  => $oldWidth,
            HEIGHT => $oldHeight
        );
    }

    # Otherwise, we need to adjust the height and width. Find a new height and
    # width that (1) fit inside the old height and width and (2) have the same
    # height/width ratio as the data

    # Option 1: scale up the height and see if we end up with a bounding box
    # that is too wide

    my $ratio = $oldHeight / $intersection->getHeight();

    my $newHeight = $oldHeight;    # equals $intersection->getHeight() * ratio
    my $newWidth = $intersection->getWidth() * $ratio;

    # round the width
    $newWidth = sprintf( "%.0f", $newWidth );

    # check to see if we have a valid width
    if ( $newWidth > $oldWidth ) {

        # Need to go with Option 2: scale up the width and adjust the height
        $ratio = $oldWidth / $intersection->getWidth();

        $newWidth = $oldWidth;     # equals $dataBbox->getWidth() * ratio
        $newHeight = $intersection->getHeight() * $ratio;

        # round the height
        $newHeight = sprintf( "%.0f", $newHeight );
    }

    return (
        BBOX   => $intersection->getString(),
        WIDTH  => $newWidth,
        HEIGHT => $newHeight
    );
}

##### end subroutines #####
