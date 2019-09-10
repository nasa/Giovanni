#!/usr/bin/env perl

=head1 NAME

g4_area_avg_diff_time_series.pl - time series of area averages of differences between two variables

=head1 SYNOPSIS

g4_area_avg_diff_time_series.pl 
  -f input_file 
  -s start_time -e end_time 
  -x varname,zdim=zValunits  -y varname
  -u units,units,units_cfg
  [-o outfile] 
  [-b bbox]
  [-S shapefile_info]
  [-a ]

=head1 ARGUMENTS

=over 4

=item -f input_file

Pathname of the file containing all the input data files as a simple text list.

=item -s start_time

Start date/time in ISO 8601 format.

=item -e end_time

End date/time in ISO 8601 format.

=item -o outfile

Output filename

=item -b bbox

 Bounding box, in a comma-separated string (W,S,E,N). 

=item -S shapeinfo

Shape information:  shapefile/shape_id.  This is passed, untrammeled, to the subroutine.

=item -x, -y varname

Name of the variables to be differenced.

=item -z zDimName=zValUnits

Horizontal slice to extract from 3-D data, 
e.g., "-z TempPrsLvls_A=500hPa" for the 500 hPa level.

=item -a

Only calculate the average rather than all the statistics

=back

=head1 EXAMPLE

g4_area_avg_diff_time_series.pl -x AIRX3STD_006_Temperature_A,TempPrsLvls_D=850hPa -y AIRX3STD_006_Temperature_D,TempPrsLvls_D=850hPa -f files.txt -b -180,-90.,180.0,90 -o airs.nc

=head1 NOTE

This script will run about 20 times faster if not used with shapefiles and 'TS_THREADS' envvar is set. 

=head1 AUTHOR

Chris Lynnes, NASA/GSFC
Richard Strub, ADNET Systems

=cut

use strict;
use Getopt::Std;
use File::Basename;
use File::Temp qw/tempfile/;
use File::Copy;
use Date::Parse;
use DateTime;
use Giovanni::Util;
use Giovanni::Data::NcFile;
use Giovanni::Algorithm::Wrapper;
use Giovanni::Algorithm::AreaAvgDiff;
use threads;

# Define and parse argument vars
use vars
    qw($opt_b $opt_x $opt_y $opt_s $opt_e $opt_f $opt_o $opt_v $opt_z $opt_S $opt_l $opt_u $opt_a $opt_j);
getopts('b:x:y:s:e:f:o:z:v:S:l:u:j:a');

# Adapting for a single time series...
$opt_x = $opt_v if $opt_v;

# Use output file directory for temporary files as well
my $outdir = $opt_o ? dirname($opt_o) : '.';

my @timesteps;
my $new_var = $opt_y ? "difference" : $opt_x;

# parse variable/field args
my ( $nvars, $ra_vars, $ra_zdims, $ra_zvals )
    = parse_field_args( $opt_x, $opt_z, $opt_x, $opt_y );
my @vars  = @$ra_vars;
my @zdims = @$ra_zdims;
my @zvals = @$ra_zvals;

my @long_names;
my @coords = ( 'x', 'y' );

my @timesteps = ();
my $PIXELS = 0;

my $DEFAULT_SETSIZE = 200;
my $REPORT_GRID = undef;

# We don't do it the fast way if differencing
if ($opt_y) {

    @timesteps = original_oneatatime();

    # Concatenate into a time series
    concatenate_timesteps( $opt_o, \@timesteps );
    # set the adjusted data bounding box in .nc file 
    set_datagrid_info($REPORT_GRID,$opt_o) if $REPORT_GRID;
}
else {
    $PIXELS = bbox_size_test();
    my $zstring = handleZdimension( $ra_zdims, $ra_zvals );

    # For proper weighting, the shapeMask.nc needs to be the same size
    my $croppedMask = "croppedMask_" . $opt_v . ".nc";
    @timesteps = chunks_and_threads( $zstring, $croppedMask, $ra_zdims );
}

# Clean up intermediate files
unlink(@timesteps) unless ( exists $ENV{CLEANUP} && $ENV{CLEANUP} == 0 );

# Update long_name
my $new_long_name = "$long_names[1] minus $long_names[0]" if ($opt_y);
update_var_attrs( $opt_o, $new_var, $new_long_name ) if $new_long_name;

