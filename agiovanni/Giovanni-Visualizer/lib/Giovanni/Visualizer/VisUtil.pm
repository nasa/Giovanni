package Giovanni::Visualizer::VisUtil;

use strict;
use warnings;
use File::Basename;
use Giovanni::Cache;
use Giovanni::DataField;
use Giovanni::Logger::Algorithm;
use Giovanni::Map::Info;
use Giovanni::OGC::SLD;
use Giovanni::Util;
use Giovanni::UnitsConversion;

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

Giovanni::Visualizer::VisUtil - common utilities shared by the visualizer modules

=head1 SYNOPSIS

use Giovanni::Visualizer::VisUtil;


=head1 DESCRIPTION

Common utilities shared by the visualizer modules

=item visualize(params);

Performs visualization

=head1 AUTHOR

AG Team

=cut

sub new {
    my ( $class, %params ) = @_;
    my $me = \%params;
    bless $me, $class;
    return $me;
}

#################################################################################
# Working with options
#################################################################################

# Returns all keys from the array of visualization itesm [{datafile, key, options}]
# Can be used to iterate through all requested keys (e.g., layers)
sub getVisualizationKeys {
    my ($inputItems) = @_;
    my $keys = [];
    foreach my $inputItem ( @{$inputItems} ) {

        # Ignore default key, it's not a real layer
        push( @{$keys}, $inputItem->{key} )
            if $inputItem->{key} ne $GIOVANNI::VISUALIZER->{DEFAULT_VIS_KEY};
    }
    return $keys;
}

# Iterates through an array of visualization itesm [{datafile, key, options}]
# and returns options matching the supplied key. If this fails - returns
# options from a first found item with default key, if available
sub getVisualizationOptionsByKey {
    my ( $inputItems, $key ) = @_;

    # Attempt to return layer-specific options
    foreach my $inputItem ( @{$inputItems} ) {
        return $inputItem->{plotOptions} if $inputItem->{key} eq $key;
    }

    # If no layer-spacific options avaialble - return any options available
    foreach my $inputItem ( @{$inputItems} ) {
        return $inputItem->{plotOptions}
            if $inputItem->{key} eq $GIOVANNI::VISUALIZER->{DEFAULT_VIS_KEY};
    }
    return {};
}

#################################################################################
# Working with SLDs
#################################################################################

# Sample $layer name:
#   MAIMCPASM_5_2_0_RH
#
# Sample metaInfo (more attributes might be present, but are not currently used):
#    {
#      'NOMINAL_MIN': undef,
#      'NOMINAL_MAX': undef,
#      'SLDS': [
#      {
#        'url': 'https://local.nasa.gov/.../sld/divergent_burd_11_sld.xml',
#        'label': 'Blue-Red (Div), 11'
#      }],
#      'UNITS': 'fraction',
#      'FILE_DATA_RANGE': [
#        '0.0997314453125',
#        '0.9873046875'
#      ],
#      'UNIT_CONVERTED': 0,
#      'ORIGINAL_UNITS': 'fraction',
#      'DATA_TYPE': 0,
#      'SCALE_TYPE': 'linear',
#    };
#
# Sample layer SLD options:
#    {
#      'min': '0.3',
#      'max': '0.6',
#      'smooth': 'off',
#      'scale': 'linear',
#      'sld': 'https://nasa.gov/session/...../MAIMCPASM_5_2_0_RH_60687_1504725622no2_sld.xml'
#    };
#
# Sample output:
#
#    @sldFileList:
#    ['.../session//MAIMCPASM_5_2_0_RH_60687_1504725623sequential_ylgn_9_sld.xml']
#
#    $sldMetaInfos:
#    [{
#     'thumbnail': 'https://nasa.gov/session/...../MAIMCPASM_5_2_0_RH_MAIMCPASM_5_2_0_RH_60687_1504725623sequential_ylgn_9_sld.png',
#     'sldName': 'variable_sld',
#     'min': '0.3',
#     'name': 'MAIMCPASM_5_2_0_RH_sequential_ylgn_9_sld',
#     'max': '0.6',
#     'url': 'https://nasa.gov/session/...../MAIMCPASM_5_2_0_RH_60687_1504725623sequential_ylgn_9_sld.xml',
#     'type': '', // Can be inverted
#     'label': 'Yellow-Green (Seq), 9'
#     }]

