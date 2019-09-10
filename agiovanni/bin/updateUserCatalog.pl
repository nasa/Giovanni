#!/usr/bin/perl
#

# $Id: updateUserCatalog.pl,v 1.5 2014/10/30 21:55:37 mhegde Exp $
# Version: $Name:  $

use strict;
use Getopt::Long;
use XML::LibXML;
use Safe;

# Set the library path
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) )
        if defined $rootPath;
}
use Giovanni::Data::NcFile;
use Giovanni::BoundingBox;
use Giovanni::Util;

# Variables to hold command line arguments
my ( $opt_h, $user, $cfgFile, $dataFile, $dataField );

# Get command line options
Getopt::Long::GetOptions(
    'h'               => \$opt_h,
    'dataFieldName=s' => \$dataField,
    'userName=s'      => \$user,
    'configFile=s'    => \$cfgFile,
    'dataFile=s'      => \$dataFile
);

my $cpt = Safe->new('GIOVANNI');
die "Failed to read configuration file" unless ( $cpt->rdo($cfgFile) );
die "User directory not defined"
    unless ( defined $GIOVANNI::USER_DATA_DIR
    && ( -d $GIOVANNI::USER_DATA_DIR ) );

my $userDataDir = "$GIOVANNI::USER_DATA_DIR/$user/data/$dataField/";
my $file        = "$userDataDir/$dataFile";
die "$file doesn't exist" unless ( -e $file );
print STDERR "Working with $file\n";
my $data = Giovanni::Data::NcFile->new( NCFILE => $file );

print STDERR "Finding variables\n";

# Fail if Giovanni::Data::NcFile can't be created
my @varList = $data->find_variables_with_latlon();

print STDERR "Found ", join( ",", @varList ), "\n";

# Fail if number of variables found is not 1

# Get the vertical dimension name
my ($vDimName)
    = Giovanni::Data::NcFile::get_vertical_dim_var( $file, 1, $varList[0] );

# Get the date time range for the variable
my @timeRange = $data->get_time_range( $varList[0] );

# Get the bounding box
my $bbox = Giovanni::BoundingBox->new(
    STRING => Giovanni::Data::NcFile::data_bbox($file) );

# Get the variable attributes
my ($varAttr)
    = Giovanni::Data::NcFile::get_variable_attributes( $file, 1,
    $varList[0] );

my $dataUrl
    = Giovanni::Util::convertFilePathToUrl( $file, \%GIOVANNI::URL_LOOKUP );
my $sswUrl = "$GIOVANNI::USER_SSW?user_id=$user&dataset_id=$dataField";

die "Failed to translate file path to URL" unless defined $dataUrl;

# Compile necessary data field info necessary
my $varInfo = {
    id                       => $dataField,
    long_name                => $varAttr->{long_name},
    startTime                => $timeRange[0],
    dataProductBeginDateTime => $timeRange[0],
    endTime                  => $timeRange[1],
    dataProductEndDateTime   => $timeRange[1],
    quantity_type            => exists $varAttr->{standard_name}
    ? $varAttr->{standard_name}
    : $dataField,

# There is no easy to way to find data product time interval (ex: daily, monthly ...)
    dataProductTimeInterval => '',
    responseFormat          => 'netCDF',
    sswUrl                  => $sswUrl,
    dataUrl                 => $dataUrl,
};

# Z-dimension name in data field if it exists
$varInfo->{zDimName} = $vDimName if defined $vDimName;

# Bounding box of data field
foreach my $attr (qw(north south west east)) {
    $varInfo->{$attr} = $bbox->{ uc($attr) } if exists $bbox->{ uc($attr) };
}

# Data catalog contains the metadata about the data field
my $dataCatalog = "$userDataDir/$dataField.xml";

# File catalog contains the start time, end time and the URL of the file
my $dataFileCatalog = "$userDataDir/$dataField.txt";

# Update the data catalog first
updateDataCatalog( $dataCatalog, $varInfo )
    or die "Failed to update data catalog";

# Update the file catalog next
updateDataFileCatalog( $dataFileCatalog, $varInfo )
    or die "Failed to update data file catalog";

# Updates data catalog
sub updateDataCatalog {
    my ( $catalogFile, $varInfo ) = @_;

    # Parse catalog file if it exists already
    my $doc
        = ( -f $catalogFile )
        ? Giovanni::Util::parseXMLDocument($catalogFile)
        : Giovanni::Util::createXMLDocument('varList');

    # List of data attributes that are mandatory
    my @attrList = (
        qw(id long_name north south east west quantity_type),
        qw(zDimName dataProductTimeInterval responseFormat)
    );

    # If the data field exists already, update it; else, create new one
    my ($varNode)
        = $doc->findnodes( '/varList/var[@id="' . $varInfo->{id} . '"]' );
    $varNode = XML::LibXML::Element->new('var') unless defined $varNode;
    foreach my $attr (@attrList) {
        $varNode->setAttribute( $attr, $varInfo->{$attr} );
    }

 # Handle time: check to see if the data time range has to be expanded because
 # the granule being added has time range outside the existing data time range
    foreach my $attr (qw(startTime dataProductBeginDateTime)) {
        my $val = $varNode->getAttribute($attr);
        if ( defined $val ) {
            if ( $val gt $varInfo->{$attr} ) {
                $varNode->setAttribute( $attr, $varInfo->{$attr} );
            }
        }
        else {
            $varNode->setAttribute( $attr, $varInfo->{$attr} );
        }
    }
    foreach my $attr (qw(endTime dataProductEndDateTime)) {
        my $val = $varNode->getAttribute($attr);
        if ( defined $val ) {
            if ( $val lt $varInfo->{$attr} ) {
                $varNode->setAttribute( $attr, $varInfo->{$attr} );
            }
        }
        else {
            $varNode->setAttribute( $attr, $varInfo->{$attr} );
        }
    }

    # Set SSW URL
    $varNode->setAttribute( 'url', $varInfo->{sswUrl} );
    foreach my $sld ( @{ $varInfo->{sld} } ) {
        my $sldNode = XML::LibXML::Element->new('sld');
        $sldNode->setAttribute( $sldNode->{label} );
        $sldNode->setAttribute( $sldNode->{url} );
        $varNode->appendChild($sldNode);
    }
    $doc->appendChild($varNode);

    # Write the data catalog
    return Giovanni::Util::writeFile( $catalogFile, $doc->toString(1) );
}

# Writes the file catalog for the data
# Returns 1/0: success/failure
sub updateDataFileCatalog {
    my ( $catalogFile, $varInfo ) = @_;

    # Read the content of existing catalog
    my @catalog
        = ( -f $catalogFile ) ? Giovanni::Util::readFile($catalogFile) : ();
    chomp(@catalog);

  # Cheap way to avoid duplicates; using start and end time as the unique keys
    for ( my $i = 0; $i < @catalog; ) {
        my ( $startTime, $endTime, $dataUrl ) = split( /,/, $catalog[$i], 3 );
        if (   $startTime eq $varInfo->{startTime}
            && $endTime eq $varInfo->{endTime} )
        {
            splice( @catalog, $i, 1 );
        }
        else {
            $i++;
        }
    }

    # Add the new item: start time, end time, file URL
    push( @catalog,
        "$varInfo->{startTime},$varInfo->{endTime},$varInfo->{dataUrl}" );

    # Write the file catalog after sorting catalog items alphabetically
    return Giovanni::Util::writeFile( $catalogFile,
        join( "\n", sort(@catalog) ) );
}
