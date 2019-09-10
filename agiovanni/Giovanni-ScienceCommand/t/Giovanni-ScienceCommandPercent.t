#$Id: Giovanni-ScienceCommandPercent.t,v 1.3 2013/05/28 19:36:43 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# This file tests the command line call Giovanni::ScienceCommand where the
# exec specifies percent done.

use File::Temp qw/ tempfile tempdir /;
use strict;

use Test::More tests => 5;
BEGIN { use_ok('Giovanni::Logger') }
BEGIN { use_ok('Giovanni::ScienceCommand') }

# create a temp file with the messages we want to pick up on stderr
my $tempDir = tempdir( "session_XXXX", CLEANUP => 1 );
my $tempFile = "$tempDir/messages.txt";

open( TEMPFILE, ">$tempFile" );
print TEMPFILE <<STRING;
PERCENT_DONE 5
PERCENT_DONE 100
STRING
close(TEMPFILE);

# we're just going to echo this file to stderr
my $cmd = "cat $tempFile 1>&2";

# get a logging object
my $logger = Giovanni::Logger->new(
    session_dir       => $tempDir,
    manifest_filename => "mfst.Test+stuff.xml"
);
my $util = Giovanni::ScienceCommand->new(
    sessionDir => $tempDir,
    logger     => $logger
);

$util->exec( $cmd, 50, 60 );

# read out the messages in the log file
open LOGFILE, "<", "$tempDir/mfst.Test+stuff.log" or die $!;
my @messages = <LOGFILE>;
close LOGFILE;

my $i = 0;
ok( $messages[ $i++ ] =~ /\[INFO \] - Test - About to run command "$cmd"/,
    "about to run command" );
ok( $messages[ $i++ ] =~ /\[INFO \] - Test - PERCENT_DONE 50.5/,
    "percent done message" );
ok( $messages[ $i++ ] =~ /\[INFO \] - Test - PERCENT_DONE 60/,
    "percent done message" );

1;

