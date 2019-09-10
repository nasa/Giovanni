package Giovanni::BinLogger;

# A log4perl module.
# Uses .../cfg/giovanni/bin_log4perl.cfg
# Borrowed and modified from CUAHSI project which was in turn borrowed and simplified from Mirador.
#
# Author rstrub

our $VERSION = '0.01';

use Log::Log4perl;
use Log::Dispatch;
use Safe;
use File::Basename;
use File::Spec;
use Date::Format;

use vars qw($BASE);

BEGIN {
    $0 =~ m#^(.*)/# and $CGIBIN = $1 or $CGIBIN = '.';
    $BASE = "$CGIBIN/../../../";
}

use strict;

my $logFileLoc;

sub new {
    my $pkg  = shift;
    my %args = @_;

    my $self = \%args;
    if ( ref $self ne 'HASH' ) {
        return "I need to be invoked with a hash";
    }
    my $flavor = $self->{config} || 'RODS';

    #scrubber_config($flavor,$self->{rootPath});

    # evaluate logger type
    my $logtype = basename $self->{logFile} || "defaultLogger";
    ($logtype) = ( $logtype =~ /([^\.]*)\.?/ );
    $self->{logtype} = $logtype;

    # end - evaluate logger type

    my $date_str = time2str( '%Y_%m_%d', time );

    #$self->{logFile} = qq($self->{logFile}.${date_str}.$$.log);
    $self->{logFile} = qq($self->{logFile}.log);
    $logFileLoc = $self->{logFile};
    print STDERR "rescrubber log location: $logFileLoc\n";

    my $mode   = 0775;
    my $status = 42;
    my ( $fn, $dirs, $suffix ) = fileparse( $self->{logFile}, qr/\.[^.]*/ );

    if ( ( $status = mkdir "$dirs" ) || $! =~ /File exists/ ) {
        chmod $mode, "$dirs";
    }
    else {
        print STDERR "Unable to mkdir $dirs/\n $!\n";
    }
    print STDERR "mkdir returned: $status and $!\n" if ( $status != 0 );

    # Here rootPath alread has cfg/giovanni added to it
    Log::Log4perl->init( $self->{logConfig} );

    $self->{logger} = Log::Log4perl::get_logger( $self->{logtype} );
    $self->{logger}{level} = ( $self->{level} eq 'debug' ) ? 'DEBUG' : 'INFO';

    print STDERR "OUTPUT LOG: $logFileLoc\n";
    bless $self, $pkg;
    return $self;
}

sub getFileName {
    return $logFileLoc;
}

sub getLevel {
    my $string = uc shift;

    return 'DEBUG' if ( $string eq 'DEBUG' );
    return 'DEBUG' if ( $string eq 'INFO' );
    return 'DEBUG' if ( $string eq 'WARN' );
    return 'DEBUG' if ( $string eq 'ERROR' );
    return 'DEBUG' if ( $string eq 'FATAL' );
}

sub logprint {
    my $self     = shift;
    my $message  = shift;
    my $level    = shift;
    my $function = shift;
    my $line     = shift;

    # What we are doing here is writing directly to the log
    # subroutines hash and array are receiving objects to be logged
    # rather than a string
    if ( open( HACKTHELOGFILE, ">>$self->{logFile}" ) ) {

        #$main::logger->{logger}->debug(sprintf("%s %s %s %s\n",
        print HACKTHELOGFILE
            sprintf( "%s %s %s %s\n", $level, $function, $line, $message );
        close(HACKTHELOGFILE);
    }
    else {
        $self->{logger}->error("Could not write selfwrite to logfile");
    }
}

# To conveniently log the entire contents of hashes
sub hash {
    my $self     = shift;
    my $hash     = shift;
    my $level    = shift;
    my $file     = shift;
    my $function = shift;
    my $line     = shift;

    my $Level = getLevel($level);
    if ( $Level < $self->{$level} ) {

        # Don't print if less than established level
        $self->{logger}->debug("level $level is not being printed");
        return 0;
    }

    if ( ref $hash eq "HASH" ) {
        foreach my $key ( keys %$hash ) {
            if ( !ref $key ) {
                my $item = qq($key -> $hash->{$key});
                logprint( $self, $item, $level, $function, $line );
            }
        }
    }
    else {
        $self->{logger}->error(
            "Could not run hash method: ref of " . $hash . " not eq HASH" );
    }
}

# To conveniently log arrays
sub array {
    my $self     = shift;
    my $array    = shift;
    my $level    = shift;
    my $file     = shift;
    my $function = shift;
    my $line     = shift;

    my $Level = getLevel($level);
    if ( $Level < $self->{$level} ) {

        # Don't print if less than established level
        $self->{logger}->debug("level $level is not being printed");
        return 0;
    }

    if ( ref $array eq "ARRAY" ) {
        foreach my $item (@$array) {
            if ( !ref $item ) {
                logprint( $self, $item, $level, $function, $line );
            }
        }
    }
    else {
        $self->{logger}
            ->error("Could not run array method, it didn't ref to an ARRAY");
    }
}

sub scrubber_config {

    my $LIB     = shift || "rescrubber";
    my $base    = shift;
    my $cfgfile = "$base/rescrubber.cfg";

    #print STDERR "$LIB config: $cfgfile\n";

    my $cpt = new Safe 'CFG';

    if ( !$cpt->rdo($cfgfile) ) {
        print STDERR
            "Unable to read/find $cfgfile. Check location, formatting, syntax, and permissions.\n";
        print STDERR "Please define LOGCONFIG";

        # There is not much more that we can do without configuration,
        # so exit.
        exit;
    }

    return $cpt;
}

1;
