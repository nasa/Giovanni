#!/usr/bin/env perl

=head1 NAME
    
g4_accumulate.pl - accumulation algorithm for Giovanni-4
    
=head1 SYNOPSIS
      
g4_accumulate.pl -y ttl -f input_file -s start_time -e end_time [-v varname] [-o outfile] 
     [-b bbox] [-z zDimName=zValUnits] 

=head1 DESCRIPTION
  
g4_accumulate.pl computes the accumulation over time at each grid cell in a
list of input netCDF data files. Note that the arguments b<-y ttl> are required,
so that we can use the same code for time averaging as well (some day).
This is just passed through to the call to ncra.
  
=head1 ARGUMENTS

=over 4

=item -y ttl

Argument is required, as is. This is passed through to ncra so that a total is
computed instead of the default average.

=item -f input_file

Pathname of the file containing all the input data files as a simple text list.

=item -s start_time

Start date/time in ISO 8601 format.

=item -e end_time

End date/time in ISO 8601 format.

=item -o outfile

Output netCDF filename.

=item -b bbox

Bounding box, in a comma-separated string (i.e., W,S,E,N). 

=item -v varname

Name of the variable to be averaged.

=item -z zDimName=zValUnits

Horizontal slice to extract from 3-D data, 
e.g., "-z TempPrsLvls_A=500hPa" for the 500 hPa level.

=back

=head1 EXAMPLE

g4_accumulate.pl -y ttl -v AIRX3STD_006_Temperature_A -f airs.txt -b -180,-90.,180.0,90 -z TempPrsLvls_A=850hPa -o airs.nc

=head1 AUTHOR
  
Chris Lynnes, NASA/GSFC
  
=cut 

use strict;
use Getopt::Std;
use File::Basename;
use Giovanni::Data::NcFile;

# Define and parse argument vars
use vars qw($opt_b $opt_v $opt_s $opt_e $opt_f $opt_o $opt_y $opt_z $opt_S);
getopts('b:v:s:e:f:o:z:y:S:');
usage() unless ( $opt_f && $opt_v && $opt_o );
my $file_list = $opt_f;

my $temp_res = get_temporal_resolution($file_list);

# Preprocess monthly data by number of hours in each month
if ( $temp_res =~ /^monthly\b/ ) {
    $file_list = convert_monthly( $file_list, $opt_v, dirname($opt_o) )
        if ( $opt_y eq 'ttl' );
}

# Split the bounding box into its edges
my $pattern = '([\d.+\-]+)';
my ( $west, $south, $east, $north )
    = ( $opt_b =~ /$pattern,$pattern,$pattern,$pattern/ );

# Build the ncra command
my @cmd = ( 'ncra', '-O', '-o', $opt_o, '-v', $opt_v );
push( @cmd, '-y', $opt_y ) if ($opt_y);
push @cmd, '-d', sprintf( "lat,%f,%f", $south, $north );
push @cmd, '-d', sprintf( "lon,%f,%f", $west,  $east );

# If a z-slice is specified, as -z var=valueunits, convert into ncra arg
if ($opt_z) {
    my ( $var, $value, $units ) = ( $opt_z =~ /(\w+)=([\d\.\-]+)(\w+)/ );
    push @cmd, '-d', sprintf( "%s,%f,%f", $var, $value, $value );
}

# For long lists of files, ncra can take them on standard in instead
push @cmd, '<', $file_list;
my $cmd = join( ' ', @cmd );

# Run it!
my $op_type = ( $opt_y eq 'ttl' ) ? 'accumulation' : 'time average';
print STDERR "USER_INFO Computing $op_type for each cell...\n";
print STDERR "INFO Running command $cmd\n";
my $rc = system($cmd);
if ( $rc == 0 ) {
    print STDERR "PERCENT_DONE 99\n";
}
else {
    print STDERR "USER_ERROR Failed to execute time averaging\n";
    my $exit_value = $rc >> 8;
    print STDERR "ERROR Time averager failed with exit code $exit_value\n";
    exit(2);
}

# when units denominator does not match timestep size...
if ( $temp_res =~ /^3-hourly\b/ ) {

    # Convert hourly rate from 3Hourly file to accumulation
    scale_data( $opt_o, $opt_v, $opt_o, 3 );
}
elsif ( $temp_res =~ /^half-hourly\b/i ) {

    # Use "0.5f" so as not to inadvertantly promote to double
    scale_data( $opt_o, $opt_v, $opt_o, "0.5f" );
}

# Cleanup extraneous stuff
warn "INFO cleaning extraneous vars\n";
run_cmd( 'ncwa', '-O', '-o', $opt_o, '-a', 'time', $opt_o );
run_cmd( 'ncatted', '-O', '-o', $opt_o, '-a', "cell_methods,$opt_v,d,,",
    $opt_o );

# Delete the time dimension variable
run_cmd( 'ncks', '-C' ,'-D', 4, '-O', '-o', $opt_o, '-x', '-v', "time", $opt_o );

# Remove time_bnds variable
run_cmd( 'ncks', '-O', '-x', '-v', 'time_bnds', $opt_o, $opt_o);

# Convert the units from accumulation rate
convert_rate_units( $opt_o, $opt_v );
print STDERR "PERCENT_DONE 100\n";
exit(0);

sub usage {
    die
        "Usage: $0 [-y ttl] -b bbox [-z slice] -v var -s start -e end -f infile -o outfile\n";
}

sub get_units {
    my ( $ncfile, $var ) = @_;
    my ( $rh_atthash, $ra_attlist )
        = Giovanni::Data::NcFile::variable_attributes( $ncfile, $var, 0 );
    return undef unless exists $rh_atthash->{units};

# Split up units and look for time-related denominators, starting from the end
    my $units = $rh_atthash->{units};
    my @parts = reverse split( '/', $units );
    pop @parts;
    my %time_units
        = map { ( $_, 1 ) } qw(s sec min hr hour day mon month yr year annum);
    my ($rate) = grep { exists $time_units{$_} } @parts;
    return ( $units, $rate );
}

sub convert_rate_units {
    my ( $ncfile, $var ) = @_;

# Delete non-standard "Units"
# Yes, there are side-effects in the lat/lon variables, but it's simpler allround
    run_cmd( 'ncatted', '-O', '-o', $ncfile, '-a', 'Units,,d,,', $ncfile );

    # Extract units for the variable in question
    my ( $units, $rate ) = get_units( $ncfile, $var );
    return 1 unless ( $units && $rate );

    my ( $rh_atthash, $ra_attlist )
        = Giovanni::Data::NcFile::variable_attributes( $ncfile, $var, 1 );

    # Found a time denominator; eliminate it.
    $units =~ s#/$rate##;
    my @ncatted = ( 'ncatted', '-O', '-o', $ncfile );
    push @ncatted, '-a', "units,$var,o,c,$units";

# TO DO:  instead of pattern substitution, add info on accumulation long_name via EDDA
    if ( exists $rh_atthash->{long_name} ) {
        $rh_atthash->{long_name} =~ s/Rate/Total/i;
        push @ncatted, '-a', "long_name,$var,o,c,$rh_atthash->{long_name}";
    }

    push @ncatted, $ncfile;
    my $cmd = join( ' ', @ncatted );
    warn "INFO running $cmd\n";
    run_cmd(@ncatted);
    return 1;
}

sub get_temporal_resolution {
    return (
        `head -1 $_[0] | xargs -I nc ncks -M nc | awk '/temporal_resolution,/ {print \$11}'`
    );
}

sub convert_monthly {
    my ( $file_list, $var, $outdir ) = @_;

  # Look at first input file for temporal resolution and return if not monthly
    my $temp_res
        = `head -1 $file_list | xargs -I nc ncks -M nc | awk '/temporal_resolution,/ {print \$11}'`;
    return $file_list unless ( $temp_res =~ /^monthly/ );

    # Form new file list
    $outdir = '.' unless $outdir;
    my $new_list = "$outdir/tmp.$$." . basename($file_list);

    # Process each file
    open IN, $file_list or die "Cannot open input file list $file_list\n";
    my @days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my ( $first_file, $to_days_multiplier );
    foreach my $infile (<IN>) {
        chomp($infile);
        if ( !$first_file ) {
            $first_file = $infile;
            $to_days_multiplier = convert_rate_to_days( $infile, $var );
            warn
                "INFO:  multipler to convert to days = $to_days_multiplier\n";

            # If no rate denominator, then nothing to see here, move along
            if ( $to_days_multiplier == 0. ) {
                close(IN);
                return $file_list;
            }
            else {
                open OUT, '>', $new_list
                    or die "Cannot write to output file list $new_list\n";
            }
        }

        # Construct new (temporary) input file
        my $multiplier;
        my $outfile   = "$outdir/tmp.$$." . basename($infile);
        my $datamonth = `ncks -s '%d' -C -H -v datamonth $infile`;
        die "ERROR Cannot find datamonth in $infile\n" unless $datamonth;
        my $yyyy  = substr( $datamonth, 0, 4 );
        my $month = substr( $datamonth, 4, 2 ) - 1;
        my $days  = $days_in_month[$month];

        # If month is February (1 in zero-indexed world), see if leap year
        if ( $month == 1 ) {
            $days++
                if ( ( ( $yyyy % 4 ) == 0 )
                && ( ( ( $yyyy % 100 ) != 0 ) || ( ( $yyyy % 400 ) == 0 ) ) );
        }
        $multiplier = $to_days_multiplier * $days;
        scale_data( $infile, $var, $outfile, $multiplier );
        print OUT "$outfile\n";
    }
    close(IN);
    close(OUT);
    return $new_list;
}

sub convert_rate_to_days {
    my ( $infile, $var ) = @_;
    my ( $units, $rate ) = get_units( $infile, $var, 0 );
    return 0. if ( $rate =~ /^mon/ || !$rate );
    return 1. if ( $rate =~ /^day/ );
    return 24.             if ( $rate =~ /^h(ou)*r/ );
    return ( 24. * 60. )   if ( $rate =~ /^min/ );
    return ( 24. * 3600. ) if ( $rate =~ /^sec/ );
    die "ERROR Cannot recognize rate $rate\n";
}

sub scale_data {
    my ( $infile, $var, $outfile, $multiplier ) = @_;
    run_cmd( 'ncap2', '-O', '-o', $outfile, '-s', "$var = $var * $multiplier",
        $infile );
    return 1;
}

sub run_cmd {
    my @cmd = @_;
    my $cmd = join( ' ', @cmd );
    warn("INFO Running $cmd\n");
    my $rc = system(@cmd);
    if ($rc) {
        die "Execution failed for $cmd\n";
    }
    return 1;
}
