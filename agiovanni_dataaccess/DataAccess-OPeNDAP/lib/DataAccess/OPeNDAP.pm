#!/usr/bin/perl
#############################################################################
# $Id: OPeNDAP.pm,v 1.9 2015/02/18 20:38:28 eseiler Exp $
# -@@@ aGiovanni_DataAccess Version: $Name:  $
#############################################################################
#
# Module for obtaining OPeNDAP subsetting URLs from OPeNDAP full-data URLS,

# given spatial and temporal criteria
#
package DataAccess::OPeNDAP;

use 5.008008;
use strict;
use warnings;

use vars '$AUTOLOAD';
use LWP::UserAgent;
use HTTP::Cookies;
use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::Simple;
use File::Basename;
use Date::Parse;
use DateTime;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DataAccess::OPeNDAP ':all';
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

# Constructor
sub new() {
    my ( $class, %input ) = @_;

    my $self = {};

    # Constructor needs FILE_LIST with at least one OPeNDAP URL,
    # or pre-found dimension information

    my $variables           = $input{VARIABLES};
    my $urls                = $input{URLS};
    my $metadata            = $input{METADATA};
    my $format              = $input{FORMAT};
    my $startDate           = $input{START};
    my $endDate             = $input{END};
    my $bbox                = $input{BBOX};
    my $nonUniformVariables = $input{NON_UNIFORM_VARIABLES};
    my $debug               = $input{DEBUG};
    my $compare             = $input{COMPARE};

    unless ( ( defined $urls )
        && ( ( defined $variables ) || ( defined $metadata ) ) )
    {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE}
            = "Must provide URLS and either VARIABLES or METADATA";
        return bless( $self, $class );
    }

    $self->{_DEBUG} = $debug if $debug;

    if ( defined $metadata ) {
        unless ($metadata) {
            $self->{_ERROR_TYPE}    = 2;
            $self->{_ERROR_MESSAGE} = "METADATA must be a non-empty string";
            return bless( $self, $class );
        }
    }
    else {

        # Unless metadata was provided, determine ddx url from first
        # granule, read and parse ddx, and get metadata from ddx
        unless ( ( ref $variables ) eq 'ARRAY' ) {
            $self->{_ERROR_TYPE}    = 3;
            $self->{_ERROR_MESSAGE} = "VARIABLES must be an array reference";
            return bless( $self, $class );
        }
        unless ( ( ref $urls ) eq 'ARRAY' ) {
            $self->{_ERROR_TYPE}    = 4;
            $self->{_ERROR_MESSAGE} = "URLS must be an array reference";
            return bless( $self, $class );
        }
    }

    $self->{_VARIABLES} = $variables;
    $self->{_URLS}      = $urls;
    $format = '' unless defined $format;
    my $typeSuffix
        = ( $format eq 'native' ) ? ''
        : ( $format eq 'netCDF' )  ? '.nc'
        : ( $format eq 'netCDF4' ) ? '.dap.nc4'
        : ( $format eq 'DODS' )    ? '.dods'
        :                            '.ascii';
    $self->{_TYPE_SUFFIX} = $typeSuffix;
    $self->{_START}       = $startDate;
    $self->{_END}         = $endDate;
    my $uniformVariables = ( defined $nonUniformVariables ) ? 0 : 1;
    $self->{_UNIFORM_VARIABLES} = $uniformVariables;
    if ( defined( $input{CREDENTIALS} ) &&
         ( ref( $input{CREDENTIALS} ) eq 'HASH' ) ) {
        $self->{_CREDENTIALS} = $input{CREDENTIALS};
    }
    if ( defined $metadata ) {
        # If catalog metadata that was obtained from OPeNDAP is provided,
        # include it, and we won't need to obtain any more metadata from
        # OPeNDAP unless we have time-splittable dimensions.
        unless ( _unserializeMetadata( $self, $metadata ) ) {
            $self->{_ERROR_TYPE}    = 2;
            $self->{_ERROR_MESSAGE} = "Could not process METADATA";
            return bless( $self, $class );
        }
    }
    else {

        my $ua = LWP::UserAgent->new();
        if ( defined( $self->{_CREDENTIALS} ) ) {

            # If credentials were provided, set the credentials in the user agent
            # for each combination of location and realm.
            foreach my $netloc ( keys %{$input{CREDENTIALS}} ) {
                foreach my $realm ( keys %{$input{CREDENTIALS}->{$netloc}} ) {
                    my $user = $input{CREDENTIALS}->{$netloc}->{$realm}->{DOWNLOAD_USER};
                    my $cred = $input{CREDENTIALS}->{$netloc}->{$realm}->{DOWNLOAD_CRED};
                    $ua->credentials( $netloc, $realm, $user, $cred );
                }
            }

            # Provide a place for the user agent to store cookies that are set
            # when basic authentication is performed. This facilitates access
            # to data that requires Earthdata Login authentication.
            my $cookies = HTTP::Cookies->new();
            $ua->cookie_jar($cookies);
        }

        #        $self->{_USER_AGENT} = $ua;

        my $od_url = $urls->[0];
        my ( $opendapDoc, $errType, $errMsg )
            = _getOpenDapDoc( $od_url, $ua );
        if ( defined $errType ) {
            $self->{_ERROR_TYPE}    = $errType;
            $self->{_ERROR_MESSAGE} = $errMsg;
            return bless( $self, $class );
        }
        my $xpc = getXPathContext($opendapDoc);

        #        $self->{_OPENDAP_DOC} = $opendapDoc;
        #        $self->{_XPC} = $xpc;

        my $variableDimsOldMethod;
        my $errorsOldMethod;
        if ($compare) {
            ( $variableDimsOldMethod, $errorsOldMethod )
                = _extractVariableDimsOldMethod( $variables,
                $uniformVariables, $opendapDoc, $xpc );
            if ( ( ref($errorsOldMethod) eq 'ARRAY' ) && (@$errorsOldMethod) )
            {
                $self->{_ERROR_TYPE} = 8;
                $self->{_ERROR_MESSAGE} = join( "\n", @$errorsOldMethod );
                return bless( $self, $class );
            }
        }
        my $variableDims;
        my $errors;
        ( $variableDims, $errors )
            = _extractVariableDims( $variables, $uniformVariables,
            $opendapDoc, $xpc );
        if ( ( ref($errors) eq 'ARRAY' ) && (@$errors) ) {
            $self->{_ERROR_TYPE} = 8;
            $self->{_ERROR_MESSAGE} = join( "\n", @$errors );
            return bless( $self, $class );
        }

        $self->{_VARIABLE_DIMS_OLD_METHOD} = $variableDimsOldMethod;
        $self->{_VARIABLE_DIMS}            = $variableDims;
        my ( $latDims, $longDims ) = _extractLatLongDims( $opendapDoc, $xpc );
        $self->{_LAT_DIMS}  = $latDims;
        $self->{_LONG_DIMS} = $longDims;
        my $timeDims = _extractTimeDims( $opendapDoc, $xpc );
        $self->{_TIME_DIMS} = $timeDims if defined $timeDims;
        my $latLongIndexes;
        ( $latLongIndexes, $errors )
            = _determineLatLongIndexes( $latDims, $longDims, $od_url, $ua,
            $bbox );

        if ( ( ref($errors) eq 'ARRAY' ) && (@$errors) ) {
            $self->{_ERROR_TYPE} = 9;
            $self->{_ERROR_MESSAGE} = join( "\n", @$errors );
            return bless( $self, $class );
        }
        $self->{_LAT_LONG_INDEXES} = $latLongIndexes;

        my $timeSplittableDimension
            = timeSplittableDimension( $variableDims, $timeDims );
        $self->{_TIME_SPLITTABLE_DIMENSION} = $timeSplittableDimension
            if defined $timeSplittableDimension;

        my $timeIndexes;
        ( $timeIndexes, $errors )
            = _determineTimeIndexes( $variableDims, $timeDims, $od_url, $ua,
            $startDate, $endDate, $timeSplittableDimension, $typeSuffix );
        if ( ( ref($errors) eq 'ARRAY' ) && (@$errors) ) {
            $self->{_ERROR_TYPE} = 9;
            $self->{_ERROR_MESSAGE} = join( "\n", @$errors );
            return bless( $self, $class );
        }

        $self->{_TIME_INDEXES} = $timeIndexes;

        # Save metadata in a serialized form
        my $metadataAttributes = [
            '_VARIABLE_DIMS',    '_LAT_DIMS',
            '_LONG_DIMS',        '_TIME_DIMS',
            '_LAT_LONG_INDEXES', '_TIME_SPLITTABLE_DIMENSION',
            '_TIME_INDEXES'
        ];
        $self->{_METADATA} = _serializeMetadata( $self, $metadataAttributes );
    }
    return bless( $self, $class );
}

sub _getOpenDapDoc {
    my ( $od_url, $ua ) = @_;

    my $errorType;
    my $message;
    my $opendapDOM;
    my $opendapDoc;

    my $ddx_url  = getDdxUrl($od_url);
    my $response = $ua->get($ddx_url);
    unless ( $response->is_success ) {
        $errorType = 5;
        $message = "Error getting $ddx_url: " . $response->status_line . "\n";
        return ( $opendapDoc, $errorType, $message );
    }
    my $ddx = $response->content();
    unless ($ddx) {
        $errorType = 6;
        $message   = "No content in $ddx_url\n";
        return ( $opendapDoc, $errorType, $message );
    }
    my $parser = XML::LibXML->new();
    eval { $opendapDOM = $parser->parse_string($ddx); };
    if ($@) {
        $errorType = 7;
        $message   = "Unable to parse ddx from $od_url\n";
        return ( $opendapDoc, $errorType, $message );
    }
    $opendapDoc = $opendapDOM->documentElement();
    return ( $opendapDoc, $errorType, $message );
}

sub getDdxUrl {
    my ($od_url) = @_;

    if (   ( $od_url =~ /\/ncml/ )
        && ( $od_url !~ /\.ncml$/ )
        && ( $od_url !~ /\.ncml\.html$/ ) )
    {

        # If '/ncml' is found in the path, assume an extension
        # of .ncml should be used
        $od_url .= '.ncml';
    }
    my $ddx_url;
    if ( $od_url =~ /\.html$/ ) {
        ( $ddx_url = $od_url ) =~ s/\.html$/.ddx/;
    }
    else {
        $ddx_url = $od_url . ".ddx";
    }

    return $ddx_url;
}

