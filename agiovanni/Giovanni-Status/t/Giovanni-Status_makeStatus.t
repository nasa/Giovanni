
#!/usr/bin/env perl

#$Id: Giovanni-Status_makeStatus.t,v 1.4 2015/01/30 21:52:37 eseiler Exp $
#-@@@ Giovanni, Version $Name:  $

use File::Temp qw/ tempfile tempdir /;

use Test::More tests => 21;
BEGIN { use_ok('Giovanni::Status') }

# create a temporary directory for status files
my $dir = tempdir( CLEANUP => 1 );

my @targets = ( "mfst.first.xml", "mfst.second.xml", "mfst.third.xml" );
writeTempFile( "$dir/targets.txt", join( "\n", @targets ) );

# get the current status. Should be the nominal message
my $status = Giovanni::Status->new($dir);
my $result = $status->findCurrentStatus();
is( $result->{flag}, 0, "Flag correct" );
is( $result->{message}, "Workflow is running", "Status is correct" );

# now write something to a log
my $firstLog = <<FIRSTLOG;
2013-01-01 00:00:00,111 - [INFO ] - first - INFO Some info message
2013-01-01 00:01:00,112 - [INFO ] - first - USER_MSG first message
2013-01-01 00:02:00,113 - [INFO ] - first - PERCENT_DONE 10
FIRSTLOG
writeTempFile( "$dir/mfst.first.log", $firstLog );
$status = Giovanni::Status->new($dir);
$result = $status->findCurrentStatus();
is( $result->{flag},            0,               "Flag correct" );
is( $result->{message},         "first message", "Got first message" );
is( $result->{percentComplete}, 0.1 * 25,        "10% of first step" );

# finish this step
$firstLog = <<FIRSTLOG;
2013-01-01 00:00:00,111 - [INFO ] - first - INFO Some info message
2013-01-01 00:01:00,112 - [INFO ] - first - USER_MSG first message
2013-01-01 00:02:00,113 - [INFO ] - first - PERCENT_DONE 10
2013-01-01 00:03:00,114 - [INFO ] - first - USER_MSG second message
2013-01-01 00:04:00,115 - [INFO ] - first - PERCENT_DONE 100
FIRSTLOG
writeTempFile( "$dir/mfst.first.log", $firstLog );
$status = Giovanni::Status->new($dir);
$result = $status->findCurrentStatus();
is( $result->{flag},            0,                "Flag correct" );
is( $result->{message},         "second message", "Got second message" );
is( $result->{percentComplete}, 25,               "100% of first step" );

# second step
my $secondLog = <<SECONDLOG;
2013-01-01 01:00:00,111 - [INFO ] - second - INFO Some info message
2013-01-01 01:01:00,112 - [INFO ] - second - USER_MSG some message
2013-01-01 01:02:00,113 - [INFO ] - second - USER_MSG another message
2013-01-01 01:03:00,114 - [INFO ] - second - PERCENT_DONE 10
2013-01-01 01:04:00,115 - [INFO ] - second - PERCENT_DONE 88
2013-01-01 01:05:00,116 - [INFO ] - second - USER_MSG yet another message
2013-01-01 01:06:00,117 - [DEBUG] - second - DEBUG debug message
SECONDLOG
writeTempFile( "$dir/mfst.second.log", $secondLog );
$status = Giovanni::Status->new($dir);
$result = $status->findCurrentStatus();
is( $result->{flag}, 0, "Flag correct" );
is( $result->{message},
    "yet another message",
    "Got message from second step"
);
is( $result->{percentComplete}, 25 + 0.88 * 25, "partial second step" );

# write a "done" second log file
$secondLog = <<SECONDLOG;
2013-01-01 02:00:00,111 - [INFO ] - second - INFO Some info message
2013-01-01 02:01:00,112 - [INFO ] - second - USER_MSG some message
2013-01-01 02:02:00,113 - [INFO ] - second - USER_MSG another message
2013-01-01 02:03:00,114 - [INFO ] - second - PERCENT_DONE 10
2013-01-01 02:04:00,115 - [INFO ] - second - PERCENT_DONE 88
2013-01-01 02:05:00,116 - [INFO ] - second - USER_MSG yet another message
2013-01-01 02:06:00,117 - [DEBUG] - second - DEBUG debug message
2013-01-01 02:07:00,118 - [INFO ] - second - PERCENT_DONE 100
SECONDLOG
writeTempFile( "$dir/mfst.second.log", $secondLog );

