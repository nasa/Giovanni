#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

=head1 NAME

spatialTemporalAverager.pl - Spatial and temporal averaging using NCO

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

spatialTemporalAverager.pl [--help] [--verbose] --input infile --outDir output-directory --bbox bbox

=head1 DESCRIPTION

This program computes averages over both space and time of variables.  The spatial averaging is latitude-
weighted.  Area averaging is performed first at individual time points, followed by averaging over time.

=head1 OPTIONS

=over 4

=item --help
Print a usage information

=item --verbose
Turn on verbose mode

=item --input infile
Input file that contains a list of data files

=item --outDir output-directory
Output directory

=item --bbox bbox
Bounding box specified as "lonW,latS,lonE,latN"

=back

=head1 AUTHOR

Jianfu Pan (jianfu.pan@nasa.gov)

=cut

use lib ".";

use strict;
use Getopt::Long;
use File::Basename;
use Giovanni::Algorithm::AreaAveragerNco;
use File::Basename;

my $cmd_dir = dirname($0);
our $cmd_getdimnames    = "$cmd_dir/getNcDimList.py";
our $cmd_getvarnames    = "$cmd_dir/getNcVarList.py";
our $cmd_getfillvalues  = "$cmd_dir/getNcFillValue.py";
our $cmd_getregionlabel = "$cmd_dir/getNcRegionLabel.py";
our $cmd_getresolution  = "$cmd_dir/getNcResolution.py";

my $help;
my $debug_level = 0;
my $verbose;
my $infile;
my $outdir = "./output";
my $bbox   = "-180,-90,180,90";
my $result = GetOptions(
    "help"      => \$help,
    "h"         => \$help,
    "verbose=s" => \$verbose,
    "input=s"   => \$infile,
    "i=s"       => \$infile,
    "outDir=s"  => \$outdir,
    "bbox=s"    => \$bbox,
    "b=s"       => \$bbox
);

my $usage
    = "Usage: $0 [--help] [--verbose] --input infile --outDir output-directory\n"
    . "    --help           Print this help info\n"
    . "    --verbose        Print out lot of messages\n"
    . "    --input infile   A text file of nc file list\n"
    . "    --outDir outdir  Session directory\n"
    . "    --bbox   bbox    Bounding box specified as \"lonW,latS,lonE,latN\"\n";

# Print usage and exit if that's all asked for
if ($help) {
    print STDERR $usage;
    exit(0);
}

# Check required options
die("ERROR infile missing") unless -s $infile;

# Validate options
die("ERROR Invalid bbox: $bbox") unless $bbox =~ /^[0-9.,-]+$/;

# Create output directory if it doesn't exist
if ( !-d $outdir ) {
    mkdir( $outdir, 0755 ) || die("ERROR Fail to make output dir $outdir");
}

print STDERR "USER_MSG Executing spatial-temporal averager\n";
print STDERR
    "STEP_DESCRIPTION Spatial and temporal averaging over the selected region and time period\n";

# Get a list of nc files from infile

open( INFILE, "<$infile" ) or die("ERROR Unable to open file $infile");
my @files_read = <INFILE>;
close(INFILE);
my @files;
foreach my $f (@files_read) {
    chomp($f);
    push( @files, $f );
}

#
# Get start/end times of the data period from the first and last files
#
my $start_time = `ncks -M $files[0] | grep start_time`;
if ($?) {
    print
        "WARN Fail to get start time: ncks -M $files[0] | grep start_time ($!)\n";
}
else {
    ($start_time) = ( $start_time =~ /value\s*=\s*(\d\d\d\d-.+Z)/ );
}
my $end_time = `ncks -M $files[-1] | grep end_time`;
if ($?) {
    print
        "WARN Fail to get end time: ncks -M $files[-1] | grep end_time ($!)\n";
}
else {
    ($end_time) = ( $end_time =~ /value\s*=\s*(\d\d\d\d-.+Z)/ );
}

#
# Do averaging on files
#

my $N        = scalar(@files);
my $N_report = 1;
$N_report = int( $N / 10 ) if $N > 100;

# Find information from first file, assuming others in the list are the same

my $f      = $files[0];
my $f_last = $files[-1];
my $fout   = get_outfile_name( $outdir, $f, $f_last, $bbox );
my $dims   = get_latlon_names($f);
my ( $vars, $dataday_name ) = get_varnames($f);

my $miss = get_fillvalues($f);
if ( $miss eq "" ) {
    die("ERROR Fill value not found in $f");
}
my $reso = `$cmd_getresolution $f`;
if ($?) { die "ERROR Fail to get spatial resolution\n"; }
chomp($reso);

# Call area averager to get time series
my $rc = Giovanni::Algorithm::AreaAveragerNco::area_averager( $infile, $fout,
    $dims, $vars, $dataday_name, $miss, $bbox, $reso );

# Time averaging
`ncwa -h -O -a time $fout $fout.tmp`;
if ($?) {
    die "ERROR ncwa failed: ncwa -h -O -a time $fout $fout.tmp\n";
}
else {

    # Remove dataday and time from the output
    my $exclude_vars = "time";
    $exclude_vars = "time,$dataday_name" if $dataday_name;
    `ncks -h -O -x -v $exclude_vars $fout.tmp $fout`;
    if ($?) {
        print STDERR
            "WARNING Fail to exclude $exclude_vars (ncks -h -O -x -v $exclude_vars $fout.tmp $fout). Ignore.\n";
        `mv $fout.tmp $fout`;
    }
    else {
        `rm -f $fout.tmp`;
    }

    #-    `mv $fout.tmp $fout`;
}

#
# Add time bounds variable
#
my $start_time_epoch = $start_time;
$start_time_epoch =~ s/T|Z/ /g;
$start_time_epoch = `date -d \"$start_time_epoch\" +%s`;
chomp($start_time_epoch);
my $end_time_epoch = $end_time;
$end_time_epoch =~ s/T|Z/ /g;
$end_time_epoch = `date -d \"$end_time_epoch\" +%s`;
chomp($end_time_epoch);

my $output_time_bnds
    = `ncap2 -h -O -s 'defdim("bnds",2);time_bnds[\$bnds]={$start_time_epoch,$end_time_epoch};time_bnds\@long_name="Time Bounds"' $fout $fout.tmp`;
if ($?) {
    die
        "ERROR Fail to create time_bnds (ncap2 -h -O -s 'defdim(\"bnds\",2);time_bnds[\$bnds]={$start_time_epoch,$end_time_epoch};time_bnds\@long_name=\"Time Bounds\"' $fout) [$output_time_bnds]\n";
}
else {
    `mv $fout.tmp $fout`;
}

#
# Add "coordinates" attribute to non-dimension variables
#

my $coord = `$cmd_getdimnames $fout`;
$coord =~ s/\blat\b|\blon\b|\btime\b/ /g;
$coord =~ s/\s+/ /g;
$coord =~ s/\s+$//;
foreach my $v (@$vars) {
    `ncatted -h -O -a "coordinates,$v,o,c,$coord" $fout`;
}

#
# Modify start/end time global attributes
#

`ncatted -O -h -a "start_time,global,o,c,$start_time" $fout`;
print STDERR
    "WARN Failed to update start times: ncatted -a start_time,global,o,c \"$start_time\" $fout ($!)\n"
    if $?;
`ncatted -O -h -a "end_time,global,o,c,$end_time" $fout`;
print STDERR
    "WARN Failed to update end times: ncatted -a end_time,global,o,c \"$end_time\" $fout ($!)\n"
    if $?;

#
# Set title attribute with region label
#

#- my $region_label = `$cmd_getregionlabel $f`;
#- chomp $region_label;
$bbox =~ s/\s| //g;
my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );
if ( $lonW =~ /^-/ ) {
    $lonW =~ s/^-//;
    $lonW = "${lonW}W";
}
else {
    $lonW = "${lonW}E";
}
if ( $lonE =~ /^-/ ) {
    $lonE =~ s/^-//;
    $lonE = "${lonE}W";
}
else {
    $lonE = "${lonE}E";
}

if ( $latS =~ /^-/ ) {
    $latS =~ s/^-//;
    $latS = "${latS}S";
}
else {
    $latS = "${latS}N";
}
if ( $latN =~ /^-/ ) {
    $latN =~ s/^-//;
    $latN = "${latN}S";
}
else {
    $latN = "${latN}N";
}

my $region_label = "$lonW - $lonE, $latS - $latN";
`ncatted -O -h -a "bounding_box,global,o,c,$bbox" $fout`;

my $title = "Vertical Profile($region_label)";
`ncatted -h -O -a "title,global,o,c,$title" $fout`;
print STDERR "OUTPUT $fout\n";

exit(0);

sub get_latlon_names {
    my ($infile) = @_;

    my @names = ();

    my $lat_str = `$cmd_getdimnames -t lat $infile`;
    die("ERROR Failed to find lat name: $cmd_getdimnames -t lat $infile")
        if $?;
    $lat_str =~ s/^\s+|\s+$//;
    push( @names, $lat_str );

    my $lon_str = `$cmd_getdimnames -t lon $infile`;
    die("ERROR Failed to find lon name: $cmd_getdimnames -t lon $infile")
        if $?;
    $lon_str =~ s/^\s+|\s+$//;
    push( @names, $lon_str );

    return \@names;
}

sub get_varnames {
    my ($infile) = @_;

    my @names        = ();
    my $dataday_name = undef;
    my $names_str    = `$cmd_getvarnames $infile`;
    if ($?) {
        die("ERROR Failed to find variable names: $cmd_getvarnames $infile");
    }
    else {
        $names_str =~ s/^\s+|\s+$//;
        my @names_tmp = split( '\s+', $names_str );
        foreach my $n (@names_tmp) {
            if ( $n eq "dataday" or $n eq "datamonth" ) {
                $dataday_name = $n;
            }
            else {
                push( @names, $n );
            }
        }
    }

    return ( \@names, $dataday_name );
}

sub get_fillvalues {
    my ($infile) = @_;

    my $fillvalue;
    my $fill_str = `$cmd_getfillvalues $infile`;
    if ($?) {
        warn("INFO No fill value found in $infile");
    }
    else {
        $fill_str =~ s/^\s+|\s+$//;
        ($fillvalue) = split( '\s+', $fill_str );
    }

    return $fillvalue;
}

# ====================================================================
# get_outfile_name($outdir, $infile, $infile_last, $bbox)
# Description: This function generates an output file name by deriving
#   it from the input file name plus additional information.
# ====================================================================
sub get_outfile_name {
    my ( $outdir, $infile, $infile_last, $bbox ) = @_;

    # Create bbox string as part of file name
    my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

    # Remove decimal digits
    my $foo;
    ( $lonW, $foo ) = split( '\.', $lonW, 2 );
    ( $lonE, $foo ) = split( '\.', $lonE, 2 );
    ( $latS, $foo ) = split( '\.', $latS, 2 );
    ( $latN, $foo ) = split( '\.', $latN, 2 );

    my $bbox_string = "";
    if ( $lonW < 0 ) {
        $bbox_string = abs($lonW) . "W";
    }
    else {
        $bbox_string = $lonW . "E";
    }
    if ( $latS < 0 ) {
        $bbox_string .= "_" . abs($latS) . "S";
    }
    else {
        $bbox_string .= "_" . $latS . "N";
    }
    if ( $lonE < 0 ) {
        $bbox_string .= "_" . abs($lonE) . "W";
    }
    else {
        $bbox_string .= "_" . $lonE . "E";
    }
    if ( $latN < 0 ) {
        $bbox_string .= "_" . abs($latN) . "S";
    }
    else {
        $bbox_string .= "_" . $latN . "N";
    }

    # Start with infile basename, split it in parts
    my $in_name = basename($infile);
    my @in_parts = split( '\.', $in_name );

    # Remove step name in the front and extension in the end
    shift(@in_parts);
    pop(@in_parts);

    # Remove and retain date
    my $T0 = pop(@in_parts);

    # Get end date from the last file
    my $in_name_last  = basename($infile_last);
    my @in_parts_last = split( '\.', $in_name_last );
    my $T1            = $in_parts_last[-2];

    my $out_name = join( '.', @in_parts );
    return "$outdir/averaged.$out_name.$T0-$T1.$bbox_string.nc";
}
