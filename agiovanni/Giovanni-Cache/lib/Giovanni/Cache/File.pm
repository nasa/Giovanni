package Giovanni::Cache::File;

use strict;
use File::Temp;
use File::Basename;
use File::Copy;
use DB_File;
use Fcntl qw(:flock);
use Safe;
require Exporter;
use Giovanni::Cache::Metadata;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.0';

sub new {
    my ( $class, %input ) = @_;
    my $self = {
        _LOGGER => ( exists $input{LOGGER} ? $input{LOGGER} : undef ),
        _CACHE_DIR => (
            exists $input{CACHE_DIR} ? $input{CACHE_DIR}
            : ( exists $input{CACHE_ROOT_PATH} ? $input{CACHE_ROOT_PATH}
                : undef
            )
        ),
    };

    my @columns = exists( $input{COLUMNS} ) ? @{ $input{COLUMNS} } : ();
    $self->{_META_ENCODE_DECODE}
        = Giovanni::Cache::Metadata->new( COLUMNS => [ "PATH", @columns ] );

    return bless( $self, $class );
}

# Arguments: DIRECTORY, KEYS, FILENAMES, REGION_LEVEL_1, REGION_LEVEL_2
sub put {
    my ( $self, %input ) = @_;

    my $logger = $self->{_LOGGER};

    # A list to hold files that were cached successfully
    my @results = ();
    $logger->user_msg("Preparing to cache data") if defined $logger;

    # Check if the directory with files to be cached exists
    unless ( exists $input{DIRECTORY} && ( -d $input{DIRECTORY} ) ) {
        if ( defined $logger ) {
            $logger->error(
                "Directory with files to be cached not defined or doesn't exist"
            );
            $logger->user_msg("Unable to cache data");
        }
        return @results;
    }

    # Check if cache keys are supplied
    unless ( exists $input{KEYS} && ( ref $input{KEYS} eq 'ARRAY' ) ) {
        if ( defined $logger ) {
            $logger->error("Keys for items to be cached not defined");
            $logger->user_msg("Unable to cache data");
        }
        return @results;
    }

    # Check if files to be cached are supplied
    unless ( exists $input{FILENAMES}
        && ( ref $input{FILENAMES} eq 'ARRAY' ) )
    {
        if ( defined $logger ) {
            $logger->error("Files to be cached not defined");
            $logger->user_msg("Unable to cache data");
        }
        return @results;
    }

    # Check if cache region is specified
    unless ( exists $input{REGION_LEVEL_1} ) {
        if ( defined $logger ) {
            $logger->error("Cache region not defined");
            $logger->user_msg("Unable to cache data");
        }
        return @results;
    }

    # Check whether the number of files matches with number of supplied keys
    my $fileCount = @{ $input{FILENAMES} };
    unless ( $fileCount == @{ $input{KEYS} } ) {
        if ( defined $logger ) {
            $logger->error("File and keys count don't match");
            $logger->user_msg("Unable to cache data");
        }
        return @results;
    }

    # Check whether the number of metadata hashes matches the number of
    # supplied keys. Metadata is optional, so it can be zero.
    my $metaCount = exists( $input{METADATA} ) ? @{ $input{METADATA} } : 0;
    unless ( $metaCount == @{ $input{KEYS} } || $metaCount == 0 ) {
        if ( defined $logger ) {
            $logger->error("Metadata and keys count don't match");
            $logger->user_msg("Unable to cache data");
        }
        return @results;
    }

    # Set umask for r+w by group
    my $oldMask = umask(002);

    # Create cache directory if one doesn't exist
    my $cacheDir = $self->{_CACHE_DIR} . '/' . $input{REGION_LEVEL_1} . '/';
    my @dirList  = ($cacheDir);

    if ( exists $input{REGION_LEVEL_2} ) {
        $cacheDir .= "$input{REGION_LEVEL_2}/";
        push( @dirList, $cacheDir );
    }

    foreach my $dir ( sort @dirList ) {
        unless ( -d $dir ) {
            unless ( mkdir( $dir, 0775 ) ) {
                if ( defined $logger ) {
                    $logger->error("Failed to create $dir ($!)");
                    $logger->user_msg("Unable to cache data");
                }
                umask($oldMask);
                return @results;
            }
        }
    }

    my $cacheSubDir
        = $input{REGION_LEVEL_1} . '/'
        . (
        exists $input{REGION_LEVEL_2} ? $input{REGION_LEVEL_2} . '/' : '' );

    # Generate keys
    my @keyList
        = ( ref $input{KEYS} eq 'ARRAY' )
        ? @{ $input{KEYS} }
        : ( $input{KEYS} );

    # Encode the metadata information
    my @encoded = ();

    for ( my $i = 0; $i < $fileCount; $i++ ) {
        my $path = qq($cacheSubDir/$input{FILENAMES}->[$i]);
        my %input = $metaCount == 0 ? () : %{ $input{METADATA}->[$i] };
        $input{PATH} = $path;
        push( @encoded, $self->{_META_ENCODE_DECODE}->encode(%input) );
    }

    my $tmpFileHash = {};
    for ( my $i = 0; $i < $fileCount; $i++ ) {
        my ( $fh, $tmpFileName ) = File::Temp::tempfile(
            'fileCacheXXXXXXXX',
            DIR    => $cacheDir,
            UNLINK => 1
        );
        my $srcFile = qq($input{DIRECTORY}/$input{FILENAMES}->[$i]);

        # Check for file's existence
        next unless -e $srcFile;

        # Flush out the file handle
        my $flag = copy( $srcFile, $tmpFileName );
        unless ($flag) {
            $logger->error("Failed to copy $srcFile to $tmpFileName")
                if defined $logger;
        }
        close($fh);
        $tmpFileHash->{ $keyList[$i] } = $tmpFileName;
    }

    # Ready to cache files
    my %dbHash = ();
    local (*FH);
    my $dbFile   = qq($self->{_CACHE_DIR}/$input{REGION_LEVEL_1}.db);
    my $lockFile = $dbFile . '.lock';
    if ( open( FH, ">$lockFile" ) ) {
        flock( FH, LOCK_EX );
    }
    else {
        $logger->error("Failed to get a lock on $dbFile") if defined $logger;
    }

    # Save DB Hash for untie'ing
    if ( tie %dbHash, "DB_File", $dbFile, O_RDWR | O_CREAT, 0666, $DB_HASH ) {

        # Save the ref to DB Hash for untie'ing in the destructor if necessary
        $self->{__DB_HASH} = \%dbHash;
        for ( my $i = 0; $i < $fileCount; $i++ ) {
            my $cacheFileName = qq($cacheDir/$input{FILENAMES}->[$i]);
            my $tmpFileName   = $tmpFileHash->{ $keyList[$i] };

            # Change file permissions just so that rename won't fail
            chmod( 0664, $cacheFileName ) if ( -f $cacheFileName );

            # Rename files at the end
            rename( $tmpFileName, $cacheFileName );
            chmod( 0444, $cacheFileName );
            $dbHash{ $keyList[$i] } = $encoded[$i];
            push( @results, $input{KEYS}->[$i] );
        }
        untie(%dbHash);

        # Delete __DB_HASH as we don't need to untie it again
        delete $self->{__DB_HASH};
    }

    # Set the umask to old value
    umask($oldMask);
    flock( FH, LOCK_UN );
    return @results;
}

