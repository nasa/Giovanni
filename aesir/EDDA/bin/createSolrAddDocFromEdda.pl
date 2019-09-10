#!/usr/bin/perl

my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) )
      if defined $rootPath;
}

use strict;
use XML::LibXML;
use URI::Escape;
use Getopt::Long;
use Safe;
use DateTime;
use JSON;
use Time::HiRes qw (gettimeofday);

my $help;
my $stdout;
my $mode;
my $result = Getopt::Long::GetOptions ("help"      => \$help,
                                       "stdout"    => \$stdout,
                                       "mode"      => \$mode);

my $dataFieldId = $ARGV[0];

my $usage = "usage: $0 [-s] dataFieldId\n" unless defined $dataFieldId;
if ($help) {
    print STDERR $usage;
    exit 0;
}

die "$usage" unless defined $dataFieldId;

my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read configuration file $cfgFile\n";
}
die "Could not find AESIR directory '$CFG::AESIR_CATALOG_DIR'" unless -d $CFG::AESIR_CATALOG_DIR;

my $dataProductsDir = "$CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR";
my $dataFieldsDir = "$CFG::AESIR_CATALOG_DATA_FIELDS_DIR";
my %addDocToDataFieldMapping = (%$CFG::ADD_DOC_DATA_FIELD_MAPPING,
                                %$CFG::ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING);
my %dataFieldToAddDocMapping = reverse %addDocToDataFieldMapping;
my %addDocToProductMapping   = %$CFG::ADD_DOC_PRODUCT_MAPPING;

my $sldList = "$CFG::SLD_LOCATION/sld_list.json";
$sldList =~ s/INSERT_MODE_HERE/$mode/g if defined $mode;
die "Could not find readable $sldList" unless -r $sldList;
my $json;
open(IN, "< $sldList") or die "Could not open $sldList: $!\n";
{
    local $/;
    $json = <IN>;
}
close(IN);
my $sldIndexHash = from_json($json);
my %sldNameFiles;
my %sldNameTitles;
foreach my $sld (@{$sldIndexHash->{sldList}->{sld}}) {
    $sldNameFiles{$sld->{name}}  = $sld->{file};
    $sldNameTitles{$sld->{name}} = $sld->{title};
}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

my $dataFieldFile = "$dataFieldsDir/$dataFieldId";
die "Data field file '$dataFieldFile' does not exist\n"
    unless -f $dataFieldFile;
my $dataFieldDom = $parser->parse_file($dataFieldFile);
my $dataFieldDoc = $dataFieldDom->documentElement();

# Create a new Solr Add Document
my $addDocDom = $parser->parse_string('<update></update>');
my $addDocDoc = $addDocDom->documentElement();
my $docElement = XML::LibXML::Element->new('doc');
my $addElement = XML::LibXML::Element->new('add');
$addElement->setAttribute('overwrite', 'true');

my $dataProductId;

# Add each of the configured attributes found in the data field document
# to the Solr Add Document, in the order specified in the configuration.
foreach my $addDocDataFieldField (@CFG::ADD_DOC_DATA_FIELD_FIELDS, @CFG::ADD_DOC_DATA_FIELD_OPTIONAL_FIELDS) {
    next if $addDocDataFieldField eq 'dataFieldInternal';

    # Instead of adding dataFieldSld as-is, we will add it afterwards
    # using the mapping for dataFieldSldUrl
    next if $addDocDataFieldField eq 'dataFieldSld';

    my $dataFieldDocXpath = $addDocToDataFieldMapping{$addDocDataFieldField};
    foreach my $node ($dataFieldDoc->findnodes($dataFieldDocXpath)) {
        foreach my $valueNode ($node->findnodes('./value')) {
            my $value = $valueNode->textContent;
            if ($addDocDataFieldField eq 'dataProductId') {
                # Expect 'dataProductId' to appear in both the data field
                # docs and the data product doc, so include it in the add doc
                # only once by adding it only from the data product doc
                $dataProductId = $value;
                next;
            }

            if ($addDocDataFieldField eq 'dataFieldLastPublished') {
                my $nowEpoch = DateTime->from_epoch(epoch => scalar(gettimeofday));
                my $now = $nowEpoch->iso8601 . '.' . $nowEpoch->millisecond . 'Z';
                $value = $now;
            }

            if ($value eq '') {
                # Don't include optional fields in the add doc if they have no
                # value.
                next if exists($CFG::ADD_DOC_DATA_FIELD_OPTIONAL_FIELDS{$addDocDataFieldField});

                # Change other empty values to a default value if a default
                # value is configured.
                $value = $CFG::ADD_DOC_DATA_FIELD_DEFAULT_VALUES{$addDocDataFieldField}
                    if exists($CFG::ADD_DOC_DATA_FIELD_DEFAULT_VALUES{$addDocDataFieldField});
            }

            # Special case for a choice from valids that represents no value
            $value = '' if $value eq '(none)';

            my $fieldNode = XML::LibXML::Element->new('field');
            $fieldNode->setAttribute('name', $addDocDataFieldField);
            $fieldNode->appendText($value);
            $docElement->addChild($fieldNode);
        }
    }
}

