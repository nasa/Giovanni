#$Id: DataStager.pm,v 1.33 2015/08/18 16:00:55 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::DataStager;

use 5.008008;
use strict;
use warnings;
use Giovanni::Cache;
use Giovanni::DataField;
use Giovanni::Logger::InputOutput;
use Giovanni::DataStager::StagedFile;
use Giovanni::UrlDownloader;
use Giovanni::ScienceCommand;
use Giovanni::Util;
use File::Basename;
use POSIX;
use List::Util qw/min/;
use XML::LibXML;
use List::MoreUtils qw/first_index last_index/;
use DateTime;

our $VERSION = '0.01';

# Preloaded methods go here.
sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;
    _checkParams( \%params, "DIRECTORY", "LOGGER", "CHUNK_SIZE", "TIME_OUT",
        "MAX_RETRY_COUNT", "RETRY_INTERVAL", "CACHER" );

   # Filter skipping is for messages in log. The code only puts
   # message_number % FILTER_SKIP in the log. So, setting the value to 1 means
   # all messages will get through.
    if ( !defined( $self->{FILTER_SKIP} ) ) {
        $self->{FILTER_SKIP} = 1;
    }

    # Default is to delete the raw downloaded files
    if ( !defined( $self->{KEEP_RAW_FILES} ) ) {
        $self->{KEEP_RAW_FILES} = 0;
    }

    return $self;
}

sub stage {
    my ( $self, %params ) = @_;
    _checkParams( \%params, "URLS_FILE", "DATA_FIELD_INFO_FILE",
        "MANIFEST_FILENAME" );

    $self->{MANIFEST_FILENAME}    = $params{MANIFEST_FILENAME};
    $self->{DATA_FIELD_INFO_FILE} = $params{DATA_FIELD_INFO_FILE};

    # read the data field info file
    $self->{DATA_FIELD_INFO} = Giovanni::DataField->new(
        MANIFEST => $params{DATA_FIELD_INFO_FILE} );

    # read in the URLs
    my $doc = XML::LibXML->load_xml( location => $params{URLS_FILE} );
    my $id = $self->{DATA_FIELD_INFO}->get_id();
    my @nodes
        = $doc->findnodes(qq(/searchList/search[\@id="$id"]/result/\@url));
    my @urls = map( $_->nodeValue(), @nodes );
    @nodes = $doc->findnodes(
        qq(/searchList/search[\@id="$id"]/result/\@filename));
    my @filenames = map {

     # Add the id to the filename. These filenames come from the SSW. They are
     # basically granule filenames. If you have two variables from the same
     # granule for the same day, the SSW filename will be the same. By
     # appending the id, we make sure that we won't have problems downloading
     # files for different variables in parallel.
        my @list = File::Basename::fileparse( $_->nodeValue(), qr/\.[^.]*/ );
        $list[0] . ".$id" . $list[2];
    } @nodes;
    @nodes = $doc->findnodes(
        qq(/searchList/search[\@id="$id"]/result/\@starttime));
    my @starttimes = map( $_->nodeValue(), @nodes );
    @nodes = $doc->findnodes(
        qq(/searchList/search[\@id="$id"]/result/\@endtime));
    my @endtimes = map( $_->nodeValue(), @nodes );

    # figure out if this is a virtual data field
    my $isVirtual = 0;
    if (defined( $self->{DATA_FIELD_INFO}->get_virtualDataFieldGenerator() ) )
    {
        $isVirtual = 1;
    }

    # create an array of StagedFile objects, which will keep track of
    # individual files.
    my @stagedFiles = ();
    for ( my $i = 0; $i < scalar(@urls); $i++ ) {
        my $stagedFile = Giovanni::DataStager::StagedFile->new(
            URL                    => $urls[$i],
            IS_VIRTUAL             => $isVirtual,
            ID                     => $id,
            FILENAME_FROM_SEARCH   => $filenames[$i],
            START_TIME_FROM_SEARCH => $starttimes[$i],
            END_TIME_FROM_SEARCH   => $endtimes[$i],
        );
        push( @stagedFiles, $stagedFile );
    }

    # take care of the degenerate case
    if ( scalar(@stagedFiles) == 0 ) {
        $self->{LOGGER}->info("Nothing to do, no URLS!");
        $self->{LOGGER}->percent_done(100);

        # write the manifest file
        open( FILE,
            ">" . $self->{DIRECTORY} . "/" . $self->{MANIFEST_FILENAME} )
            or die $?;
        print FILE "<fileList />" or die $?;
        close(FILE) or die $?;

        return;

    }

    $self->{STAGED_FILES} = \@stagedFiles;

    # check to see what is in the cache (0-30% done)
    $self->_checkCache( 0, 30 );

    # see how many files need scrubbing
    my $numNeedScrubbing = scalar( @{ $self->{NEEDS_SCRUBBING} } );
    if ( $numNeedScrubbing > 0 ) {
        my $numChunks = ceil( $numNeedScrubbing / $self->{CHUNK_SIZE} );

        # this will get us from 30% to 90% done
        my $chunkingStartPercent = 30;
        my $chunkingEndPercent   = 99;
        my $percentEachIteration
            = ( $chunkingEndPercent - $chunkingStartPercent ) / $numChunks;
        for ( my $i = 0; $i < $numChunks; $i++ ) {
            my $startChunkIndex = $i * $self->{CHUNK_SIZE};
            my $endChunkIndex = min( ( $i + 1 ) * $self->{CHUNK_SIZE} - 1,
                $numNeedScrubbing - 1 );

            my @chunkFiles = @{ $self->{NEEDS_SCRUBBING} }
                [ $startChunkIndex .. $endChunkIndex ];

            $self->{LOGGER}->info( "Dowloading, scrubbing, and  caching "
                    . ( $i + 1 )
                    . " of $numChunks. "
                    . "Indices $startChunkIndex - $endChunkIndex." );

            $self->{LOGGER}
                ->user_msg( "Downloading, scrubbing, and caching files "
                    . ( $startChunkIndex + 1 ) . " - "
                    . ( $endChunkIndex + 1 )
                    . ". ($numNeedScrubbing files total for $id.)" );

            my $startPercent
                = $chunkingStartPercent + $i * $percentEachIteration;

            $self->_downloadScrubAndCache( $startPercent,
                $startPercent + $percentEachIteration,
                $i, $numChunks, @chunkFiles );
        }
    }

    # test to see if there were any bad URLs
    $self->_dealWithBadUrls();

    # if this is climatology, sort the order
    $self->_sortOutputForClimatology();

    # write the lineage
    $self->_doLineage();

    # finally, create the output manifest file
    $self->_createOutput();
    $self->{LOGGER}->percent_done(100);

}

sub _downloadScrubAndCache {
    my ( $self, $startPercent, $endPercent, $chunkNum, $numChunks, @files )
        = @_;

    my $totalPercent = $endPercent - $startPercent;

    my $newEndPercent = $startPercent + 0.4 * $totalPercent;
    $self->_downloadRawFiles( $startPercent, $newEndPercent, $chunkNum,
        $numChunks, @files );

    # filter out ones that are 'bad URLs
    my @downloaded = ();
    for my $file (@files) {
        if ( !$file->isBadUrl() ) {
            push( @downloaded, $file );
        }
    }

    my $newStartPercent = $newEndPercent;
    $newEndPercent = $startPercent + 0.8 * $totalPercent;
    my ( $scrubbedRef, $timeRef, $startTimeRef, $endTimeRef, $dataPeriodRef )
        = $self->_callScrubber( $newStartPercent, $newEndPercent, $chunkNum,
        @downloaded );

    $newStartPercent = $newEndPercent;
    $self->_putInCache( $newStartPercent, $endPercent, $chunkNum,
        $scrubbedRef, $timeRef, $startTimeRef, $endTimeRef, $dataPeriodRef );

}

