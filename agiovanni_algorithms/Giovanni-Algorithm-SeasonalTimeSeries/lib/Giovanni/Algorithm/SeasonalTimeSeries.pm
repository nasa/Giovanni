#$Id: SeasonalTimeSeries.pm,v 1.9 2015/04/24 14:08:16 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::Algorithm::SeasonalTimeSeries;

use 5.010001;
use strict;
use warnings;
use File::Temp qw/tempdir tempfile/;
use File::Spec;
use File::Basename;
use File::Path qw/remove_tree/;
use Switch;
use Giovanni::Logger::Algorithm;
use Giovanni::Data::NcFile;
use Giovanni::BoundingBox;
# preventing the indentical run_command() routines from 
# being doubly defined. Except for subset_bbox_cmd all 
# others are always referenced with full lib paths
use Giovanni::Algorithm::AreaAvgDiff qw/subset_bbox_cmd/; 
use Giovanni::Algorithm::DimensionAverager qw//;

our $VERSION = '0.01';

# Preloaded methods go here.

sub new {
    my ( $pkg, %params ) = @_;

    my %obj = ();
    my $self = bless \%obj, $pkg;

    if ( defined( $params{logger} ) ) {
        $self->{logger} = $params{logger};
    }
    else {
        $self->{logger} = Giovanni::Logger::Algorithm->new();
    }

    if ( defined( $params{sessionDir} ) ) {
        $self->{baseDir} = $params{sessionDir};
    }
    else {
        $self->{baseDir} = File::Spec->tmpdir();
    }

    return $self;
}

sub calculate {
    my ( $self, %params ) = @_;

    if ( !defined( $params{inFiles} ) ) {
        $self->{logger}->error("inFiles is a required parameter");
        return 0;
    }

    if ( scalar( @{ $params{inFiles} } ) == 0 ) {
        $self->{logger}->user_error( "No input files found for "
                . $params{variable} . ", "
                . $params{groupType} . "="
                . $params{groupValue}
                . ". Consider expanding the year range for your request or trying a different variable."
        );
        return 0;
    }

    my $bbox = "-180,-90,180,90";
    if ( defined( $params{bbox} ) ) {
        $bbox = $params{bbox};
    }

    if ( !defined( $params{outFile} ) ) {
        $self->{logger}->error("outFile is a required parameter");
        return 0;
    }
    my $outFile = $params{outFile};

    if ( !defined( $params{groupType} ) ) {
        $self->{logger}->error("groupType is a required parameter");
    }
    my $groupType = $params{groupType};

    # create a temporary directory for intermediate files
    my $dir = tempdir( "seasonalTSIntermediateFiles_XXXXX",
        DIR => $self->{baseDir} );

    # figure out what the data variable is that we will be averaging over
    my @inFiles = $self->_dropPartialSeasons(
        files      => $params{inFiles},
        dir        => $dir,
        variable   => $params{variable},
        groupType  => $params{groupType},
        groupValue => $params{groupValue},
    );

    # check to make sure we didn't lose all our files
    if ( scalar(@inFiles) == 0 ) {
        $self->{logger}->user_error( "Insufficient data found for "
                . $params{variable} . ", "
                . $params{groupType} . "="
                . $params{groupValue}
                . ". Consider expanding the year range for your request or trying a different variable."
        );
        return 0;
    }

    # subset and concatenate files that will be averaged together
    my @subsettedAndConcatenatedFiles = ();
    my @groups                        = ();
    my @dataYears                     = ();
    if ( $groupType eq 'SEASON' ) {

        # seasons
        if ( ( scalar(@inFiles) % 3 ) != 0 ) {
            $self->{logger}->error(
                "Expected number of files to be divisible by 3 for seasonal time series"
            );
            return 0;
        }

        # group files in sets of 3 for each season
        @groups = $self->_groupFiles(@inFiles);
        for my $group (@groups) {
            my $subConFile = $self->_concatenateAndSubset(
                files   => $group->{files},
                tempDir => $dir,
                bbox    => $bbox,
                zVar    => $params{zVar},
                zValue  => $params{zValue},
            );
            if ( !defined($subConFile) ) {
                return 0;
            }
            push( @subsettedAndConcatenatedFiles, $subConFile );

            # get the data year for the middle file
            my $dataYear
                = $self->_getDataYear( file => $group->{files}->[1] );
            if ( !defined($dataYear) ) {
                return 0;
            }
            push( @dataYears, $dataYear );
        }

    }
    else {

        # months
        for my $file (@inFiles) {

            # this will obviously just subset
            my $subConFile = $self->_concatenateAndSubset(
                files   => [$file],
                tempDir => $dir,
                bbox    => $bbox,
                zVar    => $params{zVar},
                zValue  => $params{zValue},
            );
            if ( !defined($subConFile) ) {
                return 0;
            }
            push( @subsettedAndConcatenatedFiles, $subConFile );

            # get the data year
            my $dataYear = $self->_getDataYear( file => $file );
            if ( !defined($dataYear) ) {
                return 0;
            }
            push( @dataYears, $dataYear );
        }

    }
# grab the data bounding box for future reporting
# before it is averaged out.
 # (as opposed to the User's bbox)
    my $actual_grid = Giovanni::Algorithm::AreaAvgDiff::grab_datagrid_info($subsettedAndConcatenatedFiles[0]);
 
    # now area average
    my @areaAveragedFiles = ();
    for my $file (@subsettedAndConcatenatedFiles) {
        my $name = basename($file);
        $name =~ s/_concatSubset[.]nc/_areaAvg.nc/;
        my $averagedFile = "$dir/$name";

        if ( $params{shape} ) {

            # The shape_mask variable will have the weights for the average
            # if the user specified a weight.
            Giovanni::Algorithm::DimensionAverager::compute_spatial_average_with_weights(
                $file, $averagedFile, $params{variable}, "shape_mask" );
        }
        else {

            Giovanni::Algorithm::DimensionAverager::compute_spatial_average(
                $file, $averagedFile, $params{variable} );
        }
        push( @areaAveragedFiles, $averagedFile );
    }

    my @timeAveragedFiles = ();
    if ( $groupType eq 'SEASON' ) {

        # average over each season
        for my $file (@areaAveragedFiles) {
            my $name = basename($file);
            $name =~ s/_areaAvg[.]nc/_timeAvg.nc/;
            my $averagedFile = "$dir/$name";

            Giovanni::Algorithm::DimensionAverager::compute_temporal_average(
                $file, $averagedFile );
            push( @timeAveragedFiles, $averagedFile );
        }

        # now add back in the time
        for ( my $i = 0; $i < scalar(@timeAveragedFiles); $i++ ) {
            $self->_addTimeDimension(
                file      => $timeAveragedFiles[$i],
                timeStamp => $groups[$i]->{time},
                dir       => $dir,
            );
        }
    }
    else {

        # No need to average. There's only one file.
        @timeAveragedFiles = @areaAveragedFiles;
    }

    # concatenate the files together
    my $cmd = "ncrcat -O -h ";
    for my $file (@timeAveragedFiles) {
        $cmd = "$cmd$file ";
    }
    $cmd = "$cmd$outFile";

    if ( !$self->_runCommand($cmd) ) {
        $self->{logger}->error("Unable to concatenate files together");
        return 0;
    }

    # make sure the coordinates value for the main variable is correct
    $cmd
        = "ncatted -O -h -a 'coordinates,"
        . $params{variable}
        . ",o,c,time' "
        . "$outFile $outFile";
    if ( !$self->_runCommand($cmd) ) {
        $self->{logger}->error("Unable to set coordinates");
        return 0;
    }

    # put in the data years
    if (!$self->_addDataYearValues(
            file      => $outFile,
            dataYears => \@dataYears,
            dir       => $dir,
        )
        )
    {
        return 0;
    }

    # put in the group information in the metadata
    if (!$self->_addGroupInfo(
            file       => $outFile,
            groupType  => $params{groupType},
            groupValue => $params{groupValue},
            variable   => $params{variable}
        )
        )
    {
        return 0;
    }

    # get rid of any 'NaN' values in the output file
    if (!defined(
            $self->_convertNaNToFill(
                file     => $outFile,
                variable => $params{variable}
            )
        )
        )
    {
        $self->{logger}->error("Unable to convert NaN values to fill values");
        return 0;
    }
    
    # set the actual grid in the output file
    Giovanni::Algorithm::AreaAvgDiff::set_datagrid_info($actual_grid,$outFile);

    # delete the history
    $cmd = "ncatted -h -O -a 'history,global,d,,' $outFile $outFile";
    my $ret = $self->_runCommand($cmd);
    if ( !$ret ) {
        $self->{logger}->error("Unable to delete history");
        return 0;
    }

    #Everything worked, so delete the temporary directory.
    remove_tree($dir);

    return 1;

}

