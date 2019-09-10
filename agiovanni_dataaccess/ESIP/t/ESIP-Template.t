# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ESIP-OpenSearch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('ESIP::Template') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $templateStr
    = "https://www.whatever.com:80/something?param=one&templateBox={geo:box}&templateCount={count?}&startTime={time:start}&endTime={time:end?}#stuff";

my $localNameToUri = {};
$localNameToUri->{"geo"}  = "http://a9.com/-/opensearch/extensions/geo/1.0/";
$localNameToUri->{"time"} = "http://a9.com/-/opensearch/extensions/time/1.0/";
$localNameToUri->{""}     = "http://a9.com/-/spec/opensearch/1.1/";

my $template = ESIP::Template->new(
    template       => $templateStr,
    localNameToUri => $localNameToUri
);

# check to see if parameters are present
my ( $hasParam, $isMandatory )
    = $template->hasParameter( "http://fake.com", "nope" );
is( $hasParam, 0, "Fake URI, no template value" );

( $hasParam, $isMandatory )
    = $template->hasParameter( $localNameToUri->{"geo"}, "nope" );
is( $hasParam, 0, "Real URI, no template value" );

( $hasParam, $isMandatory )
    = $template->hasParameter( $localNameToUri->{"geo"}, "box" );
is_deeply(
    [ $hasParam, $isMandatory ],
    [ 1,         1 ],
    "Real URI, mandatory value"
);

( $hasParam, $isMandatory )
    = $template->hasParameter( $localNameToUri->{"time"}, "end" );
is_deeply( [ $hasParam, $isMandatory ], [ 1, 0 ],
    "Real URI, optional value" );

# fill in the template, but don't worry about any of the parameters
my $url = $template->fillTemplate(0);
is( $url,
    "https://www.whatever.com:80/something?param=one&templateBox=&templateCount=&startTime=&endTime=#stuff",
    "No parameters filled in"
);

# now fill in only one mandatory element and be picky
my $fills = {};
$fills->{ $localNameToUri->{"geo"} }->{box} = "-180,-90,180,90";
eval { $template->fillTemplate( 1, %{$fills} ) };
ok( $@, "Complained that mandatory field was missing" );

$fills->{ $localNameToUri->{"time"} }->{start} = "2013-01-01";
$url = $template->fillTemplate( 1, %{$fills} );
is( $url,
    "https://www.whatever.com:80/something?param=one&templateBox=-180%2C-90%2C180%2C90&templateCount=&startTime=2013-01-01&endTime=#stuff",
    "All mandatory parameters"
);

$fills->{ $localNameToUri->{"time"} }->{end} = "2013-01-31";
$url = $template->fillTemplate( 1, %{$fills} );
is( $url,
    "https://www.whatever.com:80/something?param=one&templateBox=-180%2C-90%2C180%2C90&templateCount=&startTime=2013-01-01&endTime=2013-01-31#stuff",
    "Optional parameter"
);

1;
