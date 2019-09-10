package Giovanni::Plot;

use 5.010001;
use strict;
use warnings;
use File::Basename;
require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

use File::Temp qw/tempfile tempdir/;
use CGI;
use LWP::UserAgent;
use Giovanni::Util;
use Giovanni::Map::Util;

# LWP::UserAgent is used instead of wget, so define a new instance and tie to environment proxy
my $ua = LWP::UserAgent->new();
$ua->env_proxy;

sub new {
    my ( $class, %input ) = @_;
    my $self = {};

    # Directory where images will be produced
    $self->{_DIR} = $input{DIR};

    # Create a temporary directory
    $self->{_TMPDIR} = File::Temp::tempdir( $input{DIR}, CLEANUP => 1 );

    # A list to hold titles
    $self->{_TITLES} = [];

    # A list to hold sub-titles, captions, images and overlays
    $self->{_SUBTITLES} = [];
    $self->{_CAPTIONS}  = [];
    $self->{_IMAGES}    = [];
    $self->{_OVERLAYS}  = [];
    return bless( $self, $class );
}

# Anonymous sub to get the image size
my $getImageSize = sub {
    my ($imgFile) = @_;

    # Use ImageMagick's identify to get image size
    my $imgInfo = `identify -format '%w,%h' $imgFile`;
    if ($?) {
        print STDERR "Failed to find image size\n";
        return ( undef, undef );
    }
    chomp($imgInfo);
    my ( $width, $height ) = split( /,/, $imgInfo );

    # Return the image size
    return ( $width, $height );
};

# Anonymous sub to append images vertically
my $createImageCollage = sub {
    my ( $imgFiles, $outFile ) = @_;
    my $rc
        = system( 'convert', @$imgFiles, '-background', 'transparent', '-gravity',
        'center', '-append', $outFile );
    if ($rc) {
        print STDERR "Failed to create image collage\n";
        return 0;
    }
    return 1;
};

# Anonymous sub to append images vertically
my $createImageMontage = sub {
    my ( $imgFiles, $outFile ) = @_;
    my $rc
        = system( 'convert', @$imgFiles, '-background', 'transparent', '-gravity',
        'center', '+append', $outFile );
    if ($rc) {
        print STDERR "Failed to crate image montage\n";
        return 0;
    }
    return 1;
};

# Anonymous sub to merge images by overlaying: first image is considered the base
my $mergeImages = sub {
    my ( $imgFiles, $outFile ) = @_;
    my @cmdArgList = ();
    for ( my $i = 0; $i < @$imgFiles; $i++ ) {
       if ( $i < 2 ) {
            push( @cmdArgList, $imgFiles->[$i] );
        }
        else {
            push( @cmdArgList,
                '-compose', 'Overlay', '-composite', $imgFiles->[$i] );
        }
    }
    my $mergeFile = File::Temp::tempnam( dirname($outFile), "merge_" );
    push( @cmdArgList,'-compose', 'Overlay', '-composite',$mergeFile );
    # overlay map images
    my $rc = system( 'convert', @cmdArgList );
    # Change background color from transparent to blue grey
    $rc = system('convert',  $mergeFile, '-background', '#CFCFDF', '-bordercolor', '#CFCFDF', '-border', '0x0', $outFile);
    return $rc ? 0 : 1;
};
# Anonymous sub to stack images: first on the top
my $stackImages = sub {
    my ( $imgFiles, $outFile ) = @_;
    my @cmdArgList = ();
    for ( my $i = 0; $i < @$imgFiles; $i++ ) {
       push( @cmdArgList, $imgFiles->[$i] );
    }   
    push( @cmdArgList, '-append', $outFile );
    my $rc = system( 'convert', @cmdArgList );
    return $rc ? 0 : 1;
};

# Anonymous sub to create images from text
my $createTextImage = sub {
    my ( $text, $outFile, %options ) = @_;
    my $font = exists $options{font} ? $options{font} : {};
    $font->{family} = 'Helvetica' unless exists $font->{family};
    $font->{size}   = '14'        unless exists $font->{size};
    $font->{weight} = 'normal'    unless exists $font->{weight};
    my $type = exists $options{type} ? $options{type} : 'caption';
    my $rc = system(
        'convert', '-fill', 'black', '-background', 'transparent', '-weight',
        $font->{weight}, '-font', $font->{family}, '-pointsize',
        $font->{size}, '-gravity', 'Center',
        exists $options{maxwidth} ? ( "-size", $options{maxwidth} ) : (),
        "$type:$text", $outFile
    );
    if ($rc) {
        print STDERR "Failed to convert $text to image\n";
        return 0;
    }
    return 1;
};

# Add a single title
sub addTitle {
    my ( $self, $title ) = @_;
    my $outFile = File::Temp::tempnam( $self->{_TMPDIR}, "title_" ) . '.png';

    # Create an image of the text and save it
    if ($createTextImage->(
            $title, $outFile, 
            (   type     => 'caption',
                maxwidth => 1024,
                font => { size => 14, weight => 'bold' }
            )
        )
        )
    {
        push( @{ $self->{_TITLES} }, { text => $title, image => $outFile } );
        return 1;
    }
    return 0;
}

# Add a single sub-title
sub addSubTitle {
    my ( $self, $subTitle ) = @_;
    my $outFile
        = File::Temp::tempnam( $self->{_TMPDIR}, "subtitle_" ) . '.png';

    # Create an image of the text and save it
    if ($createTextImage->(
            $subTitle, $outFile,
            (   type     => 'caption',
                maxwidth => 1024,
                font     => { weight => 'normal' }
            )
        )
        )
    {
        push(
            @{ $self->{_SUBTITLES} },
            { text => $subTitle, image => $outFile }
        );
        return 1;
    }
    return 0;
}

# Add a single caption
sub addCaption {
    my ( $self, $caption ) = @_;
    my $outFile
        = File::Temp::tempnam( $self->{_TMPDIR}, "caption_" ) . '.png';
    # Create the caption image; set the max width to 1024px
    if ($createTextImage->(
            $caption, $outFile,
            (   type     => 'caption',
                maxwidth => 1024,
                font     => { weight => 'normal' }
            )
        )
        )
    {
        push(
            @{ $self->{_CAPTIONS} },
            { text => $caption, image => $outFile }
        );
        return 1;
    }
    return 0;
}

# Add an image with optional legend
sub addImage {
    my ( $self, $imgFile, $imgLegend ) = @_;

    return 0 unless ( -f $imgFile );

    # Compute size of image and legend
    my ( $imgWidth, $imgHeight ) = $getImageSize->($imgFile);
    my $imgHash = {
        image       => $imgFile,
        imageWidth  => $imgWidth,
        imageHeight => $imgHeight
    };
    if ( defined $imgLegend ) {
        return 0 unless ( -f $imgLegend );
        my ( $legendHeight, $legendWidth ) = $getImageSize->($imgLegend);
        $imgHash->{legend}       = $imgLegend;
        $imgHash->{legendWidth}  = $legendWidth;
        $imgHash->{legendHeight} = $legendHeight;
    }
    push( @{ $self->{_IMAGES} }, $imgHash );
    return 1;
}

