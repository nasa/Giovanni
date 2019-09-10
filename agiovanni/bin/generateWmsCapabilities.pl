#!/usr/bin/perl

use strict;
use warnings;
use Giovanni::Catalog;
use Getopt::Long;

#my $catalogUrl = "http://s4ptu-ts2.ecs.nasa.gov/aesir_solr/";
#my $capaFile = "/var/scratch/pzhao1/giovanni/agwms.map";

# Variables to hold command line arguments
my ( $opt_h, $catalogUrl, $capaFile ) = ( '', '', '' );

# Get command line options
Getopt::Long::GetOptions(
    'aesir=s'         => \$catalogUrl,
    'wms-capa-file=s' => \$capaFile,
    'h'               => \$opt_h
);

# If -h is specified, provide synopsis
die "$0\n"
    . " --aesir 'URL for AESIR'\n"
    . " --wms-capa-file 'WMS capability file'\n"
    if ( $opt_h or $catalogUrl eq '' or $capaFile eq '' );

open CFILE, ">$capaFile" or die "Error opening $capaFile";
print CFILE "MAP\n";
print CFILE "  NAME \"GES_DISC_Giovanni_WMS\"\n";
print CFILE "  STATUS ON\n";
print CFILE "  EXTENT  -180 -90 180 90\n";
print CFILE "  FONTSET \"/opt/giovanni4/cfg/fonts/font.list\"\n";
print CFILE "  IMAGETYPE \"PNG\"\n";
print CFILE "  PROJECTION\n";
print CFILE "    \"init=epsg:4326\"\n";
print CFILE "  END\n";
print CFILE "  SIZE 2000 1000\n";
print CFILE "  UNITS DD\n";
print CFILE "  WEB\n";
print CFILE "    IMAGEPATH \"/var/tme/www\"\n";
print CFILE "    IMAGEURL \"WWW-TEMP\"\n";
print CFILE "    METADATA\n";
print CFILE "      \"wms_title\" \"OGC WMS for NASA Giovanni\"\n";
print CFILE
    "      \"wms_contactelectronicmailaddress\" \"help-disc\@listserv.gsfc.nasa.gov\"\n";
print CFILE
    "      \"wms_contactorganization\" \"Goddard Earth Sciences Data and Information Services Center\"\n";
print CFILE "      \"wms_contactperson\" \"Christopher Lynnes\"\n";
print CFILE "      \"wms_contactvoicetelephone\" \"301-614-5224\"\n";
print CFILE
    "      \"wms_onlineresource\" \"http://giovanni.gsfc.nasa.gov/daac-bin/giovanni/wms_ag4\"\n";
print CFILE "      \"wms_srs\" \"EPSG:4326\"\n";
print CFILE "      \"ows_enable_request\" \"*\"\n";
print CFILE "    END\n";
print CFILE "  END\n";

my $catalog = Giovanni::Catalog->new( { URL => $catalogUrl } );
my $layers = $catalog->getActiveDataFields(
    qw(long_name startTime endTime west south east north));
foreach my $key ( keys %$layers ) {
    print CFILE "  LAYER\n";
    print CFILE "    NAME \"Time-Averaged.$key\"\n";
    print CFILE "    TYPE RASTER\n";
    print CFILE "    STATUS ON\n";
    print CFILE "    PROJECTION\n";
    print CFILE "      \"init=epsg:4326\"\n";
    print CFILE "    END\n";
    print CFILE "    METADATA\n";
    print CFILE "      \"wms_title\" \""
        . $layers->{$key}{'long_name'} . "\"\n";
    print CFILE "      \"wms_timeextent\" \""
        . $layers->{$key}{'startTime'} . "/"
        . $layers->{$key}{'endTime'} . "\"\n";
    print CFILE "      \"wms_srs\" \"EPSG:4326\"\n";
    print CFILE "      \"wms_timedefault\" \""
        . $layers->{$key}{'endTime'} . "\"\n";
    print CFILE "      \"wms_extent\" \""
        . $layers->{$key}{'west'} . " "
        . $layers->{$key}{'south'} . " "
        . $layers->{$key}{'east'} . " "
        . $layers->{$key}{'north'} . "\"\n";
    print CFILE "    END\n";
    print CFILE "  END\n";
}
print CFILE "END\n";
close CFILE;

__END__

=head1 NAME

generateWmsCapabilities.pl - Script to genarate map file for AG WMS capabilities  from AESIR catalog

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

geneateWmsCapabilities.pl
[B<--wms-capa-file> Giovanni data field manifest file]
[B<--aesir> AESIR catalog base URL]
[B<-h>]

=head1 DESCRIPTION

Given map file and the AESIR location (root URL), produces MapServer map file from AESIR catalog for WMS capabilities.

=head1 OPTIONS

=over 4

=item B<h>

Prints command synposis

=item B<wms-capa-file>

MapServer map file

=item B<aesir>

Base URL for AESIR

=back

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

None

=head1 EXAMPLES

perl generateWmsCapabilities.pl --aesir  "http://s4ptu-ts2.ecs.nasa.gov/solr/" --wms-capa-file "wms.map" 

=head1 AUTHOR

Peisheng Zhao (peisheng.zhao-1@nasa.gov)

=head1 SEE ALSO

=cut

