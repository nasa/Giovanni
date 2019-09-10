#!/usr/bin/perl 

################################################################################
# $Id: EsipParser.pm,v 1.7 2014/12/10 04:25:36 mhegde Exp $
################################################################################

package ESIP::ResponseParser::EsipParser;

use strict;
use URI;
use XML::LibXML;
use XML::LibXSLT;
use URI::Escape;
use POSIX;

our $VERSION = '1.0';
$| = 1;

# THIS ONE IS CRITICAL:
# If its there we do 1.2 if not we do 1.0

our $atomNS = 'http://www.w3.org/2005/Atom';
our $osNS   = 'http://a9.com/-/spec/opensearch/1.1/';
our $timeNS = "http://a9.com/-/opensearch/extensions/time/1.0/";
our $linkNS = '';
my $DAACROOT = '';

sub getDocument {
    my $string = shift;
    my $dsDom;
    my $parser = XML::LibXML->new();
    eval { $dsDom = $parser->parse_string($string); };
    if ($@) {
        ERROR( ( caller(0) )[3], " $@" );
    }
    my $dsDoc = $dsDom->documentElement();

    return $dsDoc;
}

sub getAuthor {
    my $doc = shift;

    my ($authorNode) = $doc->getChildrenByTagNameNS( $atomNS, 'author' );
    my ($authorNameNode)
        = $authorNode->getChildrenByTagNameNS( $atomNS, 'name' )
        if $authorNode;
    my $author = $authorNameNode->textContent if $authorNameNode;
    $author =~ s/\n//g;
    $author =~ s/\s*$//g;
    $author =~ s/^\s*//g;
    return $author;
}

sub getTime {
    my $doc       = shift;
    my $whichTime = shift;
    my $time      = undef;

    my $timeNode = $doc->getChildrenByTagNameNS( $timeNS, $whichTime );
    if ($timeNode) {
        $time = $timeNode->[0]->textContent();
        $time =~ s/\n//g;
        $time =~ s/\s*$//g;
        $time =~ s/^\s*//g;
    }
    return $time;
}

sub getTitle {
    my $entry  = shift;
    my $titles = shift;
    my $idNode;

    my ($titleNode) = $entry->getChildrenByTagNameNS( $atomNS, 'title' );
    if ($titleNode) {
        my $id = $titleNode->textContent;
        $id =~ s/\n//g;
        $id =~ s/\s*$//g;
        $id =~ s/^\s*//g;
        push @$titles, $id;
    }
    elsif ( ($idNode) = $entry->getChildrenByTagNameNS( $atomNS, 'id' ) ) {
        my $id = $idNode->textContent if $idNode;
        $id =~ s/\n//g;
        $id =~ s/\s*$//g;
        $id =~ s/^\s*//g;
        push @$titles, $id;
    }
    else {
        die "Could not find title in <title> tag or <id> tag";
    }
}

sub getLastAlphaSortedUrlTitlePair {
    my $urls   = shift;
    my $titles = shift;
    my @both;
    for ( my $i = 0; $i <= $#$urls; ++$i ) {
        $both[$i] = $urls->[$i] . "^^" . $titles->[$i];
    }
    my @sorted = sort @both;
    my $both   = pop @sorted;
    my ( $url, $title ) = split( /\^\^/, $both );

    return ( $url, $title );
}

sub getLastAlphaSortedUrlTitlePair_ByTitle {
    my $urls   = shift;
    my $titles = shift;
    my @both;
    for ( my $i = 0; $i <= $#$urls; ++$i ) {
        $both[$i] = $titles->[$i] . "^^" . $urls->[$i];
    }
    my @sorted = sort @both;
    my $both   = pop @sorted;
    my ( $title, $url ) = split( /\^\^/, $both );

    return ( $url, $title );
}

sub getFirstAlphaSortedUrlTitlePair {
    my $urls   = shift;
    my $titles = shift;
    my @both;
    for ( my $i = 0; $i <= $#$urls; ++$i ) {
        $both[$i] = $urls->[$i] . "^^" . $titles->[$i];
    }
    my @sorted = sort @both;
    my $both   = shift @sorted;
    my ( $url, $title ) = split( /\^\^/, $both );

    return ( $url, $title );
}

sub checkTypes {
    my $type = shift;
    if ($type
        && ( #  $type eq "application/x-netcdf" || 
             #  $type eq "text/html"
               $type eq "application/x-hdf"
            || $type eq "application/x-hdfeos"
            || $type eq "application/x-hdfeos5"

        )
        )
    {
        return 1;
    }
    else {
        return undef;
    }
}

sub getFirstAlphaSortedUrlTitlePair_ByTitle {
    my $urls   = shift;
    my $titles = shift;
    my @both;
    for ( my $i = 0; $i <= $#$urls; ++$i ) {
        $both[$i] = $titles->[$i] . "^^" . $urls->[$i];
    }
    my @sorted = sort @both;
    my $both   = shift @sorted;
    my ( $title, $url ) = split( /\^\^/, $both );

    return ( $url, $title );
}
1;

=head1 NAME

	ESIP::ResponseParser::EsipParser - Not a class. Just contains subroutines common to ESIP::Response::ResponseParser modules


=head1 SYNOPSIS

	ESIP::ResponseParser::EsipParser - Put subroutines common to ESIP::Response::ResponseParser in here

=head2 getTitle() extracts the contents of the <title> tag from OpenSearch response. This is common to V1.0 v1.2 and PODAAC so far
 
=head2 getAuthor() extracts the contents of the <author> tag from OpenSearch response. 

=head1 MAINLY FOR PODAAC 

=head2		my $title = getTitle(entryNode) 

gets the title for each entry node

=head2 getLastAlphaSortedUrlTitlePair($urlsRefForEachTime,$correspondingTitles) 

returns the last url,title pair for each time (ORIGINAL)

=head2 getLastAlphaSortedUrlTitlePair_ByTitle($u,$t)  

in case we want to sort by title 

=head2 getFirstAlphaSortedUrlTitlePair($u,$t)         

in case we want the first one instead of the last

=head2 getFirstAlphaSortedUrlTitlePair_ByTitle($u,$t) 

in case we want the first one instead of the last by title

=head2 checkTypes(typeAttr) 

This is needed to distinguish between PODAAC and V1_2.  If application/x-netcdf is allowed, the code that tries each type in succession V1_0,V1_2,PODAAC  will think that PODAAC is V1_2

=head1 DESCRIPTION

So far the 3 parser modules only contain:

sub new 

sub getOPeNDAPUrls 

sub getDataUrls 

sub extractGranulesFromDoc 

sub extractGranulesByTime - replacement for extractGranulesFromDoc for PODAAC - this pulls last-by-alpha-sorted url for each time:start

ESIP::Response takes care of storing the extracted urls and titles and making them unique in case duplicates were found.

=head1 AUTHOR

Richard Strub

=cut

