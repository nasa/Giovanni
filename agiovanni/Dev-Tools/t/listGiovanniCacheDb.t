#$Id: cleanCacheDb.t,v 1.4 2015/04/01 19:06:22 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-BoundingBox.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

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
    CACHE_DIR => $cacheDir,
    COLUMNS   => [ "STARTTIME", "ENDTIME", "TIME", "DATAMONTH", "DATADAY" ]
);

# put daily stuff in one region
putInCache(
    "key1", "file1",
    "region_A",
    {   STARTTIME => "978307200",
        ENDTIME   => "978307200",
        TIME      => "978307200",
        DATADAY   => "20010101"
    },
    "hello world"
);
putInCache(
    "key2", "file2",
    "region_A",
    {   STARTTIME => "978393600",
        ENDTIME   => "978393600",
        TIME      => "978393600",
        DATADAY   => "20010102"
    },
    "hello world"
);
putInCache(
    "key3", "file3",
    "region_A",
    {   STARTTIME => "978480000",
        ENDTIME   => "978480000",
        TIME      => "978480000",
        DATADAY   => "20010103"
    },
    "hello world"
);

# put monthly stuff in another region
putInCache(
    "key1", "file1",
    "region_B",
    {   STARTTIME => "978307200",
        ENDTIME   => "978480000",
        TIME      => "978307200",
        DATAMONTH => "200101"
    },
    "hello world"
);
putInCache(
    "key2", "file2",
    "region_B",
    {   STARTTIME => "980985600",
        ENDTIME   => "983318400",
        TIME      => "980985600",
        DATAMONTH => "20010102"
    },
    "hello world"
);

# create a giovanni.cfg
my $cfgStr = <<"CFG";
\$CACHE_DIR = '$cacheDir';
\@CACHE_COLUMNS = ("STARTTIME", "ENDTIME", "TIME", "DATAMONTH", "DATADAY" );
CFG
my $cfgFile = "$workingDir/giovanni.cfg";
open( CFG, ">", $cfgFile ) or die $!;
print CFG $cfgStr;
close(CFG);

my $script = findScript("listGiovanniCacheDb.pl");

die "Unable to find script." unless ( -f $script );

my $cmd = "$script --cfg $cfgFile --id region_B";
my $correctOut = <<'OUT';
key2: region_B//file2 ( STARTTIME=980985600 ENDTIME=983318400 TIME=980985600 DATAMONTH=20010102 DATADAY= )
key1: region_B//file1 ( STARTTIME=978307200 ENDTIME=978480000 TIME=978307200 DATAMONTH=200101 DATADAY= )
OUT

runTest($cmd,$correctOut);

$cmd = "$script --cfg $cfgFile --id region_A";
$correctOut = <<'OUT';
key2: region_A//file2 ( STARTTIME=978393600 ENDTIME=978393600 TIME=978393600 DATAMONTH= DATADAY=20010102 )
key1: region_A//file1 ( STARTTIME=978307200 ENDTIME=978307200 TIME=978307200 DATAMONTH= DATADAY=20010101 )
key3: region_A//file3 ( STARTTIME=978480000 ENDTIME=978480000 TIME=978480000 DATAMONTH= DATADAY=20010103 )
OUT

runTest($cmd,$correctOut);

sub runTest{
    my ($cmd, $correctOut) = @_;

    my @out = `$cmd`;
    is($?,0, "Command returned 0: $cmd");
    is(join("",@out),$correctOut,"Got correct output");

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
    my ( $key, $filename, $region, $metadata, $contents ) = @_;
    my $dir = tempdir( CLEANUP => 1 );
    open( OUT, ">", "$dir/$filename" ) or die $!;
    print OUT $contents;
    close(OUT);
    $cacher->put(
        DIRECTORY      => $dir,
        KEYS           => [$key],
        FILENAMES      => [$filename],
        METADATA       => [$metadata],
        REGION_LEVEL_1 => $region,
    );
}

