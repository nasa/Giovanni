#!/usr/bin/perl

=head1 NAME

runWorkflow.pl

=head1 SYNOPSIS

  perl runWorkflow.pl --cfg /opt/giovanni4/cfg --out /path/to/directory --url "http://giovanni.gsfc.nasa.gov/giovanni/#service=TmAvMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T23:59:59Z&bbox=-180,-50,180,50&data=TRMM_3B42_Daily_7_precipitation&variableFacets=dataFieldMeasurement%3APrecipitation%3BdataProductTimeInterval%3Adaily%3B&dataKeyword=TRMM"
  perl runWorkflow.pl --cfg /opt/giovanni4/cfg --out /path/to/directory --url "http://giovanni.gsfc.nasa.gov/giovanni/daac-bin/service_manager.pl?session=D8A25996-85BD-11E6-BEAB-57E7FF5F7376&service=TmAvMp&starttime=2003-01-01T00:00:00Z&endtime=2003-01-01T23:59:59Z&bbox=-180,-50,180,50&data=TRMM_3B42_Daily_7_precipitation&variableFacets=dataFieldMeasurement%3APrecipitation%3BdataProductTimeInterval%3Adaily%3B&dataKeyword=TRMM&portal=GIOVANNI&format=json"
  
=head1 DESCRIPTION

Runs a workflow locally with make using the parameters in a bookmarkable URL or
a service manager URL. Command line options are:

=over

=item cfg - installed configuration directory. Defaults to /opt/giovanni4/cfg.

=back

=over

=item max-job-count - maximum number of jobs to allow make to run at once.
Defaults to 1.

=back

=over

=item out - directory to run the workflow in. Defaults to the current directory.
Note: Because some of the workflow code expects the directory structure to have
a session, resultset, and result directory, the workflow will actually be run
under $out/session/resultset/result.

=back

=over

=item url - URL representing the workflow to run.

=back

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use 5.008008;
use strict;
use warnings;

use Getopt::Long;
use Cwd 'abs_path';
use File::Path qw(make_path);
use URI;
use XML::LibXML;
use Safe;
use File::Copy;
use Giovanni::Workflow;

# get the command line options
my $cfg;
my $out;
my $urlString;
my $help;
my $maxJobCount;
GetOptions(
    "cfg=s"           => \$cfg,
    "out=s"           => \$out,
    "url=s"           => \$urlString,
    "max-job-count=s" => \$maxJobCount,
    "h"               => \$help,
);

if ( defined($help) ) {
    print "Usage: $0 --url 'http://bookmarkable.g4.url/giovanni/#bbox=blah'";
    exit;
}

if ( !defined($cfg) ) {
    $cfg = "/opt/giovanni4/cfg";
}

# load giovanni.cfg for Giovanni::Workflow
my $giovanniCfg  = "$cfg/giovanni.cfg";
my $giovanniSafe = Safe->new('GIOVANNI');
if ( !( $giovanniSafe->rdo($giovanniCfg) ) ) {
    die "Unable to open giovanni configuration file.";
}

# load workflow.cfg so we now which workflows are needed for this service
my $workflowCfg  = "$cfg/workflow.cfg";
my $workflowSafe = Safe->new('WORKFLOW');
if ( !( $workflowSafe->rdo($workflowCfg) ) ) {
    die "Unable to open workflow configuration file.";
}

if ( !defined($out) ) {
    $out = ".";
}

$out = abs_path($out);

# Giovani::Workflow expects the standard session directory structure.
my $resultDir = "$out/session/resultset/result";
make_path($resultDir);

if ( !defined($urlString) ) {
    die "--url option is required.";
}

if ( !defined($maxJobCount) ) {
    $maxJobCount = 1;
}

# parse the url
my $url = URI->new($urlString);

# If there's a fragment, this is a bookmarkable URL. Set the query to the
# fragment so we can parse it
if ( $url->fragment() ) {
    $url->query( $url->fragment() );
}
my %query     = $url->query_form();
my $service   = $query{'service'};
my $starttime = $query{'starttime'};
my $endtime   = $query{'endtime'};
my $bbox      = $query{'bbox'};
my $shape     = $query{'shape'};
my $portal    = $query{'portal'};
if ( !( defined($portal) ) ) {
    $portal = 'GIOVANNI';

}
my @data = split( ",", $query{'data'} );

##
# create input.xml ( or at least the pieces the workflow needs )
##

#<input>
#    <referer>http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/</referer>
#    <query>session=8D2450B2-8740-11E6-8D57-84C91EC96FC3&amp;service=TmAvMp&amp;starttime=2005-01-01T00:00:00Z&amp;endtime=2005-01-01T23:59:59Z&amp;data=AIRX3STD_006_Temperature_A(z%3D500%3Aunits%3DC)&amp;dataKeyword=AIRS&amp;portal=GIOVANNI&amp;format=json</query>
#    <title>Time Averaged Map</title>
#    <description>Interactive map of average over time at each grid cell from 2005-01-01T00:00:00Z to 2005-01-01T23:59:59Z</description>
#    <result id="B51E3510-8740-11E6-A1E5-CECA1EC96FC3">
#        <dir>/var/giovanni/session/8D2450B2-8740-11E6-8D57-84C91EC96FC3/B51D8868-8740-11E6-A1E5-CECA1EC96FC3/B51E3510-8740-11E6-A1E5-CECA1EC96FC3/</dir>
#    </result>
#    <data zValue="500" units="C">AIRX3STD_006_Temperature_A</data>
#    <dataKeyword>AIRS</dataKeyword>
#    <endtime>2005-01-01T23:59:59Z</endtime>
#    <portal>GIOVANNI</portal>
#    <service>TmAvMp</service>
#    <session>8D2450B2-8740-11E6-8D57-84C91EC96FC3</session>
#    <starttime>2005-01-01T00:00:00Z</starttime>
#</input>

my $doc  = XML::LibXML::Document->new();
my $root = $doc->createElement("input");
$doc->setDocumentElement($root);

# AIRX3STD_006_Temperature_A(z=500:units=C)
for my $dataField (@data) {
    my $element = $doc->createElement("data");

    # see if there are any modifiers.
    # E.g. - AIRX3STD_006_Temperature_A(z=500:units=C)
    if ( $dataField =~ /(.*)\((.*)\)/ ) {
        $dataField = $1;
        my $modifiers = $2;

        # get out z, if it is there
        if ( $modifiers =~ /z=([^:]*)/ ) {
            $element->setAttribute( "zValue" => $1 );
        }

        # get out units, if it is there
        if ( $modifiers =~ /units=([^:]*)/ ) {
            $element->setAttribute( "units" => $1 );
        }
    }

    $element->appendTextNode($dataField);
    $root->appendChild($element);
}

_addBasicElement( $doc, $root, "service",   $service );
_addBasicElement( $doc, $root, "starttime", $starttime );
_addBasicElement( $doc, $root, "endtime",   $endtime );
_addBasicElement( $doc, $root, "portal",    $portal );
_addBasicElement( $doc, $root, "bbox",      $bbox ) if $bbox;
_addBasicElement( $doc, $root, "shape",     $shape ) if $shape;

# add the output directory
my $resultElement = $doc->createElement("result");
$root->appendChild($resultElement);
my $dirElement = $doc->createElement("dir");
$dirElement->appendTextNode($resultDir);
$resultElement->appendChild($dirElement);

my $input = "$resultDir/input.xml";
open( INPUT, ">", $input ) or die "Unable to open file for writing: $input";
print INPUT $doc->toString();
close(INPUT);

# figure out which .make files we need
my @makeFiles;
{

    # Turn off warnings for this line. Warnings don't work well with loading
    # stuff via the Safe module.
    no warnings;
    @makeFiles = @{ $WORKFLOW::WORKFLOW_MAP{$service}{file} };
}

# copy the files over
for my $file (@makeFiles) {
    copy( "$cfg/$file", "$resultDir/$file" );
}

# start the workflow
my $workflow = Giovanni::Workflow->new(
    WORKFLOW_DIR => $resultDir,
    WORKFLOW     => \@makeFiles,
);
my $success = $workflow->launch( MAX_JOB_COUNT => $maxJobCount );

if ($success) {
    exit(0);
}
else {
    exit(1);
}

sub _addBasicElement {
    my ( $doc, $root, $name, $value ) = @_;

    my $element = $doc->createElement($name);
    $element->appendTextNode($value);
    $root->appendChild($element);
}

1;