if ( !$opt_a )
{    # Only if all statistics are calculated; else we do not update long_name
    update_var_attrs( $opt_o, "min_" . $new_var, $new_long_name )
        if $new_long_name;
    update_var_attrs( $opt_o, "max_" . $new_var, $new_long_name )
        if $new_long_name;
    update_var_attrs( $opt_o, "stddev_" . $new_var, $new_long_name )
        if $new_long_name;
    update_var_attrs(
        $opt_o,
        "count_" . $new_var,
        "count of " . $new_long_name
    ) if $new_long_name;
}
exit(0);

sub bbox_size_test {
  unless ( open IN, $opt_f ) {
    warn "USER_ERROR Internal error on file read\n";
    die "ERROR failed to read input file $opt_f: $!\n";
  }
  my $samplefile = <IN>;
  close (IN);
  chomp ($samplefile);
  chomp ($samplefile);
  my ($latres, $lonres) = Giovanni::Data::NcFile::spatial_resolution( $samplefile);

  my $classic_bbox = $opt_b;
  my @coords = split(',', $classic_bbox);

  my $longth = abs($coords[2] - $coords[0]) * 1/($lonres) ;
  my $latth  = abs($coords[3] - $coords[1]) * 1/($latres);
  my $pixels = $longth * $latth;

  print STDERR "INFO: npixels: $pixels\n";
  return $pixels;
}

sub original_oneatatime {

    # Read in input text file of file pairs to be processed
    unless ( open IN, $opt_f ) {
        warn "USER_ERROR Internal error on file read\n";
        die "ERROR failed to read input file $opt_f: $!\n";
    }

    my $n = 0;
    my @ra_ncks;
    my @converters;
    my $times_are_different = 0;
    my $is_first_pair       = 1;
    foreach my $pair (<IN>) {
        chomp($pair);
        my @infiles = split( /\s+/, $pair );
        if ( $opt_u && !@converters ) {
            @converters = unit_converters( $opt_u, join( ',', @vars ), @infiles );
        }

        my %outfiles;

        # For each file in the pair:
        #   Subset bbox and z-slice (if appropriate) with ncks
        # But note: also works for the single var case
        my $outfile;
        foreach my $j ( 0 .. ( $nvars - 1 ) ) {

            # Get the longname from the info in the first data file
            $long_names[$j]
                = Giovanni::Data::NcFile::get_variable_long_name( $infiles[$j], 0,
                $vars[$j] )
                unless $long_names[$j];

            # ncks command plus args applied to all subsets (bbox, -O)
            unless ( $ra_ncks[$j] ) {
                my @ncks = subset_bbox_cmd( $opt_b, $infiles[$j] );
                $ra_ncks[$j] = \@ncks;
            }

            #  Subset by bbox and z dimension (if applicable)
            $outfile = subset_file(
                $infiles[$j], $outdir, $coords[$j], $ra_ncks[$j],
                $vars[$j], $zdims[$j], $zvals[$j]
            );

            # Convert units if applicable
            if ( $converters[$j] ) {
                $converters[$j]->ncConvert(
                    sourceFile      => $outfile,
                    destinationFile => $outfile
                );
            }

            # Rename to "difference" so that ncdiff will see same name in both files
            run_command( '', 'ncrename', '-v', "$vars[$j],$new_var", '-O', '-o',
                $outfile, $outfile )
                if $opt_y;

            $outfiles{ $coords[$j] } = $outfile;
        }
        my $timestep = "$opt_o.$n";

        # Comparison case
        my %variable_ids = ( 'x' => $ra_vars->[0] );
        if ($opt_y) {

            # if there are two variables, the y variable is $ra_vars->[1]
            $variable_ids{'y'} = $ra_vars->[1];

            # check the first pair of files to see if the time metadata
            # is different
            if ($is_first_pair) {
                $is_first_pair       = 0;
                $times_are_different = check_times(@infiles);
            }

            if ($times_are_different) {

                # move the times aside so they won't cause problems with ncdiff
                move_time_metadata(
                    [ $outfiles{'x'},     $outfiles{'y'} ],
                    [ $variable_ids{'x'}, $variable_ids{'y'} ]
                );
            }

            # Compute differences between the two files
            run_command( '', 'ncdiff', '-O', '-o', $timestep, $outfiles{'y'},
                $outfiles{'x'} );

            if ($times_are_different) {

                # Create a new time dimension variable
                add_in_time_dimension_variable( $timestep, $variable_ids{'x'},
                    $variable_ids{'y'}, $outfiles{'x'}, $outfiles{'y'} );

            }

            $outfile = $timestep;
        }

        # Compute the area average
        if ($opt_S) {
            compute_shapefile_area_average( $outfile, $timestep, $opt_a );
        }
        else {
            $REPORT_GRID = grab_datagrid_info($timestep) ; # This is the difference so there is only on lat lon.
            compute_area_average( $outfile, $timestep, $new_var, $opt_a );
        }

        if ($opt_y) {
            if ($times_are_different) {

                # Note: the x variable id is $ra_vars->[1] and the y variable id is
                # $ra_vars->[0].
                add_in_other_times( $timestep, $variable_ids{'x'},
                    $variable_ids{'y'}, $outfiles{'x'}, $outfiles{'y'} );
            }
            unlink( $outfiles{'y'} );
        }

        recover_pseudo_time_coord( $timestep, $outfiles{'x'} );
        unlink( $outfiles{'x'} );
        push @timesteps, $timestep;
        $n++;
    }

    return @timesteps;
}

