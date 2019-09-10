#########################
#$Id: classify_seasonmonth.t,v 1.3 2014/01/21 20:14:02 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# This file test classify_seasonmonth.pl

use File::Temp qw/ tempfile tempdir /;

use strict;
use warnings;
use FindBin qw($Bin);

use Test::More tests => 4;

#########################

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
my $inputManifest = "$sessionDir/mfst.input+whatever.xml";
open( INPUT, ">", $inputManifest );
print INPUT $inputXML;
close(INPUT);

my $script = findScript("classify_seasonmonth.pl");

# build the command
my $outputManifest = "$sessionDir/mfst.output+season.xml";

my $cmd = "$script --in-file $inputManifest --out-file $outputManifest"
    . " --group-type SEASON";
my $ret = system($cmd);

is( $ret, 0, "Command returned 0" );
ok( -f $outputManifest, "Ouput manifest exists" );

# build the monthly command
$outputManifest = "$sessionDir/mfst.output+month.xml";
$cmd = "$script --in-file $inputManifest --out-file $outputManifest"
    . " --group-type MONTH";
$ret = system($cmd);

is( $ret, 0, "Command returned 0: $cmd" );
ok( -f $outputManifest, "Ouput manifest exists" );

sub findScript {
    my ($scriptName) = @_;

    # see if this is just next door (Christine's eclipse configuration)
    my $script = "../scripts/$scriptName";

    unless ( -f $script ) {

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

1;
