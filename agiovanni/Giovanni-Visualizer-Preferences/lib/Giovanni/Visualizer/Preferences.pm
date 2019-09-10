#$Id: Preferences.pm,v 2.0 2017/06/21 17:29:52 mpetrenk Exp $
#-@@@ Giovanni, Version $Name:  $
package Giovanni::Visualizer::Preferences;

use 5.008008;
use strict;
use warnings;
use File::Basename;
use JSON;
use JSV::Validator;
use Storable 'dclone';
use Giovanni::Util;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration    use Giovanni::Visualizer::Preferences ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
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

#################################################################################
# Preloaded methods go here. The class is read-only in the sense that it
# will parse a supplied JSON on the load up and then expose the parsed JSON
# as a hash object, along with a couple of export / verification functions
# that operate on this hash
# Params:
#   - DO_NOT_VALIDATE_PARAMS - names of the JSON schema params to ignore
#
#################################################################################
sub new() {
    my ( $class, $sessionDir, $params ) = @_;
    my $self          = {};
    my @allowedParams = qw(DO_NOT_VALIDATE_PARAMS PLOT_OPTIONS_SCHEMAS_DIR);
    $self->{_DEFAULT_VIS_KEY} = $GIOVANNI::VISUALIZER->{DEFAULT_VIS_KEY};
    $self->{_SESSION_DIR}     = $sessionDir;
    $self->{_PLOT_OPTIONS_SCHEMAS_DIR} = $GIOVANNI::PLOT_OPTIONS_SCHEMAS_DIR;

    # Store optional parameters
    if ( defined $params ) {
        foreach my $key (@allowedParams) {
            $self->{ '_' . $key } = $params->{$key} if exists $params->{$key};
        }
    }

    # Bind self to the class
    bless( $self, $class );

    # Load up options schema and parse JSON
    $self->{_OPTIONS_SCHEMAS} = {};

    return $self;
}

#################################################################################
# Add schema
#################################################################################

sub loadSchema {
    my ( $self, $plotType, $key ) = @_;
    my $ourKey = defined $key ? $key : $self->{_DEFAULT_VIS_KEY};

    $self->{_OPTIONS_SCHEMAS}{$plotType} = {}
        unless exists $self->{_OPTIONS_SCHEMAS}{$plotType};
    return if exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey};
    $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey}
        = $self->readSchema( $plotType, $ourKey );
}

#################################################################################
# Returns name of a file that is used to store session-specific schema file
#################################################################################
sub getSchemaFilePath {
    my ( $self, $plotType, $key ) = @_;
    return
        "JSON_SCHEMA_$plotType" . "_"
        . ( defined $key ? $key : $self->{_DEFAULT_VIS_KEY} ) . ".json";
}

#################################################################################
# Reads from file a plot type-specific JSON schema
# Any errors will stop the code, since this is a backend operation and
# we should always be able to locate an appropriate schema.
#################################################################################
sub readSchema {
    my ( $self, $plotType, $key ) = @_;
    my $schemaData = undef;
    my $ourKey = defined $key ? $key : $self->{_DEFAULT_VIS_KEY};
    die "Attempted to retrieve plot options without specifying plot type"
        unless defined $plotType;

# Try to load up schema from the session directory first. If it does not exist - load the system one instead.
    my $schemaPath
        = defined $self->{_SESSION_DIR}
        ? $self->{_SESSION_DIR} . "/"
        . $self->getSchemaFilePath( $plotType, $ourKey )
        : undef;
    $schemaPath
        = $self->{_PLOT_OPTIONS_SCHEMAS_DIR} . "/" . $plotType . ".json"
        unless defined $schemaPath && -f $schemaPath;
    die "Failed to locate JSON validation schema" unless -f $schemaPath;
    my $schemaStr = do {
        local $/ = undef;
        open my $fh, "<", $schemaPath or die "could not open $schemaPath: $!";
        <$fh>;
    };
    eval { $schemaData = decode_json($schemaStr); };
    die "Failed to load JSON validation schema" if ($@);

 # We add additionalProperties=false option to the schema just in case someone
 # forgot to specify this in the schema! (This blocks params that are not
 # explicitly specified in the schema)
    $schemaData->{additionalProperties}
        = decode_json('{"dummy":false}')->{dummy};
    return $schemaData;
}

#################################################################################
# Saves current version of all loaded JSON Schemas to session directory
#################################################################################
sub saveSchemas {
    my ( $self, $plotType, $key ) = @_;
    return unless defined $self->{_SESSION_DIR} && $self->{_OPTIONS_SCHEMAS};
    if ( defined $plotType ) {

        # Save requested schema
        die 'Unknown plot type while validating JSON data'
            unless exists $self->{_OPTIONS_SCHEMAS}{$plotType};
        my $ourKey
            = defined $key
            && exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$key}
            ? $key
            : $self->{_DEFAULT_VIS_KEY};

        my $schemaPath = $self->{_SESSION_DIR} . "/"
            . $self->getSchemaFilePath( $plotType, $ourKey );
        my $filecontent
            = encode_json( $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey} );
        Giovanni::Util::writeFile( $schemaPath, $filecontent );
    }
    else {

        # Save all schemas
        foreach $plotType ( keys %{ $self->{_OPTIONS_SCHEMAS} } ) {
            foreach $key ( keys %{ $self->{_OPTIONS_SCHEMAS}{$plotType} } ) {
                my $schemaPath = $self->{_SESSION_DIR} . "/"
                    . $self->getSchemaFilePath( $plotType, $key );
                my $filecontent = encode_json(
                    $self->{_OPTIONS_SCHEMAS}{$plotType}{$key} );
                Giovanni::Util::writeFile( $schemaPath, $filecontent );
            }
        }
    }
}

#################################################################################
# JSON Schema validator
#################################################################################
sub validate {
    my ( $self, $plotType, $key, $instance ) = @_;
    die 'Unknown plot type while validating JSON data'
        unless exists $self->{_OPTIONS_SCHEMAS}{$plotType};
    my $ourKey
        = defined $key && exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$key}
        ? $key
        : $self->{_DEFAULT_VIS_KEY};

    my $isValid = 1 == 2;
    if ( not defined $self->{_VALIDATOR} ) {

        # Load JSON schema validator
        JSV::Validator->load_environments("draft4");
        $self->{_VALIDATOR} = JSV::Validator->new( environment => "draft4" );
    }

    # JSV validator has a bug that returns either 1 or 0 on valid enum params,
    # but consistently returns 0 on invalid ones. Let's run 5 times and see
    # if we get any 1's. Almost Monte-Carlo!
    $instance = dclone $instance;
    $instance = Giovanni::Util::unifyJsonNumbers($instance);
    if ( defined $self->{_DO_NOT_VALIDATE_PARAMS} ) {
        foreach my $skipKey ( @{ $self->{_DO_NOT_VALIDATE_PARAMS} } ) {
            delete $instance->{$skipKey} if exists $instance->{$skipKey};
        }
    }
    foreach my $counter ( 0 .. 10 ) {
        my $validateWhat = dclone $instance;
        my $validationSchema
            = dclone $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey};
        $isValid
            = $isValid
            || $self->{_VALIDATOR}
            ->validate( $validationSchema, $validateWhat );
        last if $isValid;
    }
    return $isValid;
}
#################################################################################
# Adds values to a schema as defaults
#################################################################################
# Removes undef keys in-place
sub __walkSchemaAndInstance {
    my ( $self, $schemaFull, $schemaPart, $instancePart ) = @_;
    if ( ref $instancePart eq 'HASH' ) {
        foreach my $key ( keys %{$instancePart} ) {
            if ( not exists $schemaPart->{$key} ) {
                die
                    "Instance does not mathch schema at key [$key] while trying to assign defaults";
            }
            else {
                if ( exists $schemaPart->{$key}{ '$' . 'ref' } ) {
                    my $ref = $schemaPart->{$key}{ '$' . 'ref' };
                    $ref =~ s/^#\///;
                    my $definition = $schemaFull;
                    foreach my $refKey ( split( '/', $ref ) ) {
                        $definition = $definition->{$refKey};
                    }
                    $schemaPart->{$key} = dclone $definition;
                }
                if ( $schemaPart->{$key}{type} eq 'object'
                    and exists $schemaPart->{$key}{enum} )
                {
                    $schemaPart->{$key}{default} = $instancePart->{$key};
                }
                elsif ( $schemaPart->{$key}{type} eq 'object'
                    and exists $schemaPart->{$key}{properties} )
                {
                    $self->__walkSchemaAndInstance( $schemaFull,
                        $schemaPart->{$key}{properties},
                        $instancePart->{$key} );
                }
                else {
                    $self->__walkSchemaAndInstance( $schemaFull,
                        $schemaPart->{$key}, $instancePart->{$key} );
                }
            }
        }
    }
    elsif ( ref $instancePart eq 'ARRAY' ) {
        die "Default values on complex array types are not supported yet"
            unless ( $schemaPart->{items}{type} ne 'object'
            || exists $schemaPart->{items}{enum} );
        $schemaPart->{default} = $instancePart;
    }
    else {
        die
            unless ( ref $schemaPart eq 'HASH'
            and $schemaPart->{type} ne 'object' );
        $schemaPart->{default} = $instancePart;
    }
}

