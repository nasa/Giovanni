#$Id: Hints.pm,v 1.90 2015/04/24 13:50:39 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=pod

=head1 NAME

Giovanni::Visualizer::Hints - creates plot hints

=head1 SYNOPSIS

my $varStr = Giovanni::Visualizer::Hints::createDataFieldString(
        LONG_NAME => "Aerosol Optical Depth 550 nm (Ocean-only)",
        TIME_RESOLUTION => "Daily",
        SPATIAL_RESOLUTION => "0.5",
        PLATFORM_INSTRUMENT => "SeaWiFS",
        PRODUCT_SHORTNAME => "SWDB_L3M05",
        VERSION => "004",
        UNITS => "1",
    );
    
my $varStr2 = Giovanni::Visualizer::Hints::createDataFieldString(
        LONG_NAME => "Aerosol Optical Depth 550 nm (Ocean-only)",
        TIME_RESOLUTION => "Daily",
        SPATIAL_RESOLUTION => "0.5",
        PLATFORM_INSTRUMENT => "SeaWiFS",
        PRODUCT_SHORTNAME => "SWDB_L3M05",
        VERSION => "004",
        UNITS => "1",
        THIRD_DIM_VALUE => "1000",
        THIRD_DIM_UNITS => "hPa",
    );

my $captions = Giovanni::Visualizer::Hints::createCaptions(
        USER_START_TIME => "2003-01-01T00:00:00Z",
        USER_END_TIME   => "2003-01-01T23:59:59Z",
        DATA_START_TIMES =>
            [ "2002-12-31T22:30:00Z", '2003-01-01T00:00:00Z' ],
        DATA_END_TIMES => [ "2003-01-01T22:29:59Z", "2003-01-01T23:59:59Z" ],
        DATA_TEMPORAL_RESOLUTION => "daily",
        USER_BBOX                => "-180,-90.0,180,45.0",
        DATA_BBOXES => [ "-180,-50.0,180,50", "-180,-90,180,90" ],
        DATA_STRINGS => [ $varStr, $varStr2 ],
    );
    

# create a Hints object
my $hints = new Giovanni::Visualizer::Hints(
    file    => $tmpFile,
    varId   => [
        "MOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean",
        "MYD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean"
    ],
    varInfoFile   => [$varInfoFile],
    userStartTime => "2003-01-01T00:00:00Z",
    userEndTime   => "2003-01-05T23:59:59Z",
);

# tell it to add the hints
$hints->addHints();




=head1 DESCRIPTION addHints

This is a legacy function that is only used for correlation at this point. It
can be removed when (if?) the correlation service is moved to the wrapper.

parameters: file, varInfoFile, varId, userStartTime, userEndTime

Definitions:

file - location of the file we are adding hints to

varId - the AESIR id for the data field(s) in the file. This needs to be an 
  array since some products come from multiple input variables.

varInfoFile - array of locations of the data_field_info files.

userStartTime - user selected start time

userEndTime - user selected end time


=head1 DESCRIPTION createDataFieldString

This function creates the standard plot hints variable string. Any of these
parameters can be left out and you should still end up with something 
reasonable. E.g. - the third dimension stuff makes no sense for non-3D
variables.

LONG_NAME - long name  

TIME_RESOLUTION - e.g. Daily, Monthly

SPATIAL_RESOLUTION - e.g. 2.0 x 2.5

PLATFORM_INSTRUMENT - e.g. TRMM

PRODUCT_SHORTNAME - e.g. SWDB_L3M05

VERSION - e.g. 004

UNITS - e.g. mm

THIRD_DIM_VALUE - e.g. 1000

THIRD_DIM_UNITS - e.g. hPa

=head1 DESCRIPTION createCaptions 

This code returns a caption string with a bounding box and/or time caption.
If no captions are needed, it returns undef.

USER_BBOX - the user's bounding box as a string

DATA_BBOXES - an array of data bounding boxes for all the data fields

DATA_STRINGS - the data field strings (see createDataFieldString). Should be
the same size as DATA_BBOXES.

USER_START_TIME - the user's selected start time

USER_END_TIME - the user's selected end time

