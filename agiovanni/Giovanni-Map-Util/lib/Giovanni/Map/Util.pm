package Giovanni::Map::Util;

use 5.010001;
use strict;
use warnings;
use File::Basename;

our $VERSION = '0.01';

use XML::LibXML;
use File::Temp;

# Get data file location from Map file for a layer
sub getLayerData {
    my ($mapFile, $layerName) = @_;
    my $mapFileContent = Giovanni::Util::parseXMLDocument($mapFile);
    my $xc = XML::LibXML::XPathContext->new($mapFileContent);
    $xc->registerNs( 'ns', 'http://www.mapserver.org/mapserver' );
    my $cse = "/ns:Map/ns:Layer[\@name=\""
              . $layerName
              . "\"]/ns:data";
    my ($layerNode) = $xc->findnodes("$cse");
    return $layerNode->string_value;
}


sub reprojection {
    my ($inFile, $inSRS, $outFile, $outSRS, %options) = @_;

    my $warpString = "gdalwarp -of GTiff ";
    # Get NoData information using gdalinfo
    my $command = "gdalinfo $inFile | grep 'NoData'";
    my $output = `$command`;
    chop($output);
    my ($t, $v) = split("=",$output);
    $v = defined $v ?
         $v =~ /(^\d+?$)/ ? $1 : -1 :
          -1;
    $warpString .= "-srcnodata $v -dstalpha ";

    # Fill the gap for polar projections
    if ( $outSRS =~ /epsg:3413/i or $outSRS =~ /epsg:3031/i ) {
       $warpString .= "-wo SOURCE_EXTRA=100 -wo SAMPLE_GRID=YES ";
    }
    $warpString .= "-s_srs $inSRS -t_srs $outSRS ";
    if ( defined $options{OUTWIDTH} and defined $options{OUTHEIGHT} ) {
       $warpString .= "-ts $options{OUTWIDTH} $options{OUTHEIGHT} ";
    }
    if ( defined $options{OUTBBOX} ) {
       $options{OUTBBOX} =~ s/,/ /g;
       $warpString .= "-te $options{OUTBBOX} ";
    }
    my $tmpOut = File::Temp->new(
            TEMPLATE => 'tmp_reproject' . '_XXXX',
            DIR      => $GIOVANNI::SESSION_LOCATION,
            SUFFIX   => '.tif'
         );
    $warpString .= "$inFile $tmpOut > /dev/null 2>&1";
    my $rc = system ( $warpString );
    if ( $rc != 0 ) {
        print STDERR  "Reprojection is failed using $warpString\n";
        return 0;
    }
    $rc = system ( "convert $tmpOut $outFile > /dev/null 2>&1" );
    if ( $rc != 0 ) {
        print STDERR  "Failed to convert to output format after reprojection\n";
        return 0;
    } 
    return 1;
}

