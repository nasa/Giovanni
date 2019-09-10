#!/usr/bin/perl -T
#$Id: getNewsItems.pl,v 1.12 2015/02/02 22:51:23 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use strict;
use CGI;
use XML::LibXML;
use XML::LibXSLT;
use File::Temp;
use Giovanni::Util;
use LWP::UserAgent;
use Giovanni::CGI;
use JSON;
use Safe;

$| = 1;

$ENV{PATH} = '';

# Read the configuration file
my $cfgFile = ( defined $rootPath ? $rootPath : './' ) . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
if ( defined $error ) {
    print STDERR "$error\n";
    exit_with_error(
        CGI->new(),
        "500 Internal server error",
        "Error reading configuration"
    );
}

# Create a CGI object. The PREQUIRED_PARAMS is optional.
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
);

my %input = $cgi->Vars();

# look for 'portal' query parameter
my $myTagValue = $input{portal};
exit_with_error( $cgi, "422 Input not found", "Portal not defined" )
    unless defined $myTagValue;

exit_with_error(
    $cgi,
    "500 Internal server error",
    "Failed to find news server in configuration"
) unless defined $GIOVANNI::MESSAGE_SERVER;

my $ua = LWP::UserAgent->new();
$ua->env_proxy;
my $response = $ua->get( $GIOVANNI::MESSAGE_SERVER . "?format=rss" );
if ( $response->is_success() ) {
    print $cgi->header( -type => $response->content_type() );

    # if feed is coming from plone
    if ( $GIOVANNI::MESSAGE_SERVER =~ m/ag-news/ ) {
        print filterContentByTag( $response->content, 'dc:subject',
            "portal=$myTagValue" );
    }

    # if feed is coming from UUI
    if ( $GIOVANNI::MESSAGE_SERVER =~ m/api\/alerts/ ) {
        print filterContentByTag( $response->content, 'tags',
            lc $myTagValue );
    }
}
else {
    exit_with_error(
        $cgi,
        "500 Internal server error",
        "Failed to access news server: received " . $response->code()
    );
}

#######################################################################
## NAME: filterContentByTag
## DESC: filter out the news items if it does not match the requested portal
## ARGUMENTS:
##    $content -- the raw RSS feed content
##    $typeValue -- the portal name. e.g. 'portal=GIOVANNI'
## RETURN:
##    a RSS feed content with which news items are removed, if 'dc:subject' or 'tags'
##    does not match the argument '$typeValue'
## AUTHOR: X. HU
#######################################################################
sub filterContentByTag {
    my ( $content, $tagName, $tagValue ) = @_;
    my $ret = "";

    my $parser = XML::LibXML->new( no_blanks => 1 );

    my $newsDoc = $parser->parse_string($content);
    my $xpc     = XML::LibXML::XPathContext->new($newsDoc);
    $xpc->registerNs( rdc => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' );
    $xpc->registerNs( dft => 'http://purl.org/rss/1.0/' );
    $xpc->registerNs( dc  => 'http://purl.org/dc/elements/1.1/' );
    my @itemNodes = $xpc->findnodes('//dft:item');

    foreach my $itemNode (@itemNodes) {
        my @childNodes = $itemNode->getChildrenByTagName($tagName);
        my $deleteFlag = 0;
        foreach my $childNode (@childNodes)
        {    ## to search for items not belonging to $typeValue
            my $child = $childNode->textContent();
            $child
                =~ s/^\s+|\s+$//g;   ## to remove leading/trailing empty space
            if ( $child =~ /$tagValue/gi ) {
                $deleteFlag = 1;
                last;
            }
        }
        if ( $deleteFlag == 0 ) {  # to remove news item when portal not match
            eval {
                my $parentNode = $itemNode->parentNode();
                $parentNode->removeChild($itemNode);
            };
            if ($@) {
                print STDERR "ERROR: failed to remove the item node: $? \n";
            }
        }
    }

    $ret = $newsDoc->toString();

    return $ret;
}

sub exit_with_error {
    my ( $cgi, $error, $message ) = @_;
    print $cgi->header( { -type => 'text/plain', -status => $error } );
    print "$message\n" if defined $message;
    exit(0);
}

