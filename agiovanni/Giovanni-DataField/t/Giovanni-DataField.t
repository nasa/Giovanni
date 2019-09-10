#!/usr/bin/env perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-DataField.t'

#########################
use File::Temp qw/ tempfile tempdir /;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('Giovanni::DataField') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $workingdir = tempdir( CLEANUP => 1 );
ok( ( -e $workingdir ), "Working directory created: $workingdir" );
my $rootpath = "$workingdir/sessionid/resultsetid/resultid";
`mkdir -p $rootpath`;
ok( ( -e $rootpath ), "Root path created" );
my $filepath = "$rootpath/manifest.xml";
open( MANIFEST, "> $filepath" );
ok( ( -e $filepath ), "File path created: $filepath" );

while (<DATA>) {
    print MANIFEST $_;
}
close(MANIFEST);

my $dataField;

$dataField = Giovanni::DataField->new();
ok( $dataField,            "Giovanni::DataField object created" );
ok( $dataField->onError(), "Missing MANIFEST argument detected" );

$dataField = Giovanni::DataField->new( MANIFEST => 'bogusName' );
ok( $dataField->onError(), "Nonexistent manifest file detected" );

$dataField = Giovanni::DataField->new( MANIFEST => "$filepath" );
ok( $dataField, 'Giovanni::DataField created from valid file' );
ok( $dataField->get_id,
    "Method for obtaining 'id' attribute value obtained a value" );

is( $dataField->isClimatology(), 0, "Checking for climatology" );
is( $dataField->isVector(),      0, "Checking for vector data" );

# Test for SLDs
my $sldListRef = [
    {   url =>
            'http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/atmospheric_temperature_sld.xml',
        label => 'Atmospheric Temperature'
    }
];
is_deeply( $sldListRef, $dataField->get_slds(),
    "Method for getting SLDs obtained an SLD" );

__DATA__
<varList>
  <var id="AIRX3STD_006_Temperature_A" long_name="Atmospheric Temperature Profile, daytime (ascending), AIRS, 1 x 1 deg." dataFieldUnitsValue="K" fillValueFieldName="_FillValue" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" dataProductStartTimeOffset="1" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Aqua%20AIRS%20Level%203%20Daily%20standard%20physical%20retrieval%20(AIRS%2BAMSU)%20V006;agent_id=OPeNDAP;variables=Temperature_A,TempPrsLvls_A" dataProductEndTimeOffset="0" south="-90.0" dataProductTimeInterval="daily" dataProductVersion="006" west="-180.0" east="180.0" dataProductShortName="AIRX3STD" sdsName="Temperature_A" resolution="1 x 1 deg." quantity_type="Air Temperature" dataFieldStandardName="air_temperature"> 
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/atmospheric_temperature_sld.xml" label="Atmospheric Temperature"/>
    </slds>
  </var>
</varList>
