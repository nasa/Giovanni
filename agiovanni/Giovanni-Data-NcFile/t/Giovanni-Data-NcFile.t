#$Id: Giovanni-Data-NcFile.t,v 1.27 2014/06/07 17:06:31 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Data-NcFile.t'

#########################

use File::Temp qw/ tempdir /;
use File::Copy;
use Test::More tests => 42;
BEGIN { use_ok('Giovanni::Data::NcFile') }
use strict;

#########################

my $attr
    = new NcAttribute( 'name' => 'foo', 'value' => 'bar', ncotype => 'c' );
ok( $attr, 'Create ncAttribute' );

# Create temporary directory for files
my $dir = ( exists $ENV{SAVEDIR} ) ? $ENV{SAVEDIR} : tempdir( CLEANUP => 1 );
my $outfile = "$dir/test.nc";

# Write output netcdf file using CDL data
# Not used for most operational process but used in a lot of tests
my $cdl_list = read_cdl_data();
my $cdl      = $cdl_list->[0];
ok( Giovanni::Data::NcFile::write_netcdf_file( $outfile, $cdl ),
    'Write CDL to a netCDF file' );
warn "Output file: $outfile\n";
ok( ( -e $outfile ), "Output file $outfile" );

# Test diffing, first with identical...
is( Giovanni::Data::NcFile::diff_netcdf_files( $outfile, $outfile  ), "", "diff_netcdf_files" );

# Then diffing with different netcdfs...
my $cdl2 = $cdl;
$cdl2 =~ s/\n.*?Conventions.*\n/\n/;
my $outfile2 = "$dir/test2.nc";
Giovanni::Data::NcFile::write_netcdf_file( $outfile2, $cdl2 )
    or die "Failed to write netCDF file $outfile2";
isnt(
    Giovanni::Data::NcFile::diff_netcdf_files( $outfile, $outfile2, ),
    '', "diff_netcdf_files"
);

# Then With different netcdfs, but exclude
is( Giovanni::Data::NcFile::diff_netcdf_files(
        $outfile, $outfile2,  "/Conventions"
    ),
    '',
    "diff_netcdf_files"
);

# Test adding attributes
my $attr3 = new NcAttribute(
    'variable' => 'lat',
    'name'     => 'foo',
    'value'    => 123.,
    'ncotype'  => 'f'
);
my $outfile3 = "$dir/test3.nc";
my $rc = Giovanni::Data::NcFile::edit_netcdf_attributes( $outfile, $outfile3,
    $attr, $attr3 );
ok( $rc, "Write netcdf attributes" );
isnt(
    Giovanni::Data::NcFile::diff_netcdf_files( $outfile, $outfile3, ),
    '',
    "diff_netcdf_files after attribute"
);
is( Giovanni::Data::NcFile::diff_netcdf_files(
        $outfile, $outfile3, 'lat/foo', '/foo'
    ),
    '',
    "diff_netcdf_files after attribute, with exclude"
);

# Test deleting attributes
my $del_attr = 'Statistic_Type';
my $attr4    = new NcAttribute(
    'variable' => 'MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean',
    'name'     => $del_attr,
    'action'   => 'd'
);
my $outfile4 = "$dir/test4.nc";
$rc = Giovanni::Data::NcFile::edit_netcdf_attributes( $outfile, $outfile4,
    $attr, $attr4 );
ok( $rc, "Delete netcdf attributes" );
isnt(
    Giovanni::Data::NcFile::diff_netcdf_files( $outfile, $outfile4),
    '',
    "diff_netcdf_files after deleting attribute"
);
is( Giovanni::Data::NcFile::diff_netcdf_files(
        $outfile, $outfile4,  '/foo', 
        "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean/$del_attr"
    ),
    '',
    "diff_netcdf_files after deleting attribute, with exclude"
);

# Test lat/lon resolution
my ( $latres, $lonres )
    = Giovanni::Data::NcFile::spatial_resolution($outfile);
is( $latres, 1.000000, 'Latitude Resolution' );
is( $lonres, 1.000000, 'Longitude Resolution' );
( $latres, $lonres )
    = Giovanni::Data::NcFile::spatial_resolution( $outfile, 'lat', 'lon' );
is( $latres, 1.000000, 'Latitude Resolution' );
is( $lonres, 1.000000, 'Longitude Resolution' );

# Test attribute parsing
my ( $rh_att, $ra_att )
    = Giovanni::Data::NcFile::variable_attributes( $outfile,
    "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean" );
