#$Id: Giovanni-Visualizer-Hints_correlationTime.t,v 1.7 2014/04/07 14:07:45 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 SYNOPIS
This tests a correlation case where there needs to be a time caption. Also tests
to make sure that units come through in the subtitles.
=cut

use strict;
use File::Temp;
use Test::More tests => 8;
BEGIN { use_ok('Giovanni::Visualizer::Hints') }

# read the cdl
my $cdl = readCdlData();

# write it out as netcdf
my $tmpFile = writeNetCdf($cdl);

my $varInfo = <<VARINFO;
<varList>
  <var id="TRMM_3B42_daily_precipitation_V6" south="-50.0" dataProductEndTimeOffset="-5401" dataProductTimeInterval="daily" long_name="Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg." west="-180.0" dataProductVersion="6" east="180.0" accessFormat="netCDF" north="50.0" sdsName="precipitation" dataProductShortName="TRMM_3B42_daily" accessMethod="HTTP_Services_HDF_TO_NetCDF" resolution="0.25 x 0.25 deg." dataProductStartTimeOffset="-5400" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Daily+TRMM+and+Others+Rainfall+Estimate+(3B42+V6+derived)+V6;agent_id=HTTP_Services_HDF_TO_NetCDF&amp;start=2002-12-31T22:30:00&amp;end=2003-01-03T22:29:58&amp;output_type=xml" quantity_type="Precipitation" dataFieldUnitsValue="mm">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/trmm_precipitation_sld.xml" label="Precipitation"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/trmm_precipitation_panoply_diff_sld.xml" label="Panoply"/>
    </slds>
  </var>
  <var id="TRMM_3B42_daily_precipitation_V7" south="-50.0" dataProductEndTimeOffset="-5401" dataProductTimeInterval="daily" long_name="Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg." west="-180.0" dataProductVersion="7" east="180.0" accessFormat="netCDF" north="50.0" sdsName="precipitation" dataProductShortName="TRMM_3B42_daily" accessMethod="HTTP_Services_HDF_TO_NetCDF" resolution="0.25 x 0.25 deg." dataProductStartTimeOffset="-5400" url="http://s4ptu-ts2.ecs.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=Daily+TRMM+and+Others+Rainfall+Estimate+(3B42+V7+derived)+V7;agent_id=HTTP_Services_HDF_TO_NetCDF&amp;start=2002-12-31T22:30:00&amp;end=2003-01-03T22:29:58&amp;output_type=xml" quantity_type="Precipitation" dataFieldUnitsValue="mm">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/trmm_precipitation_sld.xml" label="Precipitation"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/trmm_precipitation_panoply_diff_sld.xml" label="Panoply"/>
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
        "TRMM_3B42_daily_precipitation_V6",
        "TRMM_3B42_daily_precipitation_V7"
    ],
    varInfoFile   => [$varInfoFile],
    userStartTime => "2003-01-01T00:00:00Z",
    userEndTime   => "2003-01-03T23:59:59Z"
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

my $correctSubtitle
    = qq(1st Variable: Daily Rainfall Estimate from )
    . qq(3B42 V6, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 6]\n2nd Variable: )
    . qq(Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 7]);

my $correctCaption
    = qq(- Selected date range was 2003-01-01 - 2003-01-03. )
    . qq(The data date range for the first variable, Daily Rainfall Estimate )
    . qq(from 3B42 V6, TRMM and other sources, 0.25 deg. )
    . qq([TRMM_3B42_daily V6], is 2002-12-31 22:30Z - 2003-01-03 22:29Z. )
    . qq(The data date range for the second variable, Daily Rainfall Estimate )
    . qq(from 3B42 V7, TRMM and other sources, 0.25 deg. )
    . qq([TRMM_3B42_daily V7], is 2002-12-31 22:30Z - 2003-01-03 22:29Z.);

# correlation
my $subtitleText
    = $xpc->findvalue( qq(/nc:netcdf/nc:variable[\@name="correlation"]/)
        . qq(nc:attribute[\@name="plot_hint_subtitle"]/\@value) );
is( $subtitleText, $correctSubtitle,
    "correlation variable subtitle correct" );
my $captionText
    = $xpc->findvalue( qq(/nc:netcdf/nc:variable[\@name="correlation"]/)
        . qq(nc:attribute[\@name="plot_hint_caption"]/\@value) );
is( $captionText, $correctCaption, "correlation variable caption in file" );

#n_samples
$subtitleText
    = $xpc->findvalue( qq(/nc:netcdf/nc:variable[\@name="n_samples"]/)
        . qq(nc:attribute[\@name="plot_hint_subtitle"]/\@value) );
is( $subtitleText, $correctSubtitle, "n_samples variable subtitle correct" );
$captionText
    = $xpc->findvalue( qq(/nc:netcdf/nc:variable[\@name="n_samples"]/)
        . qq(nc:attribute[\@name="plot_hint_caption"]/\@value) );
is( $captionText, $correctCaption, "n_samples variable caption in file" );

#time_matched_difference
$correctSubtitle
    = qq(Var. 1: Daily Rainfall Estimate from )
    . qq(3B42 V6, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 6]\nVar. 2: )
    . qq(Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 7]);
$subtitleText
    = $xpc->findvalue(
          qq(/nc:netcdf/nc:variable[\@name="time_matched_difference"]/)
        . qq(nc:attribute[\@name="plot_hint_subtitle"]/\@value) );
is( $subtitleText, $correctSubtitle,
    "time_matched_difference variable subtitle correct" );
$captionText
    = $xpc->findvalue(
          qq(/nc:netcdf/nc:variable[\@name="time_matched_difference"]/)
        . qq(nc:attribute[\@name="plot_hint_caption"]/\@value) );
is( $captionText, $correctCaption,
    "time_matched_difference variable caption in file" );

# history removed
my @nodes
    = $xpc->findnodes( qq(/nc:netcdf/) . qq(nc:attribute[\@name="history"]) );
is( scalar(@nodes), 0, 'history removed' );

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
netcdf correlation.TRMM_3B42_daily_precipitation_V6+TRMM_3B42_daily_precipitation_V7.20030101-20030103 {
dimensions:
	lon = 14 ;
	lat = 12 ;
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
		correlation:long_name = "Correlation of Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 6] vs. Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 7]" ;
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
	double time_matched_difference(lat, lon) ;
		time_matched_difference:long_name = "Time matched difference between Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 6] and Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 7]" ;
		time_matched_difference:_FillValue = 9.96920996838687e+36 ;
		time_matched_difference:quantity_type = "Precipitation_difference" ;
	int n_samples(lat, lon) ;
		n_samples:long_name = "Number of samples" ;
		n_samples:quantity_type = "count" ;
		n_samples:units = "count" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:title = "Correlation of Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 6] vs. Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 7]" ;
		:plot_hint_caption = "The data date range for the first variable, Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily V6], is 2002-12-31 22:30Z - 2003-01-03 22:29Z. The data date range for the second variable, Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily V7], is 2002-12-31 22:30Z - 2003-01-03 22:29Z." ;
		:matched_start_time = "2003-01-01T00:00:00Z" ;
		:matched_end_time = "2003-01-03T23:59:59Z" ;
data:

 lon = -81.125, -80.875, -80.625, -80.375, -80.125, -79.875, -79.625, 
    -79.375, -79.125, -78.875, -78.625, -78.375, -78.125, -77.875 ;

 lat = 34.625, 34.875, 35.125, 35.375, 35.625, 35.875, 36.125, 36.375, 
    36.625, 36.875, 37.125, 37.375 ;

 correlation =
  _, 0.99988254871044, 1, 1, 0.623686729901874, -0.00775743544473478, 
    0.89997705742233, -0.453712894638502, 0.992205535225293, 
    0.999826168783711, 1, 0.999978029216266, 0.999958044831646, 
    0.9999912179161,
  _, 1, _, 1, 1, 0.860845501040345, 0.990536064799671, 0.992097689269591, 
    0.997129560683356, 0.999965933107577, 0.998089084670497, 
    0.999998396324839, 0.999999992836015, 0.999546622396067,
  1, 1, 1, 1, 1, 0.999576799554785, 1, 0.999881517071977, 0.999932177487368, 
    0.999638836205989, 0.999999960388347, 0.999997598545951, 
    0.999999914033072, 0.999999385440686,
  1, 1, 0.999999985027131, 0.997833820424324, 1, 1, 1, 0.999995439063554, 
    0.985793310713774, 0.967429830379097, 0.987702667312555, 
    0.992852037654881, 0.994462161528755, 0.9997225017738,
  1, 1, 0.999997539401694, -0.809476242009824, 0.99816974721968, 1, 
    0.999976413668336, 0.999943614752494, 0.992998852971614, 
    0.773735824341841, 0.984512540489318, 0.999394837308369, 
    0.999999865226161, 0.999984888670542,
  1, 1, 1, -0.264047488142496, 0.771981465230255, 1, 1, 1, 0.999928422910451, 
    0.991118873736568, 0.999571844509322, 0.986233729370097, 
    0.999268682882902, 1,
  1, 0.999999025440895, 0.998280971051408, 0.999989027746569, 
    -0.40964401249871, 0.98333537086917, 1, 1, 0.999138695334816, 
    0.991606383072272, 0.988080323982765, 0.998969709088631, 1, 
    0.999999997551153,
  1, 0.999981249544519, 0.999908358088319, _, 1, 0.971580968708402, 1, 1, 1, 
    1, 1, 1, 1, 0.851624680646871,
  1, 1, _, _, 1, 0.98677850250411, 1, 1, 1, 1, 1, 0.996235148695474, 
    0.99536446251913, 0.941747581147978,
  1, 1, 1, 1, 1, 1, 1, 1, 0.998136708106918, 1, 1, 1, 1, 0.999991632515188,
  1, 1, 1, _, 1, 1, 0.937664975066173, 1, 1, 0.940934083522564, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ;

 slope =
  _, 2.78386800359293, _, 3.02677891834318, _, _, _, _, 2.06680478179383, 
    0.550177622845148, 1.19711132235123, 1.39326849531539, 0.772328892591824, 
    1.02935938246177,
  _, 0.0214245364963418, _, 5.25530939226519, 4.74801683120687, _, 
    3.29599242725931, 2.00358618259554, 1.19818143583691, 0.792398195922179, 
    0.803547472817992, 0.996085884389959, 0.85135935838152, 0.686992175512189,
  0.0492886583908561, 26.7857132213457, 0.769157230862127, 
    0.0522211041088838, 47.4264520386771, 6.00312969775655, 3.76435434735667, 
    2.16423681768981, 0.831907382184389, 0.733812727479111, 
    0.967267496697606, 0.983286470883403, 1.01265040114838, 1.43413095542049,
  1.7883403951096, 0.959178601896924, 1.00504823142623, 5.75222828710218, _, 
    16.0613198902891, 4.31930409834268, 1.11801344422658, _, _, 
    1.18521531545038, 0.942014377187509, 1.26480813651273, 0.918248458411964,
  1.48551473597208, _, 0.960145202014465, _, 17.4091738730264, 
    9.56971468063055, 3.38898905172547, 1.56613811369501, 1.89590354940317, 
    _, _, 1.23219953643045, 1.10110475061089, 0.897304711038049,
  0.862313081777539, _, 1.7182554877774, _, _, 3.9653368941393, 
    4.06451289859651, 1.02625021789815, 1.16948104421119, 1.2691054066057, 
    0.924064649134333, _, 1.01846790851331, 1.01113360657685,
  1.42186790513842, 1.38312366294696, 1.46922766780881, 2.90768960515167, _, 
    _, _, _, 1.03634530336784, 0.78610119684742, 0.959477732905725, 
    0.59568694373398, 0.793091388956431, 1.1313174814386,
  39.5625004074536, 1.58334901620257, 1.78884198378343, _, 3.42857121231875, 
    _, 1.69466171348822, _, 1.19370680442221, 0.843590344225014, 
    0.890142113490429, 0.558855567861884, 1.18888581652638, _,
  _, 5.35779444376628, _, _, _, _, 1.46259435017904, 1.28210690058177, 
    1.1088791325985, 0.904400930893841, _, 1.30763149667526, 
    1.58882297922528, _,
  1.78440775185047, 1.1106383321223, 0.857142803079687, 1.59677406846753, _, 
    _, 1.32158350650751, 1.05095341219812, 1.58403742819899, 
    0.753262832553077, 0.479220797664811, 0.549999986754523, _, 
    0.933164128198053,
  1.17609706467419, 1.00914030431461, 0.371249993642171, _, _, 
    0.702127650323278, _, 0.801473651060715, 1.67388672406091, _, 
    0.919939475776865, 0.544485536049715, _, _,
  _, 1.00124960255573, _, _, _, _, 1.68769056426792, _, 1.09398496779736, _, 
    0.624999979931095, _, _, _ ;

 offset =
  0, -0.0299248910744672, 0, 0, -0.316904127022634, 10.8978536549984, 
    -5.48685121339571, 10.3896980285645, -1.52179993324218, 
    0.103918766664105, 0, -0.161743066332226, 0.190068015042376, 
    0.0806699361844162,
  0, 0, 0, 0, 0, -4.86772756963329, -2.41414086529865, -2.15444604841469, 
    -1.06450886920646, 0.111382905373452, 0.821219861015416, 
    0.0307714933598705, 0.00232483462056147, -0.50060179019681,
  0, 0, 0, 0, 0, 0.62369692325592, 0, -0.330017948600002, 0.218182625378053, 
    0.391369723951256, 0.00491280103070106, 0.0330794678903802, 
    0.00595548644121043, -0.0113117754295201,
  0, 0, 0.00224549914083857, -0.275876481484371, 0, 0, 0, 0.0467309483882907, 
    -1.52854503655368, 1.41360544400366, -1.5531384433537, 0.763103612944287, 
    -0.585143923698382, 0.173833381045699,
  0, 0, 0.0161587505193849, 16.462424593496, -0.741692312676316, 0, 
    -0.155750293874114, -0.170803379796634, -1.52330483984111, 
    2.54196227952245, 1.11933001148498, -0.209478284539176, 
    8.67500788110931e-05, 0.0445976692964999,
  0, 0, 0, 9.38939204582801, -3.05691375125217, 0, 0, 5.9211894646675e-16, 
    0.145595824727175, -0.505392783396953, -0.186997440356979, 
    -1.60130878229297, 0.336345041934165, 0,
  0, 0.0186619476377174, -0.423261023482258, -0.0839895249968166, 
    6.47999954223633, -0.977142805892491, 0, 0, 0.681883518710392, 
    0.302268565511543, 0.30575652685705, 0.334767609381333, 0, 
    0.000696095251059366,
  0, 0.0885459928824398, 0.0979088606480107, _, 0, 0.492241965381076, 0, 0, 
    0, 0, 0, 0, 0, 0.508770616345902,
  0, 0, _, _, -1.1842378929335e-15, 1.6994035243988, 0, 0, 0, 0, 0, 
    -1.89153190064912, -1.68439862589633, -1.54800525675496,
  0, 0, 0, 0, 0, 0, 0, 0, -1.79392490259888, 0, 0, 2.96059473233375e-16, 0, 
    0.0370905662418638,
  0, 0, 0, 0, -5.9211894646675e-16, 0, 2.85222363471985, 0, 0, 3.375, 0, 0, 
    -2.368475785867e-15, 0,
  0, 0, 0, 0, 0, 0, 0, -1.1842378929335e-15, 0, -5.9211894646675e-16, 
    5.9211894646675e-16, -1.1842378929335e-15, 0, 0 ;

 time_matched_difference =
  0.365403925999999, -0.718147869532307, -1.25655968983968, 
    -0.911978046099345, -4.21671545505524, -9.06538891792297, 
    -7.62680276234945, -6.52315557003021, -3.83042820294698, 
    2.60412447651227, -1.46165720621745, -3.87562004725138, 3.52960701783498, 
    -0.508227348327637,
  1.18442370742559, 1.78100720047951, 0.540791392326355, -5.87624359130859, 
    -8.31557099024455, -6.39633766810099, -7.0301525592804, 
    -4.32431689898173, -0.749610424041748, 2.06397606929143, 
    1.56915283203125, 0.0100934108098348, 1.96732895324628, 5.18171727657318,
  1.15731853743394, -7.2199999888738, 2.23664728800456, 3.7371601263682, 
    -12.4660775065422, -10.9358909130096, -7.71200720469157, 
    -6.57951468974352, 2.07008757193883, 2.72604990005493, 0.336694155509273, 
    0.115889961520831, -0.110473833978176, -1.81648899614811,
  -5.06173833211263, 0.387882232666016, -0.0400566632548968, 
    -2.10023746142785, -6.28329467773438, -12.5406049092611, 
    -9.81527328491211, -1.02781431873639, 1.66696580251058, 3.66556040445964, 
    -0.0620854695638021, -0.445087353388468, -0.978676637013753, 
    0.359913984934489,
  -3.05347696940104, -4.1209971110026, 0.159999441355467, -4.37769818305969, 
    -6.90726641813914, -10.9692345460256, -9.24425912648439, 
    -3.36698643366496, -3.74597104390462, 0.893879254659017, 
    0.819595336914062, -1.12334696451823, -0.714630444844564, 
    0.505134999752045,
  0.977704366048177, 0.667182922363281, -1.55300982793172, -6.71595395853122, 
    -6.9805327852567, -4.61408233642578, -2.37846271197001, 
    -0.102395057678223, -1.18840811649958, -1.1854674021403, 
    0.610331853230794, -1.77145493030548, -0.434939344724019, 
    -0.0525859196980794,
  -1.93215497334798, -2.59789180755615, -1.62813766797384, -6.86000015089909, 
    -4.37999967734019, -3.47999969994028, -4.81563584009806, 
    -4.97008323669434, -1.02973554531733, 1.1052672068278, 
    -0.0152947107950846, 2.60007644693057, 0.828292846679688, 
    -0.672120874126752,
  -6.16999992728233, -4.04599086443583, -3.6257758140564, -7.53000005086263, 
    -3.05999970436096, 1.00000007947286, -3.97346496582031, 
    -4.91940307617188, -2.4370600382487, 1.30157470703125, 0.596099853515625, 
    3.31733957926432, -1.15350977579753, 1.24012303352356,
  -6.05993413925171, -4.35779444376628, -3.95999972025553, -8.27999941507975, 
    -0.859999974568685, -0.493064085642497, -4.62594350179036, 
    -3.49965413411458, -1.34803771972656, 0.995734532674154, 3.9356590906779, 
    -1.68562308947245, -2.92714905738831, 1.29635540644328,
  -5.17709096272786, -0.520000139872233, 0.360000133514404, 
    -0.739999850591024, -3.5585454305013, -5.65290832519531, 
    -3.50494257609049, -0.610623677571615, -5.36701226234436, 
    2.2208423614502, 4.00999959309896, 2.16000000635783, -2.00999959309896, 
    0.407179435094198,
  -1.74285761515299, -0.0975494384765625, 5.03000005086263, 4.43999989827474, 
    1.01999982198079, 1.96000003814697, 1.04488865534465, 1.73143450419108, 
    -5.62818018595378, -0.929548899332682, 0.530000686645508, 
    2.68547344207764, -6.80272102355957, -1.51896985371908,
  -1.94105275472005, -0.0143025716145833, -1.31973648071289, 
    6.22998094558716, 4.63999970753988, 1.42999998728434, -4.96512540181478, 
    -0.518376668294271, -0.75, 3.35000038146973, 2.96999994913737, 
    -1.30112075805664, -5.34296290079753, -1.70000012715658 ;

 n_samples =
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3 ;
}
