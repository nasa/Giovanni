#!/usr/bin/perl
#$Id: intersectBboxes.t,v 1.1 2014/10/07 14:07:20 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

use Test::More tests => 9;

use strict;
use warnings;

use FindBin qw($Bin);
use Giovanni::Util;

my $script = findScript("intersectBboxes.pl");
ok( -r $script, "Found script" );

my $cmd = "$script --bbox '-10,-10,10,10' --bbox '-5,-5,5,5'";
my @out = `$cmd`;
my $ret = $?;

is( $?, 0, "Command returned 0: $cmd" );
my $joined = join( "", @out );
Giovanni::Util::trim($joined);
is( $joined, "-5,-5,5,5", "correct intersection" );

$cmd = "$script --bbox '100,-90,-100,90' --bbox '-180,-90,170,90'";
@out = `$cmd`;
$ret = $?;
is( $?, 0, "Command returned 0: $cmd" );
Giovanni::Util::trim(@out);
is_deeply(
    \@out,
    [ '100,-90,170,90', '-180,-90,-100,90' ],
    "Got 2 output bounding boxes"
);

# check to make sure the justOneResult option works
$cmd = "$script --justOneResult --bbox '100,-90,-100,90' "
    . "--bbox '-180,-90,170,90'";
$ret = system($cmd);
isnt( $ret, 0,
    "Command returned non-zero for multiple bounding boxes: $cmd" );

# check to make sure we can pass an empty bounding box
$cmd = "$script --bbox '' --bbox '-5,-5,5,5'";
@out = `$cmd`;
$ret = $?;

is( $?, 0, "Command returned 0: $cmd" );
$joined = join( "", @out );
Giovanni::Util::trim($joined);
is( $joined, "-5,-5,5,5", "correct intersection with empty bounding box" );

# check that if we only pass an empty bounding box, there is an error.
$cmd = "$script --bbox ''";
@out = `$cmd`;
$ret = $?;
isnt( $?, 0,
    "Command returned non-zero for single empty bounding box: $cmd" )
    ;

sub findScript {
    my ($scriptName) = @_;

    # see if this is just next door (Christine's eclipse configuration)
    $script = "../scripts/$scriptName";

    unless ( -f $script ) {

        # see if we can find the script relative to our current location
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }

    return $script;
}

1;
