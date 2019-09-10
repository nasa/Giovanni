#!/usr/bin/perl
################################################################################
# $Id: populateEddaCatalogFromAgDataDescriptors.pl,v 1.13 2015/05/14 20:43:23 eseiler Exp $
# -@@@ aGiovanni Version: $Name:  $
################################################################################
#
# Script for populating a directory tree workspace with data product and data
# field files using information extracted from G3 data descriptors

#

my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    if (defined $rootPath) {
        push( @INC, $rootPath . 'share/perl5/site_perl/' . sprintf( "%vd", $^V ) );
        push( @INC, $rootPath . 'share/perl5/' );
        push( @INC, $rootPath . 'lib/perl5/' );
    }
}

use strict;
use XML::LibXML;
use XML::LibXSLT;
use DateTime;
use LWP::Simple;
use File::Copy;
use Getopt::Long;
use EDDA::DataProbe;
use Safe;

my $help;
my $overWriteFlag;
my $result = Getopt::Long::GetOptions ("help"      => \$help,
                                       "overwrite" => \$overWriteFlag);
my $usage = "usage: $0 [--overwrite] g3ddFileDir [g3ddFile]\n\ne.g. $0 /var/tmp/eseiler/g3prototype/xml/datadescriptions\n";

if ($help) {
    print STDERR $usage;
    exit 0;
}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

# Takes one argument:
#  -- directory containing G3 data description files for each product
my $g3ddFileDir = $ARGV[0];
# One optional argument
#  -- name of only G3 data description file
my $g3ddFile = $ARGV[1];

my $bad_g3ddFileDir = $g3ddFileDir;
$bad_g3ddFileDir =~ s/haveDifIds/badDifIds/;
if ($bad_g3ddFileDir ne $g3ddFileDir) {
    die "Writeable directory $bad_g3ddFileDir does not exist\n" unless -w $bad_g3ddFileDir;
}

unless ( (defined $g3ddFileDir) ) {
    print STDERR "$usage";
    exit 0;
}
die "Could not find data description file directory '$g3ddFileDir'" unless -d $g3ddFileDir;

my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read configuration file $cfgFile\n";
}
die "Could not find AESIR directory '$CFG::AESIR_CATALOG_DIR'" unless -d $CFG::AESIR_CATALOG_DIR;

my @ddFiles;
if ($g3ddFile) {
    @ddFiles = ($g3ddFile);
} else {
    die "Could not open $g3ddFileDir: $!\n"
        unless opendir(DIR, $g3ddFileDir);
    @ddFiles = grep { !/^\./ && -f "$g3ddFileDir/$_" } readdir(DIR);
    closedir(DIR);
}

my $xslt = XML::LibXSLT->new();
my $styleSheet;
eval { $styleSheet = $xslt->parse_stylesheet_file($CFG::AESIR_CATALOG_DATA_PRODUCTS_XSL); };
if ($@) {
    die "Error parsing stylesheet $CFG::AESIR_CATALOG_DATA_PRODUCTS_XSL: $@";
}

my $dataProductsDir = "$CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR";
my $dataFieldsDir = "$CFG::AESIR_CATALOG_DATA_FIELDS_DIR";
mkdir $dataProductsDir;
die "$dataProductsDir does not exist and could not be created\n" unless -d $dataProductsDir;
chmod 0777, $dataProductsDir;
mkdir $dataFieldsDir;
die "$dataFieldsDir does not exist and could not be created\n" unless -d $dataFieldsDir;
chmod 0777, $dataFieldsDir;

my $now = DateTime->now->iso8601 . 'Z';


# Loop through each data descriptor
DDFILE: foreach my $ddFile (@ddFiles) {

    my $dataDescriptionFile = "$g3ddFileDir/$ddFile";
    unless (-r $dataDescriptionFile) {
        print STDERR "Readable file $dataDescriptionFile not found\n";
        next;
    }

    # Parse data description file for the data product and extract information
    my $ddDom;
    eval { $ddDom = $parser->parse_file( $dataDescriptionFile ); };
    if ($@) {
        die "Could not read and parse $dataDescriptionFile\n";
    }
    my $ddDoc = $ddDom->documentElement();

    my $node;

    ($node) = $ddDoc->findnodes( '/dataProductType/dataProductName' );
    my $dataProductShortName = $node->textContent() if $node;

    ($node) = $ddDoc->findnodes( '/dataProductType/dataProductVersion' );
    my $dataProductVersion = $node->textContent() if $node;

    my $dataProductId = $dataProductShortName . '.' . $dataProductVersion
        if ( (defined $dataProductShortName) && (defined $dataProductVersion) );
    unless (defined $dataProductId) {

        my $msg = 'No value found for ';
        my $msg2 = 'dataProductName ' unless defined $dataProductShortName;
        unless (defined $dataProductVersion) {
            $msg2 .= 'and ' if defined $msg2;
            $msg2 .= 'dataProductVersion ';
        }
        print STDERR  $msg . $msg2 . "in $dataDescriptionFile, so skipping it\n";
        next;
    }

    my $newDataProductDom = $parser->parse_string($CFG::DATA_PRODUCT_XML);
    my $newDataProductDoc = $newDataProductDom->documentElement();
    my %newDataProductHash;


    if ($dataProductId =~ /_HDF4/) {
        print STDERR "Changing productId $dataProductId to ";
        $dataProductId =~ s/_HDF4//g;
        print STDERR "$dataProductId\n";
    }

    $newDataProductHash{'dataProductId'}        = $dataProductId;
    $newDataProductHash{'dataProductShortName'} = $dataProductShortName;
    $newDataProductHash{'dataProductVersion'}   = $dataProductVersion;

    my $dataProductDescriptionUrl;
    ($node) = $ddDoc->findnodes( '/dataProductType/descriptionUrl' );
    $dataProductDescriptionUrl = $node->textContent() if ($node);
    $newDataProductHash{'dataProductDescriptionUrl'} = $dataProductDescriptionUrl if $dataProductDescriptionUrl;

    my $dataProductGcmdEntryId;
    if ($dataProductDescriptionUrl =~ /getdif\.htm\?(.+)$/) {
        $dataProductGcmdEntryId = $1;
    } elsif ($dataProductDescriptionUrl =~ /EntryId=(.+?)(?:&.+)?$/) {
        $dataProductGcmdEntryId = $1;
    } else {
        my $shortName = $dataProductShortName;
        $shortName =~ s/_HDF4//g;
        $dataProductGcmdEntryId = 'GES_DISC_' . $shortName .
                                   '_V' . $dataProductVersion;
        print STDERR "Assuming DIF Entry_ID=$dataProductGcmdEntryId\n";
    }
    $newDataProductHash{'dataProductGcmdEntryId'} = $dataProductGcmdEntryId if $dataProductGcmdEntryId;

    ($node) = $ddDoc->findnodes( '/dataProductType/processingLevel' );
    my $dataProductProcessingLevel = $node->textContent() if ($node);
    $newDataProductHash{'dataProductProcessingLevel'} = $dataProductProcessingLevel if $dataProductProcessingLevel;

    ($node) = $ddDoc->findnodes( '/dataProductType/timeFrequency' );
    my $dataProductTimeFrequency = $node->textContent() if $node;
    $newDataProductHash{'dataProductTimeFrequency'} = $dataProductTimeFrequency if $dataProductTimeFrequency;

    ($node) = $ddDoc->findnodes( '/dataProductType/timeInterval' );
    my $dataProductTimeInterval = $node->textContent() if $node;
    
    # We won't use dataProductTimeFrequency any more, so instead make
    # dataProductTimeInterval contain all information about the interval duration
    $dataProductTimeInterval = $dataProductTimeFrequency . '-' . $dataProductTimeInterval
        if defined($dataProductTimeInterval) && defined($dataProductTimeFrequency) && $dataProductTimeFrequency ne '1';
    $newDataProductHash{'dataProductTimeInterval'} = $dataProductTimeInterval if $dataProductTimeInterval;

    ($node) = $ddDoc->findnodes( '/dataProductType/sensorName' );
    my $dataProductSensorName = $node->textContent() if $node;
    $newDataProductHash{'dataProductSensorName'} = $dataProductSensorName if $dataProductSensorName;

    # Information about each data product obtained from the DIF
    my $dif;
    my $dataProductLongName;
    my $dataProductPlatformShortName;
    my $dataProductPlatformLongName;
    my $dataProductInstrumentShortName;
    my $dataProductInstrumentLongName;
    my $dataProductLatitudeResolution;
    my $dataProductLongitudeResolution;
    my $dataProductSpatialResolution;
    my $dataProductDataCenter;
    my $dataProductBeginDateTime;
    my $dataProductEndDateTime;

    # By default, spatial coverage will be global.
    my $dataProductWest  = -180.0;
    my $dataProductNorth =   90.0;
    my $dataProductEast  =  180.0;
    my $dataProductSouth =  -90.0;

    if ($dataProductGcmdEntryId) {

        $dataProductDescriptionUrl = 'http://gcmd.gsfc.nasa.gov/getdif.htm?' .
                                     $dataProductGcmdEntryId;
        $newDataProductHash{'dataProductDescriptionUrl'} = $dataProductDescriptionUrl if $dataProductDescriptionUrl;

        # Attempt to fetch the DIF
        my $difURL = "http://gcmd.nasa.gov/OpenAPI/getdif.py?entry_id=$dataProductGcmdEntryId&format=xml";
        # Temporary fix
#        my $difURL = "http://gcmd.nasa.gov/OpenAPI/getdif.py?entry_id=$dataProductGcmdEntryId&format=xml&lbnode=mdlb6";
        my $max_fetch_attempts = 3;
        my $sleep_seconds = 5;
        for ( my $attempt = 1 ;
              $attempt <= $max_fetch_attempts ;
              $attempt++ ) {
            $dif = LWP::Simple::get(
                                    "http://gcmd.nasa.gov/OpenAPI/getdif.py?entry_id=$dataProductGcmdEntryId&format=xml"
                                   );
            last if ( defined $dif );
            print STDERR "Unsuccessful attempt [$attempt of "
                       . "$max_fetch_attempts] to fetch full DIF"
                       . " for $dataProductGcmdEntryId, sleeping...\n";
            sleep $sleep_seconds;
        }
        unless (defined $dif) {
#            move ($dataDescriptionFile, "$bad_g3ddFileDir/$ddFile");
#            print STDERR "Moved $dataDescriptionFile to $bad_g3ddFileDir\n";
            next DDFILE;
        }
    }
    if (defined $dif) {

        # Extract information from the fetched DIF

        # If the DIF defines a default namespace, then every XPATH
        # expression will need to use a prefix (according to the
        # documentation for XML::LibXML::Node). In order to avoid
        # forcing this script or any other script that parses
        # the fetched DIF from having to use a prefix in every
        # XPATH expression, we will use a hack here and delete any
        # definition of a default namespace.
        $dif =~ s/xmlns=".+"//;

        my $difDom = $parser->parse_string($dif);
        my $difDoc = $difDom->documentElement();

        ($node) = $difDoc->findnodes( '/DIF/Data_Set_Citation/Dataset_Title' );
        if ($node) {
            $dataProductLongName = $node->textContent();
            $dataProductLongName =~ s/^\s+//;
            $dataProductLongName =~ s/\s+$//;
        } else {
            ($node) = $difDoc->findnodes( '/DIF/Entry_Title' );
            if ($node) {
                $dataProductLongName = $node->textContent();
                $dataProductLongName =~ s/^\s+//;
                $dataProductLongName =~ s/\s+$//;
                print STDERR "No Data_Set_Citation/Dataset_Title for $dataProductGcmdEntryId, using Entry_Title\n";
            } else {
                print STDERR "No Data_Set_Citation/Dataset_Title or Entry_Title for $dataProductGcmdEntryId\n";
            }
        }

        if ($dataProductLongName) {
            $newDataProductHash{'dataProductLongName'} = $dataProductLongName;
            $newDataProductHash{'dataProductDataSetId'} = $dataProductLongName;
            if (defined $dataProductVersion) {
                $newDataProductHash{'dataProductDataSetId'} .= ' V' . $dataProductVersion;
            }
        }

        my (@sourceNameNodes) = $difDoc->findnodes( '/DIF/Source_Name' );
        if (@sourceNameNodes) {
            my $sourceNameNode = $sourceNameNodes[0];
            ($node) = $sourceNameNode->findnodes( './Short_Name' );
            $dataProductPlatformShortName = $node->textContent() if $node;
            ($node) = $sourceNameNode->findnodes( './Long_Name' );
            $dataProductPlatformLongName = $node->textContent() if $node;
            unless ($dataProductPlatformShortName) {
                $dataProductPlatformShortName = $dataProductPlatformLongName
                    if $dataProductPlatformLongName;
            }
            unless ($dataProductPlatformLongName) {
                $dataProductPlatformLongName = $dataProductPlatformShortName
                    if $dataProductPlatformShortName;
            }
       }

        my (@sensorNameNodes) = $difDoc->findnodes( '/DIF/Sensor_Name' );
        foreach my $sensorNameNode (@sensorNameNodes) {
            ($node) = $sensorNameNode->findnodes( './Short_Name' );
            $dataProductInstrumentShortName = $node->textContent() if $node;
            ($node) = $sensorNameNode->findnodes( './Long_Name' );
            $dataProductInstrumentLongName = $node->textContent() if $node;
            last if ($dataProductInstrumentShortName && $dataProductInstrumentLongName);
        }
        unless ($dataProductInstrumentShortName) {
            $dataProductInstrumentShortName = $dataProductInstrumentLongName
                if $dataProductInstrumentLongName;
        }
        unless ($dataProductInstrumentLongName) {
            $dataProductInstrumentLongName = $dataProductInstrumentShortName
                if $dataProductInstrumentShortName;
        }

        # If platform or instrument is not defined, but the data product
        # longname indicates that a model was used, set the platform
        # and/or instrument to 'Model'
        if (defined $dataProductPlatformShortName) {
            $dataProductPlatformShortName = 'Aqua'
                if $dataProductPlatformShortName eq 'AQUA';
            $dataProductPlatformShortName = 'Aura'
                if $dataProductPlatformShortName eq 'AURA';
            $dataProductPlatformShortName = 'Terra'
                if $dataProductPlatformShortName eq 'TERRA';
        } else {
            if ( $dataProductLongName =~ /gocart model/i ) {
                $dataProductPlatformShortName = 'GOCART Model';
            }
            elsif ( $dataProductLongName =~ /model/i ) {
                $dataProductPlatformShortName = 'Model';
            }
            elsif ( $dataProductLongName =~ /SeaWiFS/i ) {
                $dataProductPlatformShortName = 'OrbView-2';
            }
            elsif ( $dataProductSensorName =~ /MERRA/i ) {
                $dataProductPlatformShortName = 'MERRA Data Model';
            }
        }
        unless (defined $dataProductPlatformLongName) {
            if ( $dataProductLongName =~ /gocart model/i ) {
                $dataProductPlatformLongName = 'GOCART Model';
            }
            elsif ( $dataProductLongName =~ /model/i ) {
                $dataProductPlatformLongName = 'Model';
            }
            elsif ( $dataProductLongName =~ /SeaWiFS/i ) {
                $dataProductPlatformLongName = 'Orbital Sciences Corporation OrbView-2 Satellite';
            }
            elsif ( $dataProductSensorName =~ /MERRA/i ) {
                $dataProductPlatformLongName = 'MERRA Data Model';
            }
        }
        if (defined $dataProductInstrumentShortName) {
            $dataProductInstrumentShortName = 'SeaWiFS'
                if $dataProductInstrumentShortName eq 'SEAWIFS';
        } else {
            if ( $dataProductLongName =~ /gocart model/i ) {
                $dataProductInstrumentShortName = 'GOCART Model';
            }
            elsif ( $dataProductLongName =~ /model/i ) {
                $dataProductInstrumentShortName = 'Model';
            }
            elsif ( $dataProductSensorName =~ /MERRA/i ) {
                $dataProductInstrumentShortName = 'MERRA Data Model';
            }
        }
        unless (defined $dataProductInstrumentLongName) {
            if ( $dataProductLongName =~ /gocart model/i ) {
                $dataProductInstrumentLongName = 'GOCART Model';
            }
            elsif ( $dataProductLongName =~ /model/i ) {
                $dataProductInstrumentLongName = 'Model';
            }
            elsif ( $dataProductSensorName =~ /MERRA/i ) {
                $dataProductInstrumentLongName = 'MERRA Data Model';
            }
        }
        $newDataProductHash{'dataProductPlatformShortName'} = $dataProductPlatformShortName if $dataProductPlatformShortName;
        $newDataProductHash{'dataProductPlatformLongName'} = $dataProductPlatformLongName if $dataProductPlatformLongName;
        $newDataProductHash{'dataProductInstrumentShortName'} = $dataProductInstrumentShortName if $dataProductInstrumentShortName;
        $newDataProductHash{'dataProductInstrumentLongName'} = $dataProductInstrumentLongName if $dataProductInstrumentLongName;

        my $platInstVal;
        if ($dataProductPlatformShortName eq 'Terra') {
            if ($dataProductInstrumentShortName eq 'MODIS') {
                $platInstVal = 'MODIS-Terra';
            } elsif ($dataProductInstrumentShortName eq 'MISR') {
                $platInstVal = 'MISR';
            }
        } elsif ($dataProductPlatformShortName eq 'Aqua') {
            if ($dataProductInstrumentShortName eq 'MODIS') {
                $platInstVal = 'MODIS-Aqua';
            } elsif ($dataProductInstrumentShortName eq 'AIRS') {
                $platInstVal = 'AIRS';
            }
        } elsif ($dataProductPlatformShortName eq 'Aura') {
            if ($dataProductInstrumentShortName eq 'OMI') {
                $platInstVal = 'OMI';
            }
        } elsif ($dataProductPlatformShortName eq 'GOCART Model') {
            $platInstVal = 'GOCART Model';
        } elsif ($dataProductPlatformShortName eq 'OrbView-2') {
            if ($dataProductInstrumentShortName eq 'SeaWiFS') {
                $platInstVal = 'SeaWiFS';
            }
        } elsif ($dataProductPlatformShortName eq 'TRMM') {
            $platInstVal = 'TRMM';
        } elsif ($dataProductPlatformShortName eq 'EPA') {
            if ($dataProductInstrumentShortName eq 'AIRNow') {
                $platInstVal = 'EPA AIRNow';
            }
        } elsif ($dataProductPlatformShortName =~ /^NLDAS/) {
            $platInstVal = 'NLDAS';
        } elsif ($dataProductPlatformShortName eq 'DMSP') {
            if ($dataProductInstrumentShortName eq 'SSMI') {
                $platInstVal = 'SSMI';
            }
        } elsif ($dataProductPlatformShortName eq 'MERRA Data Model') {
            $platInstVal = 'MERRA Model';
        }
        $newDataProductHash{'dataProductPlatformInstrument'} = $platInstVal if $platInstVal;

        # Construct resolution string by combining lat. and long. resolutions
        ($node) = $difDoc->findnodes( '/DIF/Data_Resolution/Latitude_Resolution' );
        $dataProductLatitudeResolution = $node->textContent() if $node;
        my ($latRes, $latResUnit) = $dataProductLatitudeResolution =~ m/([\d.\/]+)\s*([\w.]+)/;
        # If resolution is like "1/2 degrees"
        if ($latRes =~ m/\//) {
            $latRes = eval($latRes);
            $latRes = sprintf("%.6f", $latRes);
        }

        ($node) = $difDoc->findnodes( '/DIF/Data_Resolution/Longitude_Resolution' );
        $dataProductLongitudeResolution = $node->textContent() if $node;
        my ($lonRes, $lonResUnit) = $dataProductLongitudeResolution =~ /([\d.\/]+)\s*([\w.]+)/;
        # If resolution is like "1/2 degrees"
        if ($lonRes =~ m/\//) {
            $lonRes = eval($lonRes);
            $lonRes = sprintf("%.6f", $lonRes);
        }

        $latResUnit =~ s/deg(?:\.)?(?:ree)?(?:s)?/deg./i;
        $lonResUnit =~ s/deg(?:\.)?(?:ree)?(?:s)?/deg./i;
        if ($latResUnit eq $lonResUnit) {
            $latResUnit = '';
        } else {
            $latResUnit = ' ' . $latResUnit;
        }
        $dataProductSpatialResolution = "${latRes}${latResUnit} x $lonRes $lonResUnit"
            if ( (defined $dataProductLatitudeResolution) &&
                 (defined $dataProductLongitudeResolution) );
        $newDataProductHash{'dataProductSpatialResolutionLatitude'} = $latRes if $latRes;
        $newDataProductHash{'dataProductSpatialResolutionLongitude'} = $lonRes if $lonRes;
        $newDataProductHash{'dataProductSpatialResolutionUnits'} = $lonResUnit if $lonResUnit;

        ($node) = $difDoc->findnodes( '/DIF/Data_Center/Data_Center_Name/Short_Name' );
        $dataProductDataCenter = $node->textContent() if $node;
        $newDataProductHash{'dataProductDataCenter'} = $dataProductDataCenter if $dataProductDataCenter;

        my (@temporalCoverageNodes) = $difDoc->findnodes( '/DIF/Temporal_Coverage' );
        if (@temporalCoverageNodes) {
            my $temporalCoverageNode = $temporalCoverageNodes[0];
            ($node) = $temporalCoverageNode->findnodes( './Start_Date' );
            $dataProductBeginDateTime = $node->textContent() if $node;
            $dataProductBeginDateTime .= 'T00:00:00Z'
                if $dataProductBeginDateTime;
            ($node) = $temporalCoverageNode->findnodes( './Stop_Date' );
            $dataProductEndDateTime = $node->textContent() if $node;
            $dataProductEndDateTime .= 'T23:59:59.999Z'
                if $dataProductEndDateTime;
        }
        $newDataProductHash{'dataProductBeginDateTime'} = $dataProductBeginDateTime if $dataProductBeginDateTime;
        $newDataProductHash{'dataProductEndDateTime'} = $dataProductEndDateTime if $dataProductEndDateTime;
        $newDataProductHash{'dataProductStartTimeOffset'} = 1;
        $newDataProductHash{'dataProductEndTimeOffset'} = 0;
        $newDataProductHash{'dataProductEndDateTimeLocked'} = 'false';

        my (@spatialCoverageNodes) = $difDoc->findnodes( '/DIF/Spatial_Coverage' );
        if (@spatialCoverageNodes) {
            my $spatialCoverageNode = $spatialCoverageNodes[0];
            ($node) = $spatialCoverageNode->findnodes( './Southernmost_Latitude' );
            $dataProductSouth = $node->textContent() if $node;
            ($node) = $spatialCoverageNode->findnodes( './Northernmost_Latitude' );
            $dataProductNorth = $node->textContent() if $node;
            ($node) = $spatialCoverageNode->findnodes( './Westernmost_Longitude' );
            $dataProductWest = $node->textContent() if $node;
            ($node) = $spatialCoverageNode->findnodes( './Easternmost_Longitude' );
            $dataProductEast = $node->textContent() if $node;
        }
        $newDataProductHash{'dataProductWest'}  = $dataProductWest  if defined $dataProductWest;
        $newDataProductHash{'dataProductNorth'} = $dataProductNorth if defined $dataProductNorth;
        $newDataProductHash{'dataProductEast'}  = $dataProductEast  if defined $dataProductEast;
        $newDataProductHash{'dataProductSouth'} = $dataProductSouth if defined $dataProductSouth;
    }

    my %args = (SHORTNAME  => $dataProductShortName,
                VERSION    => $dataProductVersion);
    $args{DATACENTER} = $dataProductDataCenter if $dataProductDataCenter;
    my $dataProbe = new EDDA::DataProbe(%args);
    if ($dataProbe->onError) {
        print STDERR "Data probe for $dataProductId: " . $dataProbe->errorMessage . "\n";
    } else {
        my $dataProductOpendapUrl = $dataProbe->opendapUrl;
	$dataProductOpendapUrl .= '.html' unless $dataProductOpendapUrl =~ /\.html$/;
        if ($dataProductOpendapUrl) {
            $newDataProductHash{'dataProductOpendapUrl'} = $dataProductOpendapUrl;
            print STDERR "Found dataProductOpendapUrl $dataProductOpendapUrl for $dataProductId\n";
        } else {
            print STDERR "Found no dataProductOpendapUrl for $dataProductId\n";
        }
    }
    $newDataProductHash{'dataProductResponseFormat'} = 'netCDF';

    # Extract information from each hdfParameter found in the data description
    # file for the product that also appears in the portal description file
    my (@hdfParamNodes) = $ddDoc->findnodes('/dataProductType/parameterSet/scienceParameters/hdfParameter');
    my $hdfCounter = 1;
    my @dataFieldIds;
    my %hdfSdsNames;

    foreach my $hdfParamNode(@hdfParamNodes) {
        ($node) = $hdfParamNode->getChildrenByTagName('sdsName');
        my $dataFieldSdsName = $node->textContent() if $node;
        unless ( (defined $dataProductId) && (defined $dataFieldSdsName)
                 && ($dataFieldSdsName ne '') ) {
            print STDERR "hdfParameter node $hdfCounter has no sdsName," .
                " so skipping it\n";
            next;
        }
        ($node) = $hdfParamNode->getChildrenByTagName('sdsAlias');
        my $dataFieldSdsAlias = $node->textContent() if $node;
        if ($dataFieldSdsAlias && ($dataFieldSdsAlias ne $dataFieldSdsName)) {
            print STDERR "Using alias $dataFieldSdsAlias instead of $dataFieldSdsName\n";
           $dataFieldSdsName = $dataFieldSdsAlias;
        }

        # sdsName should not have any whitespace, so fix any that have it
        $dataFieldSdsName =~ s/\s+/_/g;
        $hdfSdsNames{$dataFieldSdsName} = 1;

        ($node) = $hdfParamNode->getChildrenByTagName('shortName');
        my $dataFieldShortName = $node->textContent() if $node;

        my @wavelengths;
        my $wavelengths = $1 if $dataFieldShortName =~ /\s(.+)\s?nm/;
        foreach my $wavelength (split /\D/, $wavelengths) {
            push @wavelengths, $wavelength if $wavelength =~ /\d+/;
        }

        ($node) = $hdfParamNode->getChildrenByTagName('longName');
        my $dataFieldLongName = $node->textContent() if $node;

        unless (@wavelengths) {
            my $wavelengths = $1 if $dataFieldLongName =~ /\s(.+)\s?micron/;
            foreach my $wavelength (split /[^\d.]/, $wavelengths) {
                push @wavelengths, ($wavelength * 1000) if $wavelength =~ /[\d.]+/;
            }
        }

        if (defined $dataFieldLongName) {
            # Try to extract spatial resolution from parameter long name
            my ($resx, $resy, $units) = $dataFieldLongName =~ /([0-9]*\.?[0-9]+)\s*x\s*([0-9]*\.?[0-9]+)\s+([\w.]*)/;
            $dataProductSpatialResolution = "$resx x $resy $units"
                if ( (defined $resx) && (defined $resy) );
        }

        ($node) = $hdfParamNode->getChildrenByTagName('descriptionUrl');
        my $dataFieldDescriptionUrl = $node->textContent() if $node;

        ($node) = $hdfParamNode->getChildrenByTagName('units');
        my $dataFieldUnits = $node->textContent() if $node;
        $dataFieldUnits = '1' if $dataFieldUnits eq 'unitless';

#        my $docNode = XML::LibXML::Element->new('doc');

        #if (defined $) {
        #    $fieldNode->setAttribute( 'name', '' );
        #    $fieldNode->appendText($);
        #    $docNode->addChild($fieldNode);
        #}


        my $newDataFieldDom = $parser->parse_string($CFG::DATA_FIELD_XML);
        my $newDataFieldDoc = $newDataFieldDom->documentElement();
        my %newDataFieldHash;
        my %newOptionalDataFieldHash;

        # Since different products might use the same data field SDS name,
        # construct a unique data field id by combining the data product
        # id with the data field SDS name
        my $dataFieldId;
        if ( (defined $dataProductId) && (defined $dataFieldSdsName) ) {
#            my $dataFieldId = "$dataProductId:$dataFieldSdsName";
            $dataFieldId = $dataProductId;
            $dataFieldId =~ s/\./_/g;
            $dataFieldId .= '_' . $dataFieldSdsName;
#            $dataFieldId =~ s/ /_/g;
#            $dataFieldId =~ s/_HDF4//g;
            push @dataFieldIds, $dataFieldId;
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataFieldId' );
#             $fieldNode->appendText($dataFieldId);
#             $docNode->addChild($fieldNode);
            $newDataFieldHash{'dataFieldId'}   = $dataFieldId if $dataFieldId;
            $newDataFieldHash{'dataFieldG3Id'} = $dataFieldId if $dataFieldId;
            $newDataFieldHash{'dataProductId'} = $dataProductId if $dataProductId;
        }

#        if (defined $dataProductId) {
#            $dataProductId =~ s/_HDF4//g;
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductId' );
#             $fieldNode->appendText($dataProductId);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductShortName) {
#             $dataProductShortName =~ s/_HDF4//g;
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductShortName' );
#             $fieldNode->appendText($dataProductShortName);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductVersion) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductVersion' );
#             $fieldNode->appendText($dataProductVersion);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductLongName) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductLongName' );
#             $fieldNode->appendText($dataProductLongName);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductDescriptionUrl) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductDescriptionUrl' );
#             $fieldNode->appendText($dataProductDescriptionUrl);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductGcmdEntryId) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductGcmdEntryId' );
#             $fieldNode->appendText($dataProductGcmdEntryId);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductProcessingLevel) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductProcessingLevel' );
#             $fieldNode->appendText($dataProductProcessingLevel);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductDataCenter) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductDataCenter' );
#             $fieldNode->appendText($dataProductDataCenter);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductPlatformShortName) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductPlatformShortName' );
#             $fieldNode->appendText($dataProductPlatformShortName);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductPlatformLongName) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductPlatformLongName' );
#             $fieldNode->appendText($dataProductPlatformLongName);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductInstrumentShortName) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductInstrumentShortName' );
#             $fieldNode->appendText($dataProductInstrumentShortName);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductInstrumentLongName) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductInstrumentLongName' );
#             $fieldNode->appendText($dataProductInstrumentLongName);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductSpatialResolution) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductSpatialResolution' );
#             $fieldNode->appendText($dataProductSpatialResolution);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductBeginDateTime) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductBeginDateTime' );
#             $fieldNode->appendText($dataProductBeginDateTime);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductEndDateTime) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductEndDateTime' );
#             $fieldNode->appendText($dataProductEndDateTime);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductWest) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductWest' );
#             $fieldNode->appendText($dataProductWest);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductNorth) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductNorth' );
#             $fieldNode->appendText($dataProductNorth);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductEast) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductEast' );
#             $fieldNode->appendText($dataProductEast);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductSouth) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductSouth' );
#             $fieldNode->appendText($dataProductSouth);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductTimeInterval) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductTimeInterval' );
#             $fieldNode->appendText($dataProductTimeInterval);
#             $docNode->addChild($fieldNode);
#        }
#        if (defined $dataProductTimeFrequency) {
#             my $fieldNode = XML::LibXML::Element->new('field');
#             $fieldNode->setAttribute( 'name', 'dataProductTimeFrequency' );
#             $fieldNode->appendText($dataProductTimeFrequency);
#             $docNode->addChild($fieldNode);
#        }
#         my $fieldNode = XML::LibXML::Element->new('field');
#         $fieldNode->setAttribute( 'name', 'dataProductStartTimeOffset' );
#         $fieldNode->appendText('1');
#         $docNode->addChild($fieldNode);


        if (defined $dataFieldSdsName) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'parameterSdsName' );
#            $fieldNode->appendText($dataFieldSdsName);
#            $docNode->addChild($fieldNode);
            $newDataFieldHash{'dataFieldSdsName'} = $dataFieldSdsName if $dataFieldSdsName;
        }
        my $dataFieldMeasurement;
        if (defined $dataFieldShortName) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'parameterShortName' );
