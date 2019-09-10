package Giovanni::Algorithm::AreaAveragerNco;

use 5.008000;
use strict;
use warnings;
use FileHandle;
use File::Basename;
use File::Copy;
use File::Temp;

#- use Giovanni::Algorithm::TimeAveragerNco;

our $VERSION = '0.02';

1;

=head1 NAME

Giovanni::Algorithm::AreaAveragerNco - Perl module for area averaging of a netCDF file

=head1 PROJECT

Agile Giovanni

=head1 SYNOPSIS

  use Giovanni::Algorithm::AreaAveragerNco;
  Giovanni::Algorithm::TimeAveragerNco::area_averager($infile, $outfile);

=head1 DESCRIPTION

The area averaging is performed over a region bounded by latitudes and longitudes.
All non-coordinate variables will be averaged.

=over 4

=item $infile

Input file path

=item $outfile

Output file path

=back

=head1 AUTHOR

Jianfu Pan, E<lt>jianfu.pan@nasa.govE<gt>

=cut

################################################################################
# $Id: AreaAveragerNco.pm,v 1.19 2015/02/13 20:00:55 dedasilv Exp $
# -@@@ ProjectNameGoesHere, $Name:  $
################################################################################

# -------------------------------------------------------------
# area_averager($infiles, $outfile, $dims, $vars, $dataday, $fillvalues, $bbox)
# Descriptions:
#   The algorithm is implemented with ncap2 operators
# Inputs:
#   $infiles - Input nc files list
#   $outfile - Output nc file
#   $dims    - Reference to dimension names array
#   $vars    - Reference to variable names array
#   $dataday - Name of dataday variable ["dataday","datamonth"]
#   $fillvalues - Fill values or missing values
#   $bbox    - Bounding box ("lonW,latS,lonE,latN")
#   $reso    - Spatial resolution
# -------------------------------------------------------------
sub area_averager {
    my ( $infiles, $outfile, $dims, $vars, $dataday, $fillvalues, $bbox,
        $reso )
        = @_;

    my ( $success, $fail ) = ( 1, 0 );

    my ( $fh, $nc_tmp )
        = File::Temp::tempfile( 'output_XXXXXX', SUFFIX => '.nc' );

    # --- Determine names of lat/lon dimensions ---

    my $lat;
    my $lon;
    if ( scalar(@$dims) == 2 ) {
        $lat = $dims->[0];
        $lon = $dims->[1];
    }
    elsif ( scalar(@$dims) == 3 ) {
        $lat = $dims->[1];
        $lon = $dims->[2];
    }
    else {
        warn "ERROR area_averager fail to recognize lat lon";
        return $fail;
    }

    # --- Parse bounding box ---
    $bbox =~ s/\s| //g;
    my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

    # Making sure they are floats
    $latS = "$latS.0" unless $latS =~ /\./;
    $latN = "$latN.0" unless $latN =~ /\./;
    $lonW = "$lonW.0" unless $lonW =~ /\./;
    $lonE = "$lonE.0" unless $lonE =~ /\./;

    # Setting lat/lon range to points if they are within resolution
    # isPoint: 0 (area), 1 (line), 2 (point)
    my $isPoint = 0;
    if ( abs( $latN - $latS ) < $reso ) {
        $latN = $latS;
        $isPoint++;
    }
    if ( abs( $lonE - $lonW ) < $reso ) {
        $lonE = $lonW;
        $isPoint++;
    }

    my $d_lat = "\"$lat,$latS,$latN\"";
    my $d_lon = "\"$lon,$lonW,$lonE\"";

    print STDERR "INFO Averaging area $d_lat, $d_lon\n";

    #
    # Concatenate files
    #

    # --- Creating local nc files by symlink for shorter file names ---
    my ( $infile_new, $symlinks ) = localize_files($infiles);

    # --- Concatenate files ---
    my $infile_stitched
        = concatenate_files( $infile_new, $nc_tmp, $d_lat, $d_lon );

    #
    # Do averaging
    #

    # Check stitched file and see if we got a point data
    # No need to do this if it's already determined to be a point
    my $foundPoint = 0;
    if ( $isPoint != 2 ) {
        my $lat_dump = `ncdump -v $lat $infile_stitched`;
        my ($lat_value) = ( $lat_dump =~ /data:\s+$lat = (.+);/msg );
        $foundPoint++ unless $lat_value =~ /,/;
        my $lon_dump = `ncdump -v $lon $infile_stitched`;
        my ($lon_value) = ( $lon_dump =~ /data:\s+$lon = (.+);/msg );
        $foundPoint++ unless $lon_value =~ /,/;
    }

    if ( $isPoint == 2 or $foundPoint == 2 ) {

        # We got a point data

        # Eliminate lat/lon dimensions
        `ncwa -a "$lat,$lon" -O $infile_stitched "$infile_stitched.ncwa"`;
        move( "$infile_stitched.ncwa", $infile_stitched );

        `ncpdq -U -O $infile_stitched $outfile`;
        die("ERROR ncpdq failed $!\n") if $?;

    }
    else {
        my $rc
            = do_area_average( $infile_stitched, $outfile, $vars, $fillvalues,
            $lat, $lon );

        # Copy back dataday into output
        if ($dataday) {
            `ncks -A -v $dataday -h $infile_stitched $outfile`;
            print
                "STDERR WARN Fail to restore dataday($dataday) (ncks -A -v $dataday -h $infile_stitched $outfile. $!)\n"
                if $?;
        }
    }

    #
    # Clean up tmp files
    #

    map { unlink($_) if ( -l $_ ) } @$symlinks;

    #-  unlink($infile_new);
}

