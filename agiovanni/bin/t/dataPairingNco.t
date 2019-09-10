#!/usr/bin/env perl 

=head1 NAME

dataPairingNco.t - Unit test script for dataPairingNco.pl

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

dataPairingNco.t [--help] [--verbose]

=head1 DESCRIPTION

The script dataPairingNco.pl is a prgram that pairs data from multiple lists of
files for comparison analysis such as scatter plots.

=head1 OPTIONS

=over 4

=item --help
Print a usage information

=item --verbose
Turn on verbose mode

=back

=head1 AUTHOR

Jianfu Pan (jianfu.pan@nasa.gov)

=cut

use lib "../Giovanni-DataField/lib";
use lib "../Giovanni-BoundingBox/lib";
use lib "../Giovanni-Util/lib";
use lib "../Giovanni-Scrubber/lib";
use lib "../Giovanni-Data-NcFile/lib";
use lib "../Giovanni-ScienceCommand/lib";
use Test::More tests => 5;

use_ok('Giovanni::Data::NcFile');

$ENV{PERL5LIB}
    = "../Giovanni-DataField/lib:../Giovanni-BoundingBox/lib:../Giovanni-Util/lib:../Giovanni-Scrubber/lib:../Giovanni-Data-NcFile/lib:../Giovanni-ScienceCommand/lib:../Giovanni-WorldLongitude/lib:../Giovanni-Logger/lib:~/public_html/giovanni4/share/perl5";

use File::Temp 'tempdir';
use FindBin qw($Bin);
use Cwd 'abs_path';


# create a temporary directory to do everything in
my $dir = tempdir();

#
# Initial setting
#

my $ncfiles1 = [
    "$dir/dataPairingTRMM6_t_1.nc", "$dir/dataPairingTRMM6_t_2.nc",
    "$dir/dataPairingTRMM6_t_3.nc"
];
my $ncfiles2 = [
    "$dir/dataPairingTRMM7_t_1.nc", "$dir/dataPairingTRMM7_t_2.nc",
    "$dir/dataPairingTRMM7_t_3.nc"
];
my $inxml = "$dir/in_dataPairing_t.xml";
my $outfile
    = "$dir/pairedData.nc+nc.dataPairingTRMM6_t_1-dataPairingTRMM6_t_3.nc";

my $script = findScript('dataPairingNco.pl');

# Test existence of the script
ok( ( -f $script ), "Find $script" ) or die;

# Create test data
createTestData( $ncfiles1, $ncfiles2 );

# Create input xml file
open( FH, ">$inxml" ) || die "ERROR Fail to create input file $inxml";
print FH<<EOF;
<data>
  <dataFileList>
    <dataFile>$dir/dataPairingTRMM6_t_1.nc</dataFile>
    <dataFile>$dir/dataPairingTRMM6_t_2.nc</dataFile>
    <dataFile>$dir/dataPairingTRMM6_t_3.nc</dataFile>
  </dataFileList>
  <dataFileList>
    <dataFile>$dir/dataPairingTRMM7_t_1.nc</dataFile>
    <dataFile>$dir/dataPairingTRMM7_t_2.nc</dataFile>
    <dataFile>$dir/dataPairingTRMM7_t_3.nc</dataFile>
  </dataFileList>
</data>
EOF
close(FH);

# change to this directory so we are running the command here
$script = abs_path($script);
#chdir($dir);

# create the command
my $cmd = "$script -f $inxml -o $dir";
my $ret = system($cmd);
ok( $ret eq 0, "Script runs successfully: $cmd" ) or die;
ok( ( -f $outfile ), "Paired data file produced" ) or die;

# Test script results
$output = `ncdump -v time $outfile`;
($result) = ( $output =~ /data:.*time = (.*);/gs );
$result =~ s/\s//g;
ok( $result eq "1293834600,1293921000,1294007400", "Checking time results" );

#########################

sub createTestData {
    my ( $ncfiles1, $ncfiles2 ) = @_;

    my $ncfiles = [];
    push( @$ncfiles, @$ncfiles1 );
    push( @$ncfiles, @$ncfiles2 );

    # Read block at __DATA__ and write to a CDL file
    local ($/) = undef;
    my $cdldata = <DATA>;

    # Split the DATA text into three separate files
    my @cdl = ( $cdldata =~ m/(netcdf .*?\}\n)/gs );

    # Create nc files
    for ( my $i = 0; $i < scalar( @{$ncfiles} ); $i++ ) {
        Giovanni::Data::NcFile::write_netcdf_file( $ncfiles->[$i], $cdl[$i] );
    }
}

sub findScript {
    my ($scriptName) = @_;

    # see if this is right here
    my $script;
    if ( -f "../$scriptName" ) {
        ;
    }
    elsif ( -f "$scriptName" ) {
        $script = "$scriptName";
    }
    else {

        # see if we can find the script relative to our current location
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }

    return $script;
}

