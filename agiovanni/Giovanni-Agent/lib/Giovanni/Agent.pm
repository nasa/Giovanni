#$Id: Agent.pm,v 1.15 2015/08/06 18:44:11 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
package Giovanni::Agent;

use 5.008008;
use strict;
use warnings;

require Exporter;
use vars '$AUTOLOAD';

#our @ISA = qw(Exporter);
use base qw( Exporter );
use base qw( LWP::UserAgent );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Agent ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

=head1 NAME

Giovanni::Agent - Perl module for encapsulating Giovanni request agent.

=head1 SYNOPSIS

  use Giovanni::Agent;
  my $agent = Giovanni::Agent->new(URL => "http://host.ecs.nasa.gov/daac-bin/giovanni/service_manager.pl?session=...");
  my $requestResponse = $agent->submit_request;
  my $downloadResponse = $requestResponse->download_files(DIR => '/dir');

=head1 DESCRIPTION

Giovanni::Agent encapsulates a Giovanni service request.
When a request URL is submitted, the status is checked until the request has
completed. If the request is successful, result files can be downloaded to
a specified directory.

=head1 CONSTRUCTOR

=head2 new( URL => requestURL [, DEBUG => 1] [, %options] )

If the DEBUG option is set, status complete is written to stdout.

The MAX_TIMEOUT option sets the maximum time in seconds for the workflow to
finish and defaults to 120 seconds (2 minutes). 

%options includes all options available to LWP::UserAgent.

=head1 METHODS

=head2 submit_request()

=head2 getDownloadedDataFileNames()

Accepts type of files ('data', 'image', 'lineage') as an argument. Returns a list of downloaded file paths or an empty list if such a list can't be found.

=head2 EXPORT

None by default.

=head1 SEE ALSO


=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=cut

################################################################################

sub new() {
    my ( $class, %input ) = @_;

    my $url = $input{URL};
    delete $input{URL};
    my $debug = $input{DEBUG};
    delete $input{DEBUG};
    my $maxTime = $input{MAX_TIME};
    delete $input{MAX_TIME};
    delete $input{agent};

    my $self = $class->SUPER::new(
        agent => join( '/', __PACKAGE__, $Giovanni::Agent::VERSION ),
        %input,
    );

    unless ( defined $url ) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "No URL provided";

        #    } elsif (! _valid_request_url($url) ) {  # Check URL for validity
        #        $self->{_ERROR_TYPE} = 1;
        #        $self->{_ERROR_MESSAGE} = "Invalid URL";
    }
    else {
        my $request = Giovanni::Request->new($url);
        if ( $request->onError ) {
            $self->{_ERROR_TYPE}    = 2;
            $self->{_ERROR_MESSAGE} = $request->errorMessage;
        }
        else {
            $self->{_REQUEST_URL}     = $url;
            $self->{_INITIAL_REQUEST} = $request;
        }
    }
    $self->{_DEBUG} = $debug if $debug;
    $self->{_MAX_TIME} = defined($maxTime) ? $maxTime : 120;

    return bless( $self, $class );
}

sub submit_request {
    my ( $self, $time_out ) = @_;
    my $initial_response = $self->_request( $self->getInitialRequest );

    # Check initial response.
    unless ( $initial_response->is_success ) {
        return $initial_response;
    }

    # Send additional requests to check for status
    my $status_request_url = $initial_response->_construct_status_request_url;
    my $status_request
        = Giovanni::Request->new( $status_request_url->uri->as_string );
    if ( $status_request->onError ) {
        return $status_request->response;
    }
    $self->{STATUS_REQUEST} = $status_request;

    my $percentComplete = 0;
    my $maxSystemTime
        = defined $time_out
        ? time() + $time_out
        : time() + $self->{_MAX_TIME};
    my $isTimeOut = 0;
    my $fsleep      = 0.25;
    my $sleepFactor = 0.25;
    my $isleep      = int($fsleep);
    print STDERR "sleeping $isleep\n" if $self->debug && $isleep;
    sleep($isleep);

    my $status_response;
    while ( $percentComplete < 100.0 ) {
        $status_response = $self->_request($status_request);
        last unless $status_response->is_success;

        if ( time() > $maxSystemTime ) {
           $isTimeOut = 1;
           last;
        }
        $fsleep = $fsleep >= 2 ? 0.5 : ( $fsleep + $sleepFactor );

        #$isleep = int($fsleep);
        print STDERR "sleeping $isleep\n" if $self->debug && $isleep;
        sleep($fsleep);
        $percentComplete = $status_response->getPercentComplete;
        $percentComplete = 0 unless $percentComplete;
        print STDERR "% complete = $percentComplete\n" if $self->debug;
    }

    # cancel workflow if workflow is not finished before specified time
    if ( $percentComplete < 100.0 ) {
        my $cancel_request_string
            = $status_request_url->uri->as_string . "&cancel=1";
        my $cancel_request = Giovanni::Request->new($cancel_request_string);
        if ( $cancel_request->onError ) {
            return $cancel_request->response;
        }
        my $cancel_response = $self->_request($cancel_request);
        if ( $isTimeOut ) {
             $status_response->setErrorMessage(
            "The request is taking too long to complete. Please try your request at a later time. Visit https://disc.gsfc.nasa.gov/contact for further help.");
        }
    }

    # Return response object
    return $status_response;
}

sub _request {
    my $self    = shift;
    my $request = shift;

    my $response = $self->SUPER::request( $request, @_ );

    # Allow regular HTTP::Requests to flow through
    return $response unless $request->isa('Giovanni::Request');
    return Giovanni::Response->new( $self->getInitialRequest, $response );
}

sub AUTOLOAD {
    my ( $self, $arg ) = @_;

    if ( $AUTOLOAD =~ /.*::getInitialRequest/ ) {
        return $self->{_INITIAL_REQUEST};
    }
    elsif ( $AUTOLOAD =~ /.*::debug/ ) {
        return $self->{_DEBUG};
    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE} if exists $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE} if exists $self->{_ERROR_MESSAGE};
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorMessage/ ) {
        $self->{_ERROR_MESSAGE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorType/ ) {
        $self->{_ERROR_TYPE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getRequestUrl/ ) {
        return $self->{_REQUEST_URL} if exists $self->{_REQUEST_URL};
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }
}

################################################################################

=head1 NAME

Giovanni::Request - Encapsulate a Giovanni service request

=head1 SYNOPSIS

$giovanniRequest = Giovanni::Request->new($url);

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new( [%options] )

=head1 METHODS

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=head1 COPYRIGHT AND LICENSE

=cut

package Giovanni::Request;

use strict;
use warnings;
use vars '$AUTOLOAD';

use base qw( HTTP::Request );
use URI::QueryParam;

sub new {
    my ( $class, $url ) = @_;

    my $uri = URI->new($url);

    my $servicePart;
    my $fragment = $uri->fragment;
    if ($fragment) {

        # If a fragment (substring that follows '#') is found in the URL,
        # assume it is a bookmarkable URL
        my $response = _getBookmarkableUrl($url);

        if ( $response->{error} ) {
            my $self = {};
            $self->{_ERROR_TYPE}    = 1;
            $self->{_ERROR_MESSAGE} = $response->{error};
            $self->{_RESPONSE}      = $response;
            return bless( $self, $class );
        }

        # Extract service manager URL from bookmarkable URL response
        my ( $servicePart, $portal )
            = _getServicePart( $response->{content} );
        unless ($servicePart) {
            my $self = {};
            $self->{_ERROR_TYPE} = 2;
            $self->{_ERROR_MESSAGE}
                = "No service manager URL found in response from $url";
            return bless( $self, $class );
        }

        # Convert a bookmarkable URL to a service manager URL by inserting
        # $servicePart before the fragment
        my $new_url
            = $uri->scheme . ':' . $uri->opaque . $servicePart . $fragment;
        $uri = URI->new($new_url);
    }

    # Set format to 'xml', overriding any existing format
    my %query_params = $uri->query_form;
    $query_params{format} = 'xml';
    $uri->query_form( \%query_params );

    my $method = 'GET';
    my $self = $class->SUPER::new( $method, $uri );
    $self->{_SERVICE_PART} = $servicePart if $servicePart;

    return $self;
}

sub _getBookmarkableUrl {
    my $url = shift;

    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    unless ($ua) {
        return { error =>
                "Error creating user agent for fetching bookmarkable URL" };
    }
    my $response = $ua->get($url);
    if ( $response->is_error ) {
        return { error => "Error fetching $url: " . $response->content };
    }

    return { content => $response->content };
}

sub _getServicePart {

    # Expect the response from a bookmarkable URL to contain javascript
    # that creates a G4 session object by specifying a serviceManagerURL
    # and a portal.
    # Here we will try to find a string that matches the pattern
    # "serviceManagerURL" : "<urlString>"

    my $content = shift;

    my $servicePart = $1 if $content =~ /"serviceManagerURL"\s*:\s"(.+?)"/;
    my $portal      = $1 if $content =~ /"portal"\s*:\s"(.+?)"/;

    return ( $servicePart, $portal );
}

sub AUTOLOAD {
    my ( $self, $arg ) = @_;

    if ( $AUTOLOAD =~ /.*::debug/ ) {
        return $self->{_DEBUG};
    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE} if exists $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE} if exists $self->{_ERROR_MESSAGE};
    }
    elsif ( $AUTOLOAD =~ /.*::response/ ) {
        return $self->{_RESPONSE} if exists $self->{_RESPONSE};
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorMessage/ ) {
        $self->{_ERROR_MESSAGE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorType/ ) {
        $self->{_ERROR_TYPE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getServicePart/ ) {
        return $self->{_SERVICE_PART};
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }
}

################################################################################

=head1 NAME

Giovanni::Response - Encapsulate a response
received from a Giovanni service request

=head1 SYNOPSIS

$agent = Giovanni::Agent->new( URL => $request_url );
$response = $agent->submit_request;

=head1 DESCRIPTION

Giovanni::Response extends the HTTP::Response received by submitting
a Giovanni::Request and includes methods for downloading files whose
names are found in the response.

=head1 CONSTRUCTOR

=head2 new( $http_response )

=head1 METHODS

=head2 download_data_files( DIR => $downloadDir )

=head2 download_image_files( DIR => $downloadDir )

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=head1 COPYRIGHT AND LICENSE

=cut

package Giovanni::Response;

use strict;
use warnings;

use base qw( HTTP::Response );
use XML::LibXML;
use LWP::UserAgent;
use File::Spec;
use File::Basename;
use File::Copy;
use LWP::MediaTypes qw(guess_media_type media_suffix);
use Net::Netrc;
use Giovanni::UrlDownloader;

use vars '$AUTOLOAD';

sub new {
    my ( $class, $initial_request, $response ) = @_;

    my $self = bless $response, $class;

    # Return original response if request failed
    return $self unless $self->SUPER::is_success;

    $self->{_INITIAL_REQUEST} = $initial_request;

    my $parser = XML::LibXML->new();
    my $dom;
    eval { $dom = $parser->parse_string( $response->content ); };
    if ($@) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Error parsing response: $@";
        return $self;
    }
    my $doc = $dom->documentElement();

    my ($sessionNode) = $doc->findnodes(qq(/session));
    unless ($sessionNode) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Unexpected response: no session element";
        return $self;
    }

    my ($errorNode) = $sessionNode->findnodes(qq(./error));
    if ($errorNode) {
        my $message = $errorNode->textContent;
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = $message;
        return $self;
    }
    my $sessionId = $sessionNode->getAttribute('id');
    $self->{_SESSION_ID} = $sessionId;

    my ($resultsetNode) = $sessionNode->findnodes(qq(./resultset));
    unless ($resultsetNode) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Unexpected response: no resultset element";
        return $self;
    }
    my $resultsetId = $resultsetNode->getAttribute('id');
    $self->{_RESULTSET_ID} = $resultsetId;

    my ($resultNode) = $resultsetNode->findnodes(qq(./result));
    unless ($resultNode) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Unexpected response: no result element";
        return $self;
    }
    my $resultId = $resultNode->getAttribute('id');
    $self->{_RESULT_ID} = $resultId;

    my ($statusNode) = $resultNode->findnodes(qq(./status));
    unless ($statusNode) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Unexpected response: no status element";
        return $self;
    }
    my ($statusCodeNode) = $statusNode->findnodes(qq(./code));
    unless ($statusCodeNode) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Unexpected response: no code element";
        return $self;
    }
    my $statusCode = $statusCodeNode->textContent;
    $self->{_STATUS_CODE} = $statusCode;

    my ($messageNode) = $statusNode->findnodes(qq(./message));
    $self->{_MESSAGE} = $messageNode->textContent if $messageNode;

    if ($statusCode) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE}
            = $self->{_MESSAGE}
            ? $self->{_MESSAGE}
            : "Error status: $statusCode";
        return $self;
    }

    my ($percentCompleteNode) = $statusNode->findnodes(qq(./percentComplete));
    unless ($percentCompleteNode) {
        return $self;
    }
    my $percentComplete = $percentCompleteNode->textContent;
    $self->{_PERCENT_COMPLETE} = $percentComplete || 0;
    unless ( $percentComplete == 100.0 ) {
        return $self;
    }

    my ($lineageNode) = $resultNode->findnodes(qq(./lineage));
    unless ($lineageNode) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Unexpected response: no lineage element";
        return $self;
    }
    $self->{_LINEAGE} = $lineageNode->textContent();

    my (@dataNodes) = $resultNode->findnodes(qq(./data));
    unless (@dataNodes) {
        return $self;
    }

    my @dataFiles;
    my @imageFiles;
    my @absImageFiles;
    foreach my $dataNode (@dataNodes) {
        my @fileGroupNodes = $dataNode->findnodes(qq(./fileGroup));
        foreach my $fileGroupNode (@fileGroupNodes) {
            next unless $fileGroupNode;

            # Check for error status and exit if Failed
            my ($fileGroupStatus) = $fileGroupNode->findnodes(qq(./status));
            if ($fileGroupStatus) {

                # React to the status node only if present
                # to support testing of older giovannis
                $fileGroupStatus = $fileGroupStatus->textContent;
                my ($fileGroupMessage)
                    = $fileGroupNode->findnodes(qq(./status));
                $fileGroupMessage = $fileGroupMessage->textContent
                    if $fileGroupMessage;
                if ( $fileGroupStatus eq "Failed" ) {
                    $self->{_ERROR_TYPE}    = 1;
                    $self->{_ERROR_MESSAGE} = "Error in fileGroup node";
                    $self->{_ERROR_MESSAGE}
                        .= $fileGroupMessage ? ': ' . $fileGroupMessage : '';
                    return $self;
                }
            }

            # Find files in the group
            my @dataFileNodes = $fileGroupNode->findnodes(qq(./dataFile));
            foreach my $dataFileNode (@dataFileNodes) {
                next unless $dataFileNode;

                # Check for error status and exit if Failed
                my ($dataFileStatus) = $dataFileNode->findnodes(qq(./status));
                if ($dataFileStatus) {

                    # React to the status node only if present
                    # to support testing of older giovannis
                    $dataFileStatus = $dataFileStatus->textContent;
                    my ($dataFileMessage)
                        = $dataFileNode->findnodes(qq(./status));
                    $dataFileMessage = $dataFileMessage->textContent
                        if $dataFileMessage;
                    if ( $dataFileStatus eq "Failed" ) {
                        $self->{_ERROR_TYPE}    = 1;
                        $self->{_ERROR_MESSAGE} = "Error in dataFile node";
                        $self->{_ERROR_MESSAGE}
                            .= $dataFileMessage
                            ? ': ' . $dataFileMessage
                            : '';
                        return $self;
                    }
                }

                # Find plots in the data file
                my ($dataUrlNode) = $dataFileNode->findnodes(qq(./dataUrl));
                if ($dataUrlNode) {
                    my $dataUrl = $dataUrlNode->getAttribute('value');
                    # Old transition (Pre - Static Plot Options):
                    if (! $dataUrl) {
                         $dataUrl = $dataUrlNode->textContent;
                    }
                    $dataUrl = $self->_makeAbsolute($dataUrl);
                    my $dataUrlLabel = $dataUrlNode->getAttribute('label');
                    push @dataFiles, { $dataUrl, $dataUrlLabel }
                        if $dataUrl;
                }
                my ($imageNode) = $dataFileNode->findnodes(qq(./image));
                if ($imageNode) {

                    # Check for error status and exit if Failed
                    my ($imageStatus) = $imageNode->findnodes(qq(./status));
                    if ($imageStatus) {

                        # React to the status node only if present
                        # to support testing of older giovannis
                        $imageStatus = $imageStatus->textContent;
                        my ($imageMessage)
                            = $imageNode->findnodes(qq(./status));
                        $imageMessage = $imageMessage->textContent
                            if $imageMessage;
                        if ( $imageStatus eq "Failed" ) {
                            $self->{_ERROR_TYPE}    = 1;
                            $self->{_ERROR_MESSAGE} = "Error in image node";
                            $self->{_ERROR_MESSAGE}
                                .= $imageMessage ? ': ' . $imageMessage : '';
                            return $self;
                        }
                    }

                    # Parse URLs etc
                    my ($srcNode) = $imageNode->findnodes(qq(./src));
                    my $src = $srcNode->textContent if $srcNode;
                    my $imageUrl = $src if $src;

                    my $absImageUrl = $self->_makeAbsolute($imageUrl);
                    my $imageUrlLabel;
                    push @absImageFiles, { $absImageUrl, $imageUrlLabel }
                        if $absImageUrl;
                    push @imageFiles, { $absImageUrl, $imageUrlLabel }
                        if $absImageUrl;
                }
            }
        }
    }
    $self->{_DATA_FILES}      = \@dataFiles     if @dataFiles;
    $self->{_IMAGE_FILES}     = \@imageFiles    if @imageFiles;
    $self->{_ABS_IMAGE_FILES} = \@absImageFiles if @absImageFiles;

    return $self;
}

