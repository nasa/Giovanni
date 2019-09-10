#$Id: correlation_wrapper.t,v 1.15 2014/05/01 20:17:57 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 4;
use File::Temp qw/tempdir/;
use File::Path;
use FindBin;

BEGIN { use_ok('Giovanni::Algorithm::CorrelationWrapper') }

# Test that we can find the script by its appropriate name
my $script      = 'correlation_wrapper.pl';
my $script_path = "blib/script/$script";
foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
    next if ( $dir =~ /^\s*$/ );
    last if ( -f $script_path );
    $script_path = "../$script_path";
}
ok( ( -f $script_path ), "find $script" );

# Read input CDL
my $ra_cdl  = read_cdl_data();
my @cdl     = @$ra_cdl;
my $datadir = tempdir( CLEANUP => 0 );

# Call a routine to write out the CDL, then convert to netcdf files
my @ncfiles = map { write_netcdf( $datadir, $_ ) } @cdl;

my $infile = "$datadir/fileInfo.xml";
open OUT, '>', $infile or die "Could not open $infile: $!\n";
print OUT '<data>', "\n";
print OUT
    '  <dataFileList id="MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean" >',
    "\n";
map { printf OUT "    <dataFile>%s</dataFile>\n", $_ } @ncfiles[ 0 .. 3 ];
print OUT '  </dataFileList>', "\n";
print OUT
    '  <dataFileList id="MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean" >',
    "\n";
map { printf OUT "    <dataFile>%s</dataFile>\n", $_ } @ncfiles[ 4 .. 7 ];
print OUT '  </dataFileList>', "\n";
print OUT '</data>',           "\n";
close OUT;

my $dataInfoX = "$datadir/dataInfoX.xml";
open OUT, ">", $dataInfoX or die "Could not open $dataInfoX: $!\n";
print OUT << "XML";
<varList>
  <var id="MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean" dataProductEndDateTime="2038-01-19T03:14:07Z" long_name="Aerosol Optical Depth 550 nm (Dark Target)" dataFieldUnitsValue="1" fillValueFieldName="_FillValue" accumulatable="false" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" dataProductStartTimeOffset="1" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MODIS%2FTerra%20Aerosol%20Cloud%20Water%20Vapor%20Ozone%20Daily%20L3%20Global%201Deg%20CMG%20V051;agent_id=OPeNDAP;variables=Optical_Depth_Land_And_Ocean_Mean" startTime="2000-03-01T00:00:00Z" responseFormat="netCDF" dataProductEndTimeOffset="0" south="-90.0" dataProductTimeInterval="daily" west="-180.0" dataProductVersion="051" east="180.0" sdsName="Optical_Depth_Land_And_Ocean_Mean" dataProductShortName="MOD08_D3" dataProductPlatformInstrument="MODIS-Terra" resolution="1 deg." quantity_type="Total Aerosol Optical Depth" dataProductBeginDateTime="2000-03-01T00:00:00Z" dataFieldStandardName="">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/aod_sld.xml" label="Aerosol Optical Depth Color Map"/>
    </slds>
  </var>
</varList>
XML
close OUT;

my $dataInfoY = "$datadir/dataInfoY.xml";
open OUT, ">", $dataInfoY or die "Could not open $dataInfoY: $!\n";
print OUT << "XML";
<varList>
  <var id="MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean" dataProductEndDateTime="2038-01-19T03:14:07Z" long_name="Aerosol Optical Depth 550 nm (Dark Target)" dataFieldUnitsValue="1" fillValueFieldName="_FillValue" accumulatable="false" accessFormat="netCDF" north="90.0" accessMethod="OPeNDAP" endTime="2038-01-19T03:14:07Z" dataProductStartTimeOffset="1" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MODIS%2FAqua%20Aerosol%20Cloud%20Water%20Vapor%20Ozone%20Daily%20L3%20Global%201Deg%20CMG%20V051;agent_id=OPeNDAP;variables=Optical_Depth_Land_And_Ocean_Mean" startTime="2002-07-04T00:00:00Z" responseFormat="netCDF" dataProductEndTimeOffset="0" south="-90.0" dataProductTimeInterval="daily" west="-180.0" dataProductVersion="051" east="180.0" sdsName="Optical_Depth_Land_And_Ocean_Mean" dataProductShortName="MYD08_D3" dataProductPlatformInstrument="MODIS-Aqua" resolution="1 deg." quantity_type="Total Aerosol Optical Depth" dataProductBeginDateTime="2002-07-04T00:00:00Z" dataFieldStandardName="">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/aod_sld.xml" label="Aerosol Optical Depth Color Map"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/aod_panoply_diff_sld.xml" label="Aerosol Optical Depth Rainbow Color Map"/>
    </slds>
  </var>
</varList>
XML
close OUT;

my $start = "2003-01-01";
my $end   = "2003-01-04";

# Use a smaller bounding box than available to check the bbox arg
my $bbox    = '-60,25,-58,26';
my $outfile = "$datadir/out_correlation_wrapper.nc";
my $cmd
    = "$script_path -v 2 -O $outfile -f $infile -b $bbox -s $start -e $end -d $dataInfoX,$dataInfoY";