DATA_START_TIMES - an array of data start times. Should be the same size as
DATA_BBOXES.

DATA_END_TIMES - an array of data end times. Should be the same size as
DATA_BBOXES.

DATA_TEMPORAL_RESOLUTION - daily, monthly, hourly, etc.

IS_CLIMATOLOGY (optional, false by default) - disables time captions if set to
true

=cut

package Giovanni::Visualizer::Hints;

use 5.008008;
use strict;
use warnings;
use XML::LibXML;
use List::Util qw(max min);
use DateTime;
use DateTime::Duration;
use File::Copy;
use Switch;
use Scalar::Util qw(looks_like_number);
use Giovanni::BoundingBox;
use Giovanni::Visualizer::Hints::Time;
use Giovanni::Util;
use Giovanni::Data::NcFile;
use Giovanni::Visualizer::TimeTics;

our $VERSION = '0.01';

sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    _checkParams(
        [   'file', 'varId',
            'varInfoFile', 'userStartTime', 'userEndTime',
        ],
        \%params
    );

    # make sure varId is a reference
    if ( ref( $self->{varId} ) ne "ARRAY" ) {
        die("The varId parameter must be an array reference");
    }

    # Do an XML dump of the header.
    $self->{initialHeader} = $self->_getNetcdfMetaXPathContext();

    # Combine all the variable info files into one DOM.
    $self->_setupVariableInformationDom();

    # Get out the granule start and end times
    my @nodes = $self->{initialHeader}
        ->findnodes('/nc:netcdf/nc:attribute[@name="start_time"]');
    if ( scalar(@nodes) == 0 ) {
        @nodes = $self->{initialHeader}->findnodes(
            '/nc:netcdf/nc:attribute[@name="matched_start_time"]');
    }
    if ( scalar(@nodes) == 0 ) {
        $self->{startTime} = "";
    }
    else {
        $self->{startTime} = $nodes[0]->getAttribute("value");
    }
    @nodes = $self->{initialHeader}
        ->findnodes('/nc:netcdf/nc:attribute[@name="end_time"]');
    if ( scalar(@nodes) == 0 ) {
        @nodes = $self->{initialHeader}
            ->findnodes('/nc:netcdf/nc:attribute[@name="matched_end_time"]');
    }
    if ( scalar(@nodes) == 0 ) {
        $self->{endTime} = "";
    }
    else {
        $self->{endTime} = $nodes[0]->getAttribute("value");
    }

    # figure out the intervals and bounding boxes
    $self->{time_interal} = [];
    $self->{field_bboxes} = [];
    for my $id ( @{ $self->{varId} } ) {
        my ($node)
            = $self->{varInfo}->findnodes(qq(/varList/var[\@id="$id"]));
        push(
            @{ $self->{interval} },
            $node->getAttribute("dataProductTimeInterval")
        );

        # get out the coordinates
        my $west  = $node->getAttribute("west");
        my $south = $node->getAttribute("south");
        my $east  = $node->getAttribute("east");
        my $north = $node->getAttribute("north");
        push(
            @{ $self->{field_bboxes} },
            Giovanni::BoundingBox->new(
                WEST  => $west,
                SOUTH => $south,
                EAST  => $east,
                NORTH => $north
            )
        );
    }

    return $self;
}

# Adds plot hints based on service
sub addHints {
    my ($self) = @_;

    # correlation gets variable hints
    $self->_addCorrelationVariableHints();
    $self->_addCorrelationCaption();
    $self->_deleteExtraCorrelationVars();

    # delete history
    my $cmd = qq(ncatted -O -h -a "history,global,d,c,," $self->{file});
    my $ret = system($cmd);

    # make sure the command returned zero
    !$ret or die "Failed to delete history: $cmd";

}

sub _setupVariableInformationDom() {
    my ($self) = @_;

    # Do an XML dump of varInfo
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file( $self->{varInfoFile}->[0] );
    my $root   = $dom->documentElement;

    for ( my $i = 1; $i < scalar( @{ $self->{varInfoFile} } ); $i++ ) {
        my $anotherDom = $parser->parse_file( $self->{varInfoFile}->[$i] );
        my @nodes      = $anotherDom->findnodes("/varList/var");
        for my $node (@nodes) {
            $root->appendChild($node);
        }
    }

    $self->{varInfo} = XML::LibXML::XPathContext->new($dom);
}

