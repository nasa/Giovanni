
use Test::More tests => 4;
BEGIN { use_ok('Giovanni::PostProcess') }

use warnings;
use strict;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FindBin;
use Giovanni::Data::NcFile;
use Giovanni::Util;

# Write contents of __DATA__ to disk
my $tmpdir = tempdir( CLEANUP => 1 );
my ( $cdlInput, $cdlOutputCorrect ) = getCdlData();
my $ncInput         = "$tmpdir/ncInput.nc";
my $ncOutputCorrect = "$tmpdir/ncOutputCorrect";

Giovanni::Data::NcFile::write_netcdf_file( $ncInput, $cdlInput )
    or die "Unable to write input file";
Giovanni::Data::NcFile::write_netcdf_file( $ncOutputCorrect,
    $cdlOutputCorrect )
    or die "Unable to write correct output file";

# Run Post-Process Procedure
my $mfstDataFieldInfo = getDataFieldInfo("$tmpdir/mfst.data_field_info.xml");
my $mfstDataFieldSlice
    = getDataFieldSlice("$tmpdir/mfst.data_field_slice.xml");
my $mfstInput   = getMfstInput( "$tmpdir/mfstInput.xml", $ncInput );
my $mfstOutput  = "$tmpdir/mfstOutput.xml";
my $unitsConfig = "$FindBin::Bin/../../cfg/unitsCfg.xml";

my $rc = Giovanni::PostProcess::run(
    'bbox'        => '-180,-50,180,50',
    'endtime'     => '2005-01-01T23:59Z',
    'infile'      => $mfstInput,
    'name'        => 'Time Averaged Map',
    'outfile'     => $mfstOutput,
    'session-dir' => $tmpdir,
    'service'     => 'TmAvMp',
    'starttime'   => '2005-01-01T00:00Z',
    'units'       => "m,$unitsConfig",
    'varfiles'    => $mfstDataFieldInfo,
    'variables'   => 'AIRX3STD_006_GPHeight_D',
    'zfiles'      => $mfstDataFieldSlice
);

is( 0, $rc, "Got return code 0 from run()" );

# Compare Results
my $mfstRead = Giovanni::Util::getDataFilesFromManifest($mfstOutput);
is( 1, scalar @{ $mfstRead->{data} }, "Got one output file" );
my $ncOutputGot = $mfstRead->{data}->[0];

my $out = Giovanni::Data::NcFile::diff_netcdf_files( $ncOutputGot,
    $ncOutputCorrect, "/plot_hint_caption" );
is( $out, '', "Same output: $out" );

sub getMfstInput {
    my ( $fname, $ncInput ) = @_;

    open( MFST, ">$fname" );
    print MFST "<?xml version='1.0' encoding='UTF-8'?>\n";
    print MFST "<manifest>\n";
    print MFST "  <fileList>\n";
    print MFST "    <file>" . abs_path($ncInput) . "</file>\n";
    print MFST "  </fileList>\n";
    print MFST "</manifest>\n";
    close(MFST);

    return $fname;
}

sub getDataFieldInfo {
    my ($fname) = @_;

    open( FH, ">$fname" );
    print FH <<EOF;
<varList><var id="AIRX3STD_006_GPHeight_D" zDimUnits="hPa" long_name="Geopotential Height (Nighttime/Descending)" sampleOpendap="http://acdisc.gsfc.nasa.gov/opendap/hyrax/ncml/Aqua_AIRS_Level3/AIRX3STD.006/2002/AIRS.2002.08.31.L3.RetStd001.v6.0.9.0.G13208034313.hdf.ncml.html" dataProductTimeFrequency="1" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" url="http://dev-ts2.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Aqua%20AIRS%20Level%203%20Daily%20Standard%20Physical%20Retrieval%20(AIRS%2BAMSU)%20V006;agent_id=OPeNDAP;variables=GPHeight_D,TempPrsLvls_D" startTime="2002-08-31T00:00:00Z" responseFormat="netCDF" south="-90.0" dataProductTimeInterval="daily" dataProductVersion="006" east="180.0" dataProductShortName="AIRX3STD" resolution="1 deg." dataProductPlatformInstrument="AIRS" quantity_type="Geopotential" zDimName="TempPrsLvls_D" dataFieldStandardName="geopotential_height" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="m" latitudeResolution="1.0" accessName="GPHeight_D,TempPrsLvls_D" fillValueFieldName="_FillValue" accumulatable="false" spatialResolutionUnits="deg." longitudeResolution="1.0" dataProductStartTimeOffset="1" dataProductEndTimeOffset="-1" west="-180.0" zDimValues="1000 925 850 700 600 500 400 300 250 200 150 100 70 50 30 20 15 10 7 5 3 2 1.5 1" sdsName="GPHeight_D" dataProductBeginDateTime="2002-08-31T00:00:00Z"><slds><sld url="http://dev-ts2.gesdisc.eosdis.nasa.gov/giovanni/sld/divergent_rdbu_10_sld.xml" label="Red-Blue (Div), 10"/></slds></var></varList>
EOF

    close(FH);
    return $fname;
}

sub getDataFieldSlice {
    my ($fname) = @_;

    open( FH, ">$fname" );
    print FH
        '<manifest><data zValue="50" units="NA">AIRX3STD_006_GPHeight_D</data></manifest>';
    close(FH);

    return $fname;
}

sub getCdlData {

    # read block at __DATA__ and write to a CDL file
    #(stolen from Christine who stole from Chris...)
    my @cdldata;
    while (<DATA>) {
        push @cdldata, $_;
    }
    my $allCdf = join( '', @cdldata );

    # now divide up
    my @cdl = ( $allCdf =~ m/(netcdf .*?\}\n)/gs );
    return @cdl;
}

