#!/usr/bin/perl

# This script is an accessor for cfg/supported_browsers.xml
# It's sole purpose is to the read the file and transfer its
# contents to STDOUT.

use strict;
use warnings;

print "Content-Type: text/xml\n\n";

open( SUP_BROW, "../cfg/supported_browsers.xml" );
print $_ for <SUP_BROW>;
close(SUP_BROW);

