#$Id: Search.pm,v 1.32 2015/06/30 17:10:25 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::Search;

use 5.008008;
use strict;
use warnings;

use XML::LibXML;
use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);
use Date::Manip;
use DateTime;

use Giovanni::Logger;
use Giovanni::Util;
use Giovanni::Search::SSW;
use Giovanni::Util;
use Giovanni::Search::OPeNDAP;
use Giovanni::UrlDownloader;

# need this to build the variable name for error messages
use Giovanni::Visualizer::Hints;

our $VERSION = '0.01';

sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    my @mandatoryArgs = qw(session_dir catalog out_file);
    for my $arg (@mandatoryArgs) {
        if ( !exists $params{$arg} ) {
            die "Search constructor must have a '$arg' key in the hash";
        }
    }

    # figure out the data id
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file( $self->{catalog} );
    my $xpc    = XML::LibXML::XPathContext->new($dom);
    my @data_ids
        = map { $_->to_literal() } $xpc->findnodes("/varList/var/\@id");
    $self->{data_ids} = \@data_ids;

    # setup the logger
    if ( !$self->{logger} ) {
        $self->{logger} = Giovanni::Logger->new(
            session_dir       => $self->{session_dir},
            manifest_filename => $self->{out_file},
        );
    }

    $self->{logger}->info( "Data ids: " . join( ",", @data_ids ) );

    # set some kind of time out
    if ( !defined( $self->{time_out} ) ) {

        # default 90 seconds timeout
        $self->{time_out} = 90;
    }

    my @responseFormats = map( $_->to_literal(),
        $xpc->findnodes("/varList/var/\@responseFormat") );
    my @needsNcCopy
        = map(
        Giovanni::UrlDownloader::shouldUseNcCopy( RESPONSE_FORMAT => $_ ),
        @responseFormats );
    $self->{needsNcCopy} = \@needsNcCopy;

    return $self;
}

# Returns all the search URLS it gets from the SSW.
sub search {
    my ( $self, $start_time, $end_time ) = @_;

    # build the root of the output XML
    my $doc  = XML::LibXML->createDocument;
    my $root = $doc->createElement("searchList");
    $doc->setDocumentElement($root);

    # Create arrays to keep track of the inputs (search urls) and outputs
    # (result urls) for lineage.
    my @inputs  = ();
    my @outputs = ();

    # Read the catalog file
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file( $self->{catalog} );
    my $xpc    = XML::LibXML::XPathContext->new($dom);

    $self->{logger}->user_msg("Searching for data.");

    # loop over each id
    my $curr_percent      = 0;
    my $percent_increment = 100.0 / scalar( @{ $self->{data_ids} } );
    for ( my $i = 0; $i < scalar( @{ $self->{data_ids} } ); $i++ ) {
        my $data_id      = $self->{data_ids}->[$i];
        my $needs_nccopy = $self->{needsNcCopy}->[$i];

        my ( $resultSet, $search_urls_ref )
            = $self->_doSearchesForOneId( $data_id, $xpc, $start_time,
            $end_time, $curr_percent, $curr_percent + $percent_increment );

        for my $search_url (@$search_urls_ref) {
            push(
                @inputs,
                Giovanni::Logger::InputOutput->new(
                    name  => "Search URL",
                    value => $search_url,
                    type  => "URL"
                    )
            );
        }

        my $searchElement = $doc->createElement("search");
        $searchElement->setAttribute( "id", $data_id );
        $root->appendChild($searchElement);

        foreach my $aHash (@$resultSet) {
            my $url       = $aHash->{url};
            my $filename  = $aHash->{label};
            my $starttime = $aHash->{startTime};
            my $endtime   = $aHash->{endTime};
            my $element   = $doc->createElement("result");
            $element->setAttribute( "url",       $url );
            $element->setAttribute( "filename",  $filename );
            $element->setAttribute( "starttime", $starttime );
            $element->setAttribute( "endtime",   $endtime );
            $searchElement->appendChild($element);

            if ($needs_nccopy) {
                push(
                    @outputs,
                    Giovanni::Logger::InputOutput->new(
                        name  => "Data URL",
                        value => "nccopy $url",
                        type  => "PARAMETER"
                        )
                );
            }
            else {
                push(
                    @outputs,
                    Giovanni::Logger::InputOutput->new(
                        name  => "Data URL",
                        value => $url,
                        type  => "URL"
                        )
                );

            }
        }

        $curr_percent += $percent_increment;
    }

    # write the lineage with all inputs and outputs
    $self->{logger}->write_lineage(
        name    => "Search for data",
        inputs  => \@inputs,
        outputs => \@outputs
    );

    # write it to a file
    open( OUTFILE, ">" . $self->{session_dir} . "/" . $self->{out_file} )
        or die $?;
    print OUTFILE $doc->toString() or die $?;
    close(OUTFILE) or die $?;

    $self->{logger}->user_msg("Finished searching for data.");
    $self->{logger}->percent_done(100);
    return $self->{session_dir} . "/" . $self->{out_file};
}

sub _getTimeChunks {
    my ( $self, $catalog_xpc, $id, $start_time, $end_time ) = @_;
    my %params = ();

    _addCatalogAttributeToHash( \%params, "dataStartTime", $catalog_xpc, $id,
        "dataProductBeginDateTime" );
    _addCatalogAttributeToHash( \%params, "dataEndTime", $catalog_xpc, $id,
        "dataProductEndDateTime" );
    _addCatalogAttributeToHash( \%params, "dataStartTimeOffset", $catalog_xpc,
        $id, "dataProductStartTimeOffset" );
    _addCatalogAttributeToHash( \%params, "dataEndTimeOffset", $catalog_xpc,
        $id, "dataProductEndTimeOffset" );
    _addCatalogAttributeToHash( \%params, "searchIntervalDays", $catalog_xpc,
        $id, "searchIntervalDays" );
    _addCatalogAttributeToHash( \%params, "dataTemporalResolution",
        $catalog_xpc, $id, "dataProductTimeInterval" );
    $params{"searchStartTime"} = $start_time;
    $params{"searchEndTime"}   = $end_time;
    $params{logger}            = $self->{logger};

    my @chunks = Giovanni::Util::chunkDataTimeRange(%params);

    return @chunks;
}

sub _addCatalogAttributeToHash {
    my ( $paramHash, $key, $catalog_xpc, $id, $attribute ) = @_;
    my $xpath = qq(/varList/var[\@id="$id"]/\@$attribute);
    my @nodes = $catalog_xpc->findnodes($xpath);
    if (@nodes) {
        $paramHash->{$key} = $nodes[0]->getValue();
    }
}

# Does all the searches for one id
sub _doSearchesForOneId() {
    my ( $self, $data_id, $catalog_xpc, $start_time, $end_time,
        $start_percent, $end_percent )
        = @_;

    # see if this is a climatology
    my $isClimatology
        = $catalog_xpc->findvalue(
        qq(/varList/var[\@id="$data_id"]/\@climatology) ) eq "true"
        ? 1
        : 0;

    # variables that will hold the result URLs, return filenames, and
    # search URLs.
    my ( $resultSet, $search_urls_ref );

    # see if we have a SSW access url
    my $osdd
        = $catalog_xpc->findvalue(qq(/varList/var[\@id="$data_id"]/\@osdd));
    my $sswUrl
        = $catalog_xpc->findvalue(qq(/varList/var[\@id="$data_id"]/\@url));

    my $variableStr = $self->_createVariableString( $catalog_xpc, $data_id );
    $self->{logger}->user_msg("Searching for '$variableStr.'");

    # break up the search time
    my @chunks = ();
    if ($isClimatology) {

        if ( !$osdd ) {
            $self->{logger}->error(
                "Climatology currently only works against opensearch, not the SSW"
            );
            $self->{logger}->user_error("Unable to complete search");
            die("Unable to complete search");
        }

        # get out the data start and end time
        my $data_start_time = $catalog_xpc->findvalue(
            qq(/varList/var[\@id="$data_id"]/\@startTime) );

        # convert to a string that looks like YYYY-MM-DDTHH:MM:SSZ. (Don't want
        # subseconds because Mirador can't handle it.)
        $data_start_time = _dateToString( _parseDate($data_start_time) );

        my $data_end_time = $catalog_xpc->findvalue(
            qq(/varList/var[\@id="$data_id"]/\@endTime) );
        $data_end_time = _dateToString( _parseDate($data_end_time) );

        # if this is a climatology, we will do one search for the
        # entire time range.
        push(
            @chunks,
            { start => $data_start_time,
                end     => $data_end_time,
                overlap => 'full'
            }
        );
    }
    else {

        # if this is not a climatology, chunk
        @chunks = $self->_getTimeChunks( $catalog_xpc, $data_id, $start_time,
            $end_time );
    }

    if ($osdd) {
        my $sampleFile = $catalog_xpc->findvalue(
            qq(/varList/var[\@id="$data_id"]/\@sampleFile) );
        my $sampleOpendap = $catalog_xpc->findvalue(
            qq(/varList/var[\@id="$data_id"]/\@sampleOpendap) );
        my $accessName = $catalog_xpc->findvalue(
            qq(/varList/var[\@id="$data_id"]/\@accessName) );
        my $accessFormat = $catalog_xpc->findvalue(
            qq(/varList/var[\@id="$data_id"]/\@accessFormat) );
        my $searchFilter = $catalog_xpc->findvalue(
            qq(/varList/var[\@id="$data_id"]/\@searchFilter) );
        my $oddxDims = $catalog_xpc->findvalue(
            qq(/varList/var[\@id="$data_id"]/\@oddxDims) );
        my %params = (
            accessName           => $accessName,
            osddUrl              => $osdd,
            sampleFile           => $sampleFile,
            sampleOpendap        => $sampleOpendap,
            timeChunks           => \@chunks,
            dataId               => $data_id,
            logger               => $self->{logger},
            sessionDir           => $self->{session_dir},
            variableString       => $variableStr,
            searchFilter         => $searchFilter,
            loginCredentials     => $self->{loginCredentials},
            oddxDims             => $oddxDims,
        );
        $params{responseFormat} = $accessFormat
            if $accessFormat =~ /native|netCDF/;

        my $odSearch = Giovanni::Search::OPeNDAP->new(%params);
        ( $resultSet, $search_urls_ref ) = $odSearch->search();

    }
    else {

        # this is a SSW-accessible data field
        $self->{logger}->info("Using the SSW for search");
        my $sswSearch = Giovanni::Search::SSW->new(
            logger             => $self->{logger},
            dataId             => $data_id,
            variableString     => $variableStr,
            sessionDir         => $self->{session_dir}
        );
        my @start_times = map( $_->{start}, @chunks );
        my @end_times   = map( $_->{end},   @chunks );
        my @is_partial = map( $_->{overlap} =~ /partial/ ? 1 : 0, @chunks );
        ( $resultSet, $search_urls_ref ) = $sswSearch->search(
            startTime    => \@start_times,
            endTime      => \@end_times,
            isPartial    => \@is_partial,
            baseUrl      => $sswUrl,
            startPercent => $start_percent,
            endPercent   => $end_percent
        );

    }

    # filter out any duplicate results we may get as a result of chunking the
    # time range of the search
    $self->_filterDuplicates($resultSet);

    # filter out results that aren't in the proper range
    if ($isClimatology) {
        my $data_start_offset = 0;
        my @nodes             = $catalog_xpc->findnodes(
            qq(/varList/var[\@id="$data_id"]/\@dataProductStartTimeOffset) );
        if ( scalar(@nodes) > 0 ) {
            $data_start_offset = $nodes[0]->getValue();
        }
        my $data_end_offset = 0;
        @nodes = $catalog_xpc->findnodes(
            qq(/varList/var[\@id="$data_id"]/\@dataProductEndTimeOffset) );
        if ( scalar(@nodes) > 0 ) {
            $data_end_offset = $nodes[0]->getValue();
        }
        $self->_filterClimatology( $start_time, $data_start_offset, $end_time,
            $data_end_offset, $resultSet );


    }

    # filter out missing URLs
    if ( exists( $self->{missing_url} ) ) {

        # The class was instantiated with the location of the missing URLs.
        $self->{logger}->info("Checking for missing URLs.");
        my @filtered = $self->_checkMissingUrls($resultSet );

    }
    else {
        $self->{logger}->warning("Couldn't check for missing URLs.");
    }


    if ( scalar(@$resultSet) == 0 ) {
        $self->{logger}->error("Unable to find any results for $data_id");

        $self->{logger}->user_error(
            $self->_buildUserErrorMessage( $catalog_xpc, $data_id ) );
        die("Unable to find any results for $data_id");
    }

    $self->{logger}->user_msg("Finished searching for '$variableStr.'");
    return ( $resultSet, $search_urls_ref );

}

# After chunking the search range, we may end up with duplicate results if a
# single granule's time span covers two adjacent search time chunks. This
# function gets rid of these duplicates.
sub _filterDuplicates {
    my ( $self, $resultSet ) = @_;

    $self->{logger}->info("Looking for duplicate search results...");
    my $seen_hash     = {};
    my $numRemoved    = 0;
    for ( my $i = 0; $i <= $#$resultSet; $i++ ) {
        my $url = $resultSet->[$i]->{url};
        if ( !( $seen_hash->{$url} ) ) {
            $seen_hash->{$url} = 1;
        }
        else {
            $self->{logger}->info("Removing duplicate search result: $url");
            $numRemoved++;
            splice @$resultSet, $i, 1;
            --$i;
        }
    }

    $self->{logger}->info("Removed $numRemoved duplicate(s).");
}

sub _createVariableString {
    my ( $self, $catalog_xpc, $data_id ) = @_;

    my @nodes    = $catalog_xpc->findnodes(qq(/varList/var[\@id="$data_id"]));
    my $node     = $nodes[0];
    my $longName = $node->getAttribute("long_name");
    my $timeResolution = $node->getAttribute("dataProductTimeInterval");
    my $spatial        = $node->getAttribute("resolution");
    my $platform       = $node->getAttribute("dataProductPlatformInstrument");
    my $version        = $node->getAttribute("dataProductVersion");
    my $units          = $node->getAttribute("dataFieldUnitsValue");
    my $product        = $node->getAttribute("dataProductShortName");
    my $varString      = Giovanni::Visualizer::Hints::createDataFieldString(
        LONG_NAME           => $longName,
        TIME_RESOLUTION     => $timeResolution,
        SPATIAL_RESOLUTION  => $spatial,
        PLATFORM_INSTRUMENT => $platform,
        VERSION             => $version,
        UNITS               => $units,
        PRODUCT_SHORTNAME   => $product,
    );
    return $varString;
}

sub _buildUserErrorMessage {
    my ( $self, $catalog_xpc, $data_id ) = @_;

    my $varString = $self->_createVariableString( $catalog_xpc, $data_id );

    my $msg
        = "We were unable to find any data "
        . "matching your criteria for '$varString.' Unfortunately, we are "
        . "unable to automatically determine why. We suggest trying different "
        . "criteria, such as a different variable or a different time "
        . "range, or trying again later. "; 
    return $msg;
}

# goes through the list of result URLs and removes any that are in the missing
# URL file
sub _checkMissingUrls {
    my ($self,  $result_urls ) = @_;

    my $missing_config_loc = $self->{missing_url};
    # get out all the missing URLs
    if ( !( -e $missing_config_loc ) ) {
        die( "Unable to find missing URL file. Expected it to be $missing_config_loc"
        );
    }

    open( MISSING, "<$missing_config_loc" )
        or die "Unable to open missing URL file: $?";
    my @missingUrls = <MISSING>;
    close(MISSING) or die $?;

    # put the urls as hash keys so they are easy to find
    my %urlSet = map { Giovanni::Util::trim($_) => 1 } @missingUrls;

    my @filtered;
    for ( my $i = 0; $i <= $#$result_urls; ++$i ) {
        my $key = $result_urls->[$i]->{url};
        if ( exists $urlSet{$key} ) {
            push @filtered,$result_urls->[$i];
            splice @$result_urls, $i, 1;
            --$i;
        }
    }
    my $numRemoved = scalar @filtered;
    $self->{logger}->info("Removed $numRemoved missing urls.");
    return @filtered;
}

sub _filenameFromUrl {
    my ( $str, $id ) = @_;
    if ( defined($id) ) {
        return "searchResult_$id" . "_" . md5_hex($str) . ".xml";
    }
    else {
        return "searchResult_" . md5_hex($str) . ".xml";
    }
}

sub _filterClimatology {
    my ($self, $userStartDate, $dataProductStartTimeOffset, $userEndDate,
        $dataProductEndTimeOffset, $resultSet )
        = @_;

    # parse the start and end dates
    my $searchStartDT = _parseDate($userStartDate);
    my $searchEndDT   = _parseDate($userEndDate);

    # add the offsets
    $searchStartDT->add( seconds => $dataProductStartTimeOffset );
    $searchEndDT->add( seconds => $dataProductEndTimeOffset );

    my $numRemoved = 0;

    for ( my $i = 0; $i <= $#$resultSet; ++$i ) {

        # parse the granule start and end times
        my $granuleStartDT = _parseDate( $resultSet->[$i]->{startTime} );
        my $granuleEndDT   = _parseDate( $resultSet->[$i]->{endTime} );

        if ( _inDateRangeIgnoreYear(
                $searchStartDT,  $searchEndDT,
                $granuleStartDT, $granuleEndDT
            )
            )
        {

            # Do nothing
        }
        else {
            ++$numRemoved;
            splice @$resultSet, $i, 1;
            --$i;
        }

    }
    $self->{logger}->info("Removed $numRemoved non-applicable climatology urls.");
}