# Construct the dataFieldSldUrl field from the dataFieldSldUrl information
# in the data field document
my ($dataFieldSldUrlNode) = $dataFieldDoc->findnodes($addDocToDataFieldMapping{dataFieldSldUrl});
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
# OLD SLD VALUE
#        my ($sld, $label) = split(': ', $string);
# NEW SLD VALUE
        my $sld = $sldNameFiles{$string};
        my $label = $sldNameTitles{$string};
        my $url = $baseSldUrl . $sld if $sld;
#        $slds{$label} = $url if ($label && $url);
        $slds{$url} = $label if ($label && $url);
    }
    if (%slds) {
        my $sldsNode = XML::LibXML::Element->new( 'slds' );
#        while (my ($label, $url) = each %slds) {
        while (my ($url, $label) = each %slds) {
            my $sldNode = XML::LibXML::Element->new( 'sld' );
            $sldNode->setAttribute( 'url', $url );
            $sldNode->setAttribute( 'label', $label );
            $sldsNode->addChild($sldNode);
        }
        my $fieldNode = XML::LibXML::Element->new('field');
        $fieldNode->setAttribute('name', 'dataFieldSldUrl');
#        my $cdata = '<![CDATA[' . $sldsNode->toString() . ']]>';
#        $fieldNode->appendText($cdata);
        my $cdataNode = XML::LibXML::CDATASection->new( $sldsNode->toString() );
        $fieldNode->addChild($cdataNode);
        $docElement->addChild($fieldNode);
    }
}

# Obtain the data product information from the data product file
# and add it to the Solr Add Document in the configured order
die "No dataProductId value found\n" unless ($dataProductId);
my $dataProductFile = "$dataProductsDir/$dataProductId";
die "Data product file '$dataProductFile' does not exist\n"
    unless -f $dataProductFile;
my $dataProductDom = $parser->parse_file($dataProductFile);
my $dataProductDoc = $dataProductDom->documentElement();

