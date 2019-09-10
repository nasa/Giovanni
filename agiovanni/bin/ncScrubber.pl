#!/usr/bin/perl

#$Id: ncScrubber.pl,v 1.210 2015/09/04 13:11:49 rstrub Exp $
#-@@@ GIOVANNI,Version $Name:  $

=head1 Name

ncScrubber.pl

=head1 DESCRIPTION

ncScrubber.pl is a commandline tool used to reformat an NetCDF file for use in aGiovanni.

=head1 SYNOPSIS

#>perl ncScrubber.pl --input [listing_file] --outDir [working_direcotry] --catalog [var_info_xml_file] -v [0 | 1] [--help]

Where

=over 4

=item 1. --input

required; value should be a xml file containing a list of files.  E.g.:

<data>
   <dataFileList id="GLDAS_NOAH10_M_2_0_AvgSurfT_inst" sdsName="AvgSurfT_inst">
      <dataFile startTime="2003-02-01T00:00:00Z" endTime="2003-02-28T23:59:59Z">/var/giovanni/session/E94E2D08-B805-11E7-895C-DCB5F8F833F2/89A8B100-B807-11E7-8084-1AE2F8F833F2/89A91CA8-B807-11E7-8084-1AE2F8F833F2///GLDAS_NOAH10_M.A200302.020.nc4.GLDAS_NOAH10_M_2_0_AvgSurfT_inst.nc
      </dataFile>
      <dataFile startTime="2003-03-01T00:00:00Z" endTime="2003-03-31T23:59:59Z">/var/giovanni/session/E94E2D08-B805-11E7-895C-DCB5F8F833F2/89A8B100-B807-11E7-8084-1AE2F8F833F2/89A91CA8-B807-11E7-8084-1AE2F8F833F2///GLDAS_NOAH10_M.A200303.020.nc4.GLDAS_NOAH10_M_2_0_AvgSurfT_inst.nc
     </dataFile>
     <dataFile startTime="2003-04-01T00:00:00Z" endTime="2003-04-30T23:59:59Z">/var/giovanni/session/E94E2D08-B805-11E7-895C-DCB5F8F833F2/89A8B100-B807-11E7-8084-1AE2F8F833F2/89A91CA8-B807-11E7-8084-1AE2F8F833F2///GLDAS_NOAH10_M.A200304.020.nc4.GLDAS_NOAH10_M_2_0_AvgSurfT_inst.nc
     </dataFile>
   </dataFileList>
</data>

where WORKINGDIR is a real directory holding files.

=item 2. --outDir

required; value should a working directory where all intermediate files are located

=item 3. --catalog

required; value should be a variable catalog file in xml. E.g.:

Because of back-chaining, the scrubber always looks at a varInfo with only one variable:
<varList>
  <var id="FinalAerosolAbsOpticalDepth388" sdsName="FinalAerosolAbsOpticalDepth388" long_name="OMAERUVd.003: Aerosol Absorption Optical Depth at 388 nm" url="http://disc.gsfc.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=OMI%2FAura%20Near%20UV%20Aerosol%20Optical%20Depth%20and%20Single%20Scattering%20Albedo%20Daily%20L3%20Global%201x1%20deg%20Lat%2FLon%20Grid%20V003;agent_id=OPeNDAP;variables=_HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388" quantity_type="Optical Depth" dataProductShortName="OMAERUVd" dataProductVersion="003"/>
</varList>

=item 4. -v

optional for printing verbose message; turn on if 1, or turn off if 0 for printing informational msg;  0 is default

=item 5. --help

optional; if existing, it will print the help msg, and ignore all other arguments and executions.

=back

=head1 AUTHOR

Xiaopeng Hu <Xiaopeng.Hu@nasa.gov>
Date Created: 2012-04-05
Richard Strub
Date Refactoring began: 2014-03-03

=cut

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Copy;
use XML::LibXML;

# use Date::Parse;
use Data::Dumper;
use DateTime;
use Time::HiRes qw (sleep);
use Time::Local;
use File::Temp qw/ tempfile tempdir /;
use Date::Manip;
use Giovanni::Scrubber;
use Giovanni::Data::NcFile;
use Giovanni::DataField;
use Giovanni::WorldLongitude;
use POSIX;

our ( $verbose, $profile );

use constant FILLVALUE => -9999.;    # default value, if not found in file

my ( $listfile, $workingdir, $catalog, $help );
if ( @ARGV < 2 ) {
    usage();
    exit(1);
}
GetOptions(
    'input=s'   => \$listfile,
    'outDir=s'  => \$workingdir,
    'catalog=s' => \$catalog,
    'v=i'       => \$verbose,
    'help'      => \$help
);
$profile = defined( $ENV{PROFILE} );
printf STDERR ( "INFO Time Start =%lf\n", Time::HiRes::time() ) if ($profile);

# to validate inputs
if (   !( defined $listfile )
    || !( defined $workingdir )
    || !( defined $catalog ) )
{
    usage();
    exit(1);
}
if ( !( -f $listfile ) && !( -e $listfile ) ) {
    quit( 1, "No input filename" );
}
if ( !( -f $catalog ) && !( -e $catalog ) ) {
    quit( 1, "$catalog does not exist" );
}
if ( !( -d $workingdir ) && !( -e $workingdir ) ) {
    quit( 1, "Working directory $workingdir does not exist" );
}
if ( defined $help ) {
    usage();
    exit(0);
}

print STDERR "STEP_DESCRIPTION Preparing data for processing\n";

$workingdir =~ s/\/$//i;

# This is used later on by Giovanni::DataStager. It grabs the year from granuleDate attribute:
my $scrubbedListingFile = "scrubbed-" . basename($listfile);
$scrubbedListingFile = "$workingdir/$scrubbedListingFile";

my $parser = XML::LibXML->new();
my $doc    = $parser->parse_file($listfile);

# Get varInfo data using Giovanni::DataField instead of reading XML:
my $dataFieldVarInfo = new Giovanni::DataField( MANIFEST => $catalog );

my @files             = $doc->findnodes('//dataFile');
my $total             = @files;
my $count             = 1;
my @dataFileListNodes = $doc->findnodes('//dataFileList');

# This is used by Giovanni::DataStager. It grabs the year from granuleDate attribute:
my $listingDoc = createXMLDocument("data");

# to loop thru each file list group
foreach my $fileListNode (@dataFileListNodes) {

    # From Listing file:
    my @dataFileNodes = $fileListNode->getChildrenByTagName('dataFile');

    # From varInfo/Giovanni::DataField
    my $dataId = $dataFieldVarInfo
        ->get_id;    # because of non-alphanumeric replacement below
    my $productShortName = $dataFieldVarInfo->get_dataProductShortName;

    # 0 -- do nothing; 1 -- to generate the virtual variable, e.g. 'magnitude'
    my $virtualFlag         = 0;
    my $virtualGeneratorCmd = undef;
    my $vectorFlag          = 0;       # 0 -- scalar; 1 -- vector
    my %vectorHash          = ();
    my $dataVariableName    = "";

# to create a <dataFileList> node
# This is used by Giovanni::DataStager. It grabs the year from granuleDate attribute:
    my $fileListNode = XML::LibXML::Element->new('dataFileList');
    if ( !defined $fileListNode ) {
        print STDERR "ERROR failed to create <dataFileList> node\n";
        exit(1);
    }
    $fileListNode->setAttribute( 'id', $dataId );

    # safe to replace non-alphanumeric to _
    $dataId =~ s/[^\w]/_/g;

    # TODO:  remove backward compatibility of virtualGenerator for security
    if ( $dataFieldVarInfo->get_virtualDataFieldGenerator ) {
        $virtualFlag = 1;

        # to make virtualGenerator backward compatible
        if ( $dataFieldVarInfo->get_virtualDataFieldGenerator !~ /^ncap2/ ) {
            $virtualGeneratorCmd = "ncap2 -O -s '"
                . $dataFieldVarInfo->get_virtualDataFieldGenerator . "'";
            print STDERR
                "INFO MERRA virtual Generator: $virtualGeneratorCmd \n"
                if ($verbose);
        }
    }
    else {
        $virtualFlag = 0;
    }
    print STDERR "DEBUG virtualFlag == $virtualFlag \n" if ($verbose);
    if ( $dataFieldVarInfo->get_vectorComponents ) {
        $vectorFlag = 1;
    }
    else {
        $vectorFlag = 0;
        %vectorHash = ();
    }
    if ($vectorFlag) {
        my @vectorVariables
            = split( /\,/, $dataFieldVarInfo->get_vectorComponents );
        my $index = 0;
        foreach my $var (@vectorVariables) {
            $vectorHash{$var} = ( $index == 0 ) ? 'u' : 'v';
            $index++;
        }
    }
    else {
        print STDERR "DEBUG not a vector \n" if ($verbose);
    }

    foreach my $fileNode (@dataFileNodes) {
        my $file = $fileNode->textContent;
        chomp($file);

        my $includedVariables  = "";
        my $excludedVariables  = "";
        my $temp_vname         = "";
        my $latVariableName    = "";
        my $lonVariableName    = "";
        my $startTimeAttribute = "";
        my $endTimeAttribute   = "";
        my $timeBoundString    = "";
        my $indexVariable      = "";
        my $exportTimes        = ();
        my $OSstartTime        = $fileNode->getAttribute("startTime");
        my $OSendTime          = $fileNode->getAttribute("endTime");

        if ( !( -e $file ) ) {
            quit( 1, "Cannot find working file", $file );
        }

        # to cat a working copy from the original
        my $fname       = basename($file);
        my $workingfile = "$workingdir/formatted_$fname";

        print STDERR "DEBUG Found raw file: $file\n" if ($verbose);
        print STDERR "USER_MSG Preparing file $count / $total: $fname\n";

        copy( $file, $workingfile );

# to generate a virtual variable before anything if a 'virtualGeneratr' attribute exists
        if ( $virtualFlag == 1 ) {
            runVirtualGenerator( $workingfile, $virtualGeneratorCmd, $file );

        }

        my $NcFile = Giovanni::Data::NcFile->new(
            NCFILE      => $workingfile,
            verbose     => $verbose,
            OSstartTime => $OSstartTime,
            OSendTime   => $OSendTime
        );

        # Note: This is looking for the dimensions for any bounds variables. It is not
        # looking for the name of the time:bounds variable,
        # this line is doing that: ...$NcFile->get_time_bnds_name($timeDimension);
        my %boundsDims = $NcFile->get_names_of_bounds_dimensions();

        # to find all variables for keeping
        my $dataType = "";
        $dataType = "virtual" if ($virtualFlag);
        $dataType = "vector"  if ($vectorFlag);

# Since this ID's the indexVariable, we want to use it before deleteSelectedVariables
        $indexVariable = getIndexVariable( $NcFile, $workingfile,
            $dataFieldVarInfo->get_zDimName );

        # Passing any (usually one) bounds dimensions to this function allows us to still
        # identify the dataField by it having the same ndims as there are.
        # e.g. Normally the number of dimensions in the file is the same as there are in
        # the dataField (shape). But if there is a bounds variable with a dimension, this
        # makes an additional dim and so we can no longer id the datafield.
        my ( $variablesForKeeping, $variablesForDeleting, $orgMainVar )
            = getVariablesForKeeping( $workingfile, $dataId, $dataType,
            $dataFieldVarInfo->get_zDimName,
            \%boundsDims, $NcFile->{rootNode}, $indexVariable );

        my $shape = Giovanni::Data::NcFile::get_variable_dimensions(
            $NcFile->{file}, $NcFile->{xpc}, $orgMainVar );

        my @varDims = split( / /, $shape );

        $includedVariables = join( ',', @{$variablesForKeeping} );
        $excludedVariables = join( ',', @{$variablesForDeleting} );

        # populate $NcFile object with time and cell_methods if they exist.
        $NcFile->populate_time_and_cell_methods($orgMainVar);

# to delete the variables/dimensions "Band", "OpticalDepth", and "ParticleType" for MISR data
        if ( $excludedVariables ne "" ) {
            deleteSelectedVariables(
                $virtualFlag, $excludedVariables,
                $workingfile, $includedVariables
            );
        }
        else {
            print STDERR "INFO: No excluded variables/dimensions found\n"
                if ($verbose);
        }

 # to change the index dimension to the real dimension for 3D variable ( AIRS)
 # and to delete the index variable
 # as well as to update the 'coordinates' attribute value for data variable
        rename_dimensionVariables( $dataFieldVarInfo, $workingfile, $NcFile,
            $orgMainVar, $indexVariable );

        # We are now converting all files to NetCDF4:
        if (Giovanni::Data::NcFile::to_netCDF4_classic( $workingfile,
                "$workingfile.nc4" ) != 1
            )
        {    # not using compression
            die "Unable to create netCDF4_classic formatted file";
        }
        move_file( "$workingfile.nc4", $workingfile, "$workingfile.nc4" );

    # to create a record dim
    # this ncecat command creates a record dimension, not a time dimension
    # if a time (our record) dimension already exists it will create a new one
    #  This seems to be necessary for make_record_dimension. not sure why
        $NcFile->init($workingfile);
        if ( !$NcFile->has_time_record_dimension_already( \@varDims ) ) {
            $NcFile->createRecordDim();
        }

        # to dump to xml
        my $xmlfile = dump2XML( $workingfile, $workingdir );

        # to extract the datetime from filename
        my ( $rootNode, $time, $datestring );
        (   $rootNode, $time, $datestring, $startTimeAttribute,
            $endTimeAttribute
            )
            = Giovanni::Data::NcFile::extractDateString( $fname,
            $startTimeAttribute, $endTimeAttribute, $xmlfile, $workingfile,
            $verbose );

        # complex timebounds
        #$NcFile->init($workingfile);

     # Populate $time with proper value before inserting it into time variable
        if ( $NcFile->populate_start_end_times($dataFieldVarInfo) ) {
            $time = $NcFile->getEpochBeginSeconds()
                if ( $NcFile->getEpochBeginSeconds() );
        }

# Not sure yet if we want to put only the date in the filename (for Wrapper.pm)
# or if we want to include the time (hourly data);
# We still need to use the extractDate() $datestring because all of our
# comparison workflow code still uses the filename for datetime comparisons:
# 	Giovanni::Algorithm::CorrelationWrapper::mk_file_list
# 	Giovanni::Algorithm::Wrapper::form_command
        if ( !$startTimeAttribute and $NcFile->{cfbegindate} ) {
            $startTimeAttribute = $NcFile->{cfbegindate};
            $endTimeAttribute   = $NcFile->{cfenddate};

            #$datestring         = $NcFile->{cfbegindate};
        }

        my $ncapString  = undef;
        my @ncapVarList = ();

        # to reformat nc data variables

        # rename record to time
        #`ncrename -d record,time $workingfile`;
        # new func by checking 'units'

       # Modify the dimension name to be compatible with visualizer and
       # AG data model; handling latitude and longitude currently. This is not
       # trying to rename the bounds variables
       # Dimension names may not be same as coordinate names!
        my %dimNameMap
            = $NcFile->rename_dimension_and_coordinate_variable_names(
            $workingfile);

     # Re-Up the doc since we may have changed the coordinate dimension names:
        $NcFile->init($workingfile);

        # to get dimension node list
        my @dimensionNodeList
            = getChildrenNodeList( $NcFile->{rootNode}, 'dimension' );
        my %dimensionHash = ();

        # This hash is the dims that are not in %boundsDims
        foreach my $dimensionNode (@dimensionNodeList) {
            my $dimname = getAttributeValue( $dimensionNode, 'name' );
            chomp($dimname);
            if ( !exists $boundsDims{$dimname} ) {
                $dimensionHash{$dimname} = 1;
            }
        }

        my $dimsize = keys(%dimensionHash);
        my @variableNodeList
            = getChildrenNodeList( $NcFile->{rootNode}, 'variable' );
        my $timeFlag = "false";
        my ( $timebndsDimension, $timeBndsType )
            = $NcFile->get_time_bnds_name( $NcFile->{time} );

        my $fillval           = FILLVALUE;
        my $timeUnitValue     = "";
        my $timebndsUnitValue = "";
        my $timeDimension     = $NcFile->{time};

    VARIABLE_LOOP: foreach my $vnode (@variableNodeList) {

            my $vname
                = getAttributeValue( $vnode, 'name' );    # get variable name

            if ( defined $dimNameMap{giovanni_name}{$vname} ) {
                $vname = $dimNameMap{giovanni_name}{$vname};
                $ncapString .= "$vname=$vname;";
                push( @ncapVarList, $vname );
            }
            print STDERR "INFO Variable name: $vname \n" if ($verbose);
            $temp_vname = $vname;

            # to manipulate attributes
            my @attributeNodeList
                = getChildrenNodeList( $vnode, 'attribute' );

           # Insert a lowercase version of the variable name as standard_name.
            unless ( existsAttribute( 'standard_name', @attributeNodeList ) )
            {
                my $vnameValue = lc($vname);

                # OMI data uses lat/lon for variable name.
                # Set standard_name to latitude/longitude
                if ( $vname eq 'lon' ) {
                    $vnameValue      = "longitude";
                    $lonVariableName = $vname;
                }
                if ( $vname eq 'lat' ) {
                    $vnameValue      = "latitude";
                    $latVariableName = $vname;
                }

                # not to add a 'standard_name'
                if (Giovanni::Data::NcFile::does_variable_exist(
                        $NcFile->{xpc}, $vname
                    )
                    )
                {
                    createAttribute( $workingfile, 'standard_name', $vname,
                        'c', $vnameValue );
                }
            }

            my $skipFillValue = 0;
        ATTRIBUTE_LOOP: foreach my $attrNode (@attributeNodeList) {
                my $attrName = getAttributeValue( $attrNode, 'name' );
                chomp($attrName);
                my $from = "$vname\@$attrName";
                my $to   = $attrName;
                $to =~ s/^($vname\.)//i;
                $to =~ s/^[\s]+|[\s]+$//;

                if ( !%boundsDims or $NcFile->isInstantaneous() ) {
                    if ( $attrName =~ m/bounds/ )    # bounds and climatology
                              # are CF strings. time:bounds is optional for G4
                              # time:climatology is not
                    {    # to delete 'bounds' attribute from a TIME variable
                        deleteAttribute( $workingfile, $attrName, $vname );
                    }
                }

                if (    $vname !~ /^lat/i
                    and $vname !~ /^lon/i
                    and $vname !~ /^time/i )
                {

                    # to change the attribute data type
                    my $vtype = getAttributeValue( $vnode, 'type' );
                    if ( $vtype =~ /float/ or $vtype =~ /double/ ) {
                        if (   $attrName eq "scale_factor"
                            or $attrName eq "add_offset" )
                        {
                            my $attrValue
                                = getAttributeValue( $attrNode, 'value' );
                            my $attrDataType
                                = getAttributeValue( $attrNode, 'type' );
                            if (   $attrDataType eq "double"
                                or $attrDataType eq "float" )
                            {
                                deleteAttribute( $workingfile, $attrName,
                                    $vname );
                                createAttribute( $workingfile, $attrName,
                                    $vname, 'f', $attrValue );
                            }
                        }
                    }

  # changed the 'units' to '1' if value is "NoUnits", or "UNITLESS", or "none"
  # print STDERR "attrName = $attrName \n";
                    if ( $attrName eq 'units' ) {

                        # Clean out any extra spaces if
                        # they exists JSA 05/2012
                        my $unitsVal
                            = getAttributeValue( $attrNode, 'value' );
                        $unitsVal =~ s/^\s+|\s+$|\t|\r//;
                        $unitsVal = '1' if ($unitsVal eq "");
                        updateAttributeValue( $workingfile, $attrName, $vname,
                            'c', $unitsVal );
                        if (   $unitsVal =~ /^NoUnits$/i
                            or $unitsVal =~ /^UNITLESS$/i
                            or $unitsVal =~ /^none$/i )
                        {
                            updateAttributeValue( $workingfile, $attrName,
                                $vname, 'c', '1' );
                        }
                    }

                    my $coordinatesVal = getAttributeValue( $vnode, 'shape' );

                    # changed the 'coordinates' value
                    if ( $attrName eq 'coordinates' ) {
                        chomp($coordinatesVal);
                        if ( $coordinatesVal !~ /time/ ) {
                            $coordinatesVal =~ s/^record/time/i;
                        }
                        else {
                            $coordinatesVal =~ s/^record//i;
                        }
                        foreach my $dimName ( keys %dimNameMap ) {
                            $coordinatesVal
                                =~ s/$dimName/$dimNameMap{giovanni_name}{$dimName}/g;
                        }
                        $coordinatesVal =~ s/^\s+//i;
                        if ( $coordinatesVal ne "time lat lon" ) {
                            print STDERR
                                "WARNING reset 'coordinates' attribute value from \"$coordinatesVal\" to \"time lat lon\"\n";
                            $coordinatesVal = "time lat lon";
                        }
                        updateAttributeValue( $workingfile, $attrName, $vname,
                            'c', $coordinatesVal );
                    }
                }
                else {

 # to extract the 'units' attribute value from 'time' variable for GoCart data
                    if (   $attrName eq 'units'
                        && $timeDimension
                        && ( $timeDimension eq $vname ) )
                    {
                        $timeUnitValue
                            = getAttributeValue( $attrNode, 'value' );
                    }

                    # Note: merra was not supplying attributes for time_bnds

                    if (   $attrName eq 'units'
                        && $timebndsDimension
                        && ( $timebndsDimension eq $vname ) )
                    {
                        $timebndsUnitValue
                            = getAttributeValue( $attrNode, 'value' );
                    }
                }
            }

            # to create a new time variable if time dimension not exists
            if ( !$timeDimension && $timeFlag =~ /false/gi ) {
                my $timeDimCommand = "ncrename -d record,time $workingfile";
                runNCOCommand( $timeDimCommand,
                    "Change 'record' to 'time' dimension" );

  # to add 'time' variable and attribute
  # At this point the $time variable has been retrieved from extractDateString
                my $timeCommand
                    = "ncap2 -O -h -s \"time[time]=$time\" $workingfile $workingfile";
                runNCOCommand( $timeCommand, "Adding time variable" );
                $includedVariables = "time";
                createAttribute( $workingfile, 'standard_name', 'time', 'c',
                    'time' );
                createAttribute( $workingfile, 'long_name', 'time', 'c',
                    'time' );
                createAttribute( $workingfile, 'calendar', 'gregorian', 'c',
                    'time' );
                createAttribute( $workingfile, 'units', 'time', 'c',
                    'seconds since 1970-01-01 00:00:00' );
                $timeFlag = "true";
            }

            # special convert to seconds time case
            # so I need a special convert to seconds time_bnds case
            # time case:
            elsif ( $vname eq "time"
                or ( $timeDimension && $timeDimension eq $vname ) )
            {
                my $type = getAttributeValue( $vnode, "type" );

# NOBM was first case of time as float (nominal int/double). For whatever reason NCO
# puts the time in SCI when you update it when its a float...
                if ( $type eq 'float' ) {
                    update_type( $vname, 'float', 'double', $workingfile,
                        $file );
                }
                print STDERR "DEBUG the data type for $vname is $type \n"
                    if ($verbose);
                my @timeDataVal
                    = getVariableValues( $vname, $workingfile, $type );

                # $timeDataVal = floor($timeDataVal);

                if (    $timeUnitValue ne ""
                    and $timeUnitValue
                    !~ /^seconds since 1970-01-01 00:00:00/ )
                {
                    print STDERR
                        "INFO Product Short Name == $productShortName \n"
                        if ($verbose);
                    my @secondsArray
                        = Giovanni::Data::NcFile::cf2epoch( $timeUnitValue,
                        \@timeDataVal,
                        $dataFieldVarInfo->get_dataProductTimeInterval,
                        0 );
                    my $seconds = join( ',', @secondsArray );

                    print STDERR "INFO total seconds = $seconds \n"
                        if ($verbose);

                    if ( defined $seconds ) {
                        print STDERR
                            "INFO timeUnitValue = $timeUnitValue; timeDataVal=$timeDataVal[0]; dataTimeUnit=$dataFieldVarInfo->get_dataProductTimeInterval;\n"
                            if ($verbose);
                        updateAttributeValue( $workingfile, 'units', $vname,
                            'c', 'seconds since 1970-01-01 00:00:00' );
                        my $timeUpdateCommand
                            = "ncap2 -O -h -s '$vname(:)={$seconds}' $workingfile $workingfile.time";
                        runNCOCommand( $timeUpdateCommand,
                            "Update the time variable value" );
                        print STDERR
                            "INFO update time command: $timeUpdateCommand\n"
                            if ($verbose);
                        move_file( "$workingfile.time", $workingfile, $file );

                    }
                    else {
                        quit( 1, "ERROR Invalid date units: $timeUnitValue" );
                    }
                }

              # change the time variable name to 'time' if it is 'time' proper
                if ( $timeDimension ne "time" ) {

                 # The time dimension may already be named time FEDGIANNI-1561
                    if ( exists $dimensionHash{time} ) {
                        my $timeCommand
                            = "ncrename -h -v $timeDimension,time $workingfile";
                        runNCOCommand( $timeCommand,
                            "Rename $timeDimension to 'time'" );
                    }
                    else {
                        my $timeCommand
                            = "ncrename -h -v $timeDimension,time  $workingfile";
                        runNCOCommand( $timeCommand,
                            "Rename $timeDimension dim to 'time' and  $timeDimension variable to 'time'"
                        );
                    }

               # to update 'standard_name' value to 'time' for variable 'time'
                    updateAttributeValue( $workingfile, 'standard_name',
                        'time', 'c', 'time' );
                    updateAttributeValue( $workingfile, 'long_name', 'time',
                        'c', 'time' );
                }
            }

            # time_bnds case:
            elsif ( $vname eq "time_bnds"
                or
                ( $timebndsDimension ne "" && $timebndsDimension eq $vname ) )
            {
                if ( $timebndsUnitValue eq "" ) {
                    if ( $timeUnitValue eq "" ) {

        # timeUnitValue's assignment varies upon the order of the variables so
        # sometimes we need to retrieve it explicitly
                        my ( $atthash, $attlist )
                            = Giovanni::Data::NcFile::get_variable_attributes(
                            $workingfile, 0, "time" );
                        $timeUnitValue = $atthash->{units};
                    }
                    $timebndsUnitValue
                        = $timeUnitValue;    # merra not supplying this attr
                }
                my $type = getAttributeValue( $vnode, "type" );
                print STDERR "DEBUG the data type for $vname is $type \n"
                    if ($verbose);
                my @timeDataVal
                    = getVariableValues( $vname, $workingfile, $type );

                if (    $timebndsUnitValue ne ""
                    and $timebndsUnitValue !~ /^seconds/ )
                {
                    my $seconds
                        = "$NcFile->{beginepochsecs},$NcFile->{endepochsecs}";
                    if ( $type eq 'float' ) {
                        update_type( $vname, 'float', 'int', $workingfile,
                            $file );
                    }

                    if ( defined $NcFile->{endepochsecs} ) {
                        updateAttributeValue( $workingfile, 'units', $vname,
                            'c', 'seconds since 1970-01-01 00:00:00' );
                        my $timeUpdateCommand
                            = "ncap2 -O -h -s '$vname(:,:)={$seconds}' $workingfile $workingfile.time";
                        runNCOCommand( $timeUpdateCommand,
                            "Update the time variable value" );
                        print STDERR
                            "INFO update time command: $timeUpdateCommand\n"
                            if ($verbose);
                        move_file( "$workingfile.time", $workingfile, $file );
                    }
                    else {
                        quit( 1, "ERROR Invalid date units: $timeUnitValue" );
                    }
                }

            # In Decision Log we decided to convert these two bounds variables
            # to pre-set names e.g. time:bounds = "time_bnds" instead of
            # time:bounds = "<whatever>"
                if ($timebndsDimension
                    and (   $timebndsDimension ne "time_bnds"
                        and $timebndsDimension ne "clim_bnds" )
                    )
                {
                    my $g4StdName = "time_bnds";
                    my $localattr = "bounds";
                    if ( $timeBndsType !~ /time/ ) {
                        $g4StdName = "clim_bnds";
                        $localattr = "climatology";
                    }
                    my $timeCommand
                        = "ncrename -h -v $timebndsDimension,$g4StdName $workingfile";
                    runNCOCommand( $timeCommand,
                        "Rename $timebndsDimension to $g4StdName" );

               # to update 'standard_name' value to 'time' for variable 'time'
                    updateAttributeValue( $workingfile, 'standard_name',
                        $g4StdName, 'c', $localattr );
                    updateAttributeValue( $workingfile, $localattr,
                        $timebndsDimension, 'c', $g4StdName );
                    updateAttributeValue( $workingfile, $localattr, 'time',
                        'c', $g4StdName );

                    #	ncatted -O -a "$localattr,time,o,c,$g4StdName"

                }
            }    # time bnds case

    # to get the associated dimension from variable 'shape' attribute in .ncml
            my $vardim = getAttributeValue( $vnode, 'shape' );
            my @vshape       = split( ' ', $vardim );
            my $vsize        = @vshape;
            my $finalVarName = $dataId;

         # to change the variable name if dimension size = variable shape size
            if ( $dimsize == $vsize ) {
                my $dimmatch = 1;
                foreach my $vd (@vshape) {
                    if ( !( defined $dimensionHash{$vd} ) ) {
                        $dimmatch = 0;
                        last;
                    }
                }
                if ( $dimmatch == 1 ) {
                    $dataVariableName = $finalVarName;
                    my $dataFieldFillValueFieldName
                        = $dataFieldVarInfo->get_fillValueFieldName;

  # if there exists a fill value field name, then replace it with '_FillValue'

                    if (Giovanni::Data::NcFile::StringBoolean(
                            $dataFieldFillValueFieldName)
                        )
                    {    # this is the case where it is defined in AESIR
                        my $attrNameFlag = 0;
                    ATTRIBUTE_LOOP:
                        foreach my $attrNode (@attributeNodeList) {
                            my $attrName
                                = getAttributeValue( $attrNode, 'name' );
                            if ( $attrName eq $dataFieldFillValueFieldName ) {
                                $attrNameFlag = 1;

# to change the _FillValue from 'NaNf' to FILLVALUE if 'NaNf' exist.   e.g. in AIRNOW data
                                $fillval
                                    = getAttributeValue( $attrNode, 'value' );
                                print STDERR
                                    qq(INFO fillvalue for $dataFieldFillValueFieldName/$vname == $fillval \n)
                                    if ($verbose);
                                if ( $fillval =~ /NaN/gi ) {
                                    print STDERR "INFO FillValue === NaN \n"
                                        if ($verbose);
                                    my $fvCommand
                                        = "ncatted -a $dataFieldFillValueFieldName,$vname,o,f,"
                                        . FILLVALUE
                                        . " $workingfile";
                                    runNCOCommand( $fvCommand,
                                        'Changing the fill value "NaN" to '
                                            . FILLVALUE );
                                    $fillval
                                        = FILLVALUE;  # only if fillval is NaN
                                    print STDERR
                                        "INFO changed the _FillValue from NaNf to "
                                        . FILLVALUE;
                                }
                                last;
                            }
                        }
                        if (   $attrNameFlag == 1
                            && $dataFieldFillValueFieldName ne "_FillValue" )
                        {
                            changeAttributeName( $workingfile,
                                qq($vname\@$dataFieldFillValueFieldName),
                                '_FillValue' );
                        }
                        if (existsAttribute(
                                "$vname.missing_value", @attributeNodeList
                            )
                            )
                        {

                            # to rm GoCart missing_value; not CF-1 compliant
                            deleteAttribute( $workingfile,
                                "$vname.missing_value", $vname );
                        }
                    }
                    else {
                        foreach my $attrNode (@attributeNodeList) {
                            my $attrName
                                = getAttributeValue( $attrNode, 'name' );
                            if ( $attrName eq '_FillValue' )
                            { # This is the case if it is not defined in AESIR but is defined in file
                                $fillval
                                    = getAttributeValue( $attrNode, 'value' );
                                last;
                            }
                        }
                    }

                    # to update the 'standard_name'
                    if (Giovanni::Data::NcFile::StringBoolean(
                            $dataFieldVarInfo->get_dataFieldStandardName
                        )
                        )
                    {
                        if ( existsAttribute('standard_name') ) {
                            updateAttributeValue(
                                $workingfile,
                                'standard_name',
                                $vname,
                                'c',
                                $dataFieldVarInfo->get_dataFieldStandardName
                            );
                        }
                        else {
                            createAttribute(
                                $workingfile,
                                'standard_name',
                                $vname,
                                'c',
                                $dataFieldVarInfo->get_dataFieldStandardName
                            );
                        }
                    }

                    # to add vector variable
                    if ( $vectorFlag == 1 ) {
                        if ( defined $vectorHash{$vname} ) {
                            $finalVarName
                                = "$dataId" . '_' . $vectorHash{$vname};
                        }
                        print STDERR
                            "INFO found a vector variable: $vname -> $finalVarName\n"
                            if ($verbose);
                    }
                    else {
                        print STDERR "INFO not a vector variable\n"
                            if ($verbose);
                    }
                    print STDERR "INFO $vname === $finalVarName \n"
                        if ($verbose);
                    print STDERR
                        "INFO Virtual = $virtualFlag ; Vector = $vectorFlag \n"
                        if ($verbose);
                    changeVariableName( $workingfile, $vname, $finalVarName )
                        if ( $vname ne $finalVarName );

                    # to add the vector attribute 'vectorComponents'
                    if ($vectorFlag) {
                        my $attrPrefix = $vectorHash{$vname}
                            . " of ";    # to get 'u of' or 'v of' string
                        my $newAttr = $attrPrefix . $dataId;
                        createAttribute( $workingfile, 'vectorComponents',
                            $finalVarName, 'c', $newAttr );
                    }

     # to update the "$includedVariales" string since the variable name change
                    $temp_vname = $finalVarName;

           # if 'coordinates' attribute does not exist in a plottable variable
                    if (    $vname !~ /lat/i
                        and $vname !~ /latitude/i
                        and $vname !~ /lon/i
                        and $vname !~ /longitude/i
                        and $vname !~ /($indexVariable)/i
                        and $vname !~ /^time/i )
                    {
                        if (!existsAttribute(
                                'coordinates', @attributeNodeList
                            )
                            )
                        {
                            print STDERR
                                "INFO 'coordinates' attribute not found\n"
                                if ($verbose);
                            createAttribute( $workingfile, 'coordinates',
                                $finalVarName, 'c', 'time lat lon' );
                        }
                        if ( !existsAttribute( 'units', @attributeNodeList ) )
                        {
                            createAttribute( $workingfile, 'units',
                                $finalVarName, 'c', '1' );
                        }
                    }

                    # should find only one
                    my $productName    = "";
                    my $productVersion = "";
                    my $longName       = "";
                    createAttribute( $workingfile, 'quantity_type',
                        $finalVarName, 'c',
                        $dataFieldVarInfo->get_quantity_type )
                        if ( defined $dataFieldVarInfo->get_quantity_type );
                    createAttribute( $workingfile, 'product_short_name',
                        $finalVarName, 'c',
                        $dataFieldVarInfo->get_dataProductShortName )
                        if (
                        defined $dataFieldVarInfo->get_dataProductShortName );
                    createAttribute( $workingfile, 'product_version',
                        $finalVarName, 'c',
                        $dataFieldVarInfo->get_dataProductVersion )
                        if (
                        defined $dataFieldVarInfo->get_dataProductVersion );

                    # to add/update the 'long_name' attribute to the variable
                    if ( defined $dataFieldVarInfo->get_long_name ) {
                        if (existsAttribute(
                                'long_name', @attributeNodeList
                            )
                            )
                        {

                            # overwrite the value
                            updateAttributeValue( $workingfile, 'long_name',
                                $finalVarName, 'c',
                                $dataFieldVarInfo->get_long_name );
                        }
                        else {

                            # add the new attribute
                            createAttribute( $workingfile, 'long_name',
                                $dataId, 'c',
                                $dataFieldVarInfo->get_long_name );
                        }
                    }
                    else {
                        quit( 1,
                            "ERROR 'long_name' attribute not found for the variable $finalVarName in varInfo.xml"
                        );
                    }

                }
            }

        }    # END of VARIABLE_LOOP

# This is the first section of the code that should be refactored. -rstrub 5/13/2014
# Global attributes here
# to add a global attributes 'temporal_resolution', 'start_time', and 'end_time'
        my $rmGlobalAttributeCommand
            = "ncatted -h -O -a ,global,d,,  $workingfile";
        runNCOCommand( $rmGlobalAttributeCommand,
            "Remove global attributes" );
        createAttribute( $workingfile, 'Conventions', 'global', 'c',
            'CF-1.4' );
        print STDERR
            "DEBUG dataTimeUnit == $dataFieldVarInfo->get_dataProductTimeInterval \n"
            if ($verbose);
        my $startobj;
        my $endobj;
        my $midobj;

        if ( $dataFieldVarInfo->get_dataProductTimeInterval ne "" ) {

# THE NEW CODE START:
# this method already has access to workingfile header and global variables
# retrieved immediately upon assignment of the workingfile above.
# It looks for the actual start and end time of the file in CoreMetadata,
# HDF-EOS Global Metadata, HDF Global Metadata, time dimension, and then filename.
# In this case of TRMM 3-Hourly, it uses HDF Global Metadata
            $NcFile->init($workingfile);
            $startobj = add_offset( $NcFile->{rangebeginningdate},
                $NcFile->{rangebeginningtime}, 0 );
            if ( $NcFile->{rangeendingdate} ) {    # may not have one yet...
                $endobj = add_offset( $NcFile->{rangeendingdate},
                    $NcFile->{rangeendingtime}, 0 );
            }

            $midobj
                = DateTime->from_epoch(
                epoch => ( int( ( $endobj->epoch + $startobj->epoch ) / 2 ) )
                );

            # Check first if isClimatology
            if ( $dataFieldVarInfo->isClimatology ) {
                my $datamonth = sprintf( "%02d", $startobj->month() );
                my $timeUpdateCommand
                    = "ncap2 -O -h -s 'datamonth[time]=$datamonth' $workingfile $workingfile.month";
                runNCOCommand( $timeUpdateCommand,
                    "Add datamonth variable value" );
                move_file( "$workingfile.month", $workingfile, $file );
                createAttribute( $workingfile, 'long_name', 'datamonth', 'c',
                    "Standardized Date Label" );
                $includedVariables = "datamonth,$includedVariables";
            }

            # If monthly make sure the enddate is the last day of the month
            # (We don't want to do this if it is climatology data - which may
            # in fact also be identified as monthly)
            # If daily make sure the endtime is the last sec of the day
            elsif (
                $dataFieldVarInfo->get_dataProductTimeInterval eq 'monthly'
                and !$NcFile->isInstantaneous() )
            {

                # to set the 'datamonth' variable
                my $datamonth = sprintf( "%04d%02d", $midobj->year(),
                    $midobj->month() );
                my $timeUpdateCommand
                    = "ncap2 -O -h -s 'datamonth[time]=$datamonth' $workingfile $workingfile.month";
                runNCOCommand( $timeUpdateCommand,
                    "Add datamonth variable value" );
                move_file( "$workingfile.month", $workingfile, $file );
                createAttribute( $workingfile, 'long_name', 'datamonth', 'c',
                    "Standardized Date Label" );
                $includedVariables = "datamonth,$includedVariables";
                $exportTimes->{dataPeriod} = $datamonth;

                if (    $endobj
                    and !$NcFile->usingTimeBnds()
                    and (
                        (     $NcFile->{endepochsecs}
                            - $NcFile->{beginepochsecs}
                        ) < 2419100
                    )
                    )
                {    # may not be defined yet:
                     # sanity check for weird gldas case make sure time < 28 days before we
                    $endobj->set_day(
                        Date::Manip::Date_DaysInMonth(
                            $endobj->month, $endobj->year
                        )
                    );
                }
                $datestring = $startobj->date();
            }
            elsif ( $dataFieldVarInfo->get_dataProductTimeInterval eq 'daily' and !$NcFile->isInstantaneous() )
            {
                # DAILYs ONLY:
                my $dataday = sprintf( "%04d%03d",
                    $midobj->year(), $midobj->day_of_year() );

                if ($startobj and !$NcFile->usingTimeBnds() )
                {
                    # If the data is supplying time bounds then the end time is whatever
                    # they say.
                    # This subroutine sets the times for the file to be canonical
                    # only if it is a candidate for canonical (day:00:00:00 - day+1:00:00:00) 
                    # This does not matter for search (search has already occurred at this point)
                    # This does not matter for daily data-pairing (uses dataday)
                    # If you want have the correct number of granules selected, use
                    # AESIR's search offsets. They are VERY powerful
                    insist_on_lastsecondoftheday( $startobj, $endobj );

                    $dataday = sprintf( "%04d%03d",
                        $midobj->year(), $midobj->day_of_year() );

                }
                print STDERR "INFO dataday == $dataday \n" if ($verbose);
                my $timeUpdateCommand
                    = "ncap2 -O -h -s 'dataday[time]=$dataday' $workingfile $workingfile.day";
                runNCOCommand( $timeUpdateCommand,
                    "Add dataday variable value" );
                move_file( "$workingfile.day", $workingfile, $file );
                createAttribute( $workingfile, 'long_name', 'dataday', 'c',
                    "Standardized Date Label" );
                $includedVariables         = "dataday,$includedVariables";
                $datestring                = $startobj->date();
                $exportTimes->{dataPeriod} = $dataday;

            }

            my $startTimeAttribute = dateobj2attribute($startobj);
            my $endTimeAttribute   = dateobj2attribute($endobj);
            createAttribute( $workingfile, 'start_time', 'global', 'c',
                "$startTimeAttribute" );
            createAttribute( $workingfile, 'end_time', 'global', 'c',
                "$endTimeAttribute" );
            createAttribute( $workingfile, 'temporal_resolution', 'global',
                'c', $dataFieldVarInfo->get_dataProductTimeInterval );
            $exportTimes->{start_time} = $startTimeAttribute;
            $exportTimes->{end_time}   = $endTimeAttribute;

        }
        else {
            print STDERR
                "INFO did not find 'temporal_resolution in varInfo.xml\n"
                if ($verbose);
            $startobj = add_offset( $NcFile->{rangebeginningdate},
                $NcFile->{rangebeginningtime}, 0 );
            if ( $NcFile->{rangeendingdate} ) {    # may not have one yet...
                $endobj = add_offset( $NcFile->{rangeendingdate},
                    $NcFile->{rangeendingtime}, 0 );
            }
            my $startTimeAttribute = dateobj2attribute($startobj);
            my $endTimeAttribute   = dateobj2attribute($endobj);
            createAttribute( $workingfile, 'start_time', 'global', 'c',
                "$startTimeAttribute" );
            createAttribute( $workingfile, 'end_time', 'global', 'c',
                "$endTimeAttribute" );
            createAttribute( $workingfile, 'temporal_resolution', 'global',
                'c', 'not provided' );
            $exportTimes->{start_time} = $startTimeAttribute;
            $exportTimes->{end_time}   = $endTimeAttribute;

        }

# do this here so that the test above on where we obtained the times from holds
        $datestring = $startTimeAttribute if !$datestring;

        if ( $dataFieldVarInfo->isClimatology ) {
            if ( !$timebndsDimension ) {
                warn
                    "This is an unusual situation. You are: CREATING A CLIMATOLOGY BOUNDS ATTRIBUTE\n\n";

                # add this attribute to time variable:
                updateAttributeValue( $workingfile, "climatology", "time",
                    'c', 'clim_bnds' );

                # add a new variable called clim_bnds
                my $first  = $startobj->epoch;
                my $second = $endobj->epoch;
                my $ncapstring
                    = qq('defdim("nv",2);  clim_bnds[\$time,\$nv]={$first,$second}');
                my $timeUpdateCommand
                    = qq(ncap2 -O -h -s $ncapstring $workingfile $workingfile.clim);
                print STDERR $timeUpdateCommand, "\n" if $verbose;
                runNCOCommand( $timeUpdateCommand,
                    "Add a climatology bounds variable this file SHOULD ALREADY HAVE HAD!"
                );
                move_file( "$workingfile.clim", $workingfile, $file );
                updateAttributeValue( $workingfile, "cell_methods",
                    "clim_bnds", 'c', 'record: mean' );
                updateAttributeValue( $workingfile, "standard_name",
                    "clim_bnds", 'c', 'climatology' );
                updateAttributeValue( $workingfile, "units", "clim_bnds", 'c',
                    'seconds since 1970-01-01 00:00:00' );

            }

# If a climatology file does not have a timebnds dimension then we need to create one

            my $midpointTimeAttribute = getDateMidpoint( $startobj, $endobj );
            $exportTimes->{time} = $midpointTimeAttribute->epoch;
            update_time_value( $midpointTimeAttribute, 0, $workingfile );
        }
        else {
            update_time_value( $startTimeAttribute, $startobj->epoch,
                $workingfile );
        }

        # Unpack Latitude/Longitude for SeaWIFS use ncap2 to handle it
        # JSA 05/2012
        if ( defined $ncapString ) {
            my $unpackCommand
                = "ncap2 -O  -s '$ncapString' $workingfile $workingfile";
            runNCOCommand( $unpackCommand, "Unpack lat/lon" );

            # Build a ncatted string that will unpack the data
            my $deletionString = "ncatted ";
            foreach my $varItem (@ncapVarList) {
                $deletionString
                    .= "-a \"scale_factor,$varItem,d,,\" -a \"add_offset,$varItem,d,,\" ";
            }

            # `$deletionString $workingfile`;
            $deletionString .= " $workingfile";
            runNCOCommand( $deletionString,
                "Delete 'scale_factor' and 'add_offset'" );
        }

       # awkward fill values caused by compression attributes that should only
       # be there if they are needed
        handling_already_unpacked_data( $NcFile, $dataId );

        # Reverse decreasing coordinates to be increasing
        reverseCoords( $workingfile, $profile );
        EvenOutLatitudes( $workingfile, 'lat' );   # name is always lat by now
        my $status = $NcFile->reorder_latlon_dimensions();
        if ( $status != 0 ) {
            die "reorder_latlon_dimensions failed for $workingfile";
        }

        # padding and shifting the latitude/longitude
        print STDERR
            "INFO lat = $latVariableName; lon = $lonVariableName; var = $dataId \n"
            if ($verbose);
        if ( $latVariableName ne "" && $lonVariableName ne "" ) {
            if ( $virtualFlag == 0 && $vectorFlag == 0 ) {
                padding_sequence( $dataId, $workingfile, $workingdir,
                    \$fillval );
            }
            else {

                # to do padding to a vector variable
                if ($vectorFlag) {
                    foreach my $key ( keys %vectorHash ) {
                        my $newVarName = $dataId . "_" . $vectorHash{$key};
                        padding_sequence(
                            $newVarName, $workingfile,
                            $workingdir, \$fillval
                        );
                    }
                }
                if ($virtualFlag) {
                    padding_sequence( $dataId, $workingfile, $workingdir,
                        \$fillval );
                }
            }
            $latVariableName = '';
            $lonVariableName = '';
        }
        else {

# Check and do padding for special cases:
# get_padding now (Sep 2014 w/ TRMM RT) only pads if it is only needed in the lat direction
# get_padding now (Sep 2014 w/ TRMM RT) will either:
# a) longitude shift and pad latitude
# b) pad both if it is only needed in lat direction (if needed in both directions it won't pad (NLDAS))
            $workingfile
                = padding_sequence( $dataId, $workingfile, $workingdir,
                \$fillval );
        }

        # New MinVal Location:
        if ((   ApplyValidMinAndValidMax(
                    $workingfile, $dataId, $dataFieldVarInfo,
                    $fillval,     FILLVALUE
                )
            ) != 0
            )
        {
            die "Filtering data with validMin and or validMax failed";
        }

# to update the 'long_name' attribute value for the lat/lon variables for MODIS OpenDap data file
# but to be consistent, the following code will force all data files to have the exact same 'long_name' value
# FEDGIANNI-1823 Now we want to remove this value if it exists
        $NcFile->delete_attribute( 'long_name', 'lon' );
        $NcFile->delete_attribute( 'long_name', 'lat' );

# The standard_names, because of padding_sequence are always set correctly.
# At this point, only files that DID have lat and lon:standard_names and they were
# set incorrectly to start with need this code (so I don't expect it will ever be needed)
# So I am going to change regression test
# ncScrubber_NLDAS_climatology_bounds.t input to have a silly lat:standard_name
# rather than create a separate unit test.
        updateAttributeValue( $workingfile, 'standard_name', 'lat', 'c',
            'latitude' );
        updateAttributeValue( $workingfile, 'standard_name', 'lon', 'c',
            'longitude' );

# These are all recent (3-5/2014) requirements which use Giovanni::Data::NcFile:
# So much has been done outside of the class that this must be re-upped:
        $NcFile->init($workingfile);
        $status = $NcFile->delete_attribute( "valid_range", $dataId );
        if ( $status != 0 ) {
            die "delete_attribute failed for $workingfile";
        }
        $status = $NcFile->unpack_all_nondim_variables();
        if ( $status != 0 ) {
            die "unpack_all_ondim_variables failed for $workingfile";
        }

        # Handle units update
        if ($vectorFlag) {
            foreach my $key ( keys %vectorHash ) {
                my $vname = $dataId . "_" . $vectorHash{$key};
                $status
                    = handleUnitsUpdate( $vname, $dataFieldVarInfo, $NcFile );
                if ( $status != 0 ) {
                    warn "update_attribute failed for $workingfile";
                }
            }
        }
        else {
            $status
                = handleUnitsUpdate( $dataId, $dataFieldVarInfo, $NcFile );
        }
        if ( $status != 0 ) {
            warn "update_attribute of units failed for $workingfile";
        }

# update time variable using slider time from edda. Remember, as in the case of TRMM
#  existing time may not always be in the beginning.
#  Climatology defaults to middle using a special algorithm.
        if ( !$dataFieldVarInfo->isClimatology ) {
            $exportTimes->{time}
                = apply_timeIntvRepPos( $dataFieldVarInfo, $startobj, $endobj,
                $workingfile );
        }

#  ALL NOW HAVE TIME_BNDS:
#  We can count on time='time',time bounds = 'time_bnds' time attribute name (not value) is 'bounds'
        addTimeBnds( $NcFile, $startobj, $endobj, $workingfile );

        # Double check for instantaneous and add time: point for cell method.
        applyCellMethodPointForInstantaneous( $dataId, $startobj, $endobj,
            $workingfile );

        addLatLonBnds( $workingfile, $workingdir );

        # to clean the global 'history' attribute, but this entry remains
        my $deleteHistoryCommand
            = "ncatted -O -h -a \"history,global,d,c,,\" $workingfile";
        runNCOCommand( $deleteHistoryCommand, "Delete 'history' attribute" );

# to clean the global 'history_of_appended_files' attribute, an NCO 4.5.3 thing
        $deleteHistoryCommand
            = "ncatted -O -h -a \"history_of_appended_files,global,d,c,,\" $workingfile";
        runNCOCommand( $deleteHistoryCommand, "Delete 'history' attribute" );

        # to compress the netcdf file
        if (   defined $dataFieldVarInfo->get_deflationLevel
            && $dataFieldVarInfo->get_deflationLevel >= 1
            && $dataFieldVarInfo->get_deflationLevel <= 9 )
        {
            print STDERR "INFO compression level set to "
                . $dataFieldVarInfo->get_deflationLevel . "\n"
                if ($verbose);
            my $compressCommand
                = "nccopy -k 4 -d "
                . $dataFieldVarInfo->get_deflationLevel
                . "  $workingfile $workingfile.compress";
            runNCOCommand( $compressCommand,
                "Deflate data to level "
                    . $dataFieldVarInfo->get_deflationLevel );
            $workingfile = "$workingfile.compress";

        }
        else {
            print STDERR
                "INFO no compression level requested, or the level is out of range (<0 or >9)\n"
                if ($verbose);
        }

        # to change the filename per file name convention
        # <SERVICE>.<DATAID>.<DATESTAMP>.[<BBOX>.]<SUFFIX>
        my $filenameDatestring = $datestring;
        $filenameDatestring =~ s/[\-\:TZ]//g;
        my $newFileName
            = "$workingdir/scrubbed.$dataId.$filenameDatestring.nc";
        move_file( $workingfile, $newFileName, $file );
        print STDERR
            "INFO formalized the working file name to $newFileName \n"
            if ($verbose);

# to append a child file node for output xml
# This is used by Giovanni::DataStager. It grabs the year from granuleDate attribute:
        my $dataFileNode = XML::LibXML::Element->new('dataFile');
        $dataFileNode->appendText($newFileName);
        $dataFileNode->setAttribute( 'time', $exportTimes->{time} );
        $dataFileNode->setAttribute(
            'startTime',
            Giovanni::Data::NcFile::string2epoch(
                $exportTimes->{start_time}
            )
        );
        $dataFileNode->setAttribute( 'endTime',
            Giovanni::Data::NcFile::string2epoch( $exportTimes->{end_time} )
        );
        $dataFileNode->setAttribute( 'dataPeriod',
            $exportTimes->{dataPeriod} );
        $fileListNode->appendChild($dataFileNode);

        # to output User Msg
        my $percent = $count / $total;
        my $outfile = basename($newFileName);
        print STDERR "INFO processing end\n" if $verbose;
        print STDERR "OUTPUT $outfile\n";
        $percent = 100 * $percent;
        print STDERR "PERCENT_DONE $percent\n";

        # increment file counter
        $count++;
        $workingfile = "";
    }

# This outputfile is used by Giovanni::DataStager. It grabs the year from granuleDate attribute:
    if ( defined $fileListNode && defined $listingDoc ) {
        $listingDoc->appendChild($fileListNode);
    }
    else {
        quit( 1, "ERROR 'fileListNode' is not defined" );
    }

}

