#!/usr/bin/perl

=pod

=head1 NAME

deleteCacheFiles - deletes files from the cache safely.

=head1 SYNOPSIS

  perl deleteCacheFiles.pl filesToDelete.txt

=head1 DESCRIPTION

Deletes files in cache after locking db file so nothing else can edit cache
for a variable that is being modified.

=head2 INPUT

The input file should have the files to delete, one file per line. The input
file can list cache files for multiple variables. E.g. -

    /var/giovanni/cache/TRMM_3B42_Daily_7_precipitation/2000/scrubbed.TRMM_3B42_Daily_7_precipitation.20000101.nc
    /var/giovanni/cache/TRMM_3B42_Daily_7_precipitation/2000/scrubbed.TRMM_3B42_Daily_7_precipitation.20000102.nc
    /var/giovanni/cache/TRMM_3B42_Daily_7_precipitation/2000/scrubbed.TRMM_3B42_Daily_7_precipitation.20000103.nc
    /var/giovanni/cache/TRMM_3B43_7_precipitation/2007/scrubbed.TRMM_3B43_7_precipitation.20070101.nc

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use strict;
use warnings;
use Dev::Tools;

if ( scalar(@ARGV) == 0 ) {
    die "$0 'path to catalog directory'";
}

my $first = shift(@ARGV);

if ( $first eq '-h' ) {
    print "Usage: $0 /path/to/list/file.txt";
    exit(0);
}

my $listFile = $first;
if ( !( -e $listFile ) ) {
    die "List file $listFile does not exist";
}

my @filesToDelete = ();
open( FILE, "<", $listFile ) or die "Unable to open $listFile";
while ( my $line = <FILE> ) {

    if ( !( $line =~ /^\s*$/ ) ) {
        chomp($line);
        push( @filesToDelete, $line );
    }
}
close(FILE);
chomp(@filesToDelete);

Dev::Tools::deleteCacheFiles(
    FILE_LIST => \@filesToDelete,
    VERBOSE   => 1
);

1;
