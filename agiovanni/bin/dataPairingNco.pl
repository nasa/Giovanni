#!/usr/bin/perl -w

=head1 NAME

dataPairingNco.pl - Paring data for netcdf files using NCO

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

dataPairingNco.pl [--help] [--verbose] --outDir sessiondir --bbox bbox -x xlevel -y ylevel -f xmlfile

=head1 DESCRIPTION

This program pairs variables for scatter plots.  In the current version,
spatial resolutions and shapes are the same for all variables.

=head1 OPTIONS

=over 4

=item --help
Print a usage information

=item --verbose
Turn on verbose mode

=item -f xmlfile
Input xml file that contains a data file information

=item --outDir output directory
Output directory

=item --bbox bbox
Bounding box specified as "lonW,latS,lonE,latN"

=item -x xlevel
Level selection for the first variable in the format of vname,zname=<zvalue><zunits>

=item -y ylevel
Level selection for the second variable in the format of vname,zname=<zvalue><zunits>

=back

=head1 AUTHOR

Jianfu Pan (jianfu.pan@nasa.gov)

=cut

use lib ".";

use strict;
use Getopt::Long;
use File::Basename;
use XML::LibXML;
use Giovanni::Data::NcFile;

my $cmd_dir = dirname($0);
our $cmd_getdimnames    = "$cmd_dir/getNcDimList.py";
our $cmd_getvarnames    = "$cmd_dir/getNcVarList.py";
our $cmd_getattribute   = "$cmd_dir/getNcAttribute.py";
our $cmd_getfillvalues  = "$cmd_dir/getNcFillValue.py";
our $cmd_getregionlabel = "$cmd_dir/getNcRegionLabel.py";
our $cmd_gettime        = "$cmd_dir/getNcData1D.py -t int";

my $help;
my $debug_level = 0;
my $verbose;
my $inxml;
my $sessiondir = "./output";
my $xlevel     = undef;
my $ylevel     = undef;
my $bbox       = undef;
my $result     = GetOptions(
    "help"      => \$help,
    "h"         => \$help,
    "verbose=s" => \$verbose,
    "file=s"    => \$inxml,
    "f=s"       => \$inxml,
    "outDir=s"  => \$sessiondir,
    "x=s"       => \$xlevel,
    "y=s"       => \$ylevel,
    "bbox=s"    => \$bbox,
    "b=s"       => \$bbox
);

my $usage
    = "Usage: $0 [--help] [--verbose] --bbox bbox --outDir sessiondir -f xmlfile\n"
    . "    --help           Print this help info\n"
    . "    --verbose        Print out lot of messages\n"
    . "    -f       xmlfile Input xml file\n"
    . "    --outDir outdir  Session directory\n"
    . "    -x       xlevel  Level spec for the 1st variable (vname,zname,zvalue)\n"
    . "    -y       ylevel  Level spec for the 2nd variable (vname,zname,zvalue)\n"
    . "    --bbox   bbox    Bounding box specified as \"lonW,latS,lonE,latN\"\n";

$xlevel = undef
    if defined($xlevel)
        and ( $xlevel eq "NA" or $xlevel eq "na" );
$ylevel = undef
    if defined($ylevel)
        and ( $ylevel eq "NA" or $ylevel eq "na" );

# Print usage and exit if that's all asked for
if ($help) {
    print STDERR $usage;
    exit(0);
}

# Check required options
die("ERROR Input xml file missing") unless -f $inxml;

# Create output directory if it doesn't exist
if ( !-d $sessiondir ) {
    mkdir( $sessiondir, 0755 )
        || die("ERROR Fail to make session dir $sessiondir");
}

print STDERR "USER_MSG Executing data pairing\n";
print STDERR "STEP_DESCRIPTION Variables pairing for the selected region\n";

#
# Get lists of nc files from input xml file and save them into infiles
#

my $infiles = get_infiles($inxml);

my $Nlists = scalar(@$infiles);
if ( $Nlists < 2 ) {
    print STDERR
        "WARN Less than 2 file lists. Exiting without doing anything...\n";
    exit(0);
}

#
# Check existence of dataday
# dataday handling includes: [dataday datamonth]
#

my $isDataDay   = 0;
my $isDataMonth = 0;
foreach my $l (@$infiles) {
    my $f = `head -1 $l`;
    chomp($f);
    my $all_vars = `ncks -m $f|grep "RAM"|cut -d ' ' -f1`;
    die("ERROR ncks fail ncks -m $f|grep \"RAM\"|cut -d ' ' -f1") if $?;
    $isDataDay++   if $all_vars =~ /\bdataday\b/s;
    $isDataMonth++ if $all_vars =~ /\bdatamonth\b/s;
}
if ( $isDataDay and $isDataDay != $Nlists ) {
    print STDERR "ERROR The dataday variable not in all lists\n";
    exit(-1);
}
if ( $isDataMonth and $isDataMonth != $Nlists ) {
    print STDERR "ERROR The datamonth variable not in all lists\n";
    exit(-1);
}

my $dataday = "";
$dataday = "dataday"   if $isDataDay;
$dataday = "datamonth" if $isDataMonth;

#
# Localize files for handling a large number of files
#

my $infiles_new = localize_filelists($infiles);

#
# Get time union
# timeunion  : Unionized times in a dictionary
# timelists  : Array of time dictionary for individual lists, values are
#              file names
#

my ( $timeunion, $timelists ) = get_timeunion( $infiles_new, $dataday );

print STDERR "PERCENT_DONE 10\n";

#
# Create blank files
#

#
# Pairing data
#

my $filelists_0 = get_file_lists( $infiles->[0] );
my $filelists_1 = get_file_lists( $infiles->[1] );
my $outfile
    = get_outfile_name( $sessiondir, $filelists_0->[0], $filelists_1->[0],
    $filelists_0->[-1], $bbox, $xlevel, $ylevel );
my $rc = pair_data( $infiles_new, $timeunion, $timelists, $bbox, $outfile,
    $dataday, $xlevel, $ylevel );

#
# Exit with empty nc file if there is no match
#

if ( $rc == 0 ) {
    `touch $outfile`;
    print STDERR "WARN No match found in pairing data\n";
    print STDERR "OUTPUT $outfile\n";
    print STDERR "PERCENT_DONE 100\n";
    exit(0);
}

print STDERR "PERCENT_DONE 80\n";

#
# Set title attribute with region label
#

my $region_label = get_region_label($bbox);
my $prodnames    = get_product_names($infiles);
my $prodnameStr  = join( ' ', @$prodnames );

my $title = "Data match: $prodnameStr";
$title = "Data match ($region_label): $prodnameStr" if defined($region_label);
`ncatted -h -O -a "title,global,o,c,$title" $outfile`;

#
# Add plot hint caption
#

my $caption = create_plot_caption( $filelists_0, $filelists_1 );
`ncatted -h -O -a "plot_hint_caption,global,o,c,$caption" $outfile`
    if $caption;

#
# Finishing up
#

print STDERR "OUTPUT $outfile\n";
print STDERR "PERCENT_DONE 100\n";

exit(0);

sub create_plot_caption {
    my ( $filelist1, $filelist2 ) = @_;
    my $caption = undef;

    #
    # This is needed only for daily data
    #

    my $t_reso = get_nc_attribute( $filelist1->[0], "temporal_resolution" );
    if ( !$t_reso ) {
        print STDERR "WARN temporal_resolution missing, ignore caption\n";
        return undef;
    }
    return undef unless $t_reso eq "daily";

    #
    # Get time range
    #
    my $tstart1_iso = get_nc_attribute( $filelist1->[0],  "start_time" );
    my $tend1_iso   = get_nc_attribute( $filelist1->[-1], "end_time" );
    my $tstart2_iso = get_nc_attribute( $filelist2->[0],  "start_time" );
    my $tend2_iso   = get_nc_attribute( $filelist2->[-1], "end_time" );

    # No caption when times start at 00:00:00
    return undef if $tstart1_iso =~ /00:00:00/ and $tstart2_iso =~ /00:00:00/;

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
    my $vname1 = get_nc_vname( $filelist1->[0], "science", 1 );
    my $vname2 = get_nc_vname( $filelist2->[0], "science", 1 );
    if ( !$vname1 or !$vname2 ) {
        print STDERR "WARN Fail to found both variable names\n";
        return undef;
    }

    #
    # Construct caption
    #
    $caption
        = "The data date range for the first variable, $vname1, is $tstart1_iso - $tend1_iso. The data date range for the second variable, $vname2, is $tstart2_iso - $tend2_iso.";

    return $caption;
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
        print STDERR "WARN Cannot found attribute $aname\n";
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

sub get_infiles {
    my ($inxml) = @_;

    my $infiles         = [];
    my $infile_template = "dataPairing.$$";

    my $parser = XML::LibXML->new();
    my $xml    = $parser->parse_file($inxml);

    my @listNodes = $xml->findnodes('/data/dataFileList');
    my $cnt       = 1;
    foreach my $node (@listNodes) {
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

    return $infiles;
}

sub get_product_names {
    my ($infiles) = @_;
    my $prodnames = [];
    foreach my $in (@$infiles) {
        my $flist    = get_file_lists($in);
        my $file_0   = $flist->[0];
        my $vnameStr = `$cmd_getvarnames $file_0`;
        chomp($vnameStr);
        my @vnames = split( ' ', $vnameStr );
        my $prod_name
            = `$cmd_getattribute -v $vnames[0] -a product_short_name $file_0`;
        chomp($prod_name);
        my $prod_version
            = `$cmd_getattribute -v $vnames[0] -a product_version $file_0`;
        chomp($prod_version);
        push( @$prodnames, "$prod_name.$prod_version" );
    }
    return $prodnames;
}

sub get_region_label {
    my ($bbox) = @_;
    return undef unless defined($bbox);

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
    return $region_label;
}

# ------------------------------------------------------------------
# pair_data() - Creates paired data from input file lists
# Inputs:
#   infiles   : Array of input file lists (at least two)
#   timeunion : Dictionary of all time values
#   timelists : Array of time dictionary of lists
#   bbox      : Bounding box of the subregion
#   outfile   : Output file name for saving paired data
#   dataday   : Dataday name if it is present
#   xlevel    : Level spec for the 1st variable
#   ylevel    : Level spec for the 2nd variable
#   :level spec  : vname,zname=<zvalue><zunits>
# ------------------------------------------------------------------
sub pair_data {
    my ( $infiles, $timeunion, $timelists, $bbox, $outfile, $dataday, $xlevel,
        $ylevel )
        = @_;

    my $Nlists   = scalar(@$timelists);
    my @time_all = sort( keys(%$timeunion) );

    my $err = 0;

    # Parse the level spec for slicing z-dimension
    # Assuming x is for 1st list and y for 2nd list, otherwise more algorithm
    #   is needed.
    my @Vnames  = ( undef, undef );
    my @znames  = ( undef, undef );
    my @zvalues = ( undef, undef );
    my @zunits  = ( "",    "" );
    if ( defined($xlevel) ) {
        my ( $vname, $zname, $zvalue, $zunits )
            = ( $xlevel =~ /^(.+),(.+)=([\d\.]+)(.*)$/ );
        $Vnames[0] = $vname  if $vname;
        $znames[0] = $zname  if $zname;
        $zunits[0] = $zunits if $zunits;
        if ( $zvalue ne "" ) {
            $zvalue = "$zvalue." unless $zvalue =~ /\./;
            $zvalues[0] = $zvalue;
        }
        elsif ( $zvalue eq "na" or $zvalue eq "NA" ) {
            $znames[0]  = undef;
            $zvalues[0] = undef;
        }
    }
    if ( defined($ylevel) ) {
        my ( $vname, $zname, $zvalue, $zunits )
            = ( $ylevel =~ /^(.+),(.+)=([\d\.]+)(.*)$/ );
        $Vnames[1] = $vname  if $vname;
        $znames[1] = $zname  if $zname;
        $zunits[1] = $zunits if $zunits;
        if ( $zvalue ne "" ) {
            $zvalue = "$zvalue." unless $zvalue =~ /\./;
            $zvalues[1] = $zvalue;
        }
        elsif ( $zvalue eq "na" or $zvalue eq "NA" ) {
            $znames[1]  = undef;
            $zvalues[1] = undef;
        }
    }

    # Create new infiles of paired file lists
    my @infiles_paired = ();
    foreach my $in (@$infiles) {
        my $in_paired = "$in.$$.paired";
        push( @infiles_paired, $in_paired );
    }

    my $cnt_pairs  = 0;
    my $start_time = "";
    my $end_time   = "";
    my ( $matched_start_time, $matched_end_time ) = ( "", "" );
    my $t_last;
    foreach my $t (@time_all) {
        $t_last = $t;

        # Go through file lists to match a file for the time
        # A match is found if all all lists have the time point
        # $cnt_nomissing : Counts number of lists having the match

        my $cnt_nomissing = 0;
        my $l             = 0;
        foreach my $infile (@$infiles) {
            $cnt_nomissing++ if exists( $timelists->[$l]->{$t} );
            $l++;
        }
        next if $cnt_nomissing != $Nlists;

        # Now we have a match
        # Record down stat time of the range from 1st file of 1st list
        if ( !$start_time ) {
            my $f00 = $timelists->[0]->{$t};
            my $x   = `ncks -M $f00 | grep start_time`;
            if ($?) {
                print
                    "WARN Fail to get start time: ncks -M $f00 | grep start_time ($!)\n";
            }
            else {
                ($start_time) = ( $x =~ /value\s*=\s*(\d\d\d\d-.+Z)/ );
            }

            # Also save matched_start_time
            $matched_start_time = $t;
        }

        # Add the matched files
        for ( my $i = 0; $i < $Nlists; $i++ ) {
            `echo "$timelists->[$i]->{$t}" >> $infiles_paired[$i]`;
        }

        $cnt_pairs++;
    }    #--EndOf.foreach.time_all--

    # Record end time of the range from last file of 1st list
    my $f10 = $timelists->[0]->{$t_last};
    my $x1  = `ncks -M $f10 | grep end_time`;
    if ($?) {
        print
            "WARN Fail to get end time: ncks -M $f10 | grep end_time ($!)\n";
    }
    else {
        ($end_time) = ( $x1 =~ /value\s*=\s*(\d\d\d\d-.+Z)/ );
    }
    $matched_end_time = $t_last;

    #
    # If there is no match, return 0
    #

    return 0 if $cnt_pairs == 0;

    print STDERR "PERCENT_DONE 50\n";

    #
    # Putting together paired data into output file
    #

    # --- Parse bounding box ---
    my ( $lonW, $latS, $lonE, $latN ) = ( undef, undef, undef, undef );
    if ( defined($bbox) ) {
        $bbox =~ s/\s| //g;
        ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

        # Making sure they are floats
        $latS = "$latS.0" unless $latS =~ /\./;
        $latN = "$latN.0" unless $latN =~ /\./;
        $lonW = "$lonW.0" unless $lonW =~ /\./;
        $lonE = "$lonE.0" unless $lonE =~ /\./;
    }

    my %varnames        = ();
    my $time_k          = 0;    # For constructing new time variable name
                                # Change to 1 if rename all time variables
    my @tmpfiles        = ();
    my @firstTimeStamps = ();
    foreach my $in (@infiles_paired) {
        my $d_lat = "";
        my $d_lon = "";
        my $d_z   = "";
        my $flist = get_file_lists($in);

        # --- Subset for lat/lon dimensions ---
        if ( defined($bbox) ) {
            my ( $latres, $lonres )
                = Giovanni::Data::NcFile::spatial_resolution( $flist->[0],
                'lat', 'lon' );
            my $lat = `$cmd_getdimnames -t lat $flist->[0]`;
            chomp($lat);
            $lat =~ s/^\s+|\s+$//;
            my $lon = `$cmd_getdimnames -t lon $flist->[0]`;
            chomp($lon);
            $lon =~ s/^\s+|\s+$//;
            if ( abs( $latN - $latS ) < $latres ) {
                $d_lat = "-d \"$lat,$latS,$latS\"";
            }
            else {
                $d_lat = "-d \"$lat,$latS,$latN\"";
            }
            if ( abs( $lonE - $lonW ) < $lonres ) {
                $d_lon = "-d \"$lon,$lonW,$lonW\"";
            }
            else {
                $d_lon = "-d \"$lon,$lonW,$lonE\"";
            }
        }

        # --- Subset for z-dimension ---
        # --- time_k is also used as a list counter here ---

        if ( defined( $znames[$time_k] ) ) {

            # Make sure file has the z-dimension.
            my $dimlist = `$cmd_getdimnames $flist->[0]`;
            if ( $dimlist =~ /\b$znames[$time_k]\b/ ) {
                $d_z
                    = "-d \"$znames[$time_k],$zvalues[$time_k],$zvalues[$time_k]\"";
            }
        }

        # Concatenate the list of files into time series
        my $tmp_file = "$in.concat";
        my $cmd      = "ncrcat -H -h -O $d_z $d_lat $d_lon $tmp_file < $in";
        `$cmd`;
        if ($?) {
            die("ERROR Fail to concatenate $cmd $!\n");
        }
        else {

            # --- Rename variables if necessary ---
            my $vnameStr = `$cmd_getvarnames $tmp_file`;
            chomp($vnameStr);
            my @vnames = split( ' ', $vnameStr );
            foreach my $vn (@vnames) {

                # Skip dataday so we can exclude it later
                next if $vn eq "dataday" or $vn eq "datamonth";
                if ( exists( $varnames{$vn} ) ) {
                    my $vn_new = get_new_name( \%varnames, $vn );
                    $varnames{$vn_new} = 1;
                    `ncrename -v "$vn,$vn_new" $tmp_file`;
                }
                else {
                    $varnames{$vn} = 1;
                }
            }

            # --- Get rid of z-dimension ---
            while ($d_z) {

                # Remove the z-dimension
                `ncwa -O -h -a $znames[$time_k] $tmp_file $tmp_file.tmp`;
                die
                    "ERROR Fail to remove z-dimension (ncwa -O -h -a $znames[$time_k] $tmp_file $tmp_file.tmp)\n"
                    if $?;

            # TBD ncks could be done here to exclude the z variable in outputs
                `mv $tmp_file.tmp $tmp_file`;
                die "ERROR fail to mv (mv $tmp_file.tmp $tmp_file)\n" if $?;

                # Make sure we exit the while loop
                last;
            }

            # --- see if this file's time dimension matches the first time
            # dimension ---
            my $timeIsDifferent = 1;
            if ( $time_k == 0 ) {

                # this is the first set of files. Get out the time stamps so
                # we can compare the values with later time stamps
                $timeIsDifferent = 0;
                @firstTimeStamps
                    = Giovanni::Data::NcFile::get_variable_values( $tmp_file,
                    "time", "time" );
            }
            else {

                # this isn't the first set of files. Get out the time stamps
                # and see if they match the first values.
                my @timeStamps
                    = Giovanni::Data::NcFile::get_variable_values( $tmp_file,
                    "time", "time" );
                $timeIsDifferent = 0;
                for ( my $i = 0; $i < scalar(@timeStamps); $i++ ) {
                    if ( $timeStamps[$i] != $firstTimeStamps[$i] ) {
                        $timeIsDifferent = 1;
                    }
                }

            }

            # --- Merge to output file ---
            # TODO: only change time dimension IF the times are
            # different.
            if ( $dataday and $time_k > 0 and $timeIsDifferent ) {

                # Remove record dimension
                `nccopy -u $tmp_file $tmp_file.norec`;
                `mv $tmp_file.norec $tmp_file`;

                # Rename time variable
                `ncrename -h -d time,time$time_k -v time,time$time_k $tmp_file`;

                # Merge without dataday
                my $cmd = "ncks -h -A -x -v $dataday $tmp_file $outfile";
                `$cmd`;
                die("ERROR Fail to merge $cmd $!\n") if $?;
            }
            else {

                # Merge with dataday
                my $cmd = "ncks -h -A $tmp_file $outfile";
                `$cmd`;
                die("ERROR Fail to merge $cmd $!\n") if $?;
            }

            # --- Add variable level z_slice attributes---
            if ($d_z) {
                $zvalues[$time_k] =~ s/\.$//;
                my $ztype = "unknown";
                if ( $zunits[$time_k] eq "hPa" ) {
                    $ztype = "pressure";
                }
                `ncatted -h -O -a "z_slice,$Vnames[$time_k],o,c,$zvalues[$time_k]$zunits[$time_k]" $outfile`
                    || $err++;
                `ncatted -h -O -a "z_slice_type,$Vnames[$time_k],o,c,$ztype" $outfile`
                    || $err++;
            }
        }

        # Add tmp files for cleanup
        push( @tmpfiles, $tmp_file );
        push( @tmpfiles, "$tmp_file.tmp" );

        $time_k++;
    }

    #
    # Get rid of z variables
    #
    my $zname_list = "";
    if ( defined( $znames[0] ) ) {
        if ( defined( $znames[1] ) ) {
            $zname_list = join( ',', @znames );
        }
        else {
            $zname_list = $znames[0];
        }
    }
    else {
        $zname_list = $znames[1] if defined( $znames[1] );
    }

    if ( $zname_list ne "" ) {
        `ncks -h -O -x -v $zname_list $outfile $outfile.tmp`;
        if ($?) {
            print STDERR
                "ERROR Fail to delete z variables (ncks -h -O -x -v $zname_list $outfile $outfile.tmp)\n";
            $err++;
        }
        else {
            `mv $outfile.tmp $outfile`;
        }
    }

    #
    # Fix start/end times in outfile
    #

    if ( $dataday eq "dataday" ) {
        my ( $yr, $dy ) = ( $matched_start_time =~ /(\d\d\d\d)(\d\d\d)/ );
        $matched_start_time
            = `date -d "$yr-01-01 +$dy days - 1 day" "+%Y-%m-%dT00:00:00Z"`;
        chomp($matched_start_time);
        ( $yr, $dy ) = ( $matched_end_time =~ /(\d\d\d\d)(\d\d\d)/ );
        $matched_end_time
            = `date -d "$yr-01-01 +$dy days - 1 day" "+%Y-%m-%dT23:59:59Z"`;
        chomp($matched_end_time);
    }
    elsif ( $dataday eq "datamonth" ) {
        my ( $yr, $dy ) = ( $matched_start_time =~ /(\d\d\d\d)(\d\d)/ );
        $matched_start_time = "$yr-$dy-01T00:00:00Z";

        # - Using whatever end time in input file
        # - ($yr, $dy) = ($matched_end_time =~ /(\d\d\d\d)(\d\d)/);
        # - $matched_end_time = "$yr-$dy-01T23:59:59Z";
        $matched_end_time = $end_time;
    }
    else {
        $matched_start_time
            = `date +"%Y-%m-%dT%H:%M:%SZ" -d \@$matched_start_time`;
        $matched_end_time
            = `date +"%Y-%m-%dT%H:%M:%SZ" -d \@$matched_end_time`;
        chomp($matched_start_time);
        chomp($matched_end_time);
    }
    `ncatted -O -h -a "matched_start_time,global,o,c,$matched_start_time" $outfile`;
    print STDERR
        "WARN Failed to update start times: ncatted -a matched_start_time,global,o,c \"$matched_start_time\" $outfile ($!)\n"
        if $?;
    `ncatted -O -h -a "matched_end_time,global,o,c,$matched_end_time" $outfile`;
    print STDERR
        "WARN Failed to update end times: ncatted -a matched_end_time,global,o,c \"$matched_end_time\" $outfile ($!)\n"
        if $?;

    # Remove start_time/end_time
    `ncatted -O -h -a "start_time,global,d,," $outfile` || $err++;
    `ncatted -O -h -a "end_time,global,d,," $outfile`   || $err++;

    #
    # Clean up
    #
    unless ( $err > 0 ) {
        foreach my $f (@tmpfiles) {
            `/bin/rm $f` if -e $f;
        }
    }

    return 1;
}

# ----------------------------------------------------------------------
# get_first_files() - Get first files in file lists
# Inputs:
#     $inlists : Array of input files (each contains list of data files)
# Description: The first file is normally used to understand the product
#              the the file belongs to.
# ----------------------------------------------------------------------
sub get_first_files {
    my ($inlists) = @_;
    my $firstfiles = [];
    foreach my $in (@$inlists) {
    }
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

# ------------------------------------------------------------------
# get_timeunion() - Get union of all file lists
# Description: Goes through all file lists, extracts and saves times
#     in a dictionary.
# Inputs:
#   $inputlists : Array ref to array of input files. Each input file
#                 contains a list of data files.
#   $dataday    : Flag to indicate if dataday exists
# ------------------------------------------------------------------
sub get_timeunion {
    my ( $inputlists, $dataday ) = @_;

    my $timeunion = {};
    my $timelists = [];    # lists of time hashes for each file list

    my $k = 0;
    foreach my $flist (@$inputlists) {
        $k++;
        my $outfile_concat_tmp = "tmp_concat_$k.nc";

        # Get time/dataday list
        my $timeStr = "";
        if ( $dataday eq "dataday" ) {
            `ncrcat -H -h -O -v "dataday" $outfile_concat_tmp < $flist`;
            $timeStr = `$cmd_gettime -v dataday $outfile_concat_tmp`;
        }
        elsif ( $dataday eq "datamonth" ) {
            `ncrcat -H -h -O -v "datamonth" $outfile_concat_tmp < $flist`;
            $timeStr = `$cmd_gettime -v datamonth $outfile_concat_tmp`;
        }
        else {
            `ncrcat -H -h -O -v "time" $outfile_concat_tmp < $flist`;
            $timeStr = `$cmd_gettime -v time $outfile_concat_tmp`;
        }
        chomp $timeStr;
        die "ERROR Fail to get time list in $outfile_concat_tmp\n" if $?;

        #
        # Create time dictionary and add to the union
        #

        my %tdict    = ();
        my @timeDat  = split( ' ', $timeStr );
        my $filelist = get_file_lists($flist);

        # --- Numbers of files and time points must match ---
        if ( scalar(@timeDat) != scalar(@$filelist) ) {
            die("ERROR unexpected mismatch in time and filelist sizes\n");
        }

        my $j = 0;
        foreach my $t (@timeDat) {
            $tdict{$t} = $filelist->[$j];
            $timeunion->{$t} = 1;
            $j++;
        }

        # --- Save individual time dict ---
        push( @$timelists, \%tdict );
    }

    return ( $timeunion, $timelists );
}

sub localize_filelists {
    my ($filelists)   = @_;
    my $filelists_new = [];
    my $k             = 1;
    foreach my $flist (@$filelists) {
        my $sig     = "pair$k";
        my $txt_new = "in_$k.txt";
        my ( $txt_new_tmp, $symlinks )
            = localize_files( $flist, $txt_new, $sig );
        if ( -s $txt_new ) {
            push( @$filelists_new, $txt_new );
        }
        else {
            die("ERROR Fail to localize filelist $flist");
        }
        $k++;
    }

    return $filelists_new;
}

# ---------------------------------------------------------
# get_file_lists() - Get lists of files
# Description: Reads the input file of list of data files,
#              and returns an array ref of the file list.
# ---------------------------------------------------------
sub get_file_lists {
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

# get_time_list()
# Description: Gets list of times for each file list
sub get_time_list {
    my ($filelist) = @_;
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

# ------------------------------------------------------------------
# localize_files($infile, $infiles_new, $signature)
#
# Inputs:
#   $infile     : File that contains a list of data files
#   $infile_new : File that contains a list of symlink names
#   $signature  : Used as part of the symlink file names
# Description: to reduce amount of text in file names passed to nco
#      commands.
# -------------------------------------------------------------------
sub localize_files {
    my ( $infile, $infile_new, $signature ) = @_;
    open( INPUT, "<$infile" )
        or die("ERROR Failed to open input file $infile $!");

    # Open a unique output file to write to
    open( OUTPUT, ">$infile_new" )
        or die("ERROR Could not write to temporary file $infile_new $!");

    # Loop through input files, create symlink, add symlink to output file
    # The use of short symlink filenames gets around the file limit in ncra of
    # a total of 1 million bytes.
    my @files;
    my $i = 0;
    while (<INPUT>) {
        chomp;
        my $file = sprintf( "$signature%05d.nc", $i );
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

# ====================================================================
# get_outfile_name($infile, $infile1, $infile_last, $bbox)
# Description:  Create an output file name that follows AG convention
# Inputs:
#   $infile - First file from first file list
#   $infile1 - First file from second file list
#   $infile_last - Last file from first file list
#   $bbox - Bounding box spec
#   $xlevel - Level selection of the 1st variable
#   $ylevel - Level selection of the 2nd variable
# Algorithm:
#   Input file name pattern: <service>.<var>.<date>.nc
#   Output file: <service>.<var1>+<var2>.<date1>-<date2>.<bbox>.nc
# ====================================================================
sub get_outfile_name {
    my ( $sessiondir, $infile, $infile1, $infile_last, $bbox, $xlevel,
        $ylevel )
        = @_;

    # Parse z values
    my $zx = "";
    my $zy = "";
    my ( $x, $y );
    ( $x, $zx ) = split( "=", $xlevel, 2 ) if defined($xlevel);
    ( $y, $zy ) = split( "=", $ylevel, 2 ) if defined($ylevel);

    # Create bbox string as part of file name
    my $bbox_string = "";
    if ( defined($bbox) ) {
        my ( $lonW, $latS, $lonE, $latN ) = split( ',', $bbox );

        # Remove decimal digits
        my $foo;
        ( $lonW, $foo ) = split( '\.', $lonW, 2 );
        ( $lonE, $foo ) = split( '\.', $lonE, 2 );
        ( $latS, $foo ) = split( '\.', $latS, 2 );
        ( $latN, $foo ) = split( '\.', $latN, 2 );

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
    }

    # Parse and get info from first file of first variable
    my $in_name  = basename($infile);
    my @in_parts = split( '\.', $in_name );
    my $T0       = $in_parts[-2];
    my $var1     = $in_parts[1];

    # Parse and get info from first file of second variable
    my $in1_name  = basename($infile1);
    my @in1_parts = split( '\.', $in1_name );
    my $var2      = $in1_parts[1];

    # Get end date from the last file
    my $in_name_last  = basename($infile_last);
    my @in_parts_last = split( '\.', $in_name_last );
    my $T1            = $in_parts_last[-2];

    # Constructing output file name
    $var1 = "$var1-z$zx" if $zx;
    $var2 = "$var2-z$zy" if $zy;
    my $out_name = "pairedData.$var1+$var2.$T0-$T1";
    if ($bbox_string) {
        return "$sessiondir/$out_name.$bbox_string.nc";
    }
    else {
        return "$sessiondir/$out_name.nc";
    }
}
