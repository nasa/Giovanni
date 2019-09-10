package Giovanni::Search::OPeNDAP;

use 5.008008;
use strict;
use warnings;

use ESIP::OSDD;
use ESIP::ResponseParser::V1_2;
use Giovanni::Logger;
use Giovanni::Util;
use DataAccess::OPeNDAP;
use DataAccess::Translator;
use Digest::MD5 qw(md5_hex);
use JSON;
use XML::LibXML;

our $VERSION = '0.01';

# Constructor for the object
################################################################################
sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    # Argument list
    my @mandatoryArgs
        = qw(accessName osddUrl sampleFile sampleOpendap timeChunks dataId);
    my @optionalArgs
        = qw(responseFormat logger sessionDir variableString searchFilter
        loginCredentials);

    # A hash to indicate mandatory arguments
    my %mandatoryFlag = map { $_ => 1 } @mandatoryArgs;
    for my $arg ( @mandatoryArgs, @optionalArgs ) {
        if ( exists $params{$arg} ) {
            $self->{$arg} = $params{$arg};
        }
        elsif ( $mandatoryFlag{$arg} ) {
            die "Giovanni::Search::OPeNDAP must have '$arg' key in the hash";
        }
    }

    # By default, we expect data in netCDF
    $self->{responseFormat} = 'netCDF' unless exists $self->{responseFormat};

    return $self;
}

# Performs the search, returns multiple array refs with corrresponding indices
################################################################################
sub search {
    my ($self) = @_;

    # Perform a search for each time chunk. Caching is done at the time chunk
    # level.
    # Adding 2 new parms to handle some Federated Giovanni Partner issues
    # FEDGIANNI-1472
    my $osdd = ESIP::OSDD->new(
        osddUrl       => $self->{osddUrl},
        sampleFile    => $self->{sampleFile},
        sampleOpendap => $self->{sampleOpendap},
        searchFilter  => $self->{searchFilter}
    );
    my @results;
    my @searchUrls;
    for ( my $i = 0; $i < scalar( @{ $self->{timeChunks} } ); $i++ ) {
        my $rh_chunk = $self->{timeChunks}->[$i];
        $self->{logger}->user_msg( "Searching for time chunk "
                . ( $i + 1 ) . " of "
                . scalar( @{ $self->{timeChunks} } )
                . " for '"
                . $self->{variableString}
                . ".'" )
            if exists $self->{logger}
                && exists $self->{variableString};
        my $rh_chunkResults = $self->_processTimeChunk( $osdd, $rh_chunk );
        if ( defined $rh_chunkResults ) {
            push( @results,    @{ $rh_chunkResults->{results} } );
            push( @searchUrls, @{ $rh_chunkResults->{searchUrls} } );
        }
    }

    return ( \@results, \@searchUrls );
}

