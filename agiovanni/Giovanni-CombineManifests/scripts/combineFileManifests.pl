#!/usr/bin/perl
#$Id: combineFileManifests.pl,v 1.2 2015/04/03 19:50:04 eseiler Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

combineFileManifests - combines multiple file manifests into one

=head1 SYNOPSIS

  combineFileManifests.pl path/to/mfst.output.xml \
    /path/to/mfst.input1.xml /path/to/mfst.input2.xml 

=head1 DESCRIPTION
    The first command line argument is the output manifest file followed by
    all the input manifest files

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use strict;
use warnings;
use Giovanni::Logger;
use File::Basename;

if ( scalar(@ARGV) < 2 || $ARGV[0] eq '-h' ) {
    die
        "Usage: combineFileManifests /path/to/mfst.output.xml /path/to/mfst.input1.xml /path/to/mfst.input2.xml";
}

my $outFile = shift(@ARGV);
my @inFiles = @ARGV;

# create the logger
my ( $manifestName, $dir ) = fileparse($outFile);
my $logger = Giovanni::Logger->new(
    session_dir       => $dir,
    manifest_filename => $manifestName,
);

$logger->user_msg("Consolidating files for visualization");

# build the root of the output file
my $outDoc = XML::LibXML->createDocument();
my $root   = $outDoc->createElement("manifest");
$outDoc->setDocumentElement($root);

# go through each of the input manifest files
for my $file (@inFiles) {
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file($file);
    my $xpc    = XML::LibXML::XPathContext->new($dom);

    my @nodes = $xpc->findnodes("/manifest/fileList");
    for my $node (@nodes) {
        $root->appendChild($node);
    }
}

$logger->user_msg("Done consolidating files for visualization");
$logger->percent_done(100);

# write out the manifest file
open( FILE, ">", $outFile )
    or die "Unable to open manifest file $outFile";
print FILE $outDoc->toString()
    or die "Unable to write manifest file $outFile";
close(FILE);

1;
