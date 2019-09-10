#$Id: Giovanni-Workflow_getStatus.t,v 1.4 2013/09/30 17:52:57 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# tests the Giovanni::Workflow::getStatus().

#########################

use Test::More tests => 17;
use File::Temp qw(tempdir);
use Date::Parse;
use strict;

BEGIN { use_ok('Giovanni::Workflow') }

#########################

# create a temporary directory
my $dir = tempdir( CLEANUP => 1 );

# there will be three targets
my @targets = ( "mfst.first.xml", "mfst.second.xml", "mfst.third.xml" );

# we'll start by getting the status without any log files at all.
my ( $status_ref, $percentDone_ref, $time_ref )
    = Giovanni::Workflow::getStatus(
    "DIRECTORY" => $dir,
    "TARGETS"   => \@targets
    );
is_deeply(
    $status_ref,
    [ "", "", "" ],
    "Empty status because there are no log files"
);
is_deeply(
    $percentDone_ref,
    [ "0", "0", "0" ],
    "No percent done because there are no log files"
);
is_deeply( $time_ref, [ 0, 0, 0 ],
    "No times because there are no log files" );

# now we are going to write to the log file
my $firstLog = <<FIRSTLOG;
2013-01-01 00:00:00,000 - [INFO ] - data_field_info - INFO Some info message
on another line
and another line
2013-01-01 00:01:00,010 - [INFO ] - data_field_info - USER_MSG first message
some line
2013-01-01 00:02:00,000 - [INFO ] - data_field_info - PERCENT_DONE 10
FIRSTLOG
writeTempFile( "$dir/mfst.first.log", $firstLog );

( $status_ref, $percentDone_ref, $time_ref ) = Giovanni::Workflow::getStatus(
    "DIRECTORY" => $dir,
    "TARGETS"   => \@targets
);
is_deeply(
    $status_ref,
    [ "first message\nsome line", "", "" ],
    "First task has a message"
);
is_deeply(
    $percentDone_ref,
    [ "10", "0", "0" ],
    "First task 10 percent done"
);
is_deeply( $time_ref, [ str2time("2013-01-01 00:01:00") + 0.01, 0, 0 ],
    "First time" );

# write it again
$firstLog = <<FIRSTLOG;
2013-01-01 00:00:00,000 - [INFO ] - data_field_info - INFO Some info message
2013-01-01 00:01:00,000 - [INFO ] - data_field_info - USER_MSG first message
2013-01-01 00:02:00,000 - [INFO ] - data_field_info - PERCENT_DONE 100
2013-01-01 00:03:00,000 - [INFO ] - data_field_info - USER_MSG some other message
FIRSTLOG
writeTempFile( "$dir/mfst.first.log", $firstLog );

( $status_ref, $percentDone_ref, $time_ref ) = Giovanni::Workflow::getStatus(
    "DIRECTORY" => $dir,
    "TARGETS"   => \@targets
);
is_deeply(
    $status_ref,
    [ "some other message", "", "" ],
    "First task has a done message"
);
is_deeply(
    $percentDone_ref,
    [ "100", "0", "0" ],
    "First task 100 percent done"
);

is_deeply(
    $time_ref,
    [ str2time("2013-01-01 00:03:00"), 0, 0 ],
    "First time, second message"
);

# write the second log file
my $secondLog = <<SECONDLOG;
2013-01-01 01:00:00,000 - [INFO ] - data_field_info - INFO Some info message
2013-01-01 01:01:00,000 - [INFO ] - data_field_info - USER_MSG some message
2013-01-01 01:02:00,000 - [INFO ] - data_field_info - USER_MSG another message
2013-01-01 01:03:00,000 - [INFO ] - data_field_info - PERCENT_DONE 10
2013-01-01 01:04:00,000 - [INFO ] - data_field_info - PERCENT_DONE 88
2013-01-01 01:05:00,123 - [INFO ] - data_field_info - USER_MSG yet another message
2013-01-01 01:06:00,000 - [DEBUG] - data_field_info - DEBUG debug message
SECONDLOG
writeTempFile( "$dir/mfst.second.log", $secondLog );

( $status_ref, $percentDone_ref, $time_ref ) = Giovanni::Workflow::getStatus(
    "DIRECTORY" => $dir,
    "TARGETS"   => \@targets
);

