#$Id: OSDD.pm,v 1.3 2014/11/25 15:19:39 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
package ESIP::OSDD;

use LWP::UserAgent;
use XML::LibXML;
use Data::UUID;

use ESIP::Template;
use ESIP::Response;

use 5.008008;
use strict;
use warnings;

sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    if ( !exists( $self->{osddUrl} ) && !exists( $self->{osddXml} ) ) {
        die "Either the osddUrl or the osddXml is required";
    }

    # only try each search query once by default
    if ( !exists( $self->{maxTryCount} ) ) {
        $self->{maxTryCount} = 1;
    }

    # wait a second before retrying by default
    if ( !exists( $self->{retryInterval} ) ) {
        $self->{retryInterval} = 1;
    }

    if ( !exists( $self->{namespaceMapping} ) ) {
        my $mapping = {};
        $mapping->{"os"}  = "http://a9.com/-/spec/opensearch/1.1/";
        $mapping->{"geo"} = "http://a9.com/-/opensearch/extensions/geo/1.0/";
        $mapping->{"time"}
            = "http://a9.com/-/opensearch/extensions/time/1.0/";
        $mapping->{"esipdiscovery"}
            = "http://commons.esipfed.org/ns/discovery/1.2/";
        $self->{namespaceMapping} = $mapping;
    }

    # if we don't have the XML, download the URL
    if ( !exists( $self->{osddXml} ) ) {

        my $out = $self->_callUrl( $self->{osddUrl} );
        if ( $out->{success} ) {
            $self->{osddXml}
                = XML::LibXML->new()->parse_string( $out->{content} );
        }
        else {
            die( $out->{message} );
        }

    }
    $self->_setupTemplate();

    return $self;
}

sub performGranuleSearch {

    # Parameters:
    #
    # templateParameters (key-value hash)
    my ( $self, $strict, %params ) = @_;

    # namespace for things we'll need to pull out of the response
    my $opensearchUri = "http://a9.com/-/spec/opensearch/1.1/";

    # and get the prefixes for the opensearchUri and the esipDiscoveryUri
    # if they exist
    my $opensearchPrefix = "";
    for my $prefix ( keys %{ $self->{namespaceMapping} } ) {
        if ( $self->{namespaceMapping}->{$prefix} eq $opensearchUri ) {
            $opensearchPrefix = $prefix;
        }
    }

    # if we don't have prefix for this, create it for later use
    if ( !$opensearchPrefix ) {
        my $ug = Data::UUID->new();
        $opensearchPrefix = $ug->create_str();
        $self->{namespaceMapping}->{$opensearchPrefix} = $opensearchUri;
    }

    # See if there is a startIndex or a startPage in the template.
    # Clear out anything that may have been sent in for these parameters.
    my $hasStartPage  = 0;
    my $hasStartIndex = 0;
    delete( $params{"$opensearchPrefix:startPage"} );
    delete( $params{"$opensearchPrefix:startIndex"} );
    ($hasStartPage)
        = $self->{parsedTemplate}
        ->hasParameter( $opensearchUri, "startPage" );
    ($hasStartIndex)
        = $self->{parsedTemplate}
        ->hasParameter( $opensearchUri, "startIndex" );
    if ($hasStartPage) {
        $params{"$opensearchPrefix:startPage"} = 1;
    }
    elsif ($hasStartIndex) {
        $params{"$opensearchPrefix:startIndex"} = 1;
    }

    # setup the return hash
    my $ret = {};
    $ret->{response} = ESIP::Response->new(
        sampleOpendap => $self->{sampleOpendap},
        sampleFile    => $self->{sampleFile},
        searchFilter  => $self->{searchFilter}
    );
    $ret->{searchUrls} = [];

    # fill the template for the initial query
    my $url = $self->fillTemplate( $strict, %params );
    push( @{ $ret->{searchUrls} }, $url );

    my $out = $self->_callUrl($url);

    if ( !$out->{success} ) {
        $ret->{success} = 0;
        $ret->{message} = "Unable to complete search. " . $out->{message};
        return $ret;
    }

    # parse the output
    my $rawXml = XML::LibXML->new()->parse_string( $out->{content} );
    $ret->{response}->appendResponse($rawXml);

    my $done    = 0;
    my $lastUrl = $url;
    while ( !$done ) {
        my $nextUrl = $self->_getNextUrl($rawXml);

        # make sure this actually different from the last request...
        if ( !$nextUrl || $nextUrl eq $lastUrl ) {
            $done = 1;
        }
        else {
            push( @{ $ret->{searchUrls} }, $nextUrl );
            $out = $self->_callUrl($nextUrl);
            if ( !$out->{success} ) {
                $ret->{success} = 0;
                $ret->{message}
                    = "Unable to complete search. " . $out->{message};
                return $ret;
            }

            $rawXml = XML::LibXML->new()->parse_string( $out->{content} );
            $ret->{response}->appendResponse($rawXml);

            $lastUrl = $nextUrl;
        }
    }

    $ret->{success} = 1;
    return $ret;
}

sub _getNextUrl {
    my ( $self, $rawXml, %params ) = @_;
    my $atomUri = "http://www.w3.org/2005/Atom";

    # for now, just look for the atom stuff
    my $xpc = XML::LibXML::XPathContext->new($rawXml);
    $xpc->registerNs( atom => $atomUri );

    my $nextXpath = qq(/atom:feed/atom:link[\@rel="next"]/\@href);

    my @nodes = $xpc->findnodes($nextXpath);
    if ( scalar(@nodes) == 1 ) {

        # there's a next link, we're done
        return $nodes[0]->getValue();
    }

    my $lastXpath = qq(/atom:feed/atom:link[\@rel="last"]/\@href);
    @nodes = $xpc->findnodes($lastXpath);
    if ( scalar(@nodes) ) {

        # there's a last URL
        return $nodes[0]->getValue();
    }

    # TODO: startPage/startIndex-style next page!
    return "";

}

sub fillTemplate {
    my ( $self, $strict, %params ) = @_;
    my %templateObjHash = $self->_getTemplateHash(%params);
    return $self->{parsedTemplate}->fillTemplate( $strict, %templateObjHash );
}

sub _callUrl {
    my ( $self, $url ) = @_;

    my $ua = LWP::UserAgent->new();
    if ( $self->{timeout} ) {
        $ua->timeout( $self->{timeOut} );
    }

    my $remainingTries = $self->{maxTryCount};

    my $ret;
    while ( $remainingTries > 0 ) {

        # try to download the URL
        my $response = $ua->get($url);

        # decrement how many remaining tries we have
        $remainingTries--;

        # see if we were successful
        if ( $response->is_success() ) {
            $ret->{success} = 1;
            $ret->{content} = $response->content();
            return $ret;
        }
        else {

            # see if we can try again
            if ( $remainingTries > 0 ) {
                sleep( $self->{retryInterval} );
            }
            else {

                # couldn' t retrieve URL . $ret->{success} = 0;
                $ret->{message}
                    = "Unable to download $url. HTTP response "
                    . $response->code()
                    . ". Body: "
                    . $response->content();
                return $ret;
            }
        }
    }
}

