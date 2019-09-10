
#!/usr/bin/env perl
#$Id: ncScrubber_3hr.t,v 1.10 2015/02/02 20:25:59 rstrub Exp $
#-@@@ AEROSOLS,Version $Name:  $
# Author: Xiaopeng Hu <Xiaopeng.Hu@nasa.gov>
# Date Created: 2011-04-09

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AEROSOLS-FormatData.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use File::Compare;
use File::Temp qw/ tempfile tempdir /;
use Test::More tests => 11;
use Giovanni::Data::NcFile;
$ENV{PERL5LIB}
    = "../Giovanni-DataField/lib:../Giovanni-BoundingBox/lib:../Giovanni-Util/lib:../Giovanni-Scrubber/lib:./lib:../Giovanni-ScienceCommand/lib:../Giovanni-WorldLongitude/lib:../Giovanni-Logger/lib:../Giovanni-ScienceCommand/lib";


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
# CLEANUP => 1
my $cleanup = defined( $ENV{'CLEANUP'} ) ? $ENV{'CLEANUP'} : 1;
my $debug   = defined( $ENV{DEBUG} )     ? '-d'            : '';
my $workingdir
    = ( defined $ENV{TESTDIR} )
    ? $ENV{TESTDIR}
    : tempdir( CLEANUP => $cleanup );
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
            ok( ( -e $ncfile ), "File exist: $ncfile" );
        }
        next;
    }
    my $line = $_;
    $line =~ s/WORKINGDIR/$workingdir/;
    print FH $line;
}

use Giovanni::DataField;
my $catalog = "$workingdir/varInfo1.xml";

my $dataFieldVarInfo = new Giovanni::DataField( MANIFEST => $catalog);
my $min = $dataFieldVarInfo->get_validMin; # ""
my $max = $dataFieldVarInfo->get_validMax; # no value at all
 
pass("empty string is false")
if (!Giovanni::Data::NcFile::StringBoolean($min,-9999.));
pass("no entry  is false")
if (!Giovanni::Data::NcFile::StringBoolean($max,-9999.));

$catalog = "$workingdir/varInfo2.xml";
$dataFieldVarInfo = new Giovanni::DataField( MANIFEST => $catalog);
$min = $dataFieldVarInfo->get_validMin; # "0"
$max = $dataFieldVarInfo->get_validMax; # "0.0"
 
pass("0 is true")
if (Giovanni::Data::NcFile::StringBoolean($min,-9999.));
pass("0.0 is true")
if (Giovanni::Data::NcFile::StringBoolean($max,-9999.));


$catalog = "$workingdir/varInfo3.xml";
$dataFieldVarInfo = new Giovanni::DataField( MANIFEST => $catalog);
$min = $dataFieldVarInfo->get_validMin; # negative number 
$max = $dataFieldVarInfo->get_validMax; # positive number

pass("pos nonzero is true")
if (Giovanni::Data::NcFile::StringBoolean($min,-9999.));
pass("neg nonzero is true")
if (Giovanni::Data::NcFile::StringBoolean($max,-9999.));