# If the times for the two files were different, this code adds those time
# dimensions and bounds back into the file after averaging is over.
sub add_in_other_times {

    my ( $outfile, $opt_x, $opt_y, $x_file, $y_file ) = @_;

    # Ncdiff won't pull the new time variables over automatically. So
    # we have to add them back in.
    my @cmd
        = ( "ncks", "-h", "-A", "-v", "time_" . $opt_x, $x_file, $outfile, );
    run_command( "Add time_" . $opt_x . " back", @cmd );

    @cmd = ( "ncks", "-A", "-h", "-v", "time_" . $opt_y, $y_file, $outfile );
    run_command( "Add time_" . $opt_y . " back", @cmd );
}

# If the times for the two files were different, then this code moved each
# variables time information aside before doing the diff. Now we need to
# reconstitude a time dimension variable.
sub add_in_time_dimension_variable {
    my ( $diff_file, $x_opt, $y_opt, $x_file, $y_file ) = @_;

    # Determine whether or not the two variables have the same time dimension
    # variable values: 1. Get out the original time dimension varible values
    # for the two variables
    my @xtimes = Giovanni::Data::NcFile::get_variable_values( $x_file,
        "time_" . $x_opt );
    my @ytimes = Giovanni::Data::NcFile::get_variable_values( $y_file,
        "time_" . $y_opt );

    # Now create an ncap2 script that will add in the new time dimension
    # variable.
    my @ncap2_script = ();

    # Create a time variable of type int. (Initializing the variable to '0'
    # sets the type. If I'd used '0.0', time would be type double.)
    push( @ncap2_script, "time[time]=0;" );

    if ( $xtimes[0] == $ytimes[0] ) {

        # If both variables have the same time dimension value, then just
        # copy one of the old time variables over.
        # copy the time values over

        push( @ncap2_script, "time(0)=" . $xtimes[0] . ";" );

    }
    else {

        # If the variables have two different times, then use the lower
        # bounds value of one of the variables. (They should be the same value
        # because that is how we pair.)
        my @bnds = Giovanni::Data::NcFile::get_variable_values( $x_file,
            "time_bnds_" . $x_opt );

        # There should be two bounds values. We want the lower one, which is
        # the first one
        push( @ncap2_script, "time(0)=" . $bnds[0] . ";" );

    }

    # set the units and standard name
    push( @ncap2_script,
        qq(time\@units="seconds since 1970-01-01 00:00:00";) );
    push( @ncap2_script, qq(time\@standard_name="time";) );

    # write out the ncap2 script
    my ( $fh, $ncap_file )
        = tempfile( "add_time_variable_XXXX", SUFFIX => '.ncap2' );
    print STDERR "INFO: ncap2 script to add back time variable:\n";
    for my $line (@ncap2_script) {
        print STDERR "INFO:   $line\n";
        print $fh "$line\n";
    }
    close($fh);

    # call ncap2
    my @cmd = ( "ncap2", "-O", "-S", $ncap_file, $diff_file, $diff_file );
    run_command( "Adding times back into difference file", @cmd );

    # remove the ncap2 script
    unlink($ncap_file);
}

