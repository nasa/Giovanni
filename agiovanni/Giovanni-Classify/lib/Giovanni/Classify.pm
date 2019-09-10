package Giovanni::Classify;

use 5.008008;
use strict;
use warnings;
use Giovanni::Util;
use Giovanni::Logger;
use Giovanni::Logger::InputOutput;
use File::Basename;

our $VERSION = '0.01';

# Preloaded methods go here.

# INPUT => input manifest
# OUTPUT => output manifest
sub classify_seasons {
    my (%inputs) = @_;

    my ( $name, $path ) = fileparse( $inputs{"OUTPUT"} );
    my $logger = Giovanni::Logger->new(
        session_dir       => $path,
        manifest_filename => $name
    );
    $logger->user_msg("Classifying data files into seasons");

    my ( $id, @files ) = _getInputFiles( $inputs{"INPUT"} );

    # hash of group value to an array of files
    my $groupsHash = {};
    for my $file (@files) {

        # pull the month out of the filename
        my $month = getMonth($file);
        if ( $month eq "12" || $month eq "01" || $month eq "02" ) {
            push( @{ $groupsHash->{DJF} }, $file );
        }
        elsif ( $month eq "03" || $month eq "04" || $month eq "05" ) {
            push( @{ $groupsHash->{MAM} }, $file );
        }
        elsif ( $month eq "06" || $month eq "07" || $month eq "08" ) {
            push( @{ $groupsHash->{JJA} }, $file );
        }
        else {
            push( @{ $groupsHash->{SON} }, $file );
        }
    }

    my @groups = ( "DJF", "MAM", "JJA", "SON" );

    _writeLineage( $logger, \@files, \@groups, $groupsHash );
    $logger->user_msg("Done classifying data files into seasons");
    $logger->percent_done(100);

    # write the manifest last
    _writeManifest( $inputs{"OUTPUT"}, $id, \@groups, $groupsHash );
}

# INPUT => input manifest
# OUTPUT => output manifest
sub classify_months {
    my (%inputs) = @_;

    my ( $name, $path ) = fileparse( $inputs{"OUTPUT"} );
    my $logger = Giovanni::Logger->new(
        session_dir       => $path,
        manifest_filename => $name
    );
    $logger->user_msg("Classifying data files into months");

    my ( $id, @files ) = _getInputFiles( $inputs{"INPUT"} );

    # hash of group value to an array of files
    my $groupsHash = {};
    for my $file (@files) {

        # pull the month out of the filename
        my $month = getMonth($file);
        push( @{ $groupsHash->{$month} }, $file );
    }

    my @groups = (
        "01", "02", "03", "04", "05", "06",
        "07", "08", "09", "10", "11", "12"
    );

    _writeLineage( $logger, \@files, \@groups, $groupsHash );
    $logger->user_msg("Done classifying data files into months");
    $logger->percent_done(100);

    # write the manifest last
    _writeManifest( $inputs{"OUTPUT"}, $id, \@groups, $groupsHash );
}

sub getMonth {
    my $path = basename( $_[0] );

    # Works for both:
    # IMERG: scrubbed.GPM_3IMERGM_03_precipitation.20140701000000.nc
    # NLDAS: scrubbed.NLDAS_NOAH0125_M_002_cnwatsfc.19790101T0000.nc
    $path =~ /\.\d\d\d\d(\d\d)(\d\d)T*\d*.nc$/;
    my $month = $1;
    die "Failed to extract month from filename $path\n" unless ($month);
    return $month;
}

sub _writeLineage {
    my ( $logger, $inputFiles, $groupsRef, $groupsHash ) = @_;

    my @inputs = ();
    for my $file (@$inputFiles) {
        push(
            @inputs,
            Giovanni::Logger::InputOutput->new(
                name  => "file",
                value => basename($file),
                type  => "PARAMETER"
            )
        );
    }
    my @outputs = ();
    for my $group (@$groupsRef) {
        for my $file ( @{ $groupsHash->{$group} } ) {
            push(
                @outputs,
                Giovanni::Logger::InputOutput->new(
                    name  => "classified file",
                    value => basename($file) . " -> " . $group,
                    type  => "PARAMETER",
                )
            );
        }
    }
    $logger->write_lineage(
        name     => "Classify input data",
        inputs   => \@inputs,
        outputs  => \@outputs,
        messages => []
    );
}

sub _writeManifest {
    my ( $manifestFile, $id, $groupsRef, $groupsHash ) = @_;

    my $root = Giovanni::Util::createXMLDocument("manifest");
    my $doc  = $root->ownerDocument();

    my $fileListElement = $doc->createElement("fileList");
    $root->appendChild($fileListElement);
    $fileListElement->setAttribute( "id", $id );

    for my $group (@$groupsRef) {
        for my $file ( @{ $groupsHash->{$group} } ) {
            my $fileElement = $doc->createElement("file");
            $fileListElement->appendChild($fileElement);
            $fileElement->setAttribute( "group", $group );
            $fileElement->appendText($file);
        }
    }

    $doc->toFile($manifestFile);
}

sub _getInputFiles {
    my ($inputFile) = @_;
    my $inDoc       = Giovanni::Util::parseXMLDocument($inputFile);
    my @ids         = map( $_->nodeValue(),
        $inDoc->findnodes(qq(/manifest/fileList/\@id)) );
    if ( scalar(@ids) != 1 ) {
        die("Expected input file to have a single fileList");
    }
    my $id = $ids[0];
    my @nodes
        = $inDoc->findnodes(qq|/manifest/fileList[\@id="$id"]/file/text()|);
    my @files = map( $_->nodeValue(), @nodes );
    Giovanni::Util::trim(@files);
    return ( $id, @files );
}

1;
__END__

=head1 NAME

Giovanni::Classify - Perl extension for classifying files into seasons and months

=head1 SYNOPSIS

  use Giovanni::Classify;
  
  Giovanni::Classify::classify_months(
   INPUT        => $inputManifest,
   OUTPUT       => $outputMonthsManifest,
);

Giovanni::Classify::classify_seasons(
   INPUT        => $inputManifest,
   OUTPUT       => $outputMonthsManifest,
);
  

=head1 DESCRIPTION
Classifies data into months or seasons. The input file should be from data 
staging. The output file is the same format, but each file entry has a 'group'
attribute.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.gov<gt>

=cut
