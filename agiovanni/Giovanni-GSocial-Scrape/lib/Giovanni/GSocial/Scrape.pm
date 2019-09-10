#$Id: Scrape.pm,v 1.2 2012/09/04 17:03:41 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::GSocial::Scrape;

use 5.008008;
use strict;
use warnings;

use HTML::TreeBuilder;
use XML::LibXML;
use URI::URL;

# creates a regression test plan from an html string and writes
# the configuration to an output file.
sub createTestPlan() {
    my ( $class, $htmlStr, $outFile ) = @_;

    # first pull out the urls and descriptions for the tests
    my ( $urls, $descriptions ) = $class->_getUrls($htmlStr);

    # now create the XML
    my $doc = XML::LibXML::Document->new( '1.0', 'utf-8' );
    my $root = $doc->createElement('giovanniRegressionTests');
    $doc->addChild($root);

    # each of the urls translates into one test
    my $numTests = scalar( @{$urls} );
    for ( my $i = 0; $i < $numTests; $i++ ) {
        my $urlText         = @{$urls}[$i];
        my $descriptionText = @{$descriptions}[$i];
        my $nameText        = "Test_$i";

        # tests have a name, status, url, and validators
        my $test = $doc->createElement('test');
        $root->addChild($test);
        $test->addChild( $doc->createComment($descriptionText) );

        my $name = $doc->createElement('name');
        $test->addChild($name);
        $name->addChild( $doc->createTextNode($nameText) );

        my $status = $doc->createElement('status');
        $test->addChild($status);
        $status->addChild( $doc->createAttribute( code => '200' ) );

        my $url = $doc->createElement('url');
        $test->addChild($url);
        $url->addChild( $doc->createTextNode($urlText) );

        #
        # create a validator for the first data file
        #
        my $dataValidator = $doc->createElement('validator');
        $test->addChild($dataValidator);

        my $dVDescription = $doc->createElement('description');
        $dataValidator->addChild($dVDescription);
        $dVDescription->addChild(
            $doc->createTextNode('validate the first data file') );

        my $dVCommand = $doc->createElement('command');
        $dataValidator->addChild($dVCommand);
        $dVCommand->addChild( $doc->createTextNode('diff') );    # CHANGE ME!

        my $dVXPath = $doc->createElement('xpath');
        $dataValidator->addChild($dVXPath);
        $dVXPath->addChild(
            $doc->createTextNode(
                '/session/resultset/result/data/fileGroup/dataFile[1]/dataUrl'
            )
        );

        #
        # create a validator for the first image
        #
        my $imageValidator = $doc->createElement('validator');
        $test->addChild($imageValidator);

        my $iVDescription = $doc->createElement('description');
        $imageValidator->addChild($iVDescription);
        $iVDescription->addChild(
            $doc->createTextNode('validate the first image') );

        my $iVCommand = $doc->createElement('command');
        $imageValidator->addChild($iVCommand);
        $iVCommand->addChild( $doc->createTextNode('diff') );    # CHANGE ME!

        my $iVXPath = $doc->createElement('xpath');
        $imageValidator->addChild($iVXPath);
        $iVXPath->addChild(
            $doc->createTextNode(
                '/session/resultset/result/data/fileGroup/dataFile[1]/image/src'
            )
        );

    }

    # write the document to a file
    $doc->toFile($outFile);
}

# Returns all the aG urls and the descriptions people gave the URLs. Converts
# the bookmarkable URLs into service manager URLs.
sub _getUrls {
    my ( $class, $htmlStr ) = @_;

    # parse out the html into a tree
    my $html = HTML::TreeBuilder->new;
    $html->parse($htmlStr);
    $html->eof();

    # find all the link tags
    my @nodes = $html->find_by_tag_name("a");

    # initialize the arrays that will hold the links and descriptions
    my @links        = ();
    my @descriptions = ();
    for my $node (@nodes) {
        my $link = $node->attr("href");
        if ( defined($link) && $link =~ m/service/ ) {

            # this is a bookmarkable url
            my $serviceLink = $class->_createServiceManagerUrl($link);
            push( @links, $serviceLink );

         # Now we need to find the text associated with this entry in gsocial.
         # Get the grandparent, which includes the description. This is a div
         # tag.
            my $grandparent = $node->parent()->parent();

            # now get the paragraphs under this tag
            my @paragraphs  = $grandparent->find_by_tag_name("p");
            my $found       = 0;
            my $description = "";

            # the first thing with text is the description.
            while ( !$found && scalar(@paragraphs) > 0 ) {
                my $paragraph = shift(@paragraphs);

                # see if this has text
                my $text = $paragraph->as_text();
                if ( $text ne "" ) {
                    $description = $text;
                    $found       = 1;
                }
            }
            push( @descriptions, $description );
        }
    }

    $html->delete();
    return ( \@links, \@descriptions );
}

# converts a bookmarkable URL into a service manager URL
# http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=23D077CE-F204-11E1-891C-ECA3E963CC93&bbox=55,10,90,30&data=SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_ocean&variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&starttime=2007-01-01&endtime=2007-01-31T23:59:59Z&service=AEROSOLS_TIME_SERIES&portal=GIOVANNI
# -->
# http://giovanni.gsfc.nasa.gov/beta/daac-bin/giovanni/service_manager.pl?bbox=55,10,90,30&data=SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_ocean&variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&starttime=2007-01-01&endtime=2007-01-31T23:59:59Z&service=AEROSOLS_TIME_SERIES&portal=GIOVANNI
sub _createServiceManagerUrl {
    my ( $class, $url ) = @_;

    my $parsedUrl = URI::URL->new($url);

    # get out the fragment part of the URL
    my $fragment = $parsedUrl->fragment();

    # remove the session part, if it is there
    $fragment =~ s/session=[-0-9A-F]+&//;

    # get out the path. We are going to replace 'giovanni/' with
    # daac-bin/giovanni/service_manager.pl
    my $path = $parsedUrl->epath();
    $path =~ s/giovanni\//daac-bin\/giovanni\/service_manager.pl/;

    # now build a new URL
    my $scheme = $parsedUrl->scheme();
    my $host   = $parsedUrl->host();
    my $newUrl = "$scheme://$host$path?$fragment";
    return $newUrl;
}

1;
__END__

=head1 NAME

Giovanni::GSocial::Scrape->createTestPlan($html,$file)

=head1 SYNOPSIS

  use Giovanni::GSocial::Scrape;
  
  # get some gSocial html from a file
  open FILE, "<", "gsocial.html" or die $!;
  my @lines = <FILE>;
  close FILE;
  my $html = join('',@lines);
  
  Giovanni::GSocial::Scrape->createTestPlan($html,"temp.xml");

=head1 DESCRIPTION

Scrapes giovanni URLs from a GSocial group page and then writes a regression
test configuration file (a.k.a. - test plan).

=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>

=cut
