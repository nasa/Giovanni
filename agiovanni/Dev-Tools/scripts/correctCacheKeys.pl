#!/usr/bin/perl

#$Id: correctCacheKeys.pl,v 1.2 2015/02/24 20:42:53 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

correctCacheKeys.pl - does a search and replace on cache keys

=head1 SYNOPSIS

  correctCacheKeys.pl --dbFile "/path/to/file.db" --regex "thing_to_replace" --replacement "new_thing"

  correctCacheKeys.pl --dbFileList "/path/to/dbFiles.txt" --regex "thing_to_replace" --replacement "new_thing"


=head1 DESCRIPTION

This goes through one or more db files and corrects cache keys. NOTE: this is 
not a thread-safe operation. Do not use this on 'live' cache db files. Copy the 
db file somewhere else, run the script there, and then copy the db file back.

For example, suppose there is a cache key 'some_cache_key', the regex is 'cache'
and the replacement is 'wonderful_cache'. After this command is called, the
key entry will be 'some_wonderful_cache_key'.

=head2 dbFile 

Location of the dbFile. Either this or 'dbFileList' must be specified. 

=head2 dbFileList

A text file with the locations of db files, one file per line. Either this or
'dbFile' must be specified.

=head2 regex

The regular expression to use on the cache keys.

=head2 replacement

The replacement string.


=head2 verbose

If this option is present, the code will print out status.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use 5.008008;
use strict;
use warnings;

use Getopt::Long;
use Dev::Tools;

# flush STDOUT
$| = 1;

# get the command line options

my $dbFile;
my $dbFileList;
my $regex;
my $replacement;
my $verbose = 0;
my $help    = 0;
Getopt::Long::GetOptions(
    'verbose'       => \$verbose,
    'h'             => \$help,
    'dbFile=s'      => \$dbFile,
    'dbFileList=s'  => \$dbFileList,
    'replacement=s' => \$replacement,
    'regex=s'       => \$regex,
);

if ($help) {
    die qq(Usage: $0 --dbFile "/path/to/file.db" )
        . qq(--regex "thing_to_replace" --replacement "new_thing");
}

if ( !defined($regex) ) {
    die "The --regex option is required";
}
if ( !defined($replacement) ) {
    die "The --replacement option is required";
}

my @dbFiles = ();
if ( defined($dbFile) ) {
    push( @dbFiles, $dbFile );
}
if ( defined($dbFileList) ) {
    open( FILE, "<", $dbFileList ) or die "Unable to open $dbFileList: $!";
    my @lines = <FILE>;
    chomp(@lines);
    push( @dbFiles, @lines );
    close(FILE);
}

if ( scalar(@dbFiles) == 0 ) {
    die "No db files to update";
}

my $numFiles = scalar(@dbFiles);
for ( my $i = 0; $i < $numFiles; $i++ ) {
    my $file = $dbFiles[$i];
    print "Correcting file " . ( $i + 1 ) . " of $numFiles ($file) ...\n"
        if $verbose;

    my $numEntriesChanged = Dev::Tools::correctCacheKeys(
        DB_FILE     => $file,
        REGEX       => $regex,
        REPLACEMENT => $replacement,
        VERBOSE     => $verbose
    );

    print "Changed $numEntriesChanged entries.\n"
        if $verbose;
    print "Corrected file " . ( $i + 1 ) . " of $numFiles ($file).\n"
        if $verbose;
}

1;