sub _addGroupInfo {
    my ( $self, %params ) = @_;

    my $file       = $params{file};
    my $groupType  = $params{groupType};
    my $groupValue = $params{groupValue};
    my $variable   = $params{variable};

    # Translate month numbers to strings
    if ( $groupType eq 'MONTH' ) {
        switch ($groupValue) {
            case "01" { $groupValue = "January"; }
            case "02" { $groupValue = "February"; }
            case "03" { $groupValue = "March"; }
            case "04" { $groupValue = "April"; }
            case "05" { $groupValue = "May"; }
            case "06" { $groupValue = "June"; }
            case "07" { $groupValue = "July"; }
            case "08" { $groupValue = "August"; }
            case "09" { $groupValue = "September"; }
            case "10" { $groupValue = "October"; }
            case "11" { $groupValue = "November"; }
            case "12" { $groupValue = "December"; }
        }
    }

    my $cmd = "ncatted -O -h -a 'group_type,$variable,o,c,$groupType' "
        . "-a 'group_value,$variable,o,c,$groupValue' $file $file";

    if ( !$self->_runCommand($cmd) ) {
        $self->{logger}->error(
            "Unable to add group_type and group_value attributes to data file"
        );
        return 0;
    }
    else {
        return 1;
    }
}

sub _addDataYearValues {
    my ( $self, %params ) = @_;
    my $file      = $params{file};
    my @dataYears = @{ $params{dataYears} };

    # easiest way to do this is via an ncap2 script, I think.
    my @lines = ();

    # declare the datayear variable with values of zero.
    push( @lines, "datayear=array(0,0,\$time);" );

    # set each value
    for ( my $i = 0; $i < scalar(@dataYears); $i++ ) {
        push( @lines, "datayear($i)=$dataYears[$i];" );
    }

    # set the long name time
    push( @lines, 'datayear@long_name="Data year";' );

    my $script = join( "\n", @lines );
    $script = "$script\n";
    my ( $ft, $ncap2File ) = tempfile(
        "dataYears_XXXX",
        DIR    => $params{dir},
        SUFFIX => ".ncap2",
        UNLINK => 0
    );
    print $ft $script or die $!;
    close($ft) or die $!;

    my $cmd = "ncap2 -S $ncap2File -O $file $file";
    if ( !$self->_runCommand($cmd) ) {
        return 0;
    }
    else {
        return 1;
    }
}

sub _getDataYear {
    my ( $self, %params ) = @_;
    my $file = $params{file};

    my ($dataMonth)
        = Giovanni::Data::NcFile::get_variable_values( $params{file},
        'datamonth', 'time' );
    if ( $dataMonth =~ /^(\d\d\d\d)/ ) {
        return $1;
    }
    else {
        $self->{logger}->error(
            "Unable to parse datamonth variable value in " . $params{file} );
        return undef;
    }
}

