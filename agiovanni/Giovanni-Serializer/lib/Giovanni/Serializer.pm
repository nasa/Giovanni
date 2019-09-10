package Giovanni::Serializer;

use 5.008008;
use strict;
use Safe;
use warnings;
use File::Basename;
use Giovanni::Util;
use URI::Escape;
use vars '$AUTOLOAD';
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Serializer ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.00';

sub new() {
    my ( $class, %inputs ) = @_;
    my $self = {};
    $self->{_FILE}          = $inputs{FILE};
    $self->{_OUTPUT_FORMAT} = $inputs{FORMAT};
    ##print STDERR "INFO: X-file = " . $self->{_FILE} . "\n";

    ##unless (defined $self->{_FILE}) {
    unless ( defined $self->{_FILE} ) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "NO Input file found";
        return bless( $self, $class );
    }

    unless ( defined $self->{_OUTPUT_FORMAT} ) {
        $self->{_OUTPUT_FORMAT} = "TAB";
    }

    return bless( $self, $class );
}
################################################################################
sub serialize {
    my ($self) = @_;

    my $inputFile = $self->{_FILE};
    my $fformat   = $self->{_OUTPUT_FORMAT};
    my $result    = "";

    if ( $inputFile =~ m/^http\:/i ) {
        ## reserve for future use
    }
    else {
        unless ( -f $inputFile ) {
            $self->{_ERROR_MESSAGE}
                = "Error: \"$inputFile\" does not exist\n";
            return $inputFile;
        }

        unless ( defined $fformat ) {
            $self->{_ERROR_MESSAGE}
                = "Info: default format is TAB separated\n";
            return $fformat;
        }

        $result = $self->createFormattedOutput( $inputFile, $fformat );
    }

    return $result;
}

sub createFormattedOutput {
    my ( $self, $ncfile, $format ) = @_;
    $format = "TAB" if ( !defined($format) );
    my $ascResult;
    if ( !defined($ncfile) ) {
        $ncfile = $self->{_FILE};
    }
    if ( !defined($format) ) {
        ## print INFO message
        print STDERR "INFO: Format == $format \n";
    }

    my $file = $ncfile;
    print STDERR "INFO: Input File = $file \n";
    my $serializationType = $self->getSerializationType();

    print STDERR "TYPE: $serializationType \n";

    if ( $serializationType ne "unknown" ) {
        my $ascCommand = "java -jar";

        if ( $serializationType =~ /verticalProfile/gi ) {
            ## $ascCommand = qq{$ascCommand  "$GIOVANNI::JAR_DIR/VerticalProfileSerializer.jar" "$self->{_FILE}"};  ## to disable VerticalProfileSerializer for YOTC temporarily
        }
        elsif ( $serializationType =~ /^timeSeries/gi ) {
            $ascCommand
                = qq{$ascCommand  "$GIOVANNI::JAR_DIR/MapssSerializer.jar" "$self->{_FILE}"};
        }
        elsif ( $serializationType =~ /^scatterPlot/gi ) {
            ## 2011-02-14 X. Hu added the "scatterPlot" for serializer
            $ascCommand
                = qq{$ascCommand  "$GIOVANNI::JAR_DIR/AerostatSerializer.jar" "$self->{_FILE}"};
        }
        else {
            ## print out the error msg for unknown Plot type
            print STDERR "Unsupported SerializerType: $serializationType \n";
        }
        print STDERR "ASCII command: $ascCommand \n";

        $ascResult = `$ascCommand`;
        if ( $serializationType =~ /VerticalProfile/gi ) {
            $ascResult = "verticalProfile"
                ;    ## not supported yet, thought code is ready
        }
        ##print STDERR "ASCII file: $ascResult \n";
    }

    return $ascResult;
}

################################################################################
sub getSerializationType {
    my ($self) = @_;
    my $file = $self->{_FILE};
    $file =~ s/\s//gi;
    my $typeCommand
        = qq {java -jar "$GIOVANNI::JAR_DIR/DataOutputManager.jar" "$file"};
    print STDERR "INFO: serialization type command = $typeCommand \n";
    my $serializationType = `$typeCommand`;
    chomp $serializationType;
    return $serializationType;
}

sub getSerializationUrl {
    my ( $self, $plotType ) = @_;
    my $file = $self->{_FILE};
    $file =~ s/\s//gi;

    my %serPlotType
        = map { $_ => 1 } qw(TIME_SERIES TIME_SERIES_GNU ZONAL_MEAN_GNU);
    return ( undef, undef ) unless exists $serPlotType{$plotType};
    my $rootPath = ( $0 =~ /(.+\/)(?:cgi-bin|bin)\/.+/ ? $1 : undef );
    my $cfgFile = $rootPath . 'cfg/giovanni/giovanni.cfg';

    # Read the configuration file
    my $cpt = Safe->new('GIOVANNI');
    unless ( $cpt->rdo($cfgFile) ) {
        exit_with_error('Configuration Error');
    }
    my $sessionRootPath = $GIOVANNI::SESSION_LOCATION;

    my $server = $ENV{'SERVER_NAME'};
    my $url    = "";
    $file =~ s/^$sessionRootPath//gi;
    chomp($file);
    my @parts = split( "\/", $file );
    my $len = @parts;
    $file = $parts[ $len - 1 ];
    $url  = "daac-bin/serializer.pl?SESSION=$parts[1]"
        . "&RESULTSET=$parts[2]&RESULT=$parts[3]&FILE=" . uri_escape($file);

    $file =~ s/\.nc$/\.csv/gi;
    $file =~ s/\.hdf$/\.csv/gi;

    return $url, $file;
}

################################################################################
sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    if ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE};
    }
    elsif ( $AUTOLOAD =~ /.*::getInputFile/ ) {
        return $self->{_INPUT_FILE};
    }
    elsif ( $AUTOLOAD =~ /.*::getOutputImageFormat/ ) {
        return $self->{_IMG_FORMAT};
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::Serializer - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Giovanni::Serializer;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Giovanni::Serializer, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Mahabaleshwara S. Hegde, E<lt>mhegde@localdomainE<gt>

=cut

