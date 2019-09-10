# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Visualizer-TimeTics.t'

#########################

use strict;
use Time::Local;
use Test::More tests => 4;

BEGIN { use_ok('Giovanni::Visualizer::TimeTics') }

my $tics;

my $cdldata_tmpl = read_cdl_data();
my $tmpdir       = $ENV{SAVEDIR} ? $ENV{SAVEDIR} : ( $ENV{'TMPDIR'} || '.' );
my $cdlroot      = "$tmpdir/t_time_series_";
my ( $got, $cdldata, $ncpath, @ncpaths );

# 1 month
$cdldata = set_times( "1 month", $cdldata_tmpl, '1979-02-01', '1979-02-28' );
$tics = new Giovanni::Visualizer::TimeTics(
    'style'               => 'time',
    'temporal_resolution' => 'monthly',
    'start'               => '1979-02-01',
    'end'                 => '1979-02-28'
);
is( join( ',', @{ $tics->labels } ), '1 Feb~C~1979,1 Mar' );
$ncpath = write_netcdf( $cdlroot . "1mo.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like( $got, qr#\t\t:plot_hint_time_axis_labels = "1 Feb~C~1979,1 Mar" ;#s,
    '1 month' );

unlink(@ncpaths) unless ( $ENV{'SAVE_TEST_FILES'} );

exit(0);

sub set_times {
    my ( $title, $cdl, $t1, $t4 ) = @_;
    $cdl
        =~ s/:title = ".*?"/:title = "Giovanni::Visualizer::TimeTics test: $title"/;

    # Compute equidistant points between t1 and t4
    my ( $et1, $et4 ) = map { timestring2epoch($_) } ( $t1, $t4 );
    my $et2 = $et1 + ( $et4 - $et1 ) / 3;
    my $et3 = $et1 + 2 * ( $et4 - $et1 ) / 3;
    my $t2  = epoch2timestring($et2);
    my $t3  = epoch2timestring($et3);

    # Modify CDL
    $cdl =~ s/2010-01-03 10:30:01/$t1/;
    $cdl =~ s/2010-01-03 10:30:02/$t2/;
    $cdl =~ s/2010-01-03 10:30:03/$t3/;
    $cdl =~ s/2010-01-03 10:30:04/$t4/;
    $cdl =~ s/userstartdate = ".*?"/userstartdate = "$t1"/;
    $cdl =~ s/userenddate = ".*?"/userenddate = "$t4"/;
    $cdl
        =~ s/plot_hint_subtitle = ".*?"/plot_hint_subtitle = "timespan: $title"/;
    return $cdl;
}

sub epoch2timestring {
    my @t = gmtime( $_[0] );
    return (
        sprintf "%04d-%02d-%02d %02d:%02d:%02d",
        $t[5] + 1900,
        $t[4] + 1,
        $t[3], $t[2], $t[1], $t[0]
    );
}

sub timestring2epoch {
    my ( $y, $m, $d, $h, $mi, $s ) = split( /[T :\-]/, $_[0] );
    $h  ||= 0;
    $mi ||= 0;
    $s  ||= 0;
    return timegm( $s, $mi, $h, $d, $m - 1, $y - 1900 );
}

