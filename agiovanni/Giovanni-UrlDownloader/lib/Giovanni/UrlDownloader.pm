#$Id: UrlDownloader.pm,v 1.9 2013/08/28 19:24:10 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::UrlDownloader;

use 5.008008;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Response;
use HTTP::Cookies;

our $VERSION = '0.01';

sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;
    _checkParams( \%params, "TIME_OUT", "MAX_RETRY_COUNT", "RETRY_INTERVAL" );

    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;
    $ua->timeout( $self->{TIME_OUT} );

    if ( defined( $self->{CREDENTIALS} )
        && ( ref( $self->{CREDENTIALS} ) eq 'HASH' ) )
    {

        # If credentials were provided, set the credentials in the user agent
        # for each combination of location and realm.
        foreach my $netloc ( keys %{ $self->{CREDENTIALS} } ) {
            foreach my $realm ( keys %{ $self->{CREDENTIALS}->{$netloc} } ) {
                my $user = $self->{CREDENTIALS}->{$netloc}->{$realm}
                    ->{DOWNLOAD_USER};
                my $cred = $self->{CREDENTIALS}->{$netloc}->{$realm}
                    ->{DOWNLOAD_CRED};
                $ua->credentials( $netloc, $realm, $user, $cred );
            }
        }

        # Provide a place for the user agent to store cookies that are set
        # when basic authentication is performed. This facilitates access
        # to data that requires Earthdata Login authentication.
        my $cookies = HTTP::Cookies->new();
        $ua->cookie_jar($cookies);
    }
    $self->{_UA} = $ua;

    return $self;
}

sub download {
    my ( $self, %params ) = @_;

    _checkParams( \%params, "URL", "DIRECTORY", "FILENAME",
        "RESPONSE_FORMAT" );

    my $ret;
    for ( my $i = 0; $i < $self->{MAX_RETRY_COUNT}; $i++ ) {
        if ( $i != 0 ) {

            # retry after a delay
            sleep $self->{RETRY_INTERVAL};
        }

        $ret = $self->_tryDownload(%params);
        if ( !$ret->{ERROR} ) {

            # success!
            return $ret;
        }
    }
    return $ret;
}

sub _tryDownload {
    my ( $self, %params ) = @_;

    _checkParams( \%params, "URL", "DIRECTORY", "FILENAME",
        "RESPONSE_FORMAT" );

    my $outFile = $params{"DIRECTORY"} . "/" . $params{"FILENAME"};

    my $ret = {};
    if ( shouldUseNcCopy( RESPONSE_FORMAT => $params{"RESPONSE_FORMAT"} ) ) {

        # use nccopy
        $ret->{USED_NCCOPY} = 1;

        # If authorization credentials are configured, set up files in the
        # download directory for utilizing the credentials with nccopy
        if ( defined( $self->{CREDENTIALS} )
            && ( ref( $self->{CREDENTIALS} ) eq 'HASH' ) )
        {
            unless (
                _prepAuthentication(
                    DIRECTORY   => $params{"DIRECTORY"},
                    CREDENTIALS => $self->{CREDENTIALS}
                )
                )
            {
                $ret->{ERROR} = "Unable to create authentication files in "
                    . $params{"DIRECTORY"};
            }
        }

        my $cmd = "nccopy '" . $params{"URL"} . "' '$outFile'";
        my $out = `$cmd`;
        if ( $? == 0 ) {
            $ret->{FILEPATH} = $outFile;
        }
        else {

            # something went wrong
            $ret->{ERROR} = "Command '$cmd' returned non-zero. Output: $out";
        }
    }
    else {

        # not using nccopy
        $ret->{USED_NCCOPY} = 0;

        my $ua = $self->{_UA};

        my $response = $ua->get( $params{"URL"} );
        if ( $response->is_success() ) {

            # success. Write content to a file.
            open FILE, ">$outFile" or die $?;
            print FILE $response->content() or die $?;
            close FILE or die $?;

            $ret->{FILEPATH} = $outFile;
        }
        else {

            # something went wrong
            $ret->{ERROR}
                = "HTTP response "
                . $response->code()
                . ". Body: "
                . $response->content();
        }
    }

    # now test based on response format
    if ( !$ret->{ERROR} ) {
        if (   $params{"RESPONSE_FORMAT"} eq "DAP"
            || $params{"RESPONSE_FORMAT"} eq "netCDF" )
        {

            # redirect stderr/stdout to dev null because we don't want them
            my $cmd      = "ncdump -k " . $ret->{FILEPATH} . " &> /dev/null";
            my $retValue = system($cmd);
            if ( $retValue != 0 ) {

                # not a netcdf file!
                $ret->{ERROR}
                    = "Downloaded file is not a NetCDF file. (Command returned non-zero: $cmd)";
            }

        }
        elsif ( $params{"RESPONSE_FORMAT"} eq "NO_CHECK" ) {

            # don't check ...
        }
        else {
            $ret->{ERROR} = "Unknown response format '"
                . $params{"RESPONSE_FORMAT"} . "'.";
        }
    }

    return $ret;
}

