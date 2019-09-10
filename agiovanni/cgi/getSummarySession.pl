#!/usr/bin/perl -T

use strict;
use XML::LibXML;
use Safe;
use warnings;
use JSON;

# Set the library path
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use vars qw($logger);    # Global so it can used for SIG{WARN}

$| = 1;

# Following packages should be used after @INC is set above
use Giovanni::Session;
use Giovanni::ResultSet;
use Giovanni::Result;
use Giovanni::Logger;
use XML::XML2JSON;
use Giovanni::CGI;

#Set the umask so that files/directoreis are group writable
umask 002;

# Read the configuration file: giovanni.cfg in to GIOVANNI name space
# ...and set the environment variables
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
if ( defined $error ) {

    # Error response is in XML only
    print CGI->new()->header(
        -type          => 'text/xml',
        -cache_control => 'no-cache',
        -error         => "500 Internal Server Error"
    );
    Giovanni::Util::exit_with_error("Failed to read configuration");
}

# Create a CGI object. The PREQUIRED_PARAMS is optional.
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,

    # We want this script to either return the session or report
    # that it couldn't find it. We don't want it to return a new session.
    REQUIRED_PARAMS => ['SESSION'],
);
my $input = {};
$input = $cgi->Vars();

# Format is one of the attributes that is needed first; so, validate it first
# Default format is XML
$input->{format}
    = ( defined $input->{format} and $input->{format} =~ /(xml|json)/i )
    ? lc($1)
    : 'xml';

if ( $input->{format} eq 'xml' ) {
    print $cgi->header( -type => 'text/xml', -cache_control => 'no-cache' );
}
elsif ( $input->{format} eq 'json' ) {
    print $cgi->header(
        -type          => 'application/json',
        -cache_control => 'no-cache'
    );
}

# Find a session, Don't create a session
# Fortunately Session, ResultSet, and Result dirs are nominally separated
# We don't have to worry about being sent a 'session dir' which includes all 3.
my $session = Giovanni::Session->new(
    location => $GIOVANNI::SESSION_LOCATION,
    session  => $input->{session},

    # This format is not the xml|json format it is
    # summary (just the ID and title) or long (complete report of Result)
    # essentially this applies only to Result.pm since Session.pm
    # and ResultSet.pm nominally only return the ID
    format => "summary"
);

# On error while creating a session, log and exit
if ( $session->onError() ) {
    warn( "Session Error: " . $session->errorMessage );
    Giovanni::Util::exit_with_error( $session->errorMessage,
        $input->{format} );
}

if ( defined $input->{service} ) {
    warn("This script is not for running workflows");
    Giovanni::Util::exit_with_error( "This script is not for running workflows",
        $input->{format} );

}
elsif ( defined $input->{resultset} ) {
    warn("This script does not expect this parameter");
    Giovanni::Util::exit_with_error( "This script does not expect this parameter",
        $input->{format} );

}
else {

    #Case where the status of a session is requested
    $session->getStatus();
}

my $dom = $session->toXML();

if ( defined $input->{format} ) {
    if ( uc( $input->{format} ) eq 'JSON' ) {
        my $xml2Json = XML::XML2JSON->new(
            module           => 'JSON::XS',
            pretty           => 1,
            attribute_prefix => '',
            content_key      => 'value',
            force_array      => 1
        );
        my $jsonObj = $xml2Json->dom2obj($dom);
        print $xml2Json->obj2json($jsonObj);
    }
    elsif ( uc( $input->{format} ) eq 'XML' ) {
        print $dom->toString(1), "\n";
    }
}
else {
    print $dom->toString(1), "\n";
}
close(STDIN);
close(STDOUT);
close(STDERR);
exit(0);

=head1 NAME

getShortSession.pl - this CGI script returns the summary description of the given session 

=head1 PURPOSE 

to return the session tree

=head1 DESCRIPTION  

this adds a format member to Session.pm, ResultSet.pm and Result.pm. If format member = 'summary', then Result.pm returns only the ID

=head1 SYNOPSIS1

If the session does exist then Session.pm returns something like:

<session id="7E3F4F96-5C83-11E9-B7BE-0E82447F1F7C">
  <resultset id="BB36E22E-5C83-11E9-94F6-A284447F1F7C">
    <result id="BB379BA6-5C83-11E9-94F6-A284447F1F7C">
      <status>
        <code>0</code>
      </status>
    </result>
  </resultset>


If the session doesn't exist then Session.pm returns something like:

{
   "session" : {
      "error" : [
         {
            "value" : "Session directory does not exist"
         }
      ]
   },
   "version" : "1.0",
   "encoding" : "UTF-8"
}


=head1 ARGUMENTS
 
 session=<sessionid>
 format=<json|xml>

