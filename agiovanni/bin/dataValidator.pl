#!/usr/bin/perl
use strict;

use Safe;
use XML::LibXML;
use XML::LibXSLT;
use File::Basename;
use XML::Schematron::LibXSLT;
use XML::Schematron;
use LWP::UserAgent;
use FindBin qw($Bin);

############################################################
## to read in the inputs
my $data_file     = $ARGV[0];
my $outpath       = $ARGV[1];
my $schema_server = $ARGV[2];

die "ERROR: could not find the source data file: $data_file\n"
    if ( !-e $data_file );
die "ERROR: could not find the working directory: $outpath\n"
    if ( !-e $outpath );
die "ERROR: no schematron URL\n"
    if ( !defined($schema_server) );

##################
my $detectedModels  = "";
my %schematronFiles = ();
$schematronFiles{scrubbedData}    = "scrubbeddata_model_schematron.sch";
$schematronFiles{pairedData}      = "scatterplot_model_schematron.sch";
$schematronFiles{timeSeries}      = "timeseries_model_schematron.sch";
$schematronFiles{latlonMap}       = "latlon_model_schematron.sch";
$schematronFiles{verticalProfile} = "vertical_profile_model_schematron.sch";
$schematronFiles{XSLT}            = "ncml_to_ncml.xsl";

my $schematron_url_root;
$schematron_url_root = $schema_server;
############################################################
## to define the remote location of schematron
############################################################
my %schematrons = ();
$schematrons{scrubbedData}
    = $schematron_url_root . "/" . $schematronFiles{scrubbedData};
$schematrons{pairedData}
    = $schematron_url_root . "/" . $schematronFiles{pairedData};
$schematrons{timeSeries}
    = $schematron_url_root . "/" . $schematronFiles{timeSeries};
$schematrons{latlonMap}
    = $schematron_url_root . "/" . $schematronFiles{latlonMap};
$schematrons{verticalProfile}
    = $schematron_url_root . "/" . $schematronFiles{verticalProfile};
$schematrons{XSLT} = $schematron_url_root . "/" . $schematronFiles{XSLT};

############### to create a local copy of schematrons #######
while ( my ( $key, $url ) = each(%schematrons) ) {
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;
    my $response = $ua->get($url);
    if ( $response->is_success() ) {
        my $localSchematron = $outpath . "/" . $schematronFiles{$key};
        open FH, "> $localSchematron";
        print FH $response->content();
        close(FH);
        if ( !( -e $localSchematron ) ) {
            print STDERR
                "ERROR: failed to generate the schematron -- $localSchematron\n";
            exit(1);
        }
    }
    else {
        print STDERR "Failed to access the model $key($url):"
            . $response->code();
        exit(1);
    }
}

############################################################
## to validate the inputs
die
    "Usage: perl data_validator.pl datafile schematronfile xsltfile  optional_working_path.\n"
    unless defined $data_file and defined $outpath;

die "The source data file does not exist" unless ( -e $data_file );
$outpath = "." unless ( defined $outpath );
$outpath = "." unless ( -e $outpath );
my ( $name, $path, $suffix ) = fileparse($data_file);
$name =~ s/.nc$//i;
my $ncmlfile = "$outpath/$name.xml";
my $xmlfile  = "$outpath/$name" . "_transform.xml";

############################################################
## to dump a netcdf file into a ncml format
my $dumpcmd = "ncdump -x $data_file > $ncmlfile";
my $status;

## print "STEP 1: to dump netcdf to an ncml file\n";
eval { $status = `$dumpcmd`; };
die "ERROR: Failed in dumping netcdf file" if ($@);
die "ERROR: Can not find the dumped ncml file: $ncmlfile\n"
    unless ( -e $ncmlfile );
## print "SUCCESS: dumped data to: $ncmlfile\n\n";

############################################################
## to transform the $ncmlfile into $xmlfile (well-formed xml)
## print "STEP 2: to remove the default namespace\n\n";
my $xml  = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

my $xsltparser   = $xslt->parse_stylesheet_file( $schematrons{XSLT} );
my $trans_result = $xsltparser->transform_file($ncmlfile);
$xsltparser->output_file( $trans_result, $xmlfile );

die "ERROR: failed to remove the default namespace: $!\n"
    unless ( -e $xmlfile );
eval { `mv $xmlfile $ncmlfile`; };
## print "SUCCESS: removed the default namespace\n\n";

