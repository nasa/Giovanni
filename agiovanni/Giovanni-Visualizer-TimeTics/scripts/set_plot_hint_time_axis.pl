#!/usr/bin/env perl

=head1 NAME

set_plot_hint_time_axis.pl - set plot hints for time series netCDF files

=head1 PROJECT

aGiovanni

=head1 SYNOPSIS

set_plot_hint_time_axis.pl [files]

=head1 DESCRIPTION

This is a simply script driver for the 
Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis method.
The arguments are one or more files; it will loop over them. Also, if files are
bundled together into one argument, separated by commas, it will split them
and process each one.

=head1 AUTHOR

Christopher Lynnes, NASA/GSFC, Code 610.2

=head1 SEE ALSO

Giovanni::Visualizer::TimeTics(3)

=cut

################################################################################
# $Id: set_plot_hint_time_axis.pl,v 1.2 2011/10/11 22:08:20 clynnes Exp $
# -@@@ aGiovanni, $Name:  $
################################################################################

use strict;
use Giovanni::Visualizer::TimeTics;

# Get list of files, splitting by commas if necessary
my @files = map { split /,/, $_ } @ARGV;
my @success;
foreach my $f (@files) {
    if ( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($f) ) {
        push @success, $f;
    }
    else {
        warn "Failed to add time-axis plot hints to netCDF file\n";
    }
}

# Write successful files to stdout
print( join( "\n", @success, '' ) );
exit( $#success == $#files );