# This function deletes the extra variables with the time averages
# TODO: Remove me. Eventually we will want to keep these around
sub _deleteExtraCorrelationVars() {
    my ($self) = @_;

    for my $id ( @{ $self->{varId} } ) {
        my $xpath = qq(/nc:netcdf/nc:variable[\@name="$id"]);
        my ($node) = $self->{initialHeader}->findnodes($xpath);
        if ( defined($node) ) {
            my $tempFile = "hints_temp.nc";

            # delete the variable
            my $cmd = qq(ncks -x -v $id $self->{file} $tempFile);
            die "Failed to run: $cmd" unless ( system($cmd) == 0 );

            # move the temp to the original file
            move( $tempFile, $self->{file} )
                or die "Couldn't move $tempFile to $self->{file}";
        }
    }
}

# Adds a caption, if needed, for correlation
sub _addCorrelationCaption() {
    my ($self) = @_;

    my $caption = $self->_createBulletedString(
        $self->_createTimeCaptionFromAttribute() );
    if ( length($caption) > 0 ) {

        # correlation, n_samples, and time_matched_difference all get the same
        # caption
        my $cmd = qq(ncatted -a plot_hint_caption,correlation,o,c,)
            . qq("$caption" $self->{file});
        die "Failed to run: $cmd" unless ( system($cmd) == 0 );

        $cmd = qq(ncatted -a plot_hint_caption,n_samples,o,c,)
            . qq("$caption" $self->{file});
        die "Failed to run: $cmd" unless ( system($cmd) == 0 );

        # see if there is a difference variable
        my $xpath
            = qq(/nc:netcdf/nc:variable[\@name="time_matched_difference"]);

        if ( $self->{initialHeader}->findnodes($xpath) ) {
            $cmd
                = qq(ncatted -a plot_hint_caption,time_matched_difference,o,c,)
                . qq("$caption" $self->{file});
            die "Failed to run: $cmd" unless ( system($cmd) == 0 );
        }
    }
}

# This creates the full time caption from the global plot_hint_caption. Used
# for correlation and paired data.
sub _createTimeCaptionFromAttribute() {
    my ( $self, @variableStrings ) = @_;

    # see if there was a caption in the initial header. If a caption is
    # needed, the algorithm step will supply part of the caption.
    my @nodes = $self->{initialHeader}->findnodes(
        qq(nc:netcdf/nc:attribute[\@name="plot_hint_caption"]/\@value));
    if ( scalar(@nodes) == 0 ) {

        # no caption needed
        return undef;
    }

    # Get the user-selected range
    my $startTimeStr = Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => $self->{userStartTime},
        INTERVAL    => $self->{interval}[0],
        IS_START    => 1
    );
    my $endTimeStr = Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => $self->{userEndTime},
        INTERVAL    => $self->{interval}[0],
        IS_START    => 0
    );

    my $partialCaption = $nodes[0]->to_literal();
    for ( my $i = 0; $i < scalar(@variableStrings); $i++ ) {

        # the ids are place holders for variable names
        my $id = $self->{varId}->[$i];
        $partialCaption =~ s/$id/$variableStrings[$i]/;
    }

    return "Selected date range was $startTimeStr - $endTimeStr. "
        . $partialCaption;

}

