#!/usr/bin/env perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-DataField.t'

#########################
use File::Temp qw/ tempdir /;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::DataField') }

use FindBin qw($Bin);
use Giovanni::Util;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dir = tempdir( CLEANUP => 1 );

my $infoFile = "$dir/info.xml";
open( MANIFEST, ">", "$infoFile" );
while (<DATA>) {
    print MANIFEST $_;
}
close(MANIFEST);

my $script = findScript('getBboxOutOfDatafieldInfo.pl');
ok( -r $script, "Found script" ) or die;

my $cmd  = "$script --file $infoFile";
my @out  = `$cmd`;
my $bbox = join( "", @out );
Giovanni::Util::trim($bbox);
is( $bbox, "-180.0,-50.0,180.0,50.0", 'Retrieved bounding box' );

1;

sub findScript {
    my ($scriptName) = @_;

    my $script = "../scripts/$scriptName";

    # see if we can find the script relative to our current location
    unless ( -f $script ) {
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }

    return $script;
}

__DATA__
<varList>
  <var id="TRMM_3B42_daily_precipitation_V7" long_name="Precipitation Rate" dataProductTimeFrequency="1" accessFormat="netCDF" north="50.0" accessMethod="HTTP_Services_HDF_TO_NetCDF" endTime="2038-01-19T03:14:07Z" url="http://s4ptu-ts1.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Daily%20TRMM%20and%20Others%20Rainfall%20Estimate%20(3B42%20V7%20derived)%20V7;agent_id=HTTP_Services_HDF_TO_NetCDF;variables=TRMM_3B42_daily_precipitation_V7" startTime="1997-12-31T00:00:00Z" responseFormat="netCDF" south="-50.0" dataProductTimeInterval="daily" dataProductVersion="7" sampleFile="" east="180.0" osdd="" dataProductShortName="TRMM_3B42_daily" resolution="0.25 deg." dataProductPlatformInstrument="TRMM" quantity_type="Precipitation" dataFieldStandardName="" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="mm/day" latitudeResolution="0.25" accessName="TRMM_3B42_daily_precipitation_V7" fillValueFieldName="" accumulatable="true" spatialResolutionUnits="deg." longitudeResolution="0.25" dataProductStartTimeOffset="-5400" dataProductEndTimeOffset="-5401" west="-180.0" sdsName="precipitation" dataProductBeginDateTime="1997-12-31T00:00:00Z">
    <slds>
      <sld url="http://s4ptu-ts1.ecs.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
      <sld url="http://s4ptu-ts1.ecs.nasa.gov/giovanni/sld/rainfall_sld.xml" label="Green-Blue (Seq), 65"/>
      <sld url="http://s4ptu-ts1.ecs.nasa.gov/giovanni/sld/buylrd_div_12_panoply_sld.xml" label="Blue-Yellow-Red (Div), 12 (Source: Panoply)"/>
    </slds>
  </var>
</varList>
