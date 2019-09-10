#$Id: DimensionAverager.pm,v 1.19 2015/02/02 17:37:08 dedasilv Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::DimensionAverager;

use 5.008008;
use strict;
use warnings;
use File::Basename;
use File::Temp;
use Giovanni::Data::NcFile;

our $VERSION = '0.01';

# Preloaded methods go here.

1;

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::DimensionAverager - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Giovanni::DimensionAverager;
  $outfile = average_dimension($files, $vname, $bbox, $dimtype, $dt, $dir,$log,
                               $zname, $zvalue);
    Description: average_dimension() takes a list of input files in time
        sequence and creates a time series of dimension averaged data.
    Inputs:
        $files   : Array reference to a list of input files
        $vname   : Variable name
        $bbox    : Bounding box for region subsetting
        $dimtype : Dimension(s) to be averaged by dimension type ['lat','lon']
        $dt      : Time resolution ['daily', 'monthly', 'hourly','half-hourly']
        $dir     : Output directory
        $log     : Logger object
        $zname   : Z-dimension name for vertical slicing if there is one
        $zvalue  : Z-dimension value for vertical slicing
    Outputs:
        $outfile : Output file of the dimension averaged time series data.

=head1 DESCRIPTION

Stub documentation for Giovanni::DimensionAverager, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>

=cut

#####################################################################
# average_dimension($files, $vname, $bbox, $dimtype, $dt, $dir, $log,
#                   $zname, $zvalue)
# Inputs:
#   $files   - array object of list of input files
#   $vname   - variable name
#   $bbox    - bounding box
#   $dimtype - dimension type ['lat','lon']
#   $dt      - time resolution ['daily','monthly','hourly','half-hourly']
#   $dir     - output directory
#   $log     - logger object
#   $zname   - Z-dimension name for vertical slicing if there is one
#   $zvalue  - Z-value for vertical slicing
# Return: Result file name
#####################################################################
sub average_dimension {
    my ( $files, $vname, $bbox, $dimtype, $dt, $dir, $log, $zname, $zvalue )
        = @_;

    $dir = './' unless $dir;

    # Validate inputs
    unless ( scalar(@$files) > 0 ) {
        $log->info("average_dimension(): Empty file list");
        return undef;
    }

    unless ( $dimtype eq "lat" or $dimtype eq "lon" ) {
        $log->info("average_dimension(): Invalid dimension type ($dimtype)");
        return undef;
    }

    unless ( $dt eq "daily"
        or $dt eq "monthly"
        or $dt eq "hourly"
        or $dt eq "3-hourly"
        or $dt eq "half-hourly" )
    {
        $log->info("average_dimension(): Invalid time resolution ($dt)");
        return undef;
    }

    unless ( -d $dir ) {
        $log->info("average_dimension(): Directory doesn't exist ($dir)");
        return undef;
    }

    #- TDB Handle null $log

    my ( $first_file, $last_file ) = ( $files->[0], $files->[-1] );
    my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

    #
    # Create outfile name
    #

    my $outfile
        = create_outfile_name( $first_file, $last_file, $bbox, $zvalue,
        $dir );

    #
    # Do dimension averaging on all files
    #

    my $files_avg
        = do_average( $files, $bbox, $zname, $zvalue, $dimtype, $log );

    #
    # Filling in gaps
    #

    my $current_time = undef;
    my $current_file = undef;
    my @files_filled = ();
    foreach my $f (@$files_avg) {

        # Get file's time values
        my $times = get_time( $f, $log );
        unless ( defined($times) ) {
            $log->error("Fail to get time in file $f");
            return undef;
        }

        # Check for time gap
        my $n_missing_steps = time_gaps( $current_time, $times->[0], $dt );

        # Insert fill fields if gap exists
        for ( my $i = 0; $i < $n_missing_steps; $i++ ) {

            # Make a copy of the current file
            `cp $current_file $current_file.$i.tmp`;

            # Get time value for the filled field
            my $time_i = add_time( $current_time, $i + 1, $dt );

            # Set variable to fill and time to new time
            `ncap2 -O -h -s "$vname(:,:)=$vname.get_miss();time(0)=$time_i;" $current_file.$i.tmp $current_file.$i`;
            if ($?) {
                $log->error(
                    "ncap2 failed (ncap2 -O -h -s \"$vname(:,:)=$vname.get_miss();time(0)=$time_i;\" $current_file.$i.tmp $current_file.$i)"
                );
                return undef;
            }

            #unlink("$current_file.$i.tmp");

            # Append the filled file to the list
            push( @files_filled, "$current_file.$i" );
        }

        # Append the current file
        push( @files_filled, $f );
        $current_time = $times->[-1];
        $current_file = $f;
    }

    #
    # Concatenate files into timeseries
    #

    my $rc = concatenate_files( $outfile, \@files_filled, $log );
    unless ($rc) {
        $log->error("Concatenating files failed");
        return undef;
    }

    #
    # Clean up the output file
    #

    my ( $fh_outfile_tmp, $outfile_tmp ) = File::Temp::tempfile();
    `ncks -3 -h -O -v $vname,time $outfile $outfile_tmp`;
    unless ($?) {
        `mv $outfile_tmp $outfile`;
    }

    #
    # Fix attributes
    #

    # Global attributes

    my $end_time = `ncks -M $files->[-1] | grep end_time`;
    unless ($?) {
        ($end_time) = ( $end_time =~ /value\s*=\s*(\d\d\d\d-.+Z)/ );
        `ncatted -O -h -a "end_time,global,o,c,$end_time" $outfile`;
    }

    # Variable attributes: z_slice and z_slice_type
    if ( defined($zvalue) ) {
        my $ztype = "unknown";
        $ztype = "pressure" if $zvalue =~ /hPa$/;
        `ncatted -h -O -a "z_slice,$vname,o,c,$zvalue" $outfile`;
        `ncatted -h -O -a "z_slice_type,$vname,o,c,$ztype" $outfile`;
    }

    return $outfile;
}

# add_time($t0, $n, $dt)
# Advance time by adding $n units on base time $t0.
# Inputs:
#   $t0  - Base time in seconds
#   $n   - Number of time steps to add
#   $dt  - Time resolution ['daily','monthly','hourly','half-hourly']
# Return:
#   New time in seconds
sub add_time {
    my ( $t0, $n, $dt ) = @_;
    if ( $dt eq "half-hourly" ) {
        return $t0 + 1800 * $n;
    }
    elsif ( $dt eq "hourly" ) {
        return $t0 + 3600 * $n;
    }
    elsif ( $dt eq "3-hourly" ) {
        return $t0 + 3600 * 3 * $n;
    }
    elsif ( $dt eq "daily" ) {
        return $t0 + 86400 * $n;
    }
    elsif ( $dt eq "monthly" ) {
        my $t_string = `date +"%Y,%m,%d,%H,%M,%S" -d \@$t0`;
        chomp($t_string);
        my ( $yr, $mm, $dd, $hr, $min, $sec ) = split( ',', $t_string );
        if ( ( $n % 12 ) == 0 ) {
            $yr += int( $n / 12 );
            my $t1 = `date -d "$yr-$mm-$dd $hr:$min:$sec" +%s`;
            chomp($t1);
            return $t1;
        }
        else {
            $mm += $n;
            $yr += int( $mm / 12 );
            $mm = ( $mm % 12 );
            my $t1 = `date -d "$yr-$mm-$dd $hr:$min:$sec" +%s`;
            chomp($t1);
            return $t1;
        }
    }
    else {
        return undef;
    }
}

###############################################################
# concatenate_files($outfile, $files, $log)
# Concatenates all files together to form a time series
# Inputs:
#   $files   : Array ref of files to be concatenated together
#   $log     : Logger object
# Outputs:
#   $outfile : Output file of the concatenated results
# Return:
#   1 - success    undef - fail
###############################################################
sub concatenate_files {
    my ( $outfile, $files, $log ) = @_;
    my ( $fh, $listfile ) = File::Temp::tempfile();
    foreach my $f (@$files) {
        print $fh "$f\n";
    }
    close($fh);

    `ncrcat -h -H -O $outfile < $listfile`;
    if ($?) {
        $log->error("Fail to concate (ncrcat -h -H -O $outfile < $listfile)");
        return undef;
    }

    return 1;
}

sub do_average {
    my ( $files, $bbox, $zname, $zvalue, $dimtype, $log ) = @_;

    # Parse bbox and make sure they are floats
    my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );
    $latS = "$latS.0" unless $latS =~ /\./;
    $latN = "$latN.0" unless $latN =~ /\./;
    $lonW = "$lonW.0" unless $lonW =~ /\./;
    $lonE = "$lonE.0" unless $lonE =~ /\./;

    # Snap tiny bbox to point
    my ( $rlat, $rlon )
        = Giovanni::Data::NcFile::spatial_resolution( $files->[0], 'lat',
        'lon' );
    $latN = $latS if abs( $latN - $latS ) < $rlat;
    $lonE = $lonW if abs( $lonE - $lonW ) < $rlon;

    # Construct area subsetting string (-d option)
    my $d_string = "-d lat,$latS,$latN -d lon,$lonW,$lonE";

    if ( defined($zname) and defined($zvalue) ) {
        $zvalue = "$zvalue.0" unless $zvalue =~ /\./;
        $d_string .= " -d $zname,$zvalue,$zvalue";
    }

    # Construct ncwa dimension average string (-a option)
    my $a_string = "";
    my $w_string = "";    # Weights option
    if ( $dimtype eq "lat" ) {

        # Need latitude weighting, the intermediagte weights variable
        # will be called wlat
        $w_string = "-w wlat";
        $a_string .= " -a lat";
    }
    elsif ( $dimtype eq "lon" ) {
        $a_string .= " -a lon";
    }
    else {
        $log->error("Invalid dimension type ($dimtype)");
        return undef;
    }

    # Perform averaging
    my @files_avg = ();
    foreach my $f (@$files) {
        my $f_new = basename($f) . ".avg";

        # Do a dimension subsetting first
        my $f_subset = basename($f) . ".subset";
        `ncks -O $d_string $f $f_subset`;
        if ($?) {
            $log->error(
                "ncks subsetting failed (ncks -O $d_string $f $f_subset)");
            return undef;
        }

        my $cmd = "";
        if ($w_string) {
            `ncap2 -h -O -s "wlat=cos(lat*0.0174532925)" $f_subset $f_new.tmp`;
            if ($?) {
                $log->error(
                    "Fail to create latitude weights: ncap2 -A -s \"wlat=cos(lat*0.0174532925)\" $f_subset $f_new.tmp"
                );
                return undef;
            }

       #- $cmd = "ncwa -h -O $d_string $w_string $a_string $f_new.tmp $f_new";
            $cmd = "ncwa -h -O $w_string $a_string $f_new.tmp $f_new";
        }
        else {

            #-  $cmd = "ncwa -h -O $d_string $a_string $f_subset $f_new";
            $cmd = "ncwa -h -O $a_string $f_subset $f_new";
        }
        $log->info("dimension average cmd: $cmd");

        `$cmd`;
        if ($?) {
            $log->error("dimension average failed: $cmd");
            return undef;
        }
        unlink("$f_new.tmp") if -f "$f_new.tmp";

        push( @files_avg, $f_new );
    }

    return \@files_avg;
}

# time_gaps($t0, $t1, $dt)
# Compute number of missing time steps between $t0 and $t1
# Inputs:
#   $t0  - time value 1 in seconds
#   $t1  - time value 2 in seconds
#   $dt  - time resolution ['daily','monthly','hourly','half-hourly']
# Return:
#   On success: number of time steps in between
#   On failure: undef
sub time_gaps {
    my ( $t0, $t1, $dt ) = @_;

    # Time t1 is the first time point if t0 is undefined
    return 0 unless defined($t0);

    # Time difference in seconds
    my $t_diff = $t1 - $t0;
    return 0 if $t_diff <= 0;

    # Figure out time gaps
    my $n = 0;
    if ( $dt eq "daily" ) {
        $n = int( $t_diff / 86400 ) - 1 if $t_diff >= 86400;
    }
    elsif ( $dt eq "half-hourly" ) {
        $n = int( $t_diff / 1800 ) - 1 if $t_diff >= 1800;
    }
    elsif ( $dt eq "hourly" ) {
        $n = int( $t_diff / 3600 ) - 1 if $t_diff >= 3600;
    }
    elsif ( $dt eq "3-hourly" ) {
        $n = int( $t_diff / ( 3600 * 3 ) ) - 1 if $t_diff >= ( 3600 * 3 );
    }
    elsif ( $dt eq "monthly" ) {
        my $ym0 = `date +"%Y%m" -d \@$t0`;
        my $ym1 = `date +"%Y%m" -d \@$t1`;
        chomp($ym0);
        chomp($ym1);
        return undef if $ym0 !~ /\d\d\d\d\d\d/ or $ym1 !~ /\d\d\d\d\d\d/;

        my $yr0     = int( $ym0 / 100 );
        my $yr1     = int( $ym1 / 100 );
        my $mm0     = ( $ym0 % 100 );
        my $mm1     = ( $ym1 % 100 );
        my $yr_diff = $yr1 - $yr0;
        $yr_diff = 0 unless $yr_diff > 0;
        my $mm_diff = $mm1 - $mm0 - 1;
        $n = $yr_diff * 12 + $mm_diff;
    }
    else {
        return undef;
    }

    return $n;
}

# get_time($file, $log)
# Extract time value in nc file
# Inputs:
#   $file - nc file that contains a time dimension
#   $log  - logger
# Return:
#   Array reference of time values
sub get_time {
    my ( $file, $log ) = @_;
    my @times = `ncks -H -v time $file`;
    if ( $? or scalar(@times) < 1 ) {
        $log->error(
            "ncks failed (ncks -H -v time $file) or file does not contain time"
        );
        return undef;
    }
    chomp(@times);

    # Remove last empty line
    pop(@times) if $times[-1] eq '';

    # Extrace time values only
    for ( my $k = 0; $k < scalar(@times); $k++ ) {
        $times[$k] =~ s/^.+=\s*|\s*$//g;
    }

    return \@times;
}

sub create_outfile_name {
    my ( $first_file, $last_file, $bbox, $zvalue, $dir ) = @_;
    my $f0 = basename($first_file);
    my $f1 = basename($last_file);

    my ( $prefix0, $ds0, $T0, $f0_parts ) = split( '\.', $f0, 4 );
    my ( $prefix1, $ds1, $T1, $f1_parts ) = split( '\.', $f1, 4 );
    my ( $T0start, $T0end ) = split( '-', $T0 );
    my ( $T1start, $T1end ) = split( '-', $T1 );
    $T1end = $T1start unless $T1end;

    # Create bbox string as part of file name
    my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

    # Remove decimal digits
    my $foo;
    ( $lonW, $foo ) = split( '\.', $lonW, 2 );
    ( $lonE, $foo ) = split( '\.', $lonE, 2 );
    ( $latS, $foo ) = split( '\.', $latS, 2 );
    ( $latN, $foo ) = split( '\.', $latN, 2 );

    my $bbox_string = "";
    if ( $lonW < 0 ) {
        $bbox_string = abs($lonW) . "W";
    }
    else {
        $bbox_string = $lonW . "E";
    }
    if ( $latS < 0 ) {
        $bbox_string .= "_" . abs($latS) . "S";
    }
    else {
        $bbox_string .= "_" . $latS . "N";
    }
    if ( $lonE < 0 ) {
        $bbox_string .= "_" . abs($lonE) . "W";
    }
    else {
        $bbox_string .= "_" . $lonE . "E";
    }
    if ( $latN < 0 ) {
        $bbox_string .= "_" . abs($latN) . "S";
    }
    else {
        $bbox_string .= "_" . $latN . "N";
    }

    my $out_name;
    if ($zvalue) {
        $out_name
            = "dimensionAveraged.$ds0-$zvalue.$T0start-$T1end.$bbox_string.$f0_parts";
    }
    else {
        $out_name
            = "dimensionAveraged.$ds0.$T0start-$T1end.$bbox_string.$f0_parts";
    }
    return "$dir/$out_name";
}
