#!/usr/bin/perl -T

use Safe;
use strict;
use warnings;

# Establish the root path based on the script name
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}
$| = 1;

# Following packages should be used after @INC is set above
use Giovanni::Util;
use Giovanni::CGI;

## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Validate CGI parameters
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS =>
        [ 'filename', 'session', 'result', 'resultset' ]
    ,
);

# Get the parameters
my $file      = $cgi->param("filename");
my $session   = $cgi->param("session");
my $result    = $cgi->param("result");
my $resultSet = $cgi->param("resultset");

# Build the file path
#$GIOVANNI::SESSION_LOCATION points to session directory
my $fullFile = "$GIOVANNI::SESSION_LOCATION/$session/$resultSet/$result/$file"
    ;

# Check to make sure it exists
if ( !( -e $fullFile ) ) {
    print STDERR "Error: file does not exist ($fullFile)\n";
    exit(1);
}

my $headerCommand = "ncdump-json -j -h $fullFile";
my $header        = `$headerCommand 2>&1`;
my $status        = $?;
if ($status) {
    print STDERR
        "Error: command '$headerCommand' returned $status: $header\n";
    exit(1);
}
chomp($header);

# Eliminate 'f' from the termination of floating point value strings
# (any string that begins with ':', followed by 0 or more spaces,
# followed by optional '+' or '-', followed by 1 or more digits,
# followed by a decimal point, followed by zero or more digits,
# optionally followed by an exponent, followed by 'f',
# e.g. ': 123.45f', ': -12.f', ': 0.f'.
$header =~ s/(:\s*[+-]?\d+\.\d*([eE][+-]\d+)?)f/$1/g;

# The preceding step did not include floating point values within arrays.
# Eliminate 'f' from the termination of floating point values in arrays
# in a similar fashion.
# First find all arrays (starting with '[' and ending with ']') that
# contain 1 or more floating pint values terminated with 'f'.
my @fpArrays = $header =~ /(\[(?:[+-]?\d+\.\d*(?:[eE][+-]\d+)?f,?)+\])/g;
foreach my $fpArray (@fpArrays) {

    # Remove trailing 'f' from each value in the array
    ( my $replacement = $fpArray ) =~ s/([+-]?\d+\.\d*([eE][+-]\d+)?)f/$1/g;
    my $qfpArray = quotemeta($fpArray);
    $header =~ s/$qfpArray/$replacement/g;
}

# Eliminate decimal points followed by 0 digits
$header =~ s/(:\s*[+-]?\d+)\.,/$1,/g;

# Similarly, eliminate 's' and 'l' for short and long types
$header =~ s/(:\s*[+-]{0,1}\d+)[sl]/$1/g;

my $dataCommand = "ncdump-json -j $fullFile";
my $data        = `$dataCommand 2>&1`;
$status = $?;
if ($status) {
    print STDERR "Error: command '$dataCommand' returned $status: $data\n";
    exit(1);
}
chomp($data);

my $output = '{"header":' . $header . ',"data":' . $data . '}';

print "Content-type: application/json\n\n";
print $output;

=head1 NAME

netcdf_serializer - this cgi script serializes a netcdf file in an aG session
into json.

=head1 SYNOPSIS

perl -T -I /tools/gdaac/TS2/lib/perl5/site_perl/5.8.8 /tools/gdaac/TS2/cgi-bin/giovanni/netcdf_json_serializer.pl 'session=&resultset=&result=&filename=&variable=&variable=&'

=head1 DESCRIPTION

This script is essentailly a wrapper for ncdump-json.

=head2 Parameters

=over 12

=item session

The session directory name.

=item result

The result directory name.

=item resultset

The result set directory name.

=item filename

The name of the file.

=back

=cut
