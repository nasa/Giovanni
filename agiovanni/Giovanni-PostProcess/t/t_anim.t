
use Test::More tests => 5;
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
my $var         = 'TRMM_3B42_daily_precipitation_V7';

my $rc = Giovanni::PostProcess::run(
    'bbox'        => '-82.9687,32.9531,-78.0469,38.5781',
    'endtime'     => '2005-01-01T23:59',
    'infile'      => $mfstInput,
    'name'        => 'Time Averaged Map',
    'outfile'     => $mfstOutput,
    'service'     => 'MpAn',
    'session-dir' => $tmpdir,
    'starttime'   => '2005-01-01T00:00',
    'units'       => "mm/day,$unitsConfig",
    'varfiles'    => $mfstDataFieldInfo,
    'variables'   => $var,
    'service'     => 'MpAn',
    'units'       => "mm/hr,$unitsConfig",
    'zfiles'      => $mfstDataFieldSlice
);

is( 0, $rc, "Got return code 0 from run()" );

# Compare Results. Diff the result data and the expected data, then check that a
# spatial average over that data is close to 0. This is allow small differences due
# to rearrangements of floating point arithmetic or data types to pass.
my $mfstRead = Giovanni::Util::getDataFilesFromManifest($mfstOutput);
is( 2, scalar @{ $mfstRead->{data} }, "Got two output files" );

for my $ncOutputGot ( @{ $mfstRead->{data} } ) {
    `ncdiff $ncOutputCorrect $ncOutputGot $tmpdir/diff.nc -O`;
    `ncwa -a lat,lon $tmpdir/diff.nc $tmpdir/aavg.nc -O`;
    my $aavg = `ncks -s "%f" -HC -v $var $tmpdir/aavg.nc | head -1`;
    chomp $aavg;
    ok( abs($aavg) < 1e-10,
        "Output data of $ncOutputGot is close enough to expected data" );
}