# Download a WMS layer
sub downloadWmsLayer {
    my ( $self, $wmsLayer ) = @_;

    # Handle bounding box crossing 180 deg meridian
    my $uri          = URI->new($wmsLayer);
    my $cgi          = CGI->new( $uri->query );
    my $srs          = defined $cgi->param('SRS') ? $cgi->param('SRS') : $cgi->param('CRS');
    my $origBboxStr  = $cgi->param('BBOX');
    my $imgWidth     = $cgi->param('WIDTH');
    my $imgHeight    = $cgi->param('HEIGHT');
    my @wmsLayerList = ();
    my $widthChanged  = 0;
    my $heightChanged = 0;
    if ( defined $origBboxStr ) {
        my @newBboxStrList;
        # Test for bounding box crossing the 180deg meridian
        my @origBbox = split( /\s*,\s*/, $origBboxStr );
        if ( @origBbox == 4 ) {

            # If bounding box crosses 180deg meridian, split the box in to two
            if ( $origBbox[2] < $origBbox[0] ) {
                 @newBboxStrList = (
                    join( ',',
                        ( $origBbox[0], $origBbox[1], 180, $origBbox[3] ) ),
                    join( ',',
                        ( -180, $origBbox[1], $origBbox[2], $origBbox[3] ) )
                );
                $widthChanged = 1;
                # keep the ratio of width and height
                $imgHeight = int($imgWidth * ($origBbox[3] - $origBbox[1]) / (180-$origBbox[0] + 180 + $origBbox[2]) + 0.5);
                $cgi->delete('HEIGHT');
                $cgi->param( 'HEIGHT', $imgHeight );
             }
             # to avoid the mapserver bug, generate tiles for polar projections
             elsif ( ($srs =~ /epsg:3031/i or $srs =~ /epsg:3413/i) and
                     ($wmsLayer =~ /_contour/i or $uri =~ /wms_ogc/i)) {
               if ( $origBbox[0] < 0 and $origBbox[2] > 0 ) {
                   if ( $origBbox[1] >= 0 or $origBbox[3] <= 0 ) {
                      @newBboxStrList = (
                          join( ',',
                                ( $origBbox[0], $origBbox[1], 0, $origBbox[3] ) ),
                          join( ',',
                                ( 0, $origBbox[1], $origBbox[2], $origBbox[3] ) )
                      );
                      $widthChanged = 1;
                   }
                   else {
                      @newBboxStrList = (
                          join( ',',
                                ( $origBbox[0], $origBbox[1], 0, 0 ) ),
                          join( ',',
                                ( 0, $origBbox[1], $origBbox[2], 0 ) ),
                          join( ',',
                                ( $origBbox[0], 0, 0, $origBbox[3] ) ),
                          join( ',',
                                ( 0, 0, $origBbox[2], $origBbox[3] ) ),
                      );
                      $widthChanged  = 1;
                      $heightChanged = 1;
                   }
                }
                elsif ( $origBbox[1] < 0 and $origBbox[3] > 0 ) {
                   if ( $origBbox[0] >= 0 or $origBbox[2] <= 0 ) {
                      @newBboxStrList = (
                          join( ',',
                                ( $origBbox[0], 0, $origBbox[2], $origBbox[3] ) ),
                          join( ',',
                                ( $origBbox[0], $origBbox[1], $origBbox[2], 0 ) )
                      );
                      $heightChanged = 1;
                   }
                }
             }
             unless ( $heightChanged or $widthChanged ) {
                @wmsLayerList = ($wmsLayer);
             }
                # Replace bbox in the original request with split bounding
                # boxes to obtain new WMS URLs
             if ( @newBboxStrList) {
               foreach my $newBboxStr (@newBboxStrList) {
                  my @newBbox = split( ',', $newBboxStr );
                  $cgi->delete('BBOX');
                  $cgi->param( 'BBOX', $newBboxStr );
                  if ( $widthChanged ) {
                     my $newWidth ;
                     if ( $origBbox[2] < $origBbox[0] ) {
                        $newWidth = int( $imgWidth
                            * ( $newBbox[2] - $newBbox[0] )
                            / ( 360 + $origBbox[2] - $origBbox[0] ) + 0.5 );
                     }
                     else {
                        $newWidth = int( $imgWidth
                            * ( $newBbox[2] - $newBbox[0] )
                            / ( $origBbox[2] - $origBbox[0] ) + 0.5 );
                     }
                     $cgi->delete('WIDTH');
                     $cgi->param( 'WIDTH', $newWidth );
                   }
                   if ( $heightChanged ) {
                      my $newHeight
                        = int( $imgHeight
                            * ( $newBbox[3] - $newBbox[1] )
                            / ( $origBbox[3] - $origBbox[1] ) + 0.5 );
                      $cgi->delete('HEIGHT');
                      $cgi->param( 'HEIGHT', $newHeight );
                   }
                    $uri->query( $cgi->query_string() );
                    my $qStr = $uri->as_string();
                    $qStr =~ s/;/&/g;
                    push( @wmsLayerList, $qStr );
                }
             }
        }
    }
    else {

        # Case of BBOX not found
        @wmsLayerList = ($wmsLayer);
    }

    # Time to download WMS URLs
    my @wmsLayerImgList = ();
    for ( my $i = 0; $i < @wmsLayerList; $i++ ) {
        my $imgFile = File::Temp::tempnam( $self->{_TMPDIR}, "wmsLayer_" );
        my $session   = $cgi->param('SESSION');
        my $layerName = $cgi->param('LAYERS');
        if ( ($srs =~ /epsg:3031/i or $srs =~ /epsg:3413/i) and 
             (defined $session) and
             ($layerName !~ /_contour/i)) {
           my $mapFile = $cgi->param('MAPFILE');
           if ( $mapFile =~ /\.map$/i ) {
              $mapFile .= ".xml";
           }
           my $resultset = $cgi->param('RESULTSET');
           my $result    = $cgi->param('RESULT');
           my $imgWidth  = $cgi->param('WIDTH');
           my $imgHeight = $cgi->param('HEIGHT');
           my $imgFormat = $cgi->param('FORMAT');
           my ($dType, $dFormat) = split ('/', $imgFormat);
           my $mapDir
                = qq($GIOVANNI::SESSION_LOCATION/$session/$resultset/$result);
           $mapFile = "$mapDir/$mapFile";
           my $layerName = $cgi->param('LAYERS');
           my $dataFile = Giovanni::Map::Util::getLayerData($mapFile, $layerName);
           my %options = (
                   OUTWIDTH  => $imgWidth,
                   OUTHEIGHT => $imgHeight,
                   OUTBBOX   => $origBboxStr
              );
           $imgFile .= ".$dFormat";
           unless ( Giovanni::Map::Util::reprojection($dataFile, "EPSG:4326", $imgFile, $srs, %options)) {
              print STDERR "reprojection is failed for $dataFile\n";
              Giovanni::Util::exit_with_error( "reprojection is failed." );
           } 
        }
        else {
           # We are using LWP::UserAgent to get url; this is in favor of and replaces wget
           # Needed for cloud support of giovanni
           my $response = $ua->get( $wmsLayerList[$i] );
           if ( $response->is_success() ) {
              my $data = $response->content();

              if ( open FILE, ">", $imgFile ) {
                 print FILE $data;
                 close(FILE);
              }
              else {
                 print STDERR "Could not write to $imgFile\n";
                 Giovanni::Util::exit_with_error( $response->code() );
              }
           }
           else {
              print STDERR "Could not get response\n";
              Giovanni::Util::exit_with_error( $response->code() );
           }
        }
        push( @wmsLayerImgList, $imgFile );
    }
    my $outFile;
    if ( @wmsLayerImgList == 2 ) {
        $outFile = File::Temp::tempnam( $self->{_TMPDIR}, "wmsLayer" );
        my $rc = $widthChanged ?
                 system( 'convert', @wmsLayerImgList, '+append', $outFile ) :
                 system( 'convert', @wmsLayerImgList, '-append', $outFile ) ;
        if ($rc) {
            print STDERR "Failed to append images\n";
            return undef;
        }
    }
    elsif ( @wmsLayerImgList == 4 ) {
        my $tempFile1 = File::Temp::tempnam( $self->{_TMPDIR}, "t1" );
        my $rc = system( 'convert', $wmsLayerImgList[0], $wmsLayerImgList[1], '+append', $tempFile1 );
        if ($rc) {
            print STDERR "Failed to append images\n";
            return undef;
        }
        my $tempFile2 = File::Temp::tempnam( $self->{_TMPDIR}, "t2" );
        $rc = system( 'convert', $wmsLayerImgList[2], $wmsLayerImgList[3], '+append', $tempFile2 );
        if ($rc) {
            print STDERR "Failed to append images\n";
            return undef;
        }
        $outFile = File::Temp::tempnam( $self->{_TMPDIR}, "wmsLayer" );
        $rc = system( 'convert', $tempFile2, $tempFile1, '-append', $outFile );
        if ($rc) {
            print STDERR "Failed to append images\n";
            return undef;
        }
    }
    elsif ( @wmsLayerImgList == 1 ) {
        $outFile = $wmsLayerImgList[0];
    }
    # Test for conversion success
    return $outFile;
}

