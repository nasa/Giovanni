#!/usr/bin/env perl

=head1 NAME
    
visualize.pl -- visualization task driver 
    
=head1 SYNOPSIS
      
visualize.pl -c cfgFile -m plotManifestFileName -f dataFileListFlattened -t plotType -d outputDir -o options

=head1 DESCRIPTION
  
Driver script for visualization task
This code is originally written for visualization task queue submission
  
=head1 ARGUMENTS

=over 6

=item -c cfgFile

The giovanni cfg file

=item -m plotManifestFileName

The plot manifest file name

=item -f dataFileListFlattened

The flattened data file list that was joined by character '*'

=item -t plotType

Plot type

=item -d outputDir

Output directory name

=item -o options

Options

=back

=head1 AUTHOR
  
Hailiang Zhang <hailiang.zhang@nasa.gov>
  
=cut 

use strict;

use Getopt::Std;
use File::Basename;
use XML::LibXML;
use XML::Hash::LX;
use Giovanni::Visualizer;
use Giovanni::Util;
use Giovanni::Serializer;

################################################################################

# Define and parse argument vars
use vars qw($opt_c $opt_m $opt_f $opt_t $opt_d $opt_o);
getopts('c:m:f:t:d:o:');
usage() unless ( $opt_c && $opt_m && $opt_f && $opt_t && $opt_d );

# Set umask for r+w by group
my $oldMask = umask(002);

# Read the configuration file: giovanni.cfg in to GIOVANNI name space
# I am doing this because they were lost after previous python call
my $cfgFile = $opt_c;
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# local variables
my $plotManifestFileName  = $opt_m;
my $dataFileListFlattened = $opt_f;
my $plotType              = $opt_t;
my $outputDir             = $opt_d;
my $options               = $opt_o;

# Create the visualizer file so that the parent processor know it's already started
# generate data file list from the input flattened string
my @dataFileList = split /\*/, $dataFileListFlattened;

# Write plot manifest file
# NOTE assume plot manifest file stays in $outputDir; this may only works for localhost
my $plotManifestFile = $outputDir . '/' . $plotManifestFileName;

# Delete the plot manifest file if it exists
unlink( -f $plotManifestFile ) if ( -f $plotManifestFile );

if ( $plotType eq 'MAP_ANIMATION' ) {

    # Delete animation.txt files
    foreach my $dataFile (@dataFileList) {
        my %varInfo = Giovanni::Util::getNetcdfDataVariables($dataFile);
        foreach my $layer ( keys %varInfo ) {
            my $animationTxtFile
                = $outputDir . '/animation_' . $layer . '.txt';
            unlink( -f $animationTxtFile ) if ( -f $animationTxtFile );
        }
    }
}

# Go through input files and visualize them one-by-one, while appending the results to the manifest file
# The resulting structure we are trying to build is
# fileGroup: {
#   @code: number,
#   @status: Running/Failed/Succeeded,
#   @message: string,
#   @percentComplete: number,
#   pdfUrl: string_url,
#   dataFile: [{
#        @status: Running/Failed/Succeeded,
#        @message: string,
#        dataUrl: {label: string, value: string},
#        image: [{
#            @status: Running/Failed/Succeeded,
#            @message: string,
#            options: {
#               defaults: json_escaped,
#               schema: json_escaped,
#             },
#            src: string_url,
#            id: uuid
#        }]
#    }]
# }

# Before be begin, let's get a list of expected items
my $historyFile
    = $outputDir . '/' . $GIOVANNI::VISUALIZER->{HISTORY_FILE_NAME};
my $history = Giovanni::History->new( FILE => $historyFile );
my $expectedItems
    = $history->getUniqueAttributeCombinations( [ 'datafile', 'id' ],
    { plotType => $plotType, datafile => \@dataFileList } );
my $expectedItemsMap = {};
foreach my $item ( @{$expectedItems} ) {
    $expectedItemsMap->{ $item->{datafile} } = {}
        unless exists $expectedItemsMap->{ $item->{datafile} };
    $expectedItemsMap->{ $item->{datafile} }{ $item->{id} } = 0;
}

my $doc               = Giovanni::Util::createXMLDocument('fileGroup');
my $totalFileCount    = scalar(@dataFileList);
my $completeFileCount = 0;

# MAIN DATA LOOP:
#   - loop over each data file while calling Visualizer.pm
#   - check returned results and mark missing expected items as failed
#   - rewrite manifest file using newly collected information
my $defaultErrorMessage = 'Sorry. We could not produce a plot.';

