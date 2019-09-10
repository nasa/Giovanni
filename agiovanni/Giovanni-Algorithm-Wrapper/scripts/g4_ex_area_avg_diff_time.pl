#!/usr/bin/env perl
# bbaadt.pl -f input_file -s start_time -e end_time -x varname,zdim=zValunits  -y varname [-o outfile]
#      [-b bbox]
# -f input_file: Pathname of the file containing all the input data files as a simple text list.
# -s start_time: Start date/time in ISO 8601 format.
# -e end_time: End date/time in ISO 8601 format.
# -o outfile: Output filename
# -b bbox:  Bounding box, in a comma-separated string (W,S,E,N).
# -x, -y varname: Name of the variables to be differenced.
# -z zDimName=zValUnits: Horizontal slice to extract from 3-D data,
#    e.g., "-z TempPrsLvls_A=500hPa" for the 500 hPa level.
# Example:
# bbaadt.pl -x AIRX3STD_006_Temperature_A,TempPrsLvls_D=850hPa -y AIRX3STD_006_Temperature_D,TempPrsLvls_D=850hPa -f files.txt -b -180,-90.,180.0,90 -o airs.nc

use strict;
use Getopt::Std;
use File::Basename;

# Define and parse argument vars
use vars qw($opt_b $opt_x $opt_y $opt_s $opt_e $opt_f $opt_o $opt_z $opt_l);
getopts('b:x:y:s:e:f:o:z:l');

# Split the bounding box into its edges
my $pattern = '([\d.+\-]+)';
my ( $west, $south, $east, $north )
    = ( $opt_b =~ /$pattern,$pattern,$pattern,$pattern/ );

# Build the ncdiff command

my $outdir = $opt_o ? dirname($opt_o) : '.';
open IN, $opt_f;
my $n = 0;
my @outfiles;
foreach my $pair (<IN>) {
    chomp($pair);
    my ( $xfile, $yfile ) = split( /\s+/, $pair );
    my $j = 0;
    my %outfiles;
    foreach my $file ( $xfile, $yfile ) {
        my @cmd = ( 'ncks', '-O' );
        push @cmd, '-d', sprintf( "lat,%f,%f", $south, $north );
        push @cmd, '-d', sprintf( "lon,%f,%f", $west,  $east );
        my $outfile = "$outdir/" . basename($file);
        my ( $var,  $zinfo, $which );
        my ( $zdim, $zval,  $zunits );
        if ( $j == 0 ) {
            ( $var, $zinfo ) = split( ",", $opt_x );
            $which = 'x';
        }
        else {
            ( $var, $zinfo ) = split( ",", $opt_y );
            $which = 'y';
        }
        if ($zinfo) {
            ( $zdim, $zval, $zunits )
                = ( $zinfo =~ m/(\w+)=([\d\.\-]+)(\w+)/ );
            push @cmd, '-d', sprintf( "%s,%f,%f", $zdim, $zval, $zval );
        }
        $outfile =~ s/\.nc$/.$which.nc/;
        $outfiles{$which} = $outfile;
        my $cmd = join( ' ', @cmd, '-o', $outfile, $file );

        # Subset it
        run_command( 'subsetter',    $cmd );
        run_command( 'remove z dim', "ncwa -a $zdim -O -o $outfile $outfile" )
            if $zdim;
        run_command( 'rename vars',
            "ncrename -v $var,val -O -o $outfile $outfile" );
        $j++;
    }
    my $outfile = "$outdir/timestep.$n.nc";
    run_command( 'differencing',
        "ncdiff -O -o $outfile $outfiles{'x'} $outfiles{'y'}" );
    run_command( 'add latitude weighting',
        "ncap2 -O -o $outfile -s 'coslat=cos(lat*3.14159/180.)' $outfile" );
    run_command( 'area average',
        "ncwa -v val -w coslat -a lat,lon -O -o $outfile $outfile" );
    run_command( 'cleanup', "ncks -x -v lat,lon -O -o $outfile $outfile" );
    run_command( 'recover dataday',
        "ncks -A -o $outfile -v dataday $outfiles{'x'}" );
    unlink( $outfiles{'x'}, $outfiles{'y'} );
    push @outfiles, $outfile;
    $n++;
}
run_command( 'concatenation',
    'ncrcat -O -o ' . $opt_o . ' ' . join( ' ', @outfiles ) );
unlink(@outfiles);
exit(0);

sub run_command {
    my ( $name, $cmd ) = @_;
    print STDERR "USER_INFO $name...\n";
    print STDERR "INFO Running command $cmd\n";
    my $rc = system($cmd);
    if ($rc) {
        print STDERR "USER_ERROR Failed to execute $name\n";
        my $exit_value = $rc >> 8;
        print STDERR "ERROR $name failed with exit code $exit_value\n";
        exit(2);
    }
    return 1;
}
