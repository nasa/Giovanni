#!/usr/bin/perl
=head1 NAME

promoteDataField.pl - Promote a variable from the EDDA baseline to a higher baseline

=head1 PROJECT

AESIR EDDA

=head1 SYNOPSIS

promoteDataField.pl [--activate] [--deactivate] [--commit] dataFieldId baseline

=head1 DESCRIPTION

Promote a variable from the EDDA baseline to a higher baseline. Optionally commit the updated version of the catalog document to a CVS repository.

=head1 OPTIONS

=over 4

=item activate

Set the value of dataFieldActive to 'true' in AESIR. By default the value will
be 'false'

=item deactivate

Set the value of dataFieldActive to 'false' in AESIR. Since the default value
is 'false', this anly takes effect if the value has already beeb set to 'true'.

=item commit

Commit the changes to the catalog document to a CVS repository. Currently
works only for a configured CVS environment.

=back

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=cut

my $rootPath;
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    unshift@INC, $rootPath . 'share/perl5'
      if defined $rootPath;
}

use strict;
use XML::LibXML;
use Safe;
use Time::HiRes qw (gettimeofday);
use DateTime;
use Getopt::Long;
use File::Basename;
use File::Temp;
use File::Spec;
use File::Copy;
use EDDA::Compare;

my $usage = "Usage: $0 [--activate] [--deactivate] [--commit] dataFieldId Beta|OPS";

my $help;
my $activate;
my $deactivate;
my $commit;
my $result = Getopt::Long::GetOptions ("help"          => \$help,
                                       "activate"      => \$activate,
                                       "deactivate"    => \$deactivate,
                                       "commit"        => \$commit);

my $dataFieldId = $ARGV[0];
my $pubBaseline = $ARGV[1];

exit_with_error($usage)
    unless ( (defined $dataFieldId) && (defined $pubBaseline) );

my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    exit_with_error("Could not read configuration file $cfgFile\n");
}

if (@CFG::AESIR_BASELINES) {
    # Only allow promotion to baselines higher than $CFG::EDDA_BASELINE
    while (@CFG::AESIR_BASELINES && $CFG::EDDA_BASELINE !~ /^$CFG::AESIR_BASELINES[0]$/) {
        shift @CFG::AESIR_BASELINES;
    }
    shift @CFG::AESIR_BASELINES;
}
if (@CFG::AESIR_BASELINES) {
    my $baselinesPattern = '^' . join('|', @CFG::AESIR_BASELINES) . '$';
    exit_with_error("Unknown baseline '$pubBaseline'")
	unless $pubBaseline =~ /^$baselinesPattern$/;
} else {
    exit_with_error("No baselines higher than '$pubBaseline' found");
}

my $publishedDataFieldsDir = "$CFG::AESIR_CATALOG_PUBLISHED_DATA_FIELDS_DIR->{$pubBaseline}";
exit_with_error("Directory $publishedDataFieldsDir not found")
    unless -d $publishedDataFieldsDir;

my $eddaPublishedDataFieldsDir = "$CFG::AESIR_CATALOG_PUBLISHED_DATA_FIELDS_DIR->{TS1}";
exit_with_error("Directory $eddaPublishedDataFieldsDir not found")
    unless -d $eddaPublishedDataFieldsDir;

my $eddaPublishedDataFieldFile = "$eddaPublishedDataFieldsDir/$dataFieldId";
exit_with_error("Published data field file $eddaPublishedDataFieldFile not found. Data field must be published to TS1 before it can be published to higher baselines.")
    unless -r $eddaPublishedDataFieldFile;

my $eddaDataFieldsDir = "$CFG::AESIR_CATALOG_PUBLISHED_DATA_FIELDS_DIR->{TS1}";
exit_with_error("Directory $eddaDataFieldsDir not found")
    unless -d $eddaDataFieldsDir;

