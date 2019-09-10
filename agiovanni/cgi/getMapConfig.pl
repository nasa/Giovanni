#!/usr/bin/perl -T

# This script is an accessor for cfg/map_config.json.

use strict;
use warnings;

print "Content-Type: application/json\n\n";

open( CONFIG, "../cfg/map_config.json" );
print $_ for <CONFIG>;
close(CONFIG);

