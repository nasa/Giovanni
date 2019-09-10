package Giovanni::Visualizer::Drivers::InteractiveMaps;

use strict;
use warnings;
use File::Basename;
use Giovanni::Data::NcFile;
use Giovanni::Visualizer::ContourMap;
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

Giovanni::Visualizer::Drivers::InteractiveMaps - creates WMS file for interactive map visualization

=head1 SYNOPSIS

use Giovanni::Visualizer::Drivers::InteractiveMaps;

$driver = new Giovanni::Visualizer::Drivers::InteractiveMaps();

my $params = {};

my $resultItems = $driver->visualize(params);

=head1 DESCRIPTION

Creates WMS file for interactive map visualization

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

sub appendVariableLayerToMapTemplate {
    my ($inFile,       $plotType, $layer,       $layerType,
        $vectorLayers, $imgFile,  $contourFile, $mapFileContent,
        $xc,           $metaInfo
    ) = @_;
    my $vectorU = $vectorLayers->{vectorU};
    my $vectorV = $vectorLayers->{vectorV};
    my ($vectorLayerNode)
        = $xc->findnodes('/ns:Map/ns:Layer[@name="UVRASTER"]');
    my ($scalarLayerNode) = $xc->findnodes('/ns:Map/ns:Layer[@name="LAYER"]');
    my ($contourLayerNode)
        = $xc->findnodes('/ns:Map/ns:Layer[@name="CONTOUR"]');

    if (   ( not defined $vectorLayerNode )
        && ( not defined $scalarLayerNode )
        && ( not defined $contourLayerNode ) )
    {
        die "Failed to parse WMS map file template";
    }
    $mapFileContent->removeChild($vectorLayerNode);
    $mapFileContent->removeChild($scalarLayerNode);
    $mapFileContent->removeChild($contourLayerNode);

    my $parser = XML::LibXML->new();
    my $newLayerNode
        = $layerType eq 'scalar'
        ? $parser->parse_string( $scalarLayerNode->toString() )
        ->documentElement()
        : $parser->parse_string( $vectorLayerNode->toString() )
        ->documentElement();
    $newLayerNode->setAttribute( "name", $layer );
    my $layerXpathContext = XML::LibXML::XPathContext->new($newLayerNode);
    $layerXpathContext->registerNs( 'ns',
        'http://www.mapserver.org/mapserver' );
    my ($dataNode) = $layerXpathContext->findnodes('/ns:Layer/ns:data');
    $dataNode->removeChildNodes();
    my ($hrefNode)
        = $layerXpathContext->findnodes(
        "/ns:Layer/ns:Metadata/ns:item[\@name='wms_dataurl_href']" );
    $hrefNode->removeChildNodes();
    my ($titleNode)
        = $layerXpathContext->findnodes(
        "/ns:Layer/ns:Metadata/ns:item[\@name='wms_Title']");
    $titleNode->removeChildNodes();

    if ( $layerType eq 'scalar' ) {
        my ($dTypeNode)
            = $layerXpathContext->findnodes('/ns:Layer/ns:dataType');
        if ( defined $dTypeNode ) {
            $dTypeNode->removeChildNodes();
            $dTypeNode->appendText( "" . $metaInfo->{"DATA_TYPE"} );
        }
        $dataNode->appendText("'$imgFile'");
        $hrefNode->appendText("'$inFile'");
    }
    else {
        die "Vector U and vector V cannot be found"
            if ( not defined $vectorU || not defined $vectorV );
        print STDERR "vector u is $vectorU, v is $vectorV \n";

        my @bbox = split( /[,\n]/,
            Giovanni::Data::NcFile::data_bbox( $inFile, 'lat', 'lon' ) );
        if ( not defined $bbox[3] or $bbox[3] eq '' ) {
            my %varInfo = Giovanni::Util::getNetcdfDataVariables($inFile);
            my ( $base, $dir, $ext ) = fileparse( $inFile, '\..*' );
            my $p_ncfile = $dir . $base . "_p" . $ext;
            unless ( -f $p_ncfile ) {
                my $flag
                    = Giovanni::Data::NcFile::pixellate( $inFile,
                    $p_ncfile, [ keys %varInfo ] );
                unless ($flag) {
                    die "Failed to pixellate data file";
                }
            }
            $inFile = $p_ncfile;
        }
        my $mergedFile
            = Giovanni::Util::mergeVectorComponents(
            File::Basename::dirname($inFile),
            $inFile, $vectorU, $vectorV );
        $dataNode->appendText("\"$mergedFile\"");
        my ( $magMin, $magMax )
            = magnitudeRange( $vectorU, $vectorV, $inFile );

        if ( defined $magMax ) {
            if ( $magMax =~ /^[+-]?\d+\.?\d*$/ ) {
                my $uvScale = sprintf( "%.2f", 64 / $magMax )
                    ;    #maximum size of line is 64
                my $legendText = sprintf( "%.2f", 20 / $uvScale );
                $legendText = "\n\n" . "  " . $legendText;

                my $gdalInfo   = "gdalinfo $mergedFile | grep merged#units";
                my $unitString = `$gdalInfo`;
                if ( defined $unitString ) {
                    my $ustring
                        = ( split( "=", $unitString ) )[1];
                    $ustring = " " . $ustring . "\n\n\n\n\n\n";
                    $legendText .= $ustring;
                }
                my ($scaleNode)
                    = $layerXpathContext->findnodes(
                    '/ns:Layer/ns:processing[contains(text(),"UV_SIZE_SCALE")]'
                    );
                if ( defined $scaleNode ) {
                    $scaleNode->removeChildNodes();
                    $scaleNode->appendText("UV_SIZE_SCALE\=$uvScale");
                }
                my ($classNode)
                    = $layerXpathContext->findnodes(
                    "/ns:Layer/ns:Class[\@name='legend']");
                $classNode->setAttribute( "name", $legendText );
            }
            else {
                print STDERR
                    "INFO-Visualizer:  Max value of magnitude is not number from U:$vectorU and V:$vectorV\n";
            }
        }
        else {
            print STDERR
                "INFO-Visualizer: Max value of magnitude is not defined from U:$vectorU and V:$vectorV\n";
        }
    }
    $titleNode->appendText( $metaInfo->{'WMS_TITLE'} );
    if ( defined $metaInfo->{'CAPTION'} ) {
        my $metadataNode = $titleNode->parentNode();
        my $captionNode  = XML::LibXML::Element->new('item');
        $captionNode->setAttribute( 'name', 'caption' );
        $captionNode->appendText( $metaInfo->{'CAPTION'} );
        $metadataNode->appendChild($captionNode);
    }
    $mapFileContent->appendChild($newLayerNode);

    # update contour layer in map file
    if ( $plotType =~ m/OVERLAY/i && $layerType eq 'scalar' ) {
        my $newContourNode
            = $parser->parse_string( $contourLayerNode->toString() )
            ->documentElement();
        $newContourNode->setAttribute( "name", $layer . "_Contour" );
        $layerXpathContext = XML::LibXML::XPathContext->new($newContourNode);
        $layerXpathContext->registerNs( 'ns',
            'http://www.mapserver.org/mapserver' );
        my ($contourDataNode)
            = $layerXpathContext->findnodes('/ns:Layer/ns:data');
        $contourDataNode->removeChildNodes();
        $contourDataNode->appendText("'$contourFile'");
        $mapFileContent->appendChild($newContourNode);
    }
}

