#$Id: WorldLongitude.pm,v 1.30 2015/02/19 19:31:33 csmit Exp $
#-@@@ GIOVANNI,Version $Name:  $
package Giovanni::WorldLongitude;

use 5.008008;
use strict;
use warnings;

use POSIX qw/ceil floor/;
use Giovanni::Data::NcFile;
use File::Temp qw/tempdir tempfile/;
use File::Path;
use Giovanni::ScienceCommand;
use File::Copy;
use File::Basename;
use Giovanni::BoundingBox;
use Giovanni::Logger;
use Math::BigFloat;
use Math::BigInt;

our $VERSION = '0.01';

sub normalizeIfNeeded {
    my (%params) = @_;

    # check to make sure the parameters make sense
    %params = _checkParams(%params);

    my $firstFile = $params{"in"}->[0];

    # see if there is a longitude variable
    my $longitudeVariablName = $params{"longitudeVariable"};
    my $xmlHeader = Giovanni::Data::NcFile::get_xml_header($firstFile);
    my @nodes     = $xmlHeader->findnodes(
        qq(/nc:netcdf/nc:variable[\@name="$longitudeVariablName"]));

    if ( !@nodes ) {

        # no longitude variable, so there's nothing to do!
        return 0;
    }

    # get out the current longitude dimension values
    my @longitudes = Giovanni::Data::NcFile::get_variable_values(
        $firstFile,
        $params{"longitudeVariable"},
        $params{"longitudeVariable"}
    );

    if ( fileNeedsNewLongitudeGrid(@longitudes) ) {
        normalize(%params);
        return 1;
    }
    else {

        # nothing to be done
        return 0;
    }
}

sub normalize {
    my (%params) = @_;

    # check to make sure the parameters make sense
    %params = _checkParams(%params);

    # First dispense with the acrossDateline case...
    if ( exists $params{acrossDateline} && $params{acrossDateline} ) {
        return makeLongitudesMonotonic( $params{in}, $params{out},
            $params{longitudeVariable},
            $params{logger} );
    }

    my $obj = Giovanni::WorldLongitude->new(%params);
    $obj->_normalize();

}

