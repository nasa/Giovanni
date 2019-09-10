package EDDA::Compare;

use 5.008008;
use strict;
use warnings;
use XML::LibXML;
use vars '$AUTOLOAD';

require Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use EDDA::Compare ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


sub new() {
    my ( $class, %input ) = @_;

    my $self = {};

    # Constructor expects %input to provide both original and updated xml
    # that are to be compared.
    #
    # ORIGINAL_XML_FILE: file path to original xml file
    # ORIGINAL_XML: original xml
    # [Either ORIGINAL_XML_FILE or ORIGINAL_XML must be provided. If
    # both are provided, only ORIGINAL_XML_FILE will be used.]
    #
    # UPDATED_XML_FILE: file path to updated xml file
    # UPDATED_XML: updated xml
    # [Either UPDATED_XML_FILE or UPDATED_XML must be provided. If
    # both are provided, only UPDATED_XML_FILE will be used.]

    my $parser = XML::LibXML->new();
    $parser->keep_blanks(0);

    # Parse original and updated xml

    my $originalDom;
    my $originalDoc;
    if (exists $input{ORIGINAL_XML_FILE}) {
        eval { $originalDom = $parser->parse_file( $input{ORIGINAL_XML_FILE} ); };
        if ($@) {
            $self->{_ERROR_TYPE} = 1;
            $self->{_ERROR_MESSAGE} = "Could not read and parse original xml file $input{ORIGINAL_XML_FILE}";
            return bless( $self, $class );
        }
        $self->{ORIGINAL_XML_FILE} = $input{ORIGINAL_XML_FILE};
    } elsif (exists $input{ORIGINAL_XML}) {
        eval { $originalDom = $parser->parse_string( $input{ORIGINAL_XML} ); };
        if ($@) {
            $self->{_ERROR_TYPE} = 1;
            $self->{_ERROR_MESSAGE} = "Could not parse original xml";
            return bless( $self, $class );
        }
        $self->{ORIGINAL_XML} = $input{ORIGINAL_XML};
    } else {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Must provide either ORIGINAL_XML_FILE or ORIGINAL_XML";
        return bless( $self, $class );
    }

    my $updatedDom;
    my $updatedDoc;
    if (exists $input{UPDATED_XML_FILE}) {
        eval { $updatedDom = $parser->parse_file( $input{UPDATED_XML_FILE} ); };
        if ($@) {
            $self->{_ERROR_TYPE} = 1;
            $self->{_ERROR_MESSAGE} = "Could not read and parse updated xml file $input{UPDATED_XML_FILE}";
            return bless( $self, $class );
        }
        $self->{UPDATED_XML_FILE} = $input{UPDATED_XML_FILE};
    } elsif (exists $input{UPDATED_XML}) {
        eval { $updatedDom = $parser->parse_string( $input{UPDATED_XML} ); };
        if ($@) {
            $self->{_ERROR_TYPE} = 1;
            $self->{_ERROR_MESSAGE} = "Could not parse updated xml";
            return bless( $self, $class );
        }
        $self->{UPDATED_XML} = $input{UPDATED_XML};
    } else {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Must provide either UPDATED_XML_FILE or UPDATED_XML";
        return bless( $self, $class );
    }

    # Call _hashify to convert XML to a hash reference, where each key is an
    # xpath to a 'value' node, and each value is either a value (for
    # single-valued attributes) or a reference to a hash whose keys are
    # the values (for a multi-valued attribute).

    $originalDoc = $originalDom->documentElement();
    $self->{originalDoc} = $originalDoc;
    my $hashedOriginal = {};
    _hashify($originalDoc, $hashedOriginal);
    $self->{hashedOriginal} = $hashedOriginal;

    $updatedDoc = $updatedDom->documentElement();
    $self->{updatedDoc} = $updatedDoc;
    my $hashedUpdated = {};
    _hashify($updatedDoc, $hashedUpdated);
    $self->{hashedUpdated} = $hashedUpdated;

    return bless( $self, $class );
}

