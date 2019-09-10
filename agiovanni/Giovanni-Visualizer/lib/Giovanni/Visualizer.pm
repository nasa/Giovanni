#$Id: Visualizer.pm,v 1.176 2015/08/07 15:33:39 mpetrenk Exp $
#-@@@ Giovanni, Version $Name:  $

# Formatted with 'perltidy -pbp -nst -fnl -nolc -b'

package Giovanni::Visualizer;

use 5.008008;
use Data::UUID;
use File::Basename;
use Giovanni::History;
use Giovanni::Visualizer::Preferences;
use JSON;
use List::MoreUtils qw/ any /;
use LWP::UserAgent;
use Safe;
use Storable 'dclone';
use strict;
use vars '$AUTOLOAD';
use warnings;

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

our $VERSION = '1.00';

# LWP::UserAgent is used instead of wget, so define a new instance and tie to environment proxy
my $ua = LWP::UserAgent->new();
$ua->env_proxy;

#################################################################################
# Constructor
#################################################################################

sub new() {
    my ( $class, %input ) = @_;
    my $self = {};
    $self->{_IN_OPTIONS} = exists $input{OPTIONS} ? $input{OPTIONS} : undef;
    $self->{_NETCDF_SERIALIZER_URL} = $input{NETCDF_SERIALIZER_URL};
    $self->{_OUTPUT_DIR}
        = defined $input{OUTPUT_DIR} ? $input{OUTPUT_DIR} : undef;

    # See if input is a single file or multiple files
    if ( defined $input{FILE} ) {
        if ( ref( $input{FILE} ) eq 'ARRAY' ) {
            $self->{_INPUT_FILE} = $input{FILE};
        }
        elsif ( -f $input{FILE} ) {
            $self->{_INPUT_FILE} = $input{FILE};
        }
        else {
            die "No visualization input file found";
        }
    }

    # turn on debugging if 1; off if 0
    $self->{_DEBUG}     = 0;
    $self->{_PLOT_TYPE} = $input{PLOT_TYPE};

    # Read visualization history if one exists
    if ( defined $self->{_OUTPUT_DIR} ) {
        my $historyFile = $self->{_OUTPUT_DIR} . '/'
            . $GIOVANNI::VISUALIZER->{HISTORY_FILE_NAME};
        my $keyAttributes = [ 'datafile', 'key', 'imageUrl' ];
        $self->{_HISTORY} = Giovanni::History->new(
            FILE                  => $historyFile,
            UNIQUE_KEY_ATTRIBUTES => $keyAttributes
        );
    }

    return bless( $self, $class );
}

#################################################################################
# Configuration for individual visualizers
#################################################################################

sub getVisualizationDriver() {
    my ( $self, $plotType ) = @_;

# return { plotSupertype => $plotType, visualizer => \&visualizeInteractiveMap };
    foreach my $visConfigItem ( @{ $GIOVANNI::VISUALIZER->{VISUALIZERS} } ) {
        next unless any {/$plotType/} @{ $visConfigItem->{PLOT_TYPES} };
        my $driverClass
            = "Giovanni::Visualizer::Drivers::" . $visConfigItem->{DRIVER};
        eval "require $driverClass";
        if ($@) {
            die "Failed to load visualization driver ($driverClass)";
        }
        my $visualizationDriver = $driverClass->new();
        return $visualizationDriver;
    }
    die "Failed to find a visualization driver config for $plotType";
}

#################################################################################
# Main Driver
#################################################################################

