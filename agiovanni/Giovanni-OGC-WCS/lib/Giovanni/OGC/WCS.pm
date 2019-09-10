package Giovanni::OGC::WCS;

use 5.008008;
use strict;
use warnings;
use DateTime;
use JSON qw( decode_json );
use LWP::UserAgent;
use Giovanni::Agent;
use Giovanni::Util;
require Exporter;

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

our $VERSION = '0.01';

1;

# submit and monitor service manager request, then update map file template and return map file
sub getCoverage {

    my ($wcsRequest) = @_;
    my $dataCoverage = $wcsRequest->{'data'};

    # query catalogue to get variable metadata
    my $catalogUrl    = $GIOVANNI::DATA_CATALOG;
    my $catalog       = Giovanni::Catalog->new( { URL => $catalogUrl } );
    my $fields        = [$dataCoverage];
    my $fInfo         = $catalog->getDataFieldInfo( { FIELDS => $fields } );
    my @zDimValues    = split( / /, $fInfo->{$dataCoverage}{zDimValues} );
    my $latResolution = $fInfo->{$dataCoverage}{latitudeResolution};
    my $lonResolution = $fInfo->{$dataCoverage}{longitudeResolution};
    my $timeInterval  = $fInfo->{$dataCoverage}{dataProductTimeInterval};

    # validate z dimension
    if ( defined $wcsRequest->{'bands'} ) {
        if ( grep /^$wcsRequest->{'bands'}$/, @zDimValues ) {
            $dataCoverage
                = $dataCoverage . "(z=" . $wcsRequest->{'bands'} . ")";
        }
        else {
            return
                "The requested band $wcsRequest->{'bands'} is not avaliable";
        }
    }

    # add constraints on time to avoid time-out issue
    my $sTime = $wcsRequest->{'startTime'};
    my $eTime = $wcsRequest->{'endTime'};
    my ( $sY, $sM, $sD, $sH, $sMi, $sS )
        = $sTime =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/;
    my ( $eY, $eM, $eD, $eH, $eMi, $eS )
        = $eTime =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/;
    my ($sdt, $edt); 
    eval { $sdt = DateTime->new(
        year   => $sY,
        month  => $sM,
        day    => $sD,
        hour   => $sH,
        minute => $sMi,
        second => $sS
    );};
    return "Invalid start time" if $@;
    eval { $edt = DateTime->new(
        year   => $eY,
        month  => $eM,
        day    => $eD,
        hour   => $eH,
        minute => $eMi,
        second => $eS
    );};
    return "Invalid end time" if $@;

    my $maxInterval;
    my $cmp;

    if ( $lonResolution >= 1 ) {
        $maxInterval = 9;    # The  max number of data files to be used is 9
        $cmp = validateTimeRange( $maxInterval, $timeInterval, $sdt, $edt );
    }
    elsif ( $lonResolution >= 0.25 ) {
        $maxInterval = 7;    #The  max number of data files is 7
        $cmp = validateTimeRange( $maxInterval, $timeInterval, $sdt, $edt );
    }
    else {
        $maxInterval = 6;    #The  max number of data files is 6
        $cmp = validateTimeRange( $maxInterval, $timeInterval, $sdt, $edt );
    }
    return $cmp unless $cmp =~ m/ok/i;

    # generate service manager request
    my $serviceManager = 
        Giovanni::Util::createAbsUrl("daac-bin/service_manager.pl?service="
        . $wcsRequest->{'service'}
        . "&data="
        . $dataCoverage
        . "&starttime="
        . $sTime
        . "&endtime="
        . $eTime
        . "&bbox="
        . $wcsRequest->{'bbox'}
        . "&portal=GIOVANNI&format=xml");

    # invoke service manager
    my $agent = Giovanni::Agent->new( URL => $serviceManager );
    my $requestResponse = $agent->submit_request;
    if ( $requestResponse->errorMessage ) {
        return $requestResponse->errorMessage;
    }

    # get data path
    my ($dataUrl) = $requestResponse->data_urls;
    return "Data is not available" if not defined $dataUrl;
    my $oDataFile = $dataUrl =~ /^.+\/session\/(.+$)/ ? $1 : not defined;
    return "Data is not available" if not defined $oDataFile;
    $oDataFile = $GIOVANNI::SESSION_LOCATION . "/" . $oDataFile;

    # change output size
    my @boundingBox = split( /,/, $wcsRequest->{'bbox'} );
    my $reqLonRes
        = ( $boundingBox[2] - $boundingBox[0] ) / $wcsRequest->{'width'};
    my $reqLatRes
        = ( $boundingBox[3] - $boundingBox[1] ) / $wcsRequest->{'height'};
    my $dataFile = $oDataFile;
    if ( $reqLonRes != $lonResolution || $reqLatRes != $latResolution ) {
        $dataFile = $oDataFile . "out";
        system(
            "gdal_translate -of netCDF -outsize $wcsRequest->{'width'} $wcsRequest->{'height'} $oDataFile $dataFile >/dev/null"
        );
        system(
            "ncatted -O -a latitude_resolution,$wcsRequest->{'data'},o,d,$reqLatRes $dataFile >/dev/null"
        );
        system(
            "ncatted -O -a longitude_resolution,$wcsRequest->{'data'},o,d,$reqLonRes $dataFile >/dev/null"
        );
    }
    return "Failed to generate the data" unless -f $dataFile;

    if ( $wcsRequest->{'format'} =~ m/tiff/i ) {
        my $tifFile = $dataFile . ".tif";
        system(
            "gdal_translate -ot Float32 -of GTiff $dataFile $tifFile >/dev/null"
        );
        return "Failed to generate TIFF file" unless -f $tifFile;
        return $tifFile;
    }
    elsif ( $wcsRequest->{'format'} =~ m/asc/i ) {
        my $ascFile = $dataFile . ".xyz";
        system("gdal_translate -of XYZ $dataFile $ascFile >/dev/null");
        return "Failed to generate ASCII file" unless -f $ascFile;
        return $ascFile;
    }
    elsif ( $wcsRequest->{'format'} =~ m/netcdf/i ) {
        return $dataFile;
    }
}

