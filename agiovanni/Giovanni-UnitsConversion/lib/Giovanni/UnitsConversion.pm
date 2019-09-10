#$Id: UnitsConversion.pm,v 1.15 2015/04/09 20:41:13 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
package Giovanni::UnitsConversion;

use 5.010001;
use strict;
use warnings;
use XML::LibXML;
use File::Temp qw/tempfile/;
use Giovanni::Data::NcFile;
use List::MoreUtils qq/uniq/;

our $VERSION = '0.01';

# Preloaded methods go here.

# config file
# destination units
sub new {
    my ( $pkg, %params ) = @_;

    my %obj = ();
    my $self = bless \%obj, $pkg;

    my $logger = $params{"logger"};
    $self->{"logger"} = $params{"logger"};

    if ( !defined( $params{"config"} ) ) {
        die "config parameter is required";
    }
    if ( !( -e $params{"config"} ) ) {
        die "Unable to find configuration file: " . $params{"config"};
    }

    # parse the configuration file
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file( $params{"config"} );
    $self->{dom} = $dom;

    # setup an empty ncap2 script file
    my ( $fh, $filename ) = tempfile(
        "linearUnitsConversion_XXXX",
        SUFFIX => '.ncap2',
        UNLINK => 1,
        TMPDIR => 1
    );
    close($fh);
    $self->{ncap2} = $filename;

    return $self;
}

sub addConversion {
    my ( $self, %params ) = @_;

    if ( !defined( $params{"sourceUnits"} ) ) {
        die "sourceUnits parameter is required";
    }
    my $sourceUnits = $params{"sourceUnits"};

    if ( !defined( $params{"destinationUnits"} ) ) {
        die "destinationUnits parameter is required";
    }
    my $destinationUnits = $params{"destinationUnits"};

    if ( !defined( $params{"variable"} ) ) {
        die "variable parameter is required";
    }
    if ( !defined( $params{"type"} ) ) {
        die "type parameter is required";
    }

    if ( !$self->_setupLinearConversion(%params) ) {
        if ( !$self->_setupNonLinearConversion(%params) ) {
            my $msg
                = "Unable to setup conversion for "
                . $params{"variable"} . ", "
                . $params{"sourceUnits"} . "->"
                . $params{"destinationUnits"};
            $self->{logger}->user_error("Unable to setup units conversion")
                if $self->{logger};
            $self->{logger}->error($msg) if $self->{logger};
            die($msg);
        }
    }

}

sub _setupLinearConversion {
    my ( $self, %params ) = @_;
    my $sourceUnits      = $params{"sourceUnits"};
    my $destinationUnits = $params{"destinationUnits"};
    my $variable         = $params{"variable"};
    my $type             = $params{"type"};

    my (%out) = _getLinearConversionValues(
        sourceUnits      => $sourceUnits,
        destinationUnits => $destinationUnits,
        dom              => $self->{dom}
    );

    if ( !$out{"isLinear"} ) {
        return 0;
    }

    # found it!
    $self->{hasLinearConversion} = 1;
    my $scaleFactor = $out{"scaleFactor"};
    my $addOffset   = $out{"addOffset"};
    $self->{logger}
        ->info( "Found conversion from $sourceUnits to $destinationUnits: "
            . "scale_factor=$scaleFactor, add_offset=$addOffset" )
        if $self->{logger};

    # update the ncap2 script
    my @ncap2 = ();
    push( @ncap2,
        qq($variable=$type($variable*($scaleFactor) + ($addOffset));) );
    push( @ncap2, qq($variable\@units="$destinationUnits";) );

    open( FH, ">>", $self->{ncap2} )
        or die "Unable to open ncap2 script " . $self->{ncap2} . ": $!";
    print FH join( "\n", @ncap2 );
    print FH "\n";
    close(FH);

    if ( $self->{logger} ) {
        $self->{logger}
            ->debug( "Updated ncap2 script for units conversion to "
                . $self->{ncap2}
                . ":" );
        for my $line (@ncap2) {
            $self->{logger}->debug("    $line");
        }
    }

    return 1;
}

sub _setupNonLinearConversion {
    my ( $self, %params ) = @_;

    my $sourceUnits      = $params{"sourceUnits"};
    my $destinationUnits = $params{"destinationUnits"};
    my $variable         = $params{"variable"};
    my $type             = $params{"type"};

    my (%out) = _getNonLinearConversionValues(
        sourceUnits      => $sourceUnits,
        destinationUnits => $destinationUnits,
        dom              => $self->{dom}
    );

    if ( !$out{"isNonLinear"} ) {

        return 0;
    }
    $self->{hasNonLinearConversion} = 1;

    if ( !$out{"class"} ) {
        $out{class} = sprintf( "%s::MonthlyAccumulation", ref($self) );
    }

    # put together the commands that will create this conversion object.
    if ( !defined( $self->{nonLinearConverters} ) ) {
        $self->{nonLinearConverters} = [];
    }
    my $class       = $out{"class"};
    my %classParams = %params;
    if ( $self->{logger} ) {
        $classParams{logger} = $self->{logger};
    }
    for my $key ( keys( %{ $out{configParams} } ) ) {
        my $value = $out{configParams}->{$key};
        $classParams{$key} = $value;
    }
    my @cmds = ("use $class;");
    push( @cmds, "my \$converter = \$class->new(\%classParams);" );
    push( @cmds, 'push(@{$self->{nonLinearConverters}},$converter);' );
    eval( join( "\n", @cmds ) );
    if ($@) {
        $self->{logger}->error( "Unable to setup nonlinear converter for "
                . "$sourceUnits->$destinationUnits: $@" )
            if $self->{logger};
        return 0;
    }
    return 1;

}

sub ncConvert {
    my ( $self, %params ) = @_;
    if ( !defined( $params{sourceFile} ) ) {
        die "sourceFile is a required parameter";
    }
    my $sourceFile = $params{sourceFile};
    if ( !defined( $params{destinationFile} ) ) {
        die "destinationFile is a required parameter";
    }
    my $destinationFile = $params{destinationFile};

    # see if we have a linear conversion
    if ( $self->{hasLinearConversion} ) {
        my $cmd
            = "ncap2 -O -S "
            . $self->{ncap2}
            . " $sourceFile $destinationFile";
        my $ret = system($cmd);
        if ( $ret != 0 ) {
            my $msg = "Command returned non-zero: $cmd";
            $self->{logger}->user_error("Unable to complete units conversion")
                if $self->{logger};
            $self->{logger}->error($msg) if $self->{logger};
            return 0;
        }

        # further conversions will happen on the destination file.
        $sourceFile = $destinationFile;
    }

    # see if we have one or more non-linear conversions
    if ( $self->{hasNonLinearConversion} ) {
        for my $converter ( @{ $self->{nonLinearConverters} } ) {
            my $success = $converter->convert(
                sourceFile      => $sourceFile,
                destinationFile => $destinationFile
            );

            # our source file for the next conversion is the current
            # destination file
            $sourceFile = $destinationFile;
            if ( !$success ) {
                return 0;
            }
        }
    }

    return 1;
}

sub _getLinearConversionValues {
    my (%params)         = @_;
    my $sourceUnits      = $params{"sourceUnits"};
    my $destinationUnits = $params{"destinationUnits"};
    my @nodes
        = $params{dom}->findnodes(
        qq(/units/linearConversions/linearUnit[\@source="$sourceUnits" and \@destination="$destinationUnits"])
        );
    if ( scalar(@nodes) == 0 ) {
        return ( isLinear => 0 );
    }

    # found it!
    my $scaleFactor = $nodes[0]->getAttribute("scale_factor");
    my $addOffset   = $nodes[0]->getAttribute("add_offset");

    return (
        isLinear    => 1,
        scaleFactor => $scaleFactor,
        addOffset   => $addOffset
    );

}

sub _getNonLinearConversionValues {
    my (%params)         = @_;
    my $sourceUnits      = $params{"sourceUnits"};
    my $destinationUnits = $params{"destinationUnits"};
    my @nodes
        = $params{dom}->findnodes(
        qq(/units/nonLinearConversions/*[\@source="$sourceUnits" and \@destination="$destinationUnits"])
        );
    if ( scalar(@nodes) == 0 ) {
        return ( isNonLinear => 0 );
    }

    # found it!
    my %ret = ( isNonLinear => 1 );

    # get out all the attributes
    my %configParams = ();
    my @attributes   = $nodes[0]->findnodes("\@*");
    for my $attribute (@attributes) {
        my $name = $attribute->nodeName();
        if ( $name eq "class" ) {
            $ret{"class"} = $attribute->value();
        }
        elsif ( $name ne "source" && $name ne "destination" ) {
            $configParams{$name} = $attribute->value();
        }
    }
    $ret{"configParams"} = \%configParams;

    return %ret;
}

sub isTimeDependent {
    my ( $self, %params ) = @_;
    if ( !defined( $params{"sourceUnits"} ) ) {
        die "sourceUnits is a required input";
    }
    my $sourceUnits = $params{"sourceUnits"};
    if ( !defined( $params{"destinationUnits"} ) ) {
        die "destinationUnits is a required input";
    }
    my $destinationUnits = $params{"destinationUnits"};

    my @nodes
        = $self->{dom}->findnodes( qq(/units/nonLinearConversions/)
            . qq(timeDependentUnit[\@source="$sourceUnits" and \@destination="$destinationUnits"])
        );

    if ( scalar(@nodes) == 0 ) {
        return 0;
    }
    else {
        return 1;
    }

}

sub valuesConvert {
    my (%params) = @_;

    if ( !defined( $params{"sourceUnits"} ) ) {
        die "sourceUnits is a required input";
    }
    if ( !defined( $params{"destinationUnits"} ) ) {
        die "destinationUnits is a required input";
    }
    if ( !defined( $params{"config"} ) ) {
        die "config is a required input";
    }

    if ( !defined( $params{"values"} ) ) {
        die "values is a required input";
    }
    my @values = @{ $params{"values"} };

    my $logger = $params{"logger"};

    # find the node for this conversion
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file( $params{"config"} );

    my (%conv) = _getLinearConversionValues(
        dom              => $dom,
        destinationUnits => $params{destinationUnits},
        sourceUnits      => $params{sourceUnits},
    );

    my %ret = ();

    if ( $conv{"isLinear"} ) {
        my $scaleFactor = eval( $conv{"scaleFactor"} );
        my $addOffset   = eval( $conv{"addOffset"} );
        my @newValues   = map( $_ * $scaleFactor + $addOffset, @values );
        $ret{"success"} = 1;
        $ret{"values"}  = \@newValues;
        return %ret;
    }
    else {

        %conv = _getNonLinearConversionValues(
            dom              => $dom,
            destinationUnits => $params{destinationUnits},
            sourceUnits      => $params{sourceUnits},
        );

        if ( !$conv{"isNonLinear"} ) {
            my $msg
                = "Unable to find configuration for "
                . $params{sourceUnits} . "->"
                . $params{destinationUnits}
                . " conversion.";
            $params{logger}->warn($msg) if $params{logger};
            $ret{"message"} = $msg;
            $ret{"success"} = 0;
            return %ret;
        }

        my @newValues = ();
        my %classParams = ( values => $params{values} );
        for my $key ( keys( %{ $conv{configParams} } ) ) {
            $classParams{$key} = $conv{configParams}->{$key};
        }

        my $class = $conv{"class"};
        my @cmds  = ("use $class;");
        push( @cmds,
            "\@newValues = $class" . "::valuesConvert(%classParams);" );
        eval( join( "\n", @cmds ) );
        if ($@) {
            my $msg
                = "Unable to setup nonlinear converter for "
                . $params{sourceUnits} . "->"
                . $params{destinationUnits} . ": $@";
            $params{logger}->warn($msg) if $params{logger};
            $ret{"success"} = 0;
            $ret{"message"} = $msg;
            return %ret;
        }
        $ret{"success"} = 1;
        $ret{"values"}  = \@newValues;
        return %ret;
    }

}

sub getAllDestinationUnits {
    my (%params) = @_;
    if ( !defined( $params{"config"} ) ) {
        die "'config' is a required parameter";
    }
    my $config = $params{"config"};

    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file( $params{"config"} );

    my $xpath = '//*/@destination';

    my @nodes = $dom->findnodes($xpath);
    my @units = map( $_->getValue(), @nodes );
    @units = uniq(@units);
    return sort(@units);
}

sub checkConversions {
    my (%params) = @_;
    if ( !defined( $params{"config"} ) ) {
        die "'config' is a required parameter";
    }
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file( $params{"config"} );

    if ( !defined( $params{"sourceUnits"} ) ) {
        die "'sourceUnits' is a required parameter";
    }
    my $sourceUnits = $params{"sourceUnits"};

    if ( !defined( $params{"destinationUnits"} ) ) {
        die "'destinationUnits' is a required parameter";
    }
    my @destinationUnits = @{ $params{"destinationUnits"} };

    if ( !defined( $params{"temporalResolution"} ) ) {
        die "'temporalResolution' is a required parameter";
    }
    my $temporalResolution = $params{"temporalResolution"};

    my @problemUnits                       = ();
    my @conversionsThatDontExist           = ();
    my @conversionsForOtherTimeResolutions = ();
    for my $destinationUnit (@destinationUnits) {

        # try to find any entry with this source and destination
        my $xpath
            = qq(/units/*/*[\@source="$sourceUnits" and \@destination="$destinationUnit"]);
        my ($node) = $dom->findnodes($xpath);
        if ( !defined($node) ) {

            # not there, so we are done
            push( @problemUnits,             $destinationUnit );
            push( @conversionsThatDontExist, $destinationUnit );
        }
        else {

            # we found the conversion
            if ( $node->nodeName() eq "timeDependentUnit" ) {

                # time dependent conversions are specific to certain temporal
                # resolutions
                my $temporalResolutionsString
                    = $node->getAttribute("temporal_resolutions");
                my @resolutions = split( ',', $temporalResolutionsString );
                if (scalar( grep( /$temporalResolution/, @resolutions ) ) eq
                    0 )
                {

                    # this temporal resolution does not work with this
                    # conversion
                    push( @problemUnits, $destinationUnit );
                    push( @conversionsForOtherTimeResolutions,
                        $destinationUnit );
                }

            }
        }
    }

    if ( scalar(@problemUnits) == 0 ) {
        return ( allOkay => 1 );
    }
    else {
        my %ret = ( allOkay => 0 );
        $ret{problemUnits}             = \@problemUnits;
        $ret{conversionsThatDontExist} = \@conversionsThatDontExist;
        $ret{conversionsForOtherTimeResolutions}
            = \@conversionsForOtherTimeResolutions;

        # build a useful (?) message
        my @messages = ();
        if ( scalar(@conversionsThatDontExist) != 0 ) {
            my $msg
                = "The following conversions are not available for "
                . "$sourceUnits: "
                . join( ", ", @conversionsThatDontExist );
            push( @messages, $msg . "." );
        }
        if ( scalar(@conversionsForOtherTimeResolutions) != 0 ) {
            my $msg
                = "The following conversions are not available for "
                . "$sourceUnits with $temporalResolution temporal resolution: "
                . join( ", ", @conversionsForOtherTimeResolutions );
            push( @messages, $msg . "." );
        }
        $ret{message} = join( " ", @messages );
        return %ret;
    }

}

1;
__END__

=head1 NAME

Giovanni::UnitsConversion - Perl extension for converting units.

=head1 SYNOPSIS

  use Giovanni::UnitsConversion;
  
  ...
  
  # convert netcdf files
  my $converter = Giovanni::UnitsConversion->new( config => $cfg, );

  $converter->addConversion(
    sourceUnits      => 'mm/day',
    destinationUnits => 'mm/hr',
    variable         => 'TRMM_3B42_daily_precipitation_V7',
    type             => 'float',
  );

  
  my $ret      = $converter->ncConvert(
    sourceFile      => $dataFile,
    destinationFile => $destFile
  );
  
  
  ...
  
  # check to see if a particular conversion is time dependent
  
  my $check = $coverter->isTimeDependent(    
    sourceUnits      => 'mm/day',
    destinationUnits => 'mm/hr');

  ...
  
  # convert a list of values
  my %ret = Giovanni::UnitsConversion::valuesConvert(
    config           => $cfg,
    sourceUnits      => "mm/day",
    destinationUnits => "mm/hr",
    "values"         => \@values
  );
  
  if($ret{"success"}){
    my @values = $ret{"values"};
    # do something with converted values
    ...
  } else {
      log_error($ret{"message"});
  }
  

=head1 DESCRIPTION

Converts data variables from one set of units to another. 

=head1 FUNCTION: new

Creates a conversion object.

=head2 INPUTS

=head3 config

The location of the configuration file.

=head3 logger (optional)

Logger for intermediate status and debug information.

=head1 FUNCTION: addConversion

Sets up conversion for a variable. May be called multiple times.

=head2 INPUTS

=head3 sourceUnits

The units we are converting from.

=head3 destination Units

The units we are converting to.

=head3 variable

The name of the variable to convert.

=head3 type

The type (float, int, ...) of the variable. Note: 
Giovanni::Data::NcFile::get_variable_type() can get this information for you out
of a netcdf file.

=head1 FUNCTION: $converter->isTimeDependent()

Tests to see if a particular conversion is time dependent.

=head2 INPUTS

=head3 sourceUnits

The units we are converting from.

=head3 destination Units

The units we are converting to.


=head1 FUNCTION: $converter->ncConvert()

Converts data variables units.

=head2 INPUTS

=head3 sourceFile

The name of the input file.

=head3 destinationFile

The name of the output file.

=head2 OUTPUT

True if successful and false otherwise.

=head1 FUNCTION: Giovanni::UnitsConversion::valuesConvert

Converts an array of values to new units.

=head2 INPUTS

=head3 config

The units conversion configuration file.

=head3 sourceUnits

The original units of the data.

=head3 destinationUnits

The desired units.

=head3 values

An array of values to convert.

=head2 OUTPUT

A hash. If the conversion succeeded, $hash{"success"} will be true and
$hash{"values"} will have the array of converted values. Otherwise,
$hash{"success"} will be false and $hash{"message"} will have an error message.

=head1 CONFIGURATION FILE

The configuration file is of the format:

  <units>
      <linearConversions>
          <linearUnit source="mm/day" destination="mm/hr" scale_factor="1.0/24.0"
              add_offset="0" />
          <linearUnit source="mm/day" destination="inch/day"
              scale_factor="1.0/25.4" add_offset="0" />
      </linearConversions>
        <timeDependentUnit source="mm/hr" destination="mm/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="24.0" />
  </units>


=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>

=cut
