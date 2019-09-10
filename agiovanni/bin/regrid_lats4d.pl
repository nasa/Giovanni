#!/usr/bin/perl -w

=head1 NAME

regrid_lats4d.pl - Regridding service with Grads Lats4d

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

regrid_lats4d.pl [--help] [--verbose] --outDir <dir> --file <in.xml>
                 [--resolution <resolution>] [-x xlevel] [-y ylevel]

=head1 DESCRIPTION

This program performs regridding using Grads Lats4d approach.

=head1 OPTIONS

=over 4

=item --help
Print a usage information

=item --verbose
Turn on verbose mode

=item --outDir <dir>
Directory for output files

=item --file <in.xml>
Input xml file that contains a data file information

=item --resolution <resolution>
Resolution that can have the following values (default: "h2l"):
  "h2l" : From high to low resolution
  "l2h" : From low to high resolution

=item -x <xlevel>
Level selection for the 1st variable in the format of "vname,zname=<zvalue><zunits>"


=item -y <ylevel>
Level selection for the 2nd variable in the format of "vname,zname=<zvalue><zunits>"

=back

=head1 AUTHOR

Jianfu Pan (jianfu.pan@nasa.gov)

=cut

use lib ".";

use strict;
use POSIX;
use Getopt::Long;
use File::Basename;
use XML::LibXML;
use List::Util qw( min max );

my $cmd_dir = dirname($0);
our $cmd_gridinfo       = "$cmd_dir/getNcGridinfo.py";
our $cmd_dimname        = "$cmd_dir/getNcDimList.py";
our $cmd_getvarnames    = "$cmd_dir/getNcVarList.py";
our $cmd_getfillvalues  = "$cmd_dir/getNcFillValue.py";
our $cmd_copyattributes = "$cmd_dir/cpNcAttributes.py";
our $cmd_getdata1d      = "$cmd_dir/getNcData1D.py";

#- our $cmd_lats4d = "/opt/grads-2.0.a8/lats4d.sh";
our $cmd_lats4d = "lats4d.sh";

my $help;
my $debug_level = 0;
my $verbose;
my $inxml;
my $outdir = "./output";
my $outfile;
my $reso   = "h2l";
my $xlevel = undef;
my $ylevel = undef;
my $bbox   = "-180.,-90.,180.,90.";
my $result = GetOptions(
    "help"               => \$help,
    "h"                  => \$help,
    "verbose=s"          => \$verbose,
    "file=s"             => \$inxml,
    "f=s"                => \$inxml,
    "inputfiles=s"       => \$inxml,
    "outDir=s"           => \$outdir,
    "o=s"                => \$outdir,
    "output-file-root=s" => \$outdir,
    "outfile=s"          => \$outfile,
    "output=s"           => \$outfile,
    "resolution=s"       => \$reso,
    "r=s"                => \$reso,
    "bbox=s"             => \$bbox,
    "b=s"                => \$bbox,
    "x=s"                => \$xlevel,
    "y=s"                => \$ylevel,
);

my $usage
    = "Usage: $0 [--help] [--verbose] --outDir <outdir> --file <inxml> --resolution <resolution>\n"
    . "    --help           Print this help info\n"
    . "    --verbose        Print out lot of messages\n"
    . "    --file   inxml   Input xml file\n"
    . "    --outDir outdir  Session directory\n"
    . "    --output ouuput  Output file name\n"
    . "    --bbox   bbox    Bounding box\n"
    . "    -x       xlevel  Level selection of 1st variable (vname,zname=<zvalue><zunits>\n"
    . "    -y       ylevel  Level selection of 2nd variable (vname,zname=<zvalue><zunits>\n"
    . "    --resolution resolution Regridding target resolution\n";

# Print usage and exit if that's all asked for
if ($help) {
    print STDERR $usage;
    exit(0);
}

# Check required options
die("ERROR Input xml file missing") unless -f $inxml;

# Check level selections
$xlevel = undef if $xlevel and ( $xlevel eq "na" or $xlevel eq "NA" );
$ylevel = undef if $ylevel and ( $ylevel eq "na" or $ylevel eq "NA" );

# Create output directory if it doesn't exist
if ( !-d $outdir ) {
    mkdir( $outdir, 0755 ) || die("ERROR Fail to make session dir $outdir");
}

print STDERR "USER_MSG Executing regridding\n";
print STDERR "STEP_DESCRIPTION Regridding data\n";

#
# Get lists of nc files from input xml file and save them into infiles
# filelists:       Lists of files for each product (normally 2)
# regridRefIndex:  Array-index (0-based) pointing to the reference product
#                  For example, 2nd list is the target resolution when the index is 1.
# needRegrid:      A flag to indicate if regridding is needed
#

my ( $filelists, $regridRefIndex, $needRegrid ) = get_infiles($inxml);

my $Nlists = scalar(@$filelists);
if ( $Nlists < 2 ) {

    # No regridding will be done at this time for single resolution
    # TBD: Could regrid single resolution to a target resolution in future
    print STDERR
        "WARN No regridding will be done for single resolution. Exiting without doing anything...\n";
    my $files = get_files( $filelists->[0] );
    print_outfiles($files);
    exit(0);
}

# --- No need to regrid if all resolutions are the same ---
if ( !$needRegrid ) {
    print STDERR
        "WARN All resolutions are the same. Skipping regridding...\n";
    print STDERR "LINEAGE_MESSAGE No regridding due to same resolutions\n";
    foreach my $flist (@$filelists) {
        my $files = get_files($flist);
        print_outfiles($files);
    }
    exit(0);
}

#
# Get grid resolutions
# Look into input files for their resolutions and determine target resolution.
# $resolution = [ { lat = latResolution, lon = lonResolution, regrid = 0|1}]
# $toResolution = { lat = latResolution, lon = lonResolution }
#

my ( $resolutions, $toResolution )
    = get_resolution( $filelists, $reso, $regridRefIndex );

#
# Determine a pre-regridding subsetting bounding box (extend 2 grids)
# This is done with the target resolution NOT the files that need regridding
#
my $sample_file = `head -1 $filelists->[$regridRefIndex]`;
chomp($sample_file);
my $bbox_subset = get_subset_bbox( $bbox, $sample_file );

#
# Find the product that doesn't need regridding (reference resolution), and
# use its grid info for regridding.  This is a temporary solution because
# ideally we shouldn't need to match the region.
# TBD: Start/end values don't and shouldn't match reference product
#

my $resolution_ref;
if ( $regridRefIndex > -1 ) {
    $resolution_ref = $resolutions->[$regridRefIndex];
}
else {
    foreach my $reso (@$resolutions) {
        if ( $reso->{'regrid'} == 0 ) {

     # Find the reference product and take it even there could be more choices
     # In future we can have more complicated implementation
            $resolution_ref = $reso;
            last;
        }
    }
}

#
# Perform regridding
#

my @levels = ( $xlevel, $ylevel );
my $did_regrid = 0;
for ( my $k = 0; $k < $Nlists; $k++ ) {
    my $flist = $filelists->[$k];
    my $files = get_files($flist);
    if ( $resolutions->[$k]->{'regrid'} == 1 ) {
        my $files_new
            = do_regridding( $files, $resolutions->[$k], $resolution_ref,
            $outdir, $levels[$k], $bbox_subset, $outfile );
        fix_lat_lon( $files_new, $sample_file );
        print_outfiles($files_new);
        $did_regrid++;
    }
    else {
        print_outfiles($files);
    }
    print STDERR "PERCENT_DONE " . int( ( $k + 1 ) / $Nlists * 100 ), "\n";
}

exit(0);

sub run_command {
    my (@cmd) = @_;
    my $cmd = join( ' ', @cmd );

# warn "INFO Executing command: $cmd\n"; # Print-outs in regridder are not feasible, too many files
    my $rc = system(@cmd);
    if ( $rc == 0 ) {
        return 1;
    }
    else {
        $rc >>= 8;
        warn "ERROR on command $cmd: $rc\n";
        return;
    }
}

# This procedure copies lat / lon arrays from the reference file to regridded files
# since regridded grid might be slislightly off, impacting subsetting and merging
sub fix_lat_lon {
    my ( $files, $file_ref_in ) = @_;
    my $file_ref = $file_ref_in . '.ref';

# Regridding creates lat/lon in double by default, let's convert our reference file to double as well
    my $rc
        = system(
        "ncap2 -O -s 'lon=double(lon);lat=double(lat);' -o $file_ref $file_ref_in"
        );
    die
        "ERROR Failed to double lat/lon (ncap2 -O -s 'lon=double(lon);lat=double(lat);' -o $file_ref $file_ref_in)\n"
        if $rc != 0;

# Extract lat/lon from both reference and regridded files so that we can compare grids
    my @lons_ref     = split( ' ', `$cmd_getdata1d -v lon $file_ref` );
    my @lats_ref     = split( ' ', `$cmd_getdata1d -v lat $file_ref` );
    my @lons_gridded = split( ' ', `$cmd_getdata1d -v lon $files->[0]` );
    my @lats_gridded = split( ' ', `$cmd_getdata1d -v lat $files->[0]` );

    my $delta_lon = abs( ( $lons_ref[1] - $lons_ref[0] ) / 3. )
        ;    # Max difference between regridded and reference grid coordinates
    my $delta_lat = abs( ( $lats_ref[1] - $lats_ref[0] ) / 3. )
        ;    # Max difference between regridded and reference grid coordinates
    my $lon_start = -1;
    my $lat_start = -1;
    my $lon_end   = -1;
    my $lat_end   = -1;

    # Determine indexes of regridded / subsetted grid in the reference file
    my $idx = 0;
    for my $lon (@lons_ref) {
        $lon_start = $idx if ( abs( $lon - $lons_gridded[0] ) <= $delta_lon );
        $lon_end = $idx if ( abs( $lon - $lons_gridded[-1] ) <= $delta_lon );
        $idx++;
    }
    $idx = 0;
    for my $lat (@lats_ref) {
        $lat_start = $idx if ( abs( $lat - $lats_gridded[0] ) <= $delta_lat );
        $lat_end = $idx if ( abs( $lat - $lats_gridded[-1] ) <= $delta_lat );
        $idx++;
    }
    if (   $lon_start eq -1
        || $lon_end   eq -1
        || $lat_start eq -1
        || $lat_end   eq -1 )
    {
        warn "ERROR Failed to match reference and regridded grids \n";
        exit(-1);
    }

    # Copy reference sub-grid into all of the regridded files
    my $lon_dtype
        = `ncap2 -O -s 'mtype=lon.type();print(mtype);' -o $file_ref_in.tmp $file_ref_in 2>&1 | grep -oE '[0-9]+'`;
    unlink("$file_ref_in.tmp");
    for my $f (@$files) {
        run_command( 'ncks', '-A', '-v', 'lon', '-d',
            "lon,$lon_start,$lon_end", '-d', "lat,$lat_start,$lat_end",
            $file_ref, $f );
        
        # Make sure Lat / Lon in the regridded file have the same data type as the original file
        my $rc
            = system(
            "ncap2 -O -s 'lon=lon.convert($lon_dtype);lat=lat.convert($lon_dtype);' $f $f"
            );
        die
            "ncap2 -O -s 'lon=lon.convert($lon_dtype);lat=lat.convert($lon_dtype);' $f $f\n"
            if $rc != 0;
    }
    unlink "$file_ref";
}

sub get_subset_bbox {
    my ( $bbox, $sample_file ) = @_;
    my ( $west, $south, $east, $north ) = split( ',', $bbox );
    die "ERROR Invalid bbox $bbox\n"
        if $west < -180.0
            or $west > 180.
            or $east < -180.0
            or $east > 180.
            or $west > $east
            or $south < -90.0
            or $south > 90.0
            or $north < -90.0
            or $north > 90.0
            or $south > $north;

    # Get resolution and bounds in sample file
    my @lat_data = `ncks -s "%f\n" -H -C -v lat $sample_file`;
    chomp(@lat_data);
    @lat_data = remove_empty_elements(@lat_data);
    my @lon_data = `ncks -s "%f\n" -H -C -v lon $sample_file`;
    chomp(@lon_data);
    @lon_data = remove_empty_elements(@lon_data);
    my $dlat = $lat_data[2] - $lat_data[1];
    my $dlon = $lon_data[2] - $lon_data[1];

    # Align the grids and extend by 2 grids
    my $ilon_west  = floor( ( $west - $lon_data[0] ) / $dlon );
    my $ilon_east  = ceil(  ( $east - $lon_data[0] ) / $dlon );
    my $ilat_south = floor( ( $south - $lat_data[0] ) / $dlat );
    my $ilat_north = ceil(  ( $north - $lat_data[0] ) / $dlat );

    $west = $lon_data[ max( 0, $ilon_west - 2 ) ];
    $east = $lon_data[ min( scalar(@lon_data) - 1, $ilon_east + 2 ) ];
    $south = $lat_data[ max( 0, $ilat_south - 2 ) ];
    $north = $lat_data[ min( scalar(@lat_data) - 1, $ilat_north + 2 ) ];

    # Pre-regrid subsetting bbox
    return undef
        if $west == $lon_data[0]
            and $east == $lon_data[-1]
            and $south == $lat_data[0]
            and $north == $lat_data[-1];

    $east = min( 180., $east + abs($dlon) / 0.3 )
        if $east == $lon_data[-1];    # Pad for a possible end value run-off
    $north = min( 90., $north + abs($dlat) / 0.3 )
        if $north == $lat_data[-1];    # Pad for a possible end value run-off

    return "$west,$south,$east,$north";
}

# ------------------------------------------------------------------------------
# do_regridding - Do regridding for a  list of files of a product
# Inputs:
#   $files        : List of files (of same resolution) to be regridded
#   $resolution   : Resolution of the file ist
#   $toResolution : Target resolution of regridding
#   $outdir       : Output directory for regridded files
#   $level        : Level selection in the forma of "vname,zname=<zvalue><zunits>
#   $bbox         : Pre-regridding subsetting bbox
#   $outfile_param: Forces output file to be saved as $outfile_param
# Return:  New list of regridded files
# ------------------------------------------------------------------------------
sub do_regridding {
    my ( $files, $resolution, $toResolution, $outdir, $level, $bbox,
        $outfile_param )
        = @_;

    # --- Determine if level subset is needed ---
    my $z_subset = undef;
    my ( $xyname, $zname, $zvalue, $zunits ) = ( undef, undef, undef, undef );

    if ( defined($level) ) {

        # Parse level for subsetting
        ( $xyname, $zname, $zvalue, $zunits )
            = ( $level =~ /^(.+),(.+)=([\d\.]+)(.*)/ );

        # Get z-dimension name from the first file in the list
        my $zname_file = `$cmd_dimname -t z $files->[0]`;
        if ($?) {
            print
                "WARN Fail to get z dimension in file ($cmd_dimname -t z $files->[0])\n";
        }
        else {
            chomp($zname_file);
            $zname_file =~ s/^\s+|\s+$//g;
        }

        # z-subset is needed if we have the zname match
        if ( $zname_file eq $zname ) {
            $z_subset = 1;
        }
        else {
            if ($zname) {
                die
                    "ERROR Found z in file but mismatched zname found ($zname_file,$zname)\n";
            }
        }
    }

  # --- Get variable names in input file ---
  # All files in the list have the same variables so we only need to check one
    my $vnames     = get_varnames( $files->[0] );
    my $vnames_str = join( ',', @$vnames );
    my $dataday    = undef;
    $dataday = 'dataday'   if $vnames_str =~ /\bdataday\b/;
    $dataday = 'datamonth' if $vnames_str =~ /\bdatamonth\b/;

    # --- Get fill value ---
    # Assuming fill value is the same throughout the file
    # TBD Fill value could be a variable-dependent value

    my $fill = get_fillvalues( $files->[0] );

    # --- Create regrid dimension environment ctl for target resolution ---
    my ( $regrid_ctl, $xy_target )
        = create_regrid_ctl( $toResolution, $fill, $bbox );
    my $nlon      = $xy_target->[0];
    my $lon_start = $xy_target->[1];
    my $rlon      = $xy_target->[2];
    my $nlat      = $xy_target->[3];
    my $lat_start = $xy_target->[4];
    my $rlat      = $xy_target->[5];

    # --- Go through each file and regrid it ---
    my $files_new = [];

    my $total_num_files = scalar(@$files);
    my $xy_source;
    my $k_regrid = 0;
    for my $f (@$files) {
        $k_regrid++;
        print STDERR
            "USER_MSG Regridding $k_regrid of $total_num_files files for $vnames_str\n";

        # Create an output file name
        $outfile = ($outfile_param) ? $outfile_param : get_outfile_name( $outdir, $f );

        my $zvar_file;

        # Do subset if needed
        ( $f, $zvar_file ) = do_subset( $f, $zname, $zvalue, $bbox )
            if defined($z_subset)
                or defined($bbox);

        # Get the lat/lon range in subsetted input file.  We only need to do
        # this once. [nlon, lon_start, nlat, lat_start]
        $xy_source = get_xy_range($f);

 # Create ctl file
 # In theory lats4d can take nc file without ctl file, but the unusal boundary
 # points in products like Gocart are causing problem.
        my $f_ctl = create_infile_ctl( $xy_source, $resolution, $f, $vnames,
            $fill );

        # Execute regrid command
        #- my $rlat = $toResolution->{'lat'}->{'resolution'};
        #- my $rlon = $toResolution->{'lon'}->{'resolution'};
        #- my $start_lat = $toResolution->{'lat'}->{'start'};
        #- my $start_lon = $toResolution->{'lon'}->{'start'};
        #- my $size_lat = $toResolution->{'lat'}->{'size'};
        #- my $size_lon = $toResolution->{'lon'}->{'size'};
        my $cmd
            = "$cmd_lats4d -i $f_ctl -o $outfile -de $regrid_ctl -func 're(@,$nlon,linear,$lon_start,$rlon,$nlat,linear,$lat_start,$rlat,ba)' -v";
        print STDERR "INFO regrid command: $cmd\n";
        `$cmd >> lats4d.log 2>&1`;
        if ($?) {
            die("ERROR Regridding failed on $f\n");
        }

        #
        # Fix output file
        #

        fix_outfile( $f, $outfile, $vnames, $zname, $zvalue, $zunits,
            $zvar_file );

        # Copy back dataday
        if ($dataday) {
            `ncks -h -A -v $dataday $f $outfile`;
            if ($?) {
                print STDERR
                    "WARN Fail to restore dataday (ncks -h -A -v $dataday $f $outfile. $!)\n";
            }
        }

        push( @$files_new, $outfile );
    }

    return $files_new;
}

sub do_subset_noregionsubset {
    my ( $f, $zname, $level, $bbox ) = @_;

    # Level subset option string
    my $dz = "";
    if ( defined($zname) and defined($level) ) {

        # Make sure level is a float
        $level = "$level." unless $level =~ /\./;
        $dz = "-d $zname,$level,$level";
    }

    # Region subset option string
    my $dxy = "";
    if ( defined($bbox) ) {
        my ( $west, $south, $east, $north ) = split( ',', $bbox );
        $west  = "$west."  unless $west  =~ /\./;
        $east  = "$east."  unless $east  =~ /\./;
        $south = "$south." unless $south =~ /\./;
        $north = "$north." unless $north =~ /\./;
        $dxy = "-d lat,$south,$north -d lon,$west,$east";
    }

    # Return file as is if no subsetting is needed
    return $f unless $dz or $dxy;

    # File name for subsetted results
    my $f_subset = $f;
    $f_subset =~ s/scrubbed\./subsetted\./;

    # Subset file
    my $cmd = "ncks -h -O $dz $f $f.tmp";
    warn "INFO running $cmd to subset data\n";
    my $rc = system($cmd);
    die "ERROR ncks failed (ncks -h -O $dz $f $f.tmp). $!" if $rc;

    my $z_subset;
    if ( defined($zname) ) {

        # Save z variable for adding back in later...
        $z_subset = "$f_subset.ztmp";
        run_or_die("ncks -O -v $zname $dz $f.tmp $z_subset");

        # ...then eliminate Z dimension so as not to confuse lats4d
        run_or_die("ncwa -h -O -a $zname $f.tmp $f_subset");

        unlink("$f.tmp");
    }
    else {
        `mv $f.tmp $f_subset`;
    }

    return ( $f_subset, $z_subset );
}

sub run_or_die {
    my ( $cmd, $user_error ) = @_;
    $user_error ||= "Failed in regridding step\n";
    warn "INFO running $cmd\n";
    my $rc = system($cmd);
    die "USER_ERROR $user_error\n" if ($rc);
    return 1;
}

sub do_subset {
    my ( $f, $zname, $level, $bbox ) = @_;

    # Level subset option string
    my $dz = "";
    if ( defined($zname) and defined($level) ) {

        # Make sure level is a float
        $level = "$level." unless $level =~ /\./;
        $dz = "-d $zname,$level,$level";
    }

    # Region subset option string
    my $dxy = "";
    if ( defined($bbox) ) {
        my ( $west, $south, $east, $north ) = split( ',', $bbox );
        $west  = "$west."  unless $west  =~ /\./;
        $east  = "$east."  unless $east  =~ /\./;
        $south = "$south." unless $south =~ /\./;
        $north = "$north." unless $north =~ /\./;
        $dxy = "-d lat,$south,$north -d lon,$west,$east";
    }

    # Return file as is if no subsetting is needed
    return $f unless $dz or $dxy;

    # File name for subsetted results
    my $f_subset = $f;
    $f_subset =~ s/scrubbed\./subsetted\./;

    # Subset file
    my $cmd = "ncks -h -O $dz $dxy $f $f.tmp";
    warn "INFO subsetting with $cmd\n";
    my $rc = system($cmd);
    die "ERROR ncks failed $cmd: $rc\n" if $rc;
    my $z_subset;
    if ( defined($zname) ) {

        # Save z variable for adding back in later...
        $z_subset = "$f_subset.ztmp";
        run_or_die("ncks -v $zname $dz $f.tmp $z_subset");
        run_or_die("ncwa -h -O -a $zname $f.tmp $f_subset");
        die "ERROR ncwa failed (ncwa -h -O -a $zname $f.tmp $f_subset). $!"
            if $?;
        `rm -f $f.tmp`;
    }
    else {
        `mv $f.tmp $f_subset`;
    }

    return ( $f_subset, $z_subset );
}

sub get_xy_range {
    my ($file) = @_;
    my @lat_data = `ncks -s "%f\n" -H -C -v lat $file`;
    chomp(@lat_data);
    @lat_data = remove_empty_elements(@lat_data);
    my @lon_data = `ncks -s "%f\n" -H -C -v lon $file`;
    chomp(@lon_data);
    @lon_data = remove_empty_elements(@lon_data);
    my $nlat = scalar(@lat_data);
    my $nlon = scalar(@lon_data);
    return [ $nlon, $lon_data[0], $nlat, $lat_data[0] ];
}

sub remove_empty_elements {
    my (@arr) = @_;
    my @out = ();
    for my $val (@arr) {
        if ( $val ne '' ) {
            push( @out, $val );
        }
    }
    return @out;
}

sub fix_outfile {
    my ( $infile, $outfile, $vnames, $zname, $zvalue, $zunits, $zvar_file )
        = @_;

    # Rename variable
    `ncrename -O -v z,$vnames->[0] $outfile $outfile.rename`;
    if ($?) {
        die("ERROR Renaming failed: ncrename -v z,$vnames->[0] $outfile $outfile.rename\n"
        );
    }
    else {
        `mv $outfile.rename $outfile`;
    }

    #
    # Set correct time by copying it from input file
    #
    my $hasTime = system("ncdump -v time $infile");
    if ( $hasTime == 0 ) {
        `ncks -A -v time $infile $outfile`;
        die("ERROR Fail to remove time: ncks -A -v time $infile $outfile\n")
            if $?;
    }

    #
    # Fix attributes
    #
    `$cmd_copyattributes $infile $outfile`;
    die("ERROR Fail to reset attributes $infile $outfile\n") if $?;

    # Add z slice attributes
    if ( defined($zvalue) and defined($zunits) ) {
        my $ztype = "unknown";
        if ( $zunits eq "hPa" ) {
            $ztype = "pressure";
        }
        elsif ( $zunits eq "km" ) {
            $ztype = "height";
        }
        `ncatted -h -O -a "z_slice,$vnames->[0],o,c,$zvalue$zunits" $outfile`;
        `ncatted -h -O -a "z_slice_type,$vnames->[0],o,c,$ztype" $outfile`;
        add_z_dimension( $outfile, $zname, $zvar_file );
        unlink($zvar_file);
    }
}

sub add_z_dimension {
    my ( $file, $zname, $zvar_file ) = @_;

    # Reconstruct Z dimension
    my $newfile = "$file.fix";

    # ncecat adds a 1-element record dimension
    run_or_die("ncecat -O $file $newfile");

    # ncpdq makes time the true record dimension
    run_or_die("ncpdq -a time,record -O $newfile $newfile");

    # ncrename renames the new dimension back to its z name
    run_or_die("ncrename -d record,$zname -O $newfile $newfile");

    # ncks adds the actual z variable, subsetted, back to the file
    run_or_die("ncks -A $zvar_file $newfile");

    # Move it back to the old filename
    unless ( rename( $newfile, $file ) ) {
        warn "ERROR Failed to rename $newfile to $file: $!\n";
        die "USER_MSG Failed to regrid file\n";
    }
    return 1;
}

sub create_infile_ctl {
    my ( $xy, $resolution, $infile, $vnames, $fill ) = @_;

    my $rlat      = $resolution->{'lat'}->{'resolution'};
    my $start_lat = $xy->[3];
    my $size_lat  = $xy->[2];

    my $rlon      = $resolution->{'lon'}->{'resolution'};
    my $start_lon = $xy->[1];
    my $size_lon  = $xy->[0];

    my @infile_parts = split( '\.', basename($infile) );
    pop(@infile_parts);
    my $ctl_file = join( '.', @infile_parts ) . ".ctl";
    open( CTL, ">$ctl_file" ) || die "ERROR Fail to create file: $ctl_file\n";
    print CTL <<EOF;
DSET $infile
TITLE Input file for regridding
dtype netcdf
undef $fill
UNPACK scale_factor add_offset
XDEF $size_lon linear $start_lon $rlon
YDEF $size_lat linear $start_lat $rlat
zdef 1 linear 1 1
tdef 1 linear 00Z01JAN1900 1dy
VARS 1
$vnames->[0]=>z 0 t,y,x z
ENDVARS
EOF
    close(CTL);

    return $ctl_file;
}

# ------------------------------------------------------------------------------
# create_regrid_ctl - Create regrid dimension environment ctl file
# Description: The target resolution $toResolution will be updated to include
#              start value and size information inadditional to resolutions.
# Return:
#   (1) Regrid ctl file name will be returned
#   (2) toResolution will be updated to include start and size for both lat and lon
# ------------------------------------------------------------------------------
sub create_regrid_ctl {
    my ( $toResolution, $fill, $bbox ) = @_;

    # --- Target resolution ---
    my $rlat = $toResolution->{'lat'}->{'resolution'};
    my $rlon = $toResolution->{'lon'}->{'resolution'};

    # --- Determine new start value and size ---
    my ( $west, $south, $east, $north, $nlat, $nlon );
    if ( defined($bbox) ) {
        ( $west, $south, $east, $north ) = split( ',', $bbox );
        $nlat = int( ( $north - $south ) / $rlat ) + 1;
        $nlon = int( ( $east - $west ) / $rlon ) + 1;
    }
    else {
        $south = $toResolution->{'lat'}->{'start'};
        $west  = $toResolution->{'lon'}->{'start'};
        $nlat  = $toResolution->{'lat'}->{'size'};
        $nlon  = $toResolution->{'lon'}->{'size'};
    }
    
    # lats4d does not like when coordinates 'wrap around', i.e., regrid
    # between -180 and 180 lon. Let's detect and correct.
    # NOTE: regrid between -90 and 90 is perfectly fine, apparently
    # NOTE2: Let's hope land-see mask does not run from -180 to 180.
    $nlon = min($nlon, floor(360. / $rlon) + 1);
    $nlon = $nlon - 1 if (($nlon - 1.)*$rlon >= 360.);
    
    my $start_lat = $south;
    my $size_lat  = $nlat;
    my $start_lon = $west;
    my $size_lon  = $nlon;

    # --- Create ctl file for target resolution ---
    my $regrid_ctl_file = "regridDE.$rlat-$rlon.ctl";
    open( CTL, ">$regrid_ctl_file" )
        || die "ERROR Fail to create file: $regrid_ctl_file\n";
    print CTL <<EOF;
DSET nofile
TITLE Regridding Dimension Environment
OPTIONS template
undef $fill
XDEF $size_lon linear $start_lon $rlon
YDEF $size_lat linear $start_lat $rlat
zdef 1 linear 1 1
tdef 1 linear 00Z01JAN1900 1dy
VARS 1
fakevar=>fakevar 0 y,x Fake Variable
ENDVARS
EOF
    close(CTL);

    # --- Update toResolution to include start and size info ---
    #-    $toResolution->{'start_lat'} = $start_lat;
    #-    $toResolution->{'size_lat'} = $size_new_lat;
    #-    $toResolution->{'start_lon'} = $start_lon;
    #-    $toResolution->{'size_lon'} = $size_new_lon;

    return ( $regrid_ctl_file,
        [ $size_lon, $start_lon, $rlon, $size_lat, $start_lat, $rlat ] );
}

# ------------------------------------------------------------------------
# get_resolution($filelists, $resolution, $refi)
# Description: Determines resolutions of input files and target resolution
#   for regridding
# Inputs:
#   $filelists  - Lists of input files
#   $resolution - Target resolution that can have the following values:
#                 h2l : From high to low resolution
#                 l2h : From low to high resolution
#   $refi       - 0-based array index of file lists, no need for
#                     find toResolution if exists.
# Return: ($resolutions, $toResolution)
#   $resolutions : Array corresponding to filelists with the following
#                  structure
#                  [ { lat -> { start = x, resolution = x, size = x},
#                      lon -> { start = x, resolution = x, size = x},
#                      regrid = 0|1
#                    }
#                  ]
#   $toResolution: Target resolution
#                  { lat = latResolution, lon = lonResolution }
# ------------------------------------------------------------------------
sub get_resolution {
    my ( $filelists, $resolution, $refi ) = @_;

    my $Nlists = scalar(@$filelists);

    #
    # Get resolutions from first file of each file list
    #

    my $resolutions = [];
    my $min         = { 'lat' => 999, 'lon' => 999 };
    my $max         = { 'lat' => -999, 'lon' => -999 };
    for my $flist (@$filelists) {
        my $files = get_files($flist);
        my $file  = $files->[0];

# Found lat and lon resolutions for the list (product)
# Save the list's resolution and update highest/lowest resolutions in the process
        my $gridinfo = {};
        for my $dim ( "lat", "lon" ) {
            my $dimname = `$cmd_dimname -t $dim $file`;
            die("ERROR Failed to get $dim name: $cmd_dimname -t $dim $file\n")
                if $?;
            chomp($dimname);

            my $r = `$cmd_gridinfo -d $dimname -t $dim $file`;
            die("ERROR Failed to get lat resolution: $cmd_gridinfo -d $dimname -t $dim $file\n"
            ) if $?;
            chomp($r);
            my ( $start, $reso, $size ) = split( ',', $r );

            # --- Update min/max ---
            $min->{$dim} = $reso if $min->{$dim} > $reso;
            $max->{$dim} = $reso if $max->{$dim} < $reso;

            # --- Save resolution for this file list ---
            # Set default regrid need to true
            $gridinfo->{'regrid'} = 1;
            $gridinfo->{$dim} = {
                'start'      => $start,
                'resolution' => $reso,
                'size'       => $size,
                'regrid'     => 1
            };
        }
        push( @$resolutions, $gridinfo );
    }

    #
    # Determine which list needs regridding
    #

    my $targetLatResolution;
    my $targetLonResolution;
    if ( $refi > -1 ) {
        $resolutions->[$refi]->{'regrid'}          = 0;
        $resolutions->[$refi]->{'lat'}->{'regrid'} = 0;
        $resolutions->[$refi]->{'lon'}->{'regrid'} = 0;
        $targetLatResolution = $resolutions->[$refi]->{'lat'}->{'resolution'};
        $targetLonResolution = $resolutions->[$refi]->{'lon'}->{'resolution'};
    }
    else {

        # --- Set target resolution, default is h2l ---
        $targetLatResolution = $max->{"lat"};
        $targetLonResolution = $max->{"lon"};
        if ( $resolution eq "l2h" ) {
            $targetLatResolution = $min->{"lat"};
            $targetLonResolution = $min->{"lon"};
        }

        # --- Find out which lists need regridding ---
        for ( my $k = 0; $k < $Nlists; $k++ ) {
            my $r = $resolutions->[$k];
            if (   $r->{'lat'}->{'resolution'} != $targetLatResolution
                or $r->{'lon'}->{'resolution'} != $targetLonResolution )
            {
                $resolutions->[$k]->{'regrid'} = 1;
            }
        }
    }

    #
    # Return grid and regridding information
    #

    return ( $resolutions,
        { 'lat' => $targetLatResolution, 'lon' => $targetLonResolution } );
}

sub get_infiles {
    my ($inxml) = @_;

    my $infiles         = [];
    my $infile_template = "dataPairing.$$";

    my $parser = XML::LibXML->new();
    my $xml    = $parser->parse_file($inxml);

    my @listNodes         = $xml->findnodes('/data/dataFileList');
    my $needRegrid        = 1;
    my $regridRefIndex    = -1;
    my $cnt               = 1;
    my %productResolution = ();
    foreach my $node (@listNodes) {

        # Check if this is reference product
        my $gridref = $node->getAttribute('gridReference');
        $regridRefIndex = $cnt - 1
            if defined($gridref)
                and $gridref eq "true";

        # Product resolution
        my $resolution = $node->getAttribute('resolution');
        if ( defined($resolution) ) {
            $productResolution{$resolution} = 1;
        }
        else {
            $productResolution{"unknown$cnt"} = 1;
        }

        my @fileNodes = $node->findnodes('dataFile');
        my $infile    = "${infile_template}_$cnt.txt";
        my @files     = ();
        foreach my $fn (@fileNodes) {
            my $fpath = $fn->textContent();
            $fpath =~ s/^\s+|\s+$//g;
            push( @files, $fpath ) if $fpath ne "";
        }
        open( FH, ">$infile" ) || die("ERROR Fail to open $infile\n");
        print FH join( "\n", @files );
        close(FH);
        push( @$infiles, $infile );
        $cnt++;

        # --- Print out input files for lineage ---
        foreach my $f (@files) {
            print STDERR
                "LINEAGE_INPUT type=\"FILE\" label=\"Input File\" value=\""
                . $f . "\"\n";
        }
    }

    #
    # Determine if all resolutions are the same
    #
    $needRegrid = 0 if scalar( keys(%productResolution) ) == 1;

    return ( $infiles, $regridRefIndex, $needRegrid );
}

# -----------------------------------------------------------
# get_new_name() - Rename a variable
# Inputs:
#   $varnames : Dictionary of existing variable names
#   $vn       : Variable name that potentially needs renaming
# -----------------------------------------------------------
sub get_new_name {
    my ( $varnames, $vn ) = @_;
    my $done = 0;
    my $k    = 1;
    my $vn_new;
    while ( !$done ) {
        $vn_new = "${vn}_$k";
        if ( not exists( $varnames->{$vn_new} ) ) {
            $done = 1;
            last;
        }
        $k++;
    }

    return $vn_new;
}

# ---------------------------------------------------------
# get_files() - Get lists of files
# Description: Reads the input file of list of data files,
#              and returns an array ref of the file list.
# ---------------------------------------------------------
sub get_files {
    my ($infile) = @_;

    my @filelists = ();

    open( INFILE, "<$infile" )
        or die("ERROR Unable to open input file $infile");
    my @files_read = <INFILE>;
    close(INFILE);
    my @files;
    foreach my $f (@files_read) {
        chomp($f);
        push( @filelists, $f );
    }

    return \@filelists;
}

sub get_varnames {
    my ($infile) = @_;

    my @names     = ();
    my $names_str = `$cmd_getvarnames $infile`;
    if ($?) {
        die("ERROR Failed to find variable names: $cmd_getvarnames $infile");
    }
    else {
        $names_str =~ s/^\s+|\s+$//;
        @names = split( '\s+', $names_str );
    }

    return \@names;
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
# get_outfile_name
# Description:  Create an output file name that follows AG convention
# Inputs:
#   $outdir : Output directory
#   $infile : Input file
# Algorithm:
#   Input file name pattern: <service>.<var>.<date>.nc
# ====================================================================
sub get_outfile_name {
    my ( $outdir, $infile ) = @_;

    my $in_name = basename($infile);
    my @in_parts = split( '\.', $in_name );
    shift(@in_parts);

    # Constructing output file name
    my $out_name = "regrid." . join( '.', @in_parts );

    return "$outdir/$out_name";
}

sub print_outfiles {
    my ($filelist) = @_;
    foreach my $f (@$filelist) {
        print STDERR "OUTPUT $f\n";
    }

    return 1;
}