sub visualize {
    my ($self) = @_;

# STEP 1: Determine plot type
# STEP 2: Get user options and options schema (as a hash and as a file) for the specified plot type
# STEP 3: Go through the history and see if any combination of data file and options have been
#         visualized before. If so - add them to the list of results
# STEP 4: Call visualizer code on the remaining (not previously visualized) combinations
# STEP 5: Check for errors
# STEP 6: Add returned images/options to the history and the list of results
# STEP 7: Form response
# NOTE: Interative maps do not keep history, so they always re-visualize

    my $result;
    eval {
        # Determine plot super type and select an appropriate visualizer
        my $plotType = $self->getPlotType();
        my $driver   = $self->getVisualizationDriver($plotType);

        # Get working directory and session / resultset / result IDs
        my $sessionDir = $self->getDir();
        $sessionDir = dirname( ${ $self->getInputFiles() }[0] )
            unless defined $sessionDir;
        my ( $sessionId, $resultsetId, $resultId )
            = Giovanni::Util::getSessionIds($sessionDir);

    # Load up options parser (can specify non-validatable params if necessary)
        my $optionsParser
            = Giovanni::Visualizer::Preferences->new( $sessionDir,
            { DO_NOT_VALIDATE_PARAMS => [] } );
        my $idKeyPairs = $self->{_HISTORY}
            ->getUniqueAttributeCombinations( [ 'id', 'key' ] );
        my $idKeyMap = { map { $_->{id} => $_->{key} } @{$idKeyPairs} };
        my @keys = values %{$idKeyMap};
        push( @keys, $GIOVANNI::VISUALIZER->{DEFAULT_VIS_KEY} )
            ;    # Add default key

        foreach my $key (@keys) {

            # Load up options schema for each key if exists
            $optionsParser->loadSchema( $plotType, $key );
        }

        # Parse user options and exit if failed
        my $options
            = $self->getPlotOptionsAndSchema( $plotType, $optionsParser,
            $idKeyMap );

 # See if any of the files have been visualized already
 # If so - get existing visualizer results and a list of files
 # that still need to be (re)visualized
 # $dataFileListFinal is a final list of input files, in the following format:
 #
 #       {dataFile => [
 #           {
 #               key=>string,
 #               options=>hash
 #           }
 #       ]}
 #
 # Where key is key specifying which specific image to generate
 # in a specific dataFile file, and options are user options specific to this
 # file and key.

        my ( $historyItems, $dataFileListFinal )
            = $self->getInputFilesAndHistoryItems( $plotType, $options,
            $GIOVANNI::VISUALIZER->{DEFAULT_VIS_KEY} );

# Build hash with common input parameters for the visualizer. Some params can be undefined.
        my $params = {
            optionsParser => $optionsParser,
            dataFiles     => $dataFileListFinal,
            outDir        => $sessionDir,
            plotType      => $plotType,
            resultsetId   => $resultsetId,
            resultId      => $resultId,
            sessionId     => $sessionId
        };

        # Launch visualization if there are still files to visualize
        $result = $driver->visualize($params);
        die "Received incorrect response from visualizer"
            unless ref $result eq 'HASH';

        # Analyze results and append missing params
        $self->processVisualizerResult( $params, $result );

        # Add results to history and append found history items to result
        $self->addResultsToHistory( $params, $result );
        $result->{items} = [ @{$historyItems}, @{ $result->{items} } ];

        # Form response object
        $self->setupExternalResponseProperties( $params, $result );
    };

    # Process errors
    if ($@) {

        # Write to log and STDERR
        print STDERR "ERROR ", $@, "\n";

# Cleanup error message and set to default wording if cleanup resulted in empty string
        $@ =~ s/ at \/.*$//g;
        $@ =~ s/.*line.*//g;
        $@ = 'Unknown error while visualizing data file' if $@ eq '';

        # Pass the cleaned up message down to the clients
        die $@;
    }

    # Tell the client we succeeded
    return 1;
}

#################################################################################
# Working with history
#################################################################################
# Returns history items based on request parameters
# We need to return a list of {datafile => [{key, options}]}
# Possible scenarios:
# 1. History is empty (first request), and we received empty options or options
#    hash - just return the list of files
# 2. History is not empty, and we received a list of {id, options} pairs
#    In this case, we need:
#    a) Identify all possible {datafile, key} combinations.
#    b) Identify [{datadile, key, options}], where key and file are determined from id,
#       and options is the new options supplied by the user (if not found in history).
#       These will need to be re-rendered.
#    c) Identify most recent items for the remaining {datafile, key} combinations. For this,
#       we probably need to find all possible {datafile, key} combinations.
# 3. History is not empty, and we received a single hash {options}.
#    In this case, we need:
#    a) Identify all possible {datafile, key} combinations.
#    b) Find all {datafile, key} items that have the same {options}.
#    c) Find all {datafile, key} combinations not covered by b) - theses will become
#       [{datadile => {key, options}}] that need to be re-rendered

