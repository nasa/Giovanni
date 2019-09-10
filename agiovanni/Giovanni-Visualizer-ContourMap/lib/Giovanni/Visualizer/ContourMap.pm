package Giovanni::Visualizer::ContourMap;

use 5.008008;
use strict;
use warnings;
use Giovanni::Data::NcFile;
use Giovanni::Util;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Visualizer::ContourMap ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

# Preloaded methods go here.

1;

sub contourMap {
    my ( $ncfile, %params ) = @_;

    # Either set variable in parameters or pick the first plottable on
    my ($var)
        = ( exists $params{VARIABLE} )
        ? $params{VARIABLE}
        : Giovanni::Data::NcFile::get_plottable_variables( $ncfile, 0 );

    # Default output file adds _contour.shp onto netcdf pathname
    my $outfile
        = ( exists $params{OUTFILE} )
        ? $params{OUTFILE}
        : $ncfile . "_$var" . "_contour.shp";
    unlink $outfile if -f $outfile;

    my $min = $params{MIN};
    my $max = $params{MAX};
    if ( not defined $min or not defined $max ) {
        my @fileDataRange
            = Giovanni::Util::getNetcdfDataRange( $ncfile, $var );
        $min = $fileDataRange[0] if not defined $min;
        $max = $fileDataRange[1] if not defined $max;
    }

    # number of contour levels. The default is 10.
    my $cLevels
        = ( exists $params{LEVELS} ) ? $params{LEVELS}
        : (
        ( defined $params{INTERVAL} )
        ? int( ( $max - $min ) / ( $params{INTERVAL} ) )
        : 10
        );

    # interval between contour levels
    my $interval
        = ( defined $params{INTERVAL} )
        ? $params{INTERVAL}
        : ( $max - $min ) / $cLevels;

    # values for each contour
    my @values
        = ( exists $params{VALUES} )
        ? @{ $params{VALUES} }
        : ();
    if ( @values == 0 ) {
        push( @values, $min );
        for ( my $i = 1; $i < $cLevels; $i++ ) {
            push( @values, $min + $interval * $i );
        }
        push( @values, $max );
    }

    # Run gdal_contour
    my $contourCommand = "gdal_contour -a contour ";
    if ( @values >= 1 ) {
        my $vString = join( ' ', @values );
        $contourCommand .= "-fl $vString ";
    }
    else {
        $contourCommand .= " -i $interval ";
    }
    $ncfile = "NETCDF:\"" . $ncfile . ":\"" . $var;
    $contourCommand .= "$ncfile $outfile >/dev/null";
    print STDERR "contour command is $contourCommand \n";
    my $rc = system($contourCommand);
    if ( $rc != 0 ) {
        warn "ERROR Failed to create contour $outfile with gdal_contour\n";
        return;
    }
    return $outfile;
}

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::Visualizer::ContourMap - construct a contour map from netCDF using gdal_contour

=head1 SYNOPSIS

  use Giovanni::Visualizer::ContourMap;
  $contourFile = contourMap ( $nc_file, %params );

=head1 DESCRIPTION

=head2 REQUIRED PARAMETERS

=over 4

=item $ncfile

NetCDF file with CF-compliant coordinates.

=back

=head2 OPTIONAL PARAMETERS

=over 4

=item OUTFILE

Output contour filename.  Defaults to netcdf filename appended with _contour.shp.

=item VARIABLE

Variable name to visualize. Defaults to the first variable found.

=item MIN      

The minimum value for contour. Defaults to the data minimum value

=item  MAX     

The maximum value for contour. Defaults to the data maximum value.

=item INTERVAL

Interval between contour

=item VALUES

One or more fixed levels to extract. If it is not specified, use MIN and INTERVAL.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

Peisheng Zhao, E<lt>peisheng.zhao-1@nasa.gov<gt>

=head1 COPYRIGHT AND LICENSE

TBD.

=cut
