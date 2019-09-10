#!/usr/bin/perl

#$Id: createTestHtml.pl,v 1.9 2015/03/10 20:20:57 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

use strict;
use XML::LibXML;
use File::Temp;
use File::Copy;
use Getopt::Long;
use File::Basename;

my $opt = {};
Getopt::Long::GetOptions( $opt, "f=s", "o=s" );
my $htmlFile = $opt->{f};

# Croak if HTML file doesn't exist
die "$htmlFile doesn't exist" unless ( -f $htmlFile );
my $testJsFileLocation = dirname($htmlFile) . "/js/GiovanniRegressionTest.js";
die "Tests, $testJsFileLocation, doesn't exist"
    unless ( -f $testJsFileLocation );

# Create an XML parser
my $xmlParser = XML::LibXML->new();

# Holder for DOM
my $dom;

# Try parsing HTML file
eval { $dom = $xmlParser->parse_html_file($htmlFile); };

# On error, croak
if ($@) {
    die "Failed to parse $htmlFile";
}

# Get the document element
my $doc = $dom->documentElement();
my ($headNode) = $doc->findnodes(qq(/html/head));
die "Failed to find head tag in $htmlFile" unless defined $headNode;
my @scriptList
    = qw(jasmine/jasmine.css jasmine/jasmine.js jasmine/jasmine-html.js jasmine/boot.js jasmine/jasmine_favicon.png);
push( @scriptList, 'js/' . basename($testJsFileLocation) );
foreach my $file (@scriptList) {
    my $nodeType
        = $file =~ /\.css$/i ? 'text/css'
        : $file =~ /\.js$/i  ? 'text/javascript'
        : $file =~ /\.png$/i ? 'image/png'
        :                      undef;
    my $nodeName
        = $file =~ /\.css$/i ? 'link'
        : $file =~ /\.js$/i  ? 'script'
        : $file =~ /\.png$/i ? 'link'
        :                      undef;
    next unless defined $nodeType;
    my $node = XML::LibXML::Element->new($nodeName);
    $node->setAttribute( 'type', $nodeType );
    $node->setAttribute( 'rel', 'stylesheet' ) if ( $nodeType eq 'text/css' );
    if ( $nodeName eq 'link' ) {
        $node->setAttribute( 'href', $file );
    }
    else {
        $node->setAttribute( 'src', $file );
    }
    $headNode->appendChild($node);
}

# my $buttonNode = XML::LibXML::Element->new('input');
# $buttonNode->setAttribute( 'id', 'testButton' );
# $buttonNode->setAttribute( 'type',  'button' );
# $buttonNode->setAttribute( 'onClick',
#     'giovanni.test.RegressionTest.runTest()' );
# $buttonNode->setAttribute( 'value', 'Run Tests' );
# $buttonNode->setAttribute( 'title', 'Run Tests' );
# my ($bodyNode) = $doc->findnodes(qq(/html/body));
# $bodyNode->appendChild($buttonNode);

my $htmlFH = File::Temp->new();
print $htmlFH $dom->toStringHTML();
close($htmlFH);
unlink $opt->{o};
File::Copy::copy( $htmlFH->filename, $opt->{o} );
exit( ( -f $opt->{o} ? 0 : 1 ) );
