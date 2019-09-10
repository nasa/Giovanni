#$Id: Time.pm,v 1.6 2015/01/26 22:22:38 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

Giovanni::Visualizer::Hints::Time - handles time for plot hints

=head1 SYNOPSIS

use Giovanni::Visualizer::Hints::Time;

  print Giovanni::Visualizer::Hints::Time::formatTime(
     TIME_STRING => "2003-01-01T00:00:00Z", 
     INTERVAL    => "hourly", 
     IS_START    => 1);
  # --> prints '2003-01-01 00Z

  print Giovanni::Visualizer::Hints::Time::formatTime(
     TIME_STRING => "2003-01-01T00:00:00Z", 
     INTERVAL    => "daily", 
     IS_START    => 1);
  # --> prints '2003-01-01'

  print Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING    => "2008-12-01T00:00:00Z",
        INTERVAL       => "monthly",
        IS_START       => 1,
        IS_CLIMATOLOGY => 1);
  # --> prints 'Dec'
  
  if(Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2004:05:02T00:00:00Z",
        END_TIME   => "2004:05:02T23:59:59Z",
        INTERVAL   => 'daily')){
      print("Just one day");
  }

=head1 DESCRIPTION

Has the logic associated with time from plot hints

=head2 FORMAT TIME RANGE: Giovanni::Visualizer::Hints::Time::formatTimeRange($startTime, $endTime, $timeInterval, $justYear)

Formats time strings to drop the obvious bits. For example, if the time range 
for a daily result is 2003-01-01T00:00:00Z - 2003-01-05T23:59:59Z, then calling
this code for both dates would yield 2003-01-01 - 2003-01-05. In contrast,
an hourly result would yield '2003-01-01 00Z - 2003-01-05 23Z'.

START_TIME - the start time to format

END_TIME - the end time to format

INTERVAL - hourly, daily, monthly, half-hourly

JUST_YEAR - just return the year (used for seasonal stuff)

=head2 FORMAT TIME: Giovanni::Visualizer::Hints::Time::formatTime($timeStr, $timeInterval, $isStart, $justYear)

Formats time strings to drop the obvious bits. For example, if the time range 
for a daily result is 2003-01-01T00:00:00Z - 2003-01-05T23:59:59Z, then calling
this code for each date would yield 2003-01-01 and 2003-01-05. In contrast,
an hourly result would yield '2003-01-01 00Z' and '2003-01-05 23Z'.

TIME_STRING - the time to format

INTERVAL - hourly, daily, monthly, half-hourly

IS_START - true if this is the start of the time interval and false otherwise

JUST_YEAR - just return the year (used for seasonal stuff)

=head2 ONE SLICE:  Giovanni::Visualizer::Hints::Time::isWithinOneSlice()

Sometimes plot hints needs to know if this is a single 'slice'
of data - i.e. a single hour, a single day, or a single month

START_TIME - start time string

END_TIME - end time string

INTERVAL - hourly, daily, monthly, half-hourly

=cut

package Giovanni::Visualizer::Hints::Time;

use 5.008008;
use strict;
use warnings;
use DateTime;
use DateTime::Duration;
use Date::Manip;
use Switch;

# This method converts a start and end time to a string. Makes sure that the
# resolution of the start and end times are the same.
sub formatTimeRange {
    my (%params) = @_;
    _checkParameters( [ 'START_TIME', 'END_TIME', 'INTERVAL', 'IS_START' ],
        __LINE__, __FILE__, %params );

    my $startResolution = _getDateStringResolution(
        TIME_STRING => $params{START_TIME},
        INTERVAL    => $params{INTERVAL},
        IS_START    => 1,
        JUST_YEAR   => $params{JUST_YEAR}
    );
    my $endResolution = _getDateStringResolution(
        TIME_STRING => $params{END_TIME},
        INTERVAL    => $params{INTERVAL},
        IS_START    => 0,
        JUST_YEAR   => $params{JUST_YEAR},
    );
    my $resolution = $startResolution;
    if ( $endResolution > $startResolution ) {
        $resolution = $endResolution;
    }
    return _createDateStr(
        TIME_STRING => $params{START_TIME},
        RESOLUTION  => $resolution
        )
        . " - "
        . _createDateStr(
        TIME_STRING => $params{END_TIME},
        RESOLUTION  => $resolution
        );

}

