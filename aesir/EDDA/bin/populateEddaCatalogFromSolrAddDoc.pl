#!/usr/bin/perl
################################################################################
# $Id: populateEddaCatalogFromSolrAddDoc.pl,v 1.11 2014/06/04 00:25:03 eseiler Exp $
# -@@@ EDDA Version: $Name:  $
################################################################################
#
# Script for populating a directory tree workspace with data product and data
# field files
#

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) )
        if defined $rootPath;
}

use strict;
use XML::LibXML;
use DateTime;

#use Time::HiRes;
use JSON;
use Getopt::Long;
use Safe;

my $help;
my $overWriteFlag;
my $mode;
my $result = Getopt::Long::GetOptions(
    "help"      => \$help,
    "overwrite" => \$overWriteFlag,
    "mode"      => \$mode
);
my $usage
    = "usage: $0 [--overwrite] solrAddXml\n\ne.g. $0 aerosolDailyOpticalThicknessPortalSolrData_aesir_TS2.xml\n";

if ($help) {
    print STDERR $usage;
    exit 0;
}

# Takes one argument:
#  -- pathname of xml file used to populate AESIR Solr database
my $solrAddXml = $ARGV[0];

unless ( defined $solrAddXml ) {
    print STDERR "$usage";
    exit 0;
}
die "Could not read Solr add document '$solrAddXml'"
    unless -r $solrAddXml;

my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read configuration file $cfgFile\n";
}

my $sldList = "$CFG::SLD_LOCATION/sld_list.json";
$sldList =~ s/INSERT_MODE_HERE/$mode/g if defined $mode;
die "Could not find readable $sldList" unless -r $sldList;
my $json;
open( IN, "< $sldList" ) or die "Could not open $sldList: $!\n";
{
    local $/;
    $json = <IN>;
}
close(IN);
my $sldIndexHash = from_json($json);
my %sldFileNames;
foreach my $sld ( @{ $sldIndexHash->{sldList}->{sld} } ) {
    $sldFileNames{ $sld->{file} } = $sld->{name};
}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

my %dataProductDocs;
my %dataFieldDocs;
my %dataProductFields;
my $solrAddDom;
eval { $solrAddDom = $parser->parse_file($solrAddXml); };
if ($@) {
    die "Could not read and parse $solrAddXml\n";
}

my $catalogDir = "$CFG::AESIR_CATALOG_DIR";
unless ( -d $catalogDir ) {
    mkdir $catalogDir;
    die "$catalogDir does not exist and could not be created\n"
        unless -d $catalogDir;
    chmod 0775, $catalogDir;
}
my $dataProductsDir = "$CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR";
unless ( -d $dataProductsDir ) {
    mkdir $dataProductsDir;
    die "$dataProductsDir does not exist and could not be created\n"
        unless -d $dataProductsDir;
    chmod 0777, $dataProductsDir;
}
my $dataFieldsDir = "$CFG::AESIR_CATALOG_DATA_FIELDS_DIR";
unless ( -d $dataFieldsDir ) {
    mkdir $dataFieldsDir;
    die "$dataFieldsDir does not exist and could not be created\n"
        unless -d $dataFieldsDir;
    chmod 0777, $dataFieldsDir;
}
my $measurementValidsDom;
my $measurementValidsDoc;
if (defined $CFG::AESIR_CATALOG_DATA_FIELDS_MEASUREMENT_VALIDS_DOC &&
    -r ($CFG::AESIR_CATALOG_DATA_FIELDS_MEASUREMENT_VALIDS_DOC)) {
    eval { $measurementValidsDom = $parser->parse_file( $CFG::AESIR_CATALOG_DATA_FIELDS_MEASUREMENT_VALIDS_DOC ); };
    if ($@) {
        die "Error parsing $CFG::AESIR_CATALOG_DATA_FIELDS_MEASUREMENT_VALIDS_DOC : $@\n";
    }
    $measurementValidsDoc = $measurementValidsDom->documentElement();
}
my $sldValidsDom;
my $sldValidsDoc;
if (defined $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC &&
    -r ($CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC)) {
    eval { $sldValidsDom = $parser->parse_file( $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC ); };
    if ($@) {
        die "Error parsing $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC : $@\n";
    }
    $sldValidsDoc = $sldValidsDom->documentElement();
}

my $solrAddDoc = $solrAddDom->documentElement();
my $now        = DateTime->now->iso8601 . 'Z';
foreach my $docNode ( $solrAddDoc->findnodes('/update/add/doc') ) {

    my $dataFieldIdNode;
    ($dataFieldIdNode) = $docNode->findnodes('./field[@name="dataFieldId"]');
    unless ($dataFieldIdNode) {
        print STDERR "dataFieldId missing from add doc\n";
        next;
    }
    my $dataFieldId = $dataFieldIdNode->textContent();

    my $dataProductIdNode;
    ($dataProductIdNode)
        = $docNode->findnodes('./field[@name="dataProductId"]');
    unless ($dataProductIdNode) {
        print STDERR "dataProductId missing from add doc\n";
        next;
    }
    my $dataProductId = $dataProductIdNode->textContent();

    my $dataFieldFile = "$dataFieldsDir/$dataFieldId";
    my $dataFieldDom;
    my $dataFieldDoc;
    if ( -f $dataFieldFile ) {
        eval { $dataFieldDom = $parser->parse_file($dataFieldFile); };
        if ($@) {
            print STDERR "Could not read and parse $dataFieldFile\n";
        }
        else {
            $dataFieldDoc = $dataFieldDom->documentElement();
        }
    }

    # Each $docNode corresponds to a data field

    my $newDataProductDom = $parser->parse_string($CFG::DATA_PRODUCT_XML);
    my $newDataProductDoc = $newDataProductDom->documentElement();
    my $newDataFieldDom   = $parser->parse_string($CFG::DATA_FIELD_XML);
    my $newDataFieldDoc   = $newDataFieldDom->documentElement();
    my $dataFieldOptionalDom
        = $parser->parse_string($CFG::DATA_FIELD_OPTIONAL_XML);
    my $dataFieldOptionalDoc = $dataFieldOptionalDom->documentElement();

    my %fieldValues;
    foreach my $fieldNode ( $docNode->findnodes('./field') ) {
        my $fieldKey = $fieldNode->getAttribute('name');
        my $fieldVal = $fieldNode->textContent();
        push @{ $fieldValues{$fieldKey} }, $fieldVal;

        #        next if ($fieldKey eq 'dataFieldId');
        #        next if ($fieldKey eq 'dataProductId');
        if ( $fieldKey eq 'dataFieldSldUrl' ) {

            # Special handling for dataFieldSldUrl
            # Expect CDATA for text content
            unless ($fieldVal) {
                print "sld value is empty for $dataFieldId\n";
            }
            addSldUrlValue( $newDataFieldDoc, $fieldKey,
                $CFG::ADD_DOC_DATA_FIELD_MAPPING,
                $fieldVal, \%sldFileNames );
            next;
        }
        if ( $fieldKey eq 'dataFieldFillValueFieldName' ) {

            # Special handling for optional fields with valids
            # where one of the valids is "no value", represented
            # as "(none)".
            unless ($fieldVal) {
                addValue( $newDataFieldDoc, $fieldKey,
                    $CFG::ADD_DOC_DATA_FIELD_MAPPING, '(none)' );
                next;
            }
        }
        if ( $fieldKey eq 'dataFieldSld' ) {
            my $path = $CFG::ADD_DOC_DATA_FIELD_MAPPING->{$fieldKey};
            my $validsNodeName = "$path/valids";
            my ($validsNode) = $newDataFieldDoc->findnodes($validsNodeName);
            if ($validsNode) {
                my $clone = $sldValidsDoc->cloneNode(1);
                $validsNode->replaceNode($clone);
            }
        }
        if ( $fieldKey eq 'dataFieldMeasurement' ) {
            my $path = $CFG::ADD_DOC_DATA_FIELD_MAPPING->{$fieldKey};
            my $validsNodeName = "$path/valids";
            my ($validsNode) = $newDataFieldDoc->findnodes($validsNodeName);
            if ($validsNode) {
                my $clone = $measurementValidsDoc->cloneNode(1);
                $validsNode->replaceNode($clone);
            }
        }

        my $mapped;
        if ( exists $CFG::ADD_DOC_PRODUCT_MAPPING->{$fieldKey} ) {

            # If there is a mapping from the add doc field name to a
            # path in the data product document, construct a 'value' node
            # from the add doc field value and add it to the path in the
            # data product document determined by the mapping
            addValue(
                $newDataProductDoc,            $fieldKey,
                $CFG::ADD_DOC_PRODUCT_MAPPING, $fieldVal
            );
            $mapped = 1;
        }
        if ( exists $CFG::ADD_DOC_DATA_FIELD_MAPPING->{$fieldKey} ) {

            # If there is a mapping from the add doc field name to a
            # path in the data field document, construct a 'value' node
            # from the add doc field value and add it to the path in the
            # data field document determined by the mapping
            addValue( $newDataFieldDoc, $fieldKey,
                $CFG::ADD_DOC_DATA_FIELD_MAPPING, $fieldVal );
            $mapped = 1;
        }
        if ( exists $CFG::ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING->{$fieldKey} ) {

           # If there is a mapping from the add doc field name to a
           # path in the optional data field document, construct a 'value'
           # node from the add doc field value and either add it to the path
           # in the data field document determined by the mapping if that path
           # exists, or construct a new node at that path and add the 'value'
           # node to the new node
            addOptionalValue( $newDataFieldDoc, $fieldKey,
                $CFG::ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING,
                $dataFieldOptionalDoc, $fieldVal );
            $mapped = 1;
        }
        unless ($mapped) {
            unless ( exists $CFG::UNMAPPED_ADD_DOC_DATA_FIELDS->{$fieldKey} )
            {
                print STDERR
                    "Unmapped field $fieldKey for product $dataProductId\n";
            }
        }
    }    # END foreach my $fieldNode ($docNode->findnodes('./field'))

    if ( exists $fieldValues{'dataFieldAccessMethod'}
        && $fieldValues{'dataFieldAccessMethod'}->[0] ne 'OPeNDAP' )
    {
        modifyContent( $newDataFieldDoc, 'dataFieldAccessName',
            $CFG::ADD_DOC_DATA_FIELD_MAPPING,
            './constraints/required', 'false' );
    }

    foreach my $fieldKey (@CFG::ADD_DOC_DATA_FIELD_OPTIONAL_FIELDS_FINAL) {
        my @optionalNodes = $newDataFieldDoc->findnodes($fieldKey);
        unless (@optionalNodes) {
            my $fieldVal = '';
            addOptionalValue( $newDataFieldDoc, $fieldKey,
                $CFG::ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING,
                $dataFieldOptionalDoc );

        }
    }
    addValue( $newDataFieldDoc, 'dataFieldInternal',
        $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'true' );

    addValue( $newDataFieldDoc, 'dataFieldInDb',
        $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'true' );

    addValue( $newDataFieldDoc, 'dataFieldState',
        $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'Published' );

    # Update the timestamps
    #dataFieldLastExtracted       => '/dataField/dataFieldLastExtracted',
    #dataFieldLastModified        => '/dataField/dataFieldLastModified',
    addValue( $newDataFieldDoc, 'dataFieldLastExtracted',
        $CFG::ADD_DOC_DATA_FIELD_TIMESTAMP_MAPPING, $now );

    unless ( exists $dataProductDocs{$dataProductId} ) {

        # Save the dataProductDoc
        $dataProductDocs{$dataProductId} = $newDataProductDoc;
    }
    $dataFieldDocs{$dataFieldId} = $newDataFieldDoc;
    push @{ $dataProductFields{$dataProductId} }, $dataFieldId;
}

# In each data product document, set dataProductInternal to 'true',
# and add the list of dataFieldId values to the dataProductDataFieldIds node
foreach my $dataProductId ( keys %dataProductFields ) {
    my $dataProductDoc = $dataProductDocs{$dataProductId};

    addValue( $dataProductDoc, 'dataProductInternal',
        $CFG::ADD_DOC_PRODUCT_MAPPING, 'true' );

    my ($dataProductDataFieldIdsNode)
        = $dataProductDoc->findnodes('/dataProduct/dataProductDataFieldIds');
    my ($valueNode) = $dataProductDataFieldIdsNode->findnodes('./value');
    if ( defined $valueNode ) {
        my $content = $valueNode->textContent;
        if ( $content eq '' ) {
            $dataProductDataFieldIdsNode->removeChild($valueNode);
        }
    }
    foreach my $dataFieldId ( @{ $dataProductFields{$dataProductId} } ) {
        my $valueNode = XML::LibXML::Element->new('value');
        $valueNode->appendText($dataFieldId);
        $dataProductDataFieldIdsNode->addChild($valueNode);
    }
}

foreach my $dataProductId ( keys %dataProductFields ) {
    my $dataProductFile = "$dataProductsDir/$dataProductId";
    if ( -f $dataProductFile ) {
        if ($overWriteFlag) {
            print STDERR "$dataProductFile already exists, re-writing\n";
            my $old_xml;
            unless ( open( UPDATED, "+< $dataProductFile" ) ) {
                exit_with_error(
                    "Could not open dataProductFile for updating: $!");
            }
            {
                local $/;
                $old_xml = <UPDATED>;
            }
            my $oldDataProductDom = $parser->parse_string($old_xml);
            my $oldDataProductDoc = $oldDataProductDom->documentElement();
            my ($dataProductInternalNode)
                = $oldDataProductDoc->findnodes(
                '/dataProduct/dataProductInternal/value');
            my $dataProductInternal = $dataProductInternalNode->textContent
                if $dataProductInternalNode;

            my ($dataProductDataFieldIdsNode)
                = $oldDataProductDoc->findnodes(
                '/dataProduct/dataProductDataFieldIds');
            my @dataFieldIdNodes
                = $dataProductDataFieldIdsNode->findnodes('./value');
            my %dataProductDataFieldIds;
            my $emptyValueNode;
            foreach my $dataFieldIdNode (@dataFieldIdNodes) {
                my $dataFieldId = $dataFieldIdNode->textContent;
                if ( $dataFieldId eq '' ) {
                    $emptyValueNode = $dataFieldIdNode;
                }
                else {
                    $dataProductDataFieldIds{$dataFieldId} = 1;
                }
            }

            my $added;
            foreach
                my $dataFieldId ( @{ $dataProductFields{$dataProductId} } )
            {
                unless ( exists( $dataProductDataFieldIds{$dataFieldId} ) ) {
                    my $valueNode = XML::LibXML::Element->new('value');
                    $valueNode->appendText($dataFieldId);
                    $dataProductDataFieldIdsNode->addChild($valueNode);
                    $added = 1;
                }
            }

            if ($added) {

                # Replace the file contents with the updated information
                seek( UPDATED, 0, 0 );
                print UPDATED $oldDataProductDom->toString(1);
                truncate( UPDATED, tell(UPDATED) );
            }
            close(UPDATED);
        }
        else {
            print STDERR "$dataProductFile already exists, not overwriting\n";
        }
    }
    else {
        unless ( open( PRODUCT, "> $dataProductFile" ) ) {
            print STDERR "Could not open $dataProductFile for writing\n";
            next;
        }
        print PRODUCT $dataProductDocs{$dataProductId}
            ->ownerDocument->toString(1);
        close(PRODUCT);
        chmod 0666, $dataProductFile;
    }

    foreach my $dataFieldId ( @{ $dataProductFields{$dataProductId} } ) {
        my $dataFieldFile = "$dataFieldsDir/$dataFieldId";
        if ( ( -f $dataFieldFile ) && ( !$overWriteFlag ) ) {
            print STDERR "$dataFieldFile already exists, not overwriting\n";
        }
        else {
            unless ( open( FIELD, "> $dataFieldFile" ) ) {
                print STDERR "Could not open $dataFieldFile for writing\n";
                next;
            }
            print FIELD $dataFieldDocs{$dataFieldId}
                ->ownerDocument->toString(1);
            close(FIELD);
            chmod 0666, $dataFieldFile;
        }
    }
}

exit 0;

sub addSldUrlValue {
    my ( $doc, $key, $mapping, $value, $sldFileNames ) = @_;

    return unless $value;

    # Use mapping to determine the path in $doc that corresponds to $key
    my $path = $mapping->{$key};
    unless ($path) {
        print STDERR "Could not find mapping for key $key\n";
        return;
    }

    # Find the node in $doc at that path
    my ($node) = $doc->findnodes($path);
    unless ($node) {
        print STDERR "Could not find node for key $key path $path\n";
        return;
    }

    # Get the first 'value' child node.
    #    my ($containerNode) = $node->findnodes('./value');
    #    unless ($containerNode) {
    #        print STDERR "Did not find value child of $key\n";
    #        return;
    #    }
    #    my $containerClone = $containerNode->cloneNode(1);

    # Expect the value to be xml which needs to be parsed
    # Expect a form like <slds><sld></sld><sld></sld></slds>
    my $sldDoc = $parser->parse_string($value);
    my @slds   = $sldDoc->findnodes('//sld');
    my $addedOne;
    foreach my $sld (@slds) {
        my $url   = $sld->getAttribute('url');
        my $file  = ( split( '/', $url ) )[-1];
        my $label = $sld->getAttribute('label');

        # OLD SLD VALUE
        #        my $value = "$file: $label";
        # NEW SLD VALUE
        my $value = $sldFileNames->{$file};
        if ($addedOne) {

            #            my $newClone = $containerClone->cloneNode(1);
            #            setSldUrlValues($newClone, $url, $label);
            #            $node->addChild($newClone);
            $node->appendTextChild( 'value', $value );
        }
        else {
            #            setSldUrlValues($containerNode, $url, $label);
            my ($valueNode1) = $node->findnodes('./value');
            if ( defined $valueNode1 ) {
                my $content = $valueNode1->textContent;
                if ( $content eq '' ) {
                    $valueNode1->removeChildNodes();
                    $valueNode1->appendText($value);
                }
            }
            $addedOne = 1;
        }
    }

    return;
}

