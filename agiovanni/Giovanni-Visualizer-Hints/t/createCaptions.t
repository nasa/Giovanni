#$Id: createCaptions.t,v 1.5 2015/04/24 13:50:39 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 SYNOPIS
This tests the createCaptions logic.
code.
=cut

use strict;
use warnings;

use Test::More tests => 24;
BEGIN { use_ok('Giovanni::Visualizer::Hints') }

#### comparison time captions ####

is( Giovanni::Visualizer::Hints::_getComparisonTimeCaption(
        USER_START_TIME => "2003-01-01T00:00:00Z",
        USER_END_TIME   => "2003-01-01T23:59:59Z",
        DATA_START_TIMES =>
            [ "2003-01-01T00:00:00Z", '2003-01-01T00:00:00Z' ],
        DATA_END_TIMES => [ "2003-01-01T23:59:59Z", "2003-01-01T23:59:59Z" ],
        DATA_STRINGS   => [ "First var",            "Second var" ],
        DATA_TEMPORAL_RESOLUTION => "daily",
    ),
    undef,
    "No captions needed"
);

my $caption
    = "Selected data range was 2003-01-01 - 2003-01-01. "
    . "The data date range for First var is "
    . "2003-12-31 22:30Z - 2003-01-01 22:29Z. "
    . "The data date range for Second var is "
    . "2003-01-01 - 2003-01-01.";
is( Giovanni::Visualizer::Hints::_getComparisonTimeCaption(
        USER_START_TIME => "2003-01-01T00:00:00Z",
        USER_END_TIME   => "2003-01-01T23:59:59Z",
        DATA_START_TIMES =>
            [ "2003-12-31T22:30:00Z", '2003-01-01T00:00:00Z' ],
        DATA_END_TIMES => [ "2003-01-01T22:29:59Z", "2003-01-01T23:59:59Z" ],
        DATA_STRINGS   => [ "First var",            "Second var" ],
        DATA_TEMPORAL_RESOLUTION => "daily",
    ),
    $caption,
    "Daily caption"
);

$caption
    = "Selected data range was 2003-Jan - 2004-Dec. "
    . "The data date range for First var is "
    . "2003-12-31 22:30Z - 2004-12-31 22:29Z. "
    . "The data date range for Second var is "
    . "2003-Jan - 2004-Dec.";
is( Giovanni::Visualizer::Hints::_getComparisonTimeCaption(
        USER_START_TIME => "2003-01-01T00:00:00Z",
        USER_END_TIME   => "2004-12-31T23:59:59Z",
        DATA_START_TIMES =>
            [ "2003-12-31T22:30:00Z", '2003-01-01T00:00:00Z' ],
        DATA_END_TIMES => [ "2004-12-31T22:29:59Z", "2004-12-31T23:59:59Z" ],
        DATA_STRINGS   => [ "First var",            "Second var" ],
        DATA_TEMPORAL_RESOLUTION => "monthly",
    ),
    $caption,
    "Monthly caption"
);

$caption
    = "Selected data range was 2003-01-01 00Z - 2004-12-31 23Z. "
    . "The data date range for First var is "
    . "2003-01-01 00Z - 2004-12-31 23Z. "
    . "The data date range for Second var is "
    . "2003-12-31 22:30Z - 2004-12-31 22:29Z.";
is( Giovanni::Visualizer::Hints::_getComparisonTimeCaption(
        USER_START_TIME => "2003-01-01T00:00:00Z",
        USER_END_TIME   => "2004-12-31T23:59:59Z",
        DATA_START_TIMES =>
            [ '2003-01-01T00:00:00Z', "2003-12-31T22:30:00Z" ],
        DATA_END_TIMES => [ "2004-12-31T23:59:59Z", "2004-12-31T22:29:59Z" ],
        DATA_STRINGS   => [ "First var",            "Second var" ],
        DATA_TEMPORAL_RESOLUTION => "hourly",
    ),
    $caption,
    "Hourly caption"
);

#### non comparison time captions ####

is( Giovanni::Visualizer::Hints::_getNonComparisonTimeCaption(
        USER_START_TIME          => "2003-01-01T00:00:00Z",
        USER_END_TIME            => "2003-01-01T23:59:59Z",
        DATA_START_TIMES         => ["2003-01-01T00:00:00Z"],
        DATA_END_TIMES           => ["2003-01-01T23:59:59Z"],
        DATA_TEMPORAL_RESOLUTION => "daily",
    ),
    undef,
    "No captions needed"
);