sub appendContourLayerToMapTemplate {
    my ( $layer, $mapFileContent, $xc, $layerOptions ) = @_;
    if ( defined $layerOptions->{contourcolor} ) {
        my $cse
            = "/ns:Map/ns:Layer[\@name=\""
            . $layer
            . "_Contour\"]/ns:Class/ns:Style/ns:color";
        my ($contourColorNode) = $xc->findnodes("$cse");
        my @cColor = split( /\+/, $layerOptions->{contourcolor} );
        $contourColorNode->setAttribute( "red",   $cColor[0] );
        $contourColorNode->setAttribute( "green", $cColor[1] );
        $contourColorNode->setAttribute( "blue",  $cColor[2] );
    }
    if ( defined $layerOptions->{contoursize} ) {
        my $cse
            = "/ns:Map/ns:Layer[\@name=\""
            . $layer
            . "_Contour\"]/ns:Class/ns:Style/ns:width";
        my ($contourSizeNode) = $xc->findnodes("$cse");
        $contourSizeNode->removeChildNodes();
        $contourSizeNode->appendText( $layerOptions->{contoursize} );
    }
    if ( defined $layerOptions->{contourlinestyle} ) {
        my $cse
            = "/ns:Map/ns:Layer[\@name=\""
            . $layer
            . "_Contour\"]/ns:Class/ns:Style/ns:pattern";
        my ($contourStyleNode) = $xc->findnodes("$cse");
        $contourStyleNode->removeChildNodes();
        if ( $layerOptions->{contourlinestyle} eq "solid" ) {
            $contourStyleNode->appendText("2000 0 2000 0");
        }
        elsif ( $layerOptions->{contourlinestyle} eq "dotted" ) {
            $contourStyleNode->appendText("1 3 1 3");
        }
        elsif ( $layerOptions->{contourlinestyle} eq "dashed" ) {
            $contourStyleNode->appendText("10 5 5 10");
        }
    }
}

