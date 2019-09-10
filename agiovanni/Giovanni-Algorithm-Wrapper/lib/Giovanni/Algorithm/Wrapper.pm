package Giovanni::Algorithm::Wrapper;

use 5.008008;
use strict;
use warnings;
use File::Basename;
use File::Temp qw(tempfile);
use Cwd 'abs_path';
use List::MoreUtils qw(any);
use Time::Local;
use XML::LibXML;
use Giovanni::BoundingBox;
use Giovanni::Logger;
use Giovanni::Logger::InputOutput;
use Giovanni::Util;
use Giovanni::Data::NcFile;
use Giovanni::DataField;
use Giovanni::ScienceCommand;
use Giovanni::WorldLongitude;
use Giovanni::UnitsConversion;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'run' => [qw(run)] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'run'} } );

our @EXPORT = qw(run update_coordinates);

our $VERSION = '0.01';

our $numpat  = '\-*[\d\.]+';
our $pathpat = '([\/\w\.\-\+,]+)';

# Preloaded methods go here.

1;

# run() is supposed to run the whole thing from start to finish, so
# that the command-line code is just a driver.
sub run {
    my %args = @_;

    my ($session_dir)
        = extract_arg( '', 'session-dir', qr($pathpat), 0, %args );
    $session_dir ||= '.';

    # Set args{'output_type'} to something to avoid uninitialized variable
    # warnings
    $args{'output-type'} = 'ncfile'
        unless ( exists $args{'output-type'}
        && defined $args{'output-type'} );

    # Initialize logger
    my $logger = new Giovanni::Logger(
        session_dir       => $session_dir,
        manifest_filename => $args{'outfile'}
    );

    # Calculate the intersection bounding box to pass to the algorithm
    my @varfiles = split( ',', $args{'varfiles'} );
    my @data_fields
        = map { new Giovanni::DataField( MANIFEST => $_ ) } @varfiles;
    my $user_bbox = $args{'bbox'} ? $args{'bbox'} : "-180,-90,180,90";
    my $intersection_bbox
        = get_intersection_bbox( $logger, $user_bbox, @data_fields );
    $logger->debug("Intersection bounding box: $intersection_bbox");

    # Capture output netCDF file (computed by form_command) for the manifest
    my ( $west, $south, $east, $north )
        = Giovanni::Util::parse_bbox($intersection_bbox);

    my ( $ra_infiles, $outwest, $outeast, $outnc, $ra_cmd_args, $ra_log_input,
        $ra_lineage_extras );
    my @outnc_files;

    # Method of handling dateline:
    #   stitch:  algorithm calls algorithm twice and stitches the result back
    #            together
    if ( $west > $east
        && defined $args{'dateline'}
        && $args{'dateline'} eq 'stitch' )
    {
        my ( @east_files, @west_files );
        $args{'bbox'} = "$west,$south,180.,$north";
        ( $ra_infiles, $outwest, $ra_cmd_args, $ra_log_input,
            $ra_lineage_extras
        ) = execute_algorithm( \%args, $session_dir, $logger, 0, 49 );
        $args{'bbox'} = "-180.,$south,$east,$north";
        ( $ra_infiles, $outeast, $ra_cmd_args, $ra_log_input,
            $ra_lineage_extras
        ) = execute_algorithm( \%args, $session_dir, $logger, 49, 98 );

        # If the output file is a text list of output netCDF files,
        # read those files into an array.
        if ( $args{'output-type'} eq 'filelist' ) {
            @east_files = read_file_list($outeast);
            @west_files = read_file_list($outwest);
        }

        # ..otherwise, the file is the output netCDF itself
        else {
            @east_files = ($outeast);
            @west_files = ($outwest);
        }
        my $n_files = scalar(@east_files);
        my $west_string
            = sprintf( "%d%s", abs($west), ( $west > 0. ) ? 'E' : 'W' );

        # Stitch files in longitude direction using ncra
        foreach my $i ( 0 .. $n_files - 1 ) {
            $outeast = $east_files[$i];
            $outwest = $west_files[$i];
            $outnc   = $outeast;
            $outnc =~ s/\.180W/\.$west_string/;
            if ( Giovanni::Data::NcFile::stitch_lon(
                    1, $outwest, $outeast, $outnc
                )
                )
            {
                unlink( $outwest, $outeast );
            }
            push @outnc_files, $outnc;
        }
        $args{'bbox'} = $user_bbox;
    }

    # Otherwise, no stitching needed
    else {
        $args{'bbox'} = $intersection_bbox;
        ( $ra_infiles, $outnc, $ra_cmd_args, $ra_log_input,
            $ra_lineage_extras
        ) = execute_algorithm( \%args, $session_dir, $logger, 0, 98 );
        @outnc_files
            = ( exists( $args{'output-type'} )
                && defined $args{'output-type'}
                && ( $args{'output-type'} eq 'filelist' ) )
            ? read_file_list($outnc)
            : ($outnc);
        $args{'bbox'} = $user_bbox;
    }
    $outnc =abs_path($outnc);
    # Write output lineage
    my $log_output = new Giovanni::Logger::InputOutput(
        name  => 'file',
        value => $outnc,
        type  => 'FILE'
    );

    $logger->write_lineage(
        name    => $args{'name'},
        inputs  => $ra_log_input,
        outputs => [ $log_output, @$ra_lineage_extras ]
    );

    $args{'bbox'} = "-180.,-90.,180.,90."
        unless exists( $args{'bbox'} ) && defined $args{'bbox'};

    # 'filelist' indicates a multiplicity of files, so no point updating the
    # time range, or writing a title (which depends on the updated time range
    if ( exists( $args{'output-type'} )
        && defined $args{'output-type'}
        && $args{'output-type'} eq 'filelist' )
    {
        my $out_files = read_lineage_extras($outnc);
        $logger->write_lineage( name => $args{'name'}, 
                                inputs => $ra_log_input, 
                                outputs => [@$out_files] );
        return write_manifest( $args{'outfile'}, 
                               \@outnc_files,
                               $args{'variables'} );
    }
    else {
        $logger->write_lineage(name    => $args{'name'},
                               inputs  => $ra_log_input,
                               outputs => [ $log_output, @$ra_lineage_extras ]
        );
    }

    # Reach here only if output-type is not manifest
    # Save the sample files at each end for time range re-calc
    push( @{ $args{sample_infile} }, $ra_infiles->[0] );
    push( @{ $args{sample_infile} }, $ra_infiles->[-1] );

    # Write start and end times
    my ( $data_start, $data_end )
        = update_time_range( $outnc, $ra_infiles, $args{starttime},
        $args{endtime}, $args{comparison} );

    # Put data on a world longitude basis
    shift_longitudes( $outnc, $session_dir, $logger ) if ( $west > $east );

    # Update coordinates attribute
    update_coordinates($outnc);

    # Write output manifest (XML) file
    write_manifest( $args{'outfile'}, \@outnc_files );
    return $outnc;
}

# get the bounding box that is an intersection of all the data bounding boxes
# and the user's bounding box
sub get_intersection_bbox {
    my ( $logger, $bbox, @data_fields ) = @_;

    # corral all the boxes
    my @bboxes = ();
    push( @bboxes, Giovanni::BoundingBox->new( STRING => $bbox ) );
    for my $data_field (@data_fields) {
        my $west  = $data_field->get_west();
        my $south = $data_field->get_south();
        my $east  = $data_field->get_east();
        my $north = $data_field->get_north();
        push(
            @bboxes,
            Giovanni::BoundingBox->new(
                WEST  => $west,
                SOUTH => $south,
                EAST  => $east,
                NORTH => $north
                )
        );
    }

    # calculate the intersection
    my @intersections = Giovanni::BoundingBox::getIntersection(@bboxes);

    # check that we got back something reasonable
    if ( scalar(@intersections) == 0 ) {

        # NOTE: if the UI does its job, this should never happen.
        my $msg
            = "User bounding box, "
            . $bboxes[0]->getPrettyString()
            . ", does not intersect with data regions, ";
        my @strings
            = map( $_->getPrettyString(), @bboxes[ 1, scalar(@bboxes) - 1 ] );
        $msg = $msg . join( " and ", @strings ) . ".";
        $logger->error($msg);
        die($msg);
    }
    elsif ( scalar(@intersections) > 1 ) {

        #NOTE: if the UI does its job, this should never happen.
        my $msg
            = "User bounding box, "
            . $bboxes[0]->getPrettyString()
            . ", does not form a contiguous intersection with data regions, ";
        my @strings
            = map( $_->getPrettyString(), @bboxes[ 1, scalar(@bboxes) - 1 ] );
        $msg = $msg . join( " and ", @strings ) . ".";
        $logger->error($msg);
        die($msg);
    }

    # return the intersection.
    return $intersections[0]->getString();
}

sub shift_longitudes {
    my ( $infile, $session_dir, $logger ) = @_;
    my $inpath = ( $infile =~ m#^/# ) ? $infile : "$session_dir/$infile";
    warn "INFO shifting $inpath\n";
    my $outpath    = "$inpath.world";
    my $normalized = Giovanni::WorldLongitude::normalizeIfNeeded(
        sessionDir   => $session_dir,
        logger       => $logger,
        in           => [$inpath],
        out          => [$outpath],
        startPercent => 99,
        endPercent   => 100
    );
    if ($normalized) {
        rename( $outpath, $inpath )
            or quit( "Internal Error",
            "ERROR failed to name $outpath to $inpath\n", 2 );
        warn "INFO renamed $outpath to $inpath\n";
    }
}

sub read_file_list {
    my $file  = shift;
    my @lines = Giovanni::Util::readFile($file);
    my @files = map { split( /\s+/, $_ ) } @lines;
    return @files;
}

sub execute_algorithm {
    my ( $rh_args, $session_dir, $logger, $percent_start, $percent_end ) = @_;

    # Process arguments to form the command line
    my ( $ra_infiles, $infile, $outnc, $lineage_extras_file, $program,
        @cmd_args )
        = form_command( $rh_args, $logger );

    # Instantiate logger objects for each input file
    my @log_input = map {
        new Giovanni::Logger::InputOutput(
            name  => 'file',
            value => $_,
            type  => 'FILE'
            )
    } @$ra_infiles;

    # Run the command
    run_command( $rh_args->{'name'}, $session_dir, $logger, $percent_start,
        $percent_end, $program, @cmd_args );

    # Read lineage extras from the temp file
    my $ra_lineage_extras = read_lineage_extras($lineage_extras_file);

    # Delete temporary file with input files
    return ( $ra_infiles, $outnc, \@cmd_args, \@log_input,
        $ra_lineage_extras );
}

sub update_coordinates {
    my ( $ncfile, $reuse_hdr ) = @_;

    # Get all the plottable variables
    my @plottable = Giovanni::Data::NcFile::get_plottable_variables( $ncfile,
        $reuse_hdr );

    # Update the coordinates attribute based on the dimensions
    map {
        Giovanni::Data::NcFile::set_variable_coordinates( $ncfile, $ncfile, 1,
            $_ )
    } @plottable;
}

sub update_time_range {
    my ( $outfile, $filelist, $userstartdate, $userenddate, $iscomparison )
        = @_;

    my $start_time;
    my $end_time;
    if ($iscomparison) {

        # if this is a comparison, there should be 2 lists, one for each
        # variable.
        my $mid_index  = scalar( @{$filelist} ) / 2;
        my @startFiles = ( $filelist->[0], $filelist->[$mid_index] );
        my @endFiles   = (
            $filelist->[ $mid_index - 1 ],
            $filelist->[ scalar( @{$filelist} ) - 1 ]
        );

        # get the start and end times out of these files
        my @start_times;
        my @end_times;
        for ( my $i = 0; $i < scalar(@startFiles); $i++ ) {
            my ($att_hash)
                = Giovanni::Data::NcFile::global_attributes(
                $startFiles[$i] );
            push( @start_times, $att_hash->{start_time} );
            ($att_hash)
                = Giovanni::Data::NcFile::global_attributes( $endFiles[$i] );
            push( @end_times, $att_hash->{end_time} );
        }

        $start_time = Giovanni::Util::getEarliestTime(@start_times);
        $end_time   = Giovanni::Util::getLatestTime(@end_times);
    }
    else {

        # get the start time out of the first file
        my ($att_hash)
            = Giovanni::Data::NcFile::global_attributes( $filelist->[0] );
        $start_time = $att_hash->{start_time};

        ($att_hash)
            = Giovanni::Data::NcFile::global_attributes( $filelist->[-1] );
        $end_time = $att_hash->{end_time};
    }

    # Make array of attribute "actions"; default will be overwrite, which is fine
    my @attrs;
    $attrs[0] = new NcAttribute(
        name    => 'end_time',
        value   => $end_time,
        ncotype => 'c'
    );
    $attrs[1] = new NcAttribute(
        name    => 'start_time',
        value   => $start_time,
        ncotype => 'c'
    );
    push(
        @attrs,
        NcAttribute->new(
            name    => 'userstartdate',
            value   => $userstartdate,
            ncotype => 'c'
            )
    ) if $userstartdate;
    push(
        @attrs,
        NcAttribute->new(
            name    => 'userenddate',
            value   => $userenddate,
            ncotype => 'c'
            )
    ) if $userenddate;
    Giovanni::Data::NcFile::edit_netcdf_attributes( $outfile, $outfile,
        @attrs );
    return ( $start_time, $end_time );
}

# write_manifest - writes an output manifest file
# $varstring parameter is optional
sub write_manifest {
    my ( $output_xml, $ra_output_nc, $varstring ) = @_;

    my @output_nc = @$ra_output_nc;
    my (@vars);
    my $n_vars = 1;

    # Handle variables if specified

    if ($varstring) {
        @vars = split( /,\s*/, $varstring ) if ($varstring);
        $n_vars = scalar(@vars);
    }
    my $n_files = scalar(@output_nc) / $n_vars;

    # Check everything first so we don't output a bad manifest
    quit( "Internal error", "No output netCDF files in write_manifest", 1 )
        unless @output_nc;
    quit( "Internal error", "No output manifest file in args", 1 )
        unless $output_xml;

    # Print XML header and <manifest>
    my $mfst = '<?xml version="1.0" encoding="UTF-8"?>' . "\n<manifest>\n";
    foreach my $v ( 0 .. $n_vars - 1 ) {
        my $varid = '';
        $varid = " id=\"$vars[$v]\"" if defined($varstring);
        $mfst .= " <fileList$varid>\n";
        foreach my $f ( 0 .. $n_files - 1 ) {
            my $ncfile = $output_nc[ $n_vars * $f + $v ];
            quit( "Missing output file ",
                "Missing|empty output file $ncfile", 2 )
                unless ( -s $ncfile );
            $mfst .= "  <file>\n  " . abs_path($ncfile) . "\n  </file>\n";
        }
        $mfst .= " </fileList>\n";
    }

    $mfst .= "</manifest>\n";
    open( OUT, '>', $output_xml )
        or quit( "Internal error", "Cannot write to $output_xml: $!" );
    print OUT $mfst;
    close OUT;
    return $output_xml;
}

# Run the command and interpret the return code
sub run_command {
    my ( $name, $session_dir, $logger, $start_percent, $end_percent, @cmd )
        = @_;

    # If the "program" contains embedded args, then split them up so
    # we can use the slightly safer version of system() (array v. string)
    if ( $cmd[0] =~ / / ) {
        my @words = split( ' ', $cmd[0] );
        splice( @cmd, 0, 1, @words );
    }

    $logger->info( "Running command: " . join( ' ', @cmd ) );
    my $caller = Giovanni::ScienceCommand->new(
        sessionDir   => $session_dir,
        logger       => $logger,
        dieOnFailure => 0
    );
    my ( $dont_care1, $dont_care2, $return_value )
        = $caller->exec( \@cmd, $start_percent, $end_percent );

    $name ||= $cmd[0];
    if ( $return_value == 0 ) {
        $logger->info("Success running $name ($cmd[0])");
        $logger->user_msg("Successfully ran $name\n");
        return 1;
    }
    my $errmsg = sprintf(
        "exit=%d signal=%d core=%s",
        $return_value >> 8,
        $return_value & 127,
        ( $? & 128 ) ? 'y' : 'n'
    );
    $logger->error(
        sprintf( "failed to execute command %s: %s", $cmd[0], $errmsg ) );

    die "USER_ERROR failed to run $name\n";
}

# Form the command as an array so we can run the (slightly)
# safer version of system()
sub form_command {
    my $rh_args = shift;
    my $logger  = shift;
    my %args    = %$rh_args;

    # Patterns for checking arguments before use
    # Provides a little extra safety, even though taint is not used
    my $pathspat = '([\/\w\.\-\+, ]+)';
    my $datepat
        = '([12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]([T ][012][0-9]:[0-5][0-9]:[0-5][0-9]\.*[0-9]*Z*)?)';

    # Extract key parameters from arguments
    # Any failures on required arguments will terminate the program immediately
    my ($program) = extract_arg( '', 'program', qr($pathspat), 1, %args );
    my ($outputfileroot)
        = extract_arg( '', 'output-file-root', qr($pathpat), 0, %args );
    $outputfileroot = "output" unless $outputfileroot;
    my ($bbox)
        = extract_arg( '', 'bbox',
        qr(($numpat, *$numpat, *$numpat, *$numpat)),
        1, %args );
    $bbox =~ s/\s//g;
    my ($starttime) = extract_arg( '', 'starttime', qr($datepat), 1, %args );
    my ($endtime)   = extract_arg( '', 'endtime',   qr($datepat), 1, %args );
    my @cmd = ( '-b', $bbox, '-s', $starttime, '-e', $endtime );
    push @cmd,
        extract_arg( 'm', 'minimum-time-steps', qr(([0-9]+)), 0, %args );
    push @cmd, extract_arg( 'S', 'shapefile', qr($pathpat), 0, %args );
    my ($vars) = extract_arg( '', 'variables', qr($pathpat), 1, %args );

    # Group arg is of form TYPE=VALUE, e.g., MONTH=01
    my ($group) = extract_arg( '', 'group', qr(([\w=]+)), 0, %args );
    push( @cmd, '-g', $group ) if $group;

    my ($session_dir)
        = extract_arg( '', 'session-dir', qr($pathpat), 0, %args );
    $session_dir ||= '.';

    my $cleanup = ( exists $ENV{SAVEDIR} && $ENV{SAVEDIR} == 0 ) ? 0 : 1;
    my ( $in_fh, $infile ) = tempfile(
        'filesXXXXX',
        SUFFIX => '.txt',
        DIR    => $session_dir,
        UNLINK => $cleanup
    ) or quit( "Internal error", "Cannot get temporary file\n" );
    warn
        "INFO Printing list of input data files to $infile, cleanup=$cleanup\n";

    # For the comparison case, split the doublets on commas
    my ( $ra_infiles, @fields, $zString );
    my @vars = split( ',', $vars );
    if ( $args{'comparison'} ) {
        my @varfiles = split( ',', $args{'varfiles'} );
        my @zfiles   = split( ',', $args{'zfiles'} );

        # X is the reference file/variable/zslice
        my @zargs;
        my $i = 0;
        foreach my $arg ( '-x', '-y' ) {
            my $var = $vars[$i];
            ( $zargs[$i], $zString )
                = zdim_info( $zfiles[$i], $varfiles[$i] );
            $var .= ",$zargs[$i]" if ( $zargs[$i] );
            push @cmd, $arg, $var;

            # Construct field names from varname and z info
            my $field = $vars[$i];
            $field .= ".$zString" if $zString;
            push @fields, $field;
            $i++;
        }
        $rh_args->{'z-arg'} = \@zargs;

        # Match up by day parsed from filename
        # TODO:  read day from file, if not too expensive
        my $use_time;
        ( $ra_infiles, $use_time )
            = matched_file_list( $args{'inputfiles'}, $vars[0], $vars[1],
            $in_fh, $session_dir, 1, $logger );
    }

    # Single field case
    # Differences are:
    #   -v for variable instead of -x and -y
    #   -z Dim=ValUnits instead of -x var,Dim=ValUnits
    #   Single column of file pathnames
    else {
        push @cmd, '-v', $vars;
        my ( $zarg, $zString )
            = zdim_info( $args{'zfiles'}, $args{'varfiles'} );
        push( @cmd, '-z', $zarg ) if ($zarg);
        $rh_args->{'z-arg'} = $zarg;
        $ra_infiles = simple_input_file( $args{'inputfiles'}, $in_fh );

        # Construct field names from varname and z info
        $fields[0] = $vars;
        $fields[0] .= ".$zString" if ($zString);
    }
    warn "ERROR cannot find $infile\n" unless ( -f $infile );
    push @cmd, '-f', $infile;

    # Add units conversion arguments if specified
    my @units_args
        = convert_units( $args{units}, \@vars, $ra_infiles, $infile,
        $session_dir, $logger )
        if $args{units};
    push( @cmd, @units_args ) if @units_args;

    # Trap this output filename for return as well as arg
    my $outfile
        = output_netcdf_filename( $outputfileroot, join( '+', @fields ),
        $bbox, $starttime, $endtime, $group );
    $outfile =~ s/\.nc/.txt/
        if ( exists( $rh_args->{'output-type'} )
        && defined $rh_args->{'output-type'}
        && $rh_args->{'output-type'} eq 'filelist' );
    push @cmd, '-o', $outfile;

    # Lineage extras is a temporary file that the algorithm
    # writes to.
    my ( $unusued, $lineage_extras_file ) = tempfile(
        'lineage_extras_XXXXX',
        SUFFIX => '.txt',
        DIR    => $session_dir,
        UNLINK => $cleanup,
    ) or quit( "Internal error", "Cannot open get temporary file\n" );

    push @cmd, '-l', $lineage_extras_file;

    # Area averaging nthreads arg:
    push @cmd, '-j', $rh_args->{'jobs'} if ( exists( $rh_args->{'jobs'} ) );

    return ( $ra_infiles, $infile, $outfile, $lineage_extras_file, $program,
        @cmd );
}

# Read line-separated-values file of extra files to insert into the lineage.
# Algorithm was given this tempfile, which it may have not used.
sub read_lineage_extras {
    my ($lineage_extras_file) = @_;
    my @lineage_extras = ();

    if ( -e $lineage_extras_file ) {
        open( LINEAGE_EXTRAS, $lineage_extras_file );

        foreach my $line (<LINEAGE_EXTRAS>) {
            chomp($line);
            $line = abs_path($line);
            next unless $line;

            push(
                @lineage_extras,
                new Giovanni::Logger::InputOutput(
                    name  => 'file',
                    value => $line,
                    type  => 'FILE'
                    )
            );
        }

        close(LINEAGE_EXTRAS);
    }

    return \@lineage_extras;
}

# Construct output filename
sub output_netcdf_filename {
    my ( $root, $vars, $bbox, $starttime, $endtime, $group ) = @_;

    # Integerize box vals and convert +/- to N/S and E/W
    my ( $west, $south, $east, $north ) = split( ', *', $bbox );
    ( $west, $east )
        = map { sprintf( "%d%s", abs($_), ( $_ > 0. ) ? 'E' : 'W' ) }
        ( $west, $east );
    ( $south, $north )
        = map { sprintf( "%d%s", abs($_), ( $_ > 0. ) ? 'N' : 'S' ) }
        ( $south, $north );

    # Just keep the numbers for conciseness
    ( $starttime, $endtime )
        = map { substr( $_, 0, 4 ) . substr( $_, 5, 2 ) . substr( $_, 8, 2 ) }
        ( $starttime, $endtime );

    # Change group TYPE=VALUE to .TYPE_VALUE for filename
    my $group_str = $group ? ".$group" : '';
    $group_str =~ s/=/_/;

    # root.var1+var2.YYYYMMDD-YYYYMMDD.[GROUP.]W_S_E_N.nc
    return sprintf(
        "%s.%s_%s_%s_%s.nc",
        "$root.$vars.$starttime-$endtime$group_str",
        $west, $south, $east, $north
    );
}

sub zdim_info {
    my ( $zfile, $varfile ) = @_;

    my $zValue = get_zValue($zfile);
    return if ( $zValue eq 'NA' );

    # Get Z dimension info from the variable (field) info file
    my ( $zDimName, $zDimUnits ) = get_zDim($varfile);
    my $arg = "$zDimName=$zValue$zDimUnits";
    return ( $arg, "$zValue$zDimUnits" );
}

# simple_input_file($in, $out) - single column file with input data files
sub simple_input_file {
    my ( $infile, $fh ) = @_;

    # Read the input manifest XML file
    use XML::LibXML;
    my $xmlParser = XML::LibXML->new();
    my $doc       = $xmlParser->parse_file($infile);
    die "ERROR: no input file found in args" unless ($doc);

    my @infiles = map( $_->getValue(), $doc->findnodes(qq|//file/text()|) );

    foreach my $infile (@infiles) {
        print $fh "$infile\n";
    }
    return ( \@infiles );

}

# extract_arg($short_arg, $argname, $pat, $required, %args)
#   $short_arg = the single character of the argument to be fed
#                eventually to the algorithm code
#   $argname = the corresponding long argument name fed into the
#              wrapper, used to look up in %args hash
#   $pat = pattern for extracting info, as if tainted
#   $required = whether to quit if we don't get our arg
#   %args = hash of arguments and values from the command line
sub extract_arg {
    my ( $short_arg, $argname, $pat, $required, %args ) = @_;

    # See if we have the argument at all, and if required, then quit.
    unless ( exists $args{$argname}
        && defined( $args{$argname} )
        && $args{$argname} ne '' )
    {
        if ($required) {
            warn("USER_ERROR Internal error\n");
            die( "ERROR No $argname specified in Giovanni::Algorithm::Wrapper\n"
            );
        }
        else {
            return;
        }
    }

    # Extract argument value
    my ($value) = ( $args{$argname} =~ $pat );
    if ( !defined($value) ) {
        warn("USER_ERROR Internal error\n");
        die( "ERROR Cannot parse valid $argname specified in Giovanni::Algorithm::Wrapper\n"
        );
    }

    # Return ready to use pair of short argument (e.g., -s) and argument value
    # Can be called without the short argument to get just the value
    return ( $short_arg ? ( '-' . $short_arg, $value ) : $value );
}

# get_zValue - extract Z value from the Z slice XML file
sub get_zValue {
    my $path = shift;
    my $string = read_file($path) or return undef;

    # Extremely simple pattern, so we use pattern matching instead of
    # XML node processing or XPATH
    return "NA" if ( $string =~ /<data .*zValue="NA"/ );

    #  <manifest><data zValue="850">AIRX3STD_006_Temperature_A</data></manifest>
    my ($zval) = ( $string =~ /<data .*zValue="([\-\.\d]+)"/ );
    return $zval;
}

# get_zDim - get Z dimension info from the data field info XML file
sub get_zDim {
    my ( $path, $var ) = @_;
    my $string = read_file($path) or return undef;

    # Simple pattern, so we use pattern matching instead of
    # XML node processing or XPATH
    my ($zDimUnits) = ( $string =~ /<var .* zDimUnits="(\S+)" / );
    my ($zDimName)  = ( $string =~ /<var .* zDimName="(\S+)" / );
    return ( $zDimName, $zDimUnits );
}

# read_file() - simple utility to read file contents into a single string
sub read_file {
    my $path = shift;
    quit( "Internal error", "No path specified for read_file()" )
        unless $path;
    if ( !open( IN, $path ) ) {
        warn("ERROR failed to read $path: $!\n");
        return undef;
    }
    my @lines;
    while (<IN>) {
        push @lines, $_;
    }
    my $string = join( '', @lines );
    close IN;
    return $string;
}

# matched_file_list($infile, $var_x, $var_y, $match_filehandle, $session_dir, $min_sample_size)
#   $infile:  input XML file with input netCDF files, in two fileLists
#   $var_x:  name of the X variable
#   $var_y:  name of the Y variable
#   $match_file: output file handle for matched pairs
#   $session_dir:  directory in which this is all happening
#   $min_sample_size: if lower than this, quit
sub matched_file_list {
    my ( $infile, $var_x, $var_y, $fh, $session_dir, $min_sample_size,
        $logger )
        = @_;
    $min_sample_size = 1 unless $min_sample_size;

    # Comma in $infile string indicates two input manifests (as in regrid station)
    $infile = combine_manifests( $infile, $session_dir )
        if ( $infile =~ /,/ );

    # Cribbed most of this from Giovanni::Correlation::Wrapper
    # Parse the XML file for the variables
    my $use_time = 0;
    my $i_var    = -1;
    my %paths;
    my ( %datatimes1, %datatimes2 );
    my @infiles;
    my $parser = XML::LibXML->new();
    my $xml    = $parser->parse_file($infile);
    my @variable_ids    #This is the data variable identifier
        = map( $_->getValue(), $xml->findnodes("/manifest/fileList/\@id") );

    #This is the valid "datatime" attribute, which is used to determine if files should be compared

    for my $variable_id (@variable_ids) {

        # Figure out if x is the first or second variable
        # i.e., they need not be in order. In theory.
        if ( $variable_id eq $var_x ) {
            $i_var = 0;
        }
        elsif ( $variable_id eq $var_y ) {
            $i_var = 1;
        }
        else {
            quit(
                "Do not recognize variable info from input file",
                "Unrecognized variable $variable_id, does not match X ($var_x) or Y ($var_y)"
            );
        }

        # Parse <file> nodes from $fileList
        my @paths = map( $_->nodeValue(),
            $xml->findnodes(
                qq|/manifest/fileList[\@id="$variable_id"]/file/text()| ) );
        my @datatimes = map( $_->getValue(),
            $xml->findnodes(
                qq|/manifest/fileList[\@id="$variable_id"]/file/\@datatime| )
        );

        for ( my $i = 0; $i <= $#paths; ++$i ) {

            push @infiles, $paths[$i];
            my $file = basename( $paths[$i] );

            # Parse (as strictly as possible with regex) for date
            # ie.  Y   Y    Y     Y    M   M    D    D  T   H    H    M    M    S    S
            my ($date)
                = ( $file
                    =~ /\.([12][90][0-9][0-9][01][0-9][0-3][0-9]T*[012]*[0-9]*[012]*[0-9]*[012]*[0-9]*)\./
                );
            quit( "Cannot parse date from input filename", $file )
                unless $date;

            # Fix up date to make it more consistent: take out T and pad out to HHMMSS
            $date =~ s/T//;
            $date = substr( $date . ( '0' x 14 ), 0, 14 );

            # If more than YYYYMMDD, then we need to use time in our output filenames
            # Therefore, pass this back for future use by output_netcdf_filename
            $use_time = 1 if ( length($date) > 8 );

            if ( $i_var == 0 ) {
                $paths{qq($datatimes[$i])}{'path1'} = $paths[$i];
            }
            elsif ( $i_var == 1 ) {
                $paths{qq($datatimes[$i])}{'path2'} = $paths[$i];
            }
            else {
                quit( "Too many variables in file", $infile );
            }

        }
    }

    # Write to plain text file with filename pairs
    my $n_files = 0;
    foreach my $key ( sort keys %paths ) {
        if ( exists $paths{$key}{'path1'} and exists $paths{$key}{'path2'} ) {

            #         if ( scalar $paths{$key} == 2) {
            warn "Paths is: $paths{$key}{'path1'} $paths{$key}{'path2'}\n";
            printf $fh "$paths{$key}{'path1'} $paths{$key}{'path2'}\n";
            $n_files++;
        }
    }
    close $fh;

    # Some comparisons require a minimum number to be sensible
    if ( $n_files < $min_sample_size ) {

        $logger->user_error(
            "Only $n_files pairs of files with matching times found, must have at least $min_sample_size for comparison"
        );
        print STDERR
            "USER_ERROR Only $n_files pairs of matching files found, must have at least $min_sample_size for comparison\n";
        quit(
            "Only $n_files pairs of matching files found, must have at least $min_sample_size for comparison"
        );
    }
    else {
        warn "INFO found $n_files pairs of files for comparison\n";
    }
    return ( \@infiles, $use_time );
}

sub combine_manifests {
    my ( $infile, $outdir ) = @_;
    my @files = split( ',', $infile );
    my ( $fh, $outfile ) = tempfile(
        'mfst.combined_XXXXX',
        SUFFIX => '.xml',
        DIR    => $outdir,
        UNLINK => 0
    );
    my ( $file_string1, $file_string2 ) = map { read_file($_) } @files;
    $file_string2 =~ s/<xml.*?>//;
    $file_string1 =~ s#</manifest>##;
    print $fh $file_string1;
    print $fh $file_string2;
    close $fh;
    return $outfile;
}

sub quit {
    my ( $user_msg, $details, $exit_code ) = @_;

    # Error for the users
    warn("USER_ERROR Algorithm wrapper error: $user_msg\n");

    # Error for developers
    my $errmsg = "ERROR $user_msg";
    $errmsg .= ": $details" if $details;
    warn("$errmsg\n");
    exit( $exit_code || 1 );
}

# Units conversion support
sub convert_units {
    my ( $units_arg, $ra_vars, $ra_infiles, $infile, $outdir, $logger ) = @_;

    # The different flavors of --units:
    #   One variable, no time dep:  --units destunits,units_cfg
    #   One variable, time dep:  --units destunits,units_cfg,WRAPPER
    #   Two variables, no time dep:  --units destunits1,destunits2,units_cfg
    #   Two variables, time dep:  --units destunits1,destunits2,units_cfg,WRAPPER
    my @args       = split( ',', $units_arg );
    my @vars       = @$ra_vars;
    my @dest_units = map { shift @args } ( 0 .. $#vars );
    my $units_cfg  = shift @args;
    my $where      = shift @args;

    # Strip the where hint, no longer needed
    $units_arg = join( ',', @dest_units, $units_cfg );

    # If doing conversion in the ALGORITHM, return
    return ( '-u', $units_arg ) if ( $where ne 'WRAPPER' );

    # Doing conversion in the wrapper...
    my @cvt = setup_units_converters( $units_arg, join( ',', @vars ),
        $ra_infiles );
    my $nfiles = scalar(@$ra_infiles) / scalar(@vars);
    my ( $i, $j );
    for ( $i = 0; $i < scalar(@$ra_vars); $i++ ) {
        next unless $cvt[$i];
        for ( $j = 0; $j < $nfiles; $j++ ) {
            my $k       = $i * $nfiles + $j;
            my $newfile = $outdir . '/uc.' . basename( $ra_infiles->[$k] );
            $logger->user_msg( "Converting units in file "
                    . ( $j + 1 )
                    . " of $nfiles for variable "
                    . $ra_vars->[$i]
                    . "." );
            $cvt[$i]->ncConvert(
                sourceFile      => $ra_infiles->[$k],
                destinationFile => $newfile
            );
            $ra_infiles->[$k] = $newfile;
        }
    }

    # Pave over the input file with the new data file names
    open( OUT, '>', $infile ) or die "ERROR Cannot write to $infile: $!\n";
    for ( $j = 0; $j < $nfiles; $j++ ) {
        my @files;
        for ( $i = 0; $i < scalar(@$ra_vars); $i++ ) {
            my $k = $i * $nfiles + $j;
            push @files, $ra_infiles->[$k];
        }
        print OUT join( ' ', @files ) . "\n";
    }
    close OUT or die "ERROR closing $infile: $!\n";

    # Conversion is done, so don't return a -u arg for the algorithm
    return;
}

# setup_units_converters() sets up one or two (for comparison)
# units converter objects for each variable
# Its main tasks are to
# (1) Parse the units_string from "units,[units,]units_cfg_file into its parts
# (2) Get one (or two) sample files to get source units from
# (3) Call units_converter() for each variable
sub setup_units_converters {
    my ( $units_string, $vars, $ra_files ) = @_;

    # Split comma-separated lists into arrays
    my @vars       = split( ',', $vars );
    my $nvars      = scalar(@vars);
    my @dest_units = split( ',', $units_string );
    my $units_cfg  = pop(@dest_units);

    # Get sample input files for each var to get source units
    my @infiles = ( $ra_files->[0] );

    # Comparison case
    push( @infiles, $ra_files->[-1] ) if ( $nvars > 1 );

    # Get a converter for each destination units
    my @cvt = map {
        units_converter( $vars[$_], $infiles[$_], $dest_units[$_],
            $units_cfg )
    } ( 0 .. $#vars );
    return @cvt;
}

# units_converter() gets the source units from a sample file, then calls
# Giovanni::UnitsConversion to get a converter, which it returns
# If no conversion is necessary (source = dest units) it returns 0
# If something goes wrong, it dies :-(
sub units_converter {
    my ( $var, $ncfile, $dest_units, $units_cfg ) = @_;

    # Blank units means don't convert
    return 0 unless ($dest_units);

    # Get source units
    my ( $rh_atthash, $ra_attlist )
        = Giovanni::Data::NcFile::get_variable_attributes( $ncfile, 0, $var );
    my $source_units = $rh_atthash->{units};
    die("ERROR: no units attribute for variable $var in file $ncfile\n")
        unless ($source_units);

    # Get variable type
    my $variable_type
        = Giovanni::Data::NcFile::get_variable_type( $ncfile, 1, $var );

    # Return an integer value if not necessary
    return 0 if ( $source_units eq $dest_units );

    # Create a converter object
    my $converter = Giovanni::UnitsConversion->new( config => $units_cfg );
    $converter->addConversion(
        sourceUnits      => $source_units,
        destinationUnits => $dest_units,
        variable         => $var,
        type             => $variable_type
    );
    die( "ERROR could not create units converter with config file $units_cfg\n"
    ) unless $converter;
    return $converter;
}
__END__

=head1 NAME

Giovanni::Algorithm::Wrapper - Wrapper for scientist-provided algorithms in Giovanni

=head1 SYNOPSIS

  use Giovanni::Algorithm::Wrapper;

  For the single-variable case:

  $rc = Giovanni::Algorithm::Wrapper::run(
    'name' => name,
    'program' => program,
    'inputfiles' => "mfst_file",
    'bbox' => westsoutheastnorth,
    'output-file-root' => output_file_root,
    'outfile' => output_manifest,
    'zfiles' => zfile,
    'varfiles' => varfile,
    'variables' => variable_name,
    'starttime' => starttime,
    'endtime' => endtime,
    'dateline' => ("stitch"),
    'units' => units,config_file,[WRAPPER|ALGORITHM],
    'minimum-time-steps' => mintimesteps,
  );
    'bbox' => westsoutheastnorth,
    'output-file-root' => output_file_root,
    'output-type' => ('filelist'|'ncfile'),
    'outfile' => output_manifest,
    'zfiles' => "x-zfile,y-zfile",
    'varfiles' => varfiles,
    'variables' => "xvar,yvar",
    'starttime' => starttime,
    'endtime' => endtime,
    'dateline' => ("stitch"),
    'units' => "destunits,destunits,config-file,[WRAPPER|ALGORITHM]"
    'minimum-time-steps' => mintimesteps,

  @converters = setup_units_converters ( $units_string, $vars, $ra_files ) 

=head1 DESCRIPTION

Giovanni::Algorithm::Wrapper::run() runs a contributed algorithm in Giovanni4,
insulating the algorithm from the vicissitudes of G4 design and evolution.

It works for both single-variable algorithms and two-variable comparisons.
In the latter case, it treats the 'x' variable as a reference variable.
The comparison value is an actual word meant to be used in the output long_name
and plot titling. These will be constructed using the input long_names, as
<variable y> <comparison> <variable x>, e.g.,
"TRMM Version 7 rainfall minus TRMM Version 6 rainfall".
Likewise, a linear regression would be:
"TRMM Version 7 rainfall regressed against TRMM Version 6 rainfall"

=head2 Units Conversion

Wrapper also handles units conversion. If the last argument in the input "units" arg
is WRAPPER, the wrapper will pre-convert the units of the input files.
If it is blank or is ALGORITHM, it will pass the argument through as a "-u",
after first stripping off the ALGORITHM "hint".

A utility is also provided for algorithms to do units conversion in medias res, where needed.
This can be used for either one variable or two (the comparison case).

  @converters = setup_units_converters ( $units_string, $vars, $ra_files ) 

The units_string is the "destunits,destunits,config-file" argument contents.
It returns a list of 1 or 2 converter objects. In cases where conversion is not
necessary (same source and destination units), the value returned is '0'.
Calling algorithms should check to see that ref($converter) is true before
calling the ncConvert() method in Giovanni::UnitsConversion.

=head1 AUTHOR

Chris Lynnes, NASA/GSFC

=cut

