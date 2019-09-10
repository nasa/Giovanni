#$Id: Util.pm,v 1.106 2015/07/02 20:04:50 rstrub Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::Util;

use 5.008008;
use strict;
use warnings;
use File::Basename;
use URI;
use Data::UUID;
use File::Temp;
use XML::LibXML;
use Date::Manip;
use Date::Parse;
use DateTime;
use Giovanni::Data::NcFile;
use JSON;
use Fcntl qw(:flock);
use File::Basename;
use Scalar::Util qw( looks_like_number);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.00';

################################################################################
# Adds time offset in seconds
################################################################################
sub addTimeOffset {
    my ( $dateTime, $offsetInSeconds ) = @_;
    my $origTime = Date::Manip::ParseDate($dateTime);
    return undef unless defined $origTime;
    my $newTime
        = Date::Manip::DateCalc( $origTime, "$offsetInSeconds seconds" );
    return undef unless defined $newTime;
    return Date::Manip::UnixDate( $newTime, "%O" );
}
################################################################################
# Resets time based on whether it is start day or end day.
################################################################################
sub resetTime {
    my ( $dateTime, $type ) = @_;
    my $origTime = Date::Manip::ParseDate($dateTime);
    if ( $type eq 'START_DAY' ) {
        return Date::Manip::UnixDate( $origTime, "%Y-%m-%d" );
    }
    elsif ( $type eq 'END_DAY' ) {
        my $date = Date::Manip::UnixDate( $origTime, "%Y-%m-%d" );
        return Giovanni::Util::addTimeOffset( $date, 86399 );
    }
    elsif ( $type eq 'START_MONTH' ) {
        return Date::Manip::UnixDate( $origTime, "%Y-%m-01" );
    }
    elsif ( $type eq 'END_MONTH' ) {
        my $year  = Date::Manip::UnixDate( $origTime, "%Y" );
        my $month = Date::Manip::UnixDate( $origTime, "%m" );
        my $day = Date::Manip::Date_DaysInMonth( $month, $year );
        my $date = Date::Manip::ParseDate("$year-$month-$day");
        return Giovanni::Util::addTimeOffset( $date, 86399 );
    }
    return undef;
}
################################################################################
# Resets start time based on temporal resolution
################################################################################
sub resetStartTime {
    my ( $time, $tempRes ) = @_;
    if ( $tempRes eq 'daily' ) {
        return resetTime( $time, 'START_DAY' );
    }
    elsif ( $tempRes eq 'monthly' ) {
        return resetTime( $time, 'START_MONTH' );
    }
    return undef;
}
################################################################################
# Resets end time based on temporal resolution
################################################################################
sub resetEndTime {
    my ( $time, $tempRes ) = @_;
    if ( $tempRes eq 'daily' ) {
        return resetTime( $time, 'END_DAY' );
    }
    elsif ( $tempRes eq 'monthly' ) {
        return resetTime( $time, 'END_MONTH' );
    }
    return undef;
}
################################################################################
# Breaks a time range into chunks based on supplied chunk size
#
# tStart     -- date string
# tEnd       -- date string
# tChunkSize -- For fixed split boundaries N months apart, set to N*30
#               For fixed split boundaries 1 year apart, set to 365
#               For no fixed split boundaries, set to -1
# tOffset    -- (Optional) When operating in fixed split boundary mode, this
#               argument offsets the boundaries. Units in seconds.
#
################################################################################
sub chunkTimeRange {
    my ( $tStart, $tEnd, $tChunkSize, $tOffset, $logger ) = @_;

    $logger->debug("chunkTimeRange($tStart, $tEnd, $tChunkSize, $tOffset)")
        if defined $logger;

    my $t1 = Date::Manip::ParseDate($tStart);
    my $t2 = Date::Manip::ParseDate($tEnd);
    if ( ( not $t1 ) or ( not $t2 ) ) {
        warn( 1,
            "ERROR Could not parse search start time <$tStart> or end time <$tEnd> strings, can not proceed!"
        );
        return undef;
    }

    # Case of end time being equal to or less than start time
    if ( Date::Manip::Date_Cmp( $t2, $t1 ) <= 0 ) {
        my $startStr = Date::Manip::UnixDate( $t1, "%O%Z" );
        $startStr =~ s/GMT$/Z/;
        return (
            (   {   start   => $startStr,
                    end     => $startStr,
                    overlap => 'partial'
                }
            )
        );
    }

    $tOffset = 0 if !defined $tOffset;

    if ( int($tChunkSize) % 30 == 0 || $tChunkSize == 365 ) {
        ### Compute list of aligned intervals ##########################
        # holds the number of months each interval is to be, in months
        my $bSize = ( $tChunkSize == 365 ) ? 12 : int( $tChunkSize / 30 );

        # holds hash refs describing each boundary start and stop
        my @blocks = ();

        # hold a string for Date::Manip::DateCalc() that shifts by the
        # given offset
        my $tOffsetString;

        if ( $tOffset >= 0 ) {
            $tOffsetString = "+ $tOffset seconds";
        }
        else {
            my $tAbsOffset = abs($tOffset);
            $tOffsetString = "- $tAbsOffset seconds";
        }

        # compute the start of the first boundary, which must be
        # to the left of the overall start time.
        my $bStart = $tStart;
        $bStart = Date::Manip::Date_SetDateField( $bStart, "d",  1 );
        $bStart = Date::Manip::Date_SetDateField( $bStart, "h",  0 );
        $bStart = Date::Manip::Date_SetDateField( $bStart, "mn", 0 );
        $bStart = Date::Manip::Date_SetDateField( $bStart, "s",  0 );
        $bStart = Date::Manip::DateCalc( $bStart, $tOffsetString );

        while ( ( Date::Manip::UnixDate( $bStart, "%m" ) - 1 ) % $bSize ) {
            $bStart = Date::Manip::DateCalc( $bStart, "- 1 months" );
        }

        # compute the time we will compare against to terminate the
        # loop.
        my $tStop = Date::Manip::DateCalc( $tEnd, $tOffsetString );

        # compute the blocks, making sure the end of the last block
        # is after the overall end time.
        my $bCur = $bStart;

        while (1) {
            my $start = $bCur;
            my $end   = Date::Manip::DateCalc( $bCur,
                "+ $bSize months - 1 seconds" );

            my $startStr = Date::Manip::UnixDate( $start, "%O%Z" );
            my $endStr   = Date::Manip::UnixDate( $end,   "%O%Z" );

            push(
                @blocks,
                {   start   => $startStr,
                    end     => $endStr,
                    overlap => 'full'
                }
            );

            if ( Date::Manip::Date_Cmp( $end, $tStop ) > 0 ) {
                last;
            }

            if (   not( defined $end )
                or not($end)
                or not( defined $tStop )
                or not($tStop) )
            {
                warn( 1,
                    "ERROR Could not parse time strings while computing time blocks in aligned path, can not proceed!"
                );
                return undef;
            }

            $bCur = Date::Manip::DateCalc( $bCur, "+ $bSize months" );
        }

        ### Collect sublist of aligned interval in range ###############
        my @tChunkList = ();

        # compute the chunks
        foreach my $bHash (@blocks) {
            my $cond1
                = ( Date::Manip::Date_Cmp( $tStart, $bHash->{start} ) <= 0 );
            my $cond2
                = ( Date::Manip::Date_Cmp( $tEnd, $bHash->{end} ) >= 0 );

            if ( $cond1 && $cond2 ) {
                push( @tChunkList, $bHash )
                    ; #{ start=>Date::Manip::UnixDate($bHash->{start}, "%O%Z"), end=>Date::Manip::UnixDate($bHash->{end}, "%O%Z") } );
            }
        }

        ### Perform clipping for beginning/end  ########################
        # two cases here. either the entire time segment was completely
        # between two boundaries, or we can find the boundaries to clip
        # at.
        if ( scalar(@tChunkList) == 0 ) {
            my $tStartStr = Date::Manip::UnixDate( $tStart, "%O%Z" );
            my $tEndStr   = Date::Manip::UnixDate( $tEnd,   "%O%Z" );

            push(
                @tChunkList,
                {   start   => $tStartStr,
                    end     => $tEndStr,
                    overlap => 'partial'
                }
            );
        }
        else {
            foreach my $bHash (@blocks) {
                my $cond1 = (
                    Date::Manip::Date_Cmp( $bHash->{start}, $tStart ) < 0 );
                my $cond2 = (
                    Date::Manip::Date_Cmp( $tStart, $bHash->{end} ) <= 0 );

                if ( $cond1 && $cond2 ) {
                    unshift(
                        @tChunkList,
                        {   start => Date::Manip::UnixDate( $tStart, "%O%Z" ),
                            end   => $bHash->{end},
                            overlap => 'partial'
                        }
                    );
                    last;
                }
            }

            foreach my $bHash (@blocks) {
                my $cond1 = (
                    Date::Manip::Date_Cmp( $bHash->{start}, $tEnd ) <= 0 );
                my $cond2
                    = ( Date::Manip::Date_Cmp( $tEnd, $bHash->{end} ) < 0 );

                if ( $cond1 && $cond2 ) {
                    push(
                        @tChunkList,
                        {   start   => $bHash->{start},
                            end     => Date::Manip::UnixDate( $tEnd, "%O%Z" ),
                            overlap => 'partial'
                        }
                    );
                    last;
                }
            }
        }

        foreach my $tChunk (@tChunkList) {
            $tChunk->{start} =~ s/GMT$/Z/;
            $tChunk->{end} =~ s/GMT$/Z/;
        }
        return @tChunkList;
    }
    else {
        $logger->debug("taking unaligned path") if defined $logger;

        $tChunkSize *= 86400;    # work in seconds

        my @tChunkList = ();
        my $t          = $tStart;

        while (1) {
            my ( $t1, $t2 ) = (
                $t, Date::Manip::DateCalc( $t, $tChunkSize - 1 . " seconds" )
            );

            if ( Date::Manip::Date_Cmp( $t2, $tEnd ) > 0 ) {
                $t2 = $tEnd;
            }

            my ( $t1Str, $t2Str ) = (
                Date::Manip::UnixDate( $t1, "%OZ" ),
                Date::Manip::UnixDate( $t2, "%OZ" )
            );

            push( @tChunkList, { start => $t1Str, end => $t2Str } );

            $t = Date::Manip::DateCalc( $t, "$tChunkSize seconds" );

            last if ( Date::Manip::Date_Cmp( $t, $tEnd ) > 0 );
            if (   not( defined $t )
                or not($t)
                or not( defined $tEnd )
                or not($tEnd) )
            {
                warn( 1,
                    "ERROR Could not parse time strings while computing time blocks in unaligned path, can not proceed!"
                );
                return undef;
            }
        }

        foreach my $tChunk (@tChunkList) {
            $tChunk->{start} =~ s/GMT$/Z/;
            $tChunk->{end} =~ s/GMT$/Z/;
        }
        return @tChunkList;
    }
}
################################################################################
# Traverses a directory to product a listing of its contents
# Inputs:
#   $filelist : List of files with time dimension (array ref)
#   $T0, $T1  : Start and end time bounds for cropping
################################################################################
sub cropRecordsByTime {
    my ( $filelist, $T0, $T1 ) = @_;
    return $filelist unless scalar(@$filelist) > 0;

    my $first_file = $filelist->[0];
    my $last_file  = $filelist->[-1];

    # Convert time bounds to seconds
    $T0 =~ s/T|Z/ /g;
    $T1 =~ s/T|Z/ /g;
    my $T0_sec = `date -d \"$T0\" +%s`;
    my $T1_sec = `date -d \"$T1\" +%s`;
    chomp($T0_sec);
    chomp($T1_sec);
    $T0_sec = "$T0_sec." unless $T0_sec =~ /\./;
    $T1_sec = "$T1_sec." unless $T1_sec =~ /\./;

    # Crop the first file
    # No cropping if file contains a single or no time point
    my @times0 = `ncks -H -C -v time $first_file`;
    chomp(@times0);
    pop(@times0) if $times0[-1] eq "";
    my ($t0_first) = ( $times0[0] =~ /.+=(\d+)\s*$/ );
    my ($t0_last)  = ( $times0[-1] =~ /.+=(\d+)\s*$/ );
    if ( scalar(@times0) > 1
        and ( $t0_first < $T0_sec or $t0_last > $T1_sec ) )
    {

        # We need to crop
        my $fnew = basename($first_file);
        my ( $prefix, $rest ) = split( '\.', $fnew, 2 );
        $fnew = "cropped.$rest";
        `ncks -h -O -d time,$T0_sec,$T1_sec $first_file $fnew`;
        die
            "ERROR ncks failed (ncks -h -O -d time,$T0_sec,$T1_sec $first_file $fnew)\n"
            if $?;

        # Update start time
        my @times0_new = `ncks -H -C -v time $fnew`;
        chomp(@times0_new);
        my ($t0) = ( $times0_new[0] =~ /.+=(\d+)\s*$/ );
        my $start_time_new = `date +"%Y-%m-%dT%H:%M:%SZ" -d \@$t0`;
        chomp($start_time_new);
        `ncatted -O -h -a "start_time,global,o,c,$start_time_new" $fnew`;

        # Update filelist
        $filelist->[0] = $fnew;
    }

    # Crop the last file
    # No cropping if file contains a single or no time point
    my @times1 = `ncks -H -C -v time $last_file`;
    chomp(@times1);
    pop(@times1) if $times1[-1] eq "";
    my ($t1_first) = ( $times1[0] =~ /.+=(\d+)\s*$/ );
    my ($t1_last)  = ( $times1[-1] =~ /.+=(\d+)\s*$/ );
    if ( scalar(@times1) > 1
        and ( $t1_first < $T0_sec or $t1_last > $T1_sec ) )
    {

        # We need to crop
        my $fnew = basename($last_file);
        my ( $prefix, $rest ) = split( '\.', $fnew, 2 );
        $fnew = "cropped.$rest";
        if ( -e $fnew ) {

            # Same file is being right cropped
            `mv $fnew $rest`;
            die "ERROR Fail to rename file (mv $fnew $rest)\n" if $?;
            $last_file = $rest;
        }
        `ncks -h -O -d time,$T0_sec,$T1_sec $last_file $fnew`;
        die
            "ERROR ncks failed (ncks -h -O -d time,$T0_sec,$T1_sec $last_file $fnew)\n"
            if $?;

        # Update end time
        my @times1_new = `ncks -H -C -v time $fnew`;
        chomp(@times1_new);
        pop(@times1_new) if $times1_new[-1] eq "";
        my ($t1) = ( $times1_new[-1] =~ /.+=(\d+)\s*$/ );
        my $end_time_new = `date +"%Y-%m-%dT%H:%M:%SZ" -d \@$t1`;
        chomp($end_time_new);
        `ncatted -O -h -a "end_time,global,o,c,$end_time_new" $fnew`;
        $filelist->[-1] = $fnew;
    }

    return $filelist;
}
################################################################################
# Traverses a directory to product a listing of its contents
################################################################################
sub listDir {
    my ( $dir, %input ) = @_;
    $input{RECURSIVE} = 0 unless defined $input{RECURSIVE};
    my @list = ();
    if ( opendir( FH, qq($dir) ) ) {
        @list = grep { !/^\./ } readdir(FH);
        for ( my $i = 0; $i < @list; $i++ ) {
            $list[$i] = "$dir/$1" if ( $list[$i] =~ /(.+)/ );
        }
        closedir(FH);
        if ( $input{RECURSIVE} ) {
            foreach my $item (@list) {
                if ( -d $item ) {
                    my @subList = listDir( $item, %input );
                    push( @list, @subList );
                }
            }
        }
    }
    return @list;
}
################################################################################
# Create an XML document given the root element name
################################################################################
sub createXMLDocument {
    my ($rootElemName) = @_;
    return undef unless defined $rootElemName;
    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);
    my $dom = $xmlParser->parse_string( '<' . $rootElemName . '/>' );
    return $dom->documentElement();
}
################################################################################
# Write supplied content to a file
################################################################################
sub writeFile {
    my ( $file, $content, $mode ) = @_;
    local (*FH);
    $mode = '>' unless defined $mode;
    if ( open( FH, $mode, $file ) ) {
        local ($|) = 1;
        print FH $content;
        my $flag = close(FH);
        unless ($flag) {
            unlink($file);
            return 0;
        }
        return 1;
    }
    else {
        return 0;
    }
}
################################################################################
# Reads a file
################################################################################
sub readFile {
    my ($file) = @_;
    local (*FH);
    if ( open( FH, "<$file" ) ) {
        my $flag;
        if ( wantarray() ) {
            my @content = <FH>;
            $flag = close(FH);
            return @content;
        }
        elsif ( defined wantarray() ) {
            local ($/);
            my $content = <FH>;
            $flag = close(FH);
            return $content;
        }
        return undef;
    }
    else {
        if ( wantarray() ) {
            return ();
        }
        elsif ( defined wantarray() ) {
            return '';
        }
    }
}
################################################################################
# Parses an XML file
################################################################################
sub parseXMLDocument {
    my ($file) = @_;
    if ( -f $file ) {
        my $dom = undef;
        eval {
            my $xmlParser = XML::LibXML->new();
            $xmlParser->keep_blanks(0);
            $xmlParser->load_ext_dtd(0);
            $dom = $xmlParser->parse_file($file);
        };
        return defined $dom ? $dom->documentElement() : undef;
    }
    return undef;
}

