#!/usr/bin/perl
################################################################################
# $Id: updateDataProductEndDateTime.pl,v 1.11 2015/12/08 03:12:44 eseiler Exp $
# -@@@ EDDA Version: $Name:  $
################################################################################
#
# Script for updating the values of dataProductEndDateTime in a Solr add
# document with values determined by a granule search
#

=head1 NAME

updateDataProductEndDateTime.pl - Update the dataProductEndDateTime values in a Solr add document

=head1 PROJECT

AESIR EDDA

=head1 SYNOPSIS

updateDataProductEndDateTime.pl [--datafieldids dataFieldId1,dataFieldId2,...] [--timeinterval interval] [--enddatefile end_date_file] solrAddDocFile

=head1 DESCRIPTION

This script updates the dataProductEndDateTime values in a Solr add document
by performing a search for the latest granule in each product, comparing
the most recent granule in the search results to the latest date seen in the
previous run, and updating the dataProductEndDateTime if the search result
is later.

=head1 OPTIONS

=over 4

=item dataFieldIds

Comma-separated list of dataFieldId values. If specified,
dataProductEndDateTime values will only be checked/updated for
those dataFieldId values.

=item timeInterval

A dataProductTimeInterval value. If specified,
dataProductEndDateTime values will only be checked/updated for
variables with that dataProductTimeInterval value.

=item endDateFile

Pathname of a file that contains a dataFieldId and a date (yyyy-mm-dd)
on each line, separated by whitespace. If specified, then for each
dataFieldId in the file, the dataProductEndDateTime will be set to
that date instead of performing a search.

=back

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=cut

my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    if (defined $rootPath) {
#        unshift( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) );
        # Expect giovanni4 library for ESIP::OSDD to be installed here
        push( @INC, '/opt/giovanni4/share/perl5' );
    }
}

use strict;
use XML::LibXML;
use DateTime;
#use Time::HiRes;
use Date::Parse;
use LWP::Simple;
use LWP::UserAgent;
use ESIP::OSDD;
use URI::Escape;
use Getopt::Long;
use POSIX;
use Safe;

# Get options
my $help;
my $DEBUG;
my $dataFieldIds;
my $timeInterval;
my $endDateFile;
Getopt::Long::GetOptions( 'help'           => \$help,
                          'debug=i'        => \$DEBUG,
                          'datafieldids=s' => \$dataFieldIds,
                          'timeinterval=s' => \$timeInterval,
                          'enddatefile=s'  => \$endDateFile);

my $usage = "usage: $0 [--debug debugLevel] [--datafieldids dataFieldId1,dataFieldId2,...] [--timeinterval interval] [--enddatefile end_date_file] solrAddDocFile\n";

if ($help) {
    print "$usage";
    exit 0;
}

my %dataFieldIds = map {$_, 1} split /,/, $dataFieldIds if $dataFieldIds;

print "Starting $0 at ", scalar(gmtime), "\n";

my $solrAddDocFile = $ARGV[0];

unless ( defined $solrAddDocFile ) {
    print "$usage";
    exit 1;
}
die "Could not read Solr add document '$solrAddDocFile'"
    unless -r $solrAddDocFile;

#my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
#my $cpt     = Safe->new('CFG');
#unless ( $cpt->rdo($cfgFile) ) {
#    die "Could not read configuration file $cfgFile\n";
#}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

# Parse Solr add doc file
my $solrAddDom;
eval { $solrAddDom = $parser->parse_file( $solrAddDocFile ); };
if ($@) {
    die "Could not read and parse first time for $solrAddDocFile\n";
}
my $solrAddDoc = $solrAddDom->documentElement();

my %endDates;
if ($endDateFile) {
    # If an option specifies a file containing a dataFieldId and ending date
    # value on each line, read the values into a hash, using dataFieldId as the
    # key. These ending dates will be used when a variable is unavailable for
    # downloading, to change the date of coverage to a range for which the files
    # have already been downloaded (cached).
    if (-f $endDateFile) {
        if (open(IN, "< $endDateFile")) {
            while (<IN>) {
                chomp;
                # Expect two values separated by whitespace
                my ($id, $date) = split /\s+/;
                unless ($id && $date) {
                    print STDERR "Unexpected line in $endDateFile: $_\n";
                    next;
                }
                $date .= 'T23:59:59Z' if ($date !~ /T23:59:59Z$/);
                my $dtObject = getDtObj($date);
                if ($dtObject) {
                    $endDates{$id} = $dtObject;
                } else {
                    print STDERR "'$date' is not a valid date/time value for $id\n";
                    next;
                }
            }
            close (IN);
        }
    } else {
        print STDERR "Could not find file $endDateFile\n";
    }
}

#my $now = DateTime->now->iso8601 . 'Z';

my %productDatesFound;
my %laterProductDates;
my %latestFieldDates;
my %laterEndingDates;
my $updatedCatalog;
my %checked;

