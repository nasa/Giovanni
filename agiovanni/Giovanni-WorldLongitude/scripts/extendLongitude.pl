#!/usr/bin/perl

#$Id: extendLongitude.pl,v 1.6 2014/11/05 22:19:06 clynnes Exp $
#-@@@ GIOVANNI,Version $Name:  $

=head1 Name 

extendLongitude.pl --in-file /path/to/input/manifest.xml --out-file /path/to/output/manifest.xml [--across-dateline]

=head1 DESCRIPTION

If the longitudes are discontinuous, this code moves the data onto a -180 to 
180 longitude grid.

However, if the --across-dateline argument is given, 360 degrees is added to the 
negative values to simply extend it across the dateline. This is useful for the 
Lat-averaged Hovmollers.

NOTE: All the files in the input manifest should have the same variables and 
dimensions (including shape).

=head1 AUTHOR

Christine Smit <christine.e.smit@nasa.gov>

=cut

use strict;
use warnings;
use Getopt::Long;
use File::Copy;
use File::Basename;
use XML::LibXML;
use Giovanni::Logger;
use Giovanni::Logger::InputOutput;
use Giovanni::WorldLongitude;
use Giovanni::Util;

my $inputFile;
my $outputFile;
my $helpFlag;
my $cleanUp;
my $acrossDateline;

GetOptions(
    "out-file=s"      => \$outputFile,
    "in-file=s"       => \$inputFile,
    "clean-up=s"      => \$cleanUp,
    "across-dateline" => \$acrossDateline,
    "h"               => \$helpFlag,
);

# if this is the help flag, print out the command line arguments
if ( defined($helpFlag) ) {
    die "$0 --out-file 'path to output file'"
        . " --in-file 'path to input file'";
}

if ( !defined($inputFile) ) {
    die "Missing mandatory argument '--in-file'";
}
if ( !defined($outputFile) ) {
    die "Missing mandatory argument '--out-file'";
}
if ( !defined($cleanUp) ) {
    $cleanUp = 1;
}

# create a logger
my $outdir      = dirname($outputFile);
my $logfilename = basename($outputFile);
my $logger      = Giovanni::Logger->new(
    session_dir       => $outdir,
    manifest_filename => $logfilename
);
$logger->user_msg("Place data on world-wide longitude grid.");

# parse the input file
my $parser  = XML::LibXML->new();
my $dom     = $parser->parse_file($inputFile);
my $xpDom   = XML::LibXML::XPathContext->new($dom);
my @inFiles = map( $_->nodeValue, $xpDom->findnodes("//file/text()") );
Giovanni::Util::trim(@inFiles);

# pull the longitude out of one of these files so we can see if we actually
# need to do anything
my @longitudes
    = Giovanni::Data::NcFile::get_variable_values( $inFiles[0], "lon" );

my @outFiles     = ();
my $needsNewGrid = 0;
if ($acrossDateline) {
    $needsNewGrid = ( $longitudes[0] > $longitudes[-1] );
}
else {
    $needsNewGrid
        = Giovanni::WorldLongitude::fileNeedsNewLongitudeGrid(@longitudes);
}
if ($needsNewGrid) {

    # OK - we need to normalize. So, create output data filenames
    for my $file (@inFiles) {
        my $dir      = dirname($file);
        my $filename = basename($file);

        if ( $filename =~ m/^(.*?)[.](.*)$/ ) {

            # basically, replace the prefix with <prefix>WorldLon
            push( @outFiles, "$dir/$1" . "WorldLon." . "$2" );
        }
        else {
            die "Unable to parse input data filename in $file";
        }
    }

    # call the normalizer
    Giovanni::WorldLongitude::normalize(
        logger         => $logger,
        in             => \@inFiles,
        out            => \@outFiles,
        startPercent   => 0,
        endPercent     => 99,
        sessionDir     => $outdir,
        cleanUp        => $cleanUp,
        acrossDateline => $acrossDateline,
    );

    # write lineage
    my @inputs  = ();
    my @outputs = ();
    for ( my $i = 0; $i < scalar(@inFiles); $i++ ) {
        push(
            @inputs,
            Giovanni::Logger::InputOutput->new(
                name  => "file",
                value => $inFiles[$i],
                type  => "FILE"
            )
        );
        push(
            @outputs,
            Giovanni::Logger::InputOutput->new(
                name  => "file",
                value => $outFiles[$i],
                type  => "FILE"
            )
        );
    }

    $logger->write_lineage(
        name      => "Place data on a world-spanning longitude grid.",
        inputs    => \@inputs,
        outputs   => \@outputs,
        messagers => [],
    );

}
else {

    # No need to normalize or write lineage
    $logger->user_msg("No longitude grid extension needed.");
    @outFiles = @inFiles;
}

# build the root of the output XML
my $doc  = XML::LibXML->createDocument;
my $root = $doc->createElement("manifest");
$doc->setDocumentElement($root);
my $fileListElement = $doc->createElement("fileList");
$root->appendChild($fileListElement);

for my $file (@outFiles) {
    my $fileElement = $doc->createElement("file");
    $fileListElement->appendChild($fileElement);
    $fileElement->appendText($file);
}

# write it to the output manifest file
open( OUTFILE, ">", $outputFile )
    or die $?;
print OUTFILE $doc->toString() or die $?;
close(OUTFILE) or die $?;

$logger->percent_done(100);

exit(0);