sub _addTimeDimension {
    my ( $self, %params ) = @_;
    my $file             = $params{file};
    my $secondsSince1970 = $params{timeStamp};

    # get rid of anything after '.'. This should not be a float
    $secondsSince1970 =~ s/[.].*//;

    # first, delete the time variable that is already there
    my $cmd = "ncks -O -C -h -x -v time  $file $file";
    if ( !$self->_runCommand($cmd) ) {
        return undef;
    }

    # Bizarrely, if you run ncecat on a single file, it adds a record
    # dimension to non-dimension variables. This record dimension is called
    # "record".
    $cmd = "ncecat -O -h $file $file";
    if ( !$self->_runCommand($cmd) ) {
        return 0;
    }

    # Rename the record dimension to 'time'
    $cmd = "ncrename -O -h -d record,time $file $file";
    if ( !$self->_runCommand($cmd) ) {
        return 0;
    }

    # write a simple ncap2 script for setting up the time variable value
    my $script = <<"SCRIPT";
time[\$time]=$secondsSince1970;
time\@standard_name = "time" ;
time\@units = "seconds since 1970-01-01 00:00:00" ;
SCRIPT

    my ( $ft, $ncap2File ) = tempfile(
        "timeDim_XXXX",
        DIR    => $params{dir},
        SUFFIX => ".ncap2",
        UNLINK => 0
    );
    print $ft $script or die $!;
    close($ft) or die $!;

    $cmd = "ncap2 -S $ncap2File -O $file $file";
    if ( !$self->_runCommand($cmd) ) {
        return 0;
    }

    return 1;
}

sub _concatenateAndSubset {
    my ( $self, %params ) = @_;
    my $name = basename( $params{files}[0] );
    $name =~ s/[.]nc/_concatSubset.nc/;
    my $outFile = $params{"tempDir"} . "/$name";

    my $bbox  = Giovanni::BoundingBox->new( STRING => $params{bbox} );
    my $west  = _makeFloat( $bbox->west() );
    my $south = _makeFloat( $bbox->south() );
    my $east  = _makeFloat( $bbox->east() );
    my $north = _makeFloat( $bbox->north() );
    # snap to grid if bbox < file res
    # here the file is still fullsize so it is safe to
    # allow Giovanni::NcFile::subset_bbox_cmd use 
    # Giovanni::NcFile::spatial_resolution (needs at least 3 pixels)
    my @ncks_subset  = subset_bbox_cmd(
    "$west,$south,$east,$north", $params{files}[0]);

    my @lats = split( /,/, $ncks_subset[3] );
    my @lons = split( /,/, $ncks_subset[5] );
    $south = $lats[1];
    $north = $lats[2];
    $west  = $lons[1];
    $east  = $lons[2];

    my $cmd = "ncrcat -d 'lon,$west,$east' -d 'lat,$south,$north' ";

    if ( defined( $params{zVar} ) && defined( $params{zValue} ) ) {

        # zValue is something like 1000hPA. We want all the stuff before the
        # characters.
        if ( !( $params{zValue} =~ /^([\d.]*)/ ) ) {
            $self->{logger}
                ->error( "Unable to parse zValue: " . $params{zValue} );
            return undef;
        }
        my $zValue = $1;
        $self->{logger}->debug("Got zvalue: $zValue");

        $cmd = "$cmd" . "-d " . $params{zVar} . ",";

        my $min = $zValue - 0.0000001 * $zValue;
        my $max = $zValue + 0.0000001 * $zValue;
        $cmd = $cmd . "$min,$max ";
    }

    for my $file ( @{ $params{files} } ) {
        $cmd = $cmd . "$file ";
    }
    $cmd = $cmd . $outFile;
    if ( !$self->_runCommand($cmd) ) {
        return undef;
    }

    # now delete the 'datamonth' variable and the time variable
    $cmd = "ncks -O -C -h -x -v datamonth  $outFile $outFile";
    if ( !$self->_runCommand($cmd) ) {
        return undef;
    }
    return $outFile;
}

sub _convertNaNToFill {
    my ( $self, %params ) = @_;
    my $file     = $params{file};
    my $variable = $params{variable};
    my $cmd      = "remove_nans.py $file $file $variable";
    if ( !$self->_runCommand($cmd) ) {
        return undef;
    }
    return $file;
}

