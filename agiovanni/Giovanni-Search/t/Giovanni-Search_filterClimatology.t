#$Id: Giovanni-Search_filterClimatology.t,v 1.2 2014/12/24 18:34:05 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Search.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
use File::Temp qw/ tempfile tempdir /;
BEGIN { use_ok('Giovanni::Search') }

#########################
# setup some directories
 my $dir = tempdir( CLEANUP => 1 );
 my $workingDir = "$dir/working";
 mkdir($workingDir) or die "Unable to make directory $workingDir, $!";

my $catalogFile = $workingDir . "/" . "catalog.xml";
open( VARFILE, ">$catalogFile" )
    or die("unable to create/open catalog file $catalogFile, $!");
print VARFILE <<VARINFO;
<varList>
  <var id="OMAERUVd_003_FinalAerosolAbsOpticalDepth500">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_greys_9_sld.xml" label="Greys, Light to Dark (Seq), 9"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/buylrd_div_11_sld.xml" label="Blue-Yellow-Red (Div), 11"/>
    </slds>
  </var>
</varList>
VARINFO
close(VARFILE) or die("unable to close catalog file $catalogFile");

# test _inMonthRange with lots of different scenarios.
ok( Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('2000-03-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-06-30T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-01-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2013-03-31T00:00:00Z')
    ),
    "partial overlap"
);
ok( Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('1970-03-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-06-30T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-03-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-03-31T00:00:00Z')
    ),
    ,
    "inside"
);
ok( Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('2000-03-01T00:00:00Z'),
        Giovanni::Search::_parseDate('1900-06-30T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-06-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-07-31T00:00:00Z')
    ),
    "partial overlap"
);
ok( Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('1900-03-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2014-06-30T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-01-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-08-31T00:00:00Z')
    ),
    "outside"
);
ok( Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('2000-03-01T00:00:00Z'),
        Giovanni::Search::_parseDate('1932-06-30T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-03-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-06-30T00:00:00Z')
    ),
    "same"
);
ok( !Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('2000-03-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-06-30T00:00:00Z'),
        Giovanni::Search::_parseDate('1968-01-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-02-05T00:00:00Z')
    ),
    "no overlap"
);
ok( !Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('2000-03-01T00:00:00Z'),
        Giovanni::Search::_parseDate('1980-06-30T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-07-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-08-31T00:00:00Z')
    ),
    "no overlap"
);
ok( Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('2000-01-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-03-30T00:00:00Z'),
        Giovanni::Search::_parseDate('1956-12-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-01-31T00:00:00Z')
    ),
    "granule over year"
);
ok( !Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('2000-05-01T00:00:00Z'),
        Giovanni::Search::_parseDate('1877-07-30T00:00:00Z'),
        Giovanni::Search::_parseDate('1999-12-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-01-31T00:00:00Z')
    ),
    "granule over year"
);
ok( Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('1999-12-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-02-20T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-01-01T00:00:00Z'),
        Giovanni::Search::_parseDate('1977-01-31T00:00:00Z')
    ),
    "search over year"
);
ok( !Giovanni::Search::_inDateRangeIgnoreYear(
        Giovanni::Search::_parseDate('1999-12-01T00:00:00Z'),
        Giovanni::Search::_parseDate('1800-02-20T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-05-01T00:00:00Z'),
        Giovanni::Search::_parseDate('2000-07-31T00:00:00Z')
    ),
    "search over year"
);

# test the climatology filter
my $userStartTime = '2000-05-06T00:00:00Z';
my $userEndTime   = '2000-06-30T23:59:59Z';
my $resultSet     = [
    { "startTime" => '1970-04-01T00:00:00Z',
        "endTime" => '1970-05-01T00:00:00Z' },
    { "startTime" => '1970-05-01T00:00:00Z',
        "endTime" => '1970-06-01T00:00:00Z' },
    { "startTime" => '1970-06-01T00:00:00Z',
        "endTime" => '1970-07-01T00:00:00Z' },
    { "startTime" => '1970-07-01T00:00:00Z',
        "endTime" => '1970-08-01T00:00:00Z' }
];

my $correctSet = [
    { "startTime" => '1970-05-01T00:00:00Z',
        "endTime" => '1970-06-01T00:00:00Z' },
    { "startTime" => '1970-06-01T00:00:00Z',
        "endTime" => '1970-07-01T00:00:00Z' }
];

my $search = Giovanni::Search->new(session_dir  => $workingDir,
                                   catalog      => $catalogFile,
                                   out_file     => "search.log");

$search->_filterClimatology( $userStartTime, 1, $userEndTime,
    0, $resultSet );

is_deeply( $resultSet, $correctSet, "Filtered correctly" );