sub _normalize {
    my ($self) = @_;
    $self->{tempDir} = tempdir(
        "WorldLongitude_XXXX",
        DIR     => $self->{"sessionDir"},
        CLEANUP => $self->{"cleanUp"}
    );
    chmod 0775, $self->{tempDir};

    # get the variables with a longitude dimension (excluding the longitude
    # variable)
    $self->_getVariables();

    # get out the current longitude dimension values
    my @longitudes = Giovanni::Data::NcFile::get_variable_values(
        $self->{in}->[0],
        $self->{"longitudeVariable"},
        $self->{"longitudeVariable"}
    );

    # get normalized (between -180 and 180) longitudes
    my @normalizedLongitudes = my @newLongitudes
        = map( Giovanni::BoundingBox::getCanonicalLongitude($_),
        @longitudes );

    # store them away for future use
    $self->{original}->{longitudes}           = \@longitudes;
    $self->{original}->{normalizedLongitudes} = \@normalizedLongitudes;

    # and get out the current longitude dimension's type
    my $xpc = Giovanni::Data::NcFile::get_xml_header( $self->{in}->[0] );
    my $xpath
        = qq(/nc:netcdf/nc:variable[\@name=")
        . $self->{"longitudeVariable"}
        . qq("]/\@type);
    $self->{lonType} = $xpc->findvalue($xpath);

    if ( scalar(@normalizedLongitudes) < 2 ) {
        $self->{"logger"}->warning(
            "Not enough longitude values to calculate resolution. Leaving grid alone."
        );
        return;
    }

    # figure out what exactly we are going to do with longitude
    $self->_getNewLongitudeParams();
    $self->{"logger"}
        ->debug( "Longitude resolution: " . $self->{resolution} );
    $self->{"logger"}
        ->debug( "New start longitude: " . $self->{newStartLon} );
    $self->{"logger"}->debug( "Number of longitudes: " . $self->{numLon} );

    # map longitudes on the old longitude grid to longitudes on the new
    # longitude grid
    $self->_getIndexMapping();

    my $preproccessPercent = $self->{"startPercent"}
        + 0.1 * ( $self->{"endPercent"} - $self->{"startPercent"} );
    my $copyPercent = $self->{"startPercent"}
        + 0.9 * ( $self->{"endPercent"} - $self->{"startPercent"} );

    # go through all the files and rename their current longitude
    # dimension to <longitude>_old. Also rename the variables.
    # This is so we can put in the new variables and dimension.
    $self->_preprocessFiles();
    $self->{"logger"}->percent_done($preproccessPercent);

    # copy the variable data into a new variables with the new longitude
    # dimension.
    $self->_copyDataOver();
    $self->{"logger"}->percent_done($copyPercent);

    # delete the old variables and longitude variable
    $self->_deleteOldVars();

    $self->{"logger"}->percent_done( $self->{"endPercent"} );
}

sub _checkParams {
    my (%params) = @_;

    if ( !( exists $params{"logger"} ) ) {
        $params{"logger"} = Giovanni::Logger->new( no_stderr => 1 );
    }
    if ( !( exists $params{"in"} ) ) {
        die "Normalizer requires input files";
    }
    if ( ref( $params{"in"} ) ne "ARRAY" ) {
        die("The in parameter must be an array reference");
    }
    if ( !( exists $params{"out"} ) ) {
        die "Normalizer requires output files";
    }
    if ( ref( $params{"out"} ) ne "ARRAY" ) {
        die("The out parameter must be an array reference");
    }
    if ( scalar( @{ $params{"in"} } ) != scalar( @{ $params{"out"} } ) ) {
        die("Expected an equal number of input and output files.");
    }
    if ( ( !exists( $params{"sessionDir"} ) ) ) {
        die "Normalizer requires the session directory";
    }
    if ( !( exists( $params{"startPercent"} ) ) ) {
        $params{"startPercent"} = 0;
    }
    if ( !( exists( $params{"endPercent"} ) ) ) {
        $params{"endPercent"} = 100;
    }
    if ( !( exists( $params{"longitudeVariable"} ) ) ) {
        $params{"longitudeVariable"} = "lon";
    }
    if ( !( exists( $params{"cleanUp"} ) ) ) {
        $params{"cleanUp"} = 1;
    }

    return %params;

}

# NOTE: Please don't call this. You don't need to call this.
# Call the static functions like normalize()! The object is
# just to pass all the partial calculations around.
sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;
    return $self;
}

sub fileNeedsNewLongitudeGrid {
    my (@longitudes) = @_;

    # check for longitudes outside of the allowable range
    for my $lon (@longitudes) {
        if ( $lon < -180 || $lon > 180 ) {
            return 1;
        }
    }

    # no need if there is only 1 longitude...
    if ( scalar(@longitudes) < 2 ) {
        return 0;
    }
    my $resolution = $longitudes[1] - $longitudes[0];

    # Divide longitudes by resolution so that we should get an increase of
    # 1 between adjacent longitudes
    # NOTE: the sprintf rounds the number to the nearest integer
    my @inds = map( sprintf( "%.0f", ( $_ - $longitudes[0] ) / $resolution ),
        @longitudes );

    for ( my $i = 1; $i < scalar(@inds); $i++ ) {
        if ( $inds[$i] - $inds[ $i - 1 ] != 1 ) {

            # Something isn't continuous
            return 1;
        }
    }

    return 0;

}

sub makeLongitudesMonotonic {
    my ( $ra_in, $ra_out, $lonVar, $logger ) = @_;
    my $i;

    # Use ncap2 to add 360 to negative longitudes
    my $ncap2_script = "where ($lonVar < 0.) $lonVar = $lonVar + 360.";
    $logger->user_msg("Making longitudes monotonic across dateline");

    # Loop through input files for ncap2 executions
    my $n = scalar(@$ra_in);
    for ( $i = 0; $i < $n; $i++ ) {
        my $cmd = sprintf( "ncap2 -O -s '%s' %s %s",
            $ncap2_script, $ra_in->[$i], $ra_out->[$i] );
        $logger->info("Executing $cmd");
        my $rc = system($cmd);
        die "Command $cmd returned non-zero ($rc)\n" if $rc;
    }
    return 1;
}

# delete the original data variables and longitude variable
sub _deleteOldVars {
    my ($self) = @_;

    my $longitudeVariable = $self->{longitudeVariable};
    my $baseCmd           = "ncks -h -x -v $longitudeVariable" . "_old";
    for my $var ( @{ $self->{variables} } ) {
        $baseCmd = $baseCmd . ",$var" . "_old";
    }
    for ( my $i = 0; $i < scalar( @{ $self->{copiedFiles} } ); $i++ ) {
        my $inFile  = $self->{copiedFiles}->[$i];
        my $outFile = $self->{out}->[$i];
        my $cmd     = $baseCmd . " $inFile $outFile";
        $self->{logger}->user_msg( "Cleaning up file "
                . ( $i + 1 ) . " of "
                . scalar( @{ $self->{copiedFiles} } )
                . "." );
        $self->{logger}->info("About to run command: $cmd");

        my $ret = system($cmd);
        if ( $ret != 0 ) {
            die "Command returned non-zero: $cmd";
        }

    }
}

# copy data from the old data variable into the new variable with the new grid
sub _copyDataOver {
    my ($self) = @_;

    # figure our output file names
    my @outFiles = ();
    for my $file ( @{ $self->{preprocessedFiles} } ) {
        my $basename = basename($file);
        $basename =~ s/_PREPROCESS/_COPY/;
        push( @outFiles, $self->{tempDir} . "/$basename" );
    }

    # figure out what ncap2 commands are going to be in the script
    my @ncap2commands = ();

    # Set all the old longitudes to the normalized values
    my $longitudeVariable = $self->{longitudeVariable};
    for (
        my $i = 0;
        $i < scalar( @{ $self->{original}->{normalizedLongitudes} } );
        $i++
        )
    {
        if ( $self->{original}->{normalizedLongitudes}->[$i]
            != $self->{original}->{longitudes}->[$i] )
        {
            push( @ncap2commands,
                      $longitudeVariable
                    . "_old($i)="
                    . $self->{original}->{normalizedLongitudes}->[$i] );
        }
    }

    # Create the new longitude variable dimension, now that we've given the
    # old one a different name.
    my $numLon = $self->{numLon};
    push( @ncap2commands, qq/defdim("$longitudeVariable",$numLon)/ );
    my $initValue = _createInitValue( $self->{lonType} );
    push( @ncap2commands,
        qq/$longitudeVariable\[$longitudeVariable\]=$initValue/ );

    # next, copy over the longitude variable attributes
    my ( $dontCare, $attListRef )
        = Giovanni::Data::NcFile::variable_attributes(
        $self->{preprocessedFiles}->[0],
        $longitudeVariable . "_old" );
    for my $att ( @{$attListRef} ) {
        push( @ncap2commands,
                  "$longitudeVariable\@$att="
                . "$longitudeVariable"
                . "_old\@$att" );
    }

    # and now set the longitude values
    # NOTE: by dividing this into two commands, I can make sure that
    # the array type is correct. If I set, for example,
    #
    # lon=array(-180,2.5,$lon);
    #
    # The RHS will evaluate to an integer value because of the '-180'. It will
    # then be cast to a float for lon. This is not what we want!
    push( @ncap2commands,
        qq/$longitudeVariable=array(0,1,\$$longitudeVariable)/ );
    my $resolution  = $self->{resolution};
    my $newStartLon = $self->{newStartLon};
    push( @ncap2commands,
        qq/$longitudeVariable=$longitudeVariable*$resolution+($newStartLon)/
    );

    # and now we need to create variables with this dimension
    my $numVar = scalar( @{ $self->{variables} } );
    for ( my $i = 0; $i < $numVar; $i++ ) {
        my $var  = $self->{variables}->[$i];
        my @dims = split( '\s+', $self->{variableShapes}->[$i] );
        my $type = $self->{variableTypes}->[$i];

        # this will get the type correct for the data
        my $initValue = _createInitValue($type);
        my $dimsStr = join( ",", @dims );
        push( @ncap2commands, qq/$var\[$dimsStr\]=$initValue/ );

        # and set the fill value
        push( @ncap2commands, "$var.set_miss($var" . "_old.get_miss())" );

        # now set everything in the new variable to the fill value
        # What I need is one ':' per dimension
        my $parenStr = ":";
        for ( my $i = 1; $i < scalar(@dims); $i++ ) {
            $parenStr = "$parenStr,:";
        }

        push( @ncap2commands, "$var($parenStr)=$var" . "_old.get_miss()" );

    }

    # now the hard part - copying data from the old variables into the new
    # variables. We have 1 or more blocks of data to copy over for each of
    # one or more variables.
    for ( my $i = 0; $i < scalar( @{ $self->{variables} } ); $i++ ) {
        my $shape = $self->{variableShapes}->[$i];
        my $var   = $self->{variables}->[$i];

        # copy over all the attributes
        my ( $dontCare, $attListRef )
            = Giovanni::Data::NcFile::variable_attributes(
            $self->{preprocessedFiles}->[0],
            $var . "_old" );
        for my $att ( @{$attListRef} ) {
            if ( $att ne "_FillValue" ) {
                push( @ncap2commands, "$var\@$att=$var" . "_old\@$att" );
            }
        }

        # finally, do the hyperslab commands
        my @hyperCommands = _createHyperSlabCommands(
            variable        => $var,
            shape           => $shape,
            dimensionName   => $longitudeVariable,
            lonIndexMapping => $self->{lonIndexMapping}
        );

        push( @ncap2commands, @hyperCommands );
    }

    my $ncap2script = join( ";\n", @ncap2commands ) . ";\n";

    # log the script
    $self->{logger}->debug("ncap2 script for copying data:\n$ncap2script");

    # create a temporary directory to run ncap2 in because it
    # creates a lot of temporary files
    my $scriptFile = $self->{tempDir} . "/script.ncap2";
    open( FILE, ">", $scriptFile )
        or die "Unable to write ncap2 script to $scriptFile";
    print FILE $ncap2script;
    close(FILE);

    for ( my $i = 0; $i < scalar( @{ $self->{preprocessedFiles} } ); $i++ ) {
        $self->{logger}->user_msg( "Normalizing grid for file "
                . ( $i + 1 ) . " of "
                . scalar( @{ $self->{preprocessedFiles} } )
                . "." );
        my $cmd
            = "ncap2 -h -O -S $scriptFile "
            . $self->{preprocessedFiles}->[$i] . " "
            . $outFiles[$i];

        my $caller = Giovanni::ScienceCommand->new(
            sessionDir   => $self->{sessionDir},
            logger       => $self->{logger},
            dieOnFailure => 0,
        );
        my ( $dont_care, $dont_care2, $ret ) = $caller->exec($cmd);

        if ( $ret != 0 ) {
            die("Unable to run ncap2 command");
        }
    }

    $self->{copiedFiles} = \@outFiles;
}

# build the ncap2 commands for copying data from one variable to
# another.
sub _createHyperSlabCommands {
    my (%params)        = @_;
    my $variable        = $params{variable};
    my $shape           = $params{shape};
    my $dimensionName   = $params{dimensionName};
    my $lonIndexMapping = $params{lonIndexMapping};

   # figure out dimension we are hyper-slabbing (not a word, I know...)
   # Basically, we need to build the string:
   # var(:,:,0:10:1,:)
   # where 0:<whatever>:1 string is in the position of the longitude dimension
    my @dims             = split( '\s+', $shape );
    my $foundDim         = 0;
    my $startHyperString = '';
    my $endHyperString   = '';
    for my $dim (@dims) {
        if ( !$foundDim ) {
            if ( $dim eq $dimensionName ) {
                $foundDim = 1;
            }
            else {
                $startHyperString = $startHyperString . ":,";
            }
        }
        else {
            $endHyperString = $endHyperString . ",:";
        }
    }

    my @commands = ();

    for ( my $i = 0; $i < scalar( @{ $lonIndexMapping->{startNew} } ); $i++ )
    {
        my $oldStart = $lonIndexMapping->{startOld}->[$i];
        my $oldEnd   = $lonIndexMapping->{endOld}->[$i];
        my $newStart = $lonIndexMapping->{startNew}->[$i];
        my $newEnd   = $lonIndexMapping->{endNew}->[$i];

        # should look something like:
        # lovelyVariable(:,10:14:1,:)=lovelyVariable_old(:,0:5:1,:);
        push( @commands,
                  "$variable($startHyperString"
                . "$newStart:$newEnd:1"
                . "$endHyperString)=$variable"
                . "_old($startHyperString"
                . "$oldStart:$oldEnd:1"
                . "$endHyperString)" );
    }

    return @commands;

}

# create an initial value string that can be used in the ncap2 script to create
# a variable of the correct value.
sub _createInitValue {
    my ($type) = @_;
    if ( $type eq "double" ) {
        return "0.0";
    }
    elsif ( $type eq "float" ) {
        return "0.0f";
    }
    elsif ( $type eq "int" ) {
        return "0";
    }
    elsif ( $type eq "short" ) {
        return "0s";
    }
    else {
        die "Unsupported type '$type'.";
    }
}

# get out all the variables with the longitude dimension
sub _getVariables {
    my ($self) = @_;

    # Get some information out of the first file. We're going to assume that
    # the rest of the files are the same.
    my $file = $self->{"in"}->[0];

    my $cmd    = "ncdump -x $file";
    my @out    = `$cmd`;
    my $xmlStr = join( "", @out );

   # TODO: get rid of this untainting stuff. I can't for the life of me figure
   # out why I need to untaint this output string. Untainting the command
   # before it is run doesn't work. Untainting the $file doesn't work. So ya
   # got me! Without this line, anything that uses the variables in another
   # external command causes a taint error.
    $xmlStr =~ s/\n//g;
    $xmlStr =~ m/(.*)/;
    $xmlStr = $1;

    # parse the XML.
    my $xpc = XML::LibXML::XPathContext->new(
        XML::LibXML->new()->parse_string($xmlStr) );
    $xpc->registerNs(
        nc => 'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );

    # get all variables
    my @variables = map( $_->getValue(),
        $xpc->findnodes("/nc:netcdf/nc:variable/\@name") );
    my @shapes = ();
    my @types  = ();
    for my $variable (@variables) {
        my @nodes = $xpc->findnodes(
            qq(/nc:netcdf/nc:variable[\@name="$variable"]/\@shape));
        if ( scalar(@nodes) > 0 ) {
            push( @shapes, $nodes[0]->getValue() );
        }
        else {
            push( @shapes, "" );
        }

        @nodes = $xpc->findnodes(
            qq(/nc:netcdf/nc:variable[\@name="$variable"]/\@type));

        if ( scalar(@nodes) > 0 ) {
            push( @types, $nodes[0]->getValue() );
        }
        else {
            push( @shapes, "" );
        }
    }

    my @outVariables      = ();
    my @outShapes         = ();
    my @outTypes          = ();
    my $longitudeVariable = $self->{"longitudeVariable"};
    for ( my $i = 0; $i < scalar(@variables); $i++ ) {
        if (   $shapes[$i] =~ /$longitudeVariable/
            && $variables[$i] ne $longitudeVariable )
        {
            push( @outVariables, $variables[$i] );
            push( @outShapes,    $shapes[$i] );
            push( @outTypes,     $types[$i] );
        }
    }

    $self->{variables}      = \@outVariables;
    $self->{variableShapes} = \@outShapes;
    $self->{variableTypes}  = \@outTypes;
}

# move the longitude dimension variable and current data variables to
# "_old" variable names
sub _preprocessFiles {
    my ($self) = @_;

    my $currLonVar = $self->{longitudeVariable};
    my @inFiles    = @{ $self->{in} };
    my @variables  = @{ $self->{variables} };

    my $numFiles = scalar(@inFiles);

    my @outFiles = ();
    for my $file (@inFiles) {
        my $basename = basename($file);
        $basename =~ s/[.]nc$/_PREPROCESS.nc/;
        push( @outFiles, $self->{tempDir} . "/$basename" );
    }

    # First, make sure all the files are netcdf 3 classic
    my $type = Giovanni::Data::NcFile::get_ncdf_version( $inFiles[0] );
    if ( !defined($type) ) {
        die "Unable to determine netcdf type for file " . $inFiles[0];
    }
    if ( $type == 4 ) {
        $self->{logger}->info("Converting files from netcdf 4 to netcdf 3");
        for ( my $i = 0; $i < $numFiles; $i++ ) {
            Giovanni::Data::NcFile::to_netCDF3( $inFiles[$i], $outFiles[$i] );
        }
    }
    else {

        # just copy the files over
        for ( my $i = 0; $i < $numFiles; $i++ ) {
            copy( $inFiles[$i], $outFiles[$i] );
        }
    }

    # the base command renames the dimension, the dimension variable,
    # and the other non-dimension variables
    my $cmd_base
        = "ncrename -h -d "
        . $currLonVar . ","
        . $currLonVar . "_old " . "-v "
        . $currLonVar . ","
        . $currLonVar . "_old ";
    for my $var (@variables) {
        $cmd_base = "$cmd_base -v " . $var . "," . $var . "_old";
    }

    # now go through each file
    my $tempFile = $self->{tempDir} . "/temp_PREPROCESS.nc";
    for ( my $i = 0; $i < $numFiles; $i++ ) {
        my $cmd = $cmd_base . " " . $outFiles[$i] . " " . $tempFile;
        $self->{logger}->info("About to call command: $cmd");
        $self->{logger}->user_msg( "Preprocessing file "
                . ( $i + 1 ) . " of "
                . $numFiles
                . " before normalizing longitude grid points." );
        my $ret = system($cmd);
        if ( $ret != 0 ) {
            die "Command returned non-zero: $cmd";
        }
        move( $tempFile, $outFiles[$i] );
    }

    $self->{preprocessedFiles} = \@outFiles;

}

sub _getResolutionSafe {
    my (%params) = @_;
    my @longitudes = @{ $params{longitudes} };

    if ( scalar(@longitudes) == 1 ) {
        return undef;
    }
    elsif ( scalar(@longitudes) == 2 ) {

        # best we can do
        return _getLongitudeDifference(
            firstLon  => $longitudes[0],
            secondLon => $longitudes[1]
        );
    }
    else {

        # Basically, assume that if we get three equally spaced points next to
        # eachother, the resolution is the distance between two of the
        # adjacent points. This will (mostly) avoid accidentally calculating
        # the resolution from a gap in the longitude values.
        my $resolution = _getLongitudeDifference(
            firstLon  => $longitudes[0],
            secondLon => $longitudes[1]
        );
        for ( my $i = 2; $i < scalar(@longitudes); $i++ ) {
            my $res = _getLongitudeDifference(
                firstLon  => $longitudes[ $i - 1 ],
                secondLon => $longitudes[$i]
            );
            my $ratio = $res->copy()->bdiv($resolution);

            if ( $ratio > 3.0 / 4.0 && $ratio < 4.0 / 3.0 ) {
                return $resolution;
            }
        }
        return undef;
    }
}

# returns the least number of degrees from the first longitude to the second
sub _getLongitudeDifference {
    my (%params) = @_;

    my $firstBF  = Math::BigFloat->new( $params{firstLon} );
    my $secondBF = Math::BigFloat->new( $params{secondLon} );

    my $diff;
    if ( $firstBF > $secondBF ) {

        # this went over the 180. We want 360-$firstLon+$secondLon
        my $world = Math::BigFloat->new(360);
        $diff = $world->copy()->bsub($firstBF)->badd($secondBF)

    }
    else {
        $diff = $secondBF->copy()->bsub($firstBF);
    }

    return $diff;

}

# figure out what we want the new longitudes to be.
sub _getNewLongitudeParams {
    my ($self) = @_;

    my $resolution
        = _getResolutionSafe( longitudes => $self->{original}->{longitudes} );
    if ( !defined($resolution) ) {
        die "Unable to determine resolution";
    }

    # Figure out how many longitudes there are. This is round(360/r).
    my $numLon = Math::BigFloat->new(360)->bdiv($resolution)->ffround(0);

    # then convert to a Math::BigInt
    $numLon = Math::BigInt->new($numLon);

    # Recalculate the resolution, which may not be accurate due to limitations
    # in how the longitudes are represented.
    $resolution = Math::BigFloat->new(360)->bdiv($numLon);

    # we want the largest n such that
    #
    #   x - r*n >= -180
    #
    # where
    #
    #   x = the minimum longitude (must be >= -180)
    #   r = the resolution
    #   n = an integer number of grid cells
    #
    # So,
    #
    #   n = floor((180 + x)/r)

    my $firstLonBF
        = Math::BigFloat->new( $self->{original}->{longitudes}->[0] );

    my $n = Math::BigFloat->new(180)->badd($firstLonBF)->bdiv($resolution);
    $n->bfloor();

    # and now the first longitude is x-r*n
    my $newStartLon
        = $firstLonBF->copy()->bsub( $resolution->copy()->bmul($n) );

    $self->{resolution}  = $resolution;
    $self->{newStartLon} = $newStartLon;
    $self->{numLon}      = $numLon;
}

# figure out how to get from the old longitudes to new longitudes
sub _getIndexMapping {
    my ($self) = @_;
    my @oldLons = @{ $self->{original}->{normalizedLongitudes} };

    # calculate the indexes in the new lon map for the old longitude values.
    my @newInds = ();
    for my $lon (@oldLons) {
        my $index = Math::BigFloat->new($lon)->bsub( $self->{newStartLon} )
            ->bdiv( $self->{resolution} )->ffround(0);
        $index = Math::BigInt->new($index);
        if ( $index < 0 ) {

            # it wrapped around...
            $index = $index->badd( $self->{numLon} );
        }
        push( @newInds, $index->bstr() );
    }

    #
    # Now go through the indexes and figure out contiguous groups we can copy
    # in one go from the old data array into the new data array
    #

    # stores the start indices of groups in the @oldLons array
    my @startOldLonInds = (0);
    my @endOldLonInds   = ();

    # stores the start indices of groups in the new longitude array
    my @startNewLonInds = ( $newInds[0] );
    my @endNewLonInds   = ();

    for ( my $i = 1; $i < scalar(@newInds); $i++ ) {
        if ( $newInds[$i] - $newInds[ $i - 1 ] != 1 ) {

            # we have a discontinuity
            push( @startOldLonInds, $i );
            push( @endOldLonInds,   $i - 1 );
            push( @startNewLonInds, $newInds[$i] );
            push( @endNewLonInds,   $newInds[ $i - 1 ] );
        }
    }

    push( @endOldLonInds, scalar(@newInds) - 1 );
    push( @endNewLonInds, $newInds[-1] );

    $self->{lonIndexMapping}             = {};
    $self->{lonIndexMapping}->{startOld} = \@startOldLonInds;
    $self->{lonIndexMapping}->{endOld}   = \@endOldLonInds;
    $self->{lonIndexMapping}->{startNew} = \@startNewLonInds;
    $self->{lonIndexMapping}->{endNew}   = \@endNewLonInds;
}

1;
__END__

=head1 NAME

Giovanni::WorldLongitude - Perl extension for putting data on a -180 to 180
degree longitude grid.

=head1 SYNOPSIS

  use Giovanni::WorldLongitude;
  ...
  my $normalized = Giovanni::WorldLongitude::normalizeIfNeeded(
    logger       => $logger,
    sessionDir   => "/path/to/session/directory",
    in           => [$dataFile],
    out          => [$outFile],
    startPercent => 50,
    endPercent   => 100
  );

   my $normalized = Giovanni::WorldLongitude::normalize(
        logger       => $logger,
        in           => \@inFiles,
        out          => \@outFiles,
        startPercent => 0,
        endPercent   => 99,
        sessionDir   => $outdir,
        cleanUp      => $cleanUp,
        acrossDateline => $acrossDateline,
    );

=head1 DESCRIPTION

Code for putting data on a regular longitude grid from -180 to 180 and for
determining if you need to change the grid. 

=head2 my $normalized = normalizeIfNeeded(logger=>$logger, sessionDir => "/path/to/dir", in=>[$file1], out=>[$file2])

Puts all the data on a regular longitude grid if the input files have a 
longitude variable and it goes over the 180 meridian.

INPUTS

logger (optional): Giovanni::Logger object

sessionDir: session directory. A directory where it is safe to create temporary directories.

in: reference to array of input files. They should all have the same variables
and dimensions.

out: reference to array of output files. Needs to be different from input files.

startPercent (optional): start percent for logging. Defaults to zero.

endPercent (optional): end percent for logging. Defaults to zero.

OUTPUT

Returns true if files were normalized and false otherwise.

=head2 normalize(logger=>$logger, sessionDir => "/path/to/dir", in=>[$file1], out=>[$file2], acrossDateline => [T|F])

Puts all the data on a regular longitude grid.
However, regular may have two definitions: 
if the acrossDateline parameter is set to false, they are laid out on a global grid.
If the acrossDateline parameter is set to a true value, as should be the case when doing Hovmollers across
the dateline, then 360. is added to the negative longitudes via an ncap2 script.

INPUTS

logger (optional): Giovanni::Logger object

sessionDir: session directory. A directory where it is safe to create temporary directories.

in: reference to array of input files. They should all have the same variables
and dimensions.

out: reference to array of output files. Needs to be different from input files.

startPercent (optional): start percent for logging. Defaults to zero.

endPercent (optional): end percent for logging. Defaults to zero.

acrossDateline (optional): whether to simply "extend" across the dateline by making
the longitudes monotonic or extend to a global grid (the default).

=head2 fileNeedsNewLongitudeGrid(@longitudes)

Returns FALSE if longitudes are monotonically increasing and there are no gaps.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut
