# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Testing.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use File::Temp;
BEGIN { use_ok('Giovanni::Testing') }

my ( $cdl, $uue ) = Giovanni::Testing::parse_data_block( 'CDL', 'UUE' );
ok( $cdl, "Read data block" );
ok( $uue, "Read uuencode block" );

# Write the uuencoded block to a file
my ( $fh, $encoded_filename ) = File::Temp::tempfile();
print $fh $uue;
close($fh);
warn "INFO Wrote uuencoded file $encoded_filename\n";

# Now decode the uuencoded file
my $dir = File::Temp::tempdir();
my $pathname = Giovanni::Testing::uudecode_file( $encoded_filename, $dir );
ok( -e $pathname, "Decoded $encoded_filename" );
warn "INFO Wrote decoded file $pathname\n";

# Now encode the decoded file
my $encoded_filename_2 = "$encoded_filename.2";
my $rc = Giovanni::Testing::uuencode( $pathname, $encoded_filename_2 );
ok( -e $encoded_filename_2, "wrote $encoded_filename_2" );
warn "INFO Wrote encoded file $encoded_filename_2\n";
my $uue_1 = `tail -n +2 $encoded_filename`;
my $uue_2 = `tail -n +2 $encoded_filename_2`;
if ( ok( $uue_1 eq $uue_2 ) ) {
    unlink( $encoded_filename, $encoded_filename_2, $pathname )
        if ( $rc == 0 );
}
else {
    exit(1);
}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

__DATA__
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
begin 0644 gif.uue
M1TE&.#=A*``A`/<`````````(```*@``.0``1```5```7```9@``E@\`;!0`
M03L`,5$`+5P`0V4`&'``0G\``)<`/+0``,``)L4`$@`!30`"=P`)B@`,>T@.
M,`$0:;82*PH360L3:!058A@5>!T5:]85**D7.QP;9!P<7A\<<@8><TL@2CPA
M1G`B10TC?2,C92,C<VDC@!XD;",D;"DD;Q(E?2`E?7LF5\8F(J\G--@H,@8I
M9B8I5%HI/B,J<M4J/BHK>BLK;J8K2ALL?2LL="\LD#`L=P`M>R(N9Q<OABHO
M8R0P>W0P;I4P>"TQ<"0RA#0R;)@R:@`SE1@TF30T<S4U>F,U3<PU22LV?"0W
MG%4W9!PXC24XCZXX7P\YD!,Y:R8YI"PYK'<Y7RP[DR\[@SL[=$D[4BL\G"\\
MBST\?;8\5%L^@6<^7CL_8YL_2A)!A"Q!I$=!<2I"D#-"DX1"82]#G45#?BY$
MK#5$HV1$B3E%D+1%:!9&K71&>I9&EQ%'GD%(A2=)K'%)831*H3I*BW1*<(Q*
M7`!-GS5-LSY-GTU.?3M1L=M27%)4BU54?E95=8%56T=6K+57:VQ8<,I9;T1:
MNDU:HUA;?UI<FUY<B[!<@5A>DXM>A4M?N4MACF]A>%)DKV-DF6-FA&1FHU1G
MN51IQ&MJB+)JBYEKDE=NS6INEYAO@'1PF'UPCVYRHW-RI6%TP6IVKXEVE+=W
M=&5ZU75ZFGIZJVQ[Q'U]F,]^<W.$Q+^%AG.'W'F'GH6'G8V(HY2*EXZ.LN"1
MF+.2O,22EH63RX>6UX.7ZI"7M)B9JIF:M:N;I9"@WHZA\YRAKM"EK-2EF=NI
MKJFJO;&KM<&KK:&PR+*SP]RTPL^UMNFXOZ>Y_+FZS,&[V<N[SN*[VZN\O+F\
MQJF]V\'$U+3%_^[(TM?)S+[+Y<7+V=[,U+S-U,[/W-'3Y^O5V<_9\M?9V>C:
MU]?;Y.;<Y]W=ZMOAW^/C[.?E\??FXN;I[/'I[/#M]/SQ\O+R]/3S^N3U^?WU
M_.[\]O7\^OS\]?___P```"'Y!`D*`/\`(?\+24-#4D="1S$P,3+_```,2$QI
M;F\"$```;6YT<E)'0B!865H@!\X``@`)``8`,0``86-S<$U31E0`````245#
M('-21T(``````````````````/;6``$`````TRU(4"`@````````````````
M```````````````````````````````````````````````18W!R=````5``
M```S9&5S8P```80```!L=W1P=````?`````48FMP=````@0````4<EA96@``
M`A@````49UA96@```BP````48EA96@```D`````49&UN9````E0```!P9&UD
M9````L0```"(=G5E9````TP```"&=FEE_W<```/4````)&QU;6D```/X````
M%&UE87,```0,````)'1E8V@```0P````#')44D,```0\```(#&=44D,```0\
M```(#&)44D,```0\```(#'1E>'0`````0V]P>7)I9VAT("AC*2`Q.3DX($AE
M=VQE='0M4&%C:V%R9"!#;VUP86YY``!D97-C`````````!)S4D="($E%0S8Q
M.38V+3(N,0``````````````$G-21T(@245#-C$Y-C8M,BXQ````````````
M``````````````````````````````````````````````````````!865H@
M````````\U$``?\````!%LQ865H@`````````````````````%A96B``````
M``!OH@``./4```.06%E:(````````&*9``"WA0``&-I865H@````````)*``
M``^$``"VSV1E<V,`````````%DE%0R!H='1P.B\O=W=W+FEE8RYC:```````
M````````%DE%0R!H='1P.B\O=W=W+FEE8RYC:```````````````````````
M``````````````````````````````````````!D97-C`````````"Y)14,@
M-C$Y-C8M,BXQ($1E9F%U;'0@4D="(&-O;&]U<B!S<&%C92`M('-21T+_````
M```````````N245#(#8Q.38V+3(N,2!$969A=6QT(%)'0B!C;VQO=7(@<W!A
M8V4@+2!S4D="`````````````````````````````&1E<V,`````````+%)E
M9F5R96YC92!6:65W:6YG($-O;F1I=&EO;B!I;B!)14,V,3DV-BTR+C$`````
M`````````"Q2969E<F5N8V4@5FEE=VEN9R!#;VYD:71I;VX@:6X@245#-C$Y
M-C8M,BXQ``````````````````````````````````!V:65W```````3I/X`
M%%\N`!#/%``#[<P`!!,+``-<G@````%865H@_P``````3`E6`%````!7'^=M
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
%XQ@0`#L`
`
end
