#!/usr/bin/perl

use strict;
use XML::LibXML;
use Giovanni::Catalog;
use Giovanni::Util;
use Giovanni::Logger;
use Getopt::Long;
use Date::Manip;

# Note: log messages follow Giovanni external command specification
logMessage( "Obtaining variable information", "STEP_DESCRIPTION" );

# Variables to hold command line arguments
my ( $opt_h, $startTime, $endTime, $bbox, $varList, $aesirBaseUrl, $outDir,
    $inXmlFile )
    = ( '', '', '', '', '', '' );

# Get command line options
Getopt::Long::GetOptions(
    't1=s'        => \$startTime,
    't2=s'        => \$endTime,
    'bbox=s'      => \$bbox,
    'dataset=s'   => \$varList,
    'aesir=s'     => \$aesirBaseUrl,
    'inXmlFile=s' => \$inXmlFile,
    'outDir=s'    => \$outDir,
    'h'           => \$opt_h
);

# If -h is specified, provide synopsis
die "$0 --t1 'starttime' --t2 'endtime'"
    . " --bbox 'bounding box(West,South,East,North)'"
    . " --var 'comma separated list of dataset IDs'"
    . " --aesir 'URL for AESIR'\n"
    . " --inXmlFile 'Giovanni input.xml'\n"
    if ($opt_h);

my $logger;
if ( defined $inXmlFile && -f $inXmlFile ) {
    my $inDoc = Giovanni::Util::parseXMLDocument($inXmlFile);
    if ( defined $inDoc ) {
        $startTime = $inDoc->findvalue('//starttime');
        $endTime   = $inDoc->findvalue('//endtime');
        $bbox      = $inDoc->findvalue('//bbox');
        foreach my $varNode ( $inDoc->findnodes('//data') ) {
            my $varName = $varNode->textContent();
            $varName =~ s/^\s+|\s+$//g;
            $varList .= ( $varList ne '' ? ',' : '' ) . $varName;
        }
        $logger = Giovanni::Logger->new(
            session_dir => $outDir,
            name        => 'GetVariableInfo'
        );
    }
}
die "INFO Specify start time"       unless ( $startTime    =~ /\S+/ );
die "INFO Specify end time"         unless ( $endTime      =~ /\S+/ );
die "INFO Specify bounding box"     unless ( $bbox         =~ /\S+/ );
die "INFO Specify AESIR base URL"   unless ( $aesirBaseUrl =~ /\S+/ );
die "INFO Specify output directory" unless ( $outDir       =~ /\S+/ );
die "INFO Specify variable list"    unless ( $varList      =~ /\S+/ );

# Create a DOM for output
my $xmlParser = XML::LibXML->new();
my $outDom    = $xmlParser->parse_string('<varList />');
my $outDoc    = $outDom->documentElement();
logMessage( "Locating requested variables", "USER_MSG" );
$logger->user_msg("Locating requested variable") if defined $logger;
my $catalog = Giovanni::Catalog->new( { URL => $aesirBaseUrl } );

# Form the list of variables requested
my $fieldList = [ split( /,/, $varList ) ];

# Query to get variable metdata
my $var = $catalog->getDataFieldInfo( { FIELDS => $fieldList } );
my @foundVarList = defined $var ? keys(%$var) : ();
logMessage(
    "Found " . @foundVarList . " variable" . ( @foundVarList > 1 ? "s" : "" ),
    "USER_MSG"
);
$logger->user_msg( "Found "
        . @foundVarList
        . " variable"
        . ( @foundVarList > 1 ? "s" : "" ) )
    if defined $logger;

# Case of no variable info not found
exit(2) unless ( @foundVarList > 0 );

# Split spatial bounding box in to individual coordinates
my ( $west, $south, $east, $north ) = split( /,/, $bbox );

# Define an anonymous function to add time offset
my $addTimeOffset = sub {
    my ( $dateTime, $offsetInSeconds ) = @_;
    my $origTime = Date::Manip::ParseDate($dateTime);
    return undef unless defined $origTime;
    my $newTime
        = Date::Manip::DateCalc( $origTime, "$offsetInSeconds seconds" );
    return undef unless defined $newTime;
    return Date::Manip::UnixDate( $newTime, "%O" );
};

# Defined an anonymous function to reset start and end time
my $resetTime = sub {
    my ( $dateTime, $type ) = @_;
    my $origTime = Date::Manip::ParseDate($dateTime);
    if ( $type eq 'START_DAY' ) {
        return Date::Manip::UnixDate( $origTime, "%Y-%m-%d" );
    }
    elsif ( $type eq 'END_DAY' ) {
        my $date = Date::Manip::UnixDate( $origTime, "%Y-%m-%d" );
        return $addTimeOffset->( $date, 86399 );
    }
    return undef;
};

