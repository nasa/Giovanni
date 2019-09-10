#!/usr/bin/perl 

################################################################################
# $Id: V1_2.pm,v 1.14 2014/12/15 22:22:22 csmit Exp $
################################################################################

package ESIP::ResponseParser::V1_2;

use strict;
use URI::URL;
use XML::LibXML;
use URI::Escape;
use File::Basename;
use ESIP::ResponseParser::EsipParser;
use POSIX;

our $VERSION = '1.0';
$| = 1;

# THIS ONE IS CRITICAL:
# If its there we do 1.2 if not we do 1.0
my $esip_1_2 = 'http://esipfed.org/ns/fedsearch/1.2/';
our $esipNS = 'http://esipfed.org/ns/fedsearch/1.0/';
our $atomNS = 'http://www.w3.org/2005/Atom';
our $osNS   = 'http://a9.com/-/spec/opensearch/1.1/';
our @dcNS
    = ( 'http://purl.org/dc/elements/1.1/', 'http://purl.org/dc/terms/' );
our $linkNS = '';

sub new {
    my ( $class, %arg ) = @_;
    my $self = \%arg;

  # calling class is doing this now: $self->{doc} = getDocument($self->{XML});
  # but ESIP::Response is sending me a document not a root element.
    my $document = $self->{XML};
    die "No XML OpenSearch Response given to this Parser!" if !$document;

    $self->{doc} = $document->documentElement();

    #$self->{TYPE} = "application/x-none" if !$self->{TYPE};
    $self->{TYPE} = "" if !$self->{TYPE};

    $self->{author}
        = ESIP::ResponseParser::EsipParser::getAuthor( $self->{doc} );

    # $dataAttr determines what to look for in the value of the 'rel'
    # attribute of the 'link' elements.
    # For ESIP discovery 1.2 and later, look for rel='enclosure'.
    # For earlier versions of ESIP discovery, look for rel='ns:data#'.
    # If $granule_identifier_type matches 'enclosure', look
    # for rel='enclosure'.
    $self->{dataAttr}

# Moving from enclosure to describedBy means we are moving from GESDISC opendsearch
# to best practices /CMR opensearch. GESDISC still works with this if we use
# the regex, otherwise it returns too many opendap urls like .ddx, .info
        = $esip_1_2 ? 'enclosure' : "${esipNS}data#";    # HERE 1.0 vs 1.2
          # Hack for non-compliant LAADS OpenSearch response, which is missing
          # the '#' at the end of the 'rel' attribute
    $self->{dataAttrLAADS} = $esip_1_2 ? 'enclosure' : "${esipNS}data";

    bless( $self, $class );
    return $self;
}

sub getOPeNDAPUrls {
    my $self = shift;
    $self->{use_opendap} = 1;
    my ( $titles, $urls, $tStart, $tEnd )
        = extractGranulesFromDoc( $self, "opendap", );
    my @dataUrlList = ();
    for ( my $i = 0; $i < @$urls; $i++ ) {
        push(
            @dataUrlList,
            {   title     => $titles->[$i],
                url       => $urls->[$i],
                startTime => $tStart->[$i],
                endTime   => $tEnd->[$i]
            }
        );
    }
    return \@dataUrlList;
}

sub getDataUrls {
    my $self = shift;
    my ( $titles, $urls, $tStart, $tEnd )
        = extractGranulesFromDoc( $self, "url" );
    my @dataUrlList = ();
    for ( my $i = 0; $i < @$urls; $i++ ) {
        push(
            @dataUrlList,
            {   title     => $titles->[$i],
                url       => $urls->[$i],
                startTime => $tStart->[$i],
                endTime   => $tEnd->[$i]
            }
        );
    }
    return \@dataUrlList;
}