#            if (exists $dataFieldNewShortNames{$dataFieldShortName}) {
#                $fieldNode->appendText($dataFieldNewShortNames{$dataFieldShortName});
#            } else {
#                $fieldNode->appendText($dataFieldShortName);
#            }
#            $docNode->addChild($fieldNode);
#            if (defined $dataFieldMeasurements{$dataFieldShortName}) {
#                $dataFieldMeasurement = $dataFieldMeasurements{$dataFieldShortName};
                # When we find a parameter that was defined in the portal
                # description file in the data description file, delete
                # the parameter from the hash, so that once we have examined
                # every parameter in the data description file, we should
                # have no parameters left in the hash; if any are left over,
                # flag them as missing from the data description file.
#                delete $dataFieldMeasurements{$dataFieldShortName};
#            }
            $newDataFieldHash{'dataFieldShortName'} = $dataFieldShortName if $dataFieldShortName;
        }
        if (defined $dataFieldLongName) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'parameterLongName' );

#            # Construct a unique long name for the parameter.
#            my $name;
#            $name = $dataProductShortName if defined $dataProductShortName;
#            if (defined $dataProductVersion) {
#                $name .= '.' if defined $name;
#                $name .= $dataProductVersion;
#            }
#            $name .= ': ' if defined $name;
#            $name .= $dataFieldLongName;
#
#            $fieldNode->appendText($name);
#            $docNode->addChild($fieldNode);
            $newDataFieldHash{'dataFieldLongName'} = $dataFieldLongName if $dataFieldLongName;
        }
        if (defined $dataFieldMeasurement) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'parameterMeasurement' );
#            $fieldNode->appendText($dataFieldMeasurement);
#            $docNode->addChild($fieldNode);
            $newDataFieldHash{'dataFieldMeasurement'} = $dataFieldMeasurement if $dataFieldMeasurement;
        }
        if (defined $dataFieldDescriptionUrl) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'dataFieldDescriptionUrl' );
#            $fieldNode->appendText($dataFieldDescriptionUrl);
#            $docNode->addChild($fieldNode);
            $newDataFieldHash{'dataFieldDescriptionUrl'} = $dataFieldDescriptionUrl if $dataFieldDescriptionUrl;
        }
        my $dataFieldDiscipline;
#        my $dataFieldDiscipline = $dataFieldDisciplines{$dataFieldShortName}
#            if (exists $dataFieldDisciplines{$dataFieldShortName});
        if (defined $dataFieldDiscipline) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'parameterDiscipline' );
#            $fieldNode->appendText($dataFieldDiscipline);
#            $docNode->addChild($fieldNode);
            $newDataFieldHash{'dataFieldDiscipline'} = $dataFieldDiscipline if $dataFieldDiscipline;
        }
        if (defined $dataFieldUnits) {
            $newDataFieldHash{'dataFieldUnits'} = $dataFieldUnits if $dataFieldUnits && (! exists $newDataFieldHash{'dataFieldUnits'});
        }