# Gets a list of available SLDs from Giovanni config
# Can also return a shorter list of SLDs if specifically defined for a given layer in $layerOptions
sub getSldList {
    my ( $metaInfo, $layer, $layerOptions ) = @_;
    my @sldList  = ();
    my $sldCount = 0;

    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);

    if ( defined $layerOptions && defined $layerOptions->{sld} ) {
        push( @sldList, { url => $layerOptions->{sld} } );
    }
    else {
        @sldList  = @{ $metaInfo->{SLDS} };
        @sldList  = map { $_->{default} = 1; $_ } @sldList;
        $sldCount = @sldList;

        if ( defined $GIOVANNI::WMS{sld}{$layer} ) {
            $GIOVANNI::WMS{sld}{$layer}{url} = Giovanni::Util::createAbsUrl(
                $GIOVANNI::WMS{sld}{$layer}{url} );
            push( @sldList, $GIOVANNI::WMS{sld}{$layer} );
        }
        if ( defined $GIOVANNI::SLD_LIST ) {
            if ( -f $GIOVANNI::SLD_LIST ) {
                my $dom = $xmlParser->parse_file($GIOVANNI::SLD_LIST);
                my $doc = $dom->documentElement();
                foreach my $node ( $doc->findnodes('/slds/sld') ) {
                    my $sldHash = {};
                    foreach my $attr ( $node->getAttributes() ) {
                        $sldHash->{ $attr->nodeName() } = $attr->getValue();
                        if ( $attr->nodeName() eq 'url' ) {
                           my $sldUrl = 
                                        Giovanni::Util::convertFilePathToUrl( $sldHash->{ $attr->nodeName() },\%GIOVANNI::WWW_URL_LOOKUP );
                           $sldHash->{ $attr->nodeName() } = $sldUrl;
                        }
                    }
                    $sldHash->{default} = 0;
                    push( @sldList, $sldHash );
                }
            }
        }
    }
    return \@sldList;
}

# Checks if SLD is in the cache. If not - adds it.
sub checkAndCacheSldFile {
    my ( $inFileDir, $sldFileName, $cacher, $sldUrl ) = @_;
    my $cacheSldFile = $inFileDir . "/" . $sldFileName;
    
    return $cacheSldFile if ( -f $cacheSldFile );
    my $cacheOut = $cacher->get(
        DIRECTORY      => $inFileDir,
        KEYS           => [$sldUrl],
        REGION_LEVEL_1 => 'SLD'
    );
    my $cacheSldSize = -1;
    if ( exists( $cacheOut->{$sldUrl} ) ) {
        $cacheSldFile = $inFileDir . "/" . $cacheOut->{$sldUrl}{FILENAME};
        $cacheSldSize = -s $cacheSldFile
            if -f $cacheSldFile;
    }
    if (   ( not exists( $cacheOut->{$sldUrl} ) )
        || ( $cacheSldSize <= 0 ) )
    {
        $cacheSldFile
            = ( $cacheSldFile =~ /^((\w|-|\/|\:|\.|\+)+)/ )
            ? $1
            : '';
        $sldUrl
            = ( $sldUrl =~ /^((\w|-|\~|\/|\:|\.|\+)+)/ )
            ? $1
            : '';
        my $data = undef;
        
        if (-f $sldUrl) {
            $data = do {
                local $/ = undef;
                open my $fh, "<", $sldUrl
                    or die "could not open $sldUrl: $!";
                <$fh>;
            };
        } else {
            my $ua = LWP::UserAgent->new();
                $ua->env_proxy;
            my $response = $ua->get($sldUrl);
            $data = $response->content();
            $data = undef unless $response->is_success();
        }
        # Make a last attempt to see if another process already created the file
        return $cacheSldFile if -f $cacheSldFile  && (-s $cacheSldFile) > 0;
        if ( defined $data ) {
            unlink($cacheSldFile) if -f $cacheSldFile;
            my $ptr = Giovanni::Util::lockFile( $cacheSldFile );
            if ( open FILE, ">", $cacheSldFile ) {
                print FILE $data;
                close(FILE);
            }
            else {
                print STDERR "Could not write to $cacheSldFile\n";
                return 0
                    if $? == -1;
            }

            my $putOut = $cacher->put(
                DIRECTORY      => $inFileDir,
                KEYS           => [$sldUrl],
                REGION_LEVEL_1 => 'SLD',
                FILENAMES      => [$sldFileName]
            );
            Giovanni::Util::unlockFile($ptr);
        }
        else {
            print STDERR "Could not get SLD file from $sldUrl \n";
            return 0;
        }
    }
    return $cacheSldFile;
}

