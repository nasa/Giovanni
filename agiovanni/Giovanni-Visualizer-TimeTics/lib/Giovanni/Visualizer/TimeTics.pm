package Giovanni::Visualizer::TimeTics;

use strict;
use warnings;
use List::Util qw(min max);
use List::MoreUtils qw(any);
use Giovanni::Data::NcFile;
use Giovanni::Visualizer::TimeTics::Climatology;
use DateTime;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Visualizer::TimeTics ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
# our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# our @EXPORT = qw( );

our $VERSION = '0.02';

# Preloaded methods go here.

1;

=head1 NAME

Giovanni::Visualizer::TimeTics - compute nice tic marks, esp. for time axes

=head1 SYNOPSIS

use TimeTics;

set_plot_hint_time_axis ( $ncfile );

$tics = new TimeTics('start' => $start, 'end' => $end);

$ra_tic_vals = $tics->values;

$ra_tic_labels = $tics->labels;

$ra_tic_minor = $tics->minor;

=head1 DESCRIPTION

Compute aesthetically pleasing tic values for time axes.

=over 4

=item set_plot_hint_time_axis ( $ncfile )

For a given netCDF file, this first looks for global attributes 
start_time and end_time, and if not found, 
'userstartdate' and 'userenddate' in the file, and then computes time axis
values and labels. It then adds global attributes:
  :plot_hint_time_axis_values
  :plot_hint_time_axis_minor
  :plot_hint_time_axis_labels

=item new('start' => $start, 'end' => $end)

Takes start and end times of the form 'YYYY-MM-DD [HH:MM:SS]', and computes the
major and minor tic axis values in seconds since 1970-01-01. It also computes
labels optimized (currently) for ncl (using ~C~ to indicate carriage returns
in labels).  The intervals are based on the time difference between the start
and end date/times.

=item values()

Returns a reference to an array of major tic mark epochal times 
(since 1970-01-01).

=item minor()

Returns a reference to an array of minor tic mark epochal times 
(since 1970-01-01).

=item labels()

Returns a reference to an array of major tic mark labels.

=head1 AUTHOR

Christopher Lynnes, ported from Jianfu Pan's set_locators.py

=cut

################################################################################
# $Id: TimeTics.pm,v 1.14 2014/12/30 00:14:19 dedasilv Exp $
# -@@@ aGiovanni, $Name:  $
################################################################################

sub new {
    my ( $pkg, %params ) = @_;
    my $tics = bless \%params, $pkg;
    if ( $tics->start && $tics->end ) {
        $tics->compute_tics;
    }
    return $tics;
}

sub set_plot_hint_time_axis {
    my ( $ncfile, %opts ) = @_;
    my $tics;

    if ( $opts{is_climatology} ) {
        my $ra_time_bnds = Giovanni::Data::NcFile::get_time_bounds($ncfile);
        $tics = Giovanni::Visualizer::TimeTics::Climatology->new(
            'time_bnds' => $ra_time_bnds );
    }
    else {

        # Find start_time and end_time, or as a failsafe,
        # userstartdate and userenddate in netcdf file
        local ($/) = undef;
        my $header = `ncdump -h $ncfile`;
        my ($start) = ( $header =~ m/:userstartdate = "(.*?)"/s );
        ($start) = ( $header =~ m/:start_time = "(.*?)"/s ) unless ($start);
        my ($end) = ( $header =~ m/:userenddate = "(.*?)"/s );
        ($end) = ( $header =~ m/:end_time = "(.*?)"/s ) unless ($end);
        unless ( $start && $end ) {
            warn("could not get user start/end date from $ncfile\n");
            return 0;
        }
        my ($temporal_resolution)
            = ( $header =~ m/:temporal_resolution = "(.*?)"/s );

        # Create a Giovanni::Visualizer::TimeTics object
        $tics = new Giovanni::Visualizer::TimeTics(
            'start'               => $start,
            'end'                 => $end,
            'temporal_resolution' => $temporal_resolution
        );
    }

    # Form the plot_hint_* arguments for ncatted
    my (@cmd);
    push @cmd, "ncatted";
    push @cmd, ncatted_arg( 'plot_hint_time_axis_values', $tics->values )
        if ( $tics->values );
    push @cmd, ncatted_arg( 'plot_hint_time_axis_labels', $tics->labels )
        if ( $tics->labels );
    push @cmd, ncatted_arg( 'plot_hint_time_axis_minor', $tics->minor )
        if ( $tics->minor );
    push @cmd, $ncfile;

    # execute ncatted to modify netcdf file IN PLACE
    my $rc = system(@cmd);

    # Return 0 if command failed
    warn "Failed to set plot_time_axis in $ncfile\n" if ( $rc != 0 );
    return ( $rc == 0 );
}

sub ncatted_arg {
    my ( $attr, $ra_vals ) = @_;
    my $string = join( ',', @$ra_vals );
    return ( '-a', sprintf( "%s,global,c,c,%s", $attr, $string ) );
}

sub compute_tics {
    my $this = shift;

    # Compute time difference
    my $start_epoch         = iso2epoch( $this->start );
    my $end_epoch           = iso2epoch( $this->end );
    my $tdiff               = $end_epoch - $start_epoch;
    my $temporal_resolution = $this->temporal_resolution;

    # delta_yr only needs to be approximate
    my $delta_yr   = $tdiff / ( 86400 * 365 );
    my $delta_days = $tdiff / 86400;
    my $delta_hrs  = $tdiff / 3600;
    my ( @labels, @values );

    if    ( $delta_yr > 15 ) { $this->yeartics($delta_yr); }
    elsif ( $delta_yr > 5 )  { $this->yeartics( $delta_yr, 5, 1 ); }
    elsif ( $delta_yr > 3 )  { $this->yeartics( $delta_yr, 1, [ 3, 6, 9 ] ); }
    elsif ( $delta_yr > 2 )           { $this->monthtics( 6, 3 ); }
    elsif ( $delta_days > 365 * 1.5 ) { $this->monthtics( 3, 1 ); }
    elsif ( $delta_days > 180 )       { $this->monthtics( 2, 1 ); }
    elsif ( $delta_days > 92 )        { $this->monthtics(1); }
    elsif ( $delta_days >= 48 ) { $this->monthtics( 1, [16] ); }
    elsif ( $delta_days >= 13 ) {
        ( $temporal_resolution =~ /month/ )
            ? $this->monthtics(1)
            : $this->daytics( 5, 1 );
    }
    elsif ( $delta_days >= 5 ) { $this->daytics(1); }
    elsif ( $delta_hrs >= 48 ) { $this->hourtics( 12, 6 ); }
    elsif ( $delta_hrs >= 12 ) { $this->hourtics( 6, 3 ); }
    elsif ( $delta_hrs >= 6 )  { $this->hourtics( 3, 1 ); }
    else                       { $this->hourtics(1); }
}

sub hourtics {
    my ( $this, $major, $minor ) = @_;

    # Convert date times from ISO to epochal
    my @start = split( /[\-\.T :Z]/, $this->start );
    $start[3] ||= 0;
    $start[4] = 0;
    $start[5] = 0;
    my $start = ymdhms2epoch(@start);

    # Want the start to be on the next "full" increment, e.g.
    #  1600 w/ increment of 3 hrs -> 1800
    my $hr_inc = $start[3] % $major;
    if ( $hr_inc > 0 ) {
        my $add_hrs = int( $start[3] / $major + 1 ) * $major - $start[3];
        $start += $add_hrs * 3600;
    }

    my $end = iso2epoch( $this->end );

    # Increment by $major hours, converted to seconds
    my ( $t, $tminor, @minor, @values, @labels );
    my $skip = 3600 * $major;
    $minor *= 3600 if ($minor);
    for ( $t = $start; 1; $t += $skip ) {
        push( @values, $t );
        my $dt = DateTime->from_epoch( epoch => $t );
        my $label = sprintf( "%02dZ", $dt->hour );

        # Add day/month/year to first tic and whenever we hit 0
        $label
            .= sprintf( "~C~%d %s~C~%d", $dt->day, $dt->month_abbr,
            $dt->year )
            if ( $t == $start || $dt->hour == 0 );

        push @labels, $label;
        last if ( $t >= $end );

        # Minor increment
        if ($minor) {
            for ( $tminor = $minor; $tminor < $skip; $tminor += $minor ) {
                push @minor, $t + $tminor;
            }
        }
    }

# If we had some 00Zs in the sequence, we don't need day/month/year on the first tic
    $labels[0] =~ s/\~C.*$//
        if ( ( $labels[0] !~ /00Z/ ) && grep /00Z/, @labels );

    # Set the properties
    $this->labels( \@labels );
    $this->values( \@values );
    $this->minor( \@minor ) if @minor;
}

