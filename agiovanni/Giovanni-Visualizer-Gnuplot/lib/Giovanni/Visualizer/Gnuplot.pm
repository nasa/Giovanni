package Giovanni::Visualizer::Gnuplot;

use 5.008008;
use strict;
use warnings;
use Giovanni::Data::NcFile;
use Giovanni::Util;
use List::Util qw[min max];
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Visualizer::Gnuplot ':all';
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

sub new {
    my ( $class, %params ) = @_;
    my $me = \%params;
    bless $me, $class;
    $me->parse_data_file                 if $me->data_file;
    $me->plot_type( $params{PLOT_TYPE} ) if exists $params{PLOT_TYPE};
    $me->width( $me->{WIDTH} )           if exists $params{WIDTH};
    $me->height( $me->{HEIGHT} )         if exists $params{HEIGHT};
    $me->skip_title( $me->{SKIP_TITLE} ) if exists $params{SKIP_TITLE};
    return $me;
}

sub plot_dimensions {
    my $me = shift;

    # Set the width unless it is already set
    unless ( defined( $me->width ) ) {
        if ( $me->plot_type eq 'TIME_SERIES_GNU' ) {
            $me->width(800);
        }
        elsif ( $me->plot_type eq 'ZONAL_MEAN_GNU' ) {
            $me->width(800);
        }
        elsif ( $me->plot_type eq 'SCATTER_PLOT_GNU' ) {
            $me->width(600);
        }
        elsif ( $me->plot_type eq 'VERTICAL_PROFILE_GNU' ) {
            $me->width(550);
        }
    }

    # Set the height unless it is already set
    # Time series and scatter plot are landscapish
    # Vertical profile is portraitish
    unless ( defined( $me->height ) ) {
        if ( $me->plot_type eq 'TIME_SERIES_GNU' ) {
            $me->height(450);
        }
        elsif ( $me->plot_type eq 'ZONAL_MEAN_GNU' ) {
            $me->height(700);
        }
        elsif ( $me->plot_type eq 'SCATTER_PLOT_GNU' ) {
            $me->height(610);
        }
        elsif ( $me->plot_type eq 'VERTICAL_PROFILE_GNU' ) {
            $me->height(640);
        }
        
        # adjust the height if there is no title
        if ( $me->skip_title() ) {
            $me->height( $me->height() - 50 );
        }
    }
    return ( $me->width, $me->height );
}

sub draw {
    my $me = shift;
    warn( "INFO drawing GNUPLOT for " . $me->data_file . "\n" );

    # Parse data file if we haven't already
    if ( $me->data_file && !$me->plottable_variable ) {
        $me->parse_data_file
            or die "ERROR cannot parse data file $me->data_file\n";
    }
    my $ascii_file = $me->write_ascii_file();
    warn("INFO wrote ascii file $ascii_file\n");
    my $gnufile = $me->write_gnu_script();
    warn("INFO wrote gnu script $gnufile\n");

    # Run returns non-zero on success
    if ( run("gnuplot $gnufile") ) {

#if ((-s $me->plot_file)==0) {
#	warn "ERROR Gnuplot produced an empty " . $me->plot_file . " file using $gnufile\n";
#	return 0;
#}
        if ( $me->shouldPlotAreaStas() ) {
            return ( $me->plot_file, $me->count_file );
        }
        else {
            return ( $me->plot_file );
        }
    }
    else {
        warn "ERROR failed to draw to PNG file "
            . $me->plot_file
            . " using $gnufile\n";
        return 0;
    }
    warn( "INFO ran gnu script to produce " . $me->plot_file . "\n" );
}

sub parse_data_file {
    my $me     = shift;
    my $infile = $me->data_file;

    # Assume only one plottable variable at this point
    my @vars = Giovanni::Data::NcFile::get_plottable_variables( $infile, 0 );
    @vars = sort @vars;   #Make sure x_ is always the first plottable variable
    my $var = $vars[0];
    if ( my @varstated = map /^min_(.*)/, @vars ) {
        $var = $varstated[0];
    }    # Order can still be messed up if we have stats in the file

    if ($var) {
        warn "INFO plottable variable: $var\n";
    }
    else {
        warn "ERROR no plottable variables (with quantity_type) in $infile\n";
        return;
    }
    $me->plottable_variable($var);

    # Slurp up global attributes
    my ( $rh_global, $ra_global )
        = Giovanni::Data::NcFile::global_attributes( $infile, 1 );
    if ( !$me->skip_title() ) {
        $me->plot_hint_title( $rh_global->{'plot_hint_title'} );
        $me->plot_hint_subtitle( $rh_global->{'plot_hint_subtitle'} );
    }

    # Determine variable's min and max
    my @trueDataRange = Giovanni::Util::getNetcdfDataRange( $infile, $var );
    $me->{YMIN_DATA} = $trueDataRange[0];
    $me->{YMAX_DATA} = $trueDataRange[1];

    # Slurp up variable attributes
    my ( $rh_var, $ra_var )
        = Giovanni::Data::NcFile::get_variable_attributes( $infile, 1, $var );
    $me->quantity_type( $rh_var->{quantity_type} );
    $me->units( $rh_var->{units} );

    if ( $me->plot_type eq 'TIME_SERIES_GNU' ) {

        #Check if we have statistics for the main plottable variable
        $me->hasYVarMin( grep( /^min_${var}$/,    @vars ) );
        $me->hasYVarMax( grep( /^max_${var}$/,    @vars ) );
        $me->hasYVarStd( grep( /^stddev_${var}$/, @vars ) );
        $me->hasYVarCount( grep( /^count_${var}$/, @vars ) );
        $me->hasYVarStats( $me->hasYVarMin()
                && $me->hasYVarMax()
                && $me->hasYVarStd()
                && $me->hasYVarCount() );    # Make sure we have all 4 stats

        # Get time axis tics if it is a Time Series plot
        $me->ylabel( $rh_global->{plot_hint_y_axis_label} );
        $me->time_axis_tics(
            $rh_global->{'plot_hint_time_axis_labels'},
            $rh_global->{'plot_hint_time_axis_values'},
            $rh_global->{'plot_hint_time_axis_minor'}
        );
        my @time_tics_values
            = split( ",", $rh_global->{'plot_hint_time_axis_values'} );
        my $time_min_hint = $time_tics_values[0];
        my $time_max_hint
            = $time_tics_values[ scalar(@time_tics_values) - 1 ];
        my ( $time_min_ncfile, $time_max_ncfile )
            = Giovanni::Data::NcFile::getDataRange( $infile, "time" );
        $me->xmin( min( $time_min_hint, $time_min_ncfile ) );
        $me->xmax( max( $time_max_hint, $time_max_ncfile ) );

        #$me->xmin($time_min_hint) if ($time_min_hint<$time_min_ncfile);
        #$me->xmax($time_max_hint) if ($time_max_hint>$time_max_ncfile);
        $me->xvar('time');
        $me->yvar($var);
        my ( $rh_var, $ra_var )
            = Giovanni::Data::NcFile::get_variable_attributes( $infile, 1,
            "time" );
        $me->isClimatology( $rh_var->{'climatology'} );
    }
    if ( $me->plot_type eq 'ZONAL_MEAN_GNU' ) {
        $me->ylabel( $rh_var->{long_name}
                . ( ( $me->units ) ? ' (' . $me->units . ')' : '' ) );
        $me->xvar('lat');
        $me->quantity_type_ref('Latitude');
        $me->units_ref('degrees');
        $me->yvar($var);

        my ( $lat_min_ncfile, $lat_max_ncfile )
            = Giovanni::Data::NcFile::getDataRange( $infile, "lat" );
        $me->xmin( max( -90, $lat_min_ncfile ) );
        $me->xmax( min( 90, $lat_max_ncfile ) );
    }
    if ( $me->plot_type eq 'SCATTER_PLOT_GNU' ) {
        my $var1 = $vars[1];

        if ($var1) {
            warn "INFO plottable variable (Y-axis): $var1\n";
        }
        else {
            warn
                "ERROR no plottable Y-axis variables (with quantity_type) in $infile\n";
            return;
        }

        # Determine variable1's min and max
        $me->{XMIN_DATA} = $me->{YMIN_DATA};
        $me->{XMAX_DATA} = $me->{YMAX_DATA};
        @trueDataRange = Giovanni::Util::getNetcdfDataRange( $infile, $var1 );
        $me->{YMIN_DATA} = $trueDataRange[0];
        $me->{YMAX_DATA} = $trueDataRange[1];

        # Slurp up variable attributes for Y-axis var
        my ( $rh_var1, $ra_var1 )
            = Giovanni::Data::NcFile::get_variable_attributes( $infile, 1,
            $var1 );

#Visualizer.pm is a bit backwards and works with Y axis var by default. Let's override our original settings.
        $me->plottable_variable($var1);
        $me->quantity_type( $rh_var1->{quantity_type} );
        $me->units( $rh_var1->{units} );

        $me->plottable_variable_ref($var);
        $me->quantity_type_ref( $rh_var->{quantity_type} );
        $me->units_ref( $rh_var->{units} );

        $me->xlabel( $rh_var->{plot_hint_axis_title} );
        $me->ylabel( $rh_var1->{plot_hint_axis_title} );

        $me->xvar($var);
        $me->yvar($var1);
    }
    elsif ( $me->plot_type eq 'VERTICAL_PROFILE_GNU' ) {

# For vertical plots, find out which dimension is the vertical one and snag its
# long_name and units for the y axis label
        my ( $vertical, $rh_attrs )
            = Giovanni::Data::NcFile::get_vertical_dim_var( $infile, 1,
            $var );
        my $label = $rh_global->{plot_hint_y_axis_label};
        $me->ylog(1)     if ( $rh_attrs->{units}    =~ /Pa$/ );
        $me->yreverse(1) if ( $rh_attrs->{positive} =~ /down/i );
        $me->ylabel($label);
        $me->xlabel( $me->units );
        $me->xvar($var);
        $me->yvar($vertical);
    }

}

# Accessor for plot_file
sub plot_file {
    my $me = shift;
    if (@_) {
        $me->{PLOT_FILE} = shift;
    }
    elsif ( $me->data_file ) {
        $me->{PLOT_FILE} = $me->data_file . ".png";
    }
    return $me->{PLOT_FILE};
}

# Accessor for count_file
sub count_file {
    my $me         = shift;
    my $count_file = $me->plot_file;
    $count_file =~ s/\.png/_count.png/;
    return $count_file;
}

# Accessor for units; also scrubs useless unitless units
sub units {
    my $me = shift;
    return $me->{UNITS} unless (@_);
    my $units = shift;
    if ( $units && ( $units eq '1' || $units =~ /unitless/i ) ) {
        $me->{UNITS} = '';
    }
    else {
        $me->{UNITS} = $units;
    }
    return $me->{UNITS};
}

sub units_ref {
    my $me = shift;
    return $me->{UNITS_REF} unless (@_);
    my $units = shift;
    if ( $units && ( $units eq '1' || $units =~ /unitless/i ) ) {
        $me->{UNITS_REF} = '';
    }
    else {
        $me->{UNITS_REF} = $units;
    }
    return $me->{UNITS_REF};
}

#Basic procedure for wrapping long strings at max_len characters. Can also be done through fmt - see title()
sub wrap_string {

    my ( $inp_str, $max_len, $delimeter ) = @_;
    $delimeter = ' '
        unless defined $delimeter;    # Optional delimeter parameter

#Couple of options are discussed here: http://stackoverflow.com/questions/956379/how-can-i-word-wrap-a-string-in-perl
#s/(.{1,$max_len}\S|\S+)\s+/$1\n/g;
#s/(.{0,$max_len}(?:\s|$))/$1\n/g;
#s/(?:.{1,79$max_lenS|\S+)\K\s+/\n/g;

    ( my $str_wrapped = $inp_str )
        =~ s/(?=.{$max_len,})(.{0,$max_len}(?:\r\n?|\n\r?)?)($delimeter)/$1$2\\n/g;

    #Escape _ since in gnuplot it is an operator for subscripting
    $str_wrapped =~ s/\_/\\_/g;
    return $str_wrapped;

}

sub time_axis_tics {
    my $me = shift;
    return $me->{TIME_AXIS_TICS} unless @_;
    my ( $tic_labels, $tic_values, $minor_values ) = @_;

    # Convert heritage ncl carriage returns to old fashioned \n
    my @labels = split( ',', $tic_labels );
    my @gnu_labels;
    foreach my $label (@labels) {
        $label =~ s/~C~/\\n/g;
        push @gnu_labels, $label;
    }
    my @tics = split( ',', $tic_values );

    # Put tic values and labels in a hash so we can interleave the minor tics
    my %tics = map { ( $tics[$_], $gnu_labels[$_] ) } 0 .. $#labels;
    if ($minor_values) {
        my @mtics = split( ',', $minor_values );
        foreach my $minor (@mtics) {
            $tics{$minor} = '';    # Minor tics have no labels
        }
    }
    my @xtics;
    foreach my $t ( sort keys %tics ) {
        my $string = '"' . $tics{$t} . '" "' . $t . '"';

        # Set minor tic length to 1
        $string .= " 1" unless $tics{$t};
        push @xtics, $string;
    }
    $me->{TIME_AXIS_TICS} = join( ',', @xtics );
}

#Helper function for deriveing various staistics on the input data
#to be displayed on the scatter plot, including number of all/valid
#data points, RMSE, R2, linear fit, etc.
sub get_linear_fit_stats {
    my $me     = shift;
    my $infile = $me->data_file;
    #######
    my $var1 = $me->plottable_variable_ref();
    my $var2 = $me->plottable_variable();

    my $cdl_file = $me->data_file . ".cdl";
    my $cdl_tmp  = $me->data_file . ".cdl.tmp";
    my $cdl_out  = $me->data_file . ".cdl.nc";

    open( CDL, '>', $cdl_file )
        or die "ERROR Cannot write to cdl script file $cdl_file\n";

    print CDL "*v1=double('" . $var1 . "');\n";
    print CDL "*v2=double('" . $var2 . "');\n";
    print CDL "*miss=double(v1.get_miss());\n";
    print CDL "v1.change_miss(miss);\n";
    print CDL "v2.change_miss(miss);\n";
    if ( !( $me->plot_type eq 'TIME_SERIES_GNU' ) ) {
        print CDL "*xmin=" . $me->xmin_options . ";where (v1<xmin) v1=miss;\n"
            if ( defined( $me->xmin_options ) );
        print CDL "*xmax=" . $me->xmax_options . ";where (v1>xmax) v1=miss;\n"
            if ( defined( $me->xmax_options ) );
    }
    print CDL "*ymin=" . $me->ymin_options . ";where (v2<ymin) v2=miss;\n"
        if ( defined( $me->ymin_options ) );
    print CDL "*ymax=" . $me->ymax_options . ";where (v2>ymax) v2=miss;\n"
        if ( defined( $me->ymax_options ) );

    print CDL "*mask0=double(v1);mask0=1.;\n";
    print CDL "*mask1=double(v1*0+1);\n";
    print CDL "*mask2=double(v2*0+1);\n";
    print CDL "*mask3=double(mask1*mask2);\n";
    print CDL "stats=\"dummy\";\n";
    print CDL "Ntotal=mask0.total();\n";
    print CDL "Nofx    =mask1.total();\n";
    print CDL "Nofy    =mask2.total();\n";
    print CDL "Nall  =mask3.total();\n";
    print CDL "if (Nofx<0 || Nofx==miss) Nofx=0;\n";
    print CDL "if (Nofy<0 || Nofy==miss) Nofy=0;\n";
    print CDL "if (Nall<0 || Nall==miss) Nall=0;\n";
    print CDL "*n=(Nall);\n";
    print CDL "stats\@Ntotal=Ntotal;\n";
    print CDL "stats\@Nall=Nall;\n";
    print CDL "stats\@Nofx=Nofx;\n";
    print CDL "stats\@Nofy=Nofy;\n";
    print CDL "stats\@m=-1;stats\@b=-1;stats\@r=-1;stats\@rmse=-1;\n";
    print CDL "if (n>1) {\n";
    print CDL "where (mask3==mask3) {} elsewhere {v1=miss;v2=miss;};\n";
    print CDL "*sumx  = total(v1);	// compute sum of x\n";
    print CDL "*sumx2 = total(v1^2.);	// compute sum of x^2\n";
    print CDL "*sumxy = total(v1 * v2);	// compute sum of x * y\n";
    print CDL "*sumy  = total(v2);     	// compute sum of y\n";
    print CDL "*sumy2 = total(v2^2.);    //compute sum of y^2\n";
    print CDL "*meanx = sumx / n;    //compute mean of x\n";
    print CDL "*meany = sumy / n;    //compute mean of x\n";
    print CDL
        "stats\@m = total((v1-meanx)*(v2-meany))/total((v1-meanx)*(v1-meanx));    // compute slope \n";
    print CDL
        "stats\@b = meany - stats\@m * meanx;   // compute y-intercept \n";

#print CDL "stats\@m = (n * sumxy  -  sumx * sumy) / (n * sumx2 - (sumx)^2);                 // compute slope\n";
#print CDL "stats\@b = (sumy * sumx2  -  sumx * sumxy) / (n * sumx2  -  (sumx)^2);            // compute y-intercept\n";
    print CDL
        "stats\@r = (sumxy - sumx * sumy / n) / sqrt((sumx2 - (sumx)^2/n) * (sumy2 - (sumy)^2/n));                                           // compute correlation coefficient\n";
    print CDL "stats\@rmse=rms(v2-v1*stats\@m-stats\@b);\n";
    print CDL "};\n";

    #sum_sq= double(total((v1-v2)^2.));   \n";
    #rmse=sqrt(sum_sq/n);\n"
    close CDL;

    my $cdl_exe = "ncap2 -v -O -S $cdl_file $infile $cdl_out";
    warn "About to run $cdl_exe\n";

    # Run returns non-zero on success
    if ( !run("$cdl_exe") ) {
        warn "ERROR failed to compute stats using ncap2 script $cdl_file \n";
        return ( 0, 0, 0, 0, 0, 0, 0, 0 );
    }

    # Slurp up computed attributes
    my %regression_params;
    foreach (`ncks -m -u -H -C -v stats $cdl_out`) {
        if (/stats attribute \d+\: *(\w+),.*?, *value *\= *(.*?)$/) {
            if ( $2 =~ /_/ ) {
                warn "Recevied NaN in computed ncap2 stats";
                $2 =~ s/_//g
                    ; # We should never receive NaN over here, but let's catch it anyway
            }
            $regression_params{$1} = $2 + 0;
        }
    }

    my $records_total = $regression_params{'Ntotal'};
    my $records_fill  = $records_total - $regression_params{'Nall'};
    my $x_fill        = $records_total - $regression_params{'Nofx'};
    my $y_fill        = $records_total - $regression_params{'Nofy'};
    my $m             = $regression_params{'m'};
    my $b             = $regression_params{'b'};
    my $r             = $regression_params{'r'};
    my $rmse          = $regression_params{'rmse'};

    #unlink $cdl_tmp ;
    unlink $cdl_out;

    warn
        "INFO Scatter plot stats: Records: $records_total  Fill records: $records_fill X fill records:$x_fill Y fill records: $y_fill RMSE: $rmse m: $m  b: $b r: $r\n ";

    return ( $records_total, $records_fill, $x_fill, $y_fill, $m, $b, $r,
        $rmse );
}

sub title {
    my $me = shift;

    # Instead of respecting the title/subtitle, we just cat them together
    # and pipe them through fmt
    my $t1          = $me->plot_hint_title;
    my $t2          = $me->plot_hint_subtitle;
    my $title_width = $me->width * 0.1;

    # Pipe concatenated title through fmt
    my $title = `echo \'$t1 $t2\' | fmt -w $title_width`;
    chomp($title);

    # Escape the backslash to survive writing to gnu script
    $title =~ s/\n/\\n/g;
    return '"' . $title . '"';
}

sub write_gnu_script {
    my $me       = shift;
    my $gnu_file = $me->data_file . ".gnu";
    my ( $width, $height ) = $me->plot_dimensions();
    my $empty_series = ",1/0 title \"" . " " . "\" lc rgb 'white' ";

    open( GNU, '>', $gnu_file )
        or die "ERROR Cannot write to gnu script file $gnu_file\n";
    printf GNU "set terminal pngcairo font \"Vera,11\" size %d, %d\n",
        $width,
        $height;
    printf GNU "set output '%s'\n", $me->plot_file;
    printf GNU "set bmargin 4\n";
    if ( !$me->skip_title() ) {
        print GNU "set title ";
        print GNU $me->title;
    }

   if ( !$me->skip_title() ) { # This string is part of the title command 
        if ( $me->plot_type eq 'SCATTER_PLOT_GNU' ) {
            print GNU " offset 0,2";
        }
   }
    print GNU "\n";
    print GNU "set tics scale 2\n";
    printf GNU "set ylabel \"%s\"\n", wrap_string( $me->ylabel, 70 );
    print GNU 'set format y "%g"' . "\n";

#These are additional plotting options that may be populated depending on plot type
#and passed to 'plot'
    my $line_style        = '';
    my $additional_series = '';
    my $error_header      = '';
    my $main_series_title = '';

    if (   $me->plot_type eq 'TIME_SERIES_GNU'
        || $me->plot_type eq 'ZONAL_MEAN_GNU' )
    {
        my $time_tics;

        #Make sure we have at least one data point before we run gnuplot
        my $wcstr = "grep -m 1 \"[0-9]\" " . ${me}->ascii_file;
        chomp( my $hasnumbers = `$wcstr` );
        if ( $hasnumbers eq '' ) {

#Case of empty plot - create an empty plot with an Error message and exit the program
            $error_header = wrap_string(
                "Error:  no valid data points were found for "
                    . $me->yvar
                    . ". Requested plot can not be generated.",
                70,
                "[ \_]"
            );
            print GNU "set label 1 \"$error_header";
            print GNU "\" at graph 0,0.9\n";
            print GNU
                "set tic scale 0;unset border;unset tics;unset title;unset ylabel;unset xlabel;\n";
            print GNU
                "plot [*:*][*:*] 0 notitle lc rgb 'white',1 notitle lc rgb 'white';unset label 1;set border;set tic;\n";
            printf GNU "quit\n";
            close GNU;
            return $gnu_file;
        }

        if ( $me->plot_type eq 'TIME_SERIES_GNU' ) {
            my $bottom_margin = 4;
            $line_style = 'with linespoints lc rgb "black"';
            $time_tics  = $me->time_axis_tics;

#print GNU "set xdata time\n"; # We don't really need this since we are printing time labels on our own anyway
            print GNU "set timefmt '%s'\n";
            printf GNU "set xtics (%s)\n", $time_tics;
            my ( $time_min_ncfile, $time_max_ncfile )
                = Giovanni::Data::NcFile::getDataRange( $me->data_file,
                "time" );

            $additional_series = $empty_series;    # . $empty_series;
            ; #add a series with an empty label at the bottom to prevent title cut-off

   #Check if we have multi-line time tics labels. If we do - add a plot legend
   #with a few empty series to force gnuplot create a proper bottom margin
            if ( $time_tics && $time_tics =~ m/\".*?\\n.*?\"/ ) {
                $additional_series = $additional_series . $empty_series;
                if ( $time_tics =~ m/\".*?\\n.*?\\n.*?\"/ ) {
                    $additional_series = $additional_series . $empty_series;
                }
            }

            print GNU "set key outside\n";
            print GNU "set key under Left reverse\n";

           #print  GNU "set key maxcols 1\n";  #Does not work in older gnuplot
            print GNU "set key vertical\n";

            # Plot fitted line if requested
            $me->plottable_variable_ref('time');
            if ( defined $me->fitLine() && $me->fitLine() ) {
                $main_series_title = '';
                my $fitted_line_title = 'Fitted line';
                my ( $records_total, $records_fill, $x_fill, $y_fill, $m, $b,
                    $r, $rmse )
                    = get_linear_fit_stats($me);
                my $n_records = $records_total - $records_fill;

                # Do a few checks that the fit is sane. Also, if b is
                # really large, the plot would look really bad.
                if (   $n_records > 1
                    && index( "$rmse", "n" ) == -1
                    && index( "$r",    "n" ) == -1 )
                {    # && $b<100
                     #Print stats and fit the line only if have more than one data point
                    $bottom_margin += 1;
                    print GNU "f(x) = "
                        . sprintf( "%.6E", $m ) . "*x + "
                        . sprintf( "%.6E", $b ) . "\n";

#Older gnuplots do not support range on functions
#$additional_series =$additional_series .",[$time_min_ncfile:$time_max_ncfile] f(x) title '$fitted_line_title'";    # lc rgb 'red'
                    $additional_series = $additional_series
                        . ", f(x) title '$fitted_line_title'";

                }
            }
            if ( $me->shouldPlotAreaStas() ) {
                $bottom_margin += 3;
                print GNU "set termoption dash\n";    # Need for old gnuplot
                 #print GNU "set style line 2 linecolor rgb \"black\"pointtype 2 dashtype 2 pointsize default pointinterval 0\n"; # This is how it is done in new Gnuplot
                 #print GNU "set style line 2 linecolor rgb \"black\"pointtype 2 pointsize default pointinterval 0 lt 2\n";
                print GNU
                    "set style line 2 pointsize default pointinterval 0 lt 2\n";
                $additional_series
                    = $additional_series
                    . ", '' using 1:2:5 with yerrorbars ls 1 lc rgb 'black' pt 2 title 'Standard deviation'"
                    . ", '' using 1:3 ls 2 lc rgb 'blue' pt 3 title 'Minimum' with linespoints"
                    . ", '' using 1:4 ls 2 lc rgb 'red' pt 4 title 'Maximum' with linespoints";
            }
            print GNU
                "set bmargin $bottom_margin\n";  # Override to fit plot legend
        }

        if ( $me->plot_type eq 'ZONAL_MEAN_GNU' ) {
            $line_style = 'with linespoints pt 0';
            printf GNU ( "set xlabel \"%s\"\n",
                wrap_string( $me->xlabel, 70 ) )
                if $me->xlabel;
        }

        # Set min and/or max values
        my $yrange = $me->get_yrange();
        print GNU "set yrange $yrange\n" if $yrange;
        my $xrange = $me->get_xrange();
        print GNU "set xrange $xrange\n" if $xrange;
    }
    elsif ( $me->plot_type eq 'SCATTER_PLOT_GNU' ) {

        #Collect stats on the data
        my ( $records_total, $records_fill, $x_fill, $y_fill, $m, $b, $r,
            $rmse )
            = get_linear_fit_stats($me);

        if ( $records_total == 0 || $records_total == $records_fill ) {

#Case of empty plot - create an empty plot with an Error message and exit the program
            $error_header = wrap_string(
                "Error: Scatter Plot for X: "
                    . $me->xvar
                    . " and Y: "
                    . $me->yvar
                    . " can not be generated",
                70,
                "[ \_]"
            );
            my $xrange_str
                = $me->get_xrange() ? ' of ' . $me->get_xrange() : "";
            my $yrange_str
                = $me->get_yrange() ? ' of ' . $me->get_yrange() : "";

            print GNU "set label 1 \"$error_header:\\n\\n";
            print GNU
                " Records total: $records_total (Fill and out of range: $records_fill)\\n";
            print GNU "      X: Fill and out of range$xrange_str: $x_fill\\n";
            print GNU "      Y: Fill and out of range$yrange_str: $y_fill";
            print GNU "\" at graph 0,0.9\n";
            print GNU
                "set tic scale 0;unset border;unset tics;unset title;unset ylabel;unset xlabel;\n";
            print GNU
                "plot [*:*][*:*] 0 notitle lc rgb 'white',1 notitle lc rgb 'white';unset label 1;set border;set tic;\n";
            printf GNU "quit\n";
            close GNU;
            return $gnu_file;
        }

        my $big_plot_min = 500000;
        my $big_plot
            = ( ( $records_total - $records_fill ) > $big_plot_min )
            ? 1
            : 0;

        if ( $big_plot == 1 ) {
            printf GNU "set terminal png size %d, %d\n", $width, $height;
        }

        $line_style = "lc rgb 'blue'";

        my $xrange
            = $me->get_xrange();    # Set min and/or max values if available
        printf GNU "unset bmargin\n";
        printf GNU (
            "set xlabel \"%s\"\n",
            wrap_string( $me->xlabel, ( $big_plot == 1 ) ? 55 : 65 )
        ) if $me->xlabel;
        print GNU "set xrange $xrange\n" if $xrange;

        my $yrange = $me->get_yrange();    # Set min and/or max values
        printf GNU (
            "set ylabel \"%s\"\n",
            wrap_string( $me->ylabel, ($big_plot) == 1 ? 55 : 65 )
        ) if $me->ylabel;
        print GNU "set yrange $yrange\n" if $yrange;

        print GNU "set xtics rotate by -45\n";
        print GNU "set rmargin 5\n";
        print GNU "set size ratio 1\n"
            ;    # forces X and Y axes to appear the same size.

        my $n_records = $records_total - $records_fill;

#Do a few checks that the fit is sane. Also, if b is really large, the plot would look really bad.
        if (   $n_records > 1
            && index( "$rmse", "n" ) == -1
            && index( "$r",    "n" ) == -1 )
        {        # && $b<100
             #Print stats and fit the line only if have more than one data point
            print GNU ($me->skip_title()) ? "set tmargin 3\n" : "set tmargin 4\n";
            print GNU "f(x) = "
                . sprintf( "%.6f", $m ) . "*x + "
                . sprintf( "%.6f", $b ) . "\n";
            my $fit_string
                = "set label sprintf(\"Count: N = %d,        Fit: Y = %.4fX%+4g\\nCorrelation: R = %4g,        RMSE = %4g\",";
            $fit_string
                = $fit_string
                . $n_records . ","
                . sprintf( "%.6f", $m ) . ","
                . sprintf( "%.6f", $b ) . ","
                . sprintf( "%.6f", $r ) . ","
                . sprintf( "%.6f", $rmse );
            $fit_string = $fit_string
                . ")  at graph  0.05, graph  1.08 tc rgb 'red'\n";
            $fit_string =~ s/\+\,/+0,/g;
            print GNU $fit_string;

      #add a series with an empty label at the bottom to prevent title cut-off
            $additional_series
                = ", f(x) lc rgb 'red' notitle" . $empty_series;
        }
        else {

            #Don't print stats when we have only 1 point
            print GNU
                "set label sprintf(\"Count: N = %d\",$n_records)  at graph  0.05, graph  1.1 tc rgb 'red'\n";
            $additional_series = $empty_series;
        }
    }
    elsif ( $me->plot_type eq 'VERTICAL_PROFILE_GNU' ) {
        $line_style = 'with linespoints';
        print GNU "set yrange [] reverse\n" if ( $me->yreverse );
        print GNU "set logscale y\n"        if ( $me->ylog );
        printf GNU ( "set xlabel \"%s\"\n", $me->xlabel ) if $me->xlabel;
        print GNU "set xtics rotate by -45\n";
        print GNU "set rmargin 5\n";
    }

    # Set title to blank to avoid unnecessary legend
    printf GNU
        "plot '%s' using 1:2 $line_style title \"$main_series_title\" $additional_series",
        $me->ascii_file;

    print GNU " \n";

    if ( $me->shouldPlotAreaStas() ) {

        #print GNU "unset title\n";
        print GNU "set yrange [*:*]\n"
            ; # Not sure why the next line is not enough, but older Gnuplot wants it
        print GNU "unset yrange\n";
        printf GNU "set output '%s'\n", $me->count_file;
        print GNU "set ylabel \"Counts\"\n";
        printf GNU "plot '%s' using 1:6 $line_style\n", $me->ascii_file;
    }

    # All done
    printf GNU "quit\n";
    close GNU;
    return $gnu_file;
}

sub write_ascii_file {
    my $me            = shift;
    my $infile        = $me->data_file;
    my $yfile         = "$infile.y";
    my $xfile         = "$infile.x";
    my $file_min      = "$infile.min";
    my $file_max      = "$infile.max";
    my $file_std      = "$infile.std";
    my $file_count    = "$infile.count";
    my $stats_columns = "";
    $me->{ASCII_FILE} = "$infile.txt";

    # Dump each variable in ascii to its own file
    # Then run "paste" to put them in one file, side by side
    Giovanni::Data::NcFile::dump_var_1d( $infile, 1, $me->xvar, $xfile );
    Giovanni::Data::NcFile::dump_var_1d( $infile, 1, $me->yvar, $yfile );

    if ( $me->shouldPlotAreaStas() ) {
        $stats_columns = "$file_min $file_max $file_std $file_count";
        Giovanni::Data::NcFile::dump_var_1d( $infile, 1, 'min_' . $me->yvar,
            $file_min );
        Giovanni::Data::NcFile::dump_var_1d( $infile, 1, 'max_' . $me->yvar,
            $file_max );
        Giovanni::Data::NcFile::dump_var_1d( $infile, 1,
            'stddev_' . $me->yvar, $file_std );
        Giovanni::Data::NcFile::dump_var_1d( $infile, 1, 'count_' . $me->yvar,
            $file_count );
    }

    if ( $me->isClimatology ) {

#Nice cute case of climatology. It is special because of the CF
#conventions, that are not quite what our scintists want. Consequently,
#the data points in the file are in a correct order, but some of the
#time stamps can be exctly one year off. Thus, let's just throw away
#the time stamps altogether and replace them with sequential numbers,
#because why not. In the procesess, we get to use a beautiful perl code
#and remember the time stamps so we can rearrange the time tics hints as well.
#CRITICAL ASSUMPTION: Time labels have exactly the same timestamps as the data.

        open( my $TIME_FILE, '<', $xfile );
        chomp( my @time_array = <$TIME_FILE> );
        @time_array = grep { $_ =~ '\d+' } @time_array;
        run( "seq " . scalar(@time_array) . " > $xfile" );

        my $climaTix;
        if ( scalar(@time_array) > 1 ) {
            for ( my $i = 1; $i <= scalar(@time_array); $i++ ) {

#CRITICAL ASSUMPTION: Time labels have exactly the same timestamps as the data.
                $climaTix = sprintf( "%d", $time_array[ $i - 1 ] );
                $me->{TIME_AXIS_TICS} =~ s/$climaTix/$i/;
            }
        }
        else {

            # Unlike multiple-points climatology, single-point case has time
            # axis hint aligned with time bounds rather than time array
            $me->{TIME_AXIS_TICS} =~ s/\d{5,}/1/;
        }

        $me->xmin( 1.0 );    #Does not work in older gnuplot
        $me->xmax( scalar(@time_array) ) #Does not work in older gnuplot
    }
    run("paste $xfile $yfile $stats_columns | sed -e 's/^.*_.*\$/\\n/' > $me->{ASCII_FILE}"
    );
    unlink( $xfile, $yfile );
    unlink( $file_min, $file_max, $file_std, $file_count )
        if ( $me->shouldPlotAreaStas() );
    return $me->{ASCII_FILE};
}

# TODO: parse error returns
sub run {
    my $script = shift;
    warn "INFO Running $script\n";
    my $rc = system($script);
    exit(1) if $rc;
    return 1;
}

sub ylabel {
    my ( $me, $label ) = @_;

    # Setting ylabel
    if ($label) {
        $me->{YLABEL} = $label;
        return;
    }

    # Getting, if previously set
    return $me->{YLABEL} if ( exists $me->{YLABEL} );

    # Getting, but have not computed yet
    $label = $me->quantity_type;
    my $units = $me->units;
    $label .= ( ' (' . $units . ')' ) if $units;
    $me->{YLABEL} = $label;
    return $label;
}

sub xlabel {
    my ( $me, $label ) = @_;

    # Setting xlabel
    if ($label) {
        $me->{XLABEL} = $label;
        return $label;
    }
    return $me->{XLABEL} if ( exists $me->{XLABEL} );

    if ( defined $me->quantity_type_ref ) {

        # Getting, but have not computed yet
        $label = $me->quantity_type_ref;
        my $units = $me->units_ref;
        $label .= ( ' (' . $units . ')' ) if $units;
        $me->{XLABEL} = $label;
        return $label;
    }
    return;
}

# ACCESSORS
sub plottable_variable {
    my $me = shift;
    @_ ? $me->{PLOTTABLE_VARIABLE} = shift : $me->{PLOTTABLE_VARIABLE};
}

sub plottable_variable_ref {
    my $me = shift;
    @_
        ? $me->{PLOTTABLE_VARIABLE_REF}
        = shift
        : $me->{PLOTTABLE_VARIABLE_REF};
}

sub data_file {
    my $me = shift;
    @_ ? $me->{DATA_FILE} = shift : $me->{DATA_FILE};
}

sub ascii_file {
    my $me = shift;
    @_ ? $me->{ASCII_FILE} = shift : $me->{ASCII_FILE};
}

sub quantity_type {
    my $me = shift;
    @_ ? $me->{QUANTITY_TYPE} = shift : $me->{QUANTITY_TYPE};
}

sub quantity_type_ref {
    my $me = shift;
    @_ ? $me->{QUANTITY_TYPE_REF} = shift : $me->{QUANTITY_TYPE_REF};
}

sub plot_type {
    my $me = shift;
    @_ ? $me->{PLOT_TYPE} = shift : $me->{PLOT_TYPE};
}

sub plot_hint_title {
    my $me = shift;
    @_ ? $me->{PLOT_HINT_TITLE} = shift : $me->{PLOT_HINT_TITLE};
}

sub plot_hint_subtitle {
    my $me = shift;
    @_ ? $me->{PLOT_HINT_SUBTITLE} = shift : $me->{PLOT_HINT_SUBTITLE};
}
sub height { my $me = shift; @_ ? $me->{HEIGHT} = shift : $me->{HEIGHT} }
sub width  { my $me = shift; @_ ? $me->{WIDTH}  = shift : $me->{WIDTH} }

sub yvar { my $me = shift; @_ ? $me->{YVAR} = shift : $me->{YVAR} }
sub ymax { my $me = shift; @_ ? $me->{YMAX} = shift : $me->{YMAX} }
sub ymin { my $me = shift; @_ ? $me->{YMIN} = shift : $me->{YMIN} }

sub yreverse {
    my $me = shift;
    @_ ? $me->{YREVERSE} = shift : $me->{YREVERSE};
}
sub ylog { my $me = shift; @_ ? $me->{YLOG} = shift : $me->{YLOG} }

sub xvar { my $me = shift; @_ ? $me->{XVAR} = shift : $me->{XVAR} }
sub xmax { my $me = shift; @_ ? $me->{XMAX} = shift : $me->{XMAX} }
sub xmin { my $me = shift; @_ ? $me->{XMIN} = shift : $me->{XMIN} }

sub xreverse {
    my $me = shift;
    @_ ? $me->{XREVERSE} = shift : $me->{XREVERSE};
}
sub xlog { my $me = shift; @_ ? $me->{XLOG} = shift : $me->{XLOG} }

sub fitLine {
    my $me = shift;
    @_ ? $me->{FITLINE} = shift : $me->{FITLINE};
}

sub areaStats {
    my $me = shift;
    @_ ? $me->{AREASTATS} = shift : $me->{AREASTATS};
}

sub isClimatology {
    my $me = shift;
    @_ ? $me->{ISCLIMATOLOGY} = shift : $me->{ISCLIMATOLOGY};
}

sub hasYVarMin {
    my $me = shift;
    @_ ? $me->{HASYVARMIN} = shift : $me->{HASYVARMIN};
}

sub hasYVarMax {
    my $me = shift;
    @_ ? $me->{HASYVARMAX} = shift : $me->{HASYVARMAX};
}

sub hasYVarCount {
    my $me = shift;
    @_ ? $me->{HASYVARCOUNT} = shift : $me->{HASYVARCOUNT};
}

sub hasYVarStd {
    my $me = shift;
    @_ ? $me->{HASYVARSTD} = shift : $me->{HASYVARSTD};
}

sub hasYVarStats {
    my $me = shift;
    @_ ? $me->{HASYVARSTATS} = shift : $me->{HASYVARSTATS};
}

sub skip_title {
    my $me = shift;
    @_ ? $me->{SKIP_TITLE} = shift : $me->{SKIP_TITLE};
}

# Returns padded value to be used on the axis range by gnuplot
# Returns is '*' if value is not set. Otherwise, returns
# the value formatted (i.e., rounded) the same way as the
# dumped values text file to avoid accumulation of precision error.
# The value is reduced by var_value / 1000000 if it is the min
# component of the range, and is increased by var_value / 1000000
# if it is the max component of the range.
sub get_range_value {
    my ( $me, $var_value, $var_name, $range_type ) = @_;
    return '*' unless defined($var_value);
    my $format = Giovanni::Data::NcFile::get_format_string_for_variable(
        $me->data_file, 1, $var_name );
    my $formated_value = sprintf( $format, $var_value );
    return $formated_value
        + ( $range_type eq 'min' ? -1 : 1 ) * $var_value / 1000000.;
}

