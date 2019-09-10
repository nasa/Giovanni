package Giovanni::ResultSet;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::ResultSet ':all';
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

our $VERSION = '1.00';

# Preloaded methods go here.
use strict;
use Safe;
use vars '$AUTOLOAD';
use Data::UUID;
use Giovanni::Util;
use Giovanni::Result;

sub new() {
    my ( $class, %input ) = @_;
    my $self = {};

    #Holder for all results in the result set
    $self->{_RESULT} = [];
    $self->{_ID} = ( defined $input{resultset} ? $input{resultset} : undef );
    unless ( defined $self->{_ID} ) {

        #Generate id if one is not supplied
        my $id   = Data::UUID->new();
        my $uuid = $id->create();
        $self->{_ID} = $id->to_string($uuid);
    }
    $self->{_RESULT_SET_DIR} = $input{session_dir} . '/' . $self->{_ID};
    $self->{_FORMAT} = ( defined $input{format} ? $input{format} : undef );
    $self->{_SESSION_DIR}    = $input{session_dir};
    $self->{_TIMEOUT}        = $input{timeout};
    unless ( -d $self->{_RESULT_SET_DIR} ) {
        unless ( mkdir( $self->{_RESULT_SET_DIR} ) ) {
            $self->{_ERROR_MESSAGE}
                = 'Result set (_RESULT_SET_DIR) directory doesnot exist';
            $self->{_ERROR_TYPE} = 1;
        }
    }
    chmod( 0775, $self->{_RESULT_SET_DIR} );

    return bless( $self, $class );
}
################################################################################
sub getStatus {
    my ($self) = @_;
    my @resultArray = ();

    #Find all of Result directories under the ResultSet
    my @filesResultSet = Giovanni::Util::listDir( $self->getResultSetDir() );

    #Find the status of all results in the result set
    foreach my $resultDir (@filesResultSet) {
        my @dirParsed = split( "\/", $resultDir );

        # Build a new Result Obj and then call it's getStatus()
        my %input = (
            result        => $dirParsed[-1],
            resultset_dir => $self->getResultSetDir(),
            timeout       => $self->{_TIMEOUT},
            format        => $self->getFormat()
        );
        my $resultObj = Giovanni::Result->new(%input);
        $resultObj->getStatus();
        push( @resultArray, $resultObj );
    }
    $self->addResult(@resultArray);
}
################################################################################
sub toXML {
    my ( $self ) = @_;
    my $doc = Giovanni::Util::createXMLDocument('resultset');
    $doc->setAttribute( 'id', $self->getId() );
    foreach my $result ( @{ $self->getResults() } ) {
        $doc->appendChild( $result->toXML() );
    }
    return $doc;
}
################################################################################
sub addResult {
    my ( $self, @list ) = @_;
    my %input;
    foreach my $item (@list) {
        if ( ref($item) eq 'Giovanni::Result' ) {
            push( @{ $self->{_RESULT} }, $item );
        }
    }
}
################################################################################
sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    if ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE};
    }
    elsif ( $AUTOLOAD =~ /.*::getFormat/ ) {
        return $self->{_FORMAT};
    }
    elsif ( $AUTOLOAD =~ /.*::getId/ ) {
        return $self->{_ID};
    }
    elsif ( $AUTOLOAD =~ /.*::getResults/ ) {
        return $self->{_RESULT};
    }
    elsif ( $AUTOLOAD =~ /.*::getResultSetDir/ ) {
        return $self->{_RESULT_SET_DIR};
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }
}
################################################################################
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::ResultSet - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Giovanni::ResultSet;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Giovanni::ResultSet, created by h2xs. It looks like the
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

Mahabaleshwara S. Hegde, E<lt>mhegde@localdomainE<gt>

=cut
