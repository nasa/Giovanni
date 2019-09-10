#!/usr/bin/perl

=head1 NAME

stageGiovanniData - stages scrubbed data files

=head1 SYNOPSIS

  stageGiovanniData.pl --datafield-info-file file \
                       --data-url-file file \
                       --output file \
                       --cache-root-path '/path/to/file/cache' \
                       --time-out 10 \
                       --max-retry-count 3 \
                       --retry-interval 3 \
                       --chunk-size 20

=head1 DESCRIPTION

Stages data files in output file directory. Command line options are:

1. datafield-info-file - location of catalog file 

2. data-url-file - location of file with search URLs

3. output - output manifest file

4. no-stderr - if present, the logger will only log to a file, not to STDERR

5. time-out - how much time to wait for a URL download to finish

6. max-retry-count - the number of times to retry a URL

7. retry-interval - how long to wait between URL download tries

8. cache-root-path - if using the file cache, the location of the file cache

9. keep-going (optional) - if present, staging will continue to download and
scrub files even if some URLs are unavailable. It will still return non-zero.
By default, the code stops as soon as there is a bad URL.

10. log-filter-skip (optional) - if present, the code will cut back on the 
number of status messages it writes while downloading files. If the parameter
is set to 2, only every second URl will get user messages; if 3, only every
third URL; etc.

11. keep-raw-files (optional) - if present, the code will keep any files it
downloads to scrub.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
}

use 5.008008;
use strict;
use warnings;

use Giovanni::DataStager;
use Giovanni::Cache;
use Giovanni::Logger;
use Giovanni::Util;
use Getopt::Long;
use File::Basename;

my $callStr = $0;
for my $arg (@ARGV) {
    $callStr = "$callStr $arg";
}

# get the command line options
my $dataFieldInfoFile;
my $dataUrlFile;
my $outputFile;
my $chunkSize;
my $timeOut;
my $maxRetryCount;
my $retryInterval;
my $servlet;
my $cacheRootPath;
my $helpFlag;
my $noStderr;
my $keepGoing;
my $logFilterSkip = 1;
my $keepRawFiles;
my $giovanniCfg;

GetOptions(
    "datafield-info-file=s" => \$dataFieldInfoFile,
    "data-url-file=s"       => \$dataUrlFile,
    "output=s"              => \$outputFile,
    "chunk-size=s"          => \$chunkSize,
    "time-out=s"            => \$timeOut,
    "max-retry-count=s"     => \$maxRetryCount,
    "retry-interval=s"      => \$retryInterval,
    "servlet=s"             => \$servlet,
    "cache-root-path=s"     => \$cacheRootPath,
    "no-stderr"             => \$noStderr,
    "keep-going"            => \$keepGoing,
    "keep-raw-files"        => \$keepRawFiles,
    "log-filter-skip"       => \$logFilterSkip,
    "giovanni-cfg=s"        => \$giovanniCfg,
    "h"                     => \$helpFlag,
);

# if this is the help flag, print out the command line arguments
if ( defined($helpFlag) ) {
    die "$0 --data-field-info-file file --data-url-file file --output file "
        . "(--servlet 'http://whatever.com' | --cache-root-path '/path/to/file/cache')"
        . " [--time-out 10 --max-retry-count 3 --retry-interval 3 --chunk-size size]";
}

# Read the LOGIN_CREDENTIALS configuration variable needed for
# downloading files that require authentication. Read the columns in the cache.
my $cfgFile;
if ( defined($giovanniCfg) ) {
    $cfgFile = $giovanniCfg;
}
else {
    $cfgFile = ( defined $rootPath ? $rootPath : '/opt/giovanni4/' )
        . 'cfg/giovanni.cfg';
}

if ( !-e $cfgFile ) {
    die
        "Unable to find giovanni configuration file. Expected it to be $cfgFile.";
}

Giovanni::Util::ingestGiovanniEnv($cfgFile);

if ( !( defined($timeOut) ) ) {
    $timeOut = 10;
}
if ( !( defined($maxRetryCount) ) ) {
    $maxRetryCount = 3;
}
if ( !( defined($retryInterval) ) ) {
    $retryInterval = 3;
}
if ( !( defined($chunkSize) ) ) {
    $chunkSize = 50;
}

my ( $manifestFilename, $directory ) = fileparse($outputFile);
my $logger;
if ( defined($noStderr) ) {
    $logger = Giovanni::Logger->new(
        session_dir       => $directory,
        manifest_filename => $manifestFilename,
        no_stderr         => 1,
    );

}
else {
    $logger = Giovanni::Logger->new(
        session_dir       => $directory,
        manifest_filename => $manifestFilename,
    );
}

$logger->info($callStr);

my $cacher;
if ( defined($cacheRootPath) ) {

    $cacher = Giovanni::Cache->getCacher(
        TYPE            => "file",
        LOGGER          => $logger,
        CACHE_ROOT_PATH => $cacheRootPath,
        COLUMNS => \@GIOVANNI::CACHE_COLUMNS,
    );
}
else {
    my $msg = "Unable to create cacher. --cache-root-path option required.";
    $logger->error($msg);
    die($msg);
}

if ( defined($keepGoing) ) {
    $keepGoing = 1;
}
else {
    $keepGoing = 0;
}

my $stager = Giovanni::DataStager->new(
    DIRECTORY       => $directory,
    LOGGER          => $logger,
    CACHER          => $cacher,
    CHUNK_SIZE      => $chunkSize,
    TIME_OUT        => $timeOut,
    MAX_RETRY_COUNT => $maxRetryCount,
    RETRY_INTERVAL  => $retryInterval,
    KEEP_GOING      => $keepGoing,
    FILTER_SKIP     => $logFilterSkip,
    KEEP_RAW_FILES  => $keepRawFiles,
    CREDENTIALS     => $GIOVANNI::LOGIN_CREDENTIALS,
);

$stager->stage(
    URLS_FILE            => $dataUrlFile,
    DATA_FIELD_INFO_FILE => $dataFieldInfoFile,
    MANIFEST_FILENAME    => $manifestFilename,
);

1;
