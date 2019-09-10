
#!/usr/bin/perl -w

=head1 NAME

areaAveragerNco.t - Unit test script for areaAveragerNco.pl

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

areaAveragerNco.t [--help] [--verbose]

=head1 DESCRIPTION

The script areaAveragerNco.pl is a prgram that computes area averages using
NCO.  The weighting by latitude is applied in averaging.

=head1 OPTIONS

=over 4

=item --help
Print a usage information

=item --verbose
Turn on verbose mode

=back

=head1 AUTHOR

Jianfu Pan (jianfu.pan@nasa.gov)

=cut

use Test::More tests => 6;
use FindBin;

# These three nc files will be created as test data
my $ncfile = "areaAveragerNco_t.nc";

my $script = 'blib/script/areaAveragerNco.pl';
foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
    next if ( $dir =~ /^\s*$/ );
    last if ( -f $script );
    $script = "../$script";
}
ok( ( -f $script ), "Find $script" );

$ENV{PATH} = $ENV{PATH} . ":blib/lib";

# Create test data
my $rc   = create_test_data($ncfile);
my $bbox = "\"69.5,-2.5,93.5,14.5\"";

# Test existence of test nc files
ok( ( -f $ncfile ), "Created test nc file" );

# Test area averager
open( FH, ">areaaverager.in" )
    || die "ERROR Fail to create areaaverager.in tmp file";
print FH "$ncfile\n";
close(FH);

my $outfile = "areaaverager.test/areaAveragerNco_t.aavg.nc";
my $cmd
    = "perl -I blib/lib $script -i areaaverager.in -o areaaverager.test -b $bbox 2>&1 >/dev/null";
warn("running $cmd...\n");
`$cmd`;
ok( $? eq 0, "Script runs successfully" );
ok( ( -f $outfile ), "Area average file produced" );

# Test script results
my $output = `ncdump -v FinalAerosolAbsOpticalDepth500 $outfile`;
my ($result) = ( $output =~ /FinalAerosolAbsOpticalDepth500 = (.*);/gs );
$result =~ s/\s//g;
ok( $result eq "0.0185576765707603", "Checking data results" );

$output = `ncdump -v time $outfile`;
($result) = ( $output =~ /data:.*time = (.*);/gs );
$result =~ s/\s//g;
ok( $result eq "1230768000", "Checking time results" );

# Clean up
#unlink ($outfile, @$ncfiles, "areaaverager.in") unless $ENV{'SAVE_TEST_FILES'};
#rmdir("areaaverager.test") unless $ENV{'SAVE_TEST_FILES'};

exit(0);

#########################

sub create_test_data {
    my ($ncfile) = @_;

    # Read block at __DATA__ and write to a CDL file
    local ($/) = undef;
    my $ncdump = <DATA>;

    # Create nc files
    open( NC, ">ncdump.cdl" ) || die("ERROR Fail to create tmp cdl file");
    print NC $ncdump;
    `ncgen -b -o $ncfile ncdump.cdl`;
    close(NC);
    unlink "ncdump.cdl";

    return 1;
}

__DATA__
netcdf formatted_OMI-Aura_L3-OMAERUVd_2009m0101_v003-2011m1203t141114.he5 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lon = 25 ;
	lat = 18 ;
variables:
	int time(time) ;
		time:startValue = "2009-01-01T00:00:00Z" ;
		time:endValue = "2009-01-01T23:59:59Z" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float lon(lon) ;
		lon:grads_dim = "x" ;
		lon:grads_mapping = "linear" ;
		lon:grads_size = "360" ;
		lon:units = "degrees_east" ;
		lon:minimum = -180.f ;
		lon:maximum = 180.f ;
		lon:resolution = 1.f ;
	float lat(lat) ;
		lat:grads_dim = "y" ;
		lat:grads_mapping = "linear" ;
		lat:grads_size = "180" ;
		lat:units = "degrees_north" ;
		lat:long_name = "latitude" ;
		lat:minimum = -90.f ;
		lat:maximum = 90.f ;
		lat:resolution = 1.f ;
	float FinalAerosolAbsOpticalDepth500(time, lat, lon) ;
		FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
		FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
		FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
		FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
		FinalAerosolAbsOpticalDepth500:fonc_original_name = "_HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth500" ;
		FinalAerosolAbsOpticalDepth500:structureType = "Grid" ;
		FinalAerosolAbsOpticalDepth500:scale_factor = 1.f ;
		FinalAerosolAbsOpticalDepth500:add_offset = 0.f ;

