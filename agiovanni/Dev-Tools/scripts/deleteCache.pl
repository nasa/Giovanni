#!/usr/bin/perl
#$Id: deleteCache.pl,v 1.4 2015/04/01 19:06:22 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=pod

=head1 NAME

deleteCache - deletes the cache for a particular region

=head1 SYNOPSIS

  perl deleteCache.pl /path/to/cache MY_REGION
  perl deleteCache.pl /path/to/cache file_with_regions.txt

=head1 DESCRIPTION

Deletes the cache files and database file associated with a region. If the 
second input is a file, the code assumes it contains regions with one region
per line.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use strict;
use warnings;

use Fcntl qw(:flock);
use File::Path qw(remove_tree);

if ( scalar(@ARGV) != 2 ) {
    die
        "$0 'path to catalog directory' 'region to delete' OR $0 'path to catalog directory' 'file with regions'";
}
my $dir     = $ARGV[0];
my @regions = ();

if ( -f $ARGV[1] ) {
    open( FILE, "<", $ARGV[1] ) or die "Unable to open $ARGV[1]";
    chomp( @regions = <FILE> );
    close(FILE);
}
else {
    push( @regions, $ARGV[1] );
}

for my $region (@regions) {

    my $regionDir = "$dir/$region";
    my $cacheDb   = "$dir/$region.db";
    my $lockFile  = "$dir/$region.db.lock";

    if ( !( -e $cacheDb ) ) {

        # nothing to do!
        warn("Can't find database $cacheDb");
        exit();
    }

    # get the lock
    if ( open( FH, ">$lockFile" ) ) {
        flock( FH, LOCK_EX );
    }
    else {
        die "Unable to obtain lock file for $lockFile";
    }

    # delete the cache db file
    unlink $cacheDb or die "Could not delete cache db file: $cacheDb";

    # delete the directory of files
    remove_tree( $regionDir, verbose => 1, safe => 1 );

    if ( -e $regionDir ) {
        die "Unable to complete delete $regionDir";
    }

    # release the lock
    flock( FH, LOCK_UN );
    
    print "Done deleting region $region\n";
}