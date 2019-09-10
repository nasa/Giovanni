#!/usr/bin/env perl

#$Id: getDataFieldInfo.t,v 1.7 2014/02/13 15:28:04 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

use Test::More tests => 9;
use File::Temp;
use FindBin;

$ENV{PERL5LIB}
    = "../Giovanni-Catalog/lib:../Giovanni-DataField/lib:../Giovanni-BoundingBox/lib:../Giovanni-Util/lib:../Giovanni-Scrubber/lib:../Giovanni-Data-NcFile/lib:../Giovanni-ScienceCommand/lib:../Giovanni-WorldLongitude/lib:../Giovanni-Logger/lib";


my $script = find_script("getDataFieldInfo.pl");
my $aesirCatalog
    = defined $ENV{AESIR}
    ? $ENV{AESIR}
    : "http://aesir.gesdisc.eosdis.nasa.gov/aesir_solr/TS1/";

# Temporary workspace
ok( -f $script, "Script found" );
my $varInfoFile = "./varInfo.xml";
unlink $varInfoFile if ( -f $varInfoFile );

# Try to get info for data fields that do exist using input.xml
my $inXmlFileContent = <<INPUT_CONTENT;
<input>
 <data>OMAERUVd_003_FinalAerosolSingleScattAlb388</data>
 <data>iAIRX3STD_006_SurfSkinTemp_A</data>
</input>
INPUT_CONTENT
my ( $tempFH, $tempFile ) = File::Temp::tempfile( 'XXXX', UNLINK => 1 );
print $tempFH $inXmlFileContent;
close($tempFH);
$out
    = `$script --in-xml-file $tempFile --aesir "$aesirCatalog" --datafield-info-file $varInfoFile 2>&1`;
is( $? >> 8, 0, "Case of existing data fields: command ran successfully" );
$logFile = $varInfoFile;
$logFile =~ s/\.xml/\.log/;

# Make sure variable info file was not created
ok( -f $varInfoFile,
    "Case of existing data fields: data field info file created as expected"
);
ok( -f $logFile, "Case of existing data fields: log file found" );
my $msg = `grep "Found 1 variable" $logFile`;
is( $? >> 8, 0, "Case of existing data fields: found 1 variable" );
unlink $varInfoFile if ( -f $varInfoFile );

unlink $logFile if ( -f $logFile );

# Try to get the info for a non-existent variable
$inXmlFileContent = <<INPUT_CONTENT;
<input><data>xyz</data></input>
INPUT_CONTENT
my ( $tempFH, $tempFile ) = File::Temp::tempfile( 'XXXX', UNLINK => 1 );
print $tempFH $inXmlFileContent;
close($tempFH);
$out
    = `$script --in-xml-file $tempFile --aesir "$aesirCatalog" --datafield-info-file $varInfoFile 2>&1`;

# Test whether the command failed
is( $? >> 8, 2,
    "Case of non-existent data fields: couldn't find info as expected" );
ok( !( -f $varInfoFile ),
    "Case of non-existent data fields: data field info file not created as expected"
);
ok( -f $logFile, "Case of non-existent data fields: log file found" );
my $msg = `grep "Could not find" $logFile`;
is( $? >> 8, 0, "Case of non-existent data fields: found 0 variable" );

# Tries to find the script relative to the current location.
sub find_script {
    my ($scriptName) = @_;

    # see if we can find the script relative to our current location
    my $script = "blib/script/$scriptName";
    foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
        next if ( $dir =~ /^\s*$/ );
        last if ( -f $script );
        $script = "../$script";
    }

    unless ( -f $script ) {

        # see if this is just next door (Christine's eclipse configuration)
        $script = "../scripts/$scriptName";
    }

    return $script;
}
