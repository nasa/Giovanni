#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 65;

BEGIN { use_ok('Giovanni::Untaint') }

# regular expressions for input
my %INPUT_REGEX = (
    bbox        => qr/^([\+\-\d.,NSEW ]*)$/,
    data        => qr/^([A-Za-z \d_=.,:(){}\[\]\^\-\/]+)$/,
    dataKeyword => qr/^([\w\s\-\(\)\._,]+)$/,
    filename    => qr/^([\d\w\_\-\.]+)$/,
    flag        => qr/^([1])$/,
    number      => qr/^([\d.\-\+eE]+)$/,
    months      => qr/^([\d,]+)$/,
    options     => qr/^((\{.+\})|(\[.+\]))$/,
    portal      => qr/(AEROSTAT|MAPSS|YOTC|MULTISENSOR|GIOVANNI)$/,
    seasons     => qr/^([DJFMASON,]+)$/,
    service =>
        qr/^(DiArAvTs|CrLt|HvLt|CrTm|HiGm|TmAvSc|CoMp|ArAvTs|TmAvMp|MpAn|CACHE|TmAvOvMp|StSc|VtPf|HvLn|QuCl|InTs|ZnMn|CrLn|DiTmAvMp|IaSc|AcMp|ArAvSc)$/,
    shape => '^([A-Za-z\d_]+/[A-Za-z\d_]+)?$',
    time  => qr/^([\d\-:TZ]+)$/,
    uuid  => qr/^([A-Za-z\d-]+)$/,
    url =>
        qr/^([\w|\-|\.|\:|\/|\?|#|\[|\]|@|!|$|&|'|\(|\)|\*|\+|,|;|=|%|~]+)$/,
    variableFacets => qr@[\w\- ]+:[/\w\-,. ]+;@,
);

# create untainting object
my $untaint = Giovanni::Untaint->new( INPUT_REGEX => \%INPUT_REGEX );

##
# number
##

my $number = '-12.5';
my ( $success, $untainted ) = $untaint->number($number);
ok( $success, "negative float untainted" );
is( $untainted, $number, "negative float untainted" );

$number = '-3e+2';
( $success, $untainted ) = $untaint->number($number);
ok( $success, "scientific notation float untainted" );
is( $untainted, $number, "scientific notation float untainted" );

$number = '+4';
( $success, $untainted ) = $untaint->number($number);
ok( $success, "positive integer untainted" );
is( $untainted, $number, "positive untainted" );

$number = '4';
( $success, $untainted ) = $untaint->number($number);
ok( $success, "integer untainted" );
is( $untainted, $number, "integer untainted" );

$number = '4.3.4';
( $success, $untainted ) = $untaint->number($number);
ok( !$success, "not a number" );
is( $untainted, '', "not a number" );

##
# session/resultset/result untainting
##
my $session   = '77F95C94-0AB2-11E9-AFA8-E88F1105CF9E';
my $resultset = '78DB9208-09EA-11E9-AB27-EFD91105CF9E';
my $result    = '8BB52698-0AA1-11E9-8555-5CC1D9018B23';

# should work
( $success, $untainted ) = $untaint->UUID($session);
ok( $success, "session untainted" );
is( $untainted, $session, "session untainted" );

# should not work - not a UUID
( $success, $untainted ) = $untaint->UUID('77F95C94-0AB2-11E9-AFA8-');
ok( !$success, "bad session" );
is( $untainted, '', 'empty untainted string' );

# also should not work - bad characters
( $success, $untainted )
    = $untaint->UUID('..77F95C94-0AB2-11E9-AFA8-E88F1105CF9E');
ok( !$success, "bad session" );
is( $untainted, '', 'empty untainted string' );

# test all three
( $success, my @untainted_arr )
    = $untaint->result( $session, $resultset, $result );
ok( $success, 'successful on full result' );
is_deeply(
    \@untainted_arr,
    [ $session, $resultset, $result ],
    "Got untainted results"
);

# test all three with one that is bad
( $success, @untainted_arr )
    = $untaint->result( $session, 'lknasdf9', $result );
ok( !$success, "bad resultset" );
is_deeply( \@untainted_arr, [ '', '', '' ], 'empty untainted array' );

##
# Bounding box
##

my $bbox = '-180.0,-90,180,90';
( $success, $untainted ) = $untaint->bbox($bbox);
ok( $success, 'valid bounding box' );
is( $untainted, $bbox, 'untainted bounding box' );

$bbox = '-180';
( $success, $untainted ) = $untaint->bbox($bbox);
ok( !$success, 'incomplete bounding box' );
is( $untainted, '', 'no untainted box' );

$bbox = 'oinweot';
( $success, $untainted ) = $untaint->bbox($bbox);
ok( !$success, 'bad characters' );
is( $untainted, '', 'bad characters' );

$bbox = '-9.9.9,2,2,2';
( $success, $untainted ) = $untaint->bbox($bbox);
ok( !$success, 'not a number' );
is( $untainted, '', 'not a number' );

$bbox = '180W, 90S, 180E, 90N';
( $success, $untainted ) = $untaint->bbox($bbox);
ok( $success, "untainted easting/northing bounding box" );
is( $untainted, $bbox );

$bbox = '-270, -180, 90, 180';
( $success, $untainted ) = $untaint->bbox($bbox);
ok( $success, "weird openlayers bounding box" );
is( $untainted, $bbox );

##
# Filename
##

my $filename = 'hello.txt';
( $success, $untainted ) = $untaint->filename($filename);
ok( $success, 'recognized filename' );
is( $untainted, $filename, 'recognized filename' );
( $success, $untainted ) = $untaint->filename( $filename, '.txt' );
ok( $success, 'recognized extension' );
is( $untainted, $filename, 'recognized extension' );
( $success, $untainted ) = $untaint->filename( $filename, '.nc' );
ok( !$success, 'bad extension' );
is( $untainted, '', 'bad extension' );

$filename = '.';
( $success, $untainted ) = $untaint->filename($filename);
ok( !$success, 'not a filename' );
is( $untainted, '', 'not a filename' );

##
# URL
##

# trusted servers
my @TRUSTED_SERVERS
    = ( '.ecs.nasa.gov', '.gesdisc.eosdis.nasa.gov', '.gsfc.nasa.gov' );

my $url
    = 'https://giovanni.gsfc.nasa.gov:1000/giovanni/#service=AcMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-31T23:59:59Z&variableFacets=dataProductTimeInterval%3Amonthly%3B';
( $success, $untainted ) = $untaint->url( $url, \@TRUSTED_SERVERS );
ok( $success, 'url is valid' );
is( $untainted, $url, 'url is valid' );
( $success, $untainted ) = $untaint->url( $url, ['.ecs.nasa.gov'] );
ok( !$success, 'url has bad host' );
is( $untainted, '', 'has bad host' );

$url = 'file:///path/to/something';
( $success, $untainted ) = $untaint->url( $url, \@TRUSTED_SERVERS );
ok( !$success, 'file uri' );
is( $untainted, '', 'file uri' );

$url = 'htt://clearly_wrong.gesdisc.eosdis.nasa.gov';
( $success, $untainted ) = $untaint->url( $url, \@TRUSTED_SERVERS );
ok( !$success, 'bad scheme, so no host' );
is( $untainted, '', 'bad scheme, so no host' );

$url
    = './daac-bin/agmap.pl?LAYERS=TRMM_3B42_Daily_7_precipitation&SLD=https%3A%2F%2Fdev.gesdisc.eosdis.nasa.gov%2Fsession%2FB69FADBE-1033-11E9-8D95-915F1205CF9E%2FC6BFACA8-1033-11E9-A388-C65F1205CF9E%2FC6C24756-1033-11E9-A388-C65F1205CF9E%2F%2FTRMM_3B42_Daily_7_precipitation_57200_1546615033buylrd_div_12_panoply_sld.xml';
( $success, $untainted ) = $untaint->url( $url, \@TRUSTED_SERVERS );
ok( $success, "can handle relative URLs" );
is( $url, $untainted, "can hangle relative URLs" );

##
# Time
##

my $time = "2010-01-01T00:00:00Z";
( $success, $untainted ) = $untaint->time($time);
ok( $success, 'parsed a time string' );
is( $untainted, $time, 'parsed a time string' );

$time = "2010-01-01T00:00:00Z/2010-01-01T23:59:59Z";
( $success, $untainted ) = $untaint->time($time);
ok( $success, 'parsed a time range' );
is( $untainted, $time, 'parsed a time range' );

$time = "2010-01-01T00:00:90";
( $success, $untainted ) = $untaint->time($time);
ok( !$success, 'not a valid time' );
is( $untainted, '', 'not a valid time' );

##
# Layers
##

my $layers = "US_states,countries,grid1-8,TRMM_3B42RT_daily";
( $success, $untainted ) = $untaint->layers($layers);
ok( $success, 'parsed layers' );
is( $untainted, $layers, 'parsed layers' );

$layers = 'grid01,Something*not*correct,coastline';
( $success, $untainted ) = $untaint->layers($layers);
ok( !$success, 'bad layer' );
is( $untainted, '', 'bad layer' );

##
# JSON
##

my $json = '{  "string": "Hello World" }';
( $success, $untainted ) = $untaint->json($json);
ok( $success, 'simple json string' );
is( $untainted, $json, 'simple json string' );

$json = '{  "string": "Hello World"" }';
( $success, $untainted ) = $untaint->json($json);
ok( !$success, 'bad json' );
is( $untainted, '', 'bad json' );
