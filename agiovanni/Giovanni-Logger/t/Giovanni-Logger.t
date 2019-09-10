#########################
#$Id: Giovanni-Logger.t,v 1.12 2013/07/09 18:54:35 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# This file tests the logging aspects of Giovanni::Logger.

use File::Temp qw/ tempfile tempdir /;

use strict;

use Test::More tests => 15;
BEGIN { use_ok('Giovanni::Logger') }

#########################

# create a temporary directory for a session directory
my $tempDir = tempdir( "session_XXXX", CLEANUP => 1 );

# get a logging object
my $util = Giovanni::Logger->new(
    session_dir => $tempDir,
    manifest_filename =>
        "mfst.Test+dSOME_DATA_FIELD+t20040201000000_t20050605235959.xml",
    no_stderr => 1,
);

# different messages
$util->user_msg("user message");
$util->info("info message");
$util->debug("debug message");
$util->warning("warning message");
$util->error("error message");
$util->user_error("user error message");
$util->percent_done(100);

# make sure the log file exists
ok( -e "$tempDir/mfst.Test+dSOME_DATA_FIELD+t20040201000000_t20050605235959.log",
    "log file exists"
);

# read out the messages
open LOGFILE, "<",
    "$tempDir/mfst.Test+dSOME_DATA_FIELD+t20040201000000_t20050605235959.log"
    or die $!;
my @messages = <LOGFILE>;
close LOGFILE;

# first line should be the start step line
my $i = 0;
ok( $messages[ $i++ ] =~ /\[INFO \] - Test - USER_MSG user message/,
    "publish message" );
ok( $messages[ $i++ ] =~ /\[INFO \] - Test - info message/, "info message" );
ok( $messages[ $i++ ] =~ /\[DEBUG\] - Test - debug message/,
    "debug message" );
ok( $messages[ $i++ ] =~ /\[WARN \] - Test - warning message/,
    "warning message" );
ok( $messages[ $i++ ] =~ /\[ERROR\] - Test - error message/,
    "error message" );
ok( $messages[ $i++ ] =~ /\[ERROR\] - Test - USER_ERROR user error message/,
    "user error message" );
ok( $messages[ $i++ ] =~ /\[INFO \] - Test - PERCENT_DONE 100/,
    "percent done" );

# now try lineage
my $input = Giovanni::Logger::InputOutput->new(
    name  => "first input",
    value => "input value",
    type  => "PARAMETER"
);
my @outputs = (
    Giovanni::Logger::InputOutput->new(
        name  => "first output",
        value => "output value",
        type  => "PARAMETER"
    ),
    Giovanni::Logger::InputOutput->new(
        name  => "second output",
        value => "somefile.nc",
        type  => "FILE"
    )
);

$util->write_lineage(
    name     => "something",
    inputs   => [$input],
    outputs  => \@outputs,
    messages => [ "hello", "world" ],
);

# make sure the lineage file exists
ok( -e "$tempDir/prov.Test+dSOME_DATA_FIELD+t20040201000000_t20050605235959.xml",
    "provenance file exists"
);

# read out the messages
my $doc
    = XML::LibXML->load_xml( location =>
        "$tempDir/prov.Test+dSOME_DATA_FIELD+t20040201000000_t20050605235959.xml"
    );

# do a few checks to make sure the lineage seems reasonable
ok( $doc->find("/step"), "Has root step node" );
my @values
    = map( $_->getValue(), $doc->findnodes("/step/inputs/input/\@NAME") );
is_deeply( \@values, ["first input"], "correct input names" );

@values
    = map( $_->getValue(), $doc->findnodes("/step/outputs/output/\@NAME") );
is_deeply(
    \@values,
    [ "first output", "second output" ],
    "correct output names"
);

@values
    = map( $_->getValue(), $doc->findnodes("/step/messages/message/text()") );
is_deeply( \@values, [ "hello", "world" ], "correct lineage messages" );

ok( $doc->find("/step/\@ELAPSED_TIME"), "elapsed time in file" );
