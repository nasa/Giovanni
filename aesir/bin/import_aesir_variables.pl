#!/usr/bin/perl

##############################################################################
# $Id: import_aesir_variables.pl,v 1.3 2015/11/26 00:39:54 eseiler Exp $
# -@@@ AESIR Version: $Name:  $
##############################################################################

=head1 NAME

import_aesir_variables.pl - Import an AESIR variable from one AESIR instance into another

=head1 PROJECT

AESIR

=head1 SYNOPSIS

import_aesir_variables.pl [--help --nochange] dataFieldId sourceCatalogUrl destinationCatalogUrl

=head1 DESCRIPTION

Import an AESIR variable from one AESIR instance into another. AESIR instances are expected to be based upon Solr. The variable has a unique identifier whose Solr field is named dataFieldId. A variable will not be imported if there is already a variable with the same dataFieldId in the destination catalog.

=head1 PARAMETERS

=over 4

=item dataFieldId

The identifier in the source catalog for the variable to be imported.

=over 4

=item sourceCatalogUrl

The base URL for accessing the (Solr) source catalog, which is the catalog from which a variable is being copied. A Solr query is formed from the base URL followed by '/select', e.g. a base URL is 'http://aesir.gsfc.nasa.gov/aesir_solr/TS1'

=item destinationCatalogUrl

The base URL for accessing the (Solr) destination catalog, which is the catalog to which the data variable is being copied. It has the same form as the source catalog URL.

=back

=head1 OPTIONS

=over 4

=item --help

Display help for the script

=item --force

Force a variable to be imported even if a variable with the same dataFieldId already exists in the destination catalog

=item --nochange

Instead of importing the variable to the destination catalog, print the
information that is to be imported to stderr.

=item --verbose

Display verbose status information.

=back

=head1 AUTHOR

=head1 EXAMPLE

import_aesir_variables.pl TRMM_3B42_007_precipitation http://aesir.gsfc.nasa.gov/aesir_solr/TS1 http://aesir.gesdisc.eosdis.nasa.gov/aesir_solr/TS2

Copies the variable whose identifier (dataFieldId) is TRMM_3B42_007_precipitation from the source catalog Solr instance at http://aesir.gsfc.nasa.gov/aesir_solr/TS1 to the destination catalog at http://aesir.gsfc.nasa.gov/aesir_solr/TS2

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=cut


my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
}

use strict;
use Getopt::Long;
use LWP::UserAgent;
use XML::LibXML;
use XML::LibXSLT;
use DateTime;
use Date::Parse;
use Time::HiRes qw (gettimeofday);
use Safe;

# Read EDDA configuration file that is in the path where this script
# is installed.
# This configuration file will be used to obtain the baseline-dependent
# URLs, the Solr add document for the destination catalog, and the stylesheet
# used to convert a Solr catalog query response to the form of a Solr add
# document.
my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read configuration file $cfgFile\n";
}

my $usage = "\nusage: $0 dataFieldId sourceCatalogUrl destinationCatalogUrl\n";

my $help;
my $nochange;
my $force;
my $listsource;
my $verbose;
my $result = Getopt::Long::GetOptions ("help"        => \$help,
                                       "nochange"    => \$nochange,
				       "force"       => \$force,
				       "listsource"  => \$listsource,
				       "verbose"     => \$verbose);
if ($help) {
    print STDERR "$usage\n";
    exit 0;
}

my $dataFieldId = shift @ARGV;
my $sourceCatalogUrl = shift @ARGV;
my $destinationCatalogUrl = shift @ARGV;
unless ($dataFieldId && $sourceCatalogUrl && $destinationCatalogUrl) {
    die "$usage\n";
}
$sourceCatalogUrl .= '/' unless $sourceCatalogUrl =~ m{/$};
$destinationCatalogUrl .= '/' unless $destinationCatalogUrl =~ m{/$};

# Invert the hash of values configured for each baseline so that
# instead of having the baseline name as the primary key, the name of the
# baseline URL type as the secondary key, and URLs as the values, have
# the URL be the primary key, and the baselines as the values.
# This will provide a way to look up the configuration corresponding
# to the destination URL that is provided.
unless (defined $CFG::BASELINE_CONFIG) {
    die "Could not find \$BASELINE_CONFIG in $cfgFile\n";
}
my $configBaseline;
foreach my $baselineKey (@CFG::AESIR_BASELINES) {
    my $val= $CFG::BASELINE_CONFIG->{$baselineKey}->{CATALOG_DB_BASE_URL};
    $configBaseline->{$val}->{CATALOG_DB_BASE_URL} = $baselineKey;
}
unless (exists $configBaseline->{$destinationCatalogUrl}) {
    die "Could not find destination catalog URL '$destinationCatalogUrl' configured for any baseline. The configured destination catalog URLs are:\n  " . join("\n  ", sort(keys(%$configBaseline))) . "\n";
}
unless (exists $CFG::AESIR_IMPORT_DESTINATION_SOURCES->{$destinationCatalogUrl}) {
    die "Could not find allowed sources configured for destination '$destinationCatalogUrl'. The destination catalog URLs which have allowed sources configured are:\n  " . join("\n  ", sort(keys(%$CFG::AESIR_IMPORT_DESTINATION_SOURCES))) . "\n";
}
unless (exists $CFG::AESIR_IMPORT_DESTINATION_SOURCES->{$destinationCatalogUrl}->{$sourceCatalogUrl}) {
    die "sourceCatalogUrl '$sourceCatalogUrl' is not an allowed source for destination '$destinationCatalogUrl'. The allowed source catalog URLs are:\n  " . join("\n  ", sort(keys(%{$CFG::AESIR_IMPORT_DESTINATION_SOURCES->{$destinationCatalogUrl}}))) . "\n";
}
my $baseline;
if (exists $configBaseline->{$destinationCatalogUrl}->{CATALOG_DB_BASE_URL}) {
    $baseline = $configBaseline->{$destinationCatalogUrl}->{CATALOG_DB_BASE_URL};
} else {
    die "Could not find CATALOG_DB_BASE_URL configured for $destinationCatalogUrl in BASELINE_CONFIG of configuration file $cfgFile\n";
}

my $destinationAddDoc = $CFG::AESIR_SOLR_ADD_DOC->{$baseline}
    if exists $CFG::AESIR_SOLR_ADD_DOC->{$baseline};
unless ($destinationAddDoc) {
    die "No AESIR_SOLR_ADD_DOC configured for baseline $baseline in configuration $cfgFile\n";
}
my $styleSheetFile = $CFG::AESIR_CATALOG_EXPORT_TO_ADD_DOC_XSL;
unless (defined $styleSheetFile) {
    die "No :AESIR_CATALOG_EXPORT_TO_ADD_DOC_XSL configured for baseline $baseline\n";
}
unless ( $sourceCatalogUrl =~ m{^https?://[\w.-]+(?::\d+)?/[-\w\d/.~]+$} ) {
    die $usage . "Second argument should be the base URL for the source catalog Solr instance\n";
}
$sourceCatalogUrl =~ s{/+$}{};  # Remove trailing slashes
unless ( $destinationCatalogUrl =~ m{^https?://[\w.-]+(?::\d+)?/[-\w\d/.~]+$} ) {
    die $usage . "Third argument should be base URL for destination catalog Solr instance\n";
}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

# Parse destination catalog and check if the variable being imported
# is already there
my $dataFieldAlreadyExisted;
unless (open(UPDATED, "+< $destinationAddDoc")) {
    exit_with_error("Could not open $destinationAddDoc for updating: $!")
}
flock(UPDATED, 2);
my $catalogDom;
eval { $catalogDom = $parser->parse_file($destinationAddDoc); };
if ($@) {
    die "Could not parse $destinationAddDoc\n";
}
my $catalogDoc = $catalogDom->documentElement();
my @dataFieldIdNodes = $catalogDoc->findnodes(qq(/update/add/doc/field[\@name='dataFieldId']));
my %destinationDataFieldIds = map {$_->textContent => $_} @dataFieldIdNodes;
if (exists $destinationDataFieldIds{$dataFieldId}) {
    if ($force) {
	$dataFieldAlreadyExisted = 1;
	print STDERR "\ndataFieldId $dataFieldId already exists in catalog at '$destinationCatalogUrl' (baseline '$baseline'), but importing anyway\n";
    } else {
	die "dataFieldId $dataFieldId already exists in catalog at '$destinationCatalogUrl' (baseline '$baseline'), not importing\n";
    }
}

my $postSolrExe = $rootPath . '/bin/AESIR/post_aesir_solr.pl';
die "Executable '$postSolrExe' not found"
    unless -x $postSolrExe;

my $timeout = 5;
my $ua = LWP::UserAgent->new(timeout => $timeout);

# Create a Solr select query from the source Url, submit it, and
# check the response in order to verify that we can query the source
# catalog
my $query = $sourceCatalogUrl . '/select/';
$query .= '?q=dataFieldId:*&fl=dataFieldId&sort=dataFieldId%20asc&rows=5000&indent=on&omitHeader=true' if $listsource;
my $response = $ua->get($query);
if ($response->is_success) {
    my $contentType = $response->header('Content-Type');
    unless ($contentType =~ m{application/xml}) {
	die "Unexpected Content-Type in response: $contentType\n";
    }

    # Parse response from empty query and verify that it looks like
    # it is from Solr
    my $dom;
    my $doc;
    my $response_xml = $response->content;
    eval { $dom = $parser->parse_string( $response_xml ); };
    if ($@) {
        die "Could not parse response:\n$response_xml\n\nError:\n$@\n";
    }
    $doc = $dom->documentElement();
    my $rootElementName = $doc->nodeName;
    unless ($rootElementName eq 'response') {
	die "Unexpected query response root from source catalog. Expected 'response', found $rootElementName\n";
    }
    print STDERR "\nQuery $query successful\n" if $verbose;
    if ($listsource) {
	my @idNodes = $doc->findnodes('//str');
	my @ids;
	foreach my $idNode (@idNodes) {
	   push @ids, $idNode->textContent;
	}
	print STDERR "\ndataFieldIds in $sourceCatalogUrl:\n", join("\n", @ids), "\n";
	exit 0;
    }
} else {
    die "Error accessing $query:\n" . $response->status_line . "\n";
}

# Create an empty Solr select query from the destination Url, submit it, and
# check the response in order to verify that we can query the destination
# catalog
$query = $destinationCatalogUrl . 'select/';
$response = $ua->get($query);
if ($response->is_success) {
    my $contentType = $response->header('Content-Type');
    unless ($contentType =~ m{application/xml}) {
	die "Unexpected Content-Type in response: $contentType\n";
    }

    # Parse response from empty query and verify that it looks like
    # it is from Solr
    my $dom;
    my $doc;
    my $response_xml = $response->content;
    eval { $dom = $parser->parse_string( $response_xml ); };
    if ($@) {
        die "Could not parse response:\n$response_xml\n\nError:\n$@\n";
    }
    $doc = $dom->documentElement();
    my $rootElementName = $doc->nodeName;
    unless ($rootElementName eq 'response') {
	die "Unexpected query response root from destination catalog. Expected 'response', found $rootElementName\n";
    }
    print STDERR "\nQuery $query successful\n" if $verbose;
} else {
    die "Error accessing $query:\n" . $response->status_line . "\n";
}

# Fetch schema for the source catalog Solr instance and verify that it has
# dataFieldId as the unique key
$query = $sourceCatalogUrl . '/schema/?wt=xml';
$response = $ua->get($query);
if ($response->is_success) {
    my $contentType = $response->header('Content-Type');
    unless ($contentType =~ m{application/xml}) {
	die "Unexpected Content-Type in response: $contentType\n";
    }

    # Parse response and look for dataFieldId as the unique key
    my $dom;
    my $doc;
    my $response_xml = $response->content;
    eval { $dom = $parser->parse_string( $response_xml ); };
    if ($@) {
        die "Could not parse response:\n$response_xml\n\nError:\n$@\n";
    }
    $doc = $dom->documentElement();
    my $rootElementName = $doc->nodeName;
    unless ($rootElementName eq 'response') {
	die "Unexpected query response root. Expected 'response', found $rootElementName\n";
    }

    my ($node) = $doc->findnodes(qq(/response/lst[\@name='schema']/str[\@name='uniqueKey']));
    unless ($node) {
	die "Could not find uniqueKey element in schema\n";
    }
    my $uniqueKey = $node->textContent;
    unless ($uniqueKey eq 'dataFieldId') {
	die "Expected uniqueKey in schema to be 'dataFieldId' but found " . $uniqueKey . "\n";
    }
    print STDERR "\nFound unique key 'dataFieldId' in source catalog.\n" if $verbose;
} else {
    die "Error accessing $query:\n" . $response->status_line . "\n";
}

# Now that we are confident that we are working with an AESIR Solr schema,
# try to fetch the dataField info.
$query = $sourceCatalogUrl . '/select/?q=dataFieldId:' . $dataFieldId . '&wt=xml&omitHeader=true';
$response = $ua->get($query);
if ($response->is_success) {
    my $contentType = $response->header('Content-Type');
    unless ($contentType =~ m{application/xml}) {
	die "Unexpected Content-Type in response: $contentType\n";
    }

    # Parse response and look for dataFieldId
    my $dom;
    my $doc;
    my $response_xml = $response->content;
    eval { $dom = $parser->parse_string( $response_xml ); };
    if ($@) {
        die "Could not parse response:\n$response_xml\n\nError:\n$@\n";
    }
    $doc = $dom->documentElement();

    my ($node) = $doc->findnodes(qq(/response/result/doc/str[\@name='dataFieldId']));
    if ($node) {
	print STDERR "\nFound dataFieldId $dataFieldId in catalog at $sourceCatalogUrl\n";
    } else {
	die "Could not find dataFieldId $dataFieldId in catalog at $sourceCatalogUrl\n";
    }
    my $docNode = $node->parentNode;

    # The imported value dataProductEndDateTime may have a default value
    # that is a date in the future. If so, delete the attribute.
    my ($dataProductEndDateTimeNode) = $docNode->findnodes(qq(date[\@name='dataProductEndDateTime']));
    if ($dataProductEndDateTimeNode) {
	my $dataProductEndDateTime = ($dataProductEndDateTimeNode)->textContent;
	if ((defined $dataProductEndDateTime) && $dataProductEndDateTime) {
	    my $dateTime = Date::Parse::str2time($dataProductEndDateTime);

	    # Get current date/time
	    my $now = scalar(gettimeofday);
	    if ($dateTime > $now) {
		$docNode->removeChild($dataProductEndDateTimeNode);
	    }
	}
    }

    # Transform the dataField info from the query response into the form
    # of a Solr add document
    my $xslt = XML::LibXSLT->new();
    my $styleSheet;
    eval { $styleSheet = $xslt->parse_stylesheet_file($styleSheetFile); };
    if ($@) {
	die "Error parsing stylesheet $styleSheetFile";
    }
    my $transform = $styleSheet->transform($dom);
    my $importDocString = $styleSheet->output_string($transform);
    my $importDocDom;
    eval { $importDocDom = $parser->parse_string( $importDocString ); };
    if ($@) {
        die "Could not parse import document:\n$importDocString\n\nError:\n$@\n";
    }
    my $importDocDoc = $importDocDom->documentElement();
    my ($importDocNode) = $importDocDoc->findnodes(qq(/update/add/doc));
    unless ($importDocNode) {
	die "Unexpected import document:\n$importDocString";
    }

    # Update the destination catalog using the Solr add doc for the
    # imported variable
    my $endpoint = $CFG::BASELINE_CONFIG->{$baseline}->{CATALOG_DB_BASE_URL} . 'update';
#    my $ua = LWP::UserAgent->new(agent => 'post_aesir_solr', timeout => 60);
    my $request = HTTP::Request->new('POST', $endpoint,
                                     [Content_Type => 'text/xml; charset=utf-8'],
                                     $importDocString);
    print STDERR "\nAdd-document content:\n$importDocString" if ($verbose || $nochange);
    unless ($nochange) {
	print STDERR "\nPosting request to $endpoint...\n";
	my $response = $ua->request($request);
	if ($response->is_success) {
	    print STDERR "\n", $response->as_string if $verbose;
	    # If success, expect an xml response, and
	    # parse it to verify that the status is 0
	    my $parser = XML::LibXML->new();
	    $parser->keep_blanks(0);
	    my $dom;
	    my $doc;
	    my $response_xml = $response->content;
	    eval { $dom = $parser->parse_string( $response_xml ); };
	    if ($@) {
		print STDERR "\nCould not parse response:\n$response_xml\n\nError:\n$@\n";
		exit 1;
	    }
	    $doc = $dom->documentElement();
	    my ($statusNode) = $doc->findnodes(qq(/response/lst/int[\@name='status']));
	    unless ($statusNode) {
		print STDERR "\nCould not determine status from response:\n$response\n";
		exit 1;
	    }
	    my $status = $statusNode->textContent;
	    if ($status != 0) {
		print STDERR "\nSolr response contained non-zero status, so not committing\n";
		exit 1;
	    }
	    print STDERR "\nSuccessfully posted addition of $dataFieldId\n";
	} else {
	    die "Error posting to $endpoint:\n" . $response->status_line . "\n";
	    exit 1;
	}

	# Import to the catalog was successful. Commit the change.
	print STDERR "\nCommitting addition of $dataFieldId to Solr...\n";
	my $request2 = HTTP::Request->new('POST', $endpoint,
					  [Content_Type => 'text/xml; charset=utf-8'],
					  '<commit/>');
	my $response2 = $ua->request($request2);
	if ($response2->is_success) {
	    print STDERR "\nSuccessfully committed addition of $dataFieldId\n";
	    print STDERR "\n", $response2->as_string if $verbose;

	    # Add imported variable to Solr catalog add document
	    my ($catalogAddNode) = $catalogDoc->findnodes(qq(/update/add));
	    if ($catalogAddNode) {
		if ($dataFieldAlreadyExisted) {
		    # If a variable with that dataFieldId already existed,
		    # replace the doc element for that variable with the
		    # doc element for the imported variable
		    my $fieldNode = $destinationDataFieldIds{$dataFieldId};
		    my $docNode = $fieldNode->parentNode;
		    $docNode->replaceNode($importDocNode);
		} else {
		    # Add the doc element for the imported variable
		    $catalogAddNode->addChild($importDocNode);
		}
		seek(UPDATED, 0, 0);
		print UPDATED $catalogDom->toString(1), "\n";
		close(UPDATED);
	    }
	} else {
	    die "Error committing to $endpoint:\n" . $response2->status_line . "\n";
	}
    }
} else {
    die "Error accessing $query:\n" . $response->status_line . "\n";
}

exit 0;

1;