sub getMfstInput {
    my ( $fname, $ncInput ) = @_;

    open( MFST, ">$fname" );
    print MFST "<?xml version='1.0' encoding='UTF-8'?>\n";
    print MFST "<manifest>\n";
    print MFST "  <fileList>\n";
    print MFST "    <file>" . abs_path($ncInput) . "</file>\n";
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
netcdf timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N {
dimensions:
    lat = 10 ;
    lon = 10 ;
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
        :start_time = "2002-12-31T22:30:00Z" ;
        :end_time = "2003-01-01T22:29:59Z" ;
        :history = "Fri Mar  6 21:49:39 2015: ncatted -a valid_range,,d,, -O -o timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N.nc timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N.nc\n",
            "Fri Mar  6 21:49:39 2015: ncatted -O -a title,global,o,c,TRMM_3B42_daily_precipitation_V7 Averaged over 2003-01-01 to 2003-01-01 ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc\n",
            "Fri Mar  6 21:49:39 2015: ncks -x -v time -o ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc -O ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc\n",
            "Fri Mar  6 21:49:39 2015: ncwa -o ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc -a time -O ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc\n",
            "Fri Mar  6 21:49:39 2015: ncra -D 2 -H -O -o ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc -d lat,29.077100,31.406300 -d lon,-80.581100,-77.988300" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day over 2002-12-31 22:30Z - 2003-01-01 22:29Z, Region 80.5811W, 29.0771N, 77.9883W, 31.4063N " ;
        :userstartdate = "2003-01-01T00:00:00Z" ;
        :userenddate = "2003-01-01T23:59:59Z" ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  27.25473, 27.12524, 33.99, 141.24, 49.92, 81.27, 50.64, 162.51, 116.73, 
    132.3,
  19.70452, 21.51545, 28.68, 112.17, 140.46, 123, 34.95, 40.41, 99.84, 155.01,
  20.72279, 15.43937, 22.89, 54.39, 126.18, 128.25, 83.06999, 65.22, 111.48, 
    158.34,
  16.50453, 18.0936, 25.44, 28.35, 49.29, 105.24, 136.53, 69.53999, 65.73, 
    100.53,
  44.82, 53.88, 25.5, 21.21, 18.12, 26.16, 122.67, 78.78, 50.52, 109.53,
  38.4, 55.05, 34.53, 22.47, 16.47, 17.88, 55.08, 95.37, 76.56001, 40.95,
  33.48, 50.49, 24.18, 22.23, 16.17, 16.92, 68.55, 144, 69.89999, 25.35,
  41.31, 44.01, 26.76, 18.12, 13.62, 21.57, 52.41, 108.24, 41.58, 30.69,
  11.49, 9.246, 25.17, 23.19, 21.72, 17.67, 19.89, 51.72, 38.93999, 24.78,
  8.604, 9.791999, 30.18, 31.98, 26.19, 28.23, 18.99, 65.49, 59.25, 39.39 ;

 lat = 29.125, 29.375, 29.625, 29.875, 30.125, 30.375, 30.625, 30.875, 
    31.125, 31.375 ;

 lon = -80.375, -80.125, -79.875, -79.625, -79.375, -79.125, -78.875, 
    -78.625, -78.375, -78.125 ;

 time = 1041373800 ;
}
netcdf g4.ncInput {
dimensions:
	lat = 10 ;
	lon = 10 ;
variables:
	double TRMM_3B42_daily_precipitation_V7(lat, lon) ;
		TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.900390625 ;
		TRMM_3B42_daily_precipitation_V7:cell_methods = "time: mean time: mean" ;
		TRMM_3B42_daily_precipitation_V7:coordinates = "lat lon" ;
		TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
		TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
		TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
		TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
		TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
		TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
		TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
		TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
		TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
		TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
		TRMM_3B42_daily_precipitation_V7:units = "mm/hr" ;
		TRMM_3B42_daily_precipitation_V7:plot_hint_legend_label = "TRMM_3B42_daily_precipitation_V7" ;
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
		:start_time = "2002-12-31T22:30:00Z" ;
		:end_time = "2003-01-01T22:29:59Z" ;
		:history = "Fri Mar 13 19:43:34 2015: ncap2 -S /tmp/unitsConversion__oIG.ncap2 /tmp/1ziQPe1weq/ncInput.nc /tmp/1ziQPe1weq/g4.ncInput.nc\n",
			"Fri Mar  6 21:49:39 2015: ncatted -a valid_range,,d,, -O -o timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N.nc timeAvgMap.TRMM_3B42_daily_precipitation_V7.20030101-20030101.80W_29N_77W_31N.nc\n",
			"Fri Mar  6 21:49:39 2015: ncatted -O -a title,global,o,c,TRMM_3B42_daily_precipitation_V7 Averaged over 2003-01-01 to 2003-01-01 ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc\n",
			"Fri Mar  6 21:49:39 2015: ncks -x -v time -o ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc -O ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc\n",
			"Fri Mar  6 21:49:39 2015: ncwa -o ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc -a time -O ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc\n",
			"Fri Mar  6 21:49:39 2015: ncra -D 2 -H -O -o ./timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.81W_29N_78W_31N.nc -d lat,29.077100,31.406300 -d lon,-80.581100,-77.988300" ;
		:NCO = "4.4.4" ;
		:title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/hr over 2002-12-31 22:30Z - 2003-01-01 22:29Z, Region 82.9687W, 32.9531N, 78.0469W, 38.5781N " ;
		:userstartdate = "2003-01-01T00:00:00Z" ;
		:userenddate = "2003-01-01T23:59:59Z" ;
		:plot_hint_title = "Time Averaged Map of Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/hr" ;
		:plot_hint_subtitle = "over 2002-12-31 22:30Z - 2003-01-01 22:29Z, Region 82.9687W, 32.9531N, 78.0469W, 38.5781N " ;
		:plot_hint_caption = "- Selected date range was 2003-01-01 00:00:00Z - 2003-01-01 23:59:00Z. Title reflects the date range of the granules that went into making this result." ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  1.13561375935872, 1.13021834691366, 1.41625006993612, 5.88500022888184, 
    2.07999992370605, 3.38624986012777, 2.10999997456868, 6.77124977111816, 
    4.86375013987223, 5.51250012715658,
  0.821021636327108, 0.896477063496907, 1.19500001271566, 4.67374992370605, 
    5.85250027974447, 5.125, 1.45625003178914, 1.68374999364217, 
    4.15999984741211, 6.45874977111816,
  0.863449573516846, 0.643307089805603, 0.953749974568685, 2.26624997456868, 
    5.25750001271566, 5.34375, 3.4612496693929, 2.71750005086263, 
    4.64500013987223, 6.59749984741211,
  0.687688748041789, 0.753899971644084, 1.0600000222524, 1.18125001589457, 
    2.05375003814697, 4.3849999109904, 5.68874994913737, 2.89749972025553, 
    2.73875013987223, 4.18874994913737,
  1.86749998728434, 2.2450000445048, 1.0625, 0.883749961853027, 
    0.755000034968058, 1.08999999364217, 5.11124992370605, 3.28249994913737, 
    2.10500001907349, 4.56374994913737,
  1.60000006357829, 2.29374996821086, 1.43874994913737, 0.936249971389771, 
    0.686249971389771, 0.744999965031942, 2.29500007629395, 3.97375011444092, 
    3.19000053405762, 1.70625003178914,
  1.39499998092651, 2.10375006993612, 1.00750001271566, 0.926249980926514, 
    0.673750003178914, 0.705000003178914, 2.85625012715658, 6, 
    2.91249942779541, 1.05625001589457,
  1.72125005722046, 1.83374993006388, 1.11500000953674, 0.755000034968058, 
    0.567499995231628, 0.898749987284342, 2.18374999364217, 4.5099999109904, 
    1.73250007629395, 1.2787500222524,
  0.478749990463257, 0.385250012079875, 1.04875000317891, 0.966250022252401, 
    0.904999971389771, 0.736250003178914, 0.828749974568685, 
    2.15500005086263, 1.6224996248881, 1.03250002861023,
  0.358500003814697, 0.407999952634176, 1.25750001271566, 1.33249998092651, 
    1.0912500222524, 1.17624998092651, 0.791249990463257, 2.7287499109904, 
    2.46875, 1.641249974568682 ;

 lat = 29.125, 29.375, 29.625, 29.875, 30.125, 30.375, 30.625, 30.875, 
    31.125, 31.375 ;

 lon = -80.375, -80.125, -79.875, -79.625, -79.375, -79.125, -78.875, 
    -78.625, -78.375, -78.125 ;

 time = 1041373800 ;
}
