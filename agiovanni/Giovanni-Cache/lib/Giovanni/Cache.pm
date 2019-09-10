#$Id: Cache.pm,v 1.11 2014/07/15 14:22:59 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::Cache;

use 5.008008;
use strict;
use warnings;
use Switch;
use File::Temp qw/tempdir/;
use Giovanni::Cache::File;

our $VERSION = '0.01';

sub getCacher {
    my ( $pkg, %params ) = @_;

    # make sure we've got the cache type
    if ( !( exists $params{"TYPE"} ) ) {
        die "Must have 'TYPE' parameter";
    }

    my $cacher;
    switch ( $params{"TYPE"} ) {
        case 'file' {
            $cacher = Giovanni::Cache::File->new(%params);
        }
        default {
            die "Unknown type '" . $params{"TYPE"} . "'";
        }
    }

    return $cacher;
}

1;
__END__

=head1 NAME

Giovanni::Cache - gives access to giovanni cache

=head1 SYNOPSIS

  use Giovanni::Cache;
  
  ...
  
  my $cacher = Giovanni::Cache->getCacher(
     TYPE      => "file", 
     LOGGER    => $logger,
     CACHE_DIR => "/var/tmp/whatever",
     COLUMNS   => [ "STARTTIME", "ENDTIME", "TIME", "DATAPERIOD" ]
  );
  
  # put something in the cache
  my $fileHash = {};
  
  $fileHash->{firstKey} = "firstFilename.txt";
  my $dir = "/path/to/directory/of/files";
  my @successKeys = $cacher->put(
     DIRECTORY        => $dir,
     KEYS             => ["firstKey"],
     FILENAMES        => ["firstFilename.txt"],
     METADATA         => [ { STARTTIME  => '1451606400',
                             ENDTIME    => '1451692799',
                             TIME       => '1451606400',
                             DATAPERIOD => 20160101 } ],
     REGION_LEVEL_1   => "something",
  );
  
  # get it back out again
  my $out = $cache->get(
     DIRECTORY      => $dir,
     KEYS           => \@successKeys,
     REGION_LEVEL_1 => "something",
  );
  
  is($out->{firstKey}->{FILENAME},"firstFilename.txt");
  is($out->{firstKey}->{METADATA}->{TIME}, "1451606400");

=head1 DESCRIPTION

Gets different kinds of cachers. Currently, there in only one cache:
 
1. file - See documentation for Giovanni::Cache::File.
 
=head2 PUT

Put files in the cache. The inputs are:

DIRECTORY - the directory with all the file you want to put in the cache

KEYS - an array of keys

FILENAMES = an array of the filenames associated with KEYS

REGION_LEVEL_1 - the region for all the files

REGION_LEVEL_2 (optional) - secondary cache region under REGION_LEVEL_1

METADATA (optional) - metadata associated with a particular cache key

The output is a list of keys that were successfully put in the cache.

=head2 GET

Get files out of the cache. The inputs are:

DIRECTORY - the destination directory for the files

KEYS - an array of keys to get out of the cache

REGION_LEVEL_1 - cache region for the files

REGION_LEVEL_2 (optional) - secondary cache region under REGION_LEVEL_1

The output is a hash from keys to filenames and metadata for the files that the
cache could retrieve.

=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>

=cut
