# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Visualizer-GrADSMap.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
use File::Basename;
use File::Temp qw/tempfile  tempdir/;
BEGIN { use_ok('Giovanni::Visualizer::ContourMap') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $fileDir = dirname($0);
my $dataFile = $fileDir . "/test.nc";
my $tempDir = tempdir( CLEANUP => 1 );
my($fh, $fileName) = tempfile(DIR => $tempDir);
my $contourFile = Giovanni::Visualizer::ContourMap::contourMap (
    $dataFile,
    (OUTFILE => $fileName)
);
ok( -e $contourFile, "Make contour file $contourFile" );

my($fh, $fileName) = tempfile(DIR => $tempDir);
my $contourFile = Giovanni::Visualizer::ContourMap::contourMap (
    $dataFile,
    (OUTFILE => $fileName,
     INTERVAL => 10
    )
);
ok( -e $contourFile, "Make contour file $contourFile" );

my($fh, $fileName) = tempfile(DIR => $tempDir);
my $contourFile = Giovanni::Visualizer::ContourMap::contourMap (
    $dataFile,
    (OUTFILE => $fileName,
     LEVELS => 8,
     MIN => 8,
     MAX => 96
    )
);
ok( -e $contourFile, "Make contour file $contourFile" );

my @values = (10,20,30,40,50,60,70,80);
my($fh, $fileName) = tempfile(DIR => $tempDir);
my $contourFile = Giovanni::Visualizer::ContourMap::contourMap (
    $dataFile,
    (OUTFILE => $fileName,
     VALUES => \@values
    )
);
ok( -e $contourFile, "Make contour file $contourFile" );