sub getInputFilesAndHistoryItems {
    my ( $self, $plotType, $options, $defaultKey ) = @_;
    die "Unexpected format of options while processing history items"
        if defined $options && ref $options ne 'ARRAY';
    $options = [ {} ] unless defined $options;
    my $historyItems      = ();
    my $dataFileList      = $self->getInputFiles();    # Get input data files
    my $alreadyProcessed  = {};
    my $dataFileListFinal = ();
    my $historyItemList   = [];
    my $query             = {};
    my $collectedFileKeyCombinations = {};
    my $allFileKeyCombinations
        = $self->{_HISTORY}
        ->getUniqueAttributeCombinations( [ 'datafile', 'key' ],
        { plotType => $plotType, datafile => $dataFileList } );

# Set default options in case something goes wrong or options were not supplied
# NOTE: the side effect is that same option #1 can be assigned to all input files,
# which is useful in some cases, like map animation
    my $defaultInputItem = { plotOptions => {}, key => $defaultKey };
    $defaultInputItem->{plotOptions} = ${$options}[0]->{options}
        if @{$options} > 0 && exists ${$options}[0]->{options};

# Return a simple map containing all input files and empty keys if this is our first run
    return ( $historyItemList,
        { map { $_ => [ dclone $defaultInputItem] } @{$dataFileList} } )
        if ( !@{$allFileKeyCombinations} );

# Go through history and get items (and/or datafile/key pairs) that correspond to the supplied options
    foreach my $userOptionsItem ( @{$options} ) {
        $query = {
            plotOptions => $userOptionsItem->{options},
            plotType    => $plotType,
            datafile    => $dataFileList
        };
        $query->{id} = $userOptionsItem->{id}
            if defined $userOptionsItem->{id};
        my $match = $self->{_HISTORY}->find($query);
        if ( !@{$match} ) {

# If we did not find any matches with the supplied options - try without them
# This should find earlier requests with the same ID to learn about plot key, schema, defaults etc
            delete $query->{plotOptions};
            $match = $self->{_HISTORY}->find($query);
            if ( @{$match} >= 1 ) {

# If we located requested image ID in the history - add it's key and datafile to the list of items to re-render
                $dataFileListFinal->{ ${$match}[0]->{datafile} } = []
                    unless
                    defined $dataFileListFinal->{ ${$match}[0]->{datafile} };
                push(
                    @{ $dataFileListFinal->{ ${$match}[0]->{datafile} } },
                    {   key         => ${$match}[0]->{key},
                        plotOptions => $userOptionsItem->{options},
                        plotOptionsDefault =>
                            ${$match}[0]->{plotOptionsDefault},
                        id => ${$match}[0]->{id}
                    }
                );
            }
            else {

# If we failed to find history items even without options - let's see if we know about this plot ID at all
# (do nothing, just produce a warning in the log)
                if ( defined $userOptionsItem->{id} ) {
                    $query = { id => $userOptionsItem->{id} };
                    my $matchCheck = $self->{_HISTORY}->find($query);
                    warn
                        "WARNING User requested re-draw of a plot with an unknown image ID ($userOptionsItem->{id})"
                        unless @{$matchCheck} >= 1;
                }
            }
        }
        else {

            # If we found a match - add it to the list
            push( @{$historyItemList}, ${$match}[0] );
            warn
                "WARNING Found more then one history item matching the requested ID and options"
                if ( @{$match} > 1 );
        }

        # Make a note that we found this datafile-key combination
        $collectedFileKeyCombinations->{ $self->{_HISTORY}
                ->getItemKey( ${$match}[0], [ 'datafile', 'key' ] ) } = 1
            unless ( !@{$match} );
    }

 # Retrieve remaining visualization items that do not need to be re-visualized
    foreach my $fileKeyCombination ( @{$allFileKeyCombinations} ) {
        my $historyKey = $self->{_HISTORY}
            ->getItemKey( $fileKeyCombination, [ 'datafile', 'key' ] );
        next if exists $collectedFileKeyCombinations->{$historyKey};
        $query = {
            datafile => $fileKeyCombination->{datafile},
            key      => $fileKeyCombination->{key}
        };
        my $match = $self->{_HISTORY}->find($query);

        if ( !@{$match} ) {
            warn "WARNING Failed to find a mathcing item in history"
                if ( !@{$match} );
            next;
        }

        # Return only the most recent result
        push(
            @{$historyItemList},
            ( sort { $b->{accessed} cmp $a->{accessed} } @{$match} )[0]
        );
    }

# Update access time on the returned history items so that we know what to return on subsequent requests
    foreach my $item ( @{$historyItemList} ) {
        $item->{accessed} = time();    # Updated
    }
    return ( $historyItemList, $dataFileListFinal );
}