$caption
    = "Selected date range was 2003-01-01 - 2003-01-01. "
    . "Title reflects the date range of the granules "
    . "that went into making this result.";
is( Giovanni::Visualizer::Hints::_getNonComparisonTimeCaption(
        USER_START_TIME          => "2003-01-01T00:00:00Z",
        USER_END_TIME            => "2003-01-01T23:59:59Z",
        DATA_START_TIMES         => ["2002-12-31T22:30:00Z"],
        DATA_END_TIMES           => ["2003-01-01T22:29:59Z"],
        DATA_TEMPORAL_RESOLUTION => "daily",
    ),
    $caption,
    "Daily caption"
);

$caption
    = "Selected date range was 2003-01-01 00Z - 2003-01-01 23Z. "
    . "Title reflects the date range of the granules "
    . "that went into making this result.";
is( Giovanni::Visualizer::Hints::_getNonComparisonTimeCaption(
        USER_START_TIME          => "2003-01-01T00:00:00Z",
        USER_END_TIME            => "2003-01-01T23:59:59Z",
        DATA_START_TIMES         => ["2002-12-31T22:30:00Z"],
        DATA_END_TIMES           => ["2003-01-01T22:29:59Z"],
        DATA_TEMPORAL_RESOLUTION => "hourly",
    ),
    $caption,
    "Hourly caption"
);

$caption
    = "Selected date range was 2003-Jan - 2003-Jan. "
    . "Title reflects the date range of the granules "
    . "that went into making this result.";
is( Giovanni::Visualizer::Hints::_getNonComparisonTimeCaption(
        USER_START_TIME          => "2003-01-01T00:00:00Z",
        USER_END_TIME            => "2003-01-31T23:59:59Z",
        DATA_START_TIMES         => ["2002-12-31T22:30:00Z"],
        DATA_END_TIMES           => ["2003-01-31T22:29:59Z"],
        DATA_TEMPORAL_RESOLUTION => "monthly",
    ),
    $caption,
    "Monthly caption"
);

$caption
    = "Selected date range was 2003-01-01 - 2003-01-02. Title reflects the "
    . "date range of the granules that went into making this result.";
is( Giovanni::Visualizer::Hints::_getNonComparisonTimeCaption(
        USER_START_TIME          => "2003-01-01T00:00:00Z",
        USER_END_TIME            => "2003-01-02T23:59:59Z",
        DATA_START_TIMES         => ["2003-01-01T00:00:00Z"],
        DATA_END_TIMES           => ["2003-01-31T23:59:59Z"],
        DATA_TEMPORAL_RESOLUTION => "monthly",
    ),
    $caption,
    "Monthly caption when other variable is daily."
);

#### BBOX captions ####

is( Giovanni::Visualizer::Hints::_getBboxCaption(
        USER_BBOX    => "-180,-45,180,45",
        DATA_BBOXES  => ["-180,-50,180,50"],
        DATA_STRINGS => ["First Var"],
    ),
    undef,
    "No caption needed"
);

is( Giovanni::Visualizer::Hints::_getBboxCaption(
        USER_BBOX    => "-180,-50.0,180,50.0",
        DATA_BBOXES  => ["-180,-50,180,50"],
        DATA_STRINGS => ["First Var"],
    ),
    undef,
    "No caption needed"
);

$caption
    = 'Selected region was 180W, 90S, 180E, 50N. First Var has a '
    . 'limited data extent of 180W, 50S, 180E, 50N. The region in the title '
    . 'reflects the data extent of the subsetted granules that went into making '
    . 'this result.';

is( Giovanni::Visualizer::Hints::_getBboxCaption(
        USER_BBOX    => "-180,-90.0,180,50.0",
        DATA_BBOXES  => ["-180,-50.0,180,50"],
        DATA_STRINGS => ["First Var"],
    ),
    $caption,
    "Caption needed"
);

$caption
    = 'Selected region was 180W, 90S, 180E, 50N. First Var has a limited '
    . 'data extent of 180W, 50S, 180E, 50N. Second Var has a limited data '
    . 'extent of 60W, 60S, 60E, 60N. The region in the title reflects the '
    . 'data extent of the subsetted granules that went into making this '
    . 'result.';

is( Giovanni::Visualizer::Hints::_getBboxCaption(
        USER_BBOX    => "-180,-90.0,180,50.0",
        DATA_BBOXES  => [ "-180,-50.0,180,50", "-60,-60,60,60" ],
        DATA_STRINGS => [ "First Var", "Second Var" ],
    ),
    $caption,
    "Caption needed"
);

$caption
    = 'Selected region was 180W, 90S, 180E, 50N. First Var has a '
    . 'limited data extent of 180W, 50S, 180E, 50N. The region in the title '
    . 'reflects the data extent of the subsetted granules that went into making '
    . 'this result.';

is( Giovanni::Visualizer::Hints::_getBboxCaption(
        USER_BBOX    => "-180,-90.0,180,50.0",
        DATA_BBOXES  => [ "-180,-50.0,180,50", "-180,-90,180,90" ],
        DATA_STRINGS => [ "First Var", "Second Var" ],
    ),
    $caption,
    "Caption needed"
);

#### Combined captions ####

is( Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME => "2003-01-01T00:00:00Z",
        USER_END_TIME   => "2003-01-01T23:59:59Z",
        DATA_START_TIMES =>
            [ "2003-01-01T00:00:00Z", '2003-01-01T00:00:00Z' ],
        DATA_END_TIMES => [ "2003-01-01T23:59:59Z", "2003-01-01T23:59:59Z" ],
        DATA_TEMPORAL_RESOLUTION => "daily",
        USER_BBOX                => "-180,-45.0,180,45.0",
        DATA_BBOXES => [ "-180,-50.0,180,50", "-180,-90,180,90" ],
        DATA_STRINGS => [ "First Var", "Second Var" ],
    ),
    undef,
    "No combined caption needed"
);

is( Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME          => "2003-01-01T00:00:00Z",
        USER_END_TIME            => "2003-01-01T23:59:59Z",
        DATA_START_TIMES         => ["2003-01-01T00:00:00Z"],
        DATA_END_TIMES           => ["2003-01-01T23:59:59Z"],
        DATA_TEMPORAL_RESOLUTION => "daily",
        USER_BBOX                => "-180,-45.0,180,45.0",
        DATA_BBOXES              => ["-180,-50.0,180,50"],
        DATA_STRINGS             => ["First Var"],
    ),
    undef,
    "No combined caption needed"
);

$caption
    = "- Selected data range was 2003-01-01 - 2003-01-01. "
    . "The data date range for First Var is 2002-12-31 22:30Z - 2003-01-01 22:29Z. "
    . "The data date range for Second Var is 2003-01-01 - 2003-01-01.\n";
is( Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME => "2003-01-01T00:00:00Z",
        USER_END_TIME   => "2003-01-01T23:59:59Z",
        DATA_START_TIMES =>
            [ "2002-12-31T22:30:00Z", '2003-01-01T00:00:00Z' ],
        DATA_END_TIMES => [ "2003-01-01T22:29:59Z", "2003-01-01T23:59:59Z" ],
        DATA_TEMPORAL_RESOLUTION => "daily",
        USER_BBOX                => "-180,-45.0,180,45.0",
        DATA_BBOXES => [ "-180,-50.0,180,50", "-180,-90,180,90" ],
        DATA_STRINGS => [ "First Var", "Second Var" ],
    ),
    $caption,
    "Just the time caption"
);

$caption
    = "- Selected region was 180W, 90S, 180E, 45N. "
    . "First Var has a limited data extent of 180W, 50S, 180E, 50N. "
    . "The region in the title reflects the data extent of the subsetted granules that went into making this result.\n\n"
    . "- Selected data range was 2003-01-01 - 2003-01-01. "
    . "The data date range for First Var is 2002-12-31 22:30Z - 2003-01-01 22:29Z. "
    . "The data date range for Second Var is 2003-01-01 - 2003-01-01.\n";

is( Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME => "2003-01-01T00:00:00Z",
        USER_END_TIME   => "2003-01-01T23:59:59Z",
        DATA_START_TIMES =>
            [ "2002-12-31T22:30:00Z", '2003-01-01T00:00:00Z' ],
        DATA_END_TIMES => [ "2003-01-01T22:29:59Z", "2003-01-01T23:59:59Z" ],
        DATA_TEMPORAL_RESOLUTION => "daily",
        USER_BBOX                => "-180,-90.0,180,45.0",
        DATA_BBOXES => [ "-180,-50.0,180,50", "-180,-90,180,90" ],
        DATA_STRINGS => [ "First Var", "Second Var" ],
    ),
    $caption,
    "Bbox and time caption"
);

$caption
    = "- Selected region was 180W, 90S, 180E, 45N. "
    . "First Var has a limited data extent of 180W, 50S, 180E, 50N. "
    . "The region in the title reflects the data extent of the subsetted granules that went into making this result.\n";

is( Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME          => "2003-01-01T00:00:00Z",
        USER_END_TIME            => "2003-01-01T23:59:59Z",
        DATA_START_TIMES         => ["2003-01-01T00:00:00Z"],
        DATA_END_TIMES           => ["2003-01-01T23:59:59Z"],
        DATA_TEMPORAL_RESOLUTION => "daily",
        USER_BBOX                => "-180,-90.0,180,45.0",
        DATA_BBOXES  => [ "-180,-50.0,180,50", "-180,-90,180,90" ],
        DATA_STRINGS => ["First Var"],
    ),
    $caption,
    "Just the bbox caption"
);

$caption
    = "- Selected region was 180W, 90S, 180E, 45N. "
    . "First Var has a limited data extent of 180W, 50S, 180E, 50N. "
    . "The region in the title reflects the data extent of the subsetted "
    . "granules that went into making this result.\n";

is( Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME => "2003-01-01T00:00:00Z",
        USER_END_TIME   => "2003-01-01T23:59:59Z",
        DATA_START_TIMES =>
            [ "2002-12-31T22:30:00Z", '2003-01-01T00:00:00Z' ],
        DATA_END_TIMES => [ "2003-01-01T22:29:59Z", "2003-01-01T23:59:59Z" ],
        DATA_TEMPORAL_RESOLUTION => "daily",
        USER_BBOX                => "-180,-90.0,180,45.0",
        DATA_BBOXES => [ "-180,-50.0,180,50", "-180,-90,180,90" ],
        DATA_STRINGS   => [ "First Var", "Second Var" ],
        IS_CLIMATOLOGY => 1
    ),
    $caption,
    "Bbox caption for climatology"
);

is( Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME          => "2014-04-01T01:00:00Z",
        USER_END_TIME            => "2003-04-01T02:29:59Z",
        DATA_START_TIMES         => ["2014-04-01T01:00:00Z"],
        DATA_END_TIMES           => ["2003-04-01T02:29:59Z"],
        DATA_TEMPORAL_RESOLUTION => "half-hourly",
        USER_BBOX                => "-180,-45.0,180,45.0",
        DATA_BBOXES              => ["-180,-50.0,180,50"],
        DATA_STRINGS             => ["Var"],
    ),
    undef,
    "No combined caption needed"
);

## Group caption ##
$caption = "- Seasons with missing months are discarded.";
is( Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME          => "2014-03-01T01:00:00Z",
        USER_END_TIME            => "2003-05-31T23:59:59Z",
        DATA_START_TIMES         => ["2014-03-01T01:00:00Z"],
        DATA_END_TIMES           => ["2003-05-31T23:59:59Z"],
        DATA_TEMPORAL_RESOLUTION => "monthly",
        USER_BBOX                => "-180,-45.0,180,45.0",
        DATA_BBOXES              => ["-180,-50.0,180,50"],
        DATA_STRINGS             => ["Var"],
        GROUP                    => "SEASON=MAM",
        HAS_TIME_DIMENSION       => 0,
    ),
    $caption,
    "Season DJF caption not needed"
);

$caption = "- Seasons with missing months are discarded.\n"
    . "- DJF seasons are plotted against the year of the January and February data granules.";
is( Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME          => "2014-03-01T01:00:00Z",
        USER_END_TIME            => "2003-05-31T23:59:59Z",
        DATA_START_TIMES         => ["2014-03-01T01:00:00Z"],
        DATA_END_TIMES           => ["2003-05-31T23:59:59Z"],
        DATA_TEMPORAL_RESOLUTION => "monthly",
        USER_BBOX                => "-180,-45.0,180,45.0",
        DATA_BBOXES              => ["-180,-50.0,180,50"],
        DATA_STRINGS             => ["Var"],
        GROUP                    => "SEASON=MAM",
        HAS_TIME_DIMENSION       => 1,        
    ),
    $caption,
    "Season DJF caption needed"
);


1;
