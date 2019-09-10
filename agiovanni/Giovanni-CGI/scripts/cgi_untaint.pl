#!/usr/bin/perl

=head1 NAME

cgi_untaint.pl - Attempt to untaint CGI parameters. This script is meant to be 
used by python cgi scripts to check parameters with Giovanni::CGI.

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

cgi_untaint.pl

=head1 DESCRIPTION

This script gets the cgi parameters from the CGI environment and untaints
them using Giovanni::Untaint. It returns 0 if successful and non-zero 
otherwise. If successful, prints a new query string to STDOUT with the
untainted parameter values.

=head1 AUTHOR

Christine Smit (christine.e.smit@nasa.gov)

=cut 

use strict;
use warnings;
use URI::Escape qw(uri_escape);

# Establish the root path based on the script name
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}
$| = 1;

# Following packages should be used after @INC is set above
use Giovanni::Util;
use Giovanni::CGI;

# Unset PATH and ENV (needed for taint mode)
$ENV{PATH} = undef;
$ENV{ENV}  = undef;

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Create a new CGI object, which will untaint the CGI parameters.
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS
);

my @all_params = $cgi->all_parameters();
my @encoded    = ();
for my $param (@all_params) {
    push( @encoded, $param . "=" . $cgi->param($param) );
}

my $query_string = join("&",@encoded);
print $query_string;

1;
