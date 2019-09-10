#########################
#$Id: Giovanni-Logger-Algorithm.t,v 1.1 2015/04/14 21:01:20 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# This file tests the logging aspects of Giovanni::Logger.

use strict;

use Test::More tests => 2;
BEGIN { use_ok('Giovanni::Logger::Algorithm') }

#########################

# Tests the Giovanni::Logger::Algorithm

# get a logging object
my $util = Giovanni::Logger::Algorithm->new( start_percent => 50 );

# capture stderr in $stderrStuff
my $stderrStuff;
close(STDERR);
open( STDERR, ">", \$stderrStuff );

# different messages
$util->user_msg("user message");
$util->info("info message");
$util->debug("debug message");
$util->warning("warning message");
$util->error("error message");
$util->user_error("user error message");
$util->percent_done(50);

my $correctStderrStuff = <<CORRECTOUT;
USER_INFO user message
INFO info message
DEBUG debug message
WARN warning message
ERROR error message
USER_ERROR user error message
PERCENT_DONE 75
CORRECTOUT

is( $stderrStuff, $correctStderrStuff, "Got the right output" );

