#!/usr/bin/env perl
#$Id: ncScrubber_MERRA_hourly_time_bnds.t,v 1.6 2015/09/02 17:11:53 rstrub Exp $
#-@@@ AEROSOLS,Version $Name:  $
# Author: rstrub
# Date Created: 2015-01-09

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AEROSOLS-FormatData.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use File::Compare;
use File::Temp qw/ tempfile tempdir /;
use Test::More tests => 10;

$ENV{PERL5LIB}
    = "../Giovanni-BoundingBox/lib:../Giovanni-Util/lib:../Giovanni-Scrubber/lib:../Giovanni-DataField/lib:../Giovanni-Data-NcFile/lib:../Giovanni-ScienceCommand/lib:../Giovanni-WorldLongitude/lib:../Giovanni-Logger/lib";

my $script
    = ( -e 'blib/script/ncScrubber.pl' )
    ? 'blib/script/ncScrubber.pl'
    : '../blib/script/ncScrubber.pl';
ok( ( -e $script ),
    "check the existence of the commandline script: $script" );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
# CLEANUP => 1
my $workingdir = tempdir( CLEANUP => 1 );

# my $workingdir = "/var/scratch/hxiaopen/sprint50/aGiovanni/bin/airsout";
ok( ( -e $workingdir ), "Working directory: $workingdir" );

## to generate the source testing file, and the expected file
my $filename = "";
my $ncfile   = "";
while (<DATA>) {
    if ( $_ =~ /^FILE=/ ) {
        $filename = $_;
        $filename =~ s/^FILE=//;
        chomp($filename);
        $filename = "$workingdir/$filename";
        open FH, ">", "$filename";
        next;
    }
    if ( $_ =~ /^ENDFILE/ ) {
        close(FH);
        ok( ( -f $filename ), "Create \"$filename\"" );

        ## convert .cdl to .nc
        if ( $filename =~ /\.cdl$/ ) {
            $ncfile = $filename;
            $ncfile =~ s/(\.cdl)$/\.nc/;
            `ncgen -b -o $ncfile $filename`;
            ok( ( -e $ncfile ), "File not exist: $ncfile" );
        }
        next;
    }
    my $line = $_;
    $line =~ s/WORKINGDIR/$workingdir/;
    print FH $line;
}

my $inputListingFile = "$workingdir/listingfiles.xml";
my $catalogFile      = "$workingdir/varInfo.xml";

my $scrubbedName = "scrubbed.MAT1NXSLV_5_2_0_SLP.199006091100";

# -v 0 2>& 1
my $testCommand
    = "/usr/bin/perl $script --input $inputListingFile --catalog $catalogFile --outDir $workingdir -v 0 2>& 1"
    ;    ## ops command

#my $testCommand = "/usr/bin/perl $script --input $inputListingFile --catalog $catalogFile --outDir $workingdir -v 1";  ## debugging command
my $accounting = `$testCommand`;
if ( length $accounting > 1 ) {
    print STDERR "ISSUES in running ncScrubber!!!\n";
    print STDERR $accounting;
}
############## to generate GSSTFM vector data ######################
my $expectedCdlFile = "$workingdir/expected_$scrubbedName.cdl";
my $finalNcFile     = "$workingdir/$scrubbedName.nc";
ok( ( -e $finalNcFile ),
    "check the existence of the workingfile --  $finalNcFile" );
my $workingCdlFile = "$workingdir/$scrubbedName.cdl";
`ncdump  $finalNcFile | grep -v :NCO > $workingCdlFile`;
my $diffCommand = "diff  $workingCdlFile $expectedCdlFile ";
if ( !( -e $finalNcFile ) ) {
    print STDERR
        "Somehow the output file $finalNcFile does not exist. So doing the diff is pointless";
}
else {
    print `$diffCommand`;
    my $status = system($diffCommand);
    is( $status, 0,
        "Final Only Important Check: $workingCdlFile == $expectedCdlFile " );
}
if ($ARGV[0] == 1) {
 `cp $workingCdlFile temp.cdl`;
 `cp  $expectedCdlFile expected.cdl`;
   print STDERR "dropping an update\n";
}

