#!/usr/bin/perl

#########################
use File::Spec;
use File::Basename;
use Safe;
use File::Temp qw/ tempdir /;
use Digest::MD5;
use Giovanni::Logger;

use Test::More tests => 8;
## BEGIN { use_ok('Giovanni::Cache::File') }
BEGIN { use_ok('Giovanni::Cache') }

my $testrootpath = tempdir( CLEANUP => 0 );
my $workingdir = "$testrootpath/testdata";
`mkdir -p $workingdir`;

ok( ( -d $workingdir ), "Working directory: $workingdir" );

# make sure the directory is readable/writable by everyone
chmod 0777, $workingdir;

## to generate the source testing file, and the expected file
my $filename = "";
my $ncfile   = "";
while (<DATA>) {
    if ( $_ =~ /^FILE=/ ) {
        $filename = $_;
        $filename =~ s/^FILE=//;
        chomp($filename);
        $filename = "$workingdir/$filename";
        open FH, ">", "$filename";
        next;
    }
    if ( $_ =~ /^ENDFILE/ ) {
        close(FH);
        ok( ( -f $filename ), "Create \"$filename\"" );
        next;
    }
    my $line = $_;
    print FH $line;
}

# create a logger
my $taskName = "mfst.fake+stuff.xml";
my $logger   = Giovanni::Logger->new(
    session_dir       => $workingdir,
    manifest_filename => $taskName
);

# make a couple of temporary files to cache

my $firstFile = "test1.txt";
my $firstKey  = "977D4ECA-F3A4-11E2-8CAD-5A9B8788D312";

my $secondFile = "test2.txt";
my $secondKey  = "DE625E7E-F3A0-11E2-8EDE-1A848788D312";
my $cachePath  = "$testrootpath/cache";
`mkdir -p $cachePath`;
ok( ( -d $cachePath ), "Caching directory: $cachePath" );


my $cacher = Giovanni::Cache->getCacher(
    TYPE      => "file",
    LOGGER    => $logger,
    CACHE_DIR => $cachePath
);

# put one file in the cache
my @successKeys = ();

my %inputs = ();
$inputs{DIRECTORY} = $workingdir;
my @keys = ();
push( @keys, $firstKey );
push( @keys, $secondKey );
my @files = ();
push( @files, $firstFile );
push( @files, $secondFile );

$inputs{KEYS}           = \@keys;
$inputs{FILENAMES}      = \@files;
$inputs{REGION_LEVEL_1} = "testregion";
$inputs{REGION_LEVEL_2} = "subregion";
eval { @successKeys = $cacher->put(%inputs); };
if ($@) {
    print STDERR "ERROR failed to put to cache: $!\n";
}

my $successCount = scalar(@successKeys);
ok( $successCount == 2, "There are 2 keys" );

@successKeys = sort(@successKeys);
@allKeys = sort( ( $firstKey, $secondKey ) );
is_deeply( \@successKeys, \@allKeys, "Put files in the cache" );

## to test the get() data from cache -- a soft link to the cached data file created in workingdir
# to clean the files in $workingdir
`rm -f $workingdir/*`;
my %expects = ();
$expects{$firstKey}->{FILENAME}  = "$firstFile";
$expects{$firstKey}->{METADATA}  = {};
$expects{$secondKey}->{FILENAME} = "$secondFile";
$expects{$secondKey}->{METADATA} = {};
my $results = $cacher->get(%inputs);    ## return a hash reference

is_deeply( $results, \%expects, "Get files from the cache" );

1;

__DATA__
FILE=test1.txt
sub first 1
sub frist 2
ENDFILE
FILE=test2.txt
sub second 1
sub second 2
ENDFILE
