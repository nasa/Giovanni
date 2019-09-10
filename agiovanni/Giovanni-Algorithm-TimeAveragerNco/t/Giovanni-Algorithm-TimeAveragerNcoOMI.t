# AUTHOR:  Christine Smit, adapted from Chris Lynnes's test
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-TimeAveragerNco.t'

#########################

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
my $bbox  = '5.0,5.0,10.0,10.0';
my $start = '2005-01-01T00:00:00Z';
my $end   = '2005-01-03T23:59:59Z';

# no group
my $group = undef;

my $outfile
    = "$datadir/timeAvgMap.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050101-20050103.5E_5N_10E_10N.nc";
Giovanni::Algorithm::TimeAveragerNco::time_averager( $datadir, $outfile,
    $file_list, "OMAERUVd_003_FinalAerosolAbsOpticalDepth500",
    $start, $end, $bbox, $opt_z, $group );

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
netcdf scrubbed.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050101_SUB {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 7 ;
    lon = 7 ;
variables:
    float OMAERUVd_003_FinalAerosolAbsOpticalDepth500(time, lat, lon) ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:units = "1" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:origname = "FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:orig_dimname_list = "XDim " ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:standard_name = "finalaerosolabsopticaldepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:quantity_type = "Component Aerosol Optical Depth" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_short_name = "OMAERUVd" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_version = "003" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:long_name = "Aerosol Absorption Optical Depth 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:coordinates = "time lat lon" ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:units = "degrees_north" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
    float lon(lon) ;
        lon:units = "degrees_east" ;
        lon:standard_name = "longitude" ;
        lon:long_name = "Longitude" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2005-01-01T00:00:00Z" ;
        :end_time = "2005-01-01T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :history = "Wed Jul 22 15:42:56 2015: ncks -d lat,4.0,11.0 -d lon,4.0,11.0 -o scrubbed.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050101_SUB.nc scrubbed.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050101.nc" ;
        :NCO = "4.4.4" ;
data:

 OMAERUVd_003_FinalAerosolAbsOpticalDepth500 =
  _, 0.0801, 0.1222, 0.108, 0.1036, 0.1251, 0.0939,
  _, 0.1337, 0.1162, 0.1175, 0.1145, 0.0919, 0.0367,
  0.1007, 0.1327, 0.1356, 0.1266, 0.0533, 0.0839, 0.0435,
  0.0938, 0.1094, 0.1169, 0.116, 0.1153, 0.0364, 0.0786,
  0.0773, 0.0833, 0.1162, 0.1022, 0.0832, 0.0478, 0.0619,
  0.082, 0.0797, 0.0708, 0.0854, 0.0647, 0.0305, 0.0294,
  0.072, 0.0648, 0.0538, 0.0427, 0.0686, 0.0679, 0.0239 ;

 dataday = 2005001 ;

 lat = 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5 ;

 lon = 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5 ;

 time = 1104537600 ;
}
netcdf scrubbed.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050102_SUB {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 7 ;
    lon = 7 ;
variables:
    float OMAERUVd_003_FinalAerosolAbsOpticalDepth500(time, lat, lon) ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:units = "1" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:origname = "FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:orig_dimname_list = "XDim " ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:standard_name = "finalaerosolabsopticaldepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:quantity_type = "Component Aerosol Optical Depth" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_short_name = "OMAERUVd" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_version = "003" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:long_name = "Aerosol Absorption Optical Depth 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:coordinates = "time lat lon" ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:units = "degrees_north" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
    float lon(lon) ;
        lon:units = "degrees_east" ;
        lon:standard_name = "longitude" ;
        lon:long_name = "Longitude" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2005-01-02T00:00:00Z" ;
        :end_time = "2005-01-02T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :history = "Wed Jul 22 15:43:13 2015: ncks -d lat,4.0,11.0 -d lon,4.0,11.0 -o scrubbed.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050102_SUB.nc scrubbed.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050102.nc" ;
        :NCO = "4.4.4" ;
data:

 OMAERUVd_003_FinalAerosolAbsOpticalDepth500 =
  _, 0.0463, 0.0604, 0.1346, 0.1645, 0.1999, 0.2013,
  _, 0.0775, 0.0633, 0.0805, 0.1615, 0.0993, 0.1468,
  0.0233, 0.0577, 0.081, 0.0974, 0.0976, 0.1016, 0.1457,
  0.066, 0.0745, 0.0942, 0.0997, 0.1107, _, 0.2298,
  0.0788, 0.0636, 0.0825, 0.0738, 0.0885, _, _,
  0.069, 0.0694, 0.0723, 0.0448, 0.0396, 0.0254, _,
  0.0416, 0.053, 0.0513, 0.0251, 0.0473, 0.0418, _ ;

 dataday = 2005002 ;

 lat = 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5 ;

 lon = 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5 ;

 time = 1104624000 ;
}
netcdf scrubbed.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050103_SUB {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 7 ;
    lon = 7 ;
variables:
    float OMAERUVd_003_FinalAerosolAbsOpticalDepth500(time, lat, lon) ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:units = "1" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:origname = "FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:orig_dimname_list = "XDim " ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:standard_name = "finalaerosolabsopticaldepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:quantity_type = "Component Aerosol Optical Depth" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_short_name = "OMAERUVd" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_version = "003" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:long_name = "Aerosol Absorption Optical Depth 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:coordinates = "time lat lon" ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    float lat(lat) ;
        lat:units = "degrees_north" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
    float lon(lon) ;
        lon:units = "degrees_east" ;
        lon:standard_name = "longitude" ;
        lon:long_name = "Longitude" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2005-01-03T00:00:00Z" ;
        :end_time = "2005-01-03T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :history = "Wed Jul 22 15:43:24 2015: ncks -d lat,4.0,11.0 -d lon,4.0,11.0 -o scrubbed.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050103_SUB.nc scrubbed.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050103.nc" ;
        :NCO = "4.4.4" ;
data:

 OMAERUVd_003_FinalAerosolAbsOpticalDepth500 =
  0.1322, 0.12, 0.1128, 0.134, 0.1604, 0.1575, 0.1307,
  0.1115, 0.126, 0.1384, 0.149, 0.1504, 0.1159, 0.0567,
  0.1204, 0.1048, 0.1255, 0.1381, _, _, 0.0397,
  0.1321, 0.1151, 0.115, 0.1344, _, _, _,
  0.1179, 0.1525, 0.15, 0.1078, _, _, _,
  0.1006, 0.1404, 0.1472, 0.1345, 0.0673, 0.0441, 0.1031,
  0.0833, 0.0831, 0.09, 0.0916, 0.0884, 0.0961, 0.1601 ;

 dataday = 2005003 ;

 lat = 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5 ;

 lon = 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5 ;

 time = 1104710400 ;
}
netcdf timeAvgMap.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20050101-20050103.5E_5N_10E_10N {
dimensions:
    lat = 5 ;
    lon = 5 ;
variables:
    float OMAERUVd_003_FinalAerosolAbsOpticalDepth500(lat, lon) ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:units = "1" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:origname = "FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:orig_dimname_list = "XDim " ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:standard_name = "finalaerosolabsopticaldepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:quantity_type = "Component Aerosol Optical Depth" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_short_name = "OMAERUVd" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_version = "003" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:long_name = "Aerosol Absorption Optical Depth 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:coordinates = "lat lon" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:cell_methods = "time: mean" ;
    float lat(lat) ;
        lat:units = "degrees_north" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
    float lon(lon) ;
        lon:units = "degrees_east" ;
        lon:standard_name = "longitude" ;
        lon:long_name = "Longitude" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2005-01-01T00:00:00Z" ;
        :end_time = "2005-01-03T23:59:59Z" ;
        :NCO = "4.4.4" ;
        :title = "OMAERUVd_003_FinalAerosolAbsOpticalDepth500 Averaged over 2005-01-01 to 2005-01-03" ;
data:

 OMAERUVd_003_FinalAerosolAbsOpticalDepth500 =
  0.1124, 0.1059667, 0.1156667, 0.1421333, 0.1023667,
  0.0984, 0.1140333, 0.1207, 0.07545, 0.09275,
  0.09966666, 0.1087, 0.1167, 0.113, 0.0364,
  0.09980001, 0.1162333, 0.0946, 0.08585, 0.0478,
  0.0965, 0.09676667, 0.08823333, 0.0572, 0.03333334 ;

 lat = 5.5, 6.5, 7.5, 8.5, 9.5 ;

 lon = 5.5, 6.5, 7.5, 8.5, 9.5 ;

}

