#!/usr/bin/env perl

=head1 NAME

runCacheWorkflow.pl - run the caching workflow to cache data in Giovanni4

=head1 SYNOPSIS

runCacheWorkflow.pl start end variable

=head1 DESCRIPTION

runCacheWorkflow.pl runs the caching workflow on Giovanni4sc and monitors the session directory 
for failure / success.  (It needs to run on giovanni4sc.) 
It was developed for NLDAS caching and, while probably reusable, is not exactly robust.

When complete, it copies the make.log to a log file in the current directory.
This makes it particularly amenable to be run as a multi-processing batch job using make.

Here is an example Makefile for SWDB_L310_004_angstrom_exponent_land. Note that the directory 
is the name of the variable, a fact that the Makefile relies upon (see VAR):
 START_YR = 1997
 END_YR = 2010
 YEARS = $(shell perl -e 'print join(" ", $(START_YR)..$(END_YR))')
 MONTHS =        01 02 03 04 05 06 07 08 09 10 11 12
 MONTH_DAYS =    31 29 31 30 31 30 31 31 30 31 30 31
 RANGES = $(foreach y,$(YEARS),$(foreach m,$(MONTHS),$y-$m-01.$y-$m-$(word $m,$(MONTH_DAYS))))
 MISSING = 2009-05-01.2009-05-31 2008-02-01.2008-02-29
 LOGS = $(RANGES:%=make.log.%.$(VAR))
 MISSING_LOGS = $(MISSING:%=make.log.%.$(VAR))
 VAR = $(shell basename $(shell pwd))
 
 all:    missing $(LOGS)

 $(LOGS): 
         runCacheWorkflow.pl `echo $@ | sed -e 's/make.log.//' -e 's/\./ /g'`

 missing:
         touch $(MISSING_LOGS)

Note, if you copy this Makefile, remember to change spaces to tabs in front of touch and runCacheWorkflow.pl.
This is typically run as B<nohup make -j 6 -l 7. -k &>, which runs 6 jobs simultaneously, unless the load is 7. 
or above, at which point it stops spawning new jobs. The B<-k> option tells it to keep going if a job fails.

=head1 EXAMPLE

runCacheWorkflow.pl 2001-01-01 2001-01-31 NLDAS_NOAH0125_H_002_soilm0_10cm

=head1 AUTHOR

Chris Lynnes, NASA/GSFC

=cut

use File::Temp;
use File::Copy;
use LWP::UserAgent;
$| = 1;
my $start = shift @ARGV;
my @now   = gmtime();
my $now   = sprintf( "%04d-%02d-%02d", $now[5] + 1900, $now[4] + 1, $now[3] );
my $end   = shift @ARGV;
my $var   = shift @ARGV;
my $logfile = "make.log.$start.$end.$var";

if ( -f $logfile ) {
    die "$logfile already exists\n";
}
if ( $now lt $start ) {
    system("echo future time > $logfile");
    exit(0);
}

# Truncate non-leap-year months
my ( $end_yr,   $end_mon,   $end_day )   = split( '-', $end );
my ( $start_yr, $start_mon, $start_day ) = split( '-', $start );
if ( ( $end_mon eq '02' ) && ( $end_yr % 4 ) && ( $end_day eq '29' ) ) {
    $end_day = 28;
    $end = join( '-', $end_yr, $end_mon, $end_day );
}

die "Usage: cache.pl start end var\n" unless ( $start && $end && $var );

my $session_id = sprintf(
    "CACHENNN-%02d%02d-%02d%02d-%02d%02d-%02d%02d%02d%02d%02d%02d",
    $now[5] % 100, $now[4] + 1,   $now[3] + 1,     $now[2],
    $now[1],       $now[0],       $start_yr % 100, $start_mon,
    $start_day,    $end_yr % 100, $end_mon,        $end_day
);
warn "Session id: $session_id\n";
my $template
    = 'http://giovanni4sc.gesdisc.eosdis.nasa.gov/daac-bin/giovanni/service_manager.pl?session=%s&service=CACHE&starttime=%sT00:00:00Z&endtime=%sT23:59:59Z&bbox=-91.4062,45.9141,-83.6719,46.6172&data=%s&portal=GIOVANNI&format=json';
my $url = sprintf $template, $session_id, $start, $end, $var;

# Make request
my $t0 = time();
warn "$t0 Request: $url\n";
my $ua = LWP::UserAgent->new();
$ua->env_proxy;
my $rc = $ua->get($url)->content;
my $tr = time();
my $dt = $tr - $t0;
warn "$tr ($dt) Got response\n";
my ( $session, $results_set, $result ) = ( $rc =~ /.*?"id" : "(.*?)"/sg );

unless ( $session && $results_set && $result ) {
    die "Could not get session directory from return $rc\n";
}
my $dir = "/giovanni/OPS/session/$session/$results_set/$result";
unless ( -d $dir ) {
    die "$dir is not a directory\n";
}

# mfst.data_field_url+dNLDAS_FORA0125_H_002_apcpsfc+t19800101000000_19800131235959.xml
my $data_field_url_log
    = sprintf(
    "%s/mfst.data_field_url+d%s+t%04d%02d%02d000000_%04d%02d%02d235959.log",
    $dir, $var, $start_yr, $start_mon, $start_day, $end_yr, $end_mon,
    $end_day );
warn "Looking for $data_field_url_log...\n";
while ( !-s $data_field_url_log ) {
    my $t = time();
    sleep(2);
}
my $rc
    = system(
    "grep 'USER_MSG Input Error: End time must not be before' $data_field_url_log"
    );
if ( $rc == 0 ) {
    warn "Period before data starts, exiting 0\n";
    exit(0);
}

# mfst.result+dNLDAS_FORA0125_H_002_apcpsfc+t19800101000000_19800131235959.xml
my $mfst
    = sprintf(
    "%s/mfst.result+d%s+t%04d%02d%02d000000_%04d%02d%02d235959.xml",
    $dir, $var, $start_yr, $start_mon, $start_day, $end_yr, $end_mon,
    $end_day );

my $log = "$dir/make.log";
while ( !-s $mfst ) {
    my $t  = time();
    my $dt = $t - $t0;
    printf "Elapsed: %02d:%02d\r", $dt / 60, $dt % 60;
    sleep(10);
}
warn "Found $mfst\n";

copy( $log, $logfile );
my $t1 = time();
exit(0);
