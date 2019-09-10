# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-Wrapper.t'

#########################

# Use modules
use Test::More tests => 19;
use Giovanni::Data::NcFile;
use Giovanni::Testing;
use File::Temp;
BEGIN { use_ok('Giovanni::Algorithm::Wrapper'); }

# Find test algorithm scripts
my @script_paths
    = Giovanni::Testing::find_script_paths(
    qw(g4_ex_time_averager.pl g4_ex_area_avg_diff_time.pl giovanni_wrapper.pl)
    );

# Unit tests for semi-private utility functions
my $wordpat = '([\w\.\-\+]+)';
my $pathpat = '([\/\w\.\-\+]+)';
my $numpat  = '\-*[\d\.]+';
my $datepat
    = '([12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9][T ][012][0-9]:[0-5][0-9]:[0-5][0-9]\.*[0-9]*Z*)';
my @ans
    = Giovanni::Algorithm::Wrapper::extract_arg( '', 'program', qr($wordpat),
    1, 'program' => 'helloworld.pl' );
is( $ans[0], 'helloworld.pl' );
@ans = Giovanni::Algorithm::Wrapper::extract_arg( 'f', 'inputfiles',
    qr($pathpat), 1, 'inputfiles' => 'some/files-1.txt' );
is( $ans[1], 'some/files-1.txt' );
@ans
    = Giovanni::Algorithm::Wrapper::extract_arg( 'b', 'bbox',
    qr(($numpat,$numpat,$numpat,$numpat)),
    0, 'bbox' => "-162.,-34.,20,34.5" );
is( $ans[1], "-162.,-34.,20,34.5" );
@ans = Giovanni::Algorithm::Wrapper::extract_arg( 's', 'starttime',
    qr($datepat), 0, 'starttime' => '2001-11-30T23:59:59.9Z' );
is( $ans[1], '2001-11-30T23:59:59.9Z' );
@ans
    = Giovanni::Algorithm::Wrapper::extract_arg( 'v', 'verbose', qr(([0-9]+)),
    0, 'verbose' => 2 );
is( $ans[1], 2 );

my $cleanup = ( not exists $ENV{SAVEDIR} );
my $parent_dir = $ENV{'SAVEDIR'} || $ENV{'TMPDIR'} || '.';
my $datadir = File::Temp::tempdir( DIR => $parent_dir, CLEANUP => $cleanup );

my $code_file1 = $script_paths[0];
my $code_file2 = $script_paths[1];
my $wrapper    = $script_paths[2];

# Test matched_file_list()
my $mfst = "$datadir/mfst.test.xml";
open MFST, ">$mfst";
print MFST << 'EOF';
<?xml version="1.0"?>
<manifest><fileList id="TRMM_3B43_7_precipitation"><file>/giovanni/OPS/session/FA8B4E2C-C1C5-11E4-8091-C9F3B877C248/00AFF942-C1C6-11E4-B2CA-DF49D6A938E4/00B003C4-C1C6-11E4-B6D6-CB2A8221E2E1//scrubbed.TRMM_3B43_7_precipitation.20140501.nc</file><file>/giovanni/OPS/session/FA8B4E2C-C1C5-11E4-8091-C9F3B877C248/00AFF942-C1C6-11E4-B2CA-DF49D6A938E4/00B003C4-C1C6-11E4-B6D6-CB2A8221E2E1//scrubbed.TRMM_3B43_7_precipitation.20140601.nc</file></fileList>
<fileList id="GPM_3IMERGM_05_precipitation"><file>/giovanni/OPS/session/FA8B4E2C-C1C5-11E4-8091-C9F3B877C248/00AFF942-C1C6-11E4-B2CA-DF49D6A938E4/00B003C4-C1C6-11E4-B6D6-CB2A8221E2E1//scrubbed.GPM_3IMERGM_05_precipitation.20140501000000.nc</file><file>/giovanni/OPS/session/FA8B4E2C-C1C5-11E4-8091-C9F3B877C248/00AFF942-C1C6-11E4-B2CA-DF49D6A938E4/00B003C4-C1C6-11E4-B6D6-CB2A8221E2E1//scrubbed.GPM_3IMERGM_05_precipitation.20140601000000.nc</file></fileList></manifest>
EOF
close MFST;
my $match_list = "$datadir/match.test.txt";
open $fh, ">$match_list";
my ( $ra_infiles, $use_time )
    = Giovanni::Algorithm::Wrapper::matched_file_list( $mfst,
    "TRMM_3B43_7_precipitation", "GPM_3IMERGM_05_precipitation",
    $fh, $datadir, 1 );
close $fh;
ok( -s $match_list, "Match file $match_list found, non-zero size" );

#########################

# Read input and output CDL from __DATA__ section
my $ra_cdl = Giovanni::Data::NcFile::read_cdl_data_block();
my @cdl    = @$ra_cdl;

# Call a routine to write out the remaining input CDL,
# Then convert to netcdf files
my @ncfiles = map {
    my ($cdl_root) = ( $_ =~ /^netcdf\s+(.*?)\s+\{/ );
    Giovanni::Data::NcFile::write_netcdf_file( "$datadir/$cdl_root.nc", $_ )
} @cdl;

# TO DO:  Compare reference files
# Currently, we don't, but keep this step in here so as not to
# mess up the CDL file order
my $ref_file1 = shift @ncfiles;
unlink($ref_file1);

# my $ref_file2 = shift @ncfiles;

# Set arguments for 3D case
my $start       = "2009-01-17T00:00:00Z";
my $end         = "2009-01-19T23:59:59Z";
my $bbox        = '-148,47,-146,49';
my $outman_3d_1 = "$datadir/" . 'mfst.out_1var_3d.xml';
my $outman_3d_2 = "$datadir/" . 'mfst.out_comparison_3d.xml';

# Write driver file
my $infile_3d_1 = "$datadir/mfst.data_3d_1.xml";
write_input_manifest( $infile_3d_1, [ @ncfiles[ 0 .. 2 ] ] );
my $zfile_3d_1 = "$datadir/data_field_slice_3d_1.xml";
write_file( $zfile_3d_1,
    '<manifest><data zValue="850">AIRX3STD_006_Temperature_A</data></manifest>'
        . "\n" );

# Check z value parsing
my $zValue = Giovanni::Algorithm::Wrapper::get_zValue($zfile_3d_1);
is( $zValue, 850, "Parse z value" );

my $varinfo_3d_file1 = "$datadir/varinfo_3d_1.xml";
write_data_field_info( $varinfo_3d_file1, $ncfiles[0] );
my ( $zDimName, $zDimUnits )
    = Giovanni::Algorithm::Wrapper::get_zDim($varinfo_3d_file1);

# Check z dim info parsing
$zValue = Giovanni::Algorithm::Wrapper::get_zValue($zfile_3d_1);
is( $zDimUnits, "hPa",           "Parse Z dim units" );
is( $zDimName,  "TempPrsLvls_A", "Parse Z dim name" );

##########################################################
# RUN Single-Variable Algorithm
my $outnc_3d_1 = Giovanni::Algorithm::Wrapper::run(
    'program'          => $code_file1,
    'name'             => 'Test 3d Single Variable',
    'session-dir'      => $datadir,
    'output-file-root' => "$datadir/" . 'testSvc3d1',
    'bbox'             => $bbox,
    'starttime'        => $start,
    'endtime'          => $end,
    'variables'        => 'AIRX3STD_006_Temperature_A',
    'varfiles'         => $varinfo_3d_file1,
    'zfiles'           => $zfile_3d_1,
    'inputfiles'       => $infile_3d_1,
    'outfile'          => $outman_3d_1
);
ok( -e $outman_3d_1, "Output file $outman_3d_1 exists" );
ok( -e $outnc_3d_1,  "Output file $outnc_3d_1 exists" );
##########################################################
# RUN Comparison Algorithm
# Write driver file
my $infile_3d_2 = "$datadir/mfst.data_3d_2.xml";
write_input_manifest(
    $infile_3d_2,
    [ @ncfiles[ 0 .. 2 ] ],
    [ @ncfiles[ 3 .. 5 ] ]
);

my $zfile_3d_2 = "$datadir/data_field_slice_3d_2.xml";
write_file( $zfile_3d_2,
    '<manifest><data zValue="850">AIRX3STD_006_Temperature_D</data></manifest>'
        . "\n" );
my $varinfo_3d_file2 = "$datadir/varinfo_3d_2.xml";
write_data_field_info( $varinfo_3d_file2, $ncfiles[3] );

my $outnc_3d_2 = Giovanni::Algorithm::Wrapper::run(
    'program'          => $code_file2,
    'comparison'       => 'minus',
    'name'             => 'Test 3d Comparison',
    'session-dir'      => $datadir,
    'output-file-root' => "$datadir/" . 'testSvc3d2',
    'bbox'             => $bbox,
    'starttime'        => $start,
    'endtime'          => $end,
    'variables'  => 'AIRX3STD_006_Temperature_A,AIRX3STD_006_Temperature_D',
    'inputfiles' => $infile_3d_2,
    'platform_instrument' => 'AIRS',
    'zfiles'              => "$zfile_3d_1,$zfile_3d_2",
    'varfiles'            => "$varinfo_3d_file1,$varinfo_3d_file2",
    'outfile'             => $outman_3d_2
);
ok( -e $outman_3d_2, "Output file $outman_3d_2 exists" );
ok( -e $outnc_3d_2,  "Output file $outnc_3d_2 exists" );
##########################################################
# 2-D variables (TRMM), single-variable case
$bbox = '42,-20,43,-19';
##########################################################
# 2-D variable, single-variable case
# Run from command line

my $zfile_2d_1 = "$datadir/data_field_slice_2d_1.xml";
write_file( $zfile_2d_1,
    '<manifest><data zValue="NA">TRMM_3B42_daily_precipitation_V6</data></manifest>'
        . "\n" );
my $varinfo_2d_file1 = "$datadir/varinfo_2d_1.xml";
write_data_field_info( $varinfo_2d_file1, $ncfiles[6] );
my $infile_2d_1 = "$datadir/mfst.data_2d_1.xml";
write_input_manifest( $infile_2d_1, [ @ncfiles[ 6 .. 8 ] ] );
my $outman_2d_1 = "$datadir/" . 'mfst.out_1var_2d.xml';
my %args        = (
    'program'             => $code_file1,
    'name'                => 'Test 2d Single Variable',
    'session-dir'         => $datadir,
    'output-file-root'    => "$datadir/" . 'testSvc2d1',
    'bbox'                => $bbox,
    'starttime'           => $start,
    'endtime'             => $end,
    'variables'           => 'TRMM_3B42_daily_precipitation_V6',
    'inputfiles'          => $infile_2d_1,
    'zfiles'              => "$zfile_2d_1",
    'platform_instrument' => 'TRMM',
    'varfiles'            => "$varinfo_2d_file1",
    'outfile'             => $outman_2d_1
);
my $outnc_2d_1
    = "$datadir/testSvc2d1.TRMM_3B42_daily_precipitation_V6.20090117-20090119.42E_20S_43E_19S.nc";
my @args = map { ( '--' . $_, $args{$_} ) } sort keys %args;
warn( "INFO Running program " . join( ' ', $wrapper, @args ) . "\n" );
my $rc = system( $wrapper, @args );

is( $rc, 0, "Run 2-D single-variable from command line" );
ok( -e $outman_2d_1, "Output file $outman_2d_1 exists" );
ok( -e $outnc_2d_1,  "Output file $outnc_2d_1 exists" );

# 2-D variable, comparison case

my $zfile_2d_2 = "$datadir/data_field_slice_2d_2.xml";
write_file( $zfile_2d_2,
    '<manifest><data zValue="NA">TRMM_3B42_daily_precipitation_V7</data></manifest>'
        . "\n" );
my $varinfo_2d_file2 = "$datadir/varinfo_2d_2.xml";
write_data_field_info( $varinfo_2d_file2, $ncfiles[9] );
my $infile_2d_2 = "$datadir/mfst.data_2d_2.xml";
write_input_manifest(
    $infile_2d_2,
    [ @ncfiles[ 6 .. 8 ] ],
    [ @ncfiles[ 9 .. 11 ] ]
);
my $outman_2d_2 = "$datadir/" . 'mfst.out_comparison_2d.xml';

my $outnc_2d_2 = Giovanni::Algorithm::Wrapper::run(
    'program'          => $code_file2,
    'comparison'       => 'minus',
    'name'             => 'Test 2d Comparison',
    'output-file-root' => "$datadir/" . 'testSvc2d2',
    'session-dir'      => $datadir,
    'bbox'             => $bbox,
    'starttime'        => $start,
    'endtime'          => $end,
    'variables' =>
        'TRMM_3B42_daily_precipitation_V6,TRMM_3B42_daily_precipitation_V7',
    'inputfiles'          => $infile_2d_2,
    'zfiles'              => "$zfile_2d_1,$zfile_2d_2",
    'varfiles'            => "$varinfo_2d_file1,$varinfo_2d_file2",
    'platform_instrument' => 'TRMM',
    'outfile'             => $outman_2d_2
);
ok( -e $outman_2d_2, "Output file $outman_2d_2 exists" );
ok( -e $outnc_2d_2,  "Output file $outnc_2d_2 exists" );

# Cleanup
unless ( exists( $ENV{CLEANUP} ) && $ENV{CLEANUP} == 0 ) {
    warn "Cleaning up...\n";
    my @outmans = ( $outman_3d_1, $outman_3d_2, $outman_2d_1, $outman_2d_2 );
    unlink(@outmans);
    my @logfiles = @outmans;
    map { $_ =~ s/\.xml$/.log/ } @logfiles;
    unlink(@logfiles);
    my @provfiles = @outmans;
    map { $_ =~ s/mfst\./prov./ } @provfiles;
    unlink(@provfiles);
    unlink( $infile_3d_1, $infile_3d_2, $outnc_3d_1, $outnc_3d_2 );
    unlink( $infile_2d_1, $infile_2d_2, $outnc_2d_1, $outnc_2d_2 );
    unlink( $zfile_3d_1,  $zfile_3d_2 );
    unlink( $zfile_2d_1,  $zfile_2d_2 );
    unlink( $varinfo_3d_file1, $varinfo_3d_file2 );
    unlink( $varinfo_2d_file1, $varinfo_2d_file2 );
    map { warn( unlink($_) ? "Cleaned $_\n" : "Failed to unlink $_\n" ) }
        @ncfiles;
}
exit(0);
##########################################################
sub write_file {
    my ( $path, $string ) = @_;
    open OUT, '>', $path or die("Cannot write to $path");
    print OUT $string;
    close OUT;
    return $path;
}

sub write_data_field_info {
    my ( $path, $ncfile, %args ) = @_;
    require Giovanni::Data::NcFile;

# FILE MUST BE ALREADY SCRUBBED!!!
# This relies on a lot of assumptions...
# Also, a lot of attributes are hard coded for now as they do not (usually) affect
# the algorithms using this framework for unit testing

    # Fetch plottable variable and its attributes
    # ASSUME one plottable variable
    my ($var_id)
        = Giovanni::Data::NcFile::get_plottable_variables( $ncfile, 0 );
    my ( $rh_attrs, @attrs )
        = Giovanni::Data::NcFile::variable_attributes( $ncfile, $var_id, 1 );
    my %attrs = %$rh_attrs;
    my @coords = split( ' ', $attrs{coordinates} );
    my ( $zDimName, $zDimUnits );

    # Look for Z coordinate
    # ASSUME coordinate order: time <z> lat lon
    if ( scalar(@coords) > 3 ) {
        $zDimName = $coords[1];

        # Fetch Z coordinate attributes to get units
        my ( $rh_zattrs, @zattrs )
            = Giovanni::Data::NcFile::variable_attributes( $ncfile, $zDimName,
            1 );
        $zDimUnits = $rh_zattrs->{units};
    }

    # Ready to write:  open the stream
    unless ( open( OUT, '>', $path ) ) {
        die "Cannot write to $path: $!\n";
    }
    my $short_name = $attrs{product_short_name};
    my $source;
    if ( $short_name =~ /^TRMM/ ) {
        $source = 'TRMM';
    }
    elsif ( $short_name =~ /^AIR/ ) {
        $source = 'AIRS';
    }
    elsif ( $short_name =~ /^MOD/ ) {
        $source = 'MODIS-Terra';
    }
    elsif ( $short_name =~ /^MYD/ ) {
        $source = 'MODIS-Aqua';
    }
    print OUT "<varList>\n";
    print OUT " <var id=\"$var_id\"";
    print OUT " zDimUnits=\"$zDimUnits\" zDimName=\"$zDimName\""
        if ($zDimUnits);
    print OUT ' dataProductBeginDateTime="2000-01-01T00:00:00Z"';
    print OUT ' dataProductEndDateTime="2038-01-19T03:14:07Z"';
    print OUT " long_name=\"$attrs{long_name}\"";
    print OUT " dataFieldUnitsValue=\"$attrs{units}\""
        if ( exists( $attrs{units} ) );
    print OUT
        ' fillValueFieldName="_FillValue" accessFormat="netCDF" accessMethod="OPeNDAP" dataProductStartTimeOffset="1"';
    print OUT ' url="http://dont.use.this.url.for.anything"';
    print OUT ' north="90.0" south="-90.0" west="-180.0" east="180.0"';
    print OUT ' sdsName="DONT_USE_THIS"';
    print OUT " dataProductShortName=\"$attrs{product_short_name}\"";
    print OUT " dataProductVersion=\"$attrs{product_version}\"";
    print OUT " dataProductPlatformInstrument=\"$source\"" if ($source);
    print OUT ' dataProductTimeInterval="daily"';
    print OUT ' dataProductEndTimeOffset="-1"';
    print OUT ' resolution="1 x 1 deg."';
    print OUT ' dataFieldStandardName="foo"';
    print OUT ">\n";
    print OUT
        ' <slds><sld url="http://s4ptu-ts1.ecs.nasa.gov/giovanni/sld/divergent_rdylbu_10_sld.xml" label="Red-yellow-blue Color Map"/></slds>'
        . "\n";
    print OUT " </var>";
    print OUT "</varList>\n";
    close(OUT) or die "Failed to close file $path: $!\n";
}

sub write_input_manifest {
    my ( $path, @ra_ncfiles ) = @_;

    # Find the plottable variable
    open OUT, '>', $path or die "Could not open $path: $!\n";
    print OUT '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
    print OUT '<manifest>' . "\n";
    foreach my $ra_ncfiles (@ra_ncfiles) {
        my @ncfiles = @$ra_ncfiles;
        my ($var_id)
            = Giovanni::Data::NcFile::get_plottable_variables( $ncfiles[0],
            0 );

        # Get short name, version, long name arguments
        my ( $rh_attrs, $ra_attrs )
            = Giovanni::Data::NcFile::variable_attributes( $ncfiles[0],
            $var_id, 1 );
        print OUT
            "  <fileList id=\"$var_id\" dataProductShortName=\"$rh_attrs->{product_short_name}\" dataProductVersion=\"$rh_attrs->{product_version}\" long_name=\"$rh_attrs->{long_name}\">\n";
        map { printf OUT "    <file>%s</file>\n", $_ } @ncfiles;
        print OUT "  </fileList>\n";
    }
    print OUT "</manifest>\n";
    close OUT;
}

__DATA__
netcdf out1 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_A = 1 ;
	lat = 2 ;
	lon = 2 ;
variables:
	float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_A:units = "K" ;
		AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
		AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:Serializable = "True" ;
	float TempPrsLvls_A(TempPrsLvls_A) ;
		TempPrsLvls_A:standard_name = "Pressure" ;
		TempPrsLvls_A:long_name = "Pressure Levels Temperature Profile, daytime (ascending) node" ;
		TempPrsLvls_A:units = "hPa" ;
		TempPrsLvls_A:positive = "down" ;
		TempPrsLvls_A:_CoordinateAxisType = "GeoZ" ;
	int dataday(time) ;
		dataday:standard_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:_FillValue = -9999.f ;
		lat:long_name = "Latitude" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
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
		:start_time = "2009-01-17T00:00:00Z" ;
		:end_time = "2009-01-17T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.2.1" ;
		:history = "Thu Feb 13 14:59:00 2014: ncra -O -o out.nc -d lat,47.000000,49.000000 -d lon,-148.000000,-146.000000 -d TempPrsLvls_A,850.000000,850.000000\n",
			"Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_A.20090117.nc ss.scrubbed.AIRX3STD_006_Temperature_A.20090117.nc" ;
		:nco_input_file_number = 3 ;
		:nco_input_file_list = "ss.scrubbed.AIRX3STD_006_Temperature_A.20090117.nc ss.scrubbed.AIRX3STD_006_Temperature_A.20090118.nc ss.scrubbed.AIRX3STD_006_Temperature_A.20090119.nc" ;
data:

 AIRX3STD_006_Temperature_A =
  272.4375, 272.6042,
  272.4583, 273.0417 ;

 TempPrsLvls_A = 850 ;

 dataday = 2009018 ;

 lat = 47.5, 48.5 ;

 lon = -147.5, -146.5 ;

 time = 1232236800 ;
}
netcdf ss.scrubbed.AIRX3STD_006_Temperature_A.20090117 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_A = 24 ;
	lat = 2 ;
	lon = 2 ;
variables:
	float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_A:units = "K" ;
		AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
		AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:Serializable = "True" ;
	float TempPrsLvls_A(TempPrsLvls_A) ;
		TempPrsLvls_A:standard_name = "Pressure" ;
		TempPrsLvls_A:long_name = "Pressure Levels Temperature Profile, daytime (ascending) node" ;
		TempPrsLvls_A:units = "hPa" ;
		TempPrsLvls_A:positive = "down" ;
		TempPrsLvls_A:_CoordinateAxisType = "GeoZ" ;
	int dataday(time) ;
		dataday:standard_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:_FillValue = -9999.f ;
		lat:long_name = "Latitude" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
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
		:start_time = "2009-01-17T00:00:00Z" ;
		:end_time = "2009-01-17T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.2.1" ;
		:history = "Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_A.20090117.nc ss.scrubbed.AIRX3STD_006_Temperature_A.20090117.nc" ;
data:

 AIRX3STD_006_Temperature_A =
  _, _,
  _, _,
  278.125, 278.5625,
  278.1875, 278.4375,
  275.1875, 275.5,
  275.25, 275.6875,
  267.0625, 267.875,
  268.125, 268.4375,
  261.0625, 262.25,
  262.625, 263.3125,
  252.5938, 254.25,
  254.0938, 255.3438,
  242.8125, 244.0938,
  243.5312, 244.9688,
  236, 234.6875,
  235.125, 235.0938,
  234.7812, 233.5938,
  233.75, 233.3438,
  232.125, 232.125,
  231.4688, 231.2812,
  224.625, 224.2812,
  224.5312, 223.9375,
  215.875, 214.625,
  215.7812, 214.875,
  215.0312, 214.1562,
  214.9375, 214.25,
  216.9688, 216.5312,
  216.9062, 216.375,
  218.0625, 217.8125,
  218.5938, 218.125,
  220.6562, 220.25,
  220.6562, 220.4375,
  222.7812, 222.375,
  222.25, 221.9688,
  226.4688, 226.3438,
  225.6875, 225.25,
  231.8438, 231.9375,
  230.8125, 230.4375,
  238.375, 238.5,
  237.6875, 237.5,
  247.25, 247.0938,
  247.2812, 247.1875,
  253.5312, 252.875,
  253.8125, 253.1875,
  253.375, 252.6875,
  253.125, 252.625,
  248.2812, 248.0312,
  247.3438, 247.5312 ;

 TempPrsLvls_A = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009017 ;

 lat = 47.5, 48.5 ;

 lon = -147.5, -146.5 ;

 time = 1232150400 ;
}
netcdf ss.scrubbed.AIRX3STD_006_Temperature_A.20090118 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_A = 24 ;
	lat = 2 ;
	lon = 2 ;
variables:
	float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_A:units = "K" ;
		AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
		AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:Serializable = "True" ;
	float TempPrsLvls_A(TempPrsLvls_A) ;
		TempPrsLvls_A:standard_name = "Pressure" ;
		TempPrsLvls_A:long_name = "Pressure Levels Temperature Profile, daytime (ascending) node" ;
		TempPrsLvls_A:units = "hPa" ;
		TempPrsLvls_A:positive = "down" ;
		TempPrsLvls_A:_CoordinateAxisType = "GeoZ" ;
	int dataday(time) ;
		dataday:standard_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:_FillValue = -9999.f ;
		lat:long_name = "Latitude" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
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
		:start_time = "2009-01-18T00:00:00Z" ;
		:end_time = "2009-01-18T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.2.1" ;
		:history = "Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_A.20090118.nc ss.scrubbed.AIRX3STD_006_Temperature_A.20090118.nc" ;
data:

 AIRX3STD_006_Temperature_A =
  279.25, 279.75,
  278.375, 280.1875,
  274.625, 274.5,
  274.25, 275.75,
  272.5, 271.875,
  272.4375, 274,
  263.625, 263.5625,
  264.4375, 265.4375,
  254.125, 254.9688,
  254.5, 255.9375,
  244.9062, 245.6875,
  244.8438, 246.4688,
  236.875, 237.3438,
  237.2812, 237.5938,
  232.2812, 232.375,
  233.1875, 233.125,
  232.4688, 232.7812,
  232.6875, 233.75,
  231.7812, 231.9062,
  231.5, 232.3125,
  226.5, 226.125,
  226.1562, 225.25,
  219.7188, 219.0625,
  219.9375, 218.25,
  218.0938, 217.5312,
  218.1875, 217.1562,
  218.1562, 217.5,
  218.2812, 217.875,
  217.6875, 217.1875,
  217.4062, 217.25,
  218.1562, 217.6875,
  217.9375, 217.4062,
  219.5, 219,
  219.4375, 218.5938,
  223.8438, 223.375,
  223.8438, 222.6875,
  230.8125, 230.5312,
  230.8438, 230.2812,
  239.25, 239.1875,
  238.8125, 239.4062,
  247.4375, 247.5938,
  246.5938, 246.75,
  249.5, 249.0312,
  248.75, 248.25,
  248.625, 248.1562,
  248.0938, 247.625,
  244.875, 244.875,
  244.6875, 244.4375 ;

 TempPrsLvls_A = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009018 ;

 lat = 47.5, 48.5 ;

 lon = -147.5, -146.5 ;

 time = 1232236800 ;
}
netcdf ss.scrubbed.AIRX3STD_006_Temperature_A.20090119 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_A = 24 ;
	lat = 2 ;
	lon = 2 ;
