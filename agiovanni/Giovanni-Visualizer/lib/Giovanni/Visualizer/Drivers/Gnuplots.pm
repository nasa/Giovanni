package Giovanni::Visualizer::Drivers::Gnuplots;

use strict;
use warnings;
use File::Basename;
use JSON;
use List::Util qw[min max];
use Giovanni::Visualizer::VisUtil;
use Giovanni::Visualizer::Gnuplot;
use Giovanni::Util;

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

Giovanni::Visualizer::Drivers::Gnuplots - visualize Gnuplot family of plots

=head1 SYNOPSIS

use Giovanni::Visualizer::Drivers::Gnuplots;

$driver = new Giovanni::Visualizer::Drivers::Gnuplots();

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

# Find quantity min/max for all files
# my %qtyMinMax = Giovanni::Util::getQuantityTypeMinMax(keys %{$visualizerParams->{dataFiles}});

    foreach my $inFile ( keys %{ $visualizerParams->{dataFiles} } ) {

        # Get input item info (we expect to have only one layer to be
        # visualized per file, although this can be changed into a loop)
        my $inputItem   = ${ $visualizerParams->{dataFiles}{$inFile} }[0];
        my $plotOptions = $inputItem->{plotOptions};
        my $png_file = "$outDir/" . basename($inFile) . '_' . time() . '.png';
        my $plot     = new Giovanni::Visualizer::Gnuplot(
            DATA_FILE => $inFile,
            PLOT_FILE => $png_file,
            PLOT_TYPE => $visualizerParams->{plotType},
            SKIP_TITLE => 1,
        );

        # Get plottable variable name and its quantity type
        my $varName = $plot->plottable_variable();
        my $qtyType = $plot->quantity_type();
        my $varNameRef;
        my $qtyTypeRef;
        my @varDataRange
            = Giovanni::Util::getNetcdfDataRange( $inFile, $varName );
        my @varRefDataRange;
        my $xyAreTheSameKind = 1 == 0;

        if ( $visualizerParams->{plotType} eq 'SCATTER_PLOT_GNU' ) {
            $varNameRef = $plot->plottable_variable_ref();
            $qtyTypeRef = $plot->quantity_type_ref();
            @varRefDataRange
                = Giovanni::Util::getNetcdfDataRange( $inFile, $varNameRef )
                unless !( defined $varNameRef );
            $xyAreTheSameKind
                = defined $varNameRef
                && defined $qtyTypeRef
                && defined $qtyType
                && $qtyTypeRef eq $qtyType;
        }

        # If user options exist, use them
        $plot->areaStats( $plotOptions->{"Display area statistics"} )
            if exists $plotOptions->{"Display area statistics"};
        $plot->fitLine( $plotOptions->{"Fit a line"} )
            if exists $plotOptions->{"Fit a line"};

        my $optYMin
            = Giovanni::Util::getHashPath( $plotOptions, "Y Axis/Range/Min" );
        my $optYMax
            = Giovanni::Util::getHashPath( $plotOptions, "Y Axis/Range/Max" );
        my $optXMin
            = Giovanni::Util::getHashPath( $plotOptions, "X Axis/Range/Min" );
        my $optXMax
            = Giovanni::Util::getHashPath( $plotOptions, "X Axis/Range/Max" );

        # If user requested area statistics - ignore min / max
        # (do not pass min / max to the plot software)
        if ( !( defined $plot->areaStats() && $plot->areaStats() ) ) {

         # Set Y axis min/max to the same min/max as the Y axis if the X and Y
         # are of the same kind and the user have not provided min/max already
            $optYMin = min( $varDataRange[0], $varRefDataRange[0] )
                if !defined($optYMin) && $xyAreTheSameKind;
            $optYMax = max( $varDataRange[1], $varRefDataRange[1] )
                if !defined($optYMax) && $xyAreTheSameKind;

            # Tell the plot of our min and max
            $plot->ymin($optYMin) if defined $optYMin;
            $plot->ymax($optYMax) if defined $optYMax;
        }

        if ( defined $varNameRef ) {

         # Set X axis min/max to the same min/max as the Y axis if the X and Y
         # are of the same kind and the user have not provided min/max already
            $optXMin = min( $varDataRange[0], $varRefDataRange[0] )
                if !defined($optXMin) && $xyAreTheSameKind;
            $optXMax = max( $varDataRange[1], $varRefDataRange[1] )
                if !defined($optXMax) && $xyAreTheSameKind;

            # Tell the plot of our min and max
            $plot->xmin($optXMin) if defined $optXMin;
            $plot->xmax($optXMax) if defined $optXMax;
        }

        my @png_paths = $plot->draw();
        my @urls;
        my $failedToRenameFiles = 0;
        my $img_idx             = 0;
        for my $png_path (@png_paths) {

            # TODO Do we want to keep min/max/count on the image filename?
            my $png_file
                = "$outDir/"
                . basename($inFile) . '_'
                . ( ( $img_idx == 0 ) ? '' : "${img_idx}_" )
                . time() . '.png';

            # Need to use unique file names to avoid browser caching
            my $flag = rename( $png_path, $png_file )
                if ( -f $png_path );
            if ($flag) {
                my $png_url = Giovanni::Util::convertFilePathToUrl( $png_file,
                    \%GIOVANNI::URL_LOOKUP );
                warn "INFO wrote PNG file $png_file (path=$png_path)\n";
                push @urls, $png_url;
            }
            else {

                # TODO: Do we want to fail if any single
                # rename fails or if all fail?
                $failedToRenameFiles = 1;
                last;
            }
            $img_idx++;
        }

        if ( !$failedToRenameFiles ) {

            # Get back the plot options used
            my ( $ymin, $ymax, $fitLine, $areaStats ) = (
                $plot->ymin(),    $plot->ymax(),
                $plot->fitLine(), $plot->areaStats()
            );
            my ( $xmin, $xmax ) = ( $plot->xmin(), $plot->xmax() );

            # If user requested area stats - we did not pass min / max to the
            # plot software. But we still need to pass these min / max back to
            # the GUI to make the whole process transparent to the user, so
            # let's restore user min / max if any
            if (   defined $plot->areaStats()
                && $plot->areaStats()
                && exists $plotOptions->{"Y Axis"}
                && exists $plotOptions->{"Y Axis"}{"Range"} )
            {
                $ymin = $plotOptions->{"Y Axis"}{"Range"}{"Min"}
                    if exists $plotOptions->{"Y Axis"}{"Range"}{"Min"};
                $ymax = $plotOptions->{"Y Axis"}{"Range"}{"Max"}
                    if exists $plotOptions->{"Y Axis"}{"Range"}{"Max"};
            }

            $ymin      = $varDataRange[0] unless defined $ymin;
            $ymax      = $varDataRange[1] unless defined $ymax;
            $fitLine   = 'false'          unless defined $fitLine;
            $areaStats = 'false'          unless defined $areaStats;

            $xmin = $varRefDataRange[0]
                unless !( defined $varNameRef ) || defined $xmin;
            $xmax = $varRefDataRange[1]
                unless !( defined $varNameRef ) || defined $xmax;

            # Set plot options to be used while serializing result
            my %inFileGlobalAttr
                = Giovanni::Util::getNetcdfGlobalAttributes($inFile);
            my $label
                = ( $inFileGlobalAttr{plot_hint_title} =~ /[^,]+,\s*(.+)/ )
                ? $1
                : $qtyType;
            my $labelRef
                = ( $inFileGlobalAttr{plot_hint_title} =~ /[^,]+,\s*(.+)/ )
                ? $1
                : $qtyTypeRef

                if defined $qtyTypeRef;

            if ( $visualizerParams->{plotType} eq 'SCATTER_PLOT_GNU' ) {
                $label    = 'Y: ' . $varName;
                $labelRef = 'X: ' . $varNameRef;
            }

            #Save options to the hash, but...
            #... supress output of plot options for vertical profile plots
            my $outputPlotOptions = {};
            if (index( $visualizerParams->{plotType}, "VERTICAL_PROFILE" )
                == -1 )
            {
                $outputPlotOptions->{"Y Axis"} = {
                    Range => {
                        Min => sprintf( "%g", $ymin ),
                        Max => sprintf( "%g", $ymax )
                    },
                    Label => $label
                };

                $outputPlotOptions->{"X Axis"} = {
                    Range => {
                        Min => sprintf( "%g", $xmin ),
                        Max => sprintf( "%g", $xmax )
                    },
                    Label => $labelRef
                    }
                    if defined $varNameRef;
            }

            if ( index( $visualizerParams->{plotType}, "TIME_SERIES" ) != -1 )
            {
                $outputPlotOptions->{'Fit a line'}
                    = decode_json( '{"dummy":' . $fitLine . '}' )->{dummy};

               # Display area stats option only if there are stats in the file
                if ( $plot->hasYVarStats() ) {
                    $outputPlotOptions->{'Display area statistics'}
                        = decode_json( '{"dummy":' . $areaStats . '}' )
                        ->{dummy};
                }
                else {

# Remove 'Display area statistics' from the schema so that GUI does not display it
                    eval {
                        my $optionsParser
                            = $visualizerParams->{optionsParser};
                        $optionsParser->loadSchema(
                            $visualizerParams->{plotType}, $varName );
                        $optionsParser->removeSchemaParameter(
                            $visualizerParams->{plotType},
                            $varName, "properties/Display area statistics" );
                        $optionsParser->saveSchemas(
                            $visualizerParams->{plotType}, $varName )
                            ;    # Save to disk for later reuse
                    };
                }
            }

            # Compute alt image title
            my $altTitle
                = Giovanni::Visualizer::VisUtil::getPlotAltTitle(
                $visualizerParams->{plotType},
                $inFile, $varName );

            # Set output items
            for my $png_url (@urls) {
                my $resultItem = {
                    datafile    => $inFile,
                    imageUrl    => $png_url,
                    plotOptions => !%$outputPlotOptions
                    ? {}
                    : $outputPlotOptions,
                    caption => $inFileGlobalAttr{plot_hint_caption},
                    key     => $varName,
                    title   => $altTitle
                };
                push( @{ $result->{items} }, $resultItem );
            }
        }
    }
    return $result;
}

1;
