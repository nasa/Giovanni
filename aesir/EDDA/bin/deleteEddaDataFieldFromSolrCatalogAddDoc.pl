#!/usr/bin/perl


################################################################################
# $Id: deleteEddaDataFieldFromSolrCatalogAddDoc.pl,v 1.7 2015/12/09 02:47:23 eseiler Exp $
# -@@@ AESIR EDDA Version: $Name:  $
################################################################################

=head1 NAME

deleteEddaDataFieldFromSolrCatalogAddDoc.pl - Delete the entry for a data field in the Solr Add Document (catalog)

=head1 PROJECT

AESIR EDDA

=head1 SYNOPSIS

deleteEddaDataFieldFromSolrCatalogAddDoc.pl dataFieldId baseline

=head1 DESCRIPTION

A script to delete the entry for a data field in the catalog Solr Add
Document. It finds the doc element containing a field named dataFieldId
whose value is the dataFieldId of the data field being deleted, and
deletes that doc element from the Solr Add Document.

=head1 ARGUMENTS

=over 4

=item dataFieldId

The identifier for the data field

=item baseline

The baseline from which the field is being deleted ('TS2', 'TS1', 'Beta', or 'OPS')

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
use Getopt::Long;
use Safe;
use File::Copy;

# Exit codes
my $USAGE_ERROR = 1;
my $CANNOT_READ_CONFIGURATION = 2;
my $UNKNOWN_BASELINE = 3;
my $CATALOG_READ_ERROR = 4;
my $CATALOG_STRUCTURE_ERROR = 5;
my $DATA_FIELD_ID_NOT_FOUND = 6;
my $NO_CATALOG_WRITE_PERMISSION = 7;
my $NO_PUBLISHED_FIELDS_DIR_CFG = 8;
my $NO_PUBLISHED_FIELDS_DIR = 9;
my $NO_DELETED_FIELDS_DIR_CFG = 10;
my $NO_DELETED_FIELDS_DIR = 11;
my $DATA_FIELD_FILE_NOT_FOUND = 12;
my $DATA_FIELD_NOT_MOVED = 13;

my $help;
my $stdout;
my $result = Getopt::Long::GetOptions ("help"      => \$help,
                                       "stdout"    => \$stdout);

my $dataFieldId  = $ARGV[0];
my $solrInstance = $ARGV[1];

my $usage = "usage: $0 dataFieldId [solrInstance]\n";
if ($help) {
    print STDERR $usage;
    exit $USAGE_ERROR;
}

unless ( defined($dataFieldId) ) {
    print STDERR $usage;
    exit $USAGE_ERROR;
}

my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    print STDERR "Could not read configuration file $cfgFile\n";
    exit $CANNOT_READ_CONFIGURATION;
}

$solrInstance = $CFG::EDDA_BASELINE unless $solrInstance;
unless (exists $CFG::AESIR_SOLR_ADD_DOC->{$solrInstance}) {
    print STDERR "Could not find AESIR_SOLR_ADD_DOC->{$solrInstance} defined in $cfgFile\n";
    exit $UNKNOWN_BASELINE;
}
my $aesir_solr_add_doc = $CFG::AESIR_SOLR_ADD_DOC->{$solrInstance};

# Directory where published data field files are found
my $publishedDataFieldsDir = "$CFG::AESIR_CATALOG_PUBLISHED_DATA_FIELDS_DIR->{$solrInstance}";
unless (defined $publishedDataFieldsDir) {
    print STDERR "AESIR_CATALOG_PUBLISHED_DATA_FIELDS_DIR not defined in configuration\n";
    exit $NO_PUBLISHED_FIELDS_DIR_CFG;
}
unless (-d $publishedDataFieldsDir) {
    print STDERR "Directory $publishedDataFieldsDir not found\n";
    exit $NO_PUBLISHED_FIELDS_DIR;
}

# Directory where delete data field files are found
my $deletedDataFieldsDir = "$CFG::AESIR_CATALOG_DELETED_DATA_FIELDS_DIR->{$solrInstance}";
unless (defined $deletedDataFieldsDir) {
    print STDERR "AESIR_CATALOG_DELETED_DATA_FIELDS_DIR for $solrInstance not defined in configuration\n";
    exit $NO_DELETED_FIELDS_DIR_CFG;
}
unless (-d $deletedDataFieldsDir) {
    print STDERR "Directory $deletedDataFieldsDir not found\n";
    exit $NO_DELETED_FIELDS_DIR;
}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

my $catalogDom;
eval { $catalogDom = $parser->parse_file($aesir_solr_add_doc); };
if ($@) {
    print STDERR "Could not parse $aesir_solr_add_doc\n";
    exit $CATALOG_READ_ERROR;
}
my $catalogDoc = $catalogDom->documentElement();
my (@addNodes) = $catalogDoc->findnodes('/update/add');
unless (@addNodes) {
    print STDERR "Could not find 'add' element in $aesir_solr_add_doc\n";
    exit $CATALOG_STRUCTURE_ERROR;
}
if (@addNodes > 1) {
    print STDERR "Found too many add elements in $aesir_solr_add_doc\n";
    exit $CATALOG_STRUCTURE_ERROR;
}
my $addNode = $addNodes[0];


# Search for a field element whose name is dataFieldId and whose text
# value is the dataFieldId being deleted
my @dfidElements = $catalogDoc->findnodes(qq(/update/add/doc/field[\@name="dataFieldId"][text()="$dataFieldId"]));

if (@dfidElements) {
    if (@dfidElements > 1) {
        # dataFieldId is not unique in the Solr Add Document, which shouldn't
        # happen, and since we don't know which one to delete, no deletion
        # will be done

    } else {
        # Delete doc element that contains the dataFieldId
        my $docNode = $dfidElements[0]->parentNode;
        $docNode->unbindNode;
    }
} else {
    # Data field to be deleted not found in the Solr Add Document
    print STDERR "Could not find dataFieldId $dataFieldId in $aesir_solr_add_doc\n";
    exit $DATA_FIELD_ID_NOT_FOUND;
}

# Rewrite the Solr Add Document
if ($stdout) {
    print $catalogDoc->toString(1), "\n";
    exit 0;
}
if (open (OUTFILE, "> $aesir_solr_add_doc") ) {
    print OUTFILE $catalogDom->toString(1), "\n";
    close(OUTFILE);
} else {
    print STDERR "Could not open $aesir_solr_add_doc for writing: $!\n";
    exit $NO_CATALOG_WRITE_PERMISSION;
}

my $dataFieldFile = "$publishedDataFieldsDir/$dataFieldId";
my $deletedDataFieldFile = "$deletedDataFieldsDir/$dataFieldId";

# Move published data field file to deleted data fields directory

unless (-f $dataFieldFile) {
    print STDERR "Readable file $dataFieldFile not found";
#    exit $DATA_FIELD_FILE_NOT_FOUND;
    # Don't consider a missing published data field file to be a fatal error
    exit 0;
}
my $moveStatus = move($dataFieldFile, $deletedDataFieldFile);
unless ($moveStatus) {
    print STDERR "Could not move $dataFieldFile to $deletedDataFieldFile\n";
    exit $DATA_FIELD_NOT_MOVED;
}

exit 0;
