#$Id: Response.pm,v 1.11 2014/12/10 20:05:32 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $
package ESIP::Response;

use XML::LibXML::XPathContext;
use ESIP::ResponseParser::V1_0;
use ESIP::ResponseParser::V1_2;
use ESIP::ResponseParser::PODAAC;
use ESIP::ResponseParser::SearchFilter;
use strict;

sub new {

    # passing in sampleFile and sampleOpendap now
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;
    $self->{raw} = [];

    return $self;
}

sub getRawResponses {
    my ($self) = @_;
    return @{ $self->{raw} };
}

sub appendResponse {
    my ( $self, $response ) = @_;
    push( @{ $self->{raw} }, $response );

    # if we've parsed results before, remove them.
    delete( $self->{dataUrls} );
}

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub both_uniq {
    my $urls   = shift;
    my $titles = shift;
    my %seen;
    my @urls;
    my @titles;
    for ( my $i = 0; $i < $#$urls; ++$i ) {
        $seen{ $urls->[$i] } = $titles->[$i];
    }
    foreach my $key ( sort keys %seen ) {
        push @urls,   $key;
        push @titles, $seen{$key};
    }
    return ( \@urls, \@titles );
}

sub getDataUrls {
    my ($self) = @_;
    my $type;    # future...hdf/netcdf

    if ( exists( $self->{dataUrls} ) ) {
        return @{ $self->{dataUrls} };
    }

    my $searchResultList = [];
    my $seems2B = $self->{searchFilter} ? "SearchFilter" : "v1.0";
    foreach my $doc ( @{ $self->{raw} } ) {
        my $package;
        my $urlList = [];

        if ( $seems2B eq "SearchFilter" ) {
            $package = ESIP::ResponseParser::SearchFilter->new(
                XML          => $doc,
                searchFilter => $self->{searchFilter}
            );
            $urlList = $package->getDataUrls();
            if ( $#$urlList < 0 ) {

                # If we have a SearchFilter we don't
                # want to try any other method
                # Actually we should rarely arrive at this code
                # Most of the time it should hit getOpendapUrls()
                $seems2B = "SearchFilter";
            }
        }
        if ( $seems2B eq "v1.0" ) {
            $package = ESIP::ResponseParser::V1_0->new( XML => $doc );
            $urlList = $package->getDataUrls();
            if ( $#$urlList < 0 ) {
                $seems2B = "v1.2";
            }
        }
        if ( $seems2B eq "v1.2" ) {
            $package = ESIP::ResponseParser::V1_2->new(
                XML        => $doc,
                TYPE       => "application/x-hdf",
                sampleFile => $self->{sampleFile}
            );
            $urlList = $package->getDataUrls();
            if ( $#$urlList < 0 ) {
                $seems2B = "podaac";
            }
        }
        if ( $seems2B eq "podaac" ) {
            $package = ESIP::ResponseParser::PODAAC->new(
                XML  => $doc,
                TYPE => "application/x-hdf"
            );
            $urlList = $package->getDataUrls();
            if ( $#$urlList < 0 ) {
                last;
            }
        }
        push( @$searchResultList, @$urlList ) if @$urlList;
    }

    # Need to return unique URLs
    if (@$searchResultList) {

        # Create result list based on unique URLs
        my %flag           = ();
        my @uniqResultList = ();
        foreach my $entry (@$searchResultList) {
            push( @uniqResultList, $entry )
                unless exists $flag{ $entry->{url} };
            $flag{ $entry->{url} } = 1;
        }
        $searchResultList = \@uniqResultList;
    }

    return @$searchResultList;

    #my ($uniqurls,$uniqtitles) = both_uniq(\@urls,\@titles);
    #$self->{dataUrls} = $uniqurls;
    #$self->{titles} = $uniqtitles;
    #return @$uniqurls;
}

