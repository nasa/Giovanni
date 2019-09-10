#$Id: Giovanni-Visualizer-Hints_correlationNoDifference.t,v 1.8 2014/01/10 17:10:51 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 SYNOPIS
This tests a simple correlation case and makes sure the plot hints are added
to the netcdf file.
=cut

use strict;
use File::Temp;
use Test::More tests => 7;
BEGIN { use_ok('Giovanni::Visualizer::Hints') }

# read the cdl
my $cdl = readCdlData();

# write it out as netcdf
my $tmpFile = writeNetCdf($cdl);

my $varInfo = <<VARINFO;
<varList>
  <var id="MOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean" south="-90.0" dataProductTimeInterval="daily" long_name="Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Terra, 1 x 1 deg." west="-180.0" dataProductVersion="051" east="180.0" accessFormat="netCDF" north="90.0" sdsName="Angstrom_Exponent_1_Ocean_QA_Mean" dataProductShortName="MOD08_D3" accessMethod="OPeNDAP" resolution="1 x 1 deg." dataProductStartTimeOffset="1" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MODIS%2FTerra+Aerosol+Cloud+Water+Vapor+Ozone+Daily+L3+Global+1Deg+CMG+V051;agent_id=OPeNDAP;variables=Angstrom_Exponent_1_Ocean_QA_Mean&amp;start=2003-01-01T00:00:01&amp;end=2003-01-05T23:59:59&amp;output_type=xml" quantity_type="Angstrom Exponent">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/angstrom_exponent_sld.xml" label="Angstrom Exponent"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/angstrom_exponent_panoply_diff_sld.xml" label="Panoply"/>
    </slds>
  </var>
  <var id="MYD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean" south="-90.0" dataProductTimeInterval="daily" long_name="Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Aqua, 1 x 1 deg." west="-180.0" dataProductVersion="051" east="180.0" accessFormat="netCDF" north="90.0" sdsName="Angstrom_Exponent_1_Ocean_QA_Mean" dataProductShortName="MYD08_D3" accessMethod="OPeNDAP" resolution="1 x 1 deg." dataProductStartTimeOffset="1" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=MODIS%2FAqua+Aerosol+Cloud+Water+Vapor+Ozone+Daily+L3+Global+1Deg+CMG+V051;agent_id=OPeNDAP;variables=Angstrom_Exponent_1_Ocean_QA_Mean&amp;start=2003-01-01T00:00:01&amp;end=2003-01-05T23:59:59&amp;output_type=xml" quantity_type="Angstrom Exponent">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/angstrom_exponent_sld.xml" label="Angstrom Exponent"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/angstrom_exponent_panoply_diff_sld.xml" label="Panoply"/>
    </slds>
  </var>
</varList>
VARINFO
my $varInfoFile = writeToTempFile( $varInfo, "varInfo_XXXX", ".xml" );

# create a Hints object
my $hints = new Giovanni::Visualizer::Hints(
    file    => $tmpFile,
    service => "correlation",
    varId   => [
        "MOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean",
        "MYD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean"
    ],
    varInfoFile   => [$varInfoFile],
    userStartTime => "2003-01-01T00:00:00Z",
    userEndTime   => "2003-01-05T23:59:59Z",
);

# tell it to add the hints
$hints->addHints();

# now do an ncdump of the the file
my @lines = `ncdump -h -x $tmpFile  `
    or die "Failed to get header from $tmpFile with ncdump\n";

# parse the XML and grab the root node.
my $parser = XML::LibXML->new();
my $dom    = $parser->parse_string( join( "", @lines ) );
my $xpc    = XML::LibXML::XPathContext->new($dom);
$xpc->registerNs(
    nc => 'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );

# make sure we now have variable-level plot hints

# correlation
my $titleText
    = $xpc->findvalue( qq(/nc:netcdf/nc:variable[\@name="correlation"]/)
        . qq(nc:attribute[\@name="plot_hint_title"]/\@value) );
is( $titleText,
    "Correlation for 2003-01-01 - 2003-01-05",
    "correlation variable plot_hint_title in file"
);

my $subtitleText
    = $xpc->findvalue( qq(/nc:netcdf/nc:variable[\@name="correlation"]/)
        . qq(nc:attribute[\@name="plot_hint_subtitle"]/\@value) );
is( $subtitleText,
    "1st Variable: Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, "
        . "MODIS-Aqua [MYD08_D3 v51]\n2nd Variable: Angstrom Exponent 550/865 nm "
        . "(Dark Target), Ocean-only, MODIS-Terra \[MOD08_D3 v51\]",
    ,
    "correlation variable plot_hint_title in file"
);

#n_samples
$titleText = $xpc->findvalue( qq(/nc:netcdf/nc:variable[\@name="n_samples"]/)
        . qq(nc:attribute[\@name="plot_hint_title"]/\@value) );
is( $titleText,
    "Time matched sample size for 2003-01-01 - 2003-01-05",
    "correlation variable plot_hint_title in file"
);

$subtitleText
    = $xpc->findvalue( qq(/nc:netcdf/nc:variable[\@name="n_samples"]/)
        . qq(nc:attribute[\@name="plot_hint_subtitle"]/\@value) );
is( $subtitleText,
    "1st Variable: Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, "
        . "MODIS-Aqua [MYD08_D3 v51]\n2nd Variable: Angstrom Exponent 550/865 nm "
        . "(Dark Target), Ocean-only, MODIS-Terra \[MOD08_D3 v51\]",
    ,
    "correlation variable plot_hint_title in file"
);

#time_matched_difference
my @nodes = $xpc->findnodes(
    qq(/nc:netcdf/nc:variable[\@name="time_matched_difference"] ));
is( scalar(@nodes), 0, 'no time matched difference variable' );

@nodes
    = $xpc->findnodes( qq(/nc:netcdf/) . qq(nc:attribute[\@name="history"]) );
is( scalar(@nodes), 0, 'history removed' );

## now do an ncdump of the the file
#
#my @out = `ncdump $tmpFile` or die "Unable to dump netcdf file";
#my $dump = join( "\n", @out );
#
## make sure we now have variable-level plot hints
#
## correlation
#my $newHintTitle =
#  qq{correlation:plot_hint_title = "Correlation for 2003-01-01 - 2003-01-05"};
#ok( $dump =~ m/$newHintTitle/, 'correlation variable plot_hint_title in file' );
#
#my $newHintSubtitle =
#qq{correlation:plot_hint_subtitle = "1st Variable: Angstrom Exponent 550/865 nm \\(Dark Target\\), Ocean-only, MODIS-Aqua \\[MYD08_D3 v51\\] 2nd Variable: Angstrom Exponent 550/865 nm \\(Dark Target\\), Ocean-only, MODIS-Terra \\[MOD08_D3 v51\\]"};
#ok( $dump =~ m/$newHintSubtitle/,
#   'correlation variable plot_hint_subtitle in file' );
#
##n_samples
#$newHintTitle =
#qq{n_samples:plot_hint_title = "Time matched sample size for 2003-01-01 - 2003-01-05"};
#ok( $dump =~ m/$newHintTitle/, 'sample size plot_hint_title in file' );
#
#$newHintSubtitle =
#qq{n_samples:plot_hint_subtitle = "1st Variable: Angstrom Exponent 550/865 nm \\(Dark Target\\), Ocean-only, MODIS-Aqua \\[MYD08_D3 v51\\] 2nd Variable: Angstrom Exponent 550/865 nm \\(Dark Target\\), Ocean-only, MODIS-Terra \\[MOD08_D3 v51\\]"};
#ok( $dump =~ m/$newHintSubtitle/, 'sample size plot_hint_subtitle in file' );
#
## make sure the history was removed
#ok( !( $dump =~ m/:history/ ), 'history removed' );

# writes the cdl to a temp netcdf file
sub writeNetCdf {
    my ($cdl) = @_;

    # write the cdl to a temp file
    my $tmpCdlFile = writeToTempFile( $cdl, "hints_XXXX", ".cdl" );

    # create another temp file for netcdf
    ( my $tmpNcHandle, my $tmpNcFile )
        = File::Temp::tempfile( "hints_XXXX", SUFFIX => ".nc", UNLINK => 1 );

    my $cmd = "ncgen -o $tmpNcFile $tmpCdlFile";
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );

    return $tmpNcFile;
}

sub readCdlData {

    # read block at __DATA__ and write to a CDL file
    #(stolen from Chris...)
    my @cdldata;
    while (<DATA>) {
        push @cdldata, $_;
    }
    return ( join( '', @cdldata ) );
}

# write to temporary file and make sure it is completely written.
sub writeToTempFile {
    my ( $str, $pattern, $suffix ) = @_;

    ( my $tmpHandle, my $tmpFile )
        = File::Temp::tempfile( $pattern, SUFFIX => $suffix, UNLINK => 1 );
    print $tmpHandle $str;

    # make sure the file is flushed...
    select($tmpHandle);
    $|++;

    close($tmpHandle);
    return $tmpFile;
}

# netcdf file for testing...
__DATA__
netcdf correlation.MYD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean+MOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean.20030101-20030105 {
dimensions:
    lon = 28 ;
    lat = 19 ;
variables:
    double lon(lon) ;
        lon:long_name = "longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double lat(lat) ;
        lat:long_name = "latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double correlation(lat, lon) ;
        correlation:long_name = "Correlation of Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Aqua [MYD08_D3 v51] vs. Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Terra [MOD08_D3 v51]" ;
        correlation:_FillValue = 9.96920996838687e+36 ;
        correlation:quantity_type = "correlation" ;
        correlation:plot_hint_minval = -1. ;
        correlation:plot_hint_maxval = 1. ;   
    double slope(lat, lon) ;
        slope:long_name = "slope" ;
        slope:_FillValue = 9.96920996838687e+36 ;
    double offset(lat, lon) ;
        offset:long_name = "offset" ;
        offset:_FillValue = 9.96920996838687e+36 ;
    int n_samples(lat, lon) ;
        n_samples:long_name = "Number of samples" ;
        n_samples:quantity_type = "count" ;
        n_samples:units = "count" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :matched_start_time = "2003-01-01T00:00:00Z";
        :matched_end_time = "2003-01-05T23:59:59Z";
        :title = "Correlation of Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Aqua vs. Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Terra" ;
        :history = "Thu Sep 13 20:26:11 2012: ncrename -d .latitude,lat -d .longitude,lon -v .latitude,lat -v .longitude,lon -O /var/tmp/www/TS2/giovanni/ED05CD32-FDE0-11E1-AFAB-18DE69B977CC/0CCA95DA-FDE1-11E1-8E7F-42DE69B977CC/0CCAAF0C-FDE1-11E1-8E7F-42DE69B977CC/CorrelationScienceCommand_0/correlation.MYD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean+MOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean.20030101-20030105.nc\n",
            "Thu Sep 13 20:26:11 2012: ncatted -O -o /var/tmp/www/TS2/giovanni/ED05CD32-FDE0-11E1-AFAB-18DE69B977CC/0CCA95DA-FDE1-11E1-8E7F-42DE69B977CC/0CCAAF0C-FDE1-11E1-8E7F-42DE69B977CC/CorrelationScienceCommand_0/correlation.MYD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean+MOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean.20030101-20030105.nc -a title,global,c,c,Correlation of Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Aqua vs. Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Terra -a long_name,correlation,m,c,Correlation of Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Aqua vs. Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Terra -a plot_hint_title,global,c,c,Correlation (top) and Sample Size (bottom) for 2003-01-01 - 2003-01-05 -a plot_hint_subtitle,global,c,c,1st Variable: Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Aqua~C~2nd Variable: Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Terra -a plot_hint_caption,global,c,c,Correlation of Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Aqua vs. Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Terra. 1st Variable: Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Aqua. 2nd Variable: Angstrom Exponent 550/865 nm (Dark Target), Ocean-only, MODIS-Terra -a plot_hint_minval,correlation,c,d,-1.0 -a plot_hint_maxval,correlation,c,d,1.0 /var/tmp/www/TS2/giovanni/ED05CD32-FDE0-11E1-AFAB-18DE69B977CC/0CCA95DA-FDE1-11E1-8E7F-42DE69B977CC/0CCAAF0C-FDE1-11E1-8E7F-42DE69B977CC/CorrelationScienceCommand_0/correlation.MYD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean+MOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean.20030101-20030105.nc" ;
data:

 lon = -87.5, -86.5, -85.5, -84.5, -83.5, -82.5, -81.5, -80.5, -79.5, -78.5, 
    -77.5, -76.5, -75.5, -74.5, -73.5, -72.5, -71.5, -70.5, -69.5, -68.5, 
    -67.5, -66.5, -65.5, -64.5, -63.5, -62.5, -61.5, -60.5 ;

 lat = 21.5, 22.5, 23.5, 24.5, 25.5, 26.5, 27.5, 28.5, 29.5, 30.5, 31.5, 
    32.5, 33.5, 34.5, 35.5, 36.5, 37.5, 38.5, 39.5 ;

 correlation =
  0.884121380197987, 0.142924500714879, -0.694559256755775, _, _, _, _, _, 
    0.392528047262363, _, _, 0.224152965647461, 0.368483999997431, 
    0.965800078449206, 0.925717337788386, _, 0.203475749545978, 
    -0.265607731958487, -0.262321772090919, -0.233240005368268, 
    0.735383850615289, -0.12281909614089, 0.129166787556417, 
    0.676651926169389, 0.687007968732477, 0.654810924874622, 
    0.543019475730955, 0.817709732839388,
  0.961049199151793, 0.567364779629498, 0.339360757670787, _, _, _, _, _, _, 
    -0.618537363664528, -0.911478628878613, 0.784296886973924, 
    -0.121012857881601, 0.985259659742782, -0.29614648257609, 
    0.000767405156430932, 0.541307261809956, 0.462393743467132, 
    0.134003138640667, -0.269599799725395, -0.358981134082827, 
    0.841722316605134, 0.0593766419268116, 0.86230879711983, 
    0.883563174137665, 0.889306236811277, 0.462103242115341, 0.830248447100373,
  0.492856431532152, 0.936476990236375, _, _, _, 0.928006564685236, _, _, 
    0.816791582863398, -0.418600830369101, 0.915302734403134, 
    0.898801203407051, _, -0.492465186163831, _, -0.507400238588555, 
    0.130059950363918, 0.29380777236273, 0.230523885747585, 
    -0.106391154676826, 0.989990409397313, 0.903281449144627, 
    0.304117274389743, 0.560161543556623, 0.723803534068437, 
    0.52911683859118, 0.632568102271661, 0.292646290796757,
  0.51839044452658, 0.800542896188804, _, _, _, _, _, 0.879759440693549, 
    0.821881580720892, -0.810231851861563, _, 0.655762099712599, 
    0.117247243921671, _, _, 0.909944876473941, -0.978642644269592, _, 
    -0.881830431969174, -0.125647395960437, 0.420245398745904, 
    0.607345140581707, 0.737373927240935, 0.421300321959944, 
    0.741117225587334, 0.895228000148916, 0.481568897166496, 0.337769808128935,
  0.163498558858214, 0.842846889230839, 0.792766429470725, _, _, _, _, _, 
    0.740988732444056, 0.271994063332763, 0.874958140384239, 
    -0.192590925158457, 0.597427234992818, 0.45585128872205, 
    0.869532479653033, 0.821870907945673, -0.842506261381245, 
    -0.98903097614762, _, 0.0347192844865215, 0.915701987962188, 
    0.919110732519225, 0.830465692524487, 0.748673987867599, 
    0.883585823409303, 0.836107637736592, 0.389855997804809, 0.186240777860134,
  _, 0.914346365142374, 0.739747731313019, 0.470342998478814, _, 
    0.975609771541817, _, _, 0.824621841212401, 0.982981345536296, _, _, 
    0.880800584209049, 0.898435892874959, 0.969326070396573, 
    0.995188649823392, 0.860066021102503, _, _, _, _, 0.102348478054669, 
    0.625695314448903, 0.405875191349836, 0.113550658621856, 
    0.626784534700516, 0.671101796849349, 0.365192826678995,
  0.995810414180681, 0.993583813870908, 0.916760572727024, 0.973576544446419, 
    0.998717401855922, _, _, 0.974630057568163, 0.5628791242793, 
    0.836774808738248, 0.833685399834541, _, 0.760197402568153, 
    0.922989920817014, 0.935346866030131, 0.978986470094164, 
    0.899943687626029, _, _, _, 0.716953222402445, _, 0.456769731325429, 
    0.332716774130928, 0.484859415454257, -0.419945674682168, 
    -0.274701521622937, 0.48194814482347,
  0.772652481169569, 0.981983955264168, 0.563570648884493, 0.985386084233349, 
    0.996595415935314, _, _, 0.943507556550696, 0.925729232757417, 
    0.918475443937056, 0.733949444763585, 0.918906661594654, 
    0.851313596631496, _, 0.998880274140141, 0.986959952075557, _, _, _, _, 
    _, _, 0.998865408046515, 0.793042559730779, 0.898253535904133, 
    0.901638145620284, -0.56501836718893, 0.957271567343778,
  0.884603569600681, 0.975475521095272, 0.941747076165664, 0.994715236697238, 
    0.997394984055801, _, _, 0.98567904873771, 0.915050007364476, _, _, 
    0.9997433652009, _, _, _, 0.957821873676079, _, _, _, _, 
    0.995882471549892, _, _, _, _, 0.875907581025361, 0.806784571154101, 
    0.741065335546262,
  -0.279857208746943, 0.947872631674206, _, _, _, _, 0.775183605561914, 
    0.969219356703369, _, _, _, _, 0.701770031699936, 0.974336504443886, _, 
    0.989777304015994, _, 0.985352126393913, _, _, _, _, _, _, _, _, 
    -0.28497905558593, 0.223597858029468,
  _, _, _, _, _, _, _, 0.986694187076337, _, _, _, _, 0.857234747471821, _, 
    0.983491495156161, 0.996948445751935, 0.996458913128623, _, _, _, _, _, 
    _, _, _, _, _, _,
  _, _, _, _, _, _, _, 0.681738812743591, 0.745270164381466, 
    0.804843161614349, _, _, _, _, 0.990124809789521, 0.999984616144905, 
    0.997120249721607, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, 0.352503536719469, 0.486251896455147, _, _, _, 
    _, _, _, _, 0.950061847815665, _, _, _, 0.993105138606628, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, -0.504010453333259, _, _, _, _, 
    0.995246073661319, _, _, _, _, 0.694971021084725, _, 0.932455708076566, 
    _, _, _, _, 0.628628898094313,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    0.947589769692306, _, _, _, _, _, 0.996003978025736,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, 0.997791489055007,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    0.49929560763531, 0.448250067817948, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _ ;
    
 slope =
  _, _, _, _, _, _, _, _, _, _, _, _, _, 1.19185902208985, 1.80045157297921, 
    _, _, _, _, _, _, _, _, _, _, _, _, 1.57414746517039,
  1.44516740889483, _, _, _, _, _, _, _, _, _, _, _, _, 0.535210380228004, _, 
    _, _, _, _, _, _, _, _, _, 1.63590621546601, 1.12290264923592, _, 
    1.0379952697985,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    2.93917630608872, 1.00019382259695, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1.25519222328257, _, _, _, _, 
    _, _, _, _, _, 1.62346618318387, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, -3.73573073969798, _, _, 
    _, 1.30789477562449, _, _, 1.88839615668884, 1.10251807685896, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0.767491124260355, 
    1.0435424983137, _, _, _, _, _, _, _, _, _, _, _, _,
  0.497859242377916, 0.847398592055313, _, 1.10679950541094, 
    1.14485975410767, _, _, _, _, _, _, _, _, _, _, 0.822308400637684, _, _, 
    _, _, _, _, _, _, _, _, _, _,
  _, 1.14433611932668, _, _, 1.20416714756819, _, _, 0.822481121256427, _, _, 
    _, 2.55155173844496, _, _, 0.721154162302311, _, _, _, _, _, _, _, 
    0.589215882883785, _, _, 2.47809820306954, _, _,
  0.618618924846229, 0.592073932162277, _, 0.801761112867241, 
    1.01315765973217, _, _, 1.65415331076286, _, _, _, 0.679685064997751, _, 
    _, _, _, _, _, _, _, 1.02468327105447, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0.888313899466666, _, _, _, _, 
    _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0.915079809314154, 
    0.700681981335248, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0.943997355094668, 
    0.94935103354662, 0.830421372829799, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1.00435783127212, _, 
    _, _, 2.21483799796112, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1.47051238928131, _, _, _, _, 
    _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, 0.738057191315933,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, 0.525477882359419,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _ ;

 offset =
  0.339926361232754, 0.59904778143984, 1.8853032198932, _, _, _, _, _, 
    0.659841425665514, _, _, 0.623741019624024, 0.0375875907759184, 
    -0.249789712087369, -0.693844538475688, _, 0.384867759674702, 
    0.561571453997352, 0.38986272121624, 0.27384196350447, 
    -0.242018073656964, 0.692628255554377, 0.336789974196416, 
    0.054325232839154, -0.0398201429283699, 0.133185609252942, 
    0.0356540446761264, -0.256780792507791,
  -0.275389959606572, -1.34324267717885, -0.409499943371648, _, _, _, _, _, 
    _, 1.47961990645147, 4.42592983808751, 0.0251330133699079, 
    0.669553768022084, 0.25790895074152, 0.407088681154257, 
    0.383887776330239, 0.156446966998522, 0.112112190865878, 
    0.229712147541902, 0.284290419530323, 0.795496617050067, 0.1241761529384, 
    0.392939328881974, -0.199272281462051, -0.0703269014905641, 
    -0.0217365643218761, 0.0234308762400948, -0.124096747863542,
  0.0637496889659974, -0.56112476581184, _, _, _, -0.296446988561062, _, _, 
    0.241031174397054, 1.63273880420854, -0.174165532175383, 
    0.0668614356162577, _, 0.480260481455887, _, 0.419724285072616, 
    0.276831353919239, 0.145058917476923, 0.266841511937787, 
    0.19852160845819, -0.44258239057667, 0.0643587933158893, 
    0.247418890501958, 0.239997120656179, -0.20648111548272, 
    0.0345101017146354, -0.0471111004374569, 0.194064536529752,
  0.365832072338069, -0.147845680408459, _, _, _, _, _, 0.081793327213448, 
    -0.0726991173322125, 1.31673888694331, _, 0.430302449694759, 
    0.379269357995424, _, _, 0.053752187137356, 1.48281614349779, _, 
    0.51892673992674, 0.313830724156026, -0.0857838047644457, 
    0.108676283054964, 0.239389986042925, 0.387714996875135, 
    0.021744167323007, -0.156622980541976, 0.119143417481766, 0.10340169718571,
  0.533546450298038, -0.0104077996580051, -0.187698717573871, _, _, _, _, _, 
    0.381849334411884, 0.623107887414724, 0.228090628118482, 
    0.75501458257376, 0.207168345321932, 0.324350415266, 0.165264318120741, 
    0.104339749689337, 0.335928400040745, 0.886046071154339, _, 
    0.3135236473461, -1.19697135061394, -0.0948204082234181, 
    0.314768670632036, 0.135857929226736, -0.360728011825574, 
    -0.0372075897440853, 0.0246110926691046, 0.280740234546252,
  _, -0.0306897158362404, -0.0342322096772362, -0.17005945687283, _, 
    -0.156308703227056, _, _, -0.244136882524737, -0.402625458879399, _, _, 
    0.0810384526620385, 0.14993081854547, -0.029330899408284, 
    -0.189955500932565, -0.0319235222437065, _, _, _, _, 0.399494981981123, 
    0.224664000799761, 0.153651184441919, 0.172546453644774, 
    -0.191442788914657, -0.337136108117074, 0.110357563277036,
  0.0667692030794089, -0.060710349793021, -0.105458991614311, 
    -0.28689376401974, -0.206051345664611, _, _, -0.889522828556577, 
    0.203308723726691, -0.197800400796679, -0.474824778393695, _, 
    -0.0162264955782894, 0.0203057486175488, 0.0378586344314228, 
    0.00704584572260741, -0.018290290505524, _, _, _, -0.0987576835153674, _, 
    0.0677815726535612, 0.00974468744191759, 0.387313354043438, 
    0.758410487063086, 0.685761137095249, -0.946514569896682,
  0.326289588981218, -0.229846602083468, -0.262224643326832, 
    -0.210144670260248, -0.407054876958222, _, _, 0.285694175515846, 
    0.0794414265675235, 0.229734643853509, 0.188748006858634, 
    -0.733665525682526, 0.129536784196549, _, 0.167448486528042, 
    -0.0152122808632032, _, _, _, _, _, _, 0.109444399879675, 
    0.184622226591024, 0.035813266746282, -0.497972991424987, 
    1.5491548946833, 0.0310410908527853,
  0.202812154924827, 0.151795695695397, 0.525655668500994, 0.426748038950964, 
    -0.166166187413808, _, _, -0.355339902936724, -0.183412296186966, _, _, 
    0.130358511859941, _, _, _, 0.11783542291148, _, _, _, _, 
    -0.128416558733183, _, _, _, _, 0.141708895370033, -0.235301357170111, 
    0.134403225806451,
  13.6685405405476, 0.201343533765833, _, _, _, _, 0.18632580360025, 
    -0.666842096365776, _, _, _, _, 0.535654413316877, -0.0151415288627745, 
    _, 0.0362774361260447, _, -0.0722078326720164, _, _, _, _, _, _, _, _, 
    0.193708521007031, 0.262488262986102,
  _, _, _, _, _, _, _, -0.616813229840336, _, _, _, _, 0.390329482127633, _, 
    0.0509165225752956, 0.0736251285075844, 0.175359691313711, _, _, _, _, _, 
    _, _, _, _, _, _,
  _, _, _, _, _, _, _, 0.51061279190885, -0.069414077551582, 
    0.0115654394111512, _, _, _, _, -0.00323812211721434, 0.115550402440705, 
    0.164433027732823, _, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, 0.71525037857428, 0.498624124953925, _, _, _, _, 
    _, _, _, 0.0709987271267541, _, _, _, -0.228378743480766, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, 2.24409727007266, _, _, _, _, 
    -0.420918881040475, _, _, _, _, 0.0110339294684687, _, 
    0.0958383121732638, _, _, _, _, 0.190372559157765,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    -0.538193323936265, _, _, _, _, _, 0.269190075531521,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, 0.256643236232491,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    -0.249882912926301, -0.494262694651322, _, _, _, _, _, _,
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
    _, _, _ ;

 n_samples =
  3, 3, 3, 1, 2, 0, 2, 2, 3, 1, 2, 3, 4, 4, 4, 2, 4, 4, 4, 3, 3, 4, 3, 5, 4, 
    5, 5, 5,
  4, 4, 3, 2, 1, 1, 0, 0, 1, 3, 3, 4, 4, 4, 4, 4, 4, 4, 3, 5, 3, 4, 4, 4, 5, 
    5, 5, 5,
  4, 3, 1, 1, 2, 3, 1, 2, 3, 3, 3, 3, 2, 3, 2, 3, 4, 3, 5, 5, 3, 5, 5, 4, 5, 
    5, 5, 5,
  3, 4, 2, 2, 2, 2, 2, 3, 3, 3, 2, 3, 3, 2, 2, 5, 3, 2, 3, 4, 3, 4, 5, 3, 5, 
    5, 5, 5,
  4, 3, 3, 2, 2, 2, 1, 2, 4, 4, 3, 3, 5, 4, 3, 4, 3, 3, 2, 4, 3, 4, 4, 3, 5, 
    5, 5, 5,
  2, 3, 4, 3, 2, 3, 0, 0, 3, 3, 2, 2, 3, 3, 4, 3, 4, 2, 2, 1, 2, 4, 3, 3, 4, 
    5, 5, 5,
  4, 3, 3, 4, 4, 2, 0, 3, 3, 3, 4, 2, 3, 3, 3, 4, 3, 1, 1, 2, 3, 2, 3, 3, 3, 
    4, 5, 4,
  4, 5, 3, 3, 4, 0, 0, 4, 3, 3, 4, 4, 3, 2, 3, 3, 2, 1, 1, 2, 2, 2, 3, 3, 3, 
    4, 5, 3,
  5, 4, 3, 3, 3, 0, 1, 5, 3, 2, 2, 3, 2, 2, 2, 3, 2, 1, 1, 2, 3, 1, 2, 2, 2, 
    3, 4, 3,
  3, 3, 2, 0, 0, 0, 3, 3, 2, 1, 1, 2, 3, 3, 2, 3, 2, 3, 1, 1, 1, 1, 1, 1, 2, 
    2, 4, 4,
  0, 0, 0, 0, 0, 0, 1, 3, 2, 2, 0, 1, 3, 2, 3, 3, 3, 2, 2, 1, 1, 1, 1, 0, 0, 
    0, 1, 1,
  0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 2, 1, 1, 2, 3, 3, 3, 2, 2, 1, 1, 1, 1, 1, 1, 
    1, 1, 1,
  0, 0, 0, 0, 0, 0, 0, 0, 1, 4, 5, 2, 1, 1, 1, 2, 1, 2, 4, 1, 2, 1, 3, 2, 0, 
    1, 1, 1,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 2, 1, 1, 1, 3, 2, 1, 2, 2, 3, 2, 3, 2, 2, 
    1, 2, 3,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 3, 2, 2, 2, 
    1, 1, 3,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 2, 2, 1, 2, 
    2, 2, 3,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 2, 2, 1, 1, 1, 
    1, 1, 1,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 3, 3, 2, 1, 1, 
    1, 2, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 1, 1, 
    1, 0, 0 ;
}
