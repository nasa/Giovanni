# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Classify.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 18;
use File::Temp qw/tempdir/;
use List::MoreUtils qw/uniq/;
BEGIN { use_ok('Giovanni::Classify') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $month
    = Giovanni::Classify::getMonth(
    "/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000201.nc"
    );

is( $month, '02', "getMonth(GSSTF)" );
$month
    = Giovanni::Classify::getMonth(
    "/var/tmp/www/TS2/giovanni/CC4AC562-A247-11E4-9861-916F64A9FDC9/D2D14F14-A247-11E4-A6FF-A16F64A9FDC9/D2D16A4E-A247-11E4-A6FF-A16F64A9FDC9//scrubbed.GPM_3IMERGM_03_precipitation.20140701000000.nc"
    );
is( $month, '07', "getMonth(IMERG)" );

$month
    = Giovanni::Classify::getMonth(
    "/giovanni/OPS/session/6D1796C4-B87C-11E4-9973-CD79B99AA582/117D94B0-B87E-11E4-A8BD-FB128F859CF7/117D9EE2-B87E-11E4-BDB5-82E449012FFD//scrubbed.NLDAS_NOAH0125_M_002_cnwatsfc.19790101T0000.nc"
    );
is( $month, '01', "getMonth(NLDAS)" );

# create a temporary session directory
my $sessionDir = tempdir();

# write an input manifest file with 12 month files
my $inputXML = <<'XML';
<?xml version="1.0"?>
<manifest>
	<fileList id="GSSTFM_3_SET1_INT_E">
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000101.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000201.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000301.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000401.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000501.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000601.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000701.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000801.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000901.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20001001.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20001101.nc
		</file>
		<file>/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20001201.nc
		</file>
	</fileList>
</manifest>
XML
my $inputManifest
    = write_manifest( "$sessionDir/mfst.input+whatever.xml", $inputXML );

# call classify
my $outputManifest = "$sessionDir/mfst.output+seasonal.xml";
Giovanni::Classify::classify_seasons(
    INPUT  => $inputManifest,
    OUTPUT => $outputManifest,
);

ok( -f $outputManifest, "Output file exists" );

my $doc    = Giovanni::Util::parseXMLDocument($outputManifest);
my @nodes  = $doc->findnodes(qq(/manifest/fileList/file/\@group));
my @groups = uniq( map( $_->nodeValue, @nodes ) );
is_deeply( \@groups, [ "DJF", "MAM", "JJA", "SON" ], "Correct groups" );

@nodes = $doc->findnodes(qq|/manifest/fileList/file[\@group="DJF"]/text()|);
my @files = map( $_->nodeValue, @nodes );
is_deeply(
    \@files,
    [   "/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000101.nc",
        "/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000201.nc",
        "/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20001201.nc"
    ],
    "Correct DJF files"
);

@nodes = $doc->findnodes(qq|/manifest/fileList/file[\@group="MAM"]/text()|);
@files = map( $_->nodeValue, @nodes );
is_deeply(
    \@files,
    [   "/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000301.nc",
        "/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000401.nc",
        "/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000501.nc"
    ],
    "Correct MAM files"
);

# call classify for monthly
$outputManifest = "$sessionDir/mfst.output+monthly.xml";

Giovanni::Classify::classify_months(
    INPUT  => $inputManifest,
    OUTPUT => $outputManifest,
);

ok( -f $outputManifest, "Output file exists" );

$doc    = Giovanni::Util::parseXMLDocument($outputManifest);
@nodes  = $doc->findnodes(qq(/manifest/fileList/file/\@group));
@groups = uniq( map( $_->nodeValue, @nodes ) );
is_deeply(
    \@groups,
    [   "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"
    ],
    "Correct groups"
);

@nodes = $doc->findnodes(qq|/manifest/fileList/file[\@group="09"]/text()|);
@files = map( $_->nodeValue, @nodes );
is_deeply(
    \@files,
    [   "/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20000901.nc"
    ],
    "Correct 09 file"
);

@nodes = $doc->findnodes(qq|/manifest/fileList/file[\@group="11"]/text()|);
@files = map( $_->nodeValue, @nodes );
is_deeply(
    \@files,
    [   "/var/tmp/www/TS2/giovanni/A23EA1E6-1BEB-11E3-91CD-A4997F7E30AE/A457FBBC-1BEB-11E3-A79C-549A7F7E30AE/A4581F70-1BEB-11E3-A79C-549A7F7E30AE//scrubbed.GSSTFM_3_SET1_INT_E.20001101.nc"
    ],
    "Correct 11 file"
);
$inputXML = <<'XML2';
<?xml version="1.0"?>
<manifest>
  <fileList id="GPM_3IMERGM_03_precipitation">
    <file>/var/tmp/www/TS2/giovanni/CC4AC562-A247-11E4-9861-916F64A9FDC9/D2D14F14-A247-11E4-A6FF-A16F64A9FDC9/D2D16A4E-A247-11E4-A6FF-A16F64A9FDC9//scrubbed.GPM_3IMERGM_03_precipitation.20140501000000.nc</file>
    <file>/var/tmp/www/TS2/giovanni/CC4AC562-A247-11E4-9861-916F64A9FDC9/D2D14F14-A247-11E4-A6FF-A16F64A9FDC9/D2D16A4E-A247-11E4-A6FF-A16F64A9FDC9//scrubbed.GPM_3IMERGM_03_precipitation.20140601000000.nc</file>
    <file>/var/tmp/www/TS2/giovanni/CC4AC562-A247-11E4-9861-916F64A9FDC9/D2D14F14-A247-11E4-A6FF-A16F64A9FDC9/D2D16A4E-A247-11E4-A6FF-A16F64A9FDC9//scrubbed.GPM_3IMERGM_03_precipitation.20140701000000.nc</file>
    <file>/var/tmp/www/TS2/giovanni/CC4AC562-A247-11E4-9861-916F64A9FDC9/D2D14F14-A247-11E4-A6FF-A16F64A9FDC9/D2D16A4E-A247-11E4-A6FF-A16F64A9FDC9//scrubbed.GPM_3IMERGM_03_precipitation.20140801000000.nc</file>
  </fileList>
</manifest>
XML2

$inputManifest
    = write_manifest( "$sessionDir/mfst.input+imerg.xml", $inputXML );

$outputManifest = "$sessionDir/mfst.output+monthly.xml";
Giovanni::Classify::classify_months(
    INPUT  => $inputManifest,
    OUTPUT => $outputManifest,
);
ok( -f $outputManifest, "Output file exists" );

$doc    = Giovanni::Util::parseXMLDocument($outputManifest);
@nodes  = $doc->findnodes(qq(/manifest/fileList/file/\@group));
@groups = uniq( map( $_->nodeValue, @nodes ) );
is_deeply( \@groups, [ "05", "06", "07", "08" ], "Correct groups" );

@nodes = $doc->findnodes(qq|/manifest/fileList/file[\@group="06"]/text()|);
@files = map( $_->nodeValue, @nodes );
is_deeply(
    \@files,
    [   "/var/tmp/www/TS2/giovanni/CC4AC562-A247-11E4-9861-916F64A9FDC9/D2D14F14-A247-11E4-A6FF-A16F64A9FDC9/D2D16A4E-A247-11E4-A6FF-A16F64A9FDC9//scrubbed.GPM_3IMERGM_03_precipitation.20140601000000.nc",
    ],
    "Correct 06 file"
);

# classify seasons
# call classify
$outputManifest = "$sessionDir/mfst.output2+seasonal.xml";
Giovanni::Classify::classify_seasons(
    INPUT  => $inputManifest,
    OUTPUT => $outputManifest,
);

ok( -f $outputManifest, "Output file exists" );

my $doc    = Giovanni::Util::parseXMLDocument($outputManifest);
my @nodes  = $doc->findnodes(qq(/manifest/fileList/file/\@group));
my @groups = uniq( map( $_->nodeValue, @nodes ) );
is_deeply( \@groups, [ "MAM", "JJA" ], "Correct groups" );

@nodes = $doc->findnodes(qq|/manifest/fileList/file[\@group="JJA"]/text()|);
my @files = map( $_->nodeValue, @nodes );
is_deeply(
    \@files,
    [   "/var/tmp/www/TS2/giovanni/CC4AC562-A247-11E4-9861-916F64A9FDC9/D2D14F14-A247-11E4-A6FF-A16F64A9FDC9/D2D16A4E-A247-11E4-A6FF-A16F64A9FDC9//scrubbed.GPM_3IMERGM_03_precipitation.20140601000000.nc",
        "/var/tmp/www/TS2/giovanni/CC4AC562-A247-11E4-9861-916F64A9FDC9/D2D14F14-A247-11E4-A6FF-A16F64A9FDC9/D2D16A4E-A247-11E4-A6FF-A16F64A9FDC9//scrubbed.GPM_3IMERGM_03_precipitation.20140701000000.nc",
        "/var/tmp/www/TS2/giovanni/CC4AC562-A247-11E4-9861-916F64A9FDC9/D2D14F14-A247-11E4-A6FF-A16F64A9FDC9/D2D16A4E-A247-11E4-A6FF-A16F64A9FDC9//scrubbed.GPM_3IMERGM_03_precipitation.20140801000000.nc",
    ],
    "Correct MAM files"
);
exit(0);

sub write_manifest {
    my ( $file, $text ) = @_;
    open( INPUT, ">", $file );
    print INPUT $text;
    close(INPUT);
    return $file;
}