is( $rh_att->{'coordinates'}, "time lat lon" );

# Test global attribute parsing
( $rh_att, $ra_att ) = Giovanni::Data::NcFile::global_attributes($outfile);
is( $rh_att->{'Conventions'}, 'CF-1.4', "Global attribute parsing" );

# Test fetching of dimension lengths, with reuse
my @lengths
    = Giovanni::Data::NcFile::dimension_lengths( $outfile, 1, "lat", "lon" );
is( $lengths[0], 16, "dimension_lengths (lat)" );
is( $lengths[1], 2,  "dimension_lengths (lon)" );

# Test pixellation
my $infile = "$dir/line.nc";
$outfile = "$dir/pixline.nc";
my $reffile = "$dir/refline.nc";
Giovanni::Data::NcFile::write_netcdf_file( $infile, $cdl_list->[1] )
    or die "Failed to write netcdf $infile: $!";
Giovanni::Data::NcFile::write_netcdf_file( $reffile, $cdl_list->[2] )
    or die "Failed to write netcdf $reffile: $!";
ok( Giovanni::Data::NcFile::pixellate(
        $infile,                                            $outfile,
        ["MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"], 2
    ),
    "Run Pixellate"
);
is( Giovanni::Data::NcFile::diff_netcdf_files( $outfile, $reffile ),
    '', "Pixellate file check" );

$infile  = "$dir/pt.nc";
$outfile = "$dir/pixpt.nc";
$reffile = "$dir/refpt.nc";
Giovanni::Data::NcFile::write_netcdf_file( $infile, $cdl_list->[3] )
    or die "Failed to write netcdf $infile: $!";
Giovanni::Data::NcFile::write_netcdf_file( $reffile, $cdl_list->[4] )
    or die "Failed to write netcdf $reffile: $!";
ok( Giovanni::Data::NcFile::pixellate(
        $infile,                                            $outfile,
        ["MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"], 2
    ),
    "Run Pixellate"
);
is( Giovanni::Data::NcFile::diff_netcdf_files( $outfile, $reffile ),
    '', "Pixellate file check" );

# Test getting plotable variables
$infile = "$dir/plottable.nc";
Giovanni::Data::NcFile::write_netcdf_file( $infile, $cdl_list->[5] )
    or die "Failed to write netcdf $infile: $!";
is_deeply(
    [ Giovanni::Data::NcFile::get_plottable_variables($infile) ],
    [   "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean",
        "MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"
    ],
    "Plottable variables"
);

# Test adding resolution attributes
$infile  = "$dir/noResolution.nc";
$reffile = "$dir/resolution.nc";
Giovanni::Data::NcFile::write_netcdf_file( $infile, $cdl_list->[0] )
    or die "Failed to write netcdf $infile: $!";
Giovanni::Data::NcFile::write_netcdf_file( $reffile, $cdl_list->[6] )
    or die "Failed to write netcdf $reffile: $!";
is_deeply(
    [   Giovanni::Data::NcFile::add_resolution_attributes(
            $infile, 1.0, 1.0
        )
    ],
    ["MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"],
    "Run add resolution"
);
is( Giovanni::Data::NcFile::diff_netcdf_files( $infile, $reffile),
    '', "Pixellate file check" );

Giovanni::Data::NcFile::write_netcdf_file( $infile, $cdl_list->[0] )
    or die "Failed to write netcdf $infile: $!";
ok( Giovanni::Data::NcFile::add_resolution_attributes(
        $infile, 1.0, 1.0, ["MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"],
        "lat", "lon"
    ),
    "Run add resolution"
);
is( Giovanni::Data::NcFile::diff_netcdf_files( $infile, $reffile),
    '', "Pixellate file check" );

# Test converting longitudes to be monotonically increasing values; case of handling bbox crossing 180 deg meridian
$infile  = "$dir/nonMonotonicLon.nc";
$reffile = "$dir/monotonicLon.nc";
Giovanni::Data::NcFile::write_netcdf_file( $infile, $cdl_list->[7] )
    or die "Failed to write netcdf $infile: $!";
Giovanni::Data::NcFile::write_netcdf_file( $reffile, $cdl_list->[8] )
    or die "Failed to write netcdf $reffile: $!";

