#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

use Giovanni::Cache::Metadata;

my $columns
        = [ "PATH", "STARTTIME", "ENDTIME", "TIME", "DATAMONTH", "DATADAY" ];
my $meta = Giovanni::Cache::Metadata->new(COLUMNS=>$columns);

my $infoHash = {
    PATH      => "/var/path",
    STARTTIME => "1507918619",
    ENDTIME   => "1507918619",
    TIME      => "1507918619",
    DATAMONTH => '',
    DATADAY   => '',
};
my $encoded = $meta->encode( %{$infoHash} );
my $decoded = $meta->decode($encoded);
is_deeply( $decoded, $infoHash, 'encoded and decoded successfully' );

$meta = Giovanni::Cache::Metadata->new(
    DELIMITER => "*",
    COLUMNS   => [ 'first', 'second', 'third' ]
);

runEncodingTest( $meta, { first => 'one', second => 'two' },   "one*two*" );
runEncodingTest( $meta, { first => 'one', third  => 'three' }, "one**three" );

runDecodingTest( $meta, "1**3",
    { first => '1', second => '', third => '3' } );
runDecodingTest( $meta, "**", { first => '', second => '', third => '' } );

sub runDecodingTest {
    my ( $meta, $toDecode, $correct ) = @_;

    my $decoded = $meta->decode($toDecode);
    is_deeply( $decoded, $correct, "Got the right hash" );
}

sub runEncodingTest {
    my ( $meta, $toEncode, $correct ) = @_;

    my $encoded = $meta->encode( %{$toEncode} );
    is( $encoded, $correct,
        "Encoded " . $encoded . " expected " . $correct . "." );
}