# Find the range of the x variable (to write into gnuplot script file)
# Note that we massage the range a little bit to make sure all datapoints
# showup on the plot (otherwise boundary points might disappear b/c of the
# loss of precision on default values). This is ok since this only has
# effect on the range of the axis. Has no effect on the data itself.
sub get_xrange {
    my $me = shift;
    return '' unless defined( $me->xmin ) || defined( $me->xmax );
    my $xmin = $me->get_range_value( $me->xmin, $me->xvar, 'min' );
    my $xmax = $me->get_range_value( $me->xmax, $me->xvar, 'max' );
    return '[' . $xmin . ':' . $xmax . ']';
}

# Find the range of the y variable (to write into gnuplot script file)
# Note that we massage the range a little bit to make sure all datapoints
# showup on the plot (otherwise boundary points might disappear b/c of the
# loss of precision on default values). This is ok since this only has
# effect on the range of the axis. Has no effect on the data itself.
sub get_yrange {
    my $me = shift;
    return '' unless defined( $me->ymin ) || defined( $me->ymax );
    my $ymin = $me->get_range_value( $me->ymin, $me->yvar, 'min' );
    my $ymax = $me->get_range_value( $me->ymax, $me->yvar, 'max' );
    return '[' . $ymin . ':' . $ymax . ']';
}

# This block acts similar to xmin/xmax/ymin/ymax, but returns undef if the set
# min / max value is close to the data min/max (this is to deal with default values)
sub ymax_options {
    my $me = shift;
    if (@_) {
        $me->{YMAX} = shift;
    }
    else {
        return undef
            if ( defined $me->{YMAX}
            && defined $me->{YMAX_DATA}
            && sprintf( "%g", $me->{YMAX} ) eq
            sprintf( "%g", $me->{YMAX_DATA} ) );
        return $me->{YMAX};
    }
}

sub ymin_options {
    my $me = shift;
    if (@_) {
        $me->{YMIN} = shift;
    }
    else {
        return undef
            if ( defined $me->{YMIN}
            && defined $me->{YMIN_DATA}
            && sprintf( "%g", $me->{YMIN} ) eq
            sprintf( "%g", $me->{YMIN_DATA} ) );
        return $me->{YMIN};
    }
}

sub xmax_options {
    my $me = shift;
    if (@_) {
        $me->{XMAX} = shift;
    }
    else {
        return undef
            if ( defined $me->{XMAX}
            && defined $me->{XMAX_DATA}
            && sprintf( "%g", $me->{XMAX} ) eq
            sprintf( "%g", $me->{XMAX_DATA} ) );
        return $me->{XMAX};
    }
}

sub xmin_options {
    my $me = shift;
    if (@_) {
        $me->{XMIN} = shift;
    }
    else {
        return undef
            if ( defined $me->{XMIN}
            && defined $me->{XMIN_DATA}
            && sprintf( "%g", $me->{XMIN} ) eq
            sprintf( "%g", $me->{XMIN_DATA} ) );
        return $me->{XMIN};
    }
}

sub shouldPlotAreaStas {
    my $me = shift;
    return
           $me->hasYVarStats()
        && defined $me->areaStats()
        && $me->areaStats();
}
    __END__
    
    =head1 NAME
    
    Giovanni::Visualizer::Gnuplot - Perl extension for creating plots using gnuplot.
    
    =head1 SYNOPSIS
    
      use Giovanni::Visualizer::Gnuplot;
    
      $plot = new Giovanni::Visualizer::Gnuplot(
        DATA_FILE=>filename,
        PLOT_TYPE=>"SCATTER_PLOT_GNU",
        YMAX => maxval, 
        YMIN => minval,
        SKIP_TITLE => 1);
    
      $png_file = $plot->draw();
    
    =head2 Get/Set Accessors
    
    Calling programs can set or get the plot range by calling:
      ymin()
      ymax()
      xmin()
      xmax()
    The default is dynamically computed from the data.
    
    Calling programs can set/get the width or height of the plot in pixels via:
      width() - Default is 800
      height() - Default is 450
    
    
    The following accessors exist, but are not usually needed by calling programs.
      plottable_variable()
      data_file()
      ascii_file()
      quantity_type()
      plot_hint_title()
      plot_hint_subtitle()
    
    =head1 DESCRIPTION
    
    This module drives the Gnuplot program in order to create PNG plots from netCDF
    data in Giovanni-4. Currently only time series is supported, with plans to add
    vertical profile and x-y plots.
    
    Most programs will simply instantiate a new object with the DATA_FILE set to the data file, then call the draw() method. Some may want to modify the following 
    attributes, either at instantiation or later using the accessors (before
    calling draw()).
    
    If the SKIP_TITLE option is set, the plot will not have a title.
    
    Typicall call chain:
    
    new
        parse_data_file
        Giovanni::Data::NcFile::get_plottable_variables
        Giovanni::Data::NcFile::global_attributes
        Giovanni::Data::NcFile::get_variable_attributes
        units
        time_axis_tics
        ylabel
        xlabel
        Giovanni::Data::NcFile::get_vertical_dim_var (if vertical profile)
        set attributes:
        plot_type
        width
        height
    draw
        parse_data_file (if has not parsed alread)
        write_ascii_file (nc file serialized to a text file)
        Giovanni::Data::NcFile::dump_var_1d
        write_gnu_script (cooks script for gnuplot)
        plot_dimensions
        get_yrange
        get_linear_fit_stats (for scatter plot)
        call gnuplot on input file and script
    
    =head1 EXAMPLE
    
      $time_series_plot = new Giovanni::Visualizer::Gnuplot(DATA_FILE=>$ncfile);
      $pngfile = $time_series_plot->draw();
    
    =head1 AUTHOR
    
    Chris Lynnes, NASA
    Maksym Petrenko, ADNET
    Christine Smit, Telophase
    
    =cut
    
    
    
