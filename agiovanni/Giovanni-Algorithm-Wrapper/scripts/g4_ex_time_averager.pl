#!/usr/bin/env perl
# g4_ex_time_averager.pl -f input_file -s start_time -e end_time [-v varname] [-o outfile]
#      [-b bbox] [-z zDimName=zValUnits]
# -f input_file: Pathname of the file containing all the input data files as a simple text list.
# -s start_time: Start date/time in ISO 8601 format.
# -e end_time: End date/time in ISO 8601 format.
# -o outfile: Output filename
# -b bbox:  Bounding box, in a comma-separated string (W,S,E,N).
# -v varname: Name of the variable to be averaged.
# -z zDimName=zValUnits: Horizontal slice to extract from 3-D data,
#    e.g., "-z TempPrsLvls_A=500hPa" for the 500 hPa level.
# -g group=value
# Example:
# g4_ex_time_averager.pl -v AIRX3STD_006_Temperature_A -f airs.txt -b -180,-90.,180.0,90 -z TempPrsLvls_A=850hPa -o airs.nc

use strict;
use Getopt::Std;
use File::Basename;
use Giovanni::Algorithm::Wrapper;

# Define and parse argument vars
# Actually, we don’t really use the variable name (-v)
use vars qw($opt_b $opt_g $opt_v $opt_s $opt_e $opt_f $opt_o $opt_z $opt_u);
getopts('b:g:v:s:e:f:o:u:z:');
usage() unless ( $opt_f && $opt_v && $opt_o );

warn "INFO processing group $opt_g\n" if ($opt_g);

# Split the bounding box into its edges
my $pattern = '([\d.+\-]+)';
my ( $west, $south, $east, $north )
    = ( $opt_b =~ /$pattern,$pattern,$pattern,$pattern/ );

# Build the ncra command
my @cmd = ( 'ncra', '-O', '-o', $opt_o );
push @cmd, '-d', sprintf( "lat,%f,%f", $south, $north );
push @cmd, '-d', sprintf( "lon,%f,%f", $west,  $east );

# If a z-slice is specified, as -z var=valueunits, convert into ncra arg
if ($opt_z) {
    my ( $var, $value, $zunits ) = ( $opt_z =~ /(\w+)=([\d\.\-]+)(\w+)/ );
    push @cmd, '-d', sprintf( "%s,%f,%f", $var, $value, $value );
}

my @files;
open IN, $opt_f or die "cannot open $opt_f: $!\n";
foreach my $f (<IN>) {
    chomp($f);
    push @files, $f;
}

# Convert units, if applicable
if ($opt_u) {
    my ($cvt)
        = Giovanni::Algorithm::Wrapper::setup_units_converters( $opt_u,
        $opt_v, \@files );
    my @newfiles = map { 'uc.' . basename($_) } @files;
    map {
        $cvt->ncConvert(
            'sourceFile'      => $files[$_],
            'destinationFile' => $newfiles[$_]
            )
    } 0 .. $#files;
    my $newfile = 'uc.' . basename($opt_f);
    open OUT, '>', $newfile or die "Cannot write to $newfile\n";
    map { print OUT "$_\n" } @newfiles;
    close OUT;
    $opt_f = $newfile;
}

# For long lists of files, ncra can take them on standard in instead
push @cmd, '<', $opt_f;
my $cmd = join( ' ', @cmd );

# Run it!
print STDERR "USER_INFO Computing time average for each cell...\n";
print STDERR "INFO Running command $cmd\n";
my $rc = system($cmd);
if ( $rc == 0 ) {
    print STDERR "PERCENT_DONE 100\n";
}
else {
    print STDERR "USER_ERROR Failed to execute time averaging\n";
    my $exit_value = $rc >> 8;
    print STDERR "ERROR Time averager failed with exit code $exit_value\n";
    exit(2);
}

# Cleanup extraneous stuff
warn "INFO cleaning extraneous vars\n";
system("ncwa -O -o $opt_o -a time $opt_o");
system("ncks -O -o $opt_o -x -v time,dataday $opt_o");
exit(0);

sub usage {
    die
        "Usage: $0 -b bbox [-z slice] -v var -s start -e end -f infile -o outfile\n";
}