sub _setupTemplate {
    my ($self) = @_;
    my $xpc = XML::LibXML::XPathContext->new( $self->{osddXml} );
    $xpc->registerNs( os => 'http://a9.com/-/spec/opensearch/1.1/' );

    # try to find the template
    my @templateXPaths
        = (
        qq(//os:Url[\@type="application/atom+xml" and \@template]/\@template)
        );

    my $index = 0;
    while ( !$self->{template} && $index < scalar(@templateXPaths) ) {
        my $xpath = $templateXPaths[$index];
        $index++;

        my @nodes = $xpc->findnodes($xpath);
        if ( scalar(@nodes) == 1 ) {
            my $templateNode = $nodes[0];

            # set the template for later use
            $self->{template} = $templateNode->getValue();

            # get all the namespace mappings
            ( my $localNameToUri ) = _getNamespaceMapping($templateNode);

            # parse the template so we can create URLs easily
            $self->{parsedTemplate} = ESIP::Template->new(
                template       => $self->{template},
                localNameToUri => $localNameToUri
            );
        }
    }
}

# This class takes two pieces of information, the namespace mapping
# and the template parameter values, and creates the 2-level hash
# the template object needs.
#
# namespace mapping: $self->{namespaceMapping}->{"os"} = "http://a9.com/-/spec/opensearch/1.1/";
# template parameter values : $params{"os:count"} = 1;
#
# becomes
# $result{"http://a9.com/-/spec/opensearch/1.1/"}->{"count"} = 1;
sub _getTemplateHash {
    my ( $self, %params ) = @_;
    my %templateObjHash = ();

    for my $templateKey ( keys %params ) {
        my $templateValue = $params{$templateKey};
        my $namespace     = "";
        my $key           = $templateKey;
        if ( $templateKey =~ /:/ ) {
            ( $namespace, $key ) = split( ":", $templateKey );
        }

        if ( !$self->{namespaceMapping}->{$namespace} ) {
            die "Unknown namespace $namespace. "
                . "Please specify namespace mapping in constructor.";
        }
        $templateObjHash{ $self->{namespaceMapping}->{$namespace} }->{$key}
            = $templateValue;
    }
    return %templateObjHash;
}

# Get all the namespace mappings for a particular node.
sub _getNamespaceMapping {
    my ($node) = @_;

    my $localNameToUri = {};
    my @nsList         = $node->getNamespaces();
    for my $ns (@nsList) {
        my $localName = $ns->getLocalName();
        my $uri       = $ns->getData();
        $localNameToUri->{$localName} = $uri;
    }

    # if this node has a parent node, get its mappings as well
    my $parentNode = $node->parentNode();
    if ( defined($parentNode) ) {
        my ( $parentLocalNameToUri, $parentUriToLocalName )
            = _getNamespaceMapping($parentNode);

        # add the new mappings
        for my $localName ( keys %$parentLocalNameToUri ) {

            # only add the definition if it is new
            if ( !exists( $localNameToUri->{$localName} ) ) {
                my $uri = $parentLocalNameToUri->{$localName};
                $localNameToUri->{$localName} = $uri;

            }
        }

    }
    return $localNameToUri;
}

1;
__END__

=head1 NAME

ESIP::OpenSearch - Perl extension for performing an ESIP opensearch

=head1 SYNOPSIS

  use ESIP::OSDD;

  ...
  
  my $osdd = ESIP::OSDD->new( osddUrl => $osddUrl );


  # fill in a template
  my $filledTemplate = $osdd->fillTemplate(
      0,
      "os:count"   => 10,
      "time:start" => "2003-01-01T00:00:00Z",
      "time:end"   => "2003-01-31T23:59:59Z",
  );

  # search
  my $out = $osdd->performGranuleSearch(
      0,
      "os:count"              => 1000,
      "time:start"            => "2003-01-01T00:00:00Z",
      "time:end"              => "2003-01-05T23:59:59Z",
      "esipdiscovery:version" => "1.2",
  );

  # grab the output URLs
  if($out->{success}){
      my @urls = @{ $out->{searchUrls} };
  }

=head1 DESCRIPTION

This class retrieves an OSDD, parses out atom templates, fills in
templates, and searches for granules

=head2 new

  my $osdd = ESIP::OSDD->new( osddUrl => $osddUrl );

Create an OSDD class. Inputs (hash):

=over 4

=item I<osddUrl> - URL of the OSDD. This will be retrieved for you. Required 
element unless you specify the osddXml parameter.

=item I<osddXml> - Parsed (XML::LibXML) XML object with the OSDD. Required unless 
you specify the osddUrl parameter.

=item I<maxTryCount> [optional, default 1] - Specifies the number of times to try
each search query before failing.

=item  I<retryInterval> [optional, default 1] - Specifies how many seconds to wait
between each attempt to retrieve a search query result.


=item I<namespaceMapping> [optional] - Hash from prefixes to URIs. If not 
specified, the code assumes:

=over 8

=item os - http://a9.com/-/spec/opensearch/1.1/

=item geo - http://a9.com/-/opensearch/extensions/geo/1.0/

=item time - http://a9.com/-/opensearch/extensions/time/1.0/

=item esipdiscovery - http://commons.esipfed.org/ns/discovery/1.2/

=back

=back


=head2 fillTemplate

  my %params = ( 
     "os:count"   => 10, 
     "time:start" => "2003-01-01T00:00:00Z", 
     "time:end"   => "2003-01-31T23:59:59Z"); 
  my $filledTemplate = $osdd->fillTemplate(
     0, %params ); 


Fills the OSDD template and returns the resulting URL. Inputs:

=over 4

=item I<strict> - if set to a true value, the code will fail if mandatory elements
are not specified.

=item I<params> - hash with the the template fill values.

=back


=head2 performGranuleSearch

  my %params = (
    "os:count"              => 2,
    "time:start"            => "2003-01-01T00:00:00Z",
    "time:end"              => "2003-01-05T23:59:59Z",
    "esipdiscovery:version" => "1.2",
  );
  my $out = $osdd->performGranuleSearch(
    0,%params);


Fills in the OSDD template, calls the URL, and follows 'next' links to get
complete search results for the range specified. Inputs:

=over 4

=item I<strict> - if set to a true value, the code will fail if mandatory elements
are not specified.

=item I<params> - hash with the the template fill values. Start page/index 
values are ignored.

=back 

Output hash reference:

=over 4

=item I<success> - set to 1 if the search succeeded and 0 otherwise.

=item I<message> - if success if false, message will be filled with an error
explanation

=item I<response> - reference to an array of XML::LibXML objects with the search
response. If the code followed a 'next' link, there will be more than one
result.

=item I<searchUrls> - reference to an array of the URLs called to fulfill the 
search.

=back

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>


=cut

