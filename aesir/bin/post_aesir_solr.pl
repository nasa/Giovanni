#!/usr/bin/perl

my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
}

use strict;
use Getopt::Long;
use LWP::UserAgent;
use XML::LibXML;
use Safe;

my $help;
my $baseline;
my $toggleDataFieldActive;
my $activeCount;
my $result = Getopt::Long::GetOptions ("help"          => \$help,
                                       "baseline=s"    => \$baseline,
                                       "toggleField=s" => \$toggleDataFieldActive,
                                       "activeCount"   => \$activeCount);

# Read configuration file
my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read configuration file $cfgFile\n";
}

my $usage = "usage: $0 --baseline " . join('|', reverse sort keys(%$CFG::BASELINE_CONFIG)) . " [--toggleField=dataFieldId] solrAddDoc \n";

if ($help) {
    print STDERR $usage;
    exit 0;
}

my $infile = shift @ARGV;
if (!defined $infile && !$activeCount) {
    print STDERR $usage;
    exit 0;
}

unless (exists $CFG::BASELINE_CONFIG->{$baseline}) {
    print STDERR "'$baseline' is not an allowed value for baseline. Allowed values are ", join('|', keys %$CFG::BASELINE_CONFIG), "\n";
    print STDERR $usage;
}
unless (exists $CFG::BASELINE_CONFIG->{$baseline}->{CATALOG_DB_BASE_URL}) {
    print STDERR "No CATALOG_DB_BASE_URL configured for baseline $baseline\n";
    exit 1;
}
#unless (exists $CFG::BASELINE_CONFIG->{$baseline}->{SSW_BASE_URL}) {
#    print STDERR "No SSW_BASE_URL configured for baseline $baseline\n";
#    exit 1;
#}
unless (exists $CFG::BASELINE_CONFIG->{$baseline}->{SLD_BASE_URL}) {
    print STDERR "No SLD_BASE_URL configured for baseline $baseline\n";
    exit 1;
}

if ($activeCount) {

    # Use Solr query to get a count of all active fields in the baseline

    my $url = $CFG::BASELINE_CONFIG->{$baseline}->{CATALOG_DB_BASE_URL} . 'select/?q=dataFieldActive:true&wt=xml&indent=true&rows=0&omitHeader=true';
    my $ua = LWP::UserAgent->new(timeout => 5);
    my $response = $ua->get($url);
    if ($response->is_success) {
        my $parser = XML::LibXML->new();
        $parser->keep_blanks(0);
        my $dom;
        my $doc;
        my $response_xml = $response->content;
        eval { $dom = $parser->parse_string( $response_xml ); };
        if ($@) {
            print STDERR "Could not parse response:\n$response_xml\n\nError:\n$@\n";
            exit 1;
        }
        $doc = $dom->documentElement();
        my ($resultNode) = $doc->findnodes(qq(/response/result[\@name='response']));
        unless ($resultNode) {
            print STDERR "Could not determine active count from response:\n$response\n";
            exit 1;
        }
        my $count = $resultNode->getAttribute('numFound');
        if (defined $count) {
            print "$count\n";
            exit 0;
        } else {
            print STDERR "Could not determine active count from response:\n$response\n";
            exit 1;
        }
    }
}

die "Could not find file '$infile' for reading\n" unless -f $infile;
local $/;
open(IN, "< $infile") or die "Could not open file '$infile' for reading: $!\n";
my $xml = <IN>;
close(IN);

my $endpoint;