# generate map image
sub generateMapImage {
    my ( $dataFile, $layer, $sld, $smoothFlag ) = @_;
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

# Customize map generation parameters based on layer options and then call map generation
sub createMapImageWithOptions {
    my ( $inFile, $layer, $sldFileList, $layerOptions ) = @_;
    my $smoothFlag
        = defined $layerOptions->{smooth}
        ? $layerOptions->{smooth}
        : 0;

    my ( $imgFile, $worldFile )
        = generateMapImage( $inFile, $layer, ${$sldFileList}[0],
        $smoothFlag );
    die "Generation of map image has failed"
        unless defined $imgFile && $worldFile;
    return ( $imgFile, $worldFile );
}

sub generateContourMap {
    my ( $inFile, $layer, $sldFileList, $layerOptions ) = @_;
    my $defaultSld = Giovanni::OGC::SLD->new( FILE => ${$sldFileList}[0] );
    my @defaultRange = $defaultSld->getDataRange();
    my %contourOptions = ();
    my ( $contourFile, $contourInterval );

    $contourOptions{VARIABLE} = $layer;
    $contourOptions{MIN}
        = defined $layerOptions->{min}
        ? $layerOptions->{min}
        : $defaultRange[0];
    $contourOptions{MAX}
        = defined $layerOptions->{max}
        ? $layerOptions->{max}
        : $defaultRange[1];
    $contourOptions{INTERVAL}
        = defined $layerOptions->{contourinterval}
        && $layerOptions->{contourinterval} ne "undefined"
        ? $layerOptions->{contourinterval}
        : undef;
    $contourFile
        = Giovanni::Visualizer::ContourMap::contourMap( $inFile,
        %contourOptions );

    if ( not defined  $contourOptions{INTERVAL} ) {
        my $ci = ( $defaultRange[1] - $defaultRange[0] ) / 10;
        $contourInterval = sprintf( "%.4g", $ci );
    }
    if ( not -f $contourFile ) {
        die "Failed to generate contour file";
    }
    return ( $contourFile, $contourInterval );
}

sub appendMapMetadata {
    my ( $responseMapDoc, $metaInfo, $responseContourDoc ) = @_;

    # Add title
    if ( defined $metaInfo->{'TITLE'} ) {
        my ( $mainTitle, $subTitle ) = split( "\n", $metaInfo->{'TITLE'}, 2 );
        $responseMapDoc->setAttribute( 'title',    $mainTitle );
        $responseMapDoc->setAttribute( 'subTitle', $subTitle );
        if ( defined $responseContourDoc ) {
            $responseContourDoc->setAttribute( 'title',
                "Contour for " . $mainTitle );
            $responseContourDoc->setAttribute( 'subTitle', $subTitle );
        }
    }

    # Add other variable information for the UI titles, layer names,
    # # etc.
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
    if ( defined $responseContourDoc ) {
        if ($metaInfo) {
            $responseContourDoc->setAttribute( 'fullName',
                $metaInfo->{'FULL_NAME'} );
            $responseContourDoc->setAttribute( 'timeRange',
                $metaInfo->{'TIME_RANGE'} );
            $responseContourDoc->setAttribute( 'bbox', $metaInfo->{'BBOX'} );
            $responseContourDoc->setAttribute( 'longName',
                $metaInfo->{'LONG_NAME'} );
            $responseContourDoc->setAttribute( 'spatialResolution',
                $metaInfo->{'SPATIAL_RESOLUTION'} );
            $responseContourDoc->setAttribute( 'platformInstrument',
                $metaInfo->{'PLATFORM_INSTRUMENT'} );
            $responseContourDoc->setAttribute( 'version',
                $metaInfo->{'VERSION'} );
            $responseContourDoc->setAttribute( 'zvalue',
                $metaInfo->{'ZVALUE'} );
            $responseContourDoc->setAttribute( 'zunits',
                $metaInfo->{'ZUNITS'} );
            $responseContourDoc->setAttribute( 'units',
                $metaInfo->{'UNITS'} );
        }

        if ( defined ${ $metaInfo->{'FILE_DATA_RANGE'} }[0]
            and ${ $metaInfo->{'FILE_DATA_RANGE'} }[1] )
        {
            $responseContourDoc->setAttribute( 'min',
                ${ $metaInfo->{'FILE_DATA_RANGE'} }[0] );
            $responseContourDoc->setAttribute( 'max',
                ${ $metaInfo->{'FILE_DATA_RANGE'} }[1] );
        }
        $responseContourDoc->setAttribute( 'intervalcount',
            defined $metaInfo->{CONTOUR_INTERVAL}
            ? $metaInfo->{CONTOUR_INTERVAL}
            : "" );
    }

    # Add caption
    if ( defined $metaInfo->{'CAPTION'} ) {
        $responseMapDoc->setAttribute( 'caption', $metaInfo->{'CAPTION'} );
        $responseContourDoc->setAttribute( 'caption', $metaInfo->{'CAPTION'} )
            if defined $responseContourDoc;
    }

    # Add scale type
    $responseMapDoc->setAttribute( 'scale', $metaInfo->{'SCALE_TYPE'} );

    # Add max resolution
    if ( defined $metaInfo->{'MAX_RES'} ) {
        $responseMapDoc->setAttribute( 'maxRes', $metaInfo->{'MAX_RES'} );
    }
}

# Our goal is to generate:
#   - Reponse for the main Visualizer.pm driver. This gets returned to client via service_manager.
#   - SLD files and legends for options picker (unless vector plot)
#   - variableName.XXXXXX.png (unless vector plot, since it directly visualizes json data )
#   - WMS variableName.XXXXXX.map file.
#   - WMS variableName.XXXXXX.map.xml file.
#   - WMS variableName.XXXXXX.map.json file.
sub visualize {
    my ( $self, $visualizerParams ) = @_;
    my $inFileDir   = $visualizerParams->{outDir};
    my $result      = { items => [] };
    my $plotType    = $visualizerParams->{plotType};
    my $sessionId   = $visualizerParams->{sessionId};
    my $resultsetId = $visualizerParams->{resultsetId};
    my $resultId    = $visualizerParams->{resultId};

    my @responseFiles = ();

    foreach my $inFile ( keys %{ $visualizerParams->{dataFiles} } ) {
        my $inputItems = $visualizerParams->{dataFiles}{$inFile};

        # Compute alt image title
        my $altTitle = Giovanni::Visualizer::VisUtil::getPlotAltTitle(
            $visualizerParams->{plotType}, $inFile );

        # Get variable metadata
        my %varInfo = Giovanni::Util::getNetcdfDataVariables($inFile);

        my $vectorLayers     = {};
        my $layerTypes       = {};
        my @orderedLayerList = ();

# - Iterate through available (and expected variables) and determine whether we
#   have a usual map, correlation map, or vector map.
# - Classify each layer as either scalar or vector.
# - Determine V and U components (layers) for vector maps
# - Compile an ordered list of layers to process (orderedLayerList). Order is
#   important for correlation map, but not important for everything else.
        if ( exists $varInfo{correlation} ) {

            # Handle correlation maps where time_matched_difference exists
            # only when the two variables have the same quantity type
            foreach
                my $var (qw(correlation n_samples time_matched_difference))
            {
                if ( exists $varInfo{$var} ) {
                    $layerTypes->{$var} = "scalar";
                    push( @orderedLayerList, $var );
                }
            }
        }
        else {

            # Check for vector components
            foreach my $var ( sort keys %varInfo ) {
                if ( exists $varInfo{$var}{vectorComponents} ) {
                    my $vectorField = $varInfo{$var}{vectorComponents};
                    ( my $vectorLayer = $vectorField ) =~ s/.*of\s+(.+)$/$1/;
                    $layerTypes->{$vectorLayer} = "vector"
                        if not defined $layerTypes->{$vectorLayer};

                    # Check if this is a vector component variable
                    $vectorLayers->{vectorU} = $var
                        if $vectorField =~ /([u]) of (\S+)$/;
                    $vectorLayers->{vectorV} = $var
                        if $vectorField =~ /([v]) of (\S+)$/;
                }
                else {
                    $layerTypes->{$var} = "scalar";
                }
            }

            # Non-correlation maps: order of layers not important
            @orderedLayerList = keys( %{$layerTypes} );
        }

        foreach my $layer (@orderedLayerList) {
            my $layerType
                = $layerTypes->{$layer} ? $layerTypes->{$layer} : "scalar";

            # Retrieve plot options for a given key (layer, in this case)
            my $plotOptions
                = Giovanni::Visualizer::VisUtil::getVisualizationOptionsByKey(
                $inputItems, $layer );

# Sanity check - prevent visualization of a datafile with options that belong to other file
            last
                if defined $plotOptions
                && defined $plotOptions->{datafile}
                && File::Basename::basename($inFile) ne
                File::Basename::basename( $plotOptions->{datafile} );

# Deterine plot options. Note that even though we iterate through 'normal' layers,
# each layer has essentially two sub-layers - layer itself and overlayed contours.
# Supplied options can apply to one of these two 'sub-layers'. So, let's determine
# which options it is.
            my $layerOptions   = {};
            my $contourOptions = {};
            $layerOptions = $plotOptions
                if defined $plotOptions
                && defined $plotOptions->{name}
                && $plotOptions->{name} eq $layer;
            $contourOptions = $plotOptions
                if defined $plotOptions
                && defined $plotOptions->{name}
                && $plotOptions->{name} eq $layer . "_contour";

            # create a XML node to store map metadata information
            my $xmlParser = XML::LibXML->new();
            $xmlParser->keep_blanks(0);
            my $responseDom = $xmlParser->parse_string('<layers />');
            my $responseDoc = $responseDom->documentElement();

            # Set the session IDs
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

            # Create layer metadata node
            my ( $responseMapDoc, $responseContourDoc );
            $responseMapDoc = XML::LibXML::Element->new('layer');
            $responseMapDoc->setAttribute( 'name', $layer );
            $responseMapDoc->setAttribute( 'type',
                $layerType eq 'vector' ? 'vector' : 'map' );
            $responseDoc->appendChild($responseMapDoc);

       # Create contour map metadata node (available only for overlay service)
            if ( $layerType ne 'vector' && $plotType =~ m/OVERLAY/i ) {
                $responseContourDoc = XML::LibXML::Element->new('layer');
                $responseContourDoc->setAttribute( 'type', 'contour' );
                $responseContourDoc->setAttribute( 'name',
                    $layer . "_contour" );
                $responseDoc->appendChild($responseContourDoc);
            }

# Collect and compute metadata for UI elements from various sources, including datafile, manifest etc
            my $metaInfo
                = Giovanni::Visualizer::VisUtil::collectMetadata( $inFile,
                $layer, $layerType, $layerOptions );

            # Normal maps have slds, images and sometimes - contours.
            # Vector maps do not have any of these.
            my ( $contourFile, $imgFile, $worldFile );
            if ( $layerType ne 'vector' ) {

                # Setup SLDs and retrive SLD metadata
                ( my $sldFileList, my $sldMetaInfos )
                    = Giovanni::Visualizer::VisUtil::getSlds( $inFileDir,
                    $metaInfo, $layer, $layerOptions );

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

                # Generate map image using matplotlib
                ( $imgFile, $worldFile )
                    = createMapImageWithOptions( $inFile, $layer,
                    $sldFileList, $layerOptions );

                # Pre-generate Tif file if the size of data file is greater than 10M
                my ( $fname, $dirname, $suffix ) = fileparse( $inFile, qr/\.[^.]+$/ );
                my $tifFile = "$dirname/$fname.tif";
                unless ( -f $tifFile) {
                  my $fSize = -s $inFile;
                  if ( $fSize > 10240000 ) {
                     my $vFile = "NETCDF:\"$inFile\":$layer";
                     my $rc
                           = system("gdalwarp -t_srs EPSG:4326 $vFile $tifFile >/dev/null");
                     if ($rc) {
                            print STDERR "gdalwarp command is failed, tif file cannot be generated\n";
                     }
                  }
                }                
                # Generate contour map
                ( $contourFile, $metaInfo->{CONTOUR_INTERVAL} )
                    = generateContourMap( $inFile, $layer, $sldFileList,
                    $contourOptions )
                    if ( $plotType =~ m/OVERLAY/i );
            }

            # Generate map file
            my ( $mapFilePrefix, $mapFilePath, $mapFileSuffix )
                = fileparse( $inFile, qr/\.[^.]*/ );
            $mapFilePrefix = $layer . "_" . $mapFilePrefix;
            my $mapFile
                = join( '/', ( $inFileDir, $mapFilePrefix ) ) . '.map';
            my $mapXMLFile = $mapFile . '.xml';
            my $mapXSLT    = $GIOVANNI::WMS{map_xml_xslt};

            # Check if datafile param exists
            my $existsMapManifest = -f $mapXMLFile;

            # Read the contents of map template - either the existing file
            # from the first run, or create a new one on the first run
            my $mapFileContent
                = $existsMapManifest
                ? Giovanni::Util::parseXMLDocument($mapXMLFile)
                : Giovanni::Util::parseXMLDocument(
                $GIOVANNI::WMS{map_xml_template} );
            my $xc = XML::LibXML::XPathContext->new($mapFileContent);
            $xc->registerNs( 'ns', 'http://www.mapserver.org/mapserver' );

            # Customize the map template for the currently processed layer
            # (kicks in only the first run)
            appendVariableLayerToMapTemplate(
                $inFile,      $plotType,       $layer,
                $layerType,   $vectorLayers,   $imgFile,
                $contourFile, $mapFileContent, $xc,
                $metaInfo
            ) unless $existsMapManifest;

            # Write contour options to the template
            appendContourLayerToMapTemplate( $layer, $mapFileContent, $xc,
                $contourOptions )
                unless !%$contourOptions;

            # Write down the customized map template metadata
            Giovanni::Util::writeFile( $mapXMLFile,
                $mapFileContent->toString() );
            system("xsltproc -o $mapFile $mapXSLT $mapXMLFile");
            $responseDoc->setAttribute( 'mapfile', basename($mapFile) );

            # Write metadata into the response XML document
            appendMapMetadata( $responseMapDoc, $metaInfo,
                $responseContourDoc );

            my $xml2Json = XML::XML2JSON->new(
                module           => 'JSON::XS',
                pretty           => 1,
                attribute_prefix => '',
                content_key      => 'value',
                force_array      => 1
            );
            my $jsonObj = $xml2Json->dom2obj($responseDom);

            # Construct the manifest file based on the data file name
            # Start with the result file name
            my $plotManifestFile
                = File::Basename::fileparse( $inFile, '[^\.]+$' )
                . "map.json";

            # Insert back the layer name
            $plotManifestFile =~ s/^(g4\.)?[^\.]+\./$layer\./;

            # Remove repeated layer names if any
            $plotManifestFile =~ s/($layer\.){2,}/$layer\./g;
            $plotManifestFile = $inFileDir . "/" . $plotManifestFile;
            unlink $plotManifestFile if -f $plotManifestFile;
            Giovanni::Util::writeFile( $plotManifestFile,
                $xml2Json->obj2json($jsonObj) );
            my $imgUrl
                = Giovanni::Util::convertFilePathToUrl( $plotManifestFile,
                \%GIOVANNI::URL_LOOKUP );

            push(
                @{ $result->{items} },
                {   datafile => $inFile,
                    imageUrl => $imgUrl,
                    key      => $layer,
                    title    => $altTitle
                }
            );
        }    # end of layer
    }    # end of inFile
    return $result;
}

# Calculates minimum and maximum values of magnitude for wind vector data
sub magnitudeRange {
    my ( $uname, $vname, $infile ) = @_;
    my $min;
    my $max;
    my $tmp = File::Temp->new(
        TEMPLATE => 'tempXXXX',
        DIR      => $ENV{TMPDIR},
        SUFFIX   => '.nc'
    );
    `ncap2 -O -s \"mag=sqrt($uname*$uname+$vname*$vname)\" $infile $tmp`;
    my $tmp1 = File::Temp->new(
        TEMPLATE => 'tempXXXX',
        DIR      => $ENV{TMPDIR},
        SUFFIX   => '.nc'
    );
    `ncap2 -O -s \"vmin=min(mag)\;vmax=max(mag)\" $tmp $tmp1`;
    my $values = `ncks -H -C -v vmin,vmax $tmp1`;

    if ( defined $values ) {
        ( my $v1, my $v2 ) = split( "\n", $values );
        if ( $v1 =~ /vmax/i ) {
            $max = ( split( " ", $v1 ) )[-1];
            $min = ( split( " ", $v2 ) )[-1];
        }
        elsif ( $v1 =~ /vmin/i ) {
            $min = ( split( " ", $v1 ) )[-1];
            $max = ( split( " ", $v2 ) )[-1];
        }
    }
    return ( $min, $max );
}

1;
