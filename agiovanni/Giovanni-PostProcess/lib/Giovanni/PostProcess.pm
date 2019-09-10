
package Giovanni::PostProcess;

use strict;
use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use File::Copy qw(copy);
use List::MoreUtils qw(any);
use JSON;
use Scalar::Util qw(looks_like_number);
use Giovanni::Algorithm::Wrapper;
use Giovanni::BoundingBox;
use Giovanni::Data::NcFile;
use Giovanni::DataField;
use Giovanni::Logger;
use Giovanni::ScienceCommand;
use Giovanni::UnitsConversion;
use Giovanni::Util;
use Giovanni::Visualizer::Hints;

# Runs the post-process procedure. Returns an exit code for the procedure.
# Accepts an args hash. See also giovanni_postprocess.pl.
# Required args:
#   bbox                   bounding box as values seperated by comma
#   comparison             in-fix operator between variables for title (eg "vs"
#                          to write title as "X vs Y")
#   endtime                user-selected end time
#   group                  seasonal service info, in GroupType=GroupVal format
#   infile                 path to input manifest file (from algorithm)
#   name                   service label
#   outfile                path to output manifest file
#   service                name of service
#   session-dir            path to session directory
#   shapefile              identifier for shape use (unset for none)
#   starttime              user-selected start time
#   time-axis              whether the input data has a time axis (unset for false)
#   units                  ref to array of dest units, same order as variables. last
#                          element is the units config file
#   varfiles               path to variable manifest files
#   variables              list of variables separated by commas
#   zfiles                 path to zslice manifest files
sub run {
    my %args = @_;

    validate_args(%args);

    # Set up objects that will be used for the duration of the procedure
    my $logger = new Giovanni::Logger(
        session_dir       => $args{'session-dir'},
        manifest_filename => $args{'outfile'}
    );
    $logger->user_msg("Post-processing algorithm output");

    my @ncInputs = get_algorithm_outputs( $args{'infile'} );
    my @ncOutputs = map { dirname($_) . "/g4." . basename($_) } @ncInputs;

    # Check whether units conversion is necessary, and execute the
    # conversion if so.
    my @unitConvertTasks = get_unit_convert_tasks( \@ncInputs, \%args );

    if (@unitConvertTasks) {
        $logger->user_msg("Converting units...");
        execute_unit_convert_tasks( \@ncInputs, \@ncOutputs,
            \@unitConvertTasks, \%args, $logger );
    }
    else {

        # Copy input files to output files
        my %ncRenames = map { $ncInputs[$_] => $ncOutputs[$_] }
            0 .. scalar @ncInputs - 1;

        for my $ncInput ( keys %ncRenames ) {
            copy( $ncInput, $ncRenames{$ncInput} );
        }
    }

    # Apply plot hints to each input file
    my $nfiles = scalar @ncInputs;

    for my $i ( 0 .. $nfiles - 1 ) {
        apply_plot_hints( $ncInputs[0], $ncOutputs[0], \%args, $logger );
    }

    # Write Manifest and lineage
    write_manifest( \@ncOutputs, \%args );
    write_lineage( \@ncInputs, \@ncOutputs, $logger );

    return 0;
}

# Plot Hints / TimeTics step-- analyze the data and insert attributes into the
# NetCDF file that determine labels and style information for the next step, the
# visualizer.
sub apply_plot_hints {
    my ( $ncInput, $ncOutput, $rh_args, $logger ) = @_;

    my %args     = %$rh_args;
    my @vars     = split( ',', $args{'variables'} );
    my @varfiles = split( ',', $args{'varfiles'} );

    my ( $data_start, $data_end ) = get_time_range($ncInput);
    my @data_fields
        = map { new Giovanni::DataField( MANIFEST => $_ ) } @varfiles;

    my @vartitles = write_title(
        $args{'session-dir'}, $logger,
        98,                   100,
        $ncOutput,            $data_start,
        $data_end,            \@vars,
        \@data_fields,        %args
    );

    if ( $args{'time-axis'} ) {

        # Add time tics if it is a time series
        my $isClim = any { $_->isClimatology } @data_fields;

        Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis( $ncOutput,
            is_climatology => $isClim );

        # Add time bounds
        # Now trying to skip this costly process:
        if (!Giovanni::Data::NcFile::does_variable_exist( undef, "time_bnds", $ncOutput)) {
            my $time_bnds = Giovanni::Data::NcFile::get_time_bounds($ncOutput)
               or die "Can't get time info from $ncOutput for time_bnds";
            Giovanni::Data::NcFile::set_time_bounds( $ncOutput, $time_bnds );
        }
    }

    # Add caption
    add_captions( $ncOutput, $data_start, $data_end, \@data_fields,
        \@vartitles, %args );
}

sub get_unit_convert_tasks {
    my ( $ra_ncInputs, $rh_args ) = @_;
    my %args = %$rh_args;

    unless ( exists $args{units}
        && defined $args{units}
        && length $args{units} > 0 )
    {
        return ();
    }

    my %varInfo = Giovanni::Util::getNetcdfDataVariables( $ra_ncInputs->[0] );
    my @tasks;

    my @vars      = split( ',', $args{variables} );
    my @destUnits = split( ',', $args{units} );
    pop(@destUnits);    # remove units config file

    # Read out the data field info files
    my @varfiles = split( ',', $args{'varfiles'} );
    my @data_fields
        = map { new Giovanni::DataField( MANIFEST => $_ ) } @varfiles;

    if ( scalar @vars != scalar @destUnits ) {
        my $nvars  = scalar @vars;
        my $nunits = scalar @destUnits;
        print STDERR "Unequal numbers of variables ($nvars) and destination ";
        print STDERR "units ($nunits)\n";
        exit(1);
    }

    for my $i ( 0 .. scalar @vars - 1 ) {
        my $var           = $vars[$i];
        my $originalUnits = $data_fields[$i]{attributes}{dataFieldUnitsValue};
        my $destUnits     = $destUnits[$i];

        # Figure out the variable name from the variable name at the
        # command line.
        for my $testVar ( keys(%varInfo) ) {
            if ( index( $testVar, $var ) >= 0 ) {

                # Add task if units are not equal to target
                if (   $destUnits
                    && $destUnits ne 'NA'
                    && $varInfo{$testVar}{units} ne $destUnits
                    && $varInfo{$testVar}{units} eq $originalUnits )
                {

                    push(
                        @tasks,
                        {   variable         => $testVar,
                            sourceUnits      => $varInfo{$testVar}{units},
                            destinationUnits => $destUnits,
                            type             => $varInfo{$testVar}{type}
                        }
                    );
                }

            }

        }

    }

    return @tasks;
}

# Dies upon failure
sub execute_unit_convert_tasks {
    my ( $ra_ncInputs, $ra_ncOutputs, $ra_tasks, $rh_args, $logger ) = @_;
    my @tasks = @$ra_tasks;
    my %args  = %$rh_args;

    my @units = split( ',', $args{units} );
    my $unitsConfig = pop(@units);

    my $convert = Giovanni::UnitsConversion->new(
        config => $unitsConfig,
        logger => $logger,
    );

    # Add conversion tasks to the Units Converter
    $convert->addConversion(%$_) for @tasks;

    # Apply conversion tasks to each file
    my $nfiles = scalar @$ra_ncInputs;

    for my $i ( 0 .. $nfiles - 1 ) {
        $convert->ncConvert(
            sourceFile      => $ra_ncInputs->[$i],
            destinationFile => $ra_ncOutputs->[$i]
        ) or die "Units conversion failed";
    }
}

sub get_algorithm_outputs {
    my ($mfstPath) = @_;
    my $mfstRead = Giovanni::Util::getDataFilesFromManifest($mfstPath);
    return @{ $mfstRead->{data} };
}

# Get start_time and end_time from global NC attributes
sub get_time_range {
    my ($ncFile) = @_;
    my %attribs = Giovanni::Util::getNetcdfGlobalAttributes($ncFile);

    return ( $attribs{start_time}, $attribs{end_time} );
}

sub write_title {
    my ($session_dir,    $logger,     $start_percent, $end_percent,
        $ncfile,         $data_start, $data_end,      $ra_vars,
        $ra_data_fields, %args
    ) = @_;

    my ( $title, $plot_title, $plot_subtitle );

    my @vars        = @$ra_vars;
    my @data_fields = @$ra_data_fields;
    my @vartitles;

    parse_zfiles( \%args );

    # Format temporal constraints, taking into account the temporal
    # resolution of the input data
    my $is_climatology = any { $_->isClimatology } @data_fields;
    my $temporal_res = $data_fields[0]->get_dataProductTimeInterval;

    my $data_start_fmt = Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING    => $data_start,
        INTERVAL       => $temporal_res,
        IS_START       => 1,
        IS_CLIMATOLOGY => $is_climatology,
        GROUP          => $args{group}
    );
    my $data_end_fmt = Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING    => $data_end,
        INTERVAL       => $temporal_res,
        IS_START       => 0,
        IS_CLIMATOLOGY => $is_climatology,
        GROUP          => $args{group}
    );

    # Format spatial constraints
    my $constraints
        = ( $data_start_fmt eq $data_end_fmt )
        ? "$data_start_fmt"
        : "$data_start_fmt - $data_end_fmt";

    if ( $args{'shapefile'} ) {
        $constraints .= ", Shape " . get_shape_name( $args{'shapefile'} );
    }

    if ( $args{'bbox'} ) {
        my $user_bbox = Giovanni::BoundingBox->new( STRING => $args{'bbox'} );
        my @data_bbox = map { get_data_bbox($_) } @data_fields;
        my @intersectBox = getAllBboxesIntersection( $user_bbox, @data_bbox );
        my $bbox_str = $intersectBox[0]->getPrettyString();
        $constraints .= ", Region $bbox_str";
    }

    # Format variables
    my ( @var_desc, @add_zslice, @add_plot_axis_hints, @add_legend );

    # Single variable case
    if ( scalar(@vars) == 1 ) {
        my ( $dim, $zVal, $units );
        if ( $args{'z-arg'}->[0] ) {
            ( $dim, $zVal, $units ) = parse_zdim_info( $args{'z-arg'}->[0] );
            push( @add_zslice, '-a', "z_slice,$vars[0]*,o,c,$zVal$units" );

            # Copied logic from Jianfu's areaAveragerNco.pl
            # DONE:  Generalized
            # This exact same code is in correlation_wrapper.pl
            my $z_slice_type = $units;
            if ( $units eq 'hPa' ) {
                $z_slice_type = 'pressure';
            }
            elsif ( $units eq 'km' ) {
                $z_slice_type = 'altitude';
            }

            push( @add_zslice,
                '-a', "z_slice_type,$vars[0]*,o,c,$z_slice_type" );
        }
        $vartitles[0]
            = get_var_title( $data_fields[0], $zVal, $ncfile, $vars[0],
            $args{service}, $args{group} );

        if ( $args{group} ) {
            if ( $args{service} eq 'QuCl' ) {
                $constraints = get_QuCl_subtitle_contraint( \%args ) . " "
                    . $constraints;
            }
            $plot_title
                = get_seasonal_title( \%args, \@data_fields, $data_start_fmt,
                $data_end_fmt );
            $plot_subtitle = "Average $vartitles[0] for $constraints";
        }
        elsif ( $args{service} eq 'MpAn' ) {
            $plot_title    = $vartitles[0];
            $plot_subtitle = " ";
        }
        else {
            $plot_title    = $args{'name'} . ' of ' . $vartitles[0];
            $plot_subtitle = "over $constraints";
        }

        $title = "$plot_title $plot_subtitle";

        # Add plot_hint_legend_label only for interannual time series
        if ( $args{service} eq 'InTs' ) {
            my $legend_label = get_legend_label( \%args );
            push( @add_legend,
                '-a', "plot_hint_legend_label,$vars[0],o,c,$legend_label" );
        }
    }

    #Comparison case
    else {

        # Get the Z value in preparation
        my @zVal;

        for my $zarg ( @{ $args{'z-arg'} } ) {
            my ( $dim, $val, $units ) = parse_zdim_info($zarg);
            push( @zVal, $val && $val ne 'NA' ? $val : undef );
        }

        # Form strings for plot hints
        for my $i ( 0 .. 1 ) {
            push(
                @vartitles,
                get_var_title(
                    $data_fields[$i], $zVal[$i],      $ncfile,
                    $vars[$i],        $args{service}, $args{group}
                )
            );
        }

        $plot_title = "$args{'name'} over $constraints";
        my $scatter = ( $args{name} =~ /scatter/i );

        # TODO:  Ewwww....NCL needs ~C~ as newline...move to visualizer!
        my $newline
            = ( exists $args{'time-axis'} && $args{'time-axis'} && !$scatter )
            ? '~C~'
            : "\n";
        $plot_subtitle
            = "$vartitles[1] $args{'comparison'}$newline$vartitles[0]";
        my $long_name = "$vartitles[1] $args{'comparison'} $vartitles[0]";
        my @plottable
            = Giovanni::Data::NcFile::get_plottable_variables( $ncfile, 0 );

        # TODO:  remove logic specific to scatterplots
        if ( scalar(@plottable) ) {
            if ($scatter) {
                @plottable = sort @plottable;

                # This assumes scatter plot has variable names 'x_' and 'y_'
                # Basically, there is no reliable way to rebuild .nc variable
                # names from the  @vars array (since Algorithms are free to
                # rename the variables as they pleased, and the order of the
                # variables in the .nc file (@plottable) is not necessary the
                # same as the order of @vars. So, instead, lets make sure
                # @plottable are names as expexted (x_XXX y_YYY) and are in
                # the correct order (x_ first, y_ second), and assume the
                # order of variables in the sorted @plottable is the same as
                # in @vars.
                if (!(     substr( $plottable[0], 0, 2 ) eq 'x_'
                        && substr( $plottable[1], 0, 2 ) eq 'y_'
                    )
                    )
                {
                    $logger->error(
                        "Could not find x_ and y_ variables in while post-processing scatter plot file\n"
                    );
                    $logger->user_error(
                        "Unable to generate a proper scatter plot file\n");
                    die "Failed in PostProcess to add plot hints\n";
                }
                @var_desc = map {
                    (   '-a',
                        "plot_hint_axis_title,"
                            . $plottable[$_]
                            . ",o,c,$vartitles[$_]"
                        )
                } ( 0, 1 );
                $plot_title    = $args{name};
                $plot_subtitle = $constraints;
            }
            else {
                @var_desc
                    = ( '-a', "long_name,$plottable[0],o,c,$long_name" );
                my $legend = "$vars[1] $args{'comparison'}$newline$vars[0]";
                push( @add_legend,
                    '-a',
                    "plot_hint_legend_label,$plottable[0],o,c,$legend" );

            }
        }
        $title = "$plot_title of $long_name";
    }


    # Reformat plot title/subtitle for time axes
    if ( exists $args{'time-axis'} && $args{'time-axis'} ) {
         ( $plot_title, $plot_subtitle ) = wrap_titles($title);
    }
 
    # Apply plot hints as global attributes
    # Also, delete valid_range if present
    run_command(
        "ncatted",                                      $session_dir,
        $logger,                                        $start_percent,
        $end_percent,                                   'ncatted',
        '-h',                                           '-a',
        "title,global,o,c,$title",                      '-a',
        "plot_hint_title,global,o,c,$plot_title",       '-a',
        "plot_hint_subtitle,global,o,c,$plot_subtitle", '-a',
        "valid_range,,d,,",                             @var_desc,
        @add_legend,                                    @add_zslice,
        "-O",                                           '-o',
        $ncfile,                                        $ncfile
    );

    # Add axis labels
    if ( $args{service} eq 'ArAvTs' ) {
        add_time_series_axis_labels( \%args, $ncfile );
    }
    elsif ( $args{service} eq 'VtPf' ) {
        add_vert_prof_axis_labels( \%args, $ncfile );
    }

    return @vartitles;
}

sub get_shape_name() {
    my ($shapefile_id) = @_;
    my ( $shapefile, $shape ) = split( '/', $shapefile_id );

    # Read the shapefile info file from the provisioned shapefile directory
    my $prov_dir
        = qx/giovanni_config.pl -n '\$GIOVANNI::SHAPEFILES{provisioned_dir}\'/;
    my $json_contents = '';

    open( SF_INFO, "$prov_dir/$shapefile.json" );
    while (<SF_INFO>) {
        $json_contents .= $_;
    }
    close(SF_INFO);

    # Extract the name of the file using the bestAttr value in the info file.
    my $info         = JSON->new()->decode($json_contents);
    my $bestAttr_idx = $info->{bestAttr}[1];
    my $name         = $info->{shapes}{$shape}{values}[$bestAttr_idx];

    return $name;
}

# Note:  cloned and modified from Giovanni::Visualizer::Hints
# TO DO: Make this callable
sub getAllBboxesIntersection {
    my ( $user_bbox, @data_bboxes ) = @_;

    my @intersect = ($user_bbox);
    for my $bbox (@data_bboxes) {
        my @resultBBox = ();
        for my $intersectBBox (@intersect) {
            push(
                @resultBBox,
                Giovanni::BoundingBox::getIntersection(
                    $bbox, $intersectBBox
                )
            );
        }
        @intersect = @resultBBox;
    }
    return @intersect;
}

sub parse_zdim_info {
    my $string = shift;
    unless ($string) {
        warn "WARN no string passed to parse_zdim_info";
        return;
    }
    my ( $dim, $val, $units ) = ( $string =~ /(.*?)=([\d\.\-_]+)(.*)/ );
    $val =~ s/_/\./;
    return ( $dim, $val, $units );
}

# Wrapper around Giovanni::Visualizer::Hints::createDataFieldString which calls
# it with the correct arguments.
sub get_var_title {
    my ( $df, $zValue, $ncfile, $varid, $service, $group ) = @_;

    my %args = (
        LONG_NAME           => $df->get_long_name,
        TIME_RESOLUTION     => $df->get_dataProductTimeInterval,
        PRODUCT_SHORTNAME   => $df->get_dataProductShortName,
        SPATIAL_RESOLUTION  => $df->get_resolution,
        UNITS               => $df->get_dataFieldUnitsValue,
        PLATFORM_INSTRUMENT => $df->get_dataProductPlatformInstrument,
        VERSION             => $df->get_dataProductVersion,
        GROUP               => $group
    );

    if ( defined($zValue) && $zValue ne 'NA' ) {
        $args{THIRD_DIM_UNITS} = $df->get_zDimUnits;
        $args{THIRD_DIM_VALUE} = $zValue;
    }

    # Allow overriding of data field information with NetCDF attributes when
    # called with a $ncfile argument.
    if ($ncfile) {
        my ( $srcid, $rh_attr, $ra_attr );

        # Read units from file -----------------------------------------
        $srcid = $varid;
        $srcid = 'time_matched_difference' if $service eq 'DiTmAvMp';
        $srcid = 'difference' if $service eq 'DiArAvTs';

        if ( $service =~ /Sc$/ ) {    # scatter
            my %varInfo = Giovanni::Util::getNetcdfDataVariables($ncfile);
            for my $var ( keys(%varInfo) ) {
                if ( index( $var, $varid ) >= 0 ) {
                    $srcid = $var;
                    last;
                }
            }
        }

        ( $rh_attr, $ra_attr )
            = Giovanni::Data::NcFile::variable_attributes( $ncfile, $srcid,
            0 );

        if ( exists $rh_attr->{units} ) {
            $args{UNITS} = $rh_attr->{units};
        }

        # Read long name from file -------------------------------------
        $srcid = $varid;

        ( $rh_attr, $ra_attr )
            = Giovanni::Data::NcFile::variable_attributes( $ncfile, $srcid,
            0 );

        if ( exists $rh_attr->{long_name} ) {
            $args{LONG_NAME} = $rh_attr->{long_name};
        }
    }

    return Giovanni::Visualizer::Hints::createDataFieldString(%args);
}

sub wrap_titles {
    my $title = shift;
    warn "INFO reformatting title '$title'\n";
    my $nchars    = int( length($title) / 2 ) + 2;
    my @fmt_title = `echo "$title" | fmt -$nchars`;
    map { chomp($_) } @fmt_title;
    my $plot_title = shift @fmt_title;
    my $plot_subtitle = join( ' ', @fmt_title );
    return ( $plot_title, $plot_subtitle );
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

sub get_data_bbox {
    my $data_field = shift;
    my @bbox       = (
        $data_field->get_west, $data_field->get_south,
        $data_field->get_east, $data_field->get_north
    );
    return Giovanni::BoundingBox->new( STRING => join( ",", @bbox ) );
}
sub get_griddata_bbox {
    my $ncfile  = shift;
    my ($attrHash, $attrList) = Giovanni::Data::NcFile::global_attributes($ncfile);
    my @bbox       = (
        $attrHash->{geospatial_lon_min},
        $attrHash->{geospatial_lat_min},
        $attrHash->{geospatial_lon_max},
        $attrHash->{geospatial_lat_max},
    );

    if (    looks_like_number($bbox[0])
         && looks_like_number($bbox[1])
         && looks_like_number($bbox[2])
         && looks_like_number($bbox[3])
       ) {
       return Giovanni::BoundingBox->new( STRING => join( ",", @bbox ) );
    }
    return undef;
}
sub add_captions {
    my ( $ncfile, $data_start, $data_end, $ra_data_fields, $ra_vartitles,
        %args )
        = @_;

    my @data_fields = @$ra_data_fields;

    # Get variable file (or files if comparison)
    my @varfiles = split( ',', $args{varfiles} );

    my $ra_data_starts = [$data_start];
    my $ra_data_ends   = [$data_end];

    # Comparisons used time-matched file lists, hence have same start and end
    if ( $args{comparison} ) {
        push @$ra_data_starts, $data_start;
        push @$ra_data_ends,   $data_end;
    }
    my ( @data_bboxes, $temporal_res );

    foreach my $df (@data_fields) {

        # Temporal resolution should be the same if more than one file
        # so no harm in overwriting variable
        $temporal_res = $df->get_dataProductTimeInterval;

        # Fetch bounding boxes of data
        my $box = get_data_bbox($df);
        push @data_bboxes, $box->getString();
    }
    my $datagrid_box = get_griddata_bbox($ncfile);
    if ($datagrid_box) {
            push @data_bboxes, $datagrid_box->getString();
    }

    my $is_climatology = any { $_->isClimatology } @data_fields;

    # Construct caption(s)
    my $captions = Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME          => $args{starttime},
        USER_END_TIME            => $args{endtime},
        DATA_START_TIMES         => $ra_data_starts,
        DATA_END_TIMES           => $ra_data_ends,
        DATA_TEMPORAL_RESOLUTION => $temporal_res,
        USER_BBOX                => $args{bbox},
        DATA_BBOXES              => \@data_bboxes,
        DATA_STRINGS             => $ra_vartitles,
        IS_CLIMATOLOGY           => $is_climatology,
        GROUP                    => $args{group},
        HAS_TIME_DIMENSION       => $args{'time-axis'},
        SHAPEFILE                => $args{shapefile}
    );

    return unless ($captions);
    $captions =~ s/\n$//s;    # Trim trailing newline
    my $attr = new NcAttribute(
        'name'    => 'plot_hint_caption',
        'value'   => $captions,
        'ncotype' => 'c'
    );
    Giovanni::Data::NcFile::edit_netcdf_attributes( $ncfile, $ncfile, $attr );
}

sub write_manifest {
    my ( $ra_ncOutputs, $rh_args ) = @_;
    my %args = %$rh_args;

    open( MFST, ">" . $args{'outfile'} );
    print MFST "<?xml version='1.0' encoding='UTF-8'?>\n";
    print MFST "<manifest>\n";
    print MFST "  <fileList>\n";
    for my $ncOutput (@$ra_ncOutputs) {
        print MFST "    <file>" . abs_path($ncOutput) . "</file>\n";
    }
    print MFST "  </fileList>\n";
    print MFST "</manifest>\n";
    close(MFST);
}

sub write_lineage {
    my ( $ra_ncInputs, $ra_ncOutputs, $logger ) = @_;

    # Collect inputs and outputs as arrays of InputOutput instances
    my @provInputs;
    my @provOutputs;

    for my $ncInput (@$ra_ncInputs) {
        push(
            @provInputs,
            new Giovanni::Logger::InputOutput(
                name  => 'file',
                type  => 'FILE',
                value => $ncInput,
            )
        );
    }

    for my $ncOutput (@$ra_ncOutputs) {
        push(
            @provOutputs,
            new Giovanni::Logger::InputOutput(
                name  => 'file',
                type  => 'FILE',
                value => $ncOutput
            )
        );
    }

    # Write lineage file
    $logger->write_lineage(
        name    => 'Post-Processing',
        inputs  => \@provInputs,
        outputs => \@provOutputs
    );
}

sub get_QuCl_subtitle_contraint {
    my ($rh_args) = @_;
    my %args = %$rh_args;
    my ( $groupType, $groupValue ) = split( '=', $args{group} );

    my $ret = "";

    if ( $groupType eq 'SEASON' ) {
        $ret = "$groupValue months";
    }
    elsif ( $groupType eq 'MONTH' ) {
        my $monthName = get_month_long_name($groupValue);
        $ret = "$monthName months";
    }
    else {
        die "Invalid group type $groupType";
    }
    return $ret;
}

sub get_seasonal_title {
    my ( $rh_args, $ra_data_fields, $data_start_fmt, $data_end_fmt ) = @_;
    my %args = %$rh_args;
    my ( $groupType, $groupVal ) = split( '=', $args{group} );
    my $ret;

    # Branch based on service
    if ( $args{service} eq 'QuCl' ) {
        my $constraints = "$data_start_fmt - $data_end_fmt";

        if ( $groupType eq 'SEASON' ) {
            $ret = "$groupVal months ($constraints)";
        }
        elsif ( $groupType eq 'MONTH' ) {
            my $monthName = get_month_long_name($groupVal);
            $constraints =~ s/(\d{4})-\w{3}/$1/g;
            $ret = "$monthName months ($constraints)";
        }
        else {
            die "Invalid group type $groupType";
        }
    }

    return $ret;
}

sub get_month_long_name {
    my ($num) = @_;
    my @names = (
        "January",   "February", "March",    "April",
        "May",       "June",     "July",     "August",
        "September", "October",  "November", "December"
    );

    return $names[ $num - 1 ];
}

sub get_legend_label {
    my ($rh_args) = @_;
    my ( $groupType, $groupVal ) = split( '=', $rh_args->{group} );

    if ( $groupType eq 'SEASON' ) {
        return $groupVal;
    }
    elsif ( $groupType eq 'MONTH' ) {
        return get_month_long_name($groupVal);
    }
    else {
        die "Invalid group type $groupType";
    }
}

sub validate_args {
    my %args = @_;

    my @reqArgs = (
        "endtime",  "infile",      "name",      "outfile",
        "service",  "session-dir", "starttime", "units",
        "varfiles", "variables",   "zfiles",
    );

    for my $arg (@reqArgs) {
        die "Missing key '$arg' in \%args hash" unless exists $args{$arg};
    }

    # Check varfiles, variables, and zfiles all have same length
    my @varfiles  = split( ',', $args{varfiles} );
    my @variables = split( ',', $args{variables} );
    my @zfiles    = split( ',', $args{zfiles} );

    if ( scalar @varfiles != scalar @variables ) {
        die "Unequal amount of varfiles and variables";
    }

    if ( scalar @varfiles != scalar @zfiles ) {
        die "Unequal amount of varfiles and zfiles";
    }

    # Check all varfiles and zfiles exist
    for my $varfile (@varfiles) {
        die "varfile $varfile missing" unless -e $varfile;
    }

    for my $zfile (@zfiles) {
        die "zfile $zfile missing" unless -e $zfile;
    }
}

sub parse_zfiles {
    my ($rh_args) = @_;

    # validate_args() garuntees these two arrays are of the same length
    my @zfiles   = split( ',', $rh_args->{zfiles} );
    my @varfiles = split( ',', $rh_args->{varfiles} );
    my @zargs;

    for my $i ( 0 .. scalar @zfiles - 1 ) {
        my $unused;
        ( $zargs[$i], $unused )
            = Giovanni::Algorithm::Wrapper::zdim_info( $zfiles[$i],
            $varfiles[$i] );
    }

    $rh_args->{'z-arg'} = \@zargs;
}

sub add_time_series_axis_labels {
    my ( $rh_args, $ncfile ) = @_;
    my %args           = %$rh_args;
    my %datasetAttribs = Giovanni::Util::getNetcdfDataVariables($ncfile);

    my $varId    = $args{variables};
    my $varUnits = $datasetAttribs{$varId}{units};

    my $yAxisLabel;

    if ( $varUnits && $varUnits ne '1' ) {
        $yAxisLabel = $varUnits;
    }
    else {
        $yAxisLabel = "Unitless";
    }

    my $cmd = "ncatted -a plot_hint_y_axis_label,global,o,c,"
        . "'$yAxisLabel' $ncfile";
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );
}

sub add_vert_prof_axis_labels {
    my ( $rh_args, $ncfile ) = @_;
    my %args = %$rh_args;
    my $id   = $args{variables};

    # Get the z dimension name, units, and long name
    my $varInfo = Giovanni::Util::parseXMLDocument( $args{varfiles} );
    my $ncml    = get_netcdf_meta_xpath_context($ncfile);
    my $xpath;

    $xpath = qq(/varList/var[\@id="$id"]/\@zDimName);
    my $zDimName = $varInfo->findvalue($xpath);

    # get the long name of the z dimension
    $xpath = qq(/nc:netcdf/nc:variable[\@name="$zDimName"]/)
        . qq(nc:attribute[\@name="long_name"]/\@value);
    my $zLongName = $ncml->findvalue($xpath);

    # and the units
    $xpath = qq(/nc:netcdf/nc:variable[\@name="$zDimName"]/)
        . qq(nc:attribute[\@name="units"]/\@value);
    my $zUnits = $ncml->findvalue($xpath);

    # Build and write the Y axis label
    my $yAxisLabel;

    if ( $zUnits && $zUnits ne '1' ) {
        $yAxisLabel = "$zLongName ($zUnits)";
    }
    else {
        $yAxisLabel = "$zLongName";
    }

    my $cmd = "ncatted -a plot_hint_y_axis_label,global,o,c,"
        . "'$yAxisLabel' $ncfile";
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );

    # Build and write the X axis label
    my %varInfo    = Giovanni::Util::getNetcdfDataVariables($ncfile);
    my $xAxisLabel = $varInfo{$id}{units};

    if ( $xAxisLabel && $xAxisLabel ne '1' ) {
        $cmd = "ncatted -a plot_hint_x_axis_label,global,o,c,"
            . "'$xAxisLabel' $ncfile";
        die "Failed to run: $cmd" unless ( system($cmd) == 0 );

    }
}

sub get_netcdf_meta_xpath_context() {
    my ($ncfile) = @_;
    my @lines = `ncdump -h -x $ncfile`
        or die "Failed to get header from $ncfile with ncdump\n";

    # parse the XML and grab the root node.
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_string( join( "", @lines ) );
    my $xpc    = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs(
        nc => 'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );
    return $xpc;
}

1;

__END__

=head1 NAME

Giovanni::PostProcess - Algorithm Post-Processing for Giovanni 4

=head1 SYNOPSIS

  use Giovanni::PostProcess;

  $rc = Giovanni::PostProcess::run(%args);

=head1 DESCRIPTION

Giovanni::PostProcess::run() runs an algorithm post-processing procedure in
Giovanni4.

It works for all algorithms.

=head2 EXPORT

None by default.

=head1 AUTHOR

Daniel da Silva, NASA/GSFC/Telophase

=cut


