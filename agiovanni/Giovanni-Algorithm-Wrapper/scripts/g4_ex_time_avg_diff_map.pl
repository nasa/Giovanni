#!/usr/bin/env perl

=head1 NAME

g4_ex_time_avg_diff_map.pl - time series of area averages of differences between two variables

=head1 SYNOPSIS

g4_ex_time_avg_diff_map.pl 
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

g4_ex_time_avg_diff_map.pl -x AIRX3STD_006_Temperature_A,TempPrsLvls_D=850hPa -y AIRX3STD_006_Temperature_D,TempPrsLvls_D=850hPa -f files.txt -b -180,-90.,180.0,90 -o airs.nc

=head1 AUTHOR

Richard Strub, NASA/GSFC, Adnet Systems

=cut

use strict;
use Getopt::Std;
use File::Basename;
use Giovanni::Util;
use Giovanni::Logger;
use Giovanni::Data::NcFile;
use Giovanni::Algorithm::TimeAveragerNco;
use Time::Local;
use warnings;

# Define and parse argument vars
#'g4_time_avg_diff_map.pl'
#--inputfiles mfst.regrid+dTRMM_3A12_007_snow+z0.5+dTRMM_3B43_007_precipitation+zNA+t20090101000000_20090228235959+b103.3594W_3.0234N_65.3906W_35.3672N.xml
#--bbox '-103.3594,3.0234,-65.3906,35.3672'
#--outfile '/var/tmp/www/TS2/giovanni/10324E50-E0EF-11E3-A589-3534195684FF/2ED052F8-E0EF-11E3-9F23-E637195684FF/2ED06CE8-E0EF-11E3-9F23-E637195684FF/mfst.result+sTIME_AVG_DIFF_MAP+dTRMM_3A12_007_snow+z0.5+dTRMM_3B43_007_precipitation+zNA+t20090101000000_20090228235959+b103.3594W_3.0234N_65.3906W_35.3672N.xml'
#--zfiles 'mfst.data_field_slice+dTRMM_3A12_007_snow+z0.5.xml,mfst.data_field_slice+dTRMM_3B43_007_precipitation+zNA.xml'
#--varfiles 'mfst.data_field_info+dTRMM_3A12_007_snow.xml,mfst.data_field_info+dTRMM_3B43_007_precipitation.xml'
#--starttime "2009-01-01T00:00:00Z"
#--endtime "2009-02-28T23:59:59Z"
#--variables TRMM_3A12_007_snow,TRMM_3B43_007_precipitation
#--name 'Time Average Difference Map'  --debug 0 --time-axis
#
# g4_time_avg_diff_map.pl
#-b -103.3594,3.0234,-65.3906,35.3672
#-s 2009-01-01T00:00:00Z
#-e 2009-02-28T23:59:59Z
#-x TRMM_3A12_007_snow,nlayer=0.5km
#-y TRMM_3B43_007_precipitation
#-f ./filesB8gUd.txt
#-o timeAvgDiffMap.TRMM_3A12_007_snow+TRMM_3B43_007_precipitation.20090101-20090228.103W_3N_65W_35N.nc
# g4_time_avg_diff_map.pl -b -103.3594,3.0234,-65.3906,35.3672 -s 2009-01-01T00:00:00Z -e 2009-02-28T23:59:59Z -x TRMM_3A12_007_snow,nlayer=0.5km -y TRMM_3B43_007_precipitation -f ./filesB8gUd.txt -o timeAvgDiffMap.TRMM_3A12_007_snow+TRMM_3B43_007_precipitation.20090101-20090228.103W_3N_65W_35N.nc

use vars qw($opt_b $opt_x $opt_y $opt_s $opt_e $opt_f $opt_o);
getopts('b:x:y:s:e:f:o:z:');

my $outdir = $opt_o ? dirname($opt_o) : '.';

# Derived parts from $outfile name
my $outfile_basename = "logger";                #basename($outfile);
my $logger           = Giovanni::Logger->new(
    session_dir       => $outdir,
    manifest_filename => $outfile_basename
);
my @field_args = ( $opt_x, $opt_y );

# Time Avg first:
# Cut input file in two
my @infiles = split_input_file( $opt_f, $outdir );

my @coords = split( /,/, $opt_b );
my @timeAveragedList;

# for now we have to hope that opt_x is first and opt_y is second
foreach my $filelist (@infiles) {
    my $zvar;
    my ( $mainvar, $zinfo ) = split( ',', shift @field_args );
    if ( $zinfo =~ /([\w\d-]+)=([\w\d-\.]+)/ ) {
        $zvar  = $1;
        $zinfo = $2;
    }

    # floating point representation of epoch times for ncra time subsetting:
    my %epoch_rep;
    $epoch_rep{timeDimName} = "time";
    $epoch_rep{start}       = string2epoch($opt_s) . ".0";
    $epoch_rep{end}         = string2epoch($opt_e) . ".0";

    my $time_subset
        = get_thisFilesInterpretationOfUsersTimeConstraints($filelist);

    my $outputfile = $filelist . ".timeavg.nc";
    my $rc = Giovanni::Algorithm::TimeAveragerNco::compute_time_average(
        $filelist, $outputfile, \@coords, $mainvar, $zvar, $zinfo, $time_subset );

    # make variables the same name:
    # using SLD called time_matched_difference:
    push @timeAveragedList, $outputfile;
}

# End TimeAvg
# Now I just have two files $timeAveragedList[0] and $timeAveragedList[1]
my @zvar;
my @zval;

#my @twoLists = split_input_file_to_arrays($opt_f);
# Start regridder stuff:
my @resolutions;
my ( $lat1res, $lon1res )
    = Giovanni::Data::NcFile::spatial_resolution( $timeAveragedList[0] );
push @resolutions, "($lat1res x $lon1res)";
my ( $lat2res, $lon2res )
    = Giovanni::Data::NcFile::spatial_resolution( $timeAveragedList[1] );
push @resolutions, "($lat2res x $lon2res)";

my $zoption = "";
if ( $opt_x =~ /,/ ) {
    $zoption .= $opt_x;
}
if ( $opt_y =~ /,/ ) {
    $zoption .= " " . $opt_y;
}

my $varinfo;    # only needs resolution for create_listfile
my $zselection;
my %hash;
my @vars;
@field_args = ( $opt_x, $opt_y );
foreach my $variable (@field_args) {
    my ( $mainvar, $zinfo ) = split( ',', $variable );
    if ( $zinfo =~ /([\w\d-]+)=([\d-\.]+)([\w]+)/ ) {
        $hash{$mainvar}{zname}      = $1;
        $hash{$mainvar}{zvalue}     = $2;
        $hash{$mainvar}{zunits}     = $3;
        $hash{$mainvar}{resolution} = shift @resolutions;
        $varinfo->{$mainvar}->{'resolution'}
            = $hash{$mainvar}{resolution};    # for create_listfile
        $zselection->{$mainvar} = { 'zvalue' => $hash{$mainvar}{zvalue} }

    }
    else {
        $logger->info( "did not find zlayer for " . $variable );
        $hash{$mainvar}{resolution} = shift @resolutions;
        $varinfo->{$mainvar}->{'resolution'}
            = $hash{$mainvar}{resolution};    # for create_listfile
    }
    push @vars, $mainvar;

}

my $listfile = Giovanni::Data::NcFile::create_listfile(
    $vars[0], [ $timeAveragedList[0] ], $vars[1], [ $timeAveragedList[1] ],
    $varinfo, $zselection
);
my $Bbox = Giovanni::BoundingBox->new( STRING => $opt_b );
my $padded_box = $Bbox->pad( $lat1res, $lat2res );
my @bbox = split( /, */, $padded_box->{STRING} );

my $regriddedList;
my $messages;
if ( $bbox[0] > $bbox[2] ) {
    ( $regriddedList, $messages )
        = Giovanni::Data::NcFile::run_and_stitch( $listfile, \@bbox, ".",
        $zoption, $vars[0], $vars[1], $logger );
}
else {
    ( $regriddedList, $messages )
        = Giovanni::Data::NcFile::run_regridder( $listfile, \@bbox, ".",
        $zoption, $logger );
}

# Create lineage
my ( $inputsObj, $regriddedListObj )
    = Giovanni::Data::NcFile::create_inputs_outputs(
    [ $regriddedList->[0] ],
    [ $regriddedList->[1] ],
    $regriddedList
    );
$logger->write_lineage(
    name          => "Regridding during Algorithm Step",
    inputs        => $inputsObj,
    regriddedList => $regriddedListObj,
    messages      => $messages
);

# End regridder stuff:

run_command( '', 'ncrename', '-v',
    "$vars[0],time_matched_difference",
    '-O', '-o', $regriddedList->[0], $regriddedList->[0] );
run_command( '', 'ncrename', '-v',
    "$vars[1],time_matched_difference",
    '-O', '-o', $regriddedList->[1], $regriddedList->[1] );

#my ($lon1,$dum)  = split(/\./,$bbox[0]);
#my $difffile = "diffed_" . $vars[0] . "_" . $vars[1] . "_" . $lon1 . ".nc";

run_command( 'Creating differenced file', 'ncdiff', $regriddedList->[0], $regriddedList->[1],
    $opt_o );

# We don't want to do this here because we need to do it after it is stiched together!!!
#$logger->info("running Giovanni::Data::NcFile::make_monotonic_longitude");
#Giovanni::Data::NcFile::make_monotonic_longitude($difffile, $opt_o, 1);
#$logger->info(`ncdump -v lon $opt_o`);

# pretty sure I don't need this now:
sub create_mapfile {
    my $variable = shift;
    my $filename = $variable . "_scale.map";
    if ( open FILE, "> $filename" ) {
        print FILE qq(PROCESSING "SCALE=0,3.78113135258e-05"\n");
        print FILE qq(PROCESSING "SCALE_BUCKETS=9");
        close FILE;
    }
    else {
        die "Could not create mapfile <$filename>\n";
    }
}

# Move these 4 out to a module
sub get_thisFilesInterpretationOfUsersTimeConstraints() {
    my $file               = shift;
    my $filesample         = getFirstFile($file);
    my @time_in_file_units = cf2units($filesample);
    my %fp_rep;
    $fp_rep{timeDimName} = "time";
    $fp_rep{start} = sprintf( "%12.1f", $time_in_file_units[0] );
    $fp_rep{start} =~ s/ //g;
    $fp_rep{end} = sprintf( "%12.1f", $time_in_file_units[1] );
    $fp_rep{end} =~ s/ //g;
    return \%fp_rep;
}

sub string2epoch {
    my @s = split( /[\-: TZ]/, $_[0] );

    # Perl 5.8.8 timegm() does not handle early dates well.
    # (Keep the numbers positive just for safety.)
    # However, it is faster, so we want to use it most of the time
    # TODO:  take this if loop out when we get to 5.12 or higher
    if ( $s[0] >= 1970 ) {
        return timegm( $s[5], $s[4], $s[3], $s[2], $s[1] - 1, $s[0] );
    }
    else {
        return Date::Manip::Date_SecsSince1970GMT( $s[1], $s[2], $s[0], $s[3],
            $s[4], $s[5] );
    }
}

sub getFirstFile {
    my $file = shift;
    if ( open FILE, $file ) {
        my $pair = <FILE>;
        my ( $afile, $dummy ) = split( /\s+/, $pair );
        return $afile;
    }
    else {
        warn "Could not get sample file from $file\n";
    }
}

sub cf2units {

    #my ($cfref, $ra_cftime, $temporal_resolution, $offset) = @_;
    my ($file) = shift;
    my $temporal_resolution;
    my $offset = 0;
    my $ra_cftime;
    my $cmd
        = qq(ncdump -h $file | grep time:units | awk -F\\" '{ print \$2}');
    my $cfref = `$cmd`;

    # Parse the "since" statement in the reference time
    my ( $units, $since ) = split( '\s+since\s+', $cfref );

    # Choose multiplier depending on time units
    my %units_per_sec = (
        'days'    => 86400,
        'hours'   => 3600,
        'minutes' => 60,
        'seconds' => 1
    );
    my $multiplier = $units_per_sec{$units};

    # Convert reference time to seconds
    my $since_epoch = string2epoch($since);
    my $start_sec   = string2epoch($opt_s);
    my $end_sec     = string2epoch($opt_e);
    my $start       = ( $start_sec - $since_epoch ) / $multiplier;
    my $end         = ( $end_sec - $since_epoch ) / $multiplier;
    return ( $start, $end );

    my @newtime;

    # For daily, we want to drop the time portion to start
    # at the beginning of the day
    if ( $temporal_resolution eq 'daily' ) {
        @newtime = map {
            int( ( $_ * $multiplier + $since_epoch ) / 86400 ) * 86400
                + $offset
        } @$ra_cftime;
    }
    else {
        $since_epoch += $offset;
        @newtime = map { $_ * $multiplier + $since_epoch } @$ra_cftime;
    }
    return @newtime;
}

sub add_lat_lon {
    my ( $file, $bbox ) = @_;
    my @bbox = split( /,\s*/, $bbox );

    # Add lat/lon to make xy plotter happy
    run_command( 'add lat dim', 'ncecat', '-O', '-u', 'lat', '-o', $file,
        $file );
    run_command( 'add lon dim', 'ncecat', '-O', '-u', 'lon', '-o', $file,
        $file );
    my $ncap2 = sprintf( 'lat[$lat]=%f; lon[$lon]=%f;', $bbox[1], $bbox[0] );
    run_command( 'add lat-lon vars',
        'ncap2', '-s', $ncap2, '-O', '-o', $file, $file );
    run_command( 'reorder dims', 'ncpdq', '-a', 'time,lat,lon', '-O', '-o',
        $file, $file );

}

sub split_input_file {
    my ( $file, $outdir ) = @_;
    my @outfiles;
    $outdir = '.' unless $outdir;
    foreach my $i ( 0 .. 1 ) {
        $outfiles[$i] = "$outdir/" . basename($file) . ".$i";

        #cat two.file.lists.cubes+list | awk '{print $2}'
        my $cmd = sprintf( "cat %s  | awk '{print \$%d}' > %s",
            $file, $i + 1, $outfiles[$i] );

#my $cmd = sprintf("cut --delimiter=' ' --field=%d %s > %s", $i+1, $file, $outfiles[$i]);
        run_command( "Preparing files for processing", $cmd );
    }
    return @outfiles;
}

sub split_input_file_to_arrays {
    my ($file) = @_;
    my @xvarfiles;
    my @yvarfiles;
    my @lists;
    if ( open FILE, "$file" ) {
        while (<FILE>) {
            chomp;
            if ( length > 1 ) {
                my ( $xvariablefile, $yvariablefile ) = split( /\s+/, $_, 2 );
                push @xvarfiles, $xvariablefile;
                push @yvarfiles, $yvariablefile;
            }
        }
        close FILE;
    }
    else {
        warn
            "Could not create arrays for input into regridder from file:<$file>\n";
        return;
    }
    push @lists, \@xvarfiles;
    push @lists, \@yvarfiles;

    return @lists;
}

sub createFileListForNCO {
    my $list     = shift;
    my $item     = shift;
    my $filename = "filelistForTimeAvgDiffMap" . $item . ".txt";
    if ( open FILE, "> $filename" ) {
        foreach my $file (@$list) {
            print FILE $file, "\n";
        }
        close FILE;
    }
    else {
        die
            "Could not create $filename. This is the file for input into ncdiff";
    }
    return $filename;
}

sub compute_area_average {
    my ( $infile, $outfile, $new_var ) = @_;
    run_command(
        "Averaging" . basename($infile),
        "ncap2 -O -o $outfile -s '*d2r=acos(-1.)/180.; coslat=cos(lat*d2r)' $infile"
    );
    run_command( 'Averaging',
        "ncwa -v $new_var -w coslat -a lat,lon -O -o $outfile $outfile" );
    run_command( 'Averaging', "ncks -x -v lat,lon -O -o $outfile $outfile" );
    return $outfile;
}

sub run_command {
    my ( $user_msg, @cmd ) = @_;

    # Log some info
    warn "USER_INFO $user_msg...\n" if $user_msg;
    my $cmd = join( ' ', @cmd );
    warn "INFO Running command $cmd\n";

    # Run it
    my $rc = system(@cmd);

    # Process return code (0 = success)
    if ($rc) {
        print STDERR "USER_ERROR Failed to execute $user_msg\n";
        my $exit_value = $rc >> 8;
        print STDERR "ERROR $cmd failed with exit code $exit_value\n";
        exit(2);
    }
    return 1;
}

sub subset_bbox_cmd {
    my ( $bbox, $file ) = @_;

    my @cmd = ( 'ncks', '-O' );
    return @cmd unless ($bbox);

    # Split the bounding box into its edges
    my $pattern = '([\d.+\-]+)';
    my ( $west, $south, $east, $north )
        = ( $bbox =~ /$pattern, *$pattern, *$pattern, *$pattern/ );

# If any of the lat/lon dimensions are smaller than file resolution, then collapse them to
# a single value so that ncks will return a result
    if ($file) {
        my ( $latres, $lonres )
            = Giovanni::Data::NcFile::spatial_resolution($file);
        my $delta_lat = $north - $south;
        if ( $delta_lat < $latres ) {
            $north = ( $north + $south ) / 2.;
            $south = $north;
            warn "INFO collapsing latitude to $north\n";
        }

        # Dateline handling examples
        # West = 170., East = -175.
        #    east360 = 185, delta_lon = 15
        # West = 170., East = 160. (Wraparound)
        #    east360 = 520, delta_lon = 350
        my $east360 = $east;
        $east360 += 360. if ( $west > $east );
        my $delta_lon = $east360 - $west;
        if ( $delta_lon < $lonres ) {
            $east = ( $east360 + $west ) / 2.;
            $east -= 360. if ( $east > 180. );
            $west = $east;
            warn "INFO collapsing longitude to $west\n";
        }
    }
    push @cmd, '-d', sprintf( "lat,%f,%f", $south, $north );
    push @cmd, '-d', sprintf( "lon,%f,%f", $west,  $east );
    return @cmd;
}