# downloads WMS legend given a WMS layer with GetMap service
sub getWmsLegend {
    my ( $self, $wmsLayer ) = @_;

    # Form GetLegend request for WMS layer
    my $uri = URI->new($wmsLayer);
    my $cgi = CGI->new( $uri->query() );
    $cgi->delete('REQUEST');
    $cgi->param( 'REQUEST', 'GetLegendGraphic' );
    $cgi->delete('WIDTH');
    $cgi->delete('HEIGHT');
    $cgi->delete('SRS');
    $cgi->delete('BBOX');
    my $layer = $cgi->param( 'LAYERS');
    $cgi->delete('LAYERS');
    $cgi->param('LAYER', $layer);
    my $qString = $cgi->query_string() ;
    $qString =~ s/\;/\&/g;
    $uri->query( $qString );
    my $outFile = $self->{_TMPDIR} . "/legend_" . $layer. ".png";

    # We are using LWP::UserAgent to get url; this is in favor of and replaces wget
    # Needed for cloud support of giovanni
    my $response = $ua->get( $uri->as_string() );
    if ( $response->is_success() ) {
        my $data = $response->content();

        if ( open FILE, ">", $outFile ) {
            print FILE $data;
            close(FILE);
        }
        else {
            print STDERR "Could not write to $outFile\n";
            Giovanni::Util::exit_with_error( $response->code() );
        }
    }
    else {
        print STDERR "Could not get response\n";
        Giovanni::Util::exit_with_error( $response->code() );
    }
    return $outFile;
}

# Adds WMS layers
sub addWmsLayers {
    my ( $self, %input ) = @_;
    my @overlayImages = ();
    my @dataImages    = ();
    my @legendImages   = ();

    # Download overlays
    if ( exists $input{overlays} ) {
        my @layers
            = ( ref $input{overlays} eq 'ARRAY' )
            ? @{ $input{overlays} }
            : ( $input{overlays} );
        foreach my $layer (@layers) {
            my $layerImgFile;
            $layerImgFile = $self->downloadWmsLayer($layer);
            push( @overlayImages, $layerImgFile ) if defined $layerImgFile;
        }
    }

    # Download data layers
    if ( exists $input{layers} ) {
        my @layers
            = ( ref $input{layers} eq 'ARRAY' )
            ? @{ $input{layers} }
            : ( $input{layers} );
        foreach my $layer (@layers) {
            my $layerImgFile = $self->downloadWmsLayer($layer);
            if (defined $layerImgFile) {
               if ($layer =~ m/_contour/i) {
                  unshift(@dataImages, $layerImgFile);
               }
               else {
                  push( @dataImages, $layerImgFile );
               }
            }
            unless ($layer =~ m/_contour/i) {
               my $legendImage = $self->getWmsLegend($layer);
               my $layerType = ($layer =~ m/_vec/i) ? "Vector" : "Shaded";
               # Annotate legend
               my $llImage = File::Temp::tempnam( $self->{_TMPDIR},
                    "legendAndLabel" );
               $llImage .= ".png";
               my $captionText = (scalar @layers) > 1 ? "caption:'$layerType'" : "";
               my $command = "convert $legendImage -size 100 $captionText +swap -gravity Center  -append $llImage";
               my $rc = system($command );
               if ($rc) {
                   print STDERR "Failed to combine label and legend\n";
                   return undef;
                }              
               push(@legendImages, $llImage);
            }
        }
    }

    # Find the maximum dimensions of images
    my ( $maxWidth, $maxHeight ) = ( 0, 0 );
    foreach my $image ( @overlayImages, @dataImages ) {
        my ( $width, $height ) = $getImageSize->($image);
        $maxWidth  = $width  if ( $width > $maxWidth );
        $maxHeight = $height if ( $height > $maxHeight );
    }

    # Return 0 if width or height is zero
    return 0 if ( $maxWidth == 0 || $maxHeight == 0 );

    # Set the maximum image size to: 1024x512 pixels
    # Find the image resize ration
    my $ratioWidth  = 1024 * 1.0 / $maxWidth;
    my $ratioHeight = 512 * 1.0 / $maxHeight;
    my $resizeRatio = $ratioWidth > $ratioHeight ? $ratioHeight : $ratioWidth;
    
    my $flag;
    my $layersImage;
    # Blend data images
    if (@dataImages > 1 ) {
       $layersImage = File::Temp::tempnam( $self->{_TMPDIR},
                    "mergedLayer" );
      $flag = $mergeImages->( \@dataImages, $layersImage);
      if (! $flag) {
         print STDERR "failed to composite data layers \n";
      }
    }
    else {
      $layersImage = $dataImages[0];
    }
    # Stack legend images
    my $legendsImage;
    if (@legendImages > 1 ) {
       $legendsImage = File::Temp::tempnam( $self->{_TMPDIR},
                    "mergedLegend" );
       $flag = $stackImages->( \@legendImages, $legendsImage);
      if (! $flag) {
         print STDERR "failed to stack legends \n";
      }
    }
    else {
      $legendsImage = $legendImages[0];
    }
    # Blend overlays with data images
    if (@overlayImages) {
       my $mergedOverlaysImage
                = File::Temp::tempnam( $self->{_TMPDIR}, "mergedOverlay" );
       if ( @overlayImages > 1 ) {
          $flag
              = $mergeImages->( \@overlayImages, $mergedOverlaysImage );
       }
       else {
          if ( -f $overlayImages[0] ) {
              $mergedOverlaysImage = $overlayImages[0];
              $flag                = 1;
           }
       }
       if ($flag) {
          my $mergedDataImage = File::Temp::tempnam( $self->{_TMPDIR},
                    "mergedDataLayer" );
          my $rc = $mergeImages->(
                    [ $mergedOverlaysImage, $layersImage ],
                    $mergedDataImage
                );
          if ($rc) {
                    $self->addImage( $mergedDataImage,
                        ( defined $legendsImage ? $legendsImage : undef ) );
          }
          else {
            print STDERR
                 "Failed to composite data layer with overlays\n";
          }
       }
     }
     else {
       $self->addImage( $layersImage,
                ( defined $legendsImage ? $legendsImage : undef ) );
     }
}