sub extractGranulesFromDoc {
    my ( $self, $granule_identifier_type ) = @_;
    my $doc = $self->{doc};
    my @hrefs;
    my @titles;
    my @startTime = ();
    my @endTime   = ();

    foreach my $entry ( $doc->getChildrenByTagNameNS( $atomNS, 'entry' ) ) {
        my $hrefCount = 0;
        if ( $granule_identifier_type ne 'id' ) {
            foreach my $linkNode (
                $entry->getChildrenByTagNameNS( $atomNS, 'link' ) )
            {

                # Skip any 'link' elements that do not have an 'href'
                # attribute. This should be done first
                my $href = $linkNode->getAttribute('href');
                next unless $href;

                if ( $self->{author} && $self->{author} =~ /GES *DISC/i )
                {    # lets see if we really need this
                        # Skip any GES DISC links that utilize HTTP Services
                    next if $href =~ /HTTP_services/;
                }

                my $relAttr = $linkNode->getAttribute('rel');
                if ( !$self->{use_opendap} ) {
                    next    # Here is the rel="enclosure" requirement
                        unless ( ( $relAttr eq $self->{dataAttr} )
                        || ( $relAttr eq $self->{dataAttrLAADS} ) );
                    my $url      = URI->new($href);
                    my $filename = basename $url->path;
                    my ( $name, $path, $suffix )
                        = fileparse( $filename, '\.[^\.]*' );
                }

                my $typeAttr = $linkNode->getAttribute('type');

                # We are now writing code that can deal with no types at all.
                if ($typeAttr) {
                    next
                        unless ESIP::ResponseParser::EsipParser::checkTypes(
                        $typeAttr);
                }

                my $roleAttr = $linkNode->getAttributeNS( $linkNS, 'role' );

                unless ( $self->{use_opendap} ) {    # HERE only getDataURL
                    # Unless we want only OPeNDAP URLs,
                    # skip any links that have an OPeNDAP role attribute
                    # so this means that links with no role attr will be
                    # thought of as OPeNDAP URLs
                    # CMR has no roles...often... next if $roleAttr && $roleAttr =~ /opendap/i;
                }

                if ( $self->{use_opendap} ) {    # HERE only getOpendapUrl
                    # If we want only OPeNDAP URLs,
                    # this means in V1.2 that
                    # skip any links that do not contain the string 'opendap' or 'thredds'
                    # this will avoid the links without roles that have opendap
                    # in their paths because they are just netcdf files
                    # Remove any trailing .html from OPeNDAP URLs
                    # V1.2 has role attr but V1.0 doesn't
                    next
                        unless isLikeASampleFile( $href,
                                $self->{searchFilter} );
                    next
                        unless ( ( $href =~ /opendap/i )
                        || ( $href =~ /thredds/i ) );

                    if ( $self->{dataAttr} eq 'enclosure' )
                    { # LAST that is v1.2, 1.0 doesn't have a role in this case.
                         # next unless ( $roleAttr && ( $roleAttr =~ /opendap/i ) );
                    }
                    $href =~ s/\.html$//;
                }
                else {    # HERE only getDataURL
                          # Unless we want only OPeNDAP URLs,
                          # skip any links that contain the string 'opendap'
                    next
                        unless isLikeASampleFile( $href,
                                $self->{searchFilter} );
                    next
                        if ( ( $href =~ /opendap/i )
                        || ( $href =~ /thredds/i ) );
                }

                next unless isaFile($href);
                $href =~ s/ /\%20/g;
                push @hrefs, $href;
                $hrefCount += 1;
            }
        }

        if ( $hrefCount > 0 )
        {    # We were retrieving new titles when we didn't have new files
            ESIP::ResponseParser::EsipParser::getTitle( $entry, \@titles );
            my ( $tStart, $tEnd ) = ( undef, undef );
            foreach my $nameSpace (@dcNS) {
                my ($timeNode)
                    = $entry->getChildrenByTagNameNS( $nameSpace, "date" );
                if ( defined $timeNode ) {
                    ( $tStart, $tEnd )
                        = split( qr#/#, $timeNode->textContent() );

                    # Allow zero-width date/time intervals.
                    $tEnd = $tStart unless defined $tEnd;
                }
            }
            push( @startTime, $tStart );
            push( @endTime,   $tEnd );
        }
    }

    return \@titles, \@hrefs, \@startTime, \@endTime;
}

sub isaFile {
    my $url      = shift;
    my $uri      = URI::URL->new($url);
    my $filename = basename $uri->path;
    my ( $name, $path, $suffix ) = fileparse( $uri->path, '\.[^\.]*' );
    return 1 if ($suffix);
    return undef;
}

sub isLikeASampleFile {
    my $url    = shift;
    my $sample = shift;
    return 1 if ( !$sample );    # if no regex provided ignore this capability

    my $uri        = URI::URL->new($url);
    my $uri_sample = URI::URL->new($sample);

    my $filename = basename $uri->path;
    $sample   = basename $uri_sample->path;

    # We don't want to substitute single digits
    $sample = "^" . $sample . "\$";
    if ( $filename =~ /$sample/ ) {
        return 1;
    }
    return undef;
}

1;
__END__

=head1 NAME

ESIP::ResponseParser::V1_2 - Perl extension for parsing an OpenSearch
response from dataproviders following esipdiscovery v1.2

=head1 SYNOPSIS

 use ESIP::ResponseParser::EsipParser;

 ...

 # Create a LibXML dom of the V1_2 OpenSearch response and send it to constructor
 my $package  = ESIP::ResponseParser::V1_2->new(XML => $dom );

 # Parse out data urls and labels (filenames) into arrayRefs
 my ($titles, $urls) = $package->getDataUrls();

 # Parse out opendap urls and labels(filenames) into arrayRefs
 my ($titles, $urls) = $package->getOPeNDAPUrls();



=head1 DESCRIPTION

=head2 my $package = ESIP::ResponseParser::V1_2->new(XML => $dom );

Create a LibXML dom of the V1_2 OpenSearch response and send it to constructor

=head2  my ($titles, $urls) = $package->getDataUrls();

Parse out data urls and labels (filenames) into arrayRefs

=head2  my ($titles, $urls) = $package->getOPeNDAPUrls();

Parse out opendap urls and labels (filenames) into arrayRefs

=head2 my ( $titles, $urls, $tStart, $tEnd ) = extractGranulesFromDoc( $self, "opendap", );

extractGranulesFromDoc() is used by both getOPeNDAPUrls (passes
"opendap") and getDataUrls (passes "url").  This latest version is
removing role and type dependency, using rel=describedBy and
type=text/html for OPeNDAP granules as described in the OpenSearch
Best Practices, rather than the more restrictive interpretation of the
two-step Federated OpenSearch that GESDISC creates, and which we
originally coded to. The CMR OpenSearch may very well one day return
types and roles which may enable us to revert our changes.  If you
ever want to tear these apart into extractOpendapGranulesFromDoc and
extractDataGranulesFromDoc you will find the code is 100/116 * 100
percent the same. (save only 16 lines)

=head2  boolean isaFile($href) 

Takes the url in $href, parses it, and if there is a suffix, returns true

=head2 boolean isLikeASampleFile($href, sampleDataGranule||sampleOpendapGranule)

Given arguments of a url and sampleFile, returns 1 if the sample matches any
part of the url.

=head1 AUTHOR

Richard Strub
=cut

