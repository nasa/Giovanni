#$Id: Algorithm.pm,v 1.1 2015/04/14 21:01:20 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::Logger::Algorithm;

our $VERSION = '0.01';

use 5.008008;
use strict;
use warnings;

sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    if ( !defined( $self->{start_percent} ) ) {
        $self->{start_percent} = 0;
    }
    if ( !defined( $self->{end_percent} ) ) {
        $self->{end_percent} = 100;
    }

    $self->{percent_multiplier}
        = ( $self->{end_percent} - $self->{start_percent} ) / 100.0;
    return $self;
}

# publish a message to users
sub user_msg() {
    my ( $self, $msg ) = @_;
    print STDERR "USER_INFO $msg\n";
}

# give the percent done
sub percent_done() {
    my ( $self, $done ) = @_;

    $done = $done * $self->{percent_multiplier} + $self->{start_percent};
    print STDERR "PERCENT_DONE $done\n";
}

# debug level message - not shown to users
sub debug() {
    my ( $self, $msg ) = @_;
    print STDERR "DEBUG $msg\n";
}

# info level message - not shown to users
sub info() {
    my ( $self, $msg ) = @_;
    print STDERR "INFO $msg\n";
}

# warning level message - not shown to users
sub warning() {
    my ( $self, $msg ) = @_;
    print STDERR "WARN $msg\n";
}

# another way to call warning
sub warn() {
    my ( $self, $msg ) = @_;
    print STDERR "WARN $msg\n";
}

# error level message - not shown to users
sub error() {
    my ( $self, $msg ) = @_;
    print STDERR "ERROR $msg\n";
}

# error level message - shown to users
sub user_error() {
    my ( $self, $msg ) = @_;
    print STDERR "USER_ERROR $msg\n";
}

__END__

=head1 DESCRIPTION

Giovanni::Logger::Algorithm - Perl module for aG logging in the 
context of a 'science command', where log messages are written to STDERR. We
have some libraries that get used in both contexts. This logger has the same
log functions as Giovanni::Logger, so you can hand either one to a library as
long as it doesn't try to write lineage. 

=head1 SYNOPSIS

  use Giovanni::Logger::Algorithm;
  
  my $logger = Giovanni::Logger::Algorithm->new();
  $logger->info("Something useful");
  
  $logger = Giovanni::Logger::Algorithm->new(start_percent=>50,end_percent=>70);

=head2 CONSTRUCTOR

You can optionally specify a start_percent and/or end_percent, which will be
used by the percent_done() function to keep the percent done messages in the
specified range. E.g. - if you specify start_percent as 50 and end_percent as
70, then $logger->percent_done(50) will give the message 'PERCENT_DONE 60' 
because 60 is mid-way between 50 and 70.

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

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut
