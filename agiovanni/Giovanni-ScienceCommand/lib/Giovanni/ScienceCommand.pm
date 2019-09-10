#$Id: ScienceCommand.pm,v 1.16 2015/08/20 18:01:32 rstrub Exp $
#-@@@ Giovanni, Version $Name:  $
package Giovanni::ScienceCommand;

use 5.008008;
use strict;
use warnings;
use IPC::Open3;
use IO::Select;
use Giovanni::Util;
use File::Basename;

our $VERSION = '0.01';

# Preloaded methods go here.
# Constructs a new utility class. Requires the session directory and step name.
# The step name should be the same as the build target.
sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    # check to make sure that we have the location of the session directory
    if ( !( exists $params{"sessionDir"} ) ) {
        die "Util contructor must have a 'sessionDir' key in the hash";
    }

    # check to make sure we have the step id
    if ( !( exists $params{"logger"} ) ) {
        die "Util constructor must have a 'logger' key in the hash";
    }

    if ( !( exists $params{"dieOnFailure"} ) ) {

        # by default, die if there is a failure
        $params{"dieOnFailure"} = 1;
    }

    return $self;
}

# calls an external "science" command and processes its messages for logging
# via STDERR. Returns the names of any output files the command specifies.
sub exec() {
    my ( $self, $command, $start_percent, $end_percent ) = @_;
    my @cmdArray;
    if ( ref($command) ) {
        @cmdArray = @{$command};
    }
    else {
        @cmdArray = ($command);
    }
    my $commandString = join( " ", @cmdArray );

    if ( !defined($start_percent) ) {
        $start_percent = 0;
    }
    if ( !defined($end_percent) ) {
        $end_percent = 100;
    }

    $self->{start_percent} = $start_percent;
    $self->{end_percent}   = $end_percent;

    $self->{logger}->info(qq(About to run command "$commandString"));

    my $pid = open3( *IN, *CMD_OUT, *CMD_ERR, @cmdArray );

# I don't need to send the commands anything via STDIN, so close the
# descriptor. I don't know if there is some way to use Cwd; just not pass a handle to
# open3.
    close(IN);

    my $selector = IO::Select->new();
    $selector->add( *CMD_OUT, *CMD_ERR );

    # Read from stderr and stdout. Put these messages in the log.
    my @out_files = ();
    my @messages  = ();
    my $msgout    = "";
    my $msgerr    = "";
    my $result;

    # $sel->can_read will block until there is data available
    # on one or more fhs
    while ( my @ready = $selector->can_read ) {

        # now we have a list of all fhs that we can read from
        foreach my $fh (@ready) {    # loop through them
            my $line;

            # read up to 4096 bytes from this fh.
            # if there is less than 4096 bytes, we'll only get
            # those available bytes and won't block.  If there
            # is more than 4096 bytes, we'll only read 4096 and
            # wait for the next iteration through the loop to
            # read the rest.
	    #
            # Therefore this code tries to keep track of
            # incomplete lines and join them together when
            # the next message comes. IFF  necessary.
            my $len = sysread $fh, $line, 4096;
            if ( not defined $len ) {

                # There was an error reading
                die "Error from child: $!\n";
            }
            elsif ( $len == 0 ) {

                # Finished reading from this FH because we read
                # 0 bytes.  Remove this handle from $sel.
                # we will exit the loop once we remove all file
                # handles ($outfh and $errfh).
                $selector->remove($fh);
                next;
            }
            else {    # we read data alright

                # print "Read $len bytes from $fh\n";
                if ( $fh eq *CMD_OUT ) {
                    if ( length $msgout > 0 ) {
                        $line   = $msgout . $line;
                        $msgout = "";
                    }
                    my @lines = split( /\n/, $line );
                    if ( substr( $line, -1, 1 ) eq "\n" ) {

                        #last line is complete
                    }
                    else {

                        # last line is NOT complete
                        $msgout = pop @lines; # extract 1/2 line for next time
                    }

                    foreach my $elem (@lines) {
                        $result = $self->_processStdOut($elem);
                    }

                }
                elsif ( $fh eq *CMD_ERR ) {
                    if ( length $msgerr > 0 ) {
                        $line   = $msgerr . $line;
                        $msgerr = "";
                    }
                    my @lines = split( /\n/, $line );
                    if ( substr( $line, -1, 1 ) eq "\n" ) {

                        #last line is complete
                    }
                    else {

                        # last line is NOT complete
                        $msgerr = pop @lines; # extract 1/2 line for next time
                    }

                    foreach my $elem (@lines) {
                        $result = $self->_processStdErr($elem);

                        if ( defined( $result->{LINEAGE_MESSAGE} ) ) {
                            push( @messages, $result->{LINEAGE_MESSAGE} );
                        }
                        if ( defined( $result->{OUTPUT} ) ) {
                            push( @out_files, $result->{OUTPUT} );
                        }
                    }
                }
                else {
                    die "Shouldn't be here (not stdout or stderr)\n";
                }
            }
        }
    }

    waitpid( $pid, 0 );
    my $exitCode = $?;
    if ( $exitCode != 0 ) {
        my $msg = "Command returned non-zero: $commandString";
        $self->{logger}->error($msg);
        if ( $self->{dieOnFailure} ) {
            die($msg);
        }
    }
    else {
        $self->{logger}->info(qq(Finished running command: "$commandString"));
    }

    return ( \@out_files, \@messages, $exitCode );
}

# parse and log a science command message from stdout
sub _processStdOut() {
    my ( $self, $msg ) = @_;
    if ( defined($msg) ) {
        $self->{logger}->info("[STDOUT message] $msg");
    }
}

# parse and log a science command message from stderr
sub _processStdErr() {
    my ( $self, $msg ) = @_;

    if ( !defined($msg) ) {
        return;
    }

    my $out = {};

    $msg = Giovanni::Util::trim($msg);
    if ( $msg =~ m/^DEBUG/ ) {
        $msg =~ s/^DEBUG\s+//;
        $self->{logger}->debug($msg);
    }
    elsif ( $msg =~ /^INFO/ ) {
        $msg =~ s/^INFO\s+//;
        $self->{logger}->info($msg);
    }
    elsif ( $msg =~ /^WARN/ ) {
        $msg =~ s/^WARN\s+//;
        $self->{logger}->warning($msg);
    }
    elsif ( $msg =~ /^ERROR/ ) {
        $msg =~ s/^ERROR\s+//;
        $self->{logger}->error($msg);
    }
    elsif ( $msg =~ /^USER_ERROR/ ) {
        $msg =~ s/^USER_ERROR\s+//;
        $self->{logger}->user_error($msg);
    }
    elsif ( $msg =~ /^PERCENT_DONE/ ) {
        $msg =~ s/^PERCENT_DONE\s+//;

        # calculate the percent done
        my $diff         = $self->{end_percent} - $self->{start_percent};
        my $percent_done = $self->{start_percent} + $msg * $diff / 100;

        $self->{logger}->percent_done($percent_done);
    }
    elsif ( $msg =~ /^USER_MSG/ ) {
        $msg =~ s/^USER_MSG\s+//;
        $self->{logger}->user_msg($msg);
    }
    elsif ( $msg =~ /^USER_INFO/ ) {
        $msg =~ s/^USER_INFO\s+//;
        $self->{logger}->user_msg($msg);
    }
    elsif ( $msg =~ /^OUTPUT/ ) {
        $msg =~ s/^OUTPUT\s+//;
        $self->{logger}->info("Saw output file $msg");

        # make sure that this is a full path
        if ( $msg eq basename($msg) ) {
            $msg = $self->{sessionDir} . "/" . $msg;
            $self->{logger}->info("Translated output file to $msg");
        }
        $out->{OUTPUT} = $msg;
    }
    elsif ( $msg =~ /^LINEAGE_MESSAGE/ ) {
        $msg =~ s/^LINEAGE_MESSAGE\s+//;
        $out->{LINEAGE_MESSAGE} = $msg;
    }
    else {
        $self->{logger}->info("Unrecognized message: $msg");
    }
    return $out;
}

# old style exec
# everything on stdout is assumed to be an output file
# everything on stderr is assumed to be a user message unless it begins with WARN
sub execOldStyle {
    my ( $self, $command ) = @_;

    $self->{logger}->info(qq(About to run command "$command"));

    my $pid = open3( *IN, *CMD_OUT, *CMD_ERR, $command );

# I don't need to send the commands anything via STDIN, so close the
# descriptor. I don't know if there is some way to use Cwd; just not pass a handle to
# open3.
    close(IN);

    my $selector = IO::Select->new();
    $selector->add( *CMD_OUT, *CMD_ERR );

    # Read from stderr and stdout.
    my @out_files = ();
    while ( my @ready = $selector->can_read ) {
        foreach my $fh (@ready) {
            if ( fileno($fh) == fileno(CMD_ERR) ) {
                my $msg = scalar(<CMD_ERR>);
                if ( defined $msg ) {
                    Giovanni::Util::trim($msg);
                    if ( $msg =~ m/^WARN\s+(.*)$/ ) {
                        $self->{logger}->warning($1);
                    }
                    else {
                        $self->{logger}->user_msg($msg);
                    }
                }
            }
            elsif ( fileno($fh) == fileno(CMD_OUT) ) {
                my $msg = scalar <CMD_OUT>;
                if ( defined($msg) ) {
                    Giovanni::Util::trim($msg);
                    $self->{logger}->info("Saw output file $msg");
                    push( @out_files, $msg );
                }
            }
            if ( eof($fh) ) {
                $selector->remove($fh);
            }
        }
    }

    waitpid( $pid, 0 );
    my $exitCode = $?;
    if ( $exitCode != 0 ) {
        my $msg = "Command returned non-zero: $command";
        $self->{logger}->error($msg);
        die($msg);
    }
    $self->{logger}->info(qq(Finished running command: "$command"));
    return ( \@out_files, [] );
}

1;
__END__

=head1 NAME

Giovanni::ScienceCommand - Perl module science commands 

=head1 ABSTRACT

This class  handles logic to call an external 'science' command that can also 
contribute to the log.

=head1 SYNOPSIS

  use Giovanni::Logging
  use Giovanni::ScienceCommand;
  
  # Let's assume that the task name and session directory are command line
  # options
  my $task_name = $ARGV[0];
  my $sessionDir = $ARGV[1];
  
  # Get a logger with the name of the task in the build file. Your command
  # can get this via the command line.
  my $logger = Giovanni::Logger->new(sessionDir=>$sessionDir,name=>$task_name);
  my $caller = Giovanni::ScienceCommand->new(sessionDir=>$sessionDir,logger=>$logger);
  
  # call a 'science' command. The library will process the command's stderr for
  # log messages. The second and third parameters specify the start and end
  # percentage for the log PERCENT_DONE messages. They are optional. If not
  # present, the code assumes 0 and 100.
  my $cmd = "/path/to/science/command.pl";
  my ($outfiles_ref, $messages_ref) = $caller->exec($cmd,0,50);
  
  # Alternatively, call the command as an array.
  my @arr = ("/path/to/science/command.pl","-d","/path/to/dir",50,100);
  my ($outfiles_ref, $messages_ref) = $caller->exec(\@arr);
  
  # Tell the log that we are at 100.
  $util->percent_done(100);

=head1 DESCRIPTION

This code provides utilities for calling 'science' commands.

=head2 CONSTRUCTOR

B<Giovanni::ScienceCommand-E<gt>new(sessionDir=E<gt>$sessionDir,logger=E<gt>$logger)>
The constructor has two mandatory arguments - the session directory (location 
of the log) and a logger (Giovanni::Logger). You can also set dieOnFailure, 
which has the default value of 1. If set to true, the code will die when it
detects a non-zero return value when exec is called.


=head2 EXTERNAL 'SCIENCE' COMMANDS

B<util-E<gt>exec($cmd,$startPercent,$endPercent)> 

B<util-E<gt>exec($cmdArrayRef,$startPercent,$endPercent)>

Call a 'science' command. 
Science commands use special keywords on STDERR to put messages in log:

(1) DEBUG

(2) INFO

(3) USER_MSG

(4) WARN

(5) ERROR 

(6) PERCENT_DONE

(7) USER_ERROR

These messages are automatically put in the session log/shown to users. Science
commands also use keywords for outputs and lineage messages:

(1) OUTPUT E<lt>/path/to/output/file.ncE<gt>

(2) LINEAGE_MESSAGE E<lt>Something useful for lineageE<gt>

The outputs and messages are returned by C<exec()> function as references to 
arrays. The third returned element is the return value of the command.

The $startPercent and $endPercent control the PERCENT_DONE intermediate 
messages to log. They are optional and by default set to 0 and 100.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut
