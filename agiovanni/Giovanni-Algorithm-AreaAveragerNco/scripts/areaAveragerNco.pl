#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

=head1 NAME

areaAveragerNco.pl - Area average of a netcdf file using NCO

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

areaAveragerNco.pl [--help] [--verbose] --input infile --outDir outdir --bbox bbox -z zname=zvalue

=head1 DESCRIPTION

This program computes latitude-weighted averages of variables.
Most attributes of a variable will be carried over from the original
variable.

=head1 OPTIONS

=over 4

=item --help
Print a usage information

=item --verbose
Turn on verbose mode

=item --input infile
Input file that contains a list of data files

=item --outDir outdir
Session directory or working directory

=item --bbox bbox
Bounding box specified as "lonW,latS,lonE,latN"

=item --varinfo varInfo.xml
Variable information file

=item -z zname=zvalue
A single level of user selection, with zname being the z-dimension variable name 
and zvalue the selected level.

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
my $outdir  = "./output";
my $bbox    = "-180,-90,180,90";
my $varinfo = undef;
my $level   = undef;
my $result  = GetOptions(
    "help"      => \$help,
    "h"         => \$help,
    "verbose=s" => \$verbose,
    "input=s"   => \$infile,
    "i=s"       => \$infile,
    "varinfo=s" => \$varinfo,
    "v=s"       => \$varinfo,
    "z=s"       => \$level,
    "outDir=s"  => \$outdir,
    "bbox=s"    => \$bbox,
    "b=s"       => \$bbox
);

my $usage
    = "Usage: $0 [--help] [--verbose] --input infile -v varInfo.xml --level level --outDir outdir\n"
    . "    --help           Print this help info\n"
    . "    --verbose        Print out lot of messages\n"
    . "    --input infile   A text file of nc file list\n"
    . "    -v varInfo.xml   varInfo file\n"
    . "    -z level         Level selection as zname=zvalue\n"
    . "    --outDir outdir  Session directory\n"
    . "    --bbox   bbox    Bounding box specified as \"lonW,latS,lonE,latN\"\n";

# Print usage and exit if that's all asked for
if ($help) {
    print STDERR $usage;
    exit(0);
}

$level = undef if defined($level) and $level =~ /=na/i;

# Check required options
die("ERROR infile missing") unless -s $infile;

# Validate options
die("ERROR Invalid bbox: $bbox") unless $bbox =~ /^[0-9.,-]+$/;

# Change to working directory, make one if it doesn't exist
if ( !-d $outdir ) {
    mkdir( $outdir, 0755 ) || die("ERROR Fail to make session dir $outdir");
}

print STDERR "USER_MSG Executing area averager\n";
print STDERR "STEP_DESCRIPTION Area averaging over the selected region\n";

# Get a list of nc files from infile

open( INFILE, "<$infile" ) or die("ERROR Unable to open file $infile");
my @files_read = <INFILE>;
close(INFILE);
my @files;
foreach my $f (@files_read) {
    chomp($f);
    push( @files, $f );
}

# Subset out the level
my ( $zname, $zvalue, $zunits ) = ( undef, undef, undef );
if ( defined($level) ) {
    ( $zname, $zvalue, $zunits ) = ( $level =~ /^(.+)=([\d\.]+)(.*)$/ );
    die "ERROR Invalid level argument ($level)\n"
        unless $zname and defined($zvalue);
    $infile = subset_level( $zname, $zvalue, \@files, $infile );
}

#
# Get start/end times of the data period
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
# Process nc files
#

my $N        = scalar(@files);
my $N_report = 1;
$N_report = int( $N / 10 ) if $N > 100;

#
# Find information from first file, assuming others in the list are the same
#

my $f      = $files[0];
my $f_last = $files[-1];
my $fout   = get_outfile_name( $outdir, $f, $f_last, $bbox, $level );
my $dims   = get_latlon_names($f);
my ( $vars, $dataday_name ) = get_varnames( $f, { 'exclude' => [$zname] } );

my $miss = get_fillvalues( $f, $vars->[0] );
if ( $miss eq "" ) {
    die("ERROR Fill value not found in $f");
}
my $reso = `$cmd_getresolution $f`;
if ($?) { die "ERROR Fail to get spatial resolution\n"; }
chomp($reso);

my $rc = Giovanni::Algorithm::AreaAveragerNco::area_averager( $infile, $fout,
    $dims, $vars, $dataday_name, $miss, $bbox, $reso );

#
# Fix variable attributes
#

# Get name of time dimension
my $coord_time = `$cmd_getdimnames -t time $fout`;
$coord_time =~ s/^\s+|\s+$//;
foreach my $v (@$vars) {

    # Add "coordinates" attribute to non-dimension variables
    `ncatted -h -O -a "coordinates,$v,o,c,$coord_time" $fout`;

    fix_variable_level_attributes( $v, $files[0], $fout, $zname, $zvalue,
        $zunits )
        if defined($level);
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

my $title = "Area-Averaged Time Series ($region_label)";
`ncatted -h -O -a "title,global,o,c,$title" $fout`;
print STDERR "OUTPUT $fout\n";

exit(0);

sub fix_variable_level_attributes {
    my ( $vname, $file, $outfile, $zname, $zvalue, $zunits ) = @_;
    return $outfile unless defined($zname) and defined($zvalue);

    # Get z-type
    my $ztype = "z";
    if ( $zunits eq "hPa" ) {
        $ztype = "pressure";
    }

    # Set z attributes in output file
    `ncatted -h -O -a "z_slice_type,$vname,o,c,$ztype" $outfile`;
    if ($?) {
        print STDERR
            "WARN NCO failed (ncatted -h -O -a \"z_slice_type,$vname,o,c,$ztype\" $outfile)\n";
    }
    `ncatted -h -O -a "z_slice,$vname,o,c,$zvalue$zunits" $outfile`;
    if ($?) {
        print STDERR
            "WARN NCO failed (ncatted -h -O -a \"z_slice,$vname,o,c,$zvalue$zunits\" $outfile)\n";
    }
}

sub subset_level {
    my ( $zname, $level, $files, $infile ) = @_;
    return $infile unless defined($zname) and defined($level);

    my $infile_new = "$infile.subset";
    open( INFILE, ">$infile_new" ) || die;

    # Make sure level is a float
    $level = "$level." unless $level =~ /\./;

    # Subset files
    foreach my $f (@$files) {
        my ( $prefix, $rest ) = split( '\.', $f, 2 );
        my $file_subset = "subsetted.$rest";
        `ncks -h -O -d $zname,$level,$level $f $f.tmp`;
        die
            "ERROR ncks failed (ncks -h -O -d $zname,$level,$level $f $f.tmp). $!"
            if $?;
        `ncwa -h -O -a $zname $f.tmp $file_subset`;
        die "ERROR ncwa failed (ncwa -h -O -a $zname $f.tmp $file_subset). $!"
            if $?;
        `rm -f $f.tmp`;
        print INFILE "$file_subset\n";
    }

    close(INFILE);

    return $infile_new;
}

# find_zname() - Find variable name of z-dimension
# LIMITATION: This script doesn't consider multiple z dimensions in a file
sub find_zname {
    my ($file) = @_;

    # Find z-dimension name in a file
    my $zdim_name = `$cmd_getdimnames -t z $file`;
    chomp($zdim_name);
    $zdim_name =~ s/^\s+|\s+$//g;
    if ($zdim_name) {
        return $zdim_name;
    }
    else {
        return undef;
    }
}

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
    my ( $infile, $option ) = @_;

    my @names        = ();
    my $dataday_name = undef;
    my $tbnds_name   = undef;
    my %exclude      = ();
    if ( exists( $option->{'exclude'} ) ) {
        my $excludes = $option->{'exclude'};
        foreach my $v (@$excludes) { $exclude{$v} = 1; }
    }
    my $names_str = `$cmd_getvarnames $infile`;
    if ($?) {
        die("ERROR Failed to find variable names: $cmd_getvarnames $infile");
    }
    else {
        $names_str =~ s/^\s+|\s+$//;
        my @names_tmp = split( '\s+', $names_str );
        foreach my $n (@names_tmp) {

            # Exclude z variable by checking its _CoordinateAxisType attribute
            # This is a z variable if the attribute exists
            next if exists( $exclude{$n} );
            my $coord
                = `ncks -m -v $n $infile|grep $n| grep _CoordinateAxisType`;
            chomp($coord);
            next if $coord;

            if ( $n eq "dataday" or $n eq "datamonth" ) {
                $dataday_name = $n;
            }
            elsif ( $n eq "time_bnds" ) {
                $tbnds_name = $n;
            }
            else {
                push( @names, $n );
            }
        }
    }

    return ( \@names, $dataday_name );
}

sub get_fillvalues {
    my ( $infile, $vname ) = @_;
    $vname = "" unless $vname;

    my $fillvalue;
    my $fill_str = `$cmd_getfillvalues -v $vname $infile`;
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
    my ( $outdir, $infile, $infile_last, $bbox, $level ) = @_;

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

    # Add z value if there is one
    # level : zname=<zvalue><zunits>
    if ( defined($level) ) {
        my ( $zname, $zvalue ) = split( "=", $level, 2 );
        $out_name = "$out_name-z$zvalue";
    }

    return "$outdir/areaAvg.$out_name.$T0-$T1.$bbox_string.nc";
}
