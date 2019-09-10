# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Visualizer-TimeTics.t'

#########################

use strict;
use Time::Local;
use Test::More tests => 31;

BEGIN { use_ok('Giovanni::Visualizer::TimeTics') }

my $tics;

# Check some support routines
is( Giovanni::Visualizer::TimeTics::ymdhms2epoch( 1970, 1, 3 ),
    2 * 3600 * 24 );
is( Giovanni::Visualizer::TimeTics::ymdhms2epoch( 2002, 3, 1 ),
    timestring2epoch("2002-03-01") );
is( Giovanni::Visualizer::TimeTics::ymdhms2epoch( 1948, 3, 1 ), -689126400 );

# 2.5 months
$tics = new Giovanni::Visualizer::TimeTics(
    'style' => 'time',
    'start' => '2000-12-01',
    'end'   => '2001-02-15 12:34:22Z'
);
is( join( ',', @{ $tics->labels } ), '1 Dec,1 Jan~C~2001,1 Feb,1 Mar' );

# 40 days
$tics = new Giovanni::Visualizer::TimeTics(
    'style' => 'time',
    'start' => '2000-12-01',
    'end'   => '2001-01-09 23:59Z'
);
is( join( ',', @{ $tics->labels } ),
    '1 Dec,6 Dec,11 Dec,16 Dec,21 Dec,26 Dec,31 Dec,5 Jan~C~2001,10 Jan' );

# 1 month
$tics = new Giovanni::Visualizer::TimeTics(
    'style' => 'time',
    'start' => '2010-01-01',
    'end'   => '2010-01-31'
);
is( join( ',', @{ $tics->labels } ),
    '1 Jan~C~2010,6 Jan,11 Jan,16 Jan,21 Jan,26 Jan,31 Jan' );
is( join( ',', @{ $tics->values } ),
    '1262304000,1262736000,1263168000,1263600000,1264032000,1264464000,1264896000'
);
is( join( ',', @{ $tics->minor } ),
    '1262390400,1262476800,1262563200,1262649600,1262822400,1262908800,1262995200,1263081600,1263254400,1263340800,1263427200,1263513600,1263686400,1263772800,1263859200,1263945600,1264118400,1264204800,1264291200,1264377600,1264550400,1264636800,1264723200,1264809600'
);

my $cdldata_tmpl = read_cdl_data();
my $tmpdir       = $ENV{'TMPDIR'} || '.';
my $cdlroot      = "$tmpdir/t_time_series_";
my ( $got, $cdldata, $ncpath, @ncpaths );

# 11 years
$cdldata = set_times(
    "11 years", $cdldata_tmpl,
    '1999-12-25 21:00:00',
    '2010-12-25 21:00:00'
);
$ncpath = write_netcdf( $cdlroot . "11yrs.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like( $got, qr#\t\t:plot_hint_time_axis_labels = "2000,2005,2010,2015" ;#s,
    '11 yrs' );

# 11 years, but using start_time, end_time instead of userstartdate, userenddate
$cdldata =~ s/:userstartdate/:start_time/;
$cdldata =~ s/:userenddate/:end_time/;
$ncpath = write_netcdf( $cdlroot . "11yrs.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like( $got, qr#\t\t:plot_hint_time_axis_labels = "2000,2005,2010,2015" ;#s,
    '11 yrs' );

# 4 years
# 4 years
$cdldata = set_times(
    "4 years", $cdldata_tmpl,
    '1999-12-25 21:00:00',
    '2003-12-25 21:00:00'
);
$ncpath = write_netcdf( $cdlroot . "4yrs.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like(
    $got,
    qr#\t\t:plot_hint_time_axis_labels = "1999,2000,2001,2002,2003,2004" ;#s,
    '4 yrs'
);

# 20 months
$tics = new Giovanni::Visualizer::TimeTics(
    'style' => 'time',
    'start' => '2000-12-01',
    'end'   => '2002-07-23T12:34:22Z'
);

$cdldata = set_times( "20 mos", $cdldata_tmpl, '2000-12-01',
    '2002-07-23 12:30:00' );
$ncpath = write_netcdf( $cdlroot . "20mos.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like(
    $got,
    qr#\t\t:plot_hint_time_axis_labels = "Dec,Mar~C~2001,Jun,Sep,Dec,Mar~C~2002,Jun,Sep" ;#s,
    '20 mos'
);

# 15 months
$cdldata = set_times( "15 mos", $cdldata_tmpl, '2000-12-01',
    '2002-02-23 12:30:00' );
$ncpath = write_netcdf( $cdlroot . "15mos.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like(
    $got,
    qr#\t\t:plot_hint_time_axis_labels = "Dec,Feb~C~2001,Apr,Jun,Aug,Oct,Dec,Feb~C~2002,Apr" ;#s,
    '15 mos'
);