# If we are still searching via SSW, then read and parse the SSW catalog
# so that we can determine the dataProductOsddUrl to use when searching
# for granules.
my $ua = new LWP::UserAgent;
my $sswCatalogUrl;
my $sswCatalogDoc;
if ($solrAddDocFile =~ /OPS/) {
    $sswCatalogUrl = 'https://giovanni.gsfc.nasa.gov/daac-bin/SSW/SSW?action=CONFIGURATION;output_type=xml';
} elsif ($solrAddDocFile =~ /Beta/) {
    $sswCatalogUrl = 'https://disc-beta.gsfc.nasa.gov/daac-bin/SSW/SSW?action=CONFIGURATION;output_type=xml';
}
if ($sswCatalogUrl) {
    my $response = $ua->get($sswCatalogUrl);
    if ($response->is_success) {
        my $sswCatalogDom;
        eval { $sswCatalogDom = $parser->parse_string( $response->content ); };
        if ($@) {
            print STDERR "Could not parse output from $sswCatalogUrl\n";
        } else {
            $sswCatalogDoc = $sswCatalogDom->documentElement();
        }
    } else {
        print STDERR "Could not retrieve $sswCatalogUrl\n";
    }
}

# Examine each doc node
#
# If a list of (comma-separated) dataFieldId values has been specified,
# then consider only those variables/nodes.
#
# Skip if data field is not active
#
# Skip if the data product end date time is locked
#
# Extract current data product start and end date/time
#
# If a data product has an OPeNDAP URL, check if the OPeNDAP server is
# available, and if not, try to set the ending date to a value
# specified in a file for that variable.
#
# If product has an end date/time, and has not already been checked,
# perform a granule search, starting from that end date/time
#
# If the latest granule has an end date/time later than the existing
# date/time for the product, then update the end date/time for the product.