$cmd .= " -x MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean";
$cmd .= " -y MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean";
my $rc = system($cmd);
is( $rc, 0, "Execute $cmd" );

unlink ($outfile);

$cmd = "$script_path -v 2 -O $outfile -f $infile -b '' -s $start -e $end -d $dataInfoX,$dataInfoY";
$cmd .= " -x MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean";
$cmd .= " -y MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean";

$rc = system($cmd);

is($rc, 0, "(No bbox) Execute $cmd");

# Cleanup
unless ( $ENV{SAVE_TEST_FILES} ) {
    rmtree($datadir);
}
exit(0);

#=====================================================

sub read_cdl_data {

    # read block at __DATA__ and write to a CDL file
    local ($/) = undef;
    my $cdldata = <DATA>;
    my @cdl = ( $cdldata =~ m/(netcdf .*?\}\n)/gs );
    return \@cdl;
}

sub read_output {
    local ($/) = undef;
    my $got = `ncdump $_[0]`;
    $got =~ s/\n\s+?:history.*?;//sg;
    return $got;
}

sub write_netcdf {
    my ( $dir, $cdl ) = @_;

    # write to CDL file
    my ($cdl_file) = ( $cdl =~ /^netcdf\s+(.*?)\s+\{/ );
    $cdl_file .= '.cdl';
    my $cdlpath = "$dir/$cdl_file";
    open( CDLFILE, ">", $cdlpath ) or die "Cannot open $cdlpath: $!";
    print CDLFILE $cdl;
    close CDLFILE;

    # Convert CDL file to netCDF
    my $ncpath = $cdlpath;
    $ncpath =~ s/\.cdl/\.nc/;
    my $cmd = "ncgen -o $ncpath $cdlpath";
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );
    unlink $cdlpath;
    return $ncpath;
}

__DATA__
netcdf subsetted.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101.60W_25N_58W_26N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 2 ;
variables:
    float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-01T00:00:00Z" ;
        :end_time = "2003-01-01T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.132, 0.121 ;

 dataday = 2003001 ;

 lat = 25.5 ;

 lon = -59.5, -58.5 ;

 time = 1041379200 ;
}
netcdf subsetted.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030102.60W_25N_58W_26N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 2 ;
variables:
    float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-02T00:00:00Z" ;
        :end_time = "2003-01-02T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.098, 0.085 ;

 dataday = 2003002 ;

 lat = 25.5 ;

 lon = -59.5, -58.5 ;

 time = 1041465600 ;
}
netcdf subsetted.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030103.60W_25N_58W_26N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 2 ;
variables:
    float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-03T00:00:00Z" ;
        :end_time = "2003-01-03T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.04, 0.051 ;

 dataday = 2003003 ;

 lat = 25.5 ;

 lon = -59.5, -58.5 ;

 time = 1041552000 ;
}
netcdf subsetted.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030104.60W_25N_58W_26N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 2 ;
variables:
    float MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
        MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    float lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-04T00:00:00Z" ;
        :end_time = "2003-01-04T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.127, 0.102 ;

 dataday = 2003004 ;

 lat = 25.5 ;

 lon = -59.5, -58.5 ;

 time = 1041638400 ;
}
netcdf subsetted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101.60W_25N_58W_26N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 2 ;
variables:
    float MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Aqua, 1 x 1 deg." ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MYD08_D3" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-01T00:00:00Z" ;
        :end_time = "2003-01-01T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.064, 0.072 ;

 dataday = 2003001 ;

 lat = 25.5 ;

 lon = -59.5, -58.5 ;

 time = 1041379200 ;
}
netcdf subsetted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030102.60W_25N_58W_26N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 2 ;
variables:
    float MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Aqua, 1 x 1 deg." ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MYD08_D3" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-02T00:00:00Z" ;
        :end_time = "2003-01-02T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.106, 0.124 ;

 dataday = 2003002 ;

 lat = 25.5 ;

 lon = -59.5, -58.5 ;

 time = 1041465600 ;
}
netcdf subsetted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030103.60W_25N_58W_26N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 2 ;
variables:
    float MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Aqua, 1 x 1 deg." ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MYD08_D3" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-03T00:00:00Z" ;
        :end_time = "2003-01-03T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.025, 0.024 ;

 dataday = 2003003 ;

 lat = 25.5 ;

 lon = -59.5, -58.5 ;

 time = 1041552000 ;
}
netcdf subsetted.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030104.60W_25N_58W_26N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 2 ;
variables:
    float MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lat, lon) ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Aqua, 1 x 1 deg." ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_scale_factor = 0.001 ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:orig_add_offset = 0. ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999.f ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MYD08_D3" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
        MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :start_time = "2003-01-04T00:00:00Z" ;
        :end_time = "2003-01-04T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.112, 0.086 ;

 dataday = 2003004 ;

 lat = 25.5 ;

 lon = -59.5, -58.5 ;

 time = 1041638400 ;
}
