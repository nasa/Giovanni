#!/usr/bin/perl 

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

#########################
#$Id: updateScrubbedDataFile.pl,v 1.25 2015/04/03 17:59:56 rstrub Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

updateScrubbedDataFile - this EDITCACHE workflow script uses Scrubber.pm to update attributes in cached files

=head1 PURPOSE 

To change the cached file attributes without having to rescrub the files (thousands of times faster).

=head1 DESCRIPTION  

runs as EDITCACHE workflow using editcache.make

=head1 SYNOPSIS1

For those writing clients (such as EDDA)

 1) create a sessionid by:
     calling http://HOST/giovanni/daac-bin/service_manager.pl
     parse the element session's  id attribute from the response for the SESSIONID
 2) http://giovanni-test.gesdisc.eosdis.nasa.gov/giovanni/daac-bin/service_manager.pl?dataFieldUnits=m^2&dataFieldLongName=TotalColumnCart&session=$SESSIONID&service=EDITCACHE&data=AIRX3STD_006_Temperature_A&portal=GIOVANNI&format=json
 3) poll the response you get from the above service_manager URL until percent complete = 75.

=head1 SYNOPSIS2

For those running from the commandline (operators running big editcache tasks)

perl  ./editCache.pl http://localhost/  <dataFiledId>  <rescrubber_field>=<value>


=head1 ARGUMENTS
 
 session=See above
 service=EDITCACHE
 data=<dataFieldId>
 portal=GIOVANNI
 format=json
 <keyword>=<value>  The keyword must be in the rescrubber.cfg 
 examples are:dataFieldUnits=m^2
              dataFieldLongName=some_longname 

=head1 EXTRA_CONFIG_FILE 

