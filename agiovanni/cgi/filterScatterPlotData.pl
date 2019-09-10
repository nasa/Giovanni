#!/usr/bin/perl -T 

eval 'exec /usr/bin/perl -T  -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

#$Id: filterScatterPlotData.pl,v 1.29 2015/04/30 13:58:55 rstrub Exp $
#-@@@ Giovanni, Version $Name:  $

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use strict;
use XML::LibXML;
use LWP::Simple;
use File::Temp;
use Giovanni::Util;
use Giovanni::CGI;
use Giovanni::Data::NcFile;
use Giovanni::WorldLongitude;
use File::Basename;
use XML::XML2JSON;
use Safe;

# Disable output buffering
$| = 1;

# Configuration file for Giovanni: contains environment variables and input validation rules
my $cfgFile = ( defined $rootPath ? $rootPath : '/tools/gdaac/TS2/' )
    . 'cfg/giovanni.cfg';
my $error = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    ,
);


my %input = $cgi->Vars();

# Form the result directory where session files exist
my $resultDir
    = qq($GIOVANNI::SESSION_LOCATION/$input{session}/$input{resultset}/$input{result}/);
my $dataFile = $resultDir . $input{filename};
exit_with_error("Data file doesn't exist") unless ( -f $dataFile );
my %varInfo       = Giovanni::Util::getNetcdfDataVariables($dataFile);
my @layerNameList = keys %varInfo;
my $maskFile      = $resultDir . "mask_" . $input{filename};
my ( $xvmin, $xvmax, $yvmin, $yvmax ) = split( ",", $input{xybox} );
my ( $xbmin, $ybmin, $xbmax, $ybmax ) = split( ",", $input{bbox} );
my $dType1 = getDataType( \%varInfo, $input{x} );
my $dType2 = getDataType( \%varInfo, $input{y} );
my $out    = data_masking(
    $dataFile, $maskFile, $input{x}, $input{y}, $xvmin,
    $xvmax,    $yvmin,    $yvmax,    $xbmin,    $ybmin,
    $xbmax,    $ybmax,    $dType1,   $dType2
);

if ( not defined $out ) {
    exit_with_error("Mask data generation is failed");
}

# Generate shifted data
my $tmpInFile
    = dirname($out) . '/' . basename( $out, '.nc' ) . '_shifted_lon.nc';
unlink $tmpInFile if -f $tmpInFile;
my @longitudes = Giovanni::Data::NcFile::get_variable_values( $out, "lon" );
if ( Giovanni::WorldLongitude::fileNeedsNewLongitudeGrid(@longitudes) ) {
    Giovanni::WorldLongitude::normalize(
        in         => [$out],
        out        => [$tmpInFile],
        cleanup    => 1,
        sessionDir => $resultDir
    );
}

$out = ( -f $tmpInFile ) ? $tmpInFile : $out;

#Collapse time dimension
#my @dimensions = split (" ",$varInfo{$layerNameList[0]}{coordinates});
#foreach my $dimension(@dimensions) {
#   if($dimension =~ /time/i) {
#      $tmpInFile = dirname($out) . '/collapse_' . basename( $out, '.nc' ) . '_shifted_lon.nc';
#      `ncwa -O -a $dimension $out $tmpInFile`;
#      $out = ( -f $tmpInFile ) ? $tmpInFile : $out;
#      last;
#    }
#}

my $mapFile       = $input{filename};
my $mapFileSuffix = '.map';
$mapFile =~ s/\.([^.]+)$/$mapFileSuffix/;
my $lName       = "mask_" . $layerNameList[0];
my $responseDoc = Giovanni::Util::createXMLDocument('maskMap');
$responseDoc->setAttribute( 'mapfile', $mapFile );
$responseDoc->setAttribute( 'name',    $lName );

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

# A method to get data type
sub getDataType {
    my ( $varInfo, $varName ) = @_;
    my $dataType    = 0;
    my $type        = $varInfo->{$varName}{type};
    my $scaleFactor = $varInfo->{$varName}{scale_factor};
    my $addOffset   = $varInfo->{$varName}{add_offset};
    if ( defined $type ) {
        if ( $type eq "int" || $type eq "short" || $type eq "long" ) {
            $dataType = 1;
            if ( defined $scaleFactor ) {
                if ( $scaleFactor != 1 ) {
                    $dataType = 0;
                }
            }
            if ( defined $addOffset ) {
                if ( !$addOffset =~ m/^[+-]?\d+$/ ) {
                    $dataType = 0;
                }
            }
        }
    }
    return $dataType;
}

# A method to build mask data
sub data_masking {
    my ($infile, $outfile, $v1,        $v2,   $v1min,
        $v1max,  $v2min,   $v2max,     $west, $south,
        $east,   $north,   $dataType1, $dataType2
    ) = @_;
    print STDERR
        "\ndata_masking $infile, $outfile, $v1, $v2, $v1min, $v1max, $v2min, $v2max, $west, $south, $east, $north\n";
    if (   defined $v1min
        || defined $v1max
        || defined $v2min
        || defined $v2max )
    {
        unless ($dataType1) {
            $v1min = sprintf( "%f", $v1min ) if defined $v1min;
            $v1max = sprintf( "%f", $v1max ) if defined $v1max;
        }
        unless ($dataType2) {
            $v2min = sprintf( "%f", $v2min ) if defined $v2min;
            $v2max = sprintf( "%f", $v2max ) if defined $v2max;
        }
    }
    my $sessionDir = dirname($infile);
    my ( $tmpFH1, $tmpFile1 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".tmp1",
        UNLINK => 0
    );
    my ( $tmpFH2, $tmpFile2 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".tmp2",
        UNLINK => 0
    );
    my ( $tmpFH3, $tmpFile3 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".tmp3",
        UNLINK => 0
    );
    my ( $tmpFH4, $tmpFile4 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".tmp4",
        UNLINK => 0
    );
    my ( $varFH1, $varFile1 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".var1",
        UNLINK => 0
    );
    my ( $varFH2, $varFile2 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".var2",
        UNLINK => 0
    );
    my ( $ncoFH1, $ncoFile1 ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".nco1",
        UNLINK => 0
    );

    # Do not check in
    chmod 0664, $tmpFile1;
    chmod 0664, $tmpFile2;
    chmod 0664, $tmpFile3;
    chmod 0664, $tmpFile4;
    chmod 0664, $varFile1;
    chmod 0664, $varFile2;
    chmod 0664, $ncoFile1;

    print STDERR "-- Temp Files: --\n";
    print STDERR "tmpFile1 = $tmpFile1\n";
    print STDERR "tmpFile2 = $tmpFile2\n";
    print STDERR "tmpFile3 = $tmpFile3\n";
    print STDERR "tmpFile4 = $tmpFile4\n";
    print STDERR "varFile1 = $varFile1\n";
    print STDERR "varFile2 = $varFile2\n";
    print STDERR "ncoFile1 = $ncoFile1\n";
    print STDERR "----\n";

    # /End

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
        `/bin/cp $infile $tmpFile1`;
    }
    elsif ( $v1_condition and !$v2_condition ) {
        `ncap2 -O -s "$v1_condition $v1=$v1.get_miss()" $infile $tmpFile1`;
    }
    elsif ( !$v1_condition and $v2_condition ) {
        `ncap2 -O -s "$v2_condition $v2=$v2.get_miss()" $infile $tmpFile1`;
    }
    else {
        `ncap2 -O -s "$v1_condition $v1=$v1.get_miss(); $v2_condition $v2=$v2.get_miss();" $infile $tmpFile1`;
    }

    if ($?) {
        print STDERR
            "ERROR ncap2 failed: ncap2 -O -s \"$v1_condition $v1=$v1.get_miss(); $v2_condition $v2=$v2.get_miss();\" $infile $tmpFile1\n";
        return undef;
    }

    #
    # Collapse time dimension so we can get a 2D mask
    #

    # Separate two variables into two separate files so we can rename time1
    `ncks -O -v $v1 $tmpFile1 $varFile1`;
    `ncks -O -v $v2 $tmpFile1 $varFile2`;

    # Check which file has time1 and rename it
    my $time1 = `ncks -m $varFile1|grep "RAM"|grep time1`;
    chomp($time1);
    if ($time1) {
        `ncrename -d time1,time $varFile1`;
    }
    else {
        $time1 = `ncks -m $varFile2|grep "RAM"|grep time1`;
        chomp($time1);
        if ($time1) {
            `ncrename -d time1,time $varFile2`;
        }
    }

    # Merge two variables back into a single file to getting intersection
    `ncks -h  -A -v $v2 $varFile2 $varFile1`;
    if ($?) {
        print STDERR
            "ERROR: ncks failed: ncks -A -v $v2 $varFile2 $varFile1\n";
        return undef;
    }

    # Create an intersection of two variables (from v1 file) -- tmp2
    `ncatted -h -a "_FillValue,$v1,o,f,1.e36" -a "_FillValue,$v2,o,f,1.e36" $varFile1`;
    `ncap2 -O -s "vsum=$v1 + $v2" $varFile1 $tmpFile2`;
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
    if ( $west > $east ) {
        $ncoStr .= "where(lon<$west && lon > $east) datamask = -1;\n"
            if defined($west)
                and $west ne ""
                and defined($east)
                and $east ne "";
    }
    else {
        $ncoStr .= "where(lon<$west || lon > $east) datamask = -1;\n"
            if defined($west)
                and $west ne ""
                and defined($east)
                and $east ne "";
    }

#if( $west > $east) {
#  $ncoStr .= "// cross meridian \n";
#
#}
#else {
#  $ncoStr .= "where(lon < $west || lon > $east) datamask = -1;\n" if defined($west) and $west ne "" and defined($east) and $east ne "";
#}

    $| = 1;
    open( NCO, ">$ncoFile1" ) || die;
    print NCO "$ncoStr";
    close(NCO);

    print STDERR "\n-- NCO SCRIPT --\n";
    print STDERR $ncoStr;
    print STDERR "\n--\n";

    `ncap2 -O -S $ncoFile1 $tmpFile3 $tmpFile4`;
    if ($?) {
        print STDERR
            "ERROR ncap2 failed: ncap2 -O -S $ncoFile1 $tmpFile3 $tmpFile4\n";
        return undef;
    }

    #
    # Create output file of the mask data
    #

    `ncks -O -v datamask $tmpFile4 $outfile`;
    if ($?) {
        print STDERR
            "ERROR ncks failed: ncks -v datamask $tmpFile4 $outfile\n";
        return undef;
    }
    `ncatted -a "_FillValue,datamask,o,l,-1" $outfile`;

    return $outfile;

}