# write the third log file
my $thirdLog = <<THIRDLOG;
2013-01-01 03:00:00,111 - [INFO ] - third - INFO Some info message
2013-01-01 03:01:00,112 - [INFO ] - third - USER_MSG some message
2013-01-01 03:02:00,113 - [INFO ] - third - USER_MSG another message
2013-01-01 03:03:00,114 - [INFO ] - third - PERCENT_DONE 10
2013-01-01 03:04:00,115 - [INFO ] - third - USER_MSG three is wonderful
2013-01-01 03:05:00,116 - [INFO ] - third - PERCENT_DONE 24
THIRDLOG
writeTempFile( "$dir/mfst.third.log", $thirdLog );

$status = Giovanni::Status->new($dir);
$result = $status->findCurrentStatus();
is( $result->{flag}, 0, "Flag correct" );
is( $result->{message}, "three is wonderful", "Got message from third step" );
is( $result->{percentComplete}, 50 + 0.24 * 25, "partial third step" );

# now write the third log again but put the times before the second log
$thirdLog = <<THIRDLOG;
2013-01-01 01:30:00,111 - [INFO ] - third - INFO Some info message
2013-01-01 01:31:00,112 - [INFO ] - third - USER_MSG some message
2013-01-01 01:32:00,113 - [INFO ] - third - USER_MSG another message
2013-01-01 01:33:00,114 - [INFO ] - third - PERCENT_DONE 100
THIRDLOG
writeTempFile( "$dir/mfst.third.log", $thirdLog );
$status = Giovanni::Status->new($dir);
$result = $status->findCurrentStatus();
is( $result->{flag}, 0, "Flag correct" );
is( $result->{message}, "yet another message", "Second log after third log" );

# third step done
$thirdLog = <<THIRDLOG;
2013-01-01 03:00:00,111 - [INFO ] - third - INFO Some info message
2013-01-01 03:01:00,112 - [INFO ] - third - USER_MSG some message
2013-01-01 03:02:00,113 - [INFO ] - third - USER_MSG another message
2013-01-01 03:03:00,114 - [INFO ] - third - PERCENT_DONE 10
2013-01-01 03:04:00,115 - [INFO ] - third - USER_MSG three is wonderful
2013-01-01 03:05:00,116 - [INFO ] - third - PERCENT_DONE 100
THIRDLOG
writeTempFile( "$dir/mfst.third.log", $thirdLog );

$status = Giovanni::Status->new($dir);
$result = $status->findCurrentStatus();
is( $result->{flag}, 0, "Flag correct" );
is( $result->{message}, "three is wonderful", "Got message from third step" );
is( $result->{percentComplete}, 75, "third step done" );

# write the make output file
writeTempFile( "$dir/status.txt", "0" );
$status = Giovanni::Status->new($dir);
$result = $status->findCurrentStatus();
is( $result->{flag}, 1, "Flag shows we failed" );

# now write the third log again with partail percent done
# but we should still report 75% done because the make
# completed
# third step done
$thirdLog = <<THIRDLOG;
2013-01-01 02:00:00,111 - [INFO ] - third - INFO Some info message
2013-01-01 02:01:00,112 - [INFO ] - third - USER_MSG some message
2013-01-01 02:02:00,113 - [INFO ] - third - USER_MSG another message
2013-01-01 02:03:00,114 - [INFO ] - third - PERCENT_DONE 10
THIRDLOG
writeTempFile( "$dir/mfst.third.log", $thirdLog );
writeTempFile( "$dir/status.txt",     "1" );
$status = Giovanni::Status->new($dir);
$result = $status->findCurrentStatus();

sub writeTempFile {
    my ( $fileName, $string ) = @_;
    open( FILE, ">", $fileName ) or die $?;
    print FILE $string or die $?;
    close(FILE);
}

1;