# Check for bad URLs. Write them to a file and die if found.
sub _dealWithBadUrls() {
    my ($self) = @_;
    if ( !$self->{KEEP_GOING} ) {
        return;
    }

    my @badUrls = ();
    for my $stagedFile ( @{ $self->{STAGED_FILES} } ) {
        if ( $stagedFile->isBadUrl() ) {
            push( @badUrls, $stagedFile->getUrl() );
        }
    }

    if ( scalar(@badUrls) ) {

        # We had problems.

        # modify the manifest filename so it doesn't trigger back chaining
        my $file
            = $self->{DIRECTORY} . "/"
            . $self->{MANIFEST_FILENAME}
            . "_BAD_URLS.txt";

        open( FILE, ">", $file );
        print( FILE join( "\n", @badUrls ) );
        close(FILE);
        die("Unable to download all requested URLs");
    }

}

# Get as many files as possible out of cache.
sub _checkCache {
    my ( $self, $startPercent, $endPercent ) = @_;

    my $id = $self->{DATA_FIELD_INFO}->get_id();

    $self->{NEEDS_SCRUBBING} = [];

    $self->{LOGGER}->user_msg("Checking cache for files for $id.");

    my @keys = map( $_->getCacheKey(), @{ $self->{STAGED_FILES} } );

    my $outHash = $self->{CACHER}->get(
        DIRECTORY      => $self->{DIRECTORY},
        REGION_LEVEL_1 => $self->{DATA_FIELD_INFO}->get_id(),
        KEYS           => \@keys,
    );
    for my $stagedFile ( @{ $self->{STAGED_FILES} } ) {
        my $key = $stagedFile->getCacheKey();
        if ( defined( $outHash->{$key} )
            && length( $outHash->{$key}->{FILENAME} ) > 0 )
        {
            $self->{LOGGER}->info( "URL was in cache: "
                    . $stagedFile->getUrl()
                    . ". File is "
                    . $outHash->{$key}->{FILENAME}
                    . "." );

            # it was in the cache!
            $stagedFile->setScrubbedFilename( $outHash->{$key}->{FILENAME} );
            $stagedFile->setCacheMetadata( $outHash->{$key}->{METADATA} );

        }
        else {

            # it needs scrubbing
            push( @{ $self->{NEEDS_SCRUBBING} }, $stagedFile );
            $self->{LOGGER}
                ->info( "URL was NOT in cache: " . $stagedFile->getUrl() );
        }
    }
    $self->{LOGGER}->percent_done($endPercent);

}

sub _downloadRawFiles {
    my ($self,     $startPercent, $endPercent,
        $chunkNum, $numChunks,    @toDownload
    ) = @_;

    my $id               = $self->{DATA_FIELD_INFO}->get_id();
    my $fullVariableName = $self->{DATA_FIELD_INFO}->get_long_name() . " ["
        . $self->{DATA_FIELD_INFO}->get_dataProductShortName() . "]";

    if ( scalar(@toDownload) == 0 ) {
        $self->{LOGGER}->info("Nothing to download");
        $self->{LOGGER}->percent_done($endPercent);
        return;
    }

    # now download them
    my $downloader = Giovanni::UrlDownloader->new(
        TIME_OUT        => $self->{TIME_OUT},
        MAX_RETRY_COUNT => $self->{MAX_RETRY_COUNT},
        RETRY_INTERVAL  => $self->{RETRY_INTERVAL},
        CREDENTIALS     => $self->{CREDENTIALS},
    );

    my $percentEachIteration
        = ( $endPercent - $startPercent ) / scalar(@toDownload);
    for ( my $i = 0; $i < scalar(@toDownload); $i++ ) {
        my $stagedFile = $toDownload[$i];

        if ( ( $i % $self->{FILTER_SKIP} ) == 0 ) {
            $self->{LOGGER}
                ->info( "Downloading URL: " . $stagedFile->getUrl() );
            my $msg
                = sprintf(
                "Downloading URL %d of %d for variable '%s.' (Chunk %d of %d)",
                $i + 1, scalar(@toDownload), $fullVariableName, $chunkNum + 1,
                $numChunks );
            $self->{LOGGER}->user_msg($msg);
        }

        my $response = $downloader->download(
            URL             => $stagedFile->getUrl(),
            DIRECTORY       => $self->{DIRECTORY},
            FILENAME        => $stagedFile->getFilenameFromSearch(),
            RESPONSE_FORMAT => $self->{DATA_FIELD_INFO}->get_responseFormat(),
        );

        if ( $response->{ERROR} ) {
            if ( $self->{KEEP_GOING} ) {

                # Keep going so other stuff gets cached
                $self->{LOGGER}->error( "Unable to download "
                        . $stagedFile->getUrl()
                        . ". Error message: "
                        . $response->{ERROR} );

                # keep track of this as a bad URL
                $stagedFile->setBadUrl();
            }
            else {

                # die because we couldn't get the data.
                $self->{LOGGER}->error( "Unable to download "
                        . $stagedFile->getUrl()
                        . ". Error message: "
                        . $response->{ERROR} );
                $self->{LOGGER}
                    ->user_error("Unable to download data URL at this time.");
                die( $response->{ERROR} );
            }
        }
        else {

            # success
            if ( ( $i % $self->{FILTER_SKIP} ) == 0 ) {
                $self->{LOGGER}->user_msg( "Finished downloading URL "
                        . ( $i + 1 ) . " of "
                        . scalar(@toDownload)
                        . " for $id." );
            }
        }
        if ( ( $i % $self->{FILTER_SKIP} ) == 0 ) {
            $self->{LOGGER}
                ->percent_done( $startPercent + $i * $percentEachIteration );
        }
    }
    $self->{LOGGER}->percent_done($endPercent);

}

# calls scrubber on the files we couldn't get out of the cache.
sub _callScrubber {
    my ( $self, $startPercent, $endPercent, $chunkNum, @toScrub ) = @_;

    ######
    # create the scrubber input file
    ######
    my $doc  = XML::LibXML::Document->new();
    my $root = $doc->createElement("data");
    $doc->setDocumentElement($root);

    my $dataFileListNode = $doc->createElement("dataFileList");
    $root->appendChild($dataFileListNode);
    $dataFileListNode->setAttribute(
        "id" => $self->{DATA_FIELD_INFO}->get_id() );
    $dataFileListNode->setAttribute(
        "sdsName" => $self->{DATA_FIELD_INFO}->get_sdsName() );

    # loop through all our staged files

    for my $file (@toScrub) {
        my $dataFileNode = $doc->createElement("dataFile");
        $dataFileListNode->appendChild($dataFileNode);
        $dataFileNode->appendText(
            $self->{DIRECTORY} . "/" . $file->getFilenameFromSearch() );
        $dataFileNode->setAttribute( 'startTime',
            $file->getStartTimeFromSearch() );
        $dataFileNode->setAttribute( 'endTime',
            $file->getEndTimeFromSearch() );
    }

    my $scrubberInputFile
        = $self->{DIRECTORY}
        . "/scrubberInput_"
        . $chunkNum . "_"
        . $self->{MANIFEST_FILENAME};

    open( FILE, ">$scrubberInputFile" ) or die $?;
    print FILE $doc->toString() or die $?;
    close(FILE) or die $?;

    #####
    # call scrubber
    ####

    my @times       = ();
    my @startTimes  = ();
    my @endTimes    = ();
    my @dataPeriods = ();
    if ( scalar(@toScrub) > 0 ) {
        $self->{LOGGER}->user_msg("Updating metadata in file");

        my $cmd
            = "ncScrubber.pl --catalog '"
            . $self->{DATA_FIELD_INFO_FILE}
            . "' --outDir '"
            . $self->{DIRECTORY}
            . "' --input '$scrubberInputFile'";

        my $caller = Giovanni::ScienceCommand->new(
            sessionDir => $self->{DIRECTORY},
            logger     => $self->{LOGGER}
        );

        my ($ref) = $caller->exec( $cmd, $startPercent, $endPercent );

# <data>
#   <dataFileList id="GSSTFM_3_SET1_INT_ST_mag">
#     <dataFile time="1044057600" time_bnds_start="1044057600" time_bnds_end="1046476799" startTime="1044057600" endTime="1046476799" dataPeriod="200302">/var/scratch/csmit/TMPDIR/test_phfM/session/scrubbed.GSSTFM_3_SET1_INT_ST_mag.20030201.nc</dataFile>
#   </dataFileList>
# </data>
        my $outXml = $ref->[-1];
        my $dom = XML::LibXML->load_xml( location => $outXml );
        @times = map( $_->getValue(),
            $dom->findnodes("/data/dataFileList/dataFile/\@time") );
        @startTimes = map( $_->getValue(),
            $dom->findnodes("/data/dataFileList/dataFile/\@startTime") );
        @endTimes = map( $_->getValue(),
            $dom->findnodes("/data/dataFileList/dataFile/\@endTime") );
        @dataPeriods = map( $_->getValue(),
            $dom->findnodes("/data/dataFileList/dataFile/\@dataPeriod") );
        my @outfiles = map( $_->getValue(),
            $dom->findnodes("/data/dataFileList/dataFile/text()") );
        Giovanni::Util::trim(@outfiles);

        if ( scalar(@outfiles) != scalar(@toScrub) ) {
            die("Didn't scrub the right number of files.");
        }

        for ( my $i = 0; $i < scalar(@outfiles); $i++ ) {
            my ($filename) = fileparse( $outfiles[$i] );
            $toScrub[$i]->setScrubbedFilename($filename);
            $toScrub[$i]->setCacheMetadata(
                {   STARTTIME  => $startTimes[$i],
                    ENDTIME    => $endTimes[$i],
                    TIME       => $times[$i],
                    DATAPERIOD => $dataPeriods[$i],
                }
            );
        }
        $self->{LOGGER}->user_msg("Done updating metadata in file");
    }

    if ( !$self->{KEEP_RAW_FILES} ) {
        my @paths
            = map( $self->{DIRECTORY} . "/" . $_->getFilenameFromSearch(),
            @toScrub );
        unlink(@paths);
    }

    $self->{LOGGER}->percent_done($endPercent);

    return ( \@toScrub, \@times, \@startTimes, \@endTimes, \@dataPeriods );
}

