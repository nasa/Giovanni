package Giovanni::Algorithm::Wrapper::Test;

#$Id: Test.pm,v 1.29 2015/04/13 19:07:50 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $

use 5.008008;
use strict;
use warnings;
use File::Basename;
use Giovanni::BoundingBox;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'run_test' => [qw(run_test)] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'run_test'} } );

our @EXPORT = qw(run_test);

our $VERSION = '0.01';

use File::Temp qw/tempdir/;

# Preloaded methods go here.

1;

sub run_test {
    my %args = @_;

    # Process input arguments
    die "Must specify 'program' argument to run_test\n"
        unless ( $args{'program'} );

    my $comparison = ( exists $args{'comparison'} ) ? $args{'comparison'} : 0;
    my $name = ( exists $args{'name'} ) ? $args{'name'} : $args{'program'};
    my $bbox
        = ( exists $args{'bbox'} ) ? $args{'bbox'} : "-180.,-90.,180.,90.";

    # Setup directory
    my $tmpdir
        = ( exists $ENV{SAVEDIR} ) ? $ENV{SAVEDIR} : tempdir( CLEANUP => 1 );

    my $outfile_root
        = ( exists $args{'output-file-root'} )
        ? $args{'output-file-root'}
        : "$tmpdir/testAlgorithm";

    # Get input (and output) files
    my $ra_input_cdl
        = defined( $args{'input-netcdfs'} )
        ? $args{'input-netcdfs'}
        : Giovanni::Data::NcFile::read_cdl_data_block();
    my @input_nc;
    for my $cdl (@$ra_input_cdl) {
        my ($netcdf) = ( $cdl =~ /^netcdf\s*(\S*)/ );
        $netcdf = "$tmpdir/$netcdf.nc";
        push @input_nc, $netcdf;
        Giovanni::Data::NcFile::write_netcdf_file( $netcdf, $cdl );

        # ASSUMPTION:  Last file in sequence is the output file.
    }
    my $ref_nc  = pop(@input_nc);
    my $n_input = scalar(@input_nc);

    # Write input manifest file
    my $input_manifest = "$tmpdir/mfst.input.xml";
    unless ($comparison) {
        write_input_manifest( $input_manifest, \@input_nc );
    }
    else {
        my $n_input2     = $n_input / 2;
        my @input_field1 = @input_nc[ 0 .. $n_input2 - 1 ];
        my @input_field2 = @input_nc[ $n_input2 .. $n_input - 1 ];
        DataStager_write_input_manifest( $input_manifest, $args{'temp_res'}, \@input_field1,
            \@input_field2 );
    }

    # Write data field info files
    my ( @data_field_paths, @zfile_paths );
    my $n_fields = $comparison ? 2 : 1;
    my $ra_zslice = $args{'z-slice'} if defined( $args{'z-slice'} );
    my @fields;
    my $sample_id = 0;
    foreach my $i ( 0 .. ( $n_fields - 1 ) ) {
        $data_field_paths[$i] = "$tmpdir/mfst.data_field_info_$i" . '.xml';

        # For comparisons, the first half of the files are for one field,
        # and the second half are for the other field
        # Read one file to see what the variables are
        write_data_field_info( $data_field_paths[$i], $input_nc[$sample_id] );
        ( $fields[$i] )
            = Giovanni::Data::NcFile::get_plottable_variables(
            $input_nc[$sample_id], 0 );
        $zfile_paths[$i] = "$tmpdir/mfst.data_field_slice_info_$i.xml";
        my $zslice = ( defined $ra_zslice ) ? $ra_zslice->[$i] : 'NA';
        write_file( $zfile_paths[$i],
                  '<manifest><data zValue="' 
                . $zslice . '">'
                . $fields[$i]
                . "</data></manifest>\n" );

        # Increment sample_id in case we have a second field
        $sample_id += ( $n_input / $n_fields );
    }

    # Use arguments if available (for testing temporal subsetting)
    my $start_time = $args{'starttime'} if ( exists $args{'starttime'} );
    my $end_time   = $args{'endtime'}   if ( exists $args{'endtime'} );

    # If no start/end time specified, obtain from first and last input files
    unless ($start_time) {
        my $start_string = `ncks -M $input_nc[0] | grep ': start_time'`;
        ($start_time) = ( $start_string =~ m/value\s*=\s*(\S+)/ );
    }
    unless ($end_time) {
        my $end_string = `ncks -M $input_nc[-1] | grep ': end_time'`;
        ($end_time) = ( $end_string =~ m/value\s*=\s*(\S+)/ );
    }

    # Run wild, run free
    my $output_manifest = "$tmpdir/mfst.$name.xml";
    $output_manifest =~ s/ +/_/g;
    my $output_log = "$tmpdir/mfst.$name.log";
    $output_log =~ s/ +/_/g;
    my $provenance = "$tmpdir/prov.$name.xml";
    $provenance =~ s/ +/_/g;
    my $dateline
        = ( exists $args{'dateline'} ) ? $args{'dateline'} : "rotate";
    my %run_args = (
        'program'          => $args{'program'},
        'time-axis'        => $args{'time-axis'},
        'name'             => $args{'name'},
        'units'            => $args{'units'},
        'session-dir'      => $tmpdir,
        'comparison'       => $comparison,
        'inputfiles'       => $input_manifest,
        'bbox'             => $bbox,
        'output-file-root' => $outfile_root,
        'outfile'          => $output_manifest,
        'zfiles'           => join( ',', @zfile_paths ),
        'varfiles'         => join( ',', @data_field_paths ),
        'variables'        => join( ',', @fields ),
        'starttime'        => $start_time,
        'endtime'          => $end_time,
        'dateline'         => $dateline,
        'group'            => $args{group},
    );
    $run_args{'output-type'} = $args{'output-type'}
        if exists( $args{'output-type'} );
    my $units_cfg;

    if ( exists( $args{units} ) ) {
        $units_cfg = write_units_cfg($tmpdir);
        $run_args{units} = $args{units} . ",$units_cfg";
    }

    $run_args{'jobs'} = $args{'jobs'} if exists( $args{'jobs'} );

    my $output_file = Giovanni::Algorithm::Wrapper::run(%run_args);
    return ( 0, -1 ) unless $output_file;
    my @outnc;

    if ( exists( $args{'output-type'} )
        && $args{'output-type'} eq 'filelist' )
    {

       # Um, don't have a good plan on how to check multiple files for a match
        return ( $output_file, 0 );
    }
    my $output_nc = $output_file;

    # Get rid of the pesky (for comparison) history attr
    system("ncatted -h -a history,global,d,,, -O -o $output_nc $output_nc");
    system(
        "ncatted -h -a history_of_appended_files,global,d,,, -O -o $output_nc $output_nc"
    );

    # Get rid of the pesky (for comparison) history_of_appended_files attr
    system(
        "ncatted -h -a history_of_appended_files,global,d,,, -O -o $output_nc $output_nc"
    );

    # Diff the two files
    my @exclude = ();
    push @exclude, @{ $args{'diff-exclude'} } if ( $args{'diff-exclude'} );
    my $diff_rc
        = Giovanni::Data::NcFile::diff_netcdf_files( $ref_nc, $output_nc,
        @exclude );

    # Cleanup if successful
    my $cleanup = exists( $ENV{SAVEDIR} ) && $ENV{SAVEDIR};
    if ( ( $diff_rc eq '' ) && $cleanup ) {
        warn "Cleaned up:\n";
        unlink( $input_manifest, $output_manifest )
            || warn "failed to clean $input_manifest, $output_manifest: $!\n";
        unlink($ref_nc) || warn "failed to clean $ref_nc: $!\n";
        unlink(@input_nc)
            || warn "Failed to clean: " . join( "\n", @input_nc, '' );
        unlink(@data_field_paths)
            || warn "Failed to clean: "
            . join( "\n", @data_field_paths, "err: %!", '' );
        unlink(@zfile_paths)
            || warn "Failed to clean: "
            . join( "\n", @zfile_paths, "err: %!", '' );
        unlink($output_log);
        unlink($provenance);
    }
    return ( $output_nc, $diff_rc );
}

# my $outnc_3d_1 = Giovanni::Algorithm::Wrapper::run('program' => $code_file1, 'comparison' => 0,
# 'name' => 'Test 3d Single Variable',
# 'output-file-root' => "$datadir/" . 'testSvc3d1',
# 'bbox' => $bbox, 'starttime'=> $start, 'endtime' => $end,
# 'variables' => 'AIRX3STD_006_Temperature_A',
# 'varfiles' => $varinfo_3d_file1,
# 'zfiles' => $zfile_3d_1,
# 'inputfiles' => $infile_3d_1,
# 'outfile' => $outman_3d_1);

# Given a sample netCDF input file, reverse engineer and print out a
# data_field_info file.
# Note that this does not get ALL of the data product level info, but
# the missing aspects hopefully do not affect the algorithm execution.
sub write_data_field_info {
    my ( $path, $ncfile, %args ) = @_;
    require Giovanni::Data::NcFile;

# FILE MUST BE ALREADY SCRUBBED!!!
# This relies on a lot of assumptions...
# Also, a lot of attributes are hard coded for now as they do not (usually) affect
# the algorithms using this framework for unit testing

    # Fetch plottable variable and its attributes
    # ASSUME one plottable variable
    my ($var_id)
        = Giovanni::Data::NcFile::get_plottable_variables( $ncfile, 0 );
    my $data_bbox = Giovanni::BoundingBox->new(
        STRING => Giovanni::Data::NcFile::get_data_bounding_box($ncfile) );

    # check for the MERRA case where the data bounding box crosses the 180
    # meridian
    my $canonical = $data_bbox->getCanonicalBbox();
    if ( abs( $canonical->west() - $canonical->east() ) < 1e-5 ) {

        # east and west are the same longitude, so just set them to -180 and
        # 180 so other code handles them better
        $data_bbox = Giovanni::BoundingBox->new(
            NORTH => $data_bbox->north(),
            SOUTH => $data_bbox->south(),
            WEST  => -180,
            EAST  => 180
        );
    }

    my ( $rh_attrs, @attrs )
        = Giovanni::Data::NcFile::get_variable_attributes( $ncfile, 1,
        $var_id );
    my ( $rh_global, @global )
        = Giovanni::Data::NcFile::global_attributes( $ncfile, 1 );
    my %global = %$rh_global;
    my %attrs  = %$rh_attrs;
    my @coords = split( ' ', $attrs{coordinates} );
    my ( $zDimName, $zDimUnits );

    # Look for Z coordinate
    # ASSUME coordinate order: time <z> lat lon
    if ( scalar(@coords) > 3 ) {
        $zDimName = $coords[1];

        # Fetch Z coordinate attributes to get units
        my ( $rh_zattrs, @zattrs )
            = Giovanni::Data::NcFile::variable_attributes( $ncfile, $zDimName,
            1 );
        $zDimUnits = $rh_zattrs->{units};
    }

    my $source = infer_source( $attrs{product_short_name} );

    # Ready to write:  open the stream
    unless ( open( OUT, '>', $path ) ) {
        die "Cannot write to $path: $!\n";
    }

    print OUT "<varList>\n";
    print OUT " <var id=\"$var_id\"";
    print OUT " zDimUnits=\"$zDimUnits\" zDimName=\"$zDimName\""
        if ($zDimUnits);
    print OUT ' dataProductBeginDateTime="2000-01-01T00:00:00Z"';
    print OUT ' dataProductEndDateTime="2038-01-19T03:14:07Z"';
    print OUT " long_name=\"$attrs{long_name}\"";
    print OUT " dataFieldUnitsValue=\"$attrs{units}\""
        if ( exists( $attrs{units} ) );
    print OUT
        ' fillValueFieldName="_FillValue" accessFormat="netCDF" accessMethod="OPeNDAP" dataProductStartTimeOffset="1"';
    print OUT ' url="http://dont.use.this.url.for.anything"';
    print OUT ' north="'
        . $data_bbox->north()
        . '" south="'
        . $data_bbox->south()
        . '" west="'
        . $data_bbox->west()
        . '" east="'
        . $data_bbox->east() . '"';
    print OUT ' sdsName="DONT_USE_THIS"';
    print OUT " dataProductShortName=\"$attrs{product_short_name}\"";
    print OUT " dataProductVersion=\"$attrs{product_version}\"";
    $global{temporal_resolution} = "daily"
        unless exists( $global{temporal_resolution} );
    print OUT " dataProductTimeInterval=\"$global{temporal_resolution}\"";
    print OUT ' dataProductEndTimeOffset="-1"';
    print OUT " dataProductPlatformInstrument=\"$source\"" if $source;
    print OUT ' resolution="1 x 1 deg."';
    print OUT ' dataFieldStandardName="foo"';
    print OUT ">\n";
    print OUT
        ' <slds><sld url="http://s4ptu-ts1.ecs.nasa.gov/giovanni/sld/divergent_rdylbu_10_sld.xml" label="Red-yellow-blue Color Map"/></slds>'
        . "\n";
    print OUT " </var>";
    print OUT "</varList>\n";
    close(OUT) or die "Failed to close file $path: $!\n";
}

sub infer_source {
    my $short_name = shift;
    unless ($short_name) {
        warn "ERROR: No short name passed to infer_source";
        return;
    }
    my $source;
    if ( $short_name =~ /^TRMM/ ) {
        $source = 'TRMM';
    }
    elsif ( $short_name =~ /^GPM/ ) {
        $source = 'GPM';
    }
    elsif ( $short_name =~ /^AIR/ ) {
        $source = 'AIRS';
    }
    elsif ( $short_name =~ /^MOD/ ) {
        $source = 'MODIS-Terra';
    }
    elsif ( $short_name =~ /^MYD/ ) {
        $source = 'MODIS-Aqua';
    }
    elsif ( $short_name =~ /^G4P/ ) {
        $source = 'GOCART';
    }
    elsif ( $short_name =~ /^GLDAS_NOAH10_M/ ) {
        $source = 'GLDAS';
    }
    elsif ( $short_name =~ /^GLDAS_NOAH10_3H/ ) {
        $source = 'GLDAS';
    }
    elsif ( $short_name =~ /^GLDAS_NOAH025_3H/ ) {
        $source = 'GLDAS';
    }
    else {
        warn
            "Unrecognized shortname pattern $short_name;:  see C. Lynnes about adding to the test harness\n";
    }
    return $source;
}

sub DataStager_write_input_manifest{ # borrowed from DataStager
    my ( $path, $temporal_resolution, @ra_ncfiles ) = @_;
    my $global_metadata = 'Global';
    my $attribute       = 'start_time';

    # When this was first written we had input mfst with more than one variable. Now we don't
    my $doc = undef;
    my $var_id;
    my $root;

    foreach my $ncfiles (@ra_ncfiles) {
      ($var_id) = Giovanni::Data::NcFile::get_plottable_variables( $ncfiles->[0], 
                0 );
      if (! $doc) {
        $doc  = XML::LibXML::Document->new();
        $root = $doc->createElement("manifest");
        $doc->setDocumentElement($root);
       }
        my $fileListElement = $doc->createElement("fileList");
        $root->appendChild($fileListElement);
        $fileListElement->setAttribute( "id", $var_id); # Test
        my $first = 0;
        my $last  = 0;
        foreach my $stagedFile (@{$ncfiles}) {
            my $fileElement = $doc->createElement("file");
            $fileListElement->appendChild($fileElement);
            $fileElement->appendText( $stagedFile);
# Get the data pairing time attribute from the scubbed file. We will call this 'datatime'
# We will use a method constructed in Giovanni::Data::NcFile to get the return value
            my $file = $stagedFile;
            my $data_pairing_time = Giovanni::Data::NcFile::get_data_pairing_time( $file,
                $global_metadata, $attribute, $temporal_resolution );
            Giovanni::Util::trim($data_pairing_time);
            $data_pairing_time =~ s/-|T|:|Z//g;
            $first = $data_pairing_time if ($first == 0);
            $last = $data_pairing_time;

            $fileElement->setAttribute( "datatime", $data_pairing_time );
            my ( $rh_attrs, $ra_attrs ) = Giovanni::Data::NcFile::variable_attributes( $ncfiles->[0], $var_id, 1 );
            $fileElement->setAttribute( "dataProductShortName", $rh_attrs->{product_short_name} );
            $fileElement->setAttribute( "dataProductVersion", $rh_attrs->{product_version} );
            $fileElement->setAttribute( "long_name", $rh_attrs->{long_name} );
        }
    }
        my $diff_variable_mfst = $path;
        #$diff_variable_mfst =~ s/mfst.input.xml/mfst.data_fetch+d$var_id+${first}_$last.xml/;
        open FILE, '>>', $diff_variable_mfst or die "Could not open $diff_variable_mfst: $!\n";
        print FILE $doc->toString() or die $?;
        close(FILE) or die $?;
}
# Given one or more lists of test input files, write_input_manifest generates
# a manifest file suitable for input into a Giovanni algorithm
sub write_input_manifest {
    my ( $path, @ra_ncfiles ) = @_;

    # An array of input references, has length 1 (for single-field runs) or 2
    #  (for comparisons)
    # Find the plottable variable
    open OUT, '>', $path or die "Could not open $path: $!\n";
    print OUT '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
    print OUT '<manifest>' . "\n";
    foreach my $ra_ncfiles (@ra_ncfiles) {
        my @ncfiles = @$ra_ncfiles;
        my ($var_id)
            = Giovanni::Data::NcFile::get_plottable_variables( $ncfiles[0],
            0 );

        # Get short name, version, long name arguments
        my ( $rh_attrs, $ra_attrs )
            = Giovanni::Data::NcFile::variable_attributes( $ncfiles[0],
            $var_id, 1 );
        print OUT
            "  <fileList id=\"$var_id\" dataProductShortName=\"$rh_attrs->{product_short_name}\" dataProductVersion=\"$rh_attrs->{product_version}\" long_name=\"$rh_attrs->{long_name}\">\n";
        map { printf OUT "    <file>%s</file>\n", $_ } @ncfiles;
        print OUT "  </fileList>\n";
    }
    print OUT "</manifest>\n";
    close OUT;
}

# write_file is a convenience file for writing output files
sub write_file {
    my ( $path, $string ) = @_;
    open OUT, '>', $path or die("Cannot write to $path");
    print OUT $string;
    close OUT;
    return $path;
}

sub write_units_cfg {
    my $dir     = shift;
    my $outfile = "$dir/units-cfg.xml";
    open OUT, ">$outfile";
    print OUT << 'EOF';
<units>
        <linearConversions>
                <linearUnit source="mm/hr" destination="mm/day" scale_factor="24.0"
                        add_offset="0" />
                <linearUnit source="mm/hr" destination="inch/hr"
                        scale_factor="1.0/25.4" add_offset="0" />
                <linearUnit source="mm/hr" destination="inch/day"
                        scale_factor="24.0/25.4" add_offset="0" />
                <linearUnit source="mm/day" destination="mm/hr" scale_factor="1.0/24.0"
                        add_offset="0" />
                <linearUnit source="mm/day" destination="inch/day"
                        scale_factor="1.0/25.4" add_offset="0" />
                <linearUnit source="kg/m^2" destination="mm" scale_factor="1"
                        add_offset="0" />
                <linearUnit source="K" destination="C" scale_factor="1"
                        add_offset="-273.15" />
                <linearUnit source="kg/m^2/s" destination="mm/s"
                        scale_factor="1" add_offset="0" />
                <linearUnit source="kg/m^2/s" destination="mm/hr"
                        scale_factor="3600." add_offset="0" />
                <linearUnit source="molecules/cm^2" destination="DU"
                        scale_factor="1.0/2.6868755e+16" add_offset="0" />
        </linearConversions>
        <nonLinearConversions>
                <nonLinearUnit source="mm/hr" destination="mm/month"
                        function="monthlyRate" />
                <nonLinearUnit source="mm/hr" destination="inch/month"
                        function="monthlyRate" />
        </nonLinearConversions>
</units>
EOF
    close(OUT);
    return $outfile;
}

__END__

=head1 NAME

Giovanni::Algorithm::Wrapper::Test - Convenience functions for setting up algorithm unit/regression tests

=head1 SYNOPSIS

  use Giovanni::Algorithm::Wrapper::Test;

  $rc = Giovanni::Algorithm::Wrapper::Test::run_test(
    'program' => program,
    'comparison' => 1|0,,
    'bbox' => westsoutheastnorth,
    'output-file_root' => output_file_root,
    'starttime' => starttime,
    'endtime' => endtime,
    'z-slice' => slice_value,
    'minimum-time-steps' => mintimesteps,
  );

=head1 DESCRIPTION

Giovanni::Algorithm::Wrapper::Test::run_test() runs a test for a contributed
algorithm.  It requires a __DATA__ block in the main program with CDL
versions of the data files (you can obtain via ncdump file.nc > file.cdl).
It assumes the last file in the block to be the desired output; the rest are
inputs.  Note that the input files MUST be scrubbed files from Giovanni-4.

This will create all of the Giovanni-4 input files (data_field_info, zfile, 
input manifest file) needed for an invocation of a science algorithm. 

For units conversion, it also creates the units conversion configuration file,
so the --units argument passed should include just the one or two destination
units (matching the --variables), separated by commas. The test harness will 
append ",units-cfg.xml" and pass that on to the algorithm.

=head2 EXPORT

run_test

=head1 AUTHOR

Chris Lynnes, NASA/GSFC

=cut
