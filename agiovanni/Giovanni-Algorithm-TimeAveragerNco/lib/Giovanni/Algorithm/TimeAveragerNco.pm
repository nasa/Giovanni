package Giovanni::Algorithm::TimeAveragerNco;

use 5.008000;
use strict;
use warnings;
use File::Copy;
use File::Temp;
use File::Basename;
use Cwd;
use Giovanni::Data::NcFile;
use Giovanni::Algorithm::AreaAvgDiff;

our $VERSION = '0.02';

1;

=head1 NAME

Giovanni::Algorithm::TimeAveragerNco - Perl module for time averaging of netCDF files

=head1 PROJECT

Agile Giovanni

=head1 SYNOPSIS

  use Giovanni::Algorithm::TimeAveragerNco;

  $outfile = Giovanni::Algorithm::TimeAveragerNco::time_averager(
    $outdir, 
    $input_file,
    $varinfo_file,
    $start_time, $end_time,
    $bbox,
    $zval,
    [$shapefile_Arg],
    [$group],
    [$localize]);

=head1 DESCRIPTION

Giovanni::Algorithm::TimeAveragerNco uses the nco program ncra to average 
variables from multiple gridded netCDF files.  (Typically this is over time.)

The return value is the output filename, which is computed from the variable 
ids, the start_time/end_time (albeit as date) and the bounding box, rounded to
the nearest degrees.

=over 4

=item $outdir

Output directory to put the result.


=item $input_file

Pathname of the file containing all the input data files.

=item $varinfo_file

Pathname of the file containing information about the variables. 
This is used only to form the output filename.

=item $start_time, $end_time

Start and end date/time in ISO 8601 format

=item $bbox

Bounding box, in a comma-separated string (W,S,E,N).

=item $zval

Horizontal slice from a 3D variable. No slicing done if undefined.

=item $shapefile_Arg

If set, uses compute_shape_time_average using the shape inside
the argument instead of using compute_time_average with bbox

=item $group

Name of group:  used for constructing output filenames.

=item $localize

If set, time_averager_nco.pl creates a local directory and puts
symlinks to the data inside it. This reduces the total number of characters
passed to ncra, allowing for longer time averages.

=back

=head1 AUTHOR

Christopher Lynnes, E<lt>christopher.s.lynnes@nasa.govE<gt>

=cut

################################################################################
# $Id: TimeAveragerNco.pm,v 1.50 2015/07/23 14:53:34 csmit Exp $
# -@@@ time_averager, $Name:  $
################################################################################

sub time_averager {
    my ($outdir,     $outfile,     $input_file, $var_id,
        $start_time, $end_time,    $bbox,       $zarg,
        $group_val,  $localize_me, $shapefile_Arg
    ) = @_;

    # Parse bounding box
    my $ra_bbox;
    if ($bbox) {
        my @bbox = split( ',', $bbox );
        $ra_bbox = \@bbox;
    }

    my ( $zvar, $zval, $zunits );

    # zarg:  $zvar=$zval$zunits
    if ( defined($zarg) ) {
        ( $zvar, $zval, $zunits ) = ( $zarg =~ m/(\w+?)=([.\d]+)(\w+)/ );
        quit( "Failed to run time averager command",
            "Failed to parse Z variable in $zarg\n", 12 )
            unless $zvar;
    }

    my $zstr = $zval . $zunits if $zval;
    my ( $local_input, @file_list );

    # Create local symlinks if desired.
    if ($localize_me) {
        ( $local_input, @file_list ) = localize_files($input_file);
    }
    else {
        $local_input = $input_file;
        open (INPUT, '<', $input_file)
            or quit( "Failed to open input file $input_file",
            "Failed to open input file $input_file: $!", 9 );
        while (<INPUT>) {
            chomp;
            push @file_list, $_;
        }
        close(INPUT);
    }

    # Check to see if the variable in question is in the file
    # LIEN:  shouldn't have to do this
    preflight_check( $file_list[0], $var_id );

    # TODO: Is there an alternative way to do this so no init is necessary?
    my $rc = 2;

 # Check to see if shapefile_Arg exists. If yes, compute time avg using shape.
    $rc = compute_time_average( $local_input, $outfile, $ra_bbox, $var_id,
        $zvar, $zval );

   # Since we have averaged over time, there's a bit of time stuff to clean up
    revise_time_info( $outfile, $local_input );

    # Set z-slice attributes
    set_z_attributes( $outfile, $var_id, $zval, $zunits ) if defined($zarg);

    # Set grouping attributes
    set_group_attributes( $outfile, $var_id, $group_val ) if ($group_val);

    # Cleanup
    if ($localize_me) {
        map { unlink($_) if ( -l $_ ) } @file_list;

        # Only unlink this "temporary" file
        unlink($local_input);
    }
    add_title( $outfile, $var_id, $start_time, $end_time );

    # Check to see if our output is not just fill values
    postflight_check($outfile);

    # Print informational messages for log, user and workflow
    print STDERR "INFO Done with time averaging\n";
    print STDERR "USER_MSG Done with time averaging\n";
    print STDERR "OUTPUT $outfile\n";
    return ($rc);
}

