#!/usr/bin/perl
use lib "/tools/gdaac/TS2/lib/perl5/site_perl/5.8.8/";
use strict;
use warnings;
use Giovanni::Catalog;
use Giovanni::OGC::WMS;
use Getopt::Long;
use DateTime;
use File::Temp;
use LWP::UserAgent;

#my $catalogUrl = "http://s4ptu-ts2.ecs.nasa.gov/aesir_solr/";
#my $capaFile = "/var/scratch/pzhao1/giovanni/agwms.map";

# LWP::UserAgent is used instead of wget, so define a new instance and tie to environment proxy
my $ua = LWP::UserAgent->new();
$ua->env_proxy;

# Variables to hold command line arguments
my ( $opt_h, $refer, $target, $catalogUrl, $outputDir )
    = ( '', '', '', '', '' );

# Get command line options
Getopt::Long::GetOptions(
    'referMode=s'  => \$refer,
    'targetMode=s' => \$target,
    'catalogUrl=s' => \$catalogUrl,
    'outputDir=s'  => \$outputDir,
    'h'            => \$opt_h
);

# If -h is specified, provide synopsis
die "$0\n"
    . " --referMode 'aGiovanni mode or sandbox, TS1, OPS or sandbox'\n"
    . " --targetMode 'aGiovanni mode or sandbox, TS1, OPS or sandbox'\n"
    . " --catalogUrl 'AESIR catalog URL (option)'\n"
    . " --outputDir 'The directory of output images (option)"
    if ( $opt_h or $refer eq '' or $target eq '' );

my $referBaseUrl  = getBaseUrl($refer);
my $targetBaseUrl = getBaseUrl($target);

my $logFile
    = $outputDir ne ''
    ? $outputDir . "/compareResult.log"
    : "/var/tmp/compareResult.log";
open( LOG, "> $logFile" ) or die "cannot open log file\n";

# Query catalogo to get data field information
$catalogUrl = "http://giovanni4.ecs.nasa.gov/aesir_solr/"
    if $catalogUrl eq '';
my $catalog = Giovanni::Catalog->new( { URL => $catalogUrl } );
my $layers = $catalog->getActiveDataFields(
    qw(long_name startTime endTime west south east north));
foreach my $key ( keys %$layers ) {

    #my $key = "AIRX3STD_006_Temperature_A";
    my $width  = "512";
    my $height = "256";
    my $bbox
        = $layers->{$key}{'west'} . ","
        . $layers->{$key}{'south'} . ","
        . $layers->{$key}{'east'} . ","
        . $layers->{$key}{'north'};

    # 4 days
    my $startTime = $layers->{$key}{'startTime'};
    $startTime =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/g;
    my $dt = DateTime->new( year => $1, month => $2, day => $3 );
    $dt->add( days => 3 );
    my $endTime = $dt->ymd . "T" . $dt->hms . "Z";
    my $time    = $startTime . "/" . $endTime;

    #WMS URLs
    my $rWmsUrl
        = $referBaseUrl
        . "/daac-bin/giovanni/wms_ag4?VERSION=1.1.1&REQUEST=GetMap&SRS=EPSG:4326&WIDTH="
        . $width
        . "&HEIGHT="
        . $height
        . "&LAYERS=INTERACTIVE_MAP."
        . $key
        . "&STYLES=default&TRANSPARENT=TRUE&FORMAT=image/png&time="
        . $time
        . "&bbox="
        . $bbox;
    my $tWmsUrl
        = $targetBaseUrl
        . "/daac-bin/giovanni/wms_ag4?VERSION=1.1.1&REQUEST=GetMap&SRS=EPSG:4326&WIDTH="
        . $width
        . "&HEIGHT="
        . $height
        . "&LAYERS=INTERACTIVE_MAP."
        . $key
        . "&STYLES=default&TRANSPARENT=TRUE&FORMAT=image/png&time="
        . $time
        . "&bbox="
        . $bbox;
    my ( $rImage, $tImage, $diffImage );
    my ( $tmpFH1, $tmpFH2, $tmpFH3 );
    if ( $outputDir ne '' ) {
        $rImage    = $outputDir . "/" . $key . "_" . $refer . ".png";
        $tImage    = $outputDir . "/" . $key . "_" . $target . ".png";
        $diffImage = $outputDir . "/" . $key . "_diff.png";
    }
    else {
        ( $tmpFH1, $rImage ) = File::Temp::tempfile(
            "referImage_XXXX",
            DIR    => "/var/tmp/",
            SUFFIX => ".png",
            UNLINK => 0
        );
        ( $tmpFH2, $tImage ) = File::Temp::tempfile(
            "targetImage_XXXX",
            DIR    => "/var/tmp/",
            SUFFIX => ".png",
            UNLINK => 0
        );
        ( $tmpFH3, $diffImage ) = File::Temp::tempfile(
            "diffImage_XXXX",
            DIR    => "/var/tmp/",
            SUFFIX => ".png",
            UNLINK => 0
        );
    }
    print "Checking $key ..., ";

# We are using LWP::UserAgent to get url; this is in favor of and replaces wget
# Needed for cloud support of giovanni
    my $response = $ua->get($rWmsUrl);
    if ( $response->is_success() ) {
        my $data = $response->content();
        if ( open FILE, ">", $rImage ) {
            print FILE $data;
            close(FILE);
        }
        else {
            print STDERR "Could not write to $rImage\n";
            Giovanni::Util::exit_with_error( $response->code() );
        }
    }
    else {
        print STDERR "Could not get response\n";
        Giovanni::Util::exit_with_error( $response->code() );
    }

# We are using LWP::UserAgent to get url; this is in favor of and replaces wget
# Needed for cloud support of giovanni
    my $response = $ua->get($tWmsUrl);
    if ( $response->is_success() ) {
        my $data = $response->content();
        if ( open FILE, ">", $tImage ) {
            print FILE $data;
            close(FILE);
        }
        else {
            print STDERR "Could not write to $tImage\n";
            Giovanni::Util::exit_with_error( $response->code() );
        }
    }
    else {
        print STDERR "Could not get response\n";
        Giovanni::Util::exit_with_error( $response->code() );
    }
    my $compareCommand = "compare -metric AE $rImage $tImage $diffImage";

    # Compare two images
    my $compareResult = `$compareCommand`;
    if ( $compareResult =~ m/0 db/i ) {
        print "the $target image is the same as the $refer image\n";

        #If two images are same, detele them
        if ( $outputDir ne '' ) {
            unlink($rImage);
            unlink($tImage);
            unlink($diffImage);
        }
    }
    else {
        print "the $target image is different from the $refer image\n";
        print LOG "the $key in $target is different from the $refer \n";
    }

}
close(LOG);

sub getBaseUrl {
    my ($mode) = @_;
    my $url;
    if    ( $mode =~ m/TS2/i ) { $url = "http://s4ptu-ts2.ecs.nasa.gov/"; }
    elsif ( $mode =~ m/TS1/i ) { $url = "http://s4ptu-ts1.ecs.nasa.gov/"; }
    elsif ( $mode =~ m/BETA/i ) {
        $url = "http://giovanni.gsfc.nasa.gov/beta";
    }
    elsif ( $mode =~ m/OPS/i ) { $url = "http://giovanni.gsfc.nasa.gov/"; }
    else { $url = "http://s4ptu-ts2.ecs.nasa.gov/~$mode"; }
    return $url;
}
__END__

=head1 NAME

compareWms.pl - Script to compare WMS image from different mode

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

geneateWmsCapabilities.pl
[B<--targetMode> Giovanni mode or sandbox]
[B<--referMode> Giovanni mode or sandbox]
[B<--catalogUrl> AESIR catalog base URL]
[B<--outputDir> Directory of output images]
[B<-h>]

=head1 DESCRIPTION

Given the AESIR location (root URL), get a variable list from AESIR catalog to compare the variable images from different WMS.

=head1 OPTIONS

=over 4

=item B<h>

Prints command synposis

=item B<referMode>

Giovanni mode or sandbox for reference

=item B<targetMode>

Giovanni mode or sandbox to be compared

=item B<aesir>

Base URL for AESIR

=item B<outputDir>

Directory of output images

=back

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

None

=head1 EXAMPLES

perl wmsCompare.pl --referMode=TS1 --targetMode=OPS  --catalogUrl=http://s4ptu-ts2.ecs.nasa.gov/solr/ --outputDir=/var/tmp 

=head1 AUTHOR

Peisheng Zhao (peisheng.zhao-1@nasa.gov)

=head1 SEE ALSO

=cut

