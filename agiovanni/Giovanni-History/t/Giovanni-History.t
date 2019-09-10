use Test::More tests => 12;
use File::Temp;
use strict;

BEGIN { use_ok('Giovanni::History') }

# Define unique key attributes
my $keyAttributes = ['KEY'];

# Create Giovanni::History object for reference
my $refHistory
    = Giovanni::History->new( UNIQUE_KEY_ATTRIBUTES => $keyAttributes );

# Create sample history data structure
my %img1 = (
    'x.nc' => [qw(x1.png x2.png x3.png)],
    'y.nc' => [qw(y1.png)]
);
my %caption1 = (
    'x1.png' => 'X1 Caption',
    'x2.png' => 'X2 Caption',
    'x3.png' => 'X3 Caption',
    'y1.png' => 'Y1 Caption',
);
my $option1 = { AOD => { x => 100, y => 200 } };
my @dataList1 = qw(x.nc y.nc);

# Add data to history
$refHistory->addItems(
    [   {   CAPTION     => \%caption1,
            PLOT_OPTION => $option1,
            IMG         => \%img1,
            DATA        => \@dataList1,
            PLOT_TYPE   => 'TIME_SERIES',
            KEY         => 'ITEM-1',
            KEY2        => 'KEY-1'
        }
    ]
);

# Write a second set to history
my %caption2 = (
    'a1.png' => 'A1 Caption',
    'a2.png' => 'A2 Caption',
    'b1.png' => 'B1 Caption',
    'b2.png' => 'B2 Caption'
);
my %img2 = (
    'a.nc' => [qw(a1.png )],
    'b.nc' => [qw(b1.png b2.png)]
);
my @dataList2 = qw(a.nc b.nc);
$refHistory->addItems(
    [   {   CAPTION => \%caption2,
            IMG     => \%img2,
            DATA    => \@dataList2,
            KEY     => 'ITEM-2',
            KEY2    => 'KEY-2'
        }
    ]
);

# Write history
eval { $refHistory->write() };
ok( $@, "write(): fails when history file is undefined" );
my $historyFile = "history.json";
eval { $refHistory->write($historyFile) };
ok( !$@, "write(): succeeds when history file is defined" );

# Read history created by the reference history object above
my $history1 = Giovanni::History->new(
    FILE                  => $historyFile,
    UNIQUE_KEY_ATTRIBUTES => $keyAttributes
);

# Seek all items; returns all items in history
my $historyItemList = $history1->find();
is( scalar(@$historyItemList),
    2,
    "find(): returns all members in history when no criteria is specified" );

# Seek an item that doesn't exist; returns no items in history
$historyItemList = $history1->find( { DATA => [qw(xyz.nc)] } );
is( scalar(@$historyItemList), 0,
    "find(): returns an empty list when specified data files don't exist in history"
);

# Seek an item that does exist; returns only one matched item in history
# Case of history without plot options
$historyItemList = $history1->find( { DATA => \@dataList2 } );
is( scalar(@$historyItemList), 1,
    "find(): returns a non-empty list when specified data files exist in history"
);

# Seek an item that doesn't exist; returns no items in history
# Case of history item with data matching, but plot options not matching
$historyItemList = $history1->find(
    {   DATA        => \@dataList2,
        PLOT_OPTION => { AOD => { x => 100, y => 20 } }
    }
);
is( scalar(@$historyItemList), 0,
    "find(): returns an empty list when specified data files exist, but plot options don't match"
);

# Seek an item that does exist; returns only one matched item in history
# Case of history item with data and plot option matching
$historyItemList
    = $history1->find( { DATA => \@dataList1, PLOT_OPTION => $option1 } );
is( scalar(@$historyItemList), 1,
    "find(): returns a non-empty list when match (data files+plot options, without plot type) is found"
);

my $imgList
    = $history1->getUniqueAttributeCombinationsAndKeys( [qw( KEY KEY2 )] );
is( keys %{$imgList},
    2, "getUniqueAttributeCombinationsAndKeys(): returned 2 combinations" );
is( join( ",", sort( keys %{$imgList} ) ),
    join( ",", sort(qw( ITEM-2^^^KEY-2 ITEM-1^^^KEY-1 )) ),
    "returned 2 correct item-key combinations"
);

# Seek an item whose plot type doesn't exist and rest of the criteria matches; returns no items in history
$historyItemList = $history1->find(
    {   DATA        => \@dataList1,
        PLOT_OPTION => $option1,
        PLOT_TYPE   => 'None'
    }
);
is( scalar(@$historyItemList),
    0, "find(): returns an empty list when no match is found" );

# Seek an item whose plot type exists and rest of the criteria matches: returns an item in history
$historyItemList = $history1->find(
    {   DATA        => \@dataList1,
        PLOT_OPTION => $option1,
        PLOT_TYPE   => 'TIME_SERIES'
    }
);
is( scalar(@$historyItemList),
    1,
    "find(): returns a non-empty list when match (with plot type) is found" );

unlink $historyFile if ( -f $historyFile );