sub _putInCache() {
    my ($self,         $startPercent, $endPercent,
        $chunkNum,     $scrubbedRef,  $timeRef,
        $startTimeRef, $endTimeRef,   $dataPeriodsRef
    ) = @_;
    my @scrubbed    = @{$scrubbedRef};
    my @times       = @{$timeRef};
    my @startTimes  = @{$startTimeRef};
    my @endTimes    = @{$endTimeRef};
    my @dataPeriods = @{$dataPeriodsRef};

    # just get the year out of the start time. This will be the level 2 region
    my @dts = map( DateTime->from_epoch( epoch => $_ ), @startTimes );
    my @years = map( $_->year(), @dts );

    if ( scalar(@scrubbed) == 0 ) {
        $self->{LOGGER}->info("Nothing to put in cache.");
        $self->{LOGGER}->percent_done($endPercent);
        return;
    }

    # call the cacher
    my @keys      = map( $_->getCacheKey(),         @{$scrubbedRef} );
    my @filenames = map( $_->getScrubbedFilename(), @{$scrubbedRef} );
    my @metadata  = ();
    for ( my $i = 0; $i < scalar(@times); $i++ ) {
        $metadata[$i] = {
            STARTTIME  => $startTimes[$i],
            ENDTIME    => $endTimes[$i],
            TIME       => $times[$i],
            DATAPERIOD => $dataPeriods[$i]
        };
    }
    my @successfulKeys = $self->_putHelper(
        KEYS           => \@keys,
        FILENAMES      => \@filenames,
        REGION_LEVEL_2 => \@years,
        METADATA       => \@metadata,
    );

    if ( scalar(@successfulKeys) != scalar( @{$scrubbedRef} ) ) {

        # Something went wrong...
        $self->{LOGGER}
            ->error("Caching failed during put. Cache should have died.");
        die("Caching failed during put. Cache should have died.");
    }

    # delete all the scrubbed files
    my @paths = map( $self->{DIRECTORY} . "/" . $_, @filenames );
    unlink(@paths);

    # get them back out as symlinks
    my $outHash = $self->{CACHER}->get(
        DIRECTORY      => $self->{DIRECTORY},
        REGION_LEVEL_1 => $self->{DATA_FIELD_INFO}->get_id(),
        KEYS           => \@keys,
    );

    $self->{LOGGER}
        ->user_msg( "Finished caching files for chunk " . ( $chunkNum + 1 ) );
    $self->{LOGGER}->percent_done($endPercent);
}

# ideally, we want to just call the cache once, but the level 2 region
# may be different for some files
sub _putHelper {
    my ( $self, %params ) = @_;
    my @keys         = @{ $params{"KEYS"} };
    my @filenames    = @{ $params{"FILENAMES"} };
    my @regionLevel2 = @{ $params{"REGION_LEVEL_2"} };
    my @metadata     = @{ $params{"METADATA"} };

    my $done             = 0;
    my $currRegionLevel2 = $regionLevel2[0];
    my @successfulKeys   = ();
    while ( !$done ) {

        # figure out which indexes of regionLevel2 are $currRegionLevel2
        my $firstIndex
            = first_index { $_ == $currRegionLevel2 } @regionLevel2;
        my $lastIndex = last_index { $_ == $currRegionLevel2 } @regionLevel2;

        my @loopKeys      = @keys[ $firstIndex .. $lastIndex ];
        my @loopFilenames = @filenames[ $firstIndex .. $lastIndex ];
        my @loopMetadata  = @metadata[ $firstIndex .. $lastIndex ];

        my @successfulLoopKeys = $self->{CACHER}->put(
            DIRECTORY      => $self->{DIRECTORY},
            KEYS           => \@loopKeys,
            FILENAMES      => \@loopFilenames,
            REGION_LEVEL_1 => $self->{DATA_FIELD_INFO}->get_id(),
            REGION_LEVEL_2 => $currRegionLevel2,
            METADATA       => \@loopMetadata,
        );

        push( @successfulKeys, @successfulLoopKeys );

        # see if we are done
        if ( $lastIndex == ( scalar(@regionLevel2) - 1 ) ) {
            $done = 1;
        }
        else {
            $currRegionLevel2 = $regionLevel2[ $lastIndex + 1 ];
        }
    }

    return @successfulKeys;

}

