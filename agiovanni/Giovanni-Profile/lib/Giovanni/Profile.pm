package Giovanni::Profile;

use 5.008008;
use strict;
use warnings;

require Exporter;

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

our $VERSION = '0.01';

# Preloaded methods go here.
use Safe;
use vars '$AUTOLOAD';
use File::Basename;
use JSON;

sub new() {
    my ( $class, %input ) = @_;
    my $self = {};
    my $profileDir;
    if ( (defined $input{profileDir}) && (length($input{profileDir}) > 0) ) {
        $profileDir = $input{profileDir};
    }
    unless ( defined $profileDir ) {
        $self->{_ERROR_MESSAGE} = 'No profile directory provided';
        $self->{_ERROR_TYPE}    = 1;
        return bless( $self, $class );
    }
    unless (-d $profileDir ) {
        $self->{_ERROR_MESSAGE} = 'Profile directory does not exist';
        $self->{_ERROR_TYPE}    = 2;
        return bless( $self, $class );
    }
    $self->{_PROFILE_DIR} = $profileDir;

    if ( (defined $input{uid}) && (length($input{uid}) > 0) ) {
        $self->{_UID} = $input{uid};
    }
    unless ( defined $self->{_UID} ) {
             $self->{_ERROR_MESSAGE} = 'No user id provided';
             $self->{_ERROR_TYPE}    = 3;
             return bless( $self, $class );
    }

    my $profileFile = $self->{_PROFILE_DIR} . '/profile_' . $self->{_UID} .'.json';

    if ( defined $input{profile}) {
        # Profile information was provided.
        # Check for valid structure.
        unless ( (exists $input{profile}->{PUBLIC}) ) {
            $self->{_ERROR_MESSAGE} = "PUBLIC section missing from profile";
            $self->{_ERROR_TYPE}    = 3;
            return bless( $self, $class );
        }

        # Check if the profile file already exists, and if so, read it and
        # verify that the user id found in the file matches the user id
        # provided as an argument.
        if (-f $profileFile) {
            # A profile information file already exists.
            my ($oldProfile, $profileError) = _readProfile($profileFile);
            if ( $oldProfile && defined($self->{_UID}) &&
                 ($self->{_UID} ne $oldProfile->{PUBLIC}->{uid}) ) {
                my $msg = "Found profile for existing user $oldProfile->{PUBLIC}->{uid} when attempting to save profile for $self->{_UID}\n";
                print STDERR $msg;
                $self->{_ERROR_MESSAGE} = $msg;
                $self->{_ERROR_TYPE}    = 4;
                return bless( $self, $class );
            } elsif ($profileError) {
                $self->{_ERROR_MESSAGE} = $profileError;
                $self->{_ERROR_TYPE}    = 4;
                return bless( $self, $class );
            }
        }

        # Expect that profile information is only being provided when
        # the user is logged in, so update the profile information file.
        $self->{_PROFILE} = $input{profile};
        $self->{_PROFILE}->{IS_LOGGED_IN} = "true";
        if (_writeProfile($self->{_UID}, $profileFile, $self->{_PROFILE})) {
            $self->{_PROFILE_FILE} = $profileFile;
        } else {
            $self->{_ERROR_MESSAGE} = "Error writing profile information file $profileFile";
            $self->{_ERROR_TYPE}    = 5;
        }
    } else {
        # No profile information was provided. Try to read existing
        # profile information.
        my ($existingProfile, $profileError) = _readProfile($profileFile);
        if ($existingProfile) {
            # Verify that user id in the profile file matches the user id
            # provided as an argument.
            if ( defined($self->{_UID}) ) {
                if ( $self->{_UID} eq $existingProfile->{PUBLIC}->{uid} ) {
                    $self->{_PROFILE}      = $existingProfile;
                    $self->{_PROFILE_FILE} = $profileFile;
                } else {
                    $self->{_ERROR_MESSAGE} = "Found profile for user other than $self->{_UID}";
                    $self->{_ERROR_TYPE}    = 6;
                }
            } else {
                $self->{_PROFILE} = $existingProfile;
                delete $self->{_PROFILE}->{PUBLIC};
                delete $self->{_PROFILE}->{PRIVATE};
                $self->{_PROFILE_FILE} = $profileFile;
            }
        } else {
            if ($profileError) {
                $self->{_ERROR_MESSAGE} = $profileError;
            } else {
                $self->{_ERROR_MESSAGE} = "Unknown error trying to read $profileFile";
            }
            $self->{_ERROR_TYPE} = 7;
        }
    }

    return bless( $self, $class );
}

