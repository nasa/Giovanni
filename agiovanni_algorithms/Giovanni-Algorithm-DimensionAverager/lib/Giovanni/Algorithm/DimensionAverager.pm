package Giovanni::Algorithm::DimensionAverager;

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

# This allows declaration use Giovanni-Algorithm-DimensionAverager ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
            compute_spatial_average
            compute_temporal_average
            compute_subset_lat
            compute_subset_lon
            run_command
            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    run_command
);

our $VERSION = '0.01';

1;

sub compute_spatial_average {
    my ( $infile, $outfile, $new_var ) = @_;
    run_command(
        "Averaging " . basename($infile),
        "ncap2 -O -o $outfile -s '*d2r=acos(-1.)/180.; coslat=cos(lat*d2r)' $infile"
    );

    return compute_spatial_average_with_weights( $outfile, $outfile, $new_var,
        "coslat" );
}

sub compute_spatial_average_with_weights {
    my ( $infile, $outfile, $new_var, $weight_var ) = @_;
    run_command( '',
        "ncwa -v $new_var -w $weight_var -a lat,lon -O -o $outfile $infile" )
        ;
    run_command( '', "ncks -x -v lat,lon -O -o $outfile $outfile" );
    return $outfile;
}

sub compute_temporal_average {
    my ( $infile, $outfile ) = @_;
    run_command(
        "Averaging " . basename($infile),
        "ncwa -h -O -a time $infile $outfile"
    );
    return $outfile;
}

sub compute_subset_lat {
    my ( $d_string, $infile, $subset_outfile, $file_new ) = @_;
    run_command(
        "Subsetting " . basename($infile),
        "ncks -O $d_string $infile $subset_outfile"
    );
    run_command(
        "Averaging " . basename($infile),
        "ncap2 -h -O -s '*d2r=acos(-1.)/180.; coslat=cos(lat*d2r)' $subset_outfile $file_new.tmp"
    );    # Only ff we are averaging over latitude
    run_command( '', "ncwa -h -O -w coslat -a lat $file_new.tmp $file_new" );
    return $file_new;
}

sub compute_subset_lon {
    my ( $d_string, $infile, $subset_outfile, $file_new ) = @_;
    run_command(
        "Subsetting " . basename($infile),
        "ncks -O $d_string $infile $subset_outfile"
    );
    run_command( '', "ncwa -h -O -a lon $subset_outfile $file_new" );
    return $file_new;
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
__END__

=head1 NAME

Giovanni-Algorithm-DimensionAverager - Compute Area Average and related functions for vertical
profile, hovmoller, and seasonal services

=head1 SYNOPSIS

  use Giovanni-Algorithm-DimensionAverager;
  $outfile = compute_spatial_average($infile, $outfile, $new_var);
    --or--
  $outfile = compute_temporal_average($infile,$outfile);
    --or--
  $outfile = compute_subset_lat(d_string, $infile, $subset_outfile, $file_new);
    --or--
  $outfile = compute_subset_lon(d_string, $infile, $subset_outfile, $file_new);

=head1 DESCRIPTION

=over 4

=item compute_spatial_average($infile, $outfile, $new_var)

Compute area averages in Giovanni workflows. It uses ncap2 to add cos(lat) to the input file, 
runs ncwa to compute the average, then eliminates the lat and lon dimensions. $infile is the 
input file, $outfile is user-supplied outfile, and $new_var is the variable to be averaged over.

=item compute_spatial_average_with_weights($infile, $outfile, $new_var, $weight_var)

Compute area averages in Giovanni workflows. It runs ncwa to compute the average using
$weight_var as the weights, then eliminates the lat and lon dimensions. $infile is the input 
file, $outfile is user-supplied outfile, and $new_var is the variable to be averaged over.

=item compute_temporal_average($infile, $outfile)

Compute time averages in Giovanni workflows. It uses ncwa to compute the temporal average.

=item compute_subset_lat($d_string, $infile, $subset_outfile, $file_new)

Computes the subset and area average specified by the function input paraemters for latitude. First, the
method uses ncks to subset the files (netCDF). ncap2 is called to add cos(lat) to the input file. Run ncwa
to compute the average.

=item compute_subset_lon($d_string, $infile, $subset_outfile, $file_new)

Computes the subset and area average specified by the function input paraemters for longitude. First, the
method uses ncks to subset the files (netCDF). Run ncwa to compute the average.

=item run_command($name, $cmd, @args);

This runs a command using a system call.

=head2 EXPORT

compute_spatial_average, compute_temporal_average, compute_subset, run_command
None by default.

=head1 AUTHOR

Michael A Nardozzi, E<lt>mnardozz@localdomainE<gt>

=cut
