package Giovanni::Untaint;

our $VERSION = '0.01';

use 5.010001;
use strict;
use warnings;

use URI::URL qw();    # suppress importation of function called 'url'
use Date::Manip qw();
use Scalar::Util qw(looks_like_number);
use JSON qw(decode_json);

use Giovanni::Util;
use Giovanni::BoundingBox;

sub new {
    my ( $pkg, %params ) = @_;

    my $self = bless \%params, $pkg;
    if ( !defined( $self->{INPUT_REGEX} ) ) {
        die "INPUT_REGEX parameter is required";
    }

    return $self;
}

sub number {
    my ( $self, $number_str ) = @_;
    my $success   = 0;
    my $untainted = '';

    if ( $number_str =~ $self->{INPUT_REGEX}->{number} ) {
        my $result = $1;

        if ( looks_like_number($result) ) {
            $success   = 1;
            $untainted = $result;
        }
    }

    return ( $success, $untainted );
}

sub UUID {
    my ( $self, $uuid_str ) = @_;
    my $success   = 0;
    my $untainted = '';

    if ( $uuid_str =~ $self->{INPUT_REGEX}->{uuid} ) {
        my $result = $1;

        if ( Giovanni::Util::isUUID($result) ) {
            $success   = 1;
            $untainted = $result;
        }
    }

    return ( $success, $untainted );
}

sub result {
    my ( $self, $session, $resultset, $result ) = @_;
    my $session_untainted   = '';
    my $resultset_untainted = '';
    my $result_untainted    = '';

    ( my $s_success,   $session_untainted )   = $self->UUID($session);
    ( my $s_resultset, $resultset_untainted ) = $self->UUID($resultset);
    ( my $s_result,    $result_untainted )    = $self->UUID($result);

    if ( $s_success && $s_resultset && $s_result ) {
        return ( 1, $session_untainted, $resultset_untainted,
            $result_untainted );
    }
    else {
        return ( 0, '', '', '' );
    }
}

sub bbox {
    my ( $self, $bbox_str ) = @_;

    if ( $bbox_str =~ $self->{INPUT_REGEX}->{bbox} ) {
        my $untainted = $1;

        # try parsing as a bounding box
        my $bbox;
        eval { $bbox = Giovanni::BoundingBox->new( STRING => $untainted ) };
        if ($@) {
            return ( 0, '' );
        }

        # looks reasonable.
        return ( 1, $untainted );

    }

    # didn't pass regex
    return ( 0, '' );
}

sub filename {
    my ( $self, $filename, $extension ) = @_;

    if ( $filename =~ $self->{INPUT_REGEX}->{filename} ) {
        my $untainted = $1;

        # see if this is either '.' or '..', which are directories
        if ( $untainted eq '.' || $untainted eq '..' ) {
            return ( 0, '' );
        }

        if ( defined($extension) ) {

            # see if this extension matches the end of the filename
            my $ex_len = length($extension);
            my $f_len  = length($filename);
            if ( !Giovanni::Util::strEndsWith( $filename, $extension ) ) {
                return ( 0, '' );
            }
        }

        return ( 1, $1 );
    }

    # didn't pass regex
    return ( 0, '' );
}

sub url {
    my ( $self, $url_str, $trusted_servers ) = @_;

    if ( $url_str =~ $self->{INPUT_REGEX}->{url} ) {
        my $untainted = $1;

        my $url = URI::URL->new($untainted);
        if ( !$url ) {

            # didn't parse at all. Who knows what this is!
            return ( 0, '' );
        }

        if ( !$url->scheme() ) {

            # no scheme. Okay. This is a relative URL.
            # E.g. "./daac-bin/somecgi.pl?first=something_useful"
            return ( 1, $untainted );
        }

        # If we have an invalid URL, $url->host() can make the code die.
        my $host = eval('$url->host();');
        if ( !defined($host) ) {
            return ( 0, '' );
        }

        for my $server (@$trusted_servers) {
            if ( Giovanni::Util::strEndsWith( $host, $server ) ) {
                return ( 1, $untainted );
            }
        }

    }

    # didn't pass regex
    return ( 0, '' );
}

