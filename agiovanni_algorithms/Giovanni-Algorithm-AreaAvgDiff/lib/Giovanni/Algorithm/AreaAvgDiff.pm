package Giovanni::Algorithm::AreaAvgDiff;

use 5.008008;
use strict;
use warnings;
use Giovanni::Data::NcFile;
use File::Basename;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni-Algorithm-AreaAvgDiff ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
            compute_area_average
            compute_shapefile_area_average
            run_command
            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    compute_area_average
    compute_shapefile_area_average
    run_command
    subset_bbox_cmd
    set_datagrid_info
    grab_datagrid_info
);

our $VERSION = '0.01';

# Preloaded methods go here.

1;

sub compute_area_average {
    my ( $infile, $outfile, $new_var, $just_avg ) = @_;

    if ($just_avg) {
        run_command(
            "Averaging " . basename($infile),
            "calc_area_statistics.py $infile $outfile --variable $new_var "
                . "--no-standard-deviation --no-min --no-max --no-count"
        );
    }
    else {
        run_command( "Averaging " . basename($infile),
            "calc_area_statistics.py $infile $outfile --variable $new_var" );
    }

    return $outfile;
}

sub compute_shapefile_area_average {
    my ( $datafile, $outfile, $just_avg ) = @_;

    if ($just_avg) {
        run_command(
            "Computing shapefile mask weighted area average",
            "calc_area_statistics.py $datafile $outfile --weights shape_mask "
                . "--no-standard-deviation --no-min --no-max --no-count"
        );
    }
    else {
        run_command(
            "Computing shapefile mask weighted area average",
            "calc_area_statistics.py $datafile $outfile --weights shape_mask"
        );
    }

    return $outfile;
}

sub run_command {
    my ( $user_msg, @cmd ) = @_;

    # Log some info
    warn "USER_INFO $user_msg...\n" if $user_msg;
    my $cmd = join( ' ', @cmd );
    warn "INFO Running command $cmd\n";

    # Run it
    my $rc = system(@cmd);

    # Process return code (0 = success)
    if ($rc) {
        print STDERR "USER_ERROR Failed to execute $user_msg\n";
        my $exit_value = $rc >> 8;
        print STDERR "ERROR $cmd failed with exit code $exit_value\n";
        exit(2);
    }
    return 1;
}

sub subset_bbox_cmd {
    my ( $bbox, $file ) = @_;

    my @cmd = ( 'ncks', '-O' );
    return @cmd unless ($bbox);

    # Split the bounding box into its edges
    my $pattern = '([\d.+\-]+)';
    my ( $west, $south, $east, $north )
        = ( $bbox =~ /$pattern, *$pattern, *$pattern, *$pattern/ );

# If any of the lat/lon dimensions are smaller than file resolution, then collapse them to
# a single value so that ncks will return a result
    if ($file) {
        my ( $latres, $lonres )
            = Giovanni::Data::NcFile::spatial_resolution($file);
        my $delta_lat = $north - $south;
        if ( $delta_lat < $latres ) {
            $north = ( $north + $south ) / 2.;
            $south = $north;
            warn "INFO collapsing latitude to $north\n";
        }

        # Dateline handling examples
        # West = 170., East = -175.
        #    east360 = 185, delta_lon = 15
        # West = 170., East = 160. (Wraparound)
        #    east360 = 520, delta_lon = 350
        my $east360 = $east;
        $east360 += 360. if ( $west > $east );
        my $delta_lon = $east360 - $west;
        if ( $delta_lon < $lonres ) {
            $east = ( $east360 + $west ) / 2.;
            $east -= 360. if ( $east > 180. );
            $west = $east;
            warn "INFO collapsing longitude to $west\n";
        }
    }
    push @cmd, '-d', sprintf( "lat,%f,%f", $south, $north );
    push @cmd, '-d', sprintf( "lon,%f,%f", $west,  $east );
    return @cmd;
}

# add bbox from data (datagrid) to metadata of file
sub set_datagrid_info {
     my $REPORT_GRID = shift;
     my $filename = shift;

     my $value = sprintf("%g", $REPORT_GRID->{LAT}[0]);
     my $global_attr_name = 'geospatial_lat_min';
     my @cmd = ( "ncatted", "-h", "-O", "-a","$global_attr_name,global,o,c,$value", $filename);
     run_command( "Reporting geospatial_lat_min", @cmd );

     $value = sprintf("%g", $REPORT_GRID->{LON}[0]);
     $global_attr_name = 'geospatial_lon_min';
     @cmd = ( "ncatted", "-h", "-O", "-a","$global_attr_name,global,o,c,$value", $filename);
     run_command( "Reporting geospatial_lon_min", @cmd );

     $value = sprintf("%g", $REPORT_GRID->{LAT}[-1]);
     $global_attr_name = 'geospatial_lat_max';
     @cmd = ( "ncatted", "-h", "-O", "-a","$global_attr_name,global,o,c,$value", $filename);
     run_command( "Reporting geospatial_lat_max", @cmd );

     $value = sprintf("%g", $REPORT_GRID->{LON}[-1]);
     $global_attr_name = 'geospatial_lon_max';
     @cmd = ( "ncatted", "-h", "-O", "-a","$global_attr_name,global,o,c,$value", $filename);
     run_command( "Reporting geospatial_lon_max", @cmd );

 }

# grab the data bounding box for future reporting
# (as opposed to the User's bbox)
sub grab_datagrid_info {
     my $file = shift;
     my %REPORT_GRID;
     my @tmp = Giovanni::Data::NcFile::get_variable_values($file,'lat','lat');
     push @{$REPORT_GRID{LAT}} ,  @tmp;
     @tmp = Giovanni::Data::NcFile::get_variable_values($file,'lon','lon');
     push @{$REPORT_GRID{LON}} , @tmp;
     return \%REPORT_GRID;
}

__END__

=head1 NAME

Giovanni-Algorithm-AreaAvgDiff - Compute Area Average and related functions

=head1 SYNOPSIS

  use Giovanni-Algorithm-AreaAvgDiff;
  $outfile = compute_area_average($infile, $outfile, $newvar);
    --or--
  $outfile = compute_shapefile_area_average($infile,$outfile,
  my @ncks = subset_bbox_cmd($bbox);

=head1 DESCRIPTION

=over 4

=item compute_area_average($infile, $outfile, $new_var_name)

Compute area averages in Giovanni workflows. It uses ncap2 to add cos(lat) to the input file, 
runs ncwa to compute the average, then eliminates the lat and lon dimensions.

=item compute_shapefile_area_average($outfile,$shapefile_Arg,$user_shapes_dir,$outfile)

Compute area averages using the shapefile specified in shapefile_Arg as a mask. This method
burns a mask from the shape, cos-lat weights the mask, and does additional processing on the mask. 
This happens only once (for now, may change after adding subsetting process). After masking or retrival
of the already created mask, the time slice is computed by adding the mask to the datafile and computing 
the mask-weighted area average.
NOTE: At the moment, the outfile is the dataset input and gets overwritten after the process is complete.

=item run_command($name, $cmd, @args);

This runs a command using a system call.

=item subset_bbox_cmd($bbox)

This returns the beginning of an ncks command to subset a bounding box from a conformant
(scrubbed) file.  It is often useful to call this at the beginning of a program, then
call ncks on each input file, substituting in input and output files.

=head2 EXPORT

compute_area_average, run_command, subset_bbox_cmd

=head1 AUTHOR

Chris Lynnes, E<lt>christopher.s.lynnes@nasa.govE<gt>

=cut