foreach my $docNode ( $solrAddDoc->findnodes('/update/add/doc') ) {

    # Expect every Solr doc to have a dataFieldId. If for some reason one does
    # not, skip it.
    my ($dataFieldIdNode) = $docNode->findnodes(qq(./field[\@name='dataFieldId']));
    my $dataFieldId = $dataFieldIdNode->textContent
        if $dataFieldIdNode;
    unless ($dataFieldId) {
        print STDERR "No value found for dataFieldId \n";
        next;
    }

    if (%dataFieldIds) {
        next unless exists $dataFieldIds{$dataFieldId};
    }

    # Check dataFieldActive, and skip doc if its value is not true.
    my ($dataFieldActiveNode) = $docNode->findnodes(qq(./field[\@name='dataFieldActive']));
    my $dataFieldActive = $dataFieldActiveNode->textContent
        if $dataFieldActiveNode;
    unless ($dataFieldActive && $dataFieldActive eq 'true') {
        print STDERR "Skipping $dataFieldId because it is not active \n"
            if ($DEBUG > 1);
        next;
    }

    # Check dataProductEndDateTimeLocked, and skip doc if its value is true.
    my ($dataProductEndDateTimeLockedNode) = $docNode->findnodes(qq(./field[\@name='dataProductEndDateTimeLocked']));
    my $dataProductEndDateTimeLocked = $dataProductEndDateTimeLockedNode->textContent
        if $dataProductEndDateTimeLockedNode;
    if ($dataProductEndDateTimeLocked &&
            $dataProductEndDateTimeLocked eq 'true') {
        print STDERR "Skipping $dataFieldId because dataProductEndDateTime is locked\n"
            if ($DEBUG > 1);
        next;
    }

    # Hard-coded workaround to skip updating the ending date/time for
    # MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean
    # since it is different than the other data fields for that data product
    if ($dataFieldId eq 'MOD08_D3_051_Deep_Blue_Aerosol_Optical_Depth_550_Land_QA_Mean') {
        print STDERR "Skipping $dataFieldId because it has a locked end date/time\n"
            if ($DEBUG > 1);
        next;
    }

    # Expect every Solr doc to have a dataProductId. If for some reason one
    # does not, skip it.
    my ($dataProductIdNode) = $docNode->findnodes(qq(./field[\@name='dataProductId']));
    my $dataProductId = $dataProductIdNode->textContent
        if $dataProductIdNode;
    unless ($dataProductId) {
        print STDERR "No value found for dataProductId for dataFieldId $dataFieldId\n";
        next;
    }

    my ($dataProductBeginDateTimeNode) = $docNode->findnodes(qq(./field[\@name='dataProductBeginDateTime']));
    my ($dataProductEndDateTimeNode) = $docNode->findnodes(qq(./field[\@name='dataProductEndDateTime']));

    my ($dataProductOsddUrlNode) = $docNode->findnodes(qq(./field[\@name='dataProductOsddUrl']));
    my $dataProductOsddUrl = $dataProductOsddUrlNode->textContent
        if $dataProductOsddUrlNode;

    my ($dataProductSampleGranuleUrlNode) = $docNode->findnodes(qq(./field[\@name='dataProductSampleGranuleUrl']));
    my $dataProductSampleGranuleUrl = $dataProductSampleGranuleUrlNode->textContent
        if $dataProductSampleGranuleUrlNode;

    my ($dataProductOpendapUrlNode) = $docNode->findnodes(qq(./field[\@name='dataProductOpendapUrl']));
    my $dataProductOpendapUrl = $dataProductOpendapUrlNode->textContent
        if $dataProductOpendapUrlNode;

    my ($dataProductTimeIntervalNode) = $docNode->findnodes(qq(./field[\@name='dataProductTimeInterval']));
    my $dataProductTimeInterval = $dataProductTimeIntervalNode->textContent
        if $dataProductTimeIntervalNode;
    print STDERR "No dataProductTimeInterval for $dataFieldId\n" unless $dataProductTimeInterval;
    if ($timeInterval && ($timeInterval ne $dataProductTimeInterval)) {
        next;
    }

    # Try to retrieve the data product OPeNDAP URL if it has a value
    my $ua = new LWP::UserAgent;
    if ($dataProductOpendapUrl) {
        if (!$checked{$dataProductOpendapUrl}) {
            my $response = $ua->get($dataProductOpendapUrl);
            if ($response->is_success) {
                $checked{$dataProductOpendapUrl} = 1;
            } else {
                $checked{$dataProductOpendapUrl} = 2;
                print STDERR "Failed getting $dataProductOpendapUrl for $dataProductId: ", $response->status_line, " \n";
            }
        }
        # if ($checked{$dataProductOpendapUrl} == 2) {
        #     # If the OPeNDAP URL failed to be retrieved, set the ending date for that
        #     # variable to the end date for that variable found in a file specified by
        #     # the enddatefile option
        #     if (exists $endDates{$dataFieldId}) {
        #         my $latestEndDateStr = $endDates{$dataFieldId}->iso8601 . 'Z';
        #         $latestFieldDates{$dataFieldId} = $latestEndDateStr;
        #     } else {
        #         # If no file was provided or the dataFieldId was not found in
        #         # the file, proceed as usual.
        #         print STDERR "No most recent date specified for $dataFieldId, will search instead\n";
        #     }
        # }
    }

    # Old strategy used dates from $endDateFile only if we are unable to
    # download $dataProductOpendapUrl, i.e. the OPeNDAP server is not available.
    # If the server is available, it ignores the dates in $endDateFile.
    # The new strategy always uses the dates in $endDateFile.
    if (exists $endDates{$dataFieldId}) {
        my $latestEndDateStr = $endDates{$dataFieldId}->iso8601 . 'Z';
        $latestFieldDates{$dataFieldId} = $latestEndDateStr;
    }

    if (exists $latestFieldDates{$dataFieldId}) {
        print STDERR "Setting end date for $dataFieldId to $latestFieldDates{$dataFieldId}\n";
        $laterEndingDates{$dataFieldId} = $latestFieldDates{$dataFieldId};
        $updatedCatalog = 1;
    } elsif (exists $laterProductDates{$dataProductId}) {
        # We already found a later product end date for this product,
        # so replace the value for this data field
#        print "$dataProductId:\n  Updating dataProductEndDateTime for $dataFieldId with $laterProductDates{$dataProductId}\n"
#            if ($DEBUG > 1);
#        updateEndDateTime($dataProductBeginDateTimeNode,
#                          $dataProductEndDateTimeNode,
#                          $laterProductDates{$dataProductId});
        $laterEndingDates{$dataFieldId} = $laterProductDates{$dataProductId};
        $updatedCatalog = 1;
    } elsif (! exists $productDatesFound{$dataProductId}) {
        # Perform a search to find the latest end date/time for this
        # product.

        my ($dataProductDataCenterNode) = $docNode->findnodes(qq(./field[\@name='dataProductDataCenter']));
        my $dataProductDataCenter = $dataProductDataCenterNode->textContent
            if $dataProductDataCenterNode;
        unless ($dataProductDataCenter) {
            print STDERR "No value found for dataProductDataCenter \n";
            next;
        }
        if ($dataProductDataCenter =~ /GESDISC/) {
            $dataProductDataCenter = 'GES_DISC';
        } elsif ($dataProductDataCenter =~ /LAADS/) {
            $dataProductDataCenter = 'LAADS';
        } elsif ($dataProductDataCenter =~ /LARC_ASDC/) {
            $dataProductDataCenter = 'LARC_ASDC';
        } elsif ($dataProductDataCenter =~ /LARC/) {
            $dataProductDataCenter = 'LARC';
        } elsif ($dataProductDataCenter =~ /OB\.DAAC/) {
            $dataProductDataCenter = 'OB_DAAC';
        } elsif ($dataProductDataCenter =~ /OBPG/) {
            $dataProductDataCenter = 'OB_DAAC';
        } elsif ($dataProductDataCenter =~ /LPDAAC_ECS/) {
            $dataProductDataCenter = 'LPDAAC_ECS';
        } elsif ($dataProductDataCenter =~ /LP ?DAAC/) {
            $dataProductDataCenter = 'LP_DAAC';
        } elsif ($dataProductDataCenter =~ /PODAAC/) {
            $dataProductDataCenter = 'PODAAC';
        } elsif ($dataProductDataCenter =~ /ASF/) {
            $dataProductDataCenter = 'ASF';
        } elsif ($dataProductDataCenter =~ /AU_AADC/) {
            $dataProductDataCenter = 'AU_AADC';
        } elsif ($dataProductDataCenter =~ /CDDIS/) {
            $dataProductDataCenter = 'CDDIS';
        } elsif ($dataProductDataCenter =~ /ESA/) {
            $dataProductDataCenter = 'ESA';
        } elsif ($dataProductDataCenter =~ /EUMETSAT/) {
            $dataProductDataCenter = 'EUMETSAT';
        } elsif ($dataProductDataCenter =~ /GHRC/) {
            $dataProductDataCenter = 'GHRC';
        } elsif ($dataProductDataCenter =~ /ISRO/) {
            $dataProductDataCenter = 'ISRO';
        } elsif ($dataProductDataCenter =~ /JAXA/) {
            $dataProductDataCenter = 'JAXA';
        } elsif ($dataProductDataCenter =~ /LANCEMODIS/) {
            $dataProductDataCenter = 'LANCEMODIS';
        } elsif ($dataProductDataCenter =~ /NOAA_NCEI/) {
            $dataProductDataCenter = 'NOAA_NCEI';
        }

        my ($dataProductShortNameNode) = $docNode->findnodes(qq(./field[\@name='dataProductShortName']));
        my $dataProductShortName = $dataProductShortNameNode->textContent
            if $dataProductShortNameNode;
        unless ($dataProductShortName) {
            print STDERR "No value found for dataProductShortName \n";
            next;
        }

        my ($dataProductVersionNode) = $docNode->findnodes(qq(./field[\@name='dataProductVersion']));
        my $dataProductVersion = $dataProductVersionNode->textContent
            if $dataProductVersionNode;
        unless ($dataProductVersion) {
            print STDERR "No value found for dataProductVersion \n";
            next;
        }

#        my ($dataProductGcmdEntryIdNode) = $docNode->findnodes(qq(./field[\@name='dataProductGcmdEntryId']));
#        my $dataProductGcmdEntryId = $dataProductGcmdEntryIdNode->textContent
#            if $dataProductGcmdEntryIdNode;
#        unless ($dataProductGcmdEntryId) {
#            print STDERR "No value found for dataProductGcmdEntryId \n";
#            next;
#        }

        my $dataProductBeginDateTime = $dataProductBeginDateTimeNode->textContent
            if $dataProductBeginDateTimeNode;
        unless ($dataProductBeginDateTime) {
            print STDERR "No value found for dataProductBeginDateTime \n";
            next;
        }
        my $dataProductEndDateTime = $dataProductEndDateTimeNode->textContent
            if $dataProductEndDateTimeNode;


#        my ($dataProductOsddUrlNode) = $docNode->findnodes(qq(./field[\@name='dataProductOsddUrl']));
#        my $dataProductOsddUrl = $dataProductOsddUrlNode->textContent
#            if $dataProductOsddUrlNode;

        my ($dataProductTimeFrequencyNode) = $docNode->findnodes(qq(./field[\@name='dataProductTimeFrequency']));
        my $dataProductTimeFrequency = $dataProductTimeFrequencyNode->textContent
            if $dataProductTimeFrequencyNode;

        my ($dataFieldSearchFilterNode) = $docNode->findnodes(qq(./field[\@name='dataFieldSearchFilter']));
        my $dataFieldSearchFilter = $dataFieldSearchFilterNode->textContent
            if $dataFieldSearchFilterNode;

	# Just in case the granule searches for the data set use SSW, extract
	# the dataset_id attribute from the sswBaseSubsetUrl string so that
	# we can use it to find the dataProductOsddUrl in the SSW configuration
	# if we don't have it in the Solr add doc
        my $sswDatasetId;
        my ($sswBaseSubsetUrlNode) = $docNode->findnodes(qq(./field[\@name='sswBaseSubsetUrl']));
        my $sswBaseSubsetUrl = $sswBaseSubsetUrlNode->textContent
            if $sswBaseSubsetUrlNode;
        if ($sswBaseSubsetUrl) {
            $sswDatasetId = $1 if ($sswBaseSubsetUrl =~ /dataset_id=(.+?);/);
            $sswDatasetId = uri_unescape($sswDatasetId ) if $sswDatasetId ;
        }

        my $latestEndDateDtObj =  findLatestEndDateTime($dataProductId,
                                                        $dataProductDataCenter,
                                                        $dataProductShortName,
                                                        $dataProductVersion,
                                                        $dataProductBeginDateTime,
                                                        $dataProductEndDateTime,
                                                        $dataProductOsddUrl,
                                                        $dataProductTimeInterval,
                                                        $dataProductTimeFrequency,
                                                        $dataFieldSearchFilter,
                                                        $sswCatalogDoc,
                                                        $sswDatasetId,
                                                       );


        if ($latestEndDateDtObj) {
            # Indicate that we shouldn't search again for the latest date
            # for this product
            $productDatesFound{$dataProductId} = 1;

            # Compare the end date of the latest granule with the existing
            # end date for the product. If it is later, update
            my $dataProductEndDateTimeDtObj;
            my $fraction;
            if ($dataProductEndDateTime) {
                # DateTime does not allow fractional seconds
                my $endDateTime = $dataProductEndDateTime;
                $fraction = $1 if $endDateTime =~ m/(\.\d+)Z$/;
                $endDateTime =~ s/\.\d+Z$/Z/;
                $dataProductEndDateTimeDtObj = getDtObj($endDateTime);
            }
            # We don't want to use ending dates with a time of 00:00:00,
            # so if we find one, subtract 1 millisecond
            if ($latestEndDateDtObj->hms eq '00:00:00') {
                $latestEndDateDtObj->subtract(nanoseconds => 1000000);
            }
            if ( (! defined $dataProductEndDateTimeDtObj) ||
                 ( DateTime->compare( $latestEndDateDtObj, $dataProductEndDateTimeDtObj ) ) >= 0 ) {
                if ( (! defined $dataProductEndDateTimeDtObj) ||
                     ( DateTime->compare( $latestEndDateDtObj, $dataProductEndDateTimeDtObj ) != 0 ) ||
                     (! defined $fraction) ) {
#                        print "dataProductId: $dataProductId\n  dataProductBeginDateTime: $dataProductBeginDateTime\n  dataProductEndDateTime: $dataProductEndDateTime\n  latestEndDate: ", $latestEndDateDtObj->iso8601 . 'Z', "\n";
                    my $latestEndDateStr = $latestEndDateDtObj->iso8601 .
                        ($latestEndDateDtObj->millisecond ? '.' . $latestEndDateDtObj->millisecond : '') . 'Z';

                    # Save the later date for the product
                    $laterProductDates{$dataProductId} = $latestEndDateStr;

#                    print "$dataProductId:\n  Updating date/time from '$dataProductEndDateTime' to '$latestEndDateStr'\n";
#                    print "$dataProductId:\n  Updating dataProductEndDateTime for $dataFieldId with '$latestEndDateStr'\n"
#                        if ($DEBUG > 1);
#                    updateEndDateTime($dataProductBeginDateTimeNode,
#                                      $dataProductEndDateTimeNode,
#                                      $latestEndDateStr);
                    $laterEndingDates{$dataFieldId} =  $latestEndDateStr;
                } else {
                    my $latestEndDateStr = $latestEndDateDtObj->iso8601 .
                       ($latestEndDateDtObj->millisecond ? '.' . $latestEndDateDtObj->millisecond : '') . 'Z';
                    print "$dataProductId:\n  '$dataProductEndDateTime' not being replaced with '$latestEndDateStr'\n"
                        if ($DEBUG > 0);
                }
            }
        }
    }

}

