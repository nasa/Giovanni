#!/usr/bin/perl -T

#$Id: service_manager.pl,v 1.38 2015/02/03 15:41:04 mhegde Exp $
#aGiovanni, $Name:  $

use strict;
use CGI;
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
    NAMESPACE => 'service_manager'
);
my $input = {};
$input = $cgi->Vars();

# Format is one of the attributes that is needed first; so, validate it first
# Default format is XML
$input->{format}
    = ( defined $input->{format} and $input->{format} =~ /(xml|json)/i )
    ? lc($1)
    : 'xml';

# Handling multiple data values (separated by commas)
$input->{data} =~ s/,/\0/g;

if ( $input->{format} eq 'xml' ) {
    print $cgi->header( -type => 'text/xml', -cache_control => 'no-cache' );
}
elsif ( $input->{format} eq 'json' ) {
    print $cgi->header(
        -type          => 'application/json',
        -cache_control => 'no-cache'
    );
}

# Read workflow configuration file
my $cpt                = Safe->new('GIOVANNI');
my $workFlowConfigFile = $rootPath . 'cfg/workflow.cfg';
unless ( $cpt->rdo($workFlowConfigFile) ) {
    Giovanni::Util::exit_with_error( 'Workflow Configuration Error',
        $input->{format} );
}

# Create a session
my $session = Giovanni::Session->new(
    location => $GIOVANNI::SESSION_LOCATION,
    session  => $input->{session}
);

# On error while creating a session, log and exit
if ( $session->onError() ) {
    warn( "Session Error: " . $session->errorMessage );
    Giovanni::Util::exit_with_error( $session->errorMessage,
        $input->{format} );
}
if ( defined $input->{service} ) {

    # Case where a new service is being launched
    unless ( $input->{service} =~ /\S+/ ) {
        warn("Service not defined");
        Giovanni::Util::exit_with_error( "Service not defined",
            $input->{format} );
    }
    my $resultSet;
    if ( defined $input->{resultset} ) {

        #Case where a service is being launched under existing result set
        $resultSet = Giovanni::ResultSet->new(
            resultset   => $input->{resultset},
            session_dir => $session->getSessionDir()
        );
    }
    else {
        $resultSet = Giovanni::ResultSet->new(
            session_dir => $session->getSessionDir() );
    }

    # Verify that we don't have any errors from ResultSet.
    if ( $resultSet->onError() ) {
        warn( "ResultSet Error: " . $resultSet->errorMessage );
        Giovanni::Util::exit_with_error( $resultSet->errorMessage,
            $input->{format} );
    }
    my $result = Giovanni::Result->new(
        resultset_dir => $resultSet->getResultSetDir(),
        result        => $input->{result} || undef,
        service       => $input->{service},
        timeout       => $GIOVANNI::SESSION_TIMEOUT
    );

    # Verify that we don't have any errors from Result.
    if ( $result->onError() ) {
        warn( "Result Error: " . $result->errorMessage );
        Giovanni::Util::exit_with_error( $result->errorMessage,
            $input->{format} );
    }
    $logger = setupLogger( $result->getDir() );
    $resultSet->addResult($result);
    $session->addResultSet($resultSet);

    my $sessionLogFile = $result->getDir() . '/session.log';
    my $session_logger = Giovanni::Util::createLogger($sessionLogFile);
    $result->launchWorkflow( $input, $session_logger );
    $result->launchVisualizationManager( $input, $session_logger );
}
elsif ( defined $input->{resultset} ) {

    #Case where status of a result set or a result is needed
    # Changed to a separate %hash object, before calling ResultSet->new
    my %rsInput = (
        resultset   => $input->{resultset},
        session_dir => $session->getSessionDir(),
        timeout     => $GIOVANNI::SESSION_TIMEOUT
    );
    my $resultSet = Giovanni::ResultSet->new(%rsInput);
    if ( $resultSet->onError() ) {
        warn( "ResultSet Error: " . $resultSet->errorMessage );
        Giovanni::Util::exit_with_error( $resultSet->errorMessage,
            $input->{format} );
    }
    if ( defined $input->{result} ) {

        #Case where the status of a result is needed
        # Changed to a separate %hash object, before calling Result->new
        my %rInput = (
            result        => $input->{result},
            resultset_dir => $resultSet->getResultSetDir(),
            options =>
                ( defined $input->{options} ? $input->{options} : undef ),
            timeout => $GIOVANNI::SESSION_TIMEOUT
        );
        my $result = Giovanni::Result->new(%rInput);
        if ( $result->onError() ) {
            warn( "Result Error: " . $result->errorMessage );
            Giovanni::Util::exit_with_error( $result->errorMessage,
                $input->{format} );
        }
        $logger = setupLogger( $result->getDir() );
        my $sessionLogFile = $result->getDir() . '/session.log';
        my $session_logger = Giovanni::Util::createLogger($sessionLogFile);
        if ( exists $input->{cancel} ) {
            $result->stopWorkflow($session_logger);
            $result->stopVisualization();
        }
        elsif ( exists $input->{delete} ) {
            $result->delete();
        }
        $result->getStatus();
        $resultSet->addResult($result);
        if ( defined $input->{options} ) {
            $result->launchVisualizationManager( $input, $session_logger );
        }
    }
    else {

        #Case where the status of entire result set is needed
        $resultSet->getStatus();
    }
    $session->addResultSet($resultSet);
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

# Set up a logger for the result directory to trap warn() statements
# Log file will be svcMgr.log
sub setupLogger {
    my $dir = shift;
    warn "Adding logger to $dir\n";
    $logger = Giovanni::Logger->new(
        session_dir       => $dir,
        manifest_filename => 'svcMgr'
    );
    $SIG{__WARN__} = sub {
        my $msg = shift;
        if ( $msg =~ /^WARN/ ) {
            $logger->warn($msg);
        }
        elsif ( $msg =~ /^ERROR/ ) {
            $logger->error($msg);
        }
        else {
            $logger->info($msg);
        }
    };
    return $logger;
}
