package Giovanni::Visualizer::Drivers::Hovmollers;

use strict;
use warnings;
use File::Basename;
use Giovanni::DataField;
use Giovanni::Plot;
use Giovanni::Util;
use Giovanni::Visualizer::VisUtil;
use Giovanni::Visualizer::Hovmoller;

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

Giovanni::Visualizer::Drivers::Hovmollers - visualize Hovmoller family of plots

=head1 SYNOPSIS

use Giovanni::Visualizer::Drivers::Hovmollers;

$driver = new Giovanni::Visualizer::Drivers::Hovmollers();

my $params = {};

my $resultItems = $driver->visualize(params);

=head1 DESCRIPTION

Visualizes Hovmoller family of plots

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
    my $outDir    = $visualizerParams->{outDir};
    my $inFileDir = $outDir
        ; # set in dir to out dir since no other plot makes a distinction anyway
    my $result = { items => [] };

    my $width  = 600;
    my $height = 500;
    my $dim    = ();
    my $min    = ();
    my $max    = ();

    foreach my $inFile ( keys %{ $visualizerParams->{dataFiles} } ) {
        my $sldStr  = undef;
        my %varInfo = Giovanni::Util::getNetcdfDataVariables($inFile);
        my %varFlag = ();

        # Determine layers to visualize (either from input items
        # if specified, or all available layers otherwise)
        my $inputItems = $visualizerParams->{dataFiles}{$inFile};
        my $layers     = Giovanni::Visualizer::VisUtil::getVisualizationKeys(
            $inputItems);
        $layers = [ keys %varInfo ] unless @{$layers};

        # Define output file directory
        my $png_file = "$outDir/" . basename($inFile) . '_' . time() . '.png';

        foreach my $layer ( sort @{$layers} ) {

            # Retrieve plot options for a given key (layer, in this case)
            my $plotOptions
                = Giovanni::Visualizer::VisUtil::getVisualizationOptionsByKey(
                $inputItems, $layer );

            # Find the title and subtitle from plot hint
            my ( $title, $subtitle, $caption )
                = Giovanni::Visualizer::VisUtil::getPlotTitleSubtitleCaption(
                $inFile, $layer );

            # Find SLD and update min and max values
            my ( $min, $max );
            if (   defined $plotOptions->{Data}
                && defined $plotOptions->{Data}{Range} )
            {
                $min = $plotOptions->{Data}{Range}{Min}
                    if defined $plotOptions->{Data}{Range}{Min};
                $max = $plotOptions->{Data}{Range}{Max}
                    if defined $plotOptions->{Data}{Range}{Max};
            }

            # Find title
            my $defaultVarInfoFile = $inFileDir . '/varInfo.xml';
            my $varInfoFile
                = ( -f $defaultVarInfoFile )
                ? $defaultVarInfoFile
                : $inFileDir . '/mfst.data_field_info+d' . $layer . '.xml';
            if ( -f $varInfoFile ) {
                my $xmlParser = XML::LibXML->new();
                my $dom       = $xmlParser->parse_file($varInfoFile);
                my $doc       = $dom->documentElement();
                ($title)
                    = $doc->findvalue(
                    '//var[@id="' . $layer . '"]/@long_name' )
                    if $title eq "";
            }

            my $dataType
                = Giovanni::Util::getNetcdfDataType( $inFile, $layer );

            # Setup SLDs and retrive SLD metadata
            my $palettes
                = Giovanni::Visualizer::VisUtil::checkAndSetupStaticPlotSLDs(
                $inFile,
                $visualizerParams->{plotType},
                $visualizerParams->{optionsParser},
                $layer, 'properties/Palette/enum'
                );

            # Get default SLD entry if not specified on the options already
            $plotOptions->{Palette}
                = Giovanni::Visualizer::VisUtil::getDefaultSld( $outDir,
                $layer, $palettes )
                unless exists $plotOptions->{Palette};

            my $sldUrl = $plotOptions->{Palette}{sld};
            my ( $sldFile, $sldPath, $sldSuffix )
                = fileparse( URI->new($sldUrl)->path(), qr/\.\w+$/ );
            $sldFile = ( $sldFile =~ /(\w+)/ ? $1 : $$ . '_' . time() );
            $sldSuffix = '.xml';
            $sldFile .= $sldSuffix;

            # Create legend
            my $sld = Giovanni::OGC::SLD->new( URL => $sldUrl );
            $sld->setLayerName($layer);
            $sld->setIntData( $dataType, $layer );

# Could not find any inverted colormap - need to verify if we have one - Maksym
            if ( defined $plotOptions->{Palette}{inverted}
                and ( lc( $plotOptions->{Palette}{inverted} ) eq 'true' ) )
            {
                my $label = $sld->getUserStyleName();
                $sld->setUserStyleName("Inverted $label");
                $sld->invertPalette();
            }

# Setup scale depending on the current min/max.
# This looks copied from interactive maps, but maps have since diverged - M.P.
            if ( defined $min && defined $max ) {
                $sld->modifyColorMap(
                    MIN => $min,
                    MAX => $max
                );
            }
            else {
                my ( $sMin, $sMax ) = $sld->getDataRange();
                if (   !( defined $sMin )
                    || !( defined $sMax )
                    || $sMin eq ''
                    || $sMax eq '' )
                {
                    my $dataField = Giovanni::DataField->new(
                        MANIFEST => $varInfoFile );

                    my @fileDataRange
                        = Giovanni::Util::getNetcdfDataRange( $inFile,
                        $layer );
                    ( $min, $max ) = Giovanni::Util::getColorbarMinMax(
                        DATA_MIN    => $fileDataRange[0],
                        DATA_MAX    => $fileDataRange[1],
                        NOMINAL_MIN => $dataField->get_nominalMin(),
                        NOMINAL_MAX => $dataField->get_nominalMax()
                    );

                    $sld->modifyColorMap(
                        MIN => $min,
                        MAX => $max,
                    );
                }
                else {
                    ( $min, $max ) = ( $sMin, $sMax );
                }
            }

            my $uniqueString = $$ . '_' . time();
            my $layerSldFile
                = $inFileDir . "/"
                . $layer . "_"
                . $uniqueString . "_"
                . $sldFile;
            Giovanni::Util::writeFile( $layerSldFile, $sld->toString() );

            # Generate legend image
            my $legendImage = $layerSldFile . "_legend.png";
            my %options     = (
                type   => $dataType,
                height => 400,
                width  => 75,
                units  => undef,
                scale  => $sld->{layers}{$layer}{legendScale},
                file   => $legendImage
            );
            my $ss = $sld->createColorLegend(%options);
            die "Not able to create legend" if ( $ss == 0 );

            # Create a data image
            my $imgFile   = $inFile . "_" . $layer . ".png";
            my $worldFile = $inFile . "_" . $layer . ".wld";
            my $tmpOutput = File::Temp->new(
               TEMPLATE => 'tempXXXX',
               DIR      => $ENV{TMPDIR},
               SUFFIX   => '.png'
            );

            # Runs gradsMap passing variables to the function Note: $dim
            # is either lat or lon and needs to be inserted into tmp
            # NetCDF file so GrADS can read it
            my ( $dim, $longName, $standardName, $axis, $dir );
            if ( $visualizerParams->{plotType} eq 'HOV_LON' ) {
                $dim          = 'lat';
                $longName     = 'Latitude';
                $standardName = 'latitude';
                $axis         = 'Lat';
                $dir          = 'north';
            }
            elsif ( $visualizerParams->{plotType} eq 'HOV_LAT' ) {
                $dim          = 'lon';
                $longName     = 'Longitude';
                $standardName = 'longitude';
                $axis         = 'Lon';
                $dir          = 'east';
            }
            else {
                die "Error reading dimension: dimension is not lat or lon";
            }
            my ($hovPlot) = Giovanni::Visualizer::Hovmoller::gradsMap(
                $inFile,
                $layerSldFile,
                (   OUTFILE   => $tmpOutput,
                    SMOOTH    => 0,
                    WIDTH     => $width,
                    HEIGHT    => $height,
                    DIMENSION => $dim,
                    LNAME     => $longName,
                    SNAME     => $standardName,
                    AXIS      => $axis,
                    DIR       => $dir,
                )
            );

         # Combine colorbar legend with GrADS Plot image
            my $plot = Giovanni::Plot->new();
            $plot->addImage( $tmpOutput, $legendImage )
                if ( defined $tmpOutput );
            my $outFile = $plot->renderPNG();

            # Convert file path to URL and plot image and caption
            my $flag = rename( $outFile, $png_file )
                if ( -f $outFile );
            if ($flag) {
                my $png_url
                    = Giovanni::Util::convertFilePathToUrl( $png_file,
                    \%GIOVANNI::URL_LOOKUP );
                warn "INFO wrote PNG file $png_file (path=$tmpOutput)\n";
                my $altTitle
                    = Giovanni::Visualizer::VisUtil::getPlotAltTitle(
                    $visualizerParams->{plotType},
                    $inFile, $layer, $title, $subtitle );

                # Form output item
                my $outputPlotOptions = {
                    Data => {
                        Range => {
                            Min => $min,
                            Max => $max
                        },
                        Label => $layer
                    },
                    Palette => $plotOptions->{Palette}
                };
                my $resultItem = {
                    datafile    => $inFile,
                    imageUrl    => $png_url,
                    plotOptions => keys %{$outputPlotOptions}
                    ? $outputPlotOptions
                    : undef,
                    caption => $caption,
                    key     => $layer,
                    title   => $altTitle
                };

                push( @{ $result->{items} }, $resultItem );
            }
            else {
                die "Failed to create Hovmoller image file";
            }

        }
    }
    return $result;
}

1;
