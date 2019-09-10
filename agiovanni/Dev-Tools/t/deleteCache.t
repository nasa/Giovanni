#$Id: deleteCache.t,v 1.2 2014/04/16 14:24:00 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-BoundingBox.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;

use strict;
use warnings;

use FindBin qw($Bin);
use File::Basename;
use File::Temp qw/ tempdir /;
use Giovanni::Cache;
use Giovanni::Logger;

my $workingDir = tempdir( CLEANUP => 1 );
my $stagingDir = "$workingDir/staging";
mkdir($stagingDir);
my $outDir = "$workingDir/out";
mkdir($outDir);

# setup a cache somewhere
my $cacheDir = tempdir();
my $logger   = Giovanni::Logger->new(
    session_dir       => $workingDir,
    manifest_filename => 'mfst.whatever+blah.xml'
);
my $cacher = Giovanni::Cache->getCacher(
    TYPE      => 'file',
    LOGGER    => $logger,
    CACHE_DIR => $cacheDir
);

# put some stuff in the cache
mkdir("$workingDir/staging");
my $file1 = "$stagingDir/file1.txt";
open FILE, ">", $file1 or die $!;
print FILE "first file\n";
close(FILE);

my $file2 = "$stagingDir/file2.txt";
open FILE, ">", $file2 or die $!;
print FILE "second file\n";
close(FILE);

$cacher->put(
    DIRECTORY      => $stagingDir,
    KEYS           => ["file1"],
    FILENAMES      => ["file1.txt"],
    REGION_LEVEL_1 => "REGION_1",
);

#  make sure we can get the file
my $hash = $cacher->get(
    DIRECTORY      => $outDir,
    KEYS           => ["file1"],
    REGION_LEVEL_1 => "REGION_1"
);
ok( $hash->{file1}, "File exists in REGION_1" );
cleanOutDir($outDir);

$cacher->put(
    DIRECTORY      => $stagingDir,
    KEYS           => ["file2"],
    FILENAMES      => ["file2.txt"],
    REGION_LEVEL_1 => "REGION_2",
    REGION_LEVEL_2 => "2",
);
$hash = $cacher->get(
    DIRECTORY      => $outDir,
    KEYS           => ["file2"],
    REGION_LEVEL_1 => "REGION_2"
);
ok( $hash->{file2}, "File exists in REGION_2" );
cleanOutDir($outDir);

# find the script we are going to call
my $script = findScript('deleteCache.pl');
ok( -e $script, "Found script" ) or die;

## CALL THE SCRIPT ##
my $cmd = "$script $cacheDir REGION_1";
my $ret = system($cmd);
ok( $ret == 0, "Command returned $ret: $cmd" ) or die $!;

# make sure the file is gone
$hash = $cacher->get(
    DIRECTORY      => $outDir,
    KEYS           => ["file1"],
    REGION_LEVEL_1 => "REGION_1"
);
ok( !$hash->{file1}, "File gone from REGION_1" );
cleanOutDir($outDir);

# but the second file is still there...
$hash = $cacher->get(
    DIRECTORY      => $outDir,
    KEYS           => ["file2"],
    REGION_LEVEL_1 => "REGION_2"
);
ok( $hash->{file2}, "File exists in REGION_2" );
cleanOutDir($outDir);

## Call the script on the other region ##
$cmd = "$script $cacheDir REGION_2";
$ret = system($cmd);
ok( $ret == 0, "Command returned $ret: $cmd" ) or die $!;

# make sure the second file is now gone
$hash = $cacher->get(
    DIRECTORY      => $outDir,
    KEYS           => ["file2"],
    REGION_LEVEL_1 => "REGION_2"
);
ok( !$hash->{file2}, "File gone from REGION_2" );
cleanOutDir($outDir);

# Delete all the files in a directory. Does not look at subdirectories.
sub cleanOutDir {
    my ($outDir) = @_;
    opendir( DIR, $outDir );
    my @files = ();
    while ( my $file = readdir(DIR) ) {
        if ( -f "$outDir/$file" ) {
            push( @files, "$outDir/$file" );
        }
    }
    closedir(DIR);

    for my $file (@files) {
        unlink($file);
    }
}

# Find the script we're going to run.
sub findScript {
    my ($scriptName) = @_;

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