# Performs the same function as the _extractVariableDims method, but
# uses logic that finds dimensions by giving priority to the Array Attribute
# named 'coordinates' rather than the Array element named 'dimension'. Use
# of this method is deprecated.
sub _extractVariableDimsOldMethod {
    my ( $variables, $uniformVariables, $opendapDoc, $xpc ) = @_;

    #    DEBUG((caller(0))[3]);

    my @messages;
    my $variableDims = {};
    if ( defined $variables ) {
        foreach my $variable (@$variables) {
            my $variableName = $variable;
            my @dimensionSelections;
            my %dimensionSelections;

            # If variable contains one or more slashes, then assume it is of
            # the form <variableName>/<dimensionSelection>, i.e. that it
            # specifies a range of indexes for one or more of its dimensions,
            # where <dimensionSelection> is of the form
            # name or name[start] or name[start:end] or name[start:stride:end]
            ( $variableName, @dimensionSelections ) = split '/', $variable;
            foreach my $dimensionSelection (@dimensionSelections) {
                $dimensionSelections{$1} = $2
                    if $dimensionSelection =~ /(\w+)(\[\d+(?::\d+){0,2}\])?/;
            }

            # Check that an 'Array' node with a name attribute equal to the
            # selected subset layer/variable can be found
            my @ArrayNodes = $xpc->findnodes(
                qq(//default:Array[\@name='$variableName']));
            if (@ArrayNodes) {
                if ( @ArrayNodes > 1 ) {
                    push @messages,
                          "Subset variable $variableName found "
                        . scalar(@ArrayNodes)
                        . " times";
                }
                else {
                    my @dimNames;
                    my %dimSizes;

                    # To find dimension names, look first for an Attribute
                    # named 'coordinates', and if not found, look for
                    # all 'dimension' elements. (Note that
                    # _extractVariableDims looks for 'dimension' elements
                    # first, and only looks for an Attribute named
                    # 'coordinates" if none are found.)

                    # Look for an Attribute named 'coordinates'
                    my ($coordinatesNode) = $xpc->findnodes(
                        qq(./default:Attribute[\@name='coordinates']/default:value),
                        $ArrayNodes[0]
                    );
                    if ($coordinatesNode) {

                        # Find the name of all coordinates associated with
                        # variable $variable.
                        my $coordinatesStr = $coordinatesNode->textContent;
                        @dimNames = split( / /, $coordinatesStr );
                    }
                    else {

                        # Find the name of all dimensions associated with
                        # variable $variable.
                        my @dimNodes
                            = $xpc->findnodes( qq(./default:dimension),
                            $ArrayNodes[0] );
                        push @messages,
                            "Subset variable $variableName does not have a dimension"
                            unless @dimNodes;
                        foreach my $dimNode (@dimNodes) {
                            my $dimName = $dimNode->getAttribute('name');

                            next unless defined $dimName;

                            # Workaround for a TDS bug where a dimension
                            # can have an empty 'name' attribute
                            $dimName = '_null_' if ( $dimName eq '' );

                            if ($dimName) {
                                push @dimNames, $dimName;
                                my $dimSize = $dimNode->getAttribute('size');
                                $dimSizes{$dimName} = $dimSize;
                            }
                        }
                    }
                    foreach my $dimName (@dimNames) {

                        # Determine if a variable exists whose name is the
                        # same as the name of the dimension
                        my @dimArrayNodes = $xpc->findnodes(
                            qq(//default:Array[\@name='$dimName']));

                        unless (@dimArrayNodes) {

                            # No variable exists for the dimension
                            if ( exists $dimSizes{$dimName} ) {

                                # If we know the size of the dimension
                                # element, use that to determine the
                                # maximum index, but set noDimVar to
                                # indicate that no variable with name
                                # $dimName exists
                                push @{ $variableDims->{$variableName} },
                                    {
                                    'name'     => $dimName,
                                    'maxind'   => $dimSizes{$dimName} - 1,
                                    'noDimVar' => 1
                                    };
                                next;
                            }
                            else {

                                # Otherwise ignore dimensions for which no
                                # variable exists
                            }
                            next;
                        }

                        # Expect any dimension variable (Array element)
                        # to have one child 'dimension' element.
                        # Obtain the size of the dimension from that element.
                        foreach my $dimArrayNode (@dimArrayNodes) {
                            my ($dimNode)
                                = $xpc->findnodes( qq(./default:dimension),
                                $dimArrayNode );
                            next unless $dimNode;
                            my $dimSize = $dimNode->getAttribute('size');
                            if ( exists $dimensionSelections{$dimName} ) {
                                push @{ $variableDims->{$variableName} },
                                    {
                                    'name'   => $dimName,
                                    'maxind' => $dimSize - 1,
                                    'selectedIndexes' =>
                                        $dimensionSelections{$dimName}
                                    };
                            }
                            else {
                                push @{ $variableDims->{$variableName} },
                                    {
                                    'name'   => $dimName,
                                    'maxind' => $dimSize - 1
                                    };
                            }
                        }
                    }
                }
                unless ( keys %$variableDims ) {
                    push @messages,
                        "No dimensions found for variable $variable";
                }
            }
            else {
                push @messages, "Subset variable $variableName not found"
                    if $uniformVariables;
            }
        }
    }
    else {
        my %variableSizes;

        # No subsetting variables were selected, so assume all variables
        # are desired, possibly for spatial/temporal subsetting
        my @ArrayNodes = $xpc->findnodes(qq(//default:Array));
        if (@ArrayNodes) {
            foreach my $ArrayNode (@ArrayNodes) {
                my $variable = $ArrayNode->getAttribute('name');
                my (@dimNodes)
                    = $xpc->findnodes( qq(./default:dimension), $ArrayNode );
                if ( @dimNodes == 1 ) {
                    my $size = $dimNodes[0]->getAttribute('size');
                    $variableSizes{$variable} = $size if $size;
                }
                my ($coordinatesNode) = $xpc->findnodes(
                    qq(./default:Attribute[\@name='coordinates']/default:value),
                    $ArrayNode
                );
                if ($coordinatesNode) {

                    # Find the name of all coordinates associated with
                    # variable $variable.
                    my $coordinatesStr = $coordinatesNode->textContent;
                    foreach my $dimName ( split( / /, $coordinatesStr ) ) {
                        push @{ $variableDims->{$variable} },
                            { 'name' => $dimName };
                    }
                }
                else {

                    # Find the name of all dimensions associated with
                    # the variable
                    my @dimNodes = $xpc->findnodes( qq(./default:dimension),
                        $ArrayNode );

                    # Ignore any Array without a dimension child
                    next unless @dimNodes;
                    my $variable = $ArrayNode->getAttribute('name');
                    foreach my $dimNode (@dimNodes) {
                        my $dimName = $dimNode->getAttribute('name');
                        next if $dimName eq $variable;
                        my $dimSize = $dimNode->getAttribute('size');
                        push @{ $variableDims->{$variable} },
                            { 'name' => $dimName, 'maxind' => $dimSize - 1 };
                    }
                }
            }

            # Find dimension sizes for variables that have coordinates
            foreach my $variable ( keys %$variableDims ) {
                foreach my $attribute ( @{ $variableDims->{$variable} } ) {
                    unless ( exists $attribute->{maxind} ) {
                        my $name = $attribute->{name};
                        if ( exists $variableSizes{$name} ) {
                            $attribute->{maxind} = $variableSizes{$name} - 1;
                        }
                        else {
                            push @messages,
                                "No size found for dimension $name of variable $variable";
                        }
                    }
                }
            }
        }
    }

    return ( $variableDims, \@messages );
}

sub _extractVariableDims {
    my ( $variables, $uniformVariables, $opendapDoc, $xpc ) = @_;

    #    DEBUG((caller(0))[3]);

    my @messages;
    my $variableDims = {};
    if ( defined $variables ) {
        foreach my $variable (@$variables) {
            my $variableName = $variable;
            my @dimensionSelections;
            my %dimensionSelections;

            # If variable contains one or more slashes, then assume it is of
            # the form <variableName>/<dimensionSelection>, i.e. that it
            # specifies a range of indexes for one or more of its dimensions,
            # where <dimensionSelection> is of the form
            # name or name[start] or name[start:end] or name[start:stride:end]
            ( $variableName, @dimensionSelections ) = split '/', $variable;
            foreach my $dimensionSelection (@dimensionSelections) {
                $dimensionSelections{$1} = $2
                    if $dimensionSelection =~ /(\w+)(\[\d+(?::\d+){0,2}\])?/;
            }

            # Check that an 'Array' node with a name attribute equal to the
            # selected subset layer/variable can be found
            my @ArrayNodes = $xpc->findnodes(
                qq(//default:Array[\@name='$variableName']));
            if (@ArrayNodes) {
                if ( @ArrayNodes > 1 ) {
                    push @messages,
                          "Subset variable $variableName found "
                        . scalar(@ArrayNodes)
                        . " times";
                }
                else {
                    my @dimNames;
                    my %dimSizes;

                    # To find dimension names, look first for all dimension
                    # elements, and if none are found, look for an Attribute
                    # named 'coordinates'

                    # Find the name of all dimensions associated with
                    # variable $variable.
                    my @dimNodes = $xpc->findnodes( qq(./default:dimension),
                        $ArrayNodes[0] );
                    if (@dimNodes) {
                        foreach my $dimNode (@dimNodes) {
                            my $dimName = $dimNode->getAttribute('name');

                            next unless defined $dimName;

                            # Workaround for a TDS bug where a dimension
                            # can have an empty 'name' attribute
                            $dimName = '_null_' if ( $dimName eq '' );

                            if ($dimName) {
                                push @dimNames, $dimName;
                                my $dimSize = $dimNode->getAttribute('size');
                                $dimSizes{$dimName} = $dimSize;
                            }
                        }
                    }
                    else {

                        # Look for an Attribute named 'coordinates'
                        my ($coordinatesNode) = $xpc->findnodes(
                            qq(./default:Attribute[\@name='coordinates']/default:value),
                            $ArrayNodes[0]
                        );
                        if ($coordinatesNode) {

                            # Find the name of all coordinates associated
                            # with variable $variable.
                            my $coordinatesStr
                                = $coordinatesNode->textContent;
                            @dimNames = split( / /, $coordinatesStr );
                        }
                        push @messages,
                            "Subset variable $variableName does not have a dimension"
                            unless @dimNames;
                    }

                    foreach my $dimName (@dimNames) {

                        # Determine if a variable exists whose name is the
                        # same as the name of the dimension
                        my @dimArrayNodes = $xpc->findnodes(
                            qq(//default:Array[\@name='$dimName']));

                        unless (@dimArrayNodes) {

                            # No variable exists for the dimension
                            if ( exists $dimSizes{$dimName} ) {

                                # If we know the size of the dimension
                                # element, use that to determine the
                                # maximum index, but set noDimVar to
                                # indicate that no variable with name
                                # $dimName exists
                                push @{ $variableDims->{$variableName} },
                                    {
                                    'name'     => $dimName,
                                    'maxind'   => $dimSizes{$dimName} - 1,
                                    'noDimVar' => 1
                                    };
                                next;
                            }
                            else {

                                # Otherwise ignore dimensions for which no
                                # variable exists
                            }
                            next;
                        }

                        # Expect any dimension variable (Array element)
                        # to have one child 'dimension' element.
                        # Obtain the size of the dimension from that element.
                        foreach my $dimArrayNode (@dimArrayNodes) {
                            my ($dimNode)
                                = $xpc->findnodes( qq(./default:dimension),
                                $dimArrayNode );
                            next unless $dimNode;
                            my $dimSize = $dimNode->getAttribute('size');
                            if ( exists $dimensionSelections{$dimName} ) {
                                push @{ $variableDims->{$variableName} },
                                    {
                                    'name'   => $dimName,
                                    'maxind' => $dimSize - 1,
                                    'selectedIndexes' =>
                                        $dimensionSelections{$dimName}
                                    };
                            }
                            else {
                                push @{ $variableDims->{$variableName} },
                                    {
                                    'name'   => $dimName,
                                    'maxind' => $dimSize - 1
                                    };
                            }
                        }
                    }
                }
                unless ( keys %$variableDims ) {
                    push @messages,
                        "No dimensions found for variable $variable";
                }
            }
            else {
                push @messages, "Subset variable $variableName not found"
                    if $uniformVariables;
            }
        }
    }
    else {
        my %variableSizes;

        # No subsetting variables were selected, so assume all variables
        # are desired, possibly for spatial/temporal subsetting
        my @ArrayNodes = $xpc->findnodes(qq(//default:Array));
        if (@ArrayNodes) {
            foreach my $ArrayNode (@ArrayNodes) {
                my $variable = $ArrayNode->getAttribute('name');

                # Find the name of all dimensions associated with the Array
                my (@dimNodes)
                    = $xpc->findnodes( qq(./default:dimension), $ArrayNode );
                if (@dimNodes) {
                    if ( @dimNodes == 1 ) {
                        my $size = $dimNodes[0]->getAttribute('size');
                        $variableSizes{$variable} = $size if $size;
                    }
                    foreach my $dimNode (@dimNodes) {
                        my $dimName = $dimNode->getAttribute('name');
                        next if $dimName eq $variable;
                        my $dimSize = $dimNode->getAttribute('size');
                        push @{ $variableDims->{$variable} },
                            { 'name' => $dimName, 'maxind' => $dimSize - 1 };
                    }
                }
                else {
                    my ($coordinatesNode) = $xpc->findnodes(
                        qq(./default:Attribute[\@name='coordinates']/default:value),
                        $ArrayNode
                    );
                    if ($coordinatesNode) {

                        # Find the name of all coordinates associated with
                        # variable $variable.
                        my $coordinatesStr = $coordinatesNode->textContent;
                        foreach my $dimName ( split( / /, $coordinatesStr ) )
                        {
                            push @{ $variableDims->{$variable} },
                                { 'name' => $dimName };
                        }
                    }
                }
            }

            # Find dimension sizes for variables that have coordinates
            foreach my $variable ( keys %$variableDims ) {
                foreach my $attribute ( @{ $variableDims->{$variable} } ) {
                    unless ( exists $attribute->{maxind} ) {
                        my $name = $attribute->{name};
                        if ( exists $variableSizes{$name} ) {
                            $attribute->{maxind} = $variableSizes{$name} - 1;
                        }
                        else {
                            push @messages,
                                "No size found for dimension $name of variable $variable";
                        }
                    }
                }
            }
        }
    }

    return ( $variableDims, \@messages );
}

sub _extractLatLongDims {
    my ( $opendapDoc, $xpc ) = @_;

    # Get the names and sizes of the latitude and longitude dimensions

    #    DEBUG((caller(0))[3]);

    my @messages;
    my $latDims  = {};
    my $longDims = {};
    my ( $latDimName,  $latDimSize,  $latDimScaleFactor,  $latDimOffset );
    my ( $longDimName, $longDimSize, $longDimScaleFactor, $longDimOffset );

    # Find latitude and longitude dimensions by using a CF-1 convention.
    # Find all 'Array' nodes with an 'Attribute' child that has a 'name'
    # attribute equal to 'units' where the Attribute node has a
    # 'value' child equal to 'degrees_north'
    my @latArrayNodes
        = $xpc->findnodes(
        q(//default:Array[default:Attribute[@name='units'][default:value='degrees_north']])
        );
    unless (@latArrayNodes) {
        @latArrayNodes
            = $xpc->findnodes(
            q(//default:Array[default:Attribute[@name='units'][default:value='"degrees_north"']])
            );
    }
    unless (@latArrayNodes) {
        @latArrayNodes
            = $xpc->findnodes(
            q(//default:Array[default:Attribute[@name='units'][default:value='degree_north']])
            );
    }
    if (@latArrayNodes) {
        my $latArrayNode = $latArrayNodes[0];
        ( my $latDimNode )
            = $latArrayNode->getChildrenByTagNameNS(
            $xpc->lookupNs('default'), 'dimension' );
        $latDimName = $latDimNode->getAttribute('name');
        $latDimSize = $latDimNode->getAttribute('size');
        ( my $scaleFactorNode )
            = $xpc->findnodes(
            q(./default:Attribute[@name='scale_factor']/default:value),
            $latArrayNode );
        $latDimScaleFactor
            = $scaleFactorNode ? $scaleFactorNode->textContent : 1.0;
        ( my $offsetNode )
            = $xpc->findnodes(
            q(./default:Attribute[@name='add_offset']/default:value),
            $latArrayNode );
        $latDimOffset = $offsetNode ? $offsetNode->textContent : 0.0;
        $latDims = {
            'name'        => $latDimName,
            'size'        => $latDimSize,
            'scaleFactor' => $latDimScaleFactor,
            'offset'      => $latDimOffset
        };
    }
    else {
        push @messages, "Latitude dimension not found";
    }

    # Find all 'Array' nodes with an 'Attribute' child that has a 'name'
    # attribute equal to 'units' where the Attribute node has a
    # 'value' child equal to 'degrees_east'
    my @longArrayNodes
        = $xpc->findnodes(
        q(//default:Array[default:Attribute[@name='units'][default:value='degrees_east']])
        );
    unless (@longArrayNodes) {
        @longArrayNodes
            = $xpc->findnodes(
            q(//default:Array[default:Attribute[@name='units'][default:value='"degrees_east"']])
            );
    }
    unless (@longArrayNodes) {
        @longArrayNodes
            = $xpc->findnodes(
            q(//default:Array[default:Attribute[@name='units'][default:value='degree_east']])
            );
    }

    if (@longArrayNodes) {
        my $longArrayNode = $longArrayNodes[0];
        ( my $longDimNode )
            = $longArrayNode->getChildrenByTagNameNS(
            $xpc->lookupNs('default'), 'dimension' );
        $longDimName = $longDimNode->getAttribute('name');
        $longDimSize = $longDimNode->getAttribute('size');
        ( my $scaleFactorNode )
            = $xpc->findnodes(
            q(./default:Attribute[@name='scale_factor']/default:value),
            $longArrayNode );
        $longDimScaleFactor
            = $scaleFactorNode ? $scaleFactorNode->textContent : 1.0;
        ( my $offsetNode )
            = $xpc->findnodes(
            q(./default:Attribute[@name='add_offset']/default:value),
            $longArrayNode );
        $longDimOffset = $offsetNode ? $offsetNode->textContent : 0.0;
        $longDims = {
            'name'        => $longDimName,
            'size'        => $longDimSize,
            'scaleFactor' => $longDimScaleFactor,
            'offset'      => $longDimOffset
        };
    }
    else {
        push @messages, "Longitude dimension not found";
    }

    #    print "$_\n" for @messages;

    return ( $latDims, $longDims );
}

sub _extractTimeDims {
    my ( $opendapDoc, $xpc ) = @_;

    # Get the name and size of the time dimensions

    #    DEBUG((caller(0))[3]);

    my $timeDims = {};

    # Find time dimension by using a CF-1 convention.
    # Find all 'Array' nodes with an 'Attribute' child that has a 'name'
    # attribute equal to 'units' where the Attribute node has a
    # 'value' child that contains the string " since ", for example
    # "days since 1895-01-01 00:00:00".
    my @timeArrayNodes
        = $xpc->findnodes(
        q(//default:Array[default:Attribute[@name='units'][contains(default:value, ' since ')]])
        );

#    unless (@timeArrayNodes) {
#        @timeArrayNodes = $xpc->findnodes(q(//default:Map[default:Attribute[@name='units'][contains(default:value, ' since ')]]));
#    }
    return unless @timeArrayNodes;

    my ( $timeDimName,   $timeDimSize,   $timeDimUnits );
    my ( $boundsVarName, $boundsVarSize, $boundsVarUnits );
    foreach my $timeArrayNode (@timeArrayNodes) {
        ( my $timeUnitsNode )
            = $xpc->findnodes(
            q(./default:Attribute[@name='units']/default:value),
            $timeArrayNode );
        $timeDimUnits = $timeUnitsNode->textContent if $timeUnitsNode;
        $timeDimUnits =~ s/"//g;
        my @timeDimNodes = $timeArrayNode->getChildrenByTagNameNS(
            $xpc->lookupNs('default'), 'dimension' );
        if ( @timeDimNodes == 1 ) {

            # Time variable has a single dimension
            my $timeDimNode = $timeDimNodes[0];
            $timeDimName = $timeDimNode->getAttribute('name');
            $timeDimSize = $timeDimNode->getAttribute('size');

            # Check if this time variable has an Attribute whose name
            # is "bounds", indicating that it is associated with time bounds
            ( my $timeBoundsNode )
                = $xpc->findnodes(
                q(./default:Attribute[@name='bounds']/default:value),
                $timeArrayNode );
            if ($timeBoundsNode) {

                # This time variable is associated with time bounds.
                # Get the name of the bounds variable and find it.
                $boundsVarName = $timeBoundsNode->textContent;
                ( my $timeBndsNode )
                    = $xpc->findnodes(
                    qq(//default:Array[\@name='$boundsVarName']));
                if ($timeBndsNode) {

# Found the time bounds variable.
# Verify that it has a dimension whose name is "bnds".
#                    (my $timeBndsDimNode) = $xpc->findnodes(q(./default:dimension[@name='bnds']), $timeBndsNode);
#                    if ($timeBndsDimNode) {
                    $boundsVarSize            = $timeDimSize;
                    $boundsVarUnits           = $timeDimUnits;
                    $timeDims->{$timeDimName} = {
                        'size'           => $timeDimSize,
                        'units'          => $timeDimUnits,
                        'boundsVarName'  => $boundsVarName,
                        'boundsVarSize'  => $boundsVarSize,
                        'boundsVarUnits' => $boundsVarUnits
                    };

                    #                    }
                }
            }
            else {
                $timeDims->{$timeDimName} = {
                    'size'  => $timeDimSize,
                    'units' => $timeDimUnits
                };
            }
        }
        else {

            # Time variable has multiple dimensions. Assume that it
            # is a bounds variable
            next;
        }
    }

    return $timeDims;
}

sub getDimValues {
    my ( $fileUrl, $dimName, $dimSize, $ua ) = @_;

    my @dimVals;

    # Obtain a list of values for a dimension array by requesting the ASCII
    # values for the entire array
    #    DEBUG((caller(0))[3]);
    # Make sure that the OPeNDAP URL is not for the html resource
    $fileUrl =~ s/\.html$//;
    my $dimValsUrl
        = $fileUrl . '.ascii?' . $dimName . '[0:' . ( $dimSize - 1 ) . ']';

    #    DEBUG((caller(0))[3], " Requesting $dimValsUrl");
    my $response = $ua->get($dimValsUrl);

    #    DEBUG((caller(0))[3], " Got response from $dimValsUrl");
    unless ( $response->is_success ) {
        my $message
            = "Error getting $dimValsUrl: " . $response->status_line . "\n";
        return \@dimVals, $message;
    }

    my @dimText = split( '\n', $response->content() );

    # Expect the values to be in the last line of the response
    @dimVals = split( ', ', $dimText[-1] );

    # Remove any non-number from beginning of list
    shift @dimVals
        unless $dimVals[0]
            =~ /^\s*([-+]?(?:(?:[0-9]+\.?[0-9]*)|(?:[0-9]*\.?[0-9]+)))\s*$/;

    return \@dimVals;
}

sub _determineLatLongIndexes {
    my ( $latDims, $longDims, $odUrl, $ua, $bbox ) = @_;

    # Determine range of lat./long. indexes corresponding to spatial subset
    # bounding box

    my $indexes;
    my @messages;

    #    DEBUG((caller(0))[3]);
    my $latDimName;
    my $longDimName;
    my $latDimSize;
    my $longDimSize;
    my $latDimScaleFactor;
    my $longDimScaleFactor;
    my $latDimOffset;
    my $longDimOffset;

    $latDimName         = $latDims->{name};
    $latDimSize         = $latDims->{size};
    $latDimScaleFactor  = $latDims->{scaleFactor};
    $latDimOffset       = $latDims->{offset};
    $longDimName        = $longDims->{name};
    $longDimSize        = $longDims->{size};
    $longDimScaleFactor = $longDims->{scaleFactor};
    $longDimOffset      = $latDims->{offset};

    # If there is no bounding box, set the index range to be the
    # range of all values
    unless ( defined $bbox ) {
        if (not defined $latDimSize or not defined $longDimSize) {
             my $errMsg = "\nLatitude and or Longitude dimension was not discovered\n";
             push @messages, $errMsg;
             $indexes = [ 0, -1, 0, -1 ];
             return ( $indexes, \@messages );
        }

        $indexes = [ 0, $latDimSize - 1, 0, $longDimSize - 1 ];
        return ( $indexes, \@messages );
    }

    my $reverseLatOrder;
    my $reverseLongOrder;
    my $errMsg;

    # Get list of grid cell center latitudes, in decreasing order
    my $lats;
    ( $lats, $errMsg )
        = getDimValues( $odUrl, $latDimName, $latDimSize, $ua );
    if ($errMsg) {
        push @messages, $errMsg;
        return ( $indexes, \@messages );
    }
    my @lats         = @$lats;
    my $latHalfWidth = ( $lats[0] - $lats[1] ) * $latDimScaleFactor / 2.0;

    # If list is not in decreasing order, reverse the order
    if ( $latHalfWidth < 0.0 ) {
        $latHalfWidth    = -$latHalfWidth;
        @lats            = reverse @lats;
        $reverseLatOrder = 1;
    }

    # Get list of grid cell center longitudes, in increasing order
    my $longs;
    ( $longs, $errMsg )
        = getDimValues( $odUrl, $longDimName, $longDimSize, $ua );
    if ($errMsg) {
        push @messages, $errMsg;
        return ( $indexes, \@messages );
    }
    my @longs         = @$longs;
    my $longHalfWidth = ( $longs[1] - $longs[0] ) * $longDimScaleFactor / 2.0;

    # If list is not in increasing order, reverse the order
    if ( $longHalfWidth < 0.0 ) {
        $longHalfWidth    = -$longHalfWidth;
        @longs            = reverse @longs;
        $reverseLongOrder = 1;
    }

    my ( $minBboxLat, $minBboxLong, $maxBboxLat, $maxBboxLong ) = @$bbox;

    # Determine the range of latitude indices within the bounding box
    # $maxLatInd is the index of the maximum subset latitude
    # $minLatInd is the index of minimum subset latitude
    # Subset latitude indexes will range from $maxLatInd up to $minLatInd
    my ( $minLatInd, $maxLatInd );
    for ( my $latInd = 0; $latInd < $latDimSize; $latInd++ ) {

        # Find first (northernmost) lat. grid cell center south of the
        # maximum box latitude
        my $latValue
            = ( $lats[$latInd] * $latDimScaleFactor ) + $latDimOffset;
        next if ( $latValue > $maxBboxLat );
        unless ( defined $maxLatInd ) {
            if ($latInd) {
                if ( ( $maxBboxLat - $latValue ) > $latHalfWidth ) {

                    # We are not at the northernmost grid cell, and
                    # the lat. grid cell center is within the max. box lat.
                    # by more than half a grid cell
                    $maxLatInd = $latInd - 1;
                }
                else {

                    # We are not at the northernmost grid cell, and
                    # the lat. grid cell center is within the max. box lat.
                    # by half a grid cell or less
                    $maxLatInd = $latInd;
                }
            }
            else {

                # We are at the northernmost grid cell, and
                # the lat. grid cell center is not beyond the max. box lat.
                # by more than a half a grid cell
                $maxLatInd = 0
                    if ( $minBboxLat - $latValue ) < $latHalfWidth;
            }
        }

        # Proceed until a lat. grid cell center is south of the min. box lat.
        next if ( $latValue > $minBboxLat );
        if ($latInd) {
            if ( ( $minBboxLat - $latValue ) > $latHalfWidth ) {

                # We are not at the northernmost grid cell, and
                # the lat. grid cell center is more than half a grid cell
                # beyond the min. box lat.
                $minLatInd = $latInd - 1;
            }
            else {

                # We are not at the northernmost grid cell, and
                # the lat. grid cell center is beyond the min. box lat.
                # by half a grid cell or less
                $minLatInd = $latInd;
            }
        }
        else {

            # We are at the northernmost grid cell, and
            # the lat. grid cell center is beyond the min. box lat.
            # by half a grid cell or less
            $minLatInd = 0
                if ( $minBboxLat 
                - ( $lats[0] * $latDimScaleFactor )
                - $latDimOffset ) < $latHalfWidth;
        }
        last;
    }
    unless ( defined $maxLatInd ) {
        if (abs(  ( $lats[-1] * $latDimScaleFactor ) 
                - $latDimOffset
                    - $maxBboxLat
            ) < $latHalfWidth
            )
        {

            # The max. box lat. is beyond the southernmost lat. grid cell
            # center by a less than a half a cell.
            $maxLatInd = $latDimSize - 1;
            $minLatInd = $latDimSize - 1;
        }
    }
    unless ( defined $minLatInd ) {
        $minLatInd = $latDimSize - 1 if defined $maxLatInd;
    }

    # Determine the range of longitude indices within the bounding box
    # $maxLongInd is the index of the maximum subset longitude
    # $minLongInd is the index of minimum subset longitude
    # Subset longitude indexes will range from $minLongInd up to $maxLongInd
    my ( $minLongInd, $maxLongInd );
    for ( my $longInd = 0; $longInd < $longDimSize; $longInd++ ) {

        # Find first (westernmost) long. grid cell center within the box
        my $longValue
            = ( $longs[$longInd] * $longDimScaleFactor ) + $longDimOffset;
        next if ( $longValue < $minBboxLong );
        unless ( defined $minLongInd ) {
            if ($longInd) {
                if ( ( $longValue - $minBboxLong ) > $longHalfWidth ) {

                    # We are not at the westernmost grid cell, and
                    # the long. grid cell center is within the min. box long.
                    # by more than half a grid cell
                    $minLongInd = $longInd - 1;
                }
                else {

                    # We are not at the westernmost grid cell, and
                    # the long. grid cell center is within the min. box long.
                    # by half a grid cell or less
                    $minLongInd = $longInd;
                }
            }
            else {

                # We are at the westernmost grid cell, and
                # the long. grid cell center is not beyond the min. box long.
                # by more than half a grid cell
                $minLongInd = 0
                    if ( $longValue - $maxBboxLong ) < $longHalfWidth;
            }
        }

        # Proceed until a long. grid cell center is east of the max. box long.
        next if ( $longValue < $maxBboxLong );
        if ($longInd) {
            if ( ( $longValue - $maxBboxLong ) > $longHalfWidth ) {

                # We are not at the westernmost grid cell, and
                # the long. grid cell center is more than half a grid cell
                # beyond the max. box long.
                $maxLongInd = $longInd - 1;
            }
            else {

                # We are not at the westernmost grid cell, and
                # the long. grid cell center is beyond the max. box long
                # by half a grid cell or less
                $maxLongInd = $longInd;
            }
        }
        else {

            # We are at the westernmost grid cell, and
            # the long. grid cell center is beyond the max. box long
            # by half a grid cell or less
            $maxLongInd = 0 if ( $longValue - $maxBboxLong ) < $longHalfWidth;
        }
        last;
    }
    unless ( defined $minLongInd ) {
        if (abs(      $minBboxLong 
                    - ( $longs[-1] * $longDimScaleFactor )
                    - $longDimOffset
            ) < $longHalfWidth
            )
        {

            # The min. box long. is beyond the easternmost long. grid cell
            # center by a less than a half a cell.
            $minLongInd = $longDimSize - 1;
            $maxLongInd = $longDimSize - 1;
        }
    }
    unless ( defined $maxLongInd ) {
        $maxLongInd = $longDimSize - 1 if defined $minLongInd;
    }

    unless ( ( defined $maxLatInd ) && ( defined $minLatInd ) ) {
        push @messages,
            "No data found in latitude range $minBboxLat to $maxBboxLat";
    }
    unless ( ( defined $minLongInd ) && ( defined $maxLongInd ) ) {
        push @messages,
            "No data found in longitude range $minBboxLong to $maxBboxLong";
    }

    #        SSW::Utils::exitNoMatchException( \@messages ) if @messages;
    return ( $indexes, \@messages ) if @messages;

    if ($reverseLatOrder) {
        ( $maxLatInd, $minLatInd )
            = ( $latDimSize - $minLatInd - 1, $latDimSize - $maxLatInd - 1 );
    }
    if ($reverseLongOrder) {
        ( $maxLongInd, $minLongInd )
            = ( $longDimSize - $minLongInd - 1,
            $longDimSize - $maxLongInd - 1 );
    }
    $indexes = [ $maxLatInd, $minLatInd, $minLongInd, $maxLongInd ];

    return ( $indexes, \@messages );
}

sub _determineTimeIndexes {
    my ( $variableDims, $firstTimeDims, $odUrl, $ua, $subsetStart, $subsetEnd,
        $timeSplittableDimension, $typeSuffix )
        = @_;

    #    DEBUG((caller(0))[3]);

    #    return unless $timeDimName;
    #    return unless $odUrl;
    my $timeDims;
    my $timeIndexes;
    my @messages;

    if ($timeSplittableDimension) {

        # If a time dimension can be split by time, then
        # the splittable dimension may have units that vary from
        # one URL to the next, so we must extract the time dimensions
        # from each $odUrl, instead of relying on the time dimensions
        # being the same for every $odUrl
        my ( $opendapDoc, $errType, $errMsg ) = _getOpenDapDoc( $odUrl, $ua );
        if ($errMsg) {
            push @messages, $errMsg;
            return ( $timeIndexes, \@messages );
        }
        my $xpc = getXPathContext($opendapDoc);
        $timeDims = _extractTimeDims( $opendapDoc, $xpc );
    }
    else {
        $timeDims = $firstTimeDims;
    }

    foreach my $timeDimName ( keys %$timeDims ) {
        my $timeDimSize = $timeDims->{$timeDimName}->{size};
        if ( $timeDimSize == 1 ) {

            # The time dimension has only a single value, and
            # so cannot be subsetted
            $timeIndexes->{$timeDimName}->{indexes} = [ 0, 0 ];
        }
        else {
            my $timeDimUnits = $timeDims->{$timeDimName}->{units};

            # Make sure that the OPeNDAP URL is not for the html resource
            $odUrl =~ s/\.html$//;

            # Determine range of time indexes corresponding to
            # time range
            my $dimValsUrl
                = $odUrl
                . '.ascii?'
                . $timeDimName . '[0:1:'
                . ( $timeDimSize - 1 ) . ']';

            #            DEBUG((caller(0))[3], " Requesting $dimValsUrl");
            my $response = $ua->get($dimValsUrl);

         #            DEBUG((caller(0))[3], " Got response from $dimValsUrl");
            unless ( $response->is_success ) {

                # Handle OPeNDAP error
                @messages = "Cannot locate resource: $dimValsUrl";

                #                SSW::Utils::exitNoMatchException( $message );
                return ( $timeIndexes, \@messages );
            }

            my @dimText = split( '\n', $response->content() );

            # Get list of time values
            my @times = split( ', ', $dimText[-1] );
            shift @times if $times[0] =~ /[a-zA-Z]/;
            my $increment = ( $times[1] - $times[0] );

            # Obtain the time span of the data and the units the
            # span is measured in
            my ( $units, $spanStart ) = split( ' since ', $timeDimUnits );

            # Convert the start of the data time span to epoch time
            # in seconds
            my $dtSpanStart        = _dtObject($spanStart);
            my $spanStartEpochSecs = $dtSpanStart->epoch();

            # Convert the selected start of the subset time range
            # to epoch time in seconds
            my $dtSubsetStart
                = ( defined $subsetStart )
                ? _dtObject($subsetStart)
                : _dtObject($spanStart);
            my $subsetStartEpochSecs = $dtSubsetStart->epoch();

            # Convert the selected end of the subset time range
            # to epoch time in seconds
            my ( $dtSubsetEnd, $subsetEndEpochSecs );
            if ( defined $subsetEnd ) {
                $dtSubsetEnd        = _dtObject($subsetEnd);
                $subsetEndEpochSecs = $dtSubsetEnd->epoch();
            }

            # If a value was not specified for the end of the time range,
            # determine the index that corresponds to the latest time in the
            # data time span
            my ( $minTimeInd, $maxTimeInd );
            unless ( defined $subsetEndEpochSecs ) {
                $maxTimeInd = $timeDimSize - 1;
            }

            # Iterate through all of the values of the time dimension
            # to find the index of the first time that is greater than
            # or equal to the selected start of the subset time range,
            # and continue on to find the index of the last time that
            # is less than or equal to the selected end of the subset
            # time range.
            my $secondsPerUnit;
            my $interval;
            if ( $units =~ /day/i ) {
                $secondsPerUnit = 86400;
                $interval       = 'days';
            }
            elsif ( $units =~ /hour/i ) {
                $secondsPerUnit = 3600;
                $interval       = 'hours';
            }
            elsif ( $units =~ /minute/i ) {
                $secondsPerUnit = 60;
                $interval       = 'minutes';
            }
            elsif ( $units =~ /second/i ) {
                $secondsPerUnit = 1;
                $interval       = 'seconds';
            }
            else {

                # TO DO: Handle date spans for units other than days, hours,
                # minutes, seconds.
            }
            if ( defined $secondsPerUnit ) {
                my $subsetStartInUnits
                    = ( $subsetStartEpochSecs - $spanStartEpochSecs )
                    / $secondsPerUnit;
                my $subsetEndInUnits
                    = ( $subsetEndEpochSecs - $spanStartEpochSecs )
                    / $secondsPerUnit
                    if defined $subsetEndEpochSecs;
                for ( my $timeInd = 0; $timeInd < $timeDimSize; $timeInd++ ) {
                    next if $times[$timeInd] < $subsetStartInUnits;
                    $minTimeInd = $timeInd unless defined $minTimeInd;
                    next if defined $maxTimeInd;
                    next if $times[$timeInd] < $subsetEndInUnits;
                    $maxTimeInd
                        = ( $timeInd > $minTimeInd )
                        ? $timeInd - 1
                        : $minTimeInd;
                    last;
                }
            }
            unless ( defined $maxTimeInd ) {
                $maxTimeInd = $timeDimSize - 1 if defined $minTimeInd;
            }
            unless ( ( defined $minTimeInd ) && ( defined $maxTimeInd ) ) {
                my $message = "No data found in time range "
                    . $dtSubsetStart->iso8601();
                if ( defined $dtSubsetEnd ) {
                    $message .= " to " . $dtSubsetEnd->iso8601();
                }
                else {
                    $message .= " or later.";
                }
                push @messages, $message;

 #                SSW::Utils::exitNoMatchException( \@messages ) if @messages;
                return ( $timeIndexes, \@messages );
            }
            $timeIndexes->{$timeDimName}->{indexes}
                = [ $minTimeInd, $maxTimeInd ];
            my @timeLabels;
            if ($timeSplittableDimension) {
                my $basename = basename($odUrl);
                for ( my $idx = $minTimeInd; $idx <= $maxTimeInd; $idx++ ) {
                    my $dt = $dtSpanStart->clone->add(
                        $interval => $times[$idx] );
                    push @timeLabels,
                          $basename . '.'
                        . $dt->ymd('')
                        . $dt->hms('')
                        . $typeSuffix;
                }
                $timeIndexes->{$timeDimName}->{labels} = \@timeLabels;
            }
        }
    }

    return ($timeIndexes);
}

sub DEBUG {
    my ( $caller, $message ) = @_;
    print STDERR "$caller" . $message ? ": $message\n" : '';
    return;
}

# Get the XPath context with all namespaces registered, and set the default
# namespace prefix to 'default'
sub getXPathContext {
    my ($doc) = @_;

    # Get and register namespaces
    my $xpc = XML::LibXML::XPathContext->new($doc);

    # Use a hash to avoid duplicates
    my %nameSpace = ();
    foreach my $nsNode ( $doc->findnodes('//namespace::*') ) {
        my $prefix = $nsNode->getLocalName();
        $prefix = 'default' unless defined $prefix;
        my $uri = $nsNode->getData();
        $nameSpace{$prefix} = $uri;
    }
    foreach my $prefix ( keys %nameSpace ) {
        $xpc->registerNs( $prefix, $nameSpace{$prefix} );
    }

    return $xpc;
}

sub timeSplittableDimension {
    my ( $variableDims, $timeDims, ) = @_;

    return unless $variableDims;
    return unless $timeDims;
    foreach my $variable ( keys %$variableDims ) {
        foreach my $dim ( @{ $variableDims->{$variable} } ) {
            my $dimName = $dim->{name};
            if ( exists $timeDims->{$dimName} ) {

                # If we find any variable has a time dimension
                # with a size greater than 1,
                # then we can time split
                return $dimName if $timeDims->{$dimName}->{size} > 1;
            }
        }
    }

    return;
}

sub getSubsetQueryString {
    my ( $variableDims, $uniformVariables, $latDims, $longDims,
        $latLongIndexes, $timeDims, $timeIndexes, $singleTimeIndex )
        = @_;

    #    DEBUG((caller(0))[3]);
    my ( $latIndStart, $latIndEnd, $longIndStart, $longIndEnd )
        = @$latLongIndexes;

    my @ssParams;
    my %dimNames;
    my %dimIndexes;
    my @variables = keys %$variableDims;
    foreach my $variableName (@variables) {

        unless ($uniformVariables) {

            # If a selected variable does not exist (have a dimension) in
            # the granule, assume that not all granules have the same
            # variables, and skip that variable.
            next unless exists $variableDims->{$variableName};
        }

        my $paramStr = $variableName;
        foreach my $dim ( @{ $variableDims->{$variableName} } ) {
            my $dimName = $dim->{name};
            $dimNames{$dimName} = 1 unless exists $dim->{noDimVar};
            if ( $dimName eq $latDims->{name} ) {
                $paramStr .= "[$latIndStart:$latIndEnd]";
            }
            elsif ( $dimName eq $longDims->{name} ) {
                $paramStr .= "[$longIndStart:$longIndEnd]";
            }
            elsif (ref($timeDims) eq 'HASH'
                && exists $timeDims->{$dimName}
                && ref($timeIndexes) eq 'HASH'
                && exists $timeIndexes->{$dimName} )
            {

                # Use only a single time index if it is provided,
                # otherwise use the full range of time indices
                my ( $timeIndStart, $timeIndEnd )
                    = ( defined $singleTimeIndex )
                    ? ( $singleTimeIndex, $singleTimeIndex )
                    : @{ $timeIndexes->{$dimName}->{indexes} };
                $paramStr .= "[$timeIndStart:$timeIndEnd]"
                    if ( ( defined $timeIndStart )
                    && ( defined $timeIndEnd ) );
            }
            elsif ( exists $dim->{selectedIndexes} ) {
                $paramStr .= $dim->{selectedIndexes};
                $dimIndexes{$dimName} = $dim->{selectedIndexes};
            }
            else {
                $paramStr .= "[0:$dim->{maxind}]";
            }
        }
        push @ssParams, $paramStr;
    }

    # Include dimension variables
    foreach my $dimName ( keys(%dimNames) ) {
        if ( $dimName eq $latDims->{name} ) {
            push @ssParams, "${dimName}[$latIndStart:$latIndEnd]";
        }
        elsif ( $dimName eq $longDims->{name} ) {
            push @ssParams, "${dimName}[$longIndStart:$longIndEnd]";
        }
        elsif (ref($timeDims) eq 'HASH'
            && exists $timeDims->{$dimName}
            && ref($timeIndexes) eq 'HASH'
            && exists $timeIndexes->{$dimName} )
        {
            if ( exists $timeIndexes->{$dimName} ) {
                my ( $timeIndStart, $timeIndEnd )
                    = ( defined $singleTimeIndex )
                    ? ( $singleTimeIndex, $singleTimeIndex )
                    : @{ $timeIndexes->{$dimName}->{indexes} };
                if ( ( defined $timeIndStart ) && ( defined $timeIndEnd ) ) {
                    push @ssParams, "${dimName}[$timeIndStart:$timeIndEnd]";
                    if ( exists $timeDims->{$dimName}->{boundsVarName} ) {

                        # Include time bounds variable when it exists
                        # for the time dimension
                        my $name = $timeDims->{$dimName}->{boundsVarName};
                        push @ssParams,
                            "${name}[$timeIndStart:$timeIndEnd][0:1]";
                    }
                }
            }
        }
        elsif ( exists $dimIndexes{$dimName} ) {
            push @ssParams, "${dimName}$dimIndexes{$dimName}";
        }
        else {
            push @ssParams, $dimName;
        }
    }

    return join( ',', @ssParams );
}

sub getOpendapUrls {
    my ( $self, $oldMethod ) = @_;

    my @urls;

    my $urls           = $self->getUrlList;
    my $latDims        = $self->getLatDims;
    my $longDims       = $self->getLongDims;
    my $latLongIndexes = $self->getLatLongIndexes;
    my $variableDims
        = $oldMethod
        ? $self->getVariableDimsOldMethod
        : $self->getVariableDims;
    my $timeDims         = $self->getTimeDims;
    my $uniformVariables = $self->uniformVariables;

    my $timeSplittableDimension
        = timeSplittableDimension( $variableDims, $timeDims );
    if ($timeSplittableDimension) {
        my @labels;
        my $ua = LWP::UserAgent->new();
        if ( defined( $self->{_CREDENTIALS} ) ) {
            # If credentials were provided, set the credentials in the user agent
            # for each combination of location and realm.
            foreach my $netloc ( keys %{$self->{_CREDENTIALS}} ) {
                foreach my $realm ( keys %{$self->{_CREDENTIALS}->{$netloc}} ) {
                    my $user = $self->{_CREDENTIALS}->{$netloc}->{$realm}->{DOWNLOAD_USER};
                    my $cred = $self->{_CREDENTIALS}->{$netloc}->{$realm}->{DOWNLOAD_CRED};
                    $ua->credentials( $netloc, $realm, $user, $cred );
                }
            }

            # Provide a place for the user agent to store cookies that are set
            # when basic authentication is performed. This facilitates access
            # to data that requires Earthdata Login authentication.
            my $cookies = HTTP::Cookies->new();
            $ua->cookie_jar($cookies);
        }
        my $startDate  = $self->getStartDate;
        my $endDate    = $self->getEndDate;
        my $typeSuffix = $self->getTypeSuffix;
        foreach my $fileUrl (@$urls) {

            # Make sure that the OPeNDAP URL is not for the html resource
            $fileUrl =~ s/\.html$//;

            my $timeIndexes;
            my $errors;
            ( $timeIndexes, $errors )
                = _determineTimeIndexes( $variableDims, $timeDims, $fileUrl,
                $ua, $startDate, $endDate, $timeSplittableDimension,
                $typeSuffix );
            if ( ( ref($errors) eq 'ARRAY' ) && (@$errors) ) {
                return ( undef, undef, $errors );
            }
            my ( $timeIndStart, $timeIndEnd )
                = @{ $timeIndexes->{$timeSplittableDimension}->{indexes} };
            for (
                my $index = $timeIndStart;
                $index <= $timeIndEnd;
                $index++
                )
            {
                my $subsetQueryString
                    = getSubsetQueryString( $variableDims, $uniformVariables,
                    $latDims, $longDims, $latLongIndexes, $timeDims,
                    $timeIndexes, $index );
                my $urlSuffix
                    = $self->getTypeSuffix . '?' . $subsetQueryString;
                push @urls, $fileUrl . $urlSuffix;
            }
            push @labels,
                @{ $timeIndexes->{$timeSplittableDimension}->{labels} };
        }
        return \@urls, \@labels;
    }
    else {
        my $timeIndexes = $self->getTimeIndexes;
        my $subsetQueryString
            = getSubsetQueryString( $variableDims, $uniformVariables,
            $latDims, $longDims, $latLongIndexes, $timeDims, $timeIndexes );
        my $urlSuffix = $self->getTypeSuffix . '?' . $subsetQueryString;
        foreach my $fileUrl (@$urls) {
            my $url = $fileUrl;

            # Make sure that the OPeNDAP URL is not for the html resource
            $url =~ s/\.html$//;
            $url .= $urlSuffix;
            push @urls, $url;
        }
        return \@urls;
    }

}

sub _dtObject {
    my $dt = shift;

    #    DEBUG((caller(0))[3]);
    return ( DateTime->now ) if $dt eq 'now';

    my ( $ss, $mm, $hh, $day, $month, $year, $zone )
        = Date::Parse::strptime($dt);
    $year += 1900 if $year < 1000;
    $month++;
    $hh = 0 unless $hh;
    $mm = 0 unless $mm;
    $ss = 0 unless $ss;
    my $dtObj = DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        hour      => $hh,
        minute    => $mm,
        second    => $ss,
        time_zone => 'UTC'
    );
    return $dtObj;
}

sub _serializeMetadata {
    my ( $self, $metadataAttributes ) = @_;

    return unless ref($metadataAttributes) eq 'ARRAY';

    my $metadata = {};
    foreach my $attr (@$metadataAttributes) {
        $metadata->{$attr} = $self->{$attr}
            if ( exists $self->{$attr} ) && ( defined $self->{$attr} );
    }

    # Use the option 'KeyAttr => []' to prevent folding of hashes
    return XMLout( $metadata, KeyAttr => [] );
}

sub _unserializeMetadata {
    my ( $self, $serialized ) = @_;

    # Use the option 'KeyAttr => []' to prevent folding of hashes
    my $metadata = XMLin( $serialized, KeyAttr => [] );
    if ( ref($metadata) eq 'HASH' ) {
        foreach my $key ( keys %$metadata ) {
            $self->{$key} = $metadata->{$key};
        }
        $self->{_METADATA} = $serialized;

        # XMLin will take what was originally a reference to an array
        # containing a single hash reference and convert it to a hash
        # reference, so we can avoid that by converting any hash reference
        # to an array reference.
        if (   ( exists $self->{_VARIABLE_DIMS} )
            && ( ref( $self->{_VARIABLE_DIMS} ) eq 'HASH' ) )
        {
            foreach my $name ( keys %{ $self->{_VARIABLE_DIMS} } ) {
                unless ( ref($self->{_VARIABLE_DIMS}->{$name}) eq 'ARRAY' )
                {
                    # Make all _VARIABLE_DIMS array references
                    $self->{_VARIABLE_DIMS}->{$name}
                        = [$self->{_VARIABLE_DIMS}->{$name}];
                }
            }
        }

        # Since metadata content is determined by the value of VARIABLES
        # when it is created, the restored metadata can be used to determine
        # the value of VARIABLES
        unless ( defined $self->{_VARIABLES} ) {
            if (   ( exists $self->{_VARIABLE_DIMS} )
                && ( ref( $self->{_VARIABLE_DIMS} ) eq 'HASH' ) )
            {
                $self->{_VARIABLES} = [ keys %{ $self->{_VARIABLE_DIMS} } ];
            }
        }
        return $self;
    }

    return;
}

# Performs the same function as the getOpendapDownloadList method, but
# uses logic that finds dimensions by giving priority to the Array Attribute
# named 'coordinates' rather than the Array element named 'dimension'. Use
# of this method is deprecated. It exists as an alternative to providing
# an extra parameter to getOpendapDownloadList in order to accomplish the
# same thing.
sub getOpendapDownloadListOldMethod {
    my ($self) = @_;

    my ( $urls, $labels, $errors ) = $self->getOpendapUrls(1);
    return ( undef, $errors ) if $errors;
    return unless $urls && ref($urls) eq 'ARRAY';

    my @labels = @$labels if ref($labels) eq 'ARRAY';
    my @items;
    foreach my $url (@$urls) {
        my $label = shift @labels if @labels;
        if ( defined $label ) {
            push @items, [ $url, $label ];
        }
        else {
            my $label = basename($url);
            $label =~ s/\?.*//;
            push @items, [ $url, $label ];
        }
    }

    return \@items;
}

sub getOpendapDownloadList {
    my ($self) = @_;

    my ( $urls, $labels, $errors ) = $self->getOpendapUrls;
    return ( undef, $errors ) if $errors;
    return unless $urls && ref($urls) eq 'ARRAY';

    my @items;
    my @labels = @$labels if ref($labels) eq 'ARRAY';
    foreach my $url (@$urls) {
        my $label = shift @labels if @labels;
        if ( defined $label ) {
            push @items, [ $url, $label ];
        }
        else {
            my $label = basename($url);
            $label =~ s/\?.*//;
            push @items, [ $url, $label ];
        }
    }

    return \@items;
}

sub AUTOLOAD {
    my ( $self, $arg ) = @_;

    if ( $AUTOLOAD =~ /.*::debug/ ) {
        return $self->{_DEBUG};
    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE} if exists $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE} if exists $self->{_ERROR_MESSAGE};
    }
    elsif ( $AUTOLOAD =~ /.*::ua/ ) {
        return $self->{_USER_AGENT} if exists $self->{_USER_AGENT};
    }
    elsif ( $AUTOLOAD =~ /.*::opendapDoc/ ) {
        return $self->{_OPENDAP_DOC} if exists $self->{_OPENDAP_DOC};
    }
    elsif ( $AUTOLOAD =~ /.*::setUrlList/ ) {
        $self->{_URLS} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::uniformVariables/ ) {
        return $self->{_UNIFORM_VARIABLES}
            if exists $self->{_UNIFORM_VARIABLES};
    }
    elsif ( $AUTOLOAD =~ /.*::getUrlList/ ) {
        return $self->{_URLS} if exists $self->{_URLS};
    }
    elsif ( $AUTOLOAD =~ /.*::getVariableList/ ) {
        return $self->{_VARIABLES} if exists $self->{_VARIABLES};
    }
    elsif ( $AUTOLOAD =~ /.*::getStartDate/ ) {
        return $self->{_START} if exists $self->{_START};
    }
    elsif ( $AUTOLOAD =~ /.*::getEndDate/ ) {
        return $self->{_END} if exists $self->{_END};
    }
    elsif ( $AUTOLOAD =~ /.*::getVariableDimsOldMethod/ ) {
        return $self->{_VARIABLE_DIMS_OLD_METHOD}
            if exists $self->{_VARIABLE_DIMS_OLD_METHOD};
    }
    elsif ( $AUTOLOAD =~ /.*::getVariableDims/ ) {
        return $self->{_VARIABLE_DIMS} if exists $self->{_VARIABLE_DIMS};
    }
    elsif ( $AUTOLOAD =~ /.*::setOpendapMetadata/ ) {
        $self->{_METADATA} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getOpendapMetadata/ ) {
        return $self->{_METADATA} if exists $self->{_METADATA};
    }
    elsif ( $AUTOLOAD =~ /.*::setLatDims/ ) {
        $self->{_LAT_DIMS} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::setLongDims/ ) {
        $self->{_LONG_DIMS} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getLatDims/ ) {
        return $self->{_LAT_DIMS} if exists $self->{_LAT_DIMS};
    }
    elsif ( $AUTOLOAD =~ /.*::getLongDims/ ) {
        return $self->{_LONG_DIMS} if exists $self->{_LONG_DIMS};
    }
    elsif ( $AUTOLOAD =~ /.*::getLatLongIndexes/ ) {
        return $self->{_LAT_LONG_INDEXES}
            if exists $self->{_LAT_LONG_INDEXES};
    }
    elsif ( $AUTOLOAD =~ /.*::setTimeDims/ ) {
        $self->{_TIME_DIMS} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getTimeDims/ ) {
        return $self->{_TIME_DIMS} if exists $self->{_TIME_DIMS};
    }
    elsif ( $AUTOLOAD =~ /.*::getTimeIndexes/ ) {
        return $self->{_TIME_INDEXES} if exists $self->{_TIME_INDEXES};
    }
    elsif ( $AUTOLOAD =~ /.*::getTypeSuffix/ ) {
        return $self->{_TYPE_SUFFIX} if exists $self->{_TYPE_SUFFIX};
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorMessage/ ) {
        $self->{_ERROR_MESSAGE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorType/ ) {
        $self->{_ERROR_TYPE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DataAccess::OPeNDAP - Perl module for OPeNDAP access (subsetting)

=head1 SYNOPSIS

  use DataAccess::OPeNDAP;
  $access = DataAccess::OPeNDAP->new(VARIABLES => \@variableList, URLS =>\@urlList [, FORMAT => $format] [, START => $startDate] [, END => $endDate] [, BBOX  => $bbox][, METADATA => $metadata][, CREDENTIALS => $credentials]);
  if ($access->onError) {
      print STDERR $access->errorMessage;
      exit;
  }
  $metadata = $access->getOpendapMetadata;
  $accessList = $access->getOpendapDownloadList;


=head1 DESCRIPTION

DataAccess::OPeNDAP provides methods for obtaining URLS to access data via OPeNDAP.

=head1 CONSTRUCTOR

=over 4

=item new(VARIABLES => \@variableList, URLS =>\@urlList [, METADATA => $metadata, FORMAT => $format, START => $startDate, END => $endDate, BBOX  => \@bbox, CREDENTIALS => $credentials])

=over 4

=item VARIABLES

A reference to a list of variables to be accessed. Each value in the list should be the name of an OPeNDAP variable.

=item URLS

A reference to a list of OPeNDAP URLs. The list must contain at least one URL.

=item FORMAT

(optional) Desired format for the data that are downloaded via the URLs returned by the getOpendapUrls method, either 'netCDF', 'netCDF4', 'DODS', or 'ASCII'. If not provided, a default format of 'ASCII' will be used.

=item START

(optional) Start date/time of the desired data, in the form yyyy-mm-ddT-hh:mm:ssZ. If the time dimension of a data variable has a size N larger than 1 (i.e. there is more than one time value per OPeNDAP url), then for each url in URLS, getOpendapUrls will return up to N access URLs, but none earlier than the START date/time. Otherwise the value of START will be ignored.

=item END

(optional) End date/time of the desired data, in the form yyyy-mm-ddT-hh:mm:ssZ. If the time dimension of a data variable has a size N larger than 1 (i.e. there is more than one time value per OPeNDAP url), then for each url in URLS, getOpendapUrls will return up to N access URLs, but none later than the END date/time. Otherwise the value of END will be ignored.

=item BBOX

(optional) Bounding box for the desired spatial region. If no value is provided, all latitude and longitude values will be included in the downloaded data.

=item METADATA

(optional) A string containing OPeNDAP metadata. If this is not provided, the metadata will be obtained from the OPeNDAP server, and can then be obtained using the getOpendapMetadata method.

=item CREDENTIALS

(optional) Credentials for basic authentication used for OPeNDAP access.
Should be a reference to a hash whose keys are URL locations (host:port) and whose values are references to hashes whose keys are realms and whose values are references to hashes with key/value pairs DOWNLOAD_USER/username and DOWNLOAD_CRED/pwd.

=back

=back

=head1 METHODS

=over 4

=item getOpendapMetadata

Returns a string containing OPeNDAP metadata. This string can be provided as the value of METADATA when constructing a new object with the same value of VARIABLES.

=item getOpendapDownloadList

Returns a list of items, where each item in the list is a reference to a list of two elements, consisting of an OPeNDAP access URL and a unique label. Each file downloaded via the OPeNDAP access url will include all data variables specified by VARIABLES, and their corresponding dimension variables, and if BBOX and/or START and END are provided, downloaded data will be spatially and/or temporally subsetted.

=item getOpendapDownloadListOldMethod

Performs the same function as the getOpendapDownloadList method, but
uses logic that finds dimensions by giving priority to the Array Attribute
named 'coordinates' rather than the Array element named 'dimension'. Use
of this method is deprecated.

=item onError

Returns a value if there was an error creating the object.

=item errorMessage

If onError() has a value, returns a message describing the error.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO


=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.gov<gt>

=cut
