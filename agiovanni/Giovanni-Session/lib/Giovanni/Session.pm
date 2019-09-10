package Giovanni::Session;

# $Id: Session.pm,v 1.16 2015/02/06 15:29:09 rstrub Exp $
# aGiovanni, Version $Name:  $

use 5.008008;
use strict;
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

our $VERSION = '0.01';

# Preloaded methods go here.
use strict;
use Safe;
use vars '$AUTOLOAD';
use Data::UUID;
use File::Basename;
use Date::Manip;
use DateTime;
use Giovanni::ResultSet;
use Giovanni::Util;

sub new() {
    my ( $class, %input ) = @_;
    my $self = {};

    #Holder for all result sets
    $self->{_RESULT_SET} = [];
    $self->{_ID}
        = ( defined $input{session} && length( $input{session} ) ) > 0
        ? $input{session}
        : undef;

    # Case where a new session is being requested
    unless ( defined $self->{_ID} ) {

        # Generate unique id to be used as session ID
        my $id   = Data::UUID->new();
        my $uuid = $id->create();
        $self->{_ID} = $id->to_string($uuid);
    }
    else { # $input{format} is expected only when $input{session} is provided  
           # (the session is expected to already exist), otherwise it will be  ignored
        $self->{_FORMAT}
            = ( defined $input{format} && length( $input{format} ) ) > 0
            ? $input{format}
            : undef;
    }

    $self->{_SESSION_DIR} = $input{location} . '/' . $self->{_ID};

    # if Session Dir does not exist:
    unless ( -d $self->{_SESSION_DIR} ) {

        # If a format is specified, the session directory needs to exist to
        # be useful, so return an error if it doesn't exist.
        if ( $self->{_FORMAT} ) {
            $self->{_ERROR_MESSAGE} = 'Session directory does not exist';
            $self->{_ERROR_TYPE}    = 1;
        }
        else {
        # Otherwise if the session directory has disappeared, create a
        # new one. (mkdir:)
            unless ( mkdir( $self->{_SESSION_DIR}, 0775 ) ) {
                $self->{_ERROR_MESSAGE} = 'Session directory does not exist';
                $self->{_ERROR_TYPE}    = 1;
            }
        }

    }

    return bless( $self, $class );
}
################################################################################
sub getStatus {
    my ($self) = @_;

    #Find all the result sets under the Session

    my @resultSetArray = ();
    my @filesResultSet = Giovanni::Util::listDir( $self->getSessionDir() );

    # For each ResultSet directory, create a new ResultSet object
    # than call ResultSet getStatus (which will call Result->getStatus()s)
    foreach my $singleResultSet (@filesResultSet) {
        my @dirParsed = split( "\/", $singleResultSet );

        my %input = (
            resultset   => $dirParsed[-1],
            session_dir => $self->getSessionDir(),
            format      => $self->getFormat()
        );
        my $resultSetObj = Giovanni::ResultSet->new(%input);
        $resultSetObj->getStatus();
        push( @resultSetArray, $resultSetObj );
    }
    $self->addResultSet(@resultSetArray);
}
################################################################################
sub addResultSet {
    my ( $self, @list ) = @_;
    foreach my $item (@list) {
        if ( ref($item) eq 'Giovanni::ResultSet' ) {
            push( @{ $self->{_RESULT_SET} }, $item );
        }
    }
}
################################################################################
# Serialize result
#   modified by Hailiang Zhang on 11/2018
#   to implement sorting status check response by result creation time
#   modified by rstrub for Persistent Sessions on 05/2019
sub toXML {
    my ($self) = @_;
    my $doc = Giovanni::Util::createXMLDocument('session');
    $doc->setAttribute( 'id', $self->getId() );
    my @resultset_list;
    my @sorted = sort { $b->{_RESULT}[0]{_CREATIONTIME} <=> $a->{_RESULT}[0]{_CREATIONTIME} } @{$self->{_RESULT_SET}};
    my @byCreationTime = reverse @sorted;

    foreach my $resultSet ( @byCreationTime) {
        push( @resultset_list, $resultSet->toXML() );
    }
    
    for my $set (@resultset_list) {
        $doc->appendChild( $set);
    }
    my $styleSheet = "../../giovanni/xsl/GiovanniResponse.xsl";
    my $dom        = $doc->ownerDocument();
    $dom->insertProcessingInstruction( 'xml-stylesheet',
        qq(type="text/xsl" href="$styleSheet") );
    return $dom;
}
################################################################################
# Get sorting index based on result creation time
# It will return an empty list if
#   - creation time is not found
#   - exception is raised
# Arguments:
#   $session_dir: session direcotry full path
#   @resultset_list: list of resultset
# Return:
#   @sorting_index: sorting index based on result creation time (ascending)
# Author:
#   Hailiang Zhang
################################################################################
sub _getResultsetCreationOrder {

    my ( $session_dir, @resultset_list ) = @_;

    # loop over resultset
    # and push the result creation time to a list
    my @creationtime_list;
    for my $resultset (@resultset_list) {

        # get resultset and result id from the resultset_list arugment
        my $resultset_node = ${ $resultset->findnodes('/resultset') }[0];
        my $resultset_id   = $resultset_node->findvalue('./@id')
            if $resultset_node;
        my $result_node = ${ $resultset->findnodes('/resultset/result') }[0];
        my $result_id = $result_node->findvalue('./@id') if $resultset_node;

        # get result creation time from input.xml file
        my $input_xml_file =
            $session_dir . '/'
            . $resultset_id . '/'
            . $result_id
            . '/input.xml';
        if ( !( -r $input_xml_file ) ) {
            print STDERR
                "$input_xml_file does not exists or not readable to sort the session response\n";
            return ();
        }
        my $doc = Giovanni::Util::parseXMLDocument($input_xml_file);
        my $creationTime_node = ${ $doc->findnodes('/input/creationTime') }[0];
        my $creationTime = $creationTime_node->textContent();

        # convert result creation time to seconds since epoch
        # and push it to @creationtime_list
        my $creationTimeUnix = UnixDate( ParseDate($creationTime), "%s" ) if $creationTime;
        if ($creationTimeUnix) {
            push( @creationtime_list, $creationTimeUnix );
        } else {
            print STDERR
                "Failed to parse $input_xml_file for result creation time during ordering the session response.\n";
            return ();
        }
    }

    # get sorting index based on result creation time
    my @sorting_index =
        sort { $creationtime_list[$a] <=> $creationtime_list[$b] }
        0 .. $#creationtime_list;

    # return
    return @sorting_index;
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
    elsif ( $AUTOLOAD =~ /.*::getSessionDir/ ) {
        return $self->{_SESSION_DIR};
    }
    elsif ( $AUTOLOAD =~ /.*::getResultSets/ ) {
        return $self->{_RESULT_SET};
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }
}
################################################################################
1;
__END__

=head1 NAME

Giovanni::Session -

=head1 SYNOPSIS

  use Giovanni::Session;

=head1 DESCRIPTION


=head2 EXPORT


=head1 SEE ALSO


=head1 AUTHOR

Mahabaleshwara S. Hegde, E<lt>mhegde@localdomainE<gt>

=cut
