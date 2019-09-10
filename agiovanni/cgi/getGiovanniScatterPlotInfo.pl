#!/usr/bin/perl -T

#$Id: getGiovanniScatterPlotInfo.pl,v 1.31 2015/02/06 21:09:13 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use strict;
use Giovanni::Util;
use Giovanni::Data::NcFile;
use Giovanni::WorldLongitude;
use Giovanni::CGI;
use File::Basename;
use XML::XML2JSON;
use URI;
use Safe;

# Disable output buffering
$| = 1;

# Unset PATH and ENV (needed for taint mode)
$ENV{PATH} = undef;
$ENV{ENV}  = undef;

# Configuration file for Giovanni: contains environment variables and input validation rules
my $cfgFile = ( defined $rootPath ? $rootPath : '/tools/gdaac/TS2/' )
    . 'cfg/giovanni.cfg';

# Read the configuration file
my $error = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    ,
);

# Validate user input; first to satisfy taint mode and later with stricter rules
my %input = $cgi->Vars();


# Form the result directory where session files exist
my $resultDir
    = qq($GIOVANNI::SESSION_LOCATION/$input{session}/$input{resultset}/$input{result}/);
my $dataFile  = $resultDir . $input{filename};
my $scaleFile = $resultDir . "scale.map";
exit_with_error("Data file doesn't exist") unless ( -f $dataFile );

# Get vairable names

my $mapFile       = $dataFile;
my $mapFileSuffix = '.map';
$mapFile =~ s/\.([^.]+)$/$mapFileSuffix/;
my $mapXMLFile = $mapFile . ".xml";

#Generate shifted data
my $tmpInFile
    = dirname($dataFile) . '/'
    . basename( $dataFile, '.nc' )
    . '_shifted_lon.nc';
unless ( -e $tmpInFile ) {
    my @longitudes
        = Giovanni::Data::NcFile::get_variable_values( $dataFile, "lon" );
    if ( Giovanni::WorldLongitude::fileNeedsNewLongitudeGrid(@longitudes) ) {
        Giovanni::WorldLongitude::normalize(
            in         => [$dataFile],
            out        => [$tmpInFile],
            cleanup    => 1,
            sessionDir => $resultDir
        );
    }
}
$dataFile = ( -f $tmpInFile ) ? $tmpInFile : $dataFile;

# Assign mask file name
my $maskFile = dirname($dataFile) . "/mask_" . basename($dataFile);

$tmpInFile
    = dirname($dataFile) . '/' . basename( $dataFile, '.nc' ) . '_paired.nc';
my %varInfo       = Giovanni::Util::getNetcdfDataVariables($dataFile);
my @layerNameList = keys %varInfo;

# see ticket 26497. Find the data variables by looking for variables that start
# 'x_' and 'y_'.
my $vX;
my $vY;
foreach my $layerName (@layerNameList) {
    if ( $layerName =~ /^x_/ ) {
        $vX = $layerName;
    }
    elsif ( $layerName =~ /^y_/ ) {
        $vY = $layerName;
    }
}
if ( !defined($vX) ) {
    die "Unable to find 'x' variable in $dataFile";
}
if ( !defined($vY) ) {
    die "Unable to find 'y' variable in $dataFile";
}
$tmpInFile = data_masking(
    $dataFile, $tmpInFile, $vX,   $vY,   undef, undef,
    undef,     undef,      undef, undef, undef, undef
);

$dataFile = ( -f $tmpInFile ) ? $tmpInFile : $dataFile;

# Read the contents of map template
#%varInfo = Giovanni::Util::getNetcdfDataVariables($dataFile);
#@layerNameList = keys %varInfo;

my $mapFileContent
    = Giovanni::Util::parseXMLDocument( $GIOVANNI::WMS{map_xml_template} );

# Extract layer portion of map file and remove it
my $xc = XML::LibXML::XPathContext->new($mapFileContent);
$xc->registerNs( 'ns', 'http://www.mapserver.org/mapserver' );
my ($layerNode)
    = $xc->findnodes('/ns:Map/ns:Layer[@name="SCATTER_PLOT_DATA_LAYER"]');
my $layerXpathContext = XML::LibXML::XPathContext->new($layerNode);
$layerXpathContext->registerNs( 'ns', 'http://www.mapserver.org/mapserver' );
my ($dataNode)
    = $layerXpathContext->findnodes(
    '/ns:Map/ns:Layer[@name="SCATTER_PLOT_DATA_LAYER"]/ns:data');
$dataNode->removeChildNodes();
$layerNode->setAttribute( "name", $layerNameList[0] );
$dataNode->appendText("'NETCDF:\"$dataFile\":datamask'");

my ($maskLayerNode) = $xc->findnodes('/ns:Map/ns:Layer[@name="LAYER_MASK"]');
my $maskLayerXpathContext = XML::LibXML::XPathContext->new($maskLayerNode);
$maskLayerXpathContext->registerNs( 'ns',
    'http://www.mapserver.org/mapserver' );
my ($maskDataNode)
    = $maskLayerXpathContext->findnodes(
    '/ns:Map/ns:Layer[@name="LAYER_MASK"]/ns:data');
$maskDataNode->removeChildNodes();
$maskLayerNode->setAttribute( "name", "mask_" . $layerNameList[0] );
$maskDataNode->appendText("'NETCDF:\"$maskFile\":datamask'");

Giovanni::Util::writeFile( $mapXMLFile, $mapFileContent->toString(1) );
my $mapXSLT = $GIOVANNI::WMS{map_xml_xslt};
system("xsltproc -o $mapFile $mapXSLT $mapXMLFile");
Giovanni::Util::writeFile( $scaleFile, "" );

my $sessionQuery
    = "session=$input{session}&resultset=$input{resultset}&result=$input{result}";
my $dataQuery
    = "filename="
    . URI::Escape::uri_escape( $input{filename} ) . "&"
    . $sessionQuery;
my $dataUrl = "daac-bin/netcdf_serializer.pl?" . $dataQuery;
my $dataMaskUrl
    = "daac-bin/filterScatterPlotData.pl?"
    . $dataQuery;

my $responseDoc = Giovanni::Util::createXMLDocument('scatterplot');
$responseDoc->setAttribute( 'data', $dataUrl );
foreach my $layer ( ( $layerNameList[0] ) ) {
    my $wmsGetMapQuery
        = 'service=wms&request=getmap&version=1.1.1&format=image/png&srs=epsg:4326&transparent=true&layers='
        . $layer . '&'
        . $sessionQuery
        . '&mapfile='
        . URI::Escape::uri_escape( basename($mapFile) );
    my $dataWmsUrl = "daac-bin/agmap.pl?" . $wmsGetMapQuery;
    my $layerNode  = XML::LibXML::Element->new('layers');
    $layerNode->setAttribute( 'url',   $dataWmsUrl );
    $layerNode->setAttribute( 'label', $layer );
    $responseDoc->appendChild($layerNode);
}
$responseDoc->setAttribute( 'filter', $dataMaskUrl );

# Print out as JSON
print $cgi->header(
    -type          => 'application/json',
    -cache_control => 'no-cache'
);
my $xml2Json = XML::XML2JSON->new(
    module           => 'JSON::XS',
    pretty           => 1,
    attribute_prefix => '',
    content_key      => 'value',
    force_array      => 1
);
my $jsonObj = $xml2Json->dom2obj( $responseDoc->parentNode() );
print $xml2Json->obj2json($jsonObj);

# A method to exit with 404 HTTP header with appropriate message
sub exit_with_error {
    my ($message) = @_;
    print $cgi->header(
        -status        => 404,
        -type          => 'text/plain',
        -cache_control => 'no-cache'
    );
    print $message;
    exit;
}

# A method to build mask data
sub data_masking {
    my ($infile, $outfile, $v1,   $v2,    $v1min, $v1max,
        $v2min,  $v2max,   $west, $south, $east,  $north
    ) = @_;
    print STDERR
        "\ndata_masking $infile, $outfile, $v1, $v2, $v1min, $v1max, $v2min, $v2max, $west, $south, $east, $north\n";

    my $sessionDir = dirname($infile);
    my ( $tmpFH1, $tmpFile1 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".tmp1",
        UNLINK => 1
    );
    my ( $tmpFH2, $tmpFile2 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".tmp2",
        UNLINK => 1
    );
    my ( $tmpFH3, $tmpFile3 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".tmp3",
        UNLINK => 1
    );
    my ( $tmpFH4, $tmpFile4 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".tmp4",
        UNLINK => 1
    );
    my ( $varFH1, $varFile1 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".var1",
        UNLINK => 1
    );
    my ( $varFH2, $varFile2 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".var2",
        UNLINK => 1
    );
    my ( $ncoFH1, $ncoFile1 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".nco1",
        UNLINK => 1
    );

    $v1min =~ s/\s+//g if defined($v1min);
    $v2min =~ s/\s+//g if defined($v2min);
    $v1max =~ s/\s+//g if defined($v1max);
    $v2max =~ s/\s+//g if defined($v2max);
    $west  =~ s/\s+//g if defined($west);
    $east  =~ s/\s+//g if defined($east);
    $north =~ s/\s+//g if defined($north);
    $south =~ s/\s+//g if defined($south);

    #
    # Filter the data (data within vmin and vmax retained) -- tmp1
    #
    my $v1_condition = "";
    my $v2_condition = "";
    if ( defined($v1min) and $v1min ne "" ) {
        $v1_condition .= "where($v1 < $v1min"
            if defined($v1min)
                and $v1min ne "";
    }
    if ( defined($v1max) and $v1max ne "" ) {
        if ($v1_condition) {
            $v1_condition .= ' || ' . "$v1 > $v1max)";
        }
        else {
            $v1_condition = "where($v1 > $v1max)";
        }
    }
    else {
        $v1_condition .= ")" if $v1_condition;
    }

    if ( defined($v2min) and $v2min ne "" ) {
        $v2_condition .= "where($v2 < $v2min"
            if defined($v2min)
                and $v2min ne "";
    }
    if ( defined($v2max) and $v2max ne "" ) {
        if ($v2_condition) {
            $v2_condition .= ' || ' . "$v2 > $v2max)";
        }
        else {
            $v2_condition = "where($v2 > $v2max)";
        }
    }
    else {
        $v2_condition .= ")" if $v2_condition;
    }

 # This is needed to create a mask field because the following is not working:
 # where(v != v.get_miss()), or
 # v[$lat,$lon] = v.get_miss()
 #- $v1_condition = "where($v1 >= 0 || $v1 < 0)" unless $v1_condition;
 #- $v2_condition = "where($v2 >= 0 || $v2 < 0)" unless $v2_condition;

    if ( !$v1_condition and !$v2_condition ) {
        system("/bin/cp $infile $tmpFile1");
        if ($?) {
            print STDERR "ERROR copy file $infile $tmpFile1 failed\n";
            return undef;
        }
    }
    elsif ( $v1_condition and !$v2_condition ) {
        system(
            "ncap2 -O -s \"$v1_condition $v1=$v1.get_miss()\" $infile $tmpFile1"
        );
        if ($?) {
            print STDERR
                "ERROR ncap2 failed: ncap2 -O -s \"$v1_condition $v1=$v1.get_miss()\" $infile $tmpFile1\n";
            return undef;
        }
    }
    elsif ( !$v1_condition and $v2_condition ) {
        system(
            "ncap2 -O -s \"$v2_condition $v2=$v2.get_miss()\" $infile $tmpFile1"
        );
        if ($?) {
            print STDERR
                "ERROR ncap2 failed: ncap2 -O -s \"$v2_condition $v2=$v2.get_miss()\" $infile $tmpFile1\n";
            return undef;
        }
    }
    else {
        system(
            "ncap2 -O -s \"$v1_condition $v1=$v1.get_miss(); $v2_condition $v2=$v2.get_miss();\" $infile $tmpFile1"
        );
        if ($?) {
            print STDERR
                "ERROR ncap2 failed: ncap2 -O -s \"$v1_condition $v1=$v1.get_miss(); $v2_condition $v2=$v2.get_miss();\" $infile $tmpFile1\n";
            return undef;
        }
    }

    #
    # Collapse time dimension so we can get a 2D mask
    #

    # Separate two variables into two separate files so we can rename time1
    system("ncks -O -v $v1 $tmpFile1 $varFile1");
    if ($?) {
        print STDERR
            "ERROR ncks failed: ncks -O -v $v1 $tmpFile1 $varFile1\n";
        return undef;
    }
    system("ncks -O -v $v2 $tmpFile1 $varFile2");
    if ($?) {
        print STDERR
            "ERROR ncks failed: ncks -O -v $v1 $tmpFile1 $varFile2\n";
        return undef;
    }

    # Check which file has time1 and rename it
    my $needMerge = 0;
    my $time1     = `ncks -m $varFile1|grep "RAM"|grep time1`;
    chomp($time1);
    if ($time1) {
        $needMerge = 1;
        system("ncrename -d time1,time $varFile1");
        if ($?) {
            print STDERR
                "ERROR ncrename failed: ncrename -d time1,time $varFile1\n";
            return undef;
        }
    }
    else {
        $time1 = `ncks -m $varFile2|grep "RAM"|grep time1`;
        chomp($time1);
        if ($time1) {
            $needMerge = 1;
            system("ncrename -d time1,time $varFile2");
            if ($?) {
                print STDERR
                    "ERROR ncrename failed: ncrename -d time1,time $varFile2\n";
                return undef;
            }
        }
    }

    # Merge two variables back into a single file to getting intersection
    if ($needMerge) {

        # delete global attribute to avoid ncks segment fault
        system("ncatted -h -a ,global,d,, $varFile2");
        if ($?) {
            print STDERR
                "ERROR: ncatted failed: ncatted -h -a ,global,d,, $varFile2\n";
            return undef;
        }
        system("ncatted -h -a ,global,d,, $varFile1");
        if ($?) {
            print STDERR
                "ERROR: ncatted failed: ncatted -h -a ,global,d,, $varFile1\n";
            return undef;
        }
        system("ncks -A -v $v2 $varFile2 $varFile1");
        if ($?) {
            print STDERR
                "ERROR: ncks failed: ncks -A -v $v2 $varFile2 $varFile1\n";
            return undef;
        }
    }
    else {
        $varFile1 = $tmpFile1;
    }

    # Create an intersection of two variables (from v1 file) -- tmp2
    system(
        "ncatted -h -a \"_FillValue,$v1,o,f,1.e36\" -a \"_FillValue,$v2,o,f,1.e36\" $varFile1"
    );
    if ($?) {
        print STDERR
            "ERROR: ncatted failed: ncatted -h -a \"_FillValue,$v1,o,f,1.e36\" -a \"_FillValue,$v2,o,f,1.e36\" $varFile1\n";
        return undef;
    }
    system("ncap2 -O -s \"vsum=$v1 + $v2\" $varFile1 $tmpFile2");
    if ($?) {
        print STDERR
            "ERROR ncap2 failed: ncap2 -O -s \"vsum=$v1 + $v2\" $varFile1 $tmpFile2\n";
        return undef;
    }

    # Collapse time dimension
    `ncwa -O -a time $tmpFile2 $tmpFile3`;
     if ($?) {
        print STDERR
        "No time dimension for removing: ncwa -O -a time $tmpFile2 $tmpFile3\n";
        system("/bin/cp $tmpFile2 $tmpFile3");
     }

    #
    # Create data mask
    #

    my $ncoStr = 'datamask[$lat,$lon] = -1;' . "\n"
        . "where(vsum>=0 || vsum <0) datamask = 1;\n";
    $ncoStr .= "where(lat<$south || lat > $north) datamask = -1;\n"
        if defined($south)
            and $south ne ""
            and defined($north)
            and $north ne "";
    $ncoStr .= "where(lon<$west || lon > $east) datamask = -1;\n"
        if defined($west)
            and $west ne ""
            and defined($east)
            and $east ne "";

    $| = 1;
    open( NCO, ">$ncoFile1" ) || die;
    print NCO "$ncoStr";
    close(NCO);

    system("ncap2 -O -S $ncoFile1 $tmpFile3 $tmpFile4");
    if ($?) {
        print STDERR
            "ERROR ncap2 failed: ncap2 -O -S $ncoFile1 $tmpFile3 $tmpFile4\n";
        return undef;
    }

    #
    # Create output file of the mask data
    #

    system("ncks -O -v datamask $tmpFile4 $outfile");
    if ($?) {
        print STDERR
            "ERROR ncks failed: ncks -v datamask $tmpFile4 $outfile\n";
        return undef;
    }
    system("ncatted -a \"_FillValue,datamask,o,l,-1\" $outfile");
    if ($?) {
        print STDERR
            "ERROR ncatted failed: ncatted -a \"_FillValue,datamask,o,l,-1\" $outfile\n";
        return undef;
    }
    return $outfile;

}
