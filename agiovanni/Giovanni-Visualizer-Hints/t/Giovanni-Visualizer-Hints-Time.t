#$Id: Giovanni-Visualizer-Hints-Time.t,v 1.5 2015/01/26 22:22:40 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 SYNOPIS
This tests line wrapping and time formatting
=cut

use strict;
use File::Temp;
use DateTime;
use Test::More tests => 52;
BEGIN { use_ok('Giovanni::Visualizer::Hints::Time') }

# test the single slice functionality
ok( !Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T00:00:00Z",
        END_TIME   => "2003-01-01 00:00:00Z",
        INTERVAL   => 'n/a'
    ),
    "weird interval"
);

ok( Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T00:00:00Z",
        END_TIME   => "2003-01-01T23:59:59Z",
        INTERVAL   => 'daily'
    ),
    "One day"
);

ok( Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T01:00:00Z",
        END_TIME   => "2003-01-02T00:59:59Z",
        INTERVAL   => 'daily'
    ),
    "One day, across midnight boundary"
);

ok( !Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T01:00:00Z",
        END_TIME   => "2003-01-02T01:59:59Z",
        INTERVAL   => 'daily'
    ),
    "More than 24 hours"
);

ok( Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T00:00:00Z",
        END_TIME   => "2003-01-31T23:59:59Z",
        INTERVAL   => 'monthly'
    ),
    "Month slice"
);

ok( Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "1980-02-01T00:00:00Z",
        END_TIME   => "1980-02-29T00:00:00Z",
        INTERVAL   => "monthly"
    ),
    "Leap year month slice"
);

ok( Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T00:00:00Z",
        END_TIME   => "2003-01-01T00:59:59Z",
        INTERVAL   => 'hourly'
    ),
    "hour slice"
);

ok( !Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T01:30:00Z",
        END_TIME   => "2003-01-01T02:30:00Z",
        INTERVAL   => 'hourly'
    ),
    "longer than hour slice"
);

ok( Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T01:30:00Z",
        END_TIME   => "2003-01-01T02:30:00Z",
        INTERVAL   => '3-hourly'
    ),
    "in one 3 hour slice"
);

ok( !Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T01:30:00Z",
        END_TIME   => "2003-01-01T04:30:00Z",
        INTERVAL   => '3-hourly'
    ),
    "longer than 3 hour slice"
);

ok( Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T01:30:00Z",
        END_TIME   => "2003-01-01T01:59:59Z",
        INTERVAL   => 'half-hourly'
    ),
    "in one half hour slice"
);

ok( !Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
        START_TIME => "2003-01-01T01:30:00Z",
        END_TIME   => "2003-01-01T02:00:00Z",
        INTERVAL   => 'half-hourly'
    ),
    "longer than one half hour slice"
);

# time formatting half-hourly
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:00:00Z",
        INTERVAL    => "half-hourly",
        IS_START    => 1
    ),
    '2003-01-01 00:00Z',
    "2003-01-01T00:00:00Z half-hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:30:00Z",
        INTERVAL    => "half-hourly",
        IS_START    => 1
    ),
    '2003-01-01 00:30Z',
    "2003-01-01T00:30:00Z half-hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:33:00Z",
        INTERVAL    => "half-hourly",
        IS_START    => 1
    ),
    '2003-01-01 00:33Z',
    "2003-01-01T00:33:00Z half-hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:00:01Z",
        INTERVAL    => "half-hourly",
        IS_START    => 1
    ),
    '2003-01-01 00:00:01Z',
    "2003-01-01T00:00:01Z half-hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:29:59Z",
        INTERVAL    => "half-hourly",
        IS_START    => 0
    ),
    '2003-01-01 00:29Z',
    "2003-01-01T00:29:59Z half-hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:59:59Z",
        INTERVAL    => "half-hourly",
        IS_START    => 0
    ),
    '2003-01-01 00:59Z',
    "2003-01-01T00:59:59Z half-hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:58:59Z",
        INTERVAL    => "half-hourly",
        IS_START    => 0
    ),
    '2003-01-01 00:58Z',
    "2003-01-01T00:58:59Z half-hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:59:58Z",
        INTERVAL    => "half-hourly",
        IS_START    => 0
    ),
    '2003-01-01 00:59:58Z',
    "2003-01-01T00:59:58Z half-hourly"
);

# time formatting hourly
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:00:00Z",
        INTERVAL    => "hourly",
        IS_START    => 1
    ),
    '2003-01-01 00Z',
    "2003-01-01T00:00:00Z hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T01:00:00Z",
        INTERVAL    => "hourly",
        IS_START    => 1
    ),
    '2003-01-01 01Z',
    "2003-01-01T01:00:00Z hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:01:00Z",
        INTERVAL    => "hourly",
        IS_START    => 1
    ),
    '2003-01-01 00:01Z',
    "2003-01-01T00:01:00Z hourly"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:00:30Z",
        INTERVAL    => "hourly",
        IS_START    => 1
    ),
    '2003-01-01 00:00:30Z',
    "2003-01-01T00:00:30Z hourly"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T23:59:59Z",
        INTERVAL    => "hourly",
        IS_START    => 0
    ),
    '2003-01-01 23Z',
    "2003-01-01T23:59:59Z hourly (end)"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T22:59:59Z",
        INTERVAL    => "hourly",
        IS_START    => 0
    ),
    '2003-01-01 22Z',
    "2003-01-01T22:59:59Z hourly (end)"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T23:50:59Z",
        INTERVAL    => "hourly",
        IS_START    => 0
    ),
    '2003-01-01 23:50Z',
    "2003-01-01T23:50:59Z hourly (end)"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T23:59:50Z",
        INTERVAL    => "hourly",
        IS_START    => 0
    ),
    '2003-01-01 23:59:50Z',
    "2003-01-01T23:59:50Z hourly (end)"
);

# time formatting 3-hourly. Works just like hourly.
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:00:00Z",
        INTERVAL    => "3-hourly",
        IS_START    => 1
    ),
    '2003-01-01 00Z',
    "2003-01-01T00:00:00Z 3-hourly"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T23:59:59Z",
        INTERVAL    => "3-hourly",
        IS_START    => 0
    ),
    '2003-01-01 23Z',
    "2003-01-01T23:59:59Z 3-hourly (end)"
);

# time formatting daily
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:00:00Z",
        INTERVAL    => "daily",
        IS_START    => 1
    ),
    '2003-01-01',
    "2003-01-01T00:00:00Z daily"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T01:00:00Z",
        INTERVAL    => "daily",
        IS_START    => 1
    ),
    '2003-01-01 01Z',
    "2003-01-01T01:00:00Z daily"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:20:00Z",
        INTERVAL    => "daily",
        IS_START    => 1
    ),
    '2003-01-01 00:20Z',
    "2003-01-01T00:20:00Z daily"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:00:02Z",
        INTERVAL    => "daily",
        IS_START    => 1
    ),
    '2003-01-01 00:00:02Z',
    "2003-01-01T00:00:02Z daily"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T23:59:59Z",
        INTERVAL    => "daily",
        IS_START    => 0
    ),
    '2003-01-01',
    "2003-01-01T23:59:59Z daily (end)"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T22:59:59Z",
        INTERVAL    => "daily",
        IS_START    => 0
    ),
    '2003-01-01 22Z',
    "2003-01-01T22:59:59Z daily (end)"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T20:30:59Z",
        INTERVAL    => "daily",
        IS_START    => 0
    ),
    '2003-01-01 20:30Z',
    "2003-01-01T20:30:59Z daily (end)"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T23:59:49Z",
        INTERVAL    => "daily",
        IS_START    => 0
    ),
    '2003-01-01 23:59:49Z',
    "2003-01-01T23:59:49Z daily (end)"
);

# time formatting monthly
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:00:00Z",
        INTERVAL    => "monthly",
        IS_START    => 1
    ),
    '2003-Jan',
    "2003-01-01T00:00:00Z monthly"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-02T00:00:00Z",
        INTERVAL    => "monthly",
        IS_START    => 1
    ),
    '2003-01-02',
    "2003-01-02T00:00:00Z monthly"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T00:00:59Z",
        INTERVAL    => "monthly",
        IS_START    => 1
    ),
    '2003-01-01 00:00:59Z',
    "2003-01-01T00:00:00Z monthly"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-01-01T02:00:00Z",
        INTERVAL    => "monthly",
        IS_START    => 1
    ),
    '2003-01-01 02Z',
    "2003-01-01T02:00:00Z monthly"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-12-10T00:00:00Z",
        INTERVAL    => "monthly",
        IS_START    => 1
    ),
    '2003-12-10',
    "2003-12-10T00:00:00Z monthly"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-12-10T23:59:59Z",
        INTERVAL    => "monthly",
        IS_START    => 0
    ),
    '2003-12-10',
    "2003-12-10T23:59:59Z monthly (end)"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-12-31T23:59:59Z",
        INTERVAL    => "monthly",
        IS_START    => 0
    ),
    '2003-Dec',
    "2003-12-31T23:59:59Z monthly (end)"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2003-02-28T23:59:59Z",
        INTERVAL    => "monthly",
        IS_START    => 0
    ),
    '2003-Feb',
    "2003-02-10T23:59:59Z monthly (end)"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2008-02-29T23:59:59Z",
        INTERVAL    => "monthly",
        IS_START    => 0
    ),
    '2008-Feb',
    "2008-02-29T23:59:59Z monthly (end)"
);

is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2008-02-29T22:59:59Z",
        INTERVAL    => "monthly",
        IS_START    => 0
    ),
    '2008-02-29 22Z',
    "2008-02-29T22:59:59Z monthly (end)"
);

# time formatting climatology
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING    => "2008-12-01T00:00:00Z",
        INTERVAL       => "monthly",
        IS_START       => 1,
        IS_CLIMATOLOGY => 1,
    ),
    'Dec',
    "2008-02-29T22:59:59Z monthly climatology (end)"
);
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING    => "2008-02-29T22:59:59Z",
        INTERVAL       => "monthly",
        IS_START       => 0,
        IS_CLIMATOLOGY => 1,
    ),
    'Feb',
    "2008-02-29T22:59:59Z monthly climatology (end)"
);

# test formatting with a weird interval
is( Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => "2009-01-01T23:59:59Z",
        INTERVAL    => 'n/a',
        IS_START    => 0
    ),
    '2009-01-01 23:59:59Z',
    '2009-01-01 23:59:59Z weird interval'
);

