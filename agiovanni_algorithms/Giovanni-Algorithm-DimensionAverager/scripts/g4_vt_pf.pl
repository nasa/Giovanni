#! /usr/bin/env perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Temp qw/tempfile/;
use XML::LibXML;
use Giovanni::Util;
use Giovanni::Data::NcFile;
use Giovanni::DataField;
use Giovanni::Algorithm::DimensionAverager;
use Giovanni::Logger;

# Define and parse argument vars
use vars qw($opt_f $opt_b $opt_o $opt_v $opt_z $opt_s $opt_e $opt_d $opt_l);
getopts("f:b:o:v:z:s:e:l:");

# Check required options and die if not available
die "ERROR -f missing staging file or empty" if !defined $opt_f;
die "ERROR -b missing bounding box"          if !defined $opt_b;
die "ERROR -o missing required outfile"      if !defined $opt_o;
die "ERROR -s -e missing required start/end times"
    if !defined $opt_s and $opt_e;

# Declare setter variables from command line arguments
my $bbox         = $opt_b;
my $stagefile    = $opt_f;
my $outfile      = $opt_o;
my $varinfo_file = 'mfst.data_field_info+d' . $opt_v . '.xml';
my $outdir       = $opt_d;
my $starttime    = $opt_s;
my $endtime      = $opt_e;
my $zslice       = $opt_z;
my $lineage      = $opt_l;

# Get attributes of Manifest File
my $dataField = Giovanni::DataField->new( MANIFEST => $varinfo_file )
    if ( defined($varinfo_file) );
my $resolution = $dataField->get_resolution;
my $id         = $dataField->get_id;
my $zDimName   = $dataField->get_zDimName;
my $zDimUnits  = $dataField->get_zDimUnits;
my $start_time = $dataField->get_startTime;
my $end_time   = $dataField->get_endTime;

# Used to store contents of intermediate (temporary)  NetCDF files
my ( $fh, $nc_tmp )
    = File::Temp::tempfile( 'output_XXXXXX', SUFFIX => '.nc' );
my $cmd_dir = dirname($0);

# Compose bounding box String
my $index      = 0;
my $bboxString = "";
my @latlon     = split( /\,/, $bbox );
my $ll         = @latlon;
if ( $ll != 4 ) {
    print STDERR "USER_ERROR invalid bounding box(PH)\n";
    print STDERR "ERROR the bbox values are not correct at Plot Hints step\n";
    exit(1);
}
foreach my $llval (@latlon) {
    if ( $index == 0 || $index == 2 ) {
        $llval = ( $llval > 0 ) ? $llval . "E" : $llval . "W";
    }
    else {
        $llval = ( $llval > 0 ) ? $llval . "N" : $llval . "S";
    }
    $bboxString .= ( $bboxString eq "" ) ? $llval : "_$llval";
    $bboxString =~ s/\-//g;    ## to remove all '-' sign
    $index++;
}
print STDERR "INFO: bbox = $bboxString\n";

# Derived parts from the $outfile name
$outdir = dirname($outfile);
print STDERR "INFO: Outfile is  = $outfile\n";

# Setup logger
my $logger = Giovanni::Logger->new(
    session_dir       => $outdir,
    manifest_filename => $outfile
);

# Parse bounding box
$bbox =~ s/\s| //g;
my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

# Make sure they are floats
$latS = "$latS.0" unless $latS =~ /\./;
$latN = "$latN.0" unless $latN =~ /\./;
$lonW = "$lonW.0" unless $lonW =~ /\./;
$lonE = "$lonE.0" unless $lonE =~ /\./;

# Setting lat/lon range to points if they are within resolution
# isPoint: 0 (area), 1 (line), 2 (point)
my $isPoint = 0;
if ( abs( $latN - $latS ) < $resolution ) {
    $latN = $latS;
    $isPoint++;
}
if ( abs( $lonE - $lonW ) < $resolution ) {
    $lonE = $lonW;
    $isPoint++;
}

print STDERR "INFO: Point data is = $isPoint\n";

# Creating local nc files by symlink for shorter file names
my ( $infile_new, $symlinks ) = localize_files($stagefile);

# Concatenate files
my $infile_stitched = concatenate_files( $infile_new, $nc_tmp );

# Check stitched file and see if we got a point data
# No need to do this if it's already determined to be a point
my $foundPoint = 0;
if ( $isPoint != 2 ) {
    my $lat_dump = `ncdump -v lat $infile_stitched`;
    my ($lat_value) = ( $lat_dump =~ /data:\s+lat = (.+);/msg );
    $foundPoint++ unless $lat_value =~ /,/;
    my $lon_dump = `ncdump -v lon $infile_stitched`;
    my ($lon_value) = ( $lon_dump =~ /data:\s+lon = (.+);/msg );
    $foundPoint++ unless $lon_value =~ /,/;
}

if ( $isPoint == 2 or $foundPoint == 2 ) {

    # We got a point data
    #
    # Eliminate lat/lon dimensions
    my $cmd
        = qq(ncwa -a "lat,lon" -O $infile_stitched "$infile_stitched.ncwa");
    run_command( 'removing dimensions', $cmd );
    my $cmd = qq(mv $infile_stitched.ncwa $infile_stitched);
    run_command( 'removing dimensions', $cmd );
    my $cmd = qq(ncpdq -U -O $infile_stitched $outfile);
    run_command( 'removing dimensions', $cmd );
    die("ERROR ncpdq failed $!\n") if $?;
}

# Get file list from stagefile to retreive varnames
open( INFILE, "<$stagefile" ) or die("ERROR: Unable to open file $stagefile");
my @files_read = <INFILE>;
close(INFILE);
my @files_list;
foreach my $f (@files_read) {
    chomp($f);
    push( @files_list, $f );
}
my $f      = $files_list[0];
my $f_last = $files_list[-1];
my ( $vars, $dataday_name ) = get_varnames($f);

# Outfile
my $fout = $outfile;
print STDERR "INFO Outfile name is = $fout\n";

# Do dimension averaging on files (so as long as we do not have point data)

if ( $isPoint == 2 or $foundPoint == 2 ) {
    print STDERR "INFO: Found point data is = $foundPoint\n";
}
else {
    my $dim_averaged_outfile
        = Giovanni::Algorithm::DimensionAverager::compute_spatial_average(
        $infile_stitched, $fout, $id );
}

# Do time averaging on files

my $time_averaged_outfile
    = Giovanni::Algorithm::DimensionAverager::compute_temporal_average( $fout,
    $fout . '.tmp' );

# $starttime, $endtime, $bbox, undef, undef, undef, undef);

# Remove dataday and time from the output, then add time bounds variable
# removing dataday/time
my $exclude_vars = "time";
$exclude_vars = "time,$dataday_name" if $dataday_name;
my $cmd = qq(ncks -h -O -x -v $exclude_vars $fout'.tmp' $fout);
run_command( 'removing extra variables', $cmd );
die("ERROR Failed removing dataday and time from the output: $!") if $?;

# adding time bounds
my $start_time_epoch = $starttime;
$start_time_epoch =~ s/T|Z/ /g;
$start_time_epoch = `date -d \"$start_time_epoch\" +%s`;
chomp($start_time_epoch);
my $end_time_epoch = $endtime;
$end_time_epoch =~ s/T|Z/ /g;
$end_time_epoch = `date -d \"$end_time_epoch\" +%s`;
chomp($end_time_epoch);

my $output_time_bnds
    = qq(ncap2 -h -O -s 'defdim(\"bnds\",2);time_bnds[\$bnds]={$start_time_epoch,$end_time_epoch};time_bnds\@long_name=\"Time Bounds\"' $fout $fout.tmp);
run_command( 'adding time bounds', $output_time_bnds );
die("ERROR Failed adding time bounds variable to the output: $!") if $?;

#
## Add "coordinates" attribute to non-dimension variables
#
our $cmd_getdimnames = "$cmd_dir/getNcDimList.py";
my $coord = `$cmd_getdimnames $fout.tmp`;
$coord =~ s/\blat\b|\blon\b|\btime\b/ /g;
$coord =~ s/\s+/ /g;
$coord =~ s/\s+$//;
foreach my $v (@$vars) {
    $cmd = qq(ncatted -h -O -a "coordinates,$v,o,c,$coord" $fout.tmp);
    run_command( 'adding coordinates', $cmd );
    print STDERR "dimensions is = $coord\n";
}

#
## Modify start/end time global attributes
#
$cmd = qq(ncatted -O -h -a "starttime,global,o,c,$starttime" $fout.tmp);
run_command( 'managing attributes', $cmd );
print STDERR
    "WARN Failed to update start times: ncatted -a starttime,global,o,c \"$starttime\" $fout.tmp ($!)\n"
    if $?;
$cmd = qq(ncatted -O -h -a "endtime,global,o,c,$endtime" $fout.tmp);
run_command( 'managing attributes', $cmd );
print STDERR
    "WARN Failed to update end times: ncatted -a endtime,global,o,c \"$endtime\" $fout.tmp ($!)\n"
    if $?;

#
## Remove time_bnds, lat_bnds, lon_bnds
#
$cmd = "ncks -O -x -v time_bnds,lat_bnds,lon_bnds $fout.tmp $fout.tmp";
my $rc = system($cmd);
die "Unable to remove time bounds, lat bounds, and lon bounds: $cmd"
    if $rc != 0;

#
## Set title attribute with region label
#
$bbox =~ s/\s| //g;
my ( $lonW_lab, $latS_lab, $lonE_lab, $latN_lab ) = split( ',', $bbox );
if ( $lonW_lab =~ /^-/ ) {
    $lonW_lab =~ s/^-//;
    $lonW_lab = "${lonW}W";
}
else {
    $lonW_lab = "${lonW}E";
}
if ( $lonE_lab =~ /^-/ ) {
    $lonE_lab =~ s/^-//;
    $lonE_lab = "${lonE}W";
}
else {
    $lonE_lab = "${lonE}E";
}

if ( $latS_lab =~ /^-/ ) {
    $latS_lab =~ s/^-//;
    $latS_lab = "${latS}S";
}
else {
    $latS_lab = "${latS}N";
}
if ( $latN_lab =~ /^-/ ) {
    $latN_lab =~ s/^-//;
    $latN_lab = "${latN}S";
}
else {
    $latN_lab = "${latN}N";
}

my $region_label = "$lonW_lab - $lonE_lab, $latS_lab - $latN_lab";
$cmd = qq(ncatted -O -h -a "bounding_box,global,o,c,$bbox" $fout.tmp);
run_command( 'labeling', $cmd );
my $title = "Vertical Profile($region_label)";
$cmd = qq(ncatted -h -O -a "title,global,o,c,$title" $fout.tmp);
run_command( 'labeling', $cmd );
print STDERR "OUTPUT $fout.tmp\n";
$cmd = qq(mv $fout.tmp $fout);
run_command( 'labeling', $cmd );

exit(0);

# # -------------------------------------------------------------------
# # localize_files($listfile)
# # Modified from Chris' implementation of symlinks to input nc files,
# # to reduce amount of text in file names passed to nco commands.
# # -------------------------------------------------------------------
sub localize_files {
    my ($input_file) = @_;
    open( INPUT, "<$input_file" )
        or die("ERROR Failed to open input file $input_file $!");

    # Open a unique output file to write to
    my $base = File::Temp::tempnam( '.', 'aavg.' );
    my $infile_new = "$base.symlinks.txt";
    open( OUTPUT, ">$infile_new" )
        or die("ERROR Could not write to temporary file $infile_new $!");

    # Loop through input files, create symlink, add symlink to output file
    # The use of short symlink filenames gets around the file limit in ncra of
    # a total of 1 million bytes.
    my @files;
    my $i = 0;
    while (<INPUT>) {
        chomp;
        my $file = sprintf( "%s%05d.nc", $base, $i );
        $i++;
        if ( $file ne $_ ) {
            unless ( -e $file ) {
                symlink( $_, $file )
                    or die("ERROR Failed to symlink $_ to $file");
            }
            push @files, $file;    # Save list for cleanup
        }
        print OUTPUT "$file\n";
    }
    close INPUT;
    close OUTPUT;
    return ( $infile_new, \@files );
}

sub concatenate_files {
    my ( $infiles, $newfile ) = @_;

    my $cmd
        = qq(ncrcat -H -h -O -d lat,$latS,$latN -d lon,$lonW,$lonE $newfile < $infiles);
    run_command( 'concatenating files', $cmd );
    die("ERROR Failed concatenation: $!") if $?;

    return $newfile;
}

sub get_varnames {
    my ($infile)     = @_;
    my @names        = ();
    my $dataday_name = undef;

    my %varInfo = Giovanni::Util::getNetcdfDataVariables($f);

    foreach my $var ( keys %varInfo ) {
        if ( $var eq "dataday" or $var eq "datamonth" ) {
            $dataday_name = $var;
        }
        else {
            push( @names, $var );
        }
    }
    return ( \@names, $dataday_name );
}

=head1 NAME

g4_vt_pf.pl - Vertical Profile service algorithm

=head1 SYNOPSIS

g4_vt_pf.pl 
  -f stagefile
  -d outdir
  -b bbox
  -v varinfo_file
  -o outfile 
  -l lineage
  -s starttime
  -e endtime
  [-z zdim=zValunits]

=head1 ARGUMENTS

=over 4

=item -f stagefile

a stage data manifest file

=item -d outdir

Output directory name

=item -b bbox

Bounding box, in a comma-separated string (W,S,E,N). 

=item -v varinfo_file

datafield-info-file

=item -o outfile

output xml file

=item -l lineage

lineage extras file

=item -s starttime

start time

=item -e endtime

end time

=item -z zDimName=zValUnits

Horizontal slice to extract from 3-D data, 
e.g., "-z TempPrsLvls_A=500hPa" for the 500 hPa level.
This is input in the form of an xml file.

=back

=head1 EXAMPLE

g4_vt_pf.pl -f files.txt -b -179.375,-89.375,179.375,89.375 -o /var/giovanni/session/7008C734-D318-11E4-8DB6-03
184319ED9B/37EEB1E0-D31A-11E4-9CA1-42294319ED9B/37EEC518-D31A-11E4-9CA1-42294319ED9B/mfst.algorithm+sVtPf+dMAI3CPASM_5_2_0_T+t20110805000000_20110806000059+b179.3750W_89.3750S_179.37
50E_89.3750N.xml -v mfst.data_field_info+dMAI3CPASM_5_2_0_T.xml -s "2011-08-05T00:00:00Z" -e "2011-08-06T00:00:59Z"

=head1 AUTHOR

Michael Nardozzi, NASA/GSFC

=cut
