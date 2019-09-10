#!/usr/bin/env perl

use Giovanni::Catalog;
use DataAccess::OPeNDAP;
use File::Temp qw/ tempfile tempdir /;
use LWP::Simple;
use Getopt::Long;
use URI::Escape;
use JSON;
use XML::Simple;
use strict;

my $workingdir = tempdir( CLEANUP => 0 );
my %output;

my ( $opendap_variable, $opendap_url, $dataFieldId, $varinfo_file );
my $format = "text";

GetOptions(
    'sds=s' => \$opendap_variable,
    'url=s' => \$opendap_url,

    # A dataFieldId should be provided for this option. This does not have to be the dataFieldId
    # that will be used for the variable that will be added later to the Giovanni catalog, it can be a
    # dataFieldId for a (similar) variable that is already in the Giovanni catalog.
    'variable=s' => \$dataFieldId,
    'varinfo=s'  => \$varinfo_file,
    'format=s'  => \$format,
);

if ( !( defined $opendap_variable )
    || !( defined $opendap_url ) ) {
    usage();
    exit(1);
}
if ( !defined $dataFieldId and !defined $varinfo_file ) {
    usage();
    exit(1);
}

# START

#  show the user how Giovanni downloads an OPeNDAP URL
my $inputListingFile = Download( $opendap_variable, $opendap_url, $workingdir );

#  scrubber/Giovanni Ingest
if ( !-e $varinfo_file ) {
    $varinfo_file = createVarInfo( $workingdir, $dataFieldId );
    print STDERR "Your VARINFO file is here: $varinfo_file\n"
}
else {
    print STDERR "Using provided varinfo file: $varinfo_file\n"
}

run_scrubber( $inputListingFile, $varinfo_file, $workingdir );


if ($format =~ /json/i) {
   my $json      = JSON->new;
   my $json_text = $json->pretty->encode( \%output );
   print $json_text;
}
if ($format =~ /xml/i) {
   my $ref = XMLout(\%output);
   print $ref;
}

# END

sub run_scrubber {
    my ( $inputListingFile, $varinfo_file, $workingdir ) = @_;
    my $cmd = qq(ncScrubber.pl --input $inputListingFile --catalog $varinfo_file --outDir $workingdir);
    print STDERR qq(Running Giovanni Ingest:  $cmd...\n);
    $output{Scrubber}{scrubberCommand} = $cmd;
    my @scrubberOutput = `$cmd 2>&1`;
    foreach (@scrubberOutput) {
        if ($_ !~ /ncrename|ncatted|attribute|USER_MSG|input.xml|lineage|step|STEP|PERCENT_DONE/) {
            print STDERR "$_";
        }
        push @{ $output{Scrubber}{output} }, $_;
    }
    my $scrubbedfile = `ls -1 $workingdir | grep scrubbed | grep "\.nc"`;
    chomp($scrubbedfile);

    if ( length $scrubbedfile > 10 ) {
        print STDERR ("\nYour data CAN be ingested into Giovanni\n");
        $output{Scrubber}{scrubbedfile} = $scrubbedfile;
        $output{Scrubber}{result}       = 1;
    }
}

# This is how Giovanni downloads a file from OPeNDAP:
sub Download {
    my $opendap_variable = shift;
    my $opendap_url      = shift;
    my $workingdir       = shift;

    my $odAccess = DataAccess::OPeNDAP->new(
        VARIABLES => [$opendap_variable],
        FORMAT    => 'netCDF',
        URLS      => [$opendap_url]

    );
    if ( $odAccess->errorMessage() ) {

        # All of the error messages are already joined into one string:
        print STDERR $odAccess->errorMessage(), "\n";
        exit(1)
    }

    my $list = $odAccess->getOpendapDownloadList();
    print STDERR qq(\n\nOpendap URL: $list->[0][0]\n);
    print STDERR qq(Label: $list->[0][1]\n\n);
    my $response = get( $list->[0][0] );
    $output{download}{opendap_url}        = $opendap_url;
    $output{download}{download_url}       = $list->[0][0];
    $output{download}{download_url_label} = $list->[0][1];

    # Output: Downloaded file:
    my $outputfile = "$workingdir/$list->[0][1]";
    open FH, ">", $outputfile;
    print FH $response;
    close FH;
    print STDERR qq(Your File is HERE: $outputfile\n\nThe rest is giovanni ingest/scrubbing:\n);

    # Scrubber Listing File: (we later run scrubber using this)
    my $listingfile = "$workingdir/listingFile.xml";
    open FH, ">", $listingfile;

    # The dates here are arbitrary:
    print FH qq(<dataFileList id="$dataFieldId" sdsName="$opendap_variable">\n<dataFile startTime="2000-01-01T00:00:00Z" endTime="2000-01-01T23:59:59Z" >$outputfile</dataFile>\n </dataFileList>);
    close FH;
    return $listingfile;
}

# For scrubbing:
sub createVarInfo {
    my $workingdir  = shift;
    my $dataFieldId = shift;
    my $inputxml    = createInputXml( $workingdir, $dataFieldId );
    my $varinfo     = qq($workingdir/varinfo.txt);

    my $artifacts = `getDataFieldInfo.pl --aesir https://aesir.gsfc.nasa.gov/aesir_solr/TS1 --in-xml-file $inputxml --datafield-info-file $varinfo 2>&1`;
    my $data = `cat $varinfo `;
    $data =~ s/" /" \n/g; # make it editable in case a user want's to use it in subsequent runs
    open FH, ">", $varinfo;
    print FH $data;
    close FH;
    $output{varinfo}{filename} = $varinfo;
    $output{varinfo}{contents} = $data;
    return $varinfo;
}

# For scrubbing:
sub createInputXml {
    $workingdir  = shift;
    $dataFieldId = shift;
    my $outputfile = "$workingdir/input.xml";
    open FH, ">", $outputfile;
    print FH "<input><data>$dataFieldId</data></input>\n";
    close FH;
    print STDERR qq(input.xml: $outputfile\n);
    return $outputfile;
}

sub usage {
    print STDERR "USAGE>$0 --sds variable(name in opendap) 
                    --url opendap_URL 
                    --variable  A_Valid_DataFieldId or --varinfo your_own_varinfo file]
                   [--format json/xml]\n";
    exit(0)
}

=head1 NAME
	
 	g4_isMyDataOK.pl	

=head1 DESCRIPTION

So you want to be able to download an OPeNDAP file just like Giovanni does?
So you want to see if Giovanni will be able to ingest your data (from OPeNDAP)?

This script, will download and run Giovanni::Scrubber on a variable in OPeNDAP
However to actually test-scrub/ingest a file, we need to cheat a little bit. 
We need a varinfo file and so we need a valid dataFieldId. 
Afterwards you can save the varinfo.txt file and 
use it again by running this script using --varinfo myvarinfo.txt instead

=head1 IO

B<text> output is returned to STDERR assuming a CLI environment

B<JSON> is returned to STDOUT for machine use

=head1 SYNOPSIS

g4_isMyDataOK.pl --sds variable --url opendap_URL  --variable  A_Valid_DataFieldId  |  --varinfo your_own_varinfo file  [--format json/xml]

=head1 OPTIONS

=over 4

=item B<--sds>

This is the variable name in OPeNDAP

=item B<--url>

OPeNDAP URL (suffix .html)

B<and either:> 

=item B<--variable>

This is the variable name in Giovanni, also called the dataFieldId
dataFieldId is an identifier obtained from the Giovanni catalog that is used 
in the variables cache .db file and directory names. 
It does not matter if it is the same as the one you are testing now 
(since you are only now just seeing if it will work in Giovanni 
- you haven't added it to AESIR using EDDA yet). 
Any old dataFieldId name will do, one that is related may help. 


B<or:>

=item B<--varinfo>

Your own varinfo file. Perhaps modified from a previous run

=item B<--format>

B<text I<default>>|B<JSON>

Text output always goes to STDERR. This allows machine-readable output to go to STDOUT

=back

=head1 REAL EXAMPLES


	g4_isMyDataOK.pl --sds BCCMASS --url https://goldsmr4.gesdisc.eosdis.nasa.gov/opendap/MERRA2_MONTHLY/M2TMNXAER.5.12.4/1986/MERRA2_100.tavgM_2d_aer_Nx.198603.nc4.html --variable M2TMNXAER_5_12_4_BCCMASS

	g4_isMyDataOK.pl --sds Data_Set_43 --url https://disc1.gesdisc.eosdis.nasa.gov/opendap/tovs/TOVSADNG/1990/005/TOVS_DAILY_AM_900106_NG.HDF.Z.html --variable M2TMNXAER_5_12_4_BCCMASS 

	g4_isMyDataOK.pl --sds Ozone       --url https://acdisc.gesdisc.eosdis.nasa.gov/opendap/TEST_opendap/Meteor3_TOMS_Level3/TOMSM3L3.008/1991/TOMS-Meteor3_L3-TOMSM3L3_1991m1114_v8.HDF.html     --variable TOMSEPL3_008_Ozone

	g4_isMyDataOK.pl --sds Ozone       --url https://acdisc.gesdisc.eosdis.nasa.gov/opendap/TEST_opendap/Meteor3_TOMS_Level3/TOMSM3L3.008/1991/TOMS-Meteor3_L3-TOMSM3L3_1991m1114_v8.HDF.html     --variable TOMSEPL3_008_Ozone

	g4_isMyDataOK.pl --sds Time        --url https://acdisc.gesdisc.eosdis.nasa.gov/opendap/TEST_opendap/CAR/CAR_KUWAITOILFIRE_L1C.1/KUWAIT-car_c131_19910602_R2_1485_Level1C_20171201.nc.html    --variable TOMSEPL3_008_Ozone



=head1 

B<Or using your own varinfo file:>

	g4_isMyDataOK.pl --sds Tair_f_tavg --url https://hydro1.gesdisc.eosdis.nasa.gov:443/opendap/FLDAS/FLDAS_NOAH01_C_EA_MA.001/2017/FLDAS_NOAH01_C_EA_MA.ANOM201710.001.nc.html --varinfo my.varinfo 

=cut