# This method converts time to a string based on the resolution of the data
# and whether or not the hour/minute/second START_VALUEs are 'obvious'. Obvious
# values are XX-XX-01 00:00:00 for start times and XX-XX-<last day> 23:59:59
# for end times.
sub formatTime {
    my (%params) = @_;

    _checkParameters( [ 'TIME_STRING', 'INTERVAL', 'IS_START' ],
        __LINE__, __FILE__, %params );

    if ( !$params{JUST_YEAR} ) {
        $params{JUST_YEAR} = 0;
    }

    if ( !$params{IS_CLIMATOLOGY} ) {
        $params{IS_CLIMATOLOGY} = 0;
    }

    if ( $params{IS_CLIMATOLOGY} ) {
        return _getClimatologyStr( $params{TIME_STRING} );
    }
    else {

        my $resolution = _getDateStringResolution(
            TIME_STRING => $params{TIME_STRING},
            INTERVAL    => $params{INTERVAL},
            IS_START    => $params{IS_START},
            JUST_YEAR   => $params{JUST_YEAR}
        );

        my $timeStr = _createDateStr(
            TIME_STRING => $params{TIME_STRING},
            RESOLUTION  => $resolution
        );
        return $timeStr;
    }
}

sub _getClimatologyStr {
    my ($dateString) = @_;
    my $date         = _parseDate($dateString);
    my $month        = $date->month();
    return _monthNumberToAbbreviation($month);
}

# Format the date based on how many elements need to be present.
sub _createDateStr {
    my (%params) = @_;

    #my ( $fullDateStr, $RESOLUTION ) = @_;

    # break up the date time string
    my $date   = Date::Manip::ParseDate( $params{TIME_STRING} );
    my $year   = UnixDate( $date, "%Y" );
    my $month  = UnixDate( $date, "%m" );
    my $day    = UnixDate( $date, "%d" );
    my $hour   = UnixDate( $date, "%H" );
    my $minute = UnixDate( $date, "%M" );
    my $second = UnixDate( $date, "%S" );

    switch ( $params{RESOLUTION} ) {
        case 0 { return $year; }
        case 1 { return "$year-" . _monthNumberToAbbreviation($month); }
        case 2 { return "$year-$month-$day"; }
        case 3 { return "$year-$month-$day $hour" . "Z"; }
        case 4 { return "$year-$month-$day $hour:$minute" . "Z"; }
        else {
            return "$year-$month-$day $hour:$minute:$second" . "Z";
        }
    }

}

# Convert from month number to 3-letter abbreviation
sub _monthNumberToAbbreviation {
    my ($number) = @_;

    # remove any pre-pended zeros
    $number =~ s/^0//;
    switch ($number) {
        case '1'  { return "Jan"; }
        case '2'  { return "Feb"; }
        case '3'  { return "Mar"; }
        case '4'  { return "Apr"; }
        case '5'  { return "May"; }
        case '6'  { return "Jun"; }
        case '7'  { return "Jul"; }
        case '8'  { return "Aug"; }
        case '9'  { return "Sep"; }
        case '10' { return "Oct"; }
        case '11' { return "Nov"; }
        else      { return "Dec"; }
    }
}

# Figure out what the shortest date string is that we can create with all the
# necessary information.
# 0 => year only
# 1 => year & month
# 2 => year, month, day
# 3 => year, month, day, hour
# 4 => year, month, day, hour, minute
# 5 => year, month, day, hour, minute, second
sub _getDateStringResolution {
    my (%params) = @_;

    #my ( $fullDateStr, $INTERVAL, $IS_START, $JUST_YEAR ) = @_;

    if ( $params{JUST_YEAR} ) {
        return 0;
    }

    # if we don't know what this is, just give complete dates.
    if ( !isKnownInterval( $params{INTERVAL} ) ) {
        return 5;
    }

    # break up the date time string
    my $date   = Date::Manip::ParseDate( $params{TIME_STRING} );
    my $year   = UnixDate( $date, "%Y" );
    my $month  = UnixDate( $date, "%m" );
    my $day    = UnixDate( $date, "%d" );
    my $hour   = UnixDate( $date, "%H" );
    my $minute = UnixDate( $date, "%M" );
    my $second = UnixDate( $date, "%S" );

    # see if the second value is 'nominal'
    if (!_isNominal(
            VALUE       => $second,
            IS_START    => $params{IS_START},
            START_VALUE => "00",
            END_VALUE   => "59"
        )
        )
    {
        return 5;
    }

    # see if the minute value is 'nominal'
    if ($params{INTERVAL} eq "half-hourly"
        || !_isNominal(
            VALUE       => $minute,
            IS_START    => $params{IS_START},
            START_VALUE => "00",
            END_VALUE   => "59"
        )
        )
    {
        return 4;
    }

    # hourly data will always show the hours. Otherwise, check to see if the
    # hourly stuff is nominal
    if (   $params{INTERVAL} eq "hourly"
        || $params{INTERVAL} eq "3-hourly"
        || !_isNominal(
            VALUE       => $hour,
            IS_START    => $params{IS_START},
            START_VALUE => "00",
            END_VALUE   => "23"
        )
        )
    {
        return 3;
    }

    # days will always be shown for daily data. Otherwise, check to see if the
    # monthly stuff is nominal
    my $nominalDay = "01";
    if ( !$params{IS_START} ) {
        $nominalDay
            = DateTime->last_day_of_month( month => $month, year => $year )
            ->day();
    }
    if ($params{INTERVAL} eq "daily"
        || !_isNominal(
            VALUE       => $day,
            IS_START    => $params{IS_START},
            START_VALUE => "01",
            END_VALUE   => $nominalDay
        )
        )
    {
        return 2;
    }

    # if everything was nominal, we can just return the year and month
    return 1;
}

sub isKnownInterval {
    my ($interval) = @_;
    if (   $interval eq "monthly"
        || $interval eq "hourly"
        || $interval eq "3-hourly"
        || $interval eq "daily"
        || $interval eq "half-hourly" )

    {
        return 1;
    }
    else {
        return 0;
    }
}

# This method figures out if this start and end time represents a single
# time slice
sub isWithinOneSlice {
    my (%params) = @_;

    _checkParameters( [ 'START_TIME', 'END_TIME', 'INTERVAL' ],
        __LINE__, __FILE__, %params );

    # If we don't know about this kind of interval, just assume it isn't one
    # slice.
    if ( !isKnownInterval( $params{INTERVAL} ) ) {
        return 0;
    }

    # convert the start and end time into DateTime objects

    my $startTimeDT = _parseDate( $params{START_TIME} );
    my $endTimeDT   = _parseDate( $params{END_TIME} );

    my $nextSliceStartTime;
    if ( $params{INTERVAL} eq "monthly" ) {
        $nextSliceStartTime = $startTimeDT->add( months => 1 );
    }
    elsif ( $params{INTERVAL} eq "daily" ) {
        $nextSliceStartTime = $startTimeDT->add( days => 1 );
    }
    elsif ( $params{INTERVAL} eq "3-hourly" ) {
        $nextSliceStartTime = $startTimeDT->add( hours => 3 );
    }
    elsif ( $params{INTERVAL} eq "hourly" ) {
        $nextSliceStartTime = $startTimeDT->add( hours => 1 );
    }
    elsif ( $params{INTERVAL} eq "half-hourly" ) {
        $nextSliceStartTime = $startTimeDT->add( minutes => 30 );
    }

    # if the next slice's time is after the end time, then this is one
    # slice
    my $duration = $nextSliceStartTime->subtract_datetime($endTimeDT);
    if ( $duration->is_positive() ) {
        return 1;
    }
    else {
        return 0;
    }

}

sub _parseDate {
    my ($str) = @_;

   # I know, I know. Why am I mixing Date::Manip and DateTime? Well, I started
   # with DateTime and DateTime::Duration and wrote that logic, but DateTime
   # doesn't have a parser. So I'm using the Date::Manip::ParseDate.

    my $date = Date::Manip::ParseDate($str);

    return DateTime->new(
        year      => UnixDate( $date, "%Y" ),
        month     => UnixDate( $date, "%m" ),
        day       => UnixDate( $date, "%d" ),
        hour      => UnixDate( $date, "%H" ),
        minute    => UnixDate( $date, "%M" ),
        second    => UnixDate( $date, "%S" ),
        time_zone => 'GMT'            # we always use GMT
    );

}

# Helper function for formatTime. Checks to see if something is the nominal
# start or end value
sub _isNominal {
    my (%params) = @_;

    #my ( $value, $IS_START, $START_VALUE, $END_VALUE ) = @_;
    if ( $params{IS_START} ) {
        if ( $params{VALUE} eq $params{START_VALUE} ) {
            return 1;
        }
    }
    else {
        if ( $params{VALUE} eq $params{END_VALUE} ) {
            return 1;
        }
    }
    return 0;
}

sub _checkParameters {
    my ( $mandatoryArgs, $line, $file, %params ) = @_;

    for my $arg ( @{$mandatoryArgs} ) {
        if ( !defined( $params{$arg} ) ) {
            die "Missing mandatory argument $arg on $line of $file.";
        }
    }

}
1;
