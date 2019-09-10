# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ESIP-OpenSearch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('ESIP::OSDD') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $osddUrl
    = "http://mirador.gsfc.nasa.gov/ontologies/xml/PODAAC-GHAAO-4BC01.xml";

my $osdd = ESIP::OSDD->new( osddUrl => $osddUrl );
ok( $osdd, "Created OSDD for $osddUrl" );

# fill in a template to make sure that works
my $filledTemplate = $osdd->fillTemplate(
    0,
    "os:count"   => 5,
    "time:start" => "2014-02-01T00:00:00Z",
    "time:end"   => "2014-02-12T23:59:59Z",
);

is( $filledTemplate,
    "http://podaac.jpl.nasa.gov/ws/search/granule/?startIndex=&itemsPerPage=5&bbox=&startTime=2014-02-01T00%3A00%3A00Z&endTime=2014-02-12T23%3A59%3A59Z&datasetId=PODAAC-GHAAO-4BC01&sortBy=timeAsc&pretty=false&format=atom",
    "filled template"
);

# now call a search
my $out = $osdd->performGranuleSearch(
    0,
    "os:count"   => 50,
    "time:start" => "2000-01-01T00:00:00Z",
    "time:end"   => "2000-01-01T23:59:59Z",
);

# make sure there was one search query
my @urls = @{ $out->{searchUrls} };
is( scalar(@urls), 1, "One PODAAC search query" );