# Creates customized SLD files in session folder. Customization
# is mostly concerned with min/max thresholds.
sub getSlds {
    my ( $inFileDir, $metaInfo, $layer, $layerOptions ) = @_;
    my $sldList = getSldList( $metaInfo, $layer, $layerOptions );
    die "Can not locate SLDs\n" unless @{$sldList};

    my @sldFileList  = ();
    my $sldMetaInfos = [];
    my $logger       = Giovanni::Logger::Algorithm->new();

    my $cacher = Giovanni::Cache->getCacher(
        TYPE      => "file",
        CACHE_DIR => $GIOVANNI::CACHE_DIR,
        LOGGER    => $logger,
    );
    my $index = 0;    # used for the border of slds and extra slds
    foreach my $sldNode ( @{$sldList} ) {
        my ( $sldUrl, $sldType ) = ();
        if ( defined $layerOptions && $layerOptions->{sld} ) {
            $sldUrl  = $layerOptions->{sld};
            $sldType = '';
        }
        else {
            #if ( $index < $sldCount ) {
            $sldUrl  = $sldNode->{url};
            $sldType = $sldNode->{invert};

            #}
            #else {
            #    $sldUrl  = $sldNode->getAttribute('url');
            #$sldType = $sldNode->getAttribute('type');
            #}
        }
        next unless ( $sldUrl =~ /\S+/ );

        # Create the XML node used in response
        #my $sldName = $index < $sldCount
        #    || $index == 0 ? "variable_sld" : "sld_list";
        my $sldName;
        if ( exists $sldNode->{default} ) {
            $sldName = ( $sldNode->{default} == 0 ) ? "sld" : "variable_sld";
        }
        else {
            $sldName = "variable_sld";
        }
        $index++;

        # if sld is not in cache, then save it into cache
        my ( $sldFileName, $sldPath, $sldSuffix )
            = fileparse( URI->new($sldUrl)->path(), qr/\.\w+$/ );

        my $cacheSldFile
            = checkAndCacheSldFile( $inFileDir, $sldFileName, $cacher,
            $sldUrl );

        my $sldFile = (
              $sldFileName =~ /(\w+)/
            ? $1
            : $$ . '_' . time()
        );
        $sldSuffix = '.xml';
        $sldFile .= $sldSuffix;
        # Somebody else might be still downloading an SLD. Try to lock it first
        my $ptr = Giovanni::Util::lockFile( $cacheSldFile );
        my $sld = Giovanni::OGC::SLD->new( FILE => $cacheSldFile );
        Giovanni::Util::unlockFile($ptr);
        # See if there is user min/max set on the options or nominal min/max
        # set on the DataField info (i.e., from AESIR). If so - put it into
        # SLD file so that it can be picked up by downstream plotting software
        my ( $min, $max );
        if ( defined $layerOptions ) {
            $min = $layerOptions->{min}
                if defined $layerOptions->{min};
            $max = $layerOptions->{max}
                if defined $layerOptions->{max};
        }
        if ( defined $min && defined $max ) {
            $sld->modifyColorMap(
                MIN       => $min,
                MAX       => $max,
                SCALETYPE => $metaInfo->{SCALE_TYPE}
            );
        }
        else {
            my ( $sMin, $sMax ) = $sld->getDataRange();
            if ( !defined($sMin) || !defined($sMax) ) {
                ( $min, $max ) = getMinMax(
                    nominalMin       => $metaInfo->{NOMINAL_MIN},
                    nominalMax       => $metaInfo->{NOMINAL_MAX},
                    unitsConverted   => $metaInfo->{UNIT_CONVERTED},
                    sourceUnits      => $metaInfo->{ORIGINAL_UNITS},
                    destinationUnits => $metaInfo->{UNITS},
                    fileDataRange    => $metaInfo->{FILE_DATA_RANGE},
                    layer            => $layer
                );
                if ( not defined $min and not defined $max ) {
                    print STDERR "Can not find min and max values\n";
                    return 0;
                }
                $sld->setIntData( $metaInfo->{DATA_TYPE} );
                $sld->modifyColorMap(
                    MIN       => $min,
                    MAX       => $max,
                    SCALETYPE => $metaInfo->{SCALE_TYPE},
                );
            }
            else {
                if ( $metaInfo->{UNIT_CONVERTED} ) {
                    my @sRange  = $sld->getThresholds($layer);
                    my @psRange = Giovanni::UnitsConversion::valuesConvert(
                        config           => $GIOVANNI::UNITS_CFG,
                        sourceUnits      => $metaInfo->{ORIGINAL_UNITS},
                        destinationUnits => $metaInfo->{UNITS},
                        "values"         => \@sRange
                    );
                    $sld->setThresholds( @psRange, $layer );
                }
                if ( not defined $min || not defined $max ) {
                    ( $min, $max ) = ( $sMin, $sMax );
                }
            }
        }

        # Set units
        $sld->setUnit( $metaInfo->{UNITS} );

        # Form SLD node metadata for client response
        my $sldMetaInfo  = {};
        my $uniqueString = $$ . '_' . time();
        my $layerSldFile
            = defined $layerOptions && defined $layerOptions->{sld}
            ? $inFileDir . "/" . $sldFileName . $sldSuffix
            : "$inFileDir/$layer" . "_$uniqueString$sldFile";
        push( @sldFileList, $layerSldFile );

        my $origSldName = $sld->getLayerName();
        my @sldRange = defined $sld ? $sld->getDataRange() : ();
        $sldMetaInfo->{min}     = $sldRange[0];
        $sldMetaInfo->{max}     = $sldRange[1];
        $sldMetaInfo->{type}    = $sldType;
        $sldMetaInfo->{label}   = $sld->getUserStyleName();
        $sldMetaInfo->{name}    = join( '_', $layer, $origSldName );
        $sldMetaInfo->{sldName} = $sldName;

        Giovanni::Util::writeFile( $layerSldFile, $sld->toString() );
        $sldMetaInfo->{url}
            = Giovanni::Util::convertFilePathToUrl( $layerSldFile,
            \%GIOVANNI::URL_LOOKUP );

        # Form the thumbnail of the SLD for use in color map selectors
        my $thumbnailFile
            = $inFileDir . '/'
            . $layer . "_"
            . ( $sldFile =~ /(\w+)/ ? $1 : $$ . '_' . time() ) . '.png';
        if ( $sld->createThumbnail( FILE => $thumbnailFile ) ) {
            my $thumbnailUrl
                = ( -f $thumbnailFile )
                ? Giovanni::Util::convertFilePathToUrl( $thumbnailFile,
                \%GIOVANNI::URL_LOOKUP )
                : undef;
            $sldMetaInfo->{thumbnail} = $thumbnailUrl
                if defined $thumbnailUrl;
        }
        push( @{$sldMetaInfos}, $sldMetaInfo );
    }
    return \@sldFileList, $sldMetaInfos;
}

