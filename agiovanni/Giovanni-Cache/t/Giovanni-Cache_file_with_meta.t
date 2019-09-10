#!/usr/bin/perl

#########################
use strict;
use warnings;
use File::Spec;
use File::Basename;
use Safe;
use File::Temp qw/ tempdir /;
use Digest::MD5;
use Giovanni::Logger;

use Test::More tests => 10;

BEGIN { use_ok('Giovanni::Cache') }

# setup directories for the stuff we are doing.
my $workingDir = tempdir( CLEANUP => 1 );
my $stagingDir = "$workingDir/staging";
mkdir($stagingDir) or die "Unable to make staging directory.";
my $cacheDir = "$workingDir/cache";
mkdir($cacheDir) or die "Unable to make cache directory.";

# define the test input
my $region    = "region";
my @testInput = (
    {   STRING   => "first line\nsecond line\n",
        FILENAME => "first.txt",
        KEY      => "KEY1",
        METADATA => {
            STARTTIME => "91234087",
            ENDTIME   => "91234087",
            TIME      => "91234087",
            DATADAY   => '',
            DATAMONTH => '',
        }
    },
    {   STRING   => "different text\n",
        FILENAME => "second.txt",
        KEY      => "KEY2",
        METADATA => {
            STARTTIME => '',
            ENDTIME   => '',
            TIME      => '',
            DATADAY   => '',
            DATAMONTH => "19800101",
        }
    },
);

# write the test input to a file
for my $input (@testInput) {
    $input->{PATH} = "$stagingDir/" . $input->{FILENAME};
    open( FILE, '>', $input->{PATH} );
    print $input->{STRING};
    close(FILE);
}

# create a logger
my $logger = Giovanni::Logger->new(
    session_dir       => $workingDir,
    manifest_filename => "mfst.fake+stuff.xml"
);

# get a cacher
my $columns = [ "STARTTIME", "ENDTIME", "TIME", "DATAMONTH", "DATADAY" ];
my $cacher = Giovanni::Cache->getCacher(
    TYPE      => "file",
    LOGGER    => $logger,
    CACHE_DIR => $cacheDir,
    COLUMNS   => $columns,
);

# cache the files!
my @successKeys = ();
my @keys = map( $_->{KEY}, @testInput );
eval {
    @successKeys = $cacher->put(
        DIRECTORY      => $stagingDir,
        KEYS           => \@keys,
        FILENAMES      => [ map( $_->{FILENAME}, @testInput ) ],
        METADATA       => [ map( $_->{METADATA}, @testInput ) ],
        REGION_LEVEL_1 => $region,
    );
};
if ($@) {
    print STDERR "ERROR failed to put to cache: $!\n";
    die;
}

# check that the cacher thinks it cached all the keys
is_deeply( \@successKeys, \@keys, 'Cached data' )
    or die;

# get the files out of the cache
my $cacheOut = $cacher->get(
    DIRECTORY      => $workingDir,
    KEYS           => \@keys,
    REGION_LEVEL_1 => $region
);

# check that we have entries for all the keys
my @outKeys = keys( %{$cacheOut} );
@outKeys = sort(@outKeys);
is_deeply( \@outKeys, \@keys, 'Got all keys out' )
    or die;

# make sure the metadata is correct
for my $input (@testInput) {
    is_deeply( $cacheOut->{ $input->{KEY} }->{METADATA},
        $input->{METADATA}, "Got the correct metadata for " . $input->{KEY} );
}

# make sure we got the files
for my $input (@testInput) {
    my $path = $workingDir . "/" . $input->{FILENAME};
    ok( -f $path, "File copied from cache" );

    # delete the file because we are going to get back out of the cache
    # again
    unlink($path);
}

# create a new cacher without the columns. It should still at least be able
# retrieve the files because the path is always the first column.
$cacher = Giovanni::Cache->getCacher(
    TYPE      => "file",
    LOGGER    => $logger,
    CACHE_DIR => $cacheDir,
    COLUMNS   => $columns,
);

# get the files out of the cache
$cacheOut = $cacher->get(
    DIRECTORY      => $workingDir,
    KEYS           => \@keys,
    REGION_LEVEL_1 => $region
);

@outKeys = keys( %{$cacheOut} );
@outKeys = sort(@outKeys);
is_deeply( \@outKeys, \@keys, 'Got all keys out' )
    or die;

for my $input (@testInput) {
    my $path = $workingDir . "/" . $input->{FILENAME};
    ok( -f $path, "File copied from cache" );
}
