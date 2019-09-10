package Giovanni::Map::Info;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.01';

use XML::LibXML;

use Giovanni::DataField;
use Giovanni::Util;
use Giovanni::BoundingBox;
use Giovanni::Visualizer::Hints;
use Giovanni::Visualizer::Hints::Time;


sub getherInputInfoFromFile {
   my (%params) = @_;
   #read in input.xml
   my $xpc = XML::LibXML::XPathContext->new(
      XML::LibXML->new()->parse_file( $params{INPUT} ) );
   my %out = (
       DESCRIPTION    => $xpc->findvalue("/input/description"),
       STARTTIME      => $xpc->findvalue("/input/starttime"),
       ENDTIME        => $xpc->findvalue("/input/endtime"),
       BBOX           => $xpc->findvalue("/input/bbox"),
       SHAPE          => $xpc->findvalue("/input/shape"),
       DATA           => $xpc->findvalue("/input/data")
    );
    return %out;
}

sub gatherVariableInfoFromFile {
    my (%params) = @_;

    # read in input.xml
    my $xpc = XML::LibXML::XPathContext->new(
        XML::LibXML->new()->parse_file( $params{INPUT} ) );

    # get the data out of the data file
    my $startTime;
    my $endTime;
    if ( defined( $params{DATA} ) ) {

        # get the start time out of the data
        my $header = Giovanni::Data::NcFile::get_xml_header( $params{DATA} );
        $startTime = $header->findvalue(
            '/nc:netcdf/nc:attribute[@name="start_time"]/@value');
        $endTime = $header->findvalue(
            '/nc:netcdf/nc:attribute[@name="end_time"]/@value');
    }
    else {

        # get the start time from the user's request
        $startTime = $xpc->findvalue("/input/starttime");
        $endTime   = $xpc->findvalue("/input/endtime");
    }
    my ($fullName, $timeRange, $bbox, $long_name, $resolution, $platformInstrument, $product, $version, $zValue, $zUnits, $units, $nominalMin, $nominalMax, $slds );
    $fullName = $params{'DATA_FIELD_INFO'};
    $slds = [];
    my %out = (
        FULL_NAME           => $fullName,
        #TIME_RANGE          => $timeRange,
        #BBOX                => $bbox,
        #LONG_NAME           => $long_name,
        #SPATIAL_RESOLUTION  => $resolution,
        #PLATFORM_INSTRUMENT => $platformInstrument,
        #PRODUCT_SHORTNAME   => $product,
        #VERSION             => $version,
        #ZVALUE              => $zValue,
        #ZUNITS              => $zUnits,
        #UNITS               => $units,
        #ORIGINAL_UNITS      => $nominalUnits,
        #NOMINAL_MIN         => $nominalMin,
        #NOMINAL_MAX         => $nominalMax,
        SLDS                => $slds
    );

    return %out;
}

