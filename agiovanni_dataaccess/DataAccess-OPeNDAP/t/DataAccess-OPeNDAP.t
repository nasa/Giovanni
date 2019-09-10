# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DataAccess-OPeNDAP.t'

#########################
#use File::Temp qw/ tempfile tempdir /;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 28;
use Giovanni::Catalog;
BEGIN { use_ok('DataAccess::OPeNDAP') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Hopefully trivial tests:
my $odAccess = DataAccess::OPeNDAP->new();
ok( $odAccess, "Created accessor object when no arguments were provided" );
ok( $odAccess->onError, "Flagged error when no arguments were provided" );
ok( $odAccess->errorMessage && ( $odAccess->errorMessage =~ /Must provide/ ),
    "Error message when no URL was provided"
);
$odAccess = DataAccess::OPeNDAP->new(
    VARIABLES => 'Angstrom_Exponent_1_Ocean_QA_Mean' );
ok( $odAccess, "Created accessor object when only VARIABLES was provided" );
ok( $odAccess->onError, "Flagged error when only VARIABLES was provided" );
ok( $odAccess->errorMessage && ( $odAccess->errorMessage =~ /Must provide/ ),
    "Error message when only VARIABLES was provided"
);

$odAccess = DataAccess::OPeNDAP->new(
    URLS =>
        'http://dev.gesdisc.eosdis.nasa.gov/opendap/GLDAS_NOAH025_3H.2.0/GLDAS_NOAH025_3H.A19480101.0300.020.nc4.ncml.html'
    );
ok( $odAccess, "Created accessor object when only URLS was provided" );
ok( $odAccess->onError, "Flagged error when only URLS was provided" );
ok( $odAccess->errorMessage && ( $odAccess->errorMessage =~ /Must provide/ ),
    "Error message when only URLS was provided"
);
$odAccess = DataAccess::OPeNDAP->new(
    VARIABLES => 'Angstrom_Exponent_1_Ocean_QA_Mean',
    URLS =>
        'http://ladsweb.nascom.nasa.gov/opendap/allData/51/MOD08_D3/2000/061/MOD08_D3.A2000061.051.2010273210218.hdf.html'
);
ok( $odAccess,
    "Created accessor object when required arguments were provided" );
ok( $odAccess->onError,
    "Flagged error when required arguments were wrong type" );
ok( $odAccess->errorMessage && ( $odAccess->errorMessage =~ /must be/ ),
    "Error message indicates variables argument is wrong type "
);

# Nominally $odAccess = DataAccess::OPeNDAP constructor if provided with a few 
# parameters can provide the OPeNDAP URL.
# The particular info that is needed is the DDX info.
# This can be retrieved from OPeNDAP in real time or 
# if this info has been obtained in an earlier workflow, retrieved from AESIR 
#
# This first example is of the DDX string itself
$oddxString=qq(<opt> <_LAT_DIMS name="latitude" offset="0" scaleFactor="1" size="180" /> <_LAT_LONG_INDEXES>0</_LAT_LONG_INDEXES> <_LAT_LONG_INDEXES>179</_LAT_LONG_INDEXES> <_LAT_LONG_INDEXES>0</_LAT_LONG_INDEXES> <_LAT_LONG_INDEXES>359</_LAT_LONG_INDEXES> <_LONG_DIMS name="longitude" offset="0" scaleFactor="1" size="360" /> <_VARIABLE_DIMS> <angstrom_exponent_land_ocean maxind="179" name="latitude" /> <angstrom_exponent_land_ocean maxind="359" name="longitude" /> </_VARIABLE_DIMS> </opt> );

$odAccess = DataAccess::OPeNDAP->new(
    METADATA    => $oddxString,
    FORMAT    => 'netCDF',
    VARIABLES => ['SWDB_L3M10_004_angstrom_exponent_land_ocean'],
    URLS      => [
        'http://measures.gsfc.nasa.gov/opendap/SWDB/SWDB_L3M10.004/2001/DeepBlue-SeaWiFS-1.0_L3M_200111_v004-20130604T141127Z.h5.html'
    ]
);
ok( $odAccess,
    "Created accessor object when required arguments were provided" );
ok( !$odAccess->onError, "No error when required arguments are proper type" );

my $list = $odAccess->getOpendapDownloadList();
ok( @$list,
    "getOpendapDownloadList returned non-empty response for valid arguments"
);
ok( ( @$list == 1 ), "getOpendapDownloadList returned a list of size 1" );



# This example retrieves DDX info from all of the variables in AESIR and applys one of them
my $catalog
        = Giovanni::Catalog->new( { URL => 'https://aesir.gsfc.nasa.gov/aesir_solr/TS1' } );
    my $fieldHash = $catalog->getActiveDataFields("oddxDims");

$odAccess = DataAccess::OPeNDAP->new(
    METADATA    => $fieldHash->{GLDAS_NOAH025_3H_2_0_SWE_inst}{oddxDims},
    VARIABLES => ['GLDAS_NOAH025_3H_2_0_SWE_inst'],
    FORMAT    => 'netCDF',
    URLS      => [
        'http://dev.gesdisc.eosdis.nasa.gov/opendap/GLDAS_NOAH025_3H.2.0/GLDAS_NOAH025_3H.A19480101.0300.020.nc4.ncml.html'
    ]
);
ok( $odAccess,
    "Created accessor object when required arguments were provided" );
ok( !$odAccess->onError, "No error when required arguments are proper type" );
$list = $odAccess->getOpendapDownloadList();
ok ( ( @$list == 1 ), "getOpendapDownloadList returned list of " . @$list . qq( pairs containing "$list->[0][0]   $list->[0][1]"));




# These 2 examples assumes that the DDX info has never been retrieved before and so it gets it from OPeNDAP.
$odAccess = DataAccess::OPeNDAP->new(
    VARIABLES => ['SWE_inst'],
    FORMAT    => 'netCDF',
    URLS      => [
        'http://dev.gesdisc.eosdis.nasa.gov/opendap/GLDAS_NOAH025_3H.2.0/GLDAS_NOAH025_3H.A19490101.2100.020.nc4.ncml.html'
    ]
);
ok( $odAccess,
    "Created accessor object when required arguments were provided" );
ok( !$odAccess->onError, "No error when required arguments are proper type" );
$list = $odAccess->getOpendapDownloadList();
ok ( ( @$list == 1 ), "getOpendapDownloadList returned list of " . @$list . qq( pairs containing "$list->[0][0]   $list->[0][1]"));

$odAccess = DataAccess::OPeNDAP->new(
    VARIABLES => ['Qsm_acc'],
    FORMAT    => 'netCDF',
    URLS      => [
        'http://dev.gesdisc.eosdis.nasa.gov/opendap/GLDAS_NOAH025_3H.2.0/GLDAS_NOAH025_3H.A19500101.0000.020.nc4.ncml.html'
    ]
);
ok( $odAccess,
    "Created accessor object when required arguments were provided" );
ok( !$odAccess->onError, "No error when required arguments are proper type" );
$list = $odAccess->getOpendapDownloadList();
ok ( ( @$list == 1 ), "getOpendapDownloadList returned list of " . @$list . qq( pairs containing "$list->[0][0]   $list->[0][1]"));


# A second example, the same as the one just above using a non giovanni variable:
# The only thing that needs to be supplied is the opendap URL and which variable you want to download.
# This didn't work because the lat lon's didn't have proper units: degrees_north etc
# 'https://disc1.gesdisc.eosdis.nasa.gov/opendap/tovs/TOVSADNG/1990/005/TOVS_DAILY_AM_900106_NG.HDF.Z.html'/Data_Set_43
# https://measures.gesdisc.eosdis.nasa.gov/opendap/GSSTF/GSSTF_F10.2c/1997/GSSTF_F10.2c.1997.11.14.he5.html / H
$odAccess = DataAccess::OPeNDAP->new(
    VARIABLES => ['H'],
    FORMAT    => 'netCDF',
    URLS      => [
        'https://measures.gesdisc.eosdis.nasa.gov/opendap/GSSTF/GSSTF_F10.2c/1997/GSSTF_F10.2c.1997.11.14.he5.html'
    ]
);
ok( $odAccess,
    "Created accessor object when required arguments were provided" );
ok( !$odAccess->onError, "No error when required arguments are proper type" );
$list = $odAccess->getOpendapDownloadList();
ok ( ( @$list == 1 ), "getOpendapDownloadList returned list of " . @$list . qq( pairs containing "$list->[0][0]   $list->[0][1]"));


# Test an OPeNDAP granule that has a time dimension with multiple values
# and which therefore will be split into multiple URLs
$odAccess = DataAccess::OPeNDAP->new(
    VARIABLES => ['SPEED'],
    FORMAT    => 'netCDF',
    URLS      => [
        'http://goldsmr4.gesdisc.eosdis.nasa.gov/opendap/MERRA2/M2T1NXFLX.5.12.4/1981/08/MERRA2_100.tavg1_2d_flx_Nx.19810808.nc4.html',
        'http://goldsmr4.gesdisc.eosdis.nasa.gov/opendap/MERRA2/M2T1NXFLX.5.12.4/1981/08/MERRA2_100.tavg1_2d_flx_Nx.19810809.nc4.html'
    ]
);
$list = $odAccess->getOpendapDownloadList();
ok ( ( @$list == 48 ), "getOpendapDownloadList returned list of " . @$list . qq( pairs starting with "$list->[0][0]   $list->[0][1]"));
my $mismatch;
foreach my $item (@$list) {
    my ($dlUrl, $dlName) = @$item;
    (my $dlNameDate1, $dlNameDate2) = $dlName =~ m/\.(\d{8})/g;
    $mismatch ||= ($dlNameDate1 ne $dlNameDate2);
}
ok ( !$mismatch, "Labels for timesplitting match in date" );