variables:
	float AIRX3STD_006_Temperature_A(time, TempPrsLvls_A, lat, lon) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, daytime (ascending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_A:units = "K" ;
		AIRX3STD_006_Temperature_A:missing_value = -9999.f ;
		AIRX3STD_006_Temperature_A:coordinates = "time TempPrsLvls_A lat lon" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:Serializable = "True" ;
	float TempPrsLvls_A(TempPrsLvls_A) ;
		TempPrsLvls_A:standard_name = "Pressure" ;
		TempPrsLvls_A:long_name = "Pressure Levels Temperature Profile, daytime (ascending) node" ;
		TempPrsLvls_A:units = "hPa" ;
		TempPrsLvls_A:positive = "down" ;
		TempPrsLvls_A:_CoordinateAxisType = "GeoZ" ;
	int dataday(time) ;
		dataday:standard_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:_FillValue = -9999.f ;
		lat:long_name = "Latitude" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
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
		:start_time = "2009-01-19T00:00:00Z" ;
		:end_time = "2009-01-19T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.2.1" ;
		:history = "Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_A.20090119.nc ss.scrubbed.AIRX3STD_006_Temperature_A.20090119.nc" ;
data:

 AIRX3STD_006_Temperature_A =
  277.25, 277.4375,
  277.5625, 276.5625,
  272.25, 272.75,
  272.5625, 271.4375,
  269.625, 270.4375,
  269.6875, 269.4375,
  262.9375, 263.1875,
  262.4375, 263.0625,
  253.8438, 253.9688,
  253.6875, 254.4062,
  244.1875, 244.1875,
  243.375, 243.625,
  234.5625, 234.3438,
  233.75, 233.5625,
  230.6562, 231.0625,
  231.0938, 231.2812,
  229.5, 230.5938,
  229.8438, 230.875,
  229.3438, 230.375,
  229.5312, 230.4062,
  226.0312, 226.25,
  226.2188, 226.4375,
  218.6875, 218.0625,
  219.375, 218.7188,
  217.125, 216.5625,
  217.7812, 216.8125,
  217.4688, 216.9375,
  217.5625, 216.7812,
  217.1562, 216.5312,
  216.9062, 216.5625,
  217.75, 217.0312,
  218.0312, 217.25,
  219.125, 218.375,
  219.6875, 218.5938,
  222.8125, 222.3125,
  223.5, 222.625,
  229.0938, 228.25,
  229.9688, 228.5,
  236.5938, 235.5,
  236.9688, 235.25,
  241.375, 240.625,
  240.0938, 239.7812,
  241.0312, 240.6562,
  239.0625, 239.5938,
  240.6875, 240.625,
  238.8125, 239.5,
  240.9688, 241.1562,
  239.8438, 240.4062 ;

 TempPrsLvls_A = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009019 ;

 lat = 47.5, 48.5 ;

 lon = -147.5, -146.5 ;

 time = 1232323200 ;
}
netcdf ss.scrubbed.AIRX3STD_006_Temperature_D.20090117 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_D = 24 ;
	lat = 2 ;
	lon = 2 ;
variables:
	float AIRX3STD_006_Temperature_D(time, TempPrsLvls_D, lat, lon) ;
		AIRX3STD_006_Temperature_D:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_D:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_D:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, nighttime (descending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_D:units = "K" ;
		AIRX3STD_006_Temperature_D:missing_value = -9999.f ;
		AIRX3STD_006_Temperature_D:coordinates = "time TempPrsLvls_D lat lon" ;
		AIRX3STD_006_Temperature_D:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_D:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_D:product_version = "006" ;
		AIRX3STD_006_Temperature_D:Serializable = "True" ;
	float TempPrsLvls_D(TempPrsLvls_D) ;
		TempPrsLvls_D:standard_name = "Pressure" ;
		TempPrsLvls_D:long_name = "Pressure Levels Temperature Profile, nighttime (descending) node" ;
		TempPrsLvls_D:units = "hPa" ;
		TempPrsLvls_D:positive = "down" ;
		TempPrsLvls_D:_CoordinateAxisType = "GeoZ" ;
	int dataday(time) ;
		dataday:standard_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:_FillValue = -9999.f ;
		lat:long_name = "Latitude" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
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
		:start_time = "2009-01-17T00:00:00Z" ;
		:end_time = "2009-01-17T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.2.1" ;
		:history = "Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_D.20090117.nc ss.scrubbed.AIRX3STD_006_Temperature_D.20090117.nc" ;
data:

 AIRX3STD_006_Temperature_D =
  _, _,
  _, _,
  280.5, 281.125,
  280.4375, 280.1875,
  276.6875, 276.8125,
  276.6875, 275.375,
  267.75, 269.6875,
  268.0625, 269,
  260.375, 263.625,
  260.5, 262.8125,
  251.5312, 254.9375,
  251.1875, 253.9062,
  239.5938, 241.9062,
  239.5312, 241.6562,
  232.9375, 232.6562,
  232.5938, 232.9375,
  234.4062, 234.3125,
  233.7812, 234.0625,
  233.9688, 234.3125,
  233.9375, 233.9062,
  226, 225.9062,
  226.5938, 225.5312,
  214.5312, 213.4062,
  214.6562, 213.7188,
  214, 213.1562,
  214.0938, 213.5312,
  215.9688, 215.5312,
  216.2188, 215.5312,
  218.5, 218.3438,
  218.6875, 218.2188,
  221.3125, 220.9062,
  221.5625, 220.9688,
  222.75, 222.1562,
  222.9375, 222.2188,
  225.4375, 224.9062,
  225.0938, 224.4375,
  229.875, 230.125,
  229.0312, 228.7812,
  236.2812, 236.7812,
  234.9062, 235,
  245.3125, 245,
  244.5312, 244.2188,
  252.9375, 252.375,
  252.9062, 252.25,
  252.6875, 252.125,
  252.6562, 252.1875,
  246.4062, 245.9375,
  246.0312, 245.9062 ;

 TempPrsLvls_D = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009017 ;

 lat = 47.5, 48.5 ;

 lon = -147.5, -146.5 ;

 time = 1232150400 ;
}
netcdf ss.scrubbed.AIRX3STD_006_Temperature_D.20090118 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_D = 24 ;
	lat = 2 ;
	lon = 2 ;
variables:
	float AIRX3STD_006_Temperature_D(time, TempPrsLvls_D, lat, lon) ;
		AIRX3STD_006_Temperature_D:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_D:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_D:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, nighttime (descending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_D:units = "K" ;
		AIRX3STD_006_Temperature_D:missing_value = -9999.f ;
		AIRX3STD_006_Temperature_D:coordinates = "time TempPrsLvls_D lat lon" ;
		AIRX3STD_006_Temperature_D:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_D:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_D:product_version = "006" ;
		AIRX3STD_006_Temperature_D:Serializable = "True" ;
	float TempPrsLvls_D(TempPrsLvls_D) ;
		TempPrsLvls_D:standard_name = "Pressure" ;
		TempPrsLvls_D:long_name = "Pressure Levels Temperature Profile, nighttime (descending) node" ;
		TempPrsLvls_D:units = "hPa" ;
		TempPrsLvls_D:positive = "down" ;
		TempPrsLvls_D:_CoordinateAxisType = "GeoZ" ;
	int dataday(time) ;
		dataday:standard_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:_FillValue = -9999.f ;
		lat:long_name = "Latitude" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
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
		:start_time = "2009-01-18T00:00:00Z" ;
		:end_time = "2009-01-18T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.2.1" ;
		:history = "Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_D.20090118.nc ss.scrubbed.AIRX3STD_006_Temperature_D.20090118.nc" ;
data:

 AIRX3STD_006_Temperature_D =
  _, _,
  _, _,
  276.625, 277.3125,
  276.1875, 277.25,
  273.0625, 273.8125,
  273.25, 274.125,
  265.375, 264.9375,
  265.875, 265.5625,
  255.8438, 255.875,
  256.625, 256.625,
  246, 247.375,
  246.6875, 248.1562,
  237.375, 239.0625,
  238.0312, 240.25,
  235.2812, 234.5,
  235.1875, 234.75,
  235.8125, 235.3125,
  235.375, 234.625,
  233.3438, 233.8125,
  233.2188, 232.5938,
  226, 225.6562,
  225.9062, 225.4375,
  218.5938, 217.5,
  218.3438, 217.625,
  218.0938, 216.8438,
  218.0312, 216.7812,
  217.7812, 217.2188,
  217.75, 217.0625,
  218.4062, 218.3438,
  218.2188, 217.6875,
  218.9375, 218.375,
  218.9062, 218.625,
  219.8125, 218.9688,
  219.875, 219.7188,
  224.625, 223.9375,
  224.5938, 223.8438,
  230.9375, 231.3125,
  230.3125, 229.875,
  239.2188, 239.9375,
  238.2188, 238.1875,
  250.0312, 249.3125,
  249.625, 249.6562,
  251.5312, 250.4062,
  252.0312, 251.0312,
  249.1562, 248.1875,
  249.8125, 248.5312,
  243.375, 243,
  243.625, 243.0938 ;

 TempPrsLvls_D = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009018 ;

 lat = 47.5, 48.5 ;

 lon = -147.5, -146.5 ;

 time = 1232236800 ;
}
netcdf ss.scrubbed.AIRX3STD_006_Temperature_D.20090119 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	TempPrsLvls_D = 24 ;
	lat = 2 ;
	lon = 2 ;
variables:
	float AIRX3STD_006_Temperature_D(time, TempPrsLvls_D, lat, lon) ;
		AIRX3STD_006_Temperature_D:_FillValue = -9999.f ;
		AIRX3STD_006_Temperature_D:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_D:long_name = "Atmospheric Temperature Profile, 1000 to 1 hPa, nighttime (descending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_D:units = "K" ;
		AIRX3STD_006_Temperature_D:missing_value = -9999.f ;
		AIRX3STD_006_Temperature_D:coordinates = "time TempPrsLvls_D lat lon" ;
		AIRX3STD_006_Temperature_D:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_D:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_D:product_version = "006" ;
		AIRX3STD_006_Temperature_D:Serializable = "True" ;
	float TempPrsLvls_D(TempPrsLvls_D) ;
		TempPrsLvls_D:standard_name = "Pressure" ;
		TempPrsLvls_D:long_name = "Pressure Levels Temperature Profile, nighttime (descending) node" ;
		TempPrsLvls_D:units = "hPa" ;
		TempPrsLvls_D:positive = "down" ;
		TempPrsLvls_D:_CoordinateAxisType = "GeoZ" ;
	int dataday(time) ;
		dataday:standard_name = "Standardized Date Label" ;
	float lat(lat) ;
		lat:_FillValue = -9999.f ;
		lat:long_name = "Latitude" ;
		lat:missing_value = -9999.f ;
		lat:standard_name = "latitude" ;
		lat:units = "degrees_north" ;
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
		:start_time = "2009-01-19T00:00:00Z" ;
		:end_time = "2009-01-19T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.2.1" ;
		:history = "Mon Jul  1 13:59:57 2013: ncks -d lat,47.,49. -d lon,-148.,-146. scrubbed.AIRX3STD_006_Temperature_D.20090119.nc ss.scrubbed.AIRX3STD_006_Temperature_D.20090119.nc" ;
