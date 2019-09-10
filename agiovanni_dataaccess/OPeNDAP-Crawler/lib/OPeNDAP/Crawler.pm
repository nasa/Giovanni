#!/usr/bin/perl

package OPeNDAP::Crawler;

use 5.008008;
use strict;
use warnings;

use Data::Dumper;
use IO::Handle;
use List::MoreUtils qw(any);
use LWP::UserAgent;
use File::Basename;
use File::Temp;
use Term::ANSIColor;
use threads;
use threads::shared;
use Thread::Queue;
use URI::URL;
use XML::LibXML;

use Giovanni::Util;

use constant {
    DEFAULT_NUM_THREADS           => 10,
    CRAWL_COMPLETE_CHECK_INTERVAL => 1,
    ROLLING_UPLOAD_INTERVAL       => 5,
};

our $VERSION = '0.01';

sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    # Argument list
    my @mandatoryArgs = qw(datasetID catalog);
    my @optionalArgs  = qw(numThreads grepPattern);

    my %mandatoryFlag = map { $_ => 1 } @mandatoryArgs;

    for my $arg ( @mandatoryArgs, @optionalArgs ) {
        if ( exists $params{$arg} ) {
            $self->{$arg} = $params{$arg};
        }
        elsif ( exists $mandatoryFlag{$arg} ) {
            die "OPeNDAP::Crawler must have '$arg' key in hash, ";
        }
    }

    # Set default for optional args
    $self->{numThreads} = DEFAULT_NUM_THREADS if !exists $self->{numThreads};
    $self->{grepPattern} = undef if !exists $self->{grepPattern};

    return $self;
}

sub crawl {
    my ( $self, %params ) = @_;

    # Die if parameters exists but are empty (indication of a bug in the
    # calling program).
    if ( exists $params{solrApiPrefix} && !$params{solrApiPrefix} ) {
        die "solrApiPrefix was supplied to crawl(), but was empty";
    }

    if ( exists $params{solrCollection} && !$params{solrCollection} ) {
        die "solrCollection was supplied to crawl(), but was empty";
    }

    # Flush STDOUT after every write.
    my $oldFlushSetting = $|;
    $| = 1;

    # The approach is to use a threaded, queue-based tree traversal
    # algorithm. Because processing an element of the queue may add
    # additional elements to the queue, threads are both consumers and
    # producers.
    my $qToVisit : shared = Thread::Queue->new();

    # Output queues, indeces correspond
    my $qUrls : shared       = Thread::Queue->new();
    my $qStartTimes : shared = Thread::Queue->new();
    my $qEndTimes : shared   = Thread::Queue->new();

    # Pair of queues for storing every task vs those completed. These
    # are only used to for the stopping condition.
    my $qTasksAll : shared  = Thread::Queue->new();
    my $qTasksDone : shared = Thread::Queue->new();

    $qToVisit->enqueue( $self->{catalog} );
    $qTasksAll->enqueue( $self->{catalog} );

    # Create worker threads. Each thread is given two queues, one to
    # add all new tasks two, and a second to add all complete tasks to.
    my @threads;

    foreach my $i ( 0 .. $self->{numThreads} - 1 ) {

        my $thread_sub = make_crawler_thread( $qToVisit, $qUrls, $qStartTimes,
            $qEndTimes, $qTasksAll, $qTasksDone, $self->{grepPattern} );

        my $thread = threads->create($thread_sub);
        $thread->detach();

        push( @threads, $thread );
    }

    # These methods set $self->{exports}
    if ( $params{rollingUpload} ) {
        $self->_rollingUpload(
            \%params,   $qUrls,      $qStartTimes, $qEndTimes,
            $qTasksAll, $qTasksDone, \@threads
        );
    }
    else {
        $self->_waitForCrawl(
            $qUrls,     $qStartTimes, $qEndTimes,
            $qTasksAll, $qTasksDone,  \@threads
        );
    }

    print "\n";
    print "#####################\n";
    print "#   Crawl Results   #\n";
    print "#####################\n";
    print Dumper( $self->{exports} );
    print "#####################\n";
    print "\n";

    # Reset old flush setting.
    $| = $oldFlushSetting;

    return scalar( @{ $self->{exports} } );
}

