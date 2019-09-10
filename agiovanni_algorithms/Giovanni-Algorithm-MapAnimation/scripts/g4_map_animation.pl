#!/usr/bin/env perl

# $Id: g4_map_animation.pl,v 1.2 2015/05/16 00:30:13 eseiler Exp $

use strict;
use warnings;
use File::Basename qw(basename dirname);
use File::Temp qw(tempfile);
use Getopt::Std;
use Giovanni::Data::NcFile;
use Giovanni::WorldLongitude;

main();

sub main {
    print STDERR "USER_INFO Launching Map Animation Service\n";

    #   Parse command line arguments with getopt
    #   -----------------------------------------
    use vars
        qw($opt_b $opt_s $opt_e $opt_f $opt_o $opt_v $opt_z $opt_S $opt_l);
    getopts("b:s:e:f:o:v:z:S:l:");

    die "ERROR -b missing" if !defined $opt_b;
    die "ERROR -s missing" if !defined $opt_s;
    die "ERROR -e missing" if !defined $opt_e;
    die "ERROR -f missing" if !defined $opt_f;
    die "ERROR -o missing" if !defined $opt_o;
    die "ERROR -v missing" if !defined $opt_v;

    #   Declare variables from command line arguments
    #   ---------------------------------------------
    my $bbox = $opt_b;

    #    my $start_time = $opt_s;
    #    my $end_time = $opt_e;
    my @file_list = read_file_list($opt_f);
    my $out_file  = $opt_o;
    my $out_dir   = dirname($opt_o);
    my $var_name  = $opt_v;
    my $zSlice    = $opt_z;

    #    my $shapefile = $opt_S;
    #    my $lineageExtras = $opt_l;

    my ( $zName, $zValue, $zUnits );
    if ( defined($zSlice) ) {

        # Expect a string of the form zName=500zUnits
        # where the value consists of one or more digits or decimal points
        # and the units do not contain any digits
        ( $zName, $zValue, $zUnits ) = ( $zSlice =~ /^(.+)=([\d\.]+)(.*)$/ );
        die "ERROR Invalid z-slice argument ($zSlice)\n"
            unless $zName and defined($zValue);
    }

    my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );
    $lonW .= "." unless $lonW =~ /\./;
    $lonE .= "." unless $lonE =~ /\./;
    $latS .= "." unless $latS =~ /\./;
    $latN .= "." unless $latN =~ /\./;

    my $nFiles = scalar(@file_list);
    my $i      = 0;

    open( OUT, "> $out_file" )
        || die "Could not open $out_file for writing\n";

    foreach my $file (@file_list) {
        $i++;
        print STDERR
            "USER_MSG Subsetting $i of $nFiles files for $var_name\n";
        my $fout
            = get_outfile_name( $out_dir, $file, $bbox, $zValue, $zUnits );

        # Subset by z-slice, latitude, and longitude
        subset_dimension( $zName, $zValue, $lonW, $latS, $lonE, $latN, $file,
            $fout );
        die "ERROR Subsetting $file failed\n" unless -s $fout;

        # Correct any longitude extents that cross the 180 meridian
        my $nfile      = $fout . '_normalized';
        my $normalized = Giovanni::WorldLongitude::normalizeIfNeeded(
            sessionDir => $out_dir,
            in         => [$fout],
            out        => [$nfile]
        );
        rename $nfile, $fout if $normalized;
        print STDERR "INFO File $file normalized=$normalized\n";

        # Fix variable attributes
        if ( defined($zSlice) ) {

            # Add z-attributes and delete z in coordinate attribute
            # Fix z-attributes
            fix_variable_attributes( $var_name, $fout, $zName, $zValue,
                $zUnits );
        }

        # Fix global attributes
        # Set title attribute with region label
        my $region_label = get_region_label( $bbox, 1 );
        my $title = "$var_name ($region_label)";

#	my $cmd = qq(ncatted -h -O -a "title,global,o,c,$title" $fout);
#	my $rc = system($cmd);
#	print STDERR "INFO ncatted call ($cmd) to remove valid_range returned $rc\n";

        # Delete valid_range attribute if present
        # TO DO: remove this when we scrub the valid_range
        #	my $cmd = "ncatted -a valid_range,,d,, -O -o $fout $fout";
        my $cmd
            = qq(ncatted -a "title,global,o,c,$title" -a valid_range,,d,, -O -o $fout $fout);
        print STDERR "INFO running $cmd\n";
        my $rc = system($cmd);
        if ($rc) {
            print STDERR "WARN: Failed to run $cmd: $rc\n";
        }

        #	unlink $nfile if  ($normalized && (-f $nfile) );

        # Write name of result file to output (manifest) file
        print OUT "$fout\n";
    }

    close(OUT);

    print STDERR "INFO Map animation completed successfully.\n";
}

sub read_file_list {
    my ($file_name) = @_;

    open( IN_FILE, "< $file_name" ) || die("Unable to open $file_name");

    my @file_list;
    for my $line (<IN_FILE>) {
        chomp($line);
        push( @file_list, $line );
    }

    close(IN_FILE);

    return @file_list;
}

sub fix_variable_attributes {
    my ( $vname, $outfile, $zName, $zValue, $zUnits ) = @_;

    return $outfile unless defined($zName) and defined($zValue);

    # Remove trailing decimal point from z value
    $zValue =~ s/\.$//;

    # Get z-type
    my $ztype = ( $zUnits eq "hPa" ) ? "pressure" : "z";

    # Set z attributes in output file
    my $cmd
        = qq(ncatted -h -O -a "z_slice_type,$vname,o,c,$ztype" -a "z_slice,$vname,o,c,$zValue$zUnits" $outfile);
    print STDERR "INFO running $cmd\n";
    my $rc = system($cmd);
    if ($rc) {
        print STDERR "WARN: Failed to run $cmd: $rc\n";
    }

# Remove z-dimension in coordinates attribute
#    my $coord_attr = `ncks -m -v $vname $outfile | grep $vname | grep coordinates`;
#    chomp($coord_attr);
#    if (defined $coord_attr) {
#	my ($coord_value) = ($coord_attr =~ /.+value\s*=\s*(.+)$/);
#-    $coord_value =~ s/\btime\b//;
#-    $coord_value =~ s/\btime1\b//;
    my $coord_value
        = Giovanni::Data::NcFile::get_variable_dimensions( $outfile, 1,
        $vname );
    if ( defined $coord_value ) {
        $coord_value =~ s/\b$zName\b//;
        $coord_value =~ s/\s+/ /g;
        $coord_value =~ s/^\s+|\s+$//g;
        $cmd
            = qq(ncatted -h -O -a "coordinates,$vname,o,c,$coord_value" $outfile);
        print STDERR "INFO running $cmd\n";
        $rc = system($cmd);
        if ($rc) {
            print STDERR "WARN: Failed to run $cmd: $rc\n";
        }
    }
}

# subset_dimension() - Dimension subsetting a single file
sub subset_dimension {
    my ( $zName, $zValue, $west, $south, $east, $north, $infile, $outfile )
        = @_;

    # Construct NCO dimension range strings
    my ( $dlat, $dlon, $dz );
    $dlat = "-d lat,$south,$north";
    $dlon = "-d lon,$west,$east";
    if ( defined($zName) and defined($zValue) ) {

        # Append a decimal point if there isn't one
        $zValue .= '.' unless $zValue =~ /\./;
        $dz = "-d $zName,$zValue,$zValue";
    }
    else {
        $dz = '';
    }

    # Subset files
    my $cmd = qq(ncks -h -O $dz $dlat $dlon $infile $outfile.tmp);
    print STDERR "INFO running $cmd\n";
    my $rc = system($cmd);
    if ($rc) {
        die "ERROR Failed to run $cmd: $rc";
    }
    if ($dz) {
        $cmd = qq(ncwa -h -O -a $zName $outfile.tmp $outfile);
        print STDERR "INFO running $cmd\n";
        $rc = system($cmd);
        if ($rc) {
            die "ERROR Failed to run $cmd: $rc";
        }
        $cmd = qq(ncks -h -O -x -v $zName $outfile $outfile.tmp);
        print STDERR "INFO running $cmd\n";
        $rc = system($cmd);
        if ($rc) {
            die "ERROR Failed to run $cmd: $rc";
        }
        rename "$outfile.tmp", $outfile;
    }
    else {
        rename "$outfile.tmp", $outfile;
    }

    return;
}

# get_outfile_name($outdir, $infile, $bbox, $zValue, $zUnits)
# Description: This function generates an output file name by deriving
#   it from the input file name plus additional information.
sub get_outfile_name {
    my ( $outdir, $infile, $bbox, $zValue, $zUnits ) = @_;

    # Create bbox string as part of file name
    my $bbox_string = get_region_label( $bbox, 0 );

    # Start with input file basename, split it in parts
    my $in_name = basename($infile);
    my @in_parts = split( '\.', $in_name );

    # Remove step name in the front and extension in the end
    shift(@in_parts);
    pop(@in_parts);

    # Remove and retain date
    my $T0 = pop(@in_parts);

    my $out_name = join( '.', @in_parts );

    # Add z value if there is one
    if ( defined $zValue ) {
        $zValue =~ s/\.$//;    # Remove trailing decimal point
        $out_name .= "-$zValue";
    }
    $out_name .= $zUnits if defined($zUnits);

    return "$outdir/subsetted.$out_name.$T0.$bbox_string.nc";
}

# get_region_label() - Create a label out of bbox
# Inputs:
#   $bbox         : Bounding box (w,s,e,n)
#   $decimal_flag : 0 = Remove decimals, 1 = Keep decimals
sub get_region_label {
    my ( $bbox, $decimal_flag ) = @_;

    my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

    # Remove decimal digits if presnt
    if ( $decimal_flag == 0 ) {
        ($lonW) = split( '\.', $lonW, 2 );
        ($lonE) = split( '\.', $lonE, 2 );
        ($latS) = split( '\.', $latS, 2 );
        ($latN) = split( '\.', $latN, 2 );
    }

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

    return $bbox_string;
}

=head1 NAME

g4_map_animation.pl - Animation of a variable map plot.

=head1 SYNOPSIS

g4_map_animation.pl
  -f input_file
  -s start_time -e end_time
  -v varname
  -o outfile
  -b bbox
  [-z zdim=zValUnits]
  [-l]

=head1 ARGUMENTS

=over 4

=item -f input_file

Pathname of the file containing all the input data files as a simple text list.

=item -s start_time

Start date/time in ISO 8601 format.

=item -e end_time

End date/time in ISO 8601 format.

=item -o outfile

Output filename.

=item -b bbox

Bounding box, in a comma-separated string (W,S,E,N).

=item -v varname

Name of the variable.

=item -z zDimName=zValUnits

Horizontal slice to extract from 3-D data,
e.g., "-z TempPrsLvls_A=500hPa" for the 500 hPa level.

=item -l

Lineage extras

=back

=head1 EXAMPLE

g4_map_animation.pl -b -180.0,-90.0,180.0,90.0 -s 2005-01-01T00:00:00Z -e 2005-01-05T23:59:59Z -v TRMM_3B42_daily_precipitation_V7 -f ./files1iZyd.txt -o MpAn.TRMM_3B42_daily_precipitation_V7.20050101-20050105.180W_50S_180E_50N.nc -l lineage_extras_Gx123.txt

=head1 AUTHOR

Edward Seiler, Adnet Systems Inc.

=cut
