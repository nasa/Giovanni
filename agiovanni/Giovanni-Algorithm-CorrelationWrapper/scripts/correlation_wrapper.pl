#!/usr/bin/env perl

#$Id: correlation_wrapper.pl,v 1.48 2015/03/18 21:30:01 dedasilv Exp $
#-@@@ Giovanni, Version $Name:  $

=pod

=head1 NAME

correlation_wrapper.pl - wrapper script to run nccorrelate in aGiovanni

=head1 SYNOPSIS

correlation_wrapper.pl
B<-f> I<input_file>
B<-d> I<data_info_file>
B<-x> I<var,zdim=zvalzunits>
B<-y> I<var,zdim=zvalzunits>
B<-s> I<start>
B<-e> I<end>
[B<-d> I<output_dir>]
[B<-b> I<bounding_box>]
[B<-O> I<output_file>]
[B<-M> I<minimum sample size>]
[B<-v> I<verbose_level>]

=head1 DESCRIPTION

This script is the command line wrapper for the Perl module that in
turn wraps the nccorrelate function for execution in Giovanni4.

=head1 ARGUMENTS

=over 4

=item B<-f> I<input_file>

Input XML file with file info in it.

=item B<-d> I<data_info_file>

=item B<-o> I<output_dir>

Directory to put correlation output file. Defaults to '.'.

=item B<-x> I<var,zdim=zvalzunits>

X or reference variable. If Z slice is specified, will also include that, e.g.
TmpPrsLvls_A=850hPa.

=item B<-y> I<var,zdim=zvalzunits>

Y or dependent variable. If Z slice is specified, will also include that, e.g.
TmpPrsLvls_A=850hPa.

=item B<-b> I<bounding_box>

bounding box in "W,S,E,N" format

=item B<-s> I<start>

Start time in ISO8601 format.

=item B<-e> I<end>

Start time in ISO8601 format.

=item B<-O> I<output_file>

If specified, output will be written to this file.
If not, it will be computed.
In either case, it is echoed to stderr at the successful
completion of the progam.

=item B<-M> I<minimum sample size>
Minimum sample size required for computing correlation.  Default is 3.

=back

=head1 AUTHOR

Christopher Lynnes, NASA/GSFC

=cut

#  $Id: correlation_wrapper.pl,v 1.48 2015/03/18 21:30:01 dedasilv Exp $
#  -@@@ AppName, Version $Name:  $

use Giovanni::Algorithm::CorrelationWrapper;
use Giovanni::Util;
use Getopt::Std;
use Cwd;

use strict;
use vars
    qw($opt_f $opt_d $opt_o $opt_O $opt_b $opt_s $opt_e $opt_v $opt_x $opt_y $opt_M);

getopts('f:d:o:O:s:e:b:v:x:y:M:');
my $outdir = $opt_o || getcwd();
my $min_sample_size = 3;
$min_sample_size = $opt_M if $opt_M;

warn
    "STEP_DESCRIPTION Compute correlation between two variables over time at each lat/lon grid location\n";

# Match files up into pairs
my $file_list = 'files.txt';
my @data_info_files = split( ",", $opt_d );
Giovanni::Util::trim(@data_info_files);
my ( $vartext, $use_time, @vars )
    = Giovanni::Algorithm::CorrelationWrapper::mk_file_list( $opt_f, $opt_x,
    $data_info_files[0], $opt_y, $data_info_files[1], $file_list,
    $min_sample_size );

my @fields = ( $opt_x, $opt_y );

# Backward compatibility with Kepler workflow, with no -x and -y args
unless ($opt_x) {
    ( $opt_x, $opt_y ) = @vars;
    @fields = @vars;
}
warn("DEBUG vartext=$vartext\n") if ( $opt_v > 1 );

my $outfile = $opt_O
    || Giovanni::Algorithm::CorrelationWrapper::mk_output_filename( $outdir,
    \@fields, $opt_s, $opt_e, $use_time );

unless ($opt_b) {
    # set the bounding box as the globe if no bounding box was specified
    $opt_b = "-180,-90,180,90";
}

# Currently, run_correlation does not change $outfile, but...it could...
$outfile
    = Giovanni::Algorithm::CorrelationWrapper::run_correlation( $file_list,
    $outfile, $opt_b, $opt_v, $opt_x, $opt_y );
warn "INFO wrote output to $outfile\n";

my @variables = @fields;
map {s/,.*//} @variables;          # strip off z level info

#
# Fix/clean up difference field
#

# Determine if two variables are same quantity type
# Assuming var1 and var2 in @variables are in order
my $file_pair_0 = `head -1 $file_list`;
chomp($file_pair_0);
my ( $fileA, $fileB ) = split( '\s', $file_pair_0, 2 );
my $quantA = `ncks -m -v $variables[0] $fileA|grep quantity_type`;
my $quantB = `ncks -m -v $variables[1] $fileB|grep quantity_type`;
($quantA) = ( $quantA =~ /value\s*=\s*(.+)\b/ );
($quantB) = ( $quantB =~ /value\s*=\s*(.+)\b/ );
my $unitA = `ncks -m -v $variables[0] $fileA|grep units`;
my $unitB = `ncks -m -v $variables[1] $fileB|grep units`;
($unitA) = ( $unitA =~ /value\s*=\s*(.+)\b/ );
($unitB) = ( $unitB =~ /value\s*=\s*(.+)\b/ );

if ( ( $quantA eq $quantB ) and ( $unitA eq $unitB ) ) {

    # Retain difference and fix its attributes
    my $quant_new    = "${quantA}_difference";
    my $longname_new = $vartext;
    $longname_new =~ s/vs\./and/;
    $longname_new = "Time matched difference between $longname_new";
    Giovanni::Algorithm::CorrelationWrapper::run_command( $opt_v,
        "ncatted -O -h -a long_name,time_matched_difference,o,c,\"$longname_new\" $outfile"
    );
    Giovanni::Algorithm::CorrelationWrapper::run_command( $opt_v,
        "ncatted -O -h -a quantity_type,time_matched_difference,o,c,\"$quant_new\" $outfile"
    );
}
else {

    # Remove the difference field
    Giovanni::Algorithm::CorrelationWrapper::run_command( $opt_v,
        "ncks -h -O -x -v time_matched_difference $outfile $outfile.tmp" );
    `mv $outfile.tmp $outfile` unless $?;
}

#
# Compute time averaged means from saved sum_x and sum_y
#

compute_means( $outfile, \@variables, $file_pair_0, $opt_v, \@fields );

#
# Plot hints
#

add_plot_hints( $outfile, $opt_s, $opt_e, $vartext );

my $caption = create_plot_caption( $file_list, $vartext );
Giovanni::Algorithm::CorrelationWrapper::run_command( $opt_v,
    "ncatted -h -O -a plot_hint_caption,global,o,c,\"$caption\" $outfile" )
    if $caption;

# Technical Debt:  rename latitude and longitude to lat and lon, for now
rename_lat_lon($outfile);

#
# Add start/end time global attributes
#

# Using command line start/end time but convert them to ISO format if needed
my ( $stime, $etime )
    = Giovanni::Algorithm::CorrelationWrapper::get_start_end_times(
    $file_list);

if ($stime) {
    Giovanni::Algorithm::CorrelationWrapper::run_command( $opt_v,
        "ncatted -O -h -a matched_start_time,global,a,c,$stime $outfile" );
    warn
        "WARN Failed to update start times: ncatted -a matched_start_time,global,o,c \"$stime\" $outfile ($!)\n"
        if $?;
}
if ($etime) {
    Giovanni::Algorithm::CorrelationWrapper::run_command( $opt_v,
        "ncatted -O -h -a matched_end_time,global,a,c,$etime $outfile" );
    warn
        "WARN Failed to update end times: ncatted -a matched_end_time,global,o,c \"$etime\" $outfile ($!)\n"
        if $?;
}

#
# Add input_temporal_resolution global attribute
#

my $time_reso = get_nc_attribute( $fileA, "temporal_resolution", undef );
if ($time_reso) {
    Giovanni::Algorithm::CorrelationWrapper::run_command( $opt_v,
        "ncatted -O -h -a input_temporal_resolution,global,a,c,\"$time_reso\" $outfile"
    );
    warn
        "WARN Failed to add input_temporal_resolution: ncatted -a input_temporal_resolution,global,o,c \"$time_reso\" $outfile ($!)\n"
        if $?;
}
else {
    warn("WARN Did not find temporal_resolution attribute in file $fileA");
}
exit(0);

##########################################################################

# compute_means() - Conmpute time averaged means from sum_x and sum_y
# Description:
#   These will be matched means.  sum_x and sum_y will be removed after
#   the means are computed.
# Assumption:  Variables A and B corresponds sum_x and sum_y
# Inputs:
#   $ncfile    - Correlation file that contains sum_x and sum_y
#   $variables - Array of variable names
#   $file_pair - A pair of original data files from which we can get
#                attributes of the original variables

# TECHNICAL DEBT:  this should be done in nccorrelate.

sub compute_means {
    my ( $ncfile, $variables, $file_pair, $verbose, $ra_fields ) = @_;

    my $ncfile_tmp = "$ncfile.tmp";

    my ( $fileA, $fileB ) = split( '\s', $file_pair_0, 2 );
    my ( $varA, $varB ) = ( $variables->[0], $variables->[1] );

    # Compute means
    # NaN will be used as fill values
    Giovanni::Algorithm::CorrelationWrapper::run_command( $opt_v,
        "ncap2 --64 -h -O -s \"$varA=(n_samples>0)*(sum_x/n_samples); $varB=(n_samples>0)*(sum_y/n_samples);\" $ncfile $ncfile_tmp"
    );

    # Change _FillValue attribute to "nan" to match what's in the mean data
    # Then change it back to a double value
    # This is necessary because ncap2 is not able to match NaN (and get_miss()
    # result) which would allow to set nan in data to the original fillvalue.
    `ncatted -O -h -a _FillValue,$varA,o,d,nan -a _FillValue,$varB,o,d,nan $ncfile_tmp`;

    # Need to save 0-values as the current NCO has a bug and treats 0 as Nan.
    # This will no longer be needed once we have an updated NCO.
    `ncap2 -h -O -s "where($varA==0) $varA=-9.96920996838687e+36; where($varB==0) $varB=-9.96920996838687e+36;" $ncfile_tmp $ncfile_tmp.tmp1`;
    if ($?) {
        print STDERR
            "WARN Setting 0s to -9.96920996838687e+36 failed (ncap2 -h -O -s \"where($varA==0) $varA=-9.96920996838687e+36; where($varB==0) $varB=-9.96920996838687e+36;\" $ncfile_tmp $ncfile_tmp.tmp1)\n";
        return undef;
    }

    # Set fillvalue back to a numeric value
    `ncatted -O -h -a "_FillValue,$varA,o,d,9.96920996838687e+36" -a "_FillValue,$varB,o,d,9.96920996838687e+36" $ncfile_tmp.tmp1`;
    if ( $? > 0 ) {
        print STDERR "WARN Replacing fill value failed in $ncfile_tmp.tmp1\n";
        return undef;
    }

    # Restore 0s
    `ncap2 -h -O -s "where($varA==-9.96920996838687e+36) $varA=0; where($varB==-9.96920996838687e+36) $varB=0;" $ncfile_tmp.tmp1 $ncfile_tmp`;
    if ($?) {
        print STDERR
            "WARN Setting -9.96920996838687e+36 back to 0 failed (ncap2 -h -O -s \"where($varA==-9.96920996838687e+36) $varA=0; where($varB==-9.96920996838687e+36) $varB=0;\" $ncfile_tmp.tmp1 $ncfile_tmp)\n";
        return undef;
    }
    unlink("$ncfile_tmp.tmp1");

    # Fix attributes - A
    foreach my $aname (
        "long_name",       "standard_name",
        "units",           "product_short_name",
        "product_version", "quantity_type",
        "Serializable",    "grid_name",
        "grid_type",       "level_description"
        )
    {
        my $avalue = get_nc_attribute( $fileA, $aname, $varA );
        next unless $avalue;
        `ncatted -O -h -a "$aname,$varA,o,c,$avalue" $ncfile_tmp`;
    }
    `ncatted -O -h -a "coordinates,$varA,o,c,lat lon" $ncfile_tmp`;

    # Fix attributes - B
    foreach my $aname (
        "long_name",       "standard_name",
        "units",           "product_short_name",
        "product_version", "quantity_type",
        "Serializable",    "grid_name",
        "grid_type",       "level_description"
        )
    {
        my $avalue = get_nc_attribute( $fileB, $aname, $varB );
        next unless $avalue;
        `ncatted -O -h -a "$aname,$varB,o,c,$avalue" $ncfile_tmp`;
    }
    `ncatted -O -h -a "coordinates,$varB,o,c,lat lon" $ncfile_tmp`;

    # add z slice attribute info (z_slice, z_slice_type)
    add_z_info_to_variables( $ncfile_tmp, $verbose, @$ra_fields );

    # Copy back to ncfile with sum_x and sum_y removed
    `ncks -h -O -x -v sum_x,sum_y $ncfile_tmp $ncfile`;

    # Clean up
    unlink($ncfile_tmp);
}

sub create_plot_caption {
    my ( $filelist, $vartext ) = @_;
    my $caption = undef;

    #
    # Get first files and last files
    #

    my $first_pair = `head -1 $filelist`;
    my $last_pair  = `tail -1 $filelist`;
    chomp($first_pair);
    chomp($last_pair);
    return undef unless $first_pair and $last_pair;
    my ( $fileA0, $fileB0 ) = split( '\s', $first_pair, 2 );
    my ( $fileA1, $fileB1 ) = split( '\s', $last_pair,  2 );

    #
    # This is needed only for daily data
    #

    my $t_reso = get_nc_attribute( $fileA0, "temporal_resolution" );
    if ( !$t_reso ) {
        print STDERR "WARN temporal_resolution missing, ignore caption\n";
        return undef;
    }
    return undef unless $t_reso eq "daily";

    #
    # Get time range
    #
    my $tstart1_iso = get_nc_attribute( $fileA0, "start_time" );
    my $tend1_iso   = get_nc_attribute( $fileA1, "end_time" );
    my $tstart2_iso = get_nc_attribute( $fileB0, "start_time" );
    my $tend2_iso   = get_nc_attribute( $fileB1, "end_time" );
    my ($tstart1_hhmm) = ( $tstart1_iso =~ /T(\d\d:\d\d)/ );
    my ($tend1_hhmm)   = ( $tend1_iso   =~ /T(\d\d:\d\d)/ );
    my ($tstart2_hhmm) = ( $tstart2_iso =~ /T(\d\d:\d\d)/ );
    my ($tend2_hhmm)   = ( $tend2_iso   =~ /T(\d\d:\d\d)/ );
    if ( $tstart1_hhmm eq "00:00" and $tend1_hhmm eq "23:59" ) {
        $tstart1_iso =~ s/T.+$//;
        $tend1_iso   =~ s/T.+$//;
    }
    else {
        $tstart1_iso =~ s/T.+$//;
        $tstart1_iso .= " ${tstart1_hhmm}Z";
        $tend1_iso =~ s/T.+$//;
        $tend1_iso .= " ${tend1_hhmm}Z";
    }
    if ( $tstart2_hhmm eq "00:00" and $tend2_hhmm eq "23:59" ) {
        $tstart2_iso =~ s/T.+$//;
        $tend2_iso   =~ s/T.+$//;
    }
    else {
        $tstart2_iso =~ s/T.+$//;
        $tstart2_iso .= " ${tstart2_hhmm}Z";
        $tend2_iso =~ s/T.+$//;
        $tend2_iso .= " ${tend2_hhmm}Z";
    }

    #
    # Get variable attributes
    #
    #-    my $vname1 = get_nc_vname($fileA0, "science", 1);
    #-    my $vname2 = get_nc_vname($fileB0, "science", 1);
    #-    if (! $vname1 or ! $vname2) {
    #-        print STDERR "WARN Fail to found both variable names\n";
    #-        return undef;
    #-    }
    my @variables = split( ' vs. ', $vartext );
    my $vname1    = $variables[0];
    my $vname2    = $variables[1];

    #
    # Construct caption
    #
    $caption
        = "The data date range for the first variable, $vname1, is $tstart1_iso - $tend1_iso. The data date range for the second variable, $vname2, is $tstart2_iso - $tend2_iso.";

    # The plot_hint_caption is needed only when times are abnormal (right now
    # for daily only and abnormal means not "00:00:00" for start time)
    if (( $tstart1_iso =~ /T00:00:00Z/ and $tstart2_iso =~ /T00:00:00Z/ )
        or (    $tstart1_iso =~ /^\d\d\d\d-\d\d-\d\d$/
            and $tstart2_iso =~ /^\d\d\d\d-\d\d-\d\d$/ )
        )
    {
        return undef;
    }
    else {
        return $caption;
    }
}

sub get_nc_attribute {
    my ( $ncfile, $aname, $vname ) = @_;

    my $a_str;
    if ($vname) {
        $a_str = `ncks -m -v $vname $ncfile | grep $vname | grep $aname`;
    }
    else {
        $a_str = `ncks -h -x $ncfile | grep $aname`;
    }
    chomp($a_str);
    if ( !$a_str ) {
        print STDERR "WARN Cannot find attribute $aname\n";
        return undef;
    }
    else {
        my ($avalue) = ( $a_str =~ /value\s*=\s*(.+)$/ );
        return $avalue;
    }
}

# get_nc_vname - Get variable name from nc file
# $ncfile - nc file
# $vtype - variable type ["science"]
# $limit - Max number of variables to get
sub get_nc_vname {
    my ( $ncfile, $vtype, $limit ) = @_;
    my @vnames_all = `ncks -m $ncfile|grep "RAM"|cut -d ' ' -f 1`;
    my $cnt        = 0;
    my @vnames     = ();
    for my $v (@vnames_all) {
        chomp($v);
        next
            if $v eq "time"
                or $v eq "time1"
                or $v eq "lat"
                or $v eq "lon"
                or $v eq "dataday"
                or $v eq "datamonth";
        push( @vnames, $v );
        $cnt++;
        last if $cnt == $limit;
    }
    if ( $cnt == 0 ) {
        print STDERR "WARN No science variable found in $ncfile\n";
        return undef;
    }

    if ( $cnt == 1 ) {
        return $vnames[0];
    }
    else {
        return \@vnames;
    }
}

sub add_plot_hints {
    my ( $outfile, $start, $end, $vartext ) = @_;

    $start =~ s/T.*$//;
    $end   =~ s/T.*$//;
    my @variables = split( ' vs. ', $vartext );
    my $plot_title
        = "Correlation (top) and Sample Size (bottom) for $start - $end";
    my $plot_subtitle
        = "1st Variable: $variables[0]~C~2nd Variable: $variables[1]";
    my $title   = "Correlation of $vartext";
    my $caption = $title . '. ' . $plot_subtitle;
    $caption =~ s/~C~/. /g;

    # Form the ncatted command
    my $cmd = sprintf "ncatted -O -o $outfile";
    $cmd .= sprintf " -a 'title,global,o,c,%s'",              $title;
    $cmd .= sprintf " -a 'long_name,correlation,m,c,%s'",     $title;
    $cmd .= sprintf " -a 'plot_hint_title,global,c,c,%s'",    $plot_title;
    $cmd .= sprintf " -a 'plot_hint_subtitle,global,c,c,%s'", $plot_subtitle;

    #-  $cmd .= sprintf " -a 'plot_hint_caption,global,c,c,%s'", $caption;
    $cmd .= " -a 'plot_hint_minval,correlation,c,d,-1.0'";
    $cmd .= " -a 'plot_hint_maxval,correlation,c,d,1.0'";
    $cmd .= " $outfile";

    # If it fails, trip an error, but continue on through to completion
    if ( system($cmd) != 0 ) {
        my $err = sprintf( "ERROR failed to execute command %s: exit=%d\n",
            $cmd, $? >> 8 );
        warn($err);
        warn "USER_ERROR failed to add plot text to file\n";
    }
    return;
}

sub rename_lat_lon {
    my $outfile = shift;
    my $cmd
        = "ncrename -d .latitude,lat -d .longitude,lon -v .latitude,lat -v .longitude,lon -O $outfile";
    if ( system($cmd) != 0 ) {
        warn("USER_ERROR failed to rename lat/lon variables\n");
        warn(
            sprintf( "ERROR failed to rename lat/lon variables: %d\n",
                $? >> 8 )
        );
        exit(3);
    }
}

sub add_z_info_to_variables {
    my ( $file, $verbose, @fields ) = @_;
    my @ncatted_arg;
    foreach my $field (@fields) {

        # Split var,dim=valunits
        my ( $var, $zinfo ) = split( ',', $field );

        # Skip to next if no zinfo found
        next unless ($zinfo);

        # Parse for value and units.
        # But we only use
        my ( $zval, $zunits ) = ( $zinfo =~ /.*?=([\d\.]+)(.*)$/ );
        my $z_slice_type = $zunits;
        if ( $zunits eq 'hPa' ) {
            $z_slice_type = 'pressure';
        }
        elsif ( $zunits eq 'km' ) {
            $z_slice_type = 'altitude';
        }
        $z_slice_type = 'height' if ( $zunits eq 'km' );
        push @ncatted_arg,
            "-a z_slice,$var,o,c,$zval$zunits -a z_slice_type,$var,o,c,$z_slice_type";
    }

    # If we got z_info for any of them, then run ncatted
    if (@ncatted_arg) {
        my $cmd = join( " ", "ncatted -h -O", @ncatted_arg, $file );
        Giovanni::Algorithm::CorrelationWrapper::run_command( $verbose,
            $cmd );
    }
}