#        if ( scalar(@wavelengths) == 1 ) {
        if (@wavelengths) {
            foreach my $dataFieldWavelength (sort @wavelengths) {
#                my $fieldNode = XML::LibXML::Element->new('field');
#                $fieldNode->setAttribute( 'name', 'parameterWavelength' );
#                $fieldNode->appendText($dataFieldWavelength);
#                $docNode->addChild($fieldNode);
                push @{$newOptionalDataFieldHash{'dataFieldWavelength'}}, $dataFieldWavelength;
                push @{$newOptionalDataFieldHash{'dataFieldWavelengthUnits'}}, 'nm';
            }
        }
        my %stopwords = (
                         a => 1,
                         an => 1,
                         and => 1,
                         are => 1,
                         as => 1,
                         at => 1,
                         be => 1,
                         but => 1,
                         by => 1,
                         for => 1,
                         if => 1,
                         in => 1,
                         into => 1,
                         is => 1,
                         it => 1,
                         no => 1,
                         not => 1,
                         of => 1,
                         on => 1,
                         or => 1,
                         s => 1,
                         such => 1,
                         t => 1,
                         that => 1,
                         the => 1,
                         their => 1,
                         then => 1,
                         there => 1,
                         these => 1,
                         they => 1,
                         this => 1,
                         to => 1,
                         was => 1,
                         will => 1,
                         with => 1,
                         nm => 1,
                        );
        foreach my $keyword (split /[\s]+/, $dataFieldLongName) {
            $keyword =~ s/[)(,]//g;
            next if (exists $stopwords{$keyword});
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'parameterKeywords' );
#            $fieldNode->appendText($keyword);
#            $docNode->addChild($fieldNode);
            push @{$newDataFieldHash{'dataFieldKeywords'}}, $keyword;
        }
        if (@wavelengths) {
            foreach my $dataFieldWavelength (sort @wavelengths) {
#                my $fieldNode = XML::LibXML::Element->new('field');
#                $fieldNode->setAttribute( 'name', 'parameterKeywords' );
#                $fieldNode->appendText($dataFieldWavelength);
#                $docNode->addChild($fieldNode);
                push @{$newDataFieldHash{'dataFieldKeywords'}}, $dataFieldWavelength;
            }
        }
        my %keywordPhrases = ('Aerosol Absorption Optical Depth' => 1,
                              'Aerosol Optical Depth' => 1,
                              'Angstrom Exponent' => 1,
                              'Black Carbon' => 1,
                              'Dark Target' => 1,
                              'Deep Blue' => 1,
                              'GOCART model' => 1,
                              'MODIS-Aqua' => 1,
                              'MODIS-Terra' => 1,
                              'Organic Particulates' => 1,
                              'Pixel Count' => 1,
                              'Sea Salt' => 1,
                              'Std. Dev.' => 1);
        foreach my $keywordPhrase (keys %keywordPhrases) {
            if ($dataFieldLongName =~ /($keywordPhrase)/i) {
#                my $fieldNode = XML::LibXML::Element->new('field');
#                $fieldNode->setAttribute( 'name', 'parameterKeywords' );
#                $fieldNode->appendText($1);
#                $docNode->addChild($fieldNode);
                push @{$newDataFieldHash{'dataFieldKeywords'}}, $1;
                # AOD is essential enough to deserve to be in the suggestions
                if ($keywordPhrase eq 'Aerosol Optical Depth') {
#                    my $fieldNode2 = XML::LibXML::Element->new('field');
#                    $fieldNode2->setAttribute( 'name', 'parameterKeywords' );
#                    $fieldNode2->appendText('AOD');
#                    $docNode->addChild($fieldNode2);
                    push @{$newDataFieldHash{'dataFieldKeywords'}}, 'AOD';
                }
            }
        }
        if (defined $dataFieldMeasurement) {
            unless ( exists $keywordPhrases{$dataFieldMeasurement} ) {
#                my $fieldNode = XML::LibXML::Element->new('field');
#                $fieldNode->setAttribute( 'name', 'parameterKeywords' );
#                $fieldNode->appendText($dataFieldMeasurement);
#                $docNode->addChild($fieldNode);
                push @{$newDataFieldHash{'dataFieldKeywords'}}, $dataFieldMeasurement;
            }
        }
        if (defined $dataProductLongName) {
            my %productKeywordPhrases = ('Deep Blue' => 1,
                                         'SeaWiFS Deep Blue' => 1);
            foreach my $keywordPhrase (keys %productKeywordPhrases) {
                if ($dataFieldLongName =~ /($keywordPhrase)/i) {
#                    my $fieldNode = XML::LibXML::Element->new('field');
#                    $fieldNode->setAttribute( 'name', 'parameterKeywords' );
#                    $fieldNode->appendText($1);
#                    $docNode->addChild($fieldNode);
                    push @{$newDataFieldHash{'dataFieldKeywords'}}, $1;
                }
            }
        }
#        if (exists $accessMethods{$dataFieldShortName}) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'accessMethod' );
#            $fieldNode->appendText($accessMethods{$dataFieldShortName});
#            $docNode->addChild($fieldNode);
#        }
#        if (exists $accessFormats{$dataFieldShortName}) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'accessFormat' );
#            $fieldNode->appendText($accessFormats{$dataFieldShortName});
#            $docNode->addChild($fieldNode);
#        }
#        if (exists $dataFieldSswBaseSubsetUrls{$dataFieldShortName}) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'sswBaseSubsetUrl' );
#            $fieldNode->appendText($dataFieldSswBaseSubsetUrls{$dataFieldShortName});
#            $docNode->addChild($fieldNode);
#        }
#        if (exists $sldUrls{$dataFieldShortName}) {
#            my $fieldNode = XML::LibXML::Element->new('field');
#            $fieldNode->setAttribute( 'name', 'sldUrl' );
##            $fieldNode->appendText($sldUrls{$dataFieldShortName});
#            my $sldsNode = XML::LibXML::Element->new('slds');
#            foreach my $sldHash (@{$sldUrls{$dataFieldShortName}}) {
#                while (my ($label, $sldUrl) = each %$sldHash) {
#                    my $sldNode = XML::LibXML::Element->new('sld');
#                    $sldNode->setAttribute( 'url', $sldUrl );
#                    $sldNode->setAttribute( 'label', $label );
#                    $sldsNode->addChild($sldNode);
#                }
#            }
#            my $cdataNode = XML::LibXML::CDATASection->new($sldsNode->toString());
#            $fieldNode->addChild($cdataNode);
#            $docNode->addChild($fieldNode);
#        }
#        $addNode->addChild($docNode);
        if (defined $dataFieldSdsName) {
            my $attributes = $dataProbe->dataFieldAttributes($dataFieldSdsName);
            if ($attributes && (ref($attributes) eq 'HASH')) {
                foreach my $attribute (keys %$attributes) {
                    next unless exists $CFG::ADD_DOC_DATA_FIELD_MAPPING->{$attribute};
                    next if ($attribute eq 'dataFieldLongName');
                    my $value = $dataProbe->dataFieldAttribute($dataFieldSdsName, $attribute);
                    $newDataFieldHash{$attribute} = $value;
                }
            }
        }

        foreach my $fieldKey (@CFG::ADD_DOC_DATA_FIELD_FIELDS) {
            if (exists $newDataFieldHash{$fieldKey}) {
                if (ref $newDataFieldHash{$fieldKey} eq 'ARRAY') {
                    foreach my $val (@{$newDataFieldHash{$fieldKey}}) {
                        addValue($newDataFieldDoc, $fieldKey,
                                 $CFG::ADD_DOC_DATA_FIELD_MAPPING,
                                 $val);
                    }
                } else {
                        addValue($newDataFieldDoc, $fieldKey,
                                 $CFG::ADD_DOC_DATA_FIELD_MAPPING,
                                 $newDataFieldHash{$fieldKey});
                }
            }
        }

        if (keys %newOptionalDataFieldHash) {
            my $dataFieldOptionalDom = $parser->parse_string($CFG::DATA_FIELD_OPTIONAL_XML);
            my $dataFieldOptionalDoc = $dataFieldOptionalDom->documentElement();
            foreach my $fieldKey (@CFG::ADD_DOC_DATA_FIELD_OPTIONAL_FIELDS) {
                next unless exists $newOptionalDataFieldHash{$fieldKey};
                if (ref $newOptionalDataFieldHash{$fieldKey} eq 'ARRAY') {
                    foreach my $val (@{$newOptionalDataFieldHash{$fieldKey}}) {
                        addOptionalValue($newDataFieldDoc, $fieldKey,
                                         $CFG::ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING,
                                         $dataFieldOptionalDoc,
                                         $val);
                    }
                } else {
                    addOptionalValue($newDataFieldDoc, $fieldKey,
                                     $CFG::ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING,
                                     $dataFieldOptionalDoc,
                                     $newOptionalDataFieldHash{$fieldKey});
                }
            }
        }

        addValue($newDataFieldDoc, 'dataFieldInternal',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'false');

        addValue($newDataFieldDoc, 'dataFieldActive',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'false');

        addValue($newDataFieldDoc, 'dataFieldInDb',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'false');

        addValue($newDataFieldDoc, 'dataFieldState',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'Private');

        # Set a value for dataFieldLastModified to an arbitrary value that
        # is earlier than any changes made using EDDA
        addValue($newDataFieldDoc, 'dataFieldLastModified',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, '2013-04-01T00:00:00.000Z');

        # Update the timestamp
        addValue($newDataFieldDoc, 'dataFieldLastExtracted',
                 $CFG::ADD_DOC_DATA_FIELD_TIMESTAMP_MAPPING, $now);

        my $dataFieldFile = "$dataFieldsDir/$dataFieldId";
        if (-f $dataFieldFile) {
            # Do not overwrite files for fields that are in the (Solr) database
            # with information extracted from the data descriptor.
            # Assume that those files were created by another script
            #
#            print STDERR "$dataFieldFile already exists, not overwriting\n";
            my $dataFieldDom;
            eval { $dataFieldDom = $parser->parse_file( $dataFieldFile ); };
            if ($@) {
                print STDERR "Could not read and parse $dataFieldFile\n";
                next;
            }
            my $dataFieldDoc = $dataFieldDom->documentElement();
            my ($inDbValueNode) = $dataFieldDoc->findnodes( '/dataField/dataFieldInDb/value' );
            my $inDbValue = $inDbValueNode->textContent if $inDbValueNode;
            if ( $inDbValue =~ /true/i ) {
                print STDERR "$dataFieldId already exists in db, not overwriting $dataFieldFile\n";
                next;
            }
        }

        unless (open (FIELD, "> $dataFieldFile")) {
            print STDERR "Could not open $dataFieldFile for writing\n";
            next;
        }
        print FIELD $newDataFieldDoc->ownerDocument->toString(1);
        close(FIELD);
        chmod 0666, $dataFieldFile;

    }  # END foreach my $hdfParamNode(@hdfParamNodes)