data:

 AIRX3STD_006_Temperature_D =
  277.1875, 277.9375,
  277.5625, 277.125,
  271.875, 272.5625,
  272.375, 272.0625,
  269.625, 269.9375,
  270.3125, 269.8125,
  262.6875, 263.0625,
  263.25, 263.1875,
  254.125, 254.9688,
  254.4688, 254.9688,
  244, 245.1875,
  244.6562, 245.2812,
  233.375, 234.5,
  234.1562, 235,
  231.2188, 231.9375,
  231.2188, 232.0312,
  232.1562, 232.9688,
  231.7812, 232.4688,
  231.8438, 232.2812,
  231.4688, 231.7188,
  227.2188, 226.625,
  226.9062, 226.4375,
  219.25, 218.25,
  219.3125, 218.4375,
  217.9062, 217.3438,
  218.4688, 217.75,
  217.9062, 217.375,
  218.0938, 217.6875,
  218.2812, 217.5625,
  218.2188, 217.6562,
  218.4062, 218.0625,
  218.1875, 217.75,
  218.875, 218.7812,
  218.8438, 218.375,
  223.2188, 223.2188,
  223.0938, 222.5,
  230.0625, 230.0625,
  229.6875, 229.125,
  239.1875, 238.8125,
  238.5312, 237.9375,
  247.8125, 245.6875,
  247.1562, 246,
  247.4688, 245.375,
  247.125, 246.25,
  245.0625, 243.2812,
  244.8125, 244.0625,
  240.875, 239.9688,
  240.6875, 240.2812 ;

 TempPrsLvls_D = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;

 dataday = 2009019 ;

 lat = 47.5, 48.5 ;

 lon = -147.5, -146.5 ;

 time = 1232323200 ;
}
netcdf ss.scrubbed.TRMM_3B42_daily_precipitation_V6.20090117 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 4 ;
variables:
	float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
		TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
		TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
		TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
		TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
		TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
		TRMM_3B42_daily_precipitation_V6:long_name = "Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg." ;
		TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
		TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
		TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
		TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
		TRMM_3B42_daily_precipitation_V6:units = "mm" ;
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
		:start_time = "2009-01-16T22:30:00Z" ;
		:end_time = "2009-01-17T22:29:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb 15 21:29:02 2014: ncks -d lat,-20.0,-19.0 -d lon,42.,43. scrubbed.TRMM_3B42_daily_precipitation_V6.20090117.nc ss.scrubbed.TRMM_3B42_daily_precipitation_V6.20090117.nc" ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  63.69, 81.45, 74.22, 54,
  93.27, 75.45, 51.42, 58.86,
  57.3, 46.14, 50.04, 43.47,
  65.61, 45.6, 35.37, 67.46999 ;

 dataday = 2009017 ;

 lat = -19.875, -19.625, -19.375, -19.125 ;

 lon = 42.125, 42.375, 42.625, 42.875 ;

 time = 1232145000 ;
}
netcdf ss.scrubbed.TRMM_3B42_daily_precipitation_V6.20090118 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 4 ;
variables:
	float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
		TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
		TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
		TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
		TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
		TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
		TRMM_3B42_daily_precipitation_V6:long_name = "Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg." ;
		TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
		TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
		TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
		TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
		TRMM_3B42_daily_precipitation_V6:units = "mm" ;
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
		:start_time = "2009-01-17T22:30:00Z" ;
		:end_time = "2009-01-18T22:29:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb 15 21:29:02 2014: ncks -d lat,-20.0,-19.0 -d lon,42.,43. scrubbed.TRMM_3B42_daily_precipitation_V6.20090118.nc ss.scrubbed.TRMM_3B42_daily_precipitation_V6.20090118.nc" ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  48.54, 44.16, 30.15, 25.95,
  34.98, 31.17, 22.38, 17.13,
  25.17, 23.43, 23.31, 22.53,
  28.38, 36.44999, 32.49, 22.71 ;

 dataday = 2009018 ;

 lat = -19.875, -19.625, -19.375, -19.125 ;

 lon = 42.125, 42.375, 42.625, 42.875 ;

 time = 1232231400 ;
}
netcdf ss.scrubbed.TRMM_3B42_daily_precipitation_V6.20090119 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 4 ;
variables:
	float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
		TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
		TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
		TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
		TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
		TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
		TRMM_3B42_daily_precipitation_V6:long_name = "Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg." ;
		TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
		TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
		TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
		TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
		TRMM_3B42_daily_precipitation_V6:units = "mm" ;
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
		:start_time = "2009-01-18T22:30:00Z" ;
		:end_time = "2009-01-19T22:29:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb 15 21:29:03 2014: ncks -d lat,-20.0,-19.0 -d lon,42.,43. scrubbed.TRMM_3B42_daily_precipitation_V6.20090119.nc ss.scrubbed.TRMM_3B42_daily_precipitation_V6.20090119.nc" ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  35.52, 43.41, 46.26, 40.2,
  34.53, 51.18, 55.11, 39.3,
  57.06, 69.72, 39.36, 42.27,
  65.13, 48.33, 45.63, 27.57 ;

 dataday = 2009019 ;

 lat = -19.875, -19.625, -19.375, -19.125 ;

 lon = 42.125, 42.375, 42.625, 42.875 ;

 time = 1232317800 ;
}
netcdf ss.scrubbed.TRMM_3B42_daily_precipitation_V7.20090117 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 4 ;
variables:
	float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
		TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
		TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
		TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
		TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
		TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
		TRMM_3B42_daily_precipitation_V7:long_name = "Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg." ;
		TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
		TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
		TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
		TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
		TRMM_3B42_daily_precipitation_V7:units = "mm" ;
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
		:start_time = "2009-01-16T22:30:00Z" ;
		:end_time = "2009-01-17T22:29:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb 15 21:29:04 2014: ncks -d lat,-20.0,-19.0 -d lon,42.,43. scrubbed.TRMM_3B42_daily_precipitation_V7.20090117.nc ss.scrubbed.TRMM_3B42_daily_precipitation_V7.20090117.nc" ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  65.91, 74.57999, 70.02, 65.28,
  75.96, 64.64999, 52.10999, 49.08,
  53.31, 43.32, 51.98999, 43.91999,
  57.84, 46.68, 43.53, 62.91 ;

 dataday = 2009017 ;

 lat = -19.875, -19.625, -19.375, -19.125 ;

 lon = 42.125, 42.375, 42.625, 42.875 ;

 time = 1232145000 ;
}
netcdf ss.scrubbed.TRMM_3B42_daily_precipitation_V7.20090118 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 4 ;
variables:
	float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
		TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
		TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
		TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
		TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
		TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
		TRMM_3B42_daily_precipitation_V7:long_name = "Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg." ;
		TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
		TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
		TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
		TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
		TRMM_3B42_daily_precipitation_V7:units = "mm" ;
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
		:start_time = "2009-01-17T22:30:00Z" ;
		:end_time = "2009-01-18T22:29:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb 15 21:29:04 2014: ncks -d lat,-20.0,-19.0 -d lon,42.,43. scrubbed.TRMM_3B42_daily_precipitation_V7.20090118.nc ss.scrubbed.TRMM_3B42_daily_precipitation_V7.20090118.nc" ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  66.72, 57.33, 47.19, 34.41,
  58.47, 53.4, 42.81, 29.64,
  45.69, 41.61, 39.54, 36.54,
  44.19, 42.69, 36.72, 25.89 ;

 dataday = 2009018 ;

 lat = -19.875, -19.625, -19.375, -19.125 ;

 lon = 42.125, 42.375, 42.625, 42.875 ;

 time = 1232231400 ;
}
netcdf ss.scrubbed.TRMM_3B42_daily_precipitation_V7.20090119 {
dimensions:
	time = UNLIMITED ; // (1 currently)
	lat = 4 ;
	lon = 4 ;
variables:
	float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
		TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
		TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
		TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
		TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
		TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
		TRMM_3B42_daily_precipitation_V7:long_name = "Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg." ;
		TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
		TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
		TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
		TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
		TRMM_3B42_daily_precipitation_V7:units = "mm" ;
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
		:start_time = "2009-01-18T22:30:00Z" ;
		:end_time = "2009-01-19T22:29:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Sat Feb 15 21:29:05 2014: ncks -d lat,-20.0,-19.0 -d lon,42.,43. scrubbed.TRMM_3B42_daily_precipitation_V7.20090119.nc ss.scrubbed.TRMM_3B42_daily_precipitation_V7.20090119.nc" ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  32.73, 31.98, 33.75, 22.26,
  26.46, 48.24, 26.16, 26.28,
  37.68, 40.44, 31.14, 52.47,
  42.3, 44.91, 48.06, 38.37 ;

 dataday = 2009019 ;

 lat = -19.875, -19.625, -19.375, -19.125 ;

 lon = 42.125, 42.375, 42.625, 42.875 ;

 time = 1232317800 ;
}
