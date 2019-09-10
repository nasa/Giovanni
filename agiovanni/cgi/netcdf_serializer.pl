#!/usr/bin/perl -T

use strict;
use Safe;
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

# validate cgi parameters
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS => [ 'filename', 'session', 'resultset', 'result' ],
);

# get the parameters
my $file      = $cgi->param("filename");
my $session   = $cgi->param("session");
my $result    = $cgi->param("result");
my $resultSet = $cgi->param("resultset");

# build the file path
#$GIOVANNI::SESSION_LOCATION points to session directory
my $fullFile
    = "$GIOVANNI::SESSION_LOCATION/$session/$resultSet/$result/$file";

# check to make sure it exists
if ( !( -e $fullFile ) ) {
    print STDERR "Error: file does not exist ($fullFile)";
    exit(1);
}

# we are hard coding this for now to 7 digits
my $significantDigits = 7;

my $cmd
    = "$rootPath/bin/net_cdf_serializer.py --file $fullFile --significantDigits $significantDigits";

my $output = `$cmd 2>&1`;
my $ret    = $?;
if ( $ret != 0 ) {
    print STDERR "Error: command '$cmd' returned $ret: $output";
    exit(1);
}

print "Content-type: text/html\n\n";
print $output;

=head1 NAME

netcdf_serializer - this cgi script serializes a netcdf file in an aG session 
into json.

=head1 SYNOPSYS

perl -T I /tools/gdaac/TS2/lib/perl5/site_perl/5.8.8 /tools/gdaac/TS2/cgi-bin/giovanni/netcdf_serializer.pl 'session=&resultset=&filename=&variable=&variable=&'

=head1 DESCRIPTION

This script is essentailly a wrapper for 
gov.nasa.gsfc.giovanni.serializer.NetCdfSerializer.

=head2 Parameters

=over 12

=item session

The the session directory name.

=item result

The result directory name.

=item resultset

The result set directory name.

=item filename

The name of the file.

=back


=cut