if ($updatedCatalog) {
    open(UPDATED, "+< $solrAddDocFile");
    print STDERR "Waiting for exclusive lock of $solrAddDocFile\n";
    flock(UPDATED, 2);
    print STDERR "Obtained exclusive lock of $solrAddDocFile\n";

    # Solr add doc file may have been updated since we last parsed,
    # since we didn't lock it, so parse it again after locking
    eval { $solrAddDom = $parser->parse_file( $solrAddDocFile ); };
    if ($@) {
        die "Could not read and parse second time for $solrAddDocFile\n";
    }
    $solrAddDoc = $solrAddDom->documentElement();

    foreach my $docNode ( $solrAddDoc->findnodes('/update/add/doc') ) {

        # Expect every Solr doc to have a dataFieldId. If for some reason one
        # does not, skip it.
        my ($dataFieldIdNode) = $docNode->findnodes(qq(./field[\@name='dataFieldId']));
        my $dataFieldId = $dataFieldIdNode->textContent
            if $dataFieldIdNode;
        unless ($dataFieldId) {
            print STDERR "No value found for dataFieldId \n";
            next;
        }
        if (exists $laterEndingDates{$dataFieldId}) {
            # Expect every Solr doc to have a dataProductId. If for some reason
            # one does not, skip it.
            my ($dataProductIdNode) = $docNode->findnodes(qq(./field[\@name='dataProductId']));
            my $dataProductId = $dataProductIdNode->textContent
                if $dataProductIdNode;
            unless ($dataProductId) {
                print STDERR "No value found for dataProductId for dataFieldId $dataFieldId\n";
                next;
            }
            my ($dataProductBeginDateTimeNode) = $docNode->findnodes(qq(./field[\@name='dataProductBeginDateTime']));
            my ($dataProductEndDateTimeNode) = $docNode->findnodes(qq(./field[\@name='dataProductEndDateTime']));
            print "$dataProductId:\n  Updating dataProductEndDateTime for $dataFieldId with $laterEndingDates{$dataFieldId}\n"
                if ($DEBUG > 1);
            updateEndDateTime($dataProductBeginDateTimeNode,
                              $dataProductEndDateTimeNode,
                              $laterEndingDates{$dataFieldId});
        }
    }

    seek(UPDATED, 0, 0);
    print UPDATED $solrAddDom->toString(1);
    truncate(UPDATED, tell(UPDATED));
    close(UPDATED);
}

print "Finished $0 at ", scalar(gmtime), "\n";

exit 0;


sub findLatestEndDateTime {
    my ($dataProductId, $dataProductDataCenter, $dataProductShortName,
        $dataProductVersion, $dataProductBeginDateTime,
        $dataProductEndDateTime, $dataProductOsddUrl,
        $dataProductTimeInterval, $dataProductTimeFrequency,
        $dataFieldSearchFilter, $sswCatalogDoc, $sswDatasetId) = @_;

    # Perform an OpenSearch for granules between a recent past date and
    # the latest possible date, and find the latest end date in
    # the results. If no granules were found, make the start date of the
    # search range earlier, and repeat the search until either granules
    # are found or the entire date range of the data set has been searched.

    my $granuleOsdd;
    if ($dataProductOsddUrl) {
        $granuleOsdd = LWP::Simple::get($dataProductOsddUrl);
    } elsif ($sswCatalogDoc) {
        # Try to find $dataProductOsddUrl in SSW catalog document for the data set
        # matching $sswDatasetId
        my ($datasetNode) = $sswCatalogDoc->findnodes( qq(/DataSets/DataSet[\@id='$sswDatasetId']) );
        if ($datasetNode) {
            $dataProductOsddUrl = $datasetNode->getAttribute('granuleOsddUrl');
            $granuleOsdd = LWP::Simple::get($dataProductOsddUrl) if $dataProductOsddUrl;
        }
    }
    unless (defined $granuleOsdd) {
        # If we weren't provided with the dataProductOsddUrl, default to searching CMR
        $dataProductOsddUrl = getGranuleOsddUrl('cmr',
                                                $dataProductDataCenter,
                                                $dataProductShortName,
                                                $dataProductVersion);
        unless ($dataProductOsddUrl) {
            print STDERR "Could not determine CMR OSDD URL for shortname '$dataProductShortName' version '$dataProductVersion' \n";
            return;
        }
        $granuleOsdd = LWP::Simple::get($dataProductOsddUrl);
    }
    unless (defined $granuleOsdd) {
        print STDERR "Could not retrieve OSDD for shortname '$dataProductShortName' version '$dataProductVersion' \n";
        return;
    }

    my $osdd;
    eval { $osdd = ESIP::OSDD->new(osddUrl => $dataProductOsddUrl); };
    if ($@) {
        print STDERR "Error creating OpenSearch engine\n";
        return;
    }

    my $now = DateTime->now->iso8601 . 'Z';
    my $dtNow = getDtObj($now);
    my $dtDataProductEndDateTime;
    my $dtSearchStartTime;
    my $dtSearchEndTime;
    my $deltaDate;
    my $deltaDateUnits;
    if ($dataProductTimeInterval eq 'half-hourly') {
        $deltaDate = 24;
        $deltaDateUnits = 'hours';
    } elsif ($dataProductTimeInterval eq 'hourly') {
        $deltaDate = 48;
        $deltaDateUnits = 'hours';
    } elsif ($dataProductTimeInterval eq '3-hourly') {
        $deltaDate = 2;
        $deltaDateUnits = 'days';
    } elsif ($dataProductTimeInterval eq 'daily') {
        $deltaDate = 7;
        $deltaDateUnits = 'days';
    } elsif ($dataProductTimeInterval eq 'weekly') {
        $deltaDate = 2;
        $deltaDateUnits = 'months';
    } elsif ($dataProductTimeInterval eq '8-daily') {
        $deltaDate = 2;
        $deltaDateUnits = 'months';
    } elsif ($dataProductTimeInterval eq 'monthly') {
        $deltaDate = 6;
        $deltaDateUnits = 'months';
    }
    $deltaDate = ceil($deltaDate / $dataProductTimeFrequency);
    if ($dataProductEndDateTime) {
        # Search between the existing product end date and the current date
        $dataProductEndDateTime =~ s/\.\d+Z$/Z/;
        $dtDataProductEndDateTime = getDtObj($dataProductEndDateTime);
        $dtSearchStartTime = $dtDataProductEndDateTime->clone;
    } else {
        # Search between deltaDate before the current date and the current date
        $dtSearchStartTime = $dtNow->clone;
        $dtSearchStartTime->subtract($deltaDateUnits => $deltaDate);
    }
    $dtSearchEndTime = $dtNow->clone;

    $dataProductBeginDateTime =~ s/\.\d+Z$/Z/;
    my $dtDataProductBeginDateTime = getDtObj($dataProductBeginDateTime);
#    my $endTime = '2038-01-01T00:00:00Z';

#    my $maxPage = 4096;
    my $maxPage = 1024;  # CMR cannot seem to handle a count greater than 1024
    my $geoBox = '-180.0,-90.0,180.0,90.0';
    my %params = (
                  'os:count'   => $maxPage,
#                  'geo:box'    => $geoBox,
#                  'georss:box' => $geoBox,
                  'time:end'   => $dtNow->iso8601 . 'Z'
                 );

    my $latestFound;
    my $response;
    my $keyword = 'x';
    while (! $latestFound) {
        $params{'time:start'} = $dtSearchStartTime->iso8601 . 'Z';
        $params{'time:end'}   = $dtSearchEndTime->iso8601 . 'Z';
        print STDERR "Searching $dataProductId from $params{'time:start'} to $params{'time:end'}\n" if ($DEBUG > 0);
        eval { $response = $osdd->performGranuleSearch( 0, %params ); };
        if ($@) {
            print STDERR "OpenSearch error $@\n";
            return;
        }

        unless ( $response->{success} ) {
#            if ( $response->content =~ /timeout/ ) {
#                print STDERR "OPENSEARCH_TIMEOUT ", $response->content;
                print STDERR $response->{message};
                return;
#            }
#            else {
#                if ( $response->is_error ) {
#                    print STDERR "OPENSEARCH_ERROR ", $response->content;
#                }
#                else {
#                    print STDERR "OPENSEARCH_UNAVAILABLE ", $response->content;
#                }
#            }
        }

        # Parse the response (granule search results) from the OpenSearch server
        my $dom;
#        eval { $dom = $parser->parse_string( $response->content ); };
#        if ($@) {
#            print STDERR "OpenSearch results parsing error $@\n";
#        }
        $dom = $response->{response}->{raw}->[0]
            if exists($response->{response}->{raw});
        my $doc = $dom->documentElement();

        # Get the latest end date for a granule
        my ($nFound, $latestEndDate) = extractDatesFromDoc($doc, $dataFieldSearchFilter);
        if ($nFound > $maxPage) {
            # If more than a page of granules were found, make the interval narrower
            print STDERR "Search interval of $deltaDate too wide\n";
            $deltaDate = ceil($deltaDate / 2);
            if ($deltaDate == 1) {
                print STDERR "Search interval too narrow \n";
                return;
            }
            $dtSearchStartTime->add($deltaDateUnits => $deltaDate);
        } elsif ($nFound == 0) {
            # If no granules were found, make the search interval wider and
            # earlier, if possible
            $dtSearchEndTime = $dtSearchStartTime->clone;
            $dtSearchStartTime->subtract($deltaDateUnits => $deltaDate);
            if ( ( DateTime->compare( $dtSearchEndTime, $dtDataProductBeginDateTime ) ) < 0 ) {
                # Don't search any earlier than the beginning of the date
                # coverage
                $latestFound = 1;

                # Indicate that we shouldn't search again for the earliest date
                # for this product
                $productDatesFound{$dataProductId} = 1;
            }
            $deltaDate *= 2;
        } else {
            # If up to a page of granules were found, return the latest date
            return $latestEndDate;
        }
    }

}


