#!/usr/bin/perl

package Giovanni::BoundsNetCDF4Scrubber;

=pod

=head1 NAME

    Giovanni::BoundsNetCDF4Scrubber


=head1 SYNOPSIS

  This is the library to update the existing scrubbed files with the FEDGIANNI-1724 fixes

  justNewScrubbing does this rescrubbing
  runScrubber runs the current ncScrubber.pl on the same file so the rescrubbing can be verified

  my $extraScrubber = new Giovanni::BoundsNetCDF4Scrubber(
        input      => basename($oldScrubbed),
        catalog    => $dataFieldVarInfo,
        workingdir => "$workingdir",
        output     => 'extra_' . basename($oldScrubbed)
    );
  my $outputfile = $extraScrubber->justNewScrubbing($oldScrubbed);
 

  my $new = runScrubber( $workingdir, $varInfo, $freshlyDownloaded );

=head1 DESCRIPTION

  I hope to use this for FEDGIANNI-1724 rescrubbing and to modify it for scrubber regression testing.
  It is connected with FEDGIANNI-2134 and FEDGIANNI-2133

=head1 AUTHOR

  Richard Strub GES DISC Giovanni Project

=cut

@ISA    = qw(Exporter);
@EXPORT = qw(runScrubber);

use warnings;
use Getopt::Long;
use File::Basename;
use File::Copy;
use XML::LibXML;

# use Date::Parse;
use Data::Dumper;
use DateTime;
use Time::HiRes qw (sleep);
use Time::Local;
use File::Temp qw/ tempfile tempdir /;
use Date::Manip;
use Giovanni::Scrubber;
use Giovanni::Data::NcFile;
use Giovanni::DataField;
use Giovanni::WorldLongitude;
use POSIX;
use strict;
our $verbose;

sub new {
    my ( $class, %arg ) = @_;
    my $self = {};

    # Get the header from the file
    local ($/) = undef;
    $self = \%arg;
    bless( $self, $class );
    return $self;
}

# This is the  particular
# RE-SCRUBBING TASK
# we are doing for this time around
sub justNewScrubbing {
    my $self = shift;
    $verbose = $self->{verbose};
    my $workingdir  = $self->{workingdir};
    my $workingfile = $self->{input};

    my $dataFieldVarInfo = $self->{catalog};
    my $dataId           = $dataFieldVarInfo->get_id;

    my $NcFile = Giovanni::Data::NcFile->new(
        NCFILE  => $workingfile,
        verbose => $verbose
    );
    my ( $startobj, $endobj ) = getStartTimeAndEndTime($NcFile);

    # First check and see if it is not already netCDF-4
    # We are now converting all files to NetCDF4:
    if ( !thisFileAlreadyIsNetCDF4($workingfile) ) {
        if (Giovanni::Data::NcFile::to_netCDF4_classic( $workingfile,
                "$workingfile.nc4" ) != 1
            )
        {    # not using compression
            die "Unable to create netCDF4_classic formatted file";
        }
        move_file( "$workingfile.nc4", $workingfile, "$workingfile.nc4" );
    }

    # Before, using ncwa, how we used to create the record dimension,
    # puts in a cell_methods of "record: mean"
    # The current scrubber does not do this so we need to remove it:
    my $cellMethodsValue
        = Giovanni::Data::NcFile::get_value_of_attribute( $workingfile,
        $dataId, 'cell_methods' );
    chomp $cellMethodsValue;
    if ( $cellMethodsValue eq 'record: mean' ) {
        $NcFile->delete_attribute( 'cell_methods', $dataId );
    }
    if ( $cellMethodsValue =~ / record: mean/ ) {
        $cellMethodsValue =~ s/ record: mean//;
        my $status = $NcFile->update_attribute( 'cell_methods', $dataId,
            $cellMethodsValue );
        if ( $status != 0 ) {
            die
                "Unable to remove record: mean from cell_methods of old scrubbed file";
        }

    }

    # These next 4 subroutines are the heart of the purpose for re-scrubbing:

    apply_timeIntvRepPos( $dataFieldVarInfo, $startobj, $endobj,
        $workingfile );

    addTimeBnds( $NcFile, $startobj, $endobj, $workingfile );

    applyCellMethodPointForInstantaneous( $dataId, $startobj, $endobj,
        $workingfile );

    addLatLonBnds( $workingfile, $workingdir );

    # Finally decided we need to add long_name to time
    createAttribute( $workingfile, 'long_name', 'time', 'c', 'time' );

    my $deleteHistoryCommand
        = "ncatted -O -h -a \"history,global,d,c,,\" $workingfile";
    runNCOCommand( $deleteHistoryCommand, "Delete 'history' attribute" );

    if ( $self->{output} )
    {    # only want to create an extra_* file with compare tool
        my $outputfile = $self->{output};
        move_file( $workingfile, "$workingdir/$outputfile",
            "$workingfile.nc4" );
        return "$workingdir/$outputfile";
    }
}