// global attributes:
		:title = "NASA HDFEOS5 Grid" ;
		:Conventions = "CF-1.4" ;
		:start_time = "2009-01-01T00:00:00Z" ;
		:end_time = "2009-01-01T23:59:59Z" ;
		:dataType = "Grid" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Mon Apr 16 20:16:15 2012: ncatted -O -a history,global,d,c,, /var/scratch/hxiaopen/hegde_temp//formatted_OMI-Aura_L3-OMAERUVd_2009m0101_v003-2011m1203t141114.he5.nc" ;
data:

 time = 1230768000 ;

 lon = 69.5, 70.5, 71.5, 72.5, 73.5, 74.5, 75.5, 76.5, 77.5, 78.5, 79.5, 
    80.5, 81.5, 82.5, 83.5, 84.5, 85.5, 86.5, 87.5, 88.5, 89.5, 90.5, 91.5, 
    92.5, 93.5 ;

 lat = -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 
    10.5, 11.5, 12.5, 13.5, 14.5 ;

 FinalAerosolAbsOpticalDepth500 =
  0.0709, 0.0769, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _,
  0.0534, _, 0.0632, 0.0726, 0.0452, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _, _, _, _, 0.0719,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    0.0133, 0.0087,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, 0, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, 0, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0.0087, _, _, 
    _, _,
  _, _, _, 0, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, 0.0002, _, _, _, _, _, _, 0.0061, _, _, _, _, _, 0.0166, 
    0.0127, _, _, _, _, _, _,
  _, 0.0073, _, _, 0.0064, _, _, _, _, _, 0, 0.0109, 0.0007, _, _, _, _, _, 
    _, _, 0.0137, _, _, _, _,
  _, 0.0076, _, _, _, _, _, _, _, _, 0.0041, 0.0003, 0, _, _, _, _, _, _, 
    0.0499, 0.0604, 0.0751, _, _, _,
  _, 0.028, _, _, _, _, _, 0.0282, 0.0005, 0.0087, 0.0313, 0, 0.0013, _, _, 
    _, _, _, 0.0411, _, _, 0.0147, _, _, _,
  _, _, _, _, _, _, _, 0.0203, 0, 0, 0.012, 0.0071, _, 0.0852, _, _, _, _, _, 
    _, _, 0.0549, 0.0582, 0.0987, _,
  0.0101, _, 0.0335, 0.0338, _, _, _, 0.0037, 0, 0, 0, _, _, _, _, _, _, _, 
    _, _, _, 0.01, 0.0428, 0.0514, 0.0159,
  0.0078, _, 0.0117, 0.031, _, _, 0.041, 0.0009, 0.0001, 0, 0, _, _, _, _, _, 
    _, _, _, _, _, 0.0428, 0.0386, 0.0099, 0.0096,
  0.0082, _, 0.0114, 0.0121, _, _, 0.0047, 0, 0.0015, 0, 0, 0, _, _, _, _, _, 
    _, _, _, _, _, 0.0426, 0.0128, _,
  0.0074, 0.0096, 0.034, 0.0146, _, 0.0059, 0, 0, 0, 0.0001, 0, 0, _, _, _, 
    _, _, _, _, _, _, _, _, _, 0.0111,
  _, 0.0371, 0.0453, _, _, 0.0026, 0.0004, 0.0005, 0, 0.0004, 0, 0, _, _, _, 
    _, _, _, _, _, _, _, _, _, _ ;
}
