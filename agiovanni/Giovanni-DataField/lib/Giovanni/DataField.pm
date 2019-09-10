#-@@@ Giovanni, Version $Name:  $

package Giovanni::DataField;

use 5.008008;
use strict;
use warnings;
use vars '$AUTOLOAD';
use XML::LibXML;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::DataField ':all';
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

sub new() {
    my ( $class, %input ) = @_;

    my $self = {};
    my %attributes;
    my @sldList      = ();
    my $manifestFile = $input{MANIFEST};
    unless ( defined $manifestFile ) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "No MANIFEST provided";
    }
    elsif ( !-f $manifestFile ) {
        $self->{_ERROR_TYPE}    = 2;
        $self->{_ERROR_MESSAGE} = "File '$manifestFile' does not exist";
    }
    else {
        my $parser = XML::LibXML->new();
        $parser->keep_blanks(0);
        my $manifestDom;
        eval { $manifestDom = $parser->parse_file($manifestFile); };
        if ($@) {
            $self->{_ERROR_TYPE} = 3;
            $self->{_ERROR_MESSAGE}
                = "Could not read and parse $manifestFile: $@";
        }
        else {
            my $manifestDoc = $manifestDom->documentElement();
            my @varNodes    = $manifestDoc->findnodes('/varList/var');
            unless (@varNodes) {
                $self->{_ERROR_TYPE} = 4;
                $self->{_ERROR_MESSAGE}
                    = "Did not find any /varList/var in $manifestFile";
            }
            else {
                my $varNode    = $varNodes[0];
                my @attributes = $varNode->attributes;
                %attributes
                    = map { ( $_->getName, $_->getValue ) } @attributes;
                foreach my $sld ( $varNode->findnodes('./slds/sld') ) {
                    my $sldHashRef = {};
                    foreach my $attr (qw(url label invert)) {
                        my $val = $sld->getAttribute($attr);
                        $sldHashRef->{$attr} = $val if defined $val;
                    }
                    push( @sldList, $sldHashRef );
                }
            }
        }
    }
    $self->{attributes} = \%attributes;
    $self->{slds}       = \@sldList;

    return bless( $self, $class );
}

sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    if ( $AUTOLOAD =~ /.*::get_slds/ ) {
        return $self->{slds};
    }
    elsif ( $AUTOLOAD =~ /.*::get_(.+)/ ) {
        return $self->{attributes}->{$1} if exists $self->{attributes}->{$1};
    }
    elsif ( $AUTOLOAD =~ /.*::set_(.+)/ ) {
        if ( exists $self->{attributes}->{$1} ) {
            return $self->{attributes}->{$1} = $arg;
        }
    }
    elsif ( $AUTOLOAD =~ /.*::attributeNames/ ) {
        return ( keys %{ $self->{attributes} } )
            if exists $self->{attributes};
    }
    elsif ( $AUTOLOAD =~ /.*::attributes/ ) {
        return ( $self->{attributes} ) if exists $self->{attributes};
    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE};
    }
    elsif ( $AUTOLOAD =~ /.*::isClimatology/ ) {
        my $flag = $self->get_climatology();
        $flag = 'false' unless defined $flag;
        return ( $flag eq 'true' ? 1 : 0 );
    }
    elsif ( $AUTOLOAD =~ /.*::isVector/ ) {
        my $flag = $self->get_vectorComponents();
        return ( defined $flag ? 1 : 0 );
    }
    return undef;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Giovanni::DataField - Perl module for encapsulating Giovanni DataField

=head1 SYNOPSIS

 use Giovanni::DataField;
 $dataField = Giovanni::DataField->new(MANIFEST => 'manifestFile.xml');
 $attributeValue = $dataField->get_<attributeName>;
 $newAttributeValue = $dataField->set_<attributeName>(newValue);
 $flag = $dataField->isClimatology()
 $flag = $dataField->isVector()

=head1 DESCRIPTION

Giovanni::DataField provides accessors for the attributes of a variable (var)
found in a Giovanni data field manifest file.

=head1 CONSTRUCTOR

=over 4

=item new( MANIFEST => manifestFilePath )

=back

=head1 METHODS

=over 4

=item get_<attributeName>

Accessor that retrieves the value of the attribute with name attributeName,
e.g. if the attribute name is "east", then get_east retrieves the value.

=item set_<attributeName>(newValue)

Assigns a new value to the attribute with name attributeName,
e.g. if the attribute name is "east", then set_east('newValue') assigns the
value 'newValue' to the attribute.

=item attributeNames

Returns a list of the atrribute names found in the manifest file.

=item isVector 

Returns 1/0 depending whether a data field has vector components or not.

=item isClimatology

Returns 1/0 depending whether a data field is a climatology data field or not.

=item onError

Returns a value if there was an error creating the DataField object

=item errorMessage

If onError() has a value, returns a message describing the error

=item attributes

Returns a reference to a hash whose keys are the atrribute names and whose
values are the attribute values of the atrributes in the manifest file.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO
 

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.gov<gt>

=cut
