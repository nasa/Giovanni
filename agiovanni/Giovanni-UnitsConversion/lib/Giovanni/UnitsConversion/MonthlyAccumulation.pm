package Giovanni::UnitsConversion::MonthlyAccumulation;

use 5.010001;
use strict;
use warnings;
use Giovanni::Data::NcFile;
use DateTime;
use DateTime::Duration;
use File::Temp qw/tempfile/;

sub new {
    my ( $pkg, %params ) = @_;

    my @requiredParams
        = ( "destinationUnits", "variable", "type", "to_days_scale_factor" );
    for my $param (@requiredParams) {
        if ( !defined( $params{$param} ) ) {
            my $msg
                = "$param is a required parameter for Giovanni::UnitsConversion::MonthlyAccumulation";
            $params{logger}->error($msg) if $params{logger};
            die $msg;
        }
    }

    my $self = bless \%params, $pkg;

    return $self;
}

sub convert {
    my ( $self, %params ) = @_;

    # files
    my $sourceFile      = $params{"sourceFile"};
    my $destinationFile = $params{"destinationFile"};

    # figure out how many days in the months there are
    my @daysInMonth = $self->_getDaysInMonthArray($sourceFile);

    if ( scalar(@daysInMonth) == 0 ) {
        return 0;
    }

    my $variable             = $self->{variable};
    my $to_days_scale_factor = $self->{to_days_scale_factor};
    my $type                 = $self->{type};
    my $destinationUnits     = $self->{destinationUnits};

    # figure out the dimensions. The time dimension should always be first
    my $shape
        = Giovanni::Data::NcFile::get_variable_dimensions( $sourceFile, 0,
        $variable );
    my @dims = split( " ", $shape );
    my $numDims = scalar(@dims);

    # create a template for the hyperslab we're going to use. The time
    # dimension is always first, so the slab is going to look something like
    # "var(0,:,:)" or "var(0,:)" or var(0) depending how many dimensions there
    # are. This template will the dimensions after the "(0".
    my $template = ",:" x ( $numDims - 1 );

    # now create an nco script
    my ( $fh, $filename ) = tempfile(
        "unitsConversion_XXXX",
        SUFFIX => '.ncap2',
        UNLINK => 1,
        TMPDIR => 1
    );

    for ( my $i = 0; $i < scalar(@daysInMonth); $i++ ) {
        my $days    = $daysInMonth[$i];
        my $varSlab = "$variable($i$template)";
        print $fh
            qq($varSlab=$type($varSlab*($to_days_scale_factor)*$days);\n);
    }
    print $fh qq($variable\@units="$destinationUnits";\n);
    close($fh);

    # call ncap2
    my $cmd = "ncap2 -O -S $filename $sourceFile $destinationFile";
    my $ret = system($cmd);

    if ( $ret != 0 ) {
        $self->{logger}
            ->error("Unable to call ncap2 command to convert file: $cmd")
            if $self->{logger};
        return 0;
    }

    return 1;
}

sub _getDaysInMonthArray {
    my ( $self, $file ) = @_;

    # time in the file is seconds since 1970
    my @secondsSince1970
        = Giovanni::Data::NcFile::get_variable_values( $file, "time",
        "time" );

    if ( scalar(@secondsSince1970) == 0 ) {
        my $msg = "Unable to get time dimension out of file $file.";
        $self->{logger}->error($msg) if $self->{logger};
        return;
    }

    return map( _getDaysInMonth($_), @secondsSince1970 );
}

sub _getDaysInMonth {
    my ($secondsSince1970) = @_;

    # start with the beginning of 1970
    my $dt = DateTime->new(
        year   => 1970,
        month  => 1,
        day    => 1,
        hour   => 0,
        minute => 0,
        second => 0,
    );

    # add the seconds so we have a datetime object for the time stamp in the
    # file
    $dt->add( seconds => $secondsSince1970 );

    # get a datetime object for exactly one month later
    my $oneMonthLater = $dt->clone();
    $oneMonthLater->add( months => 1 );

    # take the difference
    my $delta = $oneMonthLater->delta_days($dt);
    return $delta->in_units('days');
}

sub valuesConvert {
    my (%params) = @_;
    my @requiredParams = ( "to_days_scale_factor", "values" );
    for my $param (@requiredParams) {
        if ( !defined( $params{$param} ) ) {
            my $msg
                = "$param is a required parameter for Giovanni::UnitsConversion::MonthlyAccumulation::valuesConbert";
            $params{logger}->error($msg) if $params{logger};
            die $msg;
        }
    }

    my $daysInMonth;
    if ( $params{"daysInMonth"} ) {
        $daysInMonth = $params{"daysInMonth"};
    }
    else {

        # Unless otherwise specified, use 30
        $daysInMonth = 30;
    }

    my @converted = map( $_ * $params{"to_days_scale_factor"} * $daysInMonth,
        @{ $params{values} } );

    return @converted;
}

1;
__END__

=head1 NAME

Giovanni::UnitsConversion::MonthlyAccumulation - Perl extension for doing
monthly accumulation units conversion. Intended to be used by 
Giovanni::UnitsConversion. See Giovanni::UnitsConversion for usage.

=head1 SYNOPSIS

  use Giovanni::UnitsConversion;
  
  ...
  
  # convert netcdf files
  my $converter = Giovanni::UnitsConversion->new( config => $cfg, );

  $converter->addConversion(
    sourceUnits      => 'mm/hr',
    destinationUnits => 'mm/month',
    variable         => 'TRMM_3B43_007_precipitation',
    type             => "float",
  );

  
  my $ret      = $converter->ncConvert(
    sourceFile      => $dataFile,
    destinationFile => $destFile
  );
  
  
  

=head1 DESCRIPTION

Converts data variables from one set of units to another. 

=head1 FUNCTION: new

Creates a conversion object.

=head2 INPUTS

=head3 logger (optional)

Logger for intermediate status and debug information.

=head3 destination Units

The units we are converting to.

=head3 variable

The name of the variable to convert.

=head3 type

The type (float, int, ...) of the variable. Note: 
Giovanni::Data::NcFile::get_variable_type() can get this information for you out
of a netcdf file.

=head3 to_days_scale_factor

The scale factor that will convert the data time base to days. This code will
figure out how to get it from days to months.


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

=head3 values

An array of values to convert.

=head3 daysInMonth (optional)

If not specified, the code will assume 30 days in a month.

=head3 to_days_scale_factor

The scale factor that will convert the data time base to days. This code will
assume 30 days in the month unless the 'daysInMonth' parameter is specified.

=head2 OUTPUT

An array a converted values.

=head1 AUTHOR

Christine E Smit, E<lt>csmit@localdomainE<gt>

=cut
