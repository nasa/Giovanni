#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use File::Temp qw(tempfile);
use Getopt::Std;
use File::Copy;
use Giovanni::Algorithm::TimeAveragerNco;
use Giovanni::Data::NcFile;
use Giovanni::ScienceCommand;
use Giovanni::Algorithm::DimensionAverager;
use Giovanni::Logger;
use Giovanni::Algorithm::Wrapper qw(update_coordinates);

main();

sub main {
    print STDERR "USER_INFO Launching Zonal Mean Service\n";

    #   Parse command line arguments with getopt
    #   -----------------------------------------
    use vars
        qw($opt_b $opt_s $opt_e $opt_f $opt_o $opt_v $opt_z $opt_S $opt_l $opt_z $opt_L);
    getopts("b:s:e:f:o:v:z:S:l:");

    die "ERROR -b missing" if !defined $opt_b;
    die "ERROR -s missing" if !defined $opt_s;
    die "ERROR -e missing" if !defined $opt_e;
    die "ERROR -f missing" if !defined $opt_f;
    die "ERROR -o missing" if !defined $opt_o;
    die "ERROR -v missing" if !defined $opt_v;

    #   Declare variables from command line arguments
    #   ---------------------------------------------
    my $var_name      = $opt_v;
    my @file_list     = read_file_list($opt_f);
    my $bbox          = $opt_b;
    my $start_time    = $opt_s;
    my $end_time      = $opt_e;
    my $out_file      = $opt_o;
    my $out_dir       = File::Basename::dirname($opt_o);
    my $zslice        = $opt_z;
    my $shapefile     = $opt_S;
    my $localizeFiles = $opt_L;

    #   Setup logger
    #   -----------------------------------------------

    my $logger = Giovanni::Logger->new(
        session_dir       => $out_dir,
        manifest_filename => $out_file
    );

    #   First merge/average by time
    #   -------------------------------------------------
    my $cropped_list
        = Giovanni::Util::cropRecordsByTime( \@file_list, $start_time,
        $end_time );
    my $cropped_list_file = create_text_listfile($cropped_list);
    my $var_info_file     = create_var_info_file($var_name);
    my $shapefile_arg     = defined($shapefile) ? "-S $shapefile" : "";

    my $temp_output = Giovanni::Algorithm::TimeAveragerNco::time_averager(
        $out_dir,       $out_file,   $cropped_list_file,
        $var_name,      $start_time, $end_time,
        $bbox,          $zslice,     undef,
        $localizeFiles, $shapefile_arg
    );

    #   Then average the resulting time-averaged file by longitude
    #   -------------------------------------------------
    # Parse bounding box
    $bbox =~ s/\s| //g;
    my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

    # Make sure they are floats
    $latS = "$latS.0" unless $latS =~ /\./;
    $latN = "$latN.0" unless $latN =~ /\./;
    $lonW = "$lonW.0" unless $lonW =~ /\./;
    $lonE = "$lonE.0" unless $lonE =~ /\./;
    my $lonW_tmp = $lonW;
    my $lonE_tmp = $lonE;

    # Do longitude averaging subsetting first
    my $temp_subset_1 = File::Basename::basename($temp_output) . ".subset";
    my $temp_output_1 = File::Basename::basename($temp_output) . ".avg";

    my $cmd;
    my $rc;

# Shift longitude by 360 if bbox crosses the dateline. Longitude gets averaged out
# at the next step, so we don't anticipate any problems down the road.
    if ( $lonW > $lonE ) {
        $lonE_tmp = sprintf( "%#f", $lonE_tmp + 360. );
        $cmd
            = qq(ncap2 -O -s 'where(lon<0) lon=lon+360.0' $temp_output $temp_output);
        $rc = Giovanni::Data::NcFile::run_command( $cmd, 1 );
        if ( !$rc ) {
            return undef;
        }
    }

    # Construct area subsetting string (-d option)
    my $d_string = "-d lat,$latS,$latN -d lon,$lonW_tmp,$lonE_tmp";
    my $subset   = Giovanni::Algorithm::DimensionAverager::compute_subset_lon(
        $d_string, $temp_output, $temp_subset_1, $temp_output_1 );
    if ($?) {
        $logger->error(
            "ncks subsetting failed (ncks -O $d_string $temp_output $temp_subset_1 $temp_output_1)"
        );
        return undef;
    }

    #   Move its output to the path in supplied in -o
    #   ---------------------------------------------
    move( $temp_output_1, $out_file );

    # Remove time and lon dimensions
    # Handle NCO averaging bug that forgets to remove degenerate dimensions
    # from 'coordinates' preventing removal of time/lon
    update_coordinates($out_file);
    $cmd = "ncks -x -v lon,time -O $out_file $out_file";
    $rc  = system($cmd);
    warn "INFO ncks call ($cmd) to remove lon dimensions returned $rc\n";

    # TODO: remove this when we scrub the valid_range
    $cmd = "ncatted -a valid_range,,d,, -O -o $out_file $out_file";
    $rc  = system($cmd);

    warn "INFO ncatted call ($cmd) to remove valid_range returned $rc\n";

    # Remove time_bnds and lon_bnds variables
    $cmd = "ncks -O -x -v time_bnds,lon_bnds $out_file $out_file";
    $rc  = system($cmd);
    warn
        "INFO ncks call ($cmd) to remove time_bnds and lon_bnds returned $rc\n"
        ;
}