# This moves the time metadata into new variables so that when files are
# combined, the metdata is not lost.
#
sub move_time_metadata {
    my ( $files, $ids ) = @_;

    for ( my $i = 0; $i < scalar(@$files); $i++ ) {
        my $file = $files->[$i];
        my $id   = $ids->[$i];

        # 1. Create a new variable called time_$id with the time dimension
        #    variable value.
        my @cmd = ( "ncap2", "-s", "time_$id=time;", "-O", $file, $file );
        run_command( "Creating new time variable time_$id", @cmd );

        # 2. Remove time dimension variable
        @cmd = ( "ncks", "-h", "-x", "-C", "-O", "-v", "time", $file, $file );
        run_command( "Removing time dimension variable", @cmd );

        # 3. Rename time_bnds variable
        @cmd = ( "ncrename", "-h", "-O", "-v", "time_bnds,time_bnds_$id",
            $file );
        run_command( "Renaming time bounds to identify with variable $id",
            @cmd );

        # 4. Change long name attribute for time_$id
        @cmd = (
            "ncatted", "-h", "-O", "-a",
            "long_name,time_$id,o,c,Time for $id", $file
        );
        run_command( "Changing long_name attribute for time_$id", @cmd );

        # 5. Modify bounds attribute of time_$id variables to associate it
        #    with the new bounds variable
        @cmd = (
            "ncatted", "-h", "-O", "-a", "bounds,time_$id,o,c,time_bnds_$id",
            $file
        );
        run_command( "Associating renamed time bounds with new time variable",
            @cmd );
    }
}

# Figure out if we need to handle time and the time_bnds carefully because they
# are different
sub check_times {
    my @files = @_;

    # use hashes to keep track of the unique start times, end times, and
    # time values
    my %start_set = ();
    my %end_set   = ();
    my %time_set  = ();
    for my $file (@files) {
        my ($att_hash) = Giovanni::Data::NcFile::global_attributes($file);
        $start_set{ $att_hash->{start_time} } = 1;
        $end_set{ $att_hash->{end_time} }     = 1;
        my @times
            = Giovanni::Data::NcFile::get_variable_values( $file, 'time' );

        # Convert the time to an integer since we don't handle sub-seconds.
        # This makes sure we don't run into silly issues with things like
        # '1' not being the same as '1.0'.
        $time_set{ int( $times[0] ) } = 1;
    }

    # see how many keys there are in our hashes
    if ( scalar( keys(%start_set) ) > 1 ) {
        return 1;
    }
    if ( scalar( keys(%end_set) ) > 1 ) {
        return 1;
    }
    if ( scalar( keys(%time_set) ) > 1 ) {
        return 1;
    }
    return 0;

}

sub concatenate_timesteps {
    my ( $outnc, $timestep_nc, $zdims ) = @_;
    my $file_list = "$outnc.files";

    # Write the files to a list for feeding in via stdin
    if ( !open FILE_LIST, '>', $file_list ) {
        die "ERROR Cannot write to file list $file_list\n";
    }
    foreach my $timestep_file (@$timestep_nc) {
        print FILE_LIST "$timestep_file\n";
    }
    close FILE_LIST;
    run_command( '', "ncrcat -O -o $opt_o < $file_list" );

    # This removes the coordinate variables (not the dimensions
    # themselves) so that a later ncks -A mask.nc target.nc
    # will work
    run_command( '', "ncks -C -x -v lat,lon -O -o $opt_o $opt_o" );

    # If there is a z dim, we need to delete it. Otherwise
    # area_avg_scatter will fail in visualization...
    if ( $zdims and $zdims[0] ne 'NA' ) {
        foreach my $dim (@$zdims) {
            run_command( "Removing vertical dimension: $dim",
                "ncwa -O -a $dim $opt_o $opt_o" );
        }
    }

}

# TODO add to a package (which?)
sub recover_pseudo_time_coord {
    my ( $outfile, $source ) = @_;
    my $hdr = `ncdump -h $source`;
    my $recover;
    if ( $hdr =~ /int dataday\(/ ) {
        $recover = 'dataday';
    }
    elsif ( $hdr =~ /int datamonth\(/ ) {
        $recover = 'datamonth';
    }
    else {
        return 1;
    }
}

sub parse_field_args {
    my ( $v_arg, $z_arg, $x_arg, $y_arg ) = @_;
    my ( @vars, @zdims, @zvals, @zinfo );

    # Comparison case: -x var1,zdim1=123hPa -y var2,zdim2=456hPa
    if ($y_arg) {
        for my $arg ( $x_arg, $y_arg ) {
            my ( $var, $zinfo ) = split( ",", $arg );
            push @vars, $var;
            push @zinfo, ( $zinfo ? $zinfo : 'NA' );
        }
    }

    # Single variable case: -v foo -z zdim=123hPa
    else {
        push @vars,  $v_arg;
        push @zinfo, $z_arg;
    }
    my $nvars = scalar(@vars);

    # For all of the variables, parse out z info
    # Put NA in each one so we don't inadvertently collapse one array
    foreach my $j ( 0 .. ( $nvars - 1 ) ) {
        my ( $zdim, $zval, $zunits ) = ( 'NA', 'NA', 'NA' );
        if ( $zinfo[$j] && ( $zinfo[$j] ne 'NA' ) ) {
            ( $zdim, $zval, $zunits )
                = ( $zinfo[$j] =~ m/(\w+)=([\d\.\-]+)(\w+)/ );
        }
        push @zdims, $zdim;
        push @zvals, $zval;
    }
    return ( $nvars, \@vars, \@zdims, \@zvals );
}

sub subset_file {
    my ( $infile, $outdir, $which, $ra_ncks, $var, $zdim, $zval ) = @_;

    # Form output filename:  foo.x.nc, foo.y.nc
    my ( $outbase, $dir, $suffix ) = fileparse( $infile, '.nc' );
    my $outfile = "$outdir/$outbase.$which$suffix";

    # Add z-slicing if needed
    my @z_subset;
    if ( $zval ne 'NA' ) {
        @z_subset = ( '-d', sprintf( "%s,%f,%f", $zdim, $zval, $zval ) );
    }

    # Now run the subsetter
    run_command( '', @$ra_ncks, @z_subset, '-o', $outfile, $infile );

    # Remove the z dimension, no longer needed in the subset
    run_command( '', 'ncwa', '-a', $zdim, '-O', '-o', $outfile, $outfile )
        if ( $zdim ne 'NA' );
    return $outfile;
}

sub update_var_attrs {
    my ( $file, $var, $long_name ) = @_;
    my @cmd = (
        'ncatted', '-O', '-o', $file, '-a',
        'long_name,' . $var . ',o,c,' . $long_name, $file
    );
    run_command( '', @cmd );
}

sub unit_converters {
    my ( $units, $vars, @infiles ) = @_;

    # Get converter objects
    warn "INFO Convert $vars to $units\n";
    my @converters
        = Giovanni::Algorithm::Wrapper::setup_units_converters( $units, $vars,
        \@infiles );
    return @converters;
}

# ---------------------------------------------------------
# These subroutines are supporting  NCO use record dim timeseries
# (the 'new' version)
sub chunks_and_threads {
    my $zstring     = shift;
    my $croppedMask = shift;
    my $zdims       = shift;

    # Each thread does 200 files at once - how NCO was crafted to run - why we add a time/record dimension
    my ( $divided_files, $gridMasterFile ) = get_files( $opt_f, $opt_v );

    my @cmds     = ();
    my $cmd_bbox = create_cmd_bbox( $zstring, $croppedMask, $gridMasterFile );
    my $cmd      = 'ncrcat -h ' . $cmd_bbox;

    my ( $subsetcmds, $wtscmds, $aavgcmds, $timesteps, 
         $cropping, $dtypeCnv) = collect_cmds( $cmd, $divided_files, 
         $croppedMask, $gridMasterFile );

    # If TS_THREADS is defined it runs this many threads at once
    # if 22000 time steps then / 200 is 110 jobs but it will only
    # run TS_THREADS at a time.
    # If TS_THREADS is not defined, then
    $opt_j =  1 if (! $opt_j) ;
    if ($opt_S) {
            do_threads( $subsetcmds, "Subsetting" );
            do_threads( $wtscmds,    "Mask preparation", "mask_prep1" );
            do_threads( $cropping,   "Mask preparation", "mask_prep2" );
            do_threads( $dtypeCnv,   "Converting to double" );
            do_threads( $aavgcmds,   "Mask averaging" );
    }
    else {
            do_threads( $subsetcmds, "Subsetting" );
            do_threads( $wtscmds,    "Weighting" );
            my $has_latlonvalues = $timesteps->[0]; 
            $has_latlonvalues =~ s/_avg.nc/_weighted.nc/;
            $REPORT_GRID = grab_datagrid_info($has_latlonvalues);
            do_threads( $aavgcmds,   "Averaging" );
    }

    concatenate_timesteps( $opt_o, $timesteps, $zdims );

    set_datagrid_info($REPORT_GRID,$opt_o) if $REPORT_GRID;
    cleanUp('latv','dim');
    cleanUp('lonv','dim');
    cleanUp('wlat','var');
    cleanUp('lat_bnds','var');
    cleanUp('lon_bnds','var');


    return @$timesteps;
}

# I take 2 functions here to manage threads
# One is to send a set of threads
# The other is to create the set and wait for them to finish.
# I am creating the whole set and waiting for all of them to finish
# before starting the next set because they are all doing the same thing
# and it keeps it simpler.
sub do_threads {
    my $subsetcmds  = shift;
    my $message     = shift;
    my $alternate   = shift || "run_command";
    my $max_threads = $opt_j || 7;
    my $n_tasks     = $#$subsetcmds + 1;
    my $this_set    = 0;
    my $i           = 0;
    my @cmds;

    while ( $#$subsetcmds >= 0 ) {
        push @cmds, shift @$subsetcmds;
        ++$i;
        if ( $#$subsetcmds < 0 or $i == $max_threads ) {
            $this_set += $i;
            launch_and_capture_threads( \@cmds, $message, $alternate, $n_tasks, $this_set );
            $i    = 0;
            @cmds = ();
        }
    }
}

# Launches a set of n threads and waits for them all to finish.
sub launch_and_capture_threads {
    my $subsetcmds = shift;
    my $message    = shift;
    my $procedure  = shift;
    my $n_tasks    = shift;
    my $this_set   = shift;

    my @threads;
    my $i = 0;
    foreach my $cmd (@$subsetcmds) {
        ++$i;
        my $step_message = qq($message on file sets $this_set of $n_tasks);
        my $thread = threads->create( $procedure, $step_message, $cmd );
        push @threads, $thread;
        unless ( defined $thread ) {
            $main::logger->{logger}->error("Failed creating thread");
            exit;
        }
    }
    my $total_threads = $#threads + 1;
    my $total         = 0;
    while ( $total < $total_threads ) {
        foreach my $thread (@threads) {
            if ( $thread->is_joinable() ) {
                my $return = $thread->join();
                ++$total;
            }
        }
        sleep 2;
    }

}

# Test to see if the user's bbox is too small for the variable's
# grid resolution. Change coordinates to single point so
# NCO snaps to grid.
sub small_bbox_test {
    my $gridMasterFile = shift;
    my $same           = 1;                      # coordinates are the same

    # -l does not  work if EOL exists
    # subset_bbox_cmd() does not work if the file is not writable
    chomp $gridMasterFile;
    if ( -l $gridMasterFile ) {
        my $dirname = dirname($gridMasterFile);
        copy( $gridMasterFile, "$dirname/gridMaster.nc" );
        $gridMasterFile = qq($dirname/gridMaster.nc)
    }

    # This hands back more than just coordinates. It returns
    # the first part of an ncks command. the coordinates
    # are stored in the 4th and 5th items
    my @ncks_subset = subset_bbox_cmd( $opt_b, $gridMasterFile );
    my @lats = split( /,/, $ncks_subset[3] );
    my @lons = split( /,/, $ncks_subset[5] );
    my @coords = ( $lons[1], $lats[1], $lons[2], $lats[2] );

    foreach my $coord (@coords) {

        # They must be floats or else nco will think they are indices
        # There may be some performance improvement with indices, we'll check that out later
        if ( $coord !~ /\./ ) {
            $coord .= ".0";
        }
    }
    return @coords;
}

# Parse the bbox input for NCO command
# This was mainly written for the shapefile w/bbox case
sub create_cmd_bbox {
    my $classic_bbox   = $opt_b;
    my $zstring        = shift;
    my $croppedMask    = shift;
    my $gridMasterFile = shift;

    my (@coords) = small_bbox_test($gridMasterFile);

    if ( !$opt_b ) {
        warn "WARN bounding box not specified\n";
    }

    if ($opt_S) {

        # Because NCO only subsets if the coord arg is smaller than the
        # corresponding, existing image coord, it works out we can just
        # crop the mask here according to the user bbox.
        my $cmd = qq(-d  lon,$coords[0],$coords[2] -d lat,$coords[1],$coords[3]);

        # but we do indeed need to recrop croppedMask.nc
        my $cmd = qq(ncks -O $cmd $croppedMask  $croppedMask 2> /dev/null);
        run_command( '', $cmd );
        print STDERR qq(INFO: re-cropping for shape and bbox:\n$cmd\n);

        # (giovanni_shape_mask.py ignores the users bbox)
        if (check_both_gridmaster_and_croppedMask($croppedMask,\@coords)) {


            # ... and then reget the whole business to get the aggregate bbox
            # cropped mask was cropped and weighted in giovanni_shape_mask.py
            # this subroutine has it's limitations...
            my $box = Giovanni::Data::NcFile::data_bbox($croppedMask);
            chomp($box);
            @coords = split( /,/, $box );
        }
    }

    my $cmd = qq(-d  lon,$coords[0],$coords[2] -d lat,$coords[1],$coords[3] $zstring );
    return $cmd;
}

sub check_both_gridmaster_and_croppedMask {
  my $mask = shift;
  my $coords = shift;

  if ( $coords-> [0] != $coords->[2] and $coords->[1] != $coords->[3] ) {
        my @lats = Giovanni::Data::NcFile::get_variable_values( $mask , 'lat');
        if (scalar @lats > 1) {
            my @lons = Giovanni::Data::NcFile::get_variable_values( $mask , 'lon');
            if (scalar @lons > 1) {
                return 1;
            }
        }
  }

  return 0;                      
}
        

# Build the NCO commands for:
#  1. subsetting  to bbox
#  2. cos(lat) weighting
#  3. area averaging
#  4. concatenation
#  5. shape masking
sub collect_cmds {
    my $cmd         = shift;
    my $master_list = shift;
    my $croppedMask = shift;
    my $gridMasterFile = shift;

    my @cmds;
    my @wts;
    my @avgs;
    my @timesteps;
    my @cropping;
    my @conv;

    # if this routine fails, datatype = "" and we convert to double 
    my $datatype = 
        Giovanni::Data::NcFile::get_variable_type($gridMasterFile, undef, $opt_v);

    foreach my $infile (@$master_list) {
        my $cmd_suffix = qq(cat $infile  | $cmd -o ${infile}_unaveraged.nc);
        push @cmds, $cmd_suffix;

        # mask is already weighted
        if ($opt_S) {
            push @wts, qq(${infile}_unaveraged.nc); # for mask_prep - mask already has weights
            push @avgs, qq(ncwa -w shape_mask -a lat,lon ${infile}_unaveraged.nc  ${infile}_avg.nc);
            push @cropping, qq(ncks -A  $croppedMask  ${infile}_unaveraged.nc);
            # if nothing gets put into @conv, the while $#subsetcmds loop never gets enterered
            if ( !($datatype eq "double" or $datatype eq "float")  ) { # need an extra step in convert/masking case
                push @conv, qq(ncap2 -h -O -s "$opt_v = double($opt_v)" ${infile}_unaveraged.nc ${infile}_unaveraged.nc);
            }
        }
        else {
            if ( !($datatype eq "double" or $datatype eq "float")  ) { # in nominal case, convert can be included with weighting
                push @wts, qq(ncap2 -h -O -s "wlat=cos(lat*0.0174532925); $opt_v = double($opt_v)" ${infile}_unaveraged.nc ${infile}_weighted.nc);
            }
            else {
                push @wts, qq(ncap2 -h -O -s "wlat=cos(lat*0.0174532925)" ${infile}_unaveraged.nc ${infile}_weighted.nc);
            }
            push @avgs, "ncwa -w wlat -a lat,lon ${infile}_weighted.nc ${infile}_avg.nc";
        }
        push @timesteps, qq(${infile}_avg.nc);
    }
    return ( \@cmds, \@wts, \@avgs, \@timesteps, \@cropping, \@conv);
}

sub handleZdimension {
    my $ra_zdims = shift;
    my $ra_zvals = shift;
    my @zdims    = @$ra_zdims;
    my @zvals    = @$ra_zvals;

    if ( $zvals[0] eq 'NA' ) {
        return "";
    }
    my $zstring = " -d ";
    for ( my $dims = 0; $dims <= $#zdims; ++$dims ) {
        if ( $zvals[$dims] !~ /\./ ) {
            $zvals[$dims] .= ".0";
        }
        $zstring .= $zdims[$dims] . "," . $zvals[$dims] . " -d ";
    }
    $zstring =~ s/-d $//;
    return $zstring;
}

# Separate the filelist into chunks of 20-200 (DEFAULT_SETSIZE)
# to feed to nco commands - taking advantage of the time/record dim
sub get_files () {

    unless ( open IN, $opt_f ) {
        warn "USER_ERROR Internal error on file read\n";
        die "ERROR failed to read input file $opt_f: $!\n";
    }

    my $sessdir = dirname($opt_f);
    my @files;
    while (<IN>) {
        push @files, $_;
    }
    close(IN);
    my $gridMasterFile = $files[0];
    # Giovanni::Data::NcFile::get_variable_values -e fails if EOL char
    $gridMasterFile =~ s/\s.*$//; 

    my $n_set = decide_setsize( $opt_j, $#files );

    print STDERR "INFO: n files = " . $#files . "\n";
    print STDERR "INFO: set size = " . $n_set . "\n";
    my $each  = 0;
    my $count = 1;
    my @master;
    my $thisfile;
    foreach my $file (@files) {
        if ( $each == 0 ) {
            $thisfile = $sessdir . "/" . qq(file_${opt_v}_$count);
            unless ( open OUT, ">", $thisfile ) {
                warn "USER_ERROR Internal error on file read\n";
                die "ERROR failed to write output file $thisfile: $!\n";
            }
        }
        print OUT $file;
        ++$each;
        if ( $each == $n_set ) {
            close(OUT);
            push @master, $thisfile;
            ++$count;
            $each = 0;
        }
    }
    if ( $each > 0 ) {
        close(OUT);
        push @master, $thisfile;
    }
    return \@master, $gridMasterFile;
}

# max number of files to be operated on by NCO is 200:
# min number of files to be operated on by NCO is 20...
# ( + the last set, whatever number of files are left):
sub decide_setsize {
    my $nthreads   = shift;
    my $totalfiles = shift;

   $DEFAULT_SETSIZE = 20 if ($PIXELS > 300000);  # GLDAS global 
   $DEFAULT_SETSIZE = 3  if ($PIXELS > 1000000);  # GPM   global
   $DEFAULT_SETSIZE = 1  if ($PIXELS > 10000000); #.05 deg global = 25 million
   
    # We want this number to always be between 20 and 200 in 
    # nominal situations:
    return $DEFAULT_SETSIZE if ( $totalfiles >= $DEFAULT_SETSIZE );
    if ($DEFAULT_SETSIZE > 100) {
       return 20 if ( int( $totalfiles / $nthreads ) <= 20 );
    }
    return int( $totalfiles / $nthreads );
}

# We need to add the mask to each of our cubes. (ncks -A)
# To do this # it helps to remove the lat, lon coordinate
# variables from the cube (The croppedMask is already the same size)
sub mask_prep1 {
    my $message = shift;
    my $outnc   = shift;

    run_command( $message, "ncks -C -x -v lat,lon -O -o $outnc $outnc" );

}

# I needed to split this in two because croppedMask name needs to be
# unique to the variable and I didn't want to name it here:
sub mask_prep2 {
    my $message = shift;
    my $cmd     = shift;

    run_command( "Attaching mask to data file", $cmd );
}

 
 sub cleanUp {
     my $var = shift;
     my $type = shift;
 
     # The python TmAvDiff version leaves only difference, time and time_bnds
     # It cleans up other variables including lat lon bnds.
     # So here we are cleaning up variables that look a little non-sensical in the context
     # of an area-averaged file.  In an area-averaged file, there are no lat lons 
     # (they have been averaged out) so we should get rid them. wlat, the variable we used
     # for getting latitude weighting,  also is no longer needed.
     
     if (Giovanni::Data::NcFile::does_variable_exist(undef,$var,$opt_o)) {
        # Delete variable
        if ($type == 'var') { 
            my @cmd = ( "ncks", "-h", "-x", "-C", "-O", "-v", $var, $opt_o,$opt_o );
            run_command( "Removing $var variable", @cmd );
        }
        # Delete dimension
        elsif ($type == 'dim') {
            run_command( "Cleaning up the $var variable: $var",
                 "ncwa -O -a $var $opt_o $opt_o" );
        }
     }
     # If this command fails, it is not particularly important.
 }