my $tmpfile = $infile . '.bak';
copy( $infile, $tmpfile ) or die "Failed to copy $infile to $tmpfile ($!)";
Giovanni::Data::NcFile::make_monotonic_longitude( $infile, $tmpfile );
is( Giovanni::Data::NcFile::diff_netcdf_files(
        $tmpfile, $reffile), '',
    "Longitudes made monotonic: output file specified"
);
Giovanni::Data::NcFile::make_monotonic_longitude($infile);
is( Giovanni::Data::NcFile::diff_netcdf_files(
        $infile, $reffile), '',
    "Longitudes made monotonic: output file not specified"
);

# Test getting out variable values
Giovanni::Data::NcFile::write_netcdf_file( $outfile, $cdl );
my @lonValues
    = Giovanni::Data::NcFile::get_variable_values( $outfile, "lon", "lon" );
is_deeply(
    \@lonValues,
    [ '116.500000000', '117.500000000' ],
    "Got variable values out of the file"
);

# test the netcdf 3/4 stuff
my $emptyCdl     = "netcdf blah{}";
my $emptyCdlFile = "$dir/blah.cdl";
open( FILE, ">", $emptyCdlFile );
print FILE $emptyCdl;
close FILE;

# create a netcdf-4 file
my $ncFile4 = "$dir/file4.nc";
my $cmd     = "ncgen -k 'netCDF-4 classic model' -o $ncFile4 $emptyCdlFile";
my $ret     = system($cmd);
if ( $ret != 0 ) {
    die "Command returned non-zero: $cmd";
}
is( Giovanni::Data::NcFile::get_ncdf_version($ncFile4),
    4, "Is a netcdf 4 file" );

# create a netcdf-3 file
my $ncFile3 = "$dir/file3.nc";
$cmd = "ncgen -k 'classic' -o $ncFile3 $emptyCdlFile";
$ret = system($cmd);
if ( $ret != 0 ) {
    die "Command returned non-zero: $cmd";
}

is( Giovanni::Data::NcFile::get_ncdf_version($ncFile3),
    3, "Is a netcdf 3 file" );

my $nc3To4 = "$dir/nc3To4.nc";
ok( Giovanni::Data::NcFile::to_netCDF4_classic( $ncFile3, $nc3To4 ),
    "Converted netcdf 3 to 4" );
is( Giovanni::Data::NcFile::get_ncdf_version($nc3To4),
    4, "Converted is a netcdf 4 file" );

my $nc4To3 = "$dir/nc4To3.nc";
ok( Giovanni::Data::NcFile::to_netCDF3( $ncFile4, $nc4To3 ),
    "Converted netcdf 4 to 3" );
is( Giovanni::Data::NcFile::get_ncdf_version($nc4To3),
    3, "Converted is a netcdf 3 file" );

$infile = "$dir/file_without_time_bounds.nc";
Giovanni::Data::NcFile::write_netcdf_file( $infile, $cdl_list->[9] )
    or die "Failed to write netcdf $infile: $!";
$reffile = "$dir/file_with_time_bounds.nc";
Giovanni::Data::NcFile::write_netcdf_file( $reffile, $cdl_list->[10] )
    or die "Failed to write netcdf $reffile: $!";
my $refTimeBounds = [
    1136073600, 1136160000, 1136160000, 1136246400, 1136246400, 1136332800,
    1136332800, 1136419200, 1136419200, 1136505600
];

# Find time bounds when the input file doesn't have one
my $timeBounds = Giovanni::Data::NcFile::get_time_bounds($infile);
is_deeply( $timeBounds, $refTimeBounds,
    "Found time bounds: input file without time bounds" );

# Set the time bounds and compare with refernce data file
Giovanni::Data::NcFile::set_time_bounds( $infile, $timeBounds );
is( Giovanni::Data::NcFile::diff_netcdf_files(
        $infile, $reffile),
    '',
    "Set time bounds"
);

# Find time bound when the input file has time bounds
$timeBounds = Giovanni::Data::NcFile::get_time_bounds($infile);
is_deeply( $timeBounds, $refTimeBounds,
    "Found time bounds: input file with time bounds" );

# Test
sub read_cdl_data {

    # read block at __DATA__ and write to a CDL file
    local ($/) = undef;
    my $cdldata = <DATA>;
    my @cdl = ( $cdldata =~ m/(netcdf .*?\}\n)/gs );
    return \@cdl;
}

