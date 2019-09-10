#!/usr/bin/perl

use strict;
use DB_File;
use Fcntl ':flock';
use File::Temp;
use File::Copy;
use Getopt::Long;
use Safe;
use Giovanni::Cache::Metadata;

use Giovanni::Util;

# get the command line options
my $giovanniCfg;
my $varId;
my $dbFile;
my $helpFlag;

GetOptions(
    "cfg=s" => \$giovanniCfg,
    "id=s"  => \$varId,
    "db=s"  => \$dbFile,
    "h"     => \$helpFlag,
);

if ( defined($helpFlag) ) {
    die "$0 --cfg 'path to giovanni cfg file' "
        . "[ --id 'variable id' | "
        . "--db 'db file' ]";
}

# find the giovanni.cfg file
if ( !defined($giovanniCfg) ) {

    # guess the location of the cfg file
    if ( -f "/opt/giovanni4/cfg/giovanni.cfg" ) {
        $giovanniCfg = "/opt/giovanni4/cfg/giovanni.cfg";
    }
    else {
        die "Unable to find giovanni.cfg. Please use --cfg option.";
    }
}
if ( !( -f $giovanniCfg ) ) {
    die "$giovanniCfg does not exist";
}

# parse giovanni.cfg
my $cpt = Safe->new('GIOVANNI');
if ( !( $cpt->rdo($giovanniCfg) ) ) {
    die "Unable to parse $giovanniCfg";
}

# cache configuration stuff
my $cacheDir = $GIOVANNI::CACHE_DIR;
my @cacheColumns
    = defined(@GIOVANNI::CACHE_COLUMNS) ? @GIOVANNI::CACHE_COLUMNS : ();

if ( !defined($dbFile) ) {

    # didn't get db file from input, so use variable id
    if ( !defined($varId) ) {
        die "Must specify either the location of the db file (--db) "
            . "or the variable id (--id).";
    }

    $dbFile = "$cacheDir/$varId" . ".db";
}

if ( !-f $dbFile ) {
    die "Unable to find db file $dbFile.";
}

my $result = ::select($dbFile);
exit(1) unless defined $result;
my $meta
    = Giovanni::Cache::Metadata->new( COLUMNS => [ "PATH", @cacheColumns ] );
foreach my $key ( keys %$result ) {
    my $outHash = $meta->decode( $result->{$key} );
    my $path    = $outHash->{"PATH"};
    print "$key: $path (";
    for my $column (@cacheColumns) {
        print " $column=" . $outHash->{$column};

    }
    print " )\n";
}

# Returns the contents of a cache db file as a hash.
sub select {
    my ($dbFile) = @_;
    my %dbHash   = ();
    my $result   = {};

    # Make a copy of the file
    my $tmpFile = tmpnam();
    unless ( File::Copy::copy( $dbFile, $tmpFile ) ) {
        print STDERR "Failed to make a copy of $dbFile.\n";
        return undef;
    }

    # Lock the file
    my $lockFile = $tmpFile . '.lock';
    local (*FH);
    if ( open( FH, ">$lockFile" ) ) {
        flock( FH, LOCK_EX );
    }
    else {
        print STDERR "Failed to obtain lock on $tmpFile.\n";
        return undef;
    }

    # Read the db file
    if ( tie %dbHash, "DB_File", $tmpFile, O_RDONLY, 0666, $DB_HASH ) {

        foreach my $key ( keys %dbHash ) {
            $result->{$key} = $dbHash{$key};
        }

        untie %dbHash;
    }
    else {
        print STDERR "Failed to open $tmpFile($!).\n";
        return undef;
    }
    flock( FH, LOCK_UN );
    unlink $lockFile if ( -O $lockFile );
    return $result;
}

=pod

=head1 Synopsis

listGiovanniCacheDb.pl --cfg /path/to/giovanni.cfg \
[--id TRMM_3B42_Daily_precipitation_V7 |
--db /path/to/TRMM_3B42_Daily_precipitation_V7.db]

=head1 Description

Script lists the cache db file content, an item per line as
"key: path ( COL1=value1 COL2=value2 )". It makes a copy of the db file before
reading.

Command line options:

--cfg (optional) - location of giovanni.cfg. Defaults to
/opt/giovanni4/cfg/giovanni.cfg.

--id - id of variable to list. Must be specified if --db option is not used

--db - location of the database file to list. Must be specified if --id option
is not used.

=head1 Example

listGiovanniCacheDb.pl --id TRMM_3B42_Daily_precipitation_V7

=cut

