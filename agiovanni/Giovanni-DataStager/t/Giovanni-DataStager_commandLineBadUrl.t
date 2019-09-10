#$Id: Giovanni-DataStager_commandLineBadUrl.t,v 1.2 2014/12/23 20:08:02 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-DataStager.t'

#########################

# Tests stageGiovanniData with the file cache.

use Test::More tests => 5;
BEGIN { use_ok('Giovanni::DataStager') }
use File::Temp qw/tempdir/;
use Giovanni::Cache;
use Giovanni::Logger;
use FindBin qw($Bin);

#########################
my $cleanup = ( defined $ENV{'CLEANUP'} ) ? $ENV{'CLEANUP'} : 1;

my $sessionDir = tempdir( CLEANUP => $cleanup );

# setup data field info and search manifest files

my $dataInfoFile
    = "$sessionDir/mfst.data_field_info+dGSSTFM_3_SET1_INT_ST_mag.xml";
my $dataInfo = <<'DATAINFO';
<varList>
  <var id="GSSTFM_3_SET1_INT_ST_mag" long_name="Wind Stress Magnitude" sampleOpendap="http://measures.gsfc.nasa.gov/opendap/hyrax/GSSTF/GSSTFM.3/1987/GSSTFM.3.1987.07.01.he5.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2008-12-31T23:59:59Z" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Goddard%20Satellite-Based%20Surface%20Turbulent%20Fluxes%2C%200.25x0.25%20deg%2C%20Monthly%20Grid%2C%20V3%2C%20(GSSTFM)%2C%20at%20GES%20DISC%20V3;agent_id=OPeNDAP;variables=SET1_INT_STu,SET1_INT_STv" startTime="1987-07-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="monthly" dataProductVersion="3" nominalMin="0.0" east="180.0" dataProductShortName="GSSTFM" resolution="0.25 deg." dataProductPlatformInstrument="SSMI" quantity_type="Wind" nominalMax="0.4" dataFieldStandardName="" dataProductEndDateTime="2008-12-31T23:59:59Z" dataFieldUnitsValue="N/m^^2" latitudeResolution="0.25" accessName="SET1_INT_STu,SET1_INT_STv" fillValueFieldName="_FillValue" accumulatable="false" spatialResolutionUnits="deg." longitudeResolution="0.25" dataProductStartTimeOffset="1" dataProductEndTimeOffset="0" west="-180.0" virtualDataFieldGenerator="GSSTFM_3_SET1_INT_ST_mag=sqrt(SET1_INT_STu*SET1_INT_STu+SET1_INT_STv*SET1_INT_STv)" sdsName="SET1_INT_ST_mag" dataProductBeginDateTime="1987-07-01T00:00:00Z">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_rd_9_sld.xml" label="Reds (Seq), 9"/>
    </slds>
  </var>
</varList>
DATAINFO
open DATAINFO, ">$dataInfoFile";
print DATAINFO $dataInfo;
close DATAINFO;

# the first and third URLs are purposefully bad
my $searchUrlsFile
    = "$sessionDir/mfst.data_search+dGSSTFM_3_SET1_INT_ST_mag+t20030101000000_20030331235959.xml";
my $searchUrls = <<'SEARCH';
<?xml version="1.0"?>
<searchList><search id="GSSTFM_3_SET1_INT_ST_mag"><result url="http://NOT_REAL.measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3/2003/GSSTFM.3.2003.01.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]" filename="GSSTFM.3.2003.01.01.he5.nc"/><result url="http://measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3/2003/GSSTFM.3.2003.02.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]" filename="GSSTFM.3.2003.02.01.he5.nc"/><result url="http://NOT_REAL.measures.gsfc.nasa.gov/opendap/GSSTF/GSSTFM.3/2003/GSSTFM.3.2003.03.01.he5.nc?SET1_INT_STu[0:719][0:1439],SET1_INT_STv[0:719][0:1439],lat[0:719],lon[0:1439]" filename="GSSTFM.3.2003.03.01.he5.nc"/></search></searchList>
SEARCH
open SEARCH, ">$searchUrlsFile";
print SEARCH $searchUrls;
close SEARCH;

# Create a giovanni.cfg with the correct columns. We don't need any
# environment variables set, so leave that blank.
my $cfgStr = <<'CFG';
@CACHE_COLUMNS = ("STARTTIME", "ENDTIME", "TIME", "DATAPERIOD");
%ENV=();
CFG
my $giovanniCfg = "$sessionDir/giovanni.cfg";
open CFG, ">$giovanniCfg";
print CFG $cfgStr;
close CFG;

my $outfilename
    = "mfst.data_fetch+dGSSTFM_3_SET1_INT_ST_mag+t20030101000000_20030331235959.xml";

# create a directory for the file cache
my $cacheRoot = tempdir( CLEANUP => 1 );

########
# call stageGiovanniData.pl
########

my $script = find_script("stageGiovanniData.pl");
ok( -r $script, "Found script: $script" );

# DO NOT specify keep going
my $cmd
    = "$script --datafield-info-file $dataInfoFile "
    . "--data-url-file $searchUrlsFile "
    . "--output $sessionDir/$outfilename "
    . "--chunk-size 10 --cache-root-path $cacheRoot --no-stderr "
    . "--giovanni-cfg $giovanniCfg";

my @out = `$cmd`;

ok( $? != 0,
    "Command returned non-zero, which is correct, (and text '"
        . join( "\n", @out )
        . "'): $cmd"
);

# check to make sure the output file DOES NOT exit
ok( !( -f "$sessionDir/$outfilename" ),
    "Output file missing, which is correct"
);

# and check for the bad url file is missing
ok( !( -f "$sessionDir/$outfilename" . "_BAD_URLS.txt" ),
    "Bad URLs file missing, which is correct"
);

sub find_script {
    my ($scriptName) = @_;

    # see if we can find the script relative to our current location
    $script = "";
    if ( -f "../scripts/$scriptName" ) {

        # Christine's eclipse configuration...
        $script = "../scripts/$scriptName";
    }
    else {
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }
    return $script;
}
