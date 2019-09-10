# AUTHOR:  Christine Smit, adapted from Chris Lynnes's test
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-TimeAveragerNco.t'

#########################

use strict;
use warnings;
use Test::More tests => 3;
use File::Temp qw/tempdir/;
use FindBin;

use Giovanni::Data::NcFile;

# Basic test of module call
BEGIN { use_ok('Giovanni::Algorithm::TimeAveragerNco') }

use vars qw($opt_z);


# Read input CDL
my $ra_cdl = read_cdl_data();

# Last netcdf {} is our output file
my @cdl      = @$ra_cdl;
my $expected = pop(@cdl);

my $datadir = tempdir( CLEANUP => 1 );

# Call a routine to write out the CDL, then convert to netcdf files
my @ncfiles
    = map { write_netcdf( "$datadir/test_" . $_ . ".cdl", $cdl[ $_ - 1 ] ) }
    1 .. scalar(@cdl);

# Call the same routine to write out the output file
my $expectedNc = write_netcdf( "$datadir/out.cdl", $expected );

# Write out input files
my $file_list = "$datadir/files.txt";
write_file( $file_list, join( "\n", @ncfiles, '' ) );

# Run it using just the module
my $bbox  = '6.0,6.0,9.0,9.0';
my $start = '2012-10-29T00:00:00Z';
my $end   = '2012-10-29T23:59:59Z';
my $opt_z = 'Height=450hPa';

my $outfile
    = "$datadir/timeAvgMap.MAI3CPASM_5_2_0_UV.450hPa.20121029-20121029.6E_6N_9E_9N.nc";
Giovanni::Algorithm::TimeAveragerNco::time_averager( $datadir, $outfile,
    $file_list, "MAI3CPASM_5_2_0_UV", $start, $end, $bbox, $opt_z );

ok( ( -f $outfile ), 'outfile exists' ) or die "No point in continuing";

# delete history in the output file
Giovanni::Data::NcFile::delete_history($outfile);

# Check return
my $df = Giovanni::Data::NcFile::diff_netcdf_files( $outfile, $expectedNc );

is( $df, '', "Same output: $df" );

#########################

sub read_output {
    local ($/) = undef;
    my $got = `ncdump $_[0]`;
    $got =~ s/\n\s+?:history.*?;//sg;
    $got =~ s/\n\s+?:nco.*?;//isg;
    return $got;
}

sub read_cdl_data {

    # read block at __DATA__ and write to a CDL file
    local ($/) = undef;
    my $cdldata = <DATA>;
    my @cdl = ( $cdldata =~ m/(netcdf .*?\}\n)/gs );
    return \@cdl;
}

sub write_file {
    my ( $filename, $string ) = @_;
    open( OUT, '>', $filename ) or die "Cannot write to $filename: $!";
    print OUT $string;
    close OUT or die "Cannot close $filename: $!";
    return;
}