sub gatherVariableInfo {
    my (%params) = @_;

    # read in the data field info file
    my $dataFieldInfo
        = Giovanni::DataField->new( MANIFEST => $params{'DATA_FIELD_INFO'} ) if (exists $params{'DATA_FIELD_INFO'} and -f $params{'DATA_FIELD_INFO'} );
    return gatherVariableInfoFromFile(%params) unless defined $dataFieldInfo;;

    my $id         = $dataFieldInfo->get_id();
    my $long_name  = $dataFieldInfo->get_long_name();
    my $product    = $dataFieldInfo->get_dataProductShortName();
    my $version    = $dataFieldInfo->get_dataProductVersion();
    my $zUnits     = $dataFieldInfo->get_zDimUnits();
    my $nominalMin = $dataFieldInfo->get_nominalMin();
    my $nominalMax = $dataFieldInfo->get_nominalMax();
    my $slds       = $dataFieldInfo->get_slds();
    my $values_distribution = $dataFieldInfo->get_valuesDistribution();
    my $dataBbox   = Giovanni::BoundingBox->new(
        WEST  => $dataFieldInfo->get_west(),
        SOUTH => $dataFieldInfo->get_south(),
        EAST  => $dataFieldInfo->get_east(),
        NORTH => $dataFieldInfo->get_north()
    );
    my $resolution         = $dataFieldInfo->get_resolution();
    my $nominalUnits       = $dataFieldInfo->get_dataFieldUnitsValue();
    my $temporalResolution = $dataFieldInfo->get_dataProductTimeInterval();
    my $platformInstrument
        = $dataFieldInfo->get_dataProductPlatformInstrument();

    # read in input.xml
    my $xpc = XML::LibXML::XPathContext->new(
        XML::LibXML->new()->parse_file( $params{INPUT} ) );

    # find the data node for this variable
    my @dataNodes = $xpc->findnodes("/input/data");
    my $dataNode;
    for my $node (@dataNodes) {
        my $nodeId = $node->textContent();
        Giovanni::Util::trim($nodeId);
        if ( $nodeId eq $id ) {
            $dataNode = $node;
        }
    }
    if ( !defined($dataNode) ) {
        die "Unable to find data information for $id in "
            . $params{INPUT} . ".";
    }
    my $userUnits = $dataNode->getAttribute('units');
    my $zValue    = $dataNode->getAttribute('zValue');

    # get the user's bounding box out of input.xml, if it exists
    my @bboxNodes = $xpc->findnodes("/input/bbox");
    my $userBbox  = undef;
    if ( scalar(@bboxNodes) == 1 ) {
        $userBbox = Giovanni::BoundingBox->new(
            STRING => $bboxNodes[0]->textContent() );
    }

    # get the data out of the data file
    my $startTime;
    my $endTime;
    if ( defined( $params{DATA} ) ) {

        # get the start time out of the data
        my $header = Giovanni::Data::NcFile::get_xml_header( $params{DATA} );
        $startTime = $header->findvalue(
            '/nc:netcdf/nc:attribute[@name="start_time"]/@value');
        $endTime = $header->findvalue(
            '/nc:netcdf/nc:attribute[@name="end_time"]/@value');
    }
    else {

        # get the start time from the user's request
        $startTime = $xpc->findvalue("/input/starttime");
        $endTime   = $xpc->findvalue("/input/endtime");
    }

    # TODO: add code to get the data start and end time out of the data
    # file

    # calculate what the final bounding box is
    my $bbox;
    if ( defined($userBbox) ) {
        my @intersections
            = Giovanni::BoundingBox::getIntersection( $userBbox, $dataBbox );

        # there will be exactly one intersection in this case
        $bbox = $intersections[0]->getString();
    }
    elsif ( defined($xpc->findvalue("/input/shape"))) {
        # if there is shp file in input, just use the output data bounding box
        $bbox = Giovanni::Data::NcFile::data_bbox($params{'DATA'});
    }
    else {

        # if there is no user bounding box, just use the data bounding box
        $bbox = $dataBbox->getString();
    }

    # final units
    my $units = defined($userUnits) ? $userUnits : $nominalUnits;

    # create the standard variable string shown in plots
    my $fullName = Giovanni::Visualizer::Hints::createDataFieldString(
        LONG_NAME           => $long_name,
        TIME_RESOLUTION     => $temporalResolution,
        SPATIAL_RESOLUTION  => $resolution,
        PLATFORM_INSTRUMENT => $platformInstrument,
        PRODUCT_SHORTNAME   => $product,
        VERSION             => $version,
        THIRD_DIM_VALUE     => $zValue,
        THIRD_DIM_UNITS     => $zUnits,
        UNITS               => $units,
    );

    # create the start and end time strings
    my $startTimeStr = Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => $startTime,
        INTERVAL    => $temporalResolution,
        IS_START    => 1
    );
    my $endTimeStr = Giovanni::Visualizer::Hints::Time::formatTime(
        TIME_STRING => $endTime,
        INTERVAL    => $temporalResolution,
        IS_START    => 0
    );
    my $timeRange;
    if ( $startTimeStr eq $endTimeStr ) {
        $timeRange = $startTimeStr;
    }
    else {
        $timeRange = "$startTimeStr - $endTimeStr";
    }

    my %out = (
        FULL_NAME           => $fullName,
        TIME_RANGE          => $timeRange,
        BBOX                => $bbox,
        LONG_NAME           => $long_name,
        SPATIAL_RESOLUTION  => $resolution,
        PLATFORM_INSTRUMENT => $platformInstrument,
        PRODUCT_SHORTNAME   => $product,
        VERSION             => $version,
        ZVALUE              => $zValue,
        ZUNITS              => $zUnits,
        UNITS               => $units,
        ORIGINAL_UNITS      => $nominalUnits,
        NOMINAL_MIN         => $nominalMin,
        NOMINAL_MAX         => $nominalMax,
        VALUES_DISTRIBUTION => $values_distribution,
        SLDS                => $slds
    );

    return %out;
}

1;
__END__

=head1 NAME

Giovanni::Map::Info - Perl extension for getting variable-specific info for
getGiovanniMapInfo.pl

=head1 SYNOPSIS

  use Giovanni::Map::Info;
  
  my %info = Giovanni::Map::Info::gatherVariableInfo(DATA_FIELD_INFO=>$infoFile, INPUT=>$inputFile);

=head1 DESCRIPTION

Get the variable information for getGiovanniMapInfo.pl. Inputs:

=over

=item DATA_FIELD_INFO - the data field info file. (a.k.a. var info)

=item INPUT - the input.xml file.

=back


Returns a hash with the following entries:

=over

=item FULL_NAME - Fully qualified variable name with units, pressure level, product, etc.  E.g. - 'Geopotential Height (Daytime/Ascending) daily 1 deg. [AIRS AIRX3STD v006] C'       

=item TIME_RANGE - Time range for the plot. E.g. - '2003-01-01 - 2003-12-31'

=item BBOX - Bounding box. E.g. - '10W, 10S, 2W, 35.6N'

=item LONG_NAME - Variable long name. E.g. 'Geopotential Height (Daytime/Ascending)'

=item SPATIAL_RESOLUTION - Spatial resolution

=item PLATFORM_INSTRUMENT - Platform or instrument. E.g. - TRMM

=item PRODUCT_SHORTNAME - Product shortname. E.g - TRMM_3B43

=item VERSION - Product version. E.g. - 006

=item ZVALUE - Vertical dimension value. Undef if not applicable. E.g. - 1000

=item ZUNITS - Vertical dimension units. Undef if not applicable. E.g. - hPa

=item UNITS - units. E.g. - m

=item ORIGINAL_UNITS - units before conversion

=item NOMINAL_MIN - very small or below the real minimum value

=item NOMINAL_MAX - very small above the real maximum value

=item SLDS - the descriptor file for the color palette

=back

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>



=cut
