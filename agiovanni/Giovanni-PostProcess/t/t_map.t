
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
    'bbox'        => '-82.9687,32.9531,-78.0469,38.5781',
    'endtime'     => '2005-01-01T23:59',
    'infile'      => $mfstInput,
    'name'        => 'Time Averaged Map',
    'outfile'     => $mfstOutput,
    'session-dir' => $tmpdir,
    'service'     => 'Mp',
    'starttime'   => '2005-01-01T00:00',
    'units'       => "mm/day,$unitsConfig",
    'varfiles'    => $mfstDataFieldInfo,
    'variables'   => 'TRMM_3B42_daily_precipitation_V7',
    'zfiles'      => $mfstDataFieldSlice
);

is( 0, $rc, "Got return code 0 from run()" );

# Compare Results
my $mfstRead = Giovanni::Util::getDataFilesFromManifest($mfstOutput);
is( 1, scalar @{ $mfstRead->{data} }, "Got one output file" );
my $ncOutputGot = $mfstRead->{data}->[0];

my $out = Giovanni::Data::NcFile::diff_netcdf_files( $ncOutputGot,
    $ncOutputCorrect );
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
<varList>
  <var id="TRMM_3B42_daily_precipitation_V7" long_name="Precipitation Rate" dataProductTimeFrequency="1" accessFormat="netCDF" north="50.0" accessMethod="HTTP_Services_HDF_TO_NetCDF" endTime="2038-01-19T03:14:07Z" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Daily%20TRMM%20and%20Others%20Rainfall%20Estimate%20(3B42%20V7%20derived)%20V7;agent_id=HTTP_Services_HDF_TO_NetCDF;variables=precipitation" startTime="1997-12-31T00:00:00Z" responseFormat="netCDF" south="-50.0" dataProductTimeInterval="daily" dataProductVersion="7" east="180.0" dataProductShortName="TRMM_3B42_daily" dataProductPlatformInstrument="TRMM" resolution="0.25 deg." quantity_type="Precipitation" dataFieldStandardName="" dataProductEndDateTime="2038-01-19T03:14:07Z" dataFieldUnitsValue="mm/day" latitudeResolution="0.25" accessName="precipitation" fillValueFieldName="" accumulatable="true" spatialResolutionUnits="deg." longitudeResolution="0.25" dataProductStartTimeOffset="-5400" dataProductEndTimeOffset="-5401" west="-180.0" sdsName="precipitation" dataProductBeginDateTime="1997-12-31T00:00:00Z">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/buylrd_div_12_panoply_sld.xml" label="Blue-Yellow-Red (Div), 12 (Source: Panoply)"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/rainfall_sld.xml" label="Green-Blue (Seq), 65"/>
    </slds>
  </var>
</varList>
EOF

    close(FH);
    return $fname;
}

sub getDataFieldSlice {
    my ($fname) = @_;

    open( FH, ">$fname" );
    print FH
        '<manifest><data zValue="NA" units="NA">TRMM_3B42_007_precipitation</data></manifest>';
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
netcdf timeAvgMap.TRMM_3B42_daily_precipitation_V7.20050101-20050101.82W_32N_78W_38N {
dimensions:
    lat = 22 ;
    lon = 20 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V7:cell_methods = "time: mean time: mean" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2004-12-31T22:30:00Z" ;
        :end_time = "2005-01-01T22:29:59Z" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day over 2004-12-31 22:30Z - 2005-01-01 22:29Z, Region 82.9687W, 32.9531N, 78.0469W, 38.5781N " ;
        :userstartdate = "2005-01-01T00:00:00Z" ;
        :userenddate = "2005-01-01T23:59:59Z" ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  0, 0, 0, 0, 0.1365725, 0.2073704, 0.4219906, 0, 0, 0, 0, 0, 1.027357, 0, 0, 
    0, 0, 0, 0.02954493, 0.1135429,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4.91376, 4.897701, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.886214, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 6.063284, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0.9335592, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0.485439, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0.09, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.465298, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4.678616, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 3.267203, 3.866767, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ;

 lat = 33.125, 33.375, 33.625, 33.875, 34.125, 34.375, 34.625, 34.875, 
    35.125, 35.375, 35.625, 35.875, 36.125, 36.375, 36.625, 36.875, 37.125, 
    37.375, 37.625, 37.875, 38.125, 38.375 ;

 lon = -82.875, -82.625, -82.375, -82.125, -81.875, -81.625, -81.375, 
    -81.125, -80.875, -80.625, -80.375, -80.125, -79.875, -79.625, -79.375, 
    -79.125, -78.875, -78.625, -78.375, -78.125 ;

 time = 1104532200 ;
}
netcdf out {
dimensions:
    lat = 22 ;
    lon = 20 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V7:cell_methods = "time: mean time: mean" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2004-12-31T22:30:00Z" ;
        :end_time = "2005-01-01T22:29:59Z" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day over 2004-12-31 22:30Z - 2005-01-01 22:29Z, Region 82.9687W, 32.9531N, 78.0469W, 38.5781N" ;
        :userstartdate = "2005-01-01T00:00:00Z" ;
        :userenddate = "2005-01-01T23:59:59Z" ;
        :plot_hint_title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day" ;
        :plot_hint_subtitle = "over 2004-12-31 22:30Z - 2005-01-01 22:29Z, Region 82.9687W, 32.9531N, 78.0469W, 38.5781N" ;
        :plot_hint_caption = "- Selected date range was 2005-01-01 00:00:00Z - 2005-01-01 23:59:00Z. Title reflects the date range of the granules that went into making this result." ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  0, 0, 0, 0, 0.1365725, 0.2073704, 0.4219906, 0, 0, 0, 0, 0, 1.027357, 0, 0, 
    0, 0, 0, 0.02954493, 0.1135429,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4.91376, 4.897701, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.886214, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 6.063284, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0.9335592, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0.485439, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0.09, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.465298, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4.678616, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 3.267203, 3.866767, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ;

 lat = 33.125, 33.375, 33.625, 33.875, 34.125, 34.375, 34.625, 34.875, 
    35.125, 35.375, 35.625, 35.875, 36.125, 36.375, 36.625, 36.875, 37.125, 
    37.375, 37.625, 37.875, 38.125, 38.375 ;

 lon = -82.875, -82.625, -82.375, -82.125, -81.875, -81.625, -81.375, 
    -81.125, -80.875, -80.625, -80.375, -80.125, -79.875, -79.625, -79.375, 
    -79.125, -78.875, -78.625, -78.375, -78.125 ;

 time = 1104532200 ;
}
