# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Visualizer-Gnuplot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use File::Temp qw /tempdir/;
use Giovanni::Data::NcFile;
use Giovanni::Testing;
use File::Basename;

BEGIN { use_ok('Giovanni::Visualizer::Gnuplot') }

#########################

my $dir = ( exists $ENV{SAVEDIR} ) ? $ENV{SAVEDIR} : tempdir( CLEANUP => 1 );
$/ = undef;
my $data = <DATA>;
my ( $cdl, $uue ) = ( $data =~ /^(netcdf.*?\n\}\n)(begin .*?\`\nend\n)/s );

my $ncfile = "$dir/vertical_profile.nc";
my $rc = Giovanni::Data::NcFile::write_netcdf_file( $ncfile, $cdl );

my $vertical_profile_plot = new Giovanni::Visualizer::Gnuplot(
    DATA_FILE => $ncfile,
    PLOT_TYPE => 'VERTICAL_PROFILE_GNU'
);
my $png = $vertical_profile_plot->draw();
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
my $ref_gif = Giovanni::Testing::uudecode_data( $uue, $dir );

# Compare the files
$rc = system("cmp $ref_gif $gif_file");
is( $rc, 0, "Difference between plot files" );
__DATA__
netcdf averaged.AIRX3STD_006_Temperature_A.20030101-20030101.106W_35N_92W_46N {
dimensions:
	bnds = 2 ;
	TempPrsLvls_A = 24 ;
variables:
	int time_bnds(bnds) ;
		time_bnds:long_name = "Time Bounds" ;
	double AIRX3STD_006_Temperature_A(TempPrsLvls_A) ;
		AIRX3STD_006_Temperature_A:_FillValue = -9999. ;
		AIRX3STD_006_Temperature_A:coordinates = "TempPrsLvls_A bnds" ;
		AIRX3STD_006_Temperature_A:long_name = "Atmospheric Temperature (3D), daytime (ascending), AIRS, 1 x 1 deg." ;
		AIRX3STD_006_Temperature_A:product_short_name = "AIRX3STD" ;
		AIRX3STD_006_Temperature_A:product_version = "006" ;
		AIRX3STD_006_Temperature_A:quantity_type = "Air Temperature" ;
		AIRX3STD_006_Temperature_A:standard_name = "air_temperature" ;
		AIRX3STD_006_Temperature_A:units = "K" ;
	float TempPrsLvls_A(TempPrsLvls_A) ;
		TempPrsLvls_A:standard_name = "Pressure" ;
		TempPrsLvls_A:long_name = "Pressure Levels Temperature Profile, daytime (ascending) node" ;
		TempPrsLvls_A:units = "hPa" ;
		TempPrsLvls_A:positive = "down" ;
		TempPrsLvls_A:_CoordinateAxisType = "GeoZ" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2003-01-01T00:00:00Z" ;
		:end_time = "2003-01-01T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:NCO = "4.3.1" ;
		:bounding_box = "-106.1719,35.5078,-92.8125,46.0547" ;
		:title = "Vertical Profile(106.1719W - 92.8125W, 35.5078N - 46.0547N)" ;
		:plot_hint_title = "Atmospheric Temperature (3D), daytime (ascending), AIRS, 1 x 1 deg. daily 1 deg. [AIRS AIRX3STD v006]" ;
		:plot_hint_subtitle = "Area-Averaged (106.1719W, 35.5078N, 92.8125W, 46.0547N)\n",
			"2003-01-01" ;
		:plot_hint_y_axis_label = "Pressure Levels Temperature Profile, daytime (ascending) node (hPa)" ;
		:plot_hint_x_axis_label = "K" ;
data:

 time_bnds = 1041379200, 1041465599 ;

 AIRX3STD_006_Temperature_A = _, 274.541986515399, 271.859577079682, 
    264.447892812366, 258.103501684722, 249.468493714116, 237.870895539968, 
    224.043796500132, 219.242036108687, 220.440964107411, 220.571947754998, 
    216.46623589976, 214.76724884602, 213.978090471014, 214.933499710226, 
    217.372762340902, 219.094732522949, 221.710962687314, 224.047729793229, 
    226.608635904311, 229.505123442072, 231.306437239417, 237.345571730636, 
    248.550143430771 ;

 TempPrsLvls_A = 1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 
    70, 50, 30, 20, 15, 10, 7, 5, 3, 2, 1.5, 1 ;
}
begin 0644 ref.vp.gif
M1TE&.#EA)@*``O8```$!`0L+"Q04%!P<'"0D)"LK*S0T-#L[.W(``$1$1$Q,
M3%-34UM;6V-C8VUM;71T='Q\?)8``/\``/\,#/\4%/\;&_\D)/\K*_\T-/\[
M._]#0_],3/]34_];6_]C8_]L;/]S<_]\?(2$A(R,C)24E)R<G*.CHZNKJ[:V
MMKR\O/^#@_^+B_^4E/^<G/^CH_^KJ_^SL_^\O,/#P\S,S-34U-S<W/_$Q/_,
MS/_4U/_<W.7EY>OKZ__CX__L[//S\__T]/___P``````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M`````````````````````````````````````````````````"'Y!```````
M+``````F`H`"``?^@$""@X2%AH>(B8J+C(V.CY"1DI.4E9:7F)F:FYR=GI^@
MH:*CI*6FIZBIJJNLK:ZOL+&RL[2UMK>XN;J[O+V^O\#!PL/$Q<;'R,G*R\S-
MSL_0T=+3U-76U]C9VMO<W=[?X.'BX^3EYN?HZ>KK[.WN[_#Q\O/T]?;W^/GZ
M^_S]_O\``PH<2+"@P8,($RI<R+"APX<0(TJ<2+&BQ8L8EZ$`H*/2QH[R1B2P
M]&,`"DD?,Z7T)#)6RI60?)C,V,A'@``[",%4M3/2#Y",``@=.O36QIRA=@B0
M(6C&`0$`!#``N5%H@`$*3!`B80`E1Z](!?W\Y&.I2P!(=_R8Q)4F(Q+^`P:,
MT/F554]0.G;H,`&`1EZ@M.XR6NMH!(%!-$SXE6'@,)"-,W3HD#%"@`$?@G8$
M.`E)\"+/G0S+`NW(!P#.;A$5@"#"L2"B``1M1&$@@`$:,VH7H"'VP8``!$H,
M.F%`*(&YCT\?N(H\.6T`MP<9!C```N'9RT6L+%$`0(`#@.D"'=&]^J#9Q6_G
M#K!;MO*K)`B1IPX!R-K9"0"(X'Z3`5+8[E&%EG/9`3&=>8@84-\A)PRXDPX"
M/#"(`@TTXH```2Q0PE<F%!"```OD!(%K0$`PP&M$!4B@;;BEQYL@!UJ7X()`
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
2V[,^^[-`&[1".[1$:Z^!```[
`
end
