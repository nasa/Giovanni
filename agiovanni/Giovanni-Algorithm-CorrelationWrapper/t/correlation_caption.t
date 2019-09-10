#$Id: correlation_caption.t,v 1.1 2014/05/01 20:17:57 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
use Test::More tests => 5;
use File::Temp qw/tempdir/;
use File::Path;
use FindBin;
use Cwd 'abs_path';
use Giovanni::Data::NcFile;
use strict;
use warnings;

BEGIN { use_ok('Giovanni::Algorithm::CorrelationWrapper') }

# Test that we can find the script by its appropriate name
my $script_path = find_script('correlation_wrapper.pl');
ok( ( -f $script_path ), "find $script_path" ) or die;

# Read input CDL
my $ra_cdl  = Giovanni::Data::NcFile::read_cdl_data_block();
my @cdl     = @$ra_cdl;
my $datadir = tempdir( CLEANUP => 0 );

# Call a routine to write out the CDL, then convert to netcdf files
my @ncfiles = write_netcdf( $datadir, @cdl );

my $infile = "$datadir/fileInfo.xml";
open OUT, '>', $infile or die "Could not open $infile: $!\n";
print OUT '<data>',                                                  "\n";
print OUT '  <dataFileList id="TRMM_3B42_daily_precipitation_V6" >', "\n";
map { printf OUT "    <dataFile>%s</dataFile>\n", $_ } @ncfiles[ 0 .. 3 ];
print OUT '  </dataFileList>', "\n";
print OUT
    '  <dataFileList id="TRMM_3B42_daily_precipitation_V7" >',
    "\n";
map { printf OUT "    <dataFile>%s</dataFile>\n", $_ } @ncfiles[ 4 .. 7 ];
print OUT '  </dataFileList>', "\n";
print OUT '</data>',           "\n";
close OUT;

my $dataInfoX = "$datadir/dataInfoX.xml";
open OUT, ">", $dataInfoX or die "Could not open $dataInfoX: $!\n";
print OUT << "XML";
<varList>
  <var id="TRMM_3B42_daily_precipitation_V6" dataProductEndDateTime="2011-06-29T22:29:59Z" long_name="Precipitation Rate" dataFieldUnitsValue="mm/day" fillValueFieldName="" accumulatable="true" accessFormat="netCDF" north="50.0" accessMethod="HTTP_Services_HDF_TO_NetCDF" endTime="2011-06-29T22:29:59Z" dataProductStartTimeOffset="-5400" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Daily%20TRMM%20and%20Others%20Rainfall%20Estimate%20(3B42%20V6%20derived)%20V6;agent_id=HTTP_Services_HDF_TO_NetCDF" startTime="1997-12-31T22:30:00Z" responseFormat="netCDF" dataProductEndTimeOffset="-5401" south="-50.0" dataProductTimeInterval="daily" west="-180.0" dataProductVersion="6" east="180.0" sdsName="precipitation" dataProductShortName="TRMM_3B42_daily" dataProductPlatformInstrument="TRMM" resolution="0.25 deg." quantity_type="Precipitation" deflationLevel="1" dataProductBeginDateTime="1997-12-31T22:30:00Z" dataFieldStandardName="">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue, Sequential, 9-Steps"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/trmm_precipitation_sld.xml" label="TRMM Rainfall Color Map"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/trmm_precipitation_panoply_diff_sld.xml" label="TRMM Precipitation Rainbow Color Map"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/rainfall_sld.xml" label="Rainfall"/>
    </slds>
  </var>
</varList>
XML
close OUT;

