#!/usr/bin/perl -T

=head1 NAME

profileLogout.pl - Update a profile to indicate that the user has logged out

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

profileLogout.pl user=<user_id>

=head1 DESCRIPTION

This cgi script provides a way to update a profile for a user that has logged
in to Earthdata to indicate that the user has logged out.

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

my $logoutStatus = {};
my $userIdParam    = $cgi->cookie('giovanniUid');
my $userId         = $1 if $userIdParam =~ /^([A-Za-z\d_\.]{4,30})$/;
#my $loggedInCookie = $cgi->cookie('isLoggedIn');

my $profile = Giovanni::Profile->new(
                                     profileDir => $GIOVANNI::USER_PROFILE_LOCATION,
                                     uid        => $userId
                                    );
my $cookies = [];
my $giovanniUidCookie = $cgi->cookie(-name => 'giovanniUid', -value => '', -expires => '-1d');
push @$cookies, $giovanniUidCookie;
my $giovanniRolesCookie = $cgi->cookie(-name => 'giovanniRoles', -value => '', -expires => '-1d');
push @$cookies, $giovanniRolesCookie;

if ($profile) {
    if ($profile->onError) {
        # Error reading profile for user $userId
        $logoutStatus->{error_message} = $profile->errorMessage;
    } else {
        my $profileIsLoggedIn = $profile->isLoggedIn;
        if (! $profileIsLoggedIn) {
            $logoutStatus->{status} = "logged out";
        } else {
            if ($profile->logout()) {
                $logoutStatus->{status} = "logged out";
            } else {
                $logoutStatus->{status} = "unsuccessful";
            }
        }
    }
}

print $cgi->header(
                   -type   => 'application/json',
                   -cookie => $cookies,
                  );
print encode_json($logoutStatus);
exit;
