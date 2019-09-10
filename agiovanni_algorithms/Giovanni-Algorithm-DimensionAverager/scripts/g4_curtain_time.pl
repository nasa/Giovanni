#!/usr/bin/env perl

=head1 NAME

g4_curtain_time.pl - Time-Pressure curtain plot of a variable (Cross Section, Time-Pressure)

=head1 SYNOPSIS

g4_curtain_time.pl 
  -f input_file 
  -s start_time -e end_time 
  -v varname
  -u units,units,units_cfg
  [-o outfile] 
  [-b bbox]
  [-S shapefile_info]

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

=item -v varname

Name of the variable to be plotted.

=back

=head1 EXAMPLE

g4_curtain_time.pl -b -180.0,-5,180,5 -s 2015-01-01T00:00:00Z -e 2015-04-30T23:59:59Z -v MAIMCPASM_5_2_0_RH -f files.txt -o dimensionAveraged.MAIMCPASM_5_2_0_RH.20150101-20150430.180W_5S_180E_5N.nc -l lineage.txt
=head1 AUTHOR

Maksym Petrenko, NASA/GSFC/ADNET

=head1 ACKNOWLEDGEMENTS

Based on g4_area_avg_diff_time_series.pl by Chris Lynnes, NASA/GSFC

=cut

use strict;
use Getopt::Std;
use File::Basename;
use File::Temp qw/tempfile/;
use Giovanni::Util;
use Giovanni::Data::NcFile;
use Giovanni::Algorithm::Wrapper;
use Giovanni::Algorithm::AreaAvgDiff;

# Define and parse argument vars
use vars
    qw($opt_b $opt_x $opt_y $opt_s $opt_e $opt_f $opt_o $opt_v $opt_S $opt_l $opt_u);
getopts('b:x:y:s:e:f:o:z:v:S:l:u:');

# Use output file directory for temporary files as well
my $outdir = $opt_o ? dirname($opt_o) : '.';

#This plumbing comes from g4_area_avg_diff_time_series.pl that also supports two-variable pltos,
# we can probably get rid of most of it.
my @timesteps;
my $new_var = $opt_v;

my @vars;
push @vars, $opt_v;
my $nvars = scalar(@vars);

my @long_names;
my @coords = ( 'x', 'y' );

# Read in input text file of file pairs to be processed
unless ( open IN, $opt_f ) {
    warn "USER_ERROR Internal error on file read\n";
    die "ERROR failed to read input file $opt_f: $!\n";
}
my $n = 0;
my @ra_ncks;
my @converters;
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

        #  Subset by bbox
        $outfile
            = subset_file( $infiles[$j], $outdir, $coords[$j], $ra_ncks[$j],
            $vars[$j] );

        # Convert units if applicable
        if ( $converters[$j] ) {
            $converters[$j]->ncConvert(
                sourceFile      => $outfile,
                destinationFile => $outfile
            );
        }

        $outfiles{ $coords[$j] } = $outfile;
    }
    my $timestep = "$opt_o.$n";

    # Compute the area average
    if ($opt_S) {
        # just calculate the average, not statistics
        compute_shapefile_area_average( $outfile, $timestep, 1 );
    }
    else {
        # just calculate the average, not statistics
        compute_area_average( $outfile, $timestep, $new_var, 1 );
    }

    recover_pseudo_time_coord( $timestep, $outfiles{'x'} );
    unlink( $outfiles{'x'} );
    push @timesteps, $timestep;
    $n++;
}

# Concatenate into a time series
concatenate_timesteps( $opt_o, @timesteps );

#Switch the order of dimentsions (probably need a temp file)
#run_command('',  "ncpdq -O -a time,Height $opt_o $opt_o");

# Clean up output files for each time slice
unlink(@timesteps) unless ( exists $ENV{CLEANUP} && $ENV{CLEANUP} == 0 );

# Update long_name
my $new_long_name = "$long_names[1] minus $long_names[0]" if ($opt_y);
update_var_attrs( $opt_o, $new_var, $new_long_name ) if $new_long_name;

exit(0);

sub concatenate_timesteps {
    my ( $outnc, @timestep_nc ) = @_;
    my $file_list = "$outnc.files";

    # Write the files to a list for feeding in via stdin
    if ( !open FILE_LIST, '>', $file_list ) {
        die "ERROR Cannot write to file list $file_list\n";
    }
    foreach my $timestep_file (@timestep_nc) {
        print FILE_LIST "$timestep_file\n";
    }
    close FILE_LIST;
    run_command( '', "ncrcat -O -o $opt_o < $file_list" );
    run_command( '', "ncks -C -x -v lat,lon -O -o $opt_o $opt_o" );
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

sub subset_file {
    my ( $infile, $outdir, $which, $ra_ncks, $var ) = @_;

    # Form output filename:  foo.x.nc, foo.y.nc
    my ( $outbase, $dir, $suffix ) = fileparse( $infile, '.nc' );
    my $outfile = "$outdir/$outbase.$which$suffix";

    my @z_subset;

    # Now run the subsetter
    run_command( '', @$ra_ncks, @z_subset, '-o', $outfile, $infile );

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