sub is_success {

    # Request is successful only if HTTP request was successful and there
    # were no errors.

    my $self = shift;
    return ( $self->SUPER::is_success && !$self->{_ERROR_MESSAGE} );
}

sub _construct_status_request_url {
    my $self = shift;

    my $request = $self->request;
    my $method  = $request->method;
    my $uri     = $request->uri;

    my %status_query_params = (
        'session'   => $self->{_SESSION_ID},
        'resultset' => $self->{_RESULTSET_ID},
        'result'    => $self->{_RESULT_ID},
        'format'    => 'xml',
    );

    my $status_uri = $uri->clone;
    $status_uri->query_form( \%status_query_params );
    my $status_request = HTTP::Request->new( $method, $status_uri );

    return $status_request;
}

sub _get_lineage_url {
    my ($self) = shift;

    # The initial request was formed in Giovanni::Request::new by inserting
    # $service_part before the fragment. To construct a final lineage
    # URL, we want to combine the portion of the initial request that precedes
    # $service_part with the lineage URL.

    # The value of $service_part here must be the same as the value of
    # $service_part in Giovanni::Request::new
    my $lineage_url  = $self->_makeAbsolute( $self->{_LINEAGE} );
    my $lineage_uri  = URI->new($lineage_url);
    my %query_params = $lineage_uri->query_form;

    # Add a type=XML query parameter to obtain the lineage in xml
    $query_params{type} = 'xml';
    $lineage_uri->query_form(%query_params);
    my $ua = $self->getUserAgent();
    unless ($ua) {
        print STDERR "Error creating user agent for fetching lineage files";
        return;
    }
    $ua->env_proxy;

    return $lineage_uri->as_string;
}

sub _add_credentialed_user_agent {

    my $self = shift;

    if ( $self->{_UA} ) {
        return $self->{_UA};
    }
    my $urs   = '';
    my $uid   = '';
    my $pwd   = '';
    my $netrc = 0;

# Try to use the user's .netrc file, if not, use Giovanni Application credentials.
# If neither of these are provided (giovanni.cfg is not populated with creds for example)
# then this whole business should not work as the whole point fo FEDGIANNI-2688 was
# that we need URS creds to get stuff from our servers now.
    my $LOGIN_CREDENTIALS = $GIOVANNI::LOGIN_CREDENTIALS;
    my @keys              = keys %$LOGIN_CREDENTIALS;

    # .netrc or not, it still needs the realms from above LOGIN_CREDENTIALS
    unless (@keys) {
        return undef;
    }

    $urs = $keys[0];

# The giovanni.cfg has the realm, but we can use the user's .netrc creds instead of the Giovanni credentials
    my $netrcstuff = Net::Netrc->lookup($urs);
    if ($netrcstuff) {
        $uid = $netrcstuff->login;
        $pwd = $netrcstuff->password;
        if ( $uid and $pwd ) {
            $netrc = 1;
            foreach my $site ( keys %$LOGIN_CREDENTIALS ) {
                foreach my $realm ( keys %{ $LOGIN_CREDENTIALS->{$site} } ) {
                    $LOGIN_CREDENTIALS->{$site}->{$realm}{DOWNLOAD_USER}
                        = $uid;
                    $LOGIN_CREDENTIALS->{$site}->{$realm}{DOWNLOAD_CRED}
                        = $pwd;
                }
            }
        }
        else {
            warn
                "No suitable credentials found in your local .netrc file, using Giovanni credentials, Will use Giovanni Application credentials\n"
                unless ( $uid and $pwd );
        }
    }
    else {
        warn "Could not find a line in your .netrc referencing " . $urs
            . " Will use Giovanni Application credentials.\n";
    }

    my $downloader = Giovanni::UrlDownloader->new(
        TIME_OUT        => 60,
        RETRY_INTERVAL  => 3,
        MAX_RETRY_COUNT => 3,
        CREDENTIALS     => $LOGIN_CREDENTIALS
    );

    $downloader->{_UA}->ssl_opts( verify_hostname => 0 );
    $self->{_UA} = $downloader->{_UA};

}

