#$Id: combineFileManifests.t,v 1.2 2015/02/20 17:19:46 rstrub Exp $
#-@@@ Giovanni, Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-CombineManifests.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use File::Temp 'tempdir';
use Giovanni::Logger;
use FindBin qw($Bin);

# find the script
my $script = find_script("combineFileManifests.pl");
ok( -r $script, "Found script" );

# create a temporary directory for the test
my $dir = tempdir( CLEANUP => 1 );

my $manifestStr1 = <<MANIFEST1;
<manifest>
  <fileList>
    <file>
      /home/csmit/workflows/quasi_climatology/session/timeAvg.TRMM_3B43_007_precipitation.20030101-20041231.180W_50S_180E_50N.MONTH_01.nc
    </file>
  </fileList>
</manifest>
MANIFEST1
my $manifestFile1
    = "$dir/mfst.world+sQuCl+dTRMM_3B43_007_precipitation+zNA+t20030101000000_20041231235959+b180.0000W_50.0000S_180.0000E_50.0000N+gMONTH_01.xml";
open( FILE, ">", $manifestFile1 ) or die "Unable to open file $manifestFile1";
print FILE $manifestStr1;
close(FILE);

my $manifestStr2 = <<MANIFEST2;
<manifest>
  <fileList>
    <file>
      /home/csmit/workflows/quasi_climatology/session/timeAvg.TRMM_3B43_007_precipitation.20030101-20041231.180W_50S_180E_50N.MONTH_02.nc
    </file>
  </fileList>
</manifest>
MANIFEST2
my $manifestFile2
    = "$dir/mfst.world+sQuCl+dTRMM_3B43_007_precipitation+zNA+t20030101000000_20041231235959+b180.0000W_50.0000S_180.0000E_50.0000N+gMONTH_02.xml";
open( FILE, ">", $manifestFile2 ) or die "Unable to open file $manifestFile2";
print FILE $manifestStr2;
close(FILE);

my $outFile
    = "$dir/mfst.combined+sQuCl+dTRMM_3B43_007_precipitation+zNA+t20030101000000_20041231235959+b180.0000W_50.0000S_180.0000E_50.0000N+gMONTH_01_02.xml";

# build and run command
my $cmd = "$script $outFile $manifestFile1 $manifestFile2";
my $ret = system($cmd);

# check return value
is( $ret, 0, "Command returned zero: $cmd" );

# check we got the output file
ok( -f $outFile, "Output file exists" ) or die $!;

# and that the output file is correct
my $correctOutput = <<OUT;
<?xml version="1.0"?>
<manifest><fileList>
    <file>
      /home/csmit/workflows/quasi_climatology/session/timeAvg.TRMM_3B43_007_precipitation.20030101-20041231.180W_50S_180E_50N.MONTH_01.nc
    </file>
  </fileList><fileList>
    <file>
      /home/csmit/workflows/quasi_climatology/session/timeAvg.TRMM_3B43_007_precipitation.20030101-20041231.180W_50S_180E_50N.MONTH_02.nc
    </file>
  </fileList></manifest>
OUT

my $parser = XML::LibXML->new();
my $dom    = $parser->parse_file($outFile);
is( $dom->toString(), $correctOutput, "Output is correct" );

sub find_script {
    my ($scriptName) = @_;

    # see if this is just next door (Christine's eclipse
    # configuration)
    my $script = "../scripts/$scriptName";

    if ( !( -f $script ) ) {

        # see if we can find the script relative to our current location
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }
    return $script;
}
