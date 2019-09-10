#!/usr/bin/perl

=head1 NAME 

giovanni_postprocess - Post-Processing of Algorithm Output.


=head1 SYNOPSIS

giovanni_postprocess.pl
  --bbox         west,south,east,north
  --comparison   vs
  --endtime      YYYY-MM-DDTHH:MI:SSZ
  --infile       mfst.result[...].xml
  --name         service_label                # ex: Time Averaged Map
  --outfile      mfst.postprocess[...].xml
  --session-dir  unique_session_directory
  --starttime    YYYY-MM-DDTHH:MI:SSZ
  --units        units1,units2,units-cfg
  --varfiles     varinfo1,varinfo2.xml
  --variables    variable1,variable2
  --zfiles       dataslice1,dataslice2
  [--time-axis] 
  [--group       seasonal information]
  
=head1 DESCRIPTION

Contains all post-processing tasks for algorithm output. Among this, it
add attributes to the dataset used by the visualizer and applies units
conversion in some cases.

=over

=item --bbox

Bounding box as values seperated by comma. Order: west,south,east,north

=item --comparison

Optional. In-fix operator between variables for title (eg "vs" to write title as "X vs Y")

=item --endtime

User-selected end time.

=item --group

Seasonal service information, if any. To be passed as GroupType=GroupVal.

=item --infile

Path to input manifest file (from algorithm).

=item --name

Human-readable label for the service.

=item --outfile

Path to output manifest file.

=item --session-dir

Path to session directory.

=item --starttime

User-selected start time.

=item --time-axis

Set this flag if the algorithm data has a time axis (omit if it doesn't).

=item --units

Comma seperated list of destination units, with order corresponding
to the order of the --variables list. However, this list must contain
an additional last element, which is the units config file.

=item --varfiles

Comma seperated list of paths to variable manifest files.

=item --variables

Comma separated list of variable names.

=item --zfiles

Comma seperated list of data field slice manifest files.

=cut

use strict;
use Getopt::Long;
use Giovanni::PostProcess;

use vars qw(
    $bbox
    $comparison
    $endtime
    $group
    $infile
    $name
    $outfile
    $service
    $session_dir
    $shapefile
    $starttime
    $time_axis
    $units
    $varfiles
    $variables
    $zfiles
);

GetOptions(
    "bbox=s"        => \$bbox,
    "comparison=s"  => \$comparison,
    "endtime=s"     => \$endtime,
    "group=s"       => \$group,
    "infile=s"      => \$infile,
    "name=s"        => \$name,
    "outfile=s"     => \$outfile,
    "service=s"     => \$service,
    "session-dir=s" => \$session_dir,
    "S=s"           => \$shapefile,
    "starttime=s"   => \$starttime,
    "time-axis"     => \$time_axis,
    "units=s"       => \$units,
    "varfiles=s"    => \$varfiles,
    "variables=s"   => \$variables,
    "zfiles=s"      => \$zfiles,
);

my %args = (
    'bbox'        => $bbox,
    'comparison'  => $comparison,
    'endtime'     => $endtime,
    'group'       => $group,
    'infile'      => $infile,
    'name'        => $name,
    'outfile'     => $outfile,
    'service'     => $service,
    'session-dir' => $session_dir,
    'shapefile'   => $shapefile,
    'starttime'   => $starttime,
    'time-axis'   => $time_axis,
    'units'       => $units,
    'varfiles'    => $varfiles,
    'variables'   => $variables,
    'zfiles'      => $zfiles,
);

exit Giovanni::PostProcess::run(%args);