sub getGranuleOsddUrl {
    my ($OSsource, $dataCenter, $shortName, $versionId) = @_;

    if ($OSsource eq 'cmr') {
        # Construct CMR granule OSDD URL.
        # TO DO: This shortcut will always produce a URL for a CMR granule
        # OSDD, even if the data set is not in CMR. The proper way
        # is to do a CMR data set OpenSearch (perhaps using the shortName
        # as the keyword) and get the OSDD URL from a result with a matching
        # data set id.
        my $cmrGranuleOsddUrlTemplate = "https://cmr.earthdata.nasa.gov/opensearch/granules/descriptor_document.xml?dataCenter=<DATACENTER>&shortName=<SHORTNAME>&versionId=<VERSIONID>&clientId=giovanni";
        $versionId = '5.1' if ($versionId eq '051');
        my $cmrGranuleOsddUrl = $cmrGranuleOsddUrlTemplate;
        $cmrGranuleOsddUrl =~ s/<DATACENTER>/$dataCenter/;
        $cmrGranuleOsddUrl =~ s/<SHORTNAME>/$shortName/;
        $cmrGranuleOsddUrl =~ s/<VERSIONID>/$versionId/;

        return $cmrGranuleOsddUrl;
    } else {
        # Unknown OpenSearch server provider
        return;
    }
}


