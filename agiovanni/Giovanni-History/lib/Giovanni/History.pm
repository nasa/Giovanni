package Giovanni::History;

# $Id: History.pm,v 1.4 2013/11/25 09:49:43 mhegde Exp $
# Giovanni, Version $Name:  $

use 5.008008;
use strict;
use warnings;
use Giovanni::Util;
use Safe;
use JSON;
use Storable 'dclone';
use Scalar::Util qw( looks_like_number);
use List::MoreUtils qw/ first_index /;

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

sub new {
    my ( $class, %input ) = @_;
    my $self = {};

    # File is used to read / write history from file
    $self->{_FILE} = $input{FILE} if ( exists $input{FILE} );

# Unique key attributes are used to prevent duplicates from being added to the history
    $self->{_UNIQUE_KEY_ATTRIBUTES} = $input{UNIQUE_KEY_ATTRIBUTES}
        if ( exists $input{UNIQUE_KEY_ATTRIBUTES} );

    bless( $self, $class );    # Bind self to class
    my $ptr = Giovanni::Util::lockFile( $self->{_FILE} );
    $self->{_LIST} = $self->read();    # Read in history items
    Giovanni::Util::unlockFile($ptr);
    return $self;
}

# Method to add event items to history
sub addItems {
    my ( $self, $items ) = @_;
    die
        "Can't add items to the history since lookup attributes have not been specified."
        unless defined $self->{_UNIQUE_KEY_ATTRIBUTES};
    my $lookupAttrs = $self->{_UNIQUE_KEY_ATTRIBUTES};
    my $allKeys = $self->getUniqueAttributeCombinationsAndKeys($lookupAttrs);
    foreach my $newItem ( @{$items} ) {
        my $key = $self->getItemKey( $newItem, $lookupAttrs );
        push( @{ $self->{_LIST} }, $newItem ) unless exists $allKeys->{$key};
    }
}

# Read history from json file
sub read {
    my ($self) = @_;
    my $historyItems = [];
    if ( $self->{_FILE} && -f $self->{_FILE} ) {
        my $historyStr = do {
            local $/ = undef;
            open my $fh, "<", $self->{_FILE}
                or die "could not open $self->{_FILE}: $!";
            <$fh>;
        };
        eval { $historyItems = decode_json($historyStr); };
        $historyItems = [] if ($@);
    }
    return $historyItems;
}

# Method to write history
sub write {
    my ( $self, $file ) = @_;
    $file = ( exists $self->{_FILE} ? $self->{_FILE} : undef )
        unless defined $file;

    die "Can't write history since history file is not specified"
        unless defined $file;

    my $ptr               = Giovanni::Util::lockFile($file);
    my $savedHistoryItems = $self->read();
    $self->addItems($savedHistoryItems);

    open my $fh, ">", $file;
    print $fh JSON->new->canonical->pretty->encode( $self->{_LIST} );
    close $fh;

    Giovanni::Util::unlockFile($ptr);
}

# Returns a string representing hash key of a perl hash
# Currently - just a canonical JSON with certain tags stripped out
sub getHashCompareStr {
    my ( $self, $someHash, $ignoreKeys ) = @_;
    $someHash = Giovanni::Util::unifyJsonNumbers( dclone $someHash);
    my $json    = JSON->new->allow_nonref->allow_blessed->canonical(1);
    my $jsonStr = $json->encode($someHash);
    for my $key ( @{$ignoreKeys} ) {

        # This assumes json is a flat string with no new lines
        $jsonStr =~ s/(\"$key\".*?)([\,\}])/$2/g;
        $jsonStr =~ s/(,)([\,\}])/$2/g;
    }
    return $jsonStr;
}

# Compares deeply two hashes, with an option to ignore certain tags
sub compareHashes {
    my ( $self, $hashA, $hashB, $ignoreKeys ) = @_;
    my $hashAstr = $self->getHashCompareStr( $hashA, $ignoreKeys );
    my $hashBstr = $self->getHashCompareStr( $hashB, $ignoreKeys );
    return $hashAstr eq $hashBstr;
}

# Compares two values in a semi-smart way
sub compareValues {
    my ( $self, $input, $item, $key, $ignoreHashKeys ) = @_;
    return 0 unless defined $input->{$key} && defined $item->{$key};
    return $input->{$key} eq $item->{$key}
        if ref $input->{$key} eq '' && ref $item->{$key} eq '';
    return $self->compareHashes( $input->{$key}, $item->{$key},
        $ignoreHashKeys )
        if ref $input->{$key} eq 'HASH' && ref $item->{$key} eq 'HASH';
    return $self->compareHashes( $input->{$key}, $item->{$key},
        $ignoreHashKeys )
        if ref $input->{$key} eq 'ARRAY' && ref $item->{$key} eq 'ARRAY';
    return ( first_index { $_ eq $input->{$key} } @{ $item->{$key} } ) != -1
        if ref $input->{$key} eq '' && ref $item->{$key} eq 'ARRAY';
    return ( first_index { $_ eq $item->{$key} } @{ $input->{$key} } ) != -1
        if ref $input->{$key} eq 'ARRAY' && ref $item->{$key} eq '';
    return 0;
}

# Method to find an "event" in history
sub find {
    my ( $self, $input ) = @_;
    my @ignoreHashKeys = ('Label');

    # If no criterion is defined, return all members in history
    return $self->{_LIST} unless keys %{$input};

    # Loop through each item in history and see if it matches the query
    my $matchedItemList = [];
    foreach my $item ( @{ $self->{_LIST} } ) {
        my $matchingItem = 1;
        foreach my $key ( keys %{$input} ) {
            $matchingItem = 0
                if (
                !$self->compareValues(
                    $input, $item, $key, \@ignoreHashKeys
                )
                );
            last unless $matchingItem;
        }
        push( @{$matchedItemList}, $item ) if $matchingItem;
    }
    return $matchedItemList;
}

# Return ID (used in getUniqueAttributeCombinations)
sub getItemKey {
    my ( $self, $item, $keys ) = @_;
    my $key = join( '^^^',
        map { defined $item->{$_} ? $item->{$_} : "###" } @$keys );
    return $key;
}

# Returns all unique combinations of the supplied attributes in the history items
sub getUniqueAttributeCombinationsAndKeys {
    my ( $self, $keys, $query ) = @_;
    my $res   = {};
    my $items = $self->{_LIST};
    $items = $self->find($query) if defined $query;
    foreach my $item ( @{$items} ) {
        my $key = $self->getItemKey( $item, $keys );
        my %values = map { $_ => $item->{$_} } @$keys;
        $res->{$key} = \%values unless exists $res->{$key};
    }
    return $res;
}

# Returns all unique value combinations of the given keys from history
# (e.g., all combinations of datafile-image tuple)
sub getUniqueAttributeCombinations {
    my ( $self, $keys, $query ) = @_;
    return [
        values
            %{ $self->getUniqueAttributeCombinationsAndKeys( $keys, $query ) }
    ];
}

1;
__END__
