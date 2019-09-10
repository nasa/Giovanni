# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ESIP-OpenSearch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('ESIP::OSDD') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $osddUrl
    = "https://mirador.gsfc.nasa.gov/OpenSearch/mirador_opensearch_MYD08_D3.051.xml";

my $osdd = ESIP::OSDD->new( osddUrl => $osddUrl );
ok( $osdd, "Created OSDD for $osddUrl" );

# fill in a template to make sure that works
my $filledTemplate = $osdd->fillTemplate(
    0,
    "os:count"   => 10,
    "time:start" => "2003-01-01T00:00:00Z",
    "time:end"   => "2003-01-31T23:59:59Z",
);

is( $filledTemplate,
    "https://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?esipdiscovery=&dataSet=MYD08_D3.051&page=&maxgranules=10&order=&dir=&endTime=2003-01-31T23%3A59%3A59Z&startTime=2003-01-01T00%3A00%3A00Z&newtime=&last=&os_altorder=&format=atom",
    "filled template"
);

# now call a search
my $out = $osdd->performGranuleSearch(
    0,
    "os:count"              => 2,
    "time:start"            => "2003-01-01T00:00:00Z",
    "time:end"              => "2003-01-05T23:59:59Z",
    "esipdiscovery:version" => "1.2",
);

# make sure there were the right number of search queries
my @urls = @{ $out->{searchUrls} };
is( scalar(@urls), 4, "Got the right number of search queries" );

# make sure we got three raw responses
ok( $out->{success}, "Completed search" );
my @raw = $out->{response}->getRawResponses();
is( scalar(@raw), 4, "Got four pages of response" );