sub _hashify {
    my $rootNode = shift;
    my $hash = shift;

    # Traverse the xml. Expect each node to have a child named 'type'
    # whose text content is either 'container' or a primitive type.
    #
    # If type is a primitive type, then expect there to be one or more
    # children named 'value' whose text content is a value associated with
    # the name of its parent node.
    #
    # If type is 'container', then expect there to be another child
    # named 'value' that contains more than one child node, each of which
    # has a child named 'type' that determines whether or not it is a
    # container or has 'value' children with text content.
    #
    # For each non-container node with a value child, add an element
    # to %$hash whose key is the xpath to that node, and whose value
    # is a reference to a hash whose keys are the values associated
    # with that xpath (thus one key for a single-value attribute,
    # and multiple keys for a multi-valued attribute). Hashes are used
    # since each xpath is unique, and each value for a multi-valued attribute
    # is assumed to be unique.

    foreach my $childNode ($rootNode->childNodes) {
        my $name = $childNode->nodeName;
        next if ($name eq '#comment');
        my $xpath = $childNode->nodePath;
        my ($typeNode) = $childNode->findnodes('./type');
        my $type = $typeNode->textContent() if $typeNode;
        unless (defined $type) {
            print STDERR "No type found for $xpath\n";
            next;
        }
#        my ($multiplicityNode) = $childNode->findnodes('./multiplicity');
        #    my $multiplicity = $multiplicityNode->textContent() if $multiplicityNode;
        #    unless (defined $multiplicity) {
        #        print STDERR "No multiplicity found for $xpath\n";
        #        next;
        #    }
        if ($type ne 'container') {
            #        if ($multiplicity eq 'one') {
            my @valueNodes = $childNode->findnodes('./value');
            unless (@valueNodes) {
                print STDERR "No value children found for $xpath\n";
                next;
            }
            foreach my $valueNode (@valueNodes) {
                my $value = $valueNode->textContent();
                $hash->{$xpath}->{$value} = 1
            }
            #        }
        } else {
            my ($valueNode) = $childNode->findnodes('./value');
            unless ($valueNode) {
                print STDERR "No value children found for $xpath\n";
                next;
            }
            # Recurse
            hashify($valueNode, $hash);
        }
    }
}

sub compareSingleValues {
    my ($self, $key) = @_;

    # Given a key, compare the original value for that key with
    # the updated value for that key.
    # If they are the same, return undef.
    # If they differ, return the original value and the updated value.
    #
    # Assume that there is only a single value associated with each key.

    my $original = $self->{hashedOriginal};
    my $updated = $self->{hashedUpdated};

    return unless exists $original->{$key};
    return unless exists $updated->{$key};
    return unless ( ( (keys %{$original->{$key}}) == 1 ) &&
                    ( (keys %{$updated->{$key}}) == 1 ) );
    my ($originalVal) = keys %{$original->{$key}};
    my ($updatedVal) = keys %{$updated->{$key}};
    if ($originalVal ne $updatedVal) {
        return ($originalVal, $updatedVal);
    }
    return;
}

sub compareAll {
    my ($self) = @_;
    my %results;

    my $hash1 = $self->{hashedOriginal};
    my $hash2 = $self->{hashedUpdated};

    # Compare all of the values stored in two hash references.
    # Values are either singletons (hash key corresponds to 1 value) or
    # multiples (hash key corresponds to another hash (reference) whose
    # keys all correspond to single values.
    #
    # Store results of comparison as a list of strings for each path.

    foreach my $key1 (sort keys %$hash1) {
        if ( exists ($hash2->{$key1}) ) {
            if ( (keys %{$hash1->{$key1}}) == 1 ) {
                my ($val1) = keys %{$hash1->{$key1}};
                my ($val2) = keys %{$hash2->{$key1}};
                if ( $val1 ne $val2 ) {
                    push @{$results{$key1}}, "'$val1' changed to '$val2'";
                }
            } else {
                foreach my $val1 (sort keys %{$hash1->{$key1}}) {
                    unless ( exists ($hash2->{$key1}->{$val1}) ) {
                        push @{$results{$key1}}, "'$val1' missing from update";
                    }
                }
                foreach my $val2 (sort keys %{$hash2->{$key1}}) {
                    unless ( exists ($hash1->{$key1}->{$val2}) ) {
                        push @{$results{$key1}}, "'$val2' missing from original";
                    }
                }
            }
        } else {
            my $result = "missing from update";
            if ( (keys %{$hash1->{$key1}}) == 1 ) {
                my ($val1) = keys %{$hash1->{$key1}};
                if ($val1 ne '') {
                    $result .= " ('$val1' in original)";
                }
            } else {
                my @originalVals;
                foreach my $val1 (sort keys %{$hash1->{$key1}}) {
                    if ($val1 ne '') {
                        push @originalVals, $val1;
                    }
                }
                if (@originalVals) {
                    $result .= ' (' .
                               join(', ', map{"'$_'"} @originalVals) .
                               ' in original)';
                }
            }
            push @{$results{$key1}}, $result;
        }
    }
    foreach my $key2 (sort keys %$hash2) {
        unless ( exists ($hash1->{$key2}) ) {
            my $result = "missing from original";
            if ( (keys %{$hash2->{$key2}}) == 1 ) {
                my ($val1) = keys %{$hash2->{$key2}};
                if ($val1 ne '') {
                    $result .= " ('$val1' in update)";
                }
            } else {
                my @updateVals;
                foreach my $val1 (sort keys %{$hash2->{$key2}}) {
                    if ($val1 ne '') {
                        push @updateVals, $val1;
                    }
                }
                if (@updateVals) {
                    $result .= ' (' .
                               join(', ', map{"'$_'"} @updateVals) .
                               ' in update)';
                }
            }
            push @{$results{$key2}}, $result;
        }
    }

    return \%results;
}