###########################################################################
## NOTE:
##     For each expected Cdf file, the file name must start with "expected_".
##     However, in the following dumped section, the file name must start with "formatted_"
##     because we expect that "formatted_" prefix for comparing with the generated CDL file.
###########################################################################
__DATA__
FILE=listingfiles.xml
<data>MAT1NXSLV_5_2_0_SLP
 <dataFileList id="" sdsName="SLP">
  <dataFile>WORKINGDIR/MERRA100.19900609110000.MAT1NXSLV_5_2_0_SLP.nc</dataFile>
 </dataFileList>
</data>
ENDFILE
FILE=varInfo.xml
<varList>
  <var id="MAT1NXSLV_5_2_0_SLP" long_name="Sea Level Pressure, time average" searchIntervalDays="7.0" sampleOpendap="http://goldsmr2.sci.gsfc.nasa.gov/opendap/ncml/MERRA/MAT1NXSLV.5.2.0/1979/01/MERRA100.prod.assim.tavg1_2d_slv_Nx.19790102.hdf.ncml.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP_TIMESPLIT" endTime="2038-01-19T03:14:07Z" url="https://giovanni-test.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MERRA%202D%20IAU%20Diagnostic%2C%20Single%20Level%20Meteorology%2C%20Time%20Average%201-hourly%20(2%2F3x1%2F2L1)%20V5.2.0;agent_id=OPeNDAP_TIMESPLIT;variables=SLP" startTime="1979-01-01T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="hourly" dataProductVersion="5.2.0" sampleFile="" east="180.0" dataProductShortName="MAT1NXSLV" osdd="" resolution="0.5 x 0.667 deg." dataProductPlatformInstrument="MERRA Model" quantity_type="Air Pressure" dataFieldStandardName="air_pressure_at_sea_level" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="hPa" latitudeResolution="0.5" accessName="SLP" fillValueFieldName="_FillValue" valuesDistribution="linear" accumulatable="false" spatialResolutionUnits="deg." longitudeResolution="0.667" dataProductStartTimeOffset="1" dataProductEndTimeOffset="0" oddxDims="&lt;opt _TIME_SPLITTABLE_DIMENSION=&quot;TIME&quot;&gt;&#10;  &lt;_LAT_DIMS name=&quot;YDim&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;361&quot; /&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;360&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;0&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LAT_LONG_INDEXES&gt;539&lt;/_LAT_LONG_INDEXES&gt;&#10;  &lt;_LONG_DIMS name=&quot;XDim&quot; offset=&quot;0&quot; scaleFactor=&quot;1&quot; size=&quot;540&quot; /&gt;&#10;  &lt;_TIME_DIMS&gt;&#10;    &lt;TIME boundsVarName=&quot;TIME_bnds&quot; boundsVarSize=&quot;24&quot; boundsVarUnits=&quot;minutes since 1979-01-02 00:30:00&quot; size=&quot;24&quot; units=&quot;minutes since 1979-01-02 00:30:00&quot; /&gt;&#10;  &lt;/_TIME_DIMS&gt;&#10;  &lt;_TIME_INDEXES&gt;&#10;    &lt;TIME&gt;&#10;      &lt;indexes&gt;0&lt;/indexes&gt;&#10;      &lt;indexes&gt;0&lt;/indexes&gt;&#10;      &lt;labels&gt;MERRA100.prod.assim.tavg1_2d_slv_Nx.19790102.hdf.ncml.19790102003000.nc&lt;/labels&gt;&#10;    &lt;/TIME&gt;&#10;  &lt;/_TIME_INDEXES&gt;&#10;  &lt;_VARIABLE_DIMS&gt;&#10;    &lt;SLP maxind=&quot;23&quot; name=&quot;TIME&quot; /&gt;&#10;    &lt;SLP maxind=&quot;360&quot; name=&quot;YDim&quot; /&gt;&#10;    &lt;SLP maxind=&quot;539&quot; name=&quot;XDim&quot; /&gt;&#10;  &lt;/_VARIABLE_DIMS&gt;&#10;&lt;/opt&gt;&#10;" 