__DATA__
netcdf timeAvgMap.AIRX3STD_006_GPHeight_D.50hPa.20050101-20050101.180W_50S_180E_50N {
dimensions:
    lat = 100 ;
    lon = 360 ;
variables:
    float AIRX3STD_006_GPHeight_D(lat, lon) ;
        AIRX3STD_006_GPHeight_D:_FillValue = -9999.f ;
        AIRX3STD_006_GPHeight_D:standard_name = "geopotential_height" ;
        AIRX3STD_006_GPHeight_D:long_name = "Geopotential Height (Nighttime/Descending)" ;
        AIRX3STD_006_GPHeight_D:units = "m" ;
        AIRX3STD_006_GPHeight_D:coordinates = "lat lon" ;
        AIRX3STD_006_GPHeight_D:quantity_type = "Geopotential" ;
        AIRX3STD_006_GPHeight_D:product_short_name = "AIRX3STD" ;
        AIRX3STD_006_GPHeight_D:product_version = "006" ;
        AIRX3STD_006_GPHeight_D:cell_methods = "time: mean TempPrsLvls_D: mean time: mean" ;
        AIRX3STD_006_GPHeight_D:z_slice = "50hPa" ;
        AIRX3STD_006_GPHeight_D:z_slice_type = "pressure" ;
        AIRX3STD_006_GPHeight_D:latitude_resolution = 1. ;
        AIRX3STD_006_GPHeight_D:longitude_resolution = 1. ;
    float TempPrsLvls_D ;
        TempPrsLvls_D:standard_name = "Pressure" ;
        TempPrsLvls_D:long_name = "Pressure Levels Temperature Profile, nighttime (descending) node" ;
        TempPrsLvls_D:units = "hPa" ;
        TempPrsLvls_D:positive = "down" ;
        TempPrsLvls_D:_CoordinateAxisType = "GeoZ" ;
        TempPrsLvls_D:cell_methods = "TempPrsLvls_D: mean" ;
    double lat(lat) ;
        lat:units = "degrees_north" ;
        lat:format = "F5.1" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
        lat:missing_value = -9999.f ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:format = "F6.1" ;
        lon:standard_name = "longitude" ;
        lon:long_name = "Longitude" ;
        lon:missing_value = -9999.f ;
    int time ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2005-01-01T00:00:00Z" ;
        :end_time = "2005-01-01T23:59:59Z" ;
        :NCO = "4.4.4" ;
        :title = "AIRX3STD_006_GPHeight_D Averaged over 2005-01-01 to 2005-01-01" ;
        :userstartdate = "2005-01-01T00:00:00Z" ;
        :userenddate = "2005-01-01T23:59:59Z" ;
}
netcdf g4.timeAvgMap.AIRX3STD_006_GPHeight_D.50hPa.20050101-20050101.180W_50S_180E_50N {
dimensions:
    lat = 100 ;
    lon = 360 ;
variables:
    float AIRX3STD_006_GPHeight_D(lat, lon) ;
        AIRX3STD_006_GPHeight_D:_FillValue = -9999.f ;
        AIRX3STD_006_GPHeight_D:standard_name = "geopotential_height" ;
        AIRX3STD_006_GPHeight_D:long_name = "Geopotential Height (Nighttime/Descending)" ;
        AIRX3STD_006_GPHeight_D:units = "m" ;
        AIRX3STD_006_GPHeight_D:coordinates = "lat lon" ;
        AIRX3STD_006_GPHeight_D:quantity_type = "Geopotential" ;
        AIRX3STD_006_GPHeight_D:product_short_name = "AIRX3STD" ;
        AIRX3STD_006_GPHeight_D:product_version = "006" ;
        AIRX3STD_006_GPHeight_D:cell_methods = "time: mean TempPrsLvls_D: mean time: mean" ;
        AIRX3STD_006_GPHeight_D:z_slice = "50hPa" ;
        AIRX3STD_006_GPHeight_D:z_slice_type = "pressure" ;
        AIRX3STD_006_GPHeight_D:latitude_resolution = 1. ;
        AIRX3STD_006_GPHeight_D:longitude_resolution = 1. ;
    float TempPrsLvls_D ;
        TempPrsLvls_D:standard_name = "Pressure" ;
        TempPrsLvls_D:long_name = "Pressure Levels Temperature Profile, nighttime (descending) node" ;
        TempPrsLvls_D:units = "hPa" ;
        TempPrsLvls_D:positive = "down" ;
        TempPrsLvls_D:_CoordinateAxisType = "GeoZ" ;
        TempPrsLvls_D:cell_methods = "TempPrsLvls_D: mean" ;
    double lat(lat) ;
        lat:units = "degrees_north" ;
        lat:format = "F5.1" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
        lat:missing_value = -9999.f ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:format = "F6.1" ;
        lon:standard_name = "longitude" ;
        lon:long_name = "Longitude" ;
        lon:missing_value = -9999.f ;
    int time ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2005-01-01T00:00:00Z" ;
        :end_time = "2005-01-01T23:59:59Z" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Geopotential Height (Nighttime/Descending) daily 1 deg. @50hPa [AIRS AIRX3STD v006] m over 2005-01-01, Region 180W, 50S, 180E, 50N" ;
        :userstartdate = "2005-01-01T00:00:00Z" ;
        :userenddate = "2005-01-01T23:59:59Z" ;
        :plot_hint_title = "Time Averaged Map of Geopotential Height (Nighttime/Descending) daily 1 deg. @50hPa [AIRS AIRX3STD v006] m" ;
        :plot_hint_subtitle = "over 2005-01-01, Region 180W, 50S, 180E, 50N" ;
}
