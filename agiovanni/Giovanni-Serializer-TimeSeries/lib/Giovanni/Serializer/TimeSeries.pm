#$Id: TimeSeries.pm,v 1.14 2014/01/30 14:47:40 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::Serializer::TimeSeries;

use 5.008008;
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use XML::LibXML;
use Date::Parse;
use Data::Dumper;
use DateTime;
use Time::HiRes qw (sleep);
use File::Temp qw/ tempfile tempdir /;
use Date::Manip;
use Giovanni::Util;
use Giovanni::Data::NcFile;
use POSIX;

our $VERSION = '0.01';

sub serialize {
    my (%params) = @_;

    # check we got the inputs we expected.
    if ( !( exists $params{"input"} ) ) {
        die "serialize requires an 'input' parameter with the input.xml file";
    }

    if ( !( exists $params{"ncFile"} ) ) {
        die
            "serialize requires an 'ncFile' parameter with the input netcdf file";
    }

    if ( !( exists $params{"outDir"} ) ) {
        die
            "serialize requires an 'outDir' parameter with the ouput directory";
    }

    ## to extract the 'time' and the data variable names
    my $url  = "";
    my $bbox = "";
    my $data = "";
    eval {
        ## to get 'url', 'bbox', and 'data' from input.xml
        my $parser       = XML::LibXML->new();
        my $doc          = $parser->parse_file( $params{"input"} );
        my @refererNodes = $doc->find('/input/referer');
        my $referer      = $refererNodes[0]->string_value;
        my @queryNodes   = $doc->find('/input/query');
        my $query        = $queryNodes[0]->string_value;
        my @qparts       = split( /\&/, $query );
        my $urlquery     = "";
        foreach my $part (@qparts) {
            next if ( $part =~ /session=/ );
            $urlquery .= "&" if ( $urlquery ne "" );
            $urlquery .= $part;
        }
        $url = "$referer#$urlquery";
        my @bboxNodes = $doc->find('/input/bbox');
        $bbox = $bboxNodes[0]->string_value;
        my @dataNodes = $doc->find('/input/data');
        $data = $dataNodes[0]->string_value;

    };
    if ($@) {
        print STDERR "USR_ERROR xml failure\n";
        print STDERR "ERROR failed to retrieve the xml root element: $@\n";
        exit(1);
    }

    return _getTimeSeriesCSV( $params{"ncFile"}, $params{"outDir"}, $url,
        $bbox, $data );

}

#########################################################################
## Name: _getTimeSeriesCSV
## Arguments:
##          $infile -- input file (netcdf)
##          $workingdir -- a working directory
##          $url -- url to reproduce results
##          $spatialarea - bounding box
##          $data - aesir id/variable name
## Return: a csv file name
## Author: X. Hu
#########################################################################
sub _getTimeSeriesCSV {
    my ( $infile, $workingdir, $url, $spatialarea, $data, $debug ) = @_;
    my $csvFile = $workingdir . "/" . basename($infile) . ".csv";
    return $csvFile
        if ( -e $csvFile && !$debug )
        ;    ## if the csv file already exists, return it directly

    ##### get the serializable data variables and time variable
    my ( $timeVarName, $dataVarNamesSet )
        = _getVariableNames( $infile, $workingdir );

    my @dataVarNames = _getVariablesInOrder(
        [   $data,               "stddev_$data",
            "min_$data",         "max_$data",
            "count_$data",       "difference",
            "stddev_difference", "min_difference",
            "max_difference",    "count_difference"
        ],
        $dataVarNamesSet
    );

    # hash the variable name to the column header if the column header is
    # different from the variable name
    my $nameHash = { $data => "mean_$data", };

    ######## to extract data variable and time
    my $info
        = _extractVariableValues( $infile,
        [ keys( %{$dataVarNamesSet} ), $timeVarName ],
        $timeVarName, 1 );
    my $timeInfo
        = _extractVariableValues( $infile, [$timeVarName], $timeVarName, 0 );

    # combine hashes
    $info = { %{$info}, %{$timeInfo} };

    ####### to declare variables
    my $bookmarkableurl = "URL to Reproduce Results:,\"$url\"\n";
    my $index           = 0;
    my $startdate       = "";
    my $enddate         = "";
    my $bbox            = "User Bounding Box:,\"$spatialarea\"\n";
    my $title           = "";
    my $hinttitle       = "";
    my $interval        = "";
    my @databbox        = ();


    ####### to grab the global attributes
    my %globalAttrs = Giovanni::Util::getNetcdfGlobalAttributes($infile);
    while ( my ( $key, $val ) = each(%globalAttrs) ) {
        if ( $key =~ /userstartdate/ ) {
            $startdate = "User Start Date:,$val\n";
        }
        elsif ( $key =~ /userenddate/ ) {
            $enddate = "User End Date:,$val\n";
        }
        elsif ( $key =~ /^plot_hint_title$/ ) {
            $hinttitle = "Title:,$val ($interval)\n";
        }
        elsif ( $key =~ /^temporal_resolution$/ ) {
            $interval = $val;
        }
        # CF convention insists we put 
        # the data bbox in 4 separate attributes:
        elsif ( $key =~ /^geospatial_lat_min$/ ) {
            $databbox[1] =  $val;
        }   
        elsif ( $key =~ /^geospatial_lat_max$/ ) {
            $databbox[3] =  $val;
        }   
        elsif ( $key =~ /^geospatial_lon_min$/ ) {
            $databbox[0] =  $val;
        }   
        elsif ( $key =~ /^geospatial_lon_max$/ ) {
            $databbox[2] =  $val;
        }   

    }
    my $bbox_string = join(",",@databbox);
    my $bboxofdata      = "Data Bounding Box:,\"$bbox_string\"\n";

    ## to concatenate the header info
    my $headerInfo .= "$hinttitle";
    $headerInfo    .= $startdate;
    $headerInfo    .= $enddate;
    $headerInfo    .= $bbox;
    $headerInfo    .= $bboxofdata;
    $headerInfo    .= "$bookmarkableurl";

    # add all the fill values
    for my $varName (@dataVarNames) {
        my $varStr = $nameHash->{$varName} ? $nameHash->{$varName} : $varName;

        # this variable is in the file, so add it to the serialization
        my $fv = $info->{$varName}->{'_FillValue'};
        if ( $fv eq '' ) {
            $headerInfo .= "Fill Value ($varStr): None,";
        }
        else {
            $headerInfo .= "Fill Value ($varStr): $fv,";
        }

    }

    # remove the last semi-colon
    chop($headerInfo);
    $headerInfo .= "\n";

    ## to write content to csv file
    open FH, '>', "$csvFile"
        or die "ERROR failed to write the file: $!\n";
    print FH $headerInfo;
    print FH "\n";
    print FH "$timeVarName";
    for my $varName (@dataVarNames) {
        my $varStr
            = $nameHash->{$varName}
            ? $nameHash->{$varName}
            : $varName;
        print FH ", $varStr";
    }
    print FH "\n";
    my $numValues = scalar( @{ $info->{$timeVarName}->{'values'} } );
    for ( my $i = 0; $i < $numValues; $i++ ) {

        # convert the time value to ISO8601 format
        my $timeStr = $info->{$timeVarName}->{'values'}->[$i];
        Giovanni::Util::trim($timeStr);
        my $t    = DateTime->from_epoch( epoch => $timeStr );
        my $tval = "" . $t->iso8601();
        my $pos  = index( $tval, "T" );
        if ( $interval eq "daily" ) {
            $tval = substr $tval, 0, $pos;
        }
        else {
            $tval =~ s/T/ /gi;
        }
        print FH $tval;

        # now print out the variable values
        for my $varName (@dataVarNames) {
            my $value = $info->{$varName}->{'values'}->[$i];
            Giovanni::Util::trim($value);
            print FH ",$value";
        }
        print FH "\n";
    }
    close(FH);

    return "" if ( !( -e $csvFile ) );

    return $csvFile;
}

##################################################
## Name: _getVariablesInOrder -- figure out what order the variables will appear
##                               in the output csv.
## Arguments:
##           $knownOrder       -- array of expected variable names, in the order
##           \%allVariableHash -- hash with the actual variable names in the
##                                data file
## Return:   @inOrder          -- order of variables that actually appear in
##                                the data file
##
## Author: C. Smit
#################################################
sub _getVariablesInOrder {
    my ( $knownOrder, $allVariableHash ) = @_;

    my @inOrder          = ();
    my $alreadyAddedHash = {};

    # okay, see which of the variables in $knownOrder are actually in the file
    for my $var ( @{$knownOrder} ) {
        if ( $allVariableHash->{$var} ) {
            push( @inOrder, $var );
            $alreadyAddedHash->{$var} = 1;
        }
    }

    # now see if there are any other variables in the file that we don't
    # have an order for.
    for my $var ( keys( %{$allVariableHash} ) ) {
        if ( !$alreadyAddedHash->{$var} ) {
            push( @inOrder, $var );
        }
    }

    return @inOrder;
}

##################################################
## Name: _getVariableNames -- get the time variable and data variables
## Arguments:
##           $ncfile           -- netcdf file
##           $workingdir       -- working directory
## Return:   $timeVariableName -- the name of the time variable
##           \%dataVarSet      -- a hash where the data variables are keys
##
## Author: C. Smit
#################################################
sub _getVariableNames {
    my ( $ncfile, $workingdir ) = @_;
    $workingdir =~ s/\/$//i;
    my $ncmlFile    = $workingdir . "/ncml_" . basename($ncfile) . ".xml";
    my $dumpCommand = "ncdump -x $ncfile > $ncmlFile";
    ## print STDERR "INFO dump command = $dumpCommand \n";
    `$dumpCommand`;
    if ( !( -e $ncmlFile ) ) {
        print STDERR "USER_ERROR failed to generate ncml: $ncmlFile\n";
        exit(1);
    }

    ## to declare variables
    my $timeVariableName = "";

    ## to extract the 'time' and the data variable names

    my $xpc = Giovanni::Data::NcFile::get_xml_header($ncfile);
    my @nodes
        = $xpc->findnodes(
        qq(/nc:netcdf/nc:variable/nc:attribute[\@name="quantity_type"]/../\@name)
        );
    my @dataVariableNames = map( $_->getValue(), @nodes );
    my %dataVarSet = ();
    for ( my $i = 0; $i < scalar(@dataVariableNames); $i++ ) {
        $dataVariableNames[$i] =~ /([a-zA-Z0-9_]*)/;
        $dataVarSet{$1} = 1;
    }

    @nodes
        = $xpc->findnodes(
        '/nc:netcdf/nc:variable/nc:attribute[@name="units" and starts-with(@value,"seconds since")]/../@name'
        );
    $timeVariableName = $nodes[0]->getValue();
    $timeVariableName =~ /([a-zA-Z0-9_]*)/;
    $timeVariableName = $1;
    if ( Scalar::Util::looks_like_number($timeVariableName) ) {
        die "Expected variable name";
    }
    return $timeVariableName, \%dataVarSet;
}

##################################################
## Name: _extractVariableValues -- to extract values and put them into a comma separated string
## Arguments:
##           $inputfile              -- netcdf file
##           $vname                  -- variable name
##           $dimname                -- name of the dimension
##           $scientificnotationokay -- if true, will use 1.38e+2 notation (%g)
## Return:   %variableInfo -- a hash of hashes. The top level key is the
##               variable name. Each variable name points to a hash with two
##               keys, '_FillValue' and 'values'. The '_FillValue' is set to ''
##               if there is no fill value.
##
## Author: X. Hu, C. Smit
#################################################
sub _extractVariableValues {
    my ( $inputfile, $vnames, $dimname, $scientificnotationokay ) = @_;

    my %variableInfo = ();

    for my $vname ( @{$vnames} ) {

        #figure out the type of the variable
        my $type = Giovanni::Data::NcFile::get_variable_type( $inputfile, 0,
            $vname );
        my $printString = '';
        if ($scientificnotationokay) {
            $printString = '%13.9g';
        }
        else {
            $printString = '%13.9f';
        }

        if ( $type eq 'int' || $type eq 'long' ) {
            $printString = '%d';
        }

        # setup the command to get data values out.
        my $cmd
            = "ncks -s '$printString\\n' -C -H -d $dimname,0, -v $vname $inputfile";

        my @values = `$cmd`;
        my $ret    = $?;
        if ( $ret != 0 ) {
            die
                "Unable to read data out of file. Command returned non-zero: $cmd.";
        }

        # remove the trailing '\n'
        chomp(@values);

        # remove trailing empty lines
        pop(@values) until $values[-1];
        $variableInfo{$vname} = {};

        # To get fill value:
        my ($attributeHash)
            = Giovanni::Data::NcFile::variable_attributes( $inputfile,
            $vname );
        if ( $attributeHash->{"_FillValue"} ) {
            my $fv = $attributeHash->{"_FillValue"};
            $fv = $fv * 1.0;
            $variableInfo{$vname}->{'_FillValue'} = $fv;

            # Replace '_' with fill value
            @values = map { $_ =~ /_/ ? $fv : $_ } @values;
        }
        else {
            $variableInfo{$vname}->{'_FillValue'} = '';
        }
        $variableInfo{$vname}->{'values'} = \@values;

    }

    return \%variableInfo;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::Serializer::TimeSeries - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Giovanni::Serializer::TimeSeries;
  my $csvFile = Giovanni::Serializer::TimeSeries::serialize(
   input  => $input,
   outDir => $outputDirectory,
   ncFile => $ncfile,
   catalog => $catalog,
   
);

=head1 DESCRIPTION

This code serializes a time series netcdf file.  It takes a hash arguments with 4 key/values: input, outDir, ncFile, and catalog
1.) input -- the input.xml file
2.) outDir -- the working directory for output
3.) ncFile -- the netcdf file to be processed
4.) catalog -- the xml file 'varInfo.xml'

=head1 AUTHOR
Xiaopeng Hu, xiaopeng.hu@nasa.gov

=cut