sub do_area_average {
    my ( $infile, $outfile, $vars, $fillvalues, $lat, $lon ) = @_;

    my $nco_file = "area_averager.nco";

    #
    # Create nco scripts
    #

    # Construct nco scripts
    my @nco      = ();
    my @new_vars = ();
    foreach my $v (@$vars) {

        # Set up missing value matching
        # We avoid using != in masking when possible to avoid rounding
        my $miss_conservative;
        my $miss_op;

        #- my $miss = $fillvalues->{$v};
        my $miss = $fillvalues;
        if ( $miss > 0 ) {
            $miss_conservative = $miss - 0.1;
            $miss_op           = "<";
        }
        elsif ( $miss < 0 ) {
            $miss_conservative = $miss + 0.1;
            $miss_op           = ">";
        }
        else {
            $miss_conservative = $miss;
            $miss_op           = "!=";
        }
        $miss_conservative = "$miss_conservative."
            unless $miss_conservative =~ /\./;

        push @nco,
            "G_w_$v=($v $miss_op $miss_conservative)*cos($lat*acos(-1.)/180.);\n";
        push @nco, "G_d_$v=$v * G_w_$v;\n";
        push @nco,
            "G4_$v=G_d_$v.ttl(\$$lat,\$$lon) / G_w_$v.ttl(\$$lat,\$$lon);\n";
        push @new_vars, "G4_$v";
    }

    $nco_file = File::Temp::tempnam( '.', 'nco_script.' )
        or
        die("ERROR Cannot create temporary file for nco_script_XXXXXX.nco\n");
    open( FILE, ">$nco_file" )
        or die("ERROR Cannot write to temporary file $nco_file\n");
    print FILE @nco;
    close(FILE);
    warn("INFO Wrote nco script to $nco_file\n");

    # Run ncap2 command
    my $outfile_temp1
        = File::Temp::tempnam( '.', basename($outfile) . ".nc" );
    `ncap2 -S $nco_file -O -h $infile $outfile_temp1`;
    if ($?) {
        die("ERROR ncap2 failed $!\n");
        print "INFO ncap2 -S $nco_file -O -o $outfile_temp1 $infile";
    }

    # Clean up output file and save to destination
    my $outfile_temp = File::Temp::tempnam( '.', basename($outfile) . ".nc" );
    my $new_varlist = join( ',', @new_vars );
    `ncks -O -h -v "$new_varlist" $outfile_temp1 $outfile_temp`;
    foreach my $v (@$vars) {
        `ncrename -v G4_$v,$v $outfile_temp`;
    }
    `mv $outfile_temp $outfile`;

    return 1;
}

sub concatenate_files {
    my ( $infiles, $newfile, $d_lat, $d_lon ) = @_;

    my $cmd = "ncrcat -H -h -O -d $d_lat -d $d_lon $newfile < $infiles";

    #-   my $cmd = "ncrcat -h -O -d $d_lat -d $d_lon $newfile";
    #   open (CMD, "|$cmd") or die("ERROR Fail to open pipe to $cmd: $!");
    #   print CMD join("\n", @$infiles);
    #   close(CMD);

    `$cmd`;
    die("ERROR Failed concatenation: $!") if $?;

    return $newfile;
}

sub concatenate_files_old {
    my ( $infiles, $newfile, $d_lat, $d_lon ) = @_;

    `ncrcat -h -O -d $d_lat -d $d_lon @$infiles $newfile`;
    if ($?) {
        die("ERROR Failed to concatenate files");
    }

    return $newfile;
}

# ------------------------------------------------------------------
# localize_files($infiles)
# Modified from Chris' implementation of symlinks to input nc files,
# to reduce amount of text in file names passed to nco commands.
# -------------------------------------------------------------------
sub localize_files {
    my ($input_file) = @_;
    open( INPUT, "<$input_file" )
        or die("ERROR Failed to open input file $input_file $!");

    # Open a unique output file to write to
    my $base = File::Temp::tempnam( '.', 'aavg.' );
    my $infile_new = "$base.symlinks.txt";
    open( OUTPUT, ">$infile_new" )
        or die("ERROR Could not write to temporary file $infile_new $!");

    # Loop through input files, create symlink, add symlink to output file
    # The use of short symlink filenames gets around the file limit in ncra of
    # a total of 1 million bytes.
    my @files;
    my $i = 0;
    while (<INPUT>) {
        chomp;
        my $file = sprintf( "%s%05d.nc", $base, $i );
        $i++;
        if ( $file ne $_ ) {
            unless ( -e $file ) {
                symlink( $_, $file )
                    or die("ERROR Failed to symlink $_ to $file");
            }
            push @files, $file;    # Save list for cleanup
        }
        print OUTPUT "$file\n";
    }
    close INPUT;
    close OUTPUT;
    return ( $infile_new, \@files );
}

