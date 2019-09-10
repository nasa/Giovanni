#!/usr/bin/perl -T

=head1 NAME

updateUserSessions.pl - Update a profile with the current value of the userSessions cookie

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

updateUserSessions.pl

=head1 DESCRIPTION

This cgi script provides a way to update the saved userSessions information for
a user that has logged in to Earthdata.

=head2 Parameters

=over 12

=item user

The user's Earthdata user id

=back

=head1 AUTHOR

Ed Seiler (Ed.Seiler@nasa.gov)

=cut

use strict;
use JSON;

# Establish the root path based on the script name
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}
$| = 1;

# Following packages should be used after @INC is set above
use Giovanni::CGI;
use Giovanni::Profile;

# Unset PATH and ENV (needed for taint mode)
$ENV{PATH} = undef;
$ENV{ENV}  = undef;

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
die "Giovanni Configuration Error: $error" if ( $error );

# Create CGI object, which will also untaint the parameters
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
);

my $userIdParam    = $cgi->cookie('giovanniUid');
my $userId         = $1 if $userIdParam =~ /^([A-Za-z\d_\.]{4,30})$/;
my $userSessions   = $cgi->cookie('userSessions');

# Create a Profile object for the user and read the stored profile
my $profile = Giovanni::Profile->new(
                                     profileDir => $GIOVANNI::USER_PROFILE_LOCATION,
                                     uid        => $userId
                                    );
my $status ={};

if ($profile) {
    if ($profile->onError) {
        # Error reading profile for user $userId
        $status->{error_message} = $profile->errorMessage;
    } else {
        # Update profile with value of userSessions cookie
        if ($profile->updateUserSessions($userSessions)) {
            $status->{status} = "updated";
        } else {
            $status->{status} = "unsuccessful";
        }
    }
}

print $cgi->header(
                   -type   => 'application/json',
                  );
print encode_json($status);
exit;