my $dataProductSpatialResolutionLatitude;
my $dataProductSpatialResolutionLongitude;
my $dataProductSpatialResolutionUnits;
foreach my $addDocProductField (@CFG::ADD_DOC_PRODUCT_FIELDS) {
    next if $addDocProductField eq 'dataProductInternal';
    my $dataProductDocXpath = $addDocToProductMapping{$addDocProductField};
    my @nodes = $dataProductDoc->findnodes($dataProductDocXpath);
    foreach my $node (@nodes) {
        my @valueNodes = $node->findnodes('./value');
        foreach my $valueNode (@valueNodes) {
            my $value = $valueNode->textContent;
            $dataProductSpatialResolutionLatitude = $value
                if ($addDocProductField eq 'dataProductSpatialResolutionLatitude');
            $dataProductSpatialResolutionLongitude = $value
                if ($addDocProductField eq 'dataProductSpatialResolutionLongitude');
            $dataProductSpatialResolutionUnits = $value
                if ($addDocProductField eq 'dataProductSpatialResolutionUnits');
            if ($value eq '') {
                # Don't include optional fields in the add doc if they have no
                # value.
                next if exists($CFG::ADD_DOC_DATA_PRODUCT_OPTIONAL_FIELDS{$addDocProductField});

                # Change other empty values to a default value if a default
                # value is configured.
                $value = $CFG::ADD_DOC_DATA_PRODUCT_DEFAULT_VALUES{$addDocProductField}
                    if exists($CFG::ADD_DOC_DATA_PRODUCT_DEFAULT_VALUES{$addDocProductField});
            }
            my $fieldNode = XML::LibXML::Element->new('field');
            $fieldNode->setAttribute('name', $addDocProductField);
            $fieldNode->appendText($value);
            $docElement->addChild($fieldNode);
            if ($dataProductSpatialResolutionLatitude &&
                $dataProductSpatialResolutionLongitude &&
                $dataProductSpatialResolutionUnits) {
                my $dataProductSpatialResolution =
                    $dataProductSpatialResolutionLatitude .
                    ' x ' .
                    $dataProductSpatialResolutionLongitude .
                    ' ' .
                    $dataProductSpatialResolutionUnits;
                my $fieldNode = XML::LibXML::Element->new('field');
                $fieldNode->setAttribute('name', 'dataProductSpatialResolution');
                $fieldNode->appendText($dataProductSpatialResolution);
                $docElement->addChild($fieldNode);
                $dataProductSpatialResolutionLatitude = undef;
                $dataProductSpatialResolutionLongitude = undef;
                $dataProductSpatialResolutionUnits = undef;
            }
        }
    }
}

# Construct sswBaseSubsetUrl from data product and data field info
my ($dataSetId) = getEddaValues($dataProductDoc, \%addDocToProductMapping,
                                'dataProductDataSetId');
$dataSetId = uri_escape($dataSetId);
my ($dataFieldAccessName) = getEddaValues($dataFieldDoc,
                                          \%addDocToDataFieldMapping,
                                          'dataFieldAccessName');
my ($dataFieldAccessFormat) = getEddaValues($dataFieldDoc,
                                            \%addDocToDataFieldMapping,
                                            'dataFieldAccessFormat');
unless ($dataFieldAccessFormat) {
    $dataFieldAccessFormat = $CFG::ADD_DOC_DATA_FIELD_DEFAULT_VALUES{'dataFieldAccessFormat'} if exists $CFG::ADD_DOC_DATA_FIELD_DEFAULT_VALUES{'dataFieldAccessFormat'};
}
my ($dataFieldAccessMethod) = getEddaValues($dataFieldDoc,
                                            \%addDocToDataFieldMapping,
                                            'dataFieldAccessMethod');
unless ($dataFieldAccessMethod) {
    $dataFieldAccessMethod = $CFG::ADD_DOC_DATA_FIELD_DEFAULT_VALUES{'dataFieldAccessMethod'} if exists $CFG::ADD_DOC_DATA_FIELD_DEFAULT_VALUES{'dataFieldAccessMethod'};
}
my $sswBaseSubsetUrl = $CFG::SSW_BASE_URL || 'http://SOLR_HOST/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;';
$sswBaseSubsetUrl .=
    'format='      . $dataFieldAccessFormat .
    ';dataset_id=' . $dataSetId .
    ';agent_id='   . $dataFieldAccessMethod;
$sswBaseSubsetUrl .= ';variables=' . $dataFieldAccessName
    if ($dataFieldAccessName ne '') && ($dataFieldAccessMethod eq 'OPeNDAP');
addField($docElement, 'sswBaseSubsetUrl', $sswBaseSubsetUrl);

# Add the doc element to the Solr Add Document
$addElement->addChild($docElement);
$addDocDoc->addChild($addElement);

# Write the Solr Add Document
my $outfile = $dataFieldId . '_solr_add_doc.xml';
if ($stdout) {
    print $addDocDoc->toString(1), "\n";
    exit 0;
}
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