# Upload the exports of the crawl as they come in. Empties
# exports every ROLLING_UPLOAD_CHECK_INTERVAL seconds.
sub _rollingUpload {
    my ( $self, $params, $qUrls, $qStartTimes, $qEndTimes, $qTasksAll,
        $qTasksDone, $threads )
        = @_;

    my @allExports;
    my $crawlComplete  = 0;
    my $uploadsPending = 0;

    until ( $crawlComplete && !$uploadsPending ) {
        if ( $qTasksAll->pending() == $qTasksDone->pending() ) {
            $crawlComplete = 1;
        }
        if ( any { $_->error } @$threads ) {
            print "FATAL ERROR: thread exited abnormally\n";
            last;
        }

        ####################################################
        # Remove everything from output queue and create
        # a solr doc
        my ( @urls, @startTimes, @endTimes );

        while ( my $url = $qUrls->dequeue_nb() ) {
            push( @urls, $url );
        }

        $uploadsPending = scalar(@urls);
        next unless $uploadsPending;

        for ( 1 .. scalar(@urls) ) {
            push( @startTimes, $qStartTimes->dequeue_nb() );
            push( @endTimes,   $qEndTimes->dequeue_nb() );
        }

        my @currentExports = map {
            {   url       => $urls[$_],
                startTime => $startTimes[$_],
                endTime   => $endTimes[$_]
            }
        } ( 0 .. scalar(@urls) - 1 );

        push( @allExports, @currentExports );
        my $solrDoc = $self->createSolrDoc( \@currentExports );

        ####################################################
        # Upload this solr doc to a solr instance
        my $solrApiPrefix  = $params->{solrApiPrefix};
        my $solrCollection = $params->{solrCollection};
        my $solrApiUrl     = "$solrApiPrefix/$solrCollection/update";

        my $fh = File::Temp->new();
        print $fh $solrDoc;
        $fh->flush();

        my $filename = $fh->filename;
        print colored ['green'], "Uploading to Solr\n";
        `curl '$solrApiUrl' --data-binary \@$filename -H 'Content-type:text/xml; charset=utf-8' 2> /dev/null`;
        `curl '$solrApiUrl' --data-binary '<commit/>' -H 'Content-type:text/xml; charset=utf-8' 2> /dev/null`;

        unlink($filename);

        ####################################################
        # Wait for a period to allow the next batch to arrive
        sleep(ROLLING_UPLOAD_INTERVAL);
    }

    $self->{exports} = \@allExports;
}

# Wait for crawling to complete, or a fatal error to occur.
sub _waitForCrawl {
    my ( $self, $qUrls, $qStartTimes, $qEndTimes, $qTasksAll, $qTasksDone,
        $threads )
        = @_;

    # Block until the length of the queue containing all done tasks
    # equals the length of the queue containing all tasks.
    while ( $qTasksAll->pending() != $qTasksDone->pending() ) {
        sleep(CRAWL_COMPLETE_CHECK_INTERVAL);

        if ( any { $_->error } @$threads ) {
            print "FATAL ERROR: thread exited abnormally\n";
            last;
        }
    }

    # Zip the output queues into a single array, and store in $self
    my @exports = ();

    while ( $qUrls->pending() ) {
        push(
            @exports,
            {   url       => $qUrls->dequeue(),
                startTime => $qStartTimes->dequeue(),
                endTime   => $qEndTimes->dequeue(),
            }
        );
    }

    $self->{exports} = \@exports;
}

sub createSolrDoc {

    # $exportsToUse is optional, if not provided it will take
    # the exports from $self->{exports]. This was done to
    # allow this method to be used incrementally as exports
    # are rolling in

    my ( $self, $exportsToUse ) = @_;

    $exportsToUse = $self->{exports} unless defined $exportsToUse;

    my $xmlDoc = XML::LibXML::Document->new( "1.0", "utf-8" );

    my $root = $xmlDoc->createElement("update");
    $xmlDoc->setDocumentElement($root);

    my $add = $xmlDoc->createElement("add");
    $add->setAttribute( update => "true" );
    $root->appendChild($add);

    for my $export (@$exportsToUse) {
        my %fields = (
            datasetID => $self->{datasetID},
            url       => $export->{url},
            startTime => $export->{startTime},
            endTime   => $export->{endTime},
        );

        my $doc = $xmlDoc->createElement("doc");

        while ( my ( $key, $value ) = each(%fields) ) {
            my $field = $xmlDoc->createElement("field");
            $field->setAttribute( name => $key );
            $field->appendTextNode($value);
            $doc->appendChild($field);
        }

        $add->appendChild($doc);
    }

    return $xmlDoc->toString(1);
}

sub make_crawler_thread {
    my ($qToVisit,  $qUrls,      $qStartTimes, $qEndTimes,
        $qTasksAll, $qTasksDone, $grepPattern
    ) = @_;

    return sub {
        while (1) {
            my $url = $qToVisit->dequeue();

            my ( $ra_children, $ra_exports ) = visit( $url, $grepPattern );

            for my $childUrl (@$ra_children) {
                $qToVisit->enqueue($childUrl);
                $qTasksAll->enqueue($childUrl);
            }

            for my $export (@$ra_exports) {
                $qUrls->enqueue( $export->[0] );
                $qStartTimes->enqueue( $export->[1] );
                $qEndTimes->enqueue( $export->[2] );
            }

            $qTasksDone->enqueue($url);
        }
    };
}

# visit a node in the OPeNDAP tree
#
# args:
#   - url         :: the URL of the node to visit
#   - grepPattern :: only visit nodes matching this regexp (undef
#                    to mute this feature).
# returns two array refs:
#   - children :: to be added to the queue of nodes to visit
#   - exports  :: to be added to the list of exports
sub visit {
    my ( $url, $grepPattern ) = @_;
    my @ret;

    print "Visiting $url\n";

    if ( $url =~ /catalog\.xml$/ ) {
        @ret = visit_directory($url);
    }
    elsif (( defined $grepPattern && $url =~ m/$grepPattern/ )
        || ( !defined $grepPattern ) )
    {
        @ret = visit_file($url);
    }

    return @ret;
}

# see documentation for &visit()
sub visit_directory {
    my ($url) = @_;

    # Perform the HTTP request, and return empty upon failure.
    my $ua = LWP::UserAgent->new();
    my $respContent;

    # LWP::UserAgent will set $@ if it fails, which is not what we
    # want. Therefore, we wrap it in an eval.
    eval {
        my $resp = $ua->get($url);

        if ( !$resp->is_success() ) {
            my $statusCode = $resp->code();
            print "HTTP Failure (code $statusCode) from $url\n";
        }
        else {
            $respContent = $resp->content();
        }
    };

    return ( [], [] ) unless defined $respContent;

    #
    my @children;
    my $doc = XML::LibXML->load_xml( string => $respContent );
    my $query;

    $query = ".//thredds:catalogRef";
    foreach my $node ( $doc->findnodes($query) ) {
        my $href = $node->getAttribute("xlink:href");
        my $childUrl = opendap_url_join( $url, $href );
        push( @children, $childUrl );
    }

    $query = ".//thredds:access[\@serviceName='dap']";
    foreach my $node ( $doc->findnodes($query) ) {
        my $urlPath = $node->getAttribute("urlPath");
        my $childUrl = opendap_url_join( $url, $urlPath );
        push( @children, $childUrl );
    }

    @children = sort(@children);

    return ( \@children, [] );
}

# see documentation for &visit()
sub visit_file {
    my ($url) = @_;

    # Determine the start and end time associated with this granule.
    # Each item in a sequence of options are tried until one is
    # successful. They are
    # 1. read the associated ddx file
    # 2. parse the URL of the granule looking for common patterns

    # read associated ddx file
    my @ddxRes = get_time_range_ddx($url);

    if ( scalar @ddxRes == 2 ) {
        my ( $startTime, $endTime ) = @ddxRes;
        my $export = [ $url, $startTime, $endTime ];
        return ( [], [$export] );
    }

    # parse the URL of the granule looking for common patterns
    my @parseRes = Giovanni::Util::getTimeRangeFromFileName( $url, 0 );

    if ( scalar @parseRes == 2 ) {
        my ( $startTime, $endTime ) = @parseRes;
        my $export = [ $url, $startTime, $endTime ];
        return ( [], [$export] );
    }

    # failure
    print "Could not determine time range for URL $url\n";

    return ( [], [] );
}