# Adds visualization result items to the history
sub addResultsToHistory {
    my ( $self, $params, $result ) = @_;

    # At the end of it, write to history only if new images are created
    $self->{_HISTORY}->addItems( $result->{items} );
    $self->{_HISTORY}->write();
}

#################################################################################
# Process input
#################################################################################

# Get plot options
sub getPlotOptionsAndSchema {
    my ( $self, $plotType, $optionsParser, $idKeyMap ) = @_;

# Handle user supplied plot options and retreive JSON schema for the selected plot type
    my $userOptionStr = $self->getUserOptions();
    return $optionsParser->parseOptions( $plotType, $self->{_DEFAULT_KEY},
        $userOptionStr, "options", $idKeyMap );
}

#################################################################################
# Process output
#################################################################################

# Returns new UUID
sub getNewUUID {
    my ($self) = @_;

    # Generate uniqe id to be used as session ID
    my $id   = Data::UUID->new();
    my $uuid = $id->create();
    return $id->to_string($uuid);
}

# This is used to append aditional/missing parameters on response items
# that we might need in history or client response
sub processVisualizerResult {
    my ( $self, $params, $result ) = @_;
    my @paramKeysToCopy = qw(plotType plotOptions);    # plotOptionsSchema
         # Loop through return items
    for my $resultItem ( @{ $result->{items} } ) {

# If this is a re-render - let's find default options and image id (i.e., conver key back to id)
# We would know this is a re-render by matching datafile and result item key to input item datafile and key
# Note that key can be undefined (in this case, one file results in one result item)
        foreach my $inputItem (
            @{ $params->{dataFiles}{ $resultItem->{datafile} } } )
        {
            if ( defined $inputItem->{id}
                && $inputItem->{key} eq $resultItem->{key} )
            {
                $resultItem->{id} = $inputItem->{id};
                $resultItem->{plotOptionsDefault}
                    = $inputItem->{plotOptionsDefault}
                    if defined $inputItem->{plotOptionsDefault}
                    ;    # Copy over defaults
                $resultItem->{plotOptions} = $inputItem->{plotOptions}
                    unless defined $resultItem->{plotOptions}
                    ;    # Copy options unless already set by visulaizer
                $resultItem->{plotOptions} = {}
                    unless defined $resultItem->{plotOptions}
                    ; # Set options to empty hash as required by the front end
                last;
            }
        }

        # Set plot ID if this is not a re-render
        $resultItem->{id} = $self->getNewUUID()
            unless defined $resultItem->{id};

        # Set defaults if this is our first render of this particular item
        $resultItem->{plotOptionsDefault} = $resultItem->{plotOptions}
            unless defined $resultItem->{plotOptionsDefault};

# $resultItem->{plotOptionsSchema} = $params->{optionsParser}->getSchema($inputItem->{plotType}, $inputItem->{key});

        # Merge results with schema for user output
        eval {
            $resultItem->{plotOptionsInstance}
                = $params->{optionsParser}
                ->getSchemaWithDefaults( $params->{plotType},
                $resultItem->{key}, $resultItem->{plotOptions} );
        };
        if ($@) {
            warn "WARNING ", $@;
            die
                "Output of visulazition module does not comply with plot schema";
        }

        # Timestamp the result to keep track of things in history
        $resultItem->{created}  = time();
        $resultItem->{accessed} = time();

        # Copy extra keys from params if not defined on the result already
        foreach my $key (@paramKeysToCopy) {
            $resultItem->{$key} = $params->{$key}
                unless defined $resultItem->{$key}
                || not defined $params->{$key};
        }

        # Delete empty keys
        foreach my $key ( keys %$resultItem ) {
            delete $resultItem->{$key} unless defined $resultItem->{$key};
        }
    }
}

# Build client response structure (to be picked up later by calling getResults)
# Note: all properties are converted to string XML nodes, unless name is prefixed with '-',
# in which case the property is converted to XML node attribute
sub setupExternalResponseProperties {
    my ( $self, $params, $result ) = @_;

    # Result object
    $self->{_RESULT_ITEMS} = {};

    for my $item ( @{ $result->{items} } ) {

        # Output result item
        $self->{_RESULT_ITEMS}{ $item->{datafile} } = []
            unless defined $self->{_RESULT_ITEMS}{ $item->{datafile} };
        my $outputItem = {
            src     => $item->{imageUrl},
            caption => $item->{caption},
            id      => $item->{id},
            options =>
                { schema => encode_json( $item->{plotOptionsInstance} ), },
            label => $item->{caption},
            title => $item->{title},
            -type => $item->{plotType}    # This becomes an attribute!
        };
        $outputItem->{options}{defaults}
            = encode_json( $item->{plotOptionsDefault} )
            if defined $item->{plotOptionsDefault};
        $outputItem = { image => $outputItem };
        Giovanni::Util::removeEmptyKeys($outputItem);
        push(
            @{ $self->{_RESULT_ITEMS}{ $item->{datafile} } },
            $outputItem
        );
    }
    $self->{_RESULT_ITEMS} = [ values %{ $self->{_RESULT_ITEMS} } ];
}

#################################################################################
# Output getters
#################################################################################

# Generates PDF url (used in static plots)
sub getPdfUrl {
    my ( $self, $portal ) = @_;
    $portal = 'GIOVANNI' unless defined $portal;
    my $plotType = $self->getPlotType();

    # PDF download is allowed only for select plot types; mostly static plots.
    my %plotListRef = map { $_ => 1 }
        qw(TIME_SERIES SCATTER_PLOT AEROSTAT_SCATTER_PLOT MAP);
    return undef unless exists $plotListRef{$plotType};
    my $dir = $self->getDir();
    return undef if not defined $dir;
    $dir =~ s/$GIOVANNI::SESSION_LOCATION//;
    $dir =~ s/^\/+|\/+$//g;
    my $pdfUrl
        = 'daac-bin/createPdf.pl?portal=' . $portal . '&result=' . $dir;
    return $pdfUrl;
}

################################################################################
sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    if ( $AUTOLOAD =~ /.*::getInputFile/ ) {
        return $self->{_INPUT_FILE};
    }
    elsif ( $AUTOLOAD =~ /.*::getResults/ ) {
        return $self->{_RESULT_ITEMS};
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }
    elsif ( $AUTOLOAD =~ /.*::getSerializer/ ) {
        return $self->{_NETCDF_SERIALIZER_URL};
    }
    elsif ( $AUTOLOAD =~ /.*::getDir/ ) {
        return $self->{_OUTPUT_DIR};
    }
    elsif ( $AUTOLOAD =~ /.*::getPlotType/ ) {
        return $self->{_PLOT_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::getUserOptions/ ) {
        return $self->{_IN_OPTIONS};
    }
}
################################################################################
1
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::Visualizer - Perl extension for blah blah blah

=head1 SYNOPSIS

    use Giovanni::Visualizer;
    eval {
        my $visualizer = Giovanni::Visualizer->new(
            FILE       => [$dataFile],
            PLOT_TYPE  => $plotType,
            OUTPUT_DIR => $outputDir,
            OPTIONS    => $options,
        );
        my $status = $visualizer->visualize();
        my $resultRef  = $visualizer->getResults();
        my $pdfUrl     = $visualizer->getPdfUrl($portal);
    };
    if ($@) {
        warn $2;
    }
    
=head1 DESCRIPTION


=head2 EXPORT


=head1 SEE ALSO


=head1 AUTHOR

Mahabaleshwara S. Hegde, E<lt>mhegde@localdomainE<gt>

=cut