sub _dropPartialSeasons {
    my ( $self, %params ) = @_;

    # create temp file
    my ( $fh, $currInputsFile ) = tempfile(
        "inFiles_XXXX",
        DIR    => $params{dir},
        SUFFIX => ".txt",
        UNLINK => 0
    );
    for my $inFile ( @{ $params{files} } ) {
        print $fh $inFile . "\n";
    }
    close($fh);

    # create an output temp file

    ( $fh, my $newInputsFile ) = tempfile(
        "noPartials_XXXX",
        DIR    => $params{dir},
        SUFFIX => '.txt',
        UNLINK => 0
    );
    close($fh);

    # create a file to pipe stdout to
    ( $fh, my $stderrFile ) = tempfile(
        "stdErrOut_XXXX",
        DIR    => $params{dir},
        SUFFIX => '.txt',
        UNLINK => 0
    );
    close($fh);

    my $variable = $params{variable};
    my $group    = $params{groupType} . "=" . $params{groupValue};
    my $cmd = "seasonDropper.py -f $currInputsFile -v $variable -g $group "
        . "-o $newInputsFile 2> $stderrFile";
    my $ret = system($cmd);
    if ( $ret != 0 ) {
        $self->{logger}->error(
            "ERROR Unable to filter input files list for partial seasons. Command returned non-zero: $cmd"
        );
        die("Unable to filter seasons");
    }

    # read how many files were dropped
    open( FILE, "<", $stderrFile );
    my $line = <FILE>;
    close(FILE);
    chomp($line);

    $self->{logger}->debug("Dropped partial seasons: $line");

    # read out the files
    open( FILE, "<", $newInputsFile );
    my @files = <FILE>;
    close(FILE);
    chomp(@files);
    return @files;
}

sub _makeFloat {
    my ($num) = @_;
    if ( !( $num =~ /[.]/ ) ) {
        $num = "$num.0";
    }
    return $num;
}

sub _runCommand {
    my ( $self, $cmd ) = @_;

    my $rc = system($cmd);
    if ( $rc == 0 ) {
        $self->{logger}->debug("ran command '$cmd'");
        return 1;
    }
    else {
        $rc >>= 8;
        $self->{logger}->error("command failed '$cmd': $rc");
        return 0;
    }
}

# Go through the files and break them up into groups of 3 (seasons). Get out
# the time stamps for the first of each group because the time dimension will
# be lost when we average.
sub _groupFiles {
    my ( $self, @inFiles ) = @_;

    my @groups = ();
    for ( my $i = 0; $i < scalar(@inFiles); $i += 3 ) {
        my @files = @inFiles[ $i .. $i + 2 ];
        my ($timeValue)
            = Giovanni::Data::NcFile::get_variable_values( $files[0], "time",
            "time" );
        push( @groups, { files => \@files, time => $timeValue } );
    }
    return @groups;
}

1;
__END__

=head1 NAME

Giovanni::Algorithm::SeasonalTimeSeries - Perl extension for calculating a 
seasonal (a.k.a. 'interannual') time series

=head1 SYNOPSIS

  use Giovanni::Algorithm::SeasonalTimeSeries;
  
  ...
  
  my $averager = Giovanni::Algorithm::SeasonalTimeSeries->new();
  
  my $ret = $averager->calculate(
    bbox       => $bbox,
    inFiles    => \@inFiles,
    outFile    => $outNc,
    groupType  => "SEASON",
    groupValue => "DJF",
    variable   => 'TRMM_3B43_007_precipitation',
  );
  
  if( !$ret ) {
      # do something about error
  }

=head1 DESCRIPTION

This is the library associated with seasonalTimeSeries.pl. 

=head2 new()

Constructor. Takes an optional 'logger' parameter. Takes an optional 'shape'
parameters. If the 'shape' parameter is set, the code will assume there is a
"shape_mask" variable with weights for area averaging in each file it 
averages.

=head2 $averager->calculate()

Performs the average.

=head3 INPUTS

=over 8

=item bbox - the bounding box in 'W,S,E,N' string format

=item inFiles - the input files for the average. Should be only the files 
associated with one season/month.

=item outFile - destination file for the average

=item groupType - 'MONTH' or 'SEASON'

=item groupValue - the month (numeric: 01, 02, ..., or 12) or season (DJF,
MAM, JJA, or SON)

=item variable - the variable to average over

=back

=head4 OUTPUT

True if successful and false otherwise.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.gov<gt>

=cut
