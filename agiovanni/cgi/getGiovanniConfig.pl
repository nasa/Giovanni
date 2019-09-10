#!/usr/bin/perl -T

use strict;
use Safe;
use warnings;
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
use Giovanni::Util;
use Giovanni::CGI;

# Clean PATH and ENV
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Create a CGI object
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS =>
        [ 'cfg' ]
    ,
);

# get the parameters
my $selections = $cgi->param('cfg');

# Response is hash{success,message}
my $response = generateResponse( $selections );

if ( $response->{success} ) {
    print $cgi->header('application/json');
    print $response->{message};
}
else {
    print $cgi->header(
        -status => '404',
        -type   => 'application/json'
    );
    print $response->{message};
}
exit 0;

sub generateResponse {

    my $selections = shift;

    # Expect selections to be comma-separated strings
    my @selections = split( ',', $selections );

    # Only allow selection by certain predefined strings.
    # Store each selected value in a hash whose key is the selection string
    my %results;
    foreach my $selection (@selections) {
        if ( $selection eq 'EARTHDATA_LOGIN' ) {
            unless ( defined %GIOVANNI::EARTHDATA_LOGIN ) {
                return {
                    success => 0,
                    message =>
                        "Failed to find EARTHDATA_LOGIN in Giovanni configuration"
                };
            }

            # Special case where we need an absolute URL and a relative URL
            # may have been configured
            if ( exists $GIOVANNI::EARTHDATA_LOGIN{redirectURI} ) {
                $GIOVANNI::EARTHDATA_LOGIN{redirectURI}
                    = Giovanni::Util::createAbsUrl(
                    $GIOVANNI::EARTHDATA_LOGIN{redirectURI} );
            }

            $results{$selection} = \%GIOVANNI::EARTHDATA_LOGIN;
        }
        elsif ( $selection eq 'APPLICATION' ) {

            # Earthdata Login enabled ?
            unless ( defined $GIOVANNI::APPLICATION ) {
                return {
                    success => 0,
                    message =>
                        "Failed to find APPLICATION in Giovanni configuration"
                };
            }

            # Set the value
            $results{$selection} = $GIOVANNI::APPLICATION;
        }
        elsif ( $selection eq 'SOME_OTHER_SELECTION' ) {

            # Earthdata Login enabled ?
            unless ( defined %GIOVANNI::SOME_OTHER_SELECTION ) {
                return {
                    success => 0,
                    message =>
                        "Failed to find SOME_OTHER_SELECTION in Giovanni configuration"
                };
            }

            # Set the value
            $results{$selection} = \%GIOVANNI::SOME_OTHER_SELECTION;
        }
        else {

            # Ignore all other selection strings
        }
    }
    if (%results) {

        # One or more configured values corresponding to the selection
        # string(s) was found
        my $json = encode_json \%results;
        return { success => 1, message => $json };
    }
    else {

        # No known selection strings encountered or no values
        # associated with the selection strings were found in the
        # configuration.
        return {
            success => 0,
            message => "Failed to find selections in Giovanni configuration"
        };
    }
}

=head1 NAME

getGiovanniConfig.pl - This cgi script returns selected Giovanni configuration values from giovanni.cfg in a similar way to how ingestGiovanniEnv retrieves GIOVANNI::ENV. It converts values to a JSON string before returning.

=head1 SYNOPSIS

perl -T -I /opt/giovanni4/share/perl5/Giovanni /opt/giovanni4/cgi-bin/getGiovanniConfig.pl?cfg=EARTHDATA_LOGIN

=head1 DESCRIPTION

Returns JSON string of giovanni.cfg GIOVANNI::EARTHDATA_LOGIN

=head2 Parameters

=over 4

=item cfg

Comma-separated list of selection strings

=back

=cut
