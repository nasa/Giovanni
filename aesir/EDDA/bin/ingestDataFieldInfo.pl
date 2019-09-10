#!/usr/bin/perl

################################################################################
# $Id: ingestDataFieldInfo.pl,v 1.6 2015/07/09 02:17:04 eseiler Exp $
# -@@@ AESIR EDDA Version: $Name:  $
################################################################################

=head1 NAME

ingestDataFieldInfo - Ingest AESIR information for one or more data fields

=head1 PROJECT

AESIR EDDA

=head1 SYNOPSIS

ingestDataFieldInfo [--help] [--action=compare|save|publish] [--outdir=outputDirectory]  dataFieldArchiveFile

=head1 DESCRIPTION

Ingest AESIR information for one or more data fields.

=head1 OPTIONS

=over 4

=item action=compare

Only compare data fields with existing data fields and report the differences

=item action=save

Save the ingested data fields but do not publish them (default)

=item action=publish

Save the ingested data fields and publish them

=back

=head1 OUTPUT

Output is a compressed tar archive file consisting of the subset of data fields
from the ingested set of data fields that already existed in EDDA, in their
state before the ingest was performed. If none of the ingested fields existed
before in EDDA, then no output file will be produced.

The output file is written to the current working directory by default,
or to the directory specified by outdir.

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=cut


my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    if (defined $rootPath) {
#	unshift( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) );
	unshift( @INC, $rootPath . 'share/perl5' );
    }
}

use strict;
use Getopt::Long;
use XML::LibXML;
use File::Copy;
use File::Basename;
use Time::HiRes qw (gettimeofday);
use EDDA::Compare;
use EDDA::Ingest;
use LWP::UserAgent;
use HTTP::Request::Common;
use URI;
use Safe;
use Text::Abbrev;

my $DEBUG;

# Process input options and arguments

my $action = 'compare';
my $help;
my $outputDir;
my $usage = "usage: $0 [--help] [--action=compare|save|publish] [--outdir=outputDirectory] dataFieldArchiveFile\n";
Getopt::Long::GetOptions( 'help'     => \$help,
                          'action=s' => \$action,
                          'outdir=s' => \$outputDir );
if ($help) {
    print $usage;
    exit 0;
}

my $uploadFile = $ARGV[0];
unless (defined $uploadFile) {
    die "$usage";
}

if ($outputDir && ! -d $outputDir) {
    die "Output directory $outputDir not found\n";
}

# Read EDDA configuration into CFG namespace
my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read configuration file $cfgFile";
}

# Check for required configuration values
die "AESIR_CATALOG_DATA_FIELDS_DIR not defined in configuration"
    unless defined $CFG::AESIR_CATALOG_DATA_FIELDS_DIR;
my $dataFieldsDir = "$CFG::AESIR_CATALOG_DATA_FIELDS_DIR";

my $baseline = $CFG::EDDA_BASELINE;

# Create object from archive file
my $ingest = EDDA::Ingest->new(ARCHIVE => $uploadFile);
die "Unknown error ingesting $uploadFile\n" unless $ingest;
if ($ingest->onError) {
    die $ingest->errorMessage, "\n";
}
unless ($ingest->validateSchema($CFG::EDDA_DATA_FIELD_SCHEMA)) {
    die $ingest->errorMessage, "\n";
}
unless ($ingest->validateRules($CFG::ADD_DOC_DATA_FIELD_MAPPING)) {
    die $ingest->errorMessage, "\n";
}

# Allow 'action' option to be abbreviated, and if it is, unabbreviate it.
my $actionExpand = abbrev qw(compare save publish);
$action = $actionExpand->{ lc($action) };

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);
my @existingIds;

foreach my $ingestedFile ($ingest->ingestedFiles) {

    # Parse the file and obtain the dataFieldId value
    my $dom = $parser->parse_file($ingestedFile);
    my $doc = $dom->documentElement();
    my ($dataFieldIdNode) = $doc->findnodes('/dataField/dataFieldId/value');
    my $dataFieldId = $dataFieldIdNode->textContent if $dataFieldIdNode;

    # Assume that the file name is identical to its dataFieldId
    my $existingFile = "$dataFieldsDir/$dataFieldId";
    if (-f $existingFile) {
        # A data field with dataFieldId already exists.
        # Save the dataFieldId in @existingIds
        push @existingIds, $dataFieldId;
        if ($action eq 'compare') {
            # Compare the field being ingested with the existing data field
            # and report the differences.
            my $comparer = EDDA::Compare->new(ORIGINAL_XML_FILE => $existingFile,
                                              UPDATED_XML_FILE  => $ingestedFile);
            if ($comparer && !$comparer->onError) {
                my $allDifferences = $comparer->compareAll;
                my $comment;
                foreach my $key (sort keys %$allDifferences) {
                    next if $key =~ /dataFieldState/;  # Do not report state
                    $comment .= "\n$key: " . join("\n", @{$allDifferences->{$key}}) . "\n";
                }
                print "Comparison of existing $dataFieldId with upload: \n";
                print "$comment\n"
            }
        }
    } else {
        print "$dataFieldId is a new data field\n"
            if ($action eq 'compare');
    }
}
exit 0 if ($action eq 'compare');


# If not just doing a comparison, confirm that configuration exists for
# creating a new data field and updating an existing data field

unless (defined $CFG::CREATE_URL) {
    die "Configuration error: No values configured for CREATE_URL\n";
}

unless (defined $CFG::UPDATE_URL) {
    die "Configuration error: No values configured for UPDATE_URL\n";
}

if (@existingIds) {

    # Create archive of all existing data field files that are being updated
    my $timeStamp = scalar(gettimeofday);
    $timeStamp =~ s/\./_/;
    my $backupArchiveFile = 'ingestDataFieldInfo_backup_' . $timeStamp . '.tar.gz';
    $backupArchiveFile = File::Spec->catfile($outputDir, $backupArchiveFile)
        if $outputDir;
    my $output = safe_exec('/bin/gtar', '--create', '-z',
                           '-f', $backupArchiveFile,
                           '-C', $dataFieldsDir, @existingIds);
    print "Created $backupArchiveFile\n" if -f $backupArchiveFile;
}

my $ua = LWP::UserAgent->new();
my $params = {};
$params->{action} = $action;

# Process each data field in the input archive
foreach my $ingestedFile ($ingest->ingestedFiles) {
    my $fname = basename($ingestedFile);

    # Parse the file and obtain the dataFieldId value
    my $dom = $parser->parse_file($ingestedFile);
    my $doc = $dom->documentElement();
    my ($dataFieldIdNode) = $doc->findnodes('/dataField/dataFieldId/value');
    my $dataFieldId = $dataFieldIdNode->textContent if $dataFieldIdNode;

    my $response;
    my $copySuccess;
    my $backupFile;
    my $existingFile = "$dataFieldsDir/$dataFieldId";
    if (-f $existingFile) {

        # Send HTTP request to update the existing data field

        my $uri = URI->new($CFG::UPDATE_URL);
        $params->{comment} = "$0 Ingested $fname from $uploadFile";

        # POST
	$uri->query_form($params);
	my $ingestUrl = $uri->as_string;
	my $content = $dom->toString();
        my $request = HTTP::Request::Common::POST( $ingestUrl,
                                                   Content_Type=>'application/xml',
                                                   Content=>$content
                                                 );
        $response = $ua->request( $request );

        # GET with file
#        $params->{updatedDataFieldFile} = $ingestedFile;
#        $params->{ignoreTimestamp} = 1;
#        $uri->query_form($params);
#        my $ingestUrl = $uri->as_string;
#        my $request = HTTP::Request::Common::GET( $ingestUrl,
#                                                  Content_Type=>'application/xml',
#                                                );
#        $response = $ua->request( $request );
    } else {

        # Send HTTP request to create a new data field

        # POST
        my $content = $dom->toString();
        my $request = HTTP::Request::Common::POST( $CFG::CREATE_URL,
                                                   Content_Type=>'application/xml',
                                                   Content=>$content
                                                 );
        $response = $ua->request( $request );

        # GET with file
#        my $uri = URI->new($CFG::CREATE_URL);
#        $params->{newDataFieldInfoFile} = $ingestedFile;
#        $uri->query_form($params);
#        my $ingestUrl = $uri->as_string;
#        my $request = HTTP::Request::Common::GET( $ingestUrl,
#                                                  Content_Type=>'application/xml',
#                                                );
#        $response = $ua->request( $request );
    }

    # Process response from create/update request
    if ( $response->is_success ) {
        my $content = $response->content;
        my $responseDom;
        eval { $responseDom = $parser->parse_string($content); };
        unless ($@) {
            my $responseDoc = $responseDom->documentElement();
            my ($node) = $responseDoc->findnodes('errorMessage');
            if ($node) {
                my $message = $node->textContent;
                print STDERR "Error occurred ingesting $fname : \n",
                    $message, "\n";
                exit 1;
            }
        }
        print "Successfully ingested $fname\n";
    } else {
        if ( $response->content =~ /timeout/ ) {
            print STDERR "Timeout occurred ingesting $fname\n";
            exit 1;
        }
        else {
            if ( $response->is_error ) {
                print STDERR "Error occurred ingesting $fname : \n",
                    $response->content, "\n";
                exit 1;
            } else {
                print STDERR "Error occurred ingesting $fname via $CFG::UPDATE_URL : \n",
                    $response->content, "\n";
            }
        }
    }
}


exit 0;



sub safe_exec {
    my $cmd_str = join( ' ', map { qq('$_') } @_ );

    my $output;
    my $pid;
    die "$0 Cannot fork: $!" unless defined( $pid = open( CHILD, "-|" ) );
    if ( $pid == 0 ) {
        exec(@_) or die "Failed executing $cmd_str: $!";
    }
    else {
        local $/;
        $output = <CHILD>;
        close(CHILD);
    }

    my $status = $? ? ( $? >> 8 ) : $?;
    if ($status) {
        if ($output) {
            print STDERR "Executed $cmd_str with status $status\n" if ($DEBUG);
            print $output;
            exit $status;
        }
        else {
            die "Failed executing $cmd_str: $!, status=$status";
        }
    }
    print STDERR "Successfully executed $cmd_str\n" if ($DEBUG);

    return $output;
}