sub setSldUrlValues {
    my ( $containerNode, $url, $label ) = @_;

    # Populate the dataFieldSldUrl value
    my ($valueNode1) = $containerNode->findnodes('./dataFieldSldUrl/value');
    if ($valueNode1) {
        $valueNode1->removeChildNodes();
        $valueNode1->appendText($url);
    }

    # Populate the dataFieldSldLabel value
    my ($valueNode2) = $containerNode->findnodes('./dataFieldSldLabel/value');
    if ($valueNode2) {
        $valueNode2->removeChildNodes();
        $valueNode2->appendText($label);
    }
}

sub addValue {
    my ( $doc, $key, $mapping, $value ) = @_;

    # Use mapping to determine the path in $doc that corresponds to $key
    my $path = $mapping->{$key};
    unless ($path) {
        print STDERR "Could not find mapping for key $key\n";
        return;
    }

    # Find the node in $doc at that path
    my ($node) = $doc->findnodes($path);
    unless ($node) {
        print STDERR "Could not find node for key $key path $path\n";
        return;
    }

    # Look for a 'value' child node. If one is found and it is empty,
    # replace it with a new value
    my (@valueNodes) = $node->findnodes('./value');
    if (@valueNodes) {
        my $valueNode1 = $valueNodes[0];
        my $content    = $valueNode1->textContent;
        if ( $content eq '' ) {
            $valueNode1->removeChildNodes();
            $valueNode1->appendText($value);
            return;
        }
    }

    # Otherwise add a new 'value' child node.
    # Construct a new 'value' node and add it to the node in $doc at
    # that path.
    $node->appendTextChild( 'value', $value );
    return;
}

sub addOptionalValue {
    my ( $doc, $key, $mapping, $dataFieldOptionalDoc, $value ) = @_;

    # Use mapping to determine the path in $doc that corresponds to $key
    my $path = $mapping->{$key};
    unless ($path) {
        print STDERR "Could not find mapping for key $key\n";
        return;
    }

    # Find the node in $doc at that path
    my ($node) = $doc->findnodes($path);

    if ($node) {
        if ( defined $value ) {
            my ($valueNode) = $node->findnodes('value');
            if ($valueNode) {
                my ($multiplicityNode) = $node->findnodes('multiplicity');
                my $multiplicity = $multiplicityNode->textContent
                    if $multiplicityNode;
                if ( $multiplicity eq 'one' ) {

                 # If value node already exists, and the muliplicity is "one",
                 # remove it, so it will then be replaced by the new value
                    $node->removeChild($valueNode);
                }
            }

            # Add the 'value' node to the node in $doc at that path
            $node->appendTextChild( 'value', $value );
        }
        return;
    }
    else {
        # Find the node in $dataFieldOptionalDoc at that path, clone it,
        # and add the 'value' node to the cloned node
        ($node) = $dataFieldOptionalDoc->findnodes($path);
        unless ($node) {
            print STDERR
                "Could not find optional node for key $key path $path\n";
            return;
        }
        my $newNode = $node->cloneNode(1);
        if ( defined $value ) {
            my ($valueNode) = $newNode->findnodes('value');
            if ($valueNode) {
                my ($multiplicityNode) = $newNode->findnodes('multiplicity');
                my $multiplicity = $multiplicityNode->textContent
                    if $multiplicityNode;
                if ( $multiplicity eq 'one' ) {

                 # If value node already exists, and the muliplicity is "one",
                 # remove it, so it will then be replaced by the new value
                    $newNode->removeChild($valueNode);
                }
            }
            $newNode->appendTextChild( 'value', $value );
        }

        # Add the cloned node to $doc
        $doc->addChild($newNode);
    }
}

sub modifyContent {
    my ( $doc, $key, $mapping, $path, $value ) = @_;

    # Use mapping to determine the path in $doc that corresponds to $key
    my $nodePath = $mapping->{$key};
    unless ($path) {
        print STDERR "Could not find mapping for key $key\n";
        return;
    }

    # Find the node in $doc at that path
    my ($node) = $doc->findnodes($nodePath);
    unless ($node) {
        print STDERR "Could not find node for key $key path $nodePath\n";
        return;
    }

    # Look for a child node. If one is found and it is empty,
    # replace it with a new value
    my ($targetNode) = $node->findnodes($path);
    if ( defined $targetNode ) {
        $targetNode->removeChildNodes();
        $targetNode->appendText($value);
    }
    return;
}