sub _createOutput {
    my ($self) = @_;

    my $doc  = XML::LibXML::Document->new();
    my $root = $doc->createElement("manifest");
    $doc->setDocumentElement($root);
    my $fileListElement = $doc->createElement("fileList");
    $root->appendChild($fileListElement);
    $fileListElement->setAttribute( "id",
        $self->{DATA_FIELD_INFO}->get_id() );

    for my $stagedFile ( @{ $self->{STAGED_FILES} } ) {
        my $fileElement = $doc->createElement("file");
        $fileListElement->appendChild($fileElement);
        $fileElement->appendText(
            $self->{DIRECTORY} . "/" . $stagedFile->getScrubbedFilename() );

       # Get the data pairing time attribute from the scrubbed file.
       # We will call this 'datatime'. Our preferred method for getting this
       # information is from the cache metadata, but we will get it out of the
       # data itself if the cache metadata is not available.
        my $file     = $stagedFile->{'SCRUBBED_FILENAME'};
        my $metadata = $stagedFile->{'CACHE_METADATA'};

        my $data_pairing_time
            ; # 'DATAPERIOD' is the dataday or datamonth value from the scrubbed
              # file if the data is daily or monthly

        if ( $metadata->{STARTTIME} ) {
            $self->{LOGGER}->info(
                "Getting time for pairing out of cache metadata: $file");

            if ( defined( $metadata->{DATAPERIOD} )
                && $metadata->{DATAPERIOD} ne "" )
            {

                # 'DATAPERIOD' is the dataday or datamonth value from the
                # scrubbed file if the data is daily or monthly
                $data_pairing_time = $metadata->{DATAPERIOD};
            }
            else {

                # If there is no DATAPERIOD, then the STARTTIME is used.
                $data_pairing_time = $metadata->{STARTTIME};
            }
        }
        else {

            # TODO: Remove this else once the cache metadata has been updated!
            # JIRA ticket FEDGIANNI-2839.
            $self->{LOGGER}
                ->warn("Getting time for pairing out of data file: $file");
            my $temporal_resolution
                = $self->{DATA_FIELD_INFO}->get_dataProductTimeInterval();
            $data_pairing_time
                = Giovanni::Data::NcFile::get_data_pairing_time( $file,
                'GLOBAL', 'start_time', $temporal_resolution );
            Giovanni::Util::trim($data_pairing_time);

            $self->{LOGGER}
                ->info( "Temporal resolution of data file manifest file: "
                    . $temporal_resolution );
        }
        $fileElement->setAttribute( "datatime", $data_pairing_time );
        $self->{LOGGER}->debug("Data time for pairing: $data_pairing_time");

    }

    open( FILE, ">" . $self->{DIRECTORY} . "/" . $self->{MANIFEST_FILENAME} )
        or die $?;
    print FILE $doc->toString() or die $?;
    close(FILE) or die $?;
    $self->{LOGGER}->info( "Finished writing manifest file: "
            . $self->{DIRECTORY} . "/"
            . $self->{MANIFEST_FILENAME} );
}

sub _sortOutputForClimatology {
    my ($self) = @_;
    if ( !$self->{DATA_FIELD_INFO}->isClimatology() ) {

        # no need to sort...
        return;
    }

    # first sort the entries by month
    my @files = sort {
        _getMonth( $a->getScrubbedFilename() )
            <=> _getMonth( $b->getScrubbedFilename() )
    } @{ $self->{STAGED_FILES} };

    # now get out the months
    my @months = map( _getMonth( $_->getScrubbedFilename() ), @files );
    if ( scalar(@months) > 1 ) {
        my $i          = 1;
        my $splitIndex = -1;
        while ( $i < scalar(@months) && $splitIndex < 0 ) {
            if ( $months[$i] != $months[ $i - 1 ] + 1 ) {

                # we have a gap
                $splitIndex = $i;
            }
            $i++;
        }
        if ( $splitIndex > 0 ) {
            @files = @files[ $splitIndex .. scalar(@files) - 1,
                0 .. $splitIndex - 1 ];
        }
    }

    $self->{STAGED_FILES} = \@files;

}

sub _getMonth {
    my ($scrubbedFilename) = @_;

    # get the stuff between the last two dots before 'nc'
    $scrubbedFilename =~ /.*\.(.*)\.nc$/;

    # date format is YYYYMMDD or YYYYMMDDhh
    return substr( $1, 4, 2 );
}