sub daytics {
    my ( $this, $major, $minor ) = @_;

    # Convert date times from ISO to epochal
    my $start = iso2epoch( $this->start );
    my $end   = iso2epoch( $this->end );

    # Increment by $major days, converted to seconds
    my ( $t, $tminor, @minor, @values, @labels );
    my $skip = 86400 * $major;
    $minor *= 86400 if $minor;
    for ( $t = $start; 1; $t += $skip ) {
        push( @values, $t );
        my $dt = DateTime->from_epoch( epoch => $t );
        push @labels,
            sprintf( "%d %s~C~%04d", $dt->mday, $dt->month_abbr, $dt->year );

        last if ( $t >= $end );

        # Minor increment
        if ($minor) {
            for ( $tminor = $minor; $tminor < $skip; $tminor += $minor ) {
                push @minor, $t + $tminor;
            }
        }
    }
    prune_years( \@labels );
    $this->labels( \@labels );
    $this->values( \@values );
    $this->minor( \@minor ) if @minor;
}

sub monthtics {
    my ( $this, $major, $ra_minor ) = @_;

    my $start_yr  = substr( $this->start, 0, 4 );
    my $start_mon = substr( $this->start, 5, 2 );
    my $end_yr    = substr( $this->end,   0, 4 );
    my $end_mon   = substr( $this->end,   5, 2 );
    my $end_yymm = sprintf( "%04d%02d", $end_yr, $end_mon );
    my ( $m, $y, @values, @labels, @minor );
    for ( $m = $start_mon - 1, $y = $start_yr;; $m += $major ) {
        if ( $m > 11 ) {
            $m %= 12;
            $y++;
        }

        # add one because $m is zero-based
        my $yymm = sprintf( "%04d%02d", $y, $m + 1 );
        my $label = &mm2mon($m);
        $label .= "~C~$y";

        # Add day to label for short increments
        $label = '1 ' . $label unless ( $major >= 2 );
        push @labels, $label;
        push @values, ymdhms2epoch( $y, $m + 1, 1, 0, 0, 0 );

        last if ( $yymm gt $end_yymm );

        # Add minor tic marks on days of month (locations only, no labels);
        if ( ref($ra_minor) ) {
            foreach my $day (@$ra_minor) {
                push @minor, ymdhms2epoch( $y, $m + 1, $day, 0, 0, 0 );
            }
        }

        # Case where argument is a simple scalar increment
        elsif ($ra_minor) {
            my ( $mm, $yy, $i );
            for ( $i = 1; $i < $major; $i++ ) {
                $mm = $m + $i;
                $yy = $y;
                if ( $mm > 11 ) {
                    $mm %= 12;
                    $yy = $y + 1;
                }
                my $yymm = sprintf( "%04d%02d", $yy, $mm + 1 );
                last if ( $yy gt $end_yymm );
                push @minor, ymdhms2epoch( $yy, $mm + 1, 1, 0, 0 );
            }
        }
    }
    prune_years( \@labels );
    $this->labels( \@labels );
    $this->values( \@values );
    $this->minor( \@minor ) if @minor;
}

sub prune_years {
    my $ra_labels = shift;
    my $i;
    my $n = scalar(@$ra_labels);
    my ($last_yr) = ( $ra_labels->[0] =~ /~C~(\d\d\d\d)/ );
    my $got_years = 0;

# Algorithm:  keep only year labels when it is different from the previous label
# Note that we change strings in place
    for ( $i = 1; $i < $n; $i++ ) {
        my ($yr) = ( $ra_labels->[$i] =~ /~C~(\d\d\d\d)/ );

        # Same as last, delete year from label
        if ( $yr == $last_yr ) {
            $ra_labels->[$i] =~ s/~C~\d\d\d\d//;
        }

        # Keep year label when it changes
        else {
            $last_yr = $yr;
            $got_years++;
        }
    }

    # Only need the label on the first year if we didn't keep any years above
    $ra_labels->[0] =~ s/~C~\d\d\d\d// if ($got_years);
}

sub mm2mon {
    return (
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    )[ $_[0] ];
}

sub yeartics {
    my ( $this, $delta_yr, $inc, $ra_minor ) = @_;

    # Set tic intervals for a 1-9 range
    # Then scale them by number of zeroes
    unless ($inc) {
        my @inc = ( 0.1, 0.2, 0.5, 0.5, 1., 1., 1., 1., 1., 1. );
        my $mult = 10.**int( log10($delta_yr) );
        $inc = $mult * $inc[ int( $delta_yr / $mult ) + 1 ];
    }

    # Line up major tics on even increments of $inc
    # e.g., yr0=1999, inc=5 => yr1=1995
    my $yr0 = substr( $this->start, 0, 4 );
    my $yr1 = $yr0 - ( $yr0 % $inc );
    my $yr2 = substr( $this->end, 0, 4 );
    my $y;
    my ( @labels, @values, @minor );
    for ( $y = $yr1; 1; $y += $inc ) {

        #...but don't make any tics before yr0...
        if ( $y >= $yr0 ) {
            push @labels, $y;
            push @values, ymdhms2epoch( $y, 1, 1, 0, 0, 0 );
        }
        last if ( $y > $yr2 );

        # Though we will construct minor tics
        if ($ra_minor) {
            if ( ref($ra_minor) ) {
                foreach my $mon (@$ra_minor) {
                    push @minor, ymdhms2epoch( $y, $mon + 1, 1, 0, 0, 0 );
                }
            }
            else {
                my ( $i, $yminor );
                for ( $i = 1; $i < $inc; $i += $ra_minor ) {
                    $yminor = $y + $i;
                    push @minor, ymdhms2epoch( $yminor, 1, 1, 0, 0, 0 )
                        if ( $yminor >= $yr0 && $yminor <= $yr2 );
                }
            }
        }
    }
    $this->{'labels'} = \@labels;
    $this->{'values'} = \@values;
    $this->{'minor'}  = \@minor if @minor;
}

sub ymdhms2epoch {

    # Save args so we can use map{} later
    my @args = @_;

 # Parts in order expected in args; may not get all (like time), but that's OK
    my @t = qw(year month day hour minute second);

    # Map into a hash suitable for passing to DateTime constructor
    my %t = map { ( $t[$_], $args[$_] ) } 0 .. $#args;
    my $dt = DateTime->new(%t);
    return $dt->epoch;
}

sub iso2epoch {
    my $string = shift;
    my ( $date, $time, $hr, $min, $sec );
    if ( $string =~ /[T ]/ ) {
        ( $date, $time ) = split( /[T ]/, $string );
        ( $hr, $min, $sec ) = split( '[:Z]', $time );
    }
    else {
        $date = $string;
    }
    $hr  ||= 0;
    $min ||= 0;
    $sec ||= 0;
    my ( $year, $mon, $mday ) = split( /[\-\.]/, $date );

    my $dt = DateTime->new(
        year   => $year,
        month  => $mon,
        day    => $mday,
        hour   => $hr,
        minute => $min,
        second => $sec
    );
    return $dt->epoch;
}
sub log10 { log( $_[0] ) / log(10.) }

sub start {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'start'}
        = $_[0]
        : $this->{'start'};
}

sub end {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'end'}
        = $_[0]
        : $this->{'end'};
}

sub temporal_resolution {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'temporal_resolution'}
        = $_[0]
        : ( $this->{'temporal_resolution'} || 'N/A' );
}

sub values {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'values'}
        = $_[0]
        : $this->{'values'};
}

sub labels {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'labels'}
        = $_[0]
        : $this->{'labels'};
}

sub minor {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'minor'}
        = $_[0]
        : $this->{'minor'};
}
