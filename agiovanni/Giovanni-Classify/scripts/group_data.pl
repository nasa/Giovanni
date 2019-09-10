#!/usr/bin/perl
#$Id: group_data.pl,v 1.1 2013/09/16 21:15:29 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

use 5.008008;
use strict;
use warnings;

use Getopt::Long;
use File::Basename;
use Giovanni::Util;
use Giovanni::Logger;
use Giovanni::Logger::InputOutput;
use Switch;

my $outputFile;
my $inputFile;
my $groupType;
my $groupValue;
my $helpFlag;
GetOptions(
    "out-file=s"    => \$outputFile,
    "in-file=s"     => \$inputFile,
    "group-type=s"  => \$groupType,
    "group-value=s" => \$groupValue,
    "h"             => \$helpFlag,
);

# if this is the help flag, print out the command line arguments
if ( defined($helpFlag) ) {
    die "$0 --out-file 'path to output file'"
        . " --in-file 'path to input file'"
        . " --group-type 'group type'"
        . " --group-value 'group values, comma separated";
}

# set up the logger
my ( $filename, $sessionDir ) = fileparse($outputFile);
my $logger = Giovanni::Logger->new(
    session_dir       => $sessionDir,
    manifest_filename => $filename
);

my $inDoc = Giovanni::Util::parseXMLDocument($inputFile);

# get the id
my @nodes = $inDoc->findnodes(qq|/manifest/fileList/\@id|);
my @ids = map( $_->nodeValue(), @nodes );
if ( scalar(@ids) != 1 ) {
    die("Expected input manifest to have only one id");
}
my $id = $ids[0];

$logger->user_msg("Grouping data $groupType=$groupValue for variable $id.");

# create the lineage input list
my @inputs = ();
@nodes = $inDoc->findnodes(qq|/manifest/fileList/file|);
for my $node (@nodes) {
    my $group    = $node->findvalue("\@group");
    my $filename = basename( $node->findvalue("text()") );
    push(
        @inputs,
        Giovanni::Logger::InputOutput->new(
            name  => "classified file",
            value => $filename . "->" . $group,
            type  => "PARAMETER"
        )
    );
}

# find all the applicable nodes
@nodes = $inDoc->findnodes(
    qq|/manifest/fileList/file[\@group="$groupValue"]/text()|);
my @files = map( $_->nodeValue(), @nodes );

# create the output manifest doc and the lineage outputs
my $root            = Giovanni::Util::createXMLDocument("manifest");
my $outDoc          = $root->ownerDocument();
my $fileListElement = $outDoc->createElement("fileList");
$root->appendChild($fileListElement);
$fileListElement->setAttribute( "id", $id );

# while we are at it, keep track of the list of outputs for lineage
my @outputs = ();
for my $file (@files) {
    my $fileElement = $outDoc->createElement("file");
    $fileListElement->appendChild($fileElement);
    $fileElement->appendText($file);

    push(
        @outputs,
        Giovanni::Logger::InputOutput->new(
            name  => "file",
            value => $file,
            type  => "FILE"
        )
    );
}

# finish up with the logger
$logger->write_lineage(
    name     => "Grouping data $groupType=$groupValue for variable $id.",
    inputs   => \@inputs,
    outputs  => \@outputs,
    messages => []
);
$logger->user_msg(
    "Finished grouping data $groupType=$groupValue for variable $id.");
$logger->percent_done(100);

# write the manifest file last
$outDoc->toFile($outputFile);

1;

__END__

=head1 NAME

group_data.pl

=head1 SYNOPSIS

  group_data.pl --in-file "/path/to/inputmanifest.xml" --out-file "/path/to/outputmanifest.xml" --group-type "SEASON" --group-value "DJF"  

=head1 DESCRIPTION
Groups or filters out data for a specific group value.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.gov<gt>

=cut