#################################################################################
# Appends default values to the schema from supplied instance
#################################################################################
sub getSchemaWithDefaults {
    my ( $self, $plotType, $key, $instance ) = @_;
    die 'Unknown plot type while validating JSON data'
        unless exists $self->{_OPTIONS_SCHEMAS}{$plotType};
    my $ourKey
        = defined $key && exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$key}
        ? $key
        : $self->{_DEFAULT_VIS_KEY};

    return dclone $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey}
        unless defined $instance;
    die "Supplied default values do not comply with specified schema"
        unless ( $self->validate( $plotType, $key, $instance ) );
    my $schemaFused = dclone $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey};
    $self->__walkSchemaAndInstance(
        $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey},
        $schemaFused->{properties}, $instance );
    return $schemaFused;
}

#################################################################################
# Parses supplied JSON file or string into an object and validates against
# a plot type-specific schema. Failed load or validation does not stop the
# code but rather returns an empty otions hash
# Parameter $optionsPath tells the code what path of the parsed
# JSON to validate
# Optional parameter $idKeyMap contains mapping from IDs to keys - this is
# used to choose an appropriate validation schema based on id of the options str
#################################################################################
sub parseOptions {
    my ( $self, $plotType, $key, $optionString, $optionsPath, $idKeyMap )
        = @_;
    my $ourKey             = $key;
    my $defaultReturnValue = undef;
    my $isHash             = 0;
    die 'Unknown plot type while validating JSON data'
        unless exists $self->{_OPTIONS_SCHEMAS}{$plotType};
    return $defaultReturnValue unless defined $optionString;

    # If supplied string is a file - load options from the file
    $optionString = Giovanni::Util::readFile($optionString)
        if ( -f $optionString );

    # Decode string or file from JSON to Perl Hash
    my $optionsData = undef;
    return $defaultReturnValue unless $optionString ne "";

    # Parse JSON string
    eval { $optionsData = decode_json($optionString); };
    if ($@) {
        $self->{_ERROR_MESSAGE}
            = "Bad plot options JSON detected, using default values";
        warn "WARNING " . $self->{_ERROR_MESSAGE};
        return $defaultReturnValue;
    }
    $optionsData = Giovanni::Util::unifyJsonNumbers( dclone $optionsData);

    # Support for parsing of output of shell commands
    if ( ref $optionsData eq 'HASH' ) {
        $isHash      = 1;
        $optionsData = [$optionsData];
    }

    # Sanity check
    if ( ref $optionsData ne "ARRAY" ) {
        $self->{_ERROR_MESSAGE}
            = "Unexpected plot options format, using default values";
        warn "WARNING " . $self->{_ERROR_MESSAGE};
        return $defaultReturnValue;
    }

    # Validate data / extract options from suppied object
    foreach my $optionsItem ( @{$optionsData} ) {

        # Determine key
        if ( !( defined $key ) ) {
            $ourKey = $idKeyMap->{ $optionsItem->{id} }
                if ( exists $optionsItem->{id}
                && defined $idKeyMap
                && exists $idKeyMap->{ $optionsItem->{id} } );
            $ourKey = defined $ourKey ? $ourKey : $self->{_DEFAULT_VIS_KEY};
            die 'Unknown plot key while validating JSON data'
                unless exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey};
        }

        # Extract options from the supplied object
        my $validateWhat
            = Giovanni::Util::getHashPath( $optionsItem, $optionsPath );

        # Validate options
        if ( !$self->validate( $plotType, $ourKey, $validateWhat ) ) {
            $self->{_ERROR_MESSAGE}
                = "Plot options do not comply with spec schema, using default values";
            warn "WARNING " . $self->{_ERROR_MESSAGE};
            Giovanni::Util::setHashPath( $optionsItem, $optionsPath,
                $defaultReturnValue );
        }
    }
    return $isHash == 1 ? ${$optionsData}[0] : $optionsData;
}

#################################################################################
# Sets options schema parameter at a given path and saves schema to file
#################################################################################
sub removeSchemaParameter {
    my ( $self, $plotType, $key, $path ) = @_;
    die 'Unknown plot type while validating JSON data'
        unless exists $self->{_OPTIONS_SCHEMAS}{$plotType};
    my $ourKey
        = defined $key && exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$key}
        ? $key
        : $self->{_DEFAULT_VIS_KEY};
    if ( defined $key
        && !( exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$key} ) )
    {
        warn
            'Attempted to set schema parameter in Preferences using a key without creating a correspoding schema.';
        warn
            'All changes will be saved to the default key. Please make sure to call loadSchema(plotType, key) first.';
    }

    my $schemaHash = $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey};
    Giovanni::Util::removeHashPath( $schemaHash, $path );
}

#################################################################################
# Removes options schema parameter at a given path and saves schema to file
#################################################################################
sub setSchemaParameter {
    my ( $self, $plotType, $key, $param, $path ) = @_;
    die 'Unknown plot type while validating JSON data'
        unless exists $self->{_OPTIONS_SCHEMAS}{$plotType};
    my $ourKey
        = defined $key && exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$key}
        ? $key
        : $self->{_DEFAULT_VIS_KEY};
    if ( defined $key
        && !( exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$key} ) )
    {
        warn
            'Attempted to set schema parameter in Preferences using a key without creating a correspoding schema.';
        warn
            'All changes will be saved to the default key. Please make sure to call loadSchema(plotType, key) first.';
    }

    my $schemaHash = $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey};
    Giovanni::Util::setHashPath( $schemaHash, $path, $param );
}

#################################################################################
# Gets options schema parameter at a given path
#################################################################################
sub getSchemaParameter {
    my ( $self, $plotType, $key, $path ) = @_;
    die 'Unknown plot type while validating JSON data'
        unless exists $self->{_OPTIONS_SCHEMAS}{$plotType};
    my $ourKey
        = defined $key && exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$key}
        ? $key
        : $self->{_DEFAULT_VIS_KEY};

    my $what = $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey};
    return Giovanni::Util::getHashPath( $what, $path );
}

#################################################################################
# Returns a hash ref with keys as axis option name
#################################################################################
sub getSchema {
    my ( $self, $plotType, $key ) = @_;
    die 'Unknown plot type while validating JSON data'
        unless exists $self->{_OPTIONS_SCHEMAS}{$plotType};
    my $ourKey
        = defined $key && exists $self->{_OPTIONS_SCHEMAS}{$plotType}{$key}
        ? $key
        : $self->{_DEFAULT_VIS_KEY};

    # Return a copy of the options to prevent modifications
    return dclone $self->{_OPTIONS_SCHEMAS}{$plotType}{$ourKey};
}

#################################################################################
# This simply dumps options object into a JSON file.
# If options are empty - no file gets created, and
# existing options file ()if any) gets removed
#################################################################################

sub createPlotOptionsFile {
    my ( $self, $fname, $optionsHash ) = @_;
    $optionsHash = {} unless ( ref $optionsHash eq 'HASH' );
    my ( $filename, $filepath, $suffix ) = fileparse($fname);
    if ( -e $filepath ) {
        if ( !( !keys %{$optionsHash} ) ) {
            my $filecontent = encode_json($optionsHash);
            Giovanni::Util::writeFile( $fname, $filecontent );
        }
        else {
            if ( -e $fname ) {
                eval { unlink($fname); };
                print STDERR
                    "INFO-Preferences: the Options file $fname is not removed because $@\n"
                    if ($@);
            }
        }
    }
    else {
        $self->{_ERROR_MESSAGE} = "Error: working directory does not exist";
    }
}

################################################################################
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::Visualizer::Preferences - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Giovanni::Visualizer::Preferences;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Giovanni::Visualizer::Preferences, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Xiaopeng Hu, E<lt>hxiaopen@localdomainE<gt>
Maksym Petrenko, E<lt>maksym.petrenko@nasa.gov<gt>


=cut