foreach my $dataFile (@dataFileList) {
    my $dataFileNode = Giovanni::Util::createXMLElement('dataFile');

   # Setup serialization URL (also helps to identify data file in the results)
    my $dataUrl = Giovanni::Util::convertFilePathToUrl( $dataFile,
        \%GIOVANNI::URL_LOOKUP );
    my $serializer = Giovanni::Serializer->new( FILE => $dataFile );
    my ( $serUrl, $serFile ) = $serializer->getSerializationUrl($plotType);
    $serUrl  = $dataUrl            unless defined $serUrl;
    $serFile = basename($dataFile) unless defined $serFile;
    my $dataUrlNode = Giovanni::Util::createXMLElement('dataUrl');
    $dataUrlNode->setAttribute( 'label', $serFile );
    $dataUrlNode->appendText( $serUrl );
    $dataFileNode->appendChild($dataUrlNode);

    # Initialize the Visualizer object
    my $visualizer;

    # Status vars
    my $status;
    my $code;
    my $message;
    my $portal = 'GIOVANNI';    # NOTE potential issue

    # Run visualization (synchronously)
    eval {
        if ( $plotType eq 'MAP_ANIMATION' ) {
           $visualizer = Giovanni::Visualizer->new(
              FILE       => \@dataFileList,
              PLOT_TYPE  => $plotType,
              OUTPUT_DIR => $outputDir,
              OPTIONS    => $options,
           );
        }
        else {
           $visualizer = Giovanni::Visualizer->new(
              FILE       => [$dataFile],
              PLOT_TYPE  => $plotType,
              OUTPUT_DIR => $outputDir,
              OPTIONS    => $options,
           );
        }
        $status = $visualizer->visualize();
    };

    # Process reuslts
    if ($@) {

        # Visualization of a given file failed
        warn "ERROR Intercepted exception while driving visualizer", $@
            if $@;    # Warn if we intercepted an exception
                      # setStatusAttributes($doc, 'Failed', $code, $message);
        setStatusAttributes( $dataFileNode, 'Failed', undef,
            $defaultErrorMessage );
    }
    else {

        # The task succeeded
        my $resultRef = $visualizer->getResults();

        foreach my $resultItem ( @{$resultRef} ) {
            # Mark image as sucessfully rendered
            if ( @{$resultItem} ) {
                foreach my $imageItem ( @{ $resultItem } ) {
                    next unless ( exists $imageItem->{image} );
                    $imageItem->{image}{status} = 'Succeeded';
                    $expectedItemsMap->{$dataFile}{ $imageItem->{image}{id} } = 1
                        if (
                        exists $expectedItemsMap->{$dataFile}
                        { $imageItem->{image}{id} } );
                }
            }

            # Convert result items hash array to XML
            my $resultXml = hash2xml(
                { root => $resultItem },
                doc       => 1,
                canonical => 1,
                attr      => '-'
            );
            for ( $resultXml->documentElement()->childNodes() ) {
                $dataFileNode->appendChild($_);
            }
        }

        # Write pdfUrl if any
        my $pdfUrl = $visualizer->getPdfUrl($portal);
        if ( defined $pdfUrl ) {
            $doc->appendChild(
                Giovanni::Util::createXMLElement( 'pdfUrl', $pdfUrl ) );
        }
        setStatusAttributes( $dataFileNode, 'Succeeded', undef, undef );
    }

# Check for any missing images and create corresponding error image nodes on the dataFile node
    if ( exists $expectedItemsMap->{$dataFile} ) {
        foreach my $imageId ( keys %{ $expectedItemsMap->{$dataFile} } ) {
            next unless $expectedItemsMap->{$dataFile}{$imageId} == 0;
            $expectedItemsMap->{$dataFile}{$imageId} = -1;
            my $imageNode
                = Giovanni::Util::createXMLElement( 'image', id => $imageId );
            setStatusAttributes( $imageNode, 'Failed', undef,
                defined $message ? $message : $defaultErrorMessage );
            $dataFileNode->appendChild($imageNode);
        }
    }

    # Uppend dataFile node to dataFileGroup
    $doc->appendChild($dataFileNode);

    # Compute percent completed
    my $percentComplete = 100 * ( ++$completeFileCount ) / $totalFileCount;
    $doc->appendChild(
        Giovanni::Util::createXMLElement(
            'percentComplete', $percentComplete
        )
    );
    setStatusAttributes( $doc,
        $completeFileCount == $totalFileCount ? 'Succeeded' : 'Running',
        undef, undef );

    # Finally write the manifest file
    Giovanni::Util::writeFile( $plotManifestFile, $doc->toString(1) );

    last if ( $plotType eq 'MAP_ANIMATION' );
}

# Reset umask
umask($oldMask);

################################################################################
sub setStatusAttributes {
    my ( $doc, $status, $code, $message ) = @_;
    $doc->appendChild(
        Giovanni::Util::createXMLElement( 'message', $message ) )
        if defined $message;
    $doc->appendChild( Giovanni::Util::createXMLElement( 'code', $code ) )
        if defined $code;
    $doc->appendChild( Giovanni::Util::createXMLElement( 'status', $status ) )
        if defined $status;
}

################################################################################
sub usage {
    die
        "Usage: $0 -c cfgFile -m plotManifestFileName -f dataFileListFlattened -t plotType -d outputDir [-o options]\n";
}