sub getWmsImage {
    my ($outFile, $wmsUrl, $layer, %options) = @_;
    my $outDir = dirname($outFile);
    $options{BBOX} = "-180,-90,180,90" unless defined $options{BBOX};
    my @bbox = split( ',', $options{BBOX} );   
    my @bboxList = splitBoundingBox(@bbox);
    my $width   = defined $options{WIDTH} ? $options{WIDTH} : "1024";
    my $height   = defined $options{HEIGHT} ? $options{HEIGHT} : "512";
    my $version = defined $options{VERSION} ? $options{VERSION} : "1.1.1";
    my $format  = defined $options{FORMAT} ? $options{FORMAT} : "image/png";
    my $srs     = defined $options{SRS} ? $options{SRS} : "EPSG:4326";
    $wmsUrl = $wmsUrl . "&VERSION=$version";
    $wmsUrl = $wmsUrl . "&FORMAT=$format";
    $wmsUrl = $wmsUrl . "&SRS=$srs";
    $wmsUrl = $wmsUrl . "&SERVICE=WMS";
    $wmsUrl = $wmsUrl . "&REQUEST=GetMap";
    $wmsUrl = $wmsUrl . "&LAYERS=$layer";
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;
    if ( scalar(@bboxList) == 2 ) {
       my $width1
        = int( $width
            * ( $bboxList[0][2] - $bboxList[0][0] )
            / ( 360 + $bbox[2] - $bbox[0] ) + 0.5 );
       my $width2
        = int( $width
            * ( $bboxList[1][2] - $bboxList[1][0] )
            / ( 360 + $bbox[2] - $bbox[0] ) + 0.5 );
       my $url
            = $wmsUrl
            . "&BBOX="
            . $bboxList[0][0] . ","
            . $bboxList[0][1] . ","
            . $bboxList[0][2] . ","
            . $bboxList[0][3];
        $url = $url . "&WIDTH=$width1&HEIGHT=$height";

        my $tmpOutput1 = File::Temp->new(
            TEMPLATE => 'baseImage_a_XXXX',
            DIR      => $outDir,
            SUFFIX   => '.png',
            UNLINK   => 1
        );
        my $response = $ua->get($url);
        if ( $response->is_success() ) {
            my $data = $response->content();
            if ( open FILE, ">", $tmpOutput1 ) {
                print FILE $data;
                close(FILE);
            }
            else {
                print STDERR "Could not write to $tmpOutput1\n";
                Giovanni::Util::exit_with_error( $response->code() )
                    unless -f $tmpOutput1;
            }
        }
        else {
            print STDERR "Could not get response from $url\n";
            Giovanni::Util::exit_with_error( $response->code() );
        }
        
        $url
            =~ s/BBOX=$bboxList[0][0],$bboxList[0][1],$bboxList[0][2],$bboxList[0][3]/BBOX=$bboxList[1][0],$bboxList[1][1],$bboxList[1][2],$bboxList[1][3]/;
        $url =~ s/WIDTH=$width1/WIDTH=$width2/;
        my $tmpOutput2 = File::Temp->new(
            TEMPLATE => 'baseImage_b_XXXX',
            DIR      => $outDir,
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
            print STDERR "Could not get response from $url\n";
            Giovanni::Util::exit_with_error( $response->code() );
        }
        my $cmd = "convert $tmpOutput1 $tmpOutput2 +append $outFile";
        my $ret = system($cmd);
        if ($?) { Giovanni::Util::exit_with_error("Failed to merge WMS images"); }   
    }
    else {
        my $url = $wmsUrl
            . "&WIDTH=$width&HEIGHT=$height&BBOX=$bbox[0],$bbox[1],$bbox[2],$bbox[3]";

        my $response = $ua->get($url);
        if ( $response->is_success() ) {
            my $data = $response->content();
            if ( open FILE, ">", $outFile ) {
                print FILE $data;
                close(FILE);
            }
            else {
                die "Could not download $outFile"
                    unless -f $outFile;
            }
        }

        else {
            print STDERR "Could not get response from $url\n";
            Giovanni::Util::exit_with_error( $response->code() );
        }
    }
}

sub splitBoundingBox {
    my @bboxList;
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

1;
__END__

=head1 NAME

Giovanni::Map::Util - some useful tools for map image generation

=head1 SYNOPSIS

  use Giovanni::Map::Util;
  
  my $result = Giovanni::Map::Util::reprojection($inFile, $inSRS, $outFile, $outSRS, %options);

=head1 DESCRIPTION

Reproject map images. Inputs:

=over

=item inFile - the source data

=item inSRS - the SRS of source data.

=item outFile - the target data

=item outSRS - the SRS of target data.

=item options - the output options, such as bounding box and size

=back


Returns successful or not:

=over

=item result - 1 for successful, 0 failed

=head1 AUTHOR

Peisheng Zhao, E<lt>peisheng.zhao-1@nasa.govE<gt>

=cut
