#!/usr/bin/perl

my ($rootPath);
BEGIN {
     $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
     push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) )
       if defined $rootPath;
}

my $mode = $ARGV[0];
if ($mode eq 'TS1') {
    $rootPath = '/tools/gdaac/TS1/';
}
push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) );

use strict;
use XML::LibXML;
use URI::Escape;
use Safe;

my $dataFieldId = $ARGV[1];

die "usage: $0 TS2|TS1 dataFieldId\n" unless defined $dataFieldId;

my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read configuration file $cfgFile\n";
}
die "Could not find AESIR directory '$CFG::AESIR_CATALOG_DIR'" unless -d $CFG::AESIR_CATALOG_DIR;

my $dataProductsDir = "$CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR";
my $dataFieldsDir = "$CFG::AESIR_CATALOG_DATA_FIELDS_DIR";
my %addDocToDataFieldMapping = (%$CFG::OLD_ADD_DOC_DATA_FIELD_MAPPING,
                                %$CFG::OLD_ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING);
my %dataFieldToAddDocMapping = reverse %addDocToDataFieldMapping;
my %addDocToProductMapping   = %$CFG::OLD_ADD_DOC_PRODUCT_MAPPING;

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

my $dataFieldFile = "$dataFieldsDir/$dataFieldId";
die "Data field file '$dataFieldFile' does not exist\n"
    unless -f $dataFieldFile;
my $dataFieldDom;
eval { $dataFieldDom = $parser->parse_file( $dataFieldFile ); };
if ($@) {
    die "Could not read and parse $dataFieldFile\n";
}
my $dataFieldDoc = $dataFieldDom->documentElement();

my $addDocDom = $parser->parse_string('<add overwrite="true"></add>');
my $addDocDoc = $addDocDom->documentElement();
my $docElement = XML::LibXML::Element->new('doc');

my $dataProductId;

addField($docElement, 'giovanniPortalId', 'aerosol_daily');

my ($parameterId) = getEddaValues($dataFieldDoc, \%addDocToDataFieldMapping,
                                  'parameterId');
if (defined $parameterId) {
    addField($docElement, 'parameterId', $parameterId);
} else {
    die "Could not obtain value for parameterId\n";
}

my ($dataFieldActive) = getEddaValues($dataFieldDoc, \%addDocToDataFieldMapping,
                                      'dataFieldActive');
if (defined $dataFieldActive) {
    addField($docElement, 'dataFieldActive', $dataFieldActive);
#} else {
#    die "Could not obtain value for dataFieldActive\n";
}

my ($dataProductId) = getEddaValues($dataFieldDoc, \%addDocToDataFieldMapping,
                                    'dataProductId');
die "No dataProductId value found\n" unless ($dataProductId);
my $dataProductFile = "$dataProductsDir/$dataProductId";
die "Data product file '$dataProductFile' does not exist\n"
    unless -f $dataProductFile;
my $dataProductDom = $parser->parse_file($dataProductFile);
my $dataProductDoc = $dataProductDom->documentElement();