# Render PNG: used for map and plot downloads
sub renderPNG {
    my ($self) = @_;

    # Output PNG file
    my $outFile = File::Temp::tempnam( $self->{_TMPDIR}, "output" ) . ".png";
    # If more than one file exists in a plot, PNG is not a supported format
    #return undef if @{ $self->{_IMAGES} } > 1;
    # Form the list of of images: title, sub-title, image, caption
    my @imgList = ();
    push( @imgList, $self->{_TITLES}[0]{image} ) if @{ $self->{_TITLES} };
    push( @imgList, $self->{_SUBTITLES}[0]{image} )
        if @{ $self->{_SUBTITLES} };
    if ( @{ $self->{_IMAGES} } ) {
        if ( exists $self->{_IMAGES}[0]{legend} ) {
            my $compositeFile
                = File::Temp::tempnam( $self->{_TMPDIR}, "imgWihLegend" )
                . ".png";
            $createImageMontage->(
                [ $self->{_IMAGES}[0]{image}, $self->{_IMAGES}[0]{legend} ],
                $compositeFile
            );
            push( @imgList, $compositeFile );
        }
        else {
            push( @imgList, $self->{_IMAGES}[0]{image} );
        }
    }
    push( @imgList, $self->{_CAPTIONS}[0]{image} ) if @{ $self->{_CAPTIONS} };
    my $rc = system(
        'convert',  @imgList, '-background', 'white', '-bordercolor', 'white', '-border', '12x0',
        '-gravity', 'center', '-append',     $outFile
    );
    if ($rc) {
        print STDERR "Failed to render plot as PNG\n";
        return undef;
    }
    return $outFile;
}

sub generateFrame {
    my ( $self, $frameImgFile ) = @_;

    # Form the list of of images: title, sub-title, image, caption
    my @imgList       = ();
    my $titleCount    = scalar( @{ $self->{_TITLES} } );
    my $subTitleCount = scalar( @{ $self->{_SUBTITLES} } );
    my $captionCount  = scalar( @{ $self->{_CAPTIONS} } );
    my @subImgList    = ();
    push( @subImgList, $self->{_TITLES}[0]{image} )
        if ( $titleCount > 0 );
    push( @subImgList, $self->{_SUBTITLES}[0]{image} )
        if ( $subTitleCount > 0 );

    if ( exists $self->{_IMAGES}[0]{legend} ) {
        my $compositeFile
            = File::Temp::tempnam( $self->{_TMPDIR}, "imgWihLegend" )
            . ".png";
        $createImageMontage->(
            [ $self->{_IMAGES}[0]{image}, $self->{_IMAGES}[0]{legend} ],
            $compositeFile
        );
        push( @subImgList, $compositeFile );
    }
    else {
        push( @subImgList, $self->{_IMAGES}[0]{image} );
    }
    push( @subImgList, $self->{_CAPTIONS}[0]{image} )
        if ( $captionCount > 0 );
    return $createImageCollage->( \@subImgList, $frameImgFile );

}

# Render animated GIF: used in animation download
# Callers may optionally provide the (frames => arrayref) keyword,
# which can contain the frames to use for the gif.
sub renderGIF {
    my ( $self, $delay, %params ) = @_;

    # Output GIF file
    my $outFile = File::Temp::tempnam( $self->{_TMPDIR}, "output" ) . ".gif";

    # Form the list of of images: title, sub-title, image, caption
    my @imgList;

    if ( exists $params{frames} ) {
        @imgList = @{ $params{frames} };
    }
    else {
        my $titleCount    = scalar( @{ $self->{_TITLES} } );
        my $subTitleCount = scalar( @{ $self->{_SUBTITLES} } );
        my $captionCount  = scalar( @{ $self->{_CAPTIONS} } );
        for ( my $i = 0; $i < @{ $self->{_IMAGES} }; $i++ ) {
            my @subImgList = ();
            push( @subImgList, $self->{_TITLES}[$i]{image} )
                if ( $i < $titleCount );
            push( @subImgList, $self->{_SUBTITLES}[$i]{image} )
                if ( $i < $subTitleCount );
            if ( exists $self->{_IMAGES}[$i]{legend} ) {
                my $compositeFile
                    = File::Temp::tempnam( $self->{_TMPDIR}, "imgWihLegend" )
                    . ".png";
                $createImageMontage->(
                    [   $self->{_IMAGES}[$i]{image},
                        $self->{_IMAGES}[$i]{legend}
                    ],
                    $compositeFile
                );
                push( @subImgList, $compositeFile );
            }
            else {
                push( @subImgList, $self->{_IMAGES}[$i]{image} );
            }
            push( @subImgList, $self->{_CAPTIONS}[$i]{image} )
                if ( $i < $captionCount );
            my $frameImgFile
                = File::Temp::tempnam( $self->{_TMPDIR}, "frame" ) . ".png";
            $createImageCollage->( \@subImgList, $frameImgFile );
            push( @imgList, $frameImgFile );
        }
    }
    my $rc = system( 'g4_fast_animate.py', '--delay', $delay / 10.0,
        @imgList, $outFile );
    if ($rc) {
        print STDERR "Failed to render plot as PNG\n";
        return undef;
    }
    return $outFile;
}

# Render animation frame: used in animation download
# Callers may optionally provide the (delay => arrayref) keyword,
# which can contain the delay to use for the animation.

sub renderAnimationFrame {
    my ( $self, $delay, %params ) = @_;

    # Form the list of of images: title, sub-title, image, caption
    my @imgList;

    if ( exists $params{frames} ) {
        @imgList = @{ $params{frames} };
    }
    else {
        my $titleCount    = scalar( @{ $self->{_TITLES} } );
        my $subTitleCount = scalar( @{ $self->{_SUBTITLES} } );
        my $captionCount  = scalar( @{ $self->{_CAPTIONS} } );
        for ( my $i = 0; $i < @{ $self->{_IMAGES} }; $i++ ) {
            my @subImgList = ();
            push( @subImgList, $self->{_TITLES}[$i]{image} )
                if ( $i < $titleCount );
            push( @subImgList, $self->{_SUBTITLES}[$i]{image} )
                if ( $i < $subTitleCount );
            if ( exists $self->{_IMAGES}[$i]{legend} ) {
                my $compositeFile
                    = File::Temp::tempnam( $self->{_TMPDIR}, "imgWihLegend" )
                    . ".png";
                $createImageMontage->(
                    [   $self->{_IMAGES}[$i]{image},
                        $self->{_IMAGES}[$i]{legend}
                    ],
                    $compositeFile
                );
                push( @subImgList, $compositeFile );
            }
            else {
                push( @subImgList, $self->{_IMAGES}[$i]{image} );
            }
            push( @subImgList, $self->{_CAPTIONS}[$i]{image} )
                if ( $i < $captionCount );
            my $frameImgFile
                = File::Temp::tempnam( $self->{_TMPDIR}, "frame" ) . ".png";
            $createImageCollage->( \@subImgList, $frameImgFile );
            push( @imgList, $frameImgFile );
        }
    }
    return @imgList;
}

sub renderTIFF {
    my ($self) = @_;

    # Output TIFF file
    my $outFile = File::Temp::tempnam( $self->{_TMPDIR}, "output" ) . ".tiff";

    # If more than one file exists in a plot, TIFF is not a supported format
    return undef if @{ $self->{_IMAGES} } > 1;
    return $self->{_IMAGES}[0]{image};
}

