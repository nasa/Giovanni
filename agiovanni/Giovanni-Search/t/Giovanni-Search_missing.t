# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Search.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Giovanni::Search') }

#########################

use strict;
use File::Temp qw/ tempfile tempdir /;
use File::Basename;
use XML::LibXML;

# setup some directories
 my $dir = tempdir( CLEANUP => 1 );
 my $workingDir = "$dir/working";
 mkdir($workingDir) or die "Unable to make directory $workingDir, $!";

my $catalogFile = $workingDir . "/" . "catalog.xml";
open( VARFILE, ">$catalogFile" )
    or die("unable to create/open catalog file $catalogFile, $!");
print VARFILE <<VARINFO;
<varList>
  <var id="OMAERUVd_003_FinalAerosolAbsOpticalDepth500">
    <slds>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_greys_9_sld.xml" label="Greys, Light to Dark (Seq), 9"/>
      <sld url="http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/buylrd_div_11_sld.xml" label="Blue-Yellow-Red (Div), 11"/>
    </slds>
  </var>
</varList>
VARINFO
close(VARFILE) or die("unable to close catalog file $catalogFile");

# create a temporary file with missing URLs
my ( $tmpNcHandle, $tmpNcFile )
    = File::Temp::tempfile( "missing_XXXX", SUFFIX => ".txt", UNLINK => 1 );


my $missing = <<MISSING;
http://missing.com
http://something.not.real.com
http://another.com
MISSING

print $tmpNcHandle $missing;
close($tmpNcHandle);

# create a list of urls
my $urls = [
    { url => "http://not.com" },
    { url => "http://whatever.com" },
    { url => "http://another.com" },
    { url => "http://missing.com" },
    { url => "http://one.com" }
];

my $search = Giovanni::Search->new(session_dir  => $workingDir,
                                   catalog      => $catalogFile,
                                   missing_url  => $tmpNcFile,
                                   out_file     => "search.log");
# call to remove missing
my (@filter) = $search->_checkMissingUrls( $urls );

is_deeply( scalar @$urls, 3, "Got the right URLs" );

