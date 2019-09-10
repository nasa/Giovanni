package Giovanni::Logger;

our $VERSION = '0.01';

use 5.008008;
use strict;
use warnings;

use Log::Log4perl qw(get_logger :levels :nowarn);
use XML::LibXML;
use Data::UUID;
use Time::HiRes qw(tv_interval gettimeofday);
use Giovanni::Logger::InputOutput;
use File::Basename;

# Constructs a new logger class. Requires the session directory and step name.
# The step name should be the same as the build target.
sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    # figure out the time we are starting with
    $self->{start_time} = [ gettimeofday() ];

    if ( exists( $params{"session_dir"} ) ) {

        # we are going to create a file logger and write lineage

        # check to make sure we have the step id
        if ( !( exists $params{"manifest_filename"} ) ) {
            die
                "Logger constructor must have a 'manifest_filename' key in the hash";
        }

        # figure out the name of the log file
        my $manifest_filename = basename( $self->{manifest_filename} );
        $self->{log_filename} = "$manifest_filename.log";
        if ( $manifest_filename =~ m/(.*)[.].*/ ) {

            # get everything before the suffix
            $self->{log_filename} = "$1.log";
        }

        # log name that shows up in the log file. This is everything between
        # msft and the first plus sign.
        my $log_name = $manifest_filename;
        if ( $log_name =~ m/^mfst[.](.*?)[+].*$/ ) {    # non-greedy .*
            $log_name = $1;
        }

        # add a UUID to the logger name, just like we do in java, to make sure
        # that logger names are unique across sessions.
        my $ug      = new Data::UUID;
        my $uuidStr = $ug->to_string( $ug->create() );

        my $full_log_name = "$uuidStr.$log_name";
        $self->{logger} = Log::Log4perl->get_logger($full_log_name);

        # figure out the name of the lineage file
        my $lineage_filename = "prov.$manifest_filename.xml";
        if ( $manifest_filename =~ m/mfst[.](.*)/ ) {
            $lineage_filename = "prov.$1";
        }
        $self->{lineage_file}
            = $self->{session_dir} . "/" . $lineage_filename;
    }
    else {

        # if there is no file log, just give the logger a UUID string
        my $ug      = new Data::UUID;
        my $uuidStr = $ug->to_string( $ug->create() );

        $self->{logger} = Log::Log4perl->get_logger($uuidStr);
    }
    $self->_config_log();

    return $self;
}

# Configure the log level and file appender.
sub _config_log() {
    my ($self) = @_;

    # set the log level
    $self->{logger}->level($TRACE);

    # create a layout
    my $layout = Log::Log4perl::Layout::PatternLayout->new(
        "%d{yyyy-MM-dd HH:mm:ss,SSS} - [%-5p] - %c{1} - %m%n");

    if ( exists( $self->{session_dir} ) ) {
        my $logfile = $self->{session_dir} . "/" . $self->{log_filename};

        # set the file appender
        my $file_appender = Log::Log4perl::Appender->new(
            "Log::Log4perl::Appender::File",
            filename => $logfile,
            mode     => "append"
        );
        $self->{logger}->add_appender($file_appender);
        $file_appender->layout($layout);
    }

    if ( !$self->{no_stderr} ) {

        # and a stderr appender
        my $stderr_appender
            = Log::Log4perl::Appender->new( "Log::Log4perl::Appender::Screen",
            stderr => 1, );
        $self->{logger}->add_appender($stderr_appender);
        $stderr_appender->layout($layout);
    }

}

# publish a message to users
sub user_msg() {
    my ( $self, $msg ) = @_;
    $self->{logger}->info("USER_MSG $msg");
}

# give the percent done
sub percent_done() {
    my ( $self, $done ) = @_;
    $self->{logger}->info("PERCENT_DONE $done");
}

# debug level message - not shown to users
sub debug() {
    my ( $self, $msg ) = @_;
    $self->{logger}->debug($msg);
}

# info level message - not shown to users
sub info() {
    my ( $self, $msg ) = @_;
    $self->{logger}->info($msg);
}

# warning level message - not shown to users
sub warning() {
    my ( $self, $msg ) = @_;
    $self->{logger}->warn($msg);
}

# another way to call warning
sub warn() {
    my ( $self, $msg ) = @_;
    $self->warning($msg);
}

# error level message - not shown to users
sub error() {
    my ( $self, $msg ) = @_;
    $self->{logger}->error($msg);
}

# error level message - shown to users
sub user_error() {
    my ( $self, $msg ) = @_;
    $self->{logger}->error("USER_ERROR $msg");
}

# writes the lineage file. Takes the inputs:
# name=>"step name", inputs=>[input1, input2],
# outputs=>[output1 output2], messages=>['first message', 'second message'].
sub write_lineage() {
    my ( $self, %params ) = @_;

    # calculate elapsed time
    my $elapsed = tv_interval( $self->{start_time} );

    my $doc  = XML::LibXML::Document->createDocument();
    my $root = $doc->createElement("step");
    $doc->setDocumentElement($root);
    $root->setAttribute( "ELAPSED_TIME", $elapsed );
    $root->setAttribute( "NAME",         $params{"name"} );

    # add inputs
    my $inputsElement = $doc->createElement("inputs");
    $root->addChild($inputsElement);
    for my $input ( @{ $params{"inputs"} } ) {
        my $inputElement = $doc->createElement("input");
        $input->add_attributes($inputElement);
        $inputsElement->appendChild($inputElement);
    }

    # add outputs
    my $outputsElement = $doc->createElement("outputs");
    $root->addChild($outputsElement);
    for my $output ( @{ $params{outputs} } ) {
        my $outputElement = $doc->createElement("output");
        $output->add_attributes($outputElement);
        $outputsElement->appendChild($outputElement);
    }

    # add messages
    my $messagesElement = $doc->createElement("messages");
    $root->addChild($messagesElement);
    for my $message ( @{ $params{messages} } ) {
        my $messageElement = $doc->createElement("message");
        $messageElement->appendTextNode($message);
        $messagesElement->appendChild($messageElement);
    }

    # write out to the lineage file
    open( LINEAGE, ">$self->{lineage_file}" )
        or die "Unable to open lineage file $self->{lineage_file}: $?";

    print LINEAGE $doc->toString();

    close(LINEAGE);

    # write something to the log
    $self->info( "Wrote lineage for step '" . $params{"name"} . "'" );
}

# Added to make sure the log file always says 100 percent done.
sub DESTROY {
    my ($self) = @_;
    $self->percent_done(100);
}

1;
__END__

=head1 NAME

Giovanni::Logger - Perl module for aG logging 

=head1 ABSTRACT

This class encapsulates all logging.

=head1 SYNOPSIS

  use Giovanni::Logger;
  
  # Let's assume that the task name and session directories are from the
  # command line
  my $task_name = $ARGV[0];
  my $session_dir = $ARGV[1];
  
  # Get a logger with the name of the task in the build file. Your command
  # can get this via the command line.
  my $util = Giovanni::Logger->new(session_dir=>$session_dir,
                manifest_filename=>$task_name);
  
  # write some messages to the log
  $util->info("Useful message for the log file");
  $util->user_msg("Something users should know");
  
  # Tell the log that we are at 100.
  $util->percent_done(100);

=head1 DESCRIPTION

This code provides utilities for aG logging.

=head2 CONSTRUCTOR

B<Giovanni::Logger-E<gt>new(session_dir=E<gt>$session_dir,manifest_filename=E<gt>$task_name)>
The constructor has two mandatory arguments - the session directory (location 
of the log) and the task name. This task name should be the name of the build 
target in the build file.

By default, the logger will also write to stderr. If you don't want this behavior, add
no_stderr=>1 to the constructor.

=head2 LOGGING

Logging serves two purposes (1) 'user messages' let users know how much 
progess has been made and (2) informational messages to just the log let us
debug problems. In general, more information is better.

B<util-E<gt>percent_done($percent)> I<[mandatory for long steps]> Update the 
user's status bar. Should be a number between 0 and 100.

B<util-E<gt>user_msg($msg)> Info level log messages. Shown to users.

B<util-E<gt>debug($msg)> Debug level log messages. NOT shown to users.

B<util-E<gt>info($msg)> Information level log messages. NOT shown to users.

B<util-E<gt>warn($msg)> Warning level log messages. NOT shown to users.

B<util-E<gt>error($msg)> Error level log messages. NOT shown to users.

B<util-E<gt>user_error($msg)> Error level log messages. Shown to users.

=head2 LINEAGE

When everything is finished, write the lineage.

B<util-E<gt>write_lineage(name=>"step name", inputs=>[input1, input2], 
outputs=>[output1 output2], messages=>['first message', 'second message']).

where the inputs and outputs are of type Giovanni::Logger::InputOutput. The
code will take care of calculating the elapsed time between creations of the
logger and creation of the lineage file.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut
