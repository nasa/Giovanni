#!/usr/bin/perl
################################################################################
# $Id: DataProbe.pm,v 1.10 2015/06/30 17:16:51 eseiler Exp $
# -@@@ EDDA Version: $Name:  $
################################################################################
#
# Module for obtaining information about accessing data fields
#
package EDDA::DataProbe;

use 5.008008;
use strict;
use warnings;
use vars '$AUTOLOAD';
use XML::LibXML;
use DateTime;
use Date::Parse;
use LWP::Simple;
use File::Copy;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use EDDA::DataProbe ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


sub new() {
    my ( $class, %input ) = @_;

    my $self = {};


    my $shortName     = $input{SHORTNAME};
    my $versionId     = $input{VERSION};
    my $dataCenter    = $input{DATACENTER};
    my $openDapUrl    = $input{OPENDAPURL};
    my $urlOnly       = $input{URLONLY};
    my $beginDateTime = $input{BEGINDATE};
    my $timeInterval  = $input{TIMEINTERVAL};

    unless ( ((defined $shortName) && (defined $versionId)) ||
             (defined $openDapUrl) ) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Must provide either SHORTNAME and VERSION or OPENDAPURL";
        return bless( $self, $class );
    }

    my $granuleOsddUrl;
    my $granuleUrl;
    my $parser = XML::LibXML->new();

    unless (defined $openDapUrl || not defined $beginDateTime) {
        # If no sample OPeNDAP URL was provided, and the start date of the
        # data coverage was provided, use OpenSearch to try to find
        # a granule URL and a corresponding OPeNDAP URL.

        # Convert DIF-style data center to CMR data provider
        $dataCenter = 'GSFCS4PA' unless defined $dataCenter;
        if ($dataCenter =~ /GESDISC/) {
            $dataCenter = 'GSFCS4PA';
        } elsif ($dataCenter =~ /LAADS/) {
            $dataCenter = 'LAADS';
        } elsif ($dataCenter =~ /LARC_ASDC/) {
            $dataCenter = 'LARC_ASDC';
        } elsif ($dataCenter =~ /LARC/) {
            $dataCenter = 'LARC';
        } elsif ($dataCenter =~ /ASF/) {
            $dataCenter = 'ASF';
        } elsif ($dataCenter =~ /CDDIS/) {
            $dataCenter = 'CDDIS';
        } elsif ($dataCenter =~ /GHRC/) {
            $dataCenter = 'GHRC';
        } elsif ($dataCenter =~ /LPDAAC/) {
            $dataCenter = 'LPDAAC_ECS';
        } elsif ($dataCenter =~ /NSIDCV0/) {
            $dataCenter = 'NSIDCV0';
        } elsif ($dataCenter =~ /NSIDC_ECS/) {
            $dataCenter = 'NSIDC_ECS';
        } elsif ($dataCenter =~ /OBPG/) {
            $dataCenter = 'OBPG';
        } elsif ($dataCenter =~ /OMINRT/) {
            $dataCenter = 'OMINRT';
        } elsif ($dataCenter =~ /ORNL_DAAC/) {
            $dataCenter = 'ORNL_DAAC';
        } elsif ($dataCenter =~ /PODAAC/) {
            $dataCenter = 'PODAAC';
        } elsif ($dataCenter =~ /SEDAC/) {
            $dataCenter = 'SEDAC';
        } elsif ($dataCenter =~ /USGS_EROS/) {
            $dataCenter = 'USGS_EROS';
        }

        # Construct a URL for a granule OSDD and try to obtain a granule
        # OSDD.

        my $granuleOsdd;
        $granuleOsddUrl = _getGranuleOsddUrl($self, 'cmr', $dataCenter,
                                             $shortName, $versionId);
        unless ($granuleOsddUrl) {
            $self->{_ERROR_TYPE} = 2;
            $self->{_ERROR_MESSAGE} = "Could not determine CMR OSDD URL for shortname '$shortName' version '$versionId'";
            return bless( $self, $class );
        }
        $granuleOsdd = LWP::Simple::get($granuleOsddUrl);
        unless (defined $granuleOsdd) {
            $self->{_ERROR_TYPE} = 3;
            $self->{_ERROR_MESSAGE} = "Could not retrieve OSDD for granule for shortname '$shortName' version '$versionId'\n";
            return bless( $self, $class );
        }

        # A granule OSDD was succesfully obtained.
        # Create an OpenSearch engine using the URL for the granule OSDD.
        # Expect that path to ESIP::OSDD can be found in @INC.
        eval {require ESIP::OSDD;};
        if ($@) {
            # ESIP::OSDD module not available
            $self->{_ERROR_TYPE} = 4;
            $self->{_ERROR_MESSAGE} = "$@\n";
            return bless( $self, $class );
        }
        my $osdd;
        eval { $osdd = ESIP::OSDD->new(osddUrl => $granuleOsddUrl); };
        if ($@) {
            # Failed to create an ESIP::OSDD object, OSDD not available
            $self->{_ERROR_TYPE} = 5;
            $self->{_ERROR_MESSAGE} = "Could not obtain granule OSDD from $granuleOsddUrl\n";
            return bless( $self, $class );
        }

        # Determine a time interval that can be expected to produce
        # a search result that contains at least some but not too many
        # granules.
        my ($deltaDate, $deltaDateUnits) = _getDeltaDate($timeInterval);
        unless ((defined $deltaDate) && (defined $deltaDateUnits)) {
            # Cannot handle the time interval provided as an argument
            $self->{_ERROR_TYPE} = 6;
            $self->{_ERROR_MESSAGE} = "Could not determine time interval for search\n";
            return bless( $self, $class );
        }
        my $dtStart = _getDtObj($beginDateTime);
        my $dtEnd = $dtStart->add($deltaDateUnits => $deltaDate);
        my $endDateTime = $dtEnd->iso8601 . 'Z';

        # Perform search for granules.
        my $keyword = '';
        my %params = (
#                      'os:count'   => 1,
                      'geo:box'    => '-180.0,-90.0,180.0,90.0',
#                      'georss:box' => '-180.0,-90.0,180.0,90.0',
#                      'time:start' => '1970-01-01T00:00:00Z',
                      'time:start' => $beginDateTime,
#                      'time:end'   => '2038-01-01T00:00:00Z'
                      'time:end'   => $endDateTime
                     );
        my $response;
        eval { $response = $osdd->performGranuleSearch( 0, %params ); };
        if ($@) {
            # OpenSearch not available
            $self->{_ERROR_TYPE} = 7;
            $self->{_ERROR_MESSAGE} = "Could not perform search for server with OSDD $granuleOsddUrl\n";
            return bless( $self, $class );
        }

        # Check for a timeout or error in the response.
        unless ( $response->{success} ) {
            $self->{_ERROR_TYPE} = 8;
            $self->{_ERROR_MESSAGE} = $response->message;
            return bless( $self, $class );
        }

        # Parse the response (granule search results) from the OpenSearch server
        my $dom;
        $dom = $response->{response}->{raw}->[0]
            if exists($response->{response}->{raw});
        my $doc = $dom->documentElement();

        # Extract the URLs for the granules from the search results
        my ($od_granule_urls, $granule_urls) = _extractGranulesFromDoc($self, $doc);
        unless (@$od_granule_urls) {
            $self->{_ERROR_TYPE} = 9;
            $self->{_ERROR_MESSAGE} = "OpenSearch failed to find any OPeNDAP granules";
            return bless( $self, $class );
        }
        $openDapUrl = @$od_granule_urls[0];
        $granuleUrl = @$granule_urls[0];
    }

#    $openDapUrl =~ s/\.html$// if defined $openDapUrl;
    if ($openDapUrl) {
        $self->{opendapUrl} = $openDapUrl;
        $self->{granuleOsddUrl} = $granuleOsddUrl if defined $granuleOsddUrl;
        $self->{granuleUrl} = $granuleUrl if defined $granuleUrl;
        return bless( $self, $class ) if $urlOnly;
    } else {
        $self->{_ERROR_TYPE} = 10;
        $self->{_ERROR_MESSAGE} = "Could not determine the URL for an OPeNDAP granule";
        return bless( $self, $class );
    }

    # Extract OPeNDAP variable attributes from the granule
    my $variables = _getOpendapVariables($self, $parser);
    $self->{variables} = $variables if $variables;

    return bless( $self, $class );
}



sub _getGranuleOsddUrl {
    my ($self, $OSsource, $dataCenter, $shortName, $versionId) = @_;

    if ($OSsource eq 'cmr') {
        # Construct CMR granule OSDD URL.
        # TO DO: This shortcut will always produce a URL for a CMR granule
        # OSDD, even if the data set is not in CMR. The proper way
        # is to do a CMR data set OpenSearch (perhaps using the shortName
        # as the keyword) and get the OSDD URL from a result with a matching
        # data set id.
        my $cmrGranuleOsddUrlTemplate = "https://cmr.earthdata.nasa.gov/opensearch/granules/descriptor_document.xml?dataCenter=<DATACENTER>&shortName=<SHORTNAME>&versionId=<VERSIONID>&clientId=Giovanni";
        my $cmrGranuleOsddUrl = $cmrGranuleOsddUrlTemplate;
        $cmrGranuleOsddUrl =~ s/<DATACENTER>/$dataCenter/;
        $cmrGranuleOsddUrl =~ s/<SHORTNAME>/$shortName/;
        $cmrGranuleOsddUrl =~ s/<VERSIONID>/$versionId/;

        return $cmrGranuleOsddUrl;
    } else {
        # Unknown OpenSearch server provider
    }
}

sub _extractGranulesFromDoc {
    my ($self, $doc) = @_;

#    DEBUG((caller(0))[3]);
    return unless $doc;

    $CFG::atomNS = 'http://www.w3.org/2005/Atom';
    $CFG::osNS   = 'http://a9.com/-/spec/opensearch/1.1/';
    $CFG::esipNS = 'http://esipfed.org/ns/fedsearch/1.0/';
    $CFG::esipdiscoveryNS = 'http://commons.esipfed.org/ns/discovery/1.2/';

    my @hrefs;
    my @ODhrefs;
#    my @ids;

    my $esipdiscoveryVersion = $doc->getAttributeNS($CFG::esipdiscoveryNS,
                                                    'version');
    my $esip_1_2 = $esipdiscoveryVersion && ($esipdiscoveryVersion >= 1.2);
    my $dataAttr = $esip_1_2 ? 'enclosure' : "${CFG::esipNS}data#";

    # Hack for non-compliant LAADS OpenSearch response, which is missing
    # the '#' at the end of the 're' attribute
    my $dataAttrLAADS = $esip_1_2 ? 'enclosure' : "${CFG::esipNS}data";

    my ($authorNode) = $doc->getChildrenByTagNameNS( $CFG::atomNS, 'author' );
    my ($authorNameNode) = $authorNode->getChildrenByTagNameNS( $CFG::atomNS,
                                                                'name' )
        if $authorNode;
    my $author = $authorNameNode->textContent if $authorNameNode;

    foreach my $entry ( $doc->getChildrenByTagNameNS( $CFG::atomNS, 'entry' ) ) {
        my $ODhrefCount = 0;
        my $hrefCount = 0;
#        if ( $granule_identifier_type ne 'id' ) {
            foreach my $linkNode ( $entry->getChildrenByTagNameNS( $CFG::atomNS,
                                                                   'link' ) ) {
                my $relAttr = $linkNode->getAttribute('rel');
                next unless (($relAttr eq $dataAttr) ||
                             ($relAttr eq $dataAttrLAADS));

                my $href = $linkNode->getAttribute('href');
                next unless $href;

                my $roleAttr = $linkNode->getAttributeNS($CFG::linkNS, 'role');
                if ($roleAttr) {
                    if ($roleAttr =~ /opendap/i) {
                        $href =~ s/ /\%20/g;
                        push @ODhrefs, $href;
                        $ODhrefCount += 1;
                    }
                } else {
                    $href =~ s/ /\%20/g;
                    push @hrefs, $href;
                    $hrefCount += 1;
                }
            }
#        }

#         if ( $author =~ /CMR/ ) {
#             # Currently CMR does not return the GranuleUR in the id tag
#             # (instead they modify the value by changing underscores to periods)
#             # As a workaround, for the time being, we will get the id value
#             # from the "title" tag instead if the author name is "CMR"
#             my ($titleNode) = $entry->getChildrenByTagNameNS( $CFG::atomNS,
#                                                               'title' );
#             if ($titleNode) {
#                 my $id = $titleNode->textContent;
# #                TRACE((caller(0))[3], " entry/title='$id'");
#                 push @ids, $id;
#             }
#         } else {
#             my ($idNode) = $entry->getChildrenByTagNameNS( $CFG::atomNS,
#                                                            'id' );
#             if ($idNode) {
#                 my $id = $idNode->textContent if $idNode;
# #                TRACE((caller(0))[3], " entry/id='$id'");
#                 push @ids, $id;
#             }
#         }
     }
#    return \@ids, \@ODhrefs;

    return \@ODhrefs, \@hrefs;
}

sub _getOpendapVariables {
    my ($self, $parser) = @_;

    my $od_url = $self->{opendapUrl};

    my $ua   = LWP::UserAgent->new();

    # If '/ncml' is found in the path, assume an extension of .ncml should
    # be used
#    if ( ($od_url =~ /\/ncml/) && ($od_url !~ /\.ncml$/) ) {
#        $od_url .= '.ncml';
#    }

    my $ddx_url;
    if ($od_url =~ /\.html$/) {
        ($ddx_url = $od_url) =~ s/\.html$/.ddx/;
    } else {
        $ddx_url = $od_url . ".ddx";
    }
    my $response = $ua->get($ddx_url);
    unless ($response->is_success) {
        $self->{_ERROR_TYPE} = 11;
        $self->{_ERROR_MESSAGE} = "Error getting $ddx_url\n";
        return;
    }
    my $opendapXML = $response->content();
    my $opendapDOM;
    eval { $opendapDOM = $parser->parse_string($opendapXML); };
    if ($@) {
        $self->{_ERROR_TYPE} = 12;
        $self->{_ERROR_MESSAGE} = "Error parsing response from $ddx_url: $@\n";
        return;
    }
    my $opendapDoc = $opendapDOM->documentElement();
    my $xc = _getXPathContext($opendapDoc);

#     my ($descriptionNode) = $xc->findnodes(qq(/default:Dataset/default:Attribute[\@name='coremetadata']/default:Attribute[\@name='INVENTORYMETADATA']/default:Attribute[\@name='COLLECTIONDESCRIPTIONCLASS']));
#     unless ($descriptionNode) {
#         ($descriptionNode) = $xc->findnodes(qq(/default:Dataset/default:Attribute[\@name='CoreMetadata']/default:Attribute[\@name='INVENTORYMETADATA']/default:Attribute[\@name='COLLECTIONDESCRIPTIONCLASS']));
#     }
#     unless ($descriptionNode) {
#         ($descriptionNode) = $xc->findnodes(qq(/default:Dataset/default:Attribute[\@name='/HDFEOS INFORMATION/CoreMetadata']/default:Attribute[\@name='INVENTORYMETADATA']/default:Attribute[\@name='COLLECTIONDESCRIPTIONCLASS']));
#     }
#     unless ($descriptionNode) {
#         print STDERR "Could not find COLLECTIONDESCRIPTIONCLASS for $od_url\n";
# #        next;
#     }
#     my ($shortNameNode) = $xc->findnodes(qq(./default:Attribute[\@name='SHORTNAME']/default:Attribute[\@name='VALUE']/default:value), $descriptionNode);
#     unless ($shortNameNode) {
#         print STDERR "Could not find SHORTNAME value for $od_url\n";
# #        next;
#     }
#     my $shortName = $shortNameNode->textContent();
#     $shortName =~ s/"//g;
#     my ($versionIdNode) = $xc->findnodes(qq(./default:Attribute[\@name='VERSIONID']/default:Attribute[\@name='VALUE']/default:value), $descriptionNode);
#     unless ($versionIdNode) {
#         print STDERR "Could not find VERSIONID value for $od_url\n";
# #        next;
#     }
#     my $versionId = $versionIdNode->textContent();
#     $versionId =~ s/"//g;
#     $versionId = sprintf("%03d", $versionId) unless $versionId =~ /\./;

#     my ($spatialNode) = $xc->findnodes(qq(/default:Dataset/default:Attribute[\@name='coremetadata']/default:Attribute[\@name='INVENTORYMETADATA']/default:Attribute[\@name='SPATIALDOMAINCONTAINER']/default:Attribute[\@name='HORIZONTALSPATIALDOMAINCONTAINER']/default:Attribute[\@name='BOUNDINGRECTANGLE']));
#     unless ($spatialNode) {
#         ($spatialNode) = $xc->findnodes(qq(/default:Dataset/default:Attribute[\@name='CoreMetadata']/default:Attribute[\@name='INVENTORYMETADATA']/default:Attribute[\@name='SPATIALDOMAINCONTAINER']/default:Attribute[\@name='HORIZONTALSPATIALDOMAINCONTAINER']/default:Attribute[\@name='BOUNDINGRECTANGLE']));
#     }
#     unless ($spatialNode) {
#         ($spatialNode) = $xc->findnodes(qq(/default:Dataset/default:Attribute[\@name='/HDFEOS INFORMATION/CoreMetadata']/default:Attribute[\@name='INVENTORYMETADATA']/default:Attribute[\@name='SPATIALDOMAINCONTAINER']/default:Attribute[\@name='HORIZONTALSPATIALDOMAINCONTAINER']/default:Attribute[\@name='BOUNDINGRECTANGLE']));
#     }
#     unless ($spatialNode) {
#         print "Could not find 'HORIZONTALSPATIALDOMAINCONTAINER for $od_url\n";
# #        next;
#     }
#     my ($eastNode) = $xc->findnodes(qq(./default:Attribute[\@name='EASTBOUNDINGCOORDINATE']/default:Attribute[\@name='VALUE']/default:value), $spatialNode);
#     unless ($eastNode) {
#         print "Could not find EASTBOUNDINGCOORDINATE value for $od_url\n";
# #        next;
#     }
#     my $east = $eastNode->textContent();
#     my ($westNode) = $xc->findnodes(qq(./default:Attribute[\@name='WESTBOUNDINGCOORDINATE']/default:Attribute[\@name='VALUE']/default:value), $spatialNode);
#     unless ($westNode) {
#         print "Could not find WESTBOUNDINGCOORDINATE value for $od_url\n";
# #        next;
#     }
#     my $west = $westNode->textContent();
#     my ($northNode) = $xc->findnodes(qq(./default:Attribute[\@name='NORTHBOUNDINGCOORDINATE']/default:Attribute[\@name='VALUE']/default:value), $spatialNode);
#     unless ($northNode) {
#         print "Could not find NORTHBOUNDINGCOORDINATE value for $od_url\n";
# #        next;
#     }
#     my $north = $northNode->textContent();
#     my ($southNode) = $xc->findnodes(qq(./default:Attribute[\@name='SOUTHBOUNDINGCOORDINATE']/default:Attribute[\@name='VALUE']/default:value), $spatialNode);
#     unless ($southNode) {
#         print "Could not find SOUTHBOUNDINGCOORDINATE value for $od_url\n";
# #        next;
#     }
#     my $south = $southNode->textContent();

    # Find latitude and longitude dimensions by using a CF-4 convention.
    # Find all 'Array' nodes with an 'Attribute' child that has a 'name'
    # attribute equal to 'units' where the Attribute node has a
    # 'value' child equal to 'degrees_north'
    my @latArrayNodes = $xc->findnodes(q(//default:Array[default:Attribute[@name='units'][default:value='degrees_north']]));
    return unless @latArrayNodes;
    my $latArrayNode = $latArrayNodes[0];
    (my $latDimNode) = $latArrayNode->getChildrenByTagNameNS($xc->lookupNs('default'), 'dimension');
    my $latDimName = $latDimNode->getAttribute('name');
    my $latDimSize = $latDimNode->getAttribute('size');

    # Find all 'Array' nodes with an 'Attribute' child that has a 'name'
    # attribute equal to 'units' where the Attribute node has a
    # 'value' child equal to 'degrees_east'
    my @longArrayNodes = $xc->findnodes(q(//default:Array[default:Attribute[@name='units'][default:value='degrees_east']]));
    return unless @longArrayNodes;
    my $longArrayNode = $longArrayNodes[0];
    (my $longDimNode) = $longArrayNode->getChildrenByTagNameNS($xc->lookupNs('default'), 'dimension');
    my $longDimName = $longDimNode->getAttribute('name');
    my $longDimSize = $longDimNode->getAttribute('size');

#    my @ArrayNodes = $xc->findnodes(qq(/default:Dataset/default:Array));
    my @ArrayNodes = $xc->findnodes(qq(//default:Array));

#    my $subsetVariablesNode = XML::LibXML::Element->new( 'SubsetVariables' );
#    $subsetVariablesNode->setAttribute('heading', 'Variables');

    my %variables;
    my $attributeNode;
    foreach my $ArrayNode (@ArrayNodes) {
        my $arrayName = $ArrayNode->getAttribute('name');
        my @latDimNodes = $xc->findnodes(qq(./default:dimension[\@name='$latDimName']), $ArrayNode);
        unless (@latDimNodes) {
            #print "Skipping $arrayName Array because it does not have a lat dim\n";
            next;
        }
        my @longDimNodes = $xc->findnodes(qq(./default:dimension[\@name='$longDimName']), $ArrayNode);
        unless (@longDimNodes) {
            #print "Skipping $arrayName Array because it does not have a long dim\n";
            next;
        }
        ($attributeNode) = $xc->findnodes(qq(./default:Attribute[\@name='long_name']/default:value), $ArrayNode);
        my $varLongName = $attributeNode->textContent() if $attributeNode;
        $variables{$arrayName}->{dataFieldLongName} = $varLongName;
        ($attributeNode) = $xc->findnodes(qq(./default:Attribute[\@name='standard_name']/default:value), $ArrayNode);
        my $standardName = $attributeNode->textContent() if $attributeNode;
        $variables{$arrayName}->{dataFieldStandardName} = $standardName if defined $standardName;
        ($attributeNode) = $xc->findnodes(qq(./default:Attribute[\@name='units']/default:value), $ArrayNode);
        my $units = $attributeNode->textContent() if $attributeNode;
        $units = '1' if defined($units) && $units eq 'unitless';
        $variables{$arrayName}->{dataFieldUnits} = $units if defined $units;
        foreach my $fieldName (qw(_FillValue h4__FillValue h5__FillValue missing_value)) {
            ($attributeNode) = $xc->findnodes(qq(./default:Attribute[\@name='$fieldName']/default:value), $ArrayNode);
            if ($attributeNode) {
                my $fillValue = $attributeNode->textContent();
                if (defined $fillValue) {
                    $variables{$arrayName}->{dataFieldFillValue} = $fillValue;
                    $variables{$arrayName}->{dataFieldFillValueFieldName} = $fieldName;
                    last;
                }
            }
        }
    }

    unless (%variables) {
        # Special case for Grib files
        if ($od_url =~ /\.grb$/) {
            @ArrayNodes = $xc->findnodes(qq(/default:Dataset/default:Grid));
            foreach my $ArrayNode (@ArrayNodes) {
                my $arrayName = $ArrayNode->getAttribute('name');
                my @latDimNodes = $xc->findnodes(qq(./default:Array/default:dimension[\@name='$latDimName']), $ArrayNode);
                unless (@latDimNodes) {
                    #print "Skipping $arrayName Array because it does not have a lat dim\n";
                    next;
                }
                my @longDimNodes = $xc->findnodes(qq(./default:Array/default:dimension[\@name='$longDimName']), $ArrayNode);
                unless (@longDimNodes) {
                    #print "Skipping $arrayName Array because it does not have a long dim\n";
                    next;
                }

                ($attributeNode) = $xc->findnodes(qq(./default:Attribute[\@name='long_name']/default:value), $ArrayNode);
                my $varLongName = $attributeNode->textContent() if $attributeNode;
                $variables{$arrayName}->{dataFieldLongName} = $varLongName;
                ($attributeNode) = $xc->findnodes(qq(./default:Attribute[\@name='standard_name']/default:value), $ArrayNode);
                my $standardName = $attributeNode->textContent() if $attributeNode;
                $variables{$arrayName}->{dataFieldStandardName} = $standardName if defined $standardName;
                ($attributeNode) = $xc->findnodes(qq(./default:Attribute[\@name='units']/default:value), $ArrayNode);
                my $units = $attributeNode->textContent() if $attributeNode;
                $units = '1' if $units eq 'unitless';
                $variables{$arrayName}->{dataFieldUnits} = $units if defined $units;
                foreach my $fieldName (qw(_FillValue h4__FillValue h5__FillValue missing_value)) {
                    ($attributeNode) = $xc->findnodes(qq(./default:Attribute[\@name='$fieldName']/default:value), $ArrayNode);
                    if ($attributeNode) {
                        my $fillValue = $attributeNode->textContent();
                        if (defined $fillValue) {
                            $variables{$arrayName}->{dataFieldFillValue} = $fillValue;
                            $variables{$arrayName}->{dataFieldFillValueFieldName} = $fieldName;
                            last;
                        }
                    }
                }

            }
        }
    }

#    foreach my $variable (sort keys %variables) {
#
#    }
    return \%variables;

}

sub _getXPathContext {
    my ( $doc ) = @_;

    # Get and register namespaces
    my $xpc = XML::LibXML::XPathContext->new($doc);
    # Use a hash to avoid duplicates
    my %nameSpace = ();
    foreach my $nsNode ( $doc->findnodes('//namespace::*') ) {
        my $prefix = $nsNode->getLocalName();
        $prefix = 'default' unless defined $prefix;
        my $uri = $nsNode->getData();
        $nameSpace{$prefix} = $uri;
    }
    foreach my $prefix ( keys %nameSpace ) {
        $xpc->registerNs($prefix, $nameSpace{$prefix});
    }
    return $xpc;
}

sub _getDeltaDate {
    my ($timeInterval) = @_;

    my $deltaDate;
    my $deltaDateUnits;
    if ($timeInterval eq 'hourly') {
        $deltaDate = 48;
        $deltaDateUnits = 'hours';
    } elsif ($timeInterval eq '3-hourly') {
        $deltaDate = 2;
        $deltaDateUnits = 'days';
    } elsif ($timeInterval eq 'daily') {
        $deltaDate = 7;
        $deltaDateUnits = 'days';
    } elsif ($timeInterval eq '8-daily') {
        $deltaDate = 2;
        $deltaDateUnits = 'months';
    } elsif ($timeInterval eq 'monthly') {
        $deltaDate = 6;
        $deltaDateUnits = 'months';
    }

    return ($deltaDate, $deltaDateUnits);
}

sub _getDtObj {
    my $dateStr = shift;

    my $message = "'$dateStr' is not a valid date/time value";
    my @parsedDate = Date::Parse::strptime($dateStr);
    unless (@parsedDate) {
        print STDERR "$message\n";
        return;
    }

    my ($ss, $mm, $hh, $day, $month, $year, $zone) = @parsedDate;
    $year +=1900 if $year < 1000;
    $month++;
    $hh = 0 unless $hh;
    $mm = 0 unless $mm;
    $ss = 0 unless $ss;
    my $dtObj;
    eval {
        $dtObj = DateTime->new(year      => $year,
                               month     => $month,
                               day       => $day,
                               hour      => $hh,
                               minute    => $mm,
                               second    => $ss,
                               time_zone => 'UTC');
    };
    if ($@) {
        print STDERR "$message\n";
        return;
    }

    return $dtObj;
}


sub AUTOLOAD {
    my ( $self, @args ) = @_;
    if ( $AUTOLOAD =~ /.*::dataFields/ ) {
        return ($self->{variables}) if exists $self->{variables};
    }
    elsif ( $AUTOLOAD =~ /.*::dataFieldNames/ ) {
        return (keys %{$self->{variables}}) if exists $self->{variables};
    }
    elsif ( $AUTOLOAD =~ /.*::dataFieldAttributes/ ) {
        return ($self->{variables}->{$args[0]})
            if exists $self->{variables} &&
            defined $args[0] &&
            exists $self->{variables}->{$args[0]};
    }
    elsif ( $AUTOLOAD =~ /.*::dataFieldAttribute/ ) {
        return $self->{variables}->{$args[0]}->{$args[1]}
            if exists $self->{variables} &&
            defined $args[0] &&
            exists $self->{variables}->{$args[0]} &&
            defined $args[1] &&
            exists $self->{variables}->{$args[0]}->{$args[1]};
    }
#    elsif ( $AUTOLOAD =~ /.*::set_(.+)/ ) {
#        if (exists $self->{variables}->{$1}) {
#            return $self->{variables}->{$1} = $arg;
#        }
#    }
    elsif ( $AUTOLOAD =~ /.*::opendapUrl/ ) {
        return ($self->{opendapUrl}) if exists $self->{opendapUrl};
    }
    elsif ( $AUTOLOAD =~ /.*::granuleOsddUrl/ ) {
        return ($self->{granuleOsddUrl}) if exists $self->{granuleOsddUrl};
    }
    elsif ( $AUTOLOAD =~ /.*::granuleUrl/ ) {
        return ($self->{granuleUrl}) if exists $self->{granuleUrl};
    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE};
    }
    return undef;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

EDDA::DataProbe - Perl module for encapsulating EDDA DataProbe

=head1 SYNOPSIS

 use EDDA::DataProbe;
 $dataProbe = EDDA::DataProbe->new(SHORTNAME => $shortName, VERSION =>$version, DATACENTER => $dataCenter);
 $variableValue = $dataProbe->get_<variableName>;

=head1 DESCRIPTION

EDDA::DataProbe provides accessors for the attributes of a dataset that
can be searched for in CMR

=head1 CONSTRUCTOR

=over 4

=item new( SHORTNAME => $shortName, VERSION =>$version, DATACENTER => $dataCenter)

=back

=head1 METHODS

=over 4

=item get_<attributeName>

Accessor that retrieves the value of the attribute with name attributeName,
e.g. if the attribute name is "east", then get_east retrieves the value.

=item variableNames

Returns a list of the atrribute names found in the manifest file.

=item onError

Returns a value if there was an error creating the DataProbe object.

=item errorMessage

If onError() has a value, returns a message describing the error.

=item variables

Returns a reference to a hash whose keys are the atrribute names and whose
values are the attribute values of the variables.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO
 

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.gov<gt>

=cut
