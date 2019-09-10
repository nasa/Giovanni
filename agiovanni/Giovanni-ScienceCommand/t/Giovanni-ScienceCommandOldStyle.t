#$Id: Giovanni-ScienceCommandOldStyle.t,v 1.1 2013/08/06 18:05:36 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# This file tests the old style command line call Giovanni::ScienceCommand

use File::Temp qw/ tempfile tempdir /;

use strict;

use Test::More tests => 8;
BEGIN { use_ok('Giovanni::Logger') }
BEGIN { use_ok('Giovanni::ScienceCommand') }

# create a temp file with the messages we want to pick up on stderr
my $tempDir = tempdir( "session_XXXX", CLEANUP => 1 );
my $tempFile = "$tempDir/messages.txt";

open( TEMPFILE, ">$tempFile" );
print TEMPFILE <<STRING;
first message
second message
WARN warning message
STRING
close(TEMPFILE);

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

my ($outfiles_ref) = $util->execOldStyle($cmd);

is( scalar( @{$outfiles_ref} ), 0, "no output files" );

# read out the messages in the log file
open LOGFILE, "<", "$tempDir/mfst.Test+stuff.log" or die $!;
my @messages = <LOGFILE>;
close LOGFILE;

my $i = 0;
like(
    $messages[ $i++ ],
    qr/\[INFO \] - Test - About to run command "$cmd"/,
    "about to run command"
);
like(
    $messages[ $i++ ],
    qr/\[INFO \] - Test - USER_MSG first message/,
    "first message"
);
like(
    $messages[ $i++ ],
    qr/\[INFO \] - Test - USER_MSG second message/,
    "second message"
);
like(
    $messages[ $i++ ],
    qr/\[WARN \] - Test - warning message/,
    "warning message"
);

# now run something with a stdout file
($outfiles_ref) = $util->execOldStyle("echo filename");
is_deeply( $outfiles_ref, ["filename"], "One output file" );

1;