my $dataProductSpatialResolutionLatitude;
my $dataProductSpatialResolutionLongitude;
my $dataProductSpatialResolutionUnits;
foreach my $addDocProductField (@CFG::OLD_ADD_DOC_PRODUCT_FIELDS) {
    next if $addDocProductField eq 'dataProductInternal';
    my $dataProductDocXpath = $addDocToProductMapping{$addDocProductField};
    my @nodes = $dataProductDoc->findnodes($dataProductDocXpath);
    foreach my $node (@nodes) {
        my @valueNodes = $node->findnodes('./value');
        foreach my $valueNode (@valueNodes) {
            my $value = $valueNode->textContent;

            # Special case for a choice from valids that represents no value
            $value = '' if $value eq '(none)';

            $dataProductSpatialResolutionLatitude = $value
                if ($addDocProductField eq 'dataProductSpatialResolutionLatitude');
            $dataProductSpatialResolutionLongitude = $value
                if ($addDocProductField eq 'dataProductSpatialResolutionLongitude');
            $dataProductSpatialResolutionUnits = $value
                if ($addDocProductField eq 'dataProductSpatialResolutionUnits');
            if ($dataProductSpatialResolutionLatitude &&
                $dataProductSpatialResolutionLongitude &&
                $dataProductSpatialResolutionUnits) {
                my $dataProductSpatialResolution =
                    $dataProductSpatialResolutionLatitude .
                    ' x ' .
                    $dataProductSpatialResolutionLongitude .
                    ' ' .
                    $dataProductSpatialResolutionUnits;
#                my $fieldNode = XML::LibXML::Element->new('field');
#                $fieldNode->setAttribute('name', 'dataProductSpatialResolution');
#                $fieldNode->appendText($dataProductSpatialResolution);
#                $docElement->addChild($fieldNode);
                addField($docElement,'dataProductSpatialResolution',
                         $dataProductSpatialResolution);
                $dataProductSpatialResolutionLatitude = undef;
                $dataProductSpatialResolutionLongitude = undef;
                $dataProductSpatialResolutionUnits = undef;
            }

            next if (($value eq '') &&
                     exists($CFG::OLD_ADD_DOC_DATA_PRODUCT_OPTIONAL_FIELDS{$addDocProductField}));
            next if ($addDocProductField eq 'dataProductSpatialResolutionLatitude');
            next if ($addDocProductField eq 'dataProductSpatialResolutionLongitude');
            next if ($addDocProductField eq 'dataProductSpatialResolutionUnits');
            addField($docElement, $addDocProductField, $value);
        }
    }
}


foreach my $addDocDataFieldField (@CFG::OLD_ADD_DOC_DATA_FIELD_FIELDS) {
#    next if $addDocDataFieldField eq 'dataFieldInternal';
    next if $addDocDataFieldField eq 'parameterId';
    next if $addDocDataFieldField eq 'dataProductId';
    if ($addDocDataFieldField eq 'parameterWavelength') {
        my @wavelengths = getEddaValues($dataFieldDoc,
                                        \%addDocToDataFieldMapping,
                                        'parameterWavelength');
        my @wavelengthUnits = getEddaValues($dataFieldDoc,
                                            \%addDocToDataFieldMapping,
                                            'parameterWavelengthUnits');
        my $wavelengthUnits;
        foreach my $wavelength (@wavelengths) {
            $wavelengthUnits = shift @wavelengthUnits if @wavelengthUnits;
            my $parameterWavelength = "$wavelength $wavelengthUnits";
            addField($docElement, 'parameterWavelength', $parameterWavelength);
        }
        next;
    }
    if ($addDocDataFieldField eq 'parameterDepth') {
        my @depths = getEddaValues($dataFieldDoc, \%addDocToDataFieldMapping,
                                   'parameterDepth');
        my @depthUnits = getEddaValues($dataFieldDoc, \%addDocToDataFieldMapping,
                                       'parameterDepthUnits');
        my $depthUnits;
        foreach my $depth (@depths) {
            $depthUnits = shift @depthUnits if @depthUnits;
            my $parameterDepth = "$depth $depthUnits";
            addField($docElement, 'parameterDepth', $parameterDepth);
        }
        next;
    }
    my $dataFieldDocXpath = $addDocToDataFieldMapping{$addDocDataFieldField};
    foreach my $node ($dataFieldDoc->findnodes($dataFieldDocXpath)) {
        foreach my $valueNode ($node->findnodes('./value')) {
            my $value = $valueNode->textContent;
#            if ($addDocDataFieldField eq 'dataProductId') {
#                # Expect 'dataProductId' to appear in both the data field
#                # docs and the data product doc, so include it in the add doc
#                # only once by adding it only from the data product doc
#                $dataProductId = $value;
#                next;
#            }
            next if (($value eq '') &&
                     exists($CFG::OLD_ADD_DOC_DATA_FIELD_OPTIONAL_FIELDS{$addDocDataFieldField}));
            my $fieldNode = XML::LibXML::Element->new('field');
            $fieldNode->setAttribute('name', $addDocDataFieldField);
            $fieldNode->appendText($value);
            $docElement->addChild($fieldNode);
        }
    }
}

# Construct sswBaseSubsetUrl
my ($dataSetId) = getEddaValues($dataProductDoc, \%addDocToProductMapping,
                                'dataProductDataSetId');