sub read_cdl_data {

    # read block at __DATA__ and write to a CDL file
    my @cdldata;
    while (<DATA>) {
        push @cdldata, $_;
    }
    return ( join( '', @cdldata ) );
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
netcdf areaAvgTimeSeries.NLDAS_FORA0125_M_002_apcpsfc.19790201-19790228.125W_25N_67W_53N {
dimensions:
	time = UNLIMITED ; // (1 currently)
variables:
	float NLDAS_FORA0125_M_002_apcpsfc(time) ;
		NLDAS_FORA0125_M_002_apcpsfc:units = "kg/m^2" ;
		NLDAS_FORA0125_M_002_apcpsfc:long_name = "Precipitation Total" ;
		NLDAS_FORA0125_M_002_apcpsfc:cell_methods = "time: sum" ;
		NLDAS_FORA0125_M_002_apcpsfc:_FillValue = -9999.f ;
		NLDAS_FORA0125_M_002_apcpsfc:GRIB_param_name = "Precipitation_hourly_total" ;
		NLDAS_FORA0125_M_002_apcpsfc:GRIB_param_short_name = "APCPsfc" ;
		NLDAS_FORA0125_M_002_apcpsfc:GRIB_center_id = 7 ;
		NLDAS_FORA0125_M_002_apcpsfc:GRIB_table_id = 130 ;
		NLDAS_FORA0125_M_002_apcpsfc:GRIB_param_number = 61 ;
		NLDAS_FORA0125_M_002_apcpsfc:GRIB_param_id = 1, 7, 130, 61 ;
		NLDAS_FORA0125_M_002_apcpsfc:GRIB_product_definition_type = "Average" ;
		NLDAS_FORA0125_M_002_apcpsfc:GRIB_level_type = 1 ;
		NLDAS_FORA0125_M_002_apcpsfc:GRIB_VectorComponentFlag = "easterlyNortherlyRelative" ;
		NLDAS_FORA0125_M_002_apcpsfc:standard_name = "precipitation_hourly_total" ;
		NLDAS_FORA0125_M_002_apcpsfc:quantity_type = "Precipitation" ;
		NLDAS_FORA0125_M_002_apcpsfc:product_short_name = "NLDAS_FORA0125_M" ;
		NLDAS_FORA0125_M_002_apcpsfc:product_version = "002" ;
		NLDAS_FORA0125_M_002_apcpsfc:coordinates = "time lat lon" ;
	int time(time) ;
		time:long_name = "forecast time for (1 months intervals)" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	int datamonth(time) ;
		datamonth:long_name = "Standardized Date Label" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:NCO = "4.3.1" ;
		:start_time = "1979-02-01T00:00:00Z" ;
		:end_time = "1979-02-28T23:59:59Z" ;
		:temporal_resolution = "monthly" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Fri Oct 24 12:47:15 2014: ncrcat -O -o areaAvgTimeSeries.NLDAS_FORA0125_M_002_apcpsfc.19790201-19790228.125W_25N_67W_53N.nc\n",
			"Fri Oct 24 12:47:15 2014: ncks -A -v datamonth -o areaAvgTimeSeries.NLDAS_FORA0125_M_002_apcpsfc.19790201-19790228.125W_25N_67W_53N.nc.0 ./scrubbed.NLDAS_FORA0125_M_002_apcpsfc.197902010000.x.nc\n",
			"Fri Oct 24 12:47:15 2014: ncks -O -d lat,25.000000,53.000000 -d lon,-125.000000,-67.000000 -o ./scrubbed.NLDAS_FORA0125_M_002_apcpsfc.197902010000.x.nc /var/tmp/www/TS2/giovanni/CBC130D8-5B78-11E4-BC03-8A455D4277A9/CDF4991C-5B78-11E4-A716-94455D4277A9/CDF4B474-5B78-11E4-A716-94455D4277A9//scrubbed.NLDAS_FORA0125_M_002_apcpsfc.197902010000.nc" ;
		:nco_input_file_number = 1 ;
		:nco_input_file_list = "areaAvgTimeSeries.NLDAS_FORA0125_M_002_apcpsfc.19790201-19790228.125W_25N_67W_53N.nc.0" ;
		:userstartdate = "1979-02-01T00:00:00Z" ;
		:userenddate = "1979-02-28T23:59:59Z" ;
		:title = "Time Series, Area-Averaged of Precipitation Total monthly 0.125 deg. [NLDAS Model NLDAS_FORA0125_M v002] kg/m^2 over 1979-Feb - 1979-Feb, Region 125W, 25N, 67W, 53N " ;
data:

 NLDAS_FORA0125_M_002_apcpsfc = 55.51714 ;

 time = 286675200 ;

 datamonth = 197902 ;
}
