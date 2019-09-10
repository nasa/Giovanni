#$Id: Status.pm,v 1.32 2015/02/02 17:41:01 dedasilv Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::Status;

use 5.008008;
use strict;
use warnings;
use File::stat;
use Time::localtime;
use Time::Local;
use Data::Dumper;
use Giovanni::Workflow;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Status ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';
use strict;
use vars '$AUTOLOAD';
use Giovanni::Util;

sub new() {
    my ( $class, $sessionDir, $timeout, $portal ) = @_;
    my $self = {};
    $self->{_PORTAL} = defined $portal ? $portal : 'UNKNOWN';
    $self->{_STATUS} = { code => 0, message => '' };
    if ( defined $sessionDir ) {
        my $actorsListFile     = $sessionDir . '/actors.txt';
        my $sessionLogFile     = $sessionDir . '/sessionLog4j.log';
        my $targetListFile     = $sessionDir . '/targets.txt';
        my $buildStatusFile    = $sessionDir . '/status.txt';
        my $workflowCancelFile = $sessionDir . '/workflow.cancel';

        if ( -f $workflowCancelFile ) {
            $self->{_STATUS}{code}    = -1;
            $self->{_STATUS}{message} = 'Service cancelled';
        }
        elsif ( -f $targetListFile ) {
            my @targetList = Giovanni::Util::readFile($targetListFile);
            @targetList = () unless @targetList;
            chomp @targetList;
            $self->{_ACTORS}          = \@targetList;
            $self->{_WORKFLOW_ENGINE} = 'make';
            my @sessionStatus = Giovanni::Util::readFile($buildStatusFile);
            $self->{_FINAL_STATUS} = \@sessionStatus;

            # read the log files for percent done and
            my ( $status_ref, $percentDone_ref, $time_ref )
                = Giovanni::Workflow::getStatus(
                "DIRECTORY" => $sessionDir,
                "TARGETS"   => \@targetList,
                );
            $self->{_LOGS}         = $status_ref;
            $self->{_PERCENT_DONE} = $percentDone_ref;
            $self->{_LOGS_TIME}    = $time_ref;

        }
        elsif ( -f $actorsListFile ) {

            #Read list of actors to be monitored
            my @actorList = Giovanni::Util::readFile($actorsListFile);
            @actorList = () unless @actorList;
            chomp @actorList;
            $self->{_ACTORS} = \@actorList;
            if ( -f $sessionLogFile ) {
                my @sessionContents
                    = Giovanni::Util::readFile($sessionLogFile);

                #Get log messages with STATUS: in them
                my @matches = grep( /STATUS:/i, @sessionContents );
                $self->{_LOGS} = \@matches;
            }
            else {
                $self->{_STATUS}{code}    = 1;
                $self->{_STATUS}{message} = 'Session log not found';
            }
            $self->{_WORKFLOW_ENGINE} = 'kepler';
        }
        else {
            $self->{_ACTORS} = [];
        }

        ##
        if ( defined $timeout ) {
            $self->{_TIMEOUT} = $timeout;
        }
    }
    else {
        $self->{_STATUS}
            = { code => 1, message => 'Session directory not defined' };

    }

    return bless( $self, $class );
}
################################################################################
sub isTimeout {
    my ( $sessionlogs, $timeout ) = @_;
    my $flag      = 0;
    my @logs      = @{$sessionlogs};
    my $logCount  = scalar(@logs);
    my $logstring = join( ';', @logs );
    my $last_log_time;
    my $index = $logCount - 1;
    while ( $index >= 0 ) {
        my $item = $logs[$index];
        chomp($item);
        next if ( $item eq "" );
        my $dtstr = extractDateTimeString($item);
        $last_log_time = convertStringToDate($dtstr);
        last;
        $index--;
    }

    ## my $file_epoch_time = stat("$sessionlogFile")->mtime;
    my $current_epoch_time = time;
    if ( defined $last_log_time ) {
        $flag = 1 if ( ( $current_epoch_time - $last_log_time ) > $timeout );
    }
    return $flag;
}

################################################################################
sub findCurrentStatus {
    my ($self) = @_;

    #Hash ref holding flag (0/1=>normal/error) percentComplete, last status
    #message
    my $resultStatusHash = { flag => 0, percentComplete => 0, message => '' };

    #List of actors to be monitored
    my @actorList = @{ $self->{_ACTORS} };

    #If no actors are found, workflow hasn't launched
    unless (@actorList) {
        $resultStatusHash->{flag}    = 0;
        $resultStatusHash->{message} = 'Launching workflow';
        return $resultStatusHash;
    }

    if ( $self->{_WORKFLOW_ENGINE} eq 'make' ) {

        # and get the last status
        $resultStatusHash->{message} = '';
        my $latestTime         = 0;
        my $latestErrorMessage = '';
        my $latestErrorTime    = 0;
        for ( my $i = 0; $i < scalar( @{ $self->{_LOGS} } ); $i++ ) {
            my $status = $self->{_LOGS}->[$i];
            my $time   = $self->{_LOGS_TIME}->[$i];
            if ( length($status) > 0 ) {
                my $isErrorMessage = index( $status, "##" ) == 0 ? 1 : 0;
                if ($isErrorMessage) {

                    # strip off the error message marker
                    $status =~ s/^##//g;

                    # check to see if this is the latest error message
                    if ( $time > $latestErrorTime ) {
                        $latestErrorMessage = $status;
                    }
                }

                # check to see if this is the latest message. (Note: may or
                # may not be an error message.)
                if ( $time > $latestTime ) {
                    $resultStatusHash->{message} = $status;
                    $latestTime = $time;
                }

            }
        }

        # check to see if the make workflow is done
        if ( scalar( @{ $self->{_FINAL_STATUS} } ) == 1 ) {

            # it's done, so we are either in an error state, or we finished
            # successfully.
            my $item = $self->{_FINAL_STATUS}->[0];
            chomp($item);
            if ( $item eq '0' ) {
                $resultStatusHash->{flag} = 1;
                if ( $latestErrorMessage ne '' ) {
                    $resultStatusHash->{message}
                        = $latestErrorMessage . '... Workflow failed';
                }
                elsif ( $resultStatusHash->{message} ne '' ) {
                    $resultStatusHash->{message} .= '... Workflow failed';
                }
                else {
                    $resultStatusHash->{message} = 'Workflow failed';
                }
            }
            elsif ( $item eq '1' ) {
                $resultStatusHash->{flag}            = 0;
                $resultStatusHash->{message}         = 'Workflow completed.';
                $resultStatusHash->{percentComplete} = 75.0;
            }
            else {
                die "Unrecognized final status. Expected 0 or 1: "
                    . $self->{_FINAL_STATUS};
            }
        }
        else {

            # the workflow is still running
            $resultStatusHash->{flag} = 0;

            # figure out the percent done
            my $numTargets  = scalar(@actorList);
            my $percentDone = 0;
            $percentDone += $_ for @{
                $self->{_PERCENT_DONE};
                };
            $resultStatusHash->{percentComplete}
                = 0.75 * $percentDone / $numTargets;

            $resultStatusHash->{message} = "Workflow is running"
                if ( $resultStatusHash->{message} eq '' );
        }
        return $resultStatusHash;
    }

    #A hash with actor names as keys
    my $actorStatusHash = { map { $_, 0 } @actorList };
LOG_ITEM: foreach my $item ( @{ $self->{_LOGS} } ) {
        my @fields = split( /-/, $item, 6 );

        #Remove any leading or trailing white spaces
        foreach my $field (@fields) {
            $field =~ s/^\s+|\s+$//g;
        }

        #Fifth field is the actor and the sixth field is the log message
        my $actorName = ( defined $fields[4] ? $fields[4] : undef );
        next LOG_ITEM unless ( defined $actorName );
        next LOG_ITEM unless ( defined $actorStatusHash->{$actorName} );
        if ( $fields[5] =~ /^STATUS:START_FIRE\s*((\d+)\/(\d+)){0,1}/ ) {

            #Do nothing; place holder for future use
        }
        elsif ( $fields[5] =~ /^STATUS:END_FIRE\s*((\d+)\/(\d+)){0,1}/ ) {
            if ( defined $1 ) {
                $actorStatusHash->{$actorName} = $2 * 1.0 / $3;
            }
            else {
                $actorStatusHash->{$actorName} = 1.0;
            }
        }
        elsif ( $fields[5] =~ /^STATUS:INTERRUPTED\s*(.*)$/ ) {

            #Case of exceptions in an actor due to run time error
            $resultStatusHash->{message} = ( defined $1 ? $1 : '' );
            $resultStatusHash->{flag} = 1;
        }
        elsif ( $fields[5] =~ /^STATUS:END_WORKFLOW\s*(.*)$/ ) {
            $actorStatusHash->{$actorName} = 1;
        }
        elsif ( $fields[5] =~ /^STATUS:INFO\s*(.*)$/ ) {
            $resultStatusHash->{message} = ( defined $1 ? $1 : '' );
        }

    #Following two status lines (STATUS:START & STATUS:COMPLETED are there for
    #backward compatibility
        elsif ( $fields[5] =~ /^STATUS:START\s*(.*)$/ ) {
            $actorStatusHash->{message} = $1 if ( defined $1 );
        }
        elsif ( $fields[5] =~ /^STATUS:COMPLETED\s*(.*)$/ ) {
            $actorStatusHash->{$actorName} = 1;
            $resultStatusHash->{message} = $1 if ( defined $1 );
        }
        elsif ( $fields[5] =~ /^STATUS:PERCENTAGE\s*(.*)$/ ) {
            $actorStatusHash->{$actorName} = $1 * 1.0 / 100 if defined $1;
        }
    }

    #Sum up the percent complete of monitored actors (percentComplete=1 if
    #actors have completed)
    for ( my $i = 0; $i < @actorList; $i++ ) {
        $resultStatusHash->{percentComplete}
            += $actorStatusHash->{ $actorList[$i] };
    }
    $resultStatusHash->{percentComplete} *= 75.0 / @actorList;
    if ( $resultStatusHash->{flag} == 1 ) {
        $self->{_STATUS}{code} = 1;
        if ( $self->{_PORTAL} eq 'MAPSS' || $self->{_PORTAL} eq 'AEROSTAT' ) {
            $self->{_STATUS}{message} = $resultStatusHash->{message};
        }
        else {
            $self->{_STATUS}{message}
             = qq(We encountered an unexpected problem trying to finish your request. ) . 
            qq(<br/>Please send us <span class=\"inlineFeedbackLink\" onclick=\"session.sendFeedback(event,'workspace');\">feedback</span> and we'll investigate.);
        }
    }
    elsif ($resultStatusHash->{flag} == 0
        && $resultStatusHash->{percentComplete} < 75 )
    {
        if ( defined $self->{_TIMEOUT} ) {
            my $timeoutFlag = isTimeout( $self->{_LOGS}, $self->{_TIMEOUT} );
            if ( $timeoutFlag == 1 ) {
                $self->{_STATUS}{code} = 1;
                $self->{_STATUS}{message}
             = qq(We encountered an unexpected problem trying to finish your request. ) . 
               qq(<br/>Please send us <span class=\"inlineFeedbackLink\" onclick=\"session.sendFeedback(event,'workspace');\">feedback</span> and we'll investigate.); 
            }

        }
    }
    return $resultStatusHash;
}

################################################################################
sub extractDateTimeString {
    my ($datetimestr) = @_;
    my $datetime = substr( $datetimestr, 0, 20 );
    $datetime =~ s/^\s|\s$//;
    return $datetime;
}

## convert ISO8601 date time string to seconds
sub convertStringToDate {
    my ($datestr) = @_;
    my ( $year, $month, $day, $hour, $minute, $second )
        = $datestr =~ m{(....)-(..)-(..) (..):(..):(..)};
    $year -= 1900;
    $month--;
    my $seconds = timelocal( $second, $minute, $hour, $day, $month, $year );
    return $seconds;
}

## to calculate the elapsed time
sub calcElapseTime {
    my ( $start, $end ) = @_;
    my $elapse = $end - $start + 1;
    return $elapse;
}

sub getElapsedTime {
    my ($self) = @_;
    my $elapse = -1;
    my ( $starttime, $endtime );

    my @logs     = @{ $self->{_LOGS} };
    my $index    = 0;
    my $logCount = scalar(@logs);
    while ( $index < $logCount ) {
        my $item = $logs[$index];
        if (    $item =~ /ServiceManager/g
            and $item
            =~ m/STATUS:INFO Preparing to perform requested service/ )
        {
            my $dtstr = extractDateTimeString($item);
            $starttime = convertStringToDate($dtstr);
            last;
        }
        $index++;
    }

    $index = $logCount - 1;
    while ( $index >= 0 ) {
        my $item = $logs[$index];
        if (    $item =~ /ServiceManager/g
            and $item =~ m/STATUS:INFO Completed requested service/ )
        {
            my $dtstr = extractDateTimeString($item);
            $endtime = convertStringToDate($dtstr);
            last;
        }
        $index--;
    }

    if ( defined($starttime) && defined($endtime) ) {
        $elapse = calcElapseTime( $starttime, $endtime );
    }

    return $elapse;
}
################################################################################
sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    if ( $AUTOLOAD =~ /.*::getStatusCode/ ) {
        return $self->{_STATUS}{code} || 0;
    }
    elsif ( $AUTOLOAD =~ /.*::getStatusMessage/ ) {
        return $self->{_STATUS}{message};
    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        return ( $self->{_STATUS}{code} ? 1 : 0 );
    }
    elsif ( $AUTOLOAD =~ /.*::getLogs/ ) {
        return $self->{_LOGS};
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Giovanni::Status - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Giovanni::Status;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Giovanni::Status, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Mahabaleshwara S. Hegde, E<lt>mhegde@localdomainE<gt>

=cut