$dataSetId = uri_escape($dataSetId);
my ($dataFieldAccessName) = getEddaValues($dataFieldDoc,
                                          \%addDocToDataFieldMapping,
                                          'dataFieldAccessName');
my ($dataFieldAccessFormat) = getEddaValues($dataFieldDoc,
                                            \%addDocToDataFieldMapping,
                                            'accessFormat');
my ($dataFieldAccessMethod) = getEddaValues($dataFieldDoc,
                                            \%addDocToDataFieldMapping,
                                            'accessMethod');
my $sswBaseSubsetUrl = $CFG::SSW_BASE_URL || 'http://SOLR_HOST/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;';
$sswBaseSubsetUrl .=
    'format='      . $dataFieldAccessFormat .
    ';dataset_id=' . $dataSetId .
    ';agent_id='   . $dataFieldAccessMethod;
$sswBaseSubsetUrl .= ';variables=' . $dataFieldAccessName
    if $dataFieldAccessName ne '';
addField($docElement, 'sswBaseSubsetUrl', $sswBaseSubsetUrl);


# Construct sldUrl
my ($dataFieldSldUrlNode) = $dataFieldDoc->findnodes($addDocToDataFieldMapping{parameterSldUrl});
if ($dataFieldSldUrlNode) {
    my $baseSldUrl = $CFG::BASE_SLD_URL || 'http://G4_HOST/giovanni/sld/';
    my %slds;
    foreach my $valueNode ($dataFieldSldUrlNode->findnodes('./value')) {
#        my ($url, $label);
#        my ($urlValueNode) = $valueNode->findnodes('./dataFieldSldUrl/value');
#        $url = $urlValueNode->textContent if $urlValueNode;
#        my ($labelValueNode) = $valueNode->findnodes('./dataFieldSldLabel/value');
#        $label = $labelValueNode->textContent if $labelValueNode;
        my $string = $valueNode->textContent;
        my ($sld, $label) = split(': ', $string);
        my $url = $baseSldUrl . $sld if $sld;
        $slds{$label} = $url if ($label && $url);
    }
    if (%slds) {
        my $sldsNode = XML::LibXML::Element->new( 'slds' );
        while (my ($label, $url) = each %slds) {
            my $sldNode = XML::LibXML::Element->new( 'sld' );
            $sldNode->setAttribute( 'url', $url );
            $sldNode->setAttribute( 'label', $label );
            $sldsNode->addChild($sldNode);
        }
        my $fieldNode = XML::LibXML::Element->new('field');
#        $fieldNode->setAttribute('name', 'dataFieldSldUrl');
        $fieldNode->setAttribute('name', 'sldUrl');
#        my $cdata = '<![CDATA[' . $sldsNode->toString() . ']]>';
#        $fieldNode->appendText($cdata);
        my $cdataNode = XML::LibXML::CDATASection->new( $sldsNode->toString() );
        $fieldNode->addChild($cdataNode);
        $docElement->addChild($fieldNode);
    }
}

$addDocDoc->addChild($docElement);

my $outfile = $dataFieldId . '_old_solr_add_doc.xml';
open (OUTFILE, "> $outfile") or die "Could not open $outfile for writing: $!";
print OUTFILE $addDocDoc->toString(1), "\n";
if (close(OUTFILE)) {
    print "Wrote $outfile\n";
}

exit 0;

sub addField {
    my ($docElement, $name, $value) = @_;

    my $fieldNode = XML::LibXML::Element->new('field');
    $fieldNode->setAttribute('name', $name);
    $fieldNode->appendText($value);
    $docElement->addChild($fieldNode);
}

sub getEddaValues {
    my ($doc, $addDocToDataFieldMapping, $addDocDataFieldField) = @_;

    my @values;
    my $dataFieldDocXpath = $addDocToDataFieldMapping->{$addDocDataFieldField};
print STDERR "No xpath found for $addDocDataFieldField\n" unless $dataFieldDocXpath;
    my (@nodes) = ($doc->findnodes($dataFieldDocXpath));
    foreach my $node (@nodes) {
        my @valueNodes = $node->findnodes('./value');
        foreach my $valueNode (@valueNodes) {
            push @values, $valueNode->textContent;
        }
    }

    return @values;
}
