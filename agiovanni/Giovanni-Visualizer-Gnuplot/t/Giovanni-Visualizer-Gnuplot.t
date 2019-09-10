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
    DATA_FILE => $ncfile,
    PLOT_TYPE => 'TIME_SERIES_GNU'
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
1B(9IJ(8):\B&;>B&MA<0`#L`
`
end