sub _readProfile {
    my ( $profileFile ) = @_;

    # Read JSON profile file and return reference to a perl structure
    my $profile;
    if ($profileFile && -f $profileFile) {
        if ( open PROFILE, "< $profileFile" ) {
            local $/;
            my $profileJson = <PROFILE>;
            close(PROFILE);
            eval {$profile = decode_json( $profileJson );};
            return ($profile, $@);
        } else {
            # Error opening profile information file for reading
            return (undef, $!);
        }
    } else {
        # Profile information file does not exist
        return $profileFile ? (undef, "Profile file $profileFile not found") : (undef, "No profile file provided");
    }
}

sub _writeProfile {
    my ( $uid, $profileFile, $profile, $userSessionsStr ) = @_;

    umask 0007;
    if ($userSessionsStr) {
        # If $userSessionsStr has a value, convert it from a json
        # string to a perl reference, and store that reference
        # in the user_sessions element of the public profile
        my $userSessions = from_json($userSessionsStr);
        foreach my $id (keys(%{$userSessions->{userSessions}})) {
            # Keep only the session information associated with the
            # user id of this profile 
            delete $userSessions->{userSessions}->{$id} unless ($id eq $uid);
        }
        $profile->{PUBLIC}->{user_sessions} = $userSessions;
    }
    if (!$userSessionsStr && -f $profileFile) {
        # If $userSessionsStr does not have a value, and a profile file already
        # exists, don't overwrite it completely, first read the file and try to
        # obtain the user_sessions portion of the public profile, and if it
        # is found, add it to the public portion of the profile information
        # that is being written.
        if (open PROFILE, "+< $profileFile") { # Open for read/write
            local $/;
            my $profileJson = <PROFILE>;
            seek(PROFILE, 0, 0); # Go back to the start of the file
            my $oldProfile;
            eval {$oldProfile = decode_json( $profileJson );};
            if ($@) {
                print STDERR "Error decoding json in $profileFile: $@\n";
            } else {
                if (exists $oldProfile->{PUBLIC}->{user_sessions}) {
                    $profile->{PUBLIC}->{user_sessions} =
                        $oldProfile->{PUBLIC}->{user_sessions};
                } else {
                    print STDERR "No userSessions found in existing profile\n";
                    if (exists $profile->{PUBLIC}->{user_sessions}) {
                        print STDERR "Found new userSessions\n";
                    }
                }
            }
            #my $newProfile = encode_json($profile);
            my $newProfile = JSON->new->pretty(1)->encode($profile);
            print PROFILE $newProfile;
            truncate PROFILE, length($newProfile);
            close(PROFILE);
            return 1;
        } else {
            # Error opening profile information file for rewriting
            print STDERR "Error opening $profileFile for rewriting: $!\n";
            return 0;
        }
    } else {
        # No need to preserve existing public user_sessions
        if (open PROFILE, "> $profileFile") {
            #print PROFILE encode_json($profile);
            print PROFILE JSON->new->pretty(1)->encode($profile);
            close(PROFILE);
            return 1;
        } else {
            # Error opening profile information file for writing
            print STDERR "Error opening $profileFile for writing: $!\n";
            return 0;
        }
    }

}

sub _setUserSessions {
    my ( $self, $userSessions ) = @_;

    if (defined $userSessions) {
        $self->{_PROFILE}->{PUBLIC}->{user_sessions} = from_json($userSessions);
        return;
    } else {
        return;
    }
}

sub logout {
    my ( $self ) = @_;

    if ( $self->{_PROFILE} && exists $self->{_PROFILE}->{PUBLIC}->{uid} &&
         $self->{_UID} eq $self->{_PROFILE}->{PUBLIC}->{uid} ) {

        # A profile information file corresponding to the user id
        # and profile directory was read, and the user id in the file was
        # consistent with the user id used to find the file.
        # Set the logged-in state to false and update the profile
        # information file.
        $self->{_PROFILE}->{IS_LOGGED_IN} = "false";
        if (-f $self->{_PROFILE_FILE}) {
            return _writeProfile($self->{_UID}, $self->{_PROFILE_FILE}, $self->{_PROFILE});
        }
    }
}

sub updateUserSessions {
    my ( $self, $userSessions ) = @_;

    if ( $self->{_PROFILE} && exists $self->{_PROFILE}->{PUBLIC}->{uid} &&
         $self->{_UID} eq $self->{_PROFILE}->{PUBLIC}->{uid} ) {

        # A profile information file corresponding to the user id
        # and profile directory was read, and the user id in the file was
        # consistent with the user id used to find the file.
        # Set the logged-in state to false and update the profile
        # information file.
        if (-f $self->{_PROFILE_FILE}) {
            return _writeProfile($self->{_UID}, $self->{_PROFILE_FILE}, $self->{_PROFILE}, $userSessions);
        }
    }
}

sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    if ( $AUTOLOAD =~ /.*::onError$/ ) {
        return $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage$/ ) {
        return $self->{_ERROR_MESSAGE};
    }
    elsif ( $AUTOLOAD =~ /.*::getUserId$/ ) {
        return $self->{_UID};
    }
    elsif ( $AUTOLOAD =~ /.*::getProfileDir$/ ) {
        return $self->{_PROFILE_DIR};
    }
    elsif ( $AUTOLOAD =~ /.*::getPublicProfile$/ ) {
        if (exists $self->{_PROFILE}->{PUBLIC}) {
            return $self->{_PROFILE}->{PUBLIC};
        }
    }
    elsif ( $AUTOLOAD =~ /.*::isLoggedIn$/ ) {
        return (exists $self->{_PROFILE}->{IS_LOGGED_IN})
          && ($self->{_PROFILE}->{IS_LOGGED_IN} eq "true");
    }
    elsif ( $AUTOLOAD =~ /.*::getRoles$/ ) {
        if (exists $self->{_PROFILE}->{PUBLIC}->{roles}) {
            return $self->{_PROFILE}->{PUBLIC}->{roles};
        } else {
            return;
        }
    }
    elsif ( $AUTOLOAD =~ /.*::getUserSessions$/ ) {
        if (exists $self->{_PROFILE}->{PUBLIC}->{user_sessions}) {
            return $self->{_PROFILE}->{PUBLIC}->{user_sessions};
        } else {
            return;
        }
    }
    elsif ( $AUTOLOAD =~ /.*::getFirstName$/ ) {
        if (exists $self->{_PROFILE}->{PUBLIC}->{first_name}) {
            return $self->{_PROFILE}->{PUBLIC}->{first_name};
        } else {
            return;
        }
    }
    elsif ( $AUTOLOAD =~ /.*::getLastName$/ ) {
        if (exists $self->{_PROFILE}->{PUBLIC}->{last_name}) {
            return $self->{_PROFILE}->{PUBLIC}->{last_name};
        } else {
            return;
        }
    }
    elsif ( $AUTOLOAD =~ /.*::getFullName$/ ) {
        my @name_parts;
        my $full_name;
        if (exists $self->{_PROFILE}->{PUBLIC}->{first_name}) {
            push @name_parts, $self->{_PROFILE}->{PUBLIC}->{first_name};
        }
        if (exists $self->{_PROFILE}->{PUBLIC}->{last_name}) {
            push @name_parts, $self->{_PROFILE}->{PUBLIC}->{last_name};
        }
        $full_name = join(' ', @name_parts) if @name_parts;
        if ($full_name) {
            return $full_name;
        } else {
            return;
        }
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }
}
################################################################################
1;
__END__

=head1 NAME

Giovanni::Profile

=head1 SYNOPSIS

  use Giovanni::Profile;

  BEGIN {
      $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
      push( @INC, $rootPath . 'share/perl5' )
          if defined $rootPath;
  }

  my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
  my $error = Giovanni::Util::ingestGiovanniEnv($cfgFile);
  die $error if ( defined $error );

  my $profileDir = qq($GIOVANNI::SESSION_LOCATION/$sessionId);
  my $profile = Giovanni::Profile->new(
     profileDir => $profileDir
    [uid        => $user_id,]
    [profile    => $profileRef]
  );

=head1 DESCRIPTION

Stores and retrieves profile user profile information. To store information,
profileDir, uid, and profile must all be provided. To access information,
profileDir must all be provided, but if uid is not provided, then only isLoggedIn
value can be accessed. If both profileDir and uid are provided, all exposed
profile information can be accessed.

Inputs:

profileDir - directory where profile information file will be read/written

uid - an Earthdata user id

profile: a hash reference. The hash should have the keys PUBLIC and PRIVATE
to separate profile information that will be exposed from information that
can be used internally. The value for the PUBLIC key is a reference to a hash
which has keys obtained from an Earthdata profile, plus aditional keys such
as 'roles'.

=head1 METHODS

=head2 new(profileDir => $profileDir [, uid => $userId] [, profile => $profile])

Create a new Profile object. If values are provided for profileDir, uid, and profile, then profile information is saved to a file in the directory $profileDir. If values are provided for only profileDir and uid, then an existing profile for user with id ui can be accessed. If a value is provided for only profileDir, then only the isLoggedIn method will return a value.

=head2 onError

If an error occurred creating a new Profile object, return an error code.

=head2 errorMessage

Return an error message correspoding to the onError condition.

=head2 getProfileDir

Return the directory containing the profile information file.

=head2 isLoggedIn

Returns true if the profile user is logged in to Earthdata.

=head2 getRoles()

Returns an array of Giovanni roles defined for the user.

=head2 getFirstName

Returns the first name of the user from the profile.

=head2 getLastName

Returns the last name of the user from the profile.

=head2 getFullName

Returns the combined first and last names of the user from the profile.

==head2 logout

Change the logged-in status in the profile information file to indicate that the user has logged out.

=head1 AUTHOR

Edward Seiler, E<lt>eseiler@localdomainE<gt>

=cut