my $eddaDataFieldFile = "$eddaDataFieldsDir/$dataFieldId";
exit_with_error("Data field file $eddaDataFieldFile not found.")
    unless -r $eddaDataFieldFile;

unless (exists $CFG::AESIR_SOLR_ADD_DOC->{$pubBaseline}) {
    my $message = "Internal error: Could not find AESIR_SOLR_ADD_DOC->{$pubBaseline} defined in $cfgFile\n";
    exit_with_error($message);
}
my $addDocFile = $CFG::AESIR_SOLR_ADD_DOC->{$pubBaseline};
unless (-w $addDocFile) {
    my $message = "Internal error: Could not find writeable $addDocFile\n";
    exit_with_error($message);
}

# Check that we can access the add document in CVS
my $cvsPath = project_path($pubBaseline, $addDocFile);
my $tempDir;
if ($commit) {
    my $rlogOutput = `cvs rlog -h $cvsPath`;
    if ($?) {
        my $message = "Failed to obtain rlog of $cvsPath in CVS\n";
        exit_with_error($message);
    }

    # Create a temporary directory for performing CVS checkout and update
    $tempDir = File::Temp::tempdir( CLEANUP => 1 );
}

my $updateAddDocExe = $rootPath . 'bin/AESIR/EDDA/updateSolrCatalogAddDocFromEdda.pl';
exit_with_error("Executable '$updateAddDocExe' not found")
    unless -x $updateAddDocExe;

my $postSolrExe = $rootPath . 'bin/AESIR/post_aesir_solr.pl';
exit_with_error("Executable '$postSolrExe' not found")
    unless -x $postSolrExe;

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

# Parse data field info
my $dataFieldDom;
eval { $dataFieldDom = $parser->parse_file($eddaPublishedDataFieldFile); };
if ($@) {
    exit_with_error("Error parsing $eddaPublishedDataFieldFile as xml: $@");
}
my $dataFieldDoc = $dataFieldDom->documentElement();

# Check the Solr add document to see if the data field has already been
# published to the desired baseline, and if so, if it is active or disabled
my $active;
my $addDocDom;
eval { $addDocDom = $parser->parse_file( $addDocFile ); };
if ($@) {
    exit_with_error("Could not parse $addDocFile\n");
}
my $addDocDoc = $addDocDom->documentElement();
my $addDocDfNode;
my ($idNode) = $addDocDoc->findnodes( qq(/update/add/doc/field[\@name='dataFieldId' and text()='$dataFieldId']) );
if ($idNode) {
    $addDocDfNode = $idNode->parentNode;
    if ($addDocDfNode) {
        my ($node) = $addDocDfNode->findnodes( qq(./field[\@name='dataFieldActive']) );
        if ($node) {
            $active = $node->textContent();
        }
    }
}

# If data field has already been published to the higher baseline
# with dataFieldActive "true", set dataFieldActive to "true", otherwise
# set it to "false".
# Assume that dataFieldActive is 'true' in the EDDA baseline data field file,
# so to set dataFieldActive to 'false' in a higher baseline, the
# field must be toggled when the TS1 data field file is published
# to Solr via $postSolrExe.
my $toggle;
unless ($active eq 'true') {
    unless ($activate) {
        $active = 'false';
        $toggle = 1;
    }
}
if ($deactivate) {
    $active = 'false';
    $toggle = 1;
}
my ($dataFieldActiveNode) = $dataFieldDoc->findnodes('/dataField/dataFieldActive/value');
if ($dataFieldActiveNode) {
    my $dataFieldActive = $dataFieldActiveNode->textContent;
    $dataFieldActiveNode->removeChildNodes();
    $dataFieldActiveNode->appendText($active);
}

my $comment;

my $publishedFile = "$publishedDataFieldsDir/$dataFieldId";
if (-f $publishedFile) {
    # Data field has been published before, so compare information being
    # published with the information that was published
    my $comparer = EDDA::Compare->new(ORIGINAL_XML_FILE => $publishedFile,
                                      UPDATED_XML_FILE  => $eddaPublishedDataFieldFile
);
    my $allDifferences = $comparer->compareAll;
    foreach my $key (sort keys %$allDifferences) {
        my ($keyname) = $key =~ /.+\/(.+)/;
        next if $keyname eq 'dataFieldState';  # Do not report state
        next if $keyname eq 'dataFieldLastModified';
        next if $keyname eq 'dataFieldLastPublished';
        $comment .= "\n$keyname: " . join("\n", @{$allDifferences->{$key}}) . "\n";
	foreach my $attr (@CFG::RESCRUB_DATA_ATTRIBUTES) {
	    if ($attr eq $keyname) {
                $comment .= "*** $attr REQUIRES RESCRUBBING ***\n";
	    }
	}
    }
} else {
    $comment .= "\nFirst publication for $dataFieldId to $pubBaseline\n";
}
my (@sldNodes) = $dataFieldDoc->findnodes('/dataField/dataFieldSld/value');
if (@sldNodes) {
    $comment .= "\nSLD names: \n";
    foreach my $sldNode (@sldNodes) {
        $comment .= '  ' . $sldNode->textContent() . "\n";
    }
}

print STDERR $comment;

# Checkout the latest revision of the Solr Catalog Add document from CVS
my $cvsDir;
if ($commit) {
    chdir $tempDir or die "Could not chdir to $tempDir\n"; 
    my $checkoutOutput = `cvs checkout $cvsPath`;
    if ($?) {
        my $message = "Failed to cvs checkout $cvsPath\n";
        exit_with_error($message);
    }
    $cvsDir = File::Spec->catdir( $tempDir, dirname($cvsPath) );
    chdir $cvsDir or die "Could not chdir to $cvsDir\n";
}

# Update entry for the data field in the Solr Catalog Add document
my $output = `$updateAddDocExe --published $dataFieldId $pubBaseline 2<&1`;
my $status = $?;
if ($status) {
    my $message = "Error executing `$updateAddDocExe`\n$output\n";
    exit_with_error($message);
}

my $updatedAddDocDom;
my $updatedAddDocDoc;
my $dataProductDataSetId;
my @sldUrls;
eval { $updatedAddDocDom = $parser->parse_file( $addDocFile ); };
if ($@) {
    exit_with_error("Could not parse $addDocFile\n");
}

# Replace Solr Catalog Add document obtained from CVS with the updated
# version and commit the change.
if ($commit) {
    copy($addDocFile, $cvsDir) or die "Failed to copy $addDocFile to $cvsDir\n";

    # Commit the change
    my $filename = basename($addDocFile);
    my $logMessage = "Updated $dataFieldId in baseline $pubBaseline";
    my $commitOutput = `cvs commit -m "$logMessage" $filename`;
    if ($?) {
        my $message = "Failed to commit changes of $filename to CVS in $cvsDir\n";
        exit_with_error($message);
    }
}

# Check updated Solr add doc
$updatedAddDocDoc = $updatedAddDocDom->documentElement();
($idNode) = $updatedAddDocDoc->findnodes( qq(/update/add/doc/field[\@name='dataFieldId' and text()='$dataFieldId']) );
if ($idNode) {
    my $docNode = $idNode->parentNode;
    if ($docNode) {
        my ($node) = $docNode->findnodes( qq(./field[\@name='dataProductDataSetId']) );
        if ($node) {
            $dataProductDataSetId = $node->textContent();
        }
        ($node) = $docNode->findnodes( qq(./field[\@name='dataFieldSldUrl']) );
        if ($node) {
            my $sldString = $node->textContent();
            my $sldDom;
            eval { $sldDom = $parser->parse_string($sldString); };
            if ($@) {
                exit_with_error("Could not parse $sldString in $addDocFile\n");
            }
            my $sldDoc = $sldDom->documentElement();
            my @sldNodes = $sldDoc->findnodes('/slds/sld');
            foreach my $sldNode (@sldNodes) {
                push @sldUrls, $sldNode->getAttribute('url');
            }
        }
    }
}
my $comment2;
$comment2 .= "dataSet Id in SSW: $dataProductDataSetId\n"
    if $dataProductDataSetId;
if (@sldUrls) {
    $comment2 .= "SLD URLs:\n";
    foreach my $sldUrl (@sldUrls) {
        $comment2 .= "  $sldUrl\n";
    }
}
print STDERR $comment2 if $comment2;

# Update Solr with the contents of the Solr Catalog Add document
#$output = `$postSolrExe --baseline $pubBaseline $addDocFile 2<&1`;
my $postBaseline = $pubBaseline;
my $command = "$postSolrExe --baseline $postBaseline";
## Temporarily post OPS catalog to Beta AESIR and vice versa
#my $tempPostBaseline = ($pubBaseline eq 'Beta') ? "OPS" : 'Beta';
#my $command = "$postSolrExe --baseline $tempPostBaseline";

$command .= " --toggleField $dataFieldId" if $toggle;
$command .= " $addDocFile 2<&1";
$output = `$command`;
$status = $?;
if ($status) {
    my $message = "Error executing `$postSolrExe`\n$output\n";
    exit_with_error($message);
}

# Update publication date if publication was successful
my ($dataFieldLastPublishedNode) = $dataFieldDoc->findnodes('/dataField/dataFieldLastPublished/value');
if ($dataFieldLastPublishedNode) {
    my $nowEpoch = DateTime->from_epoch(epoch => scalar(gettimeofday));
    my $now = $nowEpoch->iso8601 . '.' . $nowEpoch->millisecond . 'Z';
    $dataFieldLastPublishedNode->removeChildNodes();
    $dataFieldLastPublishedNode->appendText($now);
}

unless (open(PUBLISHED, "> $publishedFile")) {
    my $message = "Could not open $publishedFile for updating: $!";
    exit_with_error($message);
}
print STDERR "Waiting for exclusive lock of $publishedFile\n";
flock(PUBLISHED, 2);
print STDERR "Obtained exclusive lock of $publishedFile\n";
print PUBLISHED $dataFieldDom->toString(1);
close(PUBLISHED);
chmod 0666, $publishedFile;

print STDERR "\nSuccessfully published $dataFieldId to $pubBaseline\n";
chdir;
if ($postBaseline eq 'OPS') {
    # If promoting to OPS, update the count of active variables

#    my $countFile = '/tools/gdaac/TS1/www/giovanni/active_variable_count_OPS.txt';
    my $countFile = '/tools/gdaac/TS2/www/giovanni/active_variable_count_OPS.txt';
    my $oldCount;
    if (-f $countFile) {
        open(COUNT, "< $countFile") || die "Could not open $countFile for reading\n";
        $oldCount = <COUNT>;
        close(COUNT);
        chomp $oldCount;
        my $command = "$postSolrExe --baseline $postBaseline --activeCount";
#        my $command = "$postSolrExe --baseline $tempPostBaseline --activeCount";
        my $newCount = `$command`;
        chomp $newCount;
        if ($newCount && ($newCount ne $oldCount)) {
            open(COUNT, "> $countFile") || die "Could not open $countFile for writing\n";
            print COUNT "$newCount\n";
            close(COUNT);
            print STDERR "Updated $pubBaseline count from $oldCount to $newCount\n";
        }
    }
}

sub exit_with_error {
    my ($message) = @_;

    chdir;
    die "$message\n";
    exit;
}

sub project_path {
    my ($baseline, $doc) = @_;

    my $projPath = 'AESIR/catalog/';
    $projPath .= ($baseline eq 'Beta') ? 'OPS_beta' : $baseline;
    $projPath .= '/' . basename($doc);
    return $projPath;
}