# Parameters: { KEYS => [...], REGION_LEVEL_1 => "...", DIRECTORY => "..."
sub get {
    my ( $self, %input ) = @_;
    my $logger = $self->{_LOGGER};

    $logger->user_msg("Staging data files from the cache") if defined $logger;

    # Set umask for r+w by group
    my $oldMask = umask(002);

    # Find matching files in cache
    my $result = $self->select(
        KEYS           => $input{KEYS},
        REGION_LEVEL_1 => $input{REGION_LEVEL_1}
    );

    # Try to symlink to files in cache
    my $out = {};
    foreach my $key ( keys %$result ) {
        my $cacheFile = qq($self->{_CACHE_DIR}/$result->{$key}->{PATH});
        next unless -f $cacheFile;
        my $fileName  = basename($cacheFile);
        my $localFile = qq($input{DIRECTORY}/$fileName);
        $cacheFile = ( $cacheFile =~ /^((\w|-|\/|\:|\.|\+)+)/ ) ? $1 : '';
        $localFile = ( $localFile =~ /^((\w|-|\/|\:|\.|\+)+)/ ) ? $1 : '';
        my $flag = symlink( $cacheFile, $localFile );
        if ($flag) {
            $out->{$key}->{FILENAME} = $fileName;
            delete $result->{$key}->{PATH};
            $out->{$key}->{METADATA} = $result->{$key};
        }
        else {
            $logger->error("Failed to find $key in cache");
        }
    }

    # Reset umask
    umask($oldMask);

    return $out;
}

# Parameters: { KEYS => [...], REGION_LEVEL_1 => "..." }
sub select {
    my ( $self, %input ) = @_;
    my $logger = $self->{_LOGGER};

    $logger->user_msg("Locating data files in the cache")
        if defined $logger;

    # A hash ref to hold items that were found in cache
    my $result = {};
    return $result unless ( exists $self->{_CACHE_DIR} );

    # Check if cache keys are supplied
    unless ( exists $input{KEYS} ) {
        $logger->error("Cache keys not specified");
        $logger->user_msg("Failed to find data in cache ");
        return $result;
    }
    unless ( exists $input{REGION_LEVEL_1} ) {
        $logger->error("Cache region not specified");
        $logger->user_msg("Failed to find data in cache ");
        return $result;
    }

    # Get the list of keys
    my @keyList
        = ( ref $input{KEYS} eq 'ARRAY' )
        ? @{ $input{KEYS} }
        : ( $input{KEYS} );
    my @dbKeyList
        = ( ref $input{KEYS} eq 'ARRAY' )
        ? @{ $input{KEYS} }
        : ( $input{KEYS} );

    # Form the db file name
    my $dbFile = qq($self->{_CACHE_DIR}/$input{REGION_LEVEL_1}.db);

    # A hash tied to database
    my %dbHash = ();

    # Use file locks to safely access the database
    my $lockFile = $dbFile . '.lock';
    local (*FH);
    if ( open( FH, ">$lockFile" ) ) {
        flock( FH, LOCK_EX );
    }
    else {
        flock( FH, LOCK_UN );
        $logger->error("Unable to get a lock on cache database");
        $logger->user_msg("Failed to find data in cache ");
        return $result;
    }

    # Tie the hash to database
    # Save the reference to %dbHash in case it was not untied
    # when Giovanni::Cache::File object is not untied
    $self->{__DB_HASH} = \%dbHash;
    if ( tie %dbHash, "DB_File", $dbFile, O_RDWR | O_CREAT, 0666, $DB_HASH ) {
        for ( my $i = 0; $i < @keyList; $i++ ) {
            if ( exists $dbHash{ $dbKeyList[$i] } ) {
                my $decoded = $self->{_META_ENCODE_DECODE}
                    ->decode( $dbHash{ $dbKeyList[$i] } );
                $result->{ $keyList[$i] } = $decoded;
            }
        }
        untie %dbHash;

        # No need for __DB_HASH after untie'ing the hash
        delete $self->{__DB_HASH};
    }
    else {
        $logger->error("Failed to tie $dbFile ($!)") if defined $logger;
    }
    flock( FH, LOCK_UN );
    return $result;
}

# Destructor
# 1. Unties the DB hash if it still exists. Its existence indicates that it was not untied.
sub DESTROY {
    my ($self) = @_;

    untie %{ $self->{__DB_HASH} } if exists $self->{__DB_HASH};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::Cache::File - a file-based module for putting data into cache or getting data file from cache

=head1 SYNOPSIS

  use Giovanni::Cache::File;
  
  my $cacher = Giovanni::Cache::File->new(LOGGER => $logger,
                                          CACHE_ROOT_PATH => '/var/tmp/www/cache',
                                          COLUMNS => [ "STARTTIME", "ENDTIME", "TIME", "DATAMONTH", "DATADAY" ]);
  
  my @successKeys = $cacher->put(DIRECTORY => "/var/tmp/www/TS2/giovanni/session_dir",
                                 KEYS => \['key1', 'key2'],
					FILENAMES => \['filename1.nc', 'filename2.nc'],
					REGION_LEVEL_1 => 'MOD08_D3',
					REGION_LEVEL_2 => '',
					);

  my %results = $cacher->get(DIRECTORY => "/var/tmp/www/TS2/giovanni/session_dir",
                             KEYS => \['key1', 'key2'],
					REGION_LEVEL_1 => 'MOD08_D3',
					REGION_LEVEL_2 => '',
					);

=head1 DESCRIPTION

Note that this class is not thread safe.

constructor -- new()

requires two parameters -- LOGGER and CACHE_ROOT_PATH

	LOGGER -- a Logger.pm object
	
	CACHE_ROOT_PATH (or CACHE_DIR) -- a system file path to the root path of the cache

	COLUMNS -- the cache metadata columns. Please note that 'PATH' is a reserved column header

get() -- a subroutine to retrieve files from cache by using a soft link to the target cache file

	inputs: requires a hash with following keys
	
		DIRECTORY -- a working directory; required
		
		KEYS -- an array of keys; required
		
		REGION_LEVEL_1 -- a cache region (usually same as dataset name); required
		
		REGION_LEVEL_2 -- a cache sub-region; optional
		
    return:
	    
		a hash with key/file and metadata pairs. $ret->{$key}->{FILENAME},
		$ret->{$key}->{METADATA}->{STARTTIME}, ...
		
put() -- subroutine to put data into the data

	inputs: requires a hash with following keys

		DIRECTORY -- a working directory; required
		
		KEYS -- an array of keys; required
		
		FILENAMES -- an array of filenames; required
		
		REGION_LEVEL_1 -- a cache region (usually same as dataset name); required
		
		REGION_LEVEL_2 -- a cache sub-region; optional	
	
	
=head2 EXPORT

export get() and put()

=head1 SEE ALSO

Also check the perldoc in Cache.pm

=head1 AUTHOR

Mahabaleshwara Hegde, E<lt>maha.hegde@nasa.gov:w<gt>

=cut