pass("9999 is true") # not fillvalue
if (Giovanni::Data::NcFile::StringBoolean(9999.,-9999.));
pass("-9999 is false") # fillvalue
if (!Giovanni::Data::NcFile::StringBoolean(-9999,-9999.));
pass("-9999. is false") # fillvalue
if (!Giovanni::Data::NcFile::StringBoolean(-9999.,-9999.));

 
###########################################################################
## NOTE:
##     For each expected Cdf file, the file name must start with "expected_".
##     However, in the following dumped section, the file name must start with "formatted_"
##     because we expect that "formatted_" prefix for comparing with the generated CDL file.
# Note: The new code can find the -5400 Offset in the HDFEOS global Metadata so
#       dataProductStartTimeOffsetshould be set to 0 after Sprint 70-B - or when we start using
#       $NcFile->populate_start_end_times()
###########################################################################
__DATA__
FILE=varInfo1.xml
<varList>
  <var id="TRMM_3B42_007_precipitation" dataProductEndDateTime="2038-01-19T03:14:07Z" long_name="Precipitation" dataFieldUnitsValue="mm/hr" latitudeResolution="0.25" fillValueFieldName="" dataProductTimeFrequency="3" accumulatable="true" spatialResolutionUnits="deg." accessFormat="netCDF" north="50.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" dataProductStartTimeOffset="-5400" dataProductEndTimeOffset="0" longitudeResolution="0.25" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=TRMM%203-Hourly%200.25%20deg.%20TRMM%20and%20Other-GPI%20Calibration%20Rainfall%20Data%20V7;agent_id=OPeNDAP;variables=precipitation" startTime="1998-01-01T00:00:00Z" responseFormat="netCDF" south="-50.0" dataProductTimeInterval="3-hourly" west="-180.0" dataProductVersion="7" east="180.0" sdsName="precipitation" dataProductShortName="TRMM_3B42" dataProductPlatformInstrument="TRMM" resolution="0.25 deg." quantity_type="Precipitation" deflationLevel="1" dataProductBeginDateTime="1998-01-01T00:00:00Z" dataFieldStandardName="" validMin="" >
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
    </slds>
  </var>
</varList>
ENDFILE
FILE=varInfo2.xml
<varList>
  <var id="TRMM_3B42_007_precipitation" dataProductEndDateTime="2038-01-19T03:14:07Z" long_name="Precipitation" dataFieldUnitsValue="mm/hr" latitudeResolution="0.25" fillValueFieldName="" dataProductTimeFrequency="3" accumulatable="true" spatialResolutionUnits="deg." accessFormat="netCDF" north="50.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" dataProductStartTimeOffset="-5400" dataProductEndTimeOffset="0" longitudeResolution="0.25" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=TRMM%203-Hourly%200.25%20deg.%20TRMM%20and%20Other-GPI%20Calibration%20Rainfall%20Data%20V7;agent_id=OPeNDAP;variables=precipitation" startTime="1998-01-01T00:00:00Z" responseFormat="netCDF" south="-50.0" dataProductTimeInterval="3-hourly" west="-180.0" dataProductVersion="7" east="180.0" sdsName="precipitation" dataProductShortName="TRMM_3B42" dataProductPlatformInstrument="TRMM" resolution="0.25 deg." quantity_type="Precipitation" deflationLevel="1" dataProductBeginDateTime="1998-01-01T00:00:00Z" dataFieldStandardName="" validMin="0" validMax="0.0">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
    </slds>
  </var>
</varList>
ENDFILE
FILE=varInfo3.xml
<varList>
  <var id="TRMM_3B42_007_precipitation" dataProductEndDateTime="2038-01-19T03:14:07Z" long_name="Precipitation" dataFieldUnitsValue="mm/hr" latitudeResolution="0.25" fillValueFieldName="" dataProductTimeFrequency="3" accumulatable="true" spatialResolutionUnits="deg." accessFormat="netCDF" north="50.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" dataProductStartTimeOffset="-5400" dataProductEndTimeOffset="0" longitudeResolution="0.25" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=TRMM%203-Hourly%200.25%20deg.%20TRMM%20and%20Other-GPI%20Calibration%20Rainfall%20Data%20V7;agent_id=OPeNDAP;variables=precipitation" startTime="1998-01-01T00:00:00Z" responseFormat="netCDF" south="-50.0" dataProductTimeInterval="3-hourly" west="-180.0" dataProductVersion="7" east="180.0" sdsName="precipitation" dataProductShortName="TRMM_3B42" dataProductPlatformInstrument="TRMM" resolution="0.25 deg." quantity_type="Precipitation" deflationLevel="1" dataProductBeginDateTime="1998-01-01T00:00:00Z" dataFieldStandardName="" validMin="-1.8" validMax="2.0">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
    </slds>
  </var>
</varList>
ENDFILE