sub renderKMZ {
    my ( $self, $lName, $bbox, $timeStamp ) = @_;

    # Output KMZ file
    my $outFile = File::Temp::tempnam( $self->{_TMPDIR}, $lName ) . ".kmz";
    my $kmlFile = File::Temp::tempnam( $self->{_TMPDIR}, $lName ) . ".kml";

    #If more than one file exists in a plot, TIFF is not a supported format
    return undef if @{ $self->{_IMAGES} } > 1;
    my @boundingBox = split( ",", $bbox );
    return undef if @boundingBox != 4;
    $boundingBox[2] = 360 + $boundingBox[2]
        if $boundingBox[2] < $boundingBox[0];
    my $viewLon = ( $boundingBox[2] + $boundingBox[0] ) / 2;
    my $viewLat = ( $boundingBox[3] + $boundingBox[1] ) / 2;
    my $kmlStr  = qq(<?xml version="1.0" encoding="UTF-8"?>\n);
    $kmlStr .= qq(<kml xmlns="http://www.opengis.net/kml/2.2">\n);
    $kmlStr .= qq(  <Folder>\n);
    my $t = $self->{_TITLES}[0]{text};
    $kmlStr .= qq(    <name>$lName</name>\n);
    my $d = $self->{_SUBTITLES}[0]{text};
    $kmlStr .= qq(    <description>$t : $d</description>\n);
    $kmlStr .= qq(    <LookAt>\n);
    $kmlStr .= qq(      <longitude>$viewLon</longitude>\n);
    $kmlStr .= qq(      <latitude>$viewLat</latitude>\n);
    $kmlStr .= qq(      <tilt>0.0</tilt>\n);
    $kmlStr .= qq(      <heading>0.0</heading>\n);
    $kmlStr .= qq(      <range>8000000</range>\n);
    $kmlStr .= qq(    </LookAt>\n);
    $kmlStr .= qq(    <GroundOverlay>\n);
    $kmlStr .= qq(      <name>data content</name>\n);
    $kmlStr .= qq(      <Icon>\n);
    my $i = $self->{_IMAGES}[0]{image};
    $i = basename($i);
    $kmlStr .= qq(        <href>$i</href>\n);
    $kmlStr .= qq(      </Icon>\n);
    $kmlStr .= qq(      <LatLonBox>\n);
    $kmlStr .= qq(        <north>$boundingBox[3]</north>\n);
    $kmlStr .= qq(        <south>$boundingBox[1]</south>\n);
    $kmlStr .= qq(        <east>$boundingBox[2]</east>\n);
    $kmlStr .= qq(        <west>$boundingBox[0]</west>\n);
    $kmlStr .= qq(      </LatLonBox>\n);

    if ( defined $timeStamp ) {
        $kmlStr .= qq(      <TimeStamp>\n);
        $kmlStr .= qq(        <when>$timeStamp</when>\n);
        $kmlStr .= qq(      </TimeStamp>\n);
    }
    $kmlStr .= qq(    </GroundOverlay>\n);
    if ( defined $self->{_IMAGES}[0]{legend} ) {
        $kmlStr .= qq(    <ScreenOverlay>\n);
        $kmlStr .= qq(      <name>color_legend</name>\n);
        $kmlStr .= qq(      <color>ffffffff</color>\n);
        $kmlStr .= qq(      <Icon>\n);
        my $l = $self->{_IMAGES}[0]{legend};
        $l = basename($l);
        $kmlStr .= qq(        <href>$l</href>\n);
        $kmlStr .= qq(      </Icon>\n);
        $kmlStr
            .= qq(      <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>\n);
        $kmlStr
            .= qq(      <screenXY x="1" y="1" xunits="fraction" yunits="fraction"/>\n);
        $kmlStr
            .= qq(      <size x="-1" y="-1" xunits="fraction" yunits="fraction"/>\n);
        $kmlStr .= qq(    </ScreenOverlay>\n);
    }
    $kmlStr .= qq(  </Folder>\n);
    $kmlStr .= qq(</kml>);
    Giovanni::Util::writeFile( $kmlFile, $kmlStr );
    
    my $command = "zip -j $outFile $kmlFile $self->{_IMAGES}[0]{image} $self->{_IMAGES}[0]{legend} >/dev/null";
    my $rc = system($command);
    if ($rc) {
        print STDERR "Failed to create KMZ file\n";
        return undef;
    }
    return $outFile;
}

1;
__END__

=head1 NAME

Giovanni::Plot - Perl extension for composing a plot with titles, sub-titles, image and caption

=head1 SYNOPSIS

  use Giovanni::Plot;
  $plot = Giovanni::Plot->new();
  $status = $plot->addTitle("title");
  $status = $plot->addCaption("caption");
  $status = $plot->addSubTitle("subTitle");
  $status = $plot->addImage($imgFile, $legendImgFile);
  $plot->downloadWmsLayer();
  $plot->getWmsLegend()
  $plot->addWmsLayers();
  my @imgList = $plot->renderAnimationFrame(); 
  my $outFile = $plot->renderPNG()
  my $outFile = $plot->renderGIF()
  my $outFile = $plot->renderTIFF();

=head1 DESCRIPTION

=over 4

=item new()

creates a Giovanni::Plot object.

=back

=over 4

=item addTitle("title string")

Adds a text title. Title is rendered in bold weight at the top and are centered in the page.

=back

=over 4

=item addSubTitle("subtitle string")

Adds a text sub-title. Sub-titles appear below title text.

=back

=over 4

=item addCaption("caption string")

Adds a caption. Captions are shown at the bottom of the plot.

=back

=over 4

=item addImage("image file name", ["legend file name"])

Adds an image with a legend if specified. Image and legend are laid out in a row.

=back

=over 4

=item addWmsLayers(layers=>["WMS URL #1",...], overlays=>["Overlay URL #1", ...])

Adds WMS layers where layers is a reference to array of layer WMS URLS and overlays is a refernce to an array of overlay WMS URLs. Each layer is overlaid with specified overlay layers.

=back

=over 4

=item renderGIF()

creates animated GIF of the plot. Returns undef on failure or GIF image file name on success.

=back

=over 4

=item renderTIFF()

creates GeoTIFF version of the plot. Returns undef on failure or TIFF image file name on success.

=back

=over 4

=item renderAnimationFrame()

creates animation frame if it does not already exist in the session directory. The animation frame is part of the concatenated image files that get zipped up for animation download.

=back

=head2 EXPORT

=head1 SEE ALSO

=head1 AUTHOR

Mahabaleshwara S. Hegde, E<lt>maha.hegde@nasa.govE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
