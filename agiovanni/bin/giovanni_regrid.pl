#!/usr/bin/perl -w

=head1 Name 

giovanni_regrid.pl

=head1 DESCRIPTION

giovanni_regrid.pl is a wrapper calling regridding algorithm (regrid_lats4d.pl)

=head1 SYNOPSIS

scienceCommandWrapper.pl --inputfilelist <stagefile1.xml,stagefile2.xml> --bbox <bbox> --debug [0|1] --zfile <zfile.xml> --datafield-info-file <varInfo1.xml,varInfo2.xml> --outfile <output-mfst-file>

Sample stage_data_file.xml:
<fileList id="MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean">
  <file>/var/temp/scrubbed.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101.nc</file>
  <file>/var/temp/scrubbed.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030102.nc</file>
</fileList>

=head1 AUTHOR

Jianfu Pan

Date Created: 2013-07-09

=cut

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use XML::LibXML;
use Giovanni::ScienceCommand;
use Giovanni::Data::NcFile;
use Giovanni::Logger;
use Giovanni::Util;

my $stepname = "Regridding";

#
# Command line options
#

my ( $stagefile, $bbox, $outfile, $varinfo_file, $starttime, $endtime );
my $debug = 0;
my $zfile = undef;

GetOptions(
    'inputfilelist=s'       => \$stagefile,
    'bbox=s'                => \$bbox,
    'outfile=s'             => \$outfile,
    'zfile=s'               => \$zfile,
    'datafield-info-file=s' => \$varinfo_file,
    's=s'                   => \$starttime,
    'e=s'                   => \$endtime,
    'debug=i'               => \$debug
);

# Check for required options
die "ERROR Required outfile missing\n" unless $outfile;

# Looking for two stage files
$stagefile =~ s/\s//g;
my ( $stagefile1, $stagefile2 ) = split( ',', $stagefile, 2 );
die "ERROR Stage file #1 missing or empty ($stagefile1 in $stagefile)\n"
    unless -s $stagefile1;
die "ERROR Stage file #2 missing or empty ($stagefile2 in $stagefile)\n"
    unless -s $stagefile2;

# Looking for two varinfo files
$varinfo_file =~ s/\s//g;
my ( $varinfo_file1, $varinfo_file2 ) = split( ',', $varinfo_file, 2 );
die
    "ERROR The varinfo files missing or empty (looking for $varinfo_file1 and $varinfo_file2 in $varinfo_file\n"
    unless -s $varinfo_file1 and -s $varinfo_file2;

# Looking for two z files
# ASSUMING z files always used even for 2D
$zfile =~ s/\s//g;
my ( $zfile1, $zfile2 ) = split( ',', $zfile, 2 );
die
    "ERROR z-files missing or empty (looking for $zfile1 and $zfile2 in $zfile\n"
    unless -s $zfile1 and -s $zfile2;

# checking the start/end time specified
die "ERROR the starting/ending time must be specified\n"
    unless ( defined $starttime and defined $endtime );

# Derived parts from $outfile name
my $outdir           = dirname($outfile);
my $outfile_basename = basename($outfile);
my $logger           = Giovanni::Logger->new(
    session_dir       => $outdir,
    manifest_filename => $outfile_basename
);
$logger->info("StageFile: $stagefile");

#
# Parse stage file
#

my ( $vname1, $files1, $datatime1 ) = parse_stage_file($stagefile1);
my ( $vname2, $files2, $datatime2 ) = parse_stage_file($stagefile2);

## to crop the date time range
my ($timedfiles1)
    = Giovanni::Util::cropRecordsByTime( $files1, $starttime, $endtime );
## to crop the date time range
my ($timedfiles2)
    = Giovanni::Util::cropRecordsByTime( $files2, $starttime, $endtime );

#
# Parse varinfo file
# varinfo : { vname => {'resolution', 'zname', 'zunits'} }
#

my $varinfo = {};
$varinfo = parse_varinfo( $varinfo_file1, $varinfo );
$varinfo = parse_varinfo( $varinfo_file2, $varinfo );
die "ERROR var info missing for $vname1\n"
    unless exists( $varinfo->{$vname1} );
die "ERROR var info missing for $vname2\n"
    unless exists( $varinfo->{$vname2} );

#
# Extract z-selection
#

# Extract from zfile for {'vname' => {'zvalue' => <zvalue>}}
my $zselection = {};
$zselection = parse_zfile( $zfile1, $zselection ) if defined($zfile1);
$zselection = parse_zfile( $zfile2, $zselection ) if defined($zfile2);

#
# Construct an input list file for regrid algorithm
# The list file contains list of data files to be processed by the algorithm
#

my $listfile
    = create_listfile( $vname1, $timedfiles1, $vname2, $timedfiles2, $varinfo,
    $zselection );
die "ERROR Fail to create list file $listfile\n" unless -s $listfile;

#
# Call ScienceCommand.pm
#

# --- Construct z-option ---
my $zoption = "";
if ( exists( $zselection->{$vname1} ) ) {
    my $zname1  = $varinfo->{$vname1}->{'zname'};
    my $zunits1 = $varinfo->{$vname1}->{'zunits'};
    my $zvalue1 = $zselection->{$vname1}->{'zvalue'};
    $zoption .= "-x $vname1,$zname1=$zvalue1$zunits1"
        unless $zvalue1 =~ /^na$/i;
}
if (    exists( $zselection->{$vname2} )
    and exists( $varinfo->{$vname2}->{'zname'} ) )
{
    my $zname2  = $varinfo->{$vname2}->{'zname'};
    my $zunits2 = $varinfo->{$vname2}->{'zunits'};
    my $zvalue2 = $zselection->{$vname2}->{'zvalue'};
    $zoption .= " -y $vname1,$zname2=$zvalue2$zunits2"
        unless $zvalue2 =~ /^na$/;
}

my ( $outputs, $messages );
my @bbox = split( /, */, $bbox );
if ( $bbox[0] > $bbox[2] ) {
    ( $outputs, $messages )
        = run_and_stitch( $listfile, \@bbox, $outdir, $zoption, $vname1,
        $vname2, $logger );
}
else {
    ( $outputs, $messages )
        = run_regridder( $listfile, \@bbox, $outdir, $zoption, $logger );
}

$logger->error("No output file found") if scalar(@$outputs) < 1;

my $rc = create_outfile( $vname1, $vname2, $outfile, $outputs, $datatime1,
    $datatime2 );
$logger->info("Created the regrid manifest file: $outfile");

# Create lineage
my ( $inputsObj, $outputsObj )
    = create_inputs_outputs( $files1, $files2, $outputs );
$logger->write_lineage(
    name     => $stepname,
    inputs   => $inputsObj,
    outputs  => $outputsObj,
    messages => $messages
);

exit(0);

sub run_regridder {
    my ( $listfile, $ra_bbox, $outdir, $zoption, $logger ) = @_;

    # Reassemble bounding box into one string
    my $bbox = join( ',', @$ra_bbox );

    # Form science command
    my $scienceAlgorithm
        = "regrid_lats4d.pl -f $listfile -b $bbox -o $outdir $zoption";
    print STDERR "INFO science algorithm: $scienceAlgorithm \n";
    $logger->info("ScienceAlgorithm: $scienceAlgorithm");

    # Call science command
    my $scienceCommand = Giovanni::ScienceCommand->new(
        sessionDir => $outdir,
        logger     => $logger
    );
    my ( $outputs, $messages ) = $scienceCommand->exec($scienceAlgorithm);
    return ( $outputs, $messages );
}

sub rename_tiles {
    my ( $ra_files, $suffix ) = @_;

    my $n = scalar(@$ra_files);

    # Rename data files so they don't get clobbered
    for my $f ( 0 .. $n - 1 ) {
        next unless ( basename( $ra_files->[$f] ) =~ /^regrid/ );
        my $newfile = "$ra_files->[$f]" . $suffix;
        rename $ra_files->[$f], $newfile
            or die "Failed to rename $ra_files->[$f] to $newfile";
        $ra_files->[$f] = $newfile;
    }
}

# Removes lon_bnds from east and west (in turn) so that
# lon_bnds(lon,nv) lon dependency will allow newlon to replace
# lon in stitch_longitudes()
sub remove_lon_bnds_dependency {
    my @files = @_;
    foreach my $file (@files) {

        if ( $file !~ /scrubbed/ )
        {    # don't want to remove this var from scrubbed file
            if (Giovanni::Data::NcFile::does_variable_exist(
                    undef, 'lon_bnds', $file
                )
                )
            {
                run_command(
                    'ncks', '-O', '-o', $file,
                    '-C',   '-x', '-v', 'lon_bnds',
                    $file
                );
            }
        }
    }
}

sub run_and_stitch {
    my ( $listfile, $ra_bbox, $outdir, $zoption, $vname1, $vname2, $logger )
        = @_;

    # Regrid data to the west of the dateline
    my @westbox = @$ra_bbox;
    $westbox[2] = 180.;
    my ( $outwest, $msgwest )
        = run_regridder( $listfile, \@westbox, $outdir, $zoption, $logger );
    rename_tiles( $outwest, ".west" );
    my @outwest = @$outwest;
    remove_lon_bnds_dependency(@outwest);

    # Regrid data to the east of the dateline
    my @eastbox = @$ra_bbox;
    $eastbox[0] = -180.;
    my ( $outeast, $msgeast )
        = run_regridder( $listfile, \@eastbox, $outdir, $zoption, $logger );
    my @outputs = @$outeast;
    rename_tiles( $outeast, ".east" );
    my @outeast = @$outeast;
    remove_lon_bnds_dependency(@outeast);

    # Loop through files, stitching together west and east
    my $n = scalar(@outeast);
    my @regrid_outeast = grep /\.east$/, @outeast;

    if ( scalar(@regrid_outeast) > 0 ) {

        # only stitch files together if we actually regridded something

        # Make a single (reusable) blank one to put in the middle
        my $blank_nc = make_blank_nc( $regrid_outeast[0], $ra_bbox->[0] );

        # Stitch the sandwiches together along longitude
        foreach my $i ( 0 .. $n - 1 ) {
            next unless ( basename( $outwest[$i] ) =~ /^regrid/ );
            my $rc = stitch_longitudes( $outputs[$i], $outeast[$i], $blank_nc,
                $outwest[$i] );
            unless ($rc) {
                warn "USER_ERROR Internal error\n";
                die
                    "ERROR stitching $outwest[$i] $outeast[$i] into $outputs[$i]\n";
            }
        }
    }
    my @msg = ( @$msgwest, @$msgeast );
    return ( \@outputs, \@msg );
}

sub create_inputs_outputs {
    my ( $files1, $files2, $outfiles ) = @_;

    # Create input file objects (one for each file)
    my $inputs = [];
    foreach my $f ( @$files1, @$files2 ) {
        my $in = Giovanni::Logger::InputOutput->new(
            name  => "file",
            value => $f,
            type  => "FILE"
        );
        push( @$inputs, $in );
    }

    # Create output file objects (one for each file)
    my $outputs = [];
    foreach my $f (@$outfiles) {
        my $out = Giovanni::Logger::InputOutput->new(
            name  => "file",
            value => $f,
            type  => "FILE"
        );
        push( @$outputs, $out );
    }

    return ( $inputs, $outputs );
}

sub create_outfile {
    my ( $vname1, $vname2, $outfile, $files, $datatime1, $datatime2 ) = @_;

    # The output from regridder is a single list of files for both variables
    # and contains a datatime attribute that is used for comparison services.
    # We'll need to separate them out into two lists, based on vname
    # ASSUMPTION:  The second field in file name is variable name
    # LIMITATION:  This does not address the case when two vnames are the
    #              same (but for different level, for example)
    my $file_string1 = "";
    my $file_string2 = "";
    my $d_base       = "";
    my $i            = 0;
    my $j            = 0;
    foreach my $f (@$files) {

        my $f_base = basename($f);
        my ( $file_prefix, $vname, $rest ) = split( '\.', $f_base, 3 );
        if ( $vname eq $vname1 ) {
            my $d1 = @$datatime1[$i];
            $d_base = "datatime=" . "\"$d1\"";
            $file_string1 .= "<file $d_base>$f</file>\n";
        }
        elsif ( $vname eq $vname2 ) {

            my $d2 = @$datatime2[$j];
            $d_base = "datatime=" . "\"$d2\"";
            $file_string2 .= "<file $d_base>$f</file>\n";
            $j++;
        }
        else {
            die("ERROR unrecognized file $f ($vname1, $vname2)\n");
        }
        $i++;

    }

    #$i++;
    open( OUT, ">$outfile" ) || die;
    print OUT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print OUT "<manifest>\n";
    print OUT "<fileList id=\"$vname1\">\n";
    print OUT $file_string1;
    print OUT "</fileList>\n";
    print OUT "<fileList id=\"$vname2\">\n";
    print OUT $file_string2;
    print OUT "</fileList>\n";
    print OUT "</manifest>\n";
    close(OUT);
}

sub parse_resolution {
    my $res_str = shift;

    # Two possible forms:  1 deg. or 2.0 x 2.5 deg
    my @resolution = split( ' x ', $res_str );
    my ($rlat) = ( $resolution[0] =~ /([\d\.]+)/ );
    my ($rlon)
        = ( scalar(@resolution) > 1 )
        ? ( $resolution[1] =~ /([\d\.]+)/ )
        : ($rlat);
    return ( $rlat, $rlon );
}

sub create_listfile {
    my ( $vname1, $files1, $vname2, $files2, $varinfo, $zselection ) = @_;
    my $reso1 = $varinfo->{$vname1}->{'resolution'};
    my $reso2 = $varinfo->{$vname2}->{'resolution'};

    # Determine which resolution to regrid to
    my ( $gridReference1, $gridReference2 ) = ( "", "" );

    my ( $rlat1, $rlon1 )
        = parse_resolution( $varinfo->{$vname1}->{'resolution'} );
    my ( $rlat2, $rlon2 )
        = parse_resolution( $varinfo->{$vname2}->{'resolution'} );
    if ( $rlat1 > $rlat2 or $rlon1 > $rlon2 ) {
        $gridReference1 = "gridReference=\"true\"";
        warn "USER_MSG regridding to resolution of $vname1\n";
    }
    else {
        $gridReference2 = "gridReference=\"true\"";
        warn "USER_MSG regridding to resolution of $vname2\n";
    }

    my $dataFileList1 = "";
    foreach my $f (@$files1) {
        $dataFileList1 .= "<dataFile>$f</dataFile>\n";
    }
    my $dataFileList2 = "";
    foreach my $f (@$files2) {
        $dataFileList2 .= "<dataFile>$f</dataFile>\n";
    }
    my $listfile_content = <<EOF;
<data>
<dataFileList id="$vname1" $gridReference1 resolution="$reso1" sdsName="$vname1">
$dataFileList1
</dataFileList>
<dataFileList id="$vname2" $gridReference2 resolution="$reso2" sdsName="$vname2">
$dataFileList2
</dataFileList>
</data>
EOF

    my $listfile = "in_regrid.$$.xml";
    open( FH, ">$listfile" ) || die;
    print FH "$listfile_content";
    close(FH);

    return $listfile;
}

# parse_stage_file()
sub parse_stage_file {
    my ($stagefile) = @_;

    my @files     = ();
    my @datatimes = ();

    my $parser          = XML::LibXML->new();
    my $xml             = $parser->parse_file($stagefile);
    my ($fileList_node) = $xml->findnodes('/manifest/fileList');
    if ( !$fileList_node ) {
        print "WARN fileList node not found in $stagefile\n";
        return ();
    }

    my $vname = $fileList_node->getAttribute('id');
    if ( !$vname ) {
        print "WARN fileList doesn't contain an id $stagefile\n";
        return ();
    }

    my @file_nodes = $fileList_node->findnodes('file');
    foreach my $fn (@file_nodes) {
        my $fpath = $fn->textContent();
        my $datat = $fn->getAttribute('datatime');
        $fpath =~ s/^\s+|\s+$//g;
        push( @files, $fpath ) if $fpath ne "";
        push( @datatimes, $datat );
    }

    return ( $vname, \@files, \@datatimes );

}

sub parse_varinfo {
    my ( $varinfo_file, $varinfo ) = @_;

    my $parser    = XML::LibXML->new();
    my $xml       = $parser->parse_file($varinfo_file);
    my @var_nodes = $xml->findnodes('/varList/var');
    foreach my $n (@var_nodes) {
        my $id         = $n->getAttribute('id');
        my $zname      = $n->getAttribute('zDimName');
        my $zunits     = $n->getAttribute('zDimUnits');
        my $resolution = $n->getAttribute('resolution');
        if ( !$id ) {
            print STDERR "WARN The id for variable is missing\n";
            next;
        }
        $varinfo->{$id} = { 'resolution' => $resolution };
        next unless $zname;
        $varinfo->{$id}->{'zname'} = $zname;
        $varinfo->{$id}->{'zunits'} = $zunits if $zunits;
    }

    return $varinfo;
}

sub parse_zfile {
    my ( $zfile, $zselection ) = @_;

    # Make sure zfile is not empty
    if ( !-s $zfile ) {
        print STDERR "WARN z-file $zfile empty\n";
        return {};
    }

    # Parse zfile
    my $parser     = XML::LibXML->new();
    my $xml        = $parser->parse_file($zfile);
    my @data_nodes = $xml->findnodes('/manifest/data');

    foreach my $n (@data_nodes) {
        my $zvalue = $n->getAttribute('zValue');
        my $vname  = $n->textContent();
        $vname =~ s/^\s+|\s+$//mg;
        $zselection->{$vname} = { 'zvalue' => $zvalue }
            if $zvalue and $zvalue !~ /^NA$/i;
    }

    return $zselection;
}

# Stitch together netCDF files by longitude, assuming they are adjacent
# This is used for splitting up calculations on either side of 180 deg, and then
# putting them back together in one file.
# TO DO:  Move this to Giovanni::Data::NcFile, and deprecate stitch_lon.
sub stitch_longitudes {
    my ( $outfile, @infiles ) = @_;

    warn "INFO stitching " . join( ', ', @infiles ) . "\n";

    # Get the first plottable variable, assuming they all have the same dims
    my @vars
        = Giovanni::Data::NcFile::get_plottable_variables( $infiles[0], 0 );

    # Get dimensions based on the variable shape (not coordinates attribute)
    my $coordinates
        = Giovanni::Data::NcFile::get_variable_dimensions( $infiles[0], 1,
        $vars[0] );
    unless ($coordinates) {
        warn
            "ERROR cannot obtain dimension shape for plottable variable $vars[0]\n";
        return 0;
    }
    my $lon_first = $coordinates;
    $lon_first =~ s/\W(lon\w*)\W*//;
    my $lon_dim = $1;
    $lon_first = $lon_dim . ' ' . $lon_first;
    $lon_first =~ s/ +/,/g;

    # Permute lat/lon to make them record dimensions
    foreach my $file (@infiles) {

        # Swap dimensions in order to make longitude a record variable
        run_command("ncpdq -a $lon_first -O -o $file $file");

        # Make longitude a record variable
        run_command("ncks --mk_rec_dmn $lon_dim -O -o $file $file");
    }

    # Cat the files together with ncrcat
    run_command( 'ncrcat', '-O', '-o', $outfile, @infiles );

    # Swap latitude and longitude back
    $coordinates =~ s/ +/,/g;
    run_command("ncpdq -a $coordinates -O -o $outfile $outfile");
    return 1;
}

sub run_command {
    my (@cmd) = @_;
    my $cmd = join( ' ', @cmd );
    warn "INFO Executing command: $cmd\n";
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

# Construct a "blank" file (_FillValue) of same latitude range is
# incoming, and longitudes extending to some specified western bound
# This will be the middle of an ncrcat sandwich to put two segments
# straddling the dateline on a -180 to 180 grid.
sub make_blank_nc {
    my ( $east_nc, $west_end ) = @_;
    my @vars = Giovanni::Data::NcFile::get_plottable_variables( $east_nc, 0 );
    my ( $zdim, $z_attr )
        = Giovanni::Data::NcFile::get_vertical_dim_var( $east_nc, 1,
        $vars[0] );
    $zdim = '$' . $zdim . ',' if $zdim;
    my $nco = "$east_nc.nco";
    open NCO, '>', $nco or die "ERROR cannot write to $nco\n";

    # Compute resolution from last two points
    print NCO '*res = lon(-1)-lon(-2); ';

    # Western edge of input file is start
    print NCO '*start = lon(-1) + res; ';
    printf NCO '*n = int((%f - start) / res); ', $west_end;
    print NCO "\n";

    # Define a newlon dimension for the extension
    print NCO 'defdim("newlon", n); ';
    print NCO 'newlon[$newlon] = array(start,res,$newlon); ';
    print NCO "\n";

    # Fill variables with _FillValues
    foreach my $var (@vars) {
        printf NCO 'newval[$time,%s$lat,$newlon]=%s.get_miss(); ', $zdim,
            $var;
        printf NCO 'newval.set_miss(%s.get_miss()); ', $var;
        printf NCO '%s=newval;',                       $var;
        print NCO "\n";
    }
    close NCO;
    my $blank_nc = $east_nc;
    $blank_nc =~ s/\.east/.blank/;
    run_command( 'ncap2', '-O', '-o', $blank_nc, '-S', $nco, $east_nc )
        or die "ERROR could not create blank file\n";

   # change the 'coordinates' attribute for each data variable to remove 'lon'
    my $changeBackHash = {};
    for my $var (@vars) {
        my ($attHash)
            = Giovanni::Data::NcFile::get_variable_attributes( $blank_nc, 0,
            $var );

        # see if the coordinates have 'lon' in them
        if ( has_lon_coordinate( $attHash->{coordinates} ) ) {
            my $newcoordinates = $attHash->{coordinates};
            $newcoordinates =~ s/lon/newlon/;
            my $option = "coordinates,$var,o,c,$newcoordinates";
            run_command( 'ncatted', '-O', '-o', $blank_nc, '-a', $option,
                $blank_nc )
                or die
                "ERROR could not update coordinates for $var in $blank_nc";
            $changeBackHash->{$var} = $attHash->{coordinates};
        }

    }

    # Delete the existing 'lon' variable
    remove_lon_bnds_dependency( ($blank_nc) );
    run_command( 'ncks', '-O', '-o', $blank_nc, '-C', '-x', '-v', 'lon',
        $blank_nc );

    # Rename newlon to lon
    run_command(
        'ncrename', '-O',         '-o', $blank_nc,
        '-d',       'newlon,lon', '-v', 'newlon,lon',
        $blank_nc
    ) or die "ERROR could not rename newlon to lon\n";

    # change any coordinates variables that need to be changed
    for my $var ( keys( %{$changeBackHash} ) ) {
        my $option = "coordinates,$var,o,c," . $changeBackHash->{$var};
        run_command( 'ncatted', '-O', '-o', $blank_nc, '-a', $option,
            $blank_nc )
            or die
            "ERROR could not change coordinates back for $var in $blank_nc";
    }

    return $blank_nc;
}

sub has_lon_coordinate {
    my ($coordinates) = @_;
    my @coords = split( ' ', $coordinates );
    for my $coord (@coords) {
        if ( $coord eq 'lon' ) {
            return 1;
        }
    }
    return 0;
}