__DATA__
netcdf timeAvg.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20091231-20100102.116E_28N_118E_44N.SEASON_DJF {
dimensions:
        lat = 16 ;
        lon = 2 ;
variables:
        double lat(lat) ;
                lat:long_name = "Latitude" ;
                lat:units = "degrees_north" ;
        double lon(lon) ;
                lon:long_name = "Longitude" ;
                lon:units = "degrees_east" ;
        double MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Aerosol Optical Depth" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_type = "SEASON" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_value = "DJF" ;

// global attributes:
                :Conventions = "CF-1.4" ;
                :title = "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43.5, 42.5, 41.5, 40.5, 39.5, 38.5, 37.5, 36.5, 35.5, 34.5, 33.5,
    32.5, 31.5, 30.5, 29.5, 28.5 ;

 lon = 116.5, 117.5 ;

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, _,
  _, _,
  0.138, 0.17,
  0.139, 0.132,
  0.283, 1.455,
  0.253, 0.247,
  0.459, 0.4585,
  0.481, 0.455,
  0.4675, 0.308,
  0.46, 0.477,
  0.4655, 0.443,
  0.515, 0.498,
  0.4645, 0.547,
  0.5895, 0.5015,
  0.676, 0.626,
  0.707, 0.632 ;
}
netcdf timeAvg.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20091231-20100102.116E_28N_118E_29N.SEASON_DJF {
dimensions:
        lat = 1 ;
        lon = 2 ;
variables:
        double lat(lat) ;
                lat:long_name = "Latitude" ;
                lat:units = "degrees_north" ;
        double lon(lon) ;
                lon:long_name = "Longitude" ;
                lon:units = "degrees_east" ;
        double MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Aerosol Optical Depth" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_type = "SEASON" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_value = "DJF" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;

// global attributes:
                :Conventions = "CF-1.4" ;
                :title = "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43.5 ;

 lon = 116.5, 117.5 ;

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.707, 0.632 ;
}
netcdf refline.nc {
dimensions:
	lon = 2 ;
	lat = 4 ;
variables:
	double lon(lon) ;
		lon:long_name = "Longitude" ;
		lon:units = "degrees_east" ;
		lon:standard_name = "longitude" ;
	double lat(lat) ;
		lat:long_name = "Latitude" ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
	double MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_type = "SEASON" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_value = "DJF" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Aerosol Optical Depth" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:title = "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lon = 116.5, 117.5 ;

 lat = 43.125, 43.375, 43.625, 43.875 ;

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
   0.707, 0.632,
   0.707, 0.632,
   0.707, 0.632,
   0.707, 0.632 ;
}
netcdf pt.nc {
dimensions:
        lat = 1 ;
        lon = 1 ;
variables:
        double lat(lat) ;
                lat:long_name = "Latitude" ;
                lat:units = "degrees_north" ;
        double lon(lon) ;
                lon:long_name = "Longitude" ;
                lon:units = "degrees_east" ;
        double MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Aerosol Optical Depth" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_type = "SEASON" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_value = "DJF" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;

// global attributes:
                :Conventions = "CF-1.4" ;
                :title = "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43.5 ;

 lon = 116.5 ;

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.707 ;
}
netcdf refpt.nc {
dimensions:
        lat = 4 ;
        lon = 4 ;
variables:
        double lat(lat) ;
                lat:long_name = "Latitude" ;
                lat:standard_name = "latitude" ;
                lat:units = "degrees_north" ;
        double lon(lon) ;
                lon:long_name = "Longitude" ;
                lon:standard_name = "longitude" ;
                lon:units = "degrees_east" ;
        double MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_type = "SEASON" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_value = "DJF" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Aerosol Optical Depth" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;

// global attributes:
                :Conventions = "CF-1.4" ;
                :title = "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43.125, 43.375, 43.625, 43.875 ;

 lon = 116.125, 116.375, 116.625, 116.875 ;

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  0.707, 0.707, 0.707, 0.707,
  0.707, 0.707, 0.707, 0.707,
  0.707, 0.707, 0.707, 0.707,
  0.707, 0.707, 0.707, 0.707 ;
}
netcdf timeAvg.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20091231-20100102.116E_28N_118E_44N.SEASON_DJF {
dimensions:
        lat = 16 ;
        lon = 2 ;
variables:
        double lat(lat) ;
                lat:long_name = "Latitude" ;
                lat:units = "degrees_north" ;
        double lon(lon) ;
                lon:long_name = "Longitude" ;
                lon:units = "degrees_east" ;
        double MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Aerosol Optical Depth" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_type = "SEASON" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_value = "DJF" ;
        double MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Aerosol Optical Depth" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_type = "SEASON" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_value = "DJF" ;                

// global attributes:
                :Conventions = "CF-1.4" ;
                :title = "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43.5, 42.5, 41.5, 40.5, 39.5, 38.5, 37.5, 36.5, 35.5, 34.5, 33.5,
    32.5, 31.5, 30.5, 29.5, 28.5 ;

 lon = 116.5, 117.5 ;

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, _,
  _, _,
  0.138, 0.17,
  0.139, 0.132,
  0.283, 1.455,
  0.253, 0.247,
  0.459, 0.4585,
  0.481, 0.455,
  0.4675, 0.308,
  0.46, 0.477,
  0.4655, 0.443,
  0.515, 0.498,
  0.4645, 0.547,
  0.5895, 0.5015,
  0.676, 0.626,
  0.707, 0.632 ;
  
  MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, _,
  _, _,
  0.138, 0.17,
  0.139, 0.132,
  0.283, 1.455,
  0.253, 0.247,
  0.459, 0.4585,
  0.481, 0.455,
  0.4675, 0.308,
  0.46, 0.477,
  0.4655, 0.443,
  0.515, 0.498,
  0.4645, 0.547,
  0.5895, 0.5015,
  0.676, 0.626,
  0.707, 0.632 ;
}
netcdf timeAvg.MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20091231-20100102.116E_28N_118E_44N.SEASON_DJF {
dimensions:
        lat = 16 ;
        lon = 2 ;
variables:
        double lat(lat) ;
                lat:long_name = "Latitude" ;
                lat:units = "degrees_north" ;
        double lon(lon) ;
                lon:long_name = "Longitude" ;
                lon:units = "degrees_east" ;
        double MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(lat, lon) ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Aerosol Optical Depth" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_type = "SEASON" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:group_value = "DJF" ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:latitude_resolution = 1.0 ;
                MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:longitude_resolution = 1.0 ;

// global attributes:
                :Conventions = "CF-1.4" ;
                :title = "MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean Averaged over 2009-12-31 to 2010-01-02" ;
data:

 lat = 43.5, 42.5, 41.5, 40.5, 39.5, 38.5, 37.5, 36.5, 35.5, 34.5, 33.5,
    32.5, 31.5, 30.5, 29.5, 28.5 ;

 lon = 116.5, 117.5 ;

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, _,
  _, _,
  0.138, 0.17,
  0.139, 0.132,
  0.283, 1.455,
  0.253, 0.247,
  0.459, 0.4585,
  0.481, 0.455,
  0.4675, 0.308,
  0.46, 0.477,
  0.4655, 0.443,
  0.515, 0.498,
  0.4645, 0.547,
  0.5895, 0.5015,
  0.676, 0.626,
  0.707, 0.632 ;
}