# dumps the netcdf file to XML. Get's an XPathContext for the XML with the
# 'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' namespace set to
# 'nc'
sub _getNetcdfMetaXPathContext() {
    my ($self) = @_;
    my @lines = `ncdump -h -x $self->{file}  `
        or die "Failed to get header from $self->{file} with ncdump\n";

    # parse the XML and grab the root node.
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_string( join( "", @lines ) );
    my $xpc    = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs(
        nc => 'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );
    return $xpc;
}

# add variable-level plot hints for correlation file variables
sub _addCorrelationVariableHints {
    my ($self) = @_;

    # see if there is a difference variable
    my $xpath = qq(/nc:netcdf/nc:variable[\@name="time_matched_difference"]);
    my @nodes = $self->{initialHeader}->findnodes($xpath);
    my $hasDifference = @nodes;

    # create the date string
    my ($dateRangeString) = $self->_createDateRangeString();

    # correlation variable title
    my $cmd = "ncatted -a plot_hint_title,correlation,o,c,"
        . "'Correlation for $dateRangeString' $self->{file}";
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );

    if ($hasDifference) {

        # difference variable title
        $cmd = "ncatted -a plot_hint_title,time_matched_difference,o,c,"
            . "'Time matched difference for $dateRangeString (Var. 1 - Var. 2)' $self->{file}";
        die "Failed to run: $cmd" unless ( system($cmd) == 0 );
    }

    # n_samples variable title
    $cmd = "ncatted -a plot_hint_title,n_samples,o,c,"
        . "'Time matched sample size for $dateRangeString' $self->{file}";
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );

    # now do the subtitles, which are derived from the
    # correlation long name
    $xpath = qq(/nc:netcdf/nc:variable[\@name="correlation"])
        . qq(/nc:attribute[\@name="long_name"]);
    my ($longNameNode) = $self->{initialHeader}->findnodes($xpath);
    my $long_name = $longNameNode->getAttribute("value");

    # This long name format is "Correlation of <var 1 long name> vs. <var 2
    # long name>
    my $firstName;
    my $secondName;
    if ( $long_name =~ m/Correlation of (.*) vs. (.*)/ ) {
        $firstName  = $1;
        $secondName = $2;
    }

    if ( !( defined $firstName ) ) {
        die "Unable to get first variable name"
            . " from correlation long_name: $long_name";
    }
    if ( !( defined $secondName ) ) {
        die "Unable to get second variable name"
            . " from correlation long_name: $long_name";
    }

    my $subtitle
        = "1st Variable: "
        . $firstName . "\n"
        . "2nd Variable: "
        . $secondName;

    # add to all variables
    # correlation variable subtitle
    $cmd = "ncatted -a plot_hint_subtitle,correlation,o,c,"
        . "'$subtitle' $self->{file}";
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );

    if ($hasDifference) {
        my $diffsubtitle = "Var. 1: $firstName\n" . "Var. 2: $secondName";

        # difference variable subtitle
        $cmd = "ncatted -a plot_hint_subtitle,time_matched_difference,o,c,"
            . "'$diffsubtitle' $self->{file}";
        die "Failed to run: $cmd" unless ( system($cmd) == 0 );
    }

    # n_samples variable subtitle
    $cmd = "ncatted -a plot_hint_subtitle,n_samples,o,c,"
        . "'$subtitle' $self->{file}";
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );

}

# This creates a string for the date range based on the start time and
# end time of the data file (not the use start and end time).  If the start and
# end dates are the same time, the range string is just that date. Some
# 'obvious' part of the time are stripped off for clarity.
# E.g. -
# "2003-01-01" to "2003-01-02T23:59:59Z" --> "2003-01-01 -- 2003-01-02"
# "2003-01-01" to "2003-01-01T23:59:59Z" --> "2003-01-01"
sub _createDateRangeString {
    my ( $self, $justYear ) = @_;

    # return an empty string if we are missing the start and end time
    if ( !$self->{startTime} || !$self->{endTime} ) {
        return ( "", 0 );
    }

    # note that if there is more than one variable, the interval should be
    # the same
    my $startTime = Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => $self->{startTime},
        INTERVAL    => $self->{interval}[0],
        IS_START    => 1,
        JUST_YEAR   => $justYear
    );
    my $endTime = Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => $self->{endTime},
        INTERVAL    => $self->{interval}[0],
        IS_START    => 0,
        JUST_YEAR   => $justYear
    );

    my $dateRangeString;
    my $isSingleDate;
    if ( $startTime eq $endTime ) {
        $dateRangeString = $startTime;
        $isSingleDate    = 1;
    }
    else {
        $dateRangeString = "$startTime - $endTime";

        # see if this actually represents a single time slice, just shifted
        if (Giovanni::Visualizer::Hints::Time::isWithinOneSlice(
                START_TIME => $self->{startTime},
                END_TIME   => $self->{endTime},
                INTERVAL   => $self->{interval}[0]
            )
            )
        {
            $isSingleDate = 1;
        }
        else {
            $isSingleDate = 0;
        }
    }
    return ( $dateRangeString, $isSingleDate );
}

# Returns a string with one bullet per input string.
sub _createBulletedString() {

    # first input is self
    shift(@_);
    my @lines = @_;

    # remove empty entries
    @lines = map { $_ ? $_ : () } @lines;

    if (@lines) {
        my $str = "- " . shift(@lines);
        for my $line (@lines) {
            $str = "$str\n\n- $line";
        }
        return $str;
    }
    else {
        return "";
    }

}

sub createDataFieldString {
    my (%params) = @_;

    # LONG_NAME, TIME_RESOLUTION, SPATIAL_RESOLUTION, PLATFORM_INSTRUMENT,
    # PRODUCT_SHORTNAME, UNITS, VERSION, THIRD_DIM_VALUE, THIRD_DIM_UNITS

    _checkParams(
        [   'LONG_NAME',          'TIME_RESOLUTION',
            'SPATIAL_RESOLUTION', 'PLATFORM_INSTRUMENT',
            'PRODUCT_SHORTNAME',  'VERSION'
        ],
        \%params
    );

    my $thirdDim = '';
    if ( defined( $params{"THIRD_DIM_VALUE"} ) ) {
        $thirdDim
            = "@" . $params{"THIRD_DIM_VALUE"} . $params{"THIRD_DIM_UNITS"};
    }
    my $version = '';
    if ( defined( $params{"VERSION"} ) ) {
        $version = "v" . $params{"VERSION"};
    }

    my $units = '';
    if ( defined( $params{"UNITS"} ) && $params{"UNITS"} ne "1" ) {

        $units = $params{"UNITS"};
    }

    my $ret
        = $params{"LONG_NAME"} . " "
        . $params{"TIME_RESOLUTION"} . " "
        . $params{"SPATIAL_RESOLUTION"} . " "
        . $thirdDim . " ["
        . $params{"PLATFORM_INSTRUMENT"} . " "
        . $params{"PRODUCT_SHORTNAME"} . " "
        . $version . "] "
        . $units;

    # If there are missing fields, we will end up with multiple spaces.
    $ret =~ s/\s+/ /g;

    # trim white space at either end
    Giovanni::Util::trim($ret);

    return $ret;
}

sub createCaptions {

    # USER_START_TIME
    # USER_END_TIME
    # DATA_START_TIMES
    # DATA_END_TIMES
    # DATA_TEMPORAL_RESOLUTION
    # DATA_STRINGS
    # USER_BBOX
    # DATA_BBOXES
    # IS_CLIMATOLOGY
    # HAS_TIME_DIMENSION
    # SHAPEFILE
    my (%params) = @_;

    if ( !defined( $params{IS_CLIMATOLOGY} ) ) {
        $params{IS_CLIMATOLOGY} = 0;
    }

    if ( !defined( $params{HAS_TIME_DIMENSION} ) ) {
        $params{HAS_TIME_DIMENSION} = 0;
    }

    if ( !defined( $params{GROUP} ) ) {
        $params{GROUP} = 0;
    }
    else {
        if ( $params{GROUP} =~ /(.*)=(.*)/ ) {
            $params{GROUP_TYPE}  = $1;
            $params{GROUP_VALUE} = $2;
        }
        else {
            die "Can't parse GROUP: " . $params{GROUP};
        }
    }

    my $bboxCaption;
    if (   $params{USER_BBOX}
        && $params{DATA_BBOXES}
        && $params{DATA_STRINGS} )
    {
        $bboxCaption = _getBboxCaption(%params);
    }

    my $timeCaption;

    if (   $params{USER_START_TIME}
        && $params{USER_END_TIME}
        && $params{DATA_START_TIMES}
        && $params{DATA_END_TIMES}
        && $params{DATA_STRINGS}
        && $params{DATA_TEMPORAL_RESOLUTION}
        && !$params{IS_CLIMATOLOGY}
        && !$params{GROUP} )

    {
        if ( scalar( @{ $params{"DATA_START_TIMES"} } ) == 1 ) {

            # there is only one start time, so this is not a comparison
            # service.
            $timeCaption = _getNonComparisonTimeCaption(%params);
        }
        else {
            $timeCaption = _getComparisonTimeCaption(%params);
        }
    }

    my @captions = ();
    if ( defined($bboxCaption) ) {
        push( @captions, "- " . $bboxCaption . "\n" );
    }
    if ( defined($timeCaption) ) {
        push( @captions, "- " . $timeCaption . "\n" );
    }

    if ( $params{GROUP} && ( $params{GROUP_TYPE} eq 'SEASON' ) ) {
        push( @captions, "- Seasons with missing months are discarded." );
        if ( $params{HAS_TIME_DIMENSION} ) {
            push( @captions,
                "- DJF seasons are plotted against the year of the January and February data granules."
            );
        }
    }

    if ( scalar(@captions) ) {
        return join( "\n", @captions );
    }
    else {
        return undef;
    }

}

