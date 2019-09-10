#!/usr/bin/perl -T

=head1 NAME

earthdataLogin.pl - Obtain a token from Earthdata Login, get a user profile, and lookup user roles

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

earthdataLogin.pl code=606674200f04652579475d5df1c4527d6789c1595cd4c0dc27e6722e788b8762

=head1 DESCRIPTION

This cgi script provides a way for a client that has provided credentials to
Earthdata Login, submitted a request to authorize, and received an authorization
code to exchange that code for a token, use the token to obtain profile
information, and then use the user id from the profile to look up roles in the
UUI database. The combination of the user profile information and the roles
are returned as a JSON response.

=head2 Parameters

=over 12

=item code

Code that was returned by the Earthdata Login authorize step after successful login

=back

=head1 AUTHOR

Ed Seiler (Ed.Seiler@nasa.gov)
Maksym Petrenko (Maksym.Petrenko@nasa.gov) (code this was adapted from)

=cut 

use strict;
use HTTP::Request;
use LWP::UserAgent;
use JSON;
use URI;
use Safe;

# Establish the root path based on the script name
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}
$| = 1;

# Following packages should be used after @INC is set above
use Giovanni::Util;
use Giovanni::CGI;
use Giovanni::Profile;

# Unset PATH and ENV (needed for taint mode)
$ENV{PATH} = undef;
$ENV{ENV}  = undef;

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Create CGI object, which will also untaint the parameters
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS => [ 'code' ],
);

my $code = $cgi->param('code');

my $private_profile = {};

my $startPoint    = $GIOVANNI::EARTHDATA_LOGIN{baseURL};
my $tokenEndpoint = $startPoint . $GIOVANNI::EARTHDATA_LOGIN{tokenPath};

# Value of the redirect_uri parameter to be used to request a token from URS.
# $redirect_uri must be registered in the URS configuration for the application
# whose client_id was used in the authorize request.
# Note that the request for a token will not redirect to $redirect_uri
my $redirect_uri
    = Giovanni::Util::createAbsUrl( $GIOVANNI::EARTHDATA_LOGIN{redirectURI} );

# URL for getting roles from UUI user database
my $roles_getter_url = $GIOVANNI::EARTHDATA_LOGIN{rolesGetterURL};

# Base64 encoded authentication for the URS application for which a token is
# being requested.
my $appAuth = $GIOVANNI::EARTHDATA_LOGIN_CONFIDENTIAL{appAuth};

# Process callback from URS "authorize" request.
# Expect a query parameter named "code" and possibly one named "state".
# Send a request to URS for tokens by sending the code.
# Expect a JSON response containing an access_token, refresh_token, token_type,
# endpoint (for URS user profile), and expires_in (token expiration in secs.)
my $queryParams;
$queryParams->{grant_type}   = 'authorization_code';
$queryParams->{code}         = $code;
$queryParams->{redirect_uri} = $redirect_uri;
my $uri = URI->new;
$uri->query_form($queryParams);

my $ua = LWP::UserAgent->new( agent => 'giovanni_login', timeout => 10 );
my $request = HTTP::Request->new(
    'POST',
    $tokenEndpoint,
    [   Content_Type  => 'application/x-www-form-urlencoded; charset=utf-8',
        Authorization => $appAuth
    ],
    $uri->query
);
my $response = $ua->request($request);