# Processes a time chunk, returning a hash-ref containing urls, labels,
# startTimes, endTimes, and searchUrls keys.
################################################################################
sub _processTimeChunk {
    my ( $self, $osdd, $rh_chunk ) = @_;

    my $logMsg = "Processing chunk ($rh_chunk->{start}, $rh_chunk->{end})";
    $self->{logger}->info($logMsg) if exists $self->{logger};

    my @results;    # will be populated in this subroutine

    # Call ESIP::OSDD::performGranuleSearch to perform the search on the time
    # chunk interval.
    $logMsg = "Performing granule search";
    $self->{logger}->info($logMsg) if exists $self->{logger};

    my $resp = $osdd->performGranuleSearch(
        0,
        "time:start"            => $rh_chunk->{start},
        "time:end"              => $rh_chunk->{end},
        "os:count"              => 1024,
        "esipdiscovery:version" => "1.2"
    );

    $self->_logUrlArray( "OpenSearch URLs:", $resp->{searchUrls} );
    unless ( $resp->{success} ) {
        my $logMsg = "Unable to complete search. " . $resp->{message};
        $self->{logger}->error($logMsg) if exists $self->{logger};

        $logMsg = "Unable to complete search";
        $self->{logger}->user_error($logMsg) if exists $self->{logger};

        return;
    }

    # Now we are doing Translated URLs first
    # instead receiving whatever the Mirador was last configured for
    # ...or in case we don't publish opendap URLs to CMR.

    $logMsg = "Getting OPeNDAP URLs from DataAccess::Translator "
        . "and ESIP::Response::getDataUrls";
    $self->{logger}->debug($logMsg) if exists $self->{logger};

    my $translator = DataAccess::Translator->new(
        SOURCE_URL => $self->{sampleFile},
        TARGET_URL => $self->{sampleOpendap}
    );

    my @res            = $resp->{response}->getDataUrls;
    my @dataUrls       = map( $_->{url}, @res );
    my @translatedUrls = $translator->translate(@dataUrls);

    if (@translatedUrls) {

        for my $i ( 0 .. scalar @translatedUrls - 1 ) {
            push(
                @results,
                { 'url' => $translatedUrls[$i],
                    'startTime' => $res[$i]->{startTime},
                    'endTime'   => $res[$i]->{endTime}
                }
            );
        }

        $self->_logUrlArray( "Data URLs:",       \@dataUrls );
        $self->_logUrlArray( "Translated URLs:", \@translatedUrls );
    }
    else {

        # If there are no DataURLs translated to OpendapURLs
        # then this block checks the response for OPeNDAP URLs
        # and uses them if they are present.
        my @directResults = $resp->{response}->getOPeNDAPUrls();
        my $logMsg
            = "Getting OPeNDAP URLs from ESIP::Response::GetOPeNDAPURLs";
        $self->{logger}->debug($logMsg) if exists $self->{logger};

        push( @results, @directResults );

        my @urlArray = map( $_->{url}, @results );
        $self->_logUrlArray( "Results from above:", \@urlArray );
    }

    # Results that have the same URL should not appear twice. Filter the list
    # of results to guarantee that the url field is unique.
    my @results_dups = @results;
    @results = ();
    my %seenUrls;

    for my $result (@results_dups) {
        next if $seenUrls{ $result->{url} };
        push( @results, $result );
        $seenUrls{ $result->{url} } = 1;
    }

    # The final list of URLs is a list of OPeNDAP download URLs, which is
    # obtained by mapping the URLs through DataAccess::OPeNDAP. In addition,
    # this obtains labels for each URL.
    $logMsg = "Retrieving Opendap Download List";
    $self->{logger}->info($logMsg) if exists $self->{logger};

    my @opendapUrls = map( $_->{url}, @results );
    my @opendapVars = split( ',', $self->{accessName} );
    my $agent;
    if ( $self->{oddxDims} ) {
        $logMsg = "ddx dimension information provided to DataAccess::OPeNDAP";
        $self->{logger}->info($logMsg) if exists $self->{logger};
        $agent = DataAccess::OPeNDAP->new(
            METADATA    => $self->{oddxDims},
            URLS        => \@opendapUrls,
            VARIABLES   => \@opendapVars,
            START       => $rh_chunk->{start},
            END         => $rh_chunk->{end},
            FORMAT      => $self->{responseFormat},
            CREDENTIALS => $self->{loginCredentials},
        );
    }
    else {
        $agent = DataAccess::OPeNDAP->new(
            URLS        => \@opendapUrls,
            VARIABLES   => \@opendapVars,
            START       => $rh_chunk->{start},
            END         => $rh_chunk->{end},
            FORMAT      => $self->{responseFormat},
            CREDENTIALS => $self->{loginCredentials},
        );
    }

    if ( $agent->onError() ) {
        my $errCode = $agent->onError;
        my $errMsg  = $agent->errorMessage;
        my $logMsg  = "Error $errCode from DataAccess::OPeNDAP->new: $errMsg";
        $self->{logger}->error($errMsg) if exists $self->{logger};
        $self->_logUrlArray( "Search URLs:", $resp->{searchUrls} );
        print $errMsg unless exists $self->{logger};
        die "DataAccess::OPeNDAP->new error";
    }

    my ( $pairs, $errors ) = $agent->getOpendapDownloadList;
    if ( ( ref($errors) eq 'ARRAY' ) && (@$errors) ) {
        my $errMsg = join( "\n", @$errors );
        my $logMsg = "Error in getOpendapDownloadList: $errMsg";
        $self->{logger}->error($errMsg) if exists $self->{logger};
        $self->_logUrlArray( "Search URLs:", $resp->{searchUrls} );
        print $errMsg unless exists $self->{logger};
        die "$logMsg";
    }
    my @pairs = @$pairs;

    for my $i ( 0 .. scalar @pairs - 1 ) {
        my ( $url, $label ) = @{ $pairs[$i] };
        $results[$i]->{url}   = $url;
        $results[$i]->{label} = $label;
        delete $results[$i]->{title};
    }

    my $rh_chunkResults
        = { 'results' => \@results, 'searchUrls' => $resp->{searchUrls} };
    return $rh_chunkResults;
}

# Dumps a URL array to the logger.
################################################################################
sub _logUrlArray {
    my ( $self, $msg, $ra_urls ) = @_;

    return unless exists $self->{logger};

    $self->{logger}->debug($msg);
    $self->{logger}->debug($_) for @$ra_urls;
}

1;
__END__

=head1 NAME

Giovanni::Search::OPeNDAP - OpenSearch client with ability to translate results
                            to OPeNDAP URLs.

=head1 SYNOPSIS

use Giovanni::Search::OPeNDAP;

my $search = Giovanni::Search::OPeNDAP->new(
    accessName           => $accessName,
    osddUrl              => $osdd,
    sampleFile           => $sampleFile,
    sampleOpendap        => $sampleOpendap,
    timeChunks           => \@chunks,
    dataId               => $data_id,
   [logger               => $self->{logger},]
   [sessionDir           => $self->{session_dir},]
   [variableString       => $variableStr,]
   [searchFilter         => $searchFilter,]
   [loginCredentials     => $self->{loginCredentials},]
   [responseFormat       => $responseFormat,]
   [oddxDims             => $oddxDims,]
);

$search->search();


=head1 DESCRIPTION

Input parameters:

=over 4

=item accessName

The value of the accessName for a variable, obtained from the catalog

=item osddUrl

The OpenSearch Data Descriptor URL, obtained from the catalog

=item sampleFile

The sample data granule URL, obtained from the catalog

=item timeChunks

Array of hash references that describe the start time, end time, and overlap
for one chunk of a search that has been split into chunks

=item dataId

The uniquie id for a variable, obtained form the data catalog

=item logger

A Giovanni::Logger object used for logging

=item variableString

A string that describes a variable

=item searchFilter

An optional regular expression that can be used to filter the search results

=item loginCredentials

Credentials for basic authentication used for OPeNDAP access. Should be a
reference to a hash whose keys are URL locations (host:port) and whose
values are references to hashes whose keys are realms and whose values are
references to hashes with key/value pairs DOWNLOAD_USER/username and
DOWNLOAD_CRED/pwd.

=item responseFormat

Desired format for the data that are downloaded via the URLs returned by
the getOpendapUrls method of a DataAccess::OPeNDAP object, either 'netCDF',
'netCDF4', 'DODS', or 'ASCII'. 

=item oddxDims

XML describing the dimensions of a variable, as would be returned by the
getOpendapMetadata method of a DataAccess::OPeNDAP object.

=back

=head1 AUTHOR

Daniel da Silva, E<lt>daniel.e.dasilva@nasa.govE<gt>

=cut


