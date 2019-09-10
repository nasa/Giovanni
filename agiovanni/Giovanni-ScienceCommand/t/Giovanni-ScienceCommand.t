#$Id: Giovanni-ScienceCommand.t,v 1.4 2013/07/17 17:27:08 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# This file tests the command line call Giovanni::ScienceCommand

use File::Temp qw/ tempfile tempdir /;

use strict;

use Test::More tests => 13;
BEGIN { use_ok('Giovanni::Logger') }
BEGIN { use_ok('Giovanni::ScienceCommand') }

# create a temp file with the messages we want to pick up on stderr
my $tempDir = tempdir( "session_XXXX", CLEANUP => 1 );
my $tempFile = "$tempDir/messages.txt";

open( TEMPFILE, ">$tempFile" );
print TEMPFILE <<STRING;
DEBUG debug message
INFO informational message
WARN warning message
ERROR error message
USER_ERROR user error message
PERCENT_DONE 100
USER_MSG user message
LINEAGE_MESSAGE some lineage message
OUTPUT file.nc
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

my ( $outfiles_ref, $messages_ref ) = $util->exec($cmd);
my @outfiles = @{$outfiles_ref};

ok( scalar( @{$outfiles_ref} ) == 1, "Saw one output file" );

is_deeply( $messages_ref, ["some lineage message"], "Got lineage message" );

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
    qr/\[DEBUG\] - Test - debug message/,
    "debug message"
);
like(
    $messages[ $i++ ],
    qr/\[INFO \] - Test - informational message/,
    "informational message"
);
like(
    $messages[ $i++ ],
    qr/\[WARN \] - Test - warning message/,
    "warning message"
);
like(
    $messages[ $i++ ],
    qr/\[ERROR\] - Test - error message/,
    "error message"
);
like(
    $messages[ $i++ ],
    qr/\[ERROR\] - Test - USER_ERROR user error message/,
    "user error message"
);
like(
    $messages[ $i++ ],
    qr/\[INFO \] - Test - PERCENT_DONE 100/,
    "percent done message"
);
like(
    $messages[ $i++ ],
    qr/\[INFO \] - Test - USER_MSG user message/,
    "user message"
);
like(
    $messages[ $i++ ],
    qr/\[INFO \] - Test - Saw output file /,
    "output file"
);

1;

