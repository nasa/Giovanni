package Giovanni::Visualizer::Drivers::InteractiveScatterPlot;

use strict;
use warnings;
use File::Basename;
use URI::Escape;
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

Giovanni::Visualizer::Drivers::InteractiveScatterPlot - prepares data for InteractiveScatterPlot plot

=head1 SYNOPSIS

use Giovanni::Visualizer::Drivers::InteractiveScatterPlot;

$driver = new Giovanni::Visualizer::Drivers::InteractiveScatterPlot();

my $params = {};

my $resultItems = $driver->visualize(params);

=head1 DESCRIPTION

Prepares data for InteractiveScatterPlot plot

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
    my $result = { items => [] };

    foreach my $inFile ( keys %{ $visualizerParams->{dataFiles} } ) {
        my @idList = split( /\//, $inFile );
        my $urlQuery
            = "result=$idList[-2]&resultset=$idList[-3]&session=$idList[-4]&filename="
            . uri_escape( basename($inFile) );
        my $dataUrl = "daac-bin/getGiovanniScatterPlotInfo.pl?" . $urlQuery;

        # Compute alt image title
        my $altTitle = Giovanni::Visualizer::VisUtil::getPlotAltTitle(
            $visualizerParams->{plotType}, $inFile );

        # Set output items
        push(
            @{ $result->{items} },
            {   datafile => $inFile,
                imageUrl => $dataUrl,
                title    => $altTitle
            }
        );
    }
    return $result;
}

1;
