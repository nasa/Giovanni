#$Id: Dev-Tools.t,v 1.2 2015/01/15 14:58:35 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Cache.t'

#########################

use strict;
use warnings;

use File::Temp qw/ tempdir /;
use Giovanni::Logger;
use Giovanni::Cache;

use Test::More tests => 7;
BEGIN { use_ok('Dev::Tools') }

# setup a cache somewhere
my $cacheDir   = tempdir();
my $workingDir = tempdir();
my $logger     = Giovanni::Logger->new(
    session_dir       => $workingDir,
    manifest_filename => 'mfst.whatever+blah.xml'
);
my $cacher = Giovanni::Cache->getCacher(
    TYPE      => 'file',
    LOGGER    => $logger,
    CACHE_DIR => $cacheDir
);

# put some stuff in the cache
putInCache( "key1", "file1", "region_A", "hello world" );
putInCache( "key2", "file2", "region_A", "hello world" );
putInCache( "key3", "file3", "region_A", "hello world" );

putInCache( "key1", "file1", "region_B", "hello world" );
putInCache( "key2", "file2", "region_B", "hello world" );
putInCache( "key3", "file3", "region_B", "hello world" );

# now selectively remove a couple of files
chmod 0644, "$cacheDir/region_A/file1";
unlink("$cacheDir/region_A/file1");

chmod 0644, "$cacheDir/region_B/file2";
unlink("$cacheDir/region_B/file2");

my $outHash = Dev::Tools::cleanCacheDb( CACHE_DIR => $cacheDir );

is( scalar( keys( %{ $outHash->{region_A} } ) ),
    1, "One region A file missing" );
ok( defined( $outHash->{region_A}->{key1} ),
    "Correct missing file for region A"
);
is( scalar( keys( %{ $outHash->{region_B} } ) ),
    1, "One region B file missing" );

ok( defined( $outHash->{region_B}->{key2} ),
    "Correct missing file for region B"
);

$outHash = Dev::Tools::cleanCacheDb( CACHE_DIR => $cacheDir, VERBOSE => 0 );

is( scalar( %{$outHash} ), 0, "No more missing files" );

# put something back in the cache
putInCache( "key1", "file1", "region_A", "hello world" );

# remove it.
chmod 0644, "$cacheDir/region_A/file1";
unlink("$cacheDir/region_A/file1");

# call the clean cache code with VERBOSE set to 1. The output hash should now
# be empty.
$outHash = Dev::Tools::cleanCacheDb( CACHE_DIR => $cacheDir, VERBOSE => 1 );
is( scalar( %{$outHash} ), 0,
    'In verbose mode, return hash is always empty' );

sub putInCache {
    my ( $key, $filename, $region, $contents ) = @_;
    my $dir = tempdir( CLEANUP => 1 );
    open( OUT, ">", "$dir/$filename" ) or die $!;
    print OUT $contents;
    close(OUT);
    $cacher->put(
        DIRECTORY      => $dir,
        KEYS           => [$key],
        FILENAMES      => [$filename],
        REGION_LEVEL_1 => $region
    );
}