#
my $minTemporalResolution = undef;
my %tempResOrder = ( hourly => 0, daily => 1, monthly => 2 );
foreach my $key (@$fieldList) {
    next unless ( defined $var->{$key}{dataProductTimeInterval} );
    my $tResolution = $var->{$key}{dataProductTimeInterval};
    if ( defined $minTemporalResolution ) {
        $minTemporalResolution = $tResolution
            if $tempResOrder{$minTemporalResolution}
                > $tempResOrder{$tResolution};
    }
    else {
        $minTemporalResolution = $var->{$key}{dataProductTimeInterval};
    }
}
foreach my $key (@$fieldList) {
    next unless defined $var->{$key};
    my $elem = XML::LibXML::Element->new('var');
    $elem->setAttribute( 'id', $key );
    foreach my $attr ( keys %{ $var->{$key} } ) {
        if ( $attr eq 'url' ) {

            # Modify start and end time by adding offsets if they are defined
            # in the catalog
            my $searchStartTime = $startTime;
            if (   defined $var->{$key}{dataProductTimeInterval}
                && $var->{$key}{dataProductTimeInterval} eq 'daily'
                && $minTemporalResolution eq 'daily' )
            {
                $searchStartTime = $resetTime->( $startTime, 'START_DAY' );
                if (   defined $searchStartTime
                    && defined $var->{$key}{dataProductStartTimeOffset} )
                {
                    $searchStartTime = $addTimeOffset->(
                        $searchStartTime,
                        $var->{$key}{dataProductStartTimeOffset}
                    );
                }
            }
            my $searchEndTime = $endTime;
            if (   defined $var->{$key}{dataProductTimeInterval}
                && $var->{$key}{dataProductTimeInterval} eq 'daily'
                && $minTemporalResolution eq 'daily' )
            {
                $searchEndTime = $resetTime->( $endTime, 'END_DAY' );
                if (   defined $searchEndTime
                    && defined $var->{$key}{dataProductEndTimeOffset} )
                {
                    $searchEndTime = $addTimeOffset->(
                        $searchEndTime, $var->{$key}{dataProductEndTimeOffset}
                    );
                }
            }

            # Time to chunk time search
            if ( $var->{$key}{searchIntervalDays} != 0 ) {
                my $timeChunkSize = $var->{$key}{searchIntervalDays} * 86400;
                my $tStart        = Date::Manip::ParseDate($searchStartTime);
                my $tEnd          = Date::Manip::ParseDate($searchEndTime);
                my $t             = $tStart;
                while (1) {
                    my ( $t1, $t2 ) = (
                        $t,
                        Date::Manip::DateCalc(
                            $t, $timeChunkSize - 1 . " seconds"
                        )
                    );
                    $t2 = $tEnd
                        if ( Date::Manip::Date_Cmp( $t2, $tEnd ) > 0 );
                    my ( $t1Str, $t2Str ) = (
                        Date::Manip::UnixDate( $t1, "%O" ),
                        Date::Manip::UnixDate( $t2, "%O" )
                    );
                    my $varUrl = $var->{$key}{$attr}
                        . qq(&start=$t1Str&end=$t2Str&output_type=xml);
                    $elem->appendTextChild( 'url', $varUrl );
                    $t = Date::Manip::DateCalc( $t,
                        "$timeChunkSize seconds" );
                    last if ( Date::Manip::Date_Cmp( $t, $tEnd ) > 0 );
                }
            }
            else {
                my $varUrl = $var->{$key}{$attr}
                    . qq(&start=$searchStartTime&end=$searchEndTime&output_type=xml);
                $elem->setAttribute( $attr, $varUrl );
            }
        }
        elsif ( $attr eq 'sld' ) {

            eval {

                # Create a DOM parser for XML
                my $xmlParser = XML::LibXML->new();
                my $inDom = $xmlParser->parse_string( $var->{$key}{$attr} );
                my $inDoc = $inDom->documentElement();

                # append the XML to this element
                $elem->appendChild($inDoc);

            } or do {

                # this isn't XML, so just put in the single SLD
                my $slds = XML::LibXML::Element->new('slds');
                $elem->appendChild($slds);
                my $sld = XML::LibXML::Element->new('sld');
                $sld->setAttribute( 'url',   $var->{$key}{$attr} );
                $sld->setAttribute( 'label', "Default" );
                $slds->appendChild($sld);
            };
        }
        else {
            $elem->setAttribute( $attr, $var->{$key}{$attr} );
        }
    }
    $outDoc->appendChild($elem);
}
my $outFile = "$outDir/varInfo.xml";
if ( open( FH, ">$outFile" ) ) {
    print FH $outDoc->toString(2);
    close(FH);
    logMessage( "Completed generation of variable information", "INFO" );
    logMessage( $outFile,                                       "OUTPUT" );
}
else {
    logMessage( "Failed to generate variable information", "INFO" );
    exit(1);
}

sub logMessage($msg,$level) {
    my ( $msg, $level ) = @_;
    $level = "INFO" unless defined $level;
    print STDERR "$level $msg\n";
}
__END__

=head1 NAME

getVariableInfo.pl - Script to get Giovanni variable information

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

getVariableInfo.pl
[B<-t1> start-date-time]
[B<-t2> end-date-time]
[B<-bbox> west,south,east,north]
[B<-var> var1,var2,var3]
[B<-outDir> Output directory]
[B<-inXmlFile> Giovanni input.xml file]
[B<-h>] 

=head1 DESCRIPTION


=head1 OPTIONS

=over 4

=item B<-h>

Prints commands synposis

=item B<t1>

Start date time in ISO8601 format

=item B<t2>

End date time in ISO8601 format

=item B<bbox>

Spatial bounding box (comma separated list of west,south,east,north 
coordinates in degrees)

=item B<var>

Comma separated list of variable IDs

=item B<aesir>

Base URL for AESIR

=item B<outDir>

Directory where output will be written to

=back

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

None

=head1 EXAMPLES

perl getVariableInfo.pl --t1 "2003-01-01" --t2 "2003-01-31T23:59:59" --dataset "MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean" --aesir  "http://s4ptu-ts2.ecs.nasa.gov/solr/" --bbox "-180,-90,180,90" --outDir "./"

=head1 AUTHOR

M. Hegde (Mahabaleshwa.S.Hegde@nasa.gov)

=head1 SEE ALSO

=cut

