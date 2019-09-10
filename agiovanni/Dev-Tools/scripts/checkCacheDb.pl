#!/usr/bin/perl
#$Id: cleanCacheDb.pl,v 1.3 2015/01/14 14:58:46 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=pod

=head1 NAME

checkCacheDb - checks cache files to for key entries whose corresponding
files have disappeared. Does not change cache file!

=head1 SYNOPSIS

  perl checkCacheDb.pl /path/to/cache region_1 region_2 region_3 ...

=head1 DESCRIPTION

Check cache files to see if there are keys for missing data files.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use strict;
use warnings;
use Dev::Tools;

if ( scalar(@ARGV) == 0 ) {
    die "$0 'path to catalog directory region_1 region_2 ...'";
}

my $cacheDir = shift(@ARGV);

if ( !( -e $cacheDir ) ) {
    die "Cache directory $cacheDir does not exist";
}

my $out;
if ( scalar(@ARGV) > 0 ) {
    $out = Dev::Tools::cleanCacheDb(
        CACHE_DIR => $cacheDir,
        REGIONS   => \@ARGV,
        VERBOSE   => 0,
        SHOULD_DELETE    => 0
    );
    if ( scalar( keys( %{$out} ) ) == 0 ) {
        print "No missing files in cache\n";
    }
    else {
        print "Missing files (db file not modified):\n";
        for my $region ( keys( %{$out} ) ) {
            print "  REGION: $region\n";
            for my $key ( keys( %{ $out->{$region} } ) ) {
                my $file = $out->{$region}->{$key};
                print "    $file ($key)\n";
            }
        }
    }
}
else {
    die "Expecting regions";
}

1;