############################################################
## to validate the transformed, well-formed xml against schematron
## print "STEP 3.1: to validate against timeSeries\n";
while ( my ( $key, $url ) = each(%schematrons) ) {
    next if ( $key =~ /XSLT/ );
    my $schfile = $outpath . "/" . $schematronFiles{$key};
    ## to test external schematron
    my $status = `perl ./modelDetector.pl $schfile $ncmlfile $key 2>&1`;
    chomp($status);
    print STDERR "MODEL[$key]: $status \n";
    if ( $status !~ /(ERROR)/gi && $status ne '' ) {
        $detectedModels .= "," if ( $detectedModels ne "" );
        $detectedModels .= "$key";
        print STDERR "INFO model matched = $detectedModels\n";
    }
}

if ( $detectedModels ne "scrubbedData" ) {
    my $ret = checkLonRange($data_file);
    if ( $ret != 0 ) {
        print STDERR "ERROR longitude range validation failed\n";
        exit(1);
    }
    else {
        print STDERR "INFO passed the longitude range validation\n";
    }
}
print "OUTPUT matched model: $detectedModels\n" if ( $detectedModels ne "" );
exit(0);

########################################
## the subroutine 'checkLonRange' is used to check the longitude value range is -180 and 180.
## Currently, the visualization tool does not work well with a range of 0 to 360.
## @parameter {$file} -- $file is a CF-1 compliant netcdf file
## @return {0 | 1} -- 0 is a success; 1 is a falure
## @example:
##   my $ret = checkLonRange("workingDirectory/timeAvg.MOD08_D51.aerosol.20070101.nc");
## @author: Xiaopeng Hu
########################################
sub checkLonRange {
    my ($file) = @_;
    my $cmd = "ncks -s \"%f,\" -H -C -v lon $file";

    my @sortedLons  = ();
    my $lonValCount = 0;
    eval {
        my $valString = `$cmd`;    #extract the longitude values
        $valString =~ s/[,]$//;
        my @sortedLons = split( /,/, $valString );
        $lonValCount = @sortedLons;
    };
    if ($@) {
        print STDERR "ERROR: failed to fetched the longitude value: $?\n";
        print STDERR "USER_ERROR: failure in extracting longitude value\n";
        return 1;
    }
    if ( $lonValCount > 0 ) {
        my $first  = $sortedLons[0];
        my $length = @sortedLons;
        my $last   = $sortedLons[ $length - 1 ];

        ## to check lon is in ascending order
        if ( $first < $last ) {
            print STDERR "ERROR longitude must be in an ascending order\n";
            print STDERR
                "USER_ERROR longitude values must be in an ascending order\n";
            return 1;
        }
        ## to check the lon values are within the range from -180 to 180
        if (   $first >= -180
            && $first <= 180
            && $last <= 180
            && $last >= -180 )
        {
            print STDERR "INFO Longitude is within range\n";
            return 0;
        }
        else {
            print STDERR
                "ERROR a 'lon' value must be between -180 and 180.  Current values b/w $first and $last\n";
            print STDERR
                "USER_ERROR longitude value falls out of the range between -180 and 180\n";
            return 1;
        }
    }
    else {
        print STDERR "ERROR no longitude value found\n";
        print STDERR "USER_ERROR no longitude value is found\n";
        return 1;
    }
}

__END__

=head1 NAME

dataValidator.pl  -- a perl commandline tool used to find which data model the target netcdf file can meet

=head1 SYNOPSIS

dataValidator.pl data_file working_dir schema_server_path_URL

=head1 DESCRIPTION

This script is a commandline tool used to validate the source data file against the supported data models:

=over

=item 1. timeSeries

-- a Time Series data model

=item 2. pairedData

-- a Paired Data data model; used to plot a scatterplot

=item 3. latlonMap

-- a Latlon Map data model

=item 4. scrubbedData

-- an intermediate data file meeting the specified conventions for further processing

=item 5. verticalProfile

-- a Vertical Profile data model for 3-D data with a vertical dimension profile

This commandline utility takes two arguments: 1.) source netcdf file, 2.) a working directory.   The arguments must be given in the exact order as mentioned.

The last line of output will tell which data model a current data file in use is compliant with.

=head1 DEPENDENCIES

This commandline utility has two dependencies to work properly:

1.) modelDetector.pl -- must exist at the same directory as dataValidator.pl

2.) Giovanni::Model.pm module -- must be installed somewhere on the system

=head1 AUTHOR

Xiaopeng Hu, E<lt>xiaopeng.hu@nasa.govE<gt>
