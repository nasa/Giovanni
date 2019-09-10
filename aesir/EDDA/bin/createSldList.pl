#!/usr/bin/perl

# $Id: createSldList.pl,v 1.3 2014/06/17 20:45:24 mhegde Exp $
# $Version$

use XML::XML2JSON;
use Giovanni::OGC::SLD;
use Giovanni::Util;
use File::Basename;

umask 0002;

# Get all the SLDs in the given directory
my @sldFileList = `cd $ARGV[0]; ls -1 *.xml`;

chomp @sldFileList;
my $doc = Giovanni::Util::createXMLDocument('sldList');
my @dynamicSldList = ();
my @fixedSldList = ();
# For each SLD:
# Classify the SLD as dynamic or fixed
# Find the title, min/max
# Create thumb nail
foreach my $sldFile ( @sldFileList ) {
    my $sld = Giovanni::OGC::SLD->new( FILE => "$ARGV[0]/$sldFile" );
    my $name = $sld->getLayerName();
    my $title = $sld->getUserStyleName();
    my @dataRange = $sld->getThresholds();
    my $sldNode = XML::LibXML::Element->new('sld');
    $sldNode->setAttribute('name', $name);
    $sldNode->setAttribute('title', $title);
    $sldNode->setAttribute('file', basename($sldFile));
    my @colorList = $sld->getColors();
    $sldNode->setAttribute('numColors', scalar(@colorList) );
    # Check for threshold min/max in SLD
    if ( @dataRange > 1 && $dataRange[0] ne '' && $dataRange[-1] ne '' ) {
        # If the min and max are defined, it must be fixed SLD
        $sldNode->setAttribute('min', $dataRange[0] );
        $sldNode->setAttribute('max', $dataRange[-1] );
        push( @fixedSldList, $sldNode );
    } else {
        push( @dynamicSldList, $sldNode );
    }
    # Create the color palette icons
    my $iconFile = $sldFile;
    $iconFile =~ s/\.xml$/.png/;
    unlink $iconFile if ( -f $iconFile );
    my $status = $sld->createThumbnail(FILE=>"$ARGV[0]/$iconFile", WIDTH => 128 );
    $sldNode->setAttribute('thumbnail', $iconFile) if $status;
}

# Ensure that dynamic SLDs are listed first
@dynamicSldList = sort { $a->getAttribute('name') cmp $b->getAttribute('name') } @dynamicSldList;
@fixedSldList = sort { $a->getAttribute('name') cmp $b->getAttribute('name') } @fixedSldList;
foreach my $sldNode ( @dynamicSldList, @fixedSldList ) {
    $doc->appendChild( $sldNode );
}
# Create sld_list.json file
my $xml2Json = XML::XML2JSON->new( module => 'JSON::XS', pretty => 1, attribute_prefix => '', content_key => 'value', force_array => 1 ); 
my $jsonObj = $xml2Json->dom2obj($doc->parentNode());
if ( open(FH, ">sld_list.json" ) ) {
    print FH $xml2Json->obj2json($jsonObj);
    unless ( close(FH) ) {
        print STDERR "Failed to close sld_list.json\n";
    }
} else {
    print STDERR "Failed to close sld_list.json\n";
}


=head1 NAME

createSldList.pl - creates color palette thumbnails and sld_list.json used by EDDA

=head1 PROJECT

AESIR EDDA

=head1 SYNOPSIS

createSldList.pl <SLD directory>

=head1 DESCRIPTION

Creates  color palette thumbnails and catalogs SLD attributes in sld_list.json file
given a directory containing SLDs. sld_list.json is created in the SLD directory

Example of sld_list.json:
{
   "sldList" : {
      "sld" : [
         {
            "name" : "aerosol_optical_thickness_sld",
            "title" : "Aerosol Optical Thickness",
            "file" : "aerosol_optical_thickness_sld.xml",
            "numColors" : "256",
            "thumbnail" : "aerosol_optical_thickness_sld.png"
         }
       ]
}

=head1 OPTIONS

None

=over 4

=back

=head1 SEE ALSO

Giovanni::OGC::SLD

=over 4

=back

=head1 AUTHOR

M. Hegde, E<lt>Mahabaleshwa.S.Hegde@nasa.govE<gt>

=cut
