#!/usr/bin/perl 

################################################################################
# $Id: V1_0.pm,v 1.9 2014/12/15 22:22:18 csmit Exp $
################################################################################

package ESIP::ResponseParser::V1_0;

use strict;
use URI;
use XML::LibXML;
use URI::Escape;
use ESIP::ResponseParser::EsipParser;
use POSIX;

our $VERSION = '1.0';
$| = 1;

# THIS ONE IS CRITICAL:
# If its there we do 1.2 if not we do 1.0
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

    $self->{author}
        = ESIP::ResponseParser::EsipParser::getAuthor( $self->{doc} );

    # $dataAttr determines what to look for in the value of the 'rel'
    # attribute of the 'link' elements.
    # For ESIP discovery 1.2 and later, look for rel='enclosure'.
    # For earlier versions of ESIP discovery, look for rel='ns:data#'.
    # If $granule_identifier_type matches 'enclosure', look
    # for rel='enclosure'.
    $self->{dataAttr}    = "${esipNS}data#";       # HERE 1.0 vs 1.2
    $self->{opendapAttr} = "${esipNS}opendap#";    # HERE 1.0 vs 1.2
         # Hack for non-compliant LAADS OpenSearch response, which is missing
         # the '#' at the end of the 'rel' attribute
    $self->{dataAttrLAADS} = "${esipNS}data";

    bless( $self, $class );
    return $self;
}

sub getOPeNDAPUrls {
    my $self = shift;
    $self->{use_opendap} = 1;
    $self->{TYPE} = "application/opendap" if !$self->{TYPE};
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
                if ( $self->{use_opendap} ) {
                    next unless ( $relAttr eq $self->{opendapAttr} );
                }
                else {
                    next
                        unless ( ( $relAttr eq $self->{dataAttr} )
                        || ( $relAttr eq $self->{dataAttrLAADS} ) );
                }

                my $typeAttr = $linkNode->getAttribute('type');

                my $roleAttr = $linkNode->getAttributeNS( $linkNS, 'role' );

                unless ( $self->{use_opendap} ) {    # HERE only getDataURL
                        # Unless we want only OPeNDAP URLs,
                        # skip any links that have an OPeNDAP role attribute
                        # so this means that links with no role attr will be
                        # thought of as OPeNDAP URLs
                    next if $roleAttr && $roleAttr =~ /opendap/i;
                }

                if ( $self->{use_opendap} ) {    # HERE only getOpendapUrl
                        # If we want only OPeNDAP URLs,
                        # this means in V1.2 that
                     # skip any links that do not contain the string 'opendap' or 'thredds'
                    $href =~ s/\.html$//;
                }
                else {    # HERE only getDataURL
                          # Unless we want only OPeNDAP URLs,
                          # skip any links that contain the string 'opendap'
                    next
                        if ( ( $href =~ /opendap/i )
                        || ( $href =~ /thredds/i ) );
                }

                # print STDERR $linkNode->toString(),"\n";
                $href =~ s/ /\%20/g;
                push @hrefs, $href;
                $hrefCount += 1;
            }
        }

        ESIP::ResponseParser::EsipParser::getTitle( $entry, \@titles );

        # Extract time
        my ( $tStart, $tEnd ) = ( undef, undef );
        foreach my $nameSpace (@dcNS) {
            my ($timeNode)
                = $entry->getChildrenByTagNameNS( $nameSpace, "date" );
            if ( defined $timeNode ) {
                ( $tStart, $tEnd ) = split( qr#/#, $timeNode->textContent() );

                # Allow zero-width date/time intervals.
                $tEnd = $tStart unless defined $tEnd;
            }
        }
        push( @startTime, $tStart );
        push( @endTime,   $tEnd );
    }

    return \@titles, \@hrefs, \@startTime, \@endTime;
}
1;
__END__

=head1 NAME

ESIP::ResponseParser::V1_0 - Perl extension for parsing an OpenSearch
response from dataproviders following esipdiscovery v1.0

=head1 SYNOPSIS

 use ESIP::ResponseParser::EsipParser;

 ...

 # Create a LibXML dom of the V1_0 OpenSearch response and
 # send it to constructor
 my $package = ESIP::ResponseParser::V1_0->new(XML => $dom );

 # Parse out data urls and labels (filenames) into arrayRefs
 my ($titles, $urls) = $package->getDataUrls();

 # Parse out opendap urls and labels (filenames) into arrayRefs
 my ($titles, $urls) = $package->getOPeNDAPUrls();

=head1 DESCRIPTION

=head2 my $package = ESIP::ResponseParser::V1_0->new(XML => $dom );

Create a LibXML dom of the V1_0 OpenSearch response and send it to constructor

=head2 my ($titles, $urls) = $package->getDataUrls();

Parse out data urls and labels (filenames) into arrayRefs

=head2 my ($titles, $urls) = $package->getOPeNDAPUrls();

Parse out opendap urls and labels (filenames) into arrayRefs

=head1 AUTHOR

Richard Strub
=cut