sub getUserAgent() {
    my $self = shift;
    my $ua   = $self->{_UA};

    if ($ua) {
        return $ua;
    }
    else {
        $ua = $self->_add_credentialed_user_agent();

        # if we couldn't establish a credentialed user agent
        # with either .netrc files or the Giovanni credentials:
        if ( !$ua ) {
            $ua = LWP::UserAgent->new();
            $ua->env_proxy;
        }
    }
    return $ua;

}

sub _get_lineage_files {
    my $self = shift;

    my $lineage_query = $self->_get_lineage_url();

    # move this to Giovanni::Response::new
    my $ua = $self->getUserAgent();
    unless ($ua) {
        print STDERR "Error creating user agent for fetching lineage files";
        return;
    }
    $ua->env_proxy;

    my $response = $ua->get($lineage_query);
    if ( $response->is_error ) {
        print STDERR "Error fetching $lineage_query: ", $response->content;
        return;
    }

    my $parser = XML::LibXML->new();
    my $dom;
    eval { $dom = $parser->parse_string( $response->content ); };
    if ($@) {
        print STDERR "Error parsing response from $lineage_query: $@";
        return;
    }
    my $doc = $dom->documentElement();

    # Find the last lineage step element in the lineage response,
    # find the output elements in that step, and extract all of the
    # output file URLS
    my @stepNodes
        = ( $doc->getName() eq 'lineage' )
        ? $doc->findnodes('/lineage/step')
        : $doc->findnodes('/provenance/group/step');
    my $lastStepNode = $stepNodes[-1];
    my @outputNodes  = $lastStepNode->findnodes('.//output');
    my @outputFiles;
    foreach my $outputNode (@outputNodes) {
        my $url = $outputNode->textContent;
        $url =~ s/^\s+//;
        $url =~ s/\s+$//;
        if ($url) {
            my $label = basename($url);
            push @outputFiles, { $url, $label };
        }
    }

    return @outputFiles;
}