my $dataInfoY = "$datadir/dataInfoY.xml";
open OUT, ">", $dataInfoY or die "Could not open $dataInfoY: $!\n";
print OUT << "XML";
<varList>
  <var id="TRMM_3B42_daily_precipitation_V7" dataProductEndDateTime="2013-11-30T22:29:59Z" long_name="Precipitation Rate" dataFieldUnitsValue="mm/day" fillValueFieldName="" accumulatable="true" accessFormat="netCDF" north="50.0" accessMethod="HTTP_Services_HDF_TO_NetCDF" endTime="2013-11-30T22:29:59Z" dataProductStartTimeOffset="-5400" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Daily%20TRMM%20and%20Others%20Rainfall%20Estimate%20(3B42%20V7%20derived)%20V7;agent_id=HTTP_Services_HDF_TO_NetCDF" startTime="1997-12-31T00:00:00Z" responseFormat="netCDF" dataProductEndTimeOffset="-5401" south="-50.0" dataProductTimeInterval="daily" west="-180.0" dataProductVersion="7" east="180.0" sdsName="precipitation" dataProductShortName="TRMM_3B42_daily" dataProductPlatformInstrument="TRMM" resolution="0.25 deg." quantity_type="Precipitation" dataProductBeginDateTime="1997-12-31T00:00:00Z" dataFieldStandardName="">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_gnbu_9_sld.xml" label="Green-Blue, Sequential, 9-Steps"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/trmm_precipitation_sld.xml" label="TRMM Rainfall Color Map"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/trmm_precipitation_panoply_diff_sld.xml" label="TRMM Precipitation Rainbow Color Map"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/rainfall_sld.xml" label="Rainfall"/>
    </slds>
  </var>
</varList>
XML
close OUT;

my $start = "2003-01-01";
my $end   = "2003-01-04";

# Use a smaller bounding box than available to check the bbox arg
my $bbox    = '-81.8262,37.2349,-78.7939,40.8823';
my $outfile = "$datadir/out_correlation_wrapper.nc";
my $cmd
    = "$script_path -v 2 -O $outfile -f $infile -b $bbox -s $start -e $end -d $dataInfoX,$dataInfoY";

$cmd .= " -x TRMM_3B42_daily_precipitation_V6";
$cmd .= " -y TRMM_3B42_daily_precipitation_V7";
my $rc = system($cmd);
is( $rc, 0, "Execute $cmd" ) or die;

ok( ( -f $outfile ), "Output file exists" ) or die;

my @lines = `ncdump -h -x $outfile  `
    or die "Failed to get header from $outfile with ncdump\n";

