#!/usr/bin/perl
#$Id: giovanniAgent.pl,v 1.5 2015/08/06 18:44:11 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

giovanniAgent - command line wrapper for Giovanni::Agent

=head1 SYNOPSIS

  giovanniAgent.pl --url "http://giovanni.gsfc.nasa.gov/giovanni/#service=INTERACTIVE_MAP&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T23:59:59Z&bbox=-180,-50,180,50&data=TRMM_3B42_daily_precipitation_V7&dataKeyword=TRMM"

=head1 DESCRIPTION

Runs a giovanni service manager request and downloads the results. Command line 
options are:

1. url - the URL to request. May be either a 'bookmarkable' URL or a service
manager request URL

2. dir [optional] - directory to download output files. Defaults to the working
directory.

3. type [optional] - what kind of results to download. Defaults to 'data'. Other
options are 'image', 'lineage', and 'lineage_xml'. More than one may be 
specified at a time. If 'lineage' is specified, the code will download output
data file as specified by the lineage. If 'lineage_xml' is specified, the code
will download the entire lineage as xml.

4. debug [optional] - if the '--debug' option is present, the code will print 
out intermediate debugging/status

5. max-time [optional] - maximum time in seconds to wait for a service to 
finish. Defaults to 120 seconds (two minutes).

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use 5.008008;
use strict;
use warnings;

my $rootPath;

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5/' )
        if defined $rootPath;
}

use Giovanni::Agent;
use URI;
use Getopt::Long;
use Safe;

# get the command line options

my $url;
my $helpFlag;
my $dir;
my $debug;
my $max_time;
my @types = ();

GetOptions(
    "url=s"      => \$url,
    "dir=s"      => \$dir,
    "debug"      => \$debug,
    "type=s"     => \@types,
    "max-time=i" => \$max_time,
    "h"          => \$helpFlag,
);

# This script needs 2 things: login credentials and realm information.
# The most convenient place to keep and retrieve the realm info is the giovanni.cfg
# Also of note is: this script uses the user's netrc/login credentials 
# or if they don't exist, uses the giovanni APP's credentials from the giovanni.cfg
my $cfgFile = $rootPath . "/cfg/giovanni.cfg";
my $cpt     = Safe->new('GIOVANNI');
die "Failed to read $cfgFile" unless ( $cpt->rdo($cfgFile) );

# if this is the help flag, print out the command line arguments
if ( defined($helpFlag) ) {
    die "$0 --url 'giovanni service URL' [--dir '/path/to/output/directory' "
        . "--debug --type image --max-time 120]";
}

if ( !defined($url) ) {
    die "'--url' parameter is required";
}

if ( !defined($dir) ) {
    $dir = '.';
}

if ( scalar(@types) == 0 ) {
    @types = ('data');
}

if ( !defined($debug) ) {
    $debug = 0;
}

if ( !defined($max_time) ) {
    $max_time = 120;
}


my $agent = Giovanni::Agent->new(
    URL      => $url,
    DEBUG    => $debug,
    MAX_TIME => $max_time
);
if ( $agent->errorMessage() ) {
    die "Unable to finish request for $url: " . $agent->errorMessage();
}
if ($debug) {
    print STDERR "Translated service manager request: ",
        $agent->getInitialRequest->as_string;
}

my $requestResponse = $agent->submit_request();
if ($debug) {
    print STDERR "Session: "
        . $requestResponse->getSessionId()
        . "\nResult set: "
        . $requestResponse->getResultSetId()
        . "\nResult: "
        . $requestResponse->getResultId() . "\n";
}
if ( !$requestResponse->is_success() ) {
    die "Unable to finish request for $url: "
        . $requestResponse->errorMessage();
}

if ( $requestResponse->getPercentComplete() < 100 ) {
    die "Only finished "
        . $requestResponse->getPercentComplete()
        . " percent of the request";
}
for my $type (@types) {
    my $downloadResponse
        = $requestResponse->download_files( $type, DIR => $dir );
    if ( !$downloadResponse->is_success() ) {
        warn "Unable to download $type for request $url: "
            . $downloadResponse->message();
    }
    elsif ($debug) {
        print STDERR "Downloaded $type\n";
    }
}

1;
