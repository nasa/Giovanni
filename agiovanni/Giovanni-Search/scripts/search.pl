#!/usr/bin/perl
#$Id: search.pl,v 1.11 2015/06/30 17:10:25 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

search - searches for data files

=head1 SYNOPSIS

  perl search.pl --outFile path/to/mfst.stuff.xml \
    --catalog /path/to/catalog.xml --missingUrl /path/to/missing/urls.txt \
    [--timeOut time_out_seconds]
    --stime '2000-01-01T00:00:00Z' --etime '2000-05-25T00:00:00Z'

=head1 DESCRIPTION

Seaches for data files. Command line options are:

1. outFile - the path to the search manifest file this command will create

2. catalog - location of the catalog/variable info file

3. missingUrl (optional) - location of the missing URL file

4. timeOut (optional) - time out in seconds for each search query

5. stime - start time for search

6. etime - end time for search

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
}

use 5.008008;
use strict;
use warnings;

use Giovanni::Search;
use Giovanni::Logger;
use Giovanni::Util;
use Getopt::Long;
use File::Basename;
use Date::Manip;

# get the command line options
my $catalog_file;
my $out_file;
my $help_flag;
my $missing_url;
my $time_out;
my $start_time;
my $end_time;

GetOptions(
    "catalog=s"    => \$catalog_file,
    "outFile=s"    => \$out_file,
    "missingUrl=s" => \$missing_url,
    "timeOut=s"    => \$time_out,
    "stime=s"      => \$start_time,
    "etime=s"      => \$end_time,
    "h"            => \$help_flag,
);

# if this is the help flag, print out the command line arguments
if ( defined($help_flag) ) {
    die "$0 --outFile 'path to output file' "
        . "--catalog 'variable info file' "
        . "--stime 'start time' "
        . "--etime 'end time'" . "["
        . "--missingUrl 'path to missing URL file' "
        . "--timeOut 'query time out (s)' " . "]";
}

# make sure that all the command line options are available
# check to make sure we got everything
if ( !defined($out_file) ) {
    die("Missing required option 'outFile'");
}
if ( !defined($catalog_file) ) {
    die("Missing required option 'catalog'");
}
if ( !defined($start_time) ) {
    die("Missing required option 'stime'");
}
if ( !defined($end_time) ) {
    die("Missing required option 'etime'");
}

$start_time =~ s/Z/T00:00:00Z/
    if index( $start_time, "Z" ) != -1 and index( $start_time, "T" ) == -1;
$end_time =~ s/Z/T23:59:59Z/
    if index( $end_time, "Z" ) != -1 and index( $end_time, "T" ) == -1;

if (   not( Date::Manip::ParseDate($start_time) )
    or not( Date::Manip::ParseDate($end_time) ) )
{
    die("Bad format for 'stime' or 'etime'");
}

# break up the output file into its name and directory
my ( $out_filename, $dir ) = fileparse($out_file);

my $logger = Giovanni::Logger->new(
    session_dir       => $dir,
    manifest_filename => $out_filename,
);

my %params = (
    session_dir => $dir,
    catalog     => $catalog_file,
    out_file    => $out_filename,
    logger      => $logger,
);

if ( defined($missing_url) ) {
    $params{'missing_url'} = $missing_url;
}
if ( defined($time_out) ) {
    $params{'time_out'} = $time_out;
}

# Read the LOGIN_CREDENTIALS configuration variable needed for
# downloading files that require authentication
my $cfgFile = ( defined $rootPath ? $rootPath : '/opt/giovanni4/' )
    . 'cfg/giovanni.cfg';
Giovanni::Util::ingestGiovanniEnv($cfgFile);
$params{'loginCredentials'} = $GIOVANNI::LOGIN_CREDENTIALS;

my $searcher = Giovanni::Search->new(%params);
$searcher->search( $start_time, $end_time );

1;
