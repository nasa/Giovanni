#$Id: Giovanni-Search_commandline.t,v 1.7 2015/06/30 17:10:25 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# This tests the command line search.pl

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Giovanni::Search') }

#########################

use File::Temp qw/ tempfile tempdir /;
use File::Basename;
use FindBin qw($Bin);

# create a temporary directory for a session directory
my $tempDir = tempdir( "session_XXXX", CLEANUP => 1 );

# create a catalog file
my $catalogFile = $tempDir . "/" . "catalog.xml";
open( VARFILE, ">$catalogFile" )
    or die("unable to create/open catalog file $catalogFile");
print VARFILE <<VARINFO;
<varList>
  <var id="OMTO3d_003_RadiativeCloudFraction" long_name="Radiative Cloud Fraction" sampleOpendap="http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMTO3d.003/2004/OMI-Aura_L3-OMTO3d_2004m1001_v003-2012m0405t174138.he5.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="http://giovanni-test.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=OMI%2FAura%20TOMS-Like%20Ozone%2C%20Aerosol%20Index%2C%20Cloud%20Radiance%20Fraction%20Daily%20L3%20Global%201.0x1.0%20deg%20V003;agent_id=OPeNDAP;variables=RadiativeCloudFraction" startTime="2004-10-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="daily" dataProductVersion="003" nominalMin="0.0" east="180.0" dataProductShortName="OMTO3d" resolution="1 deg." dataProductPlatformInstrument="OMI" quantity_type="Reflectivity" nominalMax="1.0" dataFieldStandardName="" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="NoUnits" latitudeResolution="1.0" accessName="RadiativeCloudFraction" fillValueFieldName="_FillValue" accumulatable="false" spatialResolutionUnits="deg." longitudeResolution="1.0" dataProductStartTimeOffset="1" dataProductEndTimeOffset="0" oddxDims="&lt;opt&gt;&#10;  &lt;_LAT_DIMS name=&quot;lat&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;180&quot; /&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;179&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;359&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LONG_DIMS name=&quot;lon&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;360&quot; /&gt;&#10;  &lt;_VARIABLE_DIMS&gt;&#10;    &lt;RadiativeCloudFraction maxind=&quot;179&quot; name=&quot;lat&quot; /&gt;&#10;    &lt;RadiativeCloudFraction maxind=&quot;359&quot; name=&quot;lon&quot; /&gt;&#10;  &lt;/_VARIABLE_DIMS&gt;&#10;&lt;/opt&gt;&#10;" west="-180.0" sdsName="RadiativeCloudFraction" dataProductBeginDateTime="2004-10-01T00:00:00Z">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_rd_9_sld.xml" label="Reds (Seq), 9"/>
    </slds>
  </var>
</varList>
VARINFO
close(VARFILE) or die("unable to close catalog file $catalogFile");

my $script = find_script("search.pl");
ok( -r $script, "Found script" );

my $manifestFile = $tempDir
    . "/mfst.search+dOMTO3d_003_RadiativeCloudFraction+t20050101000000_20050102235959.xml";

my $cmd = qq(perl $script --catalog $catalogFile --outFile $manifestFile )
    . qq(--stime '2005-01-01T00:00:00Z' --etime '2005-01-02T23:59:59Z');

`$cmd`;

is( $?, 0, "returned 0" );

# make sure the manifest file was created
ok( -e $manifestFile, "manifest file created" );

# make sure the log file was created
my $logFile
    = $tempDir . "/"
    . "mfst.search+dOMTO3d_003_RadiativeCloudFraction+"
    . "t20050101000000_20050102235959.log";
ok( -e $logFile, "log file created" );

sub find_script {
    my ($scriptName) = @_;

    # see if we can find the script relative to our current location
    my $script = "blib/script/$scriptName";
    foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
        next if ( $dir =~ /^\s*$/ );
        last if ( -f $script );
        $script = "../$script";
    }

    unless ( -f $script ) {

        # see if this is just next door (Christine's eclipse configuration)
        $script = "../scripts/$scriptName";
    }

    return $script;
}