netcdf dimensionAveraged.AIRX3STD_006_RelHumid_A-1000.20060101-20060105.166E_48S_170W_30S {
dimensions:
	time = UNLIMITED ; // (5 currently)
	H2OPrsLvls_A = 1 ;
	lon = 23 ;
variables:
	float AIRX3STD_006_RelHumid_A(time, H2OPrsLvls_A, lon) ;
		AIRX3STD_006_RelHumid_A:_FillValue = -9999.f ;
		AIRX3STD_006_RelHumid_A:standard_name = "relative_humidity" ;
		AIRX3STD_006_RelHumid_A:long_name = "Relative Humidity (3D), daytime (ascending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_RelHumid_A:units = "percent" ;
		AIRX3STD_006_RelHumid_A:coordinates = "time H2OPrsLvls_A lat lon" ;
		AIRX3STD_006_RelHumid_A:quantity_type = "Water Vapor" ;
		AIRX3STD_006_RelHumid_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_RelHumid_A:product_version = "006" ;
		AIRX3STD_006_RelHumid_A:z_slice = "1000" ;
		AIRX3STD_006_RelHumid_A:z_slice_type = "unknown" ;
	float H2OPrsLvls_A(H2OPrsLvls_A) ;
		H2OPrsLvls_A:standard_name = "air_pressure" ;
		H2OPrsLvls_A:long_name = "Air pressure at H2O levels, daytime (ascending) node" ;
		H2OPrsLvls_A:units = "hPa" ;
		H2OPrsLvls_A:positive = "down" ;
		H2OPrsLvls_A:_CoordinateAxisType = "GeoZ" ;
	float lon(lon) ;
		lon:_FillValue = -9999.f ;
		lon:long_name = "Longitude" ;
		lon:missing_value = -9999.f ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2006-01-01T00:00:00Z" ;
		:end_time = "2006-01-05T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.3.1" ;
		:plot_hint_title = "Latitude-Averaged Hovmoller ( 48.3047S - 30.0234S )" ;
		:plot_hint_subtitle = "daily 1 x 1 deg. Relative Humidity (3D), daytime (ascending), AIRS, 1 x 1 deg. [AIRX3STD v6] in percent, @1000" ;
		:plot_hint_x_axis_label = "Longitude" ;
		:plot_hint_y_axis_label = "Time" ;
		:plot_hint_caption = "Selected latitude range was 48.3047S - 30.0234S. The variable Relative Humidity (3D), daytime (ascending), AIRS, 1 x 1 deg. [AIRX3STD v6] has a limited data extent of 90S - 90N.  The longitude range in the title reflects the data extent of the subsetted granules that went into making this result." ;
data:

 AIRX3STD_006_RelHumid_A =
  84.90134, 78.04223, 78.38239, 77.32329, 75.15656, 72.1246, 71.74733, 
    70.21346, 70.66785, 68.92024, 69.35723, 68.56245, 68.54221, _, _, 
    69.56467, 74.8856, 73.65131, 73.11855, 67.54849, 63.04778, 64.34664, 
    67.25784,
  72.81915, 72.06874, 74.63586, 77.10465, 77.72511, 77.5453, 75.65565, 
    71.72196, 74.03993, 74.66439, 77.00896, 80.45158, 88.46571, 67.54617, 
    66.06763, 66.01521, 65.56773, 66.58544, 67.45395, 68.33572, 70.28795, 
    72.62845, 77.83462,
  81.7651, 80.01939, 79.23466, _, 71.95721, 75.26917, 73.27214, 73.08754, 
    72.97534, 73.33094, 70.87957, 67.96429, 68.04806, 83.19997, 91.21711, 
    92.0111, _, _, 80.52496, 84.97622, 88.03751, 88.62823, 84.48943,
  62.73361, 62.99591, 63.85582, 65.62756, 69.24426, 70.80748, 68.75162, 
    69.73074, 73.76764, 73.75346, 76.74288, 79.75815, 80.06841, 67.71762, 
    65.15726, 63.47466, 65.51709, 66.14804, 68.87697, 69.86927, 69.92252, 
    71.95544, 73.93939,
  66.31179, 68.82038, 70.12006, 69.06141, 75.1525, 87.54301, _, 77.00787, 
    71.37151, 67.88673, 66.44595, 65.76756, 68.99266, 73.27317, 73.54247, 
    72.69487, 73.61004, 72.45677, 65.92025, 62.19873, 63.95161, 72.37199, 
    80.50443 ;

 H2OPrsLvls_A = 1000 ;

 lon = 167.5, 168.5, 169.5, 170.5, 171.5, 172.5, 173.5, 174.5, 175.5, 176.5, 
    177.5, 178.5, 179.5, -179.5, -178.5, -177.5, -176.5, -175.5, -174.5, 
    -173.5, -172.5, -171.5, -170.5 ;

 time = 1136073600, 1136160000, 1136246400, 1136332800, 1136419200 ;
}


