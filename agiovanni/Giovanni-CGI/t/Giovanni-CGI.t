use Test::More tests => 64;
use CGI;

BEGIN { use_ok('Giovanni::CGI') }

use URI::Escape qw(uri_escape);

my %INPUT_TYPES = (
    default => {
        bbox               => 'bbox',
        bgcolor            => 'hex_color',
        cancel             => 'flag',
        caption            => 'plot_text',
        cfg                => 'g_config',
        code               => 'oauth_code',
        data               => 'url',
        datakeyword        => 'data_keyword',
        delete             => 'flag',
        endtime            => 'time',
        filename           => 'filename',
        layers             => 'layers',
        months             => 'months',
        options            => 'json',
        mostly_a_flag      => 'flag',
        mostly_a_bbox      => 'bbox',
        portal             => 'portal',
        pressure           => 'number',
        random             => 'number',
        request            => 'request',
        result             => 'uuid',
        resultset          => 'uuid',
        seasons            => 'seasons',
        service            => 'service',
        session            => 'uuid',
        shape              => 'shape',
        starttime          => 'time',
        step               => 'step',
        styles             => 'styles',
        temporalresolution => 'temporal_resolution',
        transparent        => 'boolean',
        variablefacets     => 'variable_facets',
        version            => 'version',
        sld                => 'url',
    },
    other_namespace => {
        data          => 'data',
        delete        => 'boolean',
        mostly_a_bbox => 'flag',
        mostly_a_flag => 'bbox',

    },
);
@TRUSTED_SERVERS = (
    '.ecs.nasa.gov',  '.gesdisc.eosdis.nasa.gov',
    '.gsfc.nasa.gov', 'gibs.earthdata.nasa.gov'
);

# Test all kinds of parameters with correct inputs.
run_test_with_query_string(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    NAMESPACE       => "other_namespace",
    query           => {
        BBOX    => "-120,-5,0,0",
        bgcolor => '0x7b7b91',
        caption =>
            ' - Selected date range was 2003-01-01 - 2003-01-02. Title reflects the date range of the granules that went into making this result',
        code =>
            "73304154a3fe900afd34821d8f34efdb4a451afa5a741faeb7d1d83e7822dd83",
        cfg            => "EARTHDATA_LOGIN",
        random         => "-233.5",
        session        => "8E200060-137A-11E9-A518-56A6D9018B23",
        delete         => "true",
        variableFacets => "a:b;",
        starttime      => "2003-01-01T00:00:00Z",
        data =>
            "TRMM_3B42_Daily_7_precipitation,TRMM_3B42RT_Daily_7_precipitation",
        FILENAME    => "something.nc",
        dataKeyword => "TRMM_3b42_daily",
        layers =>
            'AIRX3STD_006_Temperature_A,coastline,countries,us_states,grid45',
        MONTHS             => "01,02",
        options            => "{}",
        portal             => 'GIOVANNI',
        request            => 'getcapabilities',
        seasons            => 'DJF,MAM',
        service            => 'wms',
        SHAPE              => 'gpmLandMask/shp_0',
        step               => 'data_info',
        temporalResolution => 'daily',
        transparent        => 'true',
        endtime            => '2003-01-01',
        sld =>
            'https://giovanni.gsfc.nasa.gov/session/8FB5B686-15EB-11E9-96E3-66B6E70C10F0/57BC2DC6-15ED-11E9-977E-1E3AE70C10F0/57C049CE-15ED-11E9-977E-1E3AE70C10F0//TRMM_3B42_Daily_7_precipitation_22156_1547244492buylrd_div_12_panoply_sld.xml',
        version => "1.34.12",

    },
    should_work => 1,
    test_name   => "simple",
);

# Test namespaces
run_test_with_query_string(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        mostly_a_bbox => '-180,-90,180,90',
        mostly_a_flag => '1'
    },
    should_work => 1,
    test_name   => "no namespace",
);

# Test namespaces
run_test_with_query_string(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => { mostly_a_bbox => '1', },
    should_work     => 0,
    test_name       => "no namespace, bad bbox",
);

# Test namespaces
run_test_with_query_string(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => { mostly_a_flag => '-180,-90,180,90' },
    should_work     => 0,
    test_name       => "no namespace, bad flag",
);

run_test_with_query_string(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    NAMESPACE       => 'other_namespace',
    query           => {
        mostly_a_bbox => '1',
        mostly_a_flag => '-180,-90,180,90'
    },
    should_work => 1,
    test_name   => "use namespace",
);

run_test_with_query_string(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    NAMESPACE       => 'other_namespace',
    query           => { mostly_a_flag => '1' },
    should_work     => 0,
    test_name       => "use namespace, bad flag",
);

