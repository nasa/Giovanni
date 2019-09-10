# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Visualizer-Gnuplot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use File::Temp qw /tempdir/;
use Giovanni::Data::NcFile;
use File::Basename;

BEGIN { use_ok('Giovanni::Visualizer::Gnuplot') }

#########################

my $dir = ( exists $ENV{SAVEDIR} ) ? $ENV{SAVEDIR} : tempdir( CLEANUP => 1 );
$/ = undef;
my $data = <DATA>;
my ( $cdl, $uue ) = ( $data =~ /^(netcdf.*?\n\}\n)(begin .*?\`\nend\n)/s );

my $ncfile = "$dir/ts_60days.nc";
my $rc = Giovanni::Data::NcFile::write_netcdf_file( $ncfile, $cdl );
is( $rc, $ncfile );

my $time_series_plot = new Giovanni::Visualizer::Gnuplot(
    DATA_FILE  => $ncfile,
    PLOT_TYPE  => 'TIME_SERIES_GNU',
    SKIP_TITLE => 1,
);
$time_series_plot->ymin(0.06);
is( $time_series_plot->ymin, 0.06, "set ymin" );
$time_series_plot->ymax(0.2);
is( $time_series_plot->ymax, 0.2, "set ymax" );
my $png = $time_series_plot->draw();
ok( $png, "Draw PNG" );

# Compare with reference plot file
# Convert to GIF file for comparison
# GIF does not contain a timestamp like PNG does
my $gif_file = $png;
$gif_file =~ s/\.png/.gif/;
$rc = system("convert $png $gif_file");
die("Cannot convert $png to $gif_file\n") if ($rc);

# Write uudecoded segment from data block to a file
# Use giovanni4/bin/g4_uuencode.pl to create an
# updated uuencoded file
my $ref_gif = uudecode( $uue, $dir );

# Compare the files
$rc = system("cmp $ref_gif $gif_file");
is( $rc, 0, "Difference between plot files" );

sub uudecode {
    my ( $uue, $dir ) = @_;
    my ( $perm, $file, $data )
        = ( $uue =~ /begin (\d+) (\S+)\n(.*)\`\nend/s );
    my $path = $dir . '/' . basename($file);
    open F, '>', $path or die "Cannot write to file $path: $!\n";
    print F unpack( "u", $data );
    close F;
    return $path;
}
__DATA__
netcdf ts_60days {
dimensions:
	bnds = 2 ;
	time = UNLIMITED ; // (59 currently)
variables:
	int time_bnds(time, bnds) ;
	double MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean(time) ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:_FillValue = -9999. ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:long_name = "Aerosol Optical Depth 550 nm (Deep Blue, Land-only)" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:units = "1" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:Derived_From_Level_2_Data_Set = "Deep_Blue_Aerosol_Optical_Depth_550_Land" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:Quality_Assurance_Data_Set = "Quality_Assurance_Land" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:Statistic_Type = "Simple" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:QA_Byte = 4s ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:QA_Useful_Flag_Bit = 0s ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:QA_Value_Start_Bit = 1s ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:QA_Value_Num_Bits = 2s ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:Aggregation_Data_Set = "None" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:standard_name = "deep_blue_aerosol_optical_depth_550_land_qa_mean" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:quantity_type = "Total Aerosol Optical Depth" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:product_short_name = "MOD08_D3" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:product_version = "051" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:coordinates = "time" ;
		MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean:plot_hint_legend_label = "MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int dataday(time) ;
		dataday:long_name = "Standardized Date Label" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2001-01-01T00:00:00Z" ;
		:end_time = "2001-02-28T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Tue Aug 26 18:33:11 2014: ncatted -a bounds,time,o,c,time_bnds areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.tmp\n",
			"Tue Aug 26 18:33:11 2014: ncatted -a plot_hint_time_axis_values,global,c,c,978307200,980985600,983404800 -a plot_hint_time_axis_labels,global,c,c,1 Jan~C~2001,1 Feb,1 Mar -a plot_hint_time_axis_minor,global,c,c,979603200,982281600 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc\n",
			"Tue Aug 26 18:33:10 2014: ncrcat -O -o areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc\n",
			"Tue Aug 26 18:33:02 2014: ncks -A -v dataday -o areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.0 ./scrubbed.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101.x.nc\n",
			"Tue Aug 26 18:33:02 2014: ncks -O -d lat,27.773400,43.945300 -d lon,-127.265600,-104.765600 -o ./scrubbed.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101.x.nc /var/tmp/www/TS2/giovanni/DBE6D6DC-2D4E-11E4-8739-7CF0AC2C52A4/F0E631AE-2D4E-11E4-AD2B-95F0AC2C52A4/F0E64D06-2D4E-11E4-AD2B-95F0AC2C52A4//scrubbed.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101.nc" ;
		:NCO = "4.3.1" ;
		:nco_input_file_number = 59 ;
		:nco_input_file_list = "areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.0 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.1 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.2 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.3 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.4 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.5 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.6 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.7 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.8 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.9 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.10 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.11 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.12 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.13 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.14 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.15 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.16 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.17 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.18 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.19 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.20 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.21 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.22 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.23 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.24 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.25 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.26 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.27 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.28 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.29 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.30 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.31 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.32 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.33 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.34 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.35 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.36 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.37 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.38 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.39 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.40 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.41 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.42 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.43 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.44 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.45 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.46 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.47 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.48 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.49 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.50 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.51 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.52 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.53 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.54 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.55 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.56 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.57 areaAvgTimeSeries.MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean.20010101-20010228.127W_27N_104W_43N.nc.58" ;
		:userstartdate = "2001-01-01T00:00:00Z" ;
		:userenddate = "2001-02-28T23:59:59Z" ;
		:title = "Time Series, Area-Averaged of Aerosol Optical Depth 550 nm (Deep Blue, Land-only) daily 1 deg. [MODIS-Terra MOD08_D3 v051] over 2001-01-01 - 2001-02-28, Region 127.2656W, 27.7734N, 104.7656W, 43.9453N" ;
		:plot_hint_title = "Time Series, Area-Averaged of Aerosol Optical Depth 550 nm (Deep Blue, Land-only) daily 1" ;
		:plot_hint_subtitle = "deg. [MODIS-Terra MOD08_D3 v051] over 2001-01-01 - 2001-02-28, Region 127.2656W, 27.7734N, 104.7656W, 43.9453N" ;
		:plot_hint_time_axis_values = "978307200,980985600,983404800" ;
		:plot_hint_time_axis_labels = "1 Jan~C~2001,1 Feb,1 Mar" ;
		:plot_hint_time_axis_minor = "979603200,982281600" ;
data:

 time_bnds =
  978307200, 978393600,
  978393600, 978480000,
  978480000, 978566400,
  978566400, 978652800,
  978652800, 978739200,
  978739200, 978825600,
  978825600, 978912000,
  978912000, 978998400,
  978998400, 979084800,
  979084800, 979171200,
  979171200, 979257600,
  979257600, 979344000,
  979344000, 979430400,
  979430400, 979516800,
  979516800, 979603200,
  979603200, 979689600,
  979689600, 979776000,
  979776000, 979862400,
  979862400, 979948800,
  979948800, 980035200,
  980035200, 980121600,
  980121600, 980208000,
  980208000, 980294400,
  980294400, 980380800,
  980380800, 980467200,
  980467200, 980553600,
  980553600, 980640000,
  980640000, 980726400,
  980726400, 980812800,
  980812800, 980899200,
  980899200, 980985600,
  980985600, 981072000,
  981072000, 981158400,
  981158400, 981244800,
  981244800, 981331200,
  981331200, 981417600,
  981417600, 981504000,
  981504000, 981590400,
  981590400, 981676800,
  981676800, 981763200,
  981763200, 981849600,
  981849600, 981936000,
  981936000, 982022400,
  982022400, 982108800,
  982108800, 982195200,
  982195200, 982281600,
  982281600, 982368000,
  982368000, 982454400,
  982454400, 982540800,
  982540800, 982627200,
  982627200, 982713600,
  982713600, 982800000,
  982800000, 982886400,
  982886400, 982972800,
  982972800, 983059200,
  983059200, 983145600,
  983145600, 983232000,
  983232000, 983318400,
  983318400, 983404800 ;

 MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean = 
    0.102704100207563, 0.108705805017737, 0.0791195023673634, 
    0.0782100746897099, 0.0660747828953935, 0.0932415693417506, 
    0.0875333904417041, 0.0702066617833394, 0.160589401054661, 
    0.0857912299035763, 0.0606385669928083, 0.0549145273630334, 
    0.0673724045778496, 0.0694691945994351, 0.135219649697033, 
    0.112854242308579, 0.131900163548212, 0.135802364602254, 
    0.114552332074619, 0.101032791032495, 0.0716498039414754, 
    0.137218667741337, 0.105537956308214, 0.09401204267064, 
    0.0832054223215251, 0.0936617036188349, 0.143380162497167, 
    0.122804986702164, 0.116600331994021, 0.11296068563225, 
    0.130986815059102, 0.141718137693682, 0.104858446012257, 
    0.169999413056642, 0.0972427859562177, 0.10217307817924, 
    0.0956772122398187, 0.130305988275501, 0.14341102468208, 
    0.088241083200709, 0.190697695321325, 0.0888261589868656, 
    0.094036026779886, 0.143350655957621, 0.130743744318322, 
    0.0951270760362308, 0.160228036218307, 0.238920236317731, 
    0.114229091301102, 0.108602692417308, 0.100802006398087, 
    0.133008391093446, 0.148347658605318, 0.117742692542947, 
    0.188269623121884, 0.239293712406987, 0.168528423594114, 
    0.109889171058775, 0.172456230057405 ;

 time = 978307200, 978393600, 978480000, 978566400, 978652800, 978739200, 
    978825600, 978912000, 978998400, 979084800, 979171200, 979257600, 
    979344000, 979430400, 979516800, 979603200, 979689600, 979776000, 
    979862400, 979948800, 980035200, 980121600, 980208000, 980294400, 
    980380800, 980467200, 980553600, 980640000, 980726400, 980812800, 
    980899200, 980985600, 981072000, 981158400, 981244800, 981331200, 
    981417600, 981504000, 981590400, 981676800, 981763200, 981849600, 
    981936000, 982022400, 982108800, 982195200, 982281600, 982368000, 
    982454400, 982540800, 982627200, 982713600, 982800000, 982886400, 
    982972800, 983059200, 983145600, 983232000, 983318400 ;

 dataday = 2001001, 2001002, 2001003, 2001004, 2001005, 2001006, 2001007, 
    2001008, 2001009, 2001010, 2001011, 2001012, 2001013, 2001014, 2001015, 
    2001016, 2001017, 2001018, 2001019, 2001020, 2001021, 2001022, 2001023, 
    2001024, 2001025, 2001026, 2001027, 2001028, 2001029, 2001030, 2001031, 
    2001032, 2001033, 2001034, 2001035, 2001036, 2001037, 2001038, 2001039, 
    2001040, 2001041, 2001042, 2001043, 2001044, 2001045, 2001046, 2001047, 
    2001048, 2001049, 2001050, 2001051, 2001052, 2001053, 2001054, 2001055, 
    2001056, 2001057, 2001058, 2001059 ;
}
begin 0644 ref.1.gif
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
301YRD8^<Y"4W^<E1GG)I!@0`.P``
`
end