sub read_file_list {
    my ($file_name) = @_;
    my @file_list;

    open( IN_FILE, "$file_name" ) || die("Unable to open $file_name");

    for my $line (<IN_FILE>) {
        chomp($line);
        push( @file_list, $line );
    }

    close(IN_FILE);

    return @file_list;
}

sub create_var_info_file {
    my ($var_name) = @_;
    my ( undef, $fname ) = tempfile( UNLINK => 1, SUFFIX => ".txt" );

    open( OUT, ">$fname" )
        || die "Cannot open tempfile in write mode: $fname";
    print OUT "$var_name\n";
    close(OUT);

    return $fname;
}

sub create_text_listfile {
    my ($files) = @_;
    my $listfile_content = "";

    foreach my $f (@$files) {
        $listfile_content .= "$f\n";
    }

    my $listfile = "in_time_averager.$$.txt";
    open( FH, ">$listfile" ) || die;
    print FH "$listfile_content";
    close(FH);

    return $listfile;
}

=head1 NAME

g4_zonal.pl - Zonal mean plot of a variable.

=head1 SYNOPSIS

g4_curtain_lat.pl 
  -f input_file 
  -s start_time -e end_time 
  -v varname
  -o outfile
  -b bbox
  [-z zdim=zValunits]
  [-S shapefile_info]
  [-L]

=head1 ARGUMENTS

=over 4

=item -f input_file

Pathname of the file containing all the input data files as a simple text list.

=item -s start_time

Start date/time in ISO 8601 format.

=item -e end_time

End date/time in ISO 8601 format.

=item -o outfile

Output filename.

=item -b bbox

Bounding box, in a comma-separated string (W,S,E,N). 

=item -S shapeinfo

Shape information:  shapefile/shape_id.

=item -v varname

Name of the variable.

=item -L

If set, then create a subdirectory with symlinks to reduce the size of the filenames fed to ncra.

=item -z zDimName=zValUnits

Horizontal slice to extract from 3-D data, 
e.g., "-z TempPrsLvls_A=500hPa" for the 500 hPa level.
This is input in the form of an xml file.

=back

=head1 EXAMPLE

g4_zonal.pl -b -180.0,-5,180,5 -s 2015-01-01T00:00:00Z -e 2015-04-30T23:59:59Z -v MAIMCPASM_5_2_0_RH -f files.txt -o dimensionAveraged.MAIMCPASM_5_2_0_RH.20150101-20150430.180W_5S_180E_5N.nc -l lineage.txt

=head1 AUTHOR

Maksym Petrenko, NASA/GSFC/ADNET

=head1 ACKNOWLEDGEMENTS

Based on 
g4_hov_lat.pl by Michael Nardozzi, NASA/GSFC
g4_time_avg.pl by Daniel da Silva, NASA/GSFC/Telophase

=cut

