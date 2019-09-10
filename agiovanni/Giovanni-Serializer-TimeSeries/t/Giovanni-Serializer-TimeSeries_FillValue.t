#!/usr/bin/env perl
#$Id: Giovanni-Serializer-TimeSeries_FillValue.t,v 1.1 2013/11/11 20:10:43 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

use strict;
use File::Temp qw/ tempdir /;
use Test::More tests => 11;
BEGIN { use_ok('Giovanni::Serializer::TimeSeries') }

my $bbox = "-180,-90,180,90";

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
my $input   = "$tempDir/input.xml";
my $csvFile = Giovanni::Serializer::TimeSeries::serialize(
    input  => $input,
    ncFile => $ncfile,
    outDir => $tempDir
);

# make sure the csv file was created
ok( -e $csvFile, "Output csv file exists" );

# read it out.
open( FILE, "<", $csvFile ) or die $!;
my @csvText = <FILE>;
close(FILE);

# make sure that the data is the file correctly
my $i = 5;
like( $csvText[$i], qr/Fill Value \(MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean\): -9999/, "fill value in file" );
$i = 8;
like(
    $csvText[ $i++ ],
    qr/2003-01-01 00:00:00,0.160728/,
    "first data point correct"
);
like(
    $csvText[ $i++ ],
    qr/2003-01-02 00:00:00,0.160121/,
    "second data point correct"
);
like(
    $csvText[ $i++ ],
    qr/2003-01-03 00:00:00,0.163620/,
    "third data point correct"
);
like(
    $csvText[ $i++ ],
    qr/2003-01-04 00:00:00,-9999/,
    "fourth data point correct"
);
like(
    $csvText[ $i++ ],
    qr/2003-01-05 00:00:00,0.167412/,
    "fifth data point correct"
);

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
FILE=areaAvg.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101-20030105.180W_90S_180E_90N.cdl
netcdf areaAvg.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101-20030105.180W_90S_180E_90N {
dimensions:
        time = UNLIMITED ; // (5 currently)
variables:
        double MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time) ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Serializable = "True" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target), MODIS-Terra, 1 x 1 deg." ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
                MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:valid_range = -100s, 5000s ;
        int time(time) ;
                time:standard_name = "time" ;
                time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
                :Conventions = "CF-1.4" ;
                :nco_openmp_thread_number = 1 ;
                :title = "Area-Averaged Time Series (180W - 180E, 90S - 90N)" ;
                :userstartdate = "2003-01-01T00:00:00Z" ;
                :userenddate = "2003-01-05T00:59:59Z" ;
                :plot_hint_time_axis_values = "1041379200,1041422400,1041465600,1041508800,1041552000,1041595200,1041638400,1041681600,1041724800" ;
                :plot_hint_time_axis_labels = "00Z~C~1 Jan~C~2003,12Z,00Z~C~2 Jan~C~2003,12Z,00Z~C~3 Jan~C~2003,12Z,00Z~C~4 Jan~C~2003,12Z,00Z~C~5 Jan~C~2003" ;
                :plot_hint_time_axis_minor = "1041400800,1041444000,1041487200,1041530400,1041573600,1041616800,1041660000,1041703200,1041746400" ;
                :plot_hint_title = "MOD08_D3 v51 Area-Averaged Time Series" ;
                :plot_hint_subtitle = "2003-01-01T00:00:00Z - 2003-01-05, Region 180W, 90S, 180E, 90N" ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean = 0.160728456729218, 
    0.160121114125927, 0.163620193330985, -9999.0 , 0.167412285815492 ;

 time = 1041379200, 1041465600, 1041552000, 1041638400, 1041724800 ;
}
ENDFILE
FILE=input.xml
<input>
<referer>http://s4ptu-ts2.ecs.nasa.gov/giovanni/</referer>
<query>session=6F455196-7168-11E2-9D93-81617D861513&amp;service=AREA_AVERAGED_TIME_SERIES&amp;starttime=2004-01-01T00:00:00Z&amp;endtime=2004-01-03T00:59:59Z&amp;bbox=-180,-90,180,90&amp;data=NLDAS_NOAH0125_H_002_evpsfc%2CNLDAS_NOAH0125_H_002_soilm0_10cm&amp;variableFacets=dataProductInstrumentShortName%3ANLDAS%20Noah%20Land%20Surface%20Model%3B&amp;portal=GIOVANNI&amp;format=json</query>
<result id="9D8417E0-7172-11E2-89EA-F52D7D861513">
<dir>/var/tmp/www/TS2/giovanni/6F455196-7168-11E2-9D93-81617D861513/9D83FD5A-7172-11E2-89EA-F52D7D861513/9D8417E0-7172-11E2-89EA-F52D7D861513</dir>
</result>
<bbox>-180,-90,180,90</bbox>
<data>NLDAS_NOAH0125_H_002_evpsfc</data>
<data>NLDAS_NOAH0125_H_002_soilm0_10cm</data>
<endtime>2004-01-03T00:59:59Z</endtime>
<portal>GIOVANNI</portal>
<service>AREA_AVERAGED_TIME_SERIES</service>
<starttime>2004-01-01T00:00:00Z</starttime></input>
ENDFILE
