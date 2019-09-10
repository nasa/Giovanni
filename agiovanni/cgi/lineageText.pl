#!/usr/bin/perl -T

#$Id: lineageText.pl,v 1.6 2015/02/02 22:51:23 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

use strict;
use CGI;
use Safe;
use warnings;
use File::Temp qw/tempfile/;

# Establish the root path based on the script name
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}
$| = 1;

## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

use Giovanni::Util;
use Giovanni::CGI;

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Get the CGI object
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS =>
        [ 'session', 'result', 'resultset', 'step' ]
    ,
);

# get the parameters
my $step      = $cgi->param("step");
my $session   = $cgi->param("session");
my $result    = $cgi->param("result");
my $resultSet = $cgi->param("resultset");

# We need to build the session directory path
# This information is defined in giovanni.cfg
# For a personal session  -- $session/$resultSet/$result;
# this is where it goes -- $GIOVANNI::SESSION_LOCATION
# This is the relative url -- $URL_LOOKUP{'/var/giovanni/session'};
# => '/session'
# absolute url of the the session location
my $abs_url = $GIOVANNI::URL_LOOKUP{$GIOVANNI::SESSION_LOCATION};
my $dir     = "$GIOVANNI::SESSION_LOCATION/$session/$resultSet/$result";

# file for outputs
my $outFile = "$dir/lineageText.txt";
if ( -e $outFile ) {
    unlink($outFile);
}

# figure out if this is a windows browser
my $windowsSwitch = "";
my $agent         = $cgi->user_agent();
if ( defined($agent) ) {
    $agent = lc($agent);
    if ( $agent =~ /(.*windows.*)/ ) {
        $windowsSwitch = "--windowsOutput";
    }
}

# create the command string
my $cmd = "provenanceUrls.py --dir '$dir' --step '$step' --out '$outFile'";

my $keyStr = $GIOVANNI::SESSION_LOCATION . "=>"
    . Giovanni::Util::createAbsUrl($abs_url);
$cmd = "$cmd --lookup '$keyStr'";
$cmd = "$cmd $windowsSwitch";

my @out = `$cmd`;
my $ret = $?;
if ( $ret != 0 ) {
    print STDERR "Error: command '$cmd' returned non-zero";
    exit(1);
}
if ( !( -e $outFile ) ) {
    print STDERR "Error: command '$cmd' did not produce any output";
}

my $filename = $out[0];
Giovanni::Util::trim($filename);

print qq(Content-Disposition: attachment; filename="$filename"\n);
print "Content-type: text/plain\n\n";

open( FILE, "<", $outFile ) or die "Unable to open output file $outFile";
while ( my $line = <FILE> ) {
    print $line;
}
close(FILE);

=head1 NAME

lineageText.pl - this cgi script gets the outputs of a step and writes them out
as text

=head1 SYNOPSYS

perl -T -I /tools/gdaac/TS2/lib/perl5/site_perl/5.8.8 /tools/gdaac/TS2/cgi-bin/giovanni/lineageText.pl 'session=&result=&resultset=&step='

=head1 DESCRIPTION

Wraps provenanceUrls.py.

=head2 Parameters

=over 12

=item session

The the session directory name.

=item result

The result directory name.

=item resultset

The result set directory name.

=item step

The name of the step. E.g. - data_fetch

=back


=cut
