package Giovanni::Search::SSW;

use 5.008008;
use strict;
use warnings;
use URI::Escape;
use XML::LibXML::XPathContext;
use XML::LibXML;
use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);

use Giovanni::Util;

sub new {

    # logger
    # dataId
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;
    return $self;
}

sub search {

    # startTime (array)
    # endTime (array)
    # baseUrl
    # startPercent
    # endPercent
    my ( $self, %params ) = @_;

    if ( !exists( $params{startPercent} ) ) {
        $params{startPercent} = 0;
    }
    if ( !exists( $params{endPercent} ) ) {
        $params{endPercent} = 100;
    }

    my $currPercent      = $params{startPercent};
    my $percentIncrement = ( $params{endPercent} - $params{startPercent} ) /
        scalar( @{ $params{startTime} } );

    my $resultUrls;
    my @searchUrls = ();
    my @orderedSet = ();
    my $resultSet  = {};
    for ( my $i = 0; $i < scalar( @{ $params{startTime} } ); $i++ ) {

        # build the query URL
        my $startTime = uri_escape( $params{startTime}->[$i] );
        my $endTime   = uri_escape( $params{endTime}->[$i] );
        my $url       = $params{baseUrl}
            . "&start=$startTime&end=$endTime&output_type=xml";
        push( @searchUrls, $url );

        $self->{logger}->info("Search for $self->{dataId} using URL: $url")
            if exists( $self->{logger} );
        $self->{logger}->user_msg( "Searching for time chunk "
                . ( $i + 1 ) . " of "
                . scalar( @{ $params{startTime} } )
                . " for '$self->{variableString}.'" )
            if exists( $self->{logger} );

        # download data
        my $xpc = $self->_download($url);
        if ( !defined($xpc) ) {

            # no results, so return empty arrays
            return ( [], [], [] );
        }
        $self->{logger}->debug(
            "Downloaded search query for " . $self->{dataId} . ": $url" )
            if exists( $self->{logger} );

        my $xpath       = qq(/agentResponse/downloadUrls/downloadUrl);
        my @resultNodes = $xpc->findnodes($xpath);
        for my $node (@resultNodes) {
            my %local;
            my $url       = Giovanni::Util::trim( $node->to_literal() );
            my $filename  = $node->getAttribute("label");
            my $startTime = $node->getAttribute("startTime")||"";
            my $endTime   = $node->getAttribute("endTime")||"";

            if ( defined( $resultSet->{$url} ) ) {
                $self->{logger}->info("Repeat result URL: $url ($filename)");
            }
            else {
                $local{label}     = $filename;
                $local{url}       = $url;
                $local{startTime} = $startTime;
                $local{endTime}   = $endTime;
                push @orderedSet, \%local;
                $self->{logger}->info("Result URL: $url ($filename)")
                    if defined( $self->{logger} );
            }

        }
        $currPercent += $percentIncrement;
        $self->{logger}->percent_done($currPercent)
            if exists( $self->{logger} );

    }
    return ( \@orderedSet, \@searchUrls );

}

sub _download {
    my ( $self, $url ) = @_;
    my $userAgent = LWP::UserAgent->new();
    $userAgent->env_proxy;
    $userAgent->timeout( $self->{timeOut} )
        if exists( $self->{timeOut} );

    my $response = $userAgent->get($url);
    if ( !$response->is_success() ) {
        my $msg
            = "Search url '$url' failed: "
            . $response->status_line() . ","
            . $response->content();
        $self->{logger}->error($msg) if exists( $self->{logger} );
        return undef;
    }

    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_string( $response->decoded_content() );
    my $xpc    = XML::LibXML::XPathContext->new($dom);
    return $xpc;

}

sub _filenameFromUrl {
    my ( $str, $id ) = @_;
    if ( defined($id) ) {
        return "searchResult_$id" . "_" . md5_hex($str) . ".xml";
    }
    else {
        return "searchResult_" . md5_hex($str) . ".xml";
    }
}

1;
__END__

=head1 NAME

Giovanni::Search::SSW - Perl extension for searching using the SSW

=head1 SYNOPSIS

  use Giovanni::Search::SSW;
  
  ...
  
  # create the search object
  my $searcher = Giovanni::Search::SSW->new(
    dataId     => $dataId
  );
  
  my ( $resultUrlsRef, $resultFilenamesRef ) = $searcher->search(
    startTime => \@startTimes,
    endTime   => \@endTimes,
    baseUrl   => $baseUrl
  );

=head1 DESCRIPTION

Performs a search using the SSW.

=head2 new

  my $searcher = Giovanni::Search::SSW->new(
    dataId     => $dataId
  );

Create a new search object. Inputs (hash):

=over 4

=item I<dataId> - the AESIR data field id

=item I<logger> (optional) - a Giovanni::Logger to log progress

=back

=head2 search

  my ( $resultUrlsRef, $resultFilenamesRef ) = $searcher->search(
    startTime => \@startTimes,
    endTime   => \@endTimes,
    baseUrl   => $baseUrl
  );

Performs a search against the SSW. Inputs (hash):

=over 4

=item I<startTime> - reference to an array of start times for each search query.

=item I<endTime> - reference to an array of end times for each search query.

=item I<baseUrl> - the basic SSW URL, which we will add each date range to for
search.

=item I<startPercent>, I<endPercent> (optional) - used by the logger to update
the percent done for this step as the searches proceed. 

=back

Returns two array references:

=over 4

=item I<resultUrlsRef> - array of search result URLs

=item I<resultFilenamesRef> - array of search result filenames

=back


=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>

=cut
