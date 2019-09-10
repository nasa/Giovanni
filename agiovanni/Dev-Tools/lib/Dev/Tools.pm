#$Id: Tools.pm,v 1.12 2015/03/04 17:21:50 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Dev::Tools;

use 5.008008;
use strict;
use warnings;
use Fcntl qw(:flock);
use DB_File;
use File::Path qw(rmtree);
use File::Copy;
use File::Basename;
use Cwd 'abs_path';
use Giovanni::Cache::Metadata;

our $VERSION = '0.01';

# flush STDOUT
$| = 1;

sub cleanCacheDb {
    my (%params) = @_;

    if ( !defined( $params{'CACHE_DIR'} ) ) {
        die "CACHE_DIR is required for cleaning the cache db files";
    }

    my @regions = ();
    if ( defined( $params{'REGIONS'} ) ) {
        @regions = @{ $params{'REGIONS'} };
    }
    else {

        # get all the regions in the cache directory
        @regions = _getRegions( $params{'CACHE_DIR'} );
    }

    if ( !defined( $params{'VERBOSE'} ) ) {
        $params{'VERBOSE'} = 0;
    }

    if ( !defined( $params{'SHOULD_DELETE'} ) ){
        $params{SHOULD_DELETE} = 1;
    }

    my $outHash = {};
    for my $region (@regions) {
        my $result = _cleanOneRegionCacheDb(
            CACHE_DIR     => $params{'CACHE_DIR'},
            REGION        => $region,
            VERBOSE       => $params{'VERBOSE'},
            NEED_LOCK     => $params{'NEED_LOCK'},
            SHOULD_DELETE => $params{'SHOULD_DELETE'},
        );
        if ( scalar( keys( %{$result} ) ) > 0 ) {
            $outHash->{$region} = $result;
        }
    }
    return $outHash;
}

sub _getRegions {
    my ($cacheDir) = @_;
    my @regions = ();

    # get all the regions in the cache directory
    opendir DIR, $cacheDir
        or die "Could not open directory: $!";
    while ( my $file = readdir(DIR) ) {
        if ( $file =~ s/[.]db$// ) {
            push( @regions, $file );
        }
    }
    close(DIR);
    return @regions;
}

# Cleans the cache db file for one region.
sub _cleanOneRegionCacheDb {
    my (%params) = @_;
    my $dir      = $params{CACHE_DIR};
    my $region   = $params{REGION};
    my $verbose  = $params{VERBOSE};
    my $needLock = 1;
    if ( defined( $params{NEED_LOCK} ) ) {
        $needLock = $params{NEED_LOCK};
    }
    my $delete = 1;
    if ( defined( $params{SHOULD_DELETE} ) ) {
        $delete = $params{SHOULD_DELETE};
    }

    print "Checking region $region" if $verbose;

    my $cacheDb   = "$dir/$region.db";
    my $lockFile  = "$dir/$region.db.lock";

    my $outHash = {};

    # get the lock
    if ($needLock) {
        if ( open( FH, ">$lockFile" ) ) {
            flock( FH, LOCK_EX );
        }
        else {
            print "\n" if $verbose;
            warn "Unable to obtain lock file for $lockFile";
            return;
        }
    }

    # NOTE: usually, the parser would have more columns, but we just need
    # the first column, which is 'PATH'.
    my $meta = Giovanni::Cache::Metadata->new(COLUMNS=>['PATH']);

    # open the cache db file
    if (tie my %dbHash,
        "DB_File", $cacheDb, O_RDWR | O_CREAT,
        0666, $DB_HASH
        )
    {
        my $numEntries = scalar( keys(%dbHash) );
        print " ($numEntries entries) ...\n" if $verbose;

        # go through all the keys and make sure the corresponding files
        # actually exist.
        my $entry = 0;
        for my $key ( keys(%dbHash) ) {

            if ( !defined( $dbHash{$key} ) ) {

                # check to make sure the key actually points to something in
                # the DB file. It always should, but you never know.
                warn "Key $key for $region points to nothing in .db file!";
                if ( $delete ) {
                    print "      Removing key ($key)\n" if $verbose;
                    delete $dbHash{$key};
                }
            }
            else {
                my $path = $meta->decode( $dbHash{$key} )->{PATH};

                # check to see if the file for this cache entry exists
                my $fullPath = "$dir/$path";
                if ( !( -e $fullPath ) ) {
                    if ( !$verbose ) {
                        $outHash->{$key} = $fullPath;
                    }
                    else {
                        if ($delete) {
                            print
                                "      Removing missing file $dbHash{$key} ($key)\n"
                                if $verbose && $delete;
                        }
                    }

                    if ($delete){
                        delete $dbHash{$key};
                    }
                }
            }
            $entry++;
            if ( $entry % 10000 eq 0 ) {
                print
                    "   Done looking at entry $entry of $numEntries for $region\n"
                    if $verbose;
            }
        }
        untie %dbHash;

    }
    else {
        warn "Unable to read cache db file: $cacheDb";
    }

    # release the lock
    if ($needLock) {
        flock( FH, LOCK_UN );
    }
    print "... done $region\n" if $verbose;
    return $outHash;
}

sub correctCacheKeys {
    my (%params)    = @_;
    my $dbFile      = $params{"DB_FILE"};
    my $regex       = $params{"REGEX"};
    my $replacement = $params{"REPLACEMENT"};

    my $verbose = 0;
    if ( exists( $params{"VERBOSE"} ) ) {
        $verbose = $params{"VERBOSE"};
    }

    # open the cache db file
    print "Tying db file $dbFile\n" if $verbose;
    my $numEntriesChanged = 0;
    if (tie my %dbHash,
        "DB_File", $dbFile, O_RDWR | O_CREAT,
        0666, $DB_HASH
        )
    {
        my $numEntries = scalar( keys(%dbHash) );
        print "$numEntries entries in db file ...\n" if $verbose;

        # go through all the keys and fix any that
        my $entry = 0;
        for my $key ( keys(%dbHash) ) {
            if ( $key =~ /$regex/ ) {
                my $newKey = $key;
                $newKey =~ s/$regex/$replacement/;
                $dbHash{$newKey} = $dbHash{$key};
                delete $dbHash{$key};
                $numEntriesChanged++;
            }

            $entry++;
            if ( $entry % 10000 eq 0 ) {
                print
                    "   Done looking at entry $entry of $numEntries. $numEntriesChanged changed.\n"
                    if $verbose;
            }
        }
        print " Done with db changes. Untying.\n" if $verbose;
        untie %dbHash;
        print " Done untying.\n" if $verbose;
    }

    return $numEntriesChanged;

}

sub deleteCacheFiles {
    my (%params) = @_;
    my $verbose = 0;
    if ( $params{VERBOSE} ) {
        $verbose = 1;
    }
    my @fileList = @{ $params{FILE_LIST} };

    # figure out which files are associated with which db files
    my $dbHash = _sortFilesToDelete(@fileList);
    for my $db ( keys( %{$dbHash} ) ) {

        # lock this db file
        my $dbLock = "$db.lock";
        if ( open( FH, ">", "$dbLock" ) ) {
            flock( FH, LOCK_EX );
        }
        else {
            die "Unable to obtain lock on $dbLock";
        }

        # delete all the files associated with this db files
        if ($verbose) {
            print "About to delete files:";
            for my $file ( @{ $dbHash->{$db} } ) {
                print " $file";
            }
            print "\n";
        }
        unlink @{ $dbHash->{$db} };

        # clean up the db file
        my $cacheDir = dirname($db);

        # the db file is <region>.db. Pull out 'region'
        my $basename = basename($db);
        my $region;
        if ( $basename =~ /^(.*)[.]db$/ ) {
            $region = $1;
        }
        else {

            # unlock this db file
            flock( FH, LOCK_UN );
            die "Unable to find region from db file $db";
        }

        cleanCacheDb(
            REGIONS   => [$region],
            CACHE_DIR => $cacheDir,
            VERBOSE   => $verbose,
            NEED_LOCK => 0,
        );

        # unlock this db file
        flock( FH, LOCK_UN );

    }

}

# Get a hash of db files to files we want to delete.
sub _sortFilesToDelete {
    my @fileList = @_;

    my $dbHash = {};
    for my $file (@fileList) {
        if ( -f $file ) {
            my $dbFile = _getDbFile($file);
            if ( !defined($dbFile) ) {
                warn "Unable to find db file for $file. Skipping.\n";
            }
            else {
                push( @{ $dbHash->{$dbFile} }, $file );
            }
        }
        else {
            warn "Unable to find file $file. Skipping.\n";
        }
    }

    return $dbHash;
}

# Get the db file for a particular cache file
sub _getDbFile {
    my ($file) = @_;

    # The db should be at the parent directory or grandparent directory level,
    # depending on whether or not there is a second level region. Start with
    # the parent directory.
    my $parentDir      = dirname($file);
    my $basename       = basename($parentDir);
    my $grandParentDir = dirname($parentDir);
    if ( -f ("$grandParentDir/$basename.db") ) {
        return abs_path("$grandParentDir/$basename.db");
    }

    # Not in the parent directory level, so try one more up
    $basename = basename($grandParentDir);
    my $greatGrandParentDir = dirname($grandParentDir);
    if ( -f ("$greatGrandParentDir/$basename.db") ) {
        return abs_path("$greatGrandParentDir/$basename.db");
    }

    # okay ... no luck
    return undef;
}

1;
__END__

=head1 NAME

Dev::Tools - Perl extension for helper functions

=head1 SYNOPSIS

   use Dev::Tools;

   my $outHash = Dev::Tools::deleteSearchCache( CACHE_DIR => "/path/to/cache" );
   $outHash = Dev::Tools::cleanCacheDb( CACHE_DIR => "/path/to/cache" );

=head1 DESCRIPTION

Helper functions for dev tools.

=head2 FUNCTION $outHash = Dev::Tools::cleanCacheDb( CACHE_DIR => "/path/to/cache" [, REGIONS => \@regions] )

Cleans cache db files to remove key entries for files that don't exist.

=head3 CACHE_DIR

Location of the cache

=head3 REGIONS (optional)

An array of regions to clean. By default, all are cleaned.

=head3 OUTPUT

Returns a hash of hashes with the key/file pairs that were removed for each 
region. $outHash->{region}->{key} will give you the file path of a missing file
for key 'key' in region 'region'.

=head2 FUNCTION $numChanged = Dev::Tools::correctCacheKeys(DB_FILE=>"/path/to/file.db", REGEX=>"thingToReplace", REPLACEMENT=>"somethingNew")

Goes through the db file and compares each key using the regex. If the regex 
matches, the matched string will be replaced.

NOTE: This is NOT thread-safe. It does not use the lock file.

=head3 DB_FILE

The location of the .db file.

=head3 REGEX

The expression to compare each key to.

=head3 REPLACEMENT

The replacement string.

=head3 OUTPUT

The number of changed entries.

=head2 FUNCTION my ( $numChanged, $numMoved ) = Dev::Tools::correctCacheFiles( CACHE_DIR => $cacheDir, REGION => "region", REGEX => 'thingToReplace', REPLACEMENT => 'somethingNew');

Goes through the db file and compares each file to the regex. If the regex 
matches, the file will be updated in the db file. Will also move the entry in
the cache to the new name. Should be thread safe because the db file gets 
locked.

=head3 CACHE_DIR

Cache directory

=head3 REGION

Level 1 cache region to check

=head3 REGEX

The expression to compare each file to.

=head3 REPLACEMENT

The replacement string.

=head3 OUTPUT

The number of changed entries and the number of files moved in the cache.

=head2 FUNCTION Dev::Tools::deleteCacheFiles(FILE_LIST=> "/path/to/file/list.txt");

Takes a list of files in the cache to delete and deletes them safely, cleaning
the .db file up to make sure there are no dangling keys. This function can
safely be used operationally because it locks the .db files while it is
working on them.

=head 3 FILE_LIST

An array of files to delete.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut
