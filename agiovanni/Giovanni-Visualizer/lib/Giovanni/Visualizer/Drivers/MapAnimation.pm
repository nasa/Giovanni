package Giovanni::Visualizer::Drivers::MapAnimation;

use strict;
use warnings;
use DateTime;
use File::Basename;
use Giovanni::Visualizer::VisUtil;
use Giovanni::Util;
use XML::XML2JSON;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
# our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# our @EXPORT = qw( );

our $VERSION = '0.01';

# Preloaded methods go here.

1;

=head1 NAME

Giovanni::Visualizer::Drivers::MapAnimation - creates WMS based animation

=head1 SYNOPSIS

use Giovanni::Visualizer::Drivers::MapAnimation;

$driver = new Giovanni::Visualizer::Drivers::MapAnimation();

my $params = {};

my $resultItems = $driver->visualize(params);

=head1 DESCRIPTION

Visualizes Gnuplot family of plots

=item visualize(params);

Performs visualization. See visualize() in Giovanni::Visualizer for the
most up-to-date format of the visualization parameters as this might be outdated.
Note that the key parm typically represents layer or variable, but can be any other string.
If not set, defaults to $GIOVANNI::VISUALIZER->{DEFAULT_VIS_KEY}.
Please make output key is the same as input key if specified, unless this a default key!

    params = {
        optionsParser => optionsParser, # Instance of Giovanni::Visualizer::Preferences containing JSON schema
        dataFiles => {dataFilePath => [{key=>string, options=>hash}]}, # Input items - files with options and keys (layers)
        outDir => sessionDir, # Output directory
        plotType => plotType, # Plot type, see giovanni.cfg
        resultsetId => resultsetId, # Result set ID
        resultId => resultId, # Result ID
        sessionId => sessionId # Session ID
    };

returns an array of hashes. Typical return params (need at least datafile and imageUrl):
    [{
        datafile => inFile, # Input file
        imageUrl => png_url, # Image url
        plotOptions => {}, # Hash of options complying with the plot schema
        caption => caption, # String
        key => key # String identifier of the plot
    }]
    
=head1 AUTHOR

AG Team

=cut

sub new {
    my ( $class, %params ) = @_;
    my $self = bless \%params, $class;    # Currently unused
    return $self;
}

