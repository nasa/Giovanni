#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell


################################################################################
# $Id: updateSolrCatalogAddDocFromEdda.pl,v 1.7 2015/12/09 02:47:23 eseiler Exp $
# -@@@ AESIR EDDA Version: $Name:  $
################################################################################

=head1 NAME

updateSolrCatalogAddDocFromEdda.pl - Update the entry for a data field in the Solr Add Document (catalog)

=head1 PROJECT

AESIR EDDA

=head1 SYNOPSIS

updateSolrCatalogAddDocFromEdda.pl dataFieldId baseline

=head1 DESCRIPTION

A script to update the entry for a data field in the catalog Solr Add
Document. It combines the XML in a data field file with the XML for
its corresponding data product and converts that to XML for adding
that data field to a Solr database. The resulting XML is either added
to the Solr Add Document if the data field is not yet in it, or
replaces the XML for a data field that is already in the Solr Add
Document.

It sets the value of dataFieldLastPublished to the current date/time.

It constructs the dataFieldSldUrl field using values from an SLD
information file, using a placeholder for the host portion of the SLD
URL. The script that posts the Solr Add Document will replace the
placeholder with the host configured for the baseline to which the
data field is being published.

It also constructs the SSW URL that is used for subsetting a data granule
in order to obtain the desired variable, using a placeholder that
the script that posts the Solr Add Document will replace with the SSW
host for the baseline to which the data field is being published.

=head1 ARGUMENTS

=over 4

=item dataFieldId

The identifier for the data field

=item baseline

The baseline to which the field is being published ('TS2', 'TS1', 'Beta', or 'OPS')

=back

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=cut

my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) )
      if defined $rootPath;
}

use strict;
use XML::LibXML;
use Tie::IxHash;
use URI::Escape;
use Getopt::Long;
use Safe;
use DateTime;
use JSON;
use Time::HiRes qw (gettimeofday);
use URI;
use LWP::UserAgent;
use HTML::TokeParser;
use File::Basename;

# Use the installed Giovanni DataAccess::OPeNDAP module in order to obtain
# OPeNDAP metadata needed by Giovanni
use lib '/opt/giovanni4/share/perl5';
use DataAccess::OPeNDAP;

my $help;
my $stdout;
my $mode;
my $published;
my $result = Getopt::Long::GetOptions ("help"      => \$help,
                                       "stdout"    => \$stdout,
				       "published" => \$published,
                                       "mode"      => \$mode);

my $dataFieldId  = $ARGV[0];
my $solrInstance = $ARGV[1];

my $usage = "usage: $0 [-s] dataFieldId [solrInstance]\n"
    unless defined $dataFieldId;
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
die "Could not find AESIR directory '$CFG::AESIR_CATALOG_DIR'"
    unless -d $CFG::AESIR_CATALOG_DIR;

$solrInstance = $CFG::EDDA_BASELINE unless $solrInstance;
unless (exists $CFG::AESIR_SOLR_ADD_DOC->{$solrInstance}) {
    die "Could not find AESIR_SOLR_ADD_DOC->{$solrInstance} defined in $cfgFile";
}
my $aesir_solr_add_doc = $CFG::AESIR_SOLR_ADD_DOC->{$solrInstance};
my $dataProductsDir = "$CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR";
my $dataFieldsDir = "$CFG::AESIR_CATALOG_DATA_FIELDS_DIR";
if ($published) {
    $dataFieldsDir = "$CFG::AESIR_CATALOG_PUBLISHED_DATA_FIELDS_DIR->{$CFG::EDDA_BASELINE}";
} else {
    $dataFieldsDir = "$CFG::AESIR_CATALOG_DATA_FIELDS_DIR";
}
my %addDocToDataFieldMapping = (%$CFG::ADD_DOC_DATA_FIELD_MAPPING,
                                %$CFG::ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING);
my %dataFieldToAddDocMapping = reverse %addDocToDataFieldMapping;
my %addDocToProductMapping   = %$CFG::ADD_DOC_PRODUCT_MAPPING;

my $sldList = "$CFG::SLD_LOCATION/sld_list.json";
#$sldList =~ s/INSERT_MODE_HERE/$mode/g if defined $mode;
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

my $catalogDom;
eval { $catalogDom = $parser->parse_file($aesir_solr_add_doc); };
if ($@) {
    die "Could not parse $aesir_solr_add_doc\n";
}
my $catalogDoc = $catalogDom->documentElement();
my (@addNodes) = $catalogDoc->findnodes('/update/add');
unless (@addNodes) {
    die "Could not find 'add' element in $aesir_solr_add_doc\n"
}
if (@addNodes > 1) {
    die "Found too many 'add' elements in $aesir_solr_add_doc\n"
}
my $addNode = $addNodes[0];

my $docElement = XML::LibXML::Element->new('doc');

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
    tie %slds, 'Tie::IxHash';  # Maintain order of the SLDs in the hash
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
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute('name', $addDocProductField);
#            $fieldNode->appendText($value);
            if ($dataProductSpatialResolutionLatitude &&
                $dataProductSpatialResolutionLongitude &&
                $dataProductSpatialResolutionUnits) {
                my $dataProductSpatialResolution;
                if ($dataProductSpatialResolutionLatitude ==
                    $dataProductSpatialResolutionLongitude) {
                    $dataProductSpatialResolution =
                        $dataProductSpatialResolutionLatitude . ' ' .
                        $dataProductSpatialResolutionUnits;
                } else {
                    $dataProductSpatialResolution =
                        $dataProductSpatialResolutionLatitude .
                        ' x ' .
                        $dataProductSpatialResolutionLongitude .
                        ' ' .
                        $dataProductSpatialResolutionUnits;
                }
                my $fieldNode2 = XML::LibXML::Element->new('field');
                $fieldNode2->setAttribute('name', 'dataProductSpatialResolution');
                $fieldNode2->appendText($dataProductSpatialResolution);
                $docElement->addChild($fieldNode2);
                $dataProductSpatialResolutionLatitude = undef;
                $dataProductSpatialResolutionLongitude = undef;
                $dataProductSpatialResolutionUnits = undef;
            }
            next if (($value eq '') &&
                     exists($CFG::ADD_DOC_DATA_PRODUCT_OPTIONAL_FIELDS{$addDocProductField}));
            $value = 1 if ( ($addDocProductField eq 'dataProductStartTimeOffset') && ($value eq '') );
            my $fieldNode = XML::LibXML::Element->new('field');
            $fieldNode->setAttribute('name', $addDocProductField);
            $fieldNode->appendText($value);
            $docElement->addChild($fieldNode);
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
    if $dataFieldAccessName ne '';
addField($docElement, 'sswBaseSubsetUrl', $sswBaseSubsetUrl);

my ($dataProductOpendapUrl) =
    getEddaValues( $dataProductDoc, \%addDocToProductMapping,
		   'dataProductOpendapUrl' );
my ($dataFieldSearchFilter) =
    getEddaValues( $dataFieldDoc, \%addDocToDataFieldMapping,
		   'dataFieldSearchFilter' );

# If there is a search filter, look in the OPeNDAP file listing for a filename
# that matches the search filter. If a filename match is found, construct a new
# dataProductOpendapUrl by replacing the filename in the original
# dataProductOpendapUrl with the filename that matched.
if ($dataFieldSearchFilter) {
    my $odUrlURI = URI->new($dataProductOpendapUrl);
    my $odBase   = $odUrlURI->scheme . ':' . dirname( $odUrlURI->opaque ) . '/';
    my $ua       = LWP::UserAgent->new;
    my $response = $ua->get( $odBase );
    if ( $response->is_success ) {
	my $content = $response->content;
	my $p       = HTML::TokeParser->new( \$content );

	# Look through all of the file links in the OPeNDAP directory listing
	while ( my $token = $p->get_tag('a') ) {
	    my $href = $token->[1]{href};
	    my $url = $odBase . $href;
	    if ( $url =~ /$dataFieldSearchFilter/ ) {
		$dataProductOpendapUrl = $url;
		last;
	    }
	}
    } else {
	die "Failed to get $odBase\n";
    }
}

# Construct dataProductOddxDims from data product and data field info
my $variables = [ split(',', $dataFieldAccessName) ];
my ($dataProductBeginDateTime) =
    getEddaValues( $dataProductDoc, \%addDocToProductMapping,
		   'dataProductBeginDateTime' );
my ($dataProductEndDateTime) =
    getEddaValues( $dataProductDoc, \%addDocToProductMapping,
		   'dataProductEndDateTime' );
my $login_credentials = "$CFG::LOGIN_CREDENTIALS";
my $endDateTime;
if ($dataProductEndDateTime) {
    $endDateTime = $dataProductEndDateTime;
} else {
    # If data product does not have a value for ending date/time,
    # use the current date as the end date/time, in case the
    # variable has a splittable time dimension that DataAccess::OPeNDAP
    # will attempt to split. (In such a case, we don't expect the
    # dataProductOddxDims time values in the catalog to be used,
    # since those times can vary from one file to the next.)
    my $nowEpoch = DateTime->from_epoch(epoch => scalar(gettimeofday));
    $endDateTime = $nowEpoch->iso8601 . 'Z';
}
my $od = new DataAccess::OPeNDAP(
    VARIABLES   => $variables,
    URLS        => [$dataProductOpendapUrl],
    'FORMAT'    => $dataFieldAccessFormat,
    START       => $dataProductBeginDateTime,
    END         => $endDateTime,
    CREDENTIALS => $login_credentials
);
if ( $od->onError && $dataProductOpendapUrl ) {
    # Must be able to access $dataProductOpendapUrl in order to update the
    # catalog. If an error occurred, write the error to stderr and exit with
    # the error code.
    print STDERR $od->errorMessage;
    exit $od->onError;
}
my $info = $od->getOpendapMetadata if $od;
if ( $info ) {
    my $fieldNode = XML::LibXML::Element->new( 'field' );
    $fieldNode->setAttribute( 'name', 'dataProductOddxDims' );
    my $cdataNode = XML::LibXML::CDATASection->new( $info );
    $fieldNode->addChild( $cdataNode );
    $docElement->addChild( $fieldNode );
}

# Search for a field element whose name is dataFieldId and whose text
# value is the dataFieldId being updated
my ($dfidElement) = $catalogDoc->findnodes(qq(/update/add/doc/field[\@name="dataFieldId"][text()="$dataFieldId"]));

if ($dfidElement) {
    # Replace existing doc element with updated doc element
    my $oldDocNode = $dfidElement->parentNode;
    $oldDocNode->replaceNode($docElement);
} else {
    # Add new doc element
    $addNode->addChild($docElement);
}

# Rewrite the Solr Add Document
if ($stdout) {
    print $catalogDoc->toString(1), "\n";
    exit 0;
}
open (OUTFILE, "> $aesir_solr_add_doc") ||
    die "Could not open $aesir_solr_add_doc for writing: $!";
print OUTFILE $catalogDom->toString(1), "\n";
close(OUTFILE);

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