# Read the start time and end time of a granule from the ddx file
# returns ($startTime, $endTime) if successful, otherwise ();
sub get_time_range_ddx {
    my ($url) = @_;

    my $ddxUrl = "$url.ddx";
    my $ua     = LWP::UserAgent->new();
    my $resp;

    # LWP::UserAgent will set $@ if it fails, which is not what we
    # want. Therefore, we wrap it in an eval.
    eval {
        $resp = $ua->get($ddxUrl);

        if ( !$resp->is_success() ) {
            my $statusCode = $resp->code();
            print "HTTP Failure (code $statusCode) from $url\n";
            return ();
        }
        elsif ( !$resp->content() ) {
            print "Empty response from $url\n";
            return ();
        }
    };

    my $respContent = $resp->content();
    my ( $startTime, $endTime );
    my ( $doc, $query, $attribNodes );
    $doc = XML::LibXML->load_xml( string => $respContent );

    $query       = '//*[@name="time_coverage_start"]';
    $attribNodes = $doc->find($query);
    if ( $attribNodes->size > 0 ) {
        $startTime = $attribNodes->shift->textContent;
        $startTime =~ s/[\n\t ]//g;
    }

    $query       = '//*[@name="time_coverage_end"]';
    $attribNodes = $doc->find($query);
    if ( $attribNodes->size > 0 ) {
        $endTime = $attribNodes->shift->textContent;
        $endTime =~ s/[\n\t ]//g;
    }

    if ( defined $startTime && defined $endTime ) {
        return ( $startTime, $endTime );
    }
    else {
        return ();
    }
}

# The catalog files in OPeNDAP reference their contents through
# an href="..." scheme. However, there are caveats in the way
# they are referenced and a custom URL join function is required.
sub opendap_url_join {
    my ( $base, $href ) = @_;

    my $baseParsed = new URI::URL($base);
    my $ret;

    # Relative to root
    if ( $href =~ /^\// ) {

        # The caveat here is that the URL is relative to the root
        # OPeNDAP directory (usually /opendap/ or /thredds/), not
        # to the domain.
        my $format;

        if ( $baseParsed->path =~ /^\/opendap\// ) {
            $format = "%s://%s/opendap%s";
        }
        elsif ( $baseParsed->path =~ /^\/thredds\// ) {
            $format = "%s//%s/thredds%s";
        }
        else {

            # We were unable to detect a common root directory,
            # assume opendap directory is root of domain.
            $format = '%s://%s%s';
        }

        $ret = sprintf( $format, $baseParsed->scheme, $baseParsed->host,
            $href );
    }

    # Relative to directory of base URL
    else {
        my $baseDir = dirname( $baseParsed->path );
        $baseDir =~ s/^\///g;

        $ret = sprintf( "%s://%s/%s/%s",
            $baseParsed->scheme, $baseParsed->host, $baseDir, $href );
    }

    return $ret;
}

1;
__END__

=head1 NAME

OPeNDAP::Crawler - Perl module for crawling an OPeNDAP Server.

=head1 SYNOPSIS

  use OPeNDAP::Crawler;

  my $crawler = OPeNDAP::Crawler->new(
    datasetID   => ...,
    catalog     => ...,
    grepPattern => ...,
    numThreads  => ...,
  );

  $crawler->crawl();

  my $updateXml = $crawler->createSolrDoc();

=head1 DESCRIPTION

OPeNDAP::Crawler crawls an OPeNDAP Server and collects a list of granules.
Associated with each granule is a start time and an end time. Functionality
for exporting this list of granules into various formats is also supported.

=head1 CONSTRUCTOR

=over 4

=item new(datasetID => ..., catalog => ..., grepPattern => ..., numThreads => ...)

=over 4

=item datasetID

This ID is attached to the collected granules When creating a export
document. It is not used during crawling.

=item catalog

This is the URL of the catalog.xml file on the OPeNDAP server from
which to start the search. This need not be the top-level catalog
of the server.

=item grepPattern

Optional. A string containing a regular expression to require collected granules to match.

=item numThreads

Optional. Threading is used to accelerate the speed of crawling. This
parameter allows you to set the number of threads to use. Default is 10.

=back

=back

=head1 METHODS

=over 4

=item crawl()

Performs the crawling; a full traversal of the OPeNDAP tree starting from the
provided catalog. Discovered granules are stored internally. Datasets that
fail to be requested are skipped, and do not trigger onError();

Options:
  rollingUpload => 1      Upload to SOLR as results come in. Additional 
                           parameters solrApiPrefix and solrCollection
                           must be specified.

Returns the number of granules discovered.

=item createSolrDoc() 

Returns a string containing a generated XML document to use for uploading
the discovered granules to Solr, using the /<coreName>/update endpoint.

=item onError

Returns a value if an error occurred some time during the lifetime of this
object.

=item rrorMessage

if onError() has a value, returns a message describing the error.

=back

=head1 EXPORT

None by default.

=head1 AUTHOR

Daniel da Silva, E<lt>Daniel.e.daSilva@nasa.govE<gt>

=cut

