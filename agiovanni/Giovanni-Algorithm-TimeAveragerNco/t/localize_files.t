# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-TimeAveragerNco.t'

#########################

use Test::More tests => 3;

# Basic test of module call
BEGIN { use_ok('Giovanni::Algorithm::TimeAveragerNco') }

# Read input CDL
my $cdl = read_cdl_data();

my $datadir = 'staging';
mkdir($datadir) unless ( -d $datadir );

# Call a routine to write out the CDL, then convert to netcdf files
my $ncfile = write_netcdf( "$datadir/test.cdl", $cdl->[0] );

# Write out input file
my $input_file = 'files.txt';
write_file( $input_file, "$ncfile\n" );
my ( $symlink_file, @symlinks )
    = Giovanni::Algorithm::TimeAveragerNco::localize_files($input_file);
like( $symlinks[0], qr/ln....\/A0.nc/ );
unlink( $symlink_file, @symlinks ) unless $ENV{'SAVE_TEST_FILES'};

# Run it again to make sure we can overwrite symlinks
( $symlink_file, @symlinks )
    = Giovanni::Algorithm::TimeAveragerNco::localize_files($input_file);
like( $symlinks[0], qr/ln....\/A0.nc/ );

unlink( $input_file, $ncfile, $symlink_file, @symlinks )
    unless $ENV{'SAVE_TEST_FILES'};

#########################

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
netcdf formatted_MYD08_D3.A2009365.051.2010005030707.pscs_000500446339.hdf_MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean {
dimensions:
	time = UNLIMITED ; // (1 currently)
	Latitude = 38 ;
	Longitude = 3 ;
variables:
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	short MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, Latitude, Longitude) ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time Latitude Longitude" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Thickness at 0.55 microns for both Ocean (best) and Land (corrected): Mean" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999s ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:add_offset = 0. ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:scale_factor = 0.001 ;
		MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Aerosol Optical Depth" ;
	double Latitude(Latitude) ;
		Latitude:long_name = "Latitude" ;
		Latitude:units = "degrees_north" ;
	double Longitude(Longitude) ;
		Longitude:long_name = "Longitude" ;
		Longitude:units = "degrees_east" ;

// global attributes:
		:Conventions = "CF-1.4" ;
data:

 time = 1262217600 ;

 MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  _, _, _,
  200, 170, _,
  139, 132, 112,
  283, _, 360,
  253, 247, 211,
  289, 257, 255,
  367, 314, 280,
  368, 308, 262,
  _, 455, 314,
  475, 443, 420,
  515, 498, 482,
  564, 502, 415,
  650, 492, 434,
  676, 626, _,
  707, 632, 337,
  _, 329, 377 ;

 Latitude = 64.5, 63.5, 62.5, 61.5, 60.5, 59.5, 58.5, 57.5, 56.5, 55.5, 54.5, 
    53.5, 52.5, 51.5, 50.5, 49.5, 48.5, 47.5, 46.5, 45.5, 44.5, 43.5, 42.5, 
    41.5, 40.5, 39.5, 38.5, 37.5, 36.5, 35.5, 34.5, 33.5, 32.5, 31.5, 30.5, 
    29.5, 28.5, 27.5 ;

 Longitude = 116.5, 117.5, 118.5 ;
}
