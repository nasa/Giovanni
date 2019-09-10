#!/usr/bin/perl 

################################################################################
# $Id: PODAAC.pm,v 1.9 2014/12/10 04:25:36 mhegde Exp $
################################################################################

package ESIP::ResponseParser::PODAAC;

use strict;
use URI;
use Safe;
use XML::LibXML;
use XML::LibXSLT;
use URI::Escape;
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
our $linkNS = '';

sub new {
    my ( $class, %arg ) = @_;
    my $self = \%arg;

  # calling class is doing this now: $self->{doc} = getDocument($self->{XML});
  # but ESIP::Response is sending me a document not a root element.
    my $document = $self->{XML};
    die "No XML OpenSearch Response given to this Parser!" if !$document;

    $self->{doc} = $document->documentElement();
    $self->{TYPE} = "application/x-none" if !$self->{TYPE};

    $self->{author}
        = ESIP::ResponseParser::EsipParser::getAuthor( $self->{doc} );

    # $dataAttr determines what to look for in the value of the 'rel'
    # attribute of the 'link' elements.
    # For ESIP discovery 1.2 and later, look for rel='enclosure'.
    # For earlier versions of ESIP discovery, look for rel='ns:data#'.
    # If $granule_identifier_type matches 'enclosure', look
    # for rel='enclosure'.
    # Hack for non-compliant LAADS OpenSearch response, which is missing
    # the '#' at the end of the 'rel' attribute

    bless( $self, $class );
    return $self;
}

sub getOPeNDAPUrls {
    my $self = shift;
    $self->{use_opendap} = 1;
    $self->{dataAttr}    = "OPeNDAP URL";

    #my ($titles,$urls) = extractGranulesFromDoc($self, "opendap", );
    my ( $titles, $urls )
        = extractGranulesByTime( $self, "opendap", );    #new alg
    my @dataUrlList = ();
    for ( my $i = 0; $i < @$urls; $i++ ) {
        push( @dataUrlList, { title => $titles->[$i], url => $urls->[$i] } );
    }
    return \@dataUrlList;
}

sub getDataUrls {
    my $self = shift;
    $self->{dataAttr} = "FTP URL";

    #my ($titles,$urls) = extractGranulesFromDoc($self, "url");
    my ( $titles, $urls ) = extractGranulesByTime( $self, "url" );   # new alg
    my @dataUrlList = ();
    for ( my $i = 0; $i < @$urls; $i++ ) {
        push( @dataUrlList, { title => $titles->[$i], url => $urls->[$i] } );
    }
    return \@dataUrlList;
}

sub extractGranulesByTime {
    my ( $self, $granule_identifier_type ) = @_;
    my $doc = $self->{doc};
    my @hrefs;
    my @titles;
    my %hash;

    foreach my $entry ( $doc->getChildrenByTagNameNS( $atomNS, 'entry' ) ) {
        my $hrefCount = 0;
        my $time
            = ESIP::ResponseParser::EsipParser::getTime( $entry, 'start' );
        ESIP::ResponseParser::EsipParser::getTitle( $entry,
            \@{ $hash{$time}{title} } );
        foreach
            my $linkNode ( $entry->getChildrenByTagNameNS( $atomNS, 'link' ) )
        {

            # Skip any 'link' elements that do not have an 'href'
            # attribute. This should be done first
            my $href = $linkNode->getAttribute('href');
            next unless $href;

            my $relAttr   = $linkNode->getAttribute('rel');
            my $titleAttr = $linkNode->getAttribute('title');
            my $roleAttr  = $linkNode->getAttribute('role');
            next unless ( $titleAttr eq $self->{dataAttr} );

            if ( $self->{use_opendap} ) {    # HERE only getOpendapUrl
                                             # If we want only OPeNDAP URLs,
                                             # this means in V1.2 that
                 # skip any links that do not contain the string 'opendap' or 'thredds'
                 # this will avoid the links without roles that have opendap in their paths because they are just netcdf files
                 # Remove any trailing .html from OPeNDAP URLs
                 # V1.2 has role attr but V1.0 doesn't
                if ( $self->{dataAttr} eq 'enclosure' )
                {   # LAST that is v1.2, 1.0 doesn't have a role in this case.
                    next unless ( $roleAttr && ( $roleAttr =~ /opendap/i ) );
                }
                $href =~ s/\.html$//;
            }
            else {    # HERE only getDataURL
                      # Unless we want only OPeNDAP URLs,
                      # skip any links that contain the string 'opendap'
                next
                    if ( ( $href =~ /opendap/i ) || ( $href =~ /thredds/i ) );
            }

            # print STDERR $linkNode->toString(),"\n";
            $href =~ s/ /\%20/g;
            push @{ $hash{$time}{hrefs} }, $href;
            $hrefCount += 1;
        }    # each Link

    }    # each Entry

    # sort alphabetically return the last.
    foreach my $key ( keys %hash ) {
        my ( $hrf, $title )
            = ESIP::ResponseParser::EsipParser::getFirstAlphaSortedUrlTitlePair(
            $hash{$key}{hrefs},
            $hash{$key}{title} );
        if ( defined $hrf ) {
            push @hrefs,  $hrf;
            push @titles, $title;
        }
    }

    return \@titles, \@hrefs;
}

sub extractGranulesFromDoc {
    my ( $self, $granule_identifier_type ) = @_;
    my $doc = $self->{doc};
    my @hrefs;
    my @titles;

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

                my $relAttr   = $linkNode->getAttribute('rel');
                my $titleAttr = $linkNode->getAttribute('title');
                my $roleAttr  = $linkNode->getAttribute('role');
                next unless ( $titleAttr eq $self->{dataAttr} );

                if ( $self->{use_opendap} ) {    # HERE only getOpendapUrl
                        # If we want only OPeNDAP URLs,
                        # this means in V1.2 that
                     # skip any links that do not contain the string 'opendap' or 'thredds'
                     # this will avoid the links without roles that have opendap in their paths because they are just netcdf files
                     # Remove any trailing .html from OPeNDAP URLs
                     # V1.2 has role attr but V1.0 doesn't
                    if ( $self->{dataAttr} eq 'enclosure' )
                    { # LAST that is v1.2, 1.0 doesn't have a role in this case.
                        next
                            unless ( $roleAttr
                            && ( $roleAttr =~ /opendap/i ) );
                    }
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
    }

    return \@titles, \@hrefs;
}
1;
__END__

=head1 NAME

ESIP::ResponseParser::PODAAC - Perl extension for parsing an OpenSearch response from PODAAC 

=head1 SYNOPSIS

  use ESIP::ResponseParser::EsipParser;

  ...

  # Create a LibXML dom of the PODAAC OpenSearch response and send it to constructor
  my $package  = ESIP::ResponseParser::PODAAC->new(XML => $dom );

  # fish out data urls and labels(filenames) into arrayRefs
  my ($titles, $urls) = $package->getDataUrls();

  # fish out opendap urls and labels(filenames) into arrayRefs
  my ($titles, $urls) = $package->getOPeNDAPUrls();



=head1 DESCRIPTION

=head2 my $package  = ESIP::ResponseParser::PODAAC->new(XML => $dom );

Create a LibXML dom of the PODAAC OpenSearch response and send it to constructor

=head2  my ($titles, $urls) = $package->getDataUrls(); 

parse out data urls and labels(filenames) into arrayRefs

=head2  my ($titles, $urls) = $package->getOPeNDAPUrls(); 

parse out opendap urls and labels(filenames) into arrayRefs

=head2  extractGranulesFromDoc(); 

ORIGINAL

=head2  extractGranulesByTime(); 

Replacement for extractGranulesFromDoc().
This puts the dataurls or the opendapurls into an array for each unique time:start. It then sorts each array alphabettically and returns the last one.  The corresponding titles are handled during all of this. Additional subroutines were given to sort by title instead or return the first instead of the last. 


=head1 AUTHOR

Richard Strub 


=cut