routinely this file can be ignored

 the rescrubber.cfg is found in the cfg directory and needs to contain:

 $ATTR_NAMES={ dataProductStartTimeOffset => dataFieldMeasurement,    dataFieldUnits => "units",  ...}
 $PROCESSING={   dataFieldUnits => "units", dataFieldLongName => long_name     
 $SHOW=100; frequency in which  to record line processing progress in workflow.log
 $PLEASEREVIEW=1; it uses ncdump -h to display the attr_value before and afterwards. 
                  (optional - spits out a lot of data to workflow.log)

=head1 HOWTOTEST/RUN

 Because of permission issues, the easiest way to test is in your docker cluster on your own machine
 clone an agiovanni_admin repo to a convenient spot on your machine
 cd to agiovanni_admin/Giovanni-Cache-Admin/scripts
 perl  ./editCache.pl http://localhost/  <dataFiledId>  <rescrubber_field>=<value>
 e.g.
 perl  ./editCache.pl http://localhost/ OMAERUVd_003_FinalAerosolAbsOpticalDepth388 dataFieldUnits=pressure,dataFieldLongName="New long name"

=head1 CHANGING MORE THAN ONE ATTRIBUTE

 in the service_manager url: name=value separated by &
 when using editCache.pl:    name=value separated by comma on commandline

=cut

# Set the library path
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use Safe;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;
use DB_File;
use File::Copy;
use CGI;
use Fcntl ':flock';
use Giovanni::Logger;
use Giovanni::Scrubber;
use Giovanni::Util;
use Getopt::Long;
use DateTime;
use Cwd qw(getcwd);
use strict;

$| = 1;

my $data_field_info_file;
my $noStderr;

GetOptions(
    'data-url-file=s'   => \$data_field_info_file,
);

# to validate inputs
if ( !( defined $data_field_info_file )  )
{
    usage();
    exit(1);
}

# Read the configuration file
# This path must be absolute or config file won't be read
my $giovanni_cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error            = Giovanni::Util::ingestGiovanniEnv($giovanni_cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Our own config file for white list etc
# This path must be absolute or config file won't be read
my $cfgFile = $rootPath . 'cfg/rescrubber.cfg';
my $gpt     = Safe->new('SCRUBBER');
$gpt->rdo($cfgFile);
my $cfghash = $SCRUBBER::ATTR_NAMES;

if ( !$cfghash ) {
    print STDERR "Unable to read rescrubbing cfgfile: $cfgFile\n";
    exit(1);
}

my $cache_dir = $GIOVANNI::CACHE_DIR;

my $logger;

if ( defined($noStderr) ) {
    $logger = Giovanni::Logger->new(
        session_dir       => getcwd(),
        manifest_filename => $data_field_info_file,
        no_stderr         => 1,
    );

}
else {
    $logger = Giovanni::Logger->new(
        session_dir       => getcwd(),
        manifest_filename => $data_field_info_file,
    );
}

$logger->info('Starting EDITCACHE');
eval {
    $logger->info( sprintf( "If the variable is completely populated, we expect this workflow to take %d minutes\n", 
    showEstimate($data_field_info_file) ) );
}; 
if ($?) {
    $logger->info("Estimate failed, but this is not very important");
}

# Reviewing what we got from the workflow:
my $query;
my $dataFieldId;
eval {
    my $xmlParser   = XML::LibXML->new();
    my $outDom      = $xmlParser->parse_file('input.xml');
    my $doc         = $outDom->documentElement();
    $dataFieldId = $doc->getElementsByTagName('data');
    $query       = $doc->getElementsByTagName('query');
};
if ($?) {
    $logger->error("Could not XML parse the session input.xml");
    $logger->error($?);
    exit(1);
}


my $isAVector = isAVectorVariable($data_field_info_file);
my $rescrub = Giovanni::Scrubber->new( 
        cache_dir  => $cache_dir,
        vector     => $isAVector,
        data_field => $dataFieldId );

# Read the query parms from input.xml and
# if check to see which ones are rescrubbing
# parms:
my @input = split( /&/, urldecode($query) );
my %input;
foreach my $input (@input) {
    my ( $key, $value ) = split( /=/, $input );
    $input{$key} = $value;
}

# Verify rescrubbing parameters:
my $status = $rescrub->handleInput( \%input );
if ( $status != 0 ) {
    myReport( $rescrub->{message}, 500 );
}

my $files = $rescrub->getFilenames();
if ( $#$files < 0) {
    if ( $rescrub->{message} !~ /no db_file yet/ ) {
        myReport( $rescrub->{message}, 500 );
    }
    else {
        myReport( $rescrub->{message}, 500 );
    }
    $files = ();
}
$logger->info( "n files to process:" . $#$files );

my $status;
my $ith;
my $SHOW = $SCRUBBER::SHOW || 1000;
my $total = $#$files + 1;

foreach my $file (@$files) {

    my $path = $rescrub->{cache_dir} . "/" . "$file";
    if ( !-e $path )
    {    # in case db file is out of sync!
        $logger->error(
            qq(OUT OF SYNC! $file is listed in .db file but does not exist at:$path)
        );
        next;
    }
    # perhaps the value has already been set to this new value:
    $status = $rescrub->reviewFile( "before", $file );

    if ( $status > 0 ) {
        myReport( $rescrub->{message} );
    }
    elsif ( $status == -1 ) {

        # report that update had already been done
        if ( $ith % $SHOW == 0 ) {
            myReport( $rescrub->{message} . "($ith)" );
        }
    }
    else {
        if ( $ith % $SHOW == 0 ) {
            if ( length $rescrub->{notice} ) {
                myReport( $rescrub->{notice} );
                $rescrub->deleteNotice();
            }
        }
    }

    if ($SCRUBBER::CONTINUEMODE) {

        # update has already been done
        if ( $rescrub->{set} eq "true" ) {
            ++$ith;
            $rescrub->{message} = "";
            next;
        }
        # if fail sleep and try again
        $status = $rescrub->updateFile($file);
        if ( $status != 0 ) {
            myReport( $rescrub->{message} . $file );
            sleep 1;
            ++$ith;

            # just continue on to next one. see if we can get that right.
            next;
        }
    }
    else {
        # if fail stop
        $status = $rescrub->updateFile($file);
        if ( $status != 0 ) {    # This 500 means the program will stop
            myReport( $rescrub->{message}, 500 );
        }
    }

    $status = $rescrub->reviewFile( "after", $file );
    if ( $status != 0 ) {
        myReport( $rescrub->{message} );
    }

    ++$ith;

    # Logging progress in workflow.log
    if ( $ith % $SHOW == 0 ) {
        myReport( $rescrub->{message} );
        $logger->info("processed $ith of $total");
        my $percent = int( ( $ith / $total ) * 100 ) if ( $ith > 0 );
        $logger->percent_done($percent);
    }

}

$logger->percent_done('100');
$logger->info(qq(EDITCACHE FINISHED SUCCESSFULLY));

sub myReport {
    my $message = shift;
    my $status  = shift;
    if ( $status > 0 and $status != 500 and length($message) > 1 ) {
        $message = qq($status: $message);
    }
    if ( length($message) > 1 ) {
        $logger->info($message);
    }
    if ( $status == 500 ) {
        $logger->error($message);
        exit 1;
    }
}

sub usage {
    print STDERR qq{$0  [-cache_dir=<testing_cache_dir>]  -datafield-info-file  <dataFieldUnits=m^2|dataFieldLongName=some_longname> \n};
    print STDERR qq{(options for the this last, positional argument, a single key/value pair, are in the rescrubber.cfg\n)};
}

sub urldecode {
    my $s = shift;
    $s =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    $s =~ s/\+/ /g;
    return $s;
}

sub isAVectorVariable {
    my $data_field_info_file = shift;
    if ( !-e $data_field_info_file ) {
        return 0;
    }
    my $xmlParser = XML::LibXML->new();
    my $outDom    = $xmlParser->parse_file($data_field_info_file);
    my $doc       = $outDom->documentElement();
    my $var       = $doc->getElementsByTagName('var')->[0];
    return  $var->getAttribute('vectorComponents');
}

sub showEstimate {
    my $data_field_info_file = shift;
    if ( !-e $data_field_info_file ) {
        return 0;
    }
    my $xmlParser = XML::LibXML->new();
    my $outDom    = $xmlParser->parse_file($data_field_info_file);
    my $doc       = $outDom->documentElement();
    my $var       = $doc->getElementsByTagName('var')->[0];
    my $startTime = $var->getAttribute('startTime');
    my $endTime   = $var->getAttribute('endTime');
    my $res       = $var->getAttribute('dataProductTimeInterval');
    my $sec       = 0;

    if ( $res eq 'hourly' ) {
        $sec = 3600;
    }
    elsif ( $res eq 'half-hourly' ) {
        $sec = 1800;
    }
    elsif ( $res eq '3-hourly' ) {
        $sec = 3600 * 3;
    }
    elsif ( $res eq 'daily' ) {
        $sec = 3600 * 24;
    }
    elsif ( $res eq 'monthly' ) {
        $sec = 3600 * 24 * 30;
    }
    elsif ( $res eq '8-daily' ) {
        $sec = 3600 * 24 * 8;
    }
    else {
        $sec = 3600;
    }
    my $startsec = iso2epoch($startTime);
    my $endsec   = iso2epoch($endTime);

    # 2038:
    if ( $endsec > time() ) {
        $endsec = time();
    }
    my $totalsec = $endsec - $startsec;
    my $files    = ( $totalsec / $sec );

    # We process about 30 per second.
    return ( $files / 30 ) / 60;
}

sub iso2epoch {
    my $string = shift;
    my ( $date, $time, $hr, $min, $sec );
    if ( $string =~ /[T ]/ ) {
        ( $date, $time ) = split( /[T ]/, $string );
        ( $hr, $min, $sec ) = split( '[:Z]', $time );
    }
    else {
        $date = $string;
    }
    $hr  ||= 0;
    $min ||= 0;
    $sec ||= 0;
    my ( $year, $mon, $mday ) = split( /[\-\.]/, $date );

    my $dt = DateTime->new(
        year   => $year,
        month  => $mon,
        day    => $mday,
        hour   => $hr,
        minute => $min,
        second => $sec
    );
    return $dt->epoch;
}