sub _makeAbsolute {
    my ( $self, $url ) = @_;

    # If $url is relative, prepend it with the portion of the initial
    # request that precedes the relative portion of the service_manager
    # part of the initial request. In other words, make it relative to
    # the same base URL that the service manager request is relative to.

    return unless $url;
    my $uri = URI->new($url);
    return $uri if $uri->authority;
    my $service_part    = $self->getServicePart;
    my $initial_request = $self->{_INITIAL_REQUEST}->uri->as_string;
    if ( $service_part && $initial_request =~ /$service_part/ ) {
        $initial_request =~ s/$service_part.+//;
    }
    if ( $url !~ /^\.\./ ) {
        $initial_request =~ s/\/daac-bin//;
    }
    my $absolute_uri = URI->new_abs( $url, $initial_request );
    return $absolute_uri->as_string;
}

sub download_files {

    # Download data files produced by a completed service request
    my ( $self, $type, %ARGS ) = @_;

    #    my $response = $self;
    my $response = Giovanni::Response->new( $self->getInitialRequest, $self );
    $response->{_DOWNLOADED_FILE_PATH}{$type}
        = [];    # an internal attribute to store downloaded file paths
    my $downloadDir = $ARGS{DIR};
    unless ($downloadDir) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "No DIR provided";
        return $response;
    }
    unless ( -d $downloadDir ) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "No directory found at $downloadDir";
        return $response;
    }
    my $debug = $ARGS{DEBUG};
    my @files;
    if ( $type eq 'data' ) {
        @files = @{ $self->{_DATA_FILES} } if $self->{_DATA_FILES};
    }
    elsif ( $type eq 'image' ) {
        @files = @{ $self->{_IMAGE_FILES} } if $self->{_IMAGE_FILES};
    }
    elsif ( $type eq 'lineage' ) {
        @files = $self->_get_lineage_files();
    }
    elsif ( $type eq 'lineage_xml' ) {
        my $url      = $self->_get_lineage_url();
        my $filename = "lineage.xml";
        @files = ( { $url => $filename } );

    }
    unless (@files) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "No downloadable $type files.";
        return $response;
    }

    # move this to Giovanni::Response::new
    my $ua = $self->getUserAgent();
    unless ($ua) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Error creating user agent";
        return $response;
    }
    $ua->env_proxy;

    my @downloadPathList = ();

    foreach my $file (@files) {
        my ( $dataUrl, $dataUrlLabel ) = %$file;
        my $uri          = URI->new($dataUrl);
        my $downloadName = $dataUrlLabel;
        unless ($downloadName) {
            $downloadName = basename( $uri->path );
            ($downloadName) = split( '#', $downloadName );
        }
        my $downloadPath = File::Spec->catfile( $downloadDir, $downloadName );

      # If CGI request...convert to POST
      # (Earthdata redirect process seems to strip the parms from CGI requests
        my @keys = $uri->query_param;
        my $result;

        $result = $ua->request( HTTP::Request->new( GET => $dataUrl ),
                $downloadPath );

        if ( $result->is_success ) {
            print STDERR "Downloaded: $downloadName\n" if $debug;
            push( @downloadPathList, $downloadPath );
        }
        else {
            $self->{_ERROR_TYPE} = 1;
            $self->{_ERROR_MESSAGE}
                = "Error downloading $dataUrl to $downloadPath: "
                . $result->message;
            print STDERR $self->{_ERROR_MESSAGE}, "\n" if $debug;
            return $response;
        }
    }

    # Store downloaded file paths
    $response->{_DOWNLOADED_FILE_PATH}{$type} = \@downloadPathList;
    return $response;
}

sub build_post_request {
    my $uri  = shift;
    my @keys = $uri->query_param;
    my @values;
    foreach my $key (@keys) {
        push @values, $uri->query_param($key);
    }
    my %postdata;
    @postdata{@keys} = @values;
    my $url = $uri->scheme . '://' . $uri->host . $uri->path;
    return ( $url, \%postdata );
}

sub download_data_files {

    # Download data files produced by a completed service request
    my ( $self, %ARGS ) = @_;

    return $self->download_files( 'data', %ARGS );
}

sub download_image_files {

    # Download image files produced by a completed service request
    my ( $self, %ARGS ) = @_;

    return $self->download_files( 'image', %ARGS );
}

sub download_lineage_files {

    # Download lineage files produced by a completed service request
    my ( $self, %ARGS ) = @_;

    return $self->download_files( 'lineage', %ARGS );
}

sub file_urls {

    # Return URLs for a completed service request
    my ( $self, $type, %ARGS ) = @_;

    my $response = Giovanni::Response->new( $self->getInitialRequest, $self );
    my $debug = $ARGS{DEBUG};

    my @urls;

    my @files;
    if ( $type eq 'data' ) {
        @files = @{ $self->{_DATA_FILES} } if $self->{_DATA_FILES};
    }
    elsif ( $type eq 'image' ) {
        @files = @{ $self->{_IMAGE_FILES} } if $self->{_IMAGE_FILES};
    }
    elsif ( $type eq 'abs_image' ) {
        @files = @{ $self->{_ABS_IMAGE_FILES} } if $self->{_ABS_IMAGE_FILES};
    }
    elsif ( $type eq 'lineage' ) {
        @files = $self->_get_lineage_files();
    }
    unless (@files) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "No $type files found.";
        return;
    }
    foreach my $file (@files) {
        my ( $url, $urlLabel ) = %$file;
        push @urls, $url if $url;
    }
    return @urls;
}

sub data_urls {

    # Return data urls produced by a completed service request
    my ( $self, %ARGS ) = @_;

    return $self->file_urls( 'data', %ARGS );
}

sub image_urls {

    # Return data urls produced by a completed service request
    my ( $self, %ARGS ) = @_;

    return $self->file_urls( 'image', %ARGS );
}

sub abs_image_urls {

    # Return data urls produced by a completed service request
    my ( $self, %ARGS ) = @_;

    return $self->file_urls( 'abs_image', %ARGS );
}

sub lineage_urls {

    # Return lineage urls produced by a completed service request
    my ( $self, %ARGS ) = @_;

    return $self->file_urls( 'lineage', %ARGS );
}

sub message {
    my $self = shift;

    return $self->{_ERROR_MESSAGE} if exists $self->{_ERROR_MESSAGE};
    return $self->SUPER::message;
}

sub AUTOLOAD {
    my ( $self, $arg ) = @_;

    if ( $AUTOLOAD =~ /.*::getSessionId/ ) {
        return $self->{_SESSION_ID};
    }
    elsif ( $AUTOLOAD =~ /.*::getResultSetId/ ) {
        return $self->{_RESULTSET_ID};
    }
    elsif ( $AUTOLOAD =~ /.*::getResultId/ ) {
        return $self->{_RESULT_ID};
    }
    elsif ( $AUTOLOAD =~ /.*::getStatusCode/ ) {
        return $self->{_STATUS_CODE};
    }
    elsif ( $AUTOLOAD =~ /.*::getPercentComplete/ ) {
        return $self->{_PERCENT_COMPLETE};
    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE} if exists $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE} if exists $self->{_ERROR_MESSAGE};
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorMessage/ ) {
        $self->{_ERROR_MESSAGE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorType/ ) {
        $self->{_ERROR_TYPE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getInitialRequest/ ) {
        return $self->{_INITIAL_REQUEST};
    }
    elsif ( $AUTOLOAD =~ /.*::getDownloadedDataFileNames/ ) {
        return
            exists $self->{_DOWNLOADED_FILE_PATH}{data}
            ? @{ $self->{_DOWNLOADED_FILE_PATH}{data} }
            : ();
    }
    elsif ( $AUTOLOAD =~ /.*::getDownloadedImageFileNames/ ) {
        return
            exists $self->{_DOWNLOADED_FILE_PATH}{image}
            ? @{ $self->{_DOWNLOADED_FILE_PATH}{image} }
            : ();
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }
}

1;
__END__
################################################################################