run_test_with_query_string(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    NAMESPACE       => 'other_namespace',
    query       => { mostly_a_bbox => '-180,-90,180,90', },
    should_work => 0,
    test_name   => "use namespace, bad bbox",
);

# test bbox
run_test_with_query_string(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => { BBOX => '-270, -180, 90, 180', },
    should_work     => 1,
    test_name       => "openlayers weird bounding box",
);

# check that PROXY_PARAMS works.
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    PROXY_PARAMS    => ['portal'],
    query           => { portal => "NOT_A_VALID_PORTAL", },
    should_work     => 1,
    test_name       => "proxy parameter skipped",
);

# check that we can do a bounding box in easting/northing format
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        sld =>
            "https://gibs.earthdata.nasa.gov/slds/AIRS_Surface_Relative_Humidity_Daily_Day.xml&SRS=EPSG:4326&WIDTH=1024&HEIGHT=512&FORMAT=image/png&TRANSPARENT=true&LAYERS=Time-Averaged.AIRS3STD_006_RelHumSurf_A",
    },
    should_work => 1,
    test_name   => "test gibs URL",
);

# check empty style passes
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => { styles => "", },
    should_work     => 1,
    test_name       => "test empty styles parameter",
);

run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    REQUIRED_PARAMS => ['bbox'],
    query           => { bbox => "120W,5S,1E,1N", },
    should_work     => 1,
    test_name       => "easting/northing bounding box",
);

# test required parameters
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    REQUIRED_PARAMS => [ 'BBOX', 'random' ],
    query           => {
        bbox   => "-120,-5,0,0",
        random => "-233.5",
    },
    should_work => 1,
    test_name   => "required parameters",
);

# more parameters than those required
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    REQUIRED_PARAMS => ['bbox'],
    query           => {
        bbox   => "-120,-5,0,0",
        random => "-233.5",
    },
    should_work => 1,
    test_name   => "extra parameters",
);

# missing required
run_test_with_query_string(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    REQUIRED_PARAMS => [ 'bbox', 'random' ],
    query           => { bbox => "-120,-5,0,0", },
    should_work     => 0,
    test_name       => "missing required",
);

# bad bounding box
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        bbox   => "-120,-5,0,0a",
        random => "-233.5",
    },
    should_work => 0,
    test_name   => "bad bounding box",
);

# bad data
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    NAMESPACE       => 'other_namespace',
    query           => {

        starttime => "2003-01-01T00:00:00Z",
        data      => "?TRMM_3B42RT_Daily_7_precipitation*(",
        filename  => "something.nc",
    },
    should_work => 0,
    test_name   => "bad data",
);

# bad dataKeyword
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        delete         => "1",
        variableFacets => "a:b;",
        starttime      => "2003-01-01T00:00:00Z",
        data =>
            "TRMM_3B42_Daily_7_precipitation,TRMM_3B42RT_Daily_7_precipitation",
        filename    => "something.nc%%",
        dataKeyword => "TRMM_3b42_daily",
        months      => "01,02",
    },
    should_work => 0,
    test_name   => "bad data keyword",
);

# bad filename
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        filename    => "..",
        dataKeyword => "TRMM_3b42_daily",
    },
    should_work => 0,
    test_name   => "bad filename",
);

# bad flag
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {

        session        => "8E200060-137A-11E9-A518-56A6D9018B23",
        delete         => "0",
        variableFacets => "a:b;",
    },
    should_work => 0,
    test_name   => "bad flag",
);

# bad number
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        random  => "-233.5.34",
        session => "8E200060-137A-11E9-A518-56A6D9018B23",
    },
    should_work => 0,
    test_name   => "bad number",
);

# bad months
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        months  => "01,02,YH",
        options => "{}",
    },
    should_work => 0,
    test_name   => "bad months",
);

# bad json
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        options => "{",
        portal  => 'GIOVANNI',
    },
    should_work => 0,
    test_name   => "bad json",
);

# bad portal
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        bbox   => "-120,-5,0,0",
        random => "-233.5",
        portal => 'NOPE',

    },
    should_work => 0,
    test_name   => "bad portal",
);

# bad seasons
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {

        portal  => 'GIOVANNI',
        seasons => 'DJF,MAM,KSNIUD',
        service => 'ArAvTs',

    },
    should_work => 0,
    test_name   => "bad seasons",
);

# bad service
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        seasons => 'DJF,MAM',
        service => 'ArAv',
        shape   => 'state_dept_countries/shp_15',
    },
    should_work => 0,
    test_name   => "bad service",
);

# bad shape
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        bbox    => "-120,-5,0,0",
        service => 'ArAvTs',
        shape   => 'state_dept_countries/shp_15344@#$',
    },
    should_work => 0,
    test_name   => "bad shape",
);

