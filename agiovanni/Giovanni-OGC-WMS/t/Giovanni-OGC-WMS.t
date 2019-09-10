# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-OGC-WMS.t'

#########################
#########################
#
## Insert your test code below, the Test::More module is use()ed here so read
## its man page ( perldoc Test::More ) for help writing this test script.

# change 'tests => 1' to 'tests => last_test_to_print';
use URI;
use URI::QueryParam;
use Test::More tests => 4;
BEGIN { use_ok('Giovanni::OGC::WMS') }

# Define WMS getMap request
my $ogcRequest
    = "http://dev.gesdisc.eosdis.nasa.gov/giovanni/daac-bin/wms_ag4?service=wms&version=1.1.1&request=getmap&layers=Time-Averaged.AIRX3STD_006_Temperature_D&starttime=2004-01-01T00:00:00Z&endtime=2004-01-03T23:59:59Z&srs=epsg:4326&bbox=-180,-90,180,90&width=1024&height=512&format=image/png&vert_slice=100";

# Test Case: translate WMS request into service manager request
my $smRequest
    = "http://dev.gesdisc.eosdis.nasa.gov/giovanni/daac-bin/service_manager.pl?service=TmAvMp&data=AIRX3STD_006_Temperature_D(z=100)&starttime=2004-01-01T00:00:00Z&endtime=2004-01-03T23:59:59Z&bbox=-180,-90,180,90&portal=GIOVANNI&format=xml";

my $url     = URI->new($ogcRequest);
my $wmsHash = {};
$wmsHash->{'baseUrl'} = $url->host;
$wmsHash->{'options'} = $url->query_form_hash;

my $ogcWms = Giovanni::OGC::WMS->new($wmsHash);
is( $ogcWms->{_AG_SM_REQUEST}, $smRequest, "translate getMap into SM" );

# Tese Case: get map or failed
$ogcWms->submitRequest;
is( $ogcWms->{_IS_SUCCESS}, 1, "get map successfully" );

# Test Case: print OGC error message

# Reference
my $ogcError
    = "Content-Type: text/xml\n\n<?xml version='1.0' encoding=\"ISO-8859-1\" standalone=\"no\" ?>\n<!DOCTYPE ServiceExceptionReport SYSTEM \"http://schemas.opengis.net/wms/1.1.1/exception_1_1_1.dtd\">\n<ServiceExceptionReport version=\"1.1.1\">\n<ServiceException>\n  Invalid layer name\n</ServiceException>\n</ServiceExceptionReport>\n";
is( Giovanni::OGC::WMS::ogcErrorMessage("Invalid layer name"),
    $ogcError, "OGC error message" );