#    foreach my $dataFieldShortName (keys %parameterMeasurements) {
#        print STDERR "Did not find parameterShortName $dataFieldShortName in $dataDescriptionFile\n";
#    }

    foreach my $fieldName ($dataProbe->dataFieldNames) {
        next unless defined $fieldName;
        next if exists $hdfSdsNames{$fieldName};

        my $newDataFieldDom = $parser->parse_string($CFG::DATA_FIELD_XML);
        my $newDataFieldDoc = $newDataFieldDom->documentElement();
        my %newDataFieldHash;
#        my %newOptionalDataFieldHash;
        my $dataFieldId = $dataProductId;
        $dataFieldId =~ s/\./_/g;
        $dataFieldId .= '_' . $fieldName;
        push @dataFieldIds, $dataFieldId;
        $newDataFieldHash{'dataFieldId'}   = $dataFieldId if $dataFieldId;
        $newDataFieldHash{'dataProductId'} = $dataProductId if $dataProductId;
        $newDataFieldHash{'dataFieldSdsName'} = $fieldName;
        $newDataFieldHash{'dataFieldAccessName'} = $fieldName;
        $newDataFieldHash{'dataFieldAccessMethod'} = 'OPeNDAP';
        my $attributes = $dataProbe->dataFieldAttributes($fieldName);
        if ($attributes && (ref($attributes) eq 'HASH')) {
            foreach my $attribute (keys %$attributes) {
                next unless exists $CFG::ADD_DOC_DATA_FIELD_MAPPING->{$attribute};
                next if ($attribute eq 'dataFieldLongName');
                my $value = $dataProbe->dataFieldAttribute($fieldName, $attribute);
                $newDataFieldHash{$attribute} = $value;
            }
        }

        foreach my $fieldKey (@CFG::ADD_DOC_DATA_FIELD_FIELDS) {
            if (exists $newDataFieldHash{$fieldKey}) {
                if (ref $newDataFieldHash{$fieldKey} eq 'ARRAY') {
                    foreach my $val (@{$newDataFieldHash{$fieldKey}}) {
                        addValue($newDataFieldDoc, $fieldKey,
                                 $CFG::ADD_DOC_DATA_FIELD_MAPPING,
                                 $val);
                    }
                } else {
                        addValue($newDataFieldDoc, $fieldKey,
                                 $CFG::ADD_DOC_DATA_FIELD_MAPPING,
                                 $newDataFieldHash{$fieldKey});
                }
            }
        }

#         if (keys %newOptionalDataFieldHash) {
#             my $dataFieldOptionalDom = $parser->parse_string($CFG::DATA_FIELD_OPTIONAL_XML);
#             my $dataFieldOptionalDoc = $dataFieldOptionalDom->documentElement();
#             foreach my $fieldKey (@CFG::ADD_DOC_DATA_FIELD_OPTIONAL_FIELDS) {
#                 next unless exists $newOptionalDataFieldHash{$fieldKey};
#                 if (ref $newOptionalDataFieldHash{$fieldKey} eq 'ARRAY') {
#                     foreach my $val (@{$newOptionalDataFieldHash{$fieldKey}}) {
#                         addOptionalValue($newDataFieldDoc, $fieldKey,
#                                          $CFG::ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING,
#                                          $dataFieldOptionalDoc,
#                                          $val);
#                     }
#                 } else {
#                     addOptionalValue($newDataFieldDoc, $fieldKey,
#                                      $CFG::ADD_DOC_DATA_FIELD_OPTIONAL_MAPPING,
#                                      $dataFieldOptionalDoc,
#                                      $newOptionalDataFieldHash{$fieldKey});
#                 }
#             }
#         }

        addValue($newDataFieldDoc, 'dataFieldInternal',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'false');

        addValue($newDataFieldDoc, 'dataFieldActive',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'false');

        addValue($newDataFieldDoc, 'dataFieldInDb',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'false');

        addValue($newDataFieldDoc, 'dataFieldState',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, 'Private');

        # Set a value for dataFieldLastModified to an arbitrary value that
        # is earlier than any changes made using EDDA
        addValue($newDataFieldDoc, 'dataFieldLastModified',
                 $CFG::ADD_DOC_DATA_FIELD_MAPPING, '2013-04-01T00:00:00.000Z');

        # Update the timestamp
        addValue($newDataFieldDoc, 'dataFieldLastExtracted',
                 $CFG::ADD_DOC_DATA_FIELD_TIMESTAMP_MAPPING, $now);

        my $dataFieldFile = "$dataFieldsDir/$dataFieldId";
        if (-f $dataFieldFile) {
            # Do not overwrite files for fields that are in the (Solr) database
            # with information extracted from the data descriptor.
            # Assume that those files were created by another script
            #
#            print STDERR "$dataFieldFile already exists, not overwriting\n";
            my $dataFieldDom;
            eval { $dataFieldDom = $parser->parse_file( $dataFieldFile ); };
            if ($@) {
                print STDERR "Could not read and parse $dataFieldFile\n";
                next;
            }
            my $dataFieldDoc = $dataFieldDom->documentElement();
            my ($inDbValueNode) = $dataFieldDoc->findnodes( '/dataField/dataFieldInDb/value' );
            my $inDbValue = $inDbValueNode->textContent if $inDbValueNode;
            if ( $inDbValue =~ /true/i ) {
                print STDERR "$dataFieldId already exists in db, not overwriting $dataFieldFile\n";
                next;
            }
        }

        unless (open (FIELD, "> $dataFieldFile")) {
            print STDERR "Could not open $dataFieldFile for writing\n";
            next;
        }
        print FIELD $newDataFieldDoc->ownerDocument->toString(1);
        close(FIELD);
        chmod 0666, $dataFieldFile;
    }


    foreach my $fieldKey (@CFG::ADD_DOC_PRODUCT_FIELDS) {
        if (exists $newDataProductHash{$fieldKey}) {
            if (ref $newDataProductHash{$fieldKey} eq 'ARRAY') {
                foreach my $val (@{$newDataProductHash{$fieldKey}}) {
                    addValue($newDataProductDoc, $fieldKey,
                             $CFG::ADD_DOC_PRODUCT_MAPPING,
                             $val);
                }
            } else {
                    addValue($newDataProductDoc, $fieldKey,
                             $CFG::ADD_DOC_PRODUCT_MAPPING,
                             $newDataProductHash{$fieldKey});
            }
        }
    }

    addValue($newDataProductDoc, 'dataProductInternal',
             $CFG::ADD_DOC_PRODUCT_MAPPING, 'false');

    my ($dataProductDataFieldIdsNode) = $newDataProductDoc->findnodes('/dataProduct/dataProductDataFieldIds');
    my ($valueNode) = $dataProductDataFieldIdsNode->findnodes('./value');
    if (defined $valueNode) {
        my $content = $valueNode->textContent;
        if ($content eq '') {
            $dataProductDataFieldIdsNode->removeChild($valueNode);
        }
    }
    foreach my $dataFieldId (@dataFieldIds) {
        my $valueNode = XML::LibXML::Element->new('value');
        $valueNode->appendText($dataFieldId);
	$valueNode->setAttribute('longId', $dataFieldId);
        $dataProductDataFieldIdsNode->addChild($valueNode);
    }

    my $dataProductFile = "$dataProductsDir/$dataProductId";
    if (-f $dataProductFile) {

        my $old_xml;
        unless (open(UPDATED, "+< $dataProductFile")) {
            exit_with_error("Could not open dataProductFile for updating: $!")
        }
        {
            local $/;
            $old_xml = <UPDATED>;
        }
        my $oldDataProductDom = $parser->parse_string($old_xml);
        my $oldDataProductDoc = $oldDataProductDom->documentElement();
        my ($dataProductInternalNode) = $oldDataProductDoc->findnodes('/dataProduct/dataProductInternal');
        my $dataProductInternal = $dataProductInternalNode->textContent
            if $dataProductInternalNode;

        if ((defined $dataProductInternal) && $dataProductInternal =~ /true/i) {

            print STDERR "$dataProductFile already exists, not overwriting, adding data fields\n";
            my ($dataProductDataFieldIdsNode) = $oldDataProductDoc->findnodes('/dataProduct/dataProductDataFieldIds');
            my @dataFieldIdNodes = $dataProductDataFieldIdsNode->findnodes('./value');
            my %dataProductDataFieldIds;
            my $emptyValueNode;
            foreach my $dataFieldIdNode (@dataFieldIdNodes) {
                my $dataFieldId = $dataFieldIdNode->textContent;
                if ($dataFieldId eq '') {
                    $emptyValueNode = $dataFieldIdNode;
                } else {
                    $dataProductDataFieldIds{$dataFieldId} = 1;
                }
            }

            my $added;
            foreach my $dataFieldId (@dataFieldIds) {
                unless (exists($dataProductDataFieldIds{$dataFieldId})) {
                    my $valueNode = XML::LibXML::Element->new('value');
                    $valueNode->appendText($dataFieldId);
                    $dataProductDataFieldIdsNode->addChild($valueNode);
                    $added = 1;
                }
            }

            if ($added) {
                # Replace the file contents with the updated information
                seek(UPDATED, 0, 0);
                print UPDATED $oldDataProductDom->toString(1);
                truncate(UPDATED, tell(UPDATED));
            }
            close(UPDATED);
        } elsif ($overWriteFlag) {
            # Data product file was not populated with information from
            # the Solr database, and so can be overwritten
            unless (open (PRODUCT, "> $dataProductFile")) {
                print STDERR "Could not open $dataProductFile for writing\n";
                next;
            }
            print STDERR "$dataProductFile already exists, overwriting\n";
            print PRODUCT $newDataProductDoc->ownerDocument->toString(1);
            close(PRODUCT);
            chmod 0666, $dataProductFile;
        }
    } else {
        unless (open (PRODUCT, "> $dataProductFile")) {
            print STDERR "Could not open $dataProductFile for writing\n";
            next;
        }
	my $transform = $styleSheet->transform($newDataProductDom);
	my $transform_string = $styleSheet->output_string($transform);
#        print PRODUCT $newDataProductDoc->ownerDocument->toString(1);
	print PRODUCT $transform_string;
        close(PRODUCT);
        chmod 0666, $dataProductFile;
    }
}

