package Giovanni::Visualizer::Drivers::StaticPlots;

use strict;
use warnings;
use File::Basename;
use List::MoreUtils qw/ any /;
use Giovanni::Visualizer::VisUtil;

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

Giovanni::Visualizer::Drivers::StaticPlots - visualize command-line based static plots

=head1 SYNOPSIS

use Giovanni::Visualizer::Drivers::StaticPlots;

my $driver = new Giovanni::Visualizer::Drivers::Gnuplots();

my $params = {};

my $resultItems = $driver->visualize(params);

=head1 DESCRIPTION

Visualizes command-line based static plots

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
    my $outDir     = $visualizerParams->{outDir};
    my $result     = { items => [] };
    my %imgOptions = ();
    my $cmdExe     = undef;

    # Build visualization command
    if ( $visualizerParams->{plotType} eq 'HISTOGRAM' ) {
        $cmdExe = qq(histogramPlot.py);
    }
    elsif ( any {/$visualizerParams->{plotType}/}
        qw(CURTAIN TIME_SERIES_CURTAIN) )
    {
        $cmdExe = qq(curtainPlot.py);
    }
    else {
        die "Visualizer failed: unknown static plot type";
    }

    # Process individual files
    foreach my $inFile ( keys %{ $visualizerParams->{dataFiles} } ) {
        my ( $srcFile, $srcDir, $srcSuffix )
            = fileparse( $inFile, qr/\.\w+$/ );

        # Get input item info (we expect to have only one layer to be
        # visualized per file, although this can be changed into a loop)
        my $inputItem = ${ $visualizerParams->{dataFiles}{$inFile} }[0];
        my $command   = $cmdExe;

        my %varInfo = Giovanni::Util::getNetcdfDataVariables($inFile);
        my $varName;

        # Find the variable to visualize if not set already
        $varName = $inputItem->{key}
            unless $inputItem->{key} eq
            $GIOVANNI::VISUALIZER->{DEFAULT_VIS_KEY};
        if ( !( defined $varName ) ) {
            for ( keys %varInfo ) {
                $varName = $_
                    unless $_ =~ 'bin_(.*)' || $_ =~ '(.*)_log';
            }
        }

# Check if we have palletes on the options schema and if so - check if need to setup SLDs
        if ($visualizerParams->{optionsParser}->getSchemaParameter(
                $visualizerParams->{plotType},
                $GIOVANNI::VISUALIZER->{DEFAULT_VIS_KEY},
                'properties/Palette/enum'
            )
            )
        {

            # Setup SLDs and retrive SLD metadata
            my $palettes
                = Giovanni::Visualizer::VisUtil::checkAndSetupStaticPlotSLDs(
                $inFile,
                $visualizerParams->{plotType},
                $visualizerParams->{optionsParser},
                $varName, 'properties/Palette/enum'
                );

            # Get default SLD entry if not specified on the options already
            my $plotOptions = $inputItem->{plotOptions};
            $plotOptions->{Palette}
                = Giovanni::Visualizer::VisUtil::getDefaultSld( $outDir,
                $varName, $palettes )
                unless exists $plotOptions->{Palette};
        }

        # Create options file
        my $optionsFile
            = $outDir . '/PlotOptions_' . $varName . '_' . time() . '.json';
        $visualizerParams->{optionsParser}
            ->createPlotOptionsFile( $optionsFile,
            $inputItem->{plotOptions} );

        # Build visualization command string
        if ( $visualizerParams->{plotType} eq 'HISTOGRAM' ) {
            my $outFileSuffix = $outDir . "/$srcFile" . '_' . time();
            $command .= qq( -i "$inFile" ) . qq( -o "$outFileSuffix" );
            $command .= qq( -v "$varName" );
            $command .= qq( -f $optionsFile ) if ( -f $optionsFile );
        }
        elsif ( any {/$visualizerParams->{plotType}/}
            qw(CURTAIN TIME_SERIES_CURTAIN) )
        {
            my $outFileSuffix = $outDir . "/$srcFile" . '_' . time();
            $command .= qq( -i "$inFile" ) . qq( -o "$outFileSuffix" );
            $command .= qq( -v "$varName" );
            $command .= qq( -f $optionsFile ) if ( -f $optionsFile );
        }
        die "Visualizer failed: failed to change directory"
            unless chdir($outDir);

        # Execute command string in the shell and check results
        my $nclOut = `$command`;
        print STDERR "Visualization command/output: $command\n$nclOut\n";

        die "Error while running visualization command" if ($?);

# unlink $optionsFile if ( -f $optionsFile ); # Not sure why this is commented out ...
# Parse visualizer output
        my $output
            = $visualizerParams->{optionsParser}
            ->parseOptions( $visualizerParams->{plotType},
            $varName, $nclOut, "options" );

        die "Error while processing output of visualization command"
            unless defined $output && keys %{$output} > 0;
        $output->{options} = {} unless defined $output->{options};

# See if any plot captions are set, either via visualization command or via data
        if (   ( not exists $output->{caption} )
            || ( $output->{caption} !~ /\S+/ ) )
        {
            my %inFileGlobalAttr
                = Giovanni::Util::getNetcdfGlobalAttributes($inFile);
            $output->{caption} = $inFileGlobalAttr{plot_hint_caption}
                if exists $inFileGlobalAttr{plot_hint_caption};
        }

        die $output->{error} if $output->{error};  # Die if error has been set

        # Get images
        foreach my $img ( @{ $output->{images} } ) {
            my $origImgFile = basename($img);

          # Rename image files so that their file name matches data file names
            if ( $origImgFile =~ /\Q$srcFile\E/ ) {
                $img = $outDir . "/" . basename($img);
            }
            else {
                my ( $imgFile, $imgDir, $imgSuffix )
                    = fileparse( $img, qr/\.\w+$/ );
                my $linkName
                    = $outDir . '/' . $srcFile . '_' . time() . $imgSuffix;
                if ( symlink( $img, $linkName ) ) {
                    $img = $outDir . "/" . basename($linkName);
                }
                else {
                    die "Failed to link to image file";
                }
            }
        }
        my $imgRef
            = Giovanni::Visualizer::VisUtil::convertImages( $output->{images},
            %imgOptions );
        my @imgList = values(%$imgRef);

        # Compute alt image title
        my $altTitle
            = Giovanni::Visualizer::VisUtil::getPlotAltTitle(
            $visualizerParams->{plotType},
            $inFile, $varName );

        # Holder for image URL to caption mapping
        my $captionRef = {};

        # Convert image file paths to URLs
        my @imgUrlList = ();
        foreach my $img (@imgList) {
            my $imgUrl = Giovanni::Util::convertFilePathToUrl( $img,
                \%GIOVANNI::URL_LOOKUP );
            my $resultItem = {
                datafile    => $inFile,
                imageUrl    => $imgUrl,
                plotOptions => $output->{options},
                caption     => $output->{caption},
                key         => $varName,
                title       => $altTitle
            };
            push( @{ $result->{items} }, $resultItem );
        }
    }
    return $result;
}

1;
