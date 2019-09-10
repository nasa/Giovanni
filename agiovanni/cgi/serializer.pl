#!/usr/bin/perl -T

# NOTE: This does not seem like a safe thing to have in OPS!
#use CGI::Carp qw(fatalsToBrowser);
use Safe;
use FindBin qw($Bin);
use File::Basename;
use strict;

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}
use Giovanni::Serializer;
use Giovanni::Serializer::TimeSeries;
use Giovanni::Util;
use Giovanni::CGI;

## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS => [ 'SESSION', 'RESULTSET', 'RESULT' ],
);

my $file = $cgi->param("FILE");
my $sessionIDs
    = $cgi->param("SESSION") . '/'
    . $cgi->param("RESULTSET") . "/"
    . $cgi->param("RESULT");

my $fileType;
my $fullSessionPath;

if ( !defined($file) ) {        # then we ony have one input parm:

    # The InTs case 'looksfor' the mfst.combine rather than being given a
    # single file as in other cases
    print STDERR
        "WARNING: FILE is required for processing EXCEPT for InTs (interannual/seasonal time series) case";
    $fileType        = 'ints';
    $fullSessionPath = $sessionIDs;
}
else {

    # figure out what kind of serialization we are doing
    if ( $file =~ /^.*?[.](.*?)[.]/ ) {
        $fileType = $1;
    }
    else {
        print STDERR
            "Unable to parse filename to determine serialization type: $file";
        print $cgi->header(
            -type   => 'text/plain',
            -status => "500 data ERROR"
        );
        exit(1);
    }
}

my $fileRootPath = $GIOVANNI::SESSION_LOCATION;
$file = "$fileRootPath/$sessionIDs/$file";
print STDERR "INFO: Serializer Input File = $file \n";
my $downloadContent;

# build the working directory path
my $workingDir = "$GIOVANNI::SESSION_LOCATION/$sessionIDs/";

# build the input.xml path
my $inputXmlFile = "$workingDir/input.xml";

my $csvFile;
if ( $fileType eq 'zonalMean' || $fileType eq 'dimensionAveraged' ) {

    # zonal mean
    my $cmd = "serialize_zonal_mean.py $inputXmlFile $file $workingDir";
    my @out = `$cmd`;
    if ( $? == 0 ) {
        $csvFile = $out[0];
    }
}
elsif ($fileType eq 'areaAvgDiffTimeSeries'
    || $fileType eq 'areaAvgTimeSeries' )
{

    # time series
    $csvFile = Giovanni::Serializer::TimeSeries::serialize(
        input  => $inputXmlFile,
        ncFile => $file,
        outDir => $workingDir
    );
}
elsif ( $fileType eq 'ints' ) {

    #interannual time series
    if ( $fullSessionPath =~ /([A-Za-z0-9\-\:\/]+)/ ) {
        my $sessionDir = "$GIOVANNI::SESSION_LOCATION/$1/";
        my $cmd        = "serialize_ints.py $sessionDir";
        my @out        = `$cmd`;
        if ( $? == 0 ) { $csvFile = $out[0]; }
        $file = $csvFile;
        $file =~ s/\.csv$//;
    }
    else {
        print STDERR "session path not parsed";
        print $cgi->header(
            -type   => 'text/plain',
            -status => "404 data ERROR"
        );
        exit(1);
    }

}
else {
    print STDERR
        "File does not appear to be either a time series, InTs,  or a zonal mean: $file";
    print $cgi->header(
        -type   => 'text/plain',
        -status => "404 CSV file not created"
    );
    exit(1);
}

$downloadContent = Giovanni::Util::readFile($csvFile);

#### to compose an ascii file name
my $fileName = $file;
my @fa       = split( /\//, $fileName );
my $len      = @fa;
$fileName = $fa[ $len - 1 ];
$fileName =~ s/.nc$//i;
$fileName =~ s/.hdf$//i;
$fileName .= ".csv";
my $outType = "text/csv";

# Do we have output?
if ( $downloadContent eq "" ) {

    print $cgi->header(
        -type   => 'text/plain',
        -status => "404 file not created"
    );

}
else {

    print $cgi->header(
        -status                => 200,
        -type                  => $outType,
        -'Content-Disposition' => 'attachment; filename="' . $fileName . '"'
    );

    print $downloadContent;
}

=head1 NAME

serliazer.pl - serialize data series to csv.

=head1 SYNOPSYS

perl -T /opt/giovanni4/cgi-bin/serializer.pl "SESSION=3F530E84-18AA-11E9-A809-B83EE70C10F0&RESULTSET=6A19C766-18B9-11E9-9E3D-B71BE70C10F0&RESULT=6A1AE448-18B9-11E9-9E3D-B71BE70C10F0"
perl -T /opt/giovanni4/cgi-bin/serializer.pl "SESSION=C4E9188C-1903-11E9-BCEC-E63FE70C10F0&RESULTSET=2E931332-1904-11E9-9BD4-8708E70C10F0&RESULT=2E978822-1904-11E9-9BD4-8708E70C10F0&FILE=g4.areaAvgTimeSeries.M2TMNXFLX_5_12_4_PRECTOT.19810101-20181231.19W_64N_17W_66N.nc"
perl -T /opt/giovanni4/cgi-bin/serializer.pl "SESSION=6FF4CDE6-18F2-11E9-9B7F-DE9DE70C10F0&RESULTSET=DDEDEA3C-18F5-11E9-A925-2C79E70C10F0&RESULT=DDF11BF8-18F5-11E9-A925-2C79E70C10F0&FILE=g4.zonalMean.OMAERUVd_003_UVAerosolIndex.20050101-20181231.38E_29N_48E_37N.nc"

=head1 DESCRIPTION

Returns the csv representation of the data.
  

=head2 Parameters

=over 12

=item FILE

The file being serialized. Required for all services except seasonal time
seriesl (area-averaged time series, difference time series, 
zonal mean, and dimension averaged).

=item SESSION

Session UUID

=item RESULTSET

Resultset UUID

=item RESULT

Result UUID

=back


=cut