# Returns default SLD for a given variable (aka layer)
sub getDefaultSld {
    my ( $inFileDir, $layer, $sldList ) = @_;
    my $defaultSldLabel = %GIOVANNI::DEFAULT_SLD;
    warn
        "WARNING Default SLD is not set in the config - please specify DEFAULT_SLD"
        unless defined $defaultSldLabel;
    my $dataField = getDataField( $inFileDir, $layer );
    my $slds = defined $dataField ? $dataField->get_slds() : undef;
    $defaultSldLabel = ${$slds}[0]->{label} if defined $slds && @{$slds} > 0;

    my %sldMap = map { $_->{label} => $_ } @{$sldList};
    my $defaultSld = $sldMap{$defaultSldLabel};
    return $defaultSld;
}

# Mostly used by static plots to setup SLDs on a first render
# Creates SLD files in a session folder based on a supplied variable (aka layer)
# Once created, adds available SLDs to plot options schema
sub checkAndSetupStaticPlotSLDs {
    my ( $inFile, $plotType, $optionsParser, $layer, $palettesPathInOptions,
        $layerOptions )
        = @_;
    $palettesPathInOptions = 'properties/Palette/enum'
        unless defined $palettesPathInOptions;
    $optionsParser->loadSchema( $plotType, $layer );
    my $currentPalettes
        = $optionsParser->getSchemaParameter( $plotType, $layer,
        $palettesPathInOptions );

    # Do not setup SLDs if already setup and written to schema
    return $currentPalettes
        unless !( defined $currentPalettes ) || @{$currentPalettes} < 2;

# Collect and compute metadata for SLD generation and what not. For SLD, we mostly care about
# the following params (can be hard-coded, skipping collectMetadata alltogether)
#    $metaComplete = {
#      SLDS => [],
#      UNITS => '',
#      FILE_DATA_RANGE => ['0', '1.0'],
#      UNIT_CONVERTED => 0,
#      ORIGINAL_UNITS => 'fraction',
#      DATA_TYPE => 0,
#      SCALE_TYPE => 'linear'
#    };

    # Collect metadata to determine min/max and units
    my $metaInfo = collectMetadata( $inFile, $layer, undef, undef );

    # Make SLDs
    my ( $sldFileList, $sldMetaInfos )
        = getSlds( dirname($inFile), $metaInfo, $layer, $layerOptions );

    # Convert SLD setup output items into JSON schema items
    my $sldSchemaEnums = [
        map {
            {   label    => $_->{label},
                legend   => $_->{thumbnail},
                sld      => $_->{url},
                inverted => $_->{type}
            }
        } @{$sldMetaInfos}
    ];
    foreach my $sldItem (@$sldSchemaEnums) {
        delete $sldItem->{inverted} unless defined $sldItem->{inverted};
    }

    # Update schema with the newly generated SLDs
    $optionsParser->setSchemaParameter( $plotType, $layer, $sldSchemaEnums,
        $palettesPathInOptions );
    $optionsParser->saveSchemas( $plotType, $layer )
        ;    # Save to disk for later reuse
    return $sldSchemaEnums;
}

#################################################################################
# Metadata - used by maps and Hovmoller
#################################################################################

# Gets some extra metadata from data field manifest file if any
sub getDataField {
    my ( $inFileDir, $layer ) = @_;
    my $varInfoFile
        = $inFileDir . '/mfst.data_field_info+d' . $layer . '.xml';
    my $defaultVarInfoFile = $inFileDir . '/varInfo.xml';
    $varInfoFile = $defaultVarInfoFile if -f $defaultVarInfoFile;
    if ( -f $varInfoFile ) {
        return Giovanni::DataField->new( MANIFEST => $varInfoFile );
    }
    return undef;
}

# Computes a few extra metadata params and adds them to the supplied metadata hash
sub getExtraMetaInfo {
    my ( $inFile, $layer, $layerType, $varInfo, $attrInfo, $metaInfo,
        $layerOptions )
        = @_;
    my $extraMetaInfo = {};

    # set data file type
    $extraMetaInfo->{DATA_TYPE}
        = Giovanni::Util::getNetcdfDataType( $inFile, $layer );

    # set the title
    my ( $title, $subtitle, $caption )
        = getPlotTitleSubtitleCaption( $inFile, $layer );
    $extraMetaInfo->{TITLE}    = $title    if defined $title;
    $extraMetaInfo->{SUBTITLE} = $subtitle if defined $subtitle;
    $extraMetaInfo->{CAPTION}  = $caption  if defined $caption;

# NOTE: Ripped this mysterious condition out of the SLD block in the original code.
# Probably makes more sense without it - M.P.
    if ( !( defined $layerOptions && defined $layerOptions->{sld} ) ) {
        $extraMetaInfo->{TITLE} = $metaInfo->{LONG_NAME}
            if $extraMetaInfo->{TITLE} eq "";
    }

    #replace NCL control character for new line
    $extraMetaInfo->{TITLE} =~ s/~C~/ /g;
    $extraMetaInfo->{WMS_TITLE} = $extraMetaInfo->{TITLE};
    $extraMetaInfo->{WMS_TITLE} =~ s/\s*for.+//;
    $extraMetaInfo->{TITLE}
        = $extraMetaInfo->{TITLE} . "\n" . $extraMetaInfo->{SUBTITLE};

    # Need unit conversion or not
    $extraMetaInfo->{UNIT_CONVERTED} = 0;
    my $cUnit = $metaInfo->{ORIGINAL_UNITS};
    my $pUnit = $metaInfo->{UNITS};
    if ( defined $cUnit && defined $pUnit ) {
        if ( $cUnit ne "" && $cUnit ne "1" && $cUnit ne "unknown" ) {
            $extraMetaInfo->{UNIT_CONVERTED} = $cUnit eq $pUnit ? 0 : 1;
        }
    }

    # Get scale type
    my $scaleType = $metaInfo->{VALUES_DISTRIBUTION};
    $scaleType = $layerOptions->{scale} if defined $layerOptions;
    $scaleType = "linear" if not defined $scaleType;
    $extraMetaInfo->{SCALE_TYPE} = $scaleType;

    # Determine max resolution
    if ( defined $layerType && $layerType eq "vector" ) {
        my $dataResolution = $metaInfo->{SPATIAL_RESOLUTION};
        $dataResolution =~ s/\s*deg.\s*//;
        ( my $xRes, my $yRes ) = split( /x/, $dataResolution );
        if ( defined $xRes and defined $yRes ) {
            my $maxRes = $xRes > $yRes ? $xRes : $yRes;
            $maxRes = sprintf( "%.5f", $maxRes / 16 );
            $extraMetaInfo->{MAX_RES} = $maxRes;
        }
    }

    # Get data value range
    my @fileDataRange = Giovanni::Util::getNetcdfDataRange( $inFile, $layer );

    # Validate file data range to satisfy Perl taint checking
    foreach my $number (@fileDataRange) {
        if ( Scalar::Util::looks_like_number($number) ) {
            $number = $1 if ( $number =~ /(.+)/ );
        }
        else {
            $number = undef;
        }
    }
    $extraMetaInfo->{FILE_DATA_RANGE} = \@fileDataRange;

    return $extraMetaInfo;
}

# Used in layer metadata checks:
#   $layerMetadata->{layerType} (e.g., "vector")
#   $layerOptions->{sld} (who knows why) and $layerOptions->{scale}
sub collectMetadata {
    my ( $inFile, $layer, $layerType, $layerOptions ) = @_;
    my $inFileDir          = dirname($inFile);
    my $inputXmlFile       = $inFileDir . '/input.xml';
    my $defaultVarInfoFile = $inFileDir . '/varInfo.xml';

    my %attrInfo = Giovanni::Util::getNetcdfGlobalAttributes($inFile);
    my %varInfo  = Giovanni::Util::getNetcdfDataVariables($inFile);

    my $varInfoFile
        = ( -f $defaultVarInfoFile )
        ? $defaultVarInfoFile
        : $inFileDir . '/mfst.data_field_info+d' . $layer . '.xml';
    $varInfoFile = undef unless -f $varInfoFile;

    my %metaInfo = Giovanni::Map::Info::gatherVariableInfo(
        INPUT           => $inputXmlFile,
        DATA_FIELD_INFO => $varInfoFile,
        DATA            => $inFile,
    );
    my %extraMetaInfo = %{
        getExtraMetaInfo(
            $inFile,    $layer,     $layerType, \%varInfo,
            \%attrInfo, \%metaInfo, $layerOptions
        )
    };

    return { %metaInfo, %extraMetaInfo };
}

# Figure out the min/max from the data or the nominal min/max. Convert units
# of nominal min/max if necessary.
sub getMinMax {
    my (%params) = @_;

    # units conversion needed
    my $unitsConverted = $params{unitsConverted};

    # units in data file
    my $sourceUnits = $params{sourceUnits};

    # units user requested
    my $destinationUnits = $params{destinationUnits};

    # range in the file
    my $fileDataRange = $params{fileDataRange};

    # layer name
    my $layer = $params{layer};

    if ( $layer eq 'time_matched_difference' ) {

       # Time matched difference gets a zero-centered range based on the data.
       # Nominal min/max is irrelevant.
        my $val
            = abs( $fileDataRange->[0] ) > abs( $fileDataRange->[1] )
            ? abs( $fileDataRange->[0] )
            : abs( $fileDataRange->[1] );
        return ( -$val, $val );
    }
    my $nominalMin = $params{nominalMin};
    if ( defined($nominalMin) ) {
        if ($unitsConverted) {
            my %convertResult = Giovanni::UnitsConversion::valuesConvert(
                config           => $GIOVANNI::UNITS_CFG,
                sourceUnits      => $sourceUnits,
                destinationUnits => $destinationUnits,
                "values"         => [$nominalMin],
            );
            if ( $convertResult{"success"} ) {
                $nominalMin = $convertResult{"values"}->[0];
            }
        }

    }
    my $nominalMax = $params{nominalMax};
    if ( defined($nominalMax) ) {
        if ($unitsConverted) {
            my %convertResult = Giovanni::UnitsConversion::valuesConvert(
                config           => $GIOVANNI::UNITS_CFG,
                sourceUnits      => $sourceUnits,
                destinationUnits => $destinationUnits,
                "values"         => [$nominalMax],
            );
            if ( $convertResult{"success"} ) {
                $nominalMax = $convertResult{"values"}->[0];
            }
        }
    }
    my ( $min, $max ) = Giovanni::Util::getColorbarMinMax(
        DATA_MIN    => $fileDataRange->[0],
        DATA_MAX    => $fileDataRange->[1],
        NOMINAL_MIN => $nominalMin,
        NOMINAL_MAX => $nominalMax
    );

    return ( $min, $max );
}

# Returns title, subtitle, and caption based on the info in the file
sub getPlotTitleSubtitleCaption {
    my ( $inFile, $layer ) = @_;
    my ( $title, $subtitle, $caption );
    my %varInfo  = Giovanni::Util::getNetcdfDataVariables($inFile);
    my %attrInfo = Giovanni::Util::getNetcdfGlobalAttributes($inFile);
    if ( defined $layer && defined $varInfo{$layer}{plot_hint_title} ) {
        $title    = $varInfo{$layer}{plot_hint_title};
        $subtitle = $varInfo{$layer}{plot_hint_subtitle}
            if defined $varInfo{$layer}{plot_hint_subtitle};
    }
    elsif ( defined $attrInfo{plot_hint_title} ) {
        $title    = $attrInfo{plot_hint_title};
        $subtitle = $attrInfo{plot_hint_subtitle}
            if defined $attrInfo{plot_hint_subtitle};
    }
    elsif ( defined $layer && defined $varInfo{$layer}{title} ) {
        $title = $varInfo{$layer}{title};
        if ( defined $varInfo{$layer}{time} ) {

            my $t = DateTime->from_epoch( epoch => $varInfo{$layer}{time} );
            my $timeStr = $t->iso8601();
            $subtitle = $timeStr if defined $timeStr;
        }
    }
    $caption = $attrInfo{plot_hint_caption};
    return ( $title, $subtitle, $caption );
}

# Computes a title for the 'alt' image tag on the GUI
sub getPlotAltTitle {
    my ( $plotType, $inFile, $layer, $title, $subtitle ) = @_;

    # Set default title
    my $defaultAltTitle = "Giovanni image";

    # Get title / subtitle from the file unless provided with the call
    if ( !( defined $title || defined $subtitle ) ) {
        ( $title, $subtitle, undef )
            = getPlotTitleSubtitleCaption( $inFile, $layer );
    }

    # Compute title for the alt tag
    my $fullTitle = ( defined $title ? $title : "" ) . " "
        . ( defined $subtitle ? $subtitle : "" );
    $fullTitle =~ s/^\s+|\s+$//g;

    # Replace with default title if we eneded up with an empty string
    $fullTitle = $defaultAltTitle unless $fullTitle ne "";
    return $fullTitle;
}

#################################################################################
# Image file operations
#################################################################################

sub convertImages {
    my ( $imgListRef, %options ) = @_;
    my $outImgRef = {};
    my $format    = exists $options{format} ? $options{format} : 'png';
    my $optStr    = '';
    foreach my $key ( keys %options ) {
        next if ( $key eq 'format' );
        $optStr .= " -$key $options{$key}";
    }
    foreach my $srcImg ( @{$imgListRef} ) {
        my ( $srcFile, $srcDir, $srcSuffix )
            = fileparse( $srcImg, qr/\.\w+$/ );
        my $tarImg = $srcDir . '/' . $srcFile . '.' . $format;
        my $cmdOut = `convert $optStr $srcImg $tarImg`;
        if ($?) {
        }
        else {
            $outImgRef->{$srcImg} = $tarImg;
        }
    }
    return $outImgRef;
}

# Does not seem to be used anymore
sub createSVG {
    my ( $title, $subTitle, $caption, $frame, $legend ) = @_;

    my @titleLines    = split( /[\r\n]+/, $title );
    my @subTitleLines = split( /[\r\n]+/, $subTitle );

    #  my $title1 = substr($title, 0, rindex($title, ',')+1);
    #  my $title2 = substr($title, rindex($title, ',')+1);
    my $svgFileName = $frame . '.svg';

    my $yOffset = 15;

    my $imageWidth  = 0;
    my $imageHeight = 0;
    my $cmd         = 'identify -format "%wx%h" ' . $frame;
    my $output      = `$cmd`;
    if ($?) {
        $imageWidth  = 1024;
        $imageHeight = 512;
    }
    else {
        my @dims = split( 'x', $output );
        $imageWidth  = int( $dims[0] );
        $imageHeight = int( $dims[1] );
    }
    my $legendWidth = 50;

    my $xmlStr
        = '<?xml version="1.0" standalone="no"?>'
        . '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
        . '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny" xmlns:xlink="http://www.w3.org/1999/xlink">';
    my $centerPt = ( $imageWidth + $legendWidth ) / 2;
    for ( my $i = 0; $i < @titleLines; $i++ ) {
        $xmlStr
            .= '<text x="'
            . $centerPt . '" y="'
            . $yOffset
            . '" font-size="12" font-weight="'
            . ( $i == 0 ? 'bold' : 'normal' )
            . '" style="text-anchor: middle">'
            . $titleLines[$i]
            . '</text>';
        $yOffset += 15;
    }

    for ( my $i = 0; $i < @subTitleLines; $i++ ) {
        $xmlStr
            .= '<text x="'
            . $centerPt . '" y="'
            . $yOffset
            . '" font-size="12" font-weight="normal" style="text-anchor: middle">'
            . $subTitleLines[$i]
            . '</text>';
        $yOffset += 15;
    }
    $xmlStr
        .= '<image x="0" y="'
        . $yOffset
        . '" width="'
        . $imageWidth
        . '" height="'
        . $imageHeight
        . '" xlink:href="'
        . $frame . '" />'
        . '<image x="'
        . $imageWidth . '" y="'
        . $yOffset
        . '" width="'
        . $legendWidth
        . '" height="'
        . $imageHeight
        . '" xlink:href="'
        . $legend . '" />';
    $yOffset += $imageHeight;

    if ( defined $caption ) {
        my $lineWidth = $imageWidth
            * 0.2;    ### scale value calculated based on font size ###
        for ( my $ind = 0; $ind < length($caption); $ind++ ) {
            my $captionLine = substr( $caption, $ind, $lineWidth );
            if ( length($captionLine) == $lineWidth
                && substr( $captionLine, -1 ) ne ' ' )
            {
                $captionLine = substr( $captionLine, 0,
                    rindex( $captionLine, ' ' ) + 1 );
            }
            elsif ( $captionLine eq '' ) {
                last;
            }
            $yOffset += 15;
            $xmlStr
                .= '<text x="0" y="'
                . $yOffset
                . '" width="'
                . $imageWidth . '">'
                . $captionLine
                . '</text>';
            $ind += length($captionLine) - 1;
        }
    }
    $xmlStr .= '</svg>';

    open( SVGFILE, '>' . $svgFileName );
    print SVGFILE $xmlStr;
    close(SVGFILE);

    return $svgFileName;
}

#################################################################################
#################################################################################
#################################################################################

1;