sub extractDatesFromDoc {
    my ($doc, $dataFieldSearchFilter) = @_;

    return unless $doc;

    $CFG::atomNS = 'http://www.w3.org/2005/Atom';
#    $CFG::osNS   = 'http://a9.com/-/spec/opensearch/1.1/';
#    $CFG::esipNS = 'http://esipfed.org/ns/fedsearch/1.0/';
#    $CFG::esipdiscoveryNS = 'http://commons.esipfed.org/ns/discovery/1.2/';
    $CFG::dc     = 'http://purl.org/dc/terms/';
    $CFG::time   = 'http://a9.com/-/opensearch/extensions/time/1.0/';

    # Get first entry
    my (@entries) =  $doc->getChildrenByTagNameNS( $CFG::atomNS, 'entry' );
    return 0 unless @entries;

    my $firstEntry;
    my $lastEntry;
    if ($dataFieldSearchFilter) {
        # Find first entry whose file name matches the filter
        FIRSTENTRY: foreach my $entry (@entries) {
            my @links = $entry->getChildrenByTagName('link');

            # Assume the filter is specific enough to match only one
            # href for the many types of links in an entry element, and
            # thus look for a match against any link element.
            foreach my $link (@links) {
                my $href = $link->getAttribute('href');
                if ($href) {
                    if ($href =~ /$dataFieldSearchFilter/) {
                        $firstEntry = $entry;
                        last FIRSTENTRY;
                    }
                }
            }
        }
        # Find last entry whose file name matches the filter
        LASTENTRY: foreach my $entry (reverse @entries) {
            my @links = $entry->getChildrenByTagName('link');

            # Assume the filter is specific enough to match only one
            # href for the many types of links in an entry element, and
            # thus look for a match against any link element.
            foreach my $link (@links) {
                my $href = $link->getAttribute('href');
                if ($href) {
                    if ($href =~ /$dataFieldSearchFilter/) {
                        $lastEntry = $entry;
                        last LASTENTRY;
                    }
                }
            }
        }
        return 0 unless $firstEntry;
        return 0 unless $lastEntry;
    } else {
        $firstEntry = $entries[0];
        $lastEntry  = $entries[-1];
    }

    my $endNode;
    my $dateNode;
    my $firstDt;
    my $lastDt;
    ($endNode) = $firstEntry->getChildrenByTagNameNS( $CFG::time, 'end' );
    if ($endNode) {
        my $firstEnd = $endNode->textContent();
        $firstDt = getDtObj($firstEnd);
    } else {
        ($dateNode) = $firstEntry->getChildrenByTagNameNS( $CFG::dc, 'date' );
        if ($dateNode) {
            my $date = $dateNode->textContent();
            my $firstEnd = (split('/', $date))[-1];
            $firstDt = getDtObj($firstEnd);
        } else {
            return 0;
        }
    }
    ($endNode) = $lastEntry->getChildrenByTagNameNS( $CFG::time, 'end' );
    if ($endNode) {
        my $lastEnd = $endNode->textContent();
        $lastDt = getDtObj($lastEnd);
    } else {
        ($dateNode) = $lastEntry->getChildrenByTagNameNS( $CFG::dc, 'date' );
        if ($dateNode) {
            my $date = $dateNode->textContent();
            my $lastEnd = (split('/', $date))[-1];
            $lastDt = getDtObj($lastEnd);
        } else {
            return 0;
        }
    }


    # Since we don't know if the search results are in ascending or
    # descending order, determine which date is the latest.
    my $latestDt = $lastDt;
    if (DateTime->compare($firstDt, $lastDt) > 0) {
        $latestDt = $firstDt;
    }

    return (scalar(@entries), $latestDt);
}

sub compareDates {
    my ( $date1Str, $date2Str ) = @_;

    my $date1 = getDtObj($date1Str);
    my $date2 = getDtObj($date2Str);
    return DateTime->compare( $date1, $date2 );
}

sub getDtObj {
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

sub updateEndDateTime {
    my ($dataProductBeginDateTimeNode, $dataProductEndDateTimeNode,
        $laterProductDate) = @_;

    if ($dataProductEndDateTimeNode) {
        $dataProductEndDateTimeNode->removeChildNodes();
        $dataProductEndDateTimeNode->appendText($laterProductDate);
    } else {
        my $newNode = XML::LibXML::Element->new('field');
        $newNode->setAttribute('name', 'dataProductEndDateTime');
        $newNode->appendText($laterProductDate);
        $dataProductBeginDateTimeNode->addSibling($newNode);
    }
}
