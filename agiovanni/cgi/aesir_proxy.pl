#!/usr/bin/perl
use strict;
use CGI;
use List::MoreUtils qw(any);
use LWP::UserAgent;
use Safe;

use constant WHITE_LIST => [qr/^\/terms(.*)$/];

# Set root path
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

# Load configuration file

use Giovanni::Util;
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Forbid items not in whitelist
unless ( any { $ENV{PATH_INFO} =~ $_ } @{ (WHITE_LIST) } ) {
    print STDERR "Blocked aesir_proxy.pl request for $ENV{PATH_INFO}\n";
    print CGI->new->header(
        -type   => 'text/html',
        -status => '403 Forbidden'
    );
    print "403 Forbidden";
    exit;
}

my $url
    = $GIOVANNI::DATA_CATALOG . $ENV{PATH_INFO} . "?" . $ENV{QUERY_STRING};

# Request URL and Mirror
my $ua = LWP::UserAgent->new();
$ua->env_proxy;
my $resp = $ua->get($url);

print CGI->new->header( -type => $resp->header('content-type') );
print $resp->content;