sub write_netcdf {
    my ( $cdlpath, $cdldata ) = @_;

    # write to CDL file
    open( CDLFILE, ">", $cdlpath ) or die "Cannot open $cdlpath: $!";
    print CDLFILE $cdldata;
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
netcdf out {
dimensions:
    Height = 3 ;
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 4 ;
variables:
    double Height(Height) ;
        Height:long_name = "vertical level" ;
        Height:units = "hPa" ;
        Height:positive = "down" ;
        Height:coordinate = "PLE" ;
        Height:standard_name = "PLE_level" ;
        Height:formula_term = "unknown" ;
        Height:fullpath = "Height:EOSGRID" ;
    float MAI3CPASM_5_2_0_UV_u(time, Height, lat, lon) ;
        MAI3CPASM_5_2_0_UV_u:_FillValue = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_u:coordinates = "time Height lat lon" ;
        MAI3CPASM_5_2_0_UV_u:fmissing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_u:fullpath = "/EOSGRID/Data Fields/U" ;
        MAI3CPASM_5_2_0_UV_u:long_name = "Wind Vector" ;
        MAI3CPASM_5_2_0_UV_u:missing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_u:standard_name = "wind_vector" ;
        MAI3CPASM_5_2_0_UV_u:units = "m/s" ;
        MAI3CPASM_5_2_0_UV_u:valid_range = -1.e+30f, 1.e+30f ;
        MAI3CPASM_5_2_0_UV_u:vmax = 1.e+30f ;
        MAI3CPASM_5_2_0_UV_u:vmin = -1.e+30f ;
        MAI3CPASM_5_2_0_UV_u:cell_methods = "record: mean" ;
        MAI3CPASM_5_2_0_UV_u:vectorComponents = "u of MAI3CPASM_5_2_0_UV" ;
        MAI3CPASM_5_2_0_UV_u:quantity_type = "Wind" ;
        MAI3CPASM_5_2_0_UV_u:product_short_name = "MAI3CPASM" ;
        MAI3CPASM_5_2_0_UV_u:product_version = "5.2.0" ;
    float MAI3CPASM_5_2_0_UV_v(time, Height, lat, lon) ;
        MAI3CPASM_5_2_0_UV_v:_FillValue = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_v:coordinates = "time Height lat lon" ;
        MAI3CPASM_5_2_0_UV_v:fmissing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_v:fullpath = "/EOSGRID/Data Fields/V" ;
        MAI3CPASM_5_2_0_UV_v:long_name = "Wind Vector" ;
        MAI3CPASM_5_2_0_UV_v:missing_value = 1.e+15f ;
        MAI3CPASM_5_2_0_UV_v:standard_name = "wind_vector" ;
        MAI3CPASM_5_2_0_UV_v:units = "m/s" ;
        MAI3CPASM_5_2_0_UV_v:valid_range = -1.e+30f, 1.e+30f ;
        MAI3CPASM_5_2_0_UV_v:vmax = 1.e+30f ;
        MAI3CPASM_5_2_0_UV_v:vmin = -1.e+30f ;
        MAI3CPASM_5_2_0_UV_v:cell_methods = "record: mean" ;
        MAI3CPASM_5_2_0_UV_v:vectorComponents = "v of MAI3CPASM_5_2_0_UV" ;
        MAI3CPASM_5_2_0_UV_v:quantity_type = "Wind" ;
        MAI3CPASM_5_2_0_UV_v:product_short_name = "MAI3CPASM" ;
        MAI3CPASM_5_2_0_UV_v:product_version = "5.2.0" ;
    double lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:units = "degrees_north" ;
        lat:fullpath = "YDim:EOSGRID" ;
        lat:standard_name = "latitude" ;
    double lon(lon) ;
        lon:long_name = "Longitude" ;
        lon:units = "degrees_east" ;
        lon:fullpath = "XDim:EOSGRID" ;
        lon:standard_name = "longitude" ;
    double time(time) ;
        time:begin_date = 20121029 ;
        time:begin_time = 0 ;
        time:fullpath = "TIME:EOSGRID" ;
        time:long_name = "time" ;
        time:standard_name = "time" ;
        time:time_increment = 30000 ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2012-10-29T00:00:00Z" ;
        :end_time = "2012-10-29T02:59:59Z" ;
        :temporal_resolution = "3-hourly" ;
        :NCO = "4.4.4" ;
data:

 Height = 500, 450, 400 ;

 MAI3CPASM_5_2_0_UV_u =
  -8.386894, -8.918144, -9.027519, -8.699394,
  -8.027519, -8.152519, -7.558769, -8.027519,
  -9.746269, -9.355644, -8.215019, -8.215019,
  -10.23064, -8.855644, -7.855644, -7.683769,
  -7.248378, -9.279628, -10.29525, -10.06088,
  -7.904628, -11.68588, -12.21713, -10.93588,
  -10.90463, -14.24838, -14.02963, -12.52963,
  -12.62338, -12.09213, -11.18588, -10.264,
  -6.064668, -8.705293, -12.25217, -14.22092,
  -8.142793, -13.47092, -17.87717, -17.87717,
  -11.22092, -15.25217, -17.68967, -17.93967,
  -13.22092, -15.62717, -16.87717, -16.50217 ;

 MAI3CPASM_5_2_0_UV_v =
  -3.654209, -3.763584, -3.126865, -3.61124,
  -1.451084, -2.013584, -2.439365, -3.478427,
  -0.1517672, -0.2987398, -1.246005, -2.912021,
  0.3756987, -0.2772554, -1.314365, -2.619052,
  -3.192034, -2.574846, -3.262346, -4.277971,
  -2.410784, -2.266252, -3.110002, -4.356096,
  -0.3670825, -0.2179125, -1.551409, -3.426409,
  1.567732, 0.4153882, -1.281877, -3.44594,
  -1.72575, -1.460125, -3.292156, -6.049969,
  -2.046062, -2.397625, -4.518719, -6.635906,
  -0.656414, -1.674969, -3.60075, -5.057781,
  0.1238594, -1.284344, -2.139812, -2.823406 ;

 lat = 5.625, 6.875, 8.125, 9.375 ;

 lon = 5.625, 6.875, 8.125, 9.375 ;

 time = 1351468800 ;
}
netcdf timeAvgMap.MAI3CPASM_5_2_0_UV.450hPa.20121029-20121029.6E_6N_9E_9N {
dimensions:
	lat = 2 ;
	lon = 2 ;
variables:
	float MAI3CPASM_5_2_0_UV_u(lat, lon) ;
		MAI3CPASM_5_2_0_UV_u:_FillValue = 1.e+15f ;
		MAI3CPASM_5_2_0_UV_u:coordinates = " lat lon" ;
		MAI3CPASM_5_2_0_UV_u:fmissing_value = 1.e+15f ;
		MAI3CPASM_5_2_0_UV_u:fullpath = "/EOSGRID/Data Fields/U" ;
		MAI3CPASM_5_2_0_UV_u:long_name = "Wind Vector" ;
		MAI3CPASM_5_2_0_UV_u:missing_value = 1.e+15f ;
		MAI3CPASM_5_2_0_UV_u:standard_name = "wind_vector" ;
		MAI3CPASM_5_2_0_UV_u:units = "m/s" ;
		MAI3CPASM_5_2_0_UV_u:valid_range = -1.e+30f, 1.e+30f ;
		MAI3CPASM_5_2_0_UV_u:vmax = 1.e+30f ;
		MAI3CPASM_5_2_0_UV_u:vmin = -1.e+30f ;
		MAI3CPASM_5_2_0_UV_u:cell_methods = "record: mean time: mean Height: mean" ;
		MAI3CPASM_5_2_0_UV_u:vectorComponents = "u of MAI3CPASM_5_2_0_UV" ;
		MAI3CPASM_5_2_0_UV_u:quantity_type = "Wind" ;
		MAI3CPASM_5_2_0_UV_u:product_short_name = "MAI3CPASM" ;
		MAI3CPASM_5_2_0_UV_u:product_version = "5.2.0" ;
		MAI3CPASM_5_2_0_UV_u:z_slice = "450hPa" ;
		MAI3CPASM_5_2_0_UV_u:z_slice_type = "pressure" ;
	float MAI3CPASM_5_2_0_UV_v(lat, lon) ;
		MAI3CPASM_5_2_0_UV_v:_FillValue = 1.e+15f ;
		MAI3CPASM_5_2_0_UV_v:coordinates = " lat lon" ;
		MAI3CPASM_5_2_0_UV_v:fmissing_value = 1.e+15f ;
		MAI3CPASM_5_2_0_UV_v:fullpath = "/EOSGRID/Data Fields/V" ;
		MAI3CPASM_5_2_0_UV_v:long_name = "Wind Vector" ;
		MAI3CPASM_5_2_0_UV_v:missing_value = 1.e+15f ;
		MAI3CPASM_5_2_0_UV_v:standard_name = "wind_vector" ;
		MAI3CPASM_5_2_0_UV_v:units = "m/s" ;
		MAI3CPASM_5_2_0_UV_v:valid_range = -1.e+30f, 1.e+30f ;
		MAI3CPASM_5_2_0_UV_v:vmax = 1.e+30f ;
		MAI3CPASM_5_2_0_UV_v:vmin = -1.e+30f ;
		MAI3CPASM_5_2_0_UV_v:cell_methods = "record: mean time: mean Height: mean" ;
		MAI3CPASM_5_2_0_UV_v:vectorComponents = "v of MAI3CPASM_5_2_0_UV" ;
		MAI3CPASM_5_2_0_UV_v:quantity_type = "Wind" ;
		MAI3CPASM_5_2_0_UV_v:product_short_name = "MAI3CPASM" ;
		MAI3CPASM_5_2_0_UV_v:product_version = "5.2.0" ;
		MAI3CPASM_5_2_0_UV_v:z_slice = "450hPa" ;
		MAI3CPASM_5_2_0_UV_v:z_slice_type = "pressure" ;
	double lat(lat) ;
		lat:long_name = "Latitude" ;
		lat:units = "degrees_north" ;
		lat:fullpath = "YDim:EOSGRID" ;
		lat:standard_name = "latitude" ;
	double lon(lon) ;
		lon:long_name = "Longitude" ;
		lon:units = "degrees_east" ;
		lon:fullpath = "XDim:EOSGRID" ;
		lon:standard_name = "longitude" ;

// global attributes:
		:nco_openmp_thread_number = 1 ;
		:Conventions = "CF-1.4" ;
		:start_time = "2012-10-29T00:00:00Z" ;
		:end_time = "2012-10-29T02:59:59Z" ;
		:NCO = "\"4.5.3\"" ;
		:title = "MAI3CPASM_5_2_0_UV Averaged over 2012-10-29 to 2012-10-29" ;
data:

 MAI3CPASM_5_2_0_UV_u =
  -11.68588, -12.21713,
  -14.24838, -14.02963 ;

 MAI3CPASM_5_2_0_UV_v =
  -2.266252, -3.110002,
  -0.2179125, -1.551409 ;

 lat = 6.875, 8.125 ;

 lon = 6.875, 8.125 ;
}