west="-180.0" virtualDataFieldGenerator="MAT1NXSLV_5_2_0_SLP=SLP/100;" sdsName="SLP" timeIntvRepPos="middle" dataProductBeginDateTime="1979-01-01T00:00:00Z">
    <slds>
      <sld url="https://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/time_matched_difference_sld.xml" label="Blue-Yellow-Red (Div), 12"/>
    </slds>
  </var>
</varList>
ENDFILE
FILE=MERRA100.19900609110000.MAT1NXSLV_5_2_0_SLP.cdl
netcdf MERRA100.19900609110000.MAT1NXSLV_5_2_0_SLP {
dimensions:
	TIME = 1 ;
	YDim = 3 ;
	XDim = 2 ;
	bnds = 2 ;
variables:
	float SLP(TIME, YDim, XDim) ;
		SLP:_FillValue = 1.e+15f ;
		SLP:long_name = "Sea level pressure" ;
		SLP:standard_name = "sea_level_pressure" ;
		SLP:units = "Pa" ;
		SLP:scale_factor = 1.f ;
		SLP:add_offset = 0.f ;
		SLP:missing_value = 1.e+15f ;
		SLP:fmissing_value = 1.e+15f ;
		SLP:vmin = -1.e+30f ;
		SLP:vmax = 1.e+30f ;
		SLP:valid_range = -1.e+30f, 1.e+30f ;
		SLP:coordinates = "TIME YDim XDim" ;
		SLP:fullpath = "/EOSGRID/Data Fields/SLP" ;
	double TIME(TIME) ;
		TIME:long_name = "time" ;
		TIME:units = "minutes since 1990-06-09 00:30:00" ;
		TIME:time_increment = 10000 ;
		TIME:begin_date = 19900609 ;
		TIME:begin_time = 3000 ;
		TIME:fullpath = "TIME:EOSGRID" ;
		TIME:bounds = "TIME_bnds" ;
	int TIME_bnds(TIME, bnds) ;
	double XDim(XDim) ;
		XDim:long_name = "longitude" ;
		XDim:units = "degrees_east" ;
		XDim:fullpath = "XDim:EOSGRID" ;
	double YDim(YDim) ;
		YDim:long_name = "latitude" ;
		YDim:units = "degrees_north" ;
		YDim:fullpath = "YDim:EOSGRID" ;

// global attributes:
		:HDFEOSVersion = "HDFEOS_V2.14" ;
		:missing_value = 1.e+15f ;
		:Conventions = "CF-1.0" ;
		:title = "MERRA reanalysis. GEOS-5.2.0" ;
		:history = "Mon May 21 14:24:43 2018: ncks -d YDim,54.0,55.0 -d XDim,54.0,55.0 MERRA100.prod.assim.tavg1_2d_slv_Nx.19900609.hdf.ncml.19900609110000.MAT1NXSLV_5_2_0_SLP.nc MERRA100.19900609110000.MAT1NXSLV_5_2_0_SLP.nc\n",
			"File written by CFIO\n",
			"2018-05-18 14:46:31 GMT Hyrax-1.13.4 https://goldsmr2.gesdisc.eosdis.nasa.gov:443/opendap/ncml/MERRA/MAT1NXSLV.5.2.0/1990/06/MERRA100.prod.assim.tavg1_2d_slv_Nx.19900609.hdf.ncml.nc?SLP[11:11][0:360][0:539],TIME_bnds[11:11][0:1],XDim[0:539],TIME[11:11],YDim[0:360]" ;
		:institution = "Global Modeling and Assimilation Office, NASA Goddard Space Flight Center, Greenbelt, MD 20771" ;
		:source = "Global Modeling and Assimilation Office. GEOSops_5_2_0" ;
		:references = "http://gmao.gsfc.nasa.gov/research/merra/" ;
		:comment = "GEOS-5.2.0" ;
		:contact = "http://gmao.gsfc.nasa.gov/" ;
		:CoreMetadata.INVENTORYMETADATA.GROUPTYPE = "MASTERGROUP" ;
		:CoreMetadata.INVENTORYMETADATA.ECSDATAGRANULE.LOCALGRANULEID.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.ECSDATAGRANULE.LOCALGRANULEID.VALUE = "\"MERRA100.prod.assim.tavg1_2d_slv_Nx.19900609.hdf\"" ;
		:CoreMetadata.INVENTORYMETADATA.ECSDATAGRANULE.LOCALVERSIONID.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.ECSDATAGRANULE.LOCALVERSIONID.VALUE = "\"V01\"" ;
		:CoreMetadata.INVENTORYMETADATA.MEASUREDPARAMETER.MEASUREDPARAMETERCONTAINER.CLASS = "\"0\"\n",
			"\"1\"\n",
			"\"2\"\n",
			"\"3\"\n",
			"\"4\"\n",
			"\"5\"\n",
			"\"6\"\n",
			"\"7\"\n",
			"\"8\"\n",
			"\"9\"\n",
			"\"10\"\n",
			"\"11\"\n",
			"\"12\"\n",
			"\"13\"\n",
			"\"14\"\n",
			"\"15\"\n",
			"\"16\"\n",
			"\"17\"\n",
			"\"18\"\n",
			"\"19\"\n",
			"\"20\"\n",
			"\"21\"\n",
			"\"22\"\n",
			"\"23\"\n",
			"\"24\"\n",
			"\"25\"\n",
			"\"26\"\n",
			"\"27\"\n",
			"\"28\"\n",
			"\"29\"\n",
			"\"30\"\n",
			"\"31\"\n",
			"\"32\"\n",
			"\"33\"\n",
			"\"34\"\n",
			"\"35\"\n",
			"\"36\"\n",
			"\"37\"" ;
		:CoreMetadata.INVENTORYMETADATA.MEASUREDPARAMETER.MEASUREDPARAMETERCONTAINER.PARAMETERNAME.CLASS = "\"0\"\n",
			"\"1\"\n",
			"\"2\"\n",
			"\"3\"\n",
			"\"4\"\n",
			"\"5\"\n",
			"\"6\"\n",
			"\"7\"\n",
			"\"8\"\n",
			"\"9\"\n",
			"\"10\"\n",
			"\"11\"\n",
			"\"12\"\n",
			"\"13\"\n",
			"\"14\"\n",
			"\"15\"\n",
			"\"16\"\n",
			"\"17\"\n",
			"\"18\"\n",
			"\"19\"\n",
			"\"20\"\n",
			"\"21\"\n",
			"\"22\"\n",
			"\"23\"\n",
			"\"24\"\n",
			"\"25\"\n",
			"\"26\"\n",
			"\"27\"\n",
			"\"28\"\n",
			"\"29\"\n",
			"\"30\"\n",
			"\"31\"\n",
			"\"32\"\n",
			"\"33\"\n",
			"\"34\"\n",
			"\"35\"\n",
			"\"36\"\n",
			"\"37\"" ;
		:CoreMetadata.INVENTORYMETADATA.MEASUREDPARAMETER.MEASUREDPARAMETERCONTAINER.PARAMETERNAME.NUM_VAL = 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ;
		:CoreMetadata.INVENTORYMETADATA.MEASUREDPARAMETER.MEASUREDPARAMETERCONTAINER.PARAMETERNAME.VALUE = "\"SLP\"\n",
			"\"PS\"\n",
			"\"U850\"\n",
			"\"U500\"\n",
			"\"U250\"\n",
			"\"V850\"\n",
			"\"V500\"\n",
			"\"V250\"\n",
			"\"T850\"\n",
			"\"T500\"\n",
			"\"T250\"\n",
			"\"Q850\"\n",
			"\"Q500\"\n",
			"\"Q250\"\n",
			"\"H1000\"\n",
			"\"H850\"\n",
			"\"H500\"\n",
			"\"H250\"\n",
			"\"OMEGA500\"\n",
			"\"U10M\"\n",
			"\"U2M\"\n",
			"\"U50M\"\n",
			"\"V10M\"\n",
			"\"V2M\"\n",
			"\"V50M\"\n",
			"\"T10M\"\n",
			"\"T2M\"\n",
			"\"QV10M\"\n",
			"\"QV2M\"\n",
			"\"TS\"\n",
			"\"DISPH\"\n",
			"\"TROPPV\"\n",
			"\"TROPPT\"\n",
			"\"TROPPB\"\n",
			"\"TROPT\"\n",
			"\"TROPQ\"\n",
			"\"CLDPRS\"\n",
			"\"CLDTMP\"" ;
		:CoreMetadata.INVENTORYMETADATA.MEASUREDPARAMETER.MEASUREDPARAMETERCONTAINER.QAFLAGS.CLASS = "\"0\"\n",
			"\"1\"\n",
			"\"2\"\n",
			"\"3\"\n",
			"\"4\"\n",
			"\"5\"\n",
			"\"6\"\n",
			"\"7\"\n",
			"\"8\"\n",
			"\"9\"\n",
			"\"10\"\n",
			"\"11\"\n",
			"\"12\"\n",
			"\"13\"\n",
			"\"14\"\n",
			"\"15\"\n",
			"\"16\"\n",
			"\"17\"\n",
			"\"18\"\n",
			"\"19\"\n",
			"\"20\"\n",
			"\"21\"\n",
			"\"22\"\n",
			"\"23\"\n",
			"\"24\"\n",
			"\"25\"\n",
			"\"26\"\n",
			"\"27\"\n",
			"\"28\"\n",
			"\"29\"\n",
			"\"30\"\n",
			"\"31\"\n",
			"\"32\"\n",
			"\"33\"\n",
			"\"34\"\n",
			"\"35\"\n",
			"\"36\"\n",
			"\"37\"" ;
		:CoreMetadata.INVENTORYMETADATA.MEASUREDPARAMETER.MEASUREDPARAMETERCONTAINER.QAFLAGS.AUTOMATICQUALITYFLAG.NUM_VAL = 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ;
		:CoreMetadata.INVENTORYMETADATA.MEASUREDPARAMETER.MEASUREDPARAMETERCONTAINER.QAFLAGS.AUTOMATICQUALITYFLAG.VALUE = "\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"\n",
			"\"Passed\"" ;
		:CoreMetadata.INVENTORYMETADATA.MEASUREDPARAMETER.MEASUREDPARAMETERCONTAINER.QAFLAGS.AUTOMATICQUALITYFLAGEXPLANATION.NUM_VAL = 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ;
		:CoreMetadata.INVENTORYMETADATA.MEASUREDPARAMETER.MEASUREDPARAMETERCONTAINER.QAFLAGS.AUTOMATICQUALITYFLAGEXPLANATION.VALUE = "\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"\n",
			"\"parameter is produced correctly\"" ;
		:CoreMetadata.INVENTORYMETADATA.COLLECTIONDESCRIPTIONCLASS.SHORTNAME.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.COLLECTIONDESCRIPTIONCLASS.SHORTNAME.VALUE = "\"MAT1NXSLV\"" ;
		:CoreMetadata.INVENTORYMETADATA.COLLECTIONDESCRIPTIONCLASS.VERSIONID.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.COLLECTIONDESCRIPTIONCLASS.VERSIONID.VALUE = "\"5.2.0\"" ;
		:CoreMetadata.INVENTORYMETADATA.SPATIALDOMAINCONTAINER.HORIZONTALSPATIALDOMAINCONTAINER.BOUNDINGRECTANGLE.WESTBOUNDINGCOORDINATE.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.SPATIALDOMAINCONTAINER.HORIZONTALSPATIALDOMAINCONTAINER.BOUNDINGRECTANGLE.WESTBOUNDINGCOORDINATE.VALUE = -180. ;
		:CoreMetadata.INVENTORYMETADATA.SPATIALDOMAINCONTAINER.HORIZONTALSPATIALDOMAINCONTAINER.BOUNDINGRECTANGLE.EASTBOUNDINGCOORDINATE.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.SPATIALDOMAINCONTAINER.HORIZONTALSPATIALDOMAINCONTAINER.BOUNDINGRECTANGLE.EASTBOUNDINGCOORDINATE.VALUE = 180. ;
		:CoreMetadata.INVENTORYMETADATA.SPATIALDOMAINCONTAINER.HORIZONTALSPATIALDOMAINCONTAINER.BOUNDINGRECTANGLE.NORTHBOUNDINGCOORDINATE.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.SPATIALDOMAINCONTAINER.HORIZONTALSPATIALDOMAINCONTAINER.BOUNDINGRECTANGLE.NORTHBOUNDINGCOORDINATE.VALUE = 90. ;
		:CoreMetadata.INVENTORYMETADATA.SPATIALDOMAINCONTAINER.HORIZONTALSPATIALDOMAINCONTAINER.BOUNDINGRECTANGLE.SOUTHBOUNDINGCOORDINATE.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.SPATIALDOMAINCONTAINER.HORIZONTALSPATIALDOMAINCONTAINER.BOUNDINGRECTANGLE.SOUTHBOUNDINGCOORDINATE.VALUE = -90. ;
		:CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEBEGINNINGTIME.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEBEGINNINGTIME.VALUE = "\"00:00:00Z\"" ;
		:CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEBEGINNINGDATE.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEBEGINNINGDATE.VALUE = "\"1990-06-09\"" ;
		:CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEENDINGTIME.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEENDINGTIME.VALUE = "\"23:59:59Z\"" ;
		:CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEENDINGDATE.NUM_VAL = 1 ;
		:CoreMetadata.INVENTORYMETADATA.RANGEDATETIME.RANGEENDINGDATE.VALUE = "\"1990-06-09\"" ;
		:ArchiveMetadata.ARCHIVEDMETADATA.GROUPTYPE = "MASTERGROUP" ;
		:ArchiveMetadata.ARCHIVEDMETADATA.TimesPerDay.NUM_VAL = 1 ;
		:ArchiveMetadata.ARCHIVEDMETADATA.TimesPerDay.VALUE = 24 ;
		:ArchiveMetadata.ARCHIVEDMETADATA.ParameterFormat.NUM_VAL = 1 ;
		:ArchiveMetadata.ARCHIVEDMETADATA.ParameterFormat.VALUE = "\"32-bit floating point\"" ;
		:ArchiveMetadata.ARCHIVEDMETADATA.MissingValue.NUM_VAL = 1 ;
		:ArchiveMetadata.ARCHIVEDMETADATA.MissingValue.VALUE = 1.e+15 ;
		:ArchiveMetadata.ARCHIVEDMETADATA.UnpackingScaleFactor.NUM_VAL = 1 ;
		:ArchiveMetadata.ARCHIVEDMETADATA.UnpackingScaleFactor.VALUE = 1 ;
		:ArchiveMetadata.ARCHIVEDMETADATA.UnpackingOffset.NUM_VAL = 1 ;
		:ArchiveMetadata.ARCHIVEDMETADATA.UnpackingOffset.VALUE = 0 ;
		:NCO = "\"4.5.3\"" ;
data:

 SLP =
  100148.8, 100093.8,
  100056.8, 100026.8,
  99973.8, 99952.8 ;

 TIME = 660 ;

 TIME_bnds =
  630, 690 ;

 XDim = 54, 54.6666666666667 ;

 YDim = 54, 54.5, 55 ;
}
ENDFILE
FILE=expected_scrubbed.MAT1NXSLV_5_2_0_SLP.199006091100.cdl
netcdf scrubbed.MAT1NXSLV_5_2_0_SLP.199006091100 {
dimensions:
	lonv = 2 ;
	lon = 2 ;
	latv = 2 ;
	lat = 3 ;
	time = UNLIMITED ; // (1 currently)
	bnds = 2 ;
variables:
	double lon_bnds(lon, lonv) ;
		lon_bnds:units = "degrees_east" ;
	double lat_bnds(lat, latv) ;
		lat_bnds:units = "degrees_north" ;
	double time(time) ;
		time:begin_date = 19900609 ;
		time:begin_time = 3000 ;
		time:bounds = "time_bnds" ;
		time:fullpath = "TIME:EOSGRID" ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:time_increment = 10000 ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float MAT1NXSLV_5_2_0_SLP(time, lat, lon) ;
		MAT1NXSLV_5_2_0_SLP:_FillValue = 1.e+15f ;
		MAT1NXSLV_5_2_0_SLP:fmissing_value = 1.e+15f ;
		MAT1NXSLV_5_2_0_SLP:fullpath = "/EOSGRID/Data Fields/SLP" ;
		MAT1NXSLV_5_2_0_SLP:missing_value = 1.e+15f ;
		MAT1NXSLV_5_2_0_SLP:vmax = 1.e+30f ;
		MAT1NXSLV_5_2_0_SLP:vmin = -1.e+30f ;
		MAT1NXSLV_5_2_0_SLP:standard_name = "air_pressure_at_sea_level" ;
		MAT1NXSLV_5_2_0_SLP:quantity_type = "Air Pressure" ;
		MAT1NXSLV_5_2_0_SLP:product_short_name = "MAT1NXSLV" ;
		MAT1NXSLV_5_2_0_SLP:product_version = "5.2.0" ;
		MAT1NXSLV_5_2_0_SLP:long_name = "Sea Level Pressure, time average" ;
		MAT1NXSLV_5_2_0_SLP:coordinates = "time lat lon" ;
		MAT1NXSLV_5_2_0_SLP:units = "hPa" ;
	double lon(lon) ;
		lon:units = "degrees_east" ;
		lon:fullpath = "XDim:EOSGRID" ;
		lon:standard_name = "longitude" ;
		lon:bounds = "lon_bnds" ;
	double lat(lat) ;
		lat:units = "degrees_north" ;
		lat:fullpath = "YDim:EOSGRID" ;
		lat:standard_name = "latitude" ;
		lat:bounds = "lat_bnds" ;
	int time_bnds(time, bnds) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;
		time_bnds:standard_name = "bounds" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "1990-06-09T11:00:00Z" ;
		:end_time = "1990-06-09T12:00:00Z" ;
		:temporal_resolution = "hourly" ;
		:nco_openmp_thread_number = 1 ;
data:

 lon_bnds =
  53.6667, 54.3333,
  54.3333, 55 ;

 lat_bnds =
  53.75, 54.25,
  54.25, 54.75,
  54.75, 55.25 ;

 time = 644931000 ;

 MAT1NXSLV_5_2_0_SLP =
  1001.488, 1000.938,
  1000.568, 1000.268,
  999.738, 999.528 ;

 lon = 54, 54.6666666666667 ;

 lat = 54, 54.5, 55 ;

 time_bnds =
  644929200, 644932800 ;
}
ENDFILE
