#!/usr/bin/env perl
#$Id: Giovanni-Serializer-TimeSeries_TRMM.t,v 1.4 2015/02/20 17:29:08 rstrub Exp $
#-@@@ Giovanni, Version $Name:  $

use strict;
use File::Temp qw/ tempdir /;
use Test::More tests => 6;
BEGIN { use_ok('Giovanni::Serializer::TimeSeries') }

# create a temporary directory
my $tempDir = tempdir( "test_XXXXX", CLEANUP => 1 );

## to generate the source testing file, and the expected file
my $filename = "";
my $ncfile   = "";
while (<DATA>) {
    if ( $_ =~ /^FILE=/ ) {
        $filename = $_;
        $filename =~ s/^FILE=//;
        chomp($filename);
        $filename = "$tempDir/$filename";
        open FH, ">", "$filename";
        next;
    }
    if ( $_ =~ /^ENDFILE/ ) {
        close(FH);
        ok( ( -f $filename ), "Create \"$filename\"" );

        ## convert .cdl to .nc
        if ( $filename =~ /\.cdl$/ ) {
            $ncfile = $filename;
            $ncfile =~ s/(\.cdl)$/\.nc/;
            `ncgen -b -o $ncfile $filename`;
            ok( ( -e $ncfile ), "File not exist: $ncfile" );
        }
        next;
    }
    print FH $_;
}

# write it out as netcdf
my $input = "$tempDir/input.xml";

my $csvFile = Giovanni::Serializer::TimeSeries::serialize(
    input  => $input,
    ncFile => $ncfile,
    outDir => $tempDir
);

# make sure the csv file was created
ok( -e $csvFile, "Output csv file exists" );

# read it out.
open( FILE, "<", $csvFile ) or die $!;
my $csvText = join( "", <FILE> );
close(FILE);

# make sure that the data is the file correctly
ok( $csvText =~ m/2003-01-01 00:00:00,15.551931/, "data point correct" );

# writes the cdl to a temp netcdf file
sub writeNetCdf {
    my ( $cdl, $tempDir ) = @_;

    # write the cdl to a temp file
    my $tempCdlFile = "$tempDir/file.cdl";
    open( FILE, ">", $tempCdlFile );
    print FILE $cdl;
    close(FILE);

    my $tmpNcFile = "$tempDir/file.nc";

    my $cmd = "ncgen -o $tmpNcFile $tempCdlFile";
    die "Failed to run: $cmd" unless ( system($cmd) == 0 );

    return $tmpNcFile;
}

sub readCdlData {

    # read block at __DATA__ and write to a CDL file
    #(stolen from Chris...)
    my @cdldata;
    while (<DATA>) {
        push @cdldata, $_;
    }
    return ( join( '', @cdldata ) );
}

__DATA__
FILE=areaAvg.TRMM_3B42_daily_precipitation_V6.20030101-20030101.92W_26N_73W_38N.cdl
netcdf areaAvg.TRMM_3B42_daily_precipitation_V6.20030101-20030101.92W_26N_73W_38N {
dimensions:
        time = UNLIMITED ; // (1 currently)
variables:
        double TRMM_3B42_daily_precipitation_V6(time) ;
                TRMM_3B42_daily_precipitation_V6:_FillValue = -9999. ;
                TRMM_3B42_daily_precipitation_V6:Serializable = "True" ;
                TRMM_3B42_daily_precipitation_V6:coordinates = "time" ;
                TRMM_3B42_daily_precipitation_V6:grid_name = "grid-1" ;
                TRMM_3B42_daily_precipitation_V6:grid_type = "linear" ;
                TRMM_3B42_daily_precipitation_V6:level_description = "Earth surface" ;
                TRMM_3B42_daily_precipitation_V6:long_name = "Daily Rainfall Estimate from 3B42 V6, TRMM and other sources, 0.25 deg." ;
                TRMM_3B42_daily_precipitation_V6:product_short_name = "TRMM_3B42_daily" ;
                TRMM_3B42_daily_precipitation_V6:product_version = "6" ;
                TRMM_3B42_daily_precipitation_V6:quantity_type = "Precipitation" ;
                TRMM_3B42_daily_precipitation_V6:standard_name = "r" ;
                TRMM_3B42_daily_precipitation_V6:units = "mm" ;
        double time(time) ;
                time:standard_name = "time" ;
                time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
                :Conventions = "CF-1.4" ;
                :nco_openmp_thread_number = 1 ;
                :NCO = "4.2.1" ;
                :title = "Area-Averaged Time Series (92.813W - 73.828W, 26.93N - 38.883N)" ;
                :userstartdate = "2003-01-01T00:00:00Z" ;
                :userenddate = "2003-01-01T00:59:59Z" ;
                :plot_hint_time_axis_values = "1041379200" ;
                :plot_hint_time_axis_labels = "00Z~C~1 Jan~C~2003" ;
                :plot_hint_title = "TRMM_3B42_daily v6 Area-Averaged Time Series" ;
                :plot_hint_subtitle = "2003-01-01T00:00:00Z - 2003-01-01, Region 92.813W, 26.93N, 73.828W, 38.883N" ;
data:

 TRMM_3B42_daily_precipitation_V6 = 15.5519318909025 ;

 time = 1041379200 ;
}
ENDFILE
FILE=input.xml
<input>
<referer>http://s4ptu-ts2.ecs.nasa.gov/giovanni/</referer>
<query>session=6F455196-7168-11E2-9D93-81617D861513&amp;service=ArAvTs&amp;starttime=2004-01-01T00:00:00Z&amp;endtime=2004-01-03T00:59:59Z&amp;bbox=-180,-90,180,90&amp;data=NLDAS_NOAH0125_H_002_evpsfc%2CNLDAS_NOAH0125_H_002_soilm0_10cm&amp;variableFacets=dataProductInstrumentShortName%3ANLDAS%20Noah%20Land%20Surface%20Model%3B&amp;portal=GIOVANNI&amp;format=json</query>
<result id="9D8417E0-7172-11E2-89EA-F52D7D861513">
<dir>/var/tmp/www/TS2/giovanni/6F455196-7168-11E2-9D93-81617D861513/9D83FD5A-7172-11E2-89EA-F52D7D861513/9D8417E0-7172-11E2-89EA-F52D7D861513</dir>
</result>
<bbox>-180,-90,180,90</bbox>
<data>NLDAS_NOAH0125_H_002_evpsfc</data>
<data>NLDAS_NOAH0125_H_002_soilm0_10cm</data>
<endtime>2004-01-03T00:59:59Z</endtime>
<portal>GIOVANNI</portal>
<service>ArAvTs</service>
<starttime>2004-01-01T00:00:00Z</starttime></input>
ENDFILE