if ($toggleDataFieldActive) {

    # $toggleDataFieldActive is the id of one data field whose
    # dataFieldActive attribute is to be toggled from 'false' to 'true'
    # or "true' to 'false'. If this option is set, the Solr add doc
    # will be modified to toggle the value of the dataFieldActive attribute
    # for that id, and instead of posting the entire Solr add document,
    # only the portion for updating that data field will be posted.

    my $parser = XML::LibXML->new();
    $parser->keep_blanks(0);
    my $dom;
    my $doc;
    eval { $dom = $parser->parse_string( $xml ); };
    if ($@) {
        die "Could not parse file '$infile'\n";
    }
    $doc = $dom->documentElement();
    my $dataFieldIdAttrName;
    my @nodes;
    # Determine whether the name of the data field id is 'dataFieldId'
    # or 'ParameterId'
    if (@nodes = $doc->findnodes(qq(/update/add/doc[field[\@name='dataFieldId']]))) {
        $dataFieldIdAttrName = 'dataFieldId';
    } elsif (@nodes = $doc->findnodes(qq(/update/add/doc[field[\@name='parameterId']]))) {
        $dataFieldIdAttrName = 'parameterId';
    } else {
        die "Cannot determine data field identifier attribute\n";
    }
    foreach my $node (@nodes) {
        my ($idNode) = $node->findnodes(qq(./field[\@name='$dataFieldIdAttrName']));
        unless ($idNode) {
            print STDERR "Found a doc without a field named $dataFieldIdAttrName\n";
            next;
        }
        my $dataFieldId = $idNode->textContent;
        next unless ($dataFieldId eq $toggleDataFieldActive);
        my ($dataFieldActiveNode) = $node->findnodes(qq(./field[\@name='dataFieldActive']));
        unless ($dataFieldActiveNode) {
            die "Doc with field id $dataFieldId does not have a child named dataFieldActive\n";
        }
        my $dataFieldActive = $dataFieldActiveNode->textContent;
        my $newDataFieldActive = ($dataFieldActive eq 'true') ? 'false' : 'true';
        $dataFieldActiveNode->removeChildNodes();
        $dataFieldActiveNode->appendText($newDataFieldActive);
        $xml = $dom->toString(1);
        open(OUT, "> $infile") or die "Could not open file '$infile' for writing: $!\n";
        print OUT $xml, "\n";
        close(OUT);

        # Assume there is only one doc whose '<field name="dataFieldId">'
        # value is the data field id
        last;

#        my $addDocDom = $parser->parse_string('<update></update>');
#        my $addDocDoc = $addDocDom->documentElement();
#        my $addElement = XML::LibXML::Element->new('add');
#        $addElement->setAttribute('overwrite', 'true');
#        $addElement->addChild($node);
#        $addDocDoc->addChild($addElement);
#        $xml = $addDocDoc->toString(1);
    }

}

# Fill in any placeholders for baseline-dependent values
$xml =~ s#https?://SOLR_HOST/#$CFG::BASELINE_CONFIG->{$baseline}->{SSW_BASE_URL}#g if exists $CFG::BASELINE_CONFIG->{$baseline}->{SSW_BASE_URL};
$xml =~ s#https?://G4_HOST/#$CFG::BASELINE_CONFIG->{$baseline}->{SLD_BASE_URL}#g;


# Attempt to post the update, and exit if an error is detected
#foreach my $cfg_hash (@{$baselineConfig->{$baseline}}) {
#    my $solrPath = $cfg_hash->{SOLR_PATH};
    # Set the endpoint for the Solr update command URL
#    $endpoint = 'http://' . $solrPath . '/update';
    $endpoint = $CFG::BASELINE_CONFIG->{$baseline}->{CATALOG_DB_BASE_URL} . 'update';
    print STDERR "\nPosting request to $endpoint...\n\n";
    my $ua = LWP::UserAgent->new(agent => 'post_aesir_solr', timeout => 60);
    my $request = HTTP::Request->new('POST', $endpoint,
                                     [Content_Type => 'text/xml; charset=utf-8'],
                                     $xml);
    my $response = $ua->request($request);
    if ($response->is_success) {
        print STDERR $response->content;

        # If success, expect an xml response, and
        # parse it to verify that the status is 0
        my $parser = XML::LibXML->new();
        $parser->keep_blanks(0);
        my $dom;
        my $doc;
        my $response_xml = $response->content;
        eval { $dom = $parser->parse_string( $response_xml ); };
        if ($@) {
            print STDERR "Could not parse response:\n$response_xml\n\nError:\n$@\n";
            exit 1;
        }
        $doc = $dom->documentElement();
        my ($statusNode) = $doc->findnodes(qq(/response/lst/int[\@name='status']));
        unless ($statusNode) {
            print STDERR "Could not determine status from response:\n$response\n";
            exit 1;
        }
        my $status = $statusNode->textContent;
        if ($status != 0) {
            print STDERR "Solr response contained non-zero status, so not committing\n";
            exit 1;
        }
    } else {
        print $response->status_line, "\n", $response->content, "\n";
        exit 1;
    }

    # The post succeeded without error, so post a request to commit the update
    print STDERR "\nCommitting update to Solr...\n\n";
    my $request2 = HTTP::Request->new('POST', $endpoint,
                                      [Content_Type => 'text/xml; charset=utf-8'],
                                      '<commit/>');
    my $response2 = $ua->request($request2);

    print STDERR $response2->content;
#}

exit 0;