sub _doLineage {
    my ($self) = @_;

    my $usedNccopy = Giovanni::UrlDownloader::shouldUseNcCopy(
        RESPONSE_FORMAT => $self->{DATA_FIELD_INFO}->get_responseFormat(), );

    my @inputs  = ();
    my @outputs = ();
    for my $stagedFile ( @{ $self->{STAGED_FILES} } ) {
        my $input;
        if ($usedNccopy) {
            $input = Giovanni::Logger::InputOutput->new(
                name  => "Data URL",
                value => "nccopy " . $stagedFile->getUrl(),
                type  => "PARAMETER"
            );
        }
        else {
            $input = Giovanni::Logger::InputOutput->new(
                name  => "Data URL",
                value => $stagedFile->getUrl(),
                type  => "URL"
            );
        }
        push( @inputs, $input );

        my $scrubbedPath
            = $self->{DIRECTORY} . "/" . $stagedFile->getScrubbedFilename();
        my $output = Giovanni::Logger::InputOutput->new(
            name  => "Output file",
            value => "$scrubbedPath",
            type  => "FILE"
        );
        push( @outputs, $output );
    }

    $self->{LOGGER}->write_lineage(
        name     => "Data Staging",
        inputs   => \@inputs,
        outputs  => \@outputs,
        messages => []
    );
}

sub _checkParams {
    my $argHash = shift(@_);
    my @args    = @_;

    for my $arg (@args) {
        if ( !( exists( $argHash->{$arg} ) ) ) {
            my @info = caller;

            die("Missing mandatory argument $arg for " . $info[1] . ", line ",
                $info[2]
            );
        }
    }

}

1;
__END__

=head1 NAME

Giovanni::DataStager - Perl extension for staging data.

=head1 SYNOPSIS

  use Giovanni::DataStager;
  use Giovanni::Logger;
  
  my $logger = Giovanni::Logger->new(session_dir=>$sessionDir,
                  manifest_filename=>$manifestFilename)

  my $stager = Giovanni::DataStager->new(
     DIRECTORY       => $sessionDir,
     LOGGER          => $logger,
     CHUNK_SIZE      => 2,
     TIME_OUT        => 10,
     MAX_RETRY_COUNT => 1,
     RETRY_INTERVAL  => 0,
     CREDENTIALS     => $credentials,
  );
  $stager->stage(
     URLS_FILE            => $searchUrlsFile,
     DATA_FIELD_INFO_FILE => $dataInfoFile,
     MANIFEST_FILENAME    => $manifestFilename,
  );
  

=head1 DESCRIPTION

Stages files. First checks the cache. All files that are not in the cache are
downloaded, scrubbed, and put into the cache.

=head2 new()
Constructor

Inputs:

DIRECTORY - location for staged files

LOGGER - logger for messages

CHUNK_SIZE - the maximum number of cache queries that can be bundled together

TIME_OUT - time in seconds to wait for URLs to finish downloading

MAX_RETRY_COUNT - how many times to try URLs that fail

RETRY_INTERVAL - time in seconds between consecutive queries to the same (failing) URL

CREDENTIALS - A reference to a hash where each key is a location (a string
of the form host:port, e.g. urs.earthdata.nasa.gov:443) that requires HTTP basic
authentication, and each value is a reference to hash where each key is
a basic authentication realm and each value is a reference to a hash with
key/value pairs DOWNLOAD_USER => username and DOWNLOAD_CRED => password

FILTER_SKIP (optional) - decimates log message while downloading files. Defaults
to 1 (all message). If set to 2, there will be half as many messages; if set to
3, a third as many; etc.

KEEP_GOING (optional) - if set to true, the code will continue to download and 
scrub data even if a data URL fails. Defaults to false. 

KEEP_RAW_FILES (optional) - if set to true, the code will keep any raw files
downloaded from the source. Otherwise, they will be cleaned up after scrubbing.
Defaults to false.

=head3 stage()

Stages files.

Inputs:

URLS_FILE - manifest file from search step

DATA_FIELD_INFO_FILE - file with catalog information

MANIFEST_FILENAME - name of the output manifest file. (Just the name, not the path.)

=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>

=cut