# bad temporal resolution
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        shape              => 'state_dept_countries/shp_15',
        temporalResolution => '132-daily',
        starttime          => '2003-01-01T23:59:59Z',
        sld =>
            'https://giovanni.gsfc.nasa.gov/session/8FB5B686-15EB-11E9-96E3-66B6E70C10F0/57BC2DC6-15ED-11E9-977E-1E3AE70C10F0/57C049CE-15ED-11E9-977E-1E3AE70C10F0//TRMM_3B42_Daily_7_precipitation_22156_1547244492buylrd_div_12_panoply_sld.xml',

    },
    should_work => 0,
    test_name   => "bad temporalResolution",
);

# bad time
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        bbox           => "-120,-5,0,0",
        delete         => "1",
        variableFacets => "a:b;",
        starttime      => "2003-01-01T00:00:00Q",

    },
    should_work => 0,
    test_name   => "bad time",
);

# bad url
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        sld =>
            'https://giovanni.gsfc.nasa.gov.com/session/8FB5B686-15EB-11E9-96E3-66B6E70C10F0/57BC2DC6-15ED-11E9-977E-1E3AE70C10F0/57C049CE-15ED-11E9-977E-1E3AE70C10F0//TRMM_3B42_Daily_7_precipitation_22156_1547244492buylrd_div_12_panoply_sld.xml',

    },
    should_work => 0,
    test_name   => "bad URL",
);

# bad uuid
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        bbox    => "-120,-5,0,0",
        random  => "-233.5",
        session => "8EQQ00060-137A-11E9-A518-56A6D9018B23",
    },
    should_work => 0,
    test_name   => "bad uuid",
);

# bad variable facets
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {
        bbox           => "-120,-5,0,0",
        random         => "-233.5",
        session        => "8E200060-137A-11E9-A518-56A6D9018B23",
        delete         => "1",
        variableFacets => "a:b!!;",
    },
    should_work => 0,
    test_name   => "bad variable facets",
);

# bad layers
run_test_from_environment_variables(
    INPUT_TYPES     => \%INPUT_TYPES,
    TRUSTED_SERVERS => \@TRUSTED_SERVERS,
    query           => {

        starttime => "2003-01-01T00:00:00Z",
        layers    => "great,?TRMM_3B42RT_Daily_7_precipitation*(",
        filename  => "something.nc",
    },
    should_work => 0,
    test_name   => "bad layers",
);

sub run_test_with_query_string {
    my (%params) = @_;

    # clear out any previous queries
    CGI::initialize_globals();

    # build the query string
    my $query_string = create_query_string( %{ $params{query} } );

    my $to_eval = <<'EVAL';
Giovanni::CGI->new(
    INPUT_TYPES    => $params{INPUT_TYPES},
    TRUSTED_SERVERS => $params{TRUSTED_SERVERS},
    REQUIRED_PARAMS => $params{REQUIRED_PARAMS},
    PROXY_PARAMS => $params{PROXY_PARAMS},
    NAMESPACE => $params{NAMESPACE},    
    QUERY => $query_string,
);
EVAL

    my $cgi = eval($to_eval);
    if ($@) {

        # the eval failed
        _check_failure( $@, %params );
    }
    else {

        # the eval succeeded
        _check_success( $cgi, %params );
    }

}

##
# Run the cgi test. Takes parameters query, INPUT_TYPES, TRUSTED_SERVERS,
# should_work, test_name
##
sub run_test_from_environment_variables {
    my (%params) = @_;

    # clear out any previous queries
    CGI::initialize_globals();

    # tell CGI that this is a GET request
    $ENV{REQUEST_METHOD} = 'GET';

    # set the QUERY_STRING environment variable
    $ENV{QUERY_STRING} = create_query_string( %{ $params{query} } );

    my $to_eval = <<'EVAL';
Giovanni::CGI->new(
    INPUT_TYPES    => $params{INPUT_TYPES},
    TRUSTED_SERVERS => $params{TRUSTED_SERVERS},
    REQUIRED_PARAMS => $params{REQUIRED_PARAMS},
    PROXY_PARAMS => $params{PROXY_PARAMS},
    NAMESPACE => $params{NAMESPACE},
);
EVAL

    my $cgi = eval($to_eval);
    if ($@) {

        # the eval failed
        _check_failure( $@, %params );

    }
    else {

        # eval succeeded.
        _check_success( $cgi, %params );
    }

}

sub _check_failure {
    my ( $failure, %params ) = @_;
    if ( $params{should_work} ) {
        ok( 0,
            $params{test_name} . " failed, which it should not: $failure" );

    }
    else {
        ok( 1, $params{test_name} . " failed, which it should." );

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