# Runs the installed, latest scrubber
sub runScrubber {
    my $workingdir  = shift;
    my $varinfoFile = shift;
    my $freshFile   = shift;

    my $dataFieldVarInfo
        = new Giovanni::DataField( MANIFEST => $varinfoFile );
    makeListingFile( $workingdir, basename($freshFile),
        $dataFieldVarInfo->get_id );

    my $cmd
        = qq(ncScrubber.pl --input $workingdir/listingfiles.xml --catalog $varinfoFile  --outDir $workingdir  -v 0);
    my $status = system($cmd);
    if ( $status != 0 ) {
        die("ERROR: $cmd returned $status\n");
    }

    my $listfile = "$workingdir/scrubbed-listingfiles.xml";
    my $parser   = XML::LibXML->new();
    my $doc      = $parser->parse_file($listfile);
    my $output   = $doc->getElementsByTagName('dataFile')->[0]->textContent();

    return $output;

}

# a scrubber input argument:
sub makeListingFile {
    my $workingdir = shift;
    my $filename   = shift;
    my $variable   = shift;

    if ( open( LIST, ">", "$workingdir/listingfiles.xml" ) ) {
        print LIST qq(
<data>
<dataFileList id="$variable" sdsName="doesntmatter">
        <dataFile>$workingdir/$filename</dataFile>
</dataFileList>
</data>
);
        close(LIST);
    }
    else {
        die("ERROR Could not open $workingdir/listingfiles.xml for write");
    }

}

sub getStartTimeAndEndTime {

    my $NcFile   = shift;
    my $xpc      = $NcFile->getXPathPointer();
    my $startobj = undef;
    my $endobj   = undef;

    my @fnd_nodes
        = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="start_time"]));
    if (@fnd_nodes) {
        my $starttime = $fnd_nodes[0]->getAttribute('value');
        $startobj = createDateObj($starttime);
    }
    @fnd_nodes
        = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="end_time"]));
    if (@fnd_nodes) {
        my $endtime = $fnd_nodes[0]->getAttribute('value');
        $endobj = createDateObj($endtime);
    }

    return ( $startobj, $endobj );
}

sub createDateObj {
    my $date = shift;
    chop $date;
    my ( $inputDate, $inputTime ) = split( /T/, $date );

    my @dateparts = split( /-/, $inputDate, 3 );
    my @timeparts = split( /:/, $inputTime, 3 );
    my $Date      = DateTime->new(
        year       => $dateparts[0],
        month      => $dateparts[1],
        day        => $dateparts[2],
        hour       => $timeparts[0],
        minute     => $timeparts[1],
        second     => $timeparts[2],
        nanosecond => 0,
        time_zone  => 'UTC'
    );

    return $Date;
}

# Should return true if already NetCDF4
sub thisFileAlreadyIsNetCDF4 {
    my $file     = shift;
    my $CACHEDIR = $ENV{cachedir};
    my $format   = `ncdump -k $file`;
    if ( $format =~ /netCDF-4 classic model/ ) {
        return 1;
    }
    return 0;
}

1;
