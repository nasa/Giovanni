#!/usr/bin/perl -T

=head1 NAME

profileLoggedIn.pl - Update a profile to indicate that the user has logged out

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

profileLoggedIn.pl

=head1 DESCRIPTION

This cgi script provides a way to check a profile to determine if a user is logged in.

=head2 Parameters

=over 12

=back

=head1 AUTHOR

Ed Seiler (Ed.Seiler@nasa.gov)

=cut

use strict;
use CGI;
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
    #REQUIRED_PARAMS => [ 'session' ],
);

my $loginStatus = {};
my $userIdParam = $cgi->cookie('giovanniUid');
my $userId      = $1 if $userIdParam =~ /^([A-Za-z\d_\.]{4,30})$/;
my $profile = Giovanni::Profile->new(
                                     profileDir => $GIOVANNI::USER_PROFILE_LOCATION,
                                     uid        => $userId
                                    );

if ($profile) {
    if ($profile->onError) {
        $loginStatus->{error_message} = $profile->errorMessage;
    } else {
        $loginStatus->{login_status} = $profile->isLoggedIn;
        $loginStatus->{roles}        = $profile->getRoles;
    }
}

print $cgi->header(
                   -type   => 'application/json',
                  );
print encode_json($loginStatus);
exit;
