#$Id: Giovanni-WorldLongitude_noLongitude.t,v 1.1 2014/08/19 19:01:23 csmit Exp $
#-@@@ GIOVANNI,Version $Name:  $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-Algorithm-GridNormalizer.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::WorldLongitude') }

#########################

use File::Temp qw/ tempdir /;
use Giovanni::Data::NcFile;
use Giovanni::Logger;

# create a working directory
my $dir = tempdir( CLEANUP => 1 );

# create the input data file
my ($inCdl) = readCdlData();

my $dataFile
    = "$dir/correlation.TRMM_3B42_daily_precipitation_V6+TRMM_3B42_daily_precipitation_V7.20030101-20030105.nc";
Giovanni::Data::NcFile::write_netcdf_file( $dataFile, $inCdl )
    or die "Unable to write input file.";

# create a logger
my $logger = Giovanni::Logger->new(
    session_dir       => $dir,
    manifest_filename => "mfst.blah+whatever.xml"
);

my $outFile = "$dir/out.nc";

# NOTE: this file doesn't have a longitude variable, so we shouldn't do
# anything...
my $normalized = Giovanni::WorldLongitude::normalizeIfNeeded(
    logger       => $logger,
    in           => [$dataFile],
    out          => [$outFile],
    startPercent => 50,
    endPercent   => 100,
    sessionDir   => $dir,
);
ok( !$normalized, "File was not normalized" ) or die;

ok( !( -e $outFile ), "No output file" ) or die;

sub readCdlData {

    # read block at __DATA__ and write to a CDL file
    #(stolen from Chris...)
    my @cdldata;
    while (<DATA>) {
        push @cdldata, $_;
    }
    my $allCdf = join( '', @cdldata );

    # now divide up
    my @cdl = ( $allCdf =~ m/(netcdf .*?\}\n)/gs );
    return @cdl;
}

#http://s4ptu-ts2.ecs.nasa.gov/giovanni/#service=CORRELATION_MAP&starttime=2003-01-01T00:00:00Z&endtime=2003-01-05T23:59:59Z&bbox=171.8437,-22.5,-176.2032,-14.0625&data=TRMM_3B42_daily_precipitation_V6%2CTRMM_3B42_daily_precipitation_V7&dataKeyword=TRMM
# removed everything except the latitude variable
__DATA__
netcdf correlation.TRMM_3B42_daily_precipitation_V6+TRMM_3B42_daily_precipitation_V7.20030101-20030105 {
dimensions:
    lat = UNLIMITED ; // (34 currently)
variables:
    double lat(lat) ;
        lat:long_name = "latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :nco_openmp_thread_number = 1 ;
        :NCO = "4.3.1" ;
        :title = "Correlation of Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 6] vs. Daily Rainfall Estimate from 3B42 V7, TRMM and other sources, 0.25 deg. [TRMM_3B42_daily 7]" ;
        :matched_start_time = "2003-01-01T00:00:00Z" ;
        :matched_end_time = "2003-01-05T23:59:59Z" ;
        :input_temporal_resolution = "daily" ;
data:

 lat = -22.375, -22.125, -21.875, -21.625, -21.375, -21.125, -20.875, 
    -20.625, -20.375, -20.125, -19.875, -19.625, -19.375, -19.125, -18.875, 
    -18.625, -18.375, -18.125, -17.875, -17.625, -17.375, -17.125, -16.875, 
    -16.625, -16.375, -16.125, -15.875, -15.625, -15.375, -15.125, -14.875, 
    -14.625, -14.375, -14.125 ;

}
