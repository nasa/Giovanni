# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Util.t'

#########################

use Test::More tests => 14;

BEGIN { use_ok('Giovanni::Util') }

#########################
use Data::Dumper;

# Tests for chunkTimeRange
my @tChunkList;

# Case of same start and end time
@tChunkList = Giovanni::Util::chunkTimeRange( "2012-02-02T23:30:00",
    "2012-02-02T23:30:00" );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'partial',
            'end'     => '2012-02-02T23:30:00Z',
            'start'   => '2012-02-02T23:30:00Z'
        }
    ],
    "Testing start and end times being the same"
);

# Case of start time < end time
@tChunkList = Giovanni::Util::chunkTimeRange( "2012-02-02T23:30:00",
    "2012-01-02T23:30:00" );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'partial',
            'end'     => '2012-02-02T23:30:00Z',
            'start'   => '2012-02-02T23:30:00Z'
        }
    ],
    "Testing end time < start time"
);

@tChunkList = Giovanni::Util::chunkTimeRange( "2012-02-02T23:30:00",
    "2012-02-05T23:30:00", 30.0 );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'partial',
            'end'     => '2012-02-05T23:30:00Z',
            'start'   => '2012-02-02T23:30:00Z'
        }
    ],
    "Testing size-1 partial overlap at beginning of month"
);

@tChunkList = Giovanni::Util::chunkTimeRange( "2012-02-28T23:30:00",
    "2012-03-28T23:30:00", 30.0 );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'partial',
            'end'     => '2012-03-28T23:30:00Z',
            'start'   => '2012-02-28T23:30:00Z'
        }
    ],
    "Testing size-1 partial overlap at end of month"
);

@tChunkList = Giovanni::Util::chunkTimeRange( "2012-02-01T00:00:00",
    "2012-03-28T23:30:00", 30.0 );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'full',
            'end'     => '2012-02-29T23:59:59Z',
            'start'   => '2012-02-01T00:00:00Z'
        },
        {   'overlap' => 'partial',
            'end'     => '2012-03-28T23:30:00Z',
            'start'   => '2012-03-01T00:00:00Z'
        }
    ],
    "Testing size-1 partial overlap near both ends of month"
);

@tChunkList = Giovanni::Util::chunkTimeRange( "2012-02-05T23:30:00",
    "2012-04-12T23:30:00", 30.0 );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'partial',
            'end'     => '2012-02-29T23:59:59Z',
            'start'   => '2012-02-05T23:30:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '2012-03-31T23:59:59Z',
            'start'   => '2012-03-01T00:00:00Z'
        },
        {   'overlap' => 'partial',
            'end'     => '2012-04-12T23:30:00Z',
            'start'   => '2012-04-01T00:00:00Z'
        }
    ],
    "Test size-3 chunk list with partial overlap on first and last"
);

@tChunkList = Giovanni::Util::chunkTimeRange( "1995-03-05T00:00:00",
    "2000-05-01T00:00:00", 365.0 );

is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'partial',
            'end'     => '1995-12-31T23:59:59Z',
            'start'   => '1995-03-05T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '1996-12-31T23:59:59Z',
            'start'   => '1996-01-01T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '1997-12-31T23:59:59Z',
            'start'   => '1997-01-01T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '1998-12-31T23:59:59Z',
            'start'   => '1998-01-01T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '1999-12-31T23:59:59Z',
            'start'   => '1999-01-01T00:00:00Z'
        },
        {   'overlap' => 'partial',
            'end'     => '2000-05-01T00:00:00Z',
            'start'   => '2000-01-01T00:00:00Z'
        }
    ],
    "Test size-5 chunk list, 1 year interval"
);

@tChunkList = Giovanni::Util::chunkTimeRange( "2011-02-01T00:00:00",
    "2012-03-28T23:30:00", 90.0 );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'partial',
            'end'     => '2011-03-31T23:59:59Z',
            'start'   => '2011-02-01T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '2011-06-30T23:59:59Z',
            'start'   => '2011-04-01T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '2011-09-30T23:59:59Z',
            'start'   => '2011-07-01T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '2011-12-31T23:59:59Z',
            'start'   => '2011-10-01T00:00:00Z'
        },
        {   'overlap' => 'partial',
            'end'     => '2012-03-28T23:30:00Z',
            'start'   => '2012-01-01T00:00:00Z'
        }
    ],
    "Test size-5 chunk list, 90 day interval"
);

@tChunkList = Giovanni::Util::chunkTimeRange( "2011-02-04T00:00:00",
    "2014-12-31T23:59:59", 365.0 );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'partial',
            'end'     => '2011-12-31T23:59:59Z',
            'start'   => '2011-02-04T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '2012-12-31T23:59:59Z',
            'start'   => '2012-01-01T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '2013-12-31T23:59:59Z',
            'start'   => '2013-01-01T00:00:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '2014-12-31T23:59:59Z',
            'start'   => '2014-01-01T00:00:00Z'
        }
    ],
    "Test size-4 chunk list with full coverage on last chunk"
);

# Test chunkTimeRange with offset
@tChunkList = Giovanni::Util::chunkTimeRange( "2005-01-01T00:00:01Z",
    "2005-03-05T23:59:59Z", 30.0, 1 );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'full',
            'end'     => '2005-02-01T00:00:00Z',
            'start'   => '2005-01-01T00:00:01Z'
        },
        {   'overlap' => 'full',
            'end'     => '2005-03-01T00:00:00Z',
            'start'   => '2005-02-01T00:00:01Z'
        },
        {   'overlap' => 'partial',
            'end'     => '2005-03-05T23:59:59Z',
            'start'   => '2005-03-01T00:00:01Z'
        }
    ],
    "Test size-3 chunk list with full coverage on first chunk"
);

@tChunkList = Giovanni::Util::chunkTimeRange( "2005-01-01T00:00:01Z",
    "2005-03-01T00:00:00Z", 30.0, 1 );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'full',
            'end'     => '2005-02-01T00:00:00Z',
            'start'   => '2005-01-01T00:00:01Z'
        },
        {   'overlap' => 'full',
            'end'     => '2005-03-01T00:00:00Z',
            'start'   => '2005-02-01T00:00:01Z'
        }
    ],
    "Test size-2 chunk list with full coverage on both chunks"
);

# Test chunkTimeRange with negative offset
@tChunkList = Giovanni::Util::chunkTimeRange( '2005-12-31T22:30:00',
    '2008-01-05T22:29:58', 365, -5400 );
is_deeply(
    \@tChunkList,
    [   {   'overlap' => 'partial',
            'end'     => '2006-01-28T22:29:59Z',
            'start'   => '2005-12-31T22:30:00Z'
        },
        {   'overlap' => 'full',
            'end'     => '2007-01-28T22:29:59Z',
            'start'   => '2006-01-28T22:30:00Z'
        },
        {   'overlap' => 'partial',
            'end'     => '2008-01-05T22:29:58Z',
            'start'   => '2007-01-28T22:30:00Z'
        }
    ],
    "Testing with negative offset"
);

# Test chunkTimeRange with non-aligned offset
@tChunkList = Giovanni::Util::chunkTimeRange( '1948-01-01T00:00:01',
    '2017-12-31T23:59:59Z', 10000.0, 1 );
is_deeply(
    \@tChunkList,
    [   {   'end'   => '1975-05-19T00:00:00Z',
            'start' => '1948-01-01T00:00:01Z'
        },
        {   'end'   => '2002-10-04T00:00:00Z',
            'start' => '1975-05-19T00:00:01Z'
        },
        {   'end'   => '2017-12-31T23:59:59Z',
            'start' => '2002-10-04T00:00:01Z'
        }
    ],
    "Testing with non-aligned offset"
);
