
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
    'bbox'        => '-79.487651,37.886604999999996,-74.986282,39.723037',
    'endtime'     => '2010-12-31T23:59:59Z',
    'infile'      => $mfstInput,
    'name'        => 'Time Series, Area-Averaged',
    'outfile'     => $mfstOutput,
    'session-dir' => $tmpdir,
    'service'     => 'ArAvTs',
    'starttime'   => '2010-01-01T00:00:00Z',
    'shapefile'   => 'tl_2014_us_state/shp_4',
    'units'       => "mm/hr,$unitsConfig",
    'varfiles'    => $mfstDataFieldInfo,
    'variables'   => 'TRMM_3B43_007_precipitation',
    'zfiles'      => $mfstDataFieldSlice,
    'time-axis'   => '1',
);

is( 0, $rc, "Got return code 0 from run()" );

# Compare Results
my $mfstRead = Giovanni::Util::getDataFilesFromManifest($mfstOutput);
is( 1, scalar @{ $mfstRead->{data} }, "Got one output file" );
my $ncOutputGot = $mfstRead->{data}->[0];

# delete the history for the output file
Giovanni::Data::NcFile::delete_history( $ncOutputGot, $ncOutputGot )
    or die "Unable to delete history";
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
  <var id="TRMM_3B43_007_precipitation" long_name="Precipitation Rate" dataProductTimeFrequency="1" accessFormat="netCDF" north="50.0" accessMethod="HTTP_Services_HDF_TO_NetCDF" endTime="2015-02-28T23:59:59Z" url="http://dev-ts1.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=TRMM%20and%20Other%20Sources%20Monthly%20Rainfall%20Product%20(TRMM%20Product%203B43)%20V7;agent_id=HTTP_Services_HDF_TO_NetCDF;variables=pcp" startTime="1998-01-01T00:00:00Z" responseFormat="netCDF" south="-50.0" dataProductTimeInterval="monthly" dataProductVersion="7" sampleFile="" east="180.0" osdd="" dataProductShortName="TRMM_3B43" resolution="0.25 deg." dataProductPlatformInstrument="TRMM" quantity_type="Precipitation" deflationLevel="1" dataFieldStandardName="" dataProductEndDateTime="2015-02-28T23:59:59Z" dataFieldUnitsValue="mm/hr" latitudeResolution="0.25" accessName="pcp" fillValueFieldName="" valuesDistribution="linear" accumulatable="true" spatialResolutionUnits="deg." longitudeResolution="0.25" dataProductStartTimeOffset="1" dataProductEndTimeOffset="0" west="-180.0" sdsName="precipitation" dataProductBeginDateTime="1998-01-01T00:00:00Z">
    <slds>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/buylrd_div_12_panoply_sld.xml" label="Blue-Yellow-Red (Div), 12 (Source: Panoply)"/>
      <sld url="http://dev-ts1.gesdisc.eosdis.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue (Seq), 9"/>
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
netcdf areaAvgTimeSeries.TRMM_3B43_007_precipitation.20100101-20101231.79W_37N_74W_39N {
dimensions:
    time = UNLIMITED ; // (12 currently)
variables:
    float TRMM_3B43_007_precipitation(time) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time" ;
        TRMM_3B43_007_precipitation:cell_methods = "lat,lon: mean" ;
    int count_TRMM_3B43_007_precipitation(time) ;
        count_TRMM_3B43_007_precipitation:_FillValue = -999 ;
        count_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        count_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        count_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        count_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        count_TRMM_3B43_007_precipitation:long_name = "count of Precipitation Rate" ;
        count_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        count_TRMM_3B43_007_precipitation:product_version = "7" ;
        count_TRMM_3B43_007_precipitation:quantity_type = "count of Precipitation" ;
        count_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        count_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        count_TRMM_3B43_007_precipitation:units = "mm/hr" ;
        count_TRMM_3B43_007_precipitation:coordinates = "time" ;
    float max_TRMM_3B43_007_precipitation(time) ;
        max_TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        max_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        max_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        max_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        max_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        max_TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        max_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        max_TRMM_3B43_007_precipitation:product_version = "7" ;
        max_TRMM_3B43_007_precipitation:quantity_type = "maximum of Precipitation" ;
        max_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        max_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        max_TRMM_3B43_007_precipitation:units = "mm/hr" ;
        max_TRMM_3B43_007_precipitation:coordinates = "time" ;
        max_TRMM_3B43_007_precipitation:cell_methods = "lat,lon: maximum" ;
    float min_TRMM_3B43_007_precipitation(time) ;
        min_TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        min_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        min_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        min_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        min_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        min_TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        min_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        min_TRMM_3B43_007_precipitation:product_version = "7" ;
        min_TRMM_3B43_007_precipitation:quantity_type = "minimum of Precipitation" ;
        min_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        min_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        min_TRMM_3B43_007_precipitation:units = "mm/hr" ;
        min_TRMM_3B43_007_precipitation:coordinates = "time" ;
        min_TRMM_3B43_007_precipitation:cell_methods = "lat,lon: minimum" ;
    float stddev_TRMM_3B43_007_precipitation(time) ;
        stddev_TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        stddev_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        stddev_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        stddev_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        stddev_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        stddev_TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        stddev_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        stddev_TRMM_3B43_007_precipitation:product_version = "7" ;
        stddev_TRMM_3B43_007_precipitation:quantity_type = "standard deviation of Precipitation" ;
        stddev_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        stddev_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        stddev_TRMM_3B43_007_precipitation:units = "mm/hr" ;
        stddev_TRMM_3B43_007_precipitation:coordinates = "time" ;
        stddev_TRMM_3B43_007_precipitation:cell_methods = "lat,lon: standard deviation" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :NCO = "\"4.5.3\"" ;
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2010-01-01T00:00:00Z" ;
        :end_time = "2010-12-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :userstartdate = "2010-01-01T00:00:00Z" ;
        :userenddate = "2010-12-31T23:59:59Z" ;
data:

 TRMM_3B43_007_precipitation = 0.1031572, 0.1262143, 0.1781155, 0.08443902, 
    0.108007, 0.08221371, 0.1450384, 0.1332743, 0.2633432, 0.1147479, 
    0.07757945, 0.07147448 ;

 count_TRMM_3B43_007_precipitation = 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 
    71, 71 ;

 max_TRMM_3B43_007_precipitation = 0.1491, 0.1545522, 0.2354962, 0.1176911, 
    0.1735561, 0.1629394, 0.2278775, 0.1864865, 0.3890669, 0.1525602, 
    0.1607444, 0.1026398 ;

 min_TRMM_3B43_007_precipitation = 0.0885205, 0.08611593, 0.1008019, 
    0.05493916, 0.06299202, 0.06140799, 0.09670047, 0.07271225, 0.1653714, 
    0.06334045, 0.04263934, 0.06127501 ;

 stddev_TRMM_3B43_007_precipitation = 0.01018041, 0.01737979, 0.02813733, 
    0.01480785, 0.03175643, 0.02108077, 0.03758306, 0.02728483, 0.05601219, 
    0.02510941, 0.02860337, 0.006812642 ;

 time = 1262304000, 1264982400, 1267401600, 1270080000, 1272672000, 
    1275350400, 1277942400, 1280620800, 1283299200, 1285891200, 1288569600, 
    1291161600 ;
}
netcdf correct {
dimensions:
    bnds = 2 ;
    time = UNLIMITED ; // (12 currently)
variables:
    int time_bnds(time, bnds) ;
    float TRMM_3B43_007_precipitation(time) ;
        TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        TRMM_3B43_007_precipitation:grid_type = "linear" ;
        TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        TRMM_3B43_007_precipitation:product_version = "7" ;
        TRMM_3B43_007_precipitation:quantity_type = "Precipitation" ;
        TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        TRMM_3B43_007_precipitation:units = "mm/hr" ;
        TRMM_3B43_007_precipitation:coordinates = "time" ;
        TRMM_3B43_007_precipitation:cell_methods = "lat,lon: mean" ;
    int count_TRMM_3B43_007_precipitation(time) ;
        count_TRMM_3B43_007_precipitation:_FillValue = -999 ;
        count_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        count_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        count_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        count_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        count_TRMM_3B43_007_precipitation:long_name = "count of Precipitation Rate" ;
        count_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        count_TRMM_3B43_007_precipitation:product_version = "7" ;
        count_TRMM_3B43_007_precipitation:quantity_type = "count of Precipitation" ;
        count_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        count_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        count_TRMM_3B43_007_precipitation:units = "mm/hr" ;
        count_TRMM_3B43_007_precipitation:coordinates = "time" ;
    float max_TRMM_3B43_007_precipitation(time) ;
        max_TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        max_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        max_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        max_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        max_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        max_TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        max_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        max_TRMM_3B43_007_precipitation:product_version = "7" ;
        max_TRMM_3B43_007_precipitation:quantity_type = "maximum of Precipitation" ;
        max_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        max_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        max_TRMM_3B43_007_precipitation:units = "mm/hr" ;
        max_TRMM_3B43_007_precipitation:coordinates = "time" ;
        max_TRMM_3B43_007_precipitation:cell_methods = "lat,lon: maximum" ;
    float min_TRMM_3B43_007_precipitation(time) ;
        min_TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        min_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        min_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        min_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        min_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        min_TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        min_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        min_TRMM_3B43_007_precipitation:product_version = "7" ;
        min_TRMM_3B43_007_precipitation:quantity_type = "minimum of Precipitation" ;
        min_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        min_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        min_TRMM_3B43_007_precipitation:units = "mm/hr" ;
        min_TRMM_3B43_007_precipitation:coordinates = "time" ;
        min_TRMM_3B43_007_precipitation:cell_methods = "lat,lon: minimum" ;
    float stddev_TRMM_3B43_007_precipitation(time) ;
        stddev_TRMM_3B43_007_precipitation:_FillValue = -9999.9f ;
        stddev_TRMM_3B43_007_precipitation:comments = "Unknown1 variable comment" ;
        stddev_TRMM_3B43_007_precipitation:grid_name = "grid-1" ;
        stddev_TRMM_3B43_007_precipitation:grid_type = "linear" ;
        stddev_TRMM_3B43_007_precipitation:level_description = "Earth surface" ;
        stddev_TRMM_3B43_007_precipitation:long_name = "Precipitation Rate" ;
        stddev_TRMM_3B43_007_precipitation:product_short_name = "TRMM_3B43" ;
        stddev_TRMM_3B43_007_precipitation:product_version = "7" ;
        stddev_TRMM_3B43_007_precipitation:quantity_type = "standard deviation of Precipitation" ;
        stddev_TRMM_3B43_007_precipitation:standard_name = "pcp" ;
        stddev_TRMM_3B43_007_precipitation:time_statistic = "instantaneous" ;
        stddev_TRMM_3B43_007_precipitation:units = "mm/hr" ;
        stddev_TRMM_3B43_007_precipitation:coordinates = "time" ;
        stddev_TRMM_3B43_007_precipitation:cell_methods = "lat,lon: standard deviation" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:bounds = "time_bnds" ;

// global attributes:
        :NCO = "\"4.5.3\"" ;
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2010-01-01T00:00:00Z" ;
        :end_time = "2010-12-31T23:59:59Z" ;
        :temporal_resolution = "monthly" ;
        :userstartdate = "2010-01-01T00:00:00Z" ;
        :userenddate = "2010-12-31T23:59:59Z" ;
        :title = "Time Series, Area-Averaged of Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v7] mm/hr over 2010-Jan - 2010-Dec, Shape Maryland, Region 79.487651W, 37.886604999999996N, 74.986282W, 39.723037N" ;
        :plot_hint_title = "Time Series, Area-Averaged of Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v7] mm/hr over" ;
        :plot_hint_subtitle = "2010-Jan - 2010-Dec, Shape Maryland, Region 79.487651W, 37.886604999999996N, 74.986282W, 39.723037N" ;
        :plot_hint_y_axis_label = "mm/hr" ;
        :plot_hint_time_axis_values = "1262304000,1267401600,1272672000,1277942400,1283299200,1288569600,1293840000" ;
        :plot_hint_time_axis_labels = "Jan,Mar,May,Jul,Sep,Nov,Jan~C~2011" ;
        :plot_hint_time_axis_minor = "1264982400,1270080000,1275350400,1280620800,1285891200,1291161600" ;
data:

 time_bnds =
  1262304000, 1264982400,
  1264982400, 1267401600,
  1267401600, 1270080000,
  1270080000, 1272672000,
  1272672000, 1275350400,
  1275350400, 1277942400,
  1277942400, 1280620800,
  1280620800, 1283299200,
  1283299200, 1285891200,
  1285891200, 1288569600,
  1288569600, 1291161600,
  1291161600, 1293840000 ;

 TRMM_3B43_007_precipitation = 0.1031572, 0.1262143, 0.1781155, 0.08443902, 
    0.108007, 0.08221371, 0.1450384, 0.1332743, 0.2633432, 0.1147479, 
    0.07757945, 0.07147448 ;

 count_TRMM_3B43_007_precipitation = 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 
    71, 71 ;

 max_TRMM_3B43_007_precipitation = 0.1491, 0.1545522, 0.2354962, 0.1176911, 
    0.1735561, 0.1629394, 0.2278775, 0.1864865, 0.3890669, 0.1525602, 
    0.1607444, 0.1026398 ;

 min_TRMM_3B43_007_precipitation = 0.0885205, 0.08611593, 0.1008019, 
    0.05493916, 0.06299202, 0.06140799, 0.09670047, 0.07271225, 0.1653714, 
    0.06334045, 0.04263934, 0.06127501 ;

 stddev_TRMM_3B43_007_precipitation = 0.01018041, 0.01737979, 0.02813733, 
    0.01480785, 0.03175643, 0.02108077, 0.03758306, 0.02728483, 0.05601219, 
    0.02510941, 0.02860337, 0.006812642 ;

 time = 1262304000, 1264982400, 1267401600, 1270080000, 1272672000, 
    1275350400, 1277942400, 1280620800, 1283299200, 1285891200, 1288569600, 
    1291161600 ;
}