# 1 year
$cdldata = set_times(
    "1 yr", $cdldata_tmpl,
    '1999-12-02 04:00:00',
    '2000-12-02 13:00:00'
);
$ncpath = write_netcdf( $cdlroot . "1yr.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like(
    $got,
    qr#plot_hint_time_axis_labels = "Dec,Feb~C~2000,Apr,Jun,Aug,Oct,Dec,Feb~C~2001"#,
    '1 yr'
);

# 3 months
$cdldata = set_times(
    "3 months", $cdldata_tmpl,
    '1999-12-02 04:00:00',
    '2000-03-02 13:00:00'
);
$ncpath = write_netcdf( $cdlroot . "3mos.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like( $got,
    qr#plot_hint_time_axis_labels = "1 Dec,1 Jan~C~2000,1 Feb,1 Mar,1 Apr"#,
    '3 mos' );

# 48 days
$cdldata = set_times(
    "48 days", $cdldata_tmpl,
    '1999-12-03 21:00:00',
    '2000-01-20 21:00:00'
);
$ncpath = write_netcdf( $cdlroot . "48days.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like( $got,
    qr#\t\t:plot_hint_time_axis_labels = "1 Dec,1 Jan~C~2000,1 Feb" ;#s,
    , '48 days' );

# 2 days
$cdldata = set_times(
    "2 days", $cdldata_tmpl,
    '1999-12-03 21:00:00',
    '1999-12-05 21:00:00'
);
$ncpath = write_netcdf( $cdlroot . "2days.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like(
    $got,
    qr#\t\t:plot_hint_time_axis_labels = "00Z~C~4 Dec~C~1999,12Z,00Z~C~5 Dec~C~1999,12Z,00Z~C~6 Dec~C~1999"#,
    '2 days'
);

# 9 hours
$cdldata = set_times(
    "9 hours over 2 days",
    $cdldata_tmpl,
    '1999-12-01 21:00:00',
    '1999-12-02 06:00:00'
);
$ncpath = write_netcdf( $cdlroot . "9hrs2days.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like(
    $got,
    qr#plot_hint_time_axis_labels = "21Z,00Z~C~2 Dec~C~1999,03Z,06Z"#,
    '9 hrs over 2 days'
);

# 9 hours over 1 day
$cdldata = set_times(
    "9 hours over 1 day",
    $cdldata_tmpl,
    '1999-12-02 04:00:00',
    '1999-12-02 13:00:00'
);
$ncpath = write_netcdf( $cdlroot . "9hrs1day.cdl", $cdldata );
ok( Giovanni::Visualizer::TimeTics::set_plot_hint_time_axis($ncpath) );
push @ncpaths, $ncpath;
$got = `ncdump -h $ncpath | grep plot_hint | grep -v history`
    or die "Could not ncdump -h $ncpath";
like( $got, qr#plot_hint_time_axis_labels = "06Z~C~2 Dec~C~1999,09Z,12Z,15Z"#,
    '9 hrs/1 day' );

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
netcdf timeseries_test {
dimensions:
	time = UNLIMITED ; // (54 currently)
	maxCharDateTime = 19 ;
variables:
        char datetime_mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC(time, maxCharDateTime) ;

	double mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC(time) ;
		mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC:long_name = "Mean of AOD at 550nm (interpolated) from AERONET_AOD_L2.2 at GSFC" ;
		mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC:units = "UNITLESS" ;
		mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC:_FillValue = -9999.99 ;
		mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC:station = "GSFC(38.992000:-76.840000:Alt 87.000 m)" ;
		mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC:level = "2" ;
		mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC:source = "Brent Holben(brent@aeronet.gsfc.nasa.gov)" ;
		mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC:quantity_type = "Mean AOD" ;
		mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC:plot_hint_y_axis_title = "Mean AOD" ;
		mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC:plot_hint_legend_label = "Mean of AOD at 550nm (interp.) from AERONET L2.2" ;

// global attributes:
		:title = "Test File for Giovanni::Visualizer::TimeTics" ;
		:Conventions = "CF-1.0" ;
		:userstartdate = "2010-01-02 00:00:00" ;
		:userenddate = "2010-01-07 00:00:00" ;
		:access = "Restricted" ;
		:plot_hint_title = "Test file for Giovanni::Visualizer::TimeTics: AOD at GSFC" ;
		:plot_hint_subtitle = "time_span" ;

data:
 datetime_mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC =
  "2010-01-03 10:30:01",
  "2010-01-03 10:30:02",
  "2010-01-03 10:30:03",
  "2010-01-03 10:30:04" ;

 mean_AERONET_AOD_L2_2_AOD0550intrp_GSFC = 0.078, 0.066, 0.068, 0.079 ;
}
