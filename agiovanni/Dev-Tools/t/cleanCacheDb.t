#$Id: cleanCacheDb.t,v 1.4 2015/04/01 19:06:22 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-BoundingBox.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;

use strict;
use warnings;

use FindBin qw($Bin);
use File::Basename;
use File::Temp qw/ tempdir /;
use Giovanni::Logger;
use Giovanni::Cache;

# setup a cache somewhere
my $cacheDir   = tempdir( CLEANUP => 1 );
my $workingDir = tempdir( CLEANUP => 1 );
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

# find the script we are going to call
my $script = findScript('cleanCacheDb.pl');
ok( -e $script, "Found script" ) or die;

my $cmd = "$script $cacheDir";

my @out = `$cmd`;
ok( $? == 0, "Command returned non-zero:$cmd" );

my $shouldBe = <<OUT;
Checking region region_A (3 entries) ...
      Removing missing file region_A//file1 (key1)
... done region_A
Checking region region_B (3 entries) ...
      Removing missing file region_B//file2 (key2)
... done region_B
OUT

chomp(@out);
checkOutput( [ split( /\n/, $shouldBe ) ], \@out );

# run the command again. Everything should be correct now.
@out = `$cmd`;
ok( $? == 0, "Command returned non-zero:$cmd" );
$shouldBe = <<OUT;
Checking region region_A (2 entries) ...
... done region_A
Checking region region_B (2 entries) ...
... done region_B
OUT

chomp(@out);
checkOutput( [ split( /\n/, $shouldBe ) ], \@out );

sub checkOutput {
    my ( $shouldBe, $is ) = @_;

    # make sure they are the same length
    is( scalar(@$is), scalar(@$shouldBe), "Correct output length" );

    # make sure the output has all the correct lines, even if they are in
    # a different order
    my $hs = {};
    for my $line (@$is) {
        $hs->{$line} = 1;
    }

    for my $line (@$shouldBe) {
        ok( $hs->{$line}, "$line is in output" );
    }
}

sub findScript {
    my ($scriptName) = @_;

    # see if we can find the script relative to the test directory.
    my $dirname = dirname(__FILE__);
    my $script  = "$dirname/../scripts/$scriptName";

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

