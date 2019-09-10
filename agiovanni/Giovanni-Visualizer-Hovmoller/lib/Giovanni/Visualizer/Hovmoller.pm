package Giovanni::Visualizer::Hovmoller;

use 5.008008;
use strict;
use warnings;
use Giovanni::OGC::SLD;
use Giovanni::Data::NcFile;
use Giovanni::Util;
use File::Temp;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use Giovanni-Visualizer-Hovmoller ':all';
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

sub gradsMap {
    my ( $ncfile, $sld_file, %params ) = @_;

    # Default output file adds .png onto netcdf pathname
    my $outfile
        = ( exists $params{OUTFILE} ) ? $params{OUTFILE} : "$ncfile.png";

    # Either set variable in parameters or pick the first plottable on
    my ($var)
        = ( exists $params{VARIABLE} )
        ? $params{VARIABLE}
        : Giovanni::Data::NcFile::get_plottable_variables( $ncfile, 0 );

# Smooth = 0 (no smoothing), 1 (interpolated) or 2 (interpolated and smoothed)
    my $smooth = ( exists $params{SMOOTH} ) ? $params{SMOOTH} : 0;

# overlay = 0 (just data), 1 (overlay with coastline, countries and us states)
    my $overlay = ( exists $params{OVERLAY} ) ? $params{OVERLAY} : 0;

    my $width  = ( exists $params{WIDTH} )  ? $params{WIDTH}  : 563;
    my $height = ( exists $params{HEIGHT} ) ? $params{HEIGHT} : 461;
    my $bbox         = $params{BBOX}      if exists $params{BBOX};
    my $dim          = $params{DIMENSION} if exists $params{DIMENSION};
    my $longName     = $params{LNAME}     if exists $params{LNAME};
    my $standardName = $params{SNAME}     if exists $params{SNAME};
    my $axis         = $params{AXIS}      if exists $params{AXIS};
    my $dir          = $params{DIR}       if exists $params{DIR};

    # Make a temporary file and insert lat or lon dimension so
    # GrADS can read the NetCDF file
    my $tmp = File::Temp->new(
        TEMPLATE => 'tempXXXX',
        DIR      => $ENV{TMPDIR},
        SUFFIX   => '.nc'
    );

    my $tmpfile
        = Giovanni::Data::NcFile::insert_dim_var_for_grads( $ncfile, $tmp,
        $dim, $longName, $standardName, $axis, $dir );

    my $scriptfile = @_;

    # Check to see if the temporal resolution of the datafile is 8-daily
    # Giovanni cannot support this temporal resolution for Hovmoller services.
    my ($att_hash) = Giovanni::Data::NcFile::global_attributes($ncfile);
    my $temporal_resolution = $att_hash->{temporal_resolution};

    # Create the GrADS Script through sub-routine
    $scriptfile = create_script(
        $tmpfile,      $var,   $sld_file, $smooth, $overlay,
        $bbox,         $width, $height,   $dim,    $longName,
        $standardName, $axis,  $dir,      $outfile
    ) if !( $att_hash->{temporal_resolution} =~ /8-daily/ );

    $scriptfile = render_failed( $tmpfile, $temporal_resolution, $width, $height, $outfile )
        if ( $att_hash->{temporal_resolution} =~ /8-daily/ )
        ;    # Render failed since 8-daily data

    # Run GrADS in batch mode
    my $rc = system("grads -lbc $scriptfile >/dev/null");

    if ( $rc != 0 ) {
        warn "ERROR Failed to create $outfile from $scriptfile with GrADS\n";
        return;
    }
    return ($outfile);
}

sub render_failed {
    my ( $ncfile, $temporal_res, $width, $height, $outfile ) = @_;

    # Script file just appends .gs to output file
    my $script_file = "$outfile.gs";
    open( SCRIPT, '>', $script_file )
        or die "Cannot write to $script_file: $!\n";

    print SCRIPT "'clear'\n";
    print SCRIPT "'set strsiz 0.5'\n";
    print SCRIPT "'set string 1 c 3'\n";
    print SCRIPT "'set hershey off'\n";

    print SCRIPT "'draw string 5 6 Giovanni does not support'\n";
    print SCRIPT "'draw string 5 5 $temporal_res data'\n";
    print SCRIPT "'draw string 5 4 for Hovmoller services.'\n";
    print SCRIPT "'printim $outfile x$width y$height white -t 1'\n";
    print SCRIPT << 'EOF';
'set grid off'
'set grads off'
EOF
    print SCRIPT "'quit'\n";
    close SCRIPT or die "Cannot close $script_file\n";
    return ($script_file);
}

sub create_script {
    my ($ncfile,  $var,         $sld_file,     $smooth,
        $overlay, $boundingBox, $width,        $height,
        $dim,     $longName,    $standardName, $axis,
        $dir,     $outfile
    ) = @_;

    # Script file just appends .gs to output file
    my $script_file = "$outfile.gs";
    open( SCRIPT, '>', $script_file )
        or die "Cannot write to $script_file: $!\n";

    # SLD Color settings
    my $sld = new Giovanni::OGC::SLD( FILE => $sld_file );
    my ( $ra_settings, $fallbackColor ) = $sld->getGrADSColorSettings();
    my $backColorIndex = ( split( " ", $fallbackColor ) )[2];
    my $colorIndexFrom = ( split( " ", @$ra_settings[0] ) )[2];
    my @legendColors = split( " ", @$ra_settings[-2] );
    my @legendValues = split( " ", @$ra_settings[-1] );
    print SCRIPT "'$fallbackColor'\n";
    print SCRIPT "'set background $backColorIndex'\n";
    print SCRIPT "'clear'\n";

    foreach my $setting (@$ra_settings) {
        print SCRIPT "'$setting'\n";
    }
    if ( $dim eq 'lat' ) {
        print SCRIPT "'set display white'\n";
        print SCRIPT "'set background white'\n";
        print SCRIPT "'set ylab on'\n";
        print SCRIPT "'set xlab on'\n";
        print SCRIPT "'set grid off'\n";
        print SCRIPT "'set grads off'\n";
        print SCRIPT "'set gxout shaded'\n";
        print SCRIPT "'set csmooth on'\n";
        print SCRIPT "'set xyrev off'\n";
        print SCRIPT "'set xlopts 1 4 0.14'\n";
        print SCRIPT "'set ylopts 1 4 0.14'\n";
    }
    else {
        print SCRIPT "'set display white'\n";
        print SCRIPT "'set background white'\n";
        print SCRIPT "'set ylab on'\n";
        print SCRIPT "'set xlab on'\n";
        print SCRIPT "'set grid off'\n";
        print SCRIPT "'set grads off'\n";
        print SCRIPT "'set gxout shaded'\n";
        print SCRIPT "'set csmooth on'\n";
        print SCRIPT "'set xyrev on'\n";
        print SCRIPT "'set xlopts 1 4 0.14'\n";
        print SCRIPT "'set ylopts 1 4 0.14'\n";
    }
    print SCRIPT << 'EOF';
'set grid off'
'set grads off'
EOF
    print SCRIPT "'sdfopen $ncfile'\n";
    print SCRIPT "'set t 1 last'\n";
    my $grads_var = lc( substr( $var, 0, 15 ) );
    print SCRIPT "'set parea 2 9.5 1.5 7.5'\n";
    print SCRIPT "'d $grads_var'\n";

    if ($smooth) {
        print SCRIPT "'set gxout shaded'\n";
        print SCRIPT "'set csmooth on'\n" if ( $smooth > 1 );

        # Need to reprint the ccols and clevs statements
        print SCRIPT "'$ra_settings->[-2]'\n";
        print SCRIPT "'$ra_settings->[-1]'\n";

        # Overprint smoothed picture
        print SCRIPT "'d $grads_var'\n";
        print SCRIPT "'cbar'\n";
    }
    my ( $dataMin, $dataMax )
        = Giovanni::Data::NcFile::getDataRange( $ncfile, $var );
    if ( $dataMin == $dataMax ) {
        print SCRIPT "'set ccolor 17'\n";
        print SCRIPT "'d const($grads_var, $dataMin)'\n";
    }

    print SCRIPT "'printim $outfile x$width y$height -t $backColorIndex'\n";
    print SCRIPT "'quit'\n";
    close SCRIPT or die "Cannot close $script_file\n";
    return ($script_file);
}

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::Visualizer::Hovmoller - constructs a map image from netCDF using GrADS

=head1 SYNOPSIS

  use Giovanni::Visualizer::Hovmoller;
  ($imageFile) = gradsMap ( $nc_file, $sld_file, %params );

=head1 DESCRIPTION

=head2 REQUIRED PARAMETERS

=over 4

=item, $ncfile

NetCDF file with CF-compliant coordinates.

=item $sld_file

OGC Style Layer Descriptor file with color palette.

=back

=head2 OPTIONAL PARAMETERS

=over 4

=item OUTFILE

Output image filename.  Defaults to netcdf filename appended with .png.

=item VARIABLE

Variable name to visualize. Defaults to the first variable found.

=item WIDTH

Image width in pixels. Defaults to 563 pixels.

=item HEIGHT

Image height in pixels. Defaults to 461 pixels.

=item DIMENSION

Dimension attribute read from the NetCDF file. For example, the return value is either 'lat' or lon' depending on the type of Hovmoller plot. No default value is provided.

=LNAME

Long name of the dimension provided by the type of Hovmoller plot. Value is either set to 'Latitude' or 'Longitude'. No default value is provided.

=SNAME

Short name of the dimension provided by the type of Hovmoller plot. Value is either set to 'latitude' or 'longitude'. No default value is provided.

=AXIS

Type of coordinate axis used to construct the Hovmoller plot. Value is either set to 'Lat' or 'Lon'. No default value is provided.

=DIR

Type of units in terms of direction. Value is either 'north' or 'east' depending on the type of Hovmoller plot.

=item FORMAT

(Not yet implemented; png only).

=item SMOOTH

How much interpolation and/or smoothing to apply to the image:
 0 = no interpolation or smoothing (gxout grfill)
 1 = spatial interpolation (gxout shaded)
 2 = spatial interpolation and bicubic smoothing (gxout shaded, csmooth on)

=head2 EXPORT

None by default.

=head1 SEE ALSO

Giovanni::OGC::SLD

=head1 AUTHOR

Michael A Nardozzi, E<lt>michael.a.nardozzi@nasa.gov<gt>

=head1 COPYRIGHT AND LICENSE

TBD.

=cut
