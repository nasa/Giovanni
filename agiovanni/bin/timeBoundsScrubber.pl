#!/usr/bin/perl

=pod

=head1 NAME

timeBoundsScrubber.pl - this script runs timeBoundsScrubbing to add bounds variables etc to existing scrubbed files.
(specifically files produced by: giovanni4-4.21.3.001-GESDISC.x86_64 or before.

It can also be used as a scrubber regression test in that it can be modified to scrub a new file
and compare it with the corresponding file on the OPS box. 

It was first used in this capacity - doing both of these issues. 
For comparing the results to make sure that the timeBoundsRescrubbing goes ok.  
An additional flag needs to be added to do only the rescrubbing.



=head1 INPUTS

	previouslyScrubbedFile 
	[freshlyDownloadedFile]
	tempdir
	varInfoFile
	aesir    (environment variable) the URL for the desired AESIR - to create the varinfo input file needed for scrubbing

=head1 SYNOPSIS

timeBoundsScrubber.pl -variable SWDB_L3MC10_004_aerosol_optical_thickness_550_ocean
    -previouslyScrubbed /tmp/uEN1AmACAw/scrubbed.SWDB_L3MC10_004_aerosol_optical_thickness_550_ocean.19980401.nc
    -freshlyDownloaded  /tmp/uEN1AmACAw/DeepBlue-SeaWiFS-1.0_L3MC_199804-201004_v004-20130614T144155Z.h5.nc
    -workingdir  /tmp/uEN1AmACAw
    -varinfo /tmp/uEN1AmACAw/varinfo.xml

=head1 DESCRIPTION

Action 1: 
Updates a previously scrubbed  OPS file (in TmpDir) with the new requirements from FEDGIANNI-1794:  
(LatLonBnds,TimeBnds, instantaneous CellMethods, timeIntvRepPos).

Action 2:
Runs the latest installed ncScrubber.pl on a freshly downloaded file from OPeNDAP to the TmpDir.

Action 3:
Runs Giovanni::Data::NcFile::diff_netcdf_files(diff_nc.py)  and compares the result

Action 4:
Logs the results in $TMPDIR (not a tempdir) /ExtraScrubbingValidation.log

=head1 AUTHOR

Richard Strub, GES DISC::Giovanni::Department of Scrubbing.

=cut

use DB_File;
use Fcntl ':flock';
use Giovanni::Scrubber;
use Giovanni::Data::NcFile;
use Giovanni::DataField;
use Getopt::Long;
use XML::LibXML;
use File::Temp qw/ tempfile tempdir /;
use File::Basename;

# Specially written for this rescrubbing task:
# Contains code to run current scrubber and a subset of rescrubbing tasks:
use Giovanni::BoundsNetCDF4Scrubber;

use strict;

my $varInfo;
my $oldScrubbed;
my $freshlyDownloaded;
my $workingdir;
my $variable;

my $opts = GetOptions(
    "variable=s"           => \$variable,
    "varinfo=s"            => \$varInfo,
    "previouslyScrubbed=s" => \$oldScrubbed,
    "freshlydownloaded=s"  => \$freshlyDownloaded,
    "workingdir=s"         => \$workingdir
);

# If -h is specified, provide synopsis
die "$0\n"
    . " -variable 'Giovanni DataId'\n"
    . " -previouslyScrubbed 'A previously (incompletely) scrubbed file'\n"
    . " -freshlyDownloaded 'A file freshly downloaded from opendap ready for scrubbing'\n"
    . " -workingdir 'A temporary directory'\n"
    . " -varinfo 'A varinfo file'"

    if ( $variable eq ''
    or $oldScrubbed eq ''
    or $varInfo     eq ''
    or $workingdir  eq '' );

# This is the TEST
if ( thisFileAlreadyHastheNewBoundsandIsNetCDF4($oldScrubbed) ) {
    if ( !$ENV{DoNetCDF4} )
    {    # in case for some reason we want to process these
        print("$oldScrubbed  has already been processed");
        exit(0);
    }
}

# Action 1:
my $extra = runExtraScrubber( $workingdir, $varInfo, $oldScrubbed );

if ($freshlyDownloaded) {

    # Action 2:
    my $new = runScrubber( $workingdir, $varInfo, $freshlyDownloaded );

    # Action 3:
    my $status = reviewResults( $workingdir, $extra, $new );

    # Action 4:
    LogCompareResults( $variable, $extra, $new, $status );
}

sub LogCompareResults {
    my $variable = shift;
    my $file1    = shift;
    my $file2    = shift;
    my $status   = shift;
    my $data     = "";
    $file1 = basename($file1);
    $file2 = basename($file2);
    if ( $file1 ne $file2 ) {
        $data .= "files:$file1:$file2";
    }
    if ( $status eq "" ) {
        $status = 0;
    }

    my $logfile = $ENV{TMPDIR} . "/ExtraScrubbingValidation.log";
    if ( open( FILE, ">>", $logfile ) ) {
        print FILE "status:$status,$data\n";
        close(FILE);
    }
    else {
        die "\n\nUnable to open the log file: <$logfile> for append\n\n";
    }
}

# This should include the 'excludes'
sub reviewResults {
    my $workingdir = shift;
    my $renewed    = shift;
    my $new        = shift;
    my $test       = "ls -ltr  $workingdir";
    my @excludes   = ();
    print STDERR `$test`;

    if ( !$ENV{exclude_list} ) {
        die
            "\n\nERROR: Expecting a list of excludes such as: time/long_name,TempPrsLvls_D/long_name \n"
            . " to exist is a file referred to by \$ENV{exclude_list}\n\n";
    }
    if ( !-e $ENV{exclude_list} ) {
        if ( open( EFILE, '>', $ENV{exclude_list} ) ) {
            while (<DATA>) {
                print EFILE $_;
            }
            close EFILE;
        }
        else {
            die "Could not open " . $ENV{exclude_list} . " for write\n";
        }
    }

    if ( open( FILE, '<', $ENV{exclude_list} ) ) {
        while (<FILE>) {
            chomp;
            push @excludes, $_;
        }
        close FILE;
    }
    else {
        die "Could not open $ENV{exclude_list} for read";
    }

    my $status = Giovanni::Data::NcFile::diff_netcdf_files( $renewed, $new,
        @excludes );

    print "status: $status\n";
    return $status;
}

sub runExtraScrubber {
    my $workingDir  = shift;
    my $varInfoFile = shift;
    my $oldScrubbed = shift;    # is now already in workingdir
    my $dataFieldVarInfo
        = new Giovanni::DataField( MANIFEST => $varInfoFile );

    my $extraScrubber = new Giovanni::BoundsNetCDF4Scrubber(
        input      => $oldScrubbed,        # this is the file in the cache dir
        catalog    => $dataFieldVarInfo,
        workingdir => "$workingdir"

   # not using this now either output     => 'extra_' . basename($oldScrubbed)
    );

    my $outputfile = $extraScrubber->justNewScrubbing($oldScrubbed);

}

# This is our TEST:
# Is the file we are handed a candidate for what this script does:
sub thisFileAlreadyHastheNewBoundsandIsNetCDF4 {
    my $file = shift;

    my $latBndsAttrVal
        = Giovanni::Data::NcFile::get_value_of_attribute( $file, 'lat_bnds',
        'units' );
    chomp $latBndsAttrVal;
    if ( $latBndsAttrVal eq 'degrees_north' ) {
        return 1;
    }
    return 0;
}