$listingDoc = createSortedListingFile($listingDoc);

# To create the listing file for scrubbed files
# This is used by Giovanni::DataStager. It grabs the year from granuleDate attribute:
eval {
    open( FH, ">$scrubbedListingFile" );
    print FH $listingDoc->toString(2);
    close(FH);
};
if ($?) {
    quit( 1, "ERROR failed to create the scrubbed listing file: $? -- $@" );
}
if ( -e $scrubbedListingFile ) {
    print STDERR "OUTPUT $scrubbedListingFile\n";
}
else {
    quit( 1,
        "ERROR Scrubbed listing file does not exist: $scrubbedListingFile" );
}

exit(0);

sub usage {
    print "Unknown option: @_\n" if (@_);
    print
        "USAGE: perl ncScrubber.pl [--input listing_file] [--outDir workingDirectory] [--catalog varInfo_file] [-v 0 or 1] [--help]\n";
    print
        "(1.) [--input listing_file] -- listing_file is an XML file containing a list of data file names\n";
    print
        "(2.) [--outDir workingDirectory] -- is an absolute path where temporary files and output files are placed\n";
    print
        "(3.) [--catalog varInfo_file] -- is an XML file containing variable-related info\n";
    print "(4.) [-v [0|1]] is for printing informational msg if 1.\n";
    print
        "(5.) [--help] is for printing this help info.  If existing, will ignore all other arguments\n";
    exit(1);
}