sub AUTOLOAD {
    my ( $self, @args ) = @_;

    if ( $AUTOLOAD =~ /.*::originalXpaths/ ) {
        return (keys %{$self->{hashedOriginal}})
            if (exists $self->{hashedOriginal});
    }
    elsif ( $AUTOLOAD =~ /.*::updatedXpaths/ ) {
        return (keys %{$self->{hashedUpdated}})
            if (exists $self->{hashedUpdated});
    }
    elsif ( $AUTOLOAD =~ /.*::originalHasXpath/ ) {
        return 1
            if ( (defined $args[0]) && (exists $self->{hashedOriginal}->{$args[0]}) );
    }
    elsif ( $AUTOLOAD =~ /.*::updatedHasXpath/ ) {
        return 1
            if ( (defined $args[0]) && (exists $self->{hashedUpdated}->{$args[0]}) );
    }
    elsif ( $AUTOLOAD =~ /.*::originalValues/ ) {
        return (keys %{$self->{hashedOriginal}->{$args[0]}})
            if ( (defined $args[0]) && (exists $self->{hashedOriginal}->{$args[0]}) );
    }
    elsif ( $AUTOLOAD =~ /.*::updatedValues/ ) {
        return (keys %{$self->{hashedUpdated}->{$args[0]}})
            if ( (defined $args[0]) && (exists $self->{hashedUpdated}->{$args[0]}) );
    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE};
    }
    return;
}


1;
__END__

=head1 NAME

EDDA::Compare - Module for comparing EDDA data products and data fields

=head1 SYNOPSIS

use EDDA::Compare;

$dataFieldFile = "$CFG::AESIR_CATALOG_DATA_FIELDS_DIR/$dataFieldId";

$updatedXml = getUpdatedXml();  # get updated xml, e.g. via POST

$comparer = EDDA::Compare->new(ORIGINAL_XML_FILE => $dataFieldFile, UPDATED_XML => $updatedXml);

print STDERR $comparer->errorMessage, "\n" if $comparer && $comparer->onError;

$xpath = $CFG::rescrubXpath;
@differences = $comparer->compareSingleValues($xpath);

=head1 DESCRIPTION

EDDA::Compare provides a way to compare EDDA data products and data fields
to detect the changes resulting from an update performed by an EDDA user.


=head1 CONSTRUCTOR

Constructor can compare original and updated xml, where xml is in files or variables.

=over 4

=item new( ORIGINAL_XML_FILE => $originalXmlFile, UPDATED_XML_FILE => $updatedXmlFile );

Here both original and updated xml are in files.

=item new( ORIGINAL_XML => $originalXml, UPDATED_XML => $updatedXml );

Here original and updated xml are in variables.

=item new( ORIGINAL_XML_FILE => $originalXmlFile, UPDATED_XML => $updatedXml );

Here original xml is in a file, updated xml is in a variable.

=back

=head1 METHODS

=over 4

=item onError

Returns a value if there was an error creating the Compare object

=item errorMessage

If onError() has a value, returns a message describing the error

=item compareSingleValues($xpath)

Compares original value and updated value for EDDA xml xpath $xpath. If the
value is unchanged, returns undef, and if it differs, returns original
value and updated value.

=item compareAll

Compares original values and updated values for all EDDA xml xpaths, and
returns a list of strings describing each difference.

=item originalHasXpath($xpath)

Returns true if the xpath $xpath exists in the original EDDA xml

=item updatedHasXpath($xpath)

Returns true if the xpath $xpath exists in the updated EDDA xml

=item originalXpaths

Returns a list of the EDDA xml xpaths with values in the original xml

=item updatedXpaths

Returns a list of the EDDA xml xpaths with values in the updated xml

=item originalValues($xpath)

Returns a list of the EDDA xml values at xpath $xpath in the original xml

=item updatedValues($xpath)

Returns a list of the EDDA xml values at xpath $xpath in the updated xml


=back

=head2 EXPORT

None by default.


=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.gov<gt>

=cut
