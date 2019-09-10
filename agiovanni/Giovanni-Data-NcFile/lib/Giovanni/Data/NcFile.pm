#$Id: NcFile.pm,v 1.131 2015/09/03 14:11:15 rstrub Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::Data::NcFile;

use 5.008008;
use strict;
use warnings;
use XML::LibXML;
use Giovanni::Util;
use File::Temp qw/ tempfile tempdir /;
use Giovanni::BoundingBox;
use Giovanni::Scrubber;    #for getChildrenNodeList
use Giovanni::ScienceCommand;
use File::Copy;
use URI::Escape;
use DateTime;
use Time::Local;
use Scalar::Util qw(looks_like_number);
use vars qw/$AUTOLOAD/;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Data::NcFile ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our $VERSION = '0.01';

# Preloaded methods go here.

use File::Temp qw/ :POSIX /;
use File::Basename;
use Class::Struct;
use File::Copy;

our (%ncml_header);

struct(
    NcAttribute => {
        variable => '$',
        name     => '$',
        ncotype  => '$'
        , # NCO (ncatted) datatype: f=float, d=double, l=long, s=short, c=char, b=byte
        value  => '$',    # ncatted: o=overwrite, d=delete
        action => '$'
    }
);

sub new {
    my ( $class, %arg ) = @_;
    my $self = {};

    # Get the header from the file
    local ($/) = undef;
    $self->{verbose} = $arg{verbose};
    bless( $self, $class );
    init( $self, $arg{NCFILE} );
    $self->{beginepochsecs} = undef;
    $self->{endepochsecs}   = undef;
    $self->{OSstartTime}    = $arg{OSstartTime};
    $self->{OSendTime}      = $arg{OSendTime};

    return $self;
}

sub init {
    my $self       = shift;
    my $file       = shift;
    my $dumphdrcmd = qq(ncdump -x $file);
    my $text       = `$dumphdrcmd`;
    unless ($text) {
        warn "ERROR could not get header from $file\n";
        return;
    }

    # parse the XML.
    my $xpc = XML::LibXML::XPathContext->new(
        XML::LibXML->new()->parse_string($text) );
    $xpc->registerNs(
        nc => 'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );

    my @rootNodes = $xpc->findnodes('/nc:netcdf');
    $self->{rootNode} = $rootNodes[0];

    $self->{xpc}  = $xpc;
    $self->{file} = $file;
    my $type = `ncdump -k $file`;
    chomp($type);
    $self->{format} = $type;

    #netCDF-4 classic model

}

# Delete the global history attribute in a file. If only one file is specified,
# it will be edited in place.
sub delete_history {
    my ( $path1, $path2 ) = @_;
    if ( !defined($path2) ) {
        $path2 = $path1;
    }
    my $cmd = "ncatted -h -O -a history,global,d,, -o $path2 $path1";
    my $ret = system($cmd);
    if ( $ret != 0 ) {
        return 0;
    }
    else {
        return 1;
    }
}

# Use the system "diff" program to compare 2 netCDF files. Automatically
# ignores NCO-specific attributes such as 'history'.
sub diff_netcdf_files {
    my ( $path1, $path2, @exclude ) = @_;

    my $cmd = "diff_nc.py $path1 $path2 -n";
    for my $ex (@exclude) {
        $cmd = "$cmd -i '$ex'";
    }

    my $diff = `$cmd`;
    if ( $? != 0 ) {
        die "Unable to diff $path1, $path2. Command returned non-zero: $cmd.";
    }
    return $diff;
}

# Adds NcAttribute as global attribute
sub edit_netcdf_attributes {
    my ( $infile, $outfile, @attrs ) = @_;
    $outfile ||= $infile;
    my @ncatted_args = ( '-O', '-h' );

    # Produce ncatted args from attributes
    foreach my $attr (@attrs) {
        my $varname = $attr->variable();
        $varname ||= 'global';
        my $arg;
        if ( $attr->action && $attr->action eq 'd' ) {
            $arg = sprintf( '"%s,%s,d,,"', $attr->name, $varname );
        }
        else {

            # Check to make sure we have everything
            foreach my $a (qw(value ncotype)) {
                if ( !$attr->$a ) {
                    warn "ERROR: missing attribute \"$a\" for attribute\n";
                    return 0;
                }
            }
            $arg = sprintf( '"%s,%s,o,%s,%s"',
                $attr->name, $varname, $attr->ncotype, $attr->value );
        }
        push @ncatted_args, '-a', $arg;
    }
    my $cmd = join( ' ', "ncatted", @ncatted_args, $infile, $outfile );

    # Run the command
    my $rc = system($cmd);
    if ( $rc != 0 ) {
        warn("ERROR: failed to run $cmd: $rc\n");
        return 0;
    }
    return 1;
}

sub write_netcdf_file {
    my ( $ncpath, $cdldata ) = @_;

    # Check to make sure we have both a filename and something to write
    unless ($ncpath) {
        warn "ERROR: no output netCDF file specified\n";
        return 0;
    }
    unless ($cdldata) {
        warn "ERROR: no data for netCDF file\n";
        return 0;
    }
    my $cdlpath = "$ncpath.cdl";

    # write to CDL file
    unless ( open( CDLFILE, ">", $cdlpath ) ) {
        warn "ERROR: Cannot open $cdlpath: $!\n";
        return;
    }
    print CDLFILE $cdldata;
    close CDLFILE;

    # Convert CDL file to netCDF
    my $cmd = "ncgen -o $ncpath $cdlpath";

    # TODO:  more robust error handling for system call
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );
    unlink $cdlpath
        or warn "ERROR: Failed to unlink temporary CDL file $cdlpath: $!\n";
    return $ncpath;
}

sub get_format_string_for_variable {
    my ( $infile, $reuse, $variable ) = @_;
    # Lookup variable type
    my $varType = get_variable_type( $infile, $reuse, $variable );
    unless ($varType) {
        warn "ERROR could not find variable $variable in $infile\n";
        return undef;
    }

    # Lookup appropriate output format for that variable type
    my %format = (
        'int'    => '%d',
        'short'  => '%d',
        'float'  => '%g',
        'double' => '%13.9lg'
    );
    return $format{$varType};
}

sub dump_var_1d {
    my ( $infile, $reuse, $variable, $outfile ) = @_;
    my $format = get_format_string_for_variable($infile, $reuse, $variable);
    unless ( $format ) {
        warn "ERROR unsupported variable type in dump_var1d\n";
        return;
    }
    $format = $format . "\\n";

    # Run ncks
    return run_command(
        "ncks -H -C -s '$format' -v $variable $infile > $outfile");
}

sub pixellate {
    my ( $infile, $outfile, $ra_vars, $verbose ) = @_;

    # Figure out which dimensions we need to worry about
    my @dim       = ( "lat",      "lon" );
    my @long_name = ( "Latitude", "Longitude" );
    my @std_name  = ( "latitude", "longitude" );
    my @units     = ( "north",    "east" );
    my @dim_len = dimension_lengths( $infile, 0, @dim );
    my $got_time = grep /time/,
        get_variable_dimensions( $infile, 1, $ra_vars->[0] );

    # Variable attribute that indicates dimension resolution
    my @dim_res_attr = ( "latitude", "longitude" );
    return 1 unless grep { $_ eq 1 } @dim_len;
    my @nco;
    my @ncrename;

    # Set up dimension definitions for all variables
    # N.B.:  Assumes all variables use the same dimensions!
    my ( @new_dims, @old_dims );
    foreach my $i ( 0 .. 1 ) {
        if ( $dim_len[$i] < 2 ) {
            my $new_dim = "new$dim[$i]";
            push @new_dims, $new_dim;
            push @old_dims, $dim[$i];
            push @nco,      sprintf( 'defdim("new%s", 4)', $dim[$i] );
            push @nco,
                sprintf( '*delta%s = %s@%s_resolution * 1./8.',
                $dim[$i], $ra_vars->[0], $dim_res_attr[$i] );
            push @nco,
                sprintf(
                'new%s[$new%s]={%s(0)-3*delta%s, %s(0)-delta%s, %s(0)+delta%s, %s(0)+3*delta%s}',
                map { $dim[$i] } 0 .. 9 );
            push @nco,
                sprintf( '%s@long_name="%s"', $new_dim, $long_name[$i] );
            push @nco,
                sprintf( '%s@standard_name="%s"', $new_dim, $std_name[$i] );
            push @nco,
                sprintf( '%s@units="degrees_%s"', $new_dim, $units[$i] );
            push @ncrename, sprintf( "-d %s,%s", $new_dim, $dim[$i] );
            push @ncrename, sprintf( "-v %s,%s", $new_dim, $dim[$i] );
            $dim[$i] = $new_dim;
        }
        else {
            push @nco,
                sprintf( '%s@standard_name="%s"', $dim[$i], $std_name[$i] );
        }
    }

    # Loop through all the variables to copy data and attributes over
    my @new_vars;
    foreach my $var (@$ra_vars) {
        my $new_var = 'pix' . $var;
        push @new_vars, $var;
        push @nco,
            (
            $got_time
            ? sprintf( '%s[$time,$%s,$%s]=%s(:,:,:)',
                $new_var, $dim[0], $dim[1], $var )
            : sprintf(
                '%s[$%s,$%s]=%s(:,:)',
                $new_var, $dim[0], $dim[1], $var
            )
            );
        my ( $rh_attrs, $ra_attrs )
            = get_variable_attributes( $infile, 1, $var );
        foreach my $attr (@$ra_attrs) {
            if ( $attr eq '_FillValue' ) {
                push @nco,
                    sprintf( '%s.set_miss(%s@_FillValue)', $new_var, $var );
            }
            else {
                push @nco,
                    sprintf( '%s@%s=%s@%s', $new_var, $attr, $var, $attr );
            }
        }
        push @ncrename, "-v $new_var,$var";
    }

    # Run the script
    my $tmpfile = "$outfile.tmp";
    return
        unless (
        run_ncap2( $infile, $tmpfile, "-h -v -O", \@nco, $verbose ) );

    # Delete dimension variables
    # Use -C argument to "force" deletion, regardless of unused remnants in
    # file's dimensions or variable's :coordinates attribute
    return
        unless run_command(
        sprintf(
            "ncks -C -3 -h -x -v %s -O %s %s",
            join( ',', @old_dims ),
            $tmpfile, $tmpfile
        ),
        1
        );

    # Rename pixellated variables
    return
        unless run_command(
        join( ' ', "ncrename -h -O", @ncrename, $tmpfile ), 1 );
    unless ( rename( $tmpfile, $outfile ) ) {
        warn "ERROR renaming $tmpfile to $outfile\n";
        return;
    }
    return 1;
}

sub run_ncap2 {
    my ( $infile, $outfile, $args, $ra_nco, $verbose ) = @_;

# Write args to a script (command line args would not preserve attribute order)
    my $ncofile = "$outfile.nco";
    unless ( open( NCO, ">", $ncofile ) ) {
        warn "ERROR cannot open NCO script file $ncofile\n";
        return;
    }
    foreach my $nco (@$ra_nco) {
        warn "DEBUG: $nco;\n" if ( $verbose > 1 );
        print NCO "$nco;\n";
    }
    close NCO;
    my $cmd = "ncap2 -h -v -S $ncofile -O -o $outfile $infile";
    if ( run_command( $cmd, $verbose ) ) {

        #        unlink $ncofile;
        return 1;
    }
    else {
        return;
    }
}

sub insert_dim_var_for_grads {
    my ( $infile, $outfile, $dimension, $longName, $standardName, $axis, $dir,
        $verbose )
        = @_;

# First we need to get the temporal resolution from the $infile (data file)
# We accomplish this by using ncks. GrADS doesn't work well with monthly data that
# is averaged (another words it doensn't have a standard middle day. As a result
# GrADS produces a plot that has time tics labeled on top of each other.
# So, we don't want to average the time_bnds for data that has greater than
# daily resolution
    my $global_metadata
        = 'Global';    #get the global attributes from NetCDF file
    my $attribute = 'temporal_resolution';    #looking for this attribute
    my $cmd
        = qq(ncks -M -m $infile | grep -E -i "^$global_metadata attribute [0-9]+: $attribute" | cut -f 11- -d ' ' );
    my $temporal_resolution = `$cmd`;
    chomp $temporal_resolution;

# This ncap2 command will average the time for each of the pairs of time_bnds in the data file
# Assign these values to time
    my $cmd1
        = "ncap2 -O -s 'time=ceil( (double(time_bnds(:,0)) + double(time_bnds(:,1)))  /2.0 ) ' $infile $outfile";

# GrADS needs to have a lat or lon dimension to create a plot. So we will insert it here using ncap2.
    my $cmd2
        = "ncap2 -s 'defdim(\"$dimension\",1);'$dimension'['$dimension']=1.0d;'$dimension'\@units=\"degrees_$dir\";'$dimension'\@long_name=\"$longName\";'$dimension'\@standard_name=\"$standardName\";'$dimension'\@_CoordinateAxisType=\"$axis\";' -O $outfile $outfile";

# Same command, but using the infile as input because in this case we don't want to average the time_bnds first
    my $cmd3
        = "ncap2 -s 'defdim(\"$dimension\",1);'$dimension'['$dimension']=1.0d;'$dimension'\@units=\"degrees_$dir\";'$dimension'\@long_name=\"$longName\";'$dimension'\@standard_name=\"$standardName\";'$dimension'\@_CoordinateAxisType=\"$axis\";' -O $infile $outfile";

    if ( $temporal_resolution eq 'monthly' ) {
        print STDERR "\nTemporal resolution of data file 1 is: "
            . $temporal_resolution . "\n\n";
        print STDERR "\nINFO making outfile: " . $outfile . "\n\n";
        run_command( $cmd3, $verbose );
        return $outfile;
    }
    elsif ( defined $temporal_resolution ) {
        print STDERR "\nTemporal resolution of data file is: "
            . $temporal_resolution . "\n\n";
        print STDERR "\nINFO making outfile: " . $outfile . "\n\n";
        run_command( $cmd1, $verbose );
        run_command( $cmd2, $verbose );
        return $outfile;
    }
    else {
        return;
    }
}

sub run_command {
    my ( $cmd, $verbose ) = @_;
    warn "INFO Executing command: $cmd\n" if ($verbose);
    my $rc = system($cmd);
    if ( $rc == 0 ) {
        return 1;
    }
    else {
        $rc >>= 8;
        warn "ERROR on command $cmd: $rc\n";
        return;
    }
}

sub spatial_resolution {
    my ( $file, $latname, $lonname ) = @_;
    $latname ||= "lat";
    $lonname ||= "lon";
    my $outfile = tmpnam();

    # Use -v to limit the contents of the output file
    my $cmd
        = "ncap2 -v -s 'latres=(\$$latname.size>2)?abs($latname(2)-$latname(1)):abs($latname(1)-$latname(0)); lonres=abs($lonname(1)-$lonname(0)); print (latres, \"%f\"); print(lonres, \"%f\")' $file $outfile";

    # Multiply result by 1.0 to ensure floatification of strings
    my ( $latres, $lonres )
        = map { 1.0 * $_ } split( '\s+', `$cmd 2> /dev/null` );

    unlink($outfile);

    if ( $? != 0 ) {
       warn "ERROR $cmd failed. \n";
       warn "ERROR exit value:$? \n";
       warn "ERROR file:<$file> is probably not a netcdf file\n";
       exit(1);
    }

    return ( $latres, $lonres );
}

sub data_bbox {
    my ($file) = @_;
    my $outfile = tmpnam();
    my ( $nco_fh, $nco_name ) = tempfile( 'SUFFIX' => '.nco' );
    print $nco_fh '*nlon=$lon.size-1;' . "\n";
    print $nco_fh '*nlat=$lat.size-1;' . "\n";

    # Handle the case of 2-point coordinates
    # Otherwise, use more interior coords for cases like GoCart
    print $nco_fh
        '*lonres=((nlon<2) ? abs(lon(1)-lon(0)) : abs(lon(2)-lon(1)));'
        . "\n";
    print $nco_fh
        '*latres=((nlat<2) ? abs(lat(1)-lat(0)) : abs(lat(2)-lat(1)));'
        . "\n";

    # Handle either increasing or decreasing latitude...
    print $nco_fh 'if (lat(0) > lat(nlat)) {maxlat=lat(0); minlat=lat(nlat);}'
        . "\n";
    print $nco_fh 'else {minlat=lat(0); maxlat=lat(nlat);}' . "\n";
    print $nco_fh 'minlat -= latres/2.;' . "\n";
    print $nco_fh 'maxlat += latres/2.;' . "\n";

    # ...but nobody ever does decreasing longitude
    print $nco_fh 'minlon=lon(0)-lonres/2.; ' . "\n";
    print $nco_fh 'maxlon=lon(nlon)+lonres/2.; ' . "\n";
    print $nco_fh 'if((maxlon-minlon)>=360.){minlon=-180.; maxlon=180.;}'
        . "\n";
    print $nco_fh 'print(minlon,"%f"); ' . "\n";
    print $nco_fh 'print(minlat,"%f"); ' . "\n";
    print $nco_fh 'print(maxlon,"%f");' . "\n";
    print $nco_fh 'print(maxlat,"%f"); ' . "\n";
    close $nco_fh;
    my (@bbox) = `ncap2 -v -S $nco_name -O -o $outfile $file`;
    unlink( $outfile, $nco_name );

    if ( $? != 0 ) {
        warn "ERROR running NCO script\n";
        return undef;
    }
    map { chomp $_ } @bbox;
    return join( ',', @bbox );
}

sub add_resolution_attributes {
    my ( $file, $latres, $lonres, $varnames_ref ) = @_;

    # by default, add these to all plotable variables
    if ( !defined($varnames_ref) ) {
        $varnames_ref = [ get_plottable_variables($file) ];
    }

    for my $varname (@$varnames_ref) {

        # add the attributes
        my $cmd
            = qq(ncatted -h -a "latitude_resolution,$varname,o,d,$latres" $file);
        die "Failed to run: $cmd" unless ( system($cmd) == 0 );
        $cmd
            = qq(ncatted -h -a "longitude_resolution,$varname,o,d,$lonres" $file);
        die "Failed to run: $cmd" unless ( system($cmd) == 0 );
    }
    return @$varnames_ref;
}

sub get_xml_header {
    my ( $file, $reuse ) = @_;

    # Support ncdump of OPeNDAP URLs as well
    unless ( $file =~ /^http:/ || -e $file ) {
        warn "ERROR cannot find file $file\n";
        return;
    }

    # Can reuse in a static variable for performance
    return $ncml_header{$file}
        if ( $reuse && ( exists $ncml_header{$file} ) );

    # Get the header from the file
    local ($/) = undef;
    my $hdr = `ncdump -x $file`;
    unless ($hdr) {
        warn "ERROR could not get header from $file\n";
        return;
    }

    # parse the XML.
    my $xpc = XML::LibXML::XPathContext->new(
        XML::LibXML->new()->parse_string($hdr) );
    $xpc->registerNs(
        nc => 'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );
    $ncml_header{$file} = $xpc;
    return $xpc;
}

sub get_lat_lon_dimnames {
    my ( $file, $reuse ) = @_;
    my $xpc = get_xml_header( $file, $reuse );
    if ( !( defined($xpc) ) ) {
        return;
    }

    my $lon_dim
        = findUsingStdNameNotBounds( $xpc, 'longitude', 'degrees_east',
        'name' );
    my $lat_dim
        = findUsingStdNameNotBounds( $xpc, 'latitude', 'degrees_north',
        'name' );

    return ( $lat_dim, $lon_dim );
}

# Try and find a dimension name using standard name and it's units/attribute value
sub findUsingStdNameNotBounds {

    my $xpc            = shift;
    my $standardName   = shift;
    my $hasThisAttrVal = shift;
    my $field          = shift;
    my $fnd_dim        = undef;

    my @fnd_nodes
        = $xpc->findnodes(
        qq(/nc:netcdf/nc:variable/nc:attribute[\@value="$standardName"  and \@name="standard_name"]/../\@$field)
        );
    if (@fnd_nodes) {
        $fnd_dim = $fnd_nodes[0]->getValue();
    }
    else {
        @fnd_nodes
            = $xpc->findnodes(
            qq(/nc:netcdf/nc:variable/nc:attribute[\@value="$hasThisAttrVal"]/../\@$field)
            );
        if (@fnd_nodes) {
            $fnd_dim = $fnd_nodes[0]->getValue();
        }
    }
    my @checkIfBounds
        = $xpc->findnodes(
        qq(/nc:netcdf/nc:variable/nc:attribute[\@value="$fnd_dim"  and \@name="bounds"]/../\@$field)
        );
    if (@checkIfBounds) {
        die "$fnd_dim ($standardName, $hasThisAttrVal) is a bounds dimension";
    }
    return $fnd_dim;
}

# get_plottable_variables ($file, $reuse)
#   Obtain a list of the variables that are plottable, as indicated by the
#   presence of a quantity_type attribute.
#   Takes an optional $reuse variable, which will reuse an already-parsed
#   XML version of the header if it has already been parsed for other reasons
#   in this module (stored in a reuse hash, our %ncml_header).)
sub get_plottable_variables {
    my ( $file, $reuse ) = @_;

    my $xpc = get_xml_header( $file, $reuse );
    if ( !( defined($xpc) ) ) {
        return;
    }
    my @nodes
        = $xpc->findnodes(
        qq(/nc:netcdf/nc:variable/nc:attribute[\@name="quantity_type"]/../\@name)
        );
    return map( $_->getValue(), @nodes );
}

# Stitch together two netCDF files by longitude, assuming they are adjacent
# This is used for splitting up calculations on either side of 180 deg, and then
# putting them back together in one file.
sub stitch_lon {
    my ( $verbose, $west_file, $east_file, $outfile ) = @_;

    # Get the first plottable variable, assuming they all have the same dims
    my @vars = get_plottable_variables( $west_file, 0 );

# Get dimensions based on the variable shape (not coordinates attribute, as previously)
    my $coordinates = get_variable_dimensions( $west_file, 1, $vars[0] );
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
    foreach my $file ( $west_file, $east_file ) {

        # Swap dimensions in order to make longitude a record variable
        run_command( "ncpdq -a $lon_first -O -o $file $file", $verbose );

        # Make longitude a record variable
        run_command( "ncks --mk_rec_dmn $lon_dim -O -o $file $file",
            $verbose );
    }

# Add 360 to longitude of east file to make it monotonic
# - 6/5/2013 (#23955)
# - This is no longer needed and is causing problems in interactive map; was
# - needed with static map.
# -  run_command($verbose, "ncap2 -s 'longitude += (360. * (longitude < 0.))' -O -o $east_file $east_file");

    # Cat the files together with ncrcat
    run_command( "ncrcat -O $west_file $east_file $outfile", $verbose );

    # Swap latitude and longitude back
    $coordinates =~ s/ +/,/g;
    run_command( "ncpdq -a $coordinates -O -o $outfile $outfile", $verbose );
    return 1;
}

# Deprecated, different order of arguments from most other routines
sub variable_attributes {
    my ( $file, $variable, $reuse ) = @_;
    return get_variable_attributes( $file, $reuse, $variable );
}

# Returns the type of a variable (int, float, double, ...)
sub get_variable_type {
    my ( $file, $reuse, $variable ) = @_;

    my $xpc = get_xml_header( $file, $reuse ) or return undef;

    # Find the variable node
    my ($varNode)
        = $xpc->findnodes(qq(/nc:netcdf/nc:variable[\@name="$variable"]))
        or return undef;
    my $type = $varNode->getAttribute("type");
    return $type;
}

sub get_variable_attributes {
    my ( $file, $reuse, $variable ) = @_;

    # Get the XML header
    my $xpc = get_xml_header( $file, $reuse );
    return unless ($xpc);

    # get the variable node
    my $variableNode;
    eval {
        if ( $variable eq 'global' )
        {
            print STDERR
                "ERROR: This should no longer occur, global variables are handled elsewhere";
        }
        else {
            ($variableNode)
                = $xpc->findnodes(
                qq(/nc:netcdf/nc:variable[\@name="$variable"]));
        }
    };

    if ($@) {
        $xpc = redump($file);
        ($variableNode)
            = $xpc->findnodes(qq(/nc:netcdf/nc:variable[\@name="$variable"]));
    }

    unless ($variableNode) {
        warn "WARN did not find $variable in $file\n";
        return;
    }

    # pull out the attributes
    my ( %atthash, @attlist );
    for my $node ( $variableNode->getElementsByTagName("attribute") ) {
        my $name = $node->getAttribute("name");
        push( @attlist, $name );
        $atthash{$name} = $node->getAttribute("value");
    }

    # Return the unordered hash with name and value, plus an ordered
    # list of the attribute names
    return ( \%atthash, \@attlist );
}

sub global_attributes {
    my ( $file, $reuse ) = @_;

    # Get the XML header
    my $xpc = get_xml_header( $file, $reuse );
    return unless ($xpc);

    my @attributes;
    eval {

        # This will get ONLY ncdump -x'ed GLOBAL attributes:
        @attributes = $xpc->findnodes('/nc:netcdf/nc:attribute');
    };

    if ($@) {
        warn "ERROR could not get header from $file on the original try\n";
        $xpc = redump($file);
    }

    # populate list and hash:
    my ( %atthash, @attlist );
    foreach (@attributes) {
        my $name = $_->getAttribute('name');
        push( @attlist, $name );
        $atthash{$name} = $_->getAttribute("value");
    }

    # Return the unordered hash with name and value, plus an ordered
    # list of the attribute names
    return ( \%atthash, \@attlist );
}

sub redump {
    my $file       = shift;
    my $dumphdrcmd = qq(ncdump -x $file);
    my $text       = `$dumphdrcmd`;
    unless ($text) {
        warn "ERROR could not get header from $file\n";
        return;
    }

    # parse the XML.
    my $xpc = XML::LibXML::XPathContext->new(
        XML::LibXML->new()->parse_string($text) );
    $xpc->registerNs(
        nc => 'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );

    return $xpc;
}

sub get_variable_dimensions {
    my ( $file, $reuse, $variable ) = @_;
    my $xpc = get_xml_header( $file, $reuse );
    my $shape = $xpc->findvalue(
        qq(/nc:netcdf/nc:variable[\@name="$variable"]/\@shape));
    return ($shape);
}

sub is_climatology {
    my ( $file, $reuse, $variable ) = @_;

    my $time_var = get_variable_time_dimension( $file, $reuse, $variable );
    if ( defined($time_var) ) {
        my ($att_hash) = get_variable_attributes( $file, $reuse, $time_var );
        if ( $att_hash->{"climatology"} ) {
            return 1;
        }
    }
    return 0;
}

sub get_variable_time_dimension {
    my ( $file, $reuse, $variable ) = @_;

    # get the dimensions for this variable
    my $shape = get_variable_dimensions( $file, $reuse, $variable );
    my @dims = split( /\s+/, $shape );

    # get all the variables in this file
    my @all_variables = get_variable_names( $file, $reuse );
    my $var_hash = {};
    for my $var (@all_variables) {
        $var_hash->{$var} = 1;
    }

    # iterate through dimensions and look for time units
    for my $dim (@dims) {

        # check to make sure this dimension has a variable
        if ( $var_hash->{$dim} ) {
            my ($att_hash) = get_variable_attributes( $file, $reuse, $dim );
            my $units = $att_hash->{"units"};

            # seconds since 1970-01-01 00:00:00
            if ( $units =~ /since \d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/ ) {
                return $dim;
            }
        }
    }

    return undef;

}

sub get_variable_names {
    my ( $file, $reuse ) = @_;
    my $xpc = get_xml_header( $file, $reuse );
    my @nodes = $xpc->findnodes(qq(/nc:netcdf/nc:variable/\@name));
    return map( $_->getValue(), @nodes );
}

# No regression tests find time as already being a record dimension.
sub has_time_record_dimension_already {
    my $self    = shift;
    my $xpc     = $self->{xpc};
    my $varDims = shift;

# the algorithm for determining if we have time: FEDGIANNI-2249:
# determine bounds dims (from 'bounds' attr name (CF))
# get data variable: this is the one that has all of the dims in it but the bounds dims.
# if time has been supplied it must be a dataFieldId (measured variable) dim. otherwise fetch will not return it.
# So it must be one of the $varDims. and it will have units including 'since'
    my $units_willbe;
    foreach my $dim (@$varDims) {
        my $stdname
            = $xpc->findnodes(
            qq(/nc:netcdf/nc:variable[\@name="$dim"]/nc:attribute[\@name="standard_name"]/\@value)
            );

        # first do the obligatory, (in 2017) check for correct standard_name
        if ( $stdname and $stdname->[0]->textContent eq "time" ) {
            $self->{time} = $dim;
            last;
        }
        else {
            my $units_value
                = $xpc->findnodes(
                qq(/nc:netcdf/nc:variable[\@name="$dim"]/nc:attribute[\@name="units"]/\@value)
                );
            if (    $units_value
                and $units_value->[0]->textContent =~ / since / )
            {
                $self->{time} = $dim;
                last;
            }
        }
    }
    if ( $self->{time} ) {

        # if we found time, is it a record dim?
        my $dim = $self->{time};
        my $record
            = $xpc->findnodes(qq(/nc:netcdf/nc:dimension[\@name="$dim"]));
        if ( $record->[0]->getAttribute("isUnlimited") ) {
            if ( $record->[0]->getAttribute("isUnlimited") eq "true" ) {
                $self->{unlimited} = $dim;
                return 1;
            }
        }
    }

    # This last case we have not to date (2017) encountered:
    # That is we have a record dim but it is not time.
    my $unlimited
        = $xpc->findnodes(qq(/nc:netcdf/nc:dimension[\@isUnlimited="true"]));
    if ($unlimited) {
        $self->{unlimited} = $unlimited->[0]->getAttribute("name");
    }

    return undef;
}

# This code perhaps should never be needed.
# It used to be in Giovanni::Scrubber::make_record_dimension...
sub removeRecordDimension {
    my $self        = shift;
    my $record      = shift;
    my $workingfile = shift;
    my $parentNode  = $self->{rootNode};

    my $nodeList = $parentNode->getChildrenByTagName('variable');
    my $vnames   = "";
    foreach my $var (@$nodeList) {
        my $name = getAttributeValue( $var, 'name' );
        next if ( $name eq $record );
        $vnames .= "," if ( $vnames ne "" );
        $vnames .= $name;

    }
    my $recordCommand
        = "ncwa -C -h -v $vnames -a $record $workingfile $workingfile.record";
    runNCOCommand( $recordCommand, "Remove 'record:$record  dimension" );
    move_file( "$workingfile.record", $workingfile, $workingfile );
}

# This is now the only way we convert time to record dimension
# 1. If time is a record dimension just return (has not to date)
# 2. remove an arbitrary record dim if exists (has not to date)
# 3. If time exists as an ordinary dim, then use --mk_rec_dmn to convert to record dim
# 4. if time dimension doesn't exist at all use ncecat to create an arbitrary record dim which we will rename to time later.
sub createRecordDim {
    my $self        = shift;
    my $workingfile = $self->{file};
    my $tempfile    = "$workingfile.rec";
    if ( $self->{unlimited} ) {
        if ( $self->{unlimited} eq $self->{time} ) {
            return;    # time have record dimension.
        }
        else {         # remove this extraneous record dim.
                       # This code should never be needed.
            removeRecordDimension( $self, $self->{unlimited}, $workingfile );
        }
    }

    if ( $self->{time} ) {

        # already have time dimension so we want to make IT
        # the record dimension
        my $timedim = $self->{time};
        my $mkRecDimCmd
            = ("ncks -O --mk_rec_dmn $timedim  $workingfile $tempfile");
        runNCOCommand( $mkRecDimCmd, "Make time the record dimension" );
    }
    else {

        # creates a record dimension with name 'record' If we have a
        # time dimension then we want to make time the record dimension as
        # we do just above
        my $catCommand = "ncecat -h -O $workingfile $tempfile";
        runNCOCommand( $catCommand, "Copy source file" );
    }
    if ( !( -e $tempfile ) ) {
        quit( 1, "ERROR failed to find the file -- $tempfile" );
    }
    move_file( $tempfile, $workingfile, $tempfile );
}

sub get_vertical_dim_var {
    my ( $file, $reuse, $variable ) = @_;

    # Confine our search to dimensions for the variable
    my $shape = get_variable_dimensions( $file, $reuse, $variable );

    # Loop through each dimension
    foreach my $dim ( split( ' ', $shape ) ) {

        # Fetch attributes
        my ( $rh_attrs, $ra_attrs )
            = get_variable_attributes( $file, $reuse, $dim );
        if ( exists $rh_attrs->{positive} ) {
            return ( $dim, $rh_attrs );
        }
    }

    # None found, return undef
    return;
}

# get data min/max values
sub getDataRange {
    my ( $dataFileName, $varName ) = @_;

    my @dataFileList
        = ref $dataFileName eq 'ARRAY' ? @$dataFileName : ($dataFileName);
    my $dataFile;
    my ( $globalMin, $globalMax ) = ( undef, undef );
    return ( $globalMin, $globalMax ) unless defined $varName;
    if ( @dataFileList == 1 ) {
        $dataFile = $dataFileList[0];
        my $tmpfile = File::Temp->new();

# min() / max() in NCO does not work properly on dimension variables (https://sourceforge.net/p/nco/bugs/78/)
# gsl_stats_min(), on the other hand, does work on dimension variables, but does not work with fill values and can't handle
# multiple dimensions. So, let's use gsl_stats_min on time/lat/lon and the regulat min on everything else
        my $command = "ncap2 -v -O -o $tmpfile"
            . " -s 'ymin=min($varName * 1.0);ymax=max($varName * 1.0);if(ymin != $varName.get_miss()){ print(ymin);print(ymax);}' $dataFile";
        $command
            = "ncap2 -v -O -o $tmpfile"
            . " -s 'ymin=$varName.gsl_stats_min() * 1.0;ymax=$varName.gsl_stats_max() * 1.0;if(ymin != $varName.get_miss()){ print(ymin);print(ymax);}' $dataFile"
            if ( $varName eq 'time'
            || $varName eq 'lat'
            || $varName eq 'lon' );

        my @commandOutput = `$command`;
        if ($?) {
            print STDERR
                "Failed to get data range for $varName in $dataFile\n";
        }
        else {
            foreach my $str (@commandOutput) {
                if ( $str =~ /ymin/ ) {
                    my @fieldList = split( /\s*=\s*/, $str, 2 );
                    $globalMin = $fieldList[1] if ( @fieldList == 2 );
                    $globalMin =~ s/^\s*|\s*$//g;
                }
                elsif ( $str =~ /ymax/ ) {
                    my @fieldList = split( /\s*=\s*/, $str, 2 );
                    $globalMax = $fieldList[1] if ( @fieldList == 2 );
                    $globalMax =~ s/^\s*|\s*$//g;
                }
            }
        }
        return ( $globalMin, $globalMax );
    }
    my $dataFileString = '';
    foreach $dataFile (@dataFileList) {
        $dataFileString = $dataFileString . $dataFile . " ";
    }
    my $minTmpFile    = File::Temp->new();
    my $command       = "ncra -y min -O $dataFileString $minTmpFile";
    my $commandOutput = system($command);
    if ( $? == -1 ) {
        print STDERR "Failed to get min value for $varName\n";
        return ( $globalMin, $globalMax );
    }
    my $maxTmpFile = File::Temp->new();
    $command       = "ncra -y max -O $dataFileString $maxTmpFile";
    $commandOutput = system($command);
    if ( $? == -1 ) {
        print STDERR "Failed to get max value for $varName\n";
        return ( $globalMin, $globalMax );
    }
    my $fMinTmpFile = File::Temp->new();
    $command = "ncwa -O -a lat,lon -y min $minTmpFile $fMinTmpFile";
    print STDERR "dataRange generateSingleMin $command \n";
    $commandOutput = system($command);
    if ( $? == -1 ) {
        print STDERR "Failed to generate min value for $varName\n";
        return ( $globalMin, $globalMax );
    }
    my $fMaxTmpFile = File::Temp->new();
    $command       = "ncwa -O -a lat,lon -y max $maxTmpFile $fMaxTmpFile";
    $commandOutput = system($command);
    if ( $? == -1 ) {
        print STDERR "Failed to generate max value for $varName\n";
        return ( $globalMin, $globalMax );
    }
    $command       = "ncks -H -C -v $varName $fMinTmpFile";
    $commandOutput = `$command`;
    if ($?) {
        print STDERR "Failed to get min value for $varName\n";
        return ( $globalMin, $globalMax );
    }
    else {
        chomp($commandOutput);
        my @outputString = split( /=/, $commandOutput );
        $globalMin = $outputString[-1];
        $globalMin =~ s/ //g;
    }
    $command       = "ncks -H -C -v $varName $fMaxTmpFile";
    $commandOutput = `$command`;
    if ($?) {
        print STDERR "Failed to get max value for $varName\n";
    }
    else {
        chomp($commandOutput);
        my @outputString = split( /=/, $commandOutput );
        $globalMax = $outputString[-1];
        $globalMax =~ s/ //g;
    }
    return ( $globalMin, $globalMax );
}

# Set the coordinates attribute based on the shape of the variable
sub set_variable_coordinates {
    my ( $infile, $outfile, $reuse, $variable ) = @_;
    my $shape = get_variable_dimensions( $infile, $reuse, $variable );
    unless ($shape) {
        warn "ERROR failed to get shape for $variable from $infile\n";
        return 0;
    }
    my $attr = NcAttribute->new(
        variable => $variable,
        name     => 'coordinates',
        value    => $shape,
        ncotype  => 'c',
        action   => 'o'
    );
    return edit_netcdf_attributes( $infile, $outfile, $attr );
}

sub get_variable_long_name {
    my ( $file, $reuse, $variable ) = @_;
    my $xpc = get_xml_header( $file, $reuse );
    my $long_name
        = $xpc->findvalue(
        qq(/nc:netcdf/nc:variable[\@name="$variable"]/nc:attribute[\@name="long_name"]/\@value)
        );
    return ($long_name);
}

#Returns user-readable label for a variable, ideally the same label user sees in Giovanni variable picker
sub get_variable_ui_name {
    my ( $file, $reuse, $variable ) = @_;
    my $xpc = get_xml_header( $file, $reuse );
    my $ui_name
        = $xpc->findvalue(
        qq(/nc:netcdf/nc:variable[\@name="$variable"]/nc:attribute[\@name="long_name"]/\@value)
        );
    my $product_name
        = $xpc->findvalue(
        qq(/nc:netcdf/nc:variable[\@name="$variable"]/nc:attribute[\@name="product_short_name"]/\@value)
        );
    my $product_version
        = $xpc->findvalue(
        qq(/nc:netcdf/nc:variable[\@name="$variable"]/nc:attribute[\@name="product_version"]/\@value)
        );
    if ( $product_name && $product_name ne '' ) {
        $ui_name = $ui_name . ' (' . $product_name;
        if ( $product_version && $product_version ne '' ) {
            $ui_name = $ui_name . ' ' . $product_version;
        }
        $ui_name = $ui_name . ')';
    }
    return ($ui_name);
}

sub get_dimension_names {
    my ($self)   = @_;
    my $xpc      = $self->{xpc};
    my @dimNodes = $xpc->findnodes(qq(/nc:netcdf/nc:dimension));
    unless (@dimNodes) {
        warn qq(ERROR did not find dimension names in $self->{file}\n);
        return;
    }
    my @dimnames;
    my @dimlengths;

    # Loop through dimension nodes, retrieving the length
    foreach my $dim (@dimNodes) {
        $self->{topdim}{names}{ $dim->getAttribute("name") }
            = $dim->getAttribute("length")
    }
}

# makes a copy of a dimension variable (any variable really)
# in the same file (so that it can be ncdiff'ed) (ncdiff will 
# not subtract dimension variables)
sub copy_dimension_to_another_variable_name {
    my ($self,$var,$newvar,$verbose)   = @_;
    my $cmd = qq(ncap2 -O -F -s '$newvar=$var' $self->{file} $self->{file});
    my $rc = run_command( $cmd, $verbose );
    return $rc ? 1 : 0;
}

sub rename_dimension_and_coordinate_variable_names() {
    my $self        = shift;
    my $workingfile = shift;
    my %dimNameMap;

    $self->get_dimension_names();
    my $xpc = $self->{xpc};
    my ($attrName)
        = findUsingStdNameNotBounds( $xpc, 'latitude', "degrees_north",
        "name" );
    if ( !$attrName ) {
        ($attrName) = find_latitude_node( $xpc, "name" );
        update_attribute( $self, "units", $attrName, "degrees_north" );
    }
    if ( defined $attrName ) {
        $dimNameMap{$attrName}{giovanni_name} = 'lat';
    }

    my ($attrShape) = find_latitude_node( $xpc, "shape" );

    if ( defined $attrShape ) {
        if ( exists $self->{topdim}{names}{$attrShape} ) {

       # then the 'shape' of the coord variable = dimension name so we're good
            $dimNameMap{$attrName}{dimension_name} = $attrShape;
        }
        else {
            warn(
                qq($attrShape}, the shape of the latitude variable does not match any of the top dimension names)
            );
        }
    }
    ($attrName)
        = findUsingStdNameNotBounds( $xpc, 'longitude', "degrees_east",
        "name" );
    if ( !$attrName ) {
        ($attrName) = find_longitude_node( $xpc, "name" );
        update_attribute( $self, "units", $attrName, "degrees_east" );
    }
    if ( defined $attrName ) {
        $dimNameMap{$attrName}{giovanni_name} = 'lon';
    }

    ($attrShape) = find_longitude_node( $xpc, "shape" );
    if ( defined $attrShape ) {
        if ( exists $self->{topdim}{names}{$attrShape} ) {

       # then the 'shape' of the coord variable = dimension name so we're good
            $dimNameMap{$attrName}{dimension_name} = $attrShape;
        }
        else {
            warn(
                qq($attrShape}, the shape of the longitude variable does not match any of the top dimension names)
            );
        }
    }

    # Time to rename dimensions
    if ( keys %dimNameMap ) {
        my $cmd = 'ncrename';
        foreach my $dimName ( keys %dimNameMap ) {

# we want to change not only the variable name, say, longitude to lon but also the
# shape/dim which may have a different name such as columns:
            next
                if (
                $dimName eq $dimNameMap{$dimName}{giovanni_name}
                and ( $dimNameMap{$dimName}{dimension_name} eq
                    $dimNameMap{$dimName}{giovanni_name} )
                );
            if ( $self->{format} eq 'classic' ) {
                $cmd
                    .= qq( -d $dimNameMap{$dimName}{dimension_name},$dimNameMap{$dimName}{giovanni_name} -v $dimName,$dimNameMap{$dimName}{giovanni_name});
            }
            else {

# netCDF-4 classic model doesn't like to rename dims and vars at same time, renaming vars, renames dimensions:
                $cmd .= qq( -v $dimName,$dimNameMap{$dimName}{giovanni_name});
            }
        }
        if ( $cmd ne "ncrename" ) {
            $cmd .= " $workingfile";
            runNCOCommand( "$cmd", "Rename dimensions" );
        }
    }
    return %dimNameMap;
}

# This is just providing for the different possible units
sub find_longitude_node {
    my $xpc  = shift;
    my $name = shift;
    my $node;
    my $fnd_dim = undef;

    my @acceptable
        = ( "degrees_east", "degree_east", "degrees_E", "degree_E" );

    foreach my $okvalue (@acceptable) {
        $fnd_dim
            = findUsingStdNameNotBounds( $xpc, 'longitude', $okvalue, $name );
        if ($fnd_dim) {
            return $fnd_dim;
        }
    }
}

# This is just providing for the different possible units
sub find_latitude_node {
    my $xpc  = shift;
    my $name = shift;
    my $node;
    my @acceptable
        = ( "degrees_north", "degree_north", "degrees_N", "degree_N" );
    foreach my $okvalue (@acceptable) {
        if ( $node
            = findUsingStdNameNotBounds( $xpc, 'latitude', $okvalue, $name ) )
        {
            return $node;
        }
    }
}

sub dimension_lengths {
    my ( $file, $reuse, @dimensions ) = @_;
    my $xpc = get_xml_header( $file, $reuse );
    my @lengths;

    # Loop through dimension nodes, retrieving the length
    foreach my $dim (@dimensions) {
        my ($dimNode)
            = $xpc->findnodes(qq(/nc:netcdf/nc:dimension[\@name="$dim"]));
        unless ($dimNode) {
            warn "ERROR did not find dimension $dim in $file\n";
            return;
        }
        my $length = $dimNode->getAttribute("length");
        push @lengths, int($length);
    }
    return @lengths;
}

sub make_monotonic_longitude {
    my ( $infile, $outfile, $verbose ) = @_;

    # First determine whether longitude is monotonically increasing
    my $lon_str = `ncks -s "%f " -H -C -v lon $infile`;

    # By default, assume it is monotonically increasin
    my $monotonicFlag = 1;
    my $prevLon;
MONOTONIC_LON: foreach my $lon ( split( /\s+/, $lon_str ) ) {
        if ( defined $prevLon ) {
            if ( $lon < $prevLon ) {

                # If the lon decreases, flag it
                $monotonicFlag = 0;
                last MONOTONIC_LON;
            }
        }
        else {
            $prevLon = $lon;
        }
    }

    if ($monotonicFlag) {
        return copy( $infile, $outfile ) if defined $outfile;
        return 1;
    }
    my $cleanup = exists $ENV{CLEANUP} ? ( $ENV{CLEANUP} ? 1 : 0 ) : 1;
    my $cmd;
    my $tmpfile
        = defined $outfile ? undef : File::Temp::tmpnam( UNLINK => $cleanup );
    if ( defined $outfile ) {
        $cmd = qq(ncap2 -O -s "where(lon<0)lon=lon+360." $infile $outfile);
    }
    else {
        $cmd = qq(ncap2 -O -s "where(lon<0)lon=lon+360." $infile $tmpfile);
    }
    my $rc = run_command( $cmd, $verbose );
    $rc = copy( $tmpfile, $infile ) if defined $tmpfile;
    return $rc ? 1 : 0;
}

# =================================================================================================
# get_time_bounds() - Get time_bnds from an nc file
# Inputs:
#   $file - Input nc file
# Return:
#   [] - Array ref of time_bnds data (one-dimensional)
# Algorithm:
#   The time bounds values are obtained by trying several things in following order:
#   (1) Reads time_bnds variable in file
#   (2) Construct values from the global start/end time attributes (single time point only)
#   (3) Return undef when none of above succeeds
#   (TBD) one other important algorithm we want to implement is to construct time bounds from time
#       values with temporal resolution and so on (we are not in the position to implement it
#       right now)
# =================================================================================================
sub get_time_bounds {
    my ($file) = @_;
    return undef unless -s $file;

    # Initialize time bounds array
    my $time_bnds = [];

    # Try to get time bounds from time_bnds variable
    if (does_variable_exist(undef,"time_bnds",$file)) {

        # We found the time bounds variable
        my @tb_dump = `ncks -H -C -v time_bnds $file`;
        chomp(@tb_dump);
        pop(@tb_dump) if $tb_dump[-1] eq '';
        foreach my $tb (@tb_dump) {
            my ($v) = ( $tb =~ /^.+\s*=\s*([0-9\.]+)\s*$/ );
            push( @$time_bnds, $v );
        }
        return $time_bnds;
    }

    # Try to get time bounds from start/end attribute for single time point
    # Make sure it's single time point
    my @time_dump = `ncks -H -C -v time $file`;

    # Remove all starting and trailing white spaces
    @time_dump = map {
        my ($item) = $_;
        $item =~ s/[^=]+=(.+)/$1/;
        $item =~ s/^\s+|\s+$//g;
        $item
    } @time_dump;
    pop(@time_dump) if $time_dump[-1] eq '';
    if ( @time_dump > 1 ) {
        my $delta_t  = $time_dump[1] - $time_dump[0];
        my $num_time = scalar(@time_dump);
        for ( my $i = 0; $i < $num_time; $i++ ) {
            my $start_t_secs = $time_dump[$i];
            my $end_t_secs
                = ( $i == ( $num_time - 1 ) )
                ? ( $start_t_secs + $delta_t )
                : $time_dump[ $i + 1 ];
            push( @$time_bnds, ( $start_t_secs, $end_t_secs ) );
        }
        return $time_bnds;
    }
    elsif ( scalar(@time_dump) == 1 ) {

        # Getting time bounds from start/end times
        my $start_t_dump = `ncks -M $file |grep start_time`;
        my $end_t_dump   = `ncks -M $file |grep end_time`;
        chomp($start_t_dump);
        chomp($end_t_dump);
        my ($start_t) = ( $start_t_dump =~ /value\s*=\s*(\d\d\d\d-.+Z)/ );
        my ($end_t)   = ( $end_t_dump   =~ /value\s*=\s*(\d\d\d\d-.+Z)/ );

   # Converting to seconds, nothing is more reliable than the old date command
        $start_t =~ s/T|Z/ /g;
        $end_t   =~ s/T|Z/ /g;
        my $start_t_secs = `date -d \"$start_t\" +%s`;
        my $end_t_secs   = `date -d \"$end_t\" +%s`;
        chomp($start_t_secs);
        chomp($end_t_secs);
        push( @$time_bnds, ( $start_t_secs, $end_t_secs ) );
        return $time_bnds;
    }
    else {
        print STDERR
            "WARN get_time_bnds(): unable to get time bounds from start/end times\n";
    }
    print STDERR "WARN get_time_bnds(): unable to get time bounds\n";
    return undef;
}

# ==============================================================
# set_time_bounds() - Set time_bnds in an nc file
# Inputs:
#   $file      - NC file where time_bnds will be set
#   $time_bnds - One-dimenaional array ref of time bounds values
# Return:
#   1 (success) or undef (fail)
# ==============================================================
sub set_time_bounds {
    my ( $file, $time_bnds ) = @_;

    # Time bounds are in pairs
    my $n = scalar(@$time_bnds);
    my $m = $n / 2;

    # Must be in pairs
    unless ( $n > 0 and $n % 2 == 0 ) {
        print STDERR "WARN: set_time_bounds() Cannot set (invalid values)\n";
        return 0;
    }

    # === Creating new time bounds ===
    # Make sure time_bnds doesn't exist
    if (does_variable_exist(undef,"time_bnds",$file)) {
        warn "WARN: set_time_bounds() Time bounds already exists.\n";
        return 0;
    }

    # Create time bounds
    my $nco_file = "$file.nco";
    if ( !open( NCO, '>', $nco_file ) ) {
        warn "ERROR Failed to open nco script file $nco_file: $!\n";
        exit(3);
    }

    # write time bounds to an NCO script
    print NCO "defdim(\"bnds\",2);\ntime_bnds[time,bnds]={";
    print NCO join( ",\n", @$time_bnds );
    print NCO "\n};\n";
    close NCO;
    `ncap2 -O -h -S $nco_file $file $file.tmp`;
    die("ERROR Fail to set time_bnds \n") if $?;
    `ncatted -a bounds,time,o,c,time_bnds $file.tmp`;
    die("ERROR Failed to set bounds attribute for time") if $?;
    rename( "$file.tmp", $file );
    return 1;
}

sub get_variable_values {
    my ( $file, $variable, @dims ) = @_;

    #figure out the type of the variable
    my $type = get_variable_type( $file, 0, $variable );
    my $printString = '%13.9f';
    if ( $type eq 'int' || $type eq 'long' ) {
        $printString = '%d';
    }

    # setup the command to get data values out.
    my $cmd = "ncks -s '$printString\\n' -C -H ";
    for my $dim (@dims) {
        $cmd = $cmd . "-d $dim,0, ";
    }
    $cmd = $cmd . "-v $variable $file";

    my @out = `$cmd`;
    my $ret = $? >> 8;
    if ( $ret != 0 ) {
        return undef;
    }

    # remove the trailing '\n'
    chomp(@out);

    # remove trailing empty lines
    pop(@out) until $out[-1];
    return @out;
}

sub get_ncdf_version {
    my ($file) = @_;

    my $cmd = "ncdump -k $file";
    my @out = `$cmd`;
    my $ret = $? >> 8;
    if ( $ret != 0 ) {
        print STDERR "ERROR Command returned $ret: $cmd\n";
        return undef;
    }

    my $type = $out[0];
    Giovanni::Util::trim($type);
    if ( $type =~ m/netCDF-4/ ) {
        return 4;
    }
    elsif ( $type eq "classic" || $type eq '64-bit offset' ) {
        return 3;
    }
    else {
        return undef;    # don't know!
    }
}

sub to_netCDF4_classic {
    my ( $inputFile, $outputFile, $compressionLevel ) = @_;
    if ( !defined($compressionLevel) ) {
        $compressionLevel = 1;
    }
    my $cmd
        = "ncks --fl_fmt=netcdf4_classic -L $compressionLevel $inputFile $outputFile";

    my $ret = system($cmd);
    if ( $ret != 0 ) {
        $ret = $ret >> 8;
        print STDERR "ERROR Commad returned $ret: $cmd\n";
        return 0;
    }
    return 1;
}

sub to_netCDF3 {
    my ( $inputFile, $outputFile ) = @_;

    my $cmd = "nccopy -k 'classic' $inputFile $outputFile";
    my $ret = system($cmd);
    if ( $ret != 0 ) {
        $ret = $ret >> 8;
        print STDERR "ERROR Commad returned $ret: $cmd\n";
        return 0;
    }
    return 1;
}

sub read_cdl_data_block {

    # read block at __DATA__
    no warnings qw(once);
    local ($/) = undef;
    my $cdldata = <main::DATA>;

    # Each separate CDL is returned as an element in the array
    my @cdl = ( $cdldata =~ m/(netcdf .*?\}\n)/gs );
    return \@cdl;
}

sub is_a_point {

   my $bbox = shift;
   if ($bbox) { 
       if ($bbox->west() == $bbox->east() and
           $bbox->south() == $bbox->north()) {
           return 1;
       }
   }
 return 0;
}
 
sub subset_and_norm_longitude {
    my ( $inFileRef, $outFileRef, $bboxStr, $longitudeVariable,
        $latitudeVariable )
        = @_;

    if ( !defined($longitudeVariable) ) {
        $longitudeVariable = "lon";
    }
    if ( !defined($latitudeVariable) ) {
        $latitudeVariable = "lat";
    }

    # figure out the begining of the ncks subset command
    my $bbox = Giovanni::BoundingBox->new( STRING => $bboxStr );

    # we want to make sure these are interpreted as floating point values
    # rather than indexes, so print them with a '.' in them.
    my $west  = Giovanni::Util::trim( sprintf( "%13.9f", $bbox->west() ) );
    my $south = Giovanni::Util::trim( sprintf( "%13.9f", $bbox->south() ) );
    my $east  = Giovanni::Util::trim( sprintf( "%13.9f", $bbox->east() ) );
    my $north = Giovanni::Util::trim( sprintf( "%13.9f", $bbox->north() ) );
    my $subsetBaseCmd = "ncks -h -d $longitudeVariable,$west,$east"
        . " -d $latitudeVariable,$south,$north";

    if ( $bbox->crosses180() ) {

        # we are crossing the 180 merridian. So, first subset to
        # some temp files
        my $dir       = tempdir();
        my @tempFiles = ();
        for ( my $i = 0; $i < scalar( @{$inFileRef} ); $i++ ) {
            my $outfile = "$dir/$i.nc";
            push( @tempFiles, $outfile );

            my $cmd = "$subsetBaseCmd " . $inFileRef->[$i] . " " . $outfile;
            my $ret = system($cmd);
            if ( $ret != 0 ) {
                warn("ERROR Unable to subset file: $cmd");
                return undef;
            }
        }

        # now fix the longitude dimension
        my @longitudes
            = get_variable_values( $tempFiles[0], $longitudeVariable,
            $longitudeVariable );
        my $resolution = $longitudes[1] - $longitudes[0];

        # figure out where the discontinuity is
        my $startChangeInd = -1;
        for ( my $i = 1; $i < scalar(@longitudes); $i++ ) {
            if ( $longitudes[ $i - 1 ] + $resolution != $longitudes[$i] ) {
                $startChangeInd = $i;
            }
        }

        if ( $startChangeInd < 0 ) {

            # the subset must have not actually gotten points on both
            # sides of the merridian. E.g. - the east edge was -179.95
            # and the grid center points were -179.5, -178.5, etc. So just
            # copy the files over
            for ( my $i = 0; $i < scalar(@tempFiles); $i++ ) {
                copy( $tempFiles[$i], $outFileRef->[$i] );
            }

        }
        else {

            # run ncap2 to make the negative longitudes positive
            my $endChangeInd = scalar(@longitudes) - 1;

            my $ncap2cmd
                = "$longitudeVariable($startChangeInd:$endChangeInd:1)="
                . "$longitudeVariable($startChangeInd:$endChangeInd:1)+360;";

            for ( my $i = 0; $i < scalar(@tempFiles); $i++ ) {
                my $inFile  = $tempFiles[$i];
                my $outFile = $outFileRef->[$i];
                my $cmd     = "ncap2 -h -O -s '$ncap2cmd' $inFile $outFile";

                my $ret = system($cmd);
                if ( $ret != 0 ) {
                    warn("ERROR Unable to run ncap2 command: $cmd");
                    return undef;
                }
            }
        }

    }
    else {

        # not crossing the 180 merridian, so we can just ncks
        for ( my $i = 0; $i < scalar( @{$inFileRef} ); $i++ ) {
            my $cmd
                = "$subsetBaseCmd "
                . $inFileRef->[$i] . " "
                . $outFileRef->[$i];
            my $ret = system($cmd);
            if ( $ret != 0 ) {
                warn("ERROR Unable to subset file: $cmd");
                return undef;
            }
        }
    }

    return @{$outFileRef};
}

sub rotate_longitude {
    my ( $inFileRef, $outFileRef, $startLongitude, $longitudeVariable ) = @_;

    if ( !defined($longitudeVariable) ) {
        $longitudeVariable = "lon";
    }

    # get longitudes out of first file
    my $firstFile  = $inFileRef->[0];
    my @longitudes = Giovanni::Data::NcFile::get_variable_values( $firstFile,
        $longitudeVariable, $longitudeVariable );
    my $maxLongitudeInd = scalar(@longitudes) - 1;

    # if there's only one longitude, there's no need to rotate.
    if ( scalar(@longitudes) < 2 ) {
        return @{$inFileRef};
    }

    # make sure this file goes from -180 to 180. If it doesn't, we don't
    # need to rotate anything.
    my $resolution = $longitudes[1] - $longitudes[0];
    if (   $longitudes[0] - $resolution > -180
        || $longitudes[-1] + $resolution < 180 )
    {
        return @{$inFileRef};
    }

    # figure out where we are going to rotate
    my $westEdgeInd = 0;
    for ( my $i = 1; $i < scalar(@longitudes) && $westEdgeInd == 0; $i++ ) {
        if (   $longitudes[ $i - 1 ] < $startLongitude
            && $longitudes[$i] >= $startLongitude )
        {
            $westEdgeInd = $i;
        }
    }

    if ( $westEdgeInd == 0 ) {

        # no need to rotate anything
        return @{$inFileRef};
    }

    # create an temporary file for the ncap2 script file
    my ( $fh, $tempfile ) = tempfile()
        or die "Unable to create temporary file";

    # dump the headers so we can figure out which variables have longitude
    my $xpc       = get_xml_header($firstFile);
    my @variables = map( $_->getValue(),
        $xpc->findnodes("/nc:netcdf/nc:variable/\@name") );
    my @shapes = map( $_->getValue(),
        $xpc->findnodes("/nc:netcdf/nc:variable/\@shape") );

    # write the script
    for ( my $i = 0; $i < scalar(@variables); $i++ ) {

        # check to see if this variable has a longitude and needs to be
        # updated
        if ( $shapes[$i] =~ /$longitudeVariable/ ) {

            # first create a temporary copy of this variable
            my $varName  = $variables[$i];
            my $tempName = "temp_" . $varName;
            print $fh "*$tempName=$varName;\n";

            # Figure out the shift. Suppose our west edge is 100 and the last
            # longitude index is 143. We're going to create two commands:
            # var(0:143-100:1)=temp_var(100:143:1);
            # var(143-100+1:143:1)=temp_var(0:100-1:1);

            my $firstLeftIndString  = "0:$maxLongitudeInd-$westEdgeInd:1";
            my $firstRightIndString = "$westEdgeInd:$maxLongitudeInd:1";
            my $secondLeftIndString
                = "$maxLongitudeInd-$westEdgeInd+1:$maxLongitudeInd:1";
            my $secondRightIndString = "0:$westEdgeInd-1:1";

            # Create a template for the hyperslab with a '\a' in the
            # location of longitude dimension indexes
            my $template = $shapes[$i];
            Giovanni::Util::trim($template);

            # replace the longitude dimension with \a, which is a convenient
            # non-printable character
            $template =~ s/$longitudeVariable/\a/;

            # replace white spaces between dimensions with commas
            $template =~ s/\s+/,/g;

            # replace the non-longitude dimensions with a colon
            $template =~ s/\w+/:/g;

            # create the first command
            my $leftString = "$varName($template)";
            $leftString =~ s/\a/$firstLeftIndString/;
            my $rightString = "$tempName($template)";
            $rightString =~ s/\a/$firstRightIndString/;

            print $fh "$leftString=$rightString;\n";

            # and the second command
            $leftString = "$varName($template)";
            $leftString =~ s/\a/$secondLeftIndString/;
            $rightString = "$tempName($template)";
            $rightString =~ s/\a/$secondRightIndString/;

            if ( $varName eq $longitudeVariable ) {
                print $fh "$leftString=$rightString+360;\n";
            }
            else {
                print $fh "$leftString=$rightString;\n";
            }

        }

    }
    close($fh);

    # execute the script for each input and output file
    my $baseCmd = "ncap2 -O -S $tempfile";
    for ( my $i = 0; $i < scalar( @{$inFileRef} ); $i++ ) {
        my $cmd = "$baseCmd " . $inFileRef->[$i] . " " . $outFileRef->[$i];
        print STDERR "INFO About to run command: $cmd\n";
        my $ret = system($cmd);
        if ( $ret != 0 ) {
            return undef;
        }
    }

    return @{$outFileRef};
}

# The purpose of this subroutine is to make sure that the last two coordinates
# in the main variable are lat, lon. In that order.
# Originally I returned this with lat being the last dimension but later
# noticed that most of the granules ended with lon and not lat so I switched it.
sub find_dims_with_latlon {
    my ( $inputfile, $xpc );
    if ( ref( $_[0] ) eq 'Giovanni::Data::NcFile' ) {
        my $self = $_[0];
        $inputfile = $self->{file};
        $xpc       = $self->{xpc};
    }
    else {
        $inputfile = shift;
        $xpc       = shift;
    }
    my @dims = get_lat_lon_dimnames( $inputfile, $xpc );
    my @var_nodes = $xpc->findnodes(qq(/nc:netcdf/nc:variable));

    #displaynodes(\@a,"name");
    my $coords = get_coordinate_names( \@var_nodes );

    my %hash;
    my @ordered = @$coords;

    $hash{org} = $coords;

    # Now order them
    if ( $#$coords >= 2 )
    {    # not needed if only 2 items, as all are lat or lon
        my $i = 0;
        foreach (@ordered) {

            # do latitude
            if ( $dims[0] eq $_ ) {
                @ordered
                    = exchange_dim_pos( \@ordered, $dims[0], $#ordered - 1 )
                    ;    #put it next-to-last
                last;
            }
            ++$i;
        }
        $i = 0;
        foreach (@ordered) {

            # do longitude
            if ( $dims[1] eq $_ ) {
                @ordered = exchange_dim_pos( \@ordered, $dims[1], $#ordered )
                    ;    # put it last
                last;
            }
            ++$i;
        }
    }
    $hash{ordered} = \@ordered;
    return \%hash;
}

sub exchange_dim_pos {
    my $coords    = shift;
    my $fieldname = shift;
    my $needsToBe = shift;
    my $whereItIsCurrently;

    my $originallyThere = $coords->[$needsToBe];

    foreach ( my $i = 0; $i <= $#$coords; ++$i ) {
        if ( $coords->[$i] eq $fieldname ) {
            $whereItIsCurrently = $i;
            last;
        }
    }

    # Now exchange_dim_pos
    $coords->[$needsToBe]          = $fieldname;
    $coords->[$whereItIsCurrently] = $originallyThere;
    return @$coords;

}

# find_dims_with_varname

# inputs xpath obj
#        dimension name
#        new position for dimension name

sub find_dims_with_varname {
    my $xpc     = shift;
    my $varname = shift;
    my $pos     = shift;
    my $infile  = shift;

    if ( !$xpc ) {
        $xpc = Giovanni::Data::NcFile::get_xml_header($infile);
    }

    my @a;
    my @var_nodes = $xpc->findnodes(qq(/nc:netcdf/nc:variable));
    my $coords    = get_coordinate_names( \@var_nodes );

    my %hash;
    my @ordered = @$coords;

    $hash{org} = $coords;

    # Now order them
    my $i = 0;
    foreach (@ordered) {

        # do latitude
        if ( $varname eq $_ ) {
            @ordered = exchange_dim_pos( \@ordered, $varname, $pos )
                ;    #put it next-to-last
            last;
        }
        ++$i;
    }

    $hash{ordered} = \@ordered;
    return \%hash;
}

# get_coordinate_names

# This returns all of the coordinates.  The quality of coordinates is that their shape attr = name attr
# But it didn't return them in order (if they have been changed).
# So we needed to add the second bit to get it from here instead:
# <variable name="AIRX3STD_006_Temperature_A" shape="TempPrsLvls_A time lat lon" type="float">

sub get_coordinate_names {
    my $varNodeList = shift;
    my @coords;
    my $name;
    my $shape;
    my @newcoords;

    my $i = 0;
    foreach (@$varNodeList) {
        $name  = $_->getAttribute("name");
        $shape = $_->getAttribute("shape");
        if ( $name eq $shape ) {
            push @coords, $name;
        }
        ++$i;
    }

    # The second bit:
    foreach (@$varNodeList) {
        $name  = $_->getAttribute("name");
        $shape = $_->getAttribute("shape");
        my $found = 0;
        for ( my $i = 0; $i < $#coords; ++$i ) {
            if ( $shape =~ /$coords[$i]/ ) {
                ++$found;
            }
        }
        if ( $found == $#coords ) {
            @newcoords = split( /\s/, $shape );
            last;
        }
    }

    return \@newcoords;
}

# get_nondim_variable_names

# inputs: varnodelist gotten from xpath
# returns: @array of variable names whose shape attribute != name attribute

# referenced by sub unpack_nondim_variables

sub get_nondim_variable_names {
    my $varNodeList = shift;
    my @vars;
    my $name;
    my $shape;

    my $i = 0;
    foreach (@$varNodeList) {
        $name  = $_->getAttribute("name");
        $shape = $_->getAttribute("shape");
        if ( $name ne $shape ) {
            push @vars, $name;
        }
        ++$i;
    }

    return @vars;
}

# unpack_nondim_variables
# inputs:  infile verbose
# returns: none
# referenced by ncScrubber.pl
# unpacks all variables in the file that aren't dimensions

sub unpack_nondim_variables {
    my $infile  = shift;
    my $verbose = shift;
    my $reuse   = shift;

    my $xpc = Giovanni::Data::NcFile::get_xml_header( $infile, $reuse );
    my @var_nodes = $xpc->findnodes(qq(/nc:netcdf/nc:variable));
    my @nondim_vars = get_nondim_variable_names( \@var_nodes );
    foreach my $variable (@nondim_vars) {

# The problem with this command including variable is that it doesn't include other nondim variables such as dataday
# so when it comes around for the second pass, the second variable, dataday perhaps, is not there...
        my $cmd = qq(ncpdq  -U -O -h -v $variable $infile $infile);
        my $rc_status = Giovanni::Data::NcFile::run_command( $cmd, $verbose );
        if ( $rc_status != 1 ) {
            return 1;
        }
    }
    return 0;
}

sub unpack_all_nondim_variables {
    my $self    = shift;
    my $infile  = $self->{file};
    my $verbose = $self->{verbose};

    my $cmd = qq(ncpdq -U -O -h   $infile $infile);
    my $rc_status = Giovanni::Data::NcFile::run_command( $cmd, $verbose );
    if ( $rc_status != 1 ) {
        return 1;
    }

    return 0;
}

# find_variables_with_latlon

# This is similar code  to FindDimsThatIncludeLatLon
# I say variables for the case of vector data where this is a u an v component.

sub find_variables_with_latlon {
    my ( $xpc, $coords, $infile );
    if ( ref( $_[0] ) eq 'Giovanni::Data::NcFile' ) {
        my $self = $_[0];
        $xpc    = $self->{xpc};
        $infile = $self->{file};
        my $ref = $self->find_dims_with_latlon();
        $coords = $ref->{org} if exists $ref->{org};
    }
    else {
        $xpc    = shift;
        $coords = shift;
        $infile = shift;
    }

    my @var_nodes;
    my $found = undef;
    my @variables;
    if ( !$xpc ) {
        $xpc = Giovanni::Data::NcFile::get_xml_header($infile);
    }

    if ( !$coords ) {
        $coords = find_dims_with_latlon();
    }
    else {

        # if we have $coords we only need @var_nodes
        @var_nodes = $xpc->findnodes(qq(/nc:netcdf/nc:variable));
    }

    foreach (@var_nodes) {
        my $shapeValue = $_->getAttribute('shape');
        foreach my $coord ( @{$coords} ) {
            if ( $shapeValue !~ /$coord/ ) {
                ;
                $found = undef;
                last;
            }
            else {
                $found = 1;
            }
        }
        if ($found) {
            push @variables, $_->getAttribute('name');
            $found = undef;
        }
    }

    return @variables;
}

# find_variable_with_varname

# inputs xpath, coordinates from find_dims_with_latlon()
# returns single variable name

sub find_variable_with_varname {
    my $xpc    = shift;
    my $coords = shift;
    my $infile = shift;    # optional
    my @var_nodes;
    my $found = undef;

    if ( !$xpc ) {
        $xpc = Giovanni::Data::NcFile::get_xml_header($infile);
    }
    if ( !$coords ) {
        $coords = find_dims_with_varname( $xpc, $coords );
    }
    else {

        # if we have $coords we only need @var_nodes
        @var_nodes = $xpc->findnodes(qq(/nc:netcdf/nc:variable));
    }

    foreach (@var_nodes) {
        my $shapeValue = $_->getAttribute('shape');
        foreach my $coord ( @{$coords} ) {
            if ( $shapeValue !~ /$coord/ ) {
                ;
                $found = undef;
                last;
            }
            else {
                $found = 1;
            }
        }
        return $_->getAttribute('name') if $found;
    }

}

# does_variable_exist

#  inputs xpath, coordinates from find_dims_with_latlon()
#  returns single variable name

sub does_variable_exist {
    my $xpc     = shift;
    my $varname = shift;
    my $infile  = shift;    # optional
    my $found   = undef;

    if ( !$xpc ) {
        $xpc = Giovanni::Data::NcFile::get_xml_header($infile);
    }
    my @var_nodes = $xpc->findnodes(qq(/nc:netcdf/nc:variable));

    foreach (@var_nodes) {
        my $thisvar = $_->getAttribute('name');
        if ( $thisvar eq $varname ) {
            return 1;
        }
    }

    return undef;
}

sub get_time_bnds_name {
    my $self          = shift;
    my $timeDimension = shift;
    my $type          = "timebnds";
    my $value
        = does_variable_attribute_exist( $self, $timeDimension, "bounds" );
    if ( !$value ) {
        $value = does_variable_attribute_exist( $self, $timeDimension,
            "climatology" );
        if ($value) {
            $type = "climatologybnds";
        }
        else {
            $value = "";
            $type  = "";
        }
    }
    return $value, $type;
}

# supports update of units variable in ncScrubber.pl
sub does_variable_attribute_exist {
    my $self     = shift;
    my $varname  = shift;
    my $attrname = shift;
    my $xpc      = $self->{xpc};

    my @varnodes
        = $xpc->findnodes(qq(/nc:netcdf/nc:variable[\@name="$varname"]));
    if ( $#varnodes >= 0 ) {
        my @attrnodes = $varnodes[0]->getElementsByTagName("attribute");
        foreach (@attrnodes) {
            if ( $_->getAttribute('name') eq $attrname ) {
                return $_->getAttribute('value');
            }
        }
    }

    return undef;
}

# reorder_latlon_dimensions

# The purpose of this subroutine is to make sure that the last two coordinates
# in the main variable are lat, lon. In that order.
# This is called from ncScrubber
# It uses ncpdq to reorder the dimensions and then edit_netcdf_attributes to
# re-order the coordinates attribute of that variable.
# If the user knows the variable name already and the order of the dimensions already then
# a string and an array may be passed.

sub reorder_latlon_dimensions {
    my $self         = shift;
    my $verbose      = $self->{verbose};
    my $infile       = $self->{file};
    my $variable_ref = shift;
    my $dims         = shift;
    my $reuse        = shift;
    my @variables;

    if ($variable_ref) {
        @variables = @$variable_ref;
    }

    my $status = 1;
    my @attrs;
    my $dimstr;
    my $rc_status = 0;
    if ($dims) {    # calling function  provided dims
        $dimstr = join( ',', @{$dims} );
    }
    else {
        my $coords = find_dims_with_latlon( $self->{file}, $self->{xpc} );
        $dimstr = join( ',', @{ $coords->{ordered} } );
        my $cmpdimstr = join( ',', @{ $coords->{org} } );
        if ( $dimstr eq $cmpdimstr ) {

            # no re-ordering is necessary
            warn
                "No reordering of dimensions was necessary <$dimstr> == <$cmpdimstr>";
            $rc_status = 1;
        }
        if ( !@variables ) {
            @variables
                = find_variables_with_latlon( $self->{xpc}, $coords->{org} );
            if ( !@variables ) {
                warn
                    qq(Could not find a variable with this coords: $coords->{org})
                    if $verbose;
                return 3;
            }
        }
    }

    if ( $rc_status == 0 ) {
        my $cmd = qq(ncpdq -O -a $dimstr $infile $infile);

        # run_command returns 1 if success...
        $rc_status = Giovanni::Data::NcFile::run_command( $cmd, $verbose );
    }

    # update coordinates attribute:
    if ( $rc_status == 1 ) {
        $dimstr =~ s/,/ /g;
        foreach my $var (@variables) {
            push @attrs,
                NcAttribute->new(
                'variable' => $var,
                name       => 'coordinates',
                'value'    => $dimstr,
                'ncotype'  => 'c',
                'action'   => 'o'
                );
            $rc_status = edit_netcdf_attributes( $infile, $infile, @attrs );
            @attrs = ();
        }
    }

    return 0 if ( $rc_status == 1 );

    return 1;
}

# reorder_dimension

# This is not used yet but has been tested.
# It is intended to be an extension of reorder_latlon_dimension() which
# only reorders variables with lat and lon in them
# It uses ncpdq to reorder the dimensions and then edit_netcdf_attributes to
# re-order the coordinates attribute of that variable.

# If the user knows the variable name already and the order of the dimensions already then
# a string and an array may be passed.

# If a variable is not passed, then it will put varname in the new varpos in whatever variable it is found.

# inputs: infile,varname,new_varpos,verbose,[variable]

sub reorder_dimension {
    my $infile   = shift;
    my $varname  = shift;
    my $varpos   = shift;
    my $verbose  = shift;
    my $variable = shift;
    my $reuse    = shift;

    my $status = 1;
    my @attrs;
    my $xpc = Giovanni::Data::NcFile::get_xml_header( $infile, $reuse );
    my $coords = find_dims_with_varname( $xpc, $varname, $varpos );

    # See if we have anything to do:
    if ( $coords->{org}[$varpos] eq $varname ) {
        warn
            qq(DEBUG: $varname is already in position $varpos. Nothing to do.)
            if ( $verbose > 1 );
        return 0;
    }
    if ( !$variable ) {
        $variable = find_variable_with_varname( $xpc, $coords->{org} );
    }
    my $dimstr = join( ',', @{ $coords->{ordered} } );

    if ( !$variable ) {
        warn qq(Could not find a variable with this coords: $coords->{org})
            if $verbose;
        return 3;
    }
    my $cmd = qq(ncpdq -O -a $dimstr $infile $infile -v $variable);

    # run_command returns 1 if success...
    my $rc_status = Giovanni::Data::NcFile::run_command( $cmd, $verbose );

    if ( $rc_status == 1 ) {
        $dimstr =~ s/,/ /g
            ;   # commas are needed in ncpdq but not in edit_netcdf_attributes
        push @attrs,
            NcAttribute->new(
            'variable' => $variable,
            name       => 'coordinates',
            'value'    => $dimstr,
            'ncotype'  => 'c',
            'action'   => 'o'
            );
        $rc_status = edit_netcdf_attributes( $infile, $infile, @attrs );
    }

    return 0 if ( $rc_status == 1 );

    return 1;
}

# delete_attribute()

# inputs: infile,attribute2delete,varbose,variableAttributeIsUnder
# returns status 0 if successful
# Deletes an attribute from a variable if it exists. For example valid_range.

sub delete_attribute {
    my $self      = shift;
    my $attribute = shift;
    my $variable  = shift;

    my $xpc    = $self->{xpc};
    my $infile = $self->{file};
    my @attrs  = ();

    if ( does_variable_exist( $xpc, $variable ) ) {
        push @attrs,
            NcAttribute->new(
            'variable' => $variable,
            name       => $attribute,
            'value'    => '',
            'ncotype'  => '',
            'action'   => 'd'
            );
        my $rc_status = edit_netcdf_attributes( $infile, $infile, @attrs );
        if ( $rc_status == 1 ) {
            return 0;
        }
    }
    else {

        # nothing to do
        return 0;
    }

    return 1;
}

sub update_attribute {
    my $self      = shift;
    my $attribute = shift;
    my $variable  = shift;
    my $value     = shift;
    my $infile    = $self->{file};
    my $verbose   = $self->{verbose};
    my $xpc       = $self->{xpc};
    my @attrs     = ();

    if ( does_variable_exist( $xpc, $variable ) ) {
        push @attrs,
            NcAttribute->new(
            'variable' => $variable,
            name       => $attribute,
            'value'    => $value,
            'ncotype'  => 'c',
            'action'   => 'a'
            );
        my $rc_status = edit_netcdf_attributes( $infile, $infile, @attrs );
        if ( $rc_status == 1 ) {
            return 0;
        }
    }
    else {

        # nothing to do
        return 0;
    }

    return 1;
}

sub populate_start_end_times {
    my $self             = shift;
    my $dataFieldVarInfo = shift;
    $self->{obtained_times} = 1;
    my $TimeRetrievalMethod = "No time retrieval method worked";

    if ( populated_start_end_times_from_timebnds( $self, $dataFieldVarInfo ))  {
        $TimeRetrievalMethod = "populated_start_end_times_from_timebnds";
    }
    elsif (populated_start_end_times_from_timedim( $self, $dataFieldVarInfo )) {
        $TimeRetrievalMethod = "populated_start_end_times_from_timedim";
    }
    elsif ( populated_start_end_times_from_nc_global($self)) {
        $TimeRetrievalMethod = "populated_start_end_times_from_nc_global";
    }
    elsif ( populated_start_end_times_from_coremetadata($self)) {
        $TimeRetrievalMethod = "populated_start_end_times_from_coremetadata";
    }            
    elsif ( populated_start_end_times_from_hdfeos($self)) {
        $TimeRetrievalMethod = "populated_start_end_times_from_hdfeos";
    } 
    elsif ( populated_start_end_times_from_hdfglobal($self)) {
        $TimeRetrievalMethod = "populated_start_end_times_from_hdfglobal";
    } 
    elsif ( populated_start_end_times_from_coremetadata_b( $self)) {
        $TimeRetrievalMethod = "populated_start_end_times_from_coremetadata_b";
    } 
    elsif ( populated_start_end_times_from_coremetadata_glob( $self)) {
        $TimeRetrievalMethod = "populated_start_end_times_from_coremetadata_glob";
    }                         
    elsif ( populated_start_end_times_from_filename( $self, $dataFieldVarInfo )){
        $TimeRetrievalMethod = "populated_start_end_times_from_filename";
    }         
    elsif ( populated_start_end_times_from_search( $self)) {
        $TimeRetrievalMethod = "populated_start_end_times_from_search";
    }
    else { 
        die "$TimeRetrievalMethod\n";
    }

    warn "Time Retrieval Method: < $TimeRetrievalMethod > \n";

    if ( $self->{rangebeginningdate} ) {
        if ( $self->{rangebeginningdate} =~ /T/ ) {
            $self->{cfbegindate} = $self->{rangebeginningdate};
            ( $self->{rangebeginningdate}, $self->{rangebeginningtime} )
                = split( /T/, $self->{cfbegindate} );
        }
        else {
            $self->{cfbegindate} = $self->{rangebeginningdate} . "T"
                . $self->{rangebeginningtime} . "Z";
        }
        $self->{beginepochsecs} = string2epoch( $self->{cfbegindate} );
    }
    else {
        $self->{rangebeginningtime} = "00:00:00";
    }
    if ( !$self->{rangeendingdate} and $self->{rangebeginningdate} ) {
        my $temporal_res_in_secs
            = get_temporal_resolution_in_sec( $dataFieldVarInfo,
            $self->{rangebeginningdate} );
        my $endTimeSec
            = string2epoch(
            $self->{rangebeginningdate} . " " . $self->{rangebeginningtime} )
            + $temporal_res_in_secs;
        my $newEndTime = DateTime->from_epoch( epoch => $endTimeSec );
        ( $self->{rangeendingdate}, $self->{rangeendingtime} )
            = split( /T/, $newEndTime, 2 );
    }
    if ( $self->{rangeendingdate} ) {
        if ( $self->{rangeendingdate} =~ /T/ ) {
            $self->{rangeendingdate} =~ s/T\d+//;
        }
        $self->{cfenddate}
            = $self->{rangeendingdate} . "T" . $self->{rangeendingtime} . "Z";
        $self->{endepochsecs} = string2epoch( $self->{cfenddate} );
    }

    # Instantaneous Data:
    if ( $self->isInstantaneous() ) {
        $self->{cfenddate}       = $self->{cfbegindate};
        $self->{endepochsecs}    = $self->{beginepochsecs};
        $self->{rangeendingdate} = $self->{rangebeginningdate};
        $self->{rangeendingtime} = $self->{rangebeginningtime};

    }
    return 1;
}

sub get_temporal_resolution_in_sec {
    my $dataFieldVarInfo           = shift;
    my $begindate                  = shift;
    my $temporal_resolution_in_sec = undef;

    if ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'daily' ) {
        $temporal_resolution_in_sec = 60 * 60 * 24 - 1;
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'hourly' ) {
        $temporal_resolution_in_sec = 60 * 60 - 1;
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'monthly' ) {

        # is currently taken care of in body of ncScrubber.pl
        if ($begindate) {
            if ( $begindate =~ /(\d+)-(\d+)-(\d+)/ ) {
                my $y    = $1;
                my $m    = $2;
                my $d    = $3;
                my $days = Date::Manip::Date_DaysInMonth( $m, $y );
                $temporal_resolution_in_sec = 60 * 60 * 24 * $days - 1;
            }
        }
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq '3-hourly' ) {
        $temporal_resolution_in_sec = 3 * 60 * 60 - 1;
    }
    return $temporal_resolution_in_sec;
}

sub getEpochBeginSeconds() {
    my $self = shift;
    if ( defined $self->{beginepochsecs} ) {
        return $self->{beginepochsecs};
    }
    else {
        return undef;
    }
}

sub populated_start_end_times_from_coremetadata_glob {
    my $self    = shift;
    my $verbose = shift;
    my $xpc     = $self->{xpc};
    my $variable;
    my $value;
    my $data;
    my $all   = 4;
    my $found = 0;
    my $node  = $xpc->findnodes(
        qq(/nc:netcdf/nc:attribute[\@name="CoreMetadata.0"]));

    if ( $node->size() > 0 ) {
        $data = $node->[0]->toString();
    }
    else {
        return 0;
    }

    my @objs = split( /END_OBJECT/, $data );
    foreach my $obj (@objs) {
        if ( $obj =~ /Range/i ) {

            #print $obj,"\n\n";
            if ( $obj =~ /.*Value=([\d\-\/:]+).*/ ) {
                $value = $1;
                if ( $obj =~ /OBJECT=RangeBeginningTime/i ) {
                    $self->{rangebeginningtime} = $value;
                    ++$found;
                }
                if ( $obj =~ /OBJECT=RangeEndingTime/i ) {
                    $self->{rangeendingtime} = $value;
                    ++$found;
                }
                if ( $obj =~ /OBJECT=RangeBeginningDate/i ) {
                    $value =~ s/\//-/g;
                    $self->{rangebeginningdate} = $value;
                    ++$found;
                }
                if ( $obj =~ /OBJECT=RangeEndingDate/i ) {
                    $value =~ s/\//-/g;
                    $self->{rangeendingdate} = $value;
                    ++$found;
                }

            }
        }
    }
    if ( $found == $all ) {
        return 1;
    }
    return 0;
}

sub populated_start_end_times_from_coremetadata {
    my $self = shift;
    my $xpc  = $self->{xpc};
    my $variable;
    my $RBDV
        = "coremetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEBEGINNINGDATE.VALUE";
    my $RBTV
        = "coremetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEBEGINNINGTIME.VALUE";
    my $REDV
        = "coremetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEENDINGDATE.VALUE";
    my $RETV
        = "coremetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEENDINGTIME.VALUE";

    # (MOPITT use case)
    my $RBDVb
        = "CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEBEGINNINGDATE.VALUE";
    my $RBTVb
        = "CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEBEGINNINGTIME.VALUE";
    my $REDVb
        = "CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEENDINGDATE.VALUE";
    my $RETVb
        = "CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEENDINGTIME.VALUE";

    my %hash;
    $hash{rbd}{node} = $RBDV;
    $hash{rbt}{node} = $RBTV;
    $hash{red}{node} = $REDV;
    $hash{ret}{node} = $RETV;

# First test with lower case (if any one of the four is missing we can't use it.
    foreach my $key ( keys %hash ) {
        my $node = $hash{$key}{node};
        my $data
            = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$node"]));
        if ( scalar $#$data < 0 ) {

            # If it's of the second type let's use the second set:
            $hash{rbd}{node} = $RBDVb;
            $hash{rbt}{node} = $RBTVb;
            $hash{red}{node} = $REDVb;
            $hash{ret}{node} = $RETVb;
            last;
        }
    }

    foreach my $key ( keys %hash ) {
        my $node = $hash{$key}{node};
        my $data
            = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$node"]));
        if ( scalar $#$data >= 0 ) {
            my $value = uri_unescape( $data->[0]->getAttribute("value") );
            $value =~ s/"//g;
            if ( $value =~ /(\d+:\d+:\d+)\.\d+Z/ ) {
                $hash{$key}{value} = $1;
            }
            else {
                $hash{$key}{value} = $value;
            }
        }
        else {
            warn "Could not find range times in coremetadata \n"
                if $self->{verbose};
            return 0;
        }
    }
    if ( $hash{rbd}{value} =~ /\d+-\d+-\d+/ ) {
        $self->{rangebeginningdate} = $hash{rbd}{value};
        if ( $hash{red}{value} =~ /\d+-\d+-\d+/ ) {
            $self->{rangeendingdate} = $hash{red}{value};
            if ( $hash{rbt}{value} =~ /\d+:\d+:\d+/ ) {
                $self->{rangebeginningtime} = $hash{rbt}{value};
                if ( $hash{ret}{value} =~ /\d+:\d+:\d+/ ) {
                    $self->{rangeendingtime} = $hash{ret}{value};
                    return 1;    # we got all four and they seem to checkout
                }
            }
        }
    }
    return 0;
}

sub populated_start_end_times_from_nc_global {
    my $self = shift;
    my $xpc  = $self->{xpc};
    my $variable;
    my %hash;
    $hash{start}{name}     = "time_coverage_start";
    $hash{end}{name}       = "time_coverage_end";
    $hash{startdate}{name} = "start_date";
    $hash{stopdate}{name}  = "stop_date";
    $hash{starttime}{name} = "start_time";
    $hash{stoptime}{name}  = "stop_time";

    my $status = 0;

    foreach my $key ( keys %hash ) {
        my $node = "NC_GLOBAL." . $hash{$key}{name};
        my $data
            = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$node"]));
        if ( scalar $#$data >= 0 ) {
            my $value = uri_unescape( $data->[0]->getAttribute("value") );
            $value =~ s/"//g;
            if ( $value =~ /\d+/ ) {
                $hash{$key}{val} = $value;
            }
            else {
                warn "Could not parse <" 
                    . $key
                    . "> from xml in HDFEOS metadata\n"
                    if $self->{verbose};

                return 0;
            }
        }
        else {
            warn "Could not find range times for <$key> in HDF-EOS metadata\n"
                if $self->{verbose};

            #return 1;
        }
    }
    if ( exists $hash{starttime}{val} ) {
        $hash{starttime}{val} =~ s/\s\w\w\w//;
        $hash{stoptime}{val}  =~ s/\s\w\w\w//;
        $hash{start}{val}
            = $hash{startdate}{val} . "T" . $hash{starttime}{val};
        $hash{end}{val} = $hash{stopdate}{val} . "T" . $hash{stoptime}{val};
    }
    else {

        # Don't want to take chances on a date format like "01-2012"
        # on such a seldom used subroutine as this one
        $hash{start}{val} = dayyear2date( $hash{start}{val}, 1 );
        $hash{end}{val}   = dayyear2date( $hash{end}{val},   0 );
    }

    if (    $hash{start}{val} =~ /\d\d\d\d-\d\d-\d\d/
        and $hash{end}{val} =~ /\d\d\d\d-\d\d-\d\d/ )
    {

        my $startobj = DateTime->from_epoch(
            epoch => string2epoch( $hash{start}{val} ) );
        my $endobj = DateTime->from_epoch(
            epoch => string2epoch( $hash{end}{val} ) );
        if ( $startobj and $endobj ) {
            $self->{rangebeginningdate} = sprintf( "%04d-%02d-%02d",
                $startobj->year, $startobj->month, $startobj->day );
            $self->{rangebeginningtime} = sprintf( "%02d:%02d:%02d",
                $startobj->hour, $startobj->min, $startobj->sec );

            $self->{rangeendingdate} = sprintf( "%04d-%02d-%02d",
                $endobj->year, $endobj->month, $endobj->day );
            $self->{rangeendingtime} = sprintf( "%02d:%02d:%02d",
                $endobj->hour, $endobj->min, $endobj->sec );
            return 1;
        }
    }
    return 0;

}

# inputs:
#  year
#  day: 1 if start of month, n if end of month, 0 if want end of month calculated
sub dayyear2date {
    my $input = shift;
    my $day = shift || 1;

    if ( $input =~ /^(\d\d).(\d\d\d\d)$/ ) {
        my $m = $1;
        my $y = $2;
        $day = Date::Manip::Date_DaysInMonth( $m, $y ) if ( $day == 0 );
        my $date = sprintf( "%04d-%02d-%02d", $y, $m, $day );
        return $date;
    }
    return $input;
}

sub populated_start_end_times_from_hdfeos {
    my $self = shift;
    my $xpc  = $self->{xpc};
    my $variable;
    my $month = "HDFEOS_ADDITIONAL_FILE_ATTRIBUTES.GranuleMonth";
    my $day   = "HDFEOS_ADDITIONAL_FILE_ATTRIBUTES.GranuleDay";
    my $year  = "HDFEOS_ADDITIONAL_FILE_ATTRIBUTES.GranuleYear";
    my $doy   = "HDFEOS_ADDITIONAL_FILE_ATTRIBUTES.GranuleDayOfYear";
    my $bdate = "HDFEOS_ADDITIONAL_FILE_ATTRIBUTES.BeginDate";
    my $edate = "HDFEOS_ADDITIONAL_FILE_ATTRIBUTES.EndDate";

    my %hash;
    my $status = 0;
    $hash{year}{node}      = $year;
    $hash{month}{node}     = $month;
    $hash{day}{node}       = $day;
    $hash{doy}{node}       = $doy;
    $hash{begindate}{node} = $bdate;
    $hash{enddate}{node}   = $edate;

    foreach my $key ( keys %hash ) {
        my $node = $hash{$key}{node};
        my $data
            = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$node"]));
        if ( scalar $#$data >= 0 ) {
            my $value = uri_unescape( $data->[0]->getAttribute("value") );
            $value =~ s/"//g;
            if ( $value =~ /\d+/ ) {
                $hash{$key}{val} = $value;
            }
            else {
                warn "Could not parse <" 
                    . $key
                    . "> from xml in HDFEOS metadata\n"
                    if $self->{verbose};

                #return 1;
            }
        }
        else {
            warn "Could not find range times for <$key> in HDF-EOS metadata\n"
                if $self->{verbose};

            #return 1;
        }
    }
    if (    exists $hash{year}{val}
        and $hash{year}{val}  =~ /\d\d\d\d/
        and $hash{month}{val} =~ /\d+/
        and $hash{day}{val}   =~ /\d+/ )
    {

        $self->{rangebeginningdate} = sprintf( "%04d-%02d-%02d",
            $hash{year}{val}, $hash{month}{val}, $hash{day}{val} );
        $self->{rangebeginningtime} = "00:00:00";
        $self->{rangeendingdate}    = $self->{rangebeginningdate};
        $self->{rangeendingtime}    = "23:59:59";
        return 1;
    }
    elsif ( exists $hash{begindate}{val}
        and $hash{begindate}{val} =~ /\d\d\d\d-\d\d-\d\d/
        and $hash{enddate}{val}   =~ /\d\d\d\d-\d\d-\d\d/ )
    {
        $self->{rangebeginningdate} = $hash{begindate}{val};
        $self->{rangebeginningtime} = "00:00:00";
        $self->{rangeendingdate}    = $hash{enddate}{val};
        $self->{rangeendingtime}    = "23:59:59";
        return 1;
    }
    return 0;
}

# This code is was set for TRMM_3B42_daily_precipitation_V6
# and is closest to: populated_start_end_times_from_hdfglobal()
sub populated_start_end_times_from_coremetadata_b {
    my $self = shift;
    my $xpc  = $self->{xpc};
    my $variable;
    my $attrLocVal = "CoreMetadata.0";
    my $RBT        = "RangeBeginningTime.Value";
    my $RET        = "RangeEndingTime.Value";
    my $RBD        = "RangeBeginningDate.Value";
    my $RED        = "RangeEndingDate.Value";
    my %hash;
    my $status = 0;
    $hash{rbt}{node} = $RBT;
    $hash{ret}{node} = $RET;
    $hash{rbd}{node} = $RBD;
    $hash{red}{node} = $RED;

    my $data
        = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$attrLocVal"]));
    unless ( $data->size() > 0 ) {
        warn "ERROR Could not find attribute <$attrLocVal>\n";
        return 0;
    }
    my $value = uri_unescape( $data->[0]->getAttribute("value") );
    my @items = split( /\n/, $value );

    foreach my $key ( keys %hash ) {
        foreach my $item (@items) {
            chomp $item;
            if ( $item =~ /$hash{$key}{node}/ ) {
                my ( $name, $value ) = split( /:/, $item, 2 );
                $value =~ s/"//g;
                if ( $value =~ /(\d+\/\d+\/\d+)/ ) {
                    $hash{$key}{date} = $1;
                    $hash{$key}{date} =~ s/\//-/g;
                }
                elsif ( $value =~ /(\d+:\d+:\d+)/ ) {
                    $hash{$key}{time} = $1;
                }
                else {
                    $hash{$key}{value} = $value;
                }
            }
        }
    }
    if ( exists $hash{rbd}{date} and $hash{rbd}{date} =~ /\d+-\d+-\d+/ ) {
        $self->{rangebeginningdate} = $hash{rbd}{date};
        if ( exists $hash{red}{date} and $hash{red}{date} =~ /\d+-\d+-\d+/ ) {
            $self->{rangeendingdate} = $hash{red}{date};
            if ( exists $hash{rbt}{time}
                and $hash{rbt}{time} =~ /\d+:\d+:\d+/ )
            {
                $self->{rangebeginningtime} = $hash{rbt}{time};
                if ( exists $hash{ret}{time}
                    and $hash{ret}{time} =~ /\d+:\d+:\d+/ )
                {
                    $self->{rangeendingtime} = $hash{ret}{time};
                    return 1;    # we got all four and they seem to checkout
                }
            }
        }
    }
    warn "Could not find range times in core metadata glob\n"
        if $self->{verbose};
    return 0;
}

sub populated_start_end_times_from_hdfglobal {
    my $self = shift;
    my $xpc  = $self->{xpc};
    my $variable;

    # Type 1
    my $attrLocVal = "HDF_GLOBAL.FileHeader";
    my $RBT        = "StartGranuleDateTime";
    my $RET        = "StopGranuleDateTime";
    # Type 1a
    #  same but w/o HDF5_GLOBAL.

    # Type 2
    my $H5BD = "HDF5_GLOBAL.BeginDate";
    my $H5ED = "HDF5_GLOBAL.EndDate";
    my $H5BT = "HDF5_GLOBAL.BeginTime";
    my $H5ET = "HDF5_GLOBAL.EndTime";

    # Type 2a
    #  same but w/o HDF5_GLOBAL.
    my %hash;
    my $status = 0;
    $hash{rbt}{node} = $RBT;
    $hash{ret}{node} = $RET;

    # Type 1
    my $data = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$attrLocVal"]));
    if ( $data->size() < 1 ) {
        $attrLocVal  =~ s/HDF_GLOBAL.//;
        # Type 1a
        $data = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$attrLocVal"]));
    }
    if ( $data->size() >= 1 ) {
        my $ivalue = uri_unescape( $data->[0]->getAttribute("value") );
        my @items = split( /;/, $ivalue );

        foreach my $key ( keys %hash ) {
            foreach my $item (@items) {
                chomp $item;
                if ( $item =~ /$hash{$key}{node}/ ) {
                    my ( $name, $value ) = split( /=/, $item, 2 );
                    $value =~ s/"//g;
                    if ( $value =~ /(\d+-\d+-\d+)T(\d+:\d+:\d+)\.\d+Z/ ) {
                        $hash{$key}{date} = $1;
                        $hash{$key}{time} = $2;
                    }
                    else {
                        $hash{$key}{value} = $value;
                    }
                }
            }
        }
     }
    else {

        # Type 2
        $data = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$H5BD"]));
        if ( $data->size() < 1 ) {
            foreach ( $H5BD, $H5ED, $H5BT, $H5ET ) {
                $_ =~ s/HDF5_GLOBAL.//;
            }
            # Type 2a 
            $data = $xpc->findnodes( qq(/nc:netcdf/nc:attribute[\@name="$H5BD"]));
            if ( $data->size() < 1 ) {
                return 0;
            }
        }
        $hash{rbt}{date} = $data->[0]->getAttribute('value');

        $data = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$H5BT"]));
        $hash{rbt}{time} = $data->[0]->getAttribute('value');

        $data = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$H5ED"]));
        $hash{ret}{date} = $data->[0]->getAttribute('value');
        $data = $xpc->findnodes(qq(/nc:netcdf/nc:attribute[\@name="$H5ET"]));
        $hash{ret}{time} = $data->[0]->getAttribute('value');

    }

    if ( $hash{rbt}{date} =~ /\d+-\d+-\d+/ ) {
        $self->{rangebeginningdate} = $hash{rbt}{date};
        if ( $hash{ret}{date} =~ /\d+-\d+-\d+/ ) {
            $self->{rangeendingdate} = $hash{ret}{date};
            if ( $hash{rbt}{time} =~ /(\d+:\d+:\d+)/ ) {
                $self->{rangebeginningtime} = $1;

                if ( $hash{ret}{time} =~ /(\d+:\d+:\d+)/ ) {
                    $self->{rangeendingtime} = $1;
                    return 1;    # we got all four and they seem to checkout
                }
            }
        }
    }
    warn "Could not find range times in HDF Global metadata\n"
        if $self->{verbose};
    return 0;
}

sub isInstantaneous {
    my $self = shift;
    if ( defined $self->{cell_methods_value} ) {
        if ( $self->{cell_methods_value} =~ /point/ ) {
            return 1;
        }
    }
    return 0;
}

sub populated_start_end_times_from_timebnds {
    my $self             = shift;
    my $dataFieldVarInfo = shift;
    my $xpc              = $self->{xpc};
    my $variable;
    my %hash;
    my $basetime       = undef;
    my $basedate       = undef;
    my $basetimeunits  = undef;
    my $additionaltime = undef;
    my @timeDataVal;
    my $timeUnitValue;
    my $status                     = 0;
    my $temporal_resolution_in_sec = 0;
    my $newEndTime                 = undef;

    return 0 if ( $self->isInstantaneous() );

    if ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'daily' ) {
        $temporal_resolution_in_sec = 60 * 60 * 24;
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'hourly' ) {
        $temporal_resolution_in_sec = 60 * 60;
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'monthly' ) {

        # is currently taken care of in body of ncScrubber.pl
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq '3-hourly' ) {
        $temporal_resolution_in_sec = 3 * 60 * 60;
    }

    my $timedimname = $self->{time_var_name};

    if ( $timedimname eq "" ) {
        warn
            "WARN: No sort of time dimension appears to be in $self->{file}\n"
            if $self->{verbose};
        return 0;
    }

    my @data = `ncdump -v $timedimname  $self->{file}`;
    if ( $#data < 0 ) {
        warn "WARN: no time variable with name <$timedimname>\n"
            if $self->{verbose};
        return 0;
    }

    # first time is header:
    while ( $data[0] !~ /data:/ and $#data > 1 ) {
        shift @data;
        if ( $data[0]
            =~ /$timedimname:units = "((\w+) since (\d+-\d+-\d+)[ T](\d+:\d+:\d+).*")/
            )
        {
            $basetimeunits = $2;
            $basedate      = $3;
            $basetime      = $4;
            $timeUnitValue = $1;    # cf2epoch needs this
        }
        elsif ( $data[0]
            =~ /$timedimname:units = "(([\w ]+) since (\d+-\d+-\d+)[ T](\d+:\d+:\d+).*")/
            )
        {
            $basetimeunits = $2;
            $basedate      = $3;
            $basetime      = $4;
            $timeUnitValue = $1;    # calendar Month
            my @tmp = split( /\s/, $timeUnitValue );
            $timeUnitValue = lc $tmp[$#tmp];
        }
        elsif (
            $data[0] =~ /$timedimname:units = "((\w+) since (\d+-\d+-\d+))/ )
        {
            $basetimeunits = $2;
            $basedate      = $3;
            $basetime      = "00:00:00";
            $timeUnitValue = $1;           # cf2epoch needs this
        }
    }
    if (   !$basetime
        || !$basedate
        || !$basetimeunits )
    {
        warn
            "WARN: Could not get time from time dimension: <$basetime> <$basedate> <$basetimeunits> <$additionaltime>\n"
            if $self->{verbose};
        return 0;
    }

    my $bounds = $self->{time_bnds_name};

    return 0 if ( !$bounds );
    @data = `ncdump -v $bounds $self->{file}`;
    if ( $#data < 0 ) {
        warn "WARN: no time_bnds variable with name <$bounds>\n"
            if $self->{verbose};
        return 0;
    }
    while ( $data[0] !~ /$bounds =/ and $#data >= 0 ) {
        shift @data;
    }
    my $string;
    foreach (@data) {
        $string .= $_;
    }
    $string =~ s/$bounds =//;
    $string =~ s/;//;
    $string =~ s/}//;
    @data = split( /,/, $string );

    my $multiplier = 1;
    my $startTimeSec;
    my $endTimeSec;

    if ( $basetimeunits =~ /daily|Day|days/i ) {
        $multiplier = 86400;
    }
    elsif ( $basetimeunits =~ /hour/i ) {
        $multiplier = 3600;
    }
    elsif ( $basetimeunits =~ /min/i ) {
        $multiplier = 60;
    }
    elsif ( $basetimeunits =~ /sec/i ) {
    }
    elsif ( $basetimeunits =~ /month/i ) {

        # in this case we are going to have to work out the number of seconds
        # between start: time:units = "months since 1980-01-01T00:00:00Z" ;
        # and the end:   time = value (from variable)
        # start can be obtained from:
        if ( $basedate =~ /(\d+)-(\d+)-(\d+)/ ) {
            my $y          = $1;
            my $startmonth = $2;
            my $d          = $3;
            my $thismonth  = $startmonth + $data[0];
            my $localbasedate
                = sprintf( "%04d-%02d-%02d", $y, $thismonth, $d );
            $startTimeSec = string2epoch( $localbasedate . " " . $basetime );

      # this is just so it doesn't fail later. We will assume if it is monthly
      # then either climatology or 1 month
            my $origTime = Date::Manip::ParseDate($localbasedate);
            my $newTime
                = Date::Manip::DateCalc( $origTime, "$data[$#data] months" );
            if ( $newTime =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d:\d\d:\d\d)/ ) {
                $endTimeSec = string2epoch(
                    sprintf( "%04d-%02d-%02d %s", $1, $2, $3, $4 ) );

# Might as well subtract 1 second here for monthly data as we do everywhere else...
                $newEndTime = DateTime->from_epoch( epoch => $endTimeSec );
            }

        }
        else {
            warn "WARN: Could not get work out month units: <$basedate> \n"
                if $self->{verbose};
            return 0;
        }
    }
    else {
        warn "WARN: Could not get time units from header: <$basetimeunits> \n"
            if $self->{verbose};
        return 0;
    }

    $startTimeSec = $startTimeSec
        || string2epoch( $basedate . " " . $basetime )
        + $multiplier * $data[0];
    if ( $startTimeSec < string2epoch("1900-01-01T00:00:00Z") ) {
        warn
            "WARN: Could not work out starting epoch time from : <$basetime> <$basedate> <$basetimeunits> <$additionaltime> \n"
            if $self->{verbose};
        return 0;
    }
    my $newStartTime = DateTime->from_epoch( epoch => $startTimeSec );

    if ( !$newEndTime ) {
        $endTimeSec = $endTimeSec
            || string2epoch( $basedate . " " . $basetime )
            + $multiplier * $data[$#data];    # last second
        if ( $endTimeSec == $startTimeSec ) {
            $newEndTime = DateTime->from_epoch( epoch => $endTimeSec );
        }
        elsif ( $endTimeSec <= $startTimeSec ) {
            warn
                "WARN: Could not work out ending epoch time from : <$basetime> <$basedate> <$basetimeunits> <$additionaltime> \n"
                if $self->{verbose};
        }
        else {
            $newEndTime = DateTime->from_epoch( epoch => $endTimeSec );
        }
    }

    if ( $#data > 0 ) {
        if ( !$newEndTime ) {
            if ( $data[0] == 0 ) {
                $newEndTime = DateTime->from_epoch(
                    epoch => $startTimeSec + $data[$#data] * $multiplier );
            }
            else {
                $newEndTime = DateTime->from_epoch(
                    epoch => $data[$#data] * $multiplier );
            }
        }
        ( $self->{rangeendingdate}, $self->{rangeendingtime} )
            = split( /T/, $newEndTime );
    }
    ( $self->{rangebeginningdate}, $self->{rangebeginningtime} )
        = split( /T/, $newStartTime );
    if ( $self->{rangebeginningdate} =~ /\d+-\d+-\d+/ ) {
        if ( $self->{rangebeginningtime} =~ /\d+:\d+:\d+/ ) {

            # so far we have 2. We may be able to get 4:
            if ( $temporal_resolution_in_sec and !$newEndTime ) {
                $newEndTime
                    = DateTime->from_epoch(
                    epoch => ( $startTimeSec + $temporal_resolution_in_sec )
                    );
                ( $self->{rangeendingdate}, $self->{rangeendingtime} )
                    = split( /T/, $newEndTime );
                if ( $self->{rangeendingdate} =~ /\d+-\d+-\d+/ ) {
                    if ( $self->{rangeendingtime} =~ /\d+:\d+:\d+/ ) {
                        $self->{time_time_bnds} = 1;
                        return 1;    # we got all 4
                    }
                }
            }
            $self->{time_time_bnds} = 1;
            return 1;    # we got the beginning time. that's good enough.
        }
    }
    warn "Could not find range times from time dimension/variable\n"
        if $self->{verbose};
    return 0;
}

sub populated_start_end_times_from_timedim {
    my $self             = shift;
    my $dataFieldVarInfo = shift;
    my $xpc              = $self->{xpc};
    my $variable;
    my %hash;
    my $basetime       = undef;
    my $basedate       = undef;
    my $basetimeunits  = undef;
    my $additionaltime = undef;
    my @timeDataVal;
    my $timeUnitValue;
    my $status                     = 0;
    my $temporal_resolution_in_sec = 0;

    if ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'daily' ) {
        $temporal_resolution_in_sec = 60 * 60 * 24 - 1;
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'hourly' ) {
        $temporal_resolution_in_sec = 60 * 60 - 1;
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'monthly' ) {

        # identifying this is currently taken care of in body of ncScrubber.pl
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq '3-hourly' ) {
        $temporal_resolution_in_sec = 3 * 60 * 60 - 1;
    }

    my $timedimname = $self->{time_var_name};

    if ( $timedimname eq "" ) {
        warn
            "WARN: No sort of time dimension appears to be in $self->{file}\n"
            if $self->{verbose};
        return 0;
    }
    my @data = `ncdump -v $timedimname $self->{file}`;

    # first time is header:
    while ( $data[0] !~ /data:/ and $#data > 1 ) {
        shift @data;
        if ( $data[0]
            =~ /$timedimname:units = "((\w+) since (\d+-\d+-\d+)[ T]?(\d+:\d+:\d+).*")/
            )
        {
            $basetimeunits = $2;
            $basedate      = $3;
            $basetime      = $4;
            $timeUnitValue = $1;    # cf2epoch needs this
        }
        elsif (
            $data[0] =~ /$timedimname:units = "((\w+) since (\d+-\d+-\d+))/ )
        {
            $basetimeunits = $2;
            $basedate      = $3;
            $basetime      = "00:00:00";
            $timeUnitValue = $1;           # cf2epoch needs this
        }
    }
    if (   !$basetime
        || !$basedate
        || !$basetimeunits )
    {
        warn
            "WARN: Could not get time from time dimension: <$basetime> <$basedate> <$basetimeunits> <$additionaltime>\n"
            if $self->{verbose};
        return 0;
    }

    # second time is data:
    while ( $data[0] !~ /$timedimname =/ and $#data >= 0 ) {
        shift @data;
    }
    my $string;
    foreach (@data) {
        $string .= $_;
    }
    $string =~ s/$timedimname =//;
    $string =~ s/;//;
    $string =~ s/}//;
    @data = split( /,/, $string );

    my $newStartTime = undef;
    my $newEndTime   = undef;
    my $multiplier   = 1;
    my $startTimeSec = undef;
    my $endTimeSec   = undef;

# These basetime units are not what is in EDDA but rather what is in CF time units
# In these blocks that aren't month, $endTimeSec are assigned but not $newEndTime
# http://www.unidata.ucar.edu/software/udunits/udunits-1/udunits.txt. Unfortunately
# there are way to many...
    if ( $basetimeunits =~ /daily|Day|days/i ) {
        $multiplier = 86400;
    }
    elsif ( $basetimeunits =~ /week/i ) {
        $multiplier = 604800;
    }
    elsif ( $basetimeunits =~ /fortnight/i ) {
        $multiplier = 1209600;
    }
    elsif ( $basetimeunits =~ /hour|hr/i ) {
        $multiplier = 3600;
    }
    elsif ( $basetimeunits =~ /min/i ) {
        $multiplier = 60;
    }
    elsif ( $basetimeunits =~ /sec/i ) {

        # $multiplier has been initialized to 1
    }
    elsif ( $basetimeunits =~ /year|yr/i ) {
        die
            "Please write code to support obtaining start/end time for time:units = year\n";
    }
    else {
        warn "WARN: Could not get time units from header: <$basetimeunits> \n"
            if $self->{verbose};
        return 0;
    }

    # Now do stuff: 2 different cases:
    if ( $basetimeunits =~ /month/i ) {

        # in this case we are using Date:Manip:Calc to add the
        # time variable date (which in this case is in units of months)
        # to the 'since' date  - we can't just use multiplier as in the other
        # cases because months are not a regular unit of time
        if ( $basedate =~ /(\d+)-(\d+)-(\d+)/ ) {
            my $origTime = Date::Manip::ParseDate($basedate);
            my $newTime
                = Date::Manip::DateCalc( $origTime, "$data[$#data] months" );
            if ( $newTime =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d:\d\d:\d\d)/ ) {
                $startTimeSec = string2epoch(
                    sprintf( "%04d-%02d-%02d %s", $1, $2, $3, $4 ) );
                $newStartTime
                    = DateTime->from_epoch( epoch => $startTimeSec );
                ( $self->{rangebeginningdate}, $self->{rangebeginningtime} )
                    = split( /T/, $newStartTime );
            }
        }
        else {
            warn "WARN: Could not get work out month units: <$basedate> \n"
                if $self->{verbose};
            return 0;
        }

    }
    else
    {    # If time unit is not month we can use calculated multiplier (in sec)
        $startTimeSec = string2epoch( $basedate . " " . $basetime )
            + $multiplier * $data[0];
        $newStartTime = DateTime->from_epoch( epoch => $startTimeSec );
        ( $self->{rangebeginningdate}, $self->{rangebeginningtime} )
            = split( /T/, $newStartTime );
        $endTimeSec = string2epoch( $basedate . " " . $basetime )
            + $multiplier * $data[$#data];
    }

    # ERRORS
    if ( $startTimeSec < string2epoch("1900-01-01T00:00:00Z") ) {
        warn
            "WARN: Could not work out starting epoch time from : <$basetime> <$basedate> <$basetimeunits> <$additionaltime> \n"
            if $self->{verbose};
        return 0;
    }

    if ( $endTimeSec <= $startTimeSec ) {
        warn
            "WARN: Could not work out ending epoch time from : <$basetime> <$basedate> <$basetimeunits> <$additionaltime> \n"
            if $self->{verbose};

    }
    else {
        if ( !$newEndTime ) {
            $newEndTime = DateTime->from_epoch( epoch => $endTimeSec );
        }
    }

    # For end time (time variable contains more than 1 number)
    # I had to handle months separately above
    if ( $#data > 0 ) {
        if ( $basetimeunits !~ /month/ ) {
            if ( $data[0] == 0 ) {
                $newEndTime = DateTime->from_epoch(
                    epoch => $startTimeSec + $data[$#data] * $multiplier );
            }
            else {
                $newEndTime = DateTime->from_epoch(
                    epoch => $data[$#data] * $multiplier );
            }
        }
        ( $self->{rangeendingdate}, $self->{rangeendingtime} )
            = split( /T/, $newEndTime );
    }

# In this case we are using the EDDA assigned temporal resolution as last resort
    if ( $self->{rangebeginningdate} =~ /\d+-\d+-\d+/ ) {
        if ( $self->{rangebeginningtime} =~ /\d+:\d+:\d+/ ) {

            # so far we have 2. We may be able to get 4:
            if ( $temporal_resolution_in_sec and !$newEndTime ) {
                warn
                    "Using EDDA assigned temporal resolution (secs) $temporal_resolution_in_sec\n";
                $newEndTime
                    = DateTime->from_epoch(
                    epoch => ( $startTimeSec + $temporal_resolution_in_sec )
                    );
                ( $self->{rangeendingdate}, $self->{rangeendingtime} )
                    = split( /T/, $newEndTime );
                if ( $self->{rangeendingdate} =~ /\d+-\d+-\d+/ ) {
                    if ( $self->{rangeendingtime} =~ /\d+:\d+:\d+/ ) {
                        return 1;    # we got all 4
                    }
                }
            }
            return 1;    # at least begin date was assigned.
        }
    }
    warn "Could not find range times from time dimension/variable\n"
        if $self->{verbose};
    return 0;
}

sub populated_start_end_times_from_search {
    my $self       = shift;
    my $localstart = $self->{OSstartTime};
    my $localend   = $self->{OSendTime};

    if (   length $localstart == 0
        or length $localend == 0 )
    {
        warn("SSW search does not deliver OpenSearch start and end times");
        return 0;
    }

 # Unfortunately, because of all of the previous types of times, T in scrubber
 # is only a separator, not really part of an ISO time
    $localstart =~ s/Z$//;
    $localend   =~ s/Z$//;

    ( $self->{rangeendingdate}, $self->{rangeendingtime} )
        = split( /T/, $localend );
    ( $self->{rangebeginningdate}, $self->{rangebeginningtime} )
        = split( /T/, $localstart );
    return 1;
}

sub populated_start_end_times_from_filename {
    my $self             = shift;
    my $dataFieldVarInfo = shift;
    my $verbose          = $self->{verbose};
    my $workingfile      = $self->{file};
    my $fname            = basename $workingfile;
    $self->{rangebeginningtime} = "00:00:00";
    $self->{rangeendingtime}    = "23:59:59";
    my $temporal_resolution_in_sec = undef;

    # time gotten through filename is not a 'real' time
    $self->{obtained_times} = undef;

    if ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'daily' ) {
        $temporal_resolution_in_sec = 60 * 60 * 24 - 1;
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'hourly' ) {
        $temporal_resolution_in_sec = 60 * 60 - 1;
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'monthly' ) {

        # is currently taken care of in body of ncScrubber.pl
    }
    elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq '3-hourly' ) {
        $temporal_resolution_in_sec = 3 * 60 * 60 - 1;
    }

    my ( $datestring, $enddatestring, $rangebeginningtime, $rangeendingtime )
        = match_filename( $fname, $verbose );
    if ( !defined $datestring ) {
        warn("WARN no date to extract from $fname");
        return;
    }

    # I believe what we want to do here is to remove all trailing 0:s
    $datestring =~ s/T00:00:00//;
    $datestring =~ s/T00:00$//;
    $datestring =~ s/T00$//;

    my $startTimeAttribute = $datestring;
    my $endTimeAttribute;

    if ($rangeendingtime) {
        $self->{rangeendingtime} = $rangeendingtime;
    }

    # TODO:  we should put a more accurate endTimeAttribute in here
    if ($enddatestring) {
        $endTimeAttribute = $enddatestring;
    }
    else {
        $endTimeAttribute = $startTimeAttribute;
        if ($temporal_resolution_in_sec) {
            my ( $basedate, $basetime )
                = split( /T/, $startTimeAttribute, 2 );
            if ( length $basetime < 2 ) {
                $basetime = "00:00:00";
            }
            elsif ( length $basetime == 2 ) {
                $basetime .= ":00:00";
            }
            elsif ( length $basetime == 5 ) {
                $basetime .= ":00";
            }
            my $startTimeSec = string2epoch( $basedate . " " . $basetime );
            my $newEndTime   = DateTime->from_epoch(
                epoch => ( $startTimeSec + $temporal_resolution_in_sec ) );
            my $newStartTime
                = DateTime->from_epoch( epoch => ($startTimeSec) );
            ( $self->{rangeendingdate}, $self->{rangeendingtime} )
                = split( /T/, $newEndTime );
            ( $self->{rangebeginningdate}, $self->{rangebeginningtime} )
                = split( /T/, $newStartTime );
        }

    }

    # $time = 1.0 * Date::Parse::str2time($datestring);
    my $time = string2epoch($datestring);

    if ( !defined $time ) {
        warn( 1, "ERROR Invalid datetime string from filename: $datestring" );
        return 0;
    }

    if ( !$self->{rangebeginningdate} ) {
        $self->{rangebeginningdate} = $startTimeAttribute;
    }
    if ( !$self->{rangeendingdate} ) {
        $self->{rangeendingdate} = $endTimeAttribute;
    }
    return 1;
}

sub match_filename {

    my $fname   = shift;
    my $verbose = shift;
    my ( $startTimeAttribute, $endTimeAttribute );
    my $time;
    my $datestring;
    my $enddatestring;
    my $conventionsNotFound = 1;    ## not found
    my $rangebeginningtime;
    my $rangeendingtime;

    ## date from OMI filename
    if ( $fname =~ /_(\d{4})m(\d{2})(\d{2})/ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO datestring for OMI = $datestring \n" if ($verbose);
    }
    ## date from airs esgf: ta_AIRS_L3_RetStd-v5_200209-201105.AIRS_L3_RetStd_005_ta.nc
    elsif ( $fname =~ /_(\d{4})(\d{2})-(\d{4})(\d{2})/ ) {
        $datestring = "$1-$2-01";
        my $endmonth = $4;
        my $endyear  = $3;
        my $endday   = Date::Manip::Date_DaysInMonth( $endmonth, $endyear );
        $enddatestring = "$endyear-$endmonth-$endday";
        print STDERR "INFO datestring for ESGF = $datestring \n"
            if ($verbose);
    }
    ## date time from IMERG
    elsif ( $fname
        =~ /\.(\d{4})(\d{2})(\d{2})-S(\d{2})(\d{2})(\d{2})-E(\d{2})(\d{2})(\d{2})\./
        )
    {

        # from_filename $datestring                 = "$1-$2-$3";
        $datestring         = "$1-$2-$3T$4:$5:$6";
        $enddatestring      = "$1-$2-$3";
        $rangebeginningtime = "$4:$5:$6";
        $rangeendingtime    = "$7:$8:$9";
        print STDERR
            "INFO datestring for IMERG = ${datestring}  ${enddatestring}\n"
            if ($verbose);
    }

    # date from TRMM  RT v7 (no global metadata)
    elsif ( $fname =~ /\.(\d{4})\.(\d{2})\.(\d{2})\.(\d{2})z/ ) {
        $datestring = "$1-$2-$3T$4:00:00";
        print STDERR "INFO datestring for (TRMM RT v7) = $datestring \n"
            if ($verbose);
    }
    ## date from TRMM and AIRNOW filenames
    elsif ( $fname =~ /\.(\d{4})\.(\d{2})\.(\d{2})\./ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO datestring for (TRMM|AIRNOW) = $datestring \n"
            if ($verbose);
    }
    ## date from TRMM 3-Hourly filenames
    elsif ( $fname =~ /\.(\d{4})(\d{2})(\d{2})\.(\d{2})\./ ) {
        my $hours = $4;
        $datestring = "$1-$2-$3T$hours:00";
        $rangebeginningtime =~ s/00/$hours/;
        print STDERR "INFO datestring for (TRMM|AIRNOW) = $datestring \n"
            if ($verbose);
    }
    ## date from TRMM v6 filenames
    elsif ( $fname =~ /\.(\d{2})(\d{2})(\d{2})\.\d\w?\./ ) {
        my $year = $1;
        if ( $year < 50 ) {
            $year = "20" . $year;
        }
        else {
            $year = "19" . $year;
        }
        $datestring = "$year-$2-$3";
        print STDERR "INFO datestring for OMI = $datestring \n" if ($verbose);
    }
    ## date from MODIS filename
    elsif ( $fname =~ /\.A(\d{4})(\d{3})\./ ) {
        my $year = $1;
        my $dt
            = DateTime->from_day_of_year( year => $year, day_of_year => $2 );
        $datestring
            = sprintf( "%04d-%02d-%02d", $year, $dt->month(), $dt->day() );
        print STDERR "INFO datestring for MODIS = $datestring \n"
            if ($verbose);
    }

    # salinity, year and jday
    elsif ( $fname =~ /^.*?[A-Z]+(\d{4})(\d{3})(\d{4})(\d{3})\.*/ ) {
        my $year = $1;
        my $dt
            = DateTime->from_day_of_year( year => $year, day_of_year => $2 );
        $datestring
            = sprintf( "%04d-%02d-%02d", $year, $dt->month(), $dt->day() );
        print STDERR "INFO datestring for MODIS = $datestring \n"
            if ($verbose);
    }

    ## date from SeaWIFS filename
    ## YEAR-MM format
    # _(\d{4})m(\d{2})(\d{2})
    elsif ( $fname =~ /_(\d{4})(\d{2})(\d{2})*_v/ ) {
        $datestring = "$1-$2";
        if ( defined($3) ) {
            $datestring .= "-$3";
        }
        else {
            $datestring .= "-01";
        }
        print STDERR "INFO datestring for SeaWiFS = $datestring \n"
            if ($verbose);
    }
    ######### date from MISR #####
    elsif ( $fname =~ /_(\w{3})_(\d{2})_(\d{4})_/ ) {
        my %months = (
            'JAN' => '01',
            'FEB' => '02',
            'MAR' => '03',
            'APR' => '04',
            'MAY' => '05',
            'JUN' => '06',
            'JUL' => '07',
            'AUG' => '08',
            'SEP' => '09',
            'OCT' => '10',
            'NOV' => '11',
            'DEC' => '12'
        );
        $datestring = "$3-$months{$1}-$2";
        print STDERR "INFO datestring for MISR = $datestring \n"
            if ($verbose);
    }

    ####### date from GoCart ####
    elsif ( $fname =~ /_(\d{4})(\d{2})(\d{2})\.nc/ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO datestring for GoCart = $datestring \n"
            if ($verbose);
    }
    ####### date from nobm day ####
    elsif ( $fname =~ /\w+(\d{4})(\d{2})(\d{2})\.R/ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO datestring for NOBM daily = $datestring \n"
            if ($verbose);
    }
    ####### date from nobm monthly  ####
    elsif ( $fname =~ /\w+(\d{4})(\d{2})\.R/ ) {
        $datestring = "$1-$2-01";
        print STDERR "INFO datestring for NOBM monthly= $datestring \n"
            if ($verbose);
    }
    ## date from NLDAS filename
    elsif ( $fname =~ /\.A(\d{4})(\d{2})(\d{2})\.(\d{2})(\d{2})\./ ) {
        my $hr = $4;
        my $mn = $5;
        $datestring         = "$1-$2-$3T$hr:$mn";
        $rangebeginningtime = "$hr:$mn";
        print STDERR "INFO datestring for NLDAS = $datestring \n"
            if ($verbose);
    }
    ## date from NLDAS Monthly filename
    elsif ( $fname =~ /\.\w(\d{4})(\d{2})\.(\d{3})\./ ) {

        # from_filename version $datestring = "$1-$2-01";
        $datestring = "$1-$2-01T00:00";
        print STDERR "INFO datestring for NLDAS = $datestring \n"
            if ($verbose);
    }
    ## scrubber:ate from MERRA filename
    elsif ( $fname =~ /\.(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\./ ) {
        $datestring = "$1-$2-$3:$4:$5";
        print STDERR "INFO continuous  datestring for MERRA = $datestring \n"
            if ($verbose);
    }

    # ncfile
    elsif ( $fname =~ /\.(\d{4})(\d{2})(\d{2})\./ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO single datestring for MERRA = $datestring \n"
            if ($verbose);
    }
    elsif ( $fname =~ /\.(\d{4})(\d{2})(\d{2})-(\d{4})(\d{2})(\d{2})\./ ) {

        #20091231-20100102
        $datestring    = "$1-$2-$3";
        $enddatestring = "$4-$5-$6";
        print STDERR "INFO 2 datestrings for MERRA = $datestring \n"
            if ($verbose);
    }
    ## date from  GRACE and TRMM 3A12
    elsif ( $fname =~ /[A.](\d{4})(\d{2})(\d{2})\./ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO datestring for GRACE = $datestring \n"
            if ($verbose);
    }

    if ( length $datestring < 2 ) {
        warn( 1,
            "ERROR No datetime string from filename:<$fname> of datetime string: <$datestring>, our last resort!"
        );
        return;
    }
    return ( $datestring, $enddatestring, $rangebeginningtime,
        $rangeendingtime );
}

# There used to be 2 subroutines, one in Scrubber.pm, the other in NcFile.pm which did almost the same thing.
# One was this one, extractDateString, the other was:  populated_start_end_times_from_filename
# Now the shared code has been put into match_filename
sub extractDateString {
    my ( $fname, $startTimeAttribute, $endTimeAttribute, $workingfile,
        $verbose )
        = @_;
    my $time;
    my $conventionsNotFound = 1;    ## not found

    my ( $datestring, $enddatestring, $rangebeginningtime, $rangeendingtime )
        = match_filename( $fname, $verbose );

    if ( !defined $datestring ) {
        warn("WARN no date to extract from $fname");
        return;
    }
    $startTimeAttribute = $datestring;

    # Strip off trailing minutes (e.g.NLDAS)
    # $startTimeAttribute =~ s/(T\d\d):00/$1/;

    # TODO:  we should put a more accurate endTimeAttribute in here
    $endTimeAttribute = $startTimeAttribute;

    ## to add a global attribute 'Conventions'

    # $time = 1.0 * Date::Parse::str2time($datestring);
    $time = string2epoch($datestring);

    if ( !defined $time ) {
        quit( 1, "ERROR Invalid datetime string from filename: $datestring" );
    }
    return ( $time, $datestring, $startTimeAttribute, $endTimeAttribute );
}

sub run_regridder {
    my ( $listfile, $ra_bbox, $outdir, $zoption, $logger ) = @_;

    # Reassemble bounding box into one string
    my $bbox = join( ',', @$ra_bbox );

    # Form science command
    my $scienceAlgorithm
        = "regrid_lats4d.pl -f $listfile -b $bbox -o $outdir $zoption";
    print STDERR "INFO science algorithm: $scienceAlgorithm \n";
    if ($logger) {
        $logger->info("ScienceAlgorithm: $scienceAlgorithm");
    }

    # Call science command
    my $scienceCommand = Giovanni::ScienceCommand->new(
        sessionDir => $outdir,
        logger     => $logger
    );
    my ( $outputs, $messages ) = $scienceCommand->exec($scienceAlgorithm);

# Call science command
#my $scienceCommand = Giovanni::ScienceCommand->new(sessionDir=>$outdir, logger=>$logger);
#my ($outputs,$messages) = run_command($scienceAlgorithm);
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

    # Regrid data to the east of the dateline
    my @eastbox = @$ra_bbox;
    $eastbox[0] = -180.;
    my ( $outeast, $msgeast )
        = run_regridder( $listfile, \@eastbox, $outdir, $zoption, $logger );
    my @outputs = @$outeast;
    rename_tiles( $outeast, ".east" );
    my @outeast = @$outeast;

    # Loop through files, stitching together west and east
    my $n = scalar(@outeast);
    my @regrid_outeast = grep /\.east$/, @outeast;

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
    my ( $vname1, $vname2, $outfile, $files ) = @_;

    # The output from regridder is a single list of files for both variables
    # We'll need to separate them out into two lists, based on vname
    # ASSUMPTION:  The second field in file name is variable name
    # LIMITATION:  This does not address the case when two vnames are the
    #              same (but for different level, for example)
    my $file_string1 = "";
    my $file_string2 = "";
    foreach my $f (@$files) {
        my $f_base = basename($f);
        my ( $file_prefix, $vname, $rest ) = split( '\.', $f_base, 3 );
        if ( $vname eq $vname1 ) {
            $file_string1 .= "<file>$f</file>\n";
        }
        elsif ( $vname eq $vname2 ) {
            $file_string2 .= "<file>$f</file>\n";
        }
        else {
            die("ERROR unrecognized file $f ($vname1, $vname2)\n");
        }
    }
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

sub create_listfile {
    my ( $vname1, $files1, $vname2, $files2, $varinfo, $zselection ) = @_;
    my $reso1 = $varinfo->{$vname1}->{'resolution'};
    my $reso2 = $varinfo->{$vname2}->{'resolution'};

    # Determine which resolution to regrid to
    my ( $gridReference1, $gridReference2 ) = ( "", "" );
    my ( $rlat1, $rlon1 ) = ( $reso1 =~ /([\d\.]+)\s*x\s*([\d\.]+)\s*/ );
    my ( $rlat2, $rlon2 ) = ( $reso2 =~ /([\d\.]+)\s*x\s*([\d\.]+)\s*/ );
    if ( $rlat1 > $rlat2 or $rlon1 > $rlon2 ) {
        $gridReference1 = "gridReference=\"true\"";
    }
    else {
        $gridReference2 = "gridReference=\"true\"";
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

    my @files = ();

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
        $fpath =~ s/^\s+|\s+$//g;
        push( @files, $fpath ) if $fpath ne "";
    }

    return ( $vname, \@files );
}

# Only need this zande as reference on building varinfo hash
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

# Only need this zande as reference on building zselection hash
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

# Construct a "blank" file (_FillValue) of same latitude range is
# incoming, and longitudes extending to some specified western bound
# This will be the middle of an ncrcat sandwich to put two segments
# straddling the dateline on a -180 to 180 grid.
sub make_blank_nc {
    my ( $east_nc, $west_end ) = @_;
    my @vars = Giovanni::Data::NcFile::get_plottable_variables( $east_nc, 0 );
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
        printf NCO 'newval[$time,$lat,$newlon]=%s.get_miss(); ', $var;
        printf NCO 'newval.set_miss(%s.get_miss()); ',           $var;
        printf NCO '%s=newval;',                                 $var;
        print NCO "\n";
    }
    close NCO;
    my $blank_nc = $east_nc;
    $blank_nc =~ s/\.east/.blank/;
    run_command( 'ncap2', '-O', '-o', $blank_nc, '-S', $nco, $east_nc )
        or die "ERROR could not create blank file\n";

    # Delete the existing 'lon' variable
    run_command( 'ncks', '-O', '-o', $blank_nc, '-x', '-v', 'lon',
        $blank_nc );

    # Rename newlon to lon
    run_command(
        'ncrename', '-O',         '-o', $blank_nc,
        '-d',       'newlon,lon', '-v', 'newlon,lon',
        $blank_nc
    ) or die "ERROR could not rename newlon to lon\n";

    return $blank_nc;
}

sub get_data_bounding_box {
    my ( $file, $lat_name, $lon_name ) = @_;
    if ( !defined($lat_name) ) {
        $lat_name = "lat";
    }
    if ( !defined($lon_name) ) {
        $lon_name = "lon";
    }
    my ( $lat_res, $lon_res )
        = spatial_resolution( $file, $lat_name, $lon_name );
    my @lat_values = get_variable_values( $file, $lat_name, $lat_name );
    my @lon_values = get_variable_values( $file, $lon_name, $lon_name );

    # Assume that the latitude and longitude values are centered in the
    # bounding boxes.
    my $west = $lon_values[0] - $lon_res / 2.0;
    my $east = $lon_values[-1] + $lon_res / 2.0;

    my $south = $lat_values[0] - $lat_res / 2.0;
    my $north = $lat_values[-1] + $lat_res / 2.0;

    # Should not have to switch south/north, but makes it more tolerant
    if ( $south > $north ) {
        my $tmp = $north;
        $north = $south;
        $south = $tmp;
    }

    # Make sure north and south are reasonable
    if ( $north > 90 ) {
        $north = 90;
    }
    if ( $south < -90 ) {
        $south = -90;
    }

    return "$west,$south,$east,$north";
}

# Get the time bounds given a variable name
sub get_datetime_bounds {
    my ( $self, $varName ) = @_;
    my $file = $self->{file};
    my $dimListStr
        = Giovanni::Data::NcFile::get_variable_dimensions( $file, 1,
        $varName );
    foreach my $dim ( split( /\s+/, $dimListStr ) ) {
        my ($dimAttr)
            = Giovanni::Data::NcFile::get_variable_attributes( $file, 1,
            $dim );
        next unless defined $dimAttr;
        if ( exists $dimAttr->{standard_name}
            && $dimAttr->{standard_name} eq 'time' )
        {
            if ( exists $dimAttr->{bounds} ) {
                my @timeBounds
                    = Giovanni::Data::NcFile::get_variable_values( $file,
                    $dimAttr->{bounds} );
                my $timeUnit
                    = exists $dimAttr->{units} ? $dimAttr->{units} : '';
                for ( my $i = 0; $i < @timeBounds; $i++ ) {
                    $timeBounds[$i]
                        = Giovanni::Util::cf2datetime( $timeBounds[$i],
                        $timeUnit );
                }
                return @timeBounds;
            }
        }
    }
    return ();
}

sub get_time_range_from_time_dim {
    my ( $self, $varName ) = @_;
    my $file = $self->{file};

    # Try to get the time from time bounds first
    my @timeBounds = $self->get_datetime_bounds($varName);

    # Return the first and the last element of time bounds array if found
    return ( $timeBounds[0], $timeBounds[-1] ) if ( @timeBounds > 1 );

    # Return empty array if time range can't be found
    return ();
}

sub get_time_range {
    my ( $self, $varName ) = @_;

    return $self->get_time_range_from_time_dim($varName);
}

########################################################
### get_names_of_bounds_dimensions
### CF compliant attributes have bounds attributes in the form:
### VAR:bounds = "name of whatever(time) bounds variable" or
### VAR:climatology = "name of climatology bounds variable"
### So this code will return all of the variables that have
### attributes with name 'bounds' or 'climatology'
#########################################################
sub get_names_of_bounds_dimensions {
    my $self  = shift;
    my $xpc   = $self->{xpc};
    my $file  = $self->{file};
    my $reuse = $self->{rootNode};
    my %boundsHash;
    my %dimsHash;

    if ( !( defined($xpc) ) ) {
        return;
    }
    my @nodes = $xpc->findnodes(qq(/nc:netcdf/nc:variable/\@name));

    # for all variables that have bounds attrs (bounds or climatology)
    foreach my $node (@nodes) {
        my $varname = $node->getValue();
        if (   does_variable_attribute_exist( $self, $varname, "bounds" )
            or does_variable_attribute_exist( $self, $varname, "climatology" )
            )
        {
            ;
            my ( $rh_atthash, $ra_attlist )
                = get_variable_attributes( $file, $reuse, $varname );
            foreach my $attr (@$ra_attlist) {

                # if bounds var then store dims
                if ( $attr eq "climatology" or $attr eq "bounds" ) {
                    my $shape = get_variable_dimensions( $file, $reuse,
                        $rh_atthash->{$attr} );
                    my @dims = split( /\s+/, $shape );
                    foreach my $dim (@dims) {
                        $boundsHash{$dim} = $rh_atthash->{$attr};
                    }
                }
                else {

                    # if not bounds var then store dims
                    my $shape
                        = get_variable_dimensions( $file, $reuse, $varname );
                    my @dims = split( /\s+/, $shape );
                    foreach my $dim (@dims) {
                        $dimsHash{$dim} = $varname;
                    }
                }
            }
        }
    }

# remove from boundsHash any dims that aren't exclusively for bounds variables
    foreach my $vardim ( keys %dimsHash ) {
        if ( exists $dimsHash{$vardim} ) {
            delete $boundsHash{$vardim};
        }
    }

    $self->{bounds_names} = \%boundsHash;
    return %boundsHash;

    # Get attributes
}

sub populate_time_and_cell_methods {
    my $self        = shift;
    my $orgMainVar  = shift;
    my $xpc         = $self->{xpc};
    my @varList     = getChildrenNodeList( $self->{rootNode}, 'variable' );
    my $timeDmnName = '';
    my $cell_methods_value;

    ## to find the 'time' dimension from variables
    foreach my $vnode (@varList) {
        my $vname = getAttributeValue( $vnode, 'name' );

        my @attributeList = getChildrenNodeList( $vnode, 'attribute' );

        if ( $vname eq $orgMainVar ) {
            foreach my $attrNode (@attributeList) {
                my $attrName = getAttributeValue( $attrNode, 'name' );
                next if ( $attrName ne "cell_methods" );
                $cell_methods_value = getAttributeValue( $attrNode, 'value' );
                last;
            }
        }
        foreach my $attrNode (@attributeList) {
            my $attrName = getAttributeValue( $attrNode, 'name' );
            next if ( $attrName ne "units" );

            my $attrValue = getAttributeValue( $attrNode, 'value' );
            print STDERR "DEBUG attr name = 'units' and value = $attrValue\n"
                if ( $self->{verbose} );
            if ( $attrValue =~ m/\ssince\s/g ) {
                $timeDmnName = $vname;
                last;
            }
        }
    }

    ( $self->{time_bnds_name}, $self->{time_bnds_type} )
        = $self->get_time_bnds_name($timeDmnName);
    $self->{time_var_name}      = $timeDmnName;
    $self->{cell_methods_value} = $cell_methods_value;
}

sub Filter
{    # Remove values from NetCDF file that are above or below a certain value
    my $workingfile  = shift;
    my $finalVarName = shift;
    my $fillval      = shift;
    my $min          = shift;
    my $max          = shift;

    return 0
        if (!StringBoolean( $min, $fillval )
        and !StringBoolean( $max, $fillval ) );    #nothing to be done

# We want only to convert to fillvalue those values above or below the max or min because the
# max and min themselves are valid. So we do in fact want < > and not <= >=
    my $rangeCommand;
    if (   !StringBoolean( $min, $fillval )
        and StringBoolean( $max, $fillval ) )
    {
        $rangeCommand
            = "ncap2 -O -h -s 'where ( $finalVarName > $max) $finalVarName = $fillval' $workingfile $workingfile.range";
    }
    elsif ( StringBoolean( $min, $fillval )
        and !StringBoolean( $max, $fillval ) )
    {
        $rangeCommand
            = "ncap2 -O -h -s 'where ($finalVarName < $min ) $finalVarName = $fillval' $workingfile $workingfile.range";
    }
    elsif ( StringBoolean( $min, $fillval )
        and StringBoolean( $max, $fillval ) )
    {
        $rangeCommand
            = "ncap2 -O -h -s 'where ($finalVarName < $min || $finalVarName > $max) $finalVarName = $fillval' $workingfile $workingfile.range";
    }
    else {
        warn("Both min and max are fillvalue so there is nothing to do");
    }
    my $status = runNCOCommand( $rangeCommand,
        "Applied the valid data range to the data variable" );
    move_file( "$workingfile.range", $workingfile );
    return $status;
}

# Values retrieved from DataFieldInfo are strings:
# don't exist at all == false
# empty string: ""   == false
# 0 or 0.0           == true
# pos or neg nonzero == true
sub StringBoolean {
    my $value = shift;
    my $fillvalue = shift || -32767;    # OPTIONAL

    # nothing passed at all
    return 0 if ( !defined $value );

    # if empty string is passed:
    return 0 if ( $value eq "" );

    # if the value is a number equal to the fill value, return false
    # if it is a string, not a number this will fail
    # we want this number to exist so that the test itself
    # does not cause a failure
    if ( looks_like_a_number($value) and looks_like_a_number($fillvalue) ) {
        return 0 if ( $value == $fillvalue );
    }

    # if it is a string or any good value or
    # any valid kind of zero:
    return 1 if ( $value or $value == 0 );

    return 0;
}

sub get_value_of_attribute {
    my $file      = shift;
    my $variable  = shift;
    my $attribute = shift;

 # http://nco.sourceforge.net/nco.html#ncks-netCDF-Kitchen-Sink  Section 4.8.1
    my $cmd
        = qq(ncks -M -m $file | grep -E -i "^$variable attribute [0-9]+: $attribute" | cut -f 11- -d ' ' );
    my $value = `$cmd`;
    return $value;
}

sub get_data_pairing_time {
    my $file                = shift;
    my $global_metadata     = shift;
    my $attribute           = shift;
    my $temporal_resolution = shift;
    my $data_time           = @_;
    my ($self)              = @_;

# data pairing is made fairly simple. If we have dataday or datamonth available,
# we use that string for comparing the two data granules. This is a literal string
# comparison. Else, we use global start_time attribute. We will check for dataday
# and datamonth first, then start_time. If we fail to return any of these we need
# to fail abruptly and send error message to user and make.log.

    # First get the temporal resolution from the scrubbed file

    #We have daily, so get the dataday value
    if ( $temporal_resolution eq 'daily' ) {
        my $cmd       = qq(ncks -s '%d' -C -H -v dataday $file);
        my $data_time = `$cmd`;
        return $data_time;
    }

    #We have monthly, so get the datamonth value
    elsif ( $temporal_resolution eq 'monthly' ) {
        my $cmd       = qq(ncks -s '%d' -C -H -v datamonth $file);
        my $data_time = `$cmd`;
        return $data_time;
    }
    elsif ($temporal_resolution eq 'hourly'
        or $temporal_resolution eq '3-hourly'
        or $temporal_resolution eq 'half-hourly'
        or $temporal_resolution eq '8-daily' )
    {    #We have sub-daily data, so get its' value

        my $cmd
            = qq(ncks -M -m $file | grep -E -i "^$global_metadata attribute [0-9]+: $attribute" | cut -f 11- -d ' ' );
        my $data_time = `$cmd`;
        return $data_time;
    }
    else {

        $data_time = '';
        my @info = caller;
        print STDERR "$self->{$data_time}\n";
        die( "Could not find datatime from  $file " . $info[1] . ", line ",
            $info[2] );
    }
}

sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    if ( $AUTOLOAD =~ /.*::getXPathPointer/ ) {
        if ( !$self->{xpc} ) {

            $self->init( $self->getFile() );
        }
        return $self->{xpc};
    }
    elsif ( $AUTOLOAD =~ /.*::getDocRoot/ ) {
        return $self->{docRoot};
    }
    elsif ( $AUTOLOAD =~ /.*::usingTimeBnds/ ) {
        return $self->{time_time_bnds};
    }
    elsif ( $AUTOLOAD =~ /.*::obtainedValidTime/ ) {
        return $self->{obtained_times};
    }
    elsif ( $AUTOLOAD =~ /.*::getFile/ ) {
        return ( $self->{file} );
    }
}

sub string2epoch {
    my @s = split( /[\-: TZ]/, $_[0] );

    # Perl 5.8.8 timegm() does not handle early dates well.
    # (Keep the numbers positive just for safety.)
    # However, it is faster, so we want to use it most of the time
    # TODO:  take this if loop out when we get to 5.12 or higher
    for ( my $i = 3; $i <= 5; ++$i ) {
        $s[$i] = '00' if !$s[$i];
    }

    if ( $s[0] >= 1970 ) {
        return timegm( $s[5], $s[4], $s[3], $s[2], $s[1] - 1, $s[0] );
    }
    else {
        return Date::Manip::Date_SecsSince1970GMT( $s[1], $s[2], $s[0], $s[3],
            $s[4], $s[5] );
    }
}

# Name: cf2epoch($dateString, $increment, $interval, $offset )
sub cf2epoch {
    my ( $cfref, $ra_cftime, $temporal_resolution, $offset ) = @_;

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

1;
__END__

=head1 NAME

Giovanni::Data::NcFile - Perl library for working with netCDF files

=head1 SYNOPSIS

  use Giovanni::Data::NcFile;

  $attr = new NcAttribute('variable' => 'foo', name => 'baz', 'value' => 'bar', ncotype => 'c');

  $rc = Giovanni::Data::NcFile::write_netcdf_file($outfile, $cdl);

  $rc = Giovanni::Data::NcFile::dump_var_1d($ncfile, $reuse, $variable, $output_file);

  $diff = Giovanni::Data::NcFile::diff_netcdf_files($file1, $file2, [@exclude]  );

  $rc = edit_netcdf_attributes($infile, $outfile, @attrs);

  ($lat_res, $lon_res) = Giovanni::Data::NcFile::spatial_resolution($file, $latname, $lonname);

  ($minlat,$maxlat,$minlon,$maxlon) = Giovanni::Data::NcFile::data_bbox($file);

  ($rh_atthash, $ra_attlist) = Giovanni::Data::NcFile::get_variable_attributes($file, $reuse_hdr, $variable)

  $long_name =  Giovanni::Data::NcFile::get_variable_long_name ( $file, $reuse, $variable );

  $ui_name =  Giovanni::Data::NcFile::get_variable_ui_name ( $file, $reuse, $variable );

  $shape =  Giovanni::Data::NcFile::get_variable_dimensions ( $file, $reuse, $variable );

  $type = Giovanni::Data::NcFile::get_variable_type ( $file, $reuse, $variable );

  ($var, $rh_attrs) =  Giovanni::Data::NcFile::get_vertical_dim_var ( $file, $reuse, $variable );

  $rc = Giovanni::Data::NcFile::set_variable_coordinates ( $infile, $outfile, $reuse, $variable );

  $rc = Giovanni::Data::NcFile::make_monotonic_longitude($infile, [$outfile], [$verbose])

  $rc = Giovanni::Data::NcFile::stitch_lon($verbose, $west_file, $east_file, $outfile)

  @outFiles = Giovanni::Data::NcFile::rotate_longitude([$fileIn],[$fileOut],$westLongitude);
   
  %coords = Giovanni::Data::NcFile::find_dims_with_latlon();

  @varnames = find_variables_with_latlon($xpc,%coords);

  $rc = Giovanni::Data::NcFile::reorder_latlon_dimensions($infile,$verbose, [$variable_ref], [$dims], [$reuse]);

  @ordered  =  exchange_dim_pos($%coords, $dimname, $position); (internal);

  $%ordered =  Giovanni::Data::NcFile::find_dims_with_varname($xpc, $varname, $pos, [$infile]);

  @coords =  get_coordinate_names($varNodeList);

  @varname =  get_nondim_variable_names($varNodeList); 

  $status =  Giovanni::Data::NcFile::unpack_nondim_variables($infile,$verbose,[$reuse]);

  @variables =  Giovanni::Data::NcFile::find_variables_with_latlon($xpc,$coords,[$infile]);

  $variable  =  Giovanni::Data::NcFile::find_variable_with_varname($xpc,$coords,[$infile]); 

  $status    =  Giovanni::Data::NcFile::does_variable_exist($xpc,$varname,[$infile]); 

  $status  =  Giovanni::Data::NcFile::reorder_dimension($infile, $varname, $varpos, $verbose, [$variable], [$reuse]);_

  $status  =  Giovanni::Data::NcFile::update_attribute($infile, $attribute, $verbose, $variable, $value);_
  
  $bbox = Giovanni::Data::NcFile::get_data_bounding_box($infile, [$lat_name, $lon_name]);

=head1 DESCRIPTION

This provides utilities for working with netCDF files, in many cases simply by 
calling nco utilities.

=over

=item NcAttribute(['variable' => 'foo'], name => 'baz', 'value' => 'bar', 'ncotype' => 'c', ['action'=>'o']);

This creates a new NcAttribute object. If 'variable' is not specified, it assumes global.
The new() method returns an object of this type.

Action can be 'o' (overwrite=create or modify) or 'd' (delete).

=item write_netcdf_file($netcdf_file, $cdl)

This writes out a netCDF file, using ncgen, given ascii input in the CDL form.
It's useful for test scripts. Returns non-zero if successful, 0 on success.

=item dump_var_1d($netcdf_file, $reuse, $variable, $output_file)

Dump a 1-dimensional variable in ascii to the specified output file.

=item diff_netcdf_files($file1, $file2, [$exclude | \@exclude]  );

This looks at the difference of two files using diff_nc.py. It returns the diff
as a string. An empty string indicates no difference

NCO-created attributes ("NCO", "history", etc.) are automatically excluded.
Other attributes can be excluded using "variable_name/attribute_name" format.
E.g. - @exclude = ("my_var/standard_name","/Conventions") will exclude
my_var's standard_name attribute and the global 'Conventions' attribute.

=item edit_netcdf_attributes($infile, $outfile, @attrs)

This provides an easy to use routine to update attributes in a netCDF file.
It takes both input and output file, but if output file is blank, will write
to the input file.  It also uses the overwrite mode for attributes
(see L<ncatted>).

The attributes are objects created with the NcAttribute class's new() method.
If the variable name is not specified, then global will be assumed.

=item spatial_resolution($file)

The spatial_resolution function infers latitude and longitude resolution from
a netCDF file. It assumes that they are called lat and lon.

=item data_bbox($file)

The data_bbox function infers the bounding box of the data from
a netCDF file. It assumes the coordinates are called lat and lon.
It returns a string in the form west,south,east,north, the better to
parse it with Giovanni::BoundingBox.

=item add_resolution_attributes($file, $latres, $lonres)

The add_resolution_attributes adds latitude_resolution and longitude_resolution
to all plotable variables in a netcdf file.

=item get_plottable_variables($file, $reuse)

The get_plottable_variables gets all the variables in a file that are 
considered 'plottable', which for now means variables with a quantity_type
attribute. Return value is an array.
   
=item get_variable_long_name($file, $reuse, $variable)

Return the long_name attribute for a given variable in the file.

=item get_variable_ui_name($file, $reuse, $variable)

Returns user-readable label for a variable, ideally the same label user sees in Giovanni variable picker

=item get_variable_attributes($file, $reuse_hdr, $variable)

This reads the netcdf header and returns references to both a hash and ordered 
list of the attribute name and values attached to a given variable. 
It returns undef if the file could not be found or read, or if the variable 
could not be found in the file.

In case multiple header parsings are happening, the code allows you to reuse
the read-in, parsed-to-xml-tree header by setting the $reuse argument to non-zero.

(The older, deprecated variable_attributes() routine used a different order of arguments.)

=item global_attributes($file, $reuse_hdr)

This reads the netcdf header and returns references to both a hash and ordered 
list of the attribute name and values at the global level. 
It returns undef if the file could not be found or read, or if the variable 
could not be found in the file.

In case multiple header parsings are happening, the code allows you to reuse
the read-in, parsed-to-xml-tree header by setting the $reuse argument to non-zero.

=item pixellate($infile, $outfile, $ra_vars, $verbose)

This takes a netCDF file as input, and pixellates the output to a higher resolution
using basic nearest neighbor, if and only if one or more of the dimensions is
degenerate, i.e., length of 1. This enables mapping programs to plot it.

The first argument is the input netCDF file, the second is the output, and the
third is a reference to an array of the variables that are to be pixellated.

Note that for this to work, the code relies on attributes latitude_resolution
and longitude_resolution attached to the variables.

Verbose is an integer from 0 to 2. At 2, NCO scripts will be printed out
in DEBUG statements.

=item make_monotonic_longitude($infile, [$outfile], [$verbose])

This takes a netCDF file as input, and converts longitude values to [0,360). 
It returns 1 on success and 0 on failure.

The first argument is the input netCDF file name, the second argument is 
the output file name, and the third argument is the verbose flag (0 or 1, 
default=0). If the output file name is not specified, the input file is overwritten.

=item get_variable_values($infile, $variable, $dim1, [$dim2, $dim3, ...])

This returns an array with the values of $variable with dimension $dim1, $dim2,
$dim3, etc. in $infile. It returns undef if unsuccessful.

=item get_variable_type($file, $reuse, $variable)

Returns a string of the variable type (int, float, double ...)

=item get_variable_dimensions($file, $reuse, $variable)

Returns a space-delimited string of the dimensions for a variable in order.

=item get_vertical_dim_var($file, $reuse, $variable)

Returns the variable corresponding to the vertical dimension of a specified variable. For example, for         
   double AIRX3STD_006_Temperature_A(TempPrsLvls_A) ;
it returns TempPrsLvls_A.  Also returns a reference to a hash of attribuates 
for the vertical dimension variable, like 'units', 'long_name', etc.

=item get_ncdf_version($file)

Returns 3 for netcdf-3 files, 4 for netcdf-4 files, and undefined if it has a
problem

=item to_netCDF4_classic($inFile, $outFile, [$compressionLevel])

Converts a data file to netcdf 4 classic. Returns 1 if successful and 0
otherwise. Compression level is optional and will be set to 1 by default.

=item to_netCDF3($inFile, $outFile)

Converts a data file to netcdf 3. Returns 1 if successful and 0 otherwise.

=item insert_dim_var_for_grads($infile, $outfile, $dimension, $longName, $standardName, $axis, $dir, $verbose)

Inserts a dimension (lat ot lon) into NetCDF file so GrADS can read the NetCDF file. GrADS needs
a discernable X and Y cooridinate or the program cannot read the NetCDF file. This
function takes a NetCDF file and dimension variable and attributes and produces an
output file the is formated with discernable X and Y coordinates. Also updated this method
so that GrADS properly displays time for averaged, accumulated, and instantaneous data sets.
To accomplish this, we simply average the time_bnds pairs and assign this average to the time dimension.

=item read_cdl_data_block()

Reads a __DATA__block at the end of a main(!) program, consisting of one or more CDL strings.
The return is a reference to an array, with each CDL (file equivalent) in its own
element, e.g., my $ra = read_cdl_data_block(); my @cdl = @$ra;

=item stitch_lon($verbose, $west_file, $east_file, $outfile)

Stitch together two netCDF files by longitude, assuming they are adjacent.
This is used for splitting up calculations on either side of 180 deg, and then
putting them back together in one file.

The files must be in order (west, then east), and must have the same dimensions.
N.B.:  THis no longer adds 360 to negative longitude for monotonicity.

=item rotate_longitude($inFileRef, $outFileRef, $westEdgeLongitude, $longitudeVariable)

Rotate longitude so that the first longitude is greater than or equal to 
$westEdgeLongitude. The longitudes less that $westEdgeLongitude are moved to
the end of the longitude array. To keep the array monotonically increasing, the
code adds 360 to the longitudes that are moved. All variables with the 
longitude dimension are also rotated.

The function returns an array of the finished files. If the files needed to be
rotated, this will be @{$outFileRef}. Otherwise, it will be @{$inFileRef}.
 
The $longitudeVariable is optional. If not present, the code will assume the
longitude variable is called 'lon'.

=item subset_and_norm_longitude ( $inFileRef, $outFileRef, $bbox, 
$longitudeVariable, $latitudeVariable )

Subsets files to $bbox. If the resulting files have a discontinuity in the
longitude because they cross the bounding box crossed the 180 meridian (e.g. -
178,179,-180,-179), the longitudes will be updated to removed the 
discontinuity (e.g. - 178,179,180,181).

The function returns an array of the finished files if it succeeds, which will
always be the files in $outFileRef. If the function fails, it will return
undef.

The $longitudeVariable and $latitudeVariable inputs are optional. If not 
present, the code will assume the longitude variable is called 'lon' and the
latitude variable is 'lat'. 

=item reorder_dimensions($infile,$outfile, [variable,$dims])

This is called from ncScrubber to reorder the dimensions of the variable with
latitude and longitude in it. 
It uses ncpdq to reorder the dimensions and then edit_netcdf_attributes to 
re-order the coordinates attribute of that variable.
  
=item find_dims_with_varname

returns the dimensions in a hash which contains two arrays. First in the original order,
second in the order they need to be in. So one of the inputs for this more generic 
find_dims subroutine is the var/dim you are interested in and the new position you 
want it to be in.

=item find_dims_with_latlon 

Find variable whose dimensions are to reordered.
These are returned in a hash where $coords->{org} is original order
and $coords->{ordered} is new order as if unusual name is given for
lat or lon it is only in seeking for degrees that we know which is  which

 Giovanni::Data::NcFile::get_lat_lon_dimnames returns ($lat,$lon)
 dims[0] = lat
 dims[1] = lon

=item findUsingStdNameNotBounds 

Instead of finding a dimension name by it's units such as degrees_east, this subroutine
uses standard name and checks to see if it is not a bounds variable.  If this test fails
it uses the units.

It outputs the name value instead of the node because everywhere it was just getting the value
from the node

=item match_filename

There used to be 2 subroutines, one in Scrubber.pm, the other in NcFile.pm which did almost the same thing.
One was  Scrubber::extractDateString, the other was:  NcFile::populated_start_end_times_from_filename
Now the shared code has been put into match_filename

This is the thing that tries to get the date from the filename

=item find_longitude_node

This is a little fellow moved from Scrubber.pm to find longitude variable based on the 
allowed unit variations.

=item find_latitude_node

This is a little fellow moved from Scrubber.pm to find latitude variable based on the 
allowed unit variations.


=item exchange_dim_pos - a swap routine used in reordering dimensions
 
 Inputs:array of dimension names 
        the dimension being moved to a different place in the order
        The new position it is to be in

=item get_coordinate_names 

This returns all of the coordinates.  The quality of coordinates is that their shape attr = name attr
But it didn't return them in order (if they have been changed). 
So we needed to add the second bit to get it from here instead:
<variable name="AIRX3STD_006_Temperature_A" shape="TempPrsLvls_A time lat lon" type="float">

=item findVariableWithLatLon

This is similar code  to FindDimsThatIncludeLatLon

=item reorder_latlon_dimensions 

This is called from ncScrubber to reorder the dimensions of the variable with
latitude and longitude in it. 
It uses ncpdq to reorder the dimensions and then edit_netcdf_attributes to 
re-order the coordinates attribute of that variable.

If the user knows the variable name already and the order of the dimensions already then
a string and an array may be passed.

=item reorder_dimension 

This is called from ncScrubber to reorder the dimensions of the variable with time;
Use this subroutine to generalize reordering of a particular variable.
It uses ncpdq to reorder the dimensions and then edit_netcdf_attributes to 
re-order the coordinates attribute of that variable.

=item get_data_bounding_box($infile, [$lat_name, $lon_name])

longitude variables in the data file. Returns the bounding box as a string in
"W,S,E,N" format.


=item is_climatology($file, $reuse, $variable) 


Determines if a variable in a file is a climatology variable. Inputs: file,
reuse flag, variable to check. If the reuse flag is set, the code will reuse 
the dumped header. Returns: true or false.


=item get_variable_time_dimension($file, $reuse, $variable)


Returns the name of the CF-1 time dimension variable associated with the 
variable if it exists or undef if it doesn't. Inputs: file, reuse flag, 
variable to check. If the reuse flag is set, the code will reuse the dumped 
header.


=item  get_variable_names ($file, $reuse)


Returns a list of all the variables in a file. Inputs: file, reuse flag. If the 
reuse flag is set, the code will reuse the dumped header.


=item   copy_dimension_to_another_variable_name($self,$var,$newvar) 


makes a copy of a dimension variable (any variable really)
in the same file (so that it can be ncdiff'ed) (ncdiff will 
not subtract dimension variables)

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<ncatted>

=head1 AUTHORS

Chris Lynnes, Christine Smit, Richard Strub, NASA/GSFC

=head1 COPYRIGHT AND LICENSE

TBD

=cut

