#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(dirname);
use File::Temp qw(tempfile);
use Getopt::Std;
use File::Copy;
use Giovanni::Algorithm::TimeAveragerNco;
use Giovanni::Data::NcFile;
use Giovanni::ScienceCommand;

main();

sub main {
    print STDERR "USER_INFO Launching Time Averaged Map Service\n";

    #   Parse command line arguments with getopt
    #   -----------------------------------------
    use vars
        qw($opt_b $opt_s $opt_e $opt_f $opt_o $opt_v $opt_z $opt_S $opt_l $opt_z $opt_L );
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
    my $out_dir       = dirname($opt_o);
    my $zslice        = $opt_z;
    my $shapefile     = $opt_S;
    my $localizeFiles = $opt_L;

    #   Get the spatial resolution from the first file
    #   -----------------------------------------------
    my ( $lat_res, $lon_res )
        = Giovanni::Data::NcFile::spatial_resolution( $file_list[0], "lat",
        "lon" );
    if ( !defined $lat_res || !defined $lon_res ) {
        die "Unable to read spatial resolutions from $file_list[0]";
    }

    #   Make call to Giovanni::Algorithm::TimeAveragerNco
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

    #   Move its output to the path in supplied in -o
    #   ---------------------------------------------
    move( $temp_output, $out_file );
    add_resolution_attributes( $lat_res, $lon_res, $out_file );

    # TODO: remove this when we scrub the valid_range
    my $cmd = "ncatted -a valid_range,,d,, -O -o $out_file $out_file";
    my $rc  = system($cmd);

    warn "INFO ncatted call ($cmd) to remove valid_range returned $rc\n";

    # Remove time_bnds variable for now
    $cmd = "ncks -O -x -v time_bnds $out_file $out_file";
    $rc  = system($cmd);
    die "Unable to remove time bounds: $cmd" if $rc != 0;
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

sub add_resolution_attributes {
    my ( $latres, $lonres, @files ) = @_;

    for my $file (@files) {
        Giovanni::Data::NcFile::add_resolution_attributes( $file, $latres,
            $lonres );
        print "Added ($latres, $lonres) resolution to $file";
    }
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

g4_time_avg.pl - time average of a variable.

=head1 SYNOPSIS

g4_time_avg.pl 
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

=item -z zDimName=zValUnits

Horizontal slice to extract from 3-D data, 
e.g., "-z TempPrsLvls_A=500hPa" for the 500 hPa level.

=item -L

If set, then create a subdirectory with symlinks to reduce the size of the filenames fed to ncra.

=back

=head1 EXAMPLE

g4_time_avg.pl -b -180.0,-50.0,180,50 -s 2005-01-01T00:00:00Z -e 2005-01-05T23:59:59Z -v TRMM_3B42_daily_precipitation_V7 -f ./files1iZyd.txt -o timeAvgMap.TRMM_3B42_daily_precipitation_V7.20050101-20050105.180W_50S_180E_50N.nc

=head1 AUTHOR

Daniel da Silva, NASA/GSFC/Telophase

=cut