netcdf dimensionAveraged.monotonicLongitude.AIRX3STD_006_RelHumid_A-1000.20060101-20060105.166E_48S_170W_30S_without_time_bounds {
dimensions:
	lon = 23 ;
	time = UNLIMITED ; // (5 currently)
	H2OPrsLvls_A = 1 ;
variables:
	float lon(lon) ;
		lon:_FillValue = -9999.f ;
		lon:long_name = "Longitude" ;
		lon:missing_value = -9999.f ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	float AIRX3STD_006_RelHumid_A(time, H2OPrsLvls_A, lon) ;
		AIRX3STD_006_RelHumid_A:_FillValue = -9999.f ;
		AIRX3STD_006_RelHumid_A:standard_name = "relative_humidity" ;
		AIRX3STD_006_RelHumid_A:long_name = "Relative Humidity (3D), daytime (ascending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_RelHumid_A:units = "percent" ;
		AIRX3STD_006_RelHumid_A:coordinates = "time H2OPrsLvls_A lat lon" ;
		AIRX3STD_006_RelHumid_A:quantity_type = "Water Vapor" ;
		AIRX3STD_006_RelHumid_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_RelHumid_A:product_version = "006" ;
		AIRX3STD_006_RelHumid_A:z_slice = "1000" ;
		AIRX3STD_006_RelHumid_A:z_slice_type = "unknown" ;
	float H2OPrsLvls_A(H2OPrsLvls_A) ;
		H2OPrsLvls_A:standard_name = "air_pressure" ;
		H2OPrsLvls_A:long_name = "Air pressure at H2O levels, daytime (ascending) node" ;
		H2OPrsLvls_A:units = "hPa" ;
		H2OPrsLvls_A:positive = "down" ;
		H2OPrsLvls_A:_CoordinateAxisType = "GeoZ" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2006-01-01T00:00:00Z" ;
		:end_time = "2006-01-05T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.3.1" ;
		:plot_hint_title = "Latitude-Averaged Hovmoller ( 48.3047S - 30.0234S )" ;
		:plot_hint_subtitle = "daily 1 x 1 deg. Relative Humidity (3D), daytime (ascending), AIRS, 1 x 1 deg. [AIRX3STD v6] in percent, @1000" ;
		:plot_hint_x_axis_label = "Longitude" ;
		:plot_hint_y_axis_label = "Time" ;
		:plot_hint_caption = "Selected latitude range was 48.3047S - 30.0234S. The variable Relative Humidity (3D), daytime (ascending), AIRS, 1 x 1 deg. [AIRX3STD v6] has a limited data extent of 90S - 90N.  The longitude range in the title reflects the data extent of the subsetted granules that went into making this result." ;
data:

 lon = 167.5, 168.5, 169.5, 170.5, 171.5, 172.5, 173.5, 174.5, 175.5, 176.5, 
    177.5, 178.5, 179.5, 180.5, 181.5, 182.5, 183.5, 184.5, 185.5, 
    186.5, 187.5, 188.5, 189.5 ;

 AIRX3STD_006_RelHumid_A =
  84.90134, 78.04223, 78.38239, 77.32329, 75.15656, 72.1246, 71.74733, 
    70.21346, 70.66785, 68.92024, 69.35723, 68.56245, 68.54221, _, _, 
    69.56467, 74.8856, 73.65131, 73.11855, 67.54849, 63.04778, 64.34664, 
    67.25784,
  72.81915, 72.06874, 74.63586, 77.10465, 77.72511, 77.5453, 75.65565, 
    71.72196, 74.03993, 74.66439, 77.00896, 80.45158, 88.46571, 67.54617, 
    66.06763, 66.01521, 65.56773, 66.58544, 67.45395, 68.33572, 70.28795, 
    72.62845, 77.83462,
  81.7651, 80.01939, 79.23466, _, 71.95721, 75.26917, 73.27214, 73.08754, 
    72.97534, 73.33094, 70.87957, 67.96429, 68.04806, 83.19997, 91.21711, 
    92.0111, _, _, 80.52496, 84.97622, 88.03751, 88.62823, 84.48943,
  62.73361, 62.99591, 63.85582, 65.62756, 69.24426, 70.80748, 68.75162, 
    69.73074, 73.76764, 73.75346, 76.74288, 79.75815, 80.06841, 67.71762, 
    65.15726, 63.47466, 65.51709, 66.14804, 68.87697, 69.86927, 69.92252, 
    71.95544, 73.93939,
  66.31179, 68.82038, 70.12006, 69.06141, 75.1525, 87.54301, _, 77.00787, 
    71.37151, 67.88673, 66.44595, 65.76756, 68.99266, 73.27317, 73.54247, 
    72.69487, 73.61004, 72.45677, 65.92025, 62.19873, 63.95161, 72.37199, 
    80.50443 ;

 H2OPrsLvls_A = 1000 ;

 time = 1136073600, 1136160000, 1136246400, 1136332800, 1136419200 ;
}
netcdf dimensionAveraged.OMAERUVd_003_FinalAerosolExtOpticalDepth388.20060101-20060105.75E_7N_82E_12N {
dimensions:
	time = UNLIMITED ; // (5 currently)
	lon = 6 ;
variables:
	float OMAERUVd_003_FinalAerosolExtOpticalDepth388(time, lon) ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:_FillValue = -1.267651e+30f ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:units = "1" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:title = "Final Aerosol Extinction Optical Depth at 388 nm" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:UniqueFieldDefinition = "OMI-Specific" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:missing_value = -1.267651e+30f ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:origname = "FinalAerosolExtOpticalDepth388" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolExtOpticalDepth388" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:orig_dimname_list = "XDim " ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:standard_name = "finalaerosolextopticaldepth388" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:quantity_type = "Total Aerosol Optical Depth" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:product_short_name = "OMAERUVd" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:product_version = "003" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:long_name = "Aerosol Optical Depth 388 nm (near-UV), OMI, 1 x 1 deg." ;
	float lon(lon) ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
		lon:long_name = "Longitude" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2006-01-01T00:00:00Z" ;
		:end_time = "2006-01-05T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.3.1" ;
		:plot_hint_title = "Latitude-Averaged Hovmoller ( 7.2422N - 12.1641N )" ;
		:plot_hint_subtitle = "daily 1 x 1 deg. Aerosol Optical Depth 388 nm (near-UV), OMI, 1 x 1 deg. [OMAERUVd v3]" ;
		:plot_hint_x_axis_label = "Longitude" ;
		:plot_hint_y_axis_label = "Time" ;
		:plot_hint_caption = "Selected latitude range was 7.2422N - 12.1641N. The variable Aerosol Optical Depth 388 nm (near-UV), OMI, 1 x 1 deg. [OMAERUVd v3] has a limited data extent of 90S - 90N.  The longitude range in the title reflects the data extent of the subsetted granules that went into making this result." ;
data:

 OMAERUVd_003_FinalAerosolExtOpticalDepth388 =
  0.1611213, 0.3026592, 0.3159, _, _, _,
  0.3449308, _, _, 0.6037918, 0.5497, _,
  0.4340748, 0.4280727, _, _, _, _,
  _, 0.288, _, _, _, _,
  0.6101358, _, _, _, _, _ ;

 lon = 76.5, 77.5, 78.5, 79.5, 80.5, 81.5 ;

 time = 1136073600, 1136160000, 1136246400, 1136332800, 1136419200 ;
}
netcdf dimensionAveraged.OMAERUVd_003_FinalAerosolExtOpticalDepth388.20060101-20060105.75E_7N_82E_12N_with_time_bounds {
dimensions:
  bnds = 2 ;
	time = UNLIMITED ; // (5 currently)
	lon = 6 ;
variables:
  int time_bnds(time, bnds) ;
	float OMAERUVd_003_FinalAerosolExtOpticalDepth388(time, lon) ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:_FillValue = -1.267651e+30f ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:units = "1" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:title = "Final Aerosol Extinction Optical Depth at 388 nm" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:UniqueFieldDefinition = "OMI-Specific" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:missing_value = -1.267651e+30f ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:origname = "FinalAerosolExtOpticalDepth388" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolExtOpticalDepth388" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:orig_dimname_list = "XDim " ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:standard_name = "finalaerosolextopticaldepth388" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:quantity_type = "Total Aerosol Optical Depth" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:product_short_name = "OMAERUVd" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:product_version = "003" ;
		OMAERUVd_003_FinalAerosolExtOpticalDepth388:long_name = "Aerosol Optical Depth 388 nm (near-UV), OMI, 1 x 1 deg." ;
	float lon(lon) ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
		lon:long_name = "Longitude" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
    time:bounds = "time_bnds" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2006-01-01T00:00:00Z" ;
		:end_time = "2006-01-05T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.3.1" ;
		:plot_hint_title = "Latitude-Averaged Hovmoller ( 7.2422N - 12.1641N )" ;
		:plot_hint_subtitle = "daily 1 x 1 deg. Aerosol Optical Depth 388 nm (near-UV), OMI, 1 x 1 deg. [OMAERUVd v3]" ;
		:plot_hint_x_axis_label = "Longitude" ;
		:plot_hint_y_axis_label = "Time" ;
		:plot_hint_caption = "Selected latitude range was 7.2422N - 12.1641N. The variable Aerosol Optical Depth 388 nm (near-UV), OMI, 1 x 1 deg. [OMAERUVd v3] has a limited data extent of 90S - 90N.  The longitude range in the title reflects the data extent of the subsetted granules that went into making this result." ;
data:

 time_bnds =
  1136073600, 1136160000,
  1136160000, 1136246400,
  1136246400, 1136332800,
  1136332800, 1136419200,
  1136419200, 1136505600 ;

 OMAERUVd_003_FinalAerosolExtOpticalDepth388 =
  0.1611213, 0.3026592, 0.3159, _, _, _,
  0.3449308, _, _, 0.6037918, 0.5497, _,
  0.4340748, 0.4280727, _, _, _, _,
  _, 0.288, _, _, _, _,
  0.6101358, _, _, _, _, _ ;

 lon = 76.5, 77.5, 78.5, 79.5, 80.5, 81.5 ;

 time = 1136073600, 1136160000, 1136246400, 1136332800, 1136419200 ;
}