sub time {
    my ( $self, $time_str ) = @_;

    # break up the time string on '/'
    my @times = split( /\//, $time_str );

    my @all_untainted = ();

    for my $time (@times) {
        if ( $time =~ $self->{INPUT_REGEX}->{time} ) {
            my $untainted = $1;
            my $parsed    = Date::Manip::ParseDate($untainted);
            if ( !$parsed ) {

                # not a valid date
                return ( 0, '' );
            }
            push( @all_untainted, $untainted );
        }
        else {

            # does not pass regular expression
            return ( 0, '' );
        }
    }

    # return the times joined back together again
    return ( 1, join( '/', @all_untainted ) );

}

sub layers {
    my ( $self, $layers_str ) = @_;

    # break up the layers on ','
    my @layer_arr = split( /,/, $layers_str );

    my @all_untainted = ();

    for my $layer (@layer_arr) {
        if ( $layer =~ $self->{INPUT_REGEX}->{data} ) {
            my $untainted = $1;
            push( @all_untainted, $untainted );
        }
        else {

            # does not pass regular expression
            return ( 0, '' );
        }
    }

    # return the layers joined back together again
    return ( 1, join( ',', @all_untainted ) );
}

sub json {
    my ( $self, $json_str ) = @_;

    # we are going to use .* (eek!) to untaint because then we're going
    # to try to decode it as json, which is the real test.
    $json_str =~ /(.*)/;
    my $untainted = $1;

    eval('decode_json($untainted)');

    # return 0 if the decode failed
    return $@ ? (0, '') : (1, $untainted);

}

__END__

=head1 NAME

Giovanni::Untaint - Perl extension for for untainting cgi inputs that require
more than a regex

=head1 SYNOPSIS

  use Giovanni::Untaint;

  ...

  BEGIN {
      $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
      push( @INC, $rootPath . 'share/perl5' )
          if defined $rootPath;
  }
  $| = 1;


  my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
  my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
  Giovanni::Util::exit_with_error($error) if ( defined $error );

  my $untaint = Giovanni::Untaint(INPUT_REGEX => \%Giovanni::INPUT_REGEX);

  my $cgi = new CGI->new();

  my ($success, $session, $resultset, $result)
      = $untaint->result( $cgi->param("session"),
                          $cgi->param("resultset"),
                          $cgi->param("result") );

  if ( !$success ) {
    print STDERR "Unable to validate and untaint session, resultset, and result.";
    exit(1);
  }



=head1 DESCRIPTION

Some cgi inputs require more validation than a simple regular expression. This
library has that validation.

=head1 FUNCTION: new(INPUT_REGEX=>\%GIOVANNI::INPUT_REGEX)

Creates a new untainter. Takes the INPUT_REGEX hash from giovanni.cfg as input.

=head1 FUNCTION: ($success, $untainted) = $untaint->number($number)

Untaints and verifies something is a number. Returns $success as true and the
untainted string if successful.

=head1 FUNCTION: ($success, $untainted) = $untaint->UUID($uuid)

Untaints and verifies a UUID. Returns $success as true and the untainted
string if successful.

=head1 FUNCTION: ($success, $u_session, $u_resultset, $u_result) = $untaint->($session, $resultset, $result)

Untaints and verifies the session, resultset, and result all at once. Returns
$success as true and the untainted strings if successful.

=head1 FUNCTION: ($success, $untainted) = $untaint->bbox($bbox_string);

Untaints a bounding box consisting of 4 numbers separated by commas. North
and south (last and second numbers) must be between -90 and 90. Returns $success
as true and the untainted bounding box string if successful.

=head1 FUNCTION ($success, $untainted) = $untaint->filename($filename, '.nc');

Untaints a filename, makes sure it is not '.' or '..', and optionally checks
the extension. To skip the extension, don't specify the $extension parameter.
The extension parameter is NOT a regular expression. This is a straight-up
string comparison. Returns $success as true and the untainted filename if
successful.

=head1 FUNCTION ($success, $untainted) = $untaint->url($url, \@GIOVANNI::TRUSTED_SERVERS);

Untaints a URL, making sure that the host matches one of the servers in the list
passed in. Returns $success as true and the untainted url if successful.

=head1 FUNCTION ($success, $untainted) = $untaint->time($time);

Untaints one or more times separated by a forward slash ('/'). Returns 
$success as true and the untainted time string if successful.

=head1 FUNCTION ($success, $untainted) = $untaint->layers($layers);

Untaints one or more image layers separated by a comma. Returns $success as 
true and the untainted string if successful. NOTE: background layers use
the same regular expression as data layers, the INPUT_REGEX{data} expression
from giovanni.cfg.

=head1 Function ($success, $untainted) = $untaint->json($json);

Untaints a json string. Returns $success as true and the untainted string if 
the input string is valid json.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut
