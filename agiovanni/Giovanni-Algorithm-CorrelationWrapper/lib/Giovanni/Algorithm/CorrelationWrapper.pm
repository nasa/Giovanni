#$Id: CorrelationWrapper.pm,v 1.39 2015/03/18 21:30:01 dedasilv Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

Giovanni::Algorithm::CorrelationWrapper - Perl extension for wrapping the nccorrelate program

=head1 SYNOPSIS

  use Giovanni::Algorithm::CorrelationWrapper;

  $file_list_file = Giovanni::Algorithm::CorrelationWrapper::mk_file_list(
                      $infile, $x_field, $x_info_file, $y_field, 
                      $y_info_file, $file_list_file);
  $outfile = mk_output_filename ($dir, $ra_variables, $start, $end, $use_time);
  $outfile = run_correlation ($infile, $outfile, $bbox, $verbose, $x_field, $y_field);

  ($var, $zdim, $zval, $zunits) = parse_data_field($field);

=head1 DESCRIPTION

This perl module wraps the nccorrelate (C) executable.

=over 4

=item dataday2timestamp

Convert a dataday of the form YYYYDDD to a timestamp like YYYY-MM-DDTHH:MI:SSZ.

=item mk_file_list

This function matches files up by time and creates a text list with pairs
of files to be correlated. The file into which the pairs are written is
I<specified in the function arguments>.

The return values, are a "side-effect", consisting of a human-readable
text string describing the combination of variables and an array of the 
actual variables.  (Should be refactored at some time.)

=item mk_output_filename

mk_output_filename composes the pathname for the output file given the 
directory, an array of length 2 of the variables and the start and end time.

=item parse_data_field

Extracts Z dimension info from a data field specification: var,dim=valunits.
If there is no Z dimension, simply returns the input.

=item run_correlation

run_correlation actually runs the nccorrelation code.
It takes as input an output filename, where it writes the output file.
It also returns this, which can be confusing.  It does not currently
change the $outfile, but it might in the future.  If it fails, the
code will exit from within run_correlation.

Another wrinkle is that if it crosses the dateline, it will split the
files up into east.nc and west.nc, then stitch them back together in the
$outfile.

=back

=head1 SEE ALSO

nccorrelate(1), correlation_wrapper.pl(1)

=head1 AUTHOR

Chris Lynnes, NASA/GSFC

=head1 COPYRIGHT AND LICENSE

NASA use only

=cut

package Giovanni::Algorithm::CorrelationWrapper;

use 5.008000;
use strict;
use warnings;

our $VERSION = '1.1';

# Preloaded methods go here.

1;

use File::Basename;
use Time::Local;
use XML::LibXML;
use Giovanni::DataField;
use Giovanni::Visualizer::Hints;
use Giovanni::Util;
use Date::Manip;
use Giovanni::Data::NcFile;

sub dataday2timestamp {
    my ( $yyyy, $ddd ) = @_;
    my $t = timegm( 0, 0, 0, 1, 0, $yyyy - 1900 ) + ( $ddd - 1 ) * 3600 * 24;
    my @t = gmtime($t);
    return sprintf(
        "%4d-%02d-%02dT%02d:%02d:%02dZ",
        1900 + $t[5],
        $t[4] + 1,
        $t[3], $t[2], $t[1], $t[0]
    );
}

sub mk_file_list {
    my ( $infile, $x_field, $x_data_info, $y_field, $y_data_info, $outfile,
        $min_sample_size )
        = @_;
    $min_sample_size = 3 unless $min_sample_size;

    # Read input file into a single string
    open IN, $infile or quit( "Cannot open input file $infile", $! );
    local ($/) = undef;
    my $varinfo = <IN>;
    close IN;

    my ( %paths1, %paths2 );

    #  my $i = 0;
    # @variables is the netcdf variable name. @varnames is human readable
    my ( @variables, @varnames );
    my ( $var_x,     $zdim_x, $zval_x, $zunits_x, $zval_units_x );
    my ( $var_y,     $zdim_y, $zval_y, $zunits_y, $zval_units_y );
    my ( @zdims, @zval_units, @zunits );

    # For backward compatibility to Kepler workflows, check if $x_field is set
    if ($x_field) {
        ( $var_x, $zdim_x, $zval_x, $zunits_x, $zval_units_x )
            = parse_data_field($x_field);
        ( $var_y, $zdim_y, $zval_y, $zunits_y, $zval_units_y )
            = parse_data_field($y_field);
        @zdims      = ( $zdim_x,       $zdim_y );
        @zval_units = ( $zval_units_x, $zval_units_y );
        @zunits     = ( $zunits_x,     $zunits_y );
        $variables[0] = $var_x;
        $variables[1] = $var_y;
    }

    # Parse the XML file for the variables
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_string($varinfo);

    # Parse the data field info files
    my $data_info_hash = {};
    my $data_field = Giovanni::DataField->new( MANIFEST => $x_data_info );
    $data_info_hash->{ $data_field->get_id() } = $data_field;
    $data_field = Giovanni::DataField->new( MANIFEST => $y_data_info );
    $data_info_hash->{ $data_field->get_id() } = $data_field;

    my $use_time = 0;
    my $i_var    = -1;

    # get out the variable ids for the file lists
    my @vars
        = map( $_->nodeValue(), $dom->findnodes("/data/dataFileList/\@id") );
    for my $variable_id (@vars) {
        if ( $var_x && $var_y ) {
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
        }
        else {
            $i_var++;
            $variables[$i_var] = $variable_id;
        }
        my $long_name = $data_info_hash->{$variable_id}->get_long_name();
        my $product
            = $data_info_hash->{$variable_id}->get_dataProductShortName();
        my $version
            = $data_info_hash->{$variable_id}->get_dataProductVersion();
        my $time_resolution
            = $data_info_hash->{$variable_id}->get_dataProductTimeInterval();
        my $spatial_resolution
            = $data_info_hash->{$variable_id}->get_resolution();
        my $platform_instrument = $data_info_hash->{$variable_id}
            ->get_dataProductPlatformInstrument();
        my $units
            = $data_info_hash->{$variable_id}->get_dataFieldUnitsValue();

        # Require long_name and product. However, we may have versionless
        # products
        quit( "Cannot parse variable info from input file", $infile )
            unless ( $long_name && $product );

        # Format variable name
        $varnames[$i_var]
            = Giovanni::Visualizer::Hints::createDataFieldString(
            LONG_NAME           => $long_name,
            TIME_RESOLUTION     => $time_resolution,
            SPATIAL_RESOLUTION  => $spatial_resolution,
            PLATFORM_INSTRUMENT => $platform_instrument,
            PRODUCT_SHORTNAME   => $product,
            VERSION             => $version,
            UNITS               => $units,
            THIRD_DIM_VALUE     => $zval_units[$i_var],
            THIRD_DIM_UNITS     => '',
            );

        # get out the data files for this id
        my @paths = map( $_->nodeValue(),
            $dom->findnodes(
                qq|/data/dataFileList[\@id="$variable_id"]/dataFile/text()|)
        );
        for my $path (@paths) {
            my $file = basename($path);

# Parse (as strictly as possible with regex) for date
#                           Y   Y    Y     Y    M   M    D    D  T   H    H    M    M    S    S
            my ($date)
                = ( $file
                    =~ /\.([12][90][0-9][0-9][01][0-9][0-3][0-9]T*[012]*[0-9]*[012]*[0-9]*[012]*[0-9]*)\./
                );
            quit( "Cannot parse date from input filename", $file )
                unless $date;

            my $date_key = regularize_date($date);

            # If more than YYYYMMDD, then we need to use time in our output
            # filenames. Therefore, pass this back for future use by
            # mk_output_filename
            $use_time = 1 if ( length($date) > 8 );
            if ( $i_var == 0 ) {
                $paths1{$date_key} = $path;
            }
            elsif ( $i_var == 1 ) {
                $paths2{$date_key} = $path;
            }
            else {
                quit( "Too many variables in file", $infile );
            }
        }
    }

    # Write to plain text file with filename pairs
    open( OUT, ">", $outfile )
        or quit( "Cannot open output file $outfile for writing", $! );
    my $n_files = 0;
    foreach my $key ( sort keys %paths1 ) {
        if ( exists $paths2{$key} ) {
            printf OUT "$paths1{$key} $paths2{$key}\n";
            $n_files++;
        }
    }
    close OUT;

    # Must have at least 3 matched pairs to compute a correlation coefficient
    if ( $n_files < $min_sample_size ) {
        quit(
            "Only $n_files pairs of matching files found, must have at least $min_sample_size for correlation"
        );
    }
    else {
        warn "INFO found $n_files pairs of files for correlation\n";
    }

    # "Side-effect" return values (bad design, should be refactored)
    my $vartext = join( ' vs. ', @varnames );

    #  map{$_ =~ s/^.*?://} @variables;
    return ( $vartext, $use_time, @variables );

    #  return($vartext, $use_time);
}

sub regularize_date {
    my $date = shift;
    $date .= "01" if ( length($date) < 8 );
    my $miss = 14 - length($date);
    $date .= '0' x $miss;
    return $date;
}

# Construct an output filename from the directory, variable text, start and end
sub mk_output_filename {
    my ( $dir, $ra_variables, $start, $end, $use_time ) = @_;
    my $vartext = join( '+', @$ra_variables );
    $vartext =~ s/,\w+?=/-/g;

    if ($use_time) {

        # Leave 'T' as a separator
        $start =~ s/[Z:]//g;
        $end   =~ s/[Z:]//g;
    }
    else {

        # Pull times off
        $start =~ s/T.*Z//;
        $end   =~ s/T.*Z//;
    }

    # Convert '.' and ':' to _
    $vartext =~ s/[\.\:]/_/g;

    # Concatenate dates
    my $date = $start . '_' . $end;

    # Delete date delimiters
    $date =~ s/\-//g;

    # Now change underscore to - (had to protect it from above deletion)
    $date =~ s/_/-/;

    return ("$dir/correlation.$vartext.$date.nc");
}

# var,zdim=zvalzunits, e.g., Temperature_A,TempPrsLvls_A=850hPa
sub parse_data_field {
    my $field = shift;
    my ( $var, $dim, $val, $units )
        = ( $field =~ /(\w+?),(\w+?)=([\d\.]+)(\w+)/s );
    my ($val_units) = "$val $units" if ($val);

# If we found a dimension send back all info, otherwise echo back the 2D field
    return $dim ? ( $var, $dim, $val, $units, $val_units ) : ($field);
}

sub quit {
    my ( $user_msg, $details, $exit_code ) = @_;

    # Error for the users
    warn("USER_ERROR Correlation wrapper error: $user_msg\n");

    # Error for developers
    my $errmsg = "ERROR $user_msg";
    $errmsg .= ": $details" if $details;
    warn("$errmsg\n");
    exit( $exit_code || 1 );
}

sub run_command {
    my ( $verbose, $cmd ) = @_;
    warn("DEBUG run command $cmd\n") if $verbose;

    # Run command as backticks
    my $output = `$cmd`;

    # If non-zero return, then report in a meaningful way
    if ($?) {
        my $errmsg = sprintf( "exit=%d signal=%d core=%s",
            $? >> 8, $? & 127, ( $? & 128 ) ? 'y' : 'n' );
        quit(
            "Failed to run correlation command",
            "Failed to run correlation command '$cmd': $errmsg\nOutput: $output\n",
            11
        );
    }
}

sub run_correlation {
    my ( $infile, $outfile, $bbox, $verbose, $x_field, $y_field ) = @_;

    quit( "Failed to run correlation",
        "Failed to run nccorrelate, no X field specified", 12 )
        unless $x_field;

    # Put it in an array, in case we cross the dateline and have to run twice
    my @cmd = ("nccorrelate -i $infile -x $x_field -y $y_field");
    $cmd[0] .= " -v $verbose" if $verbose;
    if ($bbox) {
        my ( $west, $south, $east, $north ) = split( ',', $bbox );
        if ( $west > $east ) {
            $cmd[1] = $cmd[0];
            $cmd[0] .= " -o east.nc -w -180 -s $south -e $east -n $north";
            $cmd[1] .= " -o west.nc -w $west -s $south -e 180 -n $north";
        }
        else {
            $cmd[0] .= " -o $outfile -w $west -s $south -e $east -n $north";
        }
    }

   # Run the correlation program, once for most cases, twice for dateline case
    foreach my $cmd (@cmd) {
        my $rc = system($cmd);
        if ( $? != 0 ) {
            my $err
                = sprintf( "on command $cmd with exit code: %d", $? >> 8 );
            quit( "nccorrelate failed", $err );
        }
    }

    # If we had to split it up, then stitch it back together
    cat_netcdfs( $verbose, 'west.nc', 'east.nc', $outfile )
        if ( scalar(@cmd) > 1 );

   # TT 21991 - write Output file after the stitching, i.e., outside the loop.
    warn "OUTPUT $outfile\n";
    return $outfile;
}

sub cat_netcdfs {
    my ( $verbose, $west_file, $east_file, $outfile ) = @_;
    foreach my $file ( $west_file, $east_file ) {

    # Swap latitude and longitude in order to make longitude a record variable
        run_command( $verbose,
            "ncpdq -a longitude,latitude -O -o $file $file" );

        # Make longitude a record variable
        run_command( $verbose,
            "ncks --mk_rec_dmn longitude -O -o $file $file" );

    }

# Add 360 to longitude of east file to make it monotonic
# - 6/5/2013 (#23955)
# - This is no longer needed and is causing problems in interactive map; was
# - needed with static map.
# -  run_command($verbose, "ncap2 -s 'longitude += (360. * (longitude < 0.))' -O -o $east_file $east_file");

    # Cat the files together with ncrcat
    run_command( $verbose, "ncrcat -O $west_file $east_file $outfile" );

    # Swap latitude and longitude back
    run_command( $verbose,
        "ncpdq -a latitude,longitude -O -o $outfile $outfile" );

    # Cleanup
    unlink( $west_file, $east_file );
}

# get_start_end_times - Gets time range global attributes
# Description:
#   Start time is obtained from the first file and end time from the last file
#   to give us the time coverage. This uses the global attributes start_time
#   and end_time.
# Inputs:
#   $in_file - Input file that contains list of paired files
sub get_start_end_times {
    my ($files) = @_;

    my $firstLine;
    my $lastLine;

    open( FILE, "<", $files ) or die "Unable to open $files";
    while ( my $line = <FILE> ) {
        chomp($line);
        if ( !defined($firstLine) ) {
            $firstLine = $line;
        }
        $lastLine = $line;
    }
    close(FILE);

    # get the first two files
    my @files = Giovanni::Util::trim( split( '\s+', $firstLine ) );

    # get the start_time and end_time values
    my @times = map( _get_scrubbed_file_times($_), @files );

    # calculate the earliest start time
    my $startTime
        = Giovanni::Util::getEarliestTime( map( $_->{start}, @times ) );

    # get the last two files
    @files = Giovanni::Util::trim( split( '\s+', $lastLine ) );

    # get the start_time and end_time values
    @times = map( _get_scrubbed_file_times($_), @files );

    # calculate the latest end time
    my $endTime
        = Giovanni::Util::getLatestTime( map( $_->{end}, @times ) );

    return ( $startTime, $endTime );

}

sub _get_scrubbed_file_times {
    my ($file) = @_;
    my $xpc = Giovanni::Data::NcFile::get_xml_header($file);

    my ($startTimeNode)
        = $xpc->findnodes(
        qq(/nc:netcdf/nc:attribute[\@name="start_time"]/\@value));
    my $startTime = $startTimeNode->getValue();

    my ($endTimeNode)
        = $xpc->findnodes(
        qq(/nc:netcdf/nc:attribute[\@name="end_time"]/\@value));
    my $endTime = $endTimeNode->getValue();

    return {
        start => $startTime,
        end   => $endTime,
    };
}