# time range is ok or not
sub validateTimeRange {
    my ( $maxInterval, $timeInterval, $sdt, $edt ) = @_;
    my $ndt;
    if ( $timeInterval =~ m/monthly/i ) {
        $ndt = $sdt->add( months => $maxInterval );
        return "Please select the data less than or equal $maxInterval months"
            if ( DateTime->compare( $ndt, $edt ) ) <= 0;
    }
    elsif ( $timeInterval =~ m/daily/i ) {
        $ndt = $sdt->add( days => $maxInterval - 1 );
        return "Please select the data less than or equal $maxInterval days"
            if ( DateTime->compare( $ndt, $edt ) ) <= 0;
    }
    elsif ( $timeInterval =~ m/^hourly/i ) {
        $ndt = $sdt->add( hours => $maxInterval - 1 );
        return "Please select the data less than or equal $maxInterval hours"
            if ( DateTime->compare( $ndt, $edt ) ) <= 0;
    }
    elsif ( $timeInterval =~ m/half-hourly/i ) {
        $maxInterval = $maxInterval / 2;
        $ndt = $sdt->add( hours => ( $maxInterval - 0.5 ) );
        return
              "Please select the data less than or equal "
            . $maxInterval
            . " hours"
            if ( DateTime->compare( $ndt, $edt ) ) <= 0;
    }
    elsif ( $timeInterval =~ m/3-hourly/i ) {
        $maxInterval = $maxInterval * 3;
        $ndt = $sdt->add( hours => ( $maxInterval - 1 ) );
        return
              "Please select the data less than or equal "
            . $maxInterval
            . " hours"
            if ( DateTime->compare( $ndt, $edt ) ) <= 0;
    }
    return "ok";

}

sub generateMapFile {
    my $resultDir = $GIOVANNI::SESSION_LOCATION;
    my $capaFile  = File::Temp->new(
        TEMPLATE => 'agwcs' . '_XXXX',
        DIR      => $resultDir,
        SUFFIX   => '.map'
    );
    my $catalogUrl = $GIOVANNI::DATA_CATALOG;
    open CFILE, ">$capaFile" or die "Error opening $capaFile";
    print CFILE "MAP\n";
    print CFILE "  NAME \"GES_DISC_Giovanni_WCS\"\n";
    print CFILE "  STATUS ON\n";
    print CFILE "  EXTENT  -180 -90 180 90\n";
    print CFILE "  FONTSET \"/opt/giovanni4/cfg/fonts/font.list\"\n";
    print CFILE "  PROJECTION\n";
    print CFILE "    \"init=epsg:4326\"\n";
    print CFILE "  END\n";
    print CFILE "  SIZE 2000 1000\n";
    print CFILE "  UNITS DD\n";
    print CFILE "  WEB\n";
    print CFILE "    IMAGEPATH \"/var/tmp/www\"\n";
    print CFILE "    IMAGEURL \"WWW-TEMP\"\n";
    print CFILE "    METADATA\n";
    print CFILE "      \"wcs_label\" \"OGC WCS for NASA Giovanni\"\n";
    print CFILE
        "      \"wcs_contactelectronicmailaddress\" \"help-disc\@listserv.gsfc.nasa.gov\"\n";
    print CFILE
        "      \"wms_contactorganization\" \"Goddard Earth Sciences Data and Information Services Center\"\n";
    print CFILE "      \"wcs_contactperson\" \"Mahabaleshwa Hegde\"\n";
    print CFILE "      \"wcs_contactvoicetelephone\" \"301-614-5190\"\n";
    print CFILE
        "      \"wcs_onlineresource\" \"http://giovanni.gsfc.nasa.gov/giovanni/daac-bin/wcs_ag4\"\n";
    print CFILE "      \"ows_enable_request\" \"*\"\n";
    print CFILE "    END\n";
    print CFILE "  END\n";

    print CFILE "  OUTPUTFORMAT\n";
    print CFILE "    NAME  NETCDF\n";
    print CFILE "    DRIVER  \"GDAL/netcdf\"\n";
    print CFILE "    MIMETYPE  \"image/netcdf\"\n";
    print CFILE "    IMAGEMODE  FLOAT32\n";
    print CFILE "    EXTENSION  \"nc\" \n";
    print CFILE "  END\n";
    print CFILE "  OUTPUTFORMAT\n";
    print CFILE "    NAME  GEOTIFF\n";
    print CFILE "    DRIVER  \"GDAL/GTiff\"\n";
    print CFILE "    MIMETYPE  \"image/tiff32\"\n";
    print CFILE "    IMAGEMODE  FLOAT32\n";
    print CFILE "    EXTENSION  \"tif\" \n";
    print CFILE "  END\n";

    my $catalog = Giovanni::Catalog->new( { URL => $catalogUrl } );
    my $layers
        = $catalog->getActiveDataFields(
        qw(long_name startTime endTime responseFormat west south east north sdsName dataFieldStandardName longitudeResolution latitudeResolution zDimUnits zDimName zDimValues)
        );
    return 0 if not defined $layers;
    foreach my $key ( keys %$layers ) {
        $layers->{$key}{'longitudeResolution'} = 1
            if $layers->{$key}{'longitudeResolution'} > 180;
        $layers->{$key}{'latitudeResolution'} = 1
            if $layers->{$key}{'latitudeResolution'} > 90;
        print CFILE "  LAYER\n";
        print CFILE "    NAME \"Time-Averaged.$key\"\n";
        print CFILE "    TYPE RASTER\n";
        print CFILE "    STATUS ON\n";
        print CFILE "    PROJECTION\n";
        print CFILE "      \"init=epsg:4326\"\n";
        print CFILE "    END\n";
        print CFILE "    METADATA\n";
        print CFILE "      \"wcs_label\" \""
            . $layers->{$key}{'long_name'} . "\"\n";
        print CFILE "      \"wcs_formats\" \"NETCDF GEOTIFF ASCII\"\n";
        print CFILE "      \"wcs_timeposition\" \""
            . $layers->{$key}{'startTime'} . "/"
            . $layers->{$key}{'endTime'} . "\"\n";
        print CFILE "      \"wcs_resolution\" \""
            . $layers->{$key}{'longitudeResolution'} . " "
            . $layers->{$key}{'latitudeResolution'} . "\"\n";
        print CFILE "      \"ows_srs\" \"EPSG:4326\"\n";
        print CFILE "      \"wcs_nativeformat\" \""
            . $layers->{$key}{'responseFormat'} . "\"\n";
        print CFILE "      \"ows_extent\" \""
            . $layers->{$key}{'west'} . " "
            . $layers->{$key}{'south'} . " "
            . $layers->{$key}{'east'} . " "
            . $layers->{$key}{'north'} . "\"\n";

        if ( defined $layers->{$key}{'zDimUnits'} ) {
            my @bandCount = split( " ", $layers->{$key}{'zDimValues'} );
            if ( @bandCount > 0 ) {
                print CFILE "      \"wcs_bandcount\" \""
                    . @bandCount . "\"\n";
                print CFILE "      \"wcs_rangeset_name\" \"" . "Bands\"\n";
                print CFILE "      \"wcs_rangeset_label\" \""
                    . $layers->{$key}{'dataFieldStandardName'} . "\"\n";
                print CFILE "      \"wcs_rangeset_axes\" \""
                    . $layers->{$key}{'zDimName'} . "\"\n";
                print CFILE "      \"wcs_"
                    . $layers->{$key}{'zDimName'}
                    . "_label\" \""
                    . $layers->{$key}{'zDimName'} . "\"\n";
                print CFILE "      \"wcs_"
                    . $layers->{$key}{'zDimName'}
                    . "_values\" \""
                    . $layers->{$key}{'zDimValues'} . "\"\n";
            }
        }
        print CFILE "    END\n";
        print CFILE "  END\n";
    }
    print CFILE "END\n";
    close CFILE;
    return $capaFile;

}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Giovanni::OGC::WCS - Class for creating a WCS interface for AG

=head1 SYNOPSIS

  use Giovanni::OGC::WCS;
  my $ogc = Giovanni::OGC::WCS::getCoverage($hash);
  
=head1 DESCRIPTION

Giovanni::OGC::WCS provides a OGC WCS interface for AG. It accepts WCS request and translates it into AG requests, and invokes AG workflow to return the data to stdout.
 
=back

=head1 METHODS

=over 4

=item generateMapFile

generateMapFile() query the catalog to get variable information and generate a map file. 

=back

=head1 METHODS

=over 4

=item getCoverage($wcsOptionHash)

getCoverage() submits and monitors service manager request. If the request is successful, then generate a map file.

=back


=head1 EXPORT

All.

=head1 SEE ALSO

=head1 AUTHOR

Peisheng Zhao, E<lt>peisheng.zhao-1@nasa.gov<gt>

=cut
