#!/usr/bin/env perl

=head1 NAME

g4_area_avg_scatter.pl - time series of area averages of differences between two variables

=head1 SYNOPSIS

g4_scatterplot.pl 
  -f input_file 
  -s start_time -e end_time 
  -x varname,zdim=zValunits  -y varname
  [-o outfile] 
  [-b bbox]

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

=item -x, -y varname

Name of the variables to be compared.

=item -z zDimName=zValUnits

Horizontal slice to extract from 3-D data, 
e.g., "-z TempPrsLvls_A=500hPa" for the 500 hPa level.

=back

=head1 EXAMPLE

g4_scatterplot.pl -b 3.0557,2.5063,11.4053,7.6919 -s 2010-01-01T00:00:00Z -e 2010-02-28T23:59:59Z -x AIRX3STD_006_TotO3_A -y OMTO3d_003_ColumnAmountO3 -f /home/rstrub/files57Ce6.txt -o scatter.AIRX3STD_006_TotO3_A+OMTO3d_003_ColumnAmountO3.20100101-20100228.3E_2N_11E_7N.nc -l ./lineage_extras_mJdSE.txt


=head1 AUTHOR

Richard Strub, Adnet Systems

=cut

use strict;
use Getopt::Std;
use File::Basename;
use Giovanni::Util;
use Giovanni::Data::NcFile;
use Giovanni::Algorithm::AreaAvgDiff;
use Giovanni::Algorithm::AreaAveragerNco;
use Giovanni::Algorithm::CorrelationWrapper;
use File::Copy;

# Define and parse argument vars
use vars qw($opt_b $opt_x $opt_y $opt_s $opt_e $opt_f $opt_o $opt_l);
getopts('b:x:y:s:e:f:o:z:l:');

my $outdir = $opt_o ? dirname($opt_o) : '.';

# Step 0: Wrapper seems to have already taken care of regridding,pairing up the files, and crossing the anti-meridian

# Step 1: Cut input file in two
my @infiles = split_input_file( $opt_f, $outdir );

# Run straight area average on each file
my @field_args = ( $opt_x, $opt_y );
my @fields = @field_args;
my ( @vars, @time_series );
my @time_series = map { $opt_o . '.' . $_ } ( 0 .. 1 );

# Step 2: get matched_start_time, matched_end_time global variables
my ( $stime, $etime )
    = Giovanni::Algorithm::CorrelationWrapper::get_start_end_times($opt_f);

my @bbox = split( /,\s*/, $opt_b );
foreach (@bbox) { $_ = sprintf( "%f", $_ ) }

foreach my $i ( 0 .. 1 ) {

    # Step 3: Get z dimension info
    my $zdim;
    my $zvarname;
    my ( $var, $zinfo ) = split( ',', $field_args[$i] );
    ( $fields[$i], $zdim, $zvarname ) = get3dstring( $field_args[$i] );

    # Step 4: Shorten file names (using filelist, not '*' for ncrcat
    my $smallfilenames = Giovanni::Algorithm::AreaAveragerNco::localize_files(
        $infiles[$i] );
    my $inputfiles = join( ' ', @$smallfilenames );

# Step 5: subset and concatenate: If zdim exists this will add the syntax to do that slicing:
    my $cmd
        = qq(ncrcat -h -o  $time_series[$i] $zdim -d lat,$bbox[1],$bbox[3] -d lon,$bbox[0],$bbox[2]  $inputfiles);
    unlink( $time_series[$i] );
    run_command(
        'Concatenating and subsetting ' 
            . $var
            . ' files into a single file for analysis',
        $cmd
    );

# Step 6: if zdim exists (now only a single slice so not REALLY important, remove it with ncwa
    if ($zvarname) {

        # ncwa -O -h -a TempPrsLvls_D,TempPrsLvls_A start.nc next.nc
        my $thisStepFile = $time_series[$i];
        $thisStepFile =~ s/.nc//;
        $thisStepFile .= "_no$zvarname.nc";

        # I think we want this message to be the same as above:
        run_command(
            'Concatenating and subsetting  ' 
                . $var
                . '  files into a single file for analysis',
            "ncwa -O -h -a $zvarname  $time_series[$i] $thisStepFile"
        );
        $time_series[$i] = $thisStepFile;
    }
}

# Step 7:  Add the second time series into the first file...
# But before we can do that:
# 1) Make sure lat/lon have the same data type
# 2) Let's convert both files to the same format.
#    Otherwise, ncks might
#     freak out if model / compression is not the same
#     in both files, see bug 31507.
#     Let's start with NetCDF4 Classic. If that fails -
#     move on to NetCDF3 Classic.
# 3) Variables may contain different time metadata
#    so we need need to check the time dimension and time_bnds
#    variable values for equality. If either time or time_bnds
#    metadata are not equal, then we need to have more than one
#    time dimension.
# 4) Merge the two files into one

# Check lat and lon dimensions have the same data type.
# If they do not - convert lat/lon to double
my $lon_dtype_f1
        = `ncap2 -O -s 'mtype=lon.type();print(mtype);' -o $time_series[0].tmp $time_series[0] 2>&1 | grep -oE '[0-9]+'`;
my $lon_dtype_f2
        = `ncap2 -O -s 'mtype=lon.type();print(mtype);' -o $time_series[1].tmp $time_series[1] 2>&1 | grep -oE '[0-9]+'`;
my $lat_dtype_f1
        = `ncap2 -O -s 'mtype=lat.type();print(mtype);' -o $time_series[0].tmp $time_series[0] 2>&1 | grep -oE '[0-9]+'`;
my $lat_dtype_f2
        = `ncap2 -O -s 'mtype=lat.type();print(mtype);' -o $time_series[1].tmp $time_series[1] 2>&1 | grep -oE '[0-9]+'`;
if ($lon_dtype_f1 != $lon_dtype_f2 || $lat_dtype_f1 != $lat_dtype_f2) {
	run_command('Convert lat/lon to double on file 1',
		"ncap2 -O -s 'lon=double(lon);lat=double(lat);' -o $time_series[0] $time_series[0]");
	run_command('Convert lat/lon to double on file 2',
		"ncap2 -O -s 'lon=double(lon);lat=double(lat);' -o $time_series[1] $time_series[1]");
}
unlink( '$time_series[0].tmp.nc', '$time_series[1].tmp.nc' ); # Cleanup after NCO

# Get the XML dump of the metadata for each file
my $xpc_0 = Giovanni::Data::NcFile::get_xml_header( $time_series[0] );
my ($startTimeNode_0)
    = $xpc_0->findnodes(
    qq(/nc:netcdf/nc:attribute[\@name="start_time"]/\@value));
my $startTime_0 = $startTimeNode_0->getValue();
my ($endTimeNode_0)
    = $xpc_0->findnodes(
    qq(/nc:netcdf/nc:attribute[\@name="end_time"]/\@value));
my $endTime_0 = $endTimeNode_0->getValue();

my @values_0
    = Giovanni::Data::NcFile::get_variable_values( $time_series[0], "time",
    ("time") );

my $xpc_1 = Giovanni::Data::NcFile::get_xml_header( $time_series[1] );
my ($startTimeNode_1)
    = $xpc_1->findnodes(
    qq(/nc:netcdf/nc:attribute[\@name="start_time"]/\@value));
my $startTime_1 = $startTimeNode_1->getValue();
my ($endTimeNode_1)
    = $xpc_1->findnodes(
    qq(/nc:netcdf/nc:attribute[\@name="end_time"]/\@value));
my $endTime_1 = $endTimeNode_1->getValue();

my @values_1
    = Giovanni::Data::NcFile::get_variable_values( $time_series[1], "time",
    ("time") );

# Check the time dimension and start/end time attributes.
# We could have multiple time periods, but we only need to check the
# first index in each file. We also need to check the global attributes
# ($start_time and $end_time) and compare the strings.
my $value_0   = int( $values_0[0] );    # These need to be type integer
my $value_1   = int( $values_1[0] );
my $time_flag = @_;

if ((   ( $startTime_0 ne $startTime_1
        )    # Be careful here, 'ne' should be used with string comparison
        or ( $endTime_0 ne $endTime_1 )
    )
    or ( $value_0 != $value_1 )
    )        # A logical expression "!=" is used for comparing numbers
{

    $time_flag = "1";

    # Modify time dimension for variable 1
    modify_time_dim( $fields[0], $time_series[0] );

    # Modify time dimension for variable 2
    modify_time_dim( $fields[1], $time_series[1] );
}

my $tmp_nc = $time_series[0] . '.tmp.nc';
my $rc;
my @cmd;
for my $ncVersion ( 7, 3 ) {
    run_command( 'uncompress',
        "ncks --$ncVersion -O -o $time_series[0] $time_series[0]" );
    run_command( 'uncompress',
        "ncks --$ncVersion -O -o $time_series[1] $time_series[1]" );
    copy( $time_series[0], $tmp_nc );
}

if ( $time_flag eq "1" ) {

    # If we modified the time metadata we need to merge the files
    @cmd = ( 'ncks', '-A', $time_series[1], $tmp_nc );
    warn "INFO Merging the two files together: " . join( ' ', @cmd ) . "\n";
    $rc = system(@cmd);
}
else {

# We had the same time dimensions and global start/end times so just merge the variables
    @cmd = ( 'ncks', '-A', '-v', $fields[1], '-o', $tmp_nc, $time_series[1] );
    warn "INFO Merging the two variables together: "
        . join( ' ', @cmd ) . "\n";
    $rc = system(@cmd);
}

if ( $rc != 0 ) {
    print STDERR "USER_ERROR Failed to merge the two variables together\n";
    my $exit_value = $rc >> 8;
    print STDERR "ERROR "
        . join( ' ', @cmd )
        . " failed with exit code $exit_value\n";
    exit(2);
}

# Cleanup
move( $tmp_nc, $time_series[0] );

# Step 8: prepend variable names with _x,_y, add matched start and end time global vars:
run_command(
    'Populating the output file with the overall start and end times',
    "ncatted -O -h -a matched_start_time,global,a,c,$stime $time_series[0]"
);
run_command(
    'Populating the output file with the overall start and end times',
    "ncatted -O -h -a matched_end_time,global,a,c,$etime $time_series[0]"
);
run_command(
    '   ',
    "ncrename -v $fields[0],x_$fields[0] -O -o $time_series[0] $time_series[0]"
);
run_command(
    '   ',
    "ncrename -v $fields[1],y_$fields[1] -O -o $time_series[0] $time_series[0]"
);

# $Step 9: give outputfile it's expected name and change to netcdf3. ncks -A sometimes has a problem with netcdf4:
#Giovanni::Data::NcFile::to_netCDF3($time_series[0], $opt_o) or die "ERROR failed to convert $time_series[0] to classic $opt_o: $!\n";
move( $time_series[0], $opt_o )
    or die "ERROR failed to move $time_series[0] to $opt_o: $!\n";
unlink( $time_series[1], @infiles );
exit(0);

sub get3dstring {
    my $var = shift;
    my ( $name, $zarg ) = split( /,/, $var, 2 );
    if ( defined($zarg) ) {
        my ( $zvar, $zval, $zunits ) = ( $zarg =~ m/(\w+?)=([.\d]+)(\w+)/ );
        quit( "Failed to run time averager command",
            "Failed to parse Z variable in $zarg\n", 12 )
            unless $zvar;
        my $string = sprintf( "-d %s,%f,%f", $zvar, $zval, $zval );
        return ( $name, $string, $zvar );
    }
    return ($name);
}

sub split_input_file {
    my ( $file, $outdir ) = @_;
    my @outfiles;
    $outdir = '.' unless $outdir;
    foreach my $i ( 0 .. 1 ) {
        $outfiles[$i] = "$outdir/" . basename($file) . ".$i";
        my $cmd = sprintf( "cut --delimiter=' ' --field=%d %s > %s",
            $i + 1, $file, $outfiles[$i] );
        run_command( "Setting up files for processing", $cmd );
    }
    return @outfiles;
}

sub modify_time_dim {

    # If the time dimension values are not equal then we need to
    # # define unique time dimension attributes.
    # # To accomplish this, first we will use ncap2 to associate the
    # # time with variable 1. i.e. we will use "time_$var1=time"
    # # Next we will remove time dimension from file 1, rename time bounds,
    # # change the long_name attribute,
    # # and finally change the bound attribute.

    my ( $var, $file ) = @_;

    @cmd = ( 'ncap2', '-s', "time_$var=time", '-O', $file, $file );
    run_command( "Changing time attribute to identify with $var", @cmd );

    @cmd = ( 'ncks', '-x', '-C', '-O', '-v', 'time', $file, $file );
    run_command( "Removing time variable from $var", @cmd );

    @cmd
        = ( 'ncrename', '-h', '-O', '-v', "time_bnds,time_bnds_$var", $file );
    run_command( "Rename time bounds to identify with $var", @cmd );

    @cmd = (
        'ncatted', '-O', '-a', "long_name,time_$var,o,c,Time for $var", $file
    );
    run_command( "Change :long_name attribute time_$var in $file", @cmd );

    @cmd = (
        'ncatted', '-O', '-a', "bounds,time_$var,o,c,time_bnds_$var", $file
    );
    run_command( "Change :bounds attribute for time_$var in $file", @cmd );
}
