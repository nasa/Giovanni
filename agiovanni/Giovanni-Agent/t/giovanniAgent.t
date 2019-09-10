#!/usr/bin/env perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Agent.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Giovanni::Agent') }

use File::Temp qw/ tempdir /;
use FindBin;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $script = findScript('giovanniAgent.pl');
ok( -r $script, "Found script" )
    or die "Unable to find giovanniAgent.pl script";

# run a command that should succeed
my $dir = tempdir();
my $cmd
    = "$script "
    . "--url 'http://giovanni.gsfc.nasa.gov/giovanni/#service=TmAvMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T23:59:59Z&bbox=-180,-50,180,50&data=TRMM_3B42_Daily_7_precipitation&dataKeyword=TRMM' "
    . "--dir $dir --debug --type 'data' --type 'lineage_xml' --max-time 360";

my $ret = system($cmd);
ok( $ret == 0, "Command returned zero...This works better after running make install" )
    or die "Unable to run basic giovanniAgent.pl request.";
ok( -e "$dir/g4.timeAvgMap.TRMM_3B42_Daily_7_precipitation.20030101-20030101.180W_50S_180E_50N.nc",
    "Downloaded output file"
);
ok( -e "$dir/lineage.xml", "Downloaded lineage xml file" );

# run a command that should time out trying to run the request
$cmd
    = "$script "
    . "--url 'http://giovanni.gsfc.nasa.gov/giovanni/#service=TmAvMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T23:59:59Z&bbox=-180,-50,180,50&data=TRMM_3B42_Daily_7_precipitation&dataKeyword=TRMM' "
    . "--dir $dir --debug --type 'data' --type 'lineage_xml' --max-time 1";

$ret = system($cmd);
ok( $ret != 0, "Command failed" );

sub findScript {
    my ($scriptName) = @_;

    # see if we can find the script relative to our current location
    my $script = "$scriptName";
    #foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
    foreach my $dir ( split( /:/, $ENV{PATH}  ) ) {
        next if ( $dir =~ /^\s*$/ );
        if ( -f "$dir/$script" ) {
           $script = "$dir/$script";
           return $script;
        }
        $script = "../$script";
    }

    unless ( -f $script ) {

        # see if this is just next door (Christine's eclipse configuration)
        $script = "../scripts/$scriptName";
    }

    return $script;
}