sub _checkParams {
    my ( $requiredRef, $hashRef ) = @_;
    my ( $dont_care1, $dont_care2, $dont_care3, $subroutine ) = caller(1);
    for my $requiredKey ( @{$requiredRef} ) {
        if ( !defined( $hashRef->{$requiredKey} ) ) {
            die "$subroutine requires input $requiredKey";
        }

    }
}

sub _getNonComparisonTimeCaption {
    my (%params) = @_;

    # USER_START_TIME
    # USER_END_TIME
    # DATA_START_TIMES
    # DATA_END_TIMES
    # DATA_TEMPORAL_RESOLUTION

    # build strings for the time ranges. E.g. 2003-01-01 - 2003-01-05.
    my $userTimeString = Giovanni::Visualizer::Hints::Time::formatTimeRange(
        START_TIME => $params{"USER_START_TIME"},
        END_TIME   => $params{"USER_END_TIME"},
        INTERVAL   => $params{"DATA_TEMPORAL_RESOLUTION"},
        IS_START   => 0
    );
    my $dataTimeString = Giovanni::Visualizer::Hints::Time::formatTimeRange(
        START_TIME => $params{"DATA_START_TIMES"}->[0],
        END_TIME   => $params{"DATA_END_TIMES"}->[0],
        INTERVAL   => $params{"DATA_TEMPORAL_RESOLUTION"},
        IS_START   => 0
    );

    if ( $userTimeString ne $dataTimeString ) {
        return
              "Selected date range was $userTimeString. Title "
            . "reflects the date range of the granules that went into"
            . " making this result.";
    }
    else {
        return undef;
    }

}

sub _getComparisonTimeCaption {
    my (%params) = @_;

    # USER_START_TIME
    # USER_END_TIME
    # DATA_START_TIMES
    # DATA_END_TIMES
    # DATA_TEMPORAL_RESOLUTION
    # DATA_STRINGS

    # build strings for the time ranges. E.g. 2003-01-01 - 2003-01-05.
    my $userTimeString = Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => $params{"USER_START_TIME"},
        INTERVAL    => $params{"DATA_TEMPORAL_RESOLUTION"},
        IS_START    => 1,
        JUST_YEAR   => 0
        )
        . " - "
        . Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => $params{"USER_END_TIME"},
        INTERVAL    => $params{"DATA_TEMPORAL_RESOLUTION"},
        IS_START    => 0,
        JUST_YEAR   => 0
        );

    my @dataTimeStrings = ();
    my $needCaption     = 0;
    for ( my $i = 0; $i < scalar( @{ $params{"DATA_START_TIMES"} } ); $i++ ) {
        my $str = Giovanni::Visualizer::Hints::Time::formatTime(
            TIME_STRING => $params{"DATA_START_TIMES"}->[$i],
            INTERVAL    => $params{"DATA_TEMPORAL_RESOLUTION"},
            IS_START    => 1,
            JUST_YEAR   => 0
            )
            . " - "
            . Giovanni::Visualizer::Hints::Time::formatTime(
            TIME_STRING => $params{"DATA_END_TIMES"}->[$i],
            INTERVAL    => $params{"DATA_TEMPORAL_RESOLUTION"},
            IS_START    => 0,
            JUST_YEAR   => 0
            );
        push( @dataTimeStrings, $str );

        # see if data time range matches the user's request
        if ( $str ne $userTimeString ) {
            $needCaption = 1;
        }
    }

    if ($needCaption) {
        my $caption = "Selected data range was $userTimeString.";
        for ( my $i = 0; $i < scalar(@dataTimeStrings); $i++ ) {
            $caption
                .= " The data date range for "
                . $params{"DATA_STRINGS"}->[$i] . " is "
                . $dataTimeStrings[$i] . ".";
        }
        return $caption;
    }
    else {
        return undef;
    }
}

sub _getBboxCaption {
    my (%params) = @_;
    my $weHaveAPointContext = 0;
    # USER_BBOX
    # DATA_BBOXES
    # DATA_STRINGS

    my $userBbox
        = Giovanni::BoundingBox->new( STRING => $params{"USER_BBOX"} );
    my @dataBboxes = map( Giovanni::BoundingBox->new( STRING => $_ ), @{ $params{"DATA_BBOXES"} } );
    my @dataStrings = @{ $params{"DATA_STRINGS"} };

    my $captionRequired = 0;

    my $captionString
        = "The user-selected region was defined by " . $userBbox->getPrettyString() . ".";

    # Can only user userBbox to check if point if we have file res.
    for ( my $i = 0; $i < scalar(@dataBboxes); $i++ ) {
         if (Giovanni::Data::NcFile::is_a_point($dataBboxes[$i]))  {
            $weHaveAPointContext = 1;
         }
    }

    for ( my $i = 0; $i < scalar(@dataBboxes); $i++ ) {

        # Check to see if the user bounding box extends beyond the data
        # bounding box.
        my @intersections = Giovanni::BoundingBox::getIntersection( $userBbox,
            $dataBboxes[$i] );
        # 1. If intersection exists but equals userbox, then it just means the userbox 
        # is completely inside the data's limited extent (e.g. TRMM). If different than the user
        # bbox then it is either a limited extent or a datagrid case. limited extent bbox has a dataString
        # datagrid case does not.
        # 2. New point case:
        #      There most likely won't be an intersection when a snapped point is created from a user's small bbox
        #      The limited extent case will exist and intersect but it's kinda meaningless so we want to avoid it
        #      and focus on the fact that they are getting a snapped point. 
        if ($weHaveAPointContext) 
        { # then we don't want info about 'a limited extent'
            # Since we know it is a point we can tell them so:
            if (!$dataStrings[$i]) { # limited extent has assoc string
                $captionRequired = 1;
                $captionString .= " " . "The data grid also limits the analyzable region to the this point: "
                           . $dataBboxes[$i]->getPrettyString() . ".";
            }
        }
        elsif ( scalar(@intersections) >= 1  and !Giovanni::BoundingBox::isSameBox( $userBbox, $intersections[0] ) )
        {
            $captionRequired = 1;
            if ($dataStrings[$i]) { # limited extent has assoc string
                    $captionString .= " " . $dataStrings[$i]
                  . " has a limited data extent of "
                  . $dataBboxes[$i]->getPrettyString() . ".";
            }
            else {                  # datagrid does not
                $captionString .= " "
                  . "The data grid also limits the analyzable region to the following bounding points: "
                  . $dataBboxes[$i]->getPrettyString() . ".";
            }
        }
    }

    # In fact the region in the title reflects the user's bbox, not the data extent
    if ($params{SHAPEFILE}){ # then we want the title, which includes the user bbox,
        # shape, and data extent to describe the region.  
        $captionString .= " The intersection of the shape with the region in the title reflects the data extent of "
        . "the subsetted granules that went into making this result.";
    }
    else { # we want to emphasize the data grid as the analyzable region
        $captionString .= " This analyzable region indicates the spatial limits " . 
        "of the subsetted granules that went into making this visualization result.";
    }
    if ($captionRequired) {
        return $captionString;
    }
    else {
        return undef;
    }
}

1;