__DATA__
netcdf subsetted.TRMM_3B42_daily_precipitation_V6.20110101.78W_38N_76W_39N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 5 ;
variables:
    float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
        TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V6:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
        TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V6:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V6:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V6:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2010-12-31T22:30:00Z" ;
        :end_time = "2011-01-01T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  1.189815, 0.72, 0, 0, 0,
  1.5, 0, 0, 0, 0,
  15.45233, 2.28, 0, 3.96, 0,
  10.04339, 3.627545, 1.08, 2.28, 1.02 ;

 dataday = 2011001 ;

 lat = 38.625, 38.875, 39.125, 39.375 ;

 lon = -77.875, -77.625, -77.375, -77.125, -76.875 ;

 time = 1293834600 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V6.20110102.78W_38N_76W_39N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 5 ;
variables:
    float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
        TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V6:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
        TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V6:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V6:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V6:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2011-01-01T22:30:00Z" ;
        :end_time = "2011-01-02T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  12.43357, 8.339999, 16.44, 24.88912, 20.45774,
  3.42, 1.8, 5.88, 14.28, 15.25923,
  4.80126, 5.22, 7.08, 2.94, 4.56124,
  7.308801, 11.10249, 7.08, 2.94, 5.22 ;

 dataday = 2011002 ;

 lat = 38.625, 38.875, 39.125, 39.375 ;

 lon = -77.875, -77.625, -77.375, -77.125, -76.875 ;

 time = 1293921000 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V6.20110103.78W_38N_76W_39N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 5 ;
variables:
    float TRMM_3B42_daily_precipitation_V6(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V6:_FillValue = -9999.f ;
        TRMM_3B42_daily_precipitation_V6:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V6:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
        TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V6:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V6:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V6:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2011-01-02T22:30:00Z" ;
        :end_time = "2011-01-03T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 TRMM_3B42_daily_precipitation_V6 =
  0, 0, 0, 0, 0,
  0, 0, 0, 0, 0,
  0, 0, 0, 0, 0,
  0, 0, 0, 0, 0 ;

 dataday = 2011003 ;

 lat = 38.625, 38.875, 39.125, 39.375 ;

 lon = -77.875, -77.625, -77.375, -77.125, -76.875 ;

 time = 1294007400 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V7.20110101.78W_38N_76W_39N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 5 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2010-12-31T22:30:00Z" ;
        :end_time = "2011-01-01T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  0, 0, 0, 0, 0,
  3.06, 0, 0, 0, 0,
  7.29, 0, 0, 0, 0,
  0, 0, 0, 0, 0 ;

 dataday = 2011001 ;

 lat = 38.625, 38.875, 39.125, 39.375 ;

 lon = -77.875, -77.625, -77.375, -77.125, -76.875 ;

 time = 1293834600 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V7.20110102.78W_38N_76W_39N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 5 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2011-01-01T22:30:00Z" ;
        :end_time = "2011-01-02T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  4.68, 17.82, 26.28, 34.38, 27.96341,
  0, 15.66, 12.42, 23.4, 24.31846,
  0, 0, 0, 0, 12.48358,
  0, 0, 0, 0, 0 ;

 dataday = 2011002 ;

 lat = 38.625, 38.875, 39.125, 39.375 ;

 lon = -77.875, -77.625, -77.375, -77.125, -76.875 ;

 time = 1293921000 ;
}
netcdf subsetted.TRMM_3B42_daily_precipitation_V7.20110103.78W_38N_76W_39N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 5 ;
variables:
    float TRMM_3B42_daily_precipitation_V7(time, lat, lon) ;
        TRMM_3B42_daily_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_daily_precipitation_V7:coordinates = "time lat lon" ;
        TRMM_3B42_daily_precipitation_V7:grid_name = "grid-1" ;
        TRMM_3B42_daily_precipitation_V7:grid_type = "linear" ;
        TRMM_3B42_daily_precipitation_V7:level_description = "Earth surface" ;
        TRMM_3B42_daily_precipitation_V7:long_name = "Precipitation Rate" ;
        TRMM_3B42_daily_precipitation_V7:product_short_name = "TRMM_3B42_daily" ;
        TRMM_3B42_daily_precipitation_V7:product_version = "7" ;
        TRMM_3B42_daily_precipitation_V7:quantity_type = "Precipitation" ;
        TRMM_3B42_daily_precipitation_V7:standard_name = "r" ;
        TRMM_3B42_daily_precipitation_V7:units = "mm/day" ;
        TRMM_3B42_daily_precipitation_V7:latitude_resolution = 0.25 ;
        TRMM_3B42_daily_precipitation_V7:longitude_resolution = 0.25 ;
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :NCO = "4.3.1" ;
        :start_time = "2011-01-02T22:30:00Z" ;
        :end_time = "2011-01-03T22:29:59Z" ;
        :temporal_resolution = "daily" ;
        :nco_openmp_thread_number = 1 ;
data:

 TRMM_3B42_daily_precipitation_V7 =
  0, 0, 0, 0, 0,
  0, 0, 0, 0, 0,
  0, 0, 0, 0, 0,
  0, 0, 0, 0, 0 ;

 dataday = 2011003 ;

 lat = 38.625, 38.875, 39.125, 39.375 ;

 lon = -77.875, -77.625, -77.375, -77.125, -76.875 ;

 time = 1294007400 ;
}