sub getOPeNDAPUrls {
    my ($self) = @_;
    my $titles;
    my @urls;
    my @titles;
    my $opendapUrls;
    if ( exists( $self->{opendapUrls} ) ) {   # is this the right member name?
        return @{ $self->{opendapUrls} };
    }
    my $searchResultList = [];

    # try SearchFilter first
    my $seems2B = $self->{searchFilter} ? "SearchFilter" : "v1.0";

    foreach my $doc ( @{ $self->{raw} } ) {
        my $package;
        my $urlList = [];
        if ( $seems2B eq "SearchFilter" ) {
            $package = ESIP::ResponseParser::SearchFilter->new(
                XML          => $doc,
                searchFilter => $self->{searchFilter}
            );

            # We are now using a longer searchFilter so it alone can
            # precisely describe the URLs we are looking for
            $urlList = $package->getOPeNDAPUrls();
            if ( $#$urlList < 0 ) {

                # If we have a SearchFilter we don't
                # want to try any other method
                $seems2B = "SearchFilter";
            }
        }
        if ( $seems2B eq "v1.0" ) {
            $package = ESIP::ResponseParser::V1_0->new( XML => $doc );
            $urlList = $package->getOPeNDAPUrls();
            if ( $#$urlList < 0 ) {
                $seems2B = "v1.2";
            }
        }
        if ( $seems2B eq "v1.2" ) {
            $package = ESIP::ResponseParser::V1_2->new(
                XML           => $doc,
                TYPE          => "application/x-hdf",
                sampleOpendap => $self->{sampleOpendap},
                searchFilter  => $self->{searchFilter}
            );
            $urlList = $package->getOPeNDAPUrls();
            if ( $#$urlList < 0 ) {
                $seems2B = "podaac";
            }
        }
        if ( $seems2B eq "podaac" ) {
            $package = ESIP::ResponseParser::PODAAC->new(
                XML  => $doc,
                TYPE => "application/x-hdf"
            );
            $urlList = $package->getOPeNDAPUrls();
            if ( $#$urlList < 0 ) {
                last;
            }
        }
        push( @$searchResultList, @$urlList );
    }

    #my ($uniqurls,$uniqtitles) = both_uniq(\@urls,\@titles);
    #$self->{opendapUrls} = $uniqurls;
    #$self->{titles} = $uniqtitles;
    if (@$searchResultList) {

        # Create result list based on unique URLs
        my %flag           = ();
        my @uniqResultList = ();
        foreach my $entry (@$searchResultList) {
            push( @uniqResultList, $entry )
                unless exists $flag{ $entry->{url} };
            $flag{ $entry->{url} } = 1;
        }
        $searchResultList = \@uniqResultList;
    }
    return @$searchResultList;
}

sub getUrls {
    my $self = shift;
    return $self->{dataUrls};
}

sub get_dataUrls {
    my $self = shift;
    return $self->{dataUrls};
}

sub getTitles {
    my $self = shift;
    return $self->{titles};
}

sub get_OPeNDAPUrls {
    my $self = shift;
    return $self->{opendapUrls};
}

1;

__END__

=head1 NAME

ESIP::Response - Perl extension for managing an ESIP opensearch response

=head1 SYNOPSIS

  use ESIP::ResponseParser::V1_0;
  use ESIP::ResponseParser::V1_2;
  use ESIP::ResponseParser::PODAAC;

  ...

=head1 DESCRIPTION

=head2 ($dataUrls,$titles) =  $package->getDataUrls()

An array ref of LibXML docs made from opensearch responses has been put into Response::raw.  This method tries each of the 3 methods (V1_0,V1_2,PODAAC) on the first document.  The first one that returns data urls it then uses that method to parse data urls from the rest of the array of docs (opensearch responses). It then gathers the titles and data urls and makes sure that they are unique and places them into data members dataUrls and titles. And it returns the urls.

=head2 ($dataUrls,$titles) =  $package->getOPeNDAPUrls()

An array ref of LibXML docs made from opensearch responses has been put into Response::raw.  This method tries each of the 3 methods (V1_0,V1_2,PODAAC) on the first document.  The first one that returns OPeNDAP urls it then uses that method to parse OPeNDAP urls from the rest of the array of docs (opensearch responses). It then gathers the titles and OPeNDAP urls and makes sure that they are unique and places them into data members opendapUrls and titles. And it returns the opendapUrls.

=head2
This tries each of the 3
sub both_uniq    ($uniqueURLs, $uniqueTitles) = both_uniq($urls,$titles)

Makes sure that the elements of the array of urls is unique and that the titles correspond to the urls.

=head2 Getters:

getUrls()
get_dataUrls()
getTitles()
get_OPeNDAPUrls()

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

Richard Strub

=cut