# Convert a relative URL in Giovanni to fully qualified URL
sub createAbsUrl {
    my ($url) = @_;
    my $uri = URI->new($url);
    if ( $uri->scheme() ) {

        # URL is already fully qualified
        return $url;
    }
    elsif ( $url =~ /^\// ) {

        # Case of relative URL beginning with absolute path
        my $scriptUri = URI->new( $ENV{SCRIPT_URI} );

        # Case of proxied URLs
        $scriptUri->host( $ENV{HTTP_X_FORWARDED_HOST} )
            if ( exists $ENV{HTTP_X_FORWARDED_HOST} );
        $scriptUri->scheme( $ENV{HTTP_X_FORWARDED_PROTO} )
            if ( exists $ENV{HTTP_X_FORWARDED_PROTO} );

        # Get the scheme, server name and port in the URL
        $scriptUri->path('');

        # Return an absolute URL
        return $scriptUri->as_string() . $url;
    }
    else {

        # Case of relative URL with relative path
        my $scriptUrl = $ENV{SCRIPT_URI};
        if ( exists $ENV{HTTP_X_FORWARDED_HOST} ) {

            # Modify the servername for proxied requests
            my $uri = URI->new( $ENV{SCRIPT_URI} );
            $uri->host( $ENV{HTTP_X_FORWARDED_HOST} )
                if ( exists $ENV{HTTP_X_FORWARDED_HOST} );
            $uri->scheme( $ENV{HTTP_X_FORWARDED_PROTO} )
                if ( exists $ENV{HTTP_X_FORWARDED_PROTO} );
            $scriptUrl = $uri->as_string();
        }
        if ( $scriptUrl =~ /^([^\s]+\/giovanni\/)/ ) {
            return $1 . $url;
        }
    }
    return undef;
}
################################################################################
# Converts a file to URL
################################################################################
sub convertFilePathToUrl {
    my ( $file, $urlMap, $portal ) = @_;

    # Check to see if the fie exists
    if ( -f $file ) {

       # If the file exists, try to convert it to a URL using file path to URL
       # mapping
        my $str = $file;
        while ( ( ( $str = dirname($str) ) ne '/' ) and ( $str ne '' ) ) {
            if ( defined $urlMap->{$str} ) {
                if ( $file =~ /$str(.+)/ ) {
                    my $path = $1;
                    my $uri  = URI->new( $urlMap->{$str} );

                    if ( $uri->scheme() ) {

                        # Case of absolute URL
                        return $urlMap->{$str} . $path
                            . ( defined $portal ? "#$portal" : '' );
                    }
                    else {
                        return Giovanni::Util::createAbsUrl( $urlMap->{$str}
                                . $path
                                . ( defined $portal ? "#$portal" : '' ) );
                    }
                }
            }
        }
    }
    else {

        # If not a file, check whether it is a URL (by mistake or design)
        my $ui = URI->new($file);
        if ( defined $ui->scheme ) {
            return $file;
        }
    }
    return undef;
}

################################################################################
# Converts URL to file path based on mapping
sub convertUrlToFilePath {
    my ( $url, $urlMap ) = @_;

    my %urlToFileMap = reverse(%$urlMap);

    # Case of exact match
    foreach my $str ( reverse sort keys %urlToFileMap ) {
        return $urlToFileMap{$str} . $1 if ( $url =~ /^$str([^#]*)/ );
    }

    # Case of relative URLs specified in the
    foreach my $str ( reverse sort keys %urlToFileMap ) {
        my $uri = URI->new($str);

        # Continue if the URL in the supplied mapping is an aboslute URL
        next if ( $uri->scheme() );
        if ( $str =~ /^\// ) {

 # Case of URL in the supplied mapping being a relative URL with absolute path
            my $scriptUri = URI->new( $ENV{SCRIPT_URI} );
            $scriptUri->path($str);
            my $newUrl = $scriptUri->as_string();
            return $urlToFileMap{$str} . $1 if ( $url =~ /$newUrl(.*)/ );
        }
        else {

 # Case of URL in the supplied mapping being a relative URL with relative path
            if ( $ENV{SCRIPT_URI} =~ /(^[^\s]+\/giovanni\/$str).*/ ) {
                my $newUrl = $1;
                return $urlToFileMap{$str} . $1 if ( $url =~ /$newUrl(.*)/ );
            }
        }

        return $urlToFileMap{$str} . $1 if ( $url =~ /$str(.*)/ );
    }

    return undef;
}
################################################################################
# Moved this from service_manager, so that individual methods could
# return an error to the Gui.
sub exit_with_error {
    my ( $message, $format ) = @_;
    my $xmlParser  = XML::LibXML->new();
    my $dom        = $xmlParser->parse_string('<session />');
    my $styleSheet = "../../giovanni/xsl/GiovanniResponse.xsl";
    $dom->insertProcessingInstruction( 'xml-stylesheet',
        qq(type="text/xsl" href="$styleSheet") );
    my $doc = $dom->documentElement();
    $doc->appendTextChild( 'error', $message );
    $format = defined $format ? lc($format) : 'xml';

    if ( $format eq 'xml' ) {
        print $dom->toString(2);
    }
    elsif ( $format eq 'json' ) {
        my $xml2Json = XML::XML2JSON->new(
            module           => 'JSON::XS',
            pretty           => 1,
            attribute_prefix => '',
            content_key      => 'value',
            force_array      => 1
        );
        my $jsonObj = $xml2Json->dom2obj($dom);
        print $xml2Json->obj2json($jsonObj);
    }
    exit(0);
}
################################################################################
sub getDataTransforms {
    my ($data) = @_;

    #Make a copy
    my $dataStr = $data;

    #Following statement is there to support when multiple data sets are
    #specified by repeating parameter name in CGI query string.
    $dataStr =~ s/\0/,/g;

    #List to hold user supplied variables
    my @varList = ();

    #List to hold user supplied filters
    my @transformList = ();
    while ( $dataStr =~ s/([^,[]+(\[[^\]]*\])?)// ) {

        #Strip leading and trailing white space
        my $varId = $1;
        $varId =~ s/^\s+|\s+$//g;

        #Variable transformation are represented as var[transforms]
        if ( $varId =~ /([^\[]+)(\[(.*)\])*/ ) {
            push( @varList, $1 );
            if ( defined $2 ) {

                #Case of variable transforms
                my $transform = $2;

                #Strip outer brackets and split it in to a list using comma
                #as the delimiter
                $transform =~ s/^\[|\]$//g;

                #Strip beginning and trailing white spaces for individual
                #transforms
                push(
                    @transformList,
                    [   map { $_ =~ s/^\s+|\s+$//g; $_ }
                            split( /,/, $transform )
                    ]
                );
            }
            else {

                #Case of no transforms; set to an empty list
                push( @transformList, [] );
            }
        }
    }
    return ( { data => \@varList, transform => \@transformList } );
}
################################################################################
sub createLogger {
    my ( $logFile, $level ) = @_;
    my $logger = Log::Log4perl::get_logger();
    $level = 'info' unless defined $level;
    $level
        = ( $level eq 'debug' )
        ? $Log::Log4perl::DEBUG
        : $Log::Log4perl::INFO;
    $logger->level($level);

    if ( defined $logFile ) {
        my $layout =

            #Custom layout to match log4j used in Kepler AG actors
            Log::Log4perl::Layout::PatternLayout->new(
            "%d{yyyy-MM-dd HH:mm:ss} - [%p ] - %X{component} - %m%n");

        my $appender = Log::Log4perl::Appender->new(
            "Log::Dispatch::File",
            filename => $logFile,
            mode     => "append"
        );
        $appender->layout($layout);
        $logger->add_appender($appender);
    }
    return $logger;
}
################################################################################
sub isUUID {
    my ($input) = @_;
    my $id = Data::UUID->new();
    my $uuid;

    #See if the input is a valid UUID
    eval { $uuid = $id->from_string($input); };
    return 0 unless defined $uuid;
    return 1;
}
################################################################################
# Needs giovanni.cfg for temp dir location
# returns XML::LibXML document
#
sub getNcml {
    my ($dataFile) = @_;
    my ( $ncmlFH, $ncmlFile ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $GIOVANNI::SESSION_LOCATION,
        SUFFIX => ".ncml",
        UNLINK => 1
    );
    my $ncmlLog = `ncdump -x $dataFile > $ncmlFile`;
    if ($?) {
        print STDERR "Failed to read metadata for " . basename($dataFile);
        close($ncmlFH);
        return undef;
    }
    close($ncmlFH);
# Look in the data attributes; only variables with quantity_type attribute are
# considered data variables
    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);
    my $dom;
    eval { $dom = $xmlParser->parse_file($ncmlFile); };
    unlink $ncmlFile if ( -f $ncmlFile );
    return undef unless defined $dom;
    my $doc = $dom->documentElement();
    return $doc;
}

sub getNetcdfGlobalAttributes {
    my ($dataFile) = @_;

    my %attrInfo = ();
    my $doc      = Giovanni::Util::getNcml($dataFile);
    return %attrInfo unless defined $doc;

    my $xc = XML::LibXML::XPathContext->new($doc);

    # Extract data fields that need to be plotted
    $xc->registerNs( 'ncml',
        'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );

    # Look for variables with quantity_type attribute
    my @nodeList = $xc->findnodes('/ncml:netcdf/ncml:attribute[@name]');
    foreach my $node (@nodeList) {
        my $name = $node->getAttribute('name');
        next unless defined $name;
        my $value = $node->getAttribute('value');
        $attrInfo{$name} = defined $value ? $value : undef;
    }
    return %attrInfo;
}

sub getNetcdfDataVariables {
    my ($dataFile) = @_;

    # Holder for variable info: first level keys are short names
    my %varInfo = ();

    my $doc = Giovanni::Util::getNcml($dataFile);
    return %varInfo unless defined $doc;

    my $xc = XML::LibXML::XPathContext->new($doc);

    # Extract data fields that need to be plotted
    $xc->registerNs( 'ncml',
        'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );

    # Look for variables with quantity_type attribute
    my @nodes = $xc->findnodes(
        '/ncml:netcdf/ncml:variable/ncml:attribute[@name="quantity_type"]');

    # Find layer names
    foreach my $node (@nodes) {
        my $varNode = $node->parentNode();

        # Get variable name
        my $shortName = $varNode->getAttribute('name');
        next if ( $shortName eq "" || !defined $shortName );

        # Get variable long name
        my $longName
            = $xc->findvalue( '//ncml:variable[@name="'
                . $shortName
                . '"]/ncml:attribute[@name="long_name"]/@value' );
        $varInfo{$shortName}{title} = $longName;

        # Get the data type
        my $type = $xc->findvalue(
            '//ncml:variable[@name="' . $shortName . '"]/@type' );
        $varInfo{$shortName}{type} = $type if ( $type ne '' );

        my $quantityType
            = $xc->findvalue( '//ncml:variable[@name="'
                . $shortName
                . '"]/ncml:attribute[@name="quantity_type"]/@value' );
        $varInfo{$shortName}{quantity_type} = $quantityType;

        my @attrNodeList = $xc->findnodes(
            '//ncml:variable[@name="' . $shortName . '"]/ncml:attribute' );
        foreach my $attrNode (@attrNodeList) {
            my $attrName  = $attrNode->getAttribute('name');
            my $attrValue = $attrNode->getAttribute('value');
            $varInfo{$shortName}{$attrName} = $attrValue;
        }

        # Find time
        my ($time) = `ncks -H -C -v time $dataFile`;
        if ( defined $time ) {
            chomp($time);
            if ( $time =~ /^time\[0\]\s*=\s*(.+)\s*$/ ) {
                my $t = $1;
                $t =~ s/^\s*|\s*$//g;
                $varInfo{$shortName}{time} = $t;
            }
        }
    }
    return %varInfo;
}

sub getNetcdfDataType {
    my ( $dataFileName, $varName ) = @_;
    my $dataType    = 0;
    my %varInfo     = getNetcdfDataVariables($dataFileName);
    my $type        = $varInfo{$varName}{type};
    my $scaleFactor = $varInfo{$varName}{scale_factor};
    my $addOffset   = $varInfo{$varName}{add_offset};
    if ( defined $type ) {
        if ( $type eq "int" || $type eq "short" || $type eq "long" ) {
            $dataType = 1;
            if ( defined $scaleFactor ) {
                if ( $scaleFactor != 1 ) {
                    $dataType = 0;
                }
            }
            if ( defined $addOffset ) {
                if ( !$addOffset =~ m/^[+-]?\d+$/ ) {
                    $dataType = 0;
                }
            }
        }
    }
    return $dataType;
}

sub getNetcdfDataRange {
    my ( $dataFileName, $varName ) = @_;
    return Giovanni::Data::NcFile::getDataRange( $dataFileName, $varName );
}

# Merges U & V components
sub mergeVectorComponents {
    my ( $sessionDir, $infile, $uname, $vname ) = @_;
    die "ERROR: incomplete inputs for merging u v ($uname,$vname,$infile)\n"
        unless $uname
        and $vname
        and $infile;
    if ( not defined $sessionDir ) {
        $sessionDir = $GIOVANNI::SESSION_LOCATION
            if defined $GIOVANNI::SESSION_LOCATION;
    }
    my ( $uFH, $uFile ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".nc",
        UNLINK => 1
    );
    my ( $fFH, $vFile ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".nc",
        UNLINK => 1
    );
    my ( $mFH, $mergedFile ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".nc",
        UNLINK => 1
    );

    # Create a variable name for the merged field
    my $L = length($uname);
    my $common_str;
    for ( my $i = 1; $i < $L; $i++ ) {
        $common_str = substr( $uname, 0, $i );
        last unless $vname =~ /^$common_str/;
    }
    my $merged_name = $common_str . "_merged";

    # Merge u and v
    `ncks -h -O -v $uname $infile $uFile`;
    if ($?) {
        print STDERR
            "ERROR ncks failed (ncks -h -O -v $uname $infile $uFile)\n";
        return undef;
    }
    `ncks -h -O -v $vname $infile $vFile`;
    if ($?) {
        print STDERR
            "ERROR ncks failed (ncks -h -O -v $vname $infile $vFile)\n";
        return undef;
    }
    `ncrename -v $uname,$merged_name $uFile`;
    `ncrename -v $vname,$merged_name $vFile`;
    `ncecat -O $uFile $vFile $mergedFile`;
    my $outFile = $sessionDir . '/' . File::Basename::basename($infile);
    $outFile =~ s/\.nc$/\.tif/i;

    # Translate NetCDF into GeoTiff
    `gdal_translate -of GTiff $mergedFile $outFile`;
    return $outFile;
}

#########################################################
## parse_tfile() -- to parse the start/end time from the time manifest file
##     parameters:     time manifest file in xml
##     return:  start time and end time
## Author:
##		Xiaopeng Hu
#########################################################
sub parse_tfile {
    my ($tfile)   = @_;
    my $startTime = "";
    my $endTime   = "";

    # Make sure zfile is not empty
    if ( !-s $tfile ) {
        print STDERR "WARN t-file $tfile empty\n";
        return {};
    }

    # Parse zfile
    my $parser = XML::LibXML->new();
    my $xml    = $parser->parse_file($tfile);

    ## to extract the start time
    my @start_nodes = $xml->findnodes('/manifest/starttime');
    foreach my $n (@start_nodes) {
        $startTime = $n->textContent();
    }
    ## to extract the start time
    my @end_nodes = $xml->findnodes('/manifest/endtime');
    foreach my $n (@end_nodes) {
        $endTime = $n->textContent();
    }

    return $startTime, $endTime;
}
#############################################
## Name: getQuantityTypeMinMax -- to retrieve the min/max values from a file array
## Arguments:
##		@datafiles -- a array of data files
## Return:
##      %mmHash -- a hash of quantity_type containing a hash of min/max value
## Author:
##		Xiaopeng Hu
############################################
sub getQuantityTypeMinMax {
    my (@datafiles) = @_;

    my %mmHash = ();

    ## loop thru files
    foreach my $file (@datafiles) {
        ## to extract variable name and its relevant attributes
        my %varInfo = getNetcdfDataVariables($file);
        my $fpath   = dirname($file);

        ## to extract the quantity_type from the variable
        foreach my $vkey ( keys %varInfo ) {
            my $quantityType = $varInfo{$vkey}{quantity_type};

#Cloned from NcFile.pm to keep rounding consistend across the modules - Maksym 02/10/15
# Lookup appropriate output format for that variable type
            my $varType = $varInfo{$vkey}{type};
            my %format
                = ( 'int' => '%d', 'float' => '%g', 'double' => '%lg' );
            unless ( $format{$varType} ) {
                warn "ERROR unsupported variable type in dump_var1d\n";
                return;
            }
            my $format = $format{$varType};

            ## to find the min/max values since we have the file, the variable, and the quantity_type,
            my $tmpfile = File::Temp->new();

# min() / max() in NCO does not work properly on dimension variables (https://sourceforge.net/p/nco/bugs/78/)
# gsl_stats_min(), on the other hand, does work on dimension variables, but does not work with fill values and can't handle
# multiple dimensions. So, let's use gsl_stats_min on time/lat/lon and the regulat min on everything else
            my $mmcommand
                = "ncap2 -v -O -o $tmpfile -s 'ymin=min($vkey * 1.0);ymax=max($vkey * 1.0);print(ymin);print(ymax);' $file";
            $mmcommand
                = "ncap2 -v -O -o $tmpfile -s 'ymin=$vkey.gsl_stats_min() * 1.0;ymax=$vkey.gsl_stats_max() * 1.0;print(ymin);print(ymax);' $file"
                if ( $vkey eq 'time' || $vkey eq 'lat' || $vkey eq 'lon' );

            eval {
                my $output = `$mmcommand`;
                my @outs = split( /\n/, $output );
                if ($?) {
                    print STDERR "Failed to find min max: $output\n";
                }
                foreach my $m (@outs) {
                    chomp($m);
                    if ( $m =~ /ymin/g ) {
                        $m =~ s/ymin//gi;
                        $m =~ s/\=//g;
                        $m =~ s/\s//g;
                        $m = sprintf "$format", $m;
                        if ( !defined( $mmHash{$quantityType}{min} ) ) {
                            $mmHash{$quantityType}{min} = $m;
                        }
                        else {
                            $mmHash{$quantityType}{min}
                                = ( $mmHash{$quantityType}{min} > $m )
                                ? $m
                                : $mmHash{$quantityType}{min};
                        }

                    }
                    if ( $m =~ /ymax/g ) {
                        $m =~ s/ymax//gi;
                        $m =~ s/\=//g;
                        $m =~ s/\s//g;
                        $m = sprintf "$format", $m;
                        if ( !defined( $mmHash{$quantityType}{max} ) ) {
                            $mmHash{$quantityType}{max} = $m;
                        }
                        else {
                            $mmHash{$quantityType}{max}
                                = ( $mmHash{$quantityType}{max} < $m )
                                ? $m
                                : $mmHash{$quantityType}{max};
                        }
                    }
                }
            };
            if ($@) {
                print STDERR
                    "ERROR failed to run the min/max command: $mmcommand \n";
            }

        }
    }
    return %mmHash;
}

############################
# Removes white space at the beginning and end of lines. Stolen from
# perlmonks trim() magic. http://www.perlmonks.org/?node_id=36684
#
# trim;               # trims $_ inplace
# $new = trim;        # trims (and returns) a copy of $_
# trim $str;          # trims $str inplace
# $new = trim $str;   # trims (and returns) a copy of $str
# trim @list;         # trims @list inplace
# @new = trim @list;  # trims (and returns) a copy of @list
############################
sub trim {
    @_ = $_ if not @_ and defined wantarray;
    @_ = @_ if defined wantarray;
    for ( @_ ? @_ : $_ ) { s/^\s+//, s/\s+$// }
    return wantarray ? @_ : $_[0] if defined wantarray;
}

#############################################
# Name: bbox2string -- Converts bounding box (West,South,East,North)
#   to a string usable in filename patterns
# Arguments:
#   $west,
# Return:
#   String
# Author:
#		M. Hegde
############################################
sub bbox2string {
    my ($bbox) = @_;
    my @bbox = split( ',', $bbox );
    return '' unless ( @bbox == 4 );
    return sprintf(
        "%.3f%s_%.3f%s_%.3f%s_%.3f%s",
        abs( $bbox[0] ),
        ( $bbox[0] < 0. ) ? 'W' : 'E',
        abs( $bbox[1] ),
        ( $bbox[1] < 0. ) ? 'S' : 'N',
        abs( $bbox[2] ),
        ( $bbox[2] < 0. ) ? 'W' : 'E',
        abs( $bbox[3] ),
        ( $bbox[3] < 0. ) ? 'S' : 'N'
    );
}

sub parse_bbox {
    my $bbox_arg = shift;
    my $pattern  = '([\d.+\-]+)';    # Usable in taint mode
    my ( $west, $south, $east, $north )
        = ( $bbox_arg =~ /$pattern, *$pattern, *$pattern, *$pattern/ );
    return ( $west, $south, $east, $north );
}
#############################################
# Name: getSeasonLabels -- Gets label(s) for specified seasons
#   to string
# Arguments:
#		Month (MM) or Season (DJF, MAM, JJA, SON)
# Return:
#   String list
# Author:
#		M. Hegde
############################################
sub getSeasonLabels {
    my ($seasonStr) = @_;
    my @seasonList = split( /,/, $seasonStr );
    my @labelList  = ();
    my @monthList  = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    foreach my $season (@seasonList) {
        if ( $season =~ /^\d{2}$/ ) {
            push( @labelList, @monthList[ int($season) - 1 ] );
        }
        elsif ( $season =~ /^DJF$/ ) {
            push( @labelList, 'Dec-Jan-Feb' . "($season)" );
        }
        elsif ( $season =~ /^MAM$/ ) {
            push( @labelList, 'Mar-Apr-May' . "($season)" );
        }
        elsif ( $season =~ /^JJA$/ ) {
            push( @labelList, 'Jun-Jul-Aug' . "($season)" );
        }
        elsif ( $season =~ /^SON$/ ) {
            push( @labelList, 'Sep-Oct-Nov' . "($season)" );
        }
    }
    return @labelList;
}
#############################################
# Name: getDataFilesFromManifest -- Gets data files in manifest as a hash ref
# Arguments:
#   Manifest file name
# Return:
#   A hash ref with title, data as the key. The value for key="title" is the
#   result title. The value for key="data" is the list ref to list of data files.
# Author:
#		M. Hegde
############################################
sub getDataFilesFromManifest {
    my ($file) = @_;

    my $dataHashRef = { title => "", data => [] };
    my $manifestDoc = Giovanni::Util::parseXMLDocument($file);
    return $dataHashRef unless defined $manifestDoc;
    my $title = $manifestDoc->findvalue('/manifest/@title');
    $dataHashRef->{title} = $title if ( defined $title );
    foreach my $fileNode ( $manifestDoc->findnodes('fileList/file') ) {

        # Get the file path either via attribute or text content
        my $path = $fileNode->getAttribute('path');
        unless ( defined $path ) {
            $path = $fileNode->textContent();
        }
        next unless defined $path;

        # Remove leading/trailing white space
        $path =~ s/^\s+|\s+$//g;

        # Accumulate file names only if the file exists
        next unless ( -e $path );
        push( @{ $dataHashRef->{data} }, $path );
    }
    return $dataHashRef;
}
#############################################
# Name: createXMLElement -- Create an XML element
# Arguments:
#   element name, Hash whose keys are names of elements children and values
#   are text contents of children
# Return:
#   XML::LibXML::Element
# Author:
#		M. Hegde
############################################
sub createXMLElement {
    my ( $elementName, @attrList ) = @_;
    my $elem = XML::LibXML::Element->new($elementName);
    my $startIndex = ( @attrList % 2 ) == 0 ? 0 : 1;

    # Case of (element name, element text content)
    $elem->appendTextNode( $attrList[0] ) if $startIndex;
    for ( my $i = $startIndex; $i < @attrList; $i += 2 ) {

# Case of (element name, [element text content], ( text child name => text child content, ....))
        $elem->appendTextChild( $attrList[$i], $attrList[ $i + 1 ] );
    }
    return $elem;
}
#############################################
# Name: compare -- Compares two Perl data types
# Arguments:
#   Two data types (scalar or ref)
# Return:
#   0/1 (match/don't match)
# Author:
#		M. Hegde
############################################
sub compare {
    my ( $src, $tar ) = @_;
    my ( $refSrc, $refTar ) = ( ref($src), ref($tar) );
    if ( $refSrc eq '' && $refTar eq '' ) {

        # Case of two scalars
        return $src eq $tar ? 1 : 0;
    }
    elsif ( $refSrc eq 'ARRAY' && $refTar eq 'ARRAY' ) {

        # Case of list references
        # Return 0 if lengths don't match
        return 0 unless ( @{$src} == @{$tar} );
        my %refHash = map { $_ => 1 } @{$src};
        my %tarHash = map { $_ => 1 } @{$tar};
        foreach my $key ( keys %refHash ) {

            # Return 0 if any element doesn't match
            return 0 unless exists $tarHash{$key};
        }

        # Lists match, return 1
        return 1;
    }
    elsif ( $refSrc eq 'HASH' && $refTar eq 'HASH' ) {

        # Case of hash references
        # If number of keys don't match, return 0
        return 0 unless ( scalar( keys %$src ) != scalar( keys %$tar ) );
        foreach my $key ( keys %$src ) {

            # Return 0 if any hash member doesn't match
            return 0 unless exists $tar->{$key};
            return 0 unless ( $src->{$key} ne $tar->{$key} );
        }

        # Hashes match, return 1
        return 1;
    }
    return 0;
}

#############################################
# Name: findPath -- Finds the location of a file
# Arguments:
#   Parent directory to search from (optional)
# Return:
#   Full file path or undef
# Author:
#		M. Hegde
############################################
sub findPath {
    my ($file) = @_;
    foreach my $dir ( split( /:/, $ENV{PATH} ) ) {
        my $path = "$dir/$file";
        return $path if -f $path;
    }
    return undef;
}
#############################################
# Name: getLabelSize
#   Given a scalar, returns the size (width, height) in
#   pixels  required to hold the scalar
# Arguments:
#   Scalar, Optionally a hash containing font specs.
# Return:
#   Width and height
# Author:
#		M. Hegde
############################################
sub getLabelSize {
    my ( $label, %font ) = @_;

    return ( 0, 0 ) if ( "$label" eq '' );

    # Set default font family, size
    $font{family} = 'Helvetica' unless exists $font{family};
    $font{size}   = 12          unless exists $font{size};

    my $command
        = "convert -debug annotate xc: -font $font{family} -pointsize $font{size} -annotate 0 $label null: 2>&1 | grep width";
    my $str      = `$command`;
    my ($width)  = $str =~ /width:\s(\d*\.*\d*)/;
    my ($height) = $str =~ /height:\s(\d*\.*\d*)/;

    # Retrun the image size
    return ( $width, $height );
}
#############################################
## Name: getFontSize
##   Given a width, returns the proper font size for a specified label
##
## Arguments:
##   width, label, Optionally a hash containing font specs.
## Return:
##   font size
## Author:
##               M. Peisheng
#############################################
sub getFontSize {
    my ( $totalWidth, $labelText, %options ) = @_;
    my $fSize = defined $options{font_size} ? $options{font_size} : 14;
    for ( ; $fSize >= 6; $fSize-- ) {
        my ($labelSize)
            = Giovanni::Util::getLabelSize( $labelText, ( size => $fSize ) );
        last if ( $labelSize <= $totalWidth );
    }
    return $fSize;
}

#############################################
# Name: getAnimationDataMinMax
#   Given a dbf file containing timed WMS, returns the data (min,max)
# Arguments:
#   DBF file name and optionally, layer (=data field) name
# Return:
#   A hash whose keys are layer names and values are (min,max) array references
# Author:
#		M. Hegde
############################################
sub getAnimationDataMinMax {
    my ( $dbfName, $layerName ) = @_;

    my %dataMinMax   = ();
    my $cmd          = "dbfdump --fields LOCATION $dbfName";
    my @dataFileList = `$cmd`;
    if ($?) {
        print STDERR "Failed to find data files in dbf file: $cmd\n";
        return %dataMinMax;
    }
    chomp(@dataFileList);
    my @dataFieldList = defined $layerName ? ($layerName) : ();
    foreach my $dataFile (@dataFileList) {
        $dataFile = ( $dataFile =~ /^(\S+)$/ ? $1 : undef );
        next unless ( defined $dataFile && ( -f $dataFile ) );
        unless (@dataFieldList) {
            my %varInfo = Giovanni::Util::getNetcdfDataVariables($dataFile);
            @dataFieldList = keys %varInfo;
        }
        foreach my $dataField (@dataFieldList) {
            my ( $min, $max )
                = Giovanni::Util::getNetcdfDataRange( $dataFile, $dataField );
            next unless ( defined $min and defined $max );
            if ( exists $dataMinMax{$dataField} ) {
                $dataMinMax{$dataField}{min} = $min
                    if ( $dataMinMax{$dataField}{min} > $min );
                $dataMinMax{$dataField}{max} = $max
                    if ( $dataMinMax{$dataField}{max} < $max );
            }
            else {
                $dataMinMax{$dataField}{min} = $min;
                $dataMinMax{$dataField}{max} = $max;
            }
        }
    }
    return %dataMinMax;
}

# Given a session directory, returns session IDs
sub getSessionIds {
    my ($sessionDir) = @_;
    my $inFileDir = ( -d $sessionDir ) ? $sessionDir : dirname($sessionDir);
    $inFileDir =~ s/\/+/\//g;
    $inFileDir =~ s/\/$//;
    my @dirList = split( '/', $inFileDir );
    my ( $session, $resultset, $result )
        = ( $dirList[-3], $dirList[-2], $dirList[-1] );
    return ( $session, $resultset, $result );
}

# Converts CF-1 compliant time to date time string
# Example: cf2datetime( 200, "seconds since 1980-01-01")
sub cf2datetime {
    my ( $timeStr, $cfUnit ) = @_;

    # Parse the "since" statement in the reference time
    my ( $unit, $since ) = split( '\s+since\s+', $cfUnit );
    $unit =~ s/^\s+|\s+$//g;
    $since =~ s/^\s+|\s+$//g;
    return undef unless defined $since;
    my $sinceEpoch = Date::Parse::str2time($since);
    return undef unless defined $sinceEpoch;
    my $time;
    eval { $time = DateTime->from_epoch( epoch => $sinceEpoch ); };
    return undef unless defined $time;
    eval { $time->add( $unit => $timeStr ); };
    return undef if ($@);
    return $time->datetime() . 'Z';
}

# Breaks data time range into chunks
sub chunkDataTimeRange {

    # dataStartTime
    # dataEndTime
    # dataTemporalResolution: daily, monthly
    # searchStartTime
    # searchEndTime
    # searchIntervalDays: in days
    # dataStartTimeOffset: in seconds
    # dataEndTimeOffset: in seconds
    my (%arg) = @_;

    # Use a logger if defined
    my $logger = defined $arg{logger} ? $arg{logger} : undef;

    # A list to hold time chunks
    my @timeChunkList = ();

    my $dataStartTime   = $arg{dataStartTime};
    my $dataEndTime     = $arg{dataEndTime};
    my $searchStartTime = $arg{searchStartTime};
    my $searchEndTime   = $arg{searchEndTime};

    $dataStartTime =~ s/Z/T00:00:00Z/
        if index( $dataStartTime, "Z" ) != -1
        and index( $dataStartTime, "T" ) == -1;
    $dataEndTime =~ s/Z/T23:59:59Z/
        if index( $dataEndTime, "Z" ) != -1
        and index( $dataEndTime, "T" ) == -1;
    $searchStartTime =~ s/Z/T00:00:00Z/
        if index( $searchStartTime, "Z" ) != -1
        and index( $searchStartTime, "T" ) == -1;
    $searchEndTime =~ s/Z/T23:59:59Z/

        if index( $searchEndTime, "Z" ) != -1
        and index( $searchEndTime, "T" ) == -1;

    if (   not( Date::Manip::ParseDate($dataStartTime) )
        or not( Date::Manip::ParseDate($dataEndTime) ) )
    {
        warn( 1,
            "ERROR Could not parse data start time <$dataStartTime> or end time <$dataEndTime> strings, can not proceed!"
        );
        return 1;
    }
    if (   not( Date::Manip::ParseDate($searchStartTime) )
        or not( Date::Manip::ParseDate($searchEndTime) ) )
    {
        warn( 1,
            "ERROR Could not parse search start time <$searchStartTime> or end time <$searchEndTime> strings, can not proceed!"
        );
        return 1;
    }

    # Make sure that the search time has an overlap with data time range
    if ( Date_Cmp( $searchStartTime, $searchEndTime ) > 0 ) {

        # Case of search start time > search end time
        $logger->info(
            "USER_MSG Input Error: Search start time must not be after end time"
        ) if defined $logger;
        return @timeChunkList;
    }
    if ( Date_Cmp( $searchStartTime, $dataEndTime ) > 0 ) {

        # Case of search start time > data end time
        $logger->info(
            "USER_MSG Input Error: Start time must not be after $arg{dataEndTime}"
        ) if defined $logger;
        return @timeChunkList;
    }
    if ( Date_Cmp( $searchEndTime, $dataStartTime ) < 0 ) {

        # Case of search end time < data start time
        $logger->info(
            "USER_MSG Input Error: End time must not be before $arg{dataStartTime}"
        ) if defined $logger;
        return @timeChunkList;
    }

# Currently, nominal start and end time notion exists for monthly and daily data only
# Reset start and end time based on data temporal resolution
    if (exists $arg{dataTemporalResolution}
        && (   $arg{dataTemporalResolution} eq 'daily'
            || $arg{dataTemporalResolution} eq 'monthly' )
        )
    {
        $searchStartTime = Giovanni::Util::resetStartTime( $searchStartTime,
            $arg{dataTemporalResolution} );
        $searchEndTime = Giovanni::Util::resetEndTime( $searchEndTime,
            $arg{dataTemporalResolution} );
    }

    $searchStartTime
        = Giovanni::Util::addTimeOffset( $searchStartTime,
        $arg{dataStartTimeOffset} )
        if ( defined $searchStartTime && exists $arg{dataStartTimeOffset} );
    $searchEndTime
        = Giovanni::Util::addTimeOffset( $searchEndTime,
        $arg{dataEndTimeOffset} )
        if ( defined $searchEndTime && exists $arg{dataEndTimeOffset} );

    # Default search interval days is 365 if not supplied
    my $searchIntervalDays
        = exists $arg{searchIntervalDays} ? $arg{searchIntervalDays} : 365;
    $searchStartTime
        = Date::Manip::Date_Cmp( $dataStartTime, $searchStartTime ) > 0
        ? $dataStartTime
        : $searchStartTime;
    $searchEndTime
        = Date::Manip::Date_Cmp( $dataEndTime, $searchEndTime ) < 0
        ? $dataEndTime
        : $searchEndTime;

    my $boundaryOffset = $arg{dataStartTimeOffset} || 0;
    $logger->debug(
        "Calling chunkTimeRange with ($searchStartTime, $searchEndTime, $searchIntervalDays, $boundaryOffset)"
    ) if defined $logger;

    @timeChunkList
        = Giovanni::Util::chunkTimeRange( $searchStartTime, $searchEndTime,
        $searchIntervalDays, $boundaryOffset, $logger );
    return @timeChunkList;
}

sub getTimeRangeFromFileName {
    my ( $filePath, $verbose ) = @_;
    my $fname              = basename $filePath;
    my $rangebeginningtime = "00:00:00";
    my $rangeendingtime    = "23:59:59";
    my ( $startTimeAttribute, $endTimeAttribute );
    my $time;
    my $datestring = '';
    my $enddatestring;
    my $conventionsNotFound = 1;    ## not found

    ## date from OMI filename
    if ( $fname =~ /_(\d{4})m(\d{2})(\d{2})/ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO datestring for OMI = $datestring \n" if ($verbose);
    }
    ## date from airs esgf: ta_AIRS_L3_RetStd-v5_200209-201105.AIRS_L3_RetStd_005_ta.nc
    elsif ( $fname =~ /_(\d{4})(\d{2})-(\d{4})(\d{2})/ ) {
        $datestring = "$1-$2-01";
        my $endmonth = $4;
        my $endyear  = $3;
        my $endday   = Date::Manip::Date_DaysInMonth( $endmonth, $endyear );
        $enddatestring = "$endyear-$endmonth-$endday";
        print STDERR "INFO datestring for ESGF = $datestring \n"
            if ($verbose);
    }
    ## date from TRMM and AIRNOW filenames
    elsif ( $fname =~ /\.(\d{4})\.(\d{2})\.(\d{2})\./ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO datestring for (TRMM|AIRNOW) = $datestring \n"
            if ($verbose);
    }
    ## date from TRMM 3-Hourly filenames
    elsif ( $fname =~ /\.(\d{4})(\d{2})(\d{2})\.(\d{2})\./ ) {
        $datestring = "$1-$2-$3T$4:00";
        $rangebeginningtime =~ s/00/$4/;
        print STDERR "INFO datestring for (TRMM|AIRNOW) = $datestring \n"
            if ($verbose);
    }
    ## date from TRMM v6 filenames
    elsif ( $fname =~ /\.(\d{2})(\d{2})(\d{2})\.\d\w?\./ ) {
        my $year = $1;
        if ( $year < 50 ) {
            $year = "20" . $year;
        }
        else {
            $year = "19" . $year;
        }
        $datestring = "$year-$2-$3";
        print STDERR "INFO datestring for OMI = $datestring \n" if ($verbose);
    }
    ## date from MODIS filename
    elsif ( $fname =~ /\.A(\d{4})(\d{3})\./ ) {
        my $year = $1;
        my $dt
            = DateTime->from_day_of_year( year => $year, day_of_year => $2 );
        $datestring
            = sprintf( "%04d-%02d-%02d", $year, $dt->month(), $dt->day() );
        print STDERR "INFO datestring for MODIS = $datestring \n"
            if ($verbose);
    }

    # salinity, year and jday
    elsif ( $fname =~ /^.*?[A-Z]+(\d{4})(\d{3})(\d{4})(\d{3})\.*/ ) {
        my $year = $1;
        my $dt
            = DateTime->from_day_of_year( year => $year, day_of_year => $2 );
        $datestring
            = sprintf( "%04d-%02d-%02d", $year, $dt->month(), $dt->day() );
        print STDERR "INFO datestring for MODIS = $datestring \n"
            if ($verbose);
    }
    ## date from SeaWIFS filename
    ## YEAR-MM format
    # _(\d{4})m(\d{2})(\d{2})
    elsif ( $fname =~ /_(\d{4})(\d{2})(\d{2})*_v/ ) {
        $datestring = "$1-$2";
        if ( defined($3) ) {
            $datestring .= "-$3";
        }
        else {
            $datestring .= "-01";
        }
        print STDERR "INFO datestring for SeaWiFS = $datestring \n"
            if ($verbose);
    }
    ######### date from MISR #####
    elsif ( $fname =~ /_(\w{3})_(\d{2})_(\d{4})_/ ) {
        my %months = (
            'JAN' => '01',
            'FEB' => '02',
            'MAR' => '03',
            'APR' => '04',
            'MAY' => '05',
            'JUN' => '06',
            'JUL' => '07',
            'AUG' => '08',
            'SEP' => '09',
            'OCT' => '10',
            'NOV' => '11',
            'DEC' => '12'
        );
        $datestring = "$3-$months{$1}-$2";
        print STDERR "INFO datestring for MISR = $datestring \n"
            if ($verbose);
    }

    ####### date from GoCart ####
    elsif ( $fname =~ /_(\d{4})(\d{2})(\d{2})\.nc/ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO datestring for GoCart = $datestring \n"
            if ($verbose);
    }
    ## date from NLDAS filename
    elsif ( $fname =~ /\.A(\d{4})(\d{2})(\d{2})\.(\d{2})(\d{2})\./ ) {
        my $hr = $4;
        my $mn = $5;
        $datestring = "$1-$2-$3T$hr:$mn";
        $rangebeginningtime =~ s/00:00/$hr:$mn/;
        print STDERR "INFO datestring for NLDAS = $datestring \n"
            if ($verbose);
    }
    ## date from NLDAS Monthly filename
    elsif ( $fname =~ /\.\w(\d{4})(\d{2})\.(\d{3})\./ ) {
        $datestring = "$1-$2-01";
        print STDERR "INFO datestring for NLDAS = $datestring \n"
            if ($verbose);
    }
    ## date from MERRA filename
    elsif ( $fname =~ /\.(\d{4})(\d{2})(\d{2})\./ ) {
        $datestring = "$1-$2-$3";
        print STDERR "INFO datestring for MERRA = $datestring \n"
            if ($verbose);
    }
    elsif ( $fname =~ /\.(\d{4})(\d{2})(\d{2})-(\d{4})(\d{2})(\d{2})\./ ) {

        #20091231-20100102
        $datestring    = "$1-$2-$3";
        $enddatestring = "$4-$5-$6";
        print STDERR "INFO datestring for MERRA = $datestring \n"
            if ($verbose);
    }
    if ( length $datestring < 2 ) {
        warn( 1,
            "ERROR No datetime string from filename:<$fname> of datetime string: <$datestring>, our last resort!"
        );
        return 1;
    }
    $startTimeAttribute = $datestring;

    # Strip off trailing minutes (e.g.NLDAS)
    $startTimeAttribute =~ s/(T\d\d):00/$1/;

    # TODO:  we should put a more accurate endTimeAttribute in here
    if ($enddatestring) {
        $endTimeAttribute = $enddatestring;
    }
    else {
        $endTimeAttribute = $startTimeAttribute;
    }

    # $time = 1.0 * Date::Parse::str2time($datestring);
    $time = Date::Parse::str2time($datestring);

    if ( !defined $time ) {
        warn( 1, "ERROR Invalid datetime string from filename: $datestring" );
        return ();
    }
    my $rangebeginningdate
        = $startTimeAttribute . 'T' . $rangebeginningtime . 'Z';
    my $rangeendingdate = $endTimeAttribute . 'T' . $rangeendingtime . 'Z';
    return ( $rangebeginningdate, $rangeendingdate );
}

sub filterArray {
    my ( $arrRef, $booleanArrRef ) = @_;

    if ( scalar( @{$arrRef} ) != scalar( @{$booleanArrRef} ) ) {
        die("Filter and array must be the same size!");
    }

    my @out = ();
    for ( my $i = 0; $i < scalar( @{$arrRef} ); $i++ ) {
        if ( $booleanArrRef->[$i] ) {
            push( @out, $arrRef->[$i] );
        }
    }
    return @out;
}

sub getColorbarMinMax {
    my (%params) = @_;
    if ( $params{DATA_MIN} > $params{DATA_MAX} ) {
        die "DATA_MIN may not be greater than DATA_MAX";
    }
    if (   defined( $params{NOMINAL_MAX} )
        && defined( $params{NOMINAL_MIN} )
        && $params{NOMINAL_MIN} > $params{NOMINAL_MAX} )
    {
        die "NOMINAL_MIN may not be greater than NOMINAL_MAX";
    }

    my $min = $params{DATA_MIN};
    my $max = $params{DATA_MAX};
    if ( defined( $params{NOMINAL_MIN} ) ) {
        $min = $params{NOMINAL_MIN};
    }
    if ( defined( $params{NOMINAL_MAX} ) ) {
        $max = $params{NOMINAL_MAX};
    }

    if ( $max < $min ) {

        # We need to make sure min < max
        if ( defined( $params{NOMINAL_MIN} ) && $min == $params{NOMINAL_MIN} )
        {

            # keep the nominal min and update the max value
            $max = $min + 1;
        }
        else {

            # keep the nominal max and update the min value
            $min = $max - 1;
        }
    }

    if ( $max == $min ) {
        $max++;
    }

    return ( $min, $max );

}

sub ingestGiovanniEnv {

    my $cfgFile = shift;

    my $cpt = Safe->new('GIOVANNI');

    # FILE?
    unless ($cfgFile) {
        return "No config file was provided";
    }
    unless ( -e $cfgFile ) {
        return "No config file found at provided location";
    }

    # CFG CONTENTS?
    unless ( $cpt->rdo($cfgFile) ) {
        return "Configuration Error";
    }

    # ENV ?
    unless ( defined %GIOVANNI::ENV ) {
        return "Failed to find ENV in Giovanni configuration";
    }

    # Set the environment variables
    foreach my $key ( keys %GIOVANNI::ENV ) {
        $ENV{$key} = $GIOVANNI::ENV{$key};
    }

    return undef;
}

sub ingestGiovanniDomainLookup {

    my $cfgFile = shift;

    my $cpt = Safe->new('GIOVANNI');

    # FILE?
    unless ($cfgFile) {
        return { success => 0, message => "No config file was provided" };
    }
    unless ( -e $cfgFile ) {
        return {
            success => 0,
            message => "No config file found at provided location"
        };
    }

    # CFG CONTENTS?
    unless ( $cpt->rdo($cfgFile) ) {
        return { success => 0, message => "Configuration Error" };
    }

    # DOMAIN LOOKUP ?
    unless ( defined %GIOVANNI::DOMAIN_LOOKUP ) {
        return {
            success => 0,
            message =>
                "Failed to find DOMAIN_LOOKUP in Giovanni configuration"
        };
    }

    # Set the environment variables
    my $json = encode_json \%GIOVANNI::DOMAIN_LOOKUP;

    return { success => 1, message => $json };
}

sub getEarliestTime {
    my @timeStrings = @_;

    # parse the date into a standard string format
    my @timeParsed = map( Date::Manip::ParseDate($_), @timeStrings );

    # now convert to a DateTime object
    @timeParsed = map( DateTime->new(
            year      => UnixDate( $_, "%Y" ),
            month     => UnixDate( $_, "%m" ),
            day       => UnixDate( $_, "%d" ),
            hour      => UnixDate( $_, "%H" ),
            minute    => UnixDate( $_, "%M" ),
            second    => UnixDate( $_, "%S" ),
            time_zone => 'GMT'         # we always use GMT
        ),
        @timeParsed );

    my $earliestString = $timeStrings[0];
    my $earliestParsed = $timeParsed[0];
    for ( my $i = 1; $i < scalar(@timeStrings); $i++ ) {
        my $duration = $earliestParsed - $timeParsed[$i];
        if ( $duration->is_positive() ) {
            $earliestParsed = $timeParsed[$i];
            $earliestString = $timeStrings[$i];
        }
    }

    return $earliestString;
}

sub getLatestTime {
    my @timeStrings = @_;

    # parse the date into a standard string format
    my @timeParsed = map( Date::Manip::ParseDate($_), @timeStrings );

    # now convert to a DateTime object
    @timeParsed = map( DateTime->new(
            year      => UnixDate( $_, "%Y" ),
            month     => UnixDate( $_, "%m" ),
            day       => UnixDate( $_, "%d" ),
            hour      => UnixDate( $_, "%H" ),
            minute    => UnixDate( $_, "%M" ),
            second    => UnixDate( $_, "%S" ),
            time_zone => 'GMT'         # we always use GMT
        ),
        @timeParsed );

    my $lastestString = $timeStrings[0];
    my $lastestParsed = $timeParsed[0];
    for ( my $i = 1; $i < scalar(@timeStrings); $i++ ) {
        my $duration = $lastestParsed - $timeParsed[$i];
        if ( $duration->is_negative() ) {
            $lastestParsed = $timeParsed[$i];
            $lastestString = $timeStrings[$i];
        }
    }

    return $lastestString;
}

################################################################################
# Locking a file
################################################################################
# Credit: http://www.perlmonks.org/?node_id=394068
# Locks file by creating filepath.lock and flocking it.
# Usage: $ptr = &lock_file($path);
sub lockFile {
    my $handle;
    my $path = (shift) . '.lock';
    open( $handle, ">$path" );
    flock( $handle, LOCK_EX );
    return [ $handle, $path ];
}

# Unlocks file locked with &lock_file.
# Usage: &unlock_file($ptr);
sub unlockFile {
    my $inp = shift;
    my ( $handle, $path ) = @$inp;
    flock( $handle, LOCK_UN );
    close($handle);
    unlink($path);
}

################################################################################
################################################################################
################################################################################
#                   JSON and HASH tools, lodash style                          #
################################################################################
################################################################################
################################################################################

################################################################################
# Perl's JSON likes to qoute some numbers, but not others
# Let's convert all string number-like params to a single notation
# Credit: https://stackoverflow.com/questions/24813285
################################################################################
sub unifyJsonNumbers {
    my ($data) = @_;
    if ( ref $data eq 'HASH' ) {

        # Replace hash values with recurisvely updated values
        map { $data->{$_} = unifyJsonNumbers( $data->{$_} ) } keys %$data;
    }
    elsif ( ref $data eq 'ARRAY' ) {

        # Replace each array value with recursively processed result
        map { $_ = unifyJsonNumbers($_) } @$data;
    }
    elsif (ref $data eq 'JSON::PP::Boolean'
        || ref $data eq 'JSON::XS::Boolean' )
    {

        # Do nothing. Booleans can look like numbers, but they are not.
    }
    else {
        $data += 0 if looks_like_number($data);
    }
    return $data;
}

################################################################################
# Does some minor in-place clean-up on a HASH represnting a JSON structure
# Particulraly, converts boolean nodes to true/false, and replaces spaces
# in attribute names with underscores
################################################################################
sub cleanUpJsonHash {
    my $hashTree = shift @_;
    my @keys     = keys %{$hashTree};
    foreach my $key (@keys) {

        # Replace JSON-specific types with string equivalents
        if ( ref $hashTree->{$key} eq 'HASH' ) {
            cleanUpJsonHash( $hashTree->{$key} );
        }
        elsif (ref $hashTree->{$key} eq 'JSON::PP::Boolean'
            || ref $hashTree->{$key} eq 'JSON::XS::Boolean' )
        {
            $hashTree->{$key} = $hashTree->{$key} ? "true" : "false";
        }

        # Replace spaces in key names with underscores
        my $newKey = $key;
        $newKey =~ s/ /_/g;
        $newKey =~ s/\?//g;
        if ( $newKey ne $key ) {
            $hashTree->{$newKey} = $hashTree->{$key};
            delete $hashTree->{$key};
        }
    }
}

################################################################################
# Removes undef keys on a HASH structure in-place
################################################################################
sub removeEmptyKeys {
    my ($data) = @_;
    if ( ref $data eq 'HASH' ) {
        foreach my $key ( keys %{$data} ) {
            if ( not defined $data->{$key} ) {
                delete $data->{$key};
            }
            else {
                removeEmptyKeys( $data->{$key} );
            }
        }
    }
    elsif ( ref $data eq 'ARRAY' ) {
        foreach my $item ($data) {
            removeEmptyKeys($item);
        }
    }
}

################################################################################
# Returns an element from a hash reference specified by a path,
# e.g.,'options/Data'. $delimeter is an optional parameter (default is '/').
# Returns undef if the path is not found
################################################################################
sub getHashPath {
    my ( $data, $path, $delimeter ) = @_;
    return $data unless defined $path && $path ne '';
    return $data unless ref $data eq 'HASH';

    # Extract options from the supplied object
    foreach my $key ( split( defined $delimeter ? $delimeter : '/', $path ) )
    {
        return undef unless ref $data eq 'HASH' && exists $data->{$key};
        $data = $data->{$key};
    }
    return $data;
}

################################################################################
# Sets an element at a hash reference to a new value at a specified path,
# e.g.,'options/Data'. $delimeter is an optional parameter (default is '/').
################################################################################
sub setHashPath {
    my ( $data, $path, $newValue, $delimeter ) = @_;
    return $data unless defined $path && $path ne '';
    return $data unless ref $data eq 'HASH';

    my @pathElems  = split( defined $delimeter ? $delimeter : '/', $path );
    my $elemParent = $data;
    my $key        = shift @pathElems;

    while ( @pathElems > 0 ) {
        die 'Hash path is undefined while getting hash element'
            unless ref $elemParent eq 'HASH' && exists $elemParent->{$key};
        $elemParent = $elemParent->{$key};
        $key        = shift @pathElems;
    }
    die unless ref $elemParent eq 'HASH' && exists $elemParent->{$key};
    $elemParent->{$key} = $newValue;
}

################################################################################
# Removes an element at a hash reference at a specified path,
# e.g.,'options/Data'. $delimeter is an optional parameter (default is '/').
################################################################################
sub removeHashPath {
    my ( $data, $path, $delimeter ) = @_;
    return $data unless defined $path && $path ne '';
    return $data unless ref $data eq 'HASH';

    my @pathElems  = split( defined $delimeter ? $delimeter : '/', $path );
    my $elemParent = $data;
    my $key        = shift @pathElems;

    while ( @pathElems > 0 ) {
        die 'Hash path is undefined while getting hash element'
            unless ref $elemParent eq 'HASH' && exists $elemParent->{$key};
        $elemParent = $elemParent->{$key};
        $key        = shift @pathElems;
    }
    die unless ref $elemParent eq 'HASH' && exists $elemParent->{$key};
    delete $elemParent->{$key};
}

################################
# Helper function to check if one string ends with a different string. I
# can't find a built-in perl function for this, which seems strange to me.
# When I google, all I get is stuff about regular expressions, which is not
# what I'm looking for.
################################
sub strEndsWith{
    my ( $str, $ends_with ) = @_;

    my $str_len  = length($str);
    my $ends_len = length($ends_with);

    if (   $ends_len > $str_len
        || $ends_with ne substr( $str, $str_len - $ends_len ) )
    {
        return 0;
    }
    else {
        return 1;
    }
    
}



################################################################################
################################################################################
################################################################################

1;
__END__

=head1 NAME

Giovanni::Util - miscellaneous utility routines for Giovanni-4

=head1 SYNOPSIS

use Giovanni::Util;

($west, $south, $east, $north) = Giovanni::Util::parse_bbox ($string);

$contents = Giovanni::Util::readFile($filename);

@contents = Giovanni::Util::readFile($filename);

$isoTimeStr = Giovanni::Util::cf2datetime( 200, "seconds since 1980-01-01" );

=head1 DESCRIPTION

=over 4

=item parse_bbox($string)

Parses a common comma-separate bbox string, with or without spaces.
The returned value is an array of (west, south, east, north).

=item readFile($filename)

This reads in a file, returning either a single string, or an array
depending on the requested return.

=item getNcml($dataFile)

Uses: ncdump -x    Needs giovanni.cfg for temp dir location.  The returned value is an XML::LibXML document  

=item getNetcdfGlobalAttributes($dataFile)

returns hash of Attribute name=>value

=item getNetcdfDataVariables($dataFile) 

Uses Giovanni::Util::getNcml   Looks for variables with quantity_type attribute.  Returns a hash like:
        $varInfo{$shortName}{title}
        $varInfo{$shortName}{type} 
        $varInfo{$shortName}{quantity_type} 
        $varInfo{$shortName}{time} 
        $varInfo{$shortName}{$attrName}

=item getNetcdfDataRange($dataFile, $variableName) 

    Uses  "ncap2 -v -O -o $tmpfile -s 'ymin=min($varName * 1.0);ymax=max($varName * 1.0);print(ymin);print(ymax);' $dataFileName";
    and loops through results to get min and max for variable.

=item getQuantityTypeMinMax(@dataFiles)

    uses $varInfo returned from Giovanni::Util::getNetcdfDataVariables
    Returns %mmHash -- a hash of quantity_type containing a hash of min/max value
        $mmHash{$quantityType}{min}strEndsWith
        $mmHash{$quantityType}{max}
        where  $quantityType = $varInfo{$vkey}{quantity_type};

=item ingestGiovanniEnv(cfgFile_location)

	This function reads in configuration and then 
	puts %GIOVANNI::ENV into %ENV 
	if error then it returns a message
	otherwise returns undef
	
=item getGiovanniDomainLookup()
 
     returns DOMAIN_LOOKUP from giovanni.cfg as a JSON string
         This function reads in configuration and then 
         puts %GIOVANNI::DOMAIN_LOOKUP into JSON string
         return hash{success,json_string}

=item cf2datetime($timeStr, $cfUnit)

    Converts a CF-1 compliant time value to ISO8859 time string given the time value 
        and CF-1 compliant time unit.
    Returns ISO8859 time string if successful or undef on failure.

=item chunkDataTimeRange(%arg)

    Chunks time range supplied a hash with following keys: 
        dataStartTime (data start time in IS08601 format)
        dataEndTime (data end time IS08601 format)
        dataStartTimeOffset (optional: data start time offset in seconds)
        dataEndTimeOffset (optional: data end time offset in seconds)
        dataTemporalResolution (optional: valids are ('daily', 'monthly'))
        searchStartTime (search start time IS08601 format)
        searchEndTime (search end time IS08601 format)
        searchIntervalDays (optional: time chunk size in days; default is 365 days)
    Returns a list of hashes, each list member representing a time chunk. Each list
    member has keys=('start', 'end', 'overlap') with values representing start, end time of
    the time chunk. 'overlap' whose values can be 'full' or 'partial', indicates 
    whether the time chunk fully or partially overlap with the nominal time chunk. Overlap
    can be used in making the decision to cache search result for the time chunk.

    Example:
        @tChunkList = Giovanni::Util::chunkDataTimeRange(dataStartTime=>"2000-01-01T00:00:00Z", dataEndTime=>"2006-12-31T23:59:59Z", dataStartTimeOffset=>0, dataEndTimeOffset=>0, searchStartTime=>"2003-03-01T10:00:00Z", searchEndTime=>"2005-06-10T23:59:59Z", searchIntervalDays=>365);

=item filterArray(\@array,\@booleanFilter)

    Returns an array with only the elements specified by the boolean filter. The
    boolean filter should be exactly the same length as the array. Every element
    is treated as true or false. If the filter element in true, that element in
    the array ends up in the output array.

=item createAbsUrl($url)

    Returns the absolute URL given a URL (absolute or relative). It derives it
    based on the SCRIPT_URI environment variable. If the input URL begins with
    it is simply appended to the 'protocol://domain' of the SCRIPT_URI.
    If the input URL has a protocol already, it is returned without modification.

=item getColorbarMinMax(DATA_MIN=>$min, DATA_MAX=>$max, NOMINAL_MIN=>$nmin, NOMINAL_MAX=>$nmax)

    Returns a useful min and max for a colorbar. DATA_MIN and DATA_MAX are 
    mandatory. NOMINAL_MIN and/or NOMINAL_MAX will be used in place of DATA_MIN
    and DATA_MAX if either is present. Code makes sure the returned max is
    strictly larger than the returned min.
    
    Example:
        ($min,$max) = Giovanni::Util::getColorbarMinMax(DATA_MIN=>1, DATA_MAX=>10, NOMINAL_MIN=>0);
    

=item ingestGiovanniEnv(cfgFile_location)

    This function reads in configuration and then 
    puts %GIOVANNI::ENV into %ENV 
    if error then it returns a message
    otherwise returns undef
        
=item my $time = getEarliestTime(@times); $time = getLatestTime(@times);

    These function find the earliest and latest times in lists of times.
    Times are in string format "YYYY-MM-DDThh:mm:ssZ".

=item lockFile($path)

    Locks file by creating filepath.lock and flocking it. Returns $ptr
    object that should be used for unlocking the file.

=item unlockFile($ptr)

    Unlocks file locked by lockFile.
    
=item unifyJsonNumbers($data)
    
    Converts all string number-like params on a hash to a single number notation.
    (Since Perl's JSON parse library likes to qoute some numbers, but not others)

=item cleanUpJsonHash($hashTree)

    Does some minor in-place clean-up on a HASH represnting a JSON structure
    Particulraly, converts boolean nodes to true/false, and replaces spaces
    in attribute names with underscores.

=item removeEmptyKeys($data)
    
    Removes undef keys on a HASH structure in-place. 

=item getHashPath($data, $path, $delimeter)
    
    Returns an element from a hash reference specified by a path,
    e.g.,'options/Data'. $delimeter is an optional parameter (default is '/').
    Returns undef if the path is not found.

=item setHashPath($data, $path, $newValue, $delimeter)
    
    Sets an element at a hash reference to a new value at a specified path,
    e.g.,'options/Data'. $delimeter is an optional parameter (default is '/'). 

=item removeHashPath($data, $path, $delimeter)
    
    Removes an element at a hash reference at a specified path,
    e.g.,'options/Data'. $delimeter is an optional parameter (default is '/').
    
=item strEndsWith($str, $endsWith)

   Returns true if $str ends with the string $endsWith.

=back



=head1 AUTHORS

M. Hegde, J. Pan, C. Lynnes, D. Silva, C. Smit, R. Strub

=cut


