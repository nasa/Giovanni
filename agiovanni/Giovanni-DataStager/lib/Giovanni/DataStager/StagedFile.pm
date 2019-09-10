#$Id: StagedFile.pm,v 1.3 2014/12/23 20:08:54 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::DataStager::StagedFile;

use 5.008008;
use strict;
use warnings;
use Giovanni::Cache;
use Giovanni::DataField;
use XML::LibXML;
use URI::URL;

our $VERSION = '0.01';

sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    if (   !exists( $self->{URL} )
        || !exists( $self->{IS_VIRTUAL} )
        || !exists( $self->{ID} )
        || !exists( $self->{FILENAME_FROM_SEARCH} ) )
    {
        die("Constructor requires URL, IS_VIRTUAL, FILENAME_FROM_SEARCH, and ID"
        );
    }

    return $self;
}

sub getCacheKey {
    my ($self) = @_;
    my $key = URI::URL->new( $self->{URL} );
    $key->scheme("file");
    if ( $self->{IS_VIRTUAL} ) {
        my $fragment = $key->frag();
        if ( defined($fragment) ) {
            $fragment = $fragment . $self->{ID};
        }
        else {
            $fragment = $self->{ID};
        }
        $key->frag($fragment);
    }
    return $key->as_string();
}

sub getUrl {
    my ($self) = @_;
    return $self->{URL};
}

sub getFilenameFromSearch {
    my ($self) = @_;
    return $self->{FILENAME_FROM_SEARCH};
}

sub setScrubbedFilename {
    my ( $self, $filename ) = @_;
    $self->{SCRUBBED_FILENAME} = $filename;
}

sub getScrubbedFilename {
    my ($self) = @_;
    return $self->{SCRUBBED_FILENAME};
}

sub getStartTimeFromSearch {
    my ($self) = @_;
    return $self->{START_TIME_FROM_SEARCH};
}

sub getEndTimeFromSearch {
    my ($self) = @_;
    return $self->{END_TIME_FROM_SEARCH};
}

sub isScrubbed {
    my ($self) = @_;
    if ( exists( $self->{SCRUBBED_FILENAME} ) ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub isBadUrl {
    my ($self) = @_;
    return $self->{IS_BAD_URL};
}

sub setBadUrl {
    my ($self) = @_;
    $self->{IS_BAD_URL} = 1;
}

sub setCacheMetadata {
    my ( $self, $metadata ) = @_;
    $self->{CACHE_METADATA} = $metadata;
}

sub getMetadata {
    my ($self) = @_;
    return $self->{CACHE_METADATA};
}

1;
__END__

=head1 NAME

Giovanni::DataStager::StagedFile - Perl extension for keeping track of a single staged file.
The only logic is for calculating the cache key based on whether or not this is a virtual
variable.

=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>

=cut
