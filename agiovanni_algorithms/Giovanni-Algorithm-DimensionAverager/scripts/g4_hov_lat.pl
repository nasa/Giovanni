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

# Extract zslice
$zslice =~ s/\s| //g;
my ( $zname, $zvalue ) = split( '=', $zslice );

# Keeps digits and decimal points, removes other characters
$zvalue =~ s/[^\d.]//g;
my $zvalue_new = $zvalue;

# Parse bounding box
$bbox =~ s/\s| //g;
my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

# Make sure they are floats
$latS = "$latS.0" unless $latS =~ /\./;
$latN = "$latN.0" unless $latN =~ /\./;
$lonW = "$lonW.0" unless $lonW =~ /\./;
$lonE = "$lonE.0" unless $lonE =~ /\./;

# Get file list from stagefile to retreive varnames
open( INFILE, "<$stagefile" ) or die("ERROR: Unable to open file $stagefile");
my @files_read = <INFILE>;
close(INFILE);
my @files_list;
foreach my $f (@files_read) {
    chomp($f);
    push( @files_list, $f );
}
my $f = $files_list[0];
print STDERR "INFO: file list index[0] is = $f\n";
my $f_last = $files_list[-1];
print STDERR "INFO: file list index[-1] is = $f_last\n";
my ( $vars, $dataday_name ) = get_varnames($f);

# Snap tiny bbox to point
#my ($rlat, $rlon) = Giovanni::Data::NcFile::spatial_resolution($files_list->[0], 'lat', 'lon');
#$latN = $latS if abs($latN-$latS) < $rlat;
#$lonE = $lonW if abs($lonE-$lonW) < $rlon;

# Construct area subsetting string (-d option)
my $d_string = "-d lat,$latS,$latN -d lon,$lonW,$lonE";

if ( defined($zname) and defined($zvalue) ) {
    $zvalue = "$zvalue_new.0" unless $zvalue_new =~ /\./;
    $d_string .= " -d $zname,$zvalue,$zvalue";
}

# Subset files first
my @files_avg = ();
foreach my $f (@files_list) {
    my $f_new = basename($f) . ".avg";

    # Do a dimension subsetting first
    my $f_subset = basename($f) . ".subset";
    my $subset   = Giovanni::Algorithm::DimensionAverager::compute_subset_lon(
        $d_string, $f, $f_subset, $f_new );
    if ($?) {
        $logger->error(
            "ncks subsetting failed (ncks -O $d_string $f $f_subset $f_new)");
        return undef;
    }
    push( @files_avg, $f_new );
}

# Concatenate files into timeseries
my $rc = concatenate_files( $outfile, \@files_avg );
unless ($rc) {
    $logger->error("Concatenating files failed");
    return undef;
}

# Clean up the output file
my ( $fh_outfile_tmp, $outfile_tmp ) = File::Temp::tempfile();
my $cmd = qq(ncks -3 -h -O -v $id,time $outfile $outfile_tmp);
run_command( '', $cmd );
unless ($?) {
    my $cmd = qq(mv $outfile_tmp $outfile);
    run_command( '', $cmd );
}

# Fix attributes (global)
my $cmd = qq(ncatted -O -h -a "starttime,global,o,c,$starttime" $outfile);
print STDERR
    "WARN Failed to update start times: ncatted -a starttime,global,o,c \"$starttime\" $outfile ($!)\n"
    if $?;
my $cmd = qq(ncatted -O -h -a "endtime,global,o,c,$endtime" $outfile);
print STDERR
    "WARN Failed to update end times: ncatted -a endtime,global,o,c \"$endtime\" $outfile ($!)\n"
    if $?;

# Variable attributes: z_slice and z_slice_type
if ( defined($zvalue) ) {
    my $ztype = "unknown";
    $ztype = "pressure" if $zvalue =~ /hPa$/;
    my $cmd = qq(ncatted -h -O -a "z_slice,$id,o,c,$zvalue" $outfile);
    my $cmd = qq(ncatted -h -O -a "z_slice_type,$id,o,c,$ztype" $outfile);
}
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
    my ( $outfile, $files )    = @_;
    my ( $fh,      $listfile ) = File::Temp::tempfile();
    foreach my $f (@$files) {
        print $fh "$f\n";
    }
    close($fh);

    my $cmd = qq(ncrcat -h -H -O $outfile < $listfile);
    run_command( 'Concatenating files', $cmd );
    die("ERROR Failed concatenation: $!") if $?;
    if ($?) {
        $logger->error(
            "Fail to concate (ncrcat -h -H -O $outfile < $listfile)");
        return undef;
    }
    return 1;
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

g4_dimension_averager.pl - Dimension averaging using NCO

=head1 SYNOPSIS

g4_dimension_averager.pl 
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

g4_hov_lat.pl -f files.txt -b -179.375,-89.375,179.375,89.375 -o /var/giovanni/session/7008C734-D318-11E4-8DB6-03
184319ED9B/37EEB1E0-D31A-11E4-9CA1-42294319ED9B/37EEC518-D31A-11E4-9CA1-42294319ED9B/mfst.algorithm+sVtPf+dMAI3CPASM_5_2_0_T+t20110805000000_20110806000059+b179.3750W_89.3750S_179.37
50E_89.3750N.xml -v mfst.data_field_info+dMAI3CPASM_5_2_0_T.xml -s "2011-08-05T00:00:00Z" -e "2011-08-06T00:00:59Z"

=head1 AUTHOR

Michael Nardozzi, NASA/GSFC

=cut
