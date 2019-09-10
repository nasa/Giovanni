#!/usr/bin/perl -T 

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
use Giovanni::CGI;
use Giovanni::Map::Util;
use Giovanni::OGC::SLD;
use File::Basename;
use Safe;

$| = 1;

#Set the umask so that files/directories are group writable
umask 002;

## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
exit_with_error($error) if ( defined $error );

unless ( defined $GIOVANNI::SESSION_LOCATION ) {
    exit_with_error("Failed to find Giovanni session location");
}
my $logFile = $GIOVANNI::SESSION_LOCATION . "/mapserver.log";
open( FILE, ">>$logFile" ) or die "Could not open $logFile for writing";

my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
);
my @inputs  = $cgi->param();

#Get CGI parameters and values
my ($session, $resultset, $result,  $map,        $mapRQ,
    $sld,     $sldRQ,     $request, $layersList, $width,
    $height,  $srs,       $bbox,    $format
);

foreach (@inputs) {
    if (m/^layers{0,1}$/i) {
        $layersList = $cgi->param($_);
    }
    elsif (m/^session$/i) {
        $session = $cgi->param($_);
    }
    elsif (m/^resultset$/i) {
        $resultset = $cgi->param($_);
    }
    elsif (m/^result$/i) {
        $result = $cgi->param($_);
    }
    elsif (m/^request$/i) {
        $request = $cgi->param($_);
    }
    elsif (m/^width$/i) {
        $width = $cgi->param($_);
    }
    elsif (m/^height$/i) {
        $height = $cgi->param($_);
    }
    elsif (m/^srs$/i) {
        $srs = $cgi->param($_);
    }
    elsif (m/^crs$/i) {
        $srs = $cgi->param($_);
    }
    elsif (m/^bbox$/i) {
        $bbox = $cgi->param($_);
    }
    elsif (m/^format$/i) {
        $format = $cgi->param($_);
    }
    elsif (m/^mapfile$/i) {
        $map   = $cgi->param($_);
        $mapRQ = $_;
    }
    elsif (m/^sld$/i) {
        $sld   = $cgi->param($_);
        $sldRQ = $_;
    }
}

my $mapDir  = $GIOVANNI::SESSION_LOCATION . "/$session/$resultset/$result";
my $mapFile = $mapDir . "/" . $map;

# Get the main layer
( my $layers ) = split( ",", $layersList );

# Get the local SLD file name
my ( $sldUrl, $localSldFile );
$sldUrl = URI->new($sld) if defined $sld;
$localSldFile = dirname($mapFile) . '/' . basename( $sldUrl->path() )
    if defined $sldUrl;

# Get a copy of the SLD file locally
my $sldUrl
    = Giovanni::Util::convertFilePathToUrl( $localSldFile,
    \%GIOVANNI::URL_LOOKUP )
    if defined $localSldFile;
if ( defined $sldUrl ) {
    $cgi->param( $sldRQ, $sldUrl );
}
else {
    $cgi->delete($sldRQ);
}

# get legend without using MapServer
if ( defined $sld && $request =~ m/getlegendgraphic/i ) {
    my $legendImage = $localSldFile;
    $legendImage =~ s{\.[^.]+$}{};
    $legendImage = $legendImage . "_legend.png";
    unless ( not defined $map or $map =~ /undefined/i ) {
        my $sldInfo = Giovanni::OGC::SLD->new( FILE => $localSldFile );
        exit_with_error("Failed to read SLD $localSldFile")
            if ( $sldInfo->toString() eq '' );
        $sldInfo->setLayerName($layers);
        my $intFlag = 0;

        my $mapXmlFile     = $mapFile . ".xml";
        my $mapFileContent = Giovanni::Util::parseXMLDocument($mapXmlFile);
        my $xc             = XML::LibXML::XPathContext->new($mapFileContent);
        $xc->registerNs( 'ns', 'http://www.mapserver.org/mapserver' );
        my $dType = $xc->findvalue(
            '/ns:Map/ns:Layer[@name="' . $layers . '"]/ns:dataType' );
        $intFlag = defined $dType ? $dType : 0;

        $width  = defined $width  ? $width  : 100;
        $height = defined $height ? $height : 400;
        my %options = (
            type   => $intFlag,
            height => $height,
            width  => $width,
            units  => undef,
            scale  => $sldInfo->{layers}{$layers}{legendScale},
            file   => $legendImage
        );
        my $status = $sldInfo->createColorLegend(%options);

    }

    exit_with_error("Legend is not created") unless -f $legendImage;

    # output legend image
    outputImage($legendImage);
    exit;
}

# request map in polar projections
if (    ( $request =~ m/getmap/i )
    and ( $srs =~ /epsg:3031/i or $srs =~ /epsg:3413/i )
    and ( $layers !~ /_contour/i ) )
{
    my $mapXmlFile = $mapFile . ".xml";
    my ( $dType, $dFormat ) = split( '/', $format );
    my $dataFile = Giovanni::Map::Util::getLayerData( $mapXmlFile, $layers );
    my %options = (
        OUTWIDTH  => $width,
        OUTHEIGHT => $height,
        OUTBBOX   => $bbox
    );
    my $tmpOut = File::Temp->new(
        TEMPLATE => 'tmp_reproject' . '_XXXX',
        DIR      => $mapDir,
    );
    $tmpOut .= ".$dFormat";
    Giovanni::Map::Util::reprojection( $dataFile, "EPSG:4326", $tmpOut, $srs,
        %options );
    outputImage($tmpOut) if -f $tmpOut;
    unlink $tmpOut;
    exit;
}

#Reset query string
$cgi->delete($mapRQ);
$ENV{'MS_MAPFILE'} = $mapFile;
print FILE "query:" . $ENV{QUERY_STRING} . "\n";
$ENV{'MS_ERRORFILE'} = $logFile;

# call mapserver
my $mapServer
    = defined $GIOVANNI::WMS{map_server}
    ? $GIOVANNI::WMS{map_server}
    : $rootPath . '/cgi-bin/mapserv';
exit_with_error("Not able to find map server") unless ( -x $mapServer );
exec $mapServer;

# A method to print out images for a given image file
sub outputImage {
    my ($imgFile) = @_;
    my $length = -s $imgFile;
    print "Content-type: image/png\n";
    print "Content-length: $length \n\n";
    binmode STDOUT;
    open( FH, '<', $imgFile ) || die "Could not open $imgFile: $!";
    my $buffer = "";
    while ( read( FH, $buffer, 10240 ) ) {
        print $buffer;
    }

}

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
__END__

=head1 NAME

agmap.pl - Script to get image map from MapServer WMS

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

agmap.pl
[B<-map> map file]
[B<-layers> layer names]
[B<-bbox> west,south,east,north]
[B<-sld> SLD URL]
[B<-service> "WMS"]
[B<-request> WMS operations]
[B<-srs> spatial reference system]
[B<-width> image width]
[B<-height> image height]
[B<-transparent> transparent ture or false]
[B<-format> image format]
[B<-session> session ID]
[B<-resultset> resultset ID]
[B<-result> result ID]

=head1 DESCRIPTION

This is a highly abstracted description, designed for illustration purposes only. Do not use if operating heavy machinery.

=head1 OPTIONS

=over 4

=item B<-map>

Name of map file

=item B<layers>

Layer names (assume only one layer here)


=item B<sld>

SLD URL

=item B<bbox>

Spatial bounding box (comma separated list of west,south,east,north
coordinates in degrees)

=item B<service>

Should be "WMS"

=item B<request>

WMS operation, "GetMap" and "GetLegendGraphic"

=item B<srs>

Spatial reference system, such as EPSG:4326

=item B<width>
 
Image width

=item B<height>
 
Image height

=item B<transparent>
 
Image transparent or not

=item B<session>
 
Session ID

=item B<resultset>
 
Resultset ID

=item B<result>
 
Result ID

=back

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

MS_MAPFILE

=head1 EXAMPLES

perl agmap.pl "version=1.1.1&service=WMS&request=GetMap&SRS=EPSG:4326&WIDTH=600&HEIGHT=300&LAYERS=test&TRANSPARENT=TRUE&FORMAT=image/png&bbox=-180,-90,180,90&session=F24C903E-1300-11E2-BA3D-0C7CEA853B8F&resultset=03D0C758-1301-11E2-A56D-1D7CEA853B8F&result=03D0E026-1301-11E2-A56D-1D7CEA853B8F&map=timeAvg.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101-20030105.180W_90S_180E_90N.map&SLD=http://wdc.dlr.de/acp/sld/o3_v100.xml"

=head1 AUTHOR

Peisheng Zhao (peisheng.zhao-1@nasa.gov)

=head1 SEE ALSO

=cut 

