# This file tests the new DONT_DIE_ON_VALIDATION_ERROR option in
# Giovanni::CGI

use Test::More tests => 16;
use CGI;

BEGIN { use_ok('Giovanni::CGI') }

use URI::Escape qw(uri_escape);

my %INPUT_TYPES = (
    default => {
        bbox        => 'bbox',
        code        => 'oauth_code',
        data        => 'data',
        datakeyword => 'data_keyword',
        endtime     => 'time',
        filename    => 'filename',
        sld         => 'url',
    },
);
@TRUSTED_SERVERS = (
    '.ecs.nasa.gov',  '.gesdisc.eosdis.nasa.gov',
    '.gsfc.nasa.gov', 'gibs.earthdata.nasa.gov'
);

# Run a test that will succeed. No 'die' statements should be hit.
run_test(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        BBOX => "-120,-5,0,0",
        code =>
            "73304154a3fe900afd34821d8f34efdb4a451afa5a741faeb7d1d83e7822dd83",
        data =>
            "TRMM_3B42_Daily_7_precipitation,TRMM_3B42RT_Daily_7_precipitation",
        endtime  => '2003-01-01',
        filename => 'hello.txt',
        sld =>
            'https://giovanni.gsfc.nasa.gov/session/8FB5B686-15EB-11E9-96E3-66B6E70C10F0/57BC2DC6-15ED-11E9-977E-1E3AE70C10F0/57C049CE-15ED-11E9-977E-1E3AE70C10F0//TRMM_3B42_Daily_7_precipitation_22156_1547244492buylrd_div_12_panoply_sld.xml',

    },
    should_work => 1,
    test_name   => "simple",
);

# Something that should fail
run_test(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => { BBOX => "-120,-5,0,0a", },
    should_work     => 0,
    test_name       => "bad bounding box",
    error_message   => qr/Unable to untaint bounding box parameter 'BBOX'/,
    problem_param   => 'BBOX',
);

run_test(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        BBOX => "-120,-5,0,0",
        code =>
            "73304154a3fe900afd34821d8f34efdb4a451afa5a741faeb7d1d83e7822dd83***",
    },
    should_work   => 0,
    test_name     => "bad code",
    error_message => qr/Parameter 'code' did not pass its regular expression/,
    problem_param => 'code',
);

run_test(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    REQUIRED_PARAMS => [ 'data', 'bbox' ],
    query           => {
        data =>
            "TRMM_3B42_Daily_7_precipitation,TRMM_3B42RT_Daily_7_precipitation",
    },
    should_work => 0,
    test_name   => "missing required params",
    error_message =>
        qr/Mandatory parameter 'bbox' missing from input query string/,
    problem_param => 'bbox',
);

sub run_test {
    my (%params) = @_;

    # clear out any previous queries
    CGI::initialize_globals();

    # build the query string
    my $query_string = create_query_string( %{ $params{query} } );

    my $cgi = Giovanni::CGI->new(
        INPUT_TYPES                  => $params{INPUT_TYPES},
        TRUSTED_SERVERS              => $params{TRUSTED_SERVERS},
        REQUIRED_PARAMS              => $params{REQUIRED_PARAMS},
        PROXY_PARAMS                 => $params{PROXY_PARAMS},
        QUERY                        => $query_string,
        DONT_DIE_ON_VALIDATION_ERROR => 1,
    );

    my %status = $cgi->status();

    if ( $status{SUCCESS} ) {

        # the eval succeeded
        _check_success( $cgi, %params );

    }
    else {

        # the eval failed
        _check_failure( $cgi, %params );

    }

}

sub _check_failure {
    my ( $cgi, %params ) = @_;
    my %status = $cgi->status();
    if ( $params{should_work} ) {
        ok( 0,
                  $params{test_name}
                . " failed, which it should not: "
                . $status{ERROR_MESSAGE} );
    }
    else {
        ok( 1, $params{test_name} . " failed, which it should." );
        like( $status{ERROR_MESSAGE}, $params{error_message},
            $params{test_name} . " got the correct error message" );
        is( $status{PARAMETER}, $params{problem_param},
            $params{test_name} . " got the correct parameter" );

    }
}

sub _check_success {
    my ( $cgi, %params ) = @_;
    if ( $params{should_work} ) {

        # the eval should have succeeded, so make sure we got back the
        # untainted values
        for my $key ( keys( %{ $params{query} } ) ) {
            is_deeply(
                $cgi->param($key),
                $params{query}->{$key},
                " parameter $key for test " . $params{test_name}
            );
        }
    }
    else {
        ok( 0,
            $params{test_name} . " passed untainting, but should not have." );
    }
}

sub create_query_string {
    my (%query) = @_;

    my @pieces = ();
    for my $key ( keys(%query) ) {
        my $val_encoded = uri_escape( $query{$key} );
        push( @pieces, $key . "=" . $val_encoded );
    }

    return join( "&", @pieces );
}
