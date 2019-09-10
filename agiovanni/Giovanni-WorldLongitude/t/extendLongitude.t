#$Id: extendLongitude.t,v 1.1 2014/02/07 21:17:01 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 SYNOPIS
This tests the grid normalizer.
=cut

use strict;
use File::Temp qw/ tempfile tempdir /;
use Test::More tests => 5;
use Cwd 'abs_path';
use Giovanni::Data::NcFile;
use FindBin qw($Bin);

my $script = findScript("extendLongitude.pl");
ok( -r $script, "Found script" );

# create a temporary directory for everything
my $dir = abs_path( tempdir( DIR => ".", CLEANUP => 1 ) );

# write the netcdf there
my $cdl = readCdlData();
my $inNcFile
    = "$dir/timeAvg.NLDAS_FORA0125_H_002_tmp2m.20030101-20030101.68W_40N_123W_44N.nc";
Giovanni::Data::NcFile::write_netcdf_file( $inNcFile, $cdl ) or die $?;

# create the input manifest file
my $inManifest = "$dir/mfst.in+whatever.xml";
my $xml        = <<QUOTE;
<manifest >
  <fileList id="TRMM_3B43_007_precipitation">
    <file>$inNcFile</file>
  </fileList>
</manifest>
QUOTE
open( FILE, ">", $inManifest );
print FILE $xml;
close(FILE);

my $outManifest = "$dir/mfst.out+whatever.xml";
my $outNcFile
    = "$dir/timeAvgWorldLon.NLDAS_FORA0125_H_002_tmp2m.20030101-20030101.68W_40N_123W_44N.nc";

my $cmd = "$script --in-file $inManifest --out-file $outManifest";

my $ret = system($cmd);

ok( $ret == 0, "Command returned 0:$cmd" ) or die;

ok( -f $outManifest, "Output manifest file exists" ) or die;

# parse the output manifest file
my $parser   = XML::LibXML->new();
my $dom      = $parser->parse_file($outManifest);
my $xpDom    = XML::LibXML::XPathContext->new($dom);
my @outFiles = map( $_->nodeValue, $xpDom->findnodes("//file/text()") );

is_deeply( \@outFiles, [$outNcFile], "Correct output data file" ) or die;
ok( -f $outNcFile, "Output data file exists" ) or die;

sub findScript {
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

    return $script;
}

sub readCdlData {

    # read block at __DATA__ and write to a CDL file
    #(stolen from Chris...)
    my @cdldata;
    while (<DATA>) {
        push @cdldata, $_;
    }
    return ( join( '', @cdldata ) );
}

__DATA__
netcdf timeAvg.NLDAS_FORA0125_H_002_tmp2m.20030101-20030101.68W_40N_123W_44N {
dimensions:
    lat = 32 ;
    lon = 24 ;
variables:
    float NLDAS_FORA0125_H_002_tmp2m(lat, lon) ;
        NLDAS_FORA0125_H_002_tmp2m:units = "K" ;
        NLDAS_FORA0125_H_002_tmp2m:long_name = "Temperature (2-m above ground), NLDAS-2 Primary Forcing, 0.125 x 0.125 deg." ;
        NLDAS_FORA0125_H_002_tmp2m:_FillValue = -9999.f ;
        NLDAS_FORA0125_H_002_tmp2m:GRIB_param_name = "N2-m_above_ground_Temperature" ;
        NLDAS_FORA0125_H_002_tmp2m:GRIB_param_short_name = "TMP2m" ;
        NLDAS_FORA0125_H_002_tmp2m:GRIB_center_id = 7 ;
        NLDAS_FORA0125_H_002_tmp2m:GRIB_table_id = 130 ;
        NLDAS_FORA0125_H_002_tmp2m:GRIB_param_number = 11 ;
        NLDAS_FORA0125_H_002_tmp2m:GRIB_param_id = 1, 7, 130, 11 ;
        NLDAS_FORA0125_H_002_tmp2m:GRIB_product_definition_type = "Initialized analysis product" ;
        NLDAS_FORA0125_H_002_tmp2m:GRIB_level_type = 105 ;
        NLDAS_FORA0125_H_002_tmp2m:GRIB_VectorComponentFlag = "easterlyNortherlyRelative" ;
        NLDAS_FORA0125_H_002_tmp2m:standard_name = "n2-m_above_ground_temperature" ;
        NLDAS_FORA0125_H_002_tmp2m:quantity_type = "Air Temperature" ;
        NLDAS_FORA0125_H_002_tmp2m:product_short_name = "NLDAS_FORA0125_H" ;
        NLDAS_FORA0125_H_002_tmp2m:product_version = "002" ;
        NLDAS_FORA0125_H_002_tmp2m:latitude_resolution = 0.125 ;
        NLDAS_FORA0125_H_002_tmp2m:longitude_resolution = 0.125 ;
    double lat(lat) ;
        lat:_CoordinateAxisType = "Lat" ;
        lat:grid_spacing = "0.125 degrees_north" ;
        lat:long_name = "Latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:_CoordinateAxisType = "Lon" ;
        lon:grid_spacing = "0.125 degrees_east" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2003-01-01T20:00:00Z" ;
        :end_time = "2003-01-01T23:59:59Z" ;
        :nco_openmp_thread_number = 1 ;
        :title = "NLDAS_FORA0125_H_002_tmp2m Averaged over 2003-01-01 to 2003-01-01" ;
data:

 NLDAS_FORA0125_H_002_tmp2m =
  _, _, _, _, _, _, _, _, _, _, _, _, _, 284.2425, 282.2625, 281.3425, 
    281.8125, 282.29, 280.565, 281.465, 279.435, 279.375, 276.575, 274.5275,
  _, _, _, _, _, _, _, _, _, _, _, _, 284.2175, 282.015, 281.3, 281.49, 
    281.3175, 282.1975, 281.105, 280.7675, 278.2925, 278.5625, 277.145, 
    275.6375,
  _, _, _, _, _, _, _, _, _, _, _, _, 284.1975, 282.6475, 281.51, 280.2875, 
    281.485, 281.645, 281.2375, 276.975, 277.505, 276.8525, 276.4725, 275.895,
  _, _, _, _, _, _, _, _, _, _, _, _, 283.36, 281.865, 281.1175, 281.545, 
    282.3875, 281.175, 279.1425, 278.16, 277.8175, 276.59, 276.985, 276.59,
  _, _, _, _, _, _, _, _, _, _, _, _, 283.88, 283.305, 283.7075, 282.8225, 
    281.39, 279.9925, 278.755, 277.16, 278.75, 277.0875, 278.0175, 277.005,
  _, _, _, _, _, _, _, _, _, _, _, _, _, 284.2775, 283.845, 282.8725, 
    280.7275, 279.6925, 277.71, 278.7525, 278.2525, 277.955, 276.8925, 
    277.8575,
  _, _, _, _, _, _, _, _, _, _, _, _, _, 283.5825, 284.19, 283.5175, 282.505, 
    279.8925, 277.9125, 280.3025, 279.71, 279.0225, 277.855, 277.6425,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 284.13, 283.7725, 281.725, 
    280.4525, 280.2075, 281.1225, 278.8675, 277.8125, 275.6425, 273.1575,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 283.22, 282.8725, 281.6175, 
    280.2525, 282.085, 279.51, 276.64, 277.6425, 275.785, 274.8025,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 283.555, 282.5225, 281.35, 
    280.9875, 281.2175, 279.69, 276.8325, 277.92, 278.545, 276.025,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 283.4325, 283.145, 281.6075, 
    280.6225, 279.645, 281.6975, 279.525, 278.3375, 277.3175, 276.1125,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 283.5425, 282.7525, 281.98, 
    279.3125, 277.685, 279.1825, 279.54, 277.4825, 274.5025, 274.28,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 283.7325, 282.6225, 279.965, 
    277.5025, 276.2225, 279.435, 277.405, 274.04, 273.575, 273.1975,
  _, _, _, _, _, _, _, _, _, _, _, _, _, 283.7425, 282.79, 281.58, 280.3, 
    278.8425, 275.7175, 277.72, 279.4675, 276.9725, 273.9175, 276.1425,
  _, _, _, _, _, _, _, _, _, _, _, _, _, 283.62, 283.5, 282.0525, 280.3125, 
    278.695, 276.55, 275.6775, 278.59, 279.1775, 277.6225, 277.7375,
  _, _, _, _, _, _, _, _, _, _, _, _, _, 282.815, 282.7425, 280.82, 279.42, 
    279.405, 277.9625, 275.9, 277.1075, 275.6775, 275.4475, 274.9375,
  _, _, _, _, _, _, _, _, _, _, _, _, 282.9475, 282.21, 281.7425, 280.425, 
    278.4075, 277.5175, 280.0325, 278.415, 275.5625, 273.9425, 276.7075, 
    277.3575,
  _, _, _, _, _, _, _, _, _, _, _, _, 282.89, 281.25, 280.66, 279.84, 
    277.1625, 276.2075, 279.15, 279.41, 276.7175, 278.3175, 277.995, 278.57,
  _, _, _, _, _, _, _, _, _, _, _, _, 282.8425, 281.2075, 278.91, 279.285, 
    278.0675, 277.525, 277.39, 279.43, 278.51, 279.025, 278.795, 277.51,
  _, _, _, _, _, _, _, _, _, _, _, _, 283.0725, 280.9025, 279.325, 279.4575, 
    278.9425, 277.4375, 276.38, 277.565, 279.735, 278.8725, 278.43, 278.5475,
  _, _, _, _, _, _, _, _, _, _, _, 283.71, 283.0925, 281.995, 280.6075, 
    280.6625, 277.8525, 276.36, 276.8975, 278.25, 278.6175, 276.5725, 
    277.085, 276.765,
  _, _, _, _, _, _, _, _, _, _, _, 283.705, 282.455, 280.77, 279.435, 
    279.8475, 279.575, 278.6325, 278.565, 278.6125, 278.88, 277.3075, 
    275.2425, 275.6725,
  _, _, _, _, _, _, _, _, _, _, _, 283.6425, 282.6425, 281.3225, 281.3325, 
    280.765, 278.3825, 278.52, 278.895, 279.8625, 278.59, 278.27, 277.1325, 
    276.445,
  _, _, _, _, _, _, _, _, _, _, _, 283.77, 282.9875, 281.8175, 282.2625, 
    282.26, 280.6975, 279.48, 279.4225, 279.615, 279.4675, 279.7825, 
    279.0725, 278.875,
  _, _, _, _, _, _, _, _, _, _, _, _, 283.5675, 282.85, 283.1625, 282.69, 
    281.86, 279.54, 279.7675, 280.375, 280.245, 279.7575, 279.2675, 278.545,
  _, _, _, _, _, _, _, _, _, _, _, _, 283.7225, 283.3175, 283.16, 283.0075, 
    281.6175, 279.845, 278.5275, 279.8825, 280.9775, 280.405, 279.435, 
    278.6925,
  _, _, _, _, _, _, _, _, _, _, _, _, 283.3675, 283.4125, 283.265, 282.4, 
    281.25, 280.76, 279.6075, 279.715, 281.525, 280.97, 280.535, 279.86,
  _, _, _, _, _, _, _, _, _, _, _, _, _, 283.635, 283.1575, 282.29, 281.54, 
    280.34, 280.385, 281.3275, 281.145, 281.8825, 281.335, 279.53,
  _, _, _, _, _, _, _, _, _, _, _, _, _, 282.4425, 283.135, 282.4425, 280.98, 
    281.555, 280.9575, 282.0525, 280.7825, 281.4525, 280.805, 279.3475,
  _, _, _, _, _, _, _, _, _, _, _, _, _, 282.7975, 283.24, 282.8675, 282.26, 
    281.8125, 281.915, 281.7625, 281.3625, 281.5325, 281.035, 280.07,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 283.3, 282.94, 282.535, 281.9, 
    281.7175, 281.1325, 280.905, 280.925, 280.835, 280.98,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 283.4975, 282.985, 282.11, 
    280.9775, 281.1725, 281.395, 280.925, 281.055, 281.0675, 281.0775 ;

 lat = 40.0625, 40.1875, 40.3125, 40.4375, 40.5625, 40.6875, 40.8125, 
    40.9375, 41.0625, 41.1875, 41.3125, 41.4375, 41.5625, 41.6875, 41.8125, 
    41.9375, 42.0625, 42.1875, 42.3125, 42.4375, 42.5625, 42.6875, 42.8125, 
    42.9375, 43.0625, 43.1875, 43.3125, 43.4375, 43.5625, 43.6875, 43.8125, 
    43.9375 ;

 lon = -67.9375, -67.8125, -67.6875, -67.5625, -67.4375, -67.3125, -67.1875, 
    -67.0625, -124.9375, -124.8125, -124.6875, -124.5625, -124.4375, 
    -124.3125, -124.1875, -124.0625, -123.9375, -123.8125, -123.6875, 
    -123.5625, -123.4375, -123.3125, -123.1875, -123.0625 ;
}