if ( $response->is_success ) {

    # Parse JSON response and extract access_token, refresh_token,
    # token_type, expires_in, and endpoint.
    # Then request the user profile using the endpoint from the response,
    # with an Authorization header that has the token_type and the
    # access_token
    my $token_data        = decode_json( $response->decoded_content );
    my $access_token      = $token_data->{'access_token'};
    my $refresh_token     = $token_data->{'refresh_token'};
    my $token_type        = $token_data->{'token_type'};
    my $expires_in        = $token_data->{'expires_in'};
    my $urs_user_endpoint = $startPoint . '/' . $token_data->{'endpoint'};

    $private_profile->{'access_token'}  = $access_token;
    $private_profile->{'refresh_token'} = $refresh_token;
    $private_profile->{'token_type'}    = $token_type;
    $private_profile->{'expires_in'}    = $expires_in;

    my $authorization = $token_type . ' ' . $access_token;
    $request = HTTP::Request->new(
        'GET',
        $urs_user_endpoint,
        [   Content_Type =>
                'application/x-www-form-urlencoded; charset=utf-8',
            Authorization => $authorization
        ]
    );
    $response = $ua->request($request);
    unless ( $response->is_success ) {
        print $cgi->header(
            -type   => $response->header('Content-Type'),
            -status => $response->code()
        );
        print $response->decoded_content;
        exit;
    }

    my $decodedContent = $response->decoded_content;
    my $earthdata_profile = decode_json( $decodedContent );
    my $ursUid = $earthdata_profile->{'uid'};

    # Select a subset of the Earthdata profile information to include in
    # the Giovanni profile
    # Known fields:
    #   affiliation
    #   agreed_to_meris_eula
    #   agreed_to_sentinel_eula
    #   allow_auth_app_emails
    #   authorized_date
    #   country
    #   email_address
    #   first_name
    #   last_name
    #   member_groups
    #   middle_initial
    #   organization
    #   registered_date
    #   study_area
    #   uid
    #   user_authorized_apps
    #   user_groups
    #   user_type
    my @selectedFields = ('uid', 'first_name', 'middle_initial', 'last_name');
    my $public_profile;
    foreach my $field (@selectedFields) {
        $public_profile->{$field} = $earthdata_profile->{$field}
          if (exists $earthdata_profile->{$field});
    }

    # Get roles info
    my $rolesJSON;
    if ($roles_getter_url) {
        $request = HTTP::Request->new( 'GET',
            $roles_getter_url . '?user=' . $ursUid );
        $response = $ua->request($request);
        if ( $response->is_success ) {
            $rolesJSON = $response->decoded_content;
            my $roles = decode_json( $rolesJSON );
            $public_profile->{'roles'} = $roles;
        } else {
            print STDERR "Error in getting roles via $roles_getter_url for user $ursUid: ", $response->decoded_content, "\n";
        }
    }
    my $profile = { PRIVATE=>$private_profile, PUBLIC=>$public_profile };

    my $cookies = [];
    my $giovanniUidCookie = $cgi->cookie(-name  => 'giovanniUid',
                                         -value => $ursUid);
    push @$cookies, $giovanniUidCookie;
    if (defined $rolesJSON) {
        my $giovanniRolesCookie = $cgi->cookie(-name  => 'giovanniRoles',
                                               -value => $rolesJSON);
        push @$cookies, $giovanniRolesCookie;
    }
    #sleep 4;
    print $cgi->header(
        -type                          => $response->header('Content-Type'),
        -Access_Control_Allow_Origin   => 'https://dev.gesdisc.eosdis.nasa.gov',
        -Access_Control_Allow_Methods  => 'GET, POST',
        -Access_Control_Expose_Headers => 'true',
        -cookie                        => $cookies,
    );

    unless (-d $GIOVANNI::USER_PROFILE_LOCATION) {
       umask 0000;
        if ( mkdir($GIOVANNI::USER_PROFILE_LOCATION, 0775) ) {
            print STDERR "Created directory $GIOVANNI::USER_PROFILE_LOCATION\n";
        } else {
            print STDERR "Could not create directory $GIOVANNI::USER_PROFILE_LOCATION: $!\n";
        }
    }
    my $gProfile = Giovanni::Profile->new(
        profileDir => $GIOVANNI::USER_PROFILE_LOCATION,
        uid        => $ursUid,
        profile    => $profile
    );
    if ($gProfile && $gProfile->onError) {
        print STDERR $gProfile->errorMessage(), "\n";
    } else {
        print encode_json($gProfile->getPublicProfile);
    }
}
else {
    print $cgi->header(
        -type   => $response->header('Content-Type'),
        -status => $response->code()
    );
    print $response->decoded_content;
    exit;
}

exit;