is_deeply(
    $status_ref,
    [ "some other message", "yet another message", "" ],
    "Second task partly done message"
);
is_deeply( $percentDone_ref, [ "100", "88", "0" ], "Second task 88% done" );

is_deeply(
    $time_ref,
    [   str2time("2013-01-01 00:03:00"),
        str2time("2013-01-01 01:05:00") + 0.123,
        0
    ],
    "Second task time"
);

# write a "done" second log file
$secondLog = <<SECONDLOG;
2013-01-01 01:00:00,000 - [INFO ] - data_field_info - INFO Some info message
2013-01-01 01:01:00,000 - [INFO ] - data_field_info - USER_MSG some message
2013-01-01 01:02:00,000 - [INFO ] - data_field_info - USER_MSG another message
2013-01-01 01:03:00,000 - [INFO ] - data_field_info - PERCENT_DONE 10
2013-01-01 01:04:00,000 - [INFO ] - data_field_info - PERCENT_DONE 88
2013-01-01 01:05:00,000 - [INFO ] - data_field_info - USER_MSG yet another message
2013-01-01 01:06:00,000 - [DEBUG] - data_field_info - DEBUG debug message
2013-01-01 01:04:00,000 - [INFO ] - data_field_info - PERCENT_DONE 100
SECONDLOG
writeTempFile( "$dir/mfst.second.log", $secondLog );

# write the third log file
my $thirdLog = <<THIRDLOG;
2013-01-01 02:00:00,000 - [INFO ] - data_field_info - INFO Some info message
2013-01-01 02:01:00,000 - [INFO ] - data_field_info - USER_MSG some message
2013-01-01 02:02:00,000 - [INFO ] - data_field_info - USER_MSG another message
2013-01-01 02:03:00,000 - [INFO ] - data_field_info - PERCENT_DONE 10
2013-01-01 02:04:00,000 - [INFO ] - data_field_info - USER_MSG yet another message
2013-01-01 02:05:00,000 - [INFO ] - data_field_info - PERCENT_DONE 24
2013-01-01 02:06:00,000 - [ERROR] - data_field_info - ERROR Something went wrong!
THIRDLOG
writeTempFile( "$dir/mfst.third.log", $thirdLog );

( $status_ref, $percentDone_ref, $time_ref ) = Giovanni::Workflow::getStatus(
    "DIRECTORY" => $dir,
    "TARGETS"   => \@targets
);

is_deeply(
    $status_ref,
    [ "some other message", "yet another message", "" ],
    "Third task - error message does not come through"
);
is_deeply( $percentDone_ref, [ "100", "100", "24" ], "Third task 24% done" );

# rewrite the third log file
$thirdLog = <<THIRDLOG;
2013-01-01 00:00:00,000 - [INFO ] - data_field_info - INFO Some info message
2013-01-01 00:01:00,000 - [INFO ] - data_field_info - USER_MSG some message
2013-01-01 00:02:00,000 - [INFO ] - data_field_info - USER_MSG another message
2013-01-01 00:03:00,000 - [INFO ] - data_field_info - PERCENT_DONE 10
2013-01-01 00:04:00,000 - [INFO ] - data_field_info - USER_MSG yet another message
2013-01-01 00:05:00,000 - [INFO ] - data_field_info - PERCENT_DONE 24
2013-01-01 00:06:00,000 - [ERROR] - data_field_info - USER_ERROR Something went wrong!
THIRDLOG
writeTempFile( "$dir/mfst.third.log", $thirdLog );

( $status_ref, $percentDone_ref, $time_ref ) = Giovanni::Workflow::getStatus(
    "DIRECTORY" => $dir,
    "TARGETS"   => \@targets
);

is_deeply(
    $status_ref,
    [ "some other message", "yet another message", "##Something went wrong!" ],
    "Error message gets through"
);
is_deeply(
    $percentDone_ref,
    [ "100", "100", "24" ],
    "Third task 24% done again"
);

sub writeTempFile {
    my ( $fileName, $string ) = @_;
    open( FILE, ">", $fileName ) or die $?;
    print FILE $string or die $?;
    close(FILE);
}