sub visualize {
    my ( $self, $visualizerParams ) = @_;

    my $outDir = $visualizerParams->{outDir};
    my $result = { items => [] };
    my $sessionId   = $visualizerParams->{sessionId};
    my $resultsetId = $visualizerParams->{resultsetId};
    my $resultId    = $visualizerParams->{resultId};

    my $layerOptions
        = {};   # Same layer-specific single options item applies to all files
    my $dataFileList = [];
    my $altTitle;

# A hash to hold animation info: file name and date-time string are its elements
    my $animationDataHash = {};
    foreach my $inFile ( keys %{ $visualizerParams->{dataFiles} } ) {
        push(@$dataFileList, $inFile);
        my $inputItems  = $visualizerParams->{dataFiles}{$inFile};
        my $plotOptions = ${$inputItems}[0]->{plotOptions};

        # Compute alt image title
        $altTitle = Giovanni::Visualizer::VisUtil::getPlotAltTitle(
            $visualizerParams->{plotType}, $inFile );

        # Get variable info
        my %varInfo = Giovanni::Util::getNetcdfDataVariables($inFile);
        foreach my $layerName ( keys %varInfo ) {
            my $ts = $varInfo{$layerName}{time};
            $ts =~ s/^\s+//;
            $ts =~ s/\s+$//;
            my $t       = DateTime->from_epoch( epoch => $ts );
            my $timeStr = $t->iso8601();
            my $info    = { file => $inFile, time => $timeStr };
            $layerOptions->{$layerName} = $plotOptions
                if !exists( $layerOptions->{$layerName} )
                && $layerName eq $plotOptions->{name};
            if ( exists $animationDataHash->{$layerName} ) {
                push( @{ $animationDataHash->{$layerName} }, $info );
            }
            else {
                $animationDataHash->{$layerName} = [$info];
            }
        }
    }
    
    
    # create a XML node to store map metadata information
    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);
    my $responseDom = $xmlParser->parse_string('<layers />');
    my $responseDoc = $responseDom->documentElement();
    $responseDoc->setAttribute( 'session',   $sessionId );
    $responseDoc->setAttribute( 'resultset', $resultsetId );
    $responseDoc->setAttribute( 'result',    $resultId );
    # Set domain lookup info for sharding, if present 
    if (%GIOVANNI::DOMAIN_LOOKUP) {
       foreach my $key ( sort keys %GIOVANNI::DOMAIN_LOOKUP ) {
          next unless ref $GIOVANNI::DOMAIN_LOOKUP{$key} eq 'ARRAY';
          my @cnameList = @{ $GIOVANNI::DOMAIN_LOOKUP{$key} };
          my $domain    = XML::LibXML::Element->new('domain');
          $domain->setAttribute( 'name', $key );
          foreach my $cname (@cnameList) {
             $domain->appendTextChild( 'shard', $cname );
          }
          $responseDoc->appendChild($domain);
       }
    }
    foreach my $layerName ( keys %$animationDataHash ) {
     
        my $responseMapDoc = XML::LibXML::Element->new('layer');
        $responseMapDoc->setAttribute( 'name', $layerName );
        $responseMapDoc->setAttribute( 'type', 'map');
        $responseDoc->appendChild($responseMapDoc);
        # Get min/max values
        my @fileDataRange = Giovanni::Util::getNetcdfDataRange( $dataFileList, $layerName );
        # Sort each frame based on the time string
        my @dataList = sort { $a->{time} cmp $b->{time} }
            @{ $animationDataHash->{$layerName} };
 
        # Add time values
        foreach my $tData ( @dataList ) {
           my $ts = $tData->{time};
           my $node = XML::LibXML::Element->new('time');
           $node->appendText($ts);
           $responseDoc->appendChild($node);
        }

        # Collect and compute metadata for UI elements from various sources, including datafile, manifest etc
        my $metaInfo
                = Giovanni::Visualizer::VisUtil::collectMetadata( $dataList[0]->{file},
                $layerName, 'map', $layerOptions->{$layerName} );

        # Setup SLDs and retrive SLD metadata
        ( my $sldFileList, my $sldMetaInfos )
                    = Giovanni::Visualizer::VisUtil::getSlds( $outDir,
                    $metaInfo, $layerName, $layerOptions->{$layerName} );

        # Put SLD metadata on the response map file XML
        foreach my $metaSldInfo ( @{$sldMetaInfos} ) {
           my $node = XML::LibXML::Element->new(
                        $metaSldInfo->{sldName} );
           foreach my $metaKey ( keys %{$metaSldInfo} ) {
              next if $metaKey eq 'sldName';
              $node->setAttribute( $metaKey,
                            $metaSldInfo->{$metaKey} );
           }
           $responseMapDoc->appendChild($node);
        }

        # Generate frame images using matplotlib
        foreach my $frame ( @{ $animationDataHash->{$layerName} } ) {
           my $frameNode = XML::LibXML::Element->new('frames');
           my $infile = $frame->{file};
           my ( $imgFile, $worldFile )
                    = createMapImageWithOptions( $infile, $layerName,
                    $sldFileList, $layerOptions->{$layerName} );
           $frameNode->setAttribute( 'data', $infile );
           $frameNode->setAttribute( 'image', $imgFile );
           $frameNode->setAttribute( 'time', $frame->{time} );
           $responseMapDoc->appendChild($frameNode);
        }
        # Generate legend
        my $intFlag = Giovanni::Util::getNetcdfDataType( $dataList[0]->{file}, $layerName );
        my $legendFile = createLegend ( $layerName, $intFlag, ${$sldFileList}[0] );

 
        # Write metadata into the response XML document
         appendMapMetadata( $responseMapDoc, $metaInfo );

        my $xml2Json = XML::XML2JSON->new(
                module           => 'JSON::XS',
                pretty           => 1,
                attribute_prefix => '',
                content_key      => 'value',
                force_array      => 1
            );
        my $jsonObj = $xml2Json->dom2obj($responseDom);

        # Pass on user options
        #if ( exists $layerOptions->{$layerName} ) {
        #    foreach my $key ( keys %{ $layerOptions->{$layerName} } ) {
        #        next unless $key ne "name";
        #        next unless defined $layerOptions->{$layerName}{$key};
        #        $mapUrl
        #            .= '&' . "$key="
        #            . URI::Escape::uri_escape(
        #            $layerOptions->{$layerName}{$key} );
        #    }
        #}
        
        # Construct the manifest file based on the layer name
        my $plotManifestFile
                = $outDir . "/" . $layerName . "_animation.json";
        unlink $plotManifestFile if -f $plotManifestFile;
        Giovanni::Util::writeFile( $plotManifestFile,
                $xml2Json->obj2json($jsonObj) );
        my $imgUrl
                = Giovanni::Util::convertFilePathToUrl( $plotManifestFile,
                \%GIOVANNI::URL_LOOKUP );

        # Set output items
        push(
            @{ $result->{items} },
            {   datafile    =>$dataFileList,
                imageUrl    => $imgUrl,
                key         => $layerName,
                plotOptions => exists $layerOptions->{$layerName}
                ? $layerOptions->{$layerName}
                : {},
                title => $altTitle
            }
        );
    }
    return $result;
}

# Customize map generation parameters based on layer options and then call map generation
sub createMapImageWithOptions {
    my ( $inFile, $layer, $sldFileList, $layerOptions ) = @_;
    my $smoothFlag
        = defined $layerOptions->{smooth}
        ? $layerOptions->{smooth}
        : 0;
    my $width  =  $layerOptions->{width};
    my $height =  $layerOptions->{height};
    my ( $imgFile, $worldFile )
        = generateMapImage( $inFile, $layer, ${$sldFileList}[0],
        $smoothFlag, $width, $height );
    die "Generation of map image has failed"
        unless defined $imgFile && $worldFile;
    return ( $imgFile, $worldFile );
}

# generate map image
sub generateMapImage {
    my ( $dataFile, $layer, $sld, $smoothFlag, $width, $height ) = @_;
    my $imgFile   = $dataFile . "_" . $layer . ".png";
    my $worldFile = $dataFile . "_" . $layer . ".wld";
    my $dir       = dirname($dataFile);
    my $tmpOutput = File::Temp->new(
        TEMPLATE => 'tmp_' . $layer . '_XXXX',
        DIR      => $dir,
        SUFFIX   => '.png'
    );
    my $tmpWorld = File::Temp->new(
        TEMPLATE => 'tmp_' . $layer . '_XXXX',
        DIR      => $dir,
        SUFFIX   => '.wld'
    );
    my @cmd = (
        "python_map_visualizer.py", $dataFile, $tmpOutput->filename,
        "--world", $tmpWorld->filename, "--extend_for_map_server",
    );
    push( @cmd, ( '--sld', $sld ) ) if defined $sld;
    push( @cmd, ( '--width', $width ) ) if defined $width;
    push( @cmd, ( '--height', $height ) ) if defined $height;
    push( @cmd, '--contour' ) if ( $smoothFlag eq 'on' );
    push( @cmd, "--variable" );
    push( @cmd, $layer );
    my $ret = system( join( " ", @cmd ) );

    if ( $ret != 0 ) {
        warn( "Generate map image Command returned non-zero: "
                . join( " ", @cmd ) );
        return ( undef, undef );
    }
    rename( $tmpOutput, $imgFile );
    chmod( 0664, $imgFile );
    rename( $tmpWorld, $worldFile );
    chmod( 0664, $worldFile );
    return ( $imgFile, $worldFile );
}

# Generate legend
sub createLegend {
    my ( $layer, $intFlag, $sldFile, $width, $height) = @_;
    $width  = defined $width  ? $width  : 100;
    $height = defined $height ? $height : 400;
    
    my $sldInfo = Giovanni::OGC::SLD->new( FILE => $sldFile );
    $sldInfo->setLayerName($layer);
    my $legendImg = $sldFile;
    $legendImg =~ s{\.[^.]+$}{};
    $legendImg .= "_legend.png";
    my %options = (
        type   => $intFlag,
        height => $height,
        width  => $width,
        units  => undef,
        scale  => $sldInfo->{layers}{$layer}{legendScale},
        file   => $legendImg
    );
    my $status = $sldInfo->createColorLegend(%options);
    if ( $status == 0 ) {
        Giovanni::Util::exit_with_error("Not able to create legend");
    }
    chmod( 0664, $legendImg );
    return $legendImg;
}

sub appendMapMetadata {
    my ( $responseMapDoc, $metaInfo ) = @_;
    # Add title
    if ( defined $metaInfo->{'TITLE'} ) {
        my ( $mainTitle, $subTitle ) = split( "\n", $metaInfo->{'TITLE'}, 2 );
        $responseMapDoc->setAttribute( 'title',    $mainTitle );
        $responseMapDoc->setAttribute( 'subTitle', $subTitle );
    }

    # Add other variable information for the UI titles, layer names,etc.
    if ($metaInfo) {
        $responseMapDoc->setAttribute( 'fullName', $metaInfo->{'FULL_NAME'} );
        $responseMapDoc->setAttribute( 'timeRange',
            $metaInfo->{'TIME_RANGE'} );
        $responseMapDoc->setAttribute( 'bbox',     $metaInfo->{'BBOX'} );
        $responseMapDoc->setAttribute( 'longName', $metaInfo->{'LONG_NAME'} );
        $responseMapDoc->setAttribute( 'spatialResolution',
            $metaInfo->{'SPATIAL_RESOLUTION'} );
        $responseMapDoc->setAttribute( 'platformInstrument',
            $metaInfo->{'PLATFORM_INSTRUMENT'} );
        $responseMapDoc->setAttribute( 'version', $metaInfo->{'VERSION'} );
        $responseMapDoc->setAttribute( 'zvalue',  $metaInfo->{'ZVALUE'} );
        $responseMapDoc->setAttribute( 'zunits',  $metaInfo->{'ZUNITS'} );
        $responseMapDoc->setAttribute( 'units',   $metaInfo->{'UNITS'} );
    }

    # Add caption
    if ( defined $metaInfo->{'CAPTION'} ) {
        $responseMapDoc->setAttribute( 'caption', $metaInfo->{'CAPTION'} );
    }

    # Add scale type
    $responseMapDoc->setAttribute( 'scale', $metaInfo->{'SCALE_TYPE'} );

}

1;