sub _inDateRangeIgnoreYear {
    my ( $searchStartDateTime, $searchEndDateTime,
        $granuleStartDateTime, $granuleEndDateTime
    ) = @_;

    if ( _compareIgnoreYear( $searchStartDateTime, $searchEndDateTime ) > 0 )
    {

        # if the search range wraps around the year, divide into the piece at
        # the beginning of the year and the piece at the end.
        return _inDateRangeIgnoreYear(
            _parseDate('2000-01-01T00:00:00Z'), $searchEndDateTime,
            $granuleStartDateTime, $granuleEndDateTime
            )
            || _inDateRangeIgnoreYear(
            $searchStartDateTime,  _parseDate('2000-12-31T23:59:59Z'),
            $granuleStartDateTime, $granuleEndDateTime
            );
    }

    if ( _compareIgnoreYear( $granuleStartDateTime, $granuleEndDateTime ) > 0 )
    {

        # if the granule month range wraps around the year (as for seasonal
        # DJF granules), divide into the piece at the beginning of the year
        # and the piece at the end.
        return _inDateRangeIgnoreYear(
            $searchStartDateTime, $searchEndDateTime,
            _parseDate('2000-01-01T00:00:00Z'), $granuleEndDateTime
            )
            || _inDateRangeIgnoreYear(
            $searchStartDateTime,  $searchEndDateTime,
            $granuleStartDateTime, _parseDate('2000-12-31T23:59:59Z')
            );
    }

    if ( _compareIgnoreYear( $granuleEndDateTime, $searchStartDateTime ) < 0
        || _compareIgnoreYear( $granuleStartDateTime, $searchEndDateTime )
        > 0 )
    {
        return 0;
    }
    return 1;
}

sub _compareIgnoreYear {
    my ( $firstDT, $secondDT ) = @_;

    # convert both to strings
    my $firstStr  = _dateToString($firstDT);
    my $secondStr = _dateToString($secondDT);

    # get rid of the year, which is the first 4 characters
    $firstStr  = substr( $firstStr,  4 );
    $secondStr = substr( $secondStr, 4 );

    if ( $firstStr eq $secondStr ) {
        return 0;
    }
    elsif ( $firstStr lt $secondStr ) {
        return -1;
    }
    else {
        return 1;
    }

}

sub _dateToString {
    my ($date) = @_;
    return sprintf(
        "%.4d-%.2d-%.2dT%.2d:%.2d:%.2dZ",
        $date->year(), $date->month(),  $date->day(),
        $date->hour(), $date->minute(), $date->second()
    );
}

sub _parseDate {
    my ($str) = @_;

    # I know, I know. Why am I mixing Date::Manip and DateTime? I think
    # the DateTime interface is easier, but it doesn't have a parser

    my $date = Date::Manip::ParseDate($str);

    return DateTime->new(
        year   => UnixDate( $date, "%Y" ),
        month  => UnixDate( $date, "%m" ),
        day    => UnixDate( $date, "%d" ),
        hour   => UnixDate( $date, "%H" ),
        minute => UnixDate( $date, "%M" ),
        second => UnixDate( $date, "%S" ),
        time_zone => 'GMT'    # we always use GMT
    );
}

sub _getOffsetMonth {
    my ( $dateStr, $offsetSeconds ) = @_;

    my $dt = _parseDate($dateStr);
    $dt->add( seconds => $offsetSeconds );
    return $dt->month();
}

1;
__END__

=head1 NAME

Giovanni::Search - Perl extension for searching

=head1 SYNOPSIS

  use Giovanni::Search;

  my $search = Giovanni::Search->new(
   session_dir => ".",
   catalog     => "/path/to/varInfo.xml",
   out_file    => "mfst.search+dMOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean"
     . "+dMOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+t20030101000000_20030102235959.xml",
   missing_url => "/path/to/missingUrl.txt",
  );

  $search->search();


=head1 DESCRIPTION

Searches for data. Inputs:

1. session_dir - the session directory

2. catalog - location (full path) of the catalog file

3. out_file - output filename. The file will be put in the session directory.

4. missing_url (optional) - text file with URLS that are known to be missing.

5. time_out (optional) - timeout in seconds for getting the search results from
     a single query. Set to 90 seconds by default.

6. loginCredentials - obtained from the giovanni.cfg to be used to login (EDL)  to
     other data providers OPeNDAP systems.

7. logger (optional) - if not passed in, the code will create a logger.

=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>

=cut