exit 0;



sub addValue {
    my ($doc, $key, $mapping, $value) = @_;

    # Use mapping to determine the path in $doc that corresponds to $key
    my $path = $mapping->{$key};
    unless ($path) {
        print STDERR "Could not find mapping for key $key\n";
        return;
    }

    # Find the node in $doc at that path
    my ($node) = $doc->findnodes($path);
    unless ($node) {
        print STDERR "Could not find node for key $key path $path\n";
        return;
    }

    # Look for a 'value' child node. If one is found and it is empty,
    # replace it with a new value
    my ($valueNode1) = $node->findnodes('./value');
    if (defined $valueNode1) {
        my $content = $valueNode1->textContent;
        if ($content eq '') {
            $valueNode1->removeChildNodes();
            $valueNode1->appendText($value);
            return;
        }
    }

    # Otherwise add a new 'value' child node.
    # Construct a new 'value' node and add it to the node in $doc at
    # that path.
    $node->appendTextChild('value', $value);
    return;
}

sub addOptionalValue {
    my ($doc, $key, $mapping, $dataFieldOptionalDoc, $value) = @_;

    # Use mapping to determine the path in $doc that corresponds to $key
    my $path = $mapping->{$key};
    unless ($path) {
        print STDERR "Could not find mapping for key $key\n";
        return;
    }

    # Find the node in $doc at that path
    my ($node) = $doc->findnodes($path);

    if ($node) {
        # Add the 'value' node to the node in $doc at that path
        $node->appendTextChild('value', $value);
        return;
    } else {
        # Find the node in $dataFieldOptionalDoc at that path, clone it,
        # and add the 'value' node to the cloned node
        ($node) = $dataFieldOptionalDoc->findnodes($path);
        unless ($node) {
            print STDERR "Could not find optional node for key $key path $path\n";
            return;
        }
        my $newNode = $node->cloneNode(1);
        $newNode->appendTextChild('value', $value);

        # Add the cloned node to $doc
        $doc->addChild($newNode);
    }
}