sub set_group_attributes {
    my ( $outfile, $var_id, $group_val ) = @_;
    my ( $group, $val ) = split( '_', $group_val );

    # Add both attributes with one ncatted command
    run_cmd_bcktck_nomsg(
        "ncatted -h -O -a \"group_type,$var_id,o,c,$group\" -a \"group_value,$var_id,o,c,$val\" $outfile"
    );
}

sub set_z_attributes {
    my ( $outfile, $var_id, $zval, $zunits ) = @_;
    my $ztype = "UNKNOWN";
    if ( $zunits eq "hPa" ) {
        $ztype = "pressure";
    }
    run_cmd_bcktck_nomsg(
        "ncatted -h -O -a \"z_slice,$var_id*,o,c,$zval$zunits\" -a \"z_slice_type,$var_id*,o,c,$ztype\" $outfile"
    );
}

sub add_title {
    my ( $file, $var_id, $start, $end ) = @_;
    my $date_range = substr( $start, 0, 10 ) . ' to ' . substr( $end, 0, 10 );
    my $title = "$var_id Averaged over $date_range";
    my $cmd
        = sprintf( "ncatted -O -a 'title,global,o,c,%s' %s", $title, $file );
    my $out = `$cmd`;

    # Do NOT fail if we cannot write the title, it's not important enough
    if ($?) {
        print STDERR "ERROR Failed to run $cmd on $file: $out\n";
    }
    return;
}

sub compute_time_average {
    my ( $input_file, $output_filename, $ra_bbox, $var_id, $zvar, $zval,
        $time_constraints )
        = @_;


    # The main command and args...
    my $local_dir = $input_file;
    $local_dir =~ s/\.txt$//;
    my $cmd = "ncra -D 2 -H -O -o $output_filename";
    my $NcFile;

    if ( $ra_bbox || defined($zvar) || defined($time_constraints) ) {

        # Add spatial subset args if bbox is specified
        open (INPUT_FILE, '<', $input_file)
            or quit( "Failed to open input file",
            "Failed to open input file $input_file: $!", 10 );
        my $sample_file = <INPUT_FILE>;
        close INPUT_FILE;
        chomp $sample_file;
        my $NcFile = Giovanni::Data::NcFile->new(
            NCFILE  => $sample_file,
            verbose => 0
        );
        my ( $lat_var, $lon_var ) = Giovanni::Data::NcFile::get_lat_lon_dimnames($sample_file,$NcFile->getXPathPointer());
        my $itIsACube
            = isItACube( $NcFile, $time_constraints->{timeDimName} );

        # Snap small lat/lon range to a point
        # ncks command plus args applied to all subsets (bbox, -O)
        my @ncks = Giovanni::Algorithm::AreaAvgDiff::subset_bbox_cmd( join(",",@$ra_bbox), $sample_file );
        my @lats = split( /,/, $ncks[3] );
        my @lons = split( /,/, $ncks[5] );
        my $latS = $lats[1];
        my $latN = $lats[2];
        my $lonW = $lons[1];
        my $lonE = $lons[2];
        
        # Add latitude and longitude of bounding box to command
        $cmd .= sprintf( " -d %s,%f,%f -d %s,%f,%f",
            $lat_var, $latS, $latN, $lon_var, $lonW, $lonE )
            if ($ra_bbox);
        $cmd .= sprintf( " -d %s,%f,%f", $zvar, $zval, $zval )
            if ( defined($zvar) );

     # If you have time constraints to process a cube, add this to the command
        if ( $time_constraints and $itIsACube ) {
            $cmd .= sprintf( " -d %s,%s,%s",
                $time_constraints->{timeDimName},
                $time_constraints->{start},
                $time_constraints->{end} );
        }
    }

    # Add input file and stderr processing
    # Output a USER_MSG every 100 files
    $cmd
        .= " 2>&1 < $input_file "
        . "|perl -ne 's/ncra: INFO/USER_MSG Processing/; s/ is.*\$/\./; warn("
        . '$_'
        . ") if /Input.*00\\./'";

    # Execute the command
    run_cmd_bcktck_nomsg($cmd);
    warn "USER_MSG Finished computing averages\n";

    # Get rid of z-dimension
    if ( defined($zvar) ) {

        # FEDGIANNI-1434
        if (!$NcFile) {
            $NcFile = Giovanni::Data::NcFile->new(
                 NCFILE  => $output_filename, # is the same kind of file as sample_file
                 verbose => 0
            );
        }
        my @variables  = $NcFile->find_variables_with_latlon();
        my @shapes = ();
        # We might have two (vector) variables:
        foreach my $var_id ( @variables) {
            my $shape = Giovanni::Data::NcFile::get_variable_dimensions("$output_filename", "", $var_id);
            $shape =~ s/$zvar//;
            push @shapes,$shape
        }
        # We only want to do this once though;
            run_cmd_bcktck_nomsg("ncwa -h -O -a $zvar $output_filename $output_filename.tmp");

        # Fix coordinate variable: FEDGIANNI-1434:
        
        # We might have two (vector) variables:
        foreach my $var_id ( @variables) {
            my $shape = shift @shapes;
            run_cmd_bcktck_nomsg( "ncatted -h -a 'coordinates,$var_id,o,c,$shape' $output_filename.tmp");
        }
        run_cmd_bcktck_nomsg(
            "ncks -h -O -x -v $zvar $output_filename.tmp $output_filename");
    }

    return $output_filename;
}

sub isItACube {
    my $NcFile    = shift;
    my $timelabel = shift;
    return undef if ( !$timelabel );
    my $xpc = $NcFile->getXPathPointer();

    my $sizeOfTimeDim = $xpc->findvalue(
        qq(/nc:netcdf/nc:dimension[\@name="$timelabel"]/\@length));
    if ( $sizeOfTimeDim == 1 ) {
        return undef;
    }
    elsif ( $sizeOfTimeDim > 1 ) {
        return 1;
    }
    else {
        die "Could not determine if cube or not";
    }
}

sub run_cmd_bcktck_nomsg {
    my ($cmd) = @_;
    warn "INFO running $cmd\n";
    my $output = `$cmd`;
    if ($?) {
        my $errmsg = sprintf( "exit=%d signal=%d core=%s",
            $? >> 8, $? & 127, ( $? & 128 ) ? 'y' : 'n' );
        quit(
            "Failed to run time averager command",
            "Failed to run time averager cmd '$cmd': $errmsg\nOutput: $output\n",
            11
        );
    }
}


sub localize_files {
    my $input_file = shift;
    open (INPUT, "<" , $input_file)
        or quit( "Failed to open input file $input_file",
        "Failed to open input file $input_file: $!", 9 );

    # Open a unique output file to write to
    my $dir = File::Temp::tempdir( 'lnXXXX', DIR => '.' );
    chmod 0770, $dir;
    my $outfile = "$dir.txt";
    open( OUTPUT, '>', $outfile )
        or quit(
        "Could not write to temporary file $outfile",
        "Could not write to temporary file $outfile: $!"
        );

    # Loop through input files, create symlink, add symlink to output file
    # The use of short symlink filenames gets around the file limit in ncra of
    # a total of 1 million bytes.
    # TODO:  hmmm...I think ncra does not have this shortcoming anymore.
    my @files;
    my $i = 0;
    while (<INPUT>) {
        chomp;
        my $file = sprintf( "$dir/A%d.nc", $i );
        $i++;
        if ( $file ne $_ ) {

           # Unlink the symlink if there. Not for normal cases, but unit tests
           # and restarts.
            my $abs_path = Cwd::abs_path($_);
            unlink($file) if ( -e $file );
            symlink( $abs_path, $file )
                or quit( "Failed to set up local symlink",
                "Failed to symlink $abs_path to $file", 10 );
            push @files, $file;    # Save list for cleanup
        }
        print OUTPUT $file . "\n";
    }
    close INPUT;
    close OUTPUT;
    return ( $outfile, @files );
}

sub preflight_check {
    my ( $file, $var_id ) = @_;
    `ncdump -h $file | grep -i -q $var_id`;
    if ( $? != 0 ) {
        quit( "Could not find variable $var_id in file",
            "Could not find variable $var_id in file $file", 23 );
    }
    return 1;
}

sub postflight_check {
    my ($file) = @_;

    # NOTE: if this is a vector, then there are two data variables in the data
    # file (u and v components), neither of which will match the variable id.
    # So, look for at least one plotable variable and use that to determine
    # if everything is a fill value.
    my @vars = Giovanni::Data::NcFile::get_plottable_variables($file);
    my $min  = qx/getNcMin.py -v $vars[0] $file/;
    chomp $min;

    if ( $min eq '--' ) {
        my $varUiLabel
            = Giovanni::Data::NcFile::get_variable_ui_name( $file, 1,
            $vars[0] );
        quit( "Data is all fill values in [$varUiLabel]",
            "Failing-- data is all fill values in [$varUiLabel]", 5 );
    }
}

sub quit {
    my ( $user_msg, $error_msg, $exit_code ) = @_;
    warn "USER_ERROR $user_msg\n";
    warn "ERROR $error_msg\n";
    exit($exit_code);
}

# revise_time_info:  now that we have an aggregation over time, we need to
# clean up the time data and metadata:
#   Remove dataday, datamonth
#   update start_time and end_time to match what's in the data
#   Remove time dimension and variable

sub revise_time_info {
    my ( $outfile, $infile_list ) = @_;

    # Remove time dimension
    run_cmd_bcktck_nomsg("ncwa -o $outfile -a time -O $outfile");

    # Remove time variable
    run_cmd_bcktck_nomsg("ncks -x -v time -o $outfile -O $outfile");

   # Since we have averaged over time, there's a bit of time stuff to clean up
   # Adjust start and end time
    my ( $start_time, $end_time ) = actual_time_range($infile_list);
    my @args = ( "-a", "temporal_resolution,global,d,c," );
    push( @args, "-a", "start_time,global,o,c,$start_time" ) if $start_time;
    push( @args, "-a", "end_time,global,o,c,$end_time" )     if $end_time;
    my $cmd = "ncatted -O -h " . join( ' ', @args, $outfile );
    run_cmd_bcktck_nomsg($cmd);

    # Exclude dataday/datamonth in output file
    my @dataday = `ncks -m $outfile |grep RAM|grep dataday`;
    chomp(@dataday);
    if ( scalar(@dataday) == 0 ) {
        @dataday = `ncks -m $outfile |grep RAM|grep datamonth`;
        chomp(@dataday);
    }
    if ( scalar(@dataday) > 0 ) {
        my ( $dataday_name, $stuff ) = split( ' ', $dataday[0], 2 );
        `ncks -h -O -x -v $dataday_name $outfile $outfile.tmp`;
        `mv $outfile.tmp $outfile` unless $?;
    }
}

sub actual_time_range {
    my $infile_list = shift;

    # TO DO:  Move this to the front and do away with begin and end args
    open( IN, '<', $infile_list )
        or die "Cannot open input file list $infile_list: $!";
    my ( $first_file, $last_file );
    $first_file = <IN>;
    while (<IN>) { $last_file = $_; }
    close(IN);
    chomp($first_file);
    chomp($last_file);
    my $time = `ncks -h -x $first_file|grep start_time`;
    my ($start_time) = ( $time =~ /value\s*=\s*(.+Z)\b/ );
    $time = `ncks -h -x $last_file|grep end_time`;
    my ($end_time) = ( $time =~ /value\s*=\s*(.+Z)\b/ );
    return ( $start_time, $end_time );
}