# This function has the logic for determining if we should use nccopy
sub shouldUseNcCopy {
    my (%params) = @_;
    my $responseFormat = uc( $params{"RESPONSE_FORMAT"} );

    if ( $responseFormat eq "DAP" ) {

        # use nccopy
        return 1;
    }
    else {

        # don't need nccopy
        return 0;
    }
}

sub _checkParams {
    my $argHash = shift(@_);
    my @args    = @_;

    for my $arg (@args) {
        if ( !( exists( $argHash->{$arg} ) ) ) {
            my @info = caller;

            die("Missing mandatory argument $arg for " . $info[1] . ", line ",
                $info[2]
            );
        }
    }

}

sub _prepAuthentication {
    my (%params) = @_;

    my $netrcPath   = $params{DIRECTORY} . "/" . '.netrc';
    my $dodsrcPath  = $params{DIRECTORY} . "/" . '.dodsrc';
    my $cookiesPath = $params{DIRECTORY} . "/" . 'ursCookies';

    # If it does not already exist, create a .netrc file for use by Libcurl
    # to perform redirection-based authentication
    unless ( -f $netrcPath ) {
        return unless ( open( NETRC, "> $netrcPath" ) );
        foreach my $netloc ( keys %{ $params{CREDENTIALS} } ) {
            my $machine = $1 if $netloc =~ /(\w+\.\w+\.\w+\.\w+)(:\d+)?/;

            # Obtain credentials from first realm in configuration
            my $realm1 = ( keys %{ $params{CREDENTIALS}->{$netloc} } )[0];
            next unless defined $realm1;
            my $user
                = $params{CREDENTIALS}->{$netloc}->{$realm1}->{DOWNLOAD_USER};
            next unless defined $user;
            my $cred
                = $params{CREDENTIALS}->{$netloc}->{$realm1}->{DOWNLOAD_CRED};
            next unless defined $cred;
            print NETRC "machine $machine login $user password $cred\n";
        }
        close(NETRC);
        chmod( 0600, $netrcPath );
    }

    # If it does not already exist, create a .dodsrc file for use by
    # netCDF library
    unless ( -f $dodsrcPath ) {
        return unless ( open( DODSRC, "> $dodsrcPath" ) );
        print DODSRC "HTTP.NETRC=$netrcPath\n";
        print DODSRC "HTTP.COOKIEJAR=$cookiesPath\n";
        close(DODSRC);
    }

    return 1;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::UrlDownloader - Perl extension for downloading files.

=head1 SYNOPSIS

  use Giovanni::UrlDownloader;
  
  my $downloader = Giovanni::UrlDownloader->new(
     TIME_OUT          => 10,
     MAX_RETRY_COUNT => 3,
     RETRY_INTERVAL   => 3
   [,CREDENTIALS      => $credentialsRef ]
  );
  
  $response = $downloader->download(
     URL =>
  "http://disc2.nascom.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fftp%2Fdata%2Fs4pa%2FTRMM_L3%2FTRMM_3B42_daily.6%2F2002%2F365%2F3B42_daily.2003.01.01.6.bin&FORMAT=bmV0Q0RGLw&LABEL=3B42_daily.2003.01.01.6.nc&SHORTNAME=TRMM_3B42_daily&SERVICE=HDF_TO_NetCDF&VERSION=1.02&DATASET_VERSION=6",
     DIRECTORY     => ".",
     FILENAME      => "3B42_daily.2003.01.01.6.nc",
     RESPONSE_FORMAT => "netCDF",
   );
   
   if(!$response->{ERROR}){
      # do something
   }
   

=head1 DESCRIPTION

=head2 new

=head3 inputs:


TIME_OUT - the timeout in seconds for the request

MAX_RETRY_COUNT - the number of times to retry an unsuccessful query

RETRY_INTERVAL - time in seconds between requests

CREDENTIALS - (optional) reference to a hash where a username and password
is provided for each realm of each location that requires HTTP basic
authentication

=head2 download

=head3 inputs:


URL - the URL to download

DIRECTORY - the directory for the file

FILENAME - what to call the file

RESPONSE_FORMAT - should be 'DAP', 'netCDF', 'NO_CHECK'. If the response format
is 'DAP', the downloader will use nccopy to get the file. If the response 
format is 'DAP' or 'netCDF', the downloader will check to make sure it got a
netcdf file. If the response format is 'NO_CHECK', no extra checks will be
performed on the downloaded file.


=head3 outputs:

$out->{ERROR} - an error message, if there was a problem. If everything went 
  well, this is not set.

$out->{USED_NCCOPY} - set to true if nccopy was used. False otherwise.

$out->{FILEPATH} - path to the downloaded file if it was downloaded.


=head2 shouldUseNcCopy

Used to find out if the downloader should use nccopy based on the response 
format. Can be called without creating an object.

=head3 inputs:

RESPONSE_FORMAT - if the response format is 'DAP', the downloader will use 
nccopy to get the file.

=head3 output:

True if the downloader would use nccopy and false otherwise.

=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>



=cut
