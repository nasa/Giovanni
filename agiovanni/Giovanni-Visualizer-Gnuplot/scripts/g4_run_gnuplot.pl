#!/usr/bin/env perl

=head1 NAME

g4_run_gnuplot.pl - simple utility to run gnuplot on G4 data file

=head1 SYNOPSIS

g4_run_gnuplot.pl infile

=head1 DESCRIPTION

This is a simple utility for debugging Gnuplot visualizations.  
It allows to run gnuplot on a Giovanni-4 data file.

=head1 AUTHOR

Chris Lynnes, NASA/GSFC

=cut

use File::Temp qw /tempdir/;
use Giovanni::Visualizer::Gnuplot;
use File::Basename;

my ( $ncfile, $plot_type ) = @ARGV or die "Usage: $0 file plot_type\n";

#$plot_type= PLOT_FILE=>$png_file, "TIME_SERIES_GNU"
$plot_type = "SCATTER_PLOT_GNU" unless defined $plot_type;
my $time_series_plot = new Giovanni::Visualizer::Gnuplot(
    DATA_FILE => $ncfile,
    PLOT_TYPE => $plot_type,
    SKIP_TITLE => 1,
);
my @pngs = $time_series_plot->draw();
print $pngs[0];
warn "INFO wrote plot files: " . join(', ', @pngs) . "\n";
exit(0);