# parse the XML and grab the root node.
my $parser = XML::LibXML->new();
my $dom    = $parser->parse_string( join( "", @lines ) );
my $xpc    = XML::LibXML::XPathContext->new($dom);
$xpc->registerNs(
    nc => 'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );

my $xpath   = qq(nc:netcdf/nc:attribute[\@name="plot_hint_caption"]/\@value);
my $caption = $xpc->findvalue($xpath);
my $correctCaptionText
    = "The data date range for the first variable, Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v6] mm/day, is 2002-12-31 22:30Z - 2003-01-04 22:29Z. The data date range for the second variable, Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm/day, is 2002-12-31 22:30Z - 2003-01-04 22:29Z.";
is( $caption, $correctCaptionText, "Caption correct" );

# Cleanup
unless ( $ENV{SAVE_TEST_FILES} ) {
    rmtree($datadir);
}
exit(0);

#=====================================================

sub find_script {
    my ($scriptName) = @_;

    # see if this is just next door (Christine's eclipse configuration)
    my $script = "../scripts/$scriptName";

    unless ( -f $script ) {

        # see if we can find the script relative to our current location
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }

    return abs_path($script);
}

sub write_netcdf {
    my ( $dir, @cdls ) = @_;

    my @ncpaths = ();
    for my $cdl (@cdls) {

        # Convert CDL file to netCDF
        my ($ncpath) = ( $cdl =~ /^netcdf\s+(.*?)\s+\{/ );
        $ncpath = "$dir/$ncpath" . ".nc";

        if ( !Giovanni::Data::NcFile::write_netcdf_file( $ncpath, $cdl ) ) {
            die "Unable to write nc file: $ncpath";
        }
        push( @ncpaths, $ncpath );
    }

    return @ncpaths;
}

__DATA__
netcdf subsetted.TRMM_3B42_daily_precipitation_V6.20030101.81W_37N_78W_40N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 15 ;
    lon = 12 ;
variables:
    float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
        TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
        TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V6:units = "mm" ;
        TRMM_3B42_daily_precipitation_V6:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V6:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V6:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2002-12-31T22:30:00Z" ;
        :end_time = "2003-01-01T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :title = "TRMM_3B42_daily_precipitation_V6 (81.8262W_37.2349N_78.7939W_40.8823N)" ;
        :plot_hint_title = "Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v6] mm for 2002-12-31 22:30Z - 2003-01-01 22:29Z" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-04. Title reflects the date range of the granules that went into making this result.\n",
            "" ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  19.66184, 28.73023, 31.70684, 34.33709, 29.91427, 24.17994, 19.86, 13.56, 
    21.66, 27.69487, 23.94, 22.92,
  19.13144, 26.33183, 27.05622, 37.01238, 24.11595, 17.75183, 24.36, 25.74, 
    24.3, 24.6, 23.34, 23.1,
  21.96, 24.46274, 30.17833, 20.70104, 17.38733, 21.41801, 23.88, 24.78, 
    18.66, 17.7, 27.42, 30.9,
  35.57401, 32.02055, 22.62, 11.46375, 18.24, 16.39712, 19.86, 21.54, 22.02, 
    20.1, 25.68, 33.24,
  32.7078, 26.10511, 18.12, 18.9, 17.62793, 18.12, 29.22, 20.1, 24.54, 35.28, 
    41.01398, 48.0977,
  33.37934, 32.14343, 35.7, 41.6437, 41.93477, 37.14189, 41.5911, 37.14, 
    43.26, 35.7, 70.8869, 62.55231,
  45.16803, 43.83416, 44.40218, 47.41395, 50.5803, 37.65466, 35.33077, 46.14, 
    36.42, 34.26, 54.45878, 42.9,
  31.15498, 43.29633, 46.4374, 46.65045, 42.43903, 44.94168, 39.9, 38.52, 
    29.04, 29.088, 27.01699, 27.12,
  35.0832, 44.07508, 49.92509, 47.82275, 41.7919, 47.56553, 44.33007, 39.66, 
    29.52, 28.56, 33.78, 29.34,
  33.46582, 32.1, 42.807, 45.50755, 45.36135, 42.74392, 42.12376, 45.25866, 
    54.15172, 45.3, 27.18, 22.62,
  23.61371, 19.8, 26.7, 38.7, 30.3, 29.52, 39.84, 44.34, 50.22589, 58.14, 
    51.9, 29.9611,
  12.46528, 12.6, 22.68, 21.9, 21.9, 19.86, 22.98, 25.38, 37.02, 40.32, 
    36.2986, 33.29947,
  28.95577, 25.51385, 26.64, 25.68, 23.1, 23.52, 22.44, 31.32, 27.72, 31.26, 
    26.82, 27.54,
  37.12036, 38.65405, 31.50932, 35.3741, 29.28, 28.44, 27.3, 52.14, 51.72, 
    40.32, 32.76, 33.72,
  35.18536, 39.43334, 38.60522, 42.42, 28.56, 29.94, 47.76, 51.74353, 
    50.0193, 42.5497, 39.39637, 39.99218 ;

 dataday = 2003001 ;

 lat = 37.375, 37.625, 37.875, 38.125, 38.375, 38.625, 38.875, 39.125, 
    39.375, 39.625, 39.875, 40.125, 40.375, 40.625, 40.875 ;

 lon = -81.625, -81.375, -81.125, -80.875, -80.625, -80.375, -80.125, 
    -79.875, -79.625, -79.375, -79.125, -78.875 ;

 time = 1041373800 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V6.20030102.81W_37N_78W_40N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 15 ;
    lon = 12 ;
variables:
    float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
        TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
        TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V6:units = "mm" ;
        TRMM_3B42_daily_precipitation_V6:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V6:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V6:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2003-01-01T22:30:00Z" ;
        :end_time = "2003-01-02T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :title = "TRMM_3B42_daily_precipitation_V6 (81.8262W_37.2349N_78.7939W_40.8823N)" ;
        :plot_hint_title = "Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v6] mm for 2003-01-01 22:30Z - 2003-01-02 22:29Z" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-04. Title reflects the date range of the granules that went into making this result.\n",
            "" ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 9.059999, 0, 2.82,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3.18,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.12114,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 8.16, 2.52, 6.42,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 7.32, 2.88, 6.18,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3.046937, 6.896914 ;

 dataday = 2003002 ;

 lat = 37.375, 37.625, 37.875, 38.125, 38.375, 38.625, 38.875, 39.125, 
    39.375, 39.625, 39.875, 40.125, 40.375, 40.625, 40.875 ;

 lon = -81.625, -81.375, -81.125, -80.875, -80.625, -80.375, -80.125, 
    -79.875, -79.625, -79.375, -79.125, -78.875 ;

 time = 1041460200 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V6.20030103.81W_37N_78W_40N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 15 ;
    lon = 12 ;
variables:
    float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
        TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
        TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V6:units = "mm" ;
        TRMM_3B42_daily_precipitation_V6:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V6:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V6:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2003-01-02T22:30:00Z" ;
        :end_time = "2003-01-03T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :title = "TRMM_3B42_daily_precipitation_V6 (81.8262W_37.2349N_78.7939W_40.8823N)" ;
        :plot_hint_title = "Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v6] mm for 2003-01-02 22:30Z - 2003-01-03 22:29Z" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-04. Title reflects the date range of the granules that went into making this result.\n",
            "" ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  8.942586, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  10.87327, 4.487417, 0, 0, 5.530218, 0, 0, 0, 0, 0, 0, 0,
  7.68, 6.806167, 0, 0, 0.8571219, 0, 0, 0, 0, 0, 0, 0,
  0, 2.415586, 5.1, 0, 0, 6.704031, 0, 0, 0, 0, 0, 0,
  0, 8.49271, 12.12, 2.88, 1.767994, 2.04, 7.56, 0, 0, 0, 0, 0,
  0, 0, 0, 6.495267, 2.491174, 5.007277, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 6.503075, 3.681356, 9.643265, 14.41771, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 5.152343, 8.548418, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 5.650078, 6.411528, 5.27739, 12.54, 12.9, 7.5, 2.76, 0,
  0, 0, 0, 0, 1.882013, 5.003324, 8.342957, 13.95868, 9.200535, 6.72, 3.24, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3.72, 2.607234,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 5.16, 11.11902, 8.031736,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 3.12, 3.06, 2.52,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 5.04, 3.72, 2.52,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 2.630133, 3.314213, 5.408371 ;

 dataday = 2003003 ;

 lat = 37.375, 37.625, 37.875, 38.125, 38.375, 38.625, 38.875, 39.125, 
    39.375, 39.625, 39.875, 40.125, 40.375, 40.625, 40.875 ;

 lon = -81.625, -81.375, -81.125, -80.875, -80.625, -80.375, -80.125, 
    -79.875, -79.625, -79.375, -79.125, -78.875 ;

 time = 1041546600 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V6.20030104.81W_37N_78W_40N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 15 ;
    lon = 12 ;
variables:
    float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
        TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
        TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V6:units = "mm" ;
        TRMM_3B42_daily_precipitation_V6:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V6:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V6:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2003-01-03T22:30:00Z" ;
        :end_time = "2003-01-04T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :title = "TRMM_3B42_daily_precipitation_V6 (81.8262W_37.2349N_78.7939W_40.8823N)" ;
        :plot_hint_title = "Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v6] mm for 2003-01-03 22:30Z - 2003-01-04 22:29Z" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-04. Title reflects the date range of the granules that went into making this result.\n",
            "" ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ;

 dataday = 2003004 ;

 lat = 37.375, 37.625, 37.875, 38.125, 38.375, 38.625, 38.875, 39.125, 
    39.375, 39.625, 39.875, 40.125, 40.375, 40.625, 40.875 ;

 lon = -81.625, -81.375, -81.125, -80.875, -80.625, -80.375, -80.125, 
    -79.875, -79.625, -79.375, -79.125, -78.875 ;

 time = 1041633000 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V7.20030101.81W_37N_78W_40N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 15 ;
    lon = 12 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2002-12-31T22:30:00Z" ;
        :end_time = "2003-01-01T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :title = "TRMM_3B42_daily_precipitation_V7 (81.8262W_37.2349N_78.7939W_40.8823N)" ;
        :plot_hint_title = "Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm for 2002-12-31 22:30Z - 2003-01-01 22:29Z" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-04. Title reflects the date range of the granules that went into making this result.\n",
            "" ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  26.91, 32.49, 37.53, 34.38, 33.87348, 5.49, 5.94, 9.27, 36.55537, 29.25, 
    26.19, 12.87,
  16.47, 34.59489, 5.85, 25.02, 33.42615, 29.35648, 28.62008, 9.809999, 
    43.3228, 25.29, 20.25, 14.94,
  24.48, 25.99504, 35.33067, 21.6, 18.81, 13.32, 31.23, 23.58, 8.01, 
    9.629999, 16.11, 31.81624,
  41.82759, 35.52677, 39.56973, 16.47, 24.3, 22.14, 9.27, 46.6774, 35.2525, 
    8.82, 11.7, 31.14,
  38.32555, 26.90498, 36.25989, 28.26, 30.24, 36.45, 21.51, 10.8, 10.26, 
    26.37, 38.97594, 45.54304,
  28.29359, 34.43437, 36.86077, 47.79, 21.6, 60.66, 36.99, 17.19, 44.46, 
    56.11354, 57.80021, 23.31,
  35.50047, 41.34281, 49.64733, 69.99776, 42.39, 32.31, 57.30666, 27, 
    51.84091, 50.7896, 49.41, 30.33,
  44.88203, 46.87199, 45.98018, 58.09324, 47.43, 54.81, 37.89, 11.16, 15.39, 
    8.82, 12.51, 9.36,
  43.92237, 50.67144, 53.73107, 58.14089, 57.00337, 63.88735, 63.21618, 54, 
    27.72, 11.07, 23.76, 33.21,
  32.6067, 35.93832, 45.23671, 51.04076, 47.07055, 38.88589, 47.51512, 
    56.36236, 48.06, 28.08, 24.39, 29.61,
  12.39013, 20.17097, 23.58108, 38.97, 50.48202, 33.47501, 49.16439, 
    54.60852, 53.54981, 48.69, 50.4, 41.22,
  8.53914, 12.74212, 18.54, 7.92, 21.33, 19.62, 25.38, 45.72, 32.67, 32.76, 
    52.56, 62.28,
  21.92238, 22.17461, 28.63221, 11.25, 11.34, 19.71, 16.47, 19.53, 21.6, 
    25.47, 23.58, 19.26,
  26.10303, 30.37092, 26.01, 24.48, 17.91, 11.43, 25.29, 44.27999, 45.36, 
    40.86, 37.35, 36.09,
  10.98, 11.97, 14.4, 14.13, 8.639999, 9.45, 16.02, 25.92, 26.19, 27.63, 
    31.59, 42.51488 ;

 dataday = 2003001 ;

 lat = 37.375, 37.625, 37.875, 38.125, 38.375, 38.625, 38.875, 39.125, 
    39.375, 39.625, 39.875, 40.125, 40.375, 40.625, 40.875 ;

 lon = -81.625, -81.375, -81.125, -80.875, -80.625, -80.375, -80.125, 
    -79.875, -79.625, -79.375, -79.125, -78.875 ;

 time = 1041373800 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V7.20030102.81W_37N_78W_40N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 15 ;
    lon = 12 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2003-01-01T22:30:00Z" ;
        :end_time = "2003-01-02T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :title = "TRMM_3B42_daily_precipitation_V7 (81.8262W_37.2349N_78.7939W_40.8823N)" ;
        :plot_hint_title = "Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm for 2003-01-01 22:30Z - 2003-01-02 22:29Z" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-04. Title reflects the date range of the granules that went into making this result.\n",
            "" ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11.45058,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 6.389999, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 11.43, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12.42,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11.07,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 8.549999, 13.05, 11.7,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 9.629999, 14.58, 10.26,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10.17, 12.69,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 3.06, 10.62, 19.23087 ;

 dataday = 2003002 ;

 lat = 37.375, 37.625, 37.875, 38.125, 38.375, 38.625, 38.875, 39.125, 
    39.375, 39.625, 39.875, 40.125, 40.375, 40.625, 40.875 ;

 lon = -81.625, -81.375, -81.125, -80.875, -80.625, -80.375, -80.125, 
    -79.875, -79.625, -79.375, -79.125, -78.875 ;

 time = 1041460200 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V7.20030103.81W_37N_78W_40N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 15 ;
    lon = 12 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2003-01-02T22:30:00Z" ;
        :end_time = "2003-01-03T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :title = "TRMM_3B42_daily_precipitation_V7 (81.8262W_37.2349N_78.7939W_40.8823N)" ;
        :plot_hint_title = "Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm for 2003-01-02 22:30Z - 2003-01-03 22:29Z" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-04. Title reflects the date range of the granules that went into making this result.\n",
            "" ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  4.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  25.11, 0, 0, 0, 9.528016, 0, 0, 0, 0, 0, 0, 0,
  12.33, 21.69242, 0, 0, 2.61, 0, 0, 0, 0, 0, 0, 0,
  3.843134, 12.12319, 3.016205, 0.72, 2.16, 2.16, 1.26, 0, 0, 0, 0, 0,
  3.251865, 10.04253, 10.44523, 4.14, 4.23, 4.23, 2.16, 1.62, 0, 0, 0, 0,
  4.115431, 7.737279, 7.086111, 0, 2.16, 4.23, 9.719999, 4.5, 0.63, 0, 0, 0,
  7.100092, 2.687922, 0, 0, 2.16, 12.78, 10.7956, 0.63, 0, 5.275085, 0, 0,
  0, 0, 0, 0, 11.25, 14.67, 6.389999, 1.89, 4.41, 3.24, 4.139999, 2.97,
  0, 0, 0, 0, 8.405033, 10.15896, 7.189635, 17.01, 19.53, 21.06, 13.41, 2.88,
  0, 0, 0, 3.210111, 14.92986, 25.54044, 13.36796, 12.72067, 18.81, 8.190001, 
    3.96, 0,
  0, 0, 0, 0.9899999, 4.826651, 26.95478, 20.20157, 9.784027, 14.54439, 
    9.629999, 7.199999, 3.33,
  0, 0, 0, 0, 0, 3.33, 8.639999, 8.73, 0, 7.74, 8.91, 6.39,
  0, 0, 0, 0, 0, 3.24, 3.42, 0, 0, 5.85, 7.47, 5.31,
  0, 0, 0, 0, 0, 3.24, 3.33, 0, 5.49, 7.2, 9.9, 7.2,
  0, 0, 0, 0, 0, 0, 4.32, 4.59, 6.48, 8.819999, 8.19, 4.915513 ;

 dataday = 2003003 ;

 lat = 37.375, 37.625, 37.875, 38.125, 38.375, 38.625, 38.875, 39.125, 
    39.375, 39.625, 39.875, 40.125, 40.375, 40.625, 40.875 ;

 lon = -81.625, -81.375, -81.125, -80.875, -80.625, -80.375, -80.125, 
    -79.875, -79.625, -79.375, -79.125, -78.875 ;

 time = 1041546600 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V7.20030104.81W_37N_78W_40N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 15 ;
    lon = 12 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2003-01-03T22:30:00Z" ;
        :end_time = "2003-01-04T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
        :title = "TRMM_3B42_daily_precipitation_V7 (81.8262W_37.2349N_78.7939W_40.8823N)" ;
        :plot_hint_title = "Precipitation Rate daily 0.25 deg. [TRMM TRMM_3B42_daily v7] mm for 2003-01-03 22:30Z - 2003-01-04 22:29Z" ;
        :plot_hint_caption = "- Selected date range was 2003-01-01 - 2003-01-04. Title reflects the date range of the granules that went into making this result.\n",
            "" ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ;

 dataday = 2003004 ;

 lat = 37.375, 37.625, 37.875, 38.125, 38.375, 38.625, 38.875, 39.125, 
    39.375, 39.625, 39.875, 40.125, 40.375, 40.625, 40.875 ;

 lon = -81.625, -81.375, -81.125, -80.875, -80.625, -80.375, -80.125, 
    -79.875, -79.625, -79.375, -79.125, -78.875 ;

 time = 1041633000 ;
}
