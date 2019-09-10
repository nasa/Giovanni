#!/usr/bin/env perl

=head1 Name

checkForTimeAttributes.pl

=head1 Description

This script is run by the Scrubber regression tests when $ARGV[0] = 1.
It helps the developer to sometimes see the status of the various times
that the scrubber puts in the scrubber output listfile for datastager
 
=head1 Synopsis

(from bin dir)
t/ncScrubber_*.t 1

=head1 Author

Richard Strub

=cut 

use strict;
use XML::LibXML;
use DateTime;
use Giovanni::Data::NcFile;

if ($#ARGV < 0) {
  print STDERR "USAGE>$0 workingdir\n";
  exit();
}

my $workingdir = $ARGV[0];
my $scrubberListingFile = "$workingdir/scrubbed-listingfiles.xml";
my $scrubbed_file       = `ls $workingdir/scrubbed.*.nc`;chomp $scrubbed_file;
my $xmlParser = XML::LibXML->new();
my $doc = $xmlParser->parse_file($scrubberListingFile);
my $nodes = $doc->getElementsByTagName('dataFile');

   my @time_bnds;
   my $start_time = 25;
   my $end_time   = 25;


my @time_bnds = get_variable_values($scrubbed_file, 'time_bnds');
if ($#time_bnds <= 0 ) {
    @time_bnds = get_variable_values($scrubbed_file, 'clim_bnds');
}

foreach my $node (@$nodes) {
   my @attrs = $node->findnodes("./@*");

   foreach my $attr (@attrs) {
       if ($attr->nodeName =~ /Period/) { 
           print sprintf("%20s :%s\n",$attr->nodeName, $attr->value)
       }
       else {
           if (Giovanni::Data::NcFile::StringBoolean($attr->value)) {
               print sprintf("%20s :%s %s\n",$attr->nodeName, $attr->value,
                         DateTime->from_epoch(epoch => $attr->value));
           }
           else {
               warn $attr->nodeName . " attribute has no value in output listing file <$scrubberListingFile>\n";

           }
             # before removal if ($attr->nodeName eq 'time_bnds_start') { $time_bnds[0] = $attr->value; }
             # before removal if ($attr->nodeName eq 'time_bnds_end') { $time_bnds[1] =  $attr->value; }
              if ($attr->nodeName eq 'startTime') {
                   $start_time = $attr->value;
              }
              if ($attr->nodeName eq 'endTime') {
                   $end_time = $attr->value;
              }

       }
   }
}
if ($time_bnds[0] != $start_time) {
      print STDERR sprintf("\n\nStart Times Don't Match\nStart_Global    = %d\nStart_time_bnds = %d\n\n",
               $start_time, $time_bnds[0]);
   }
   if ($time_bnds[1] != $end_time) {
      print STDERR sprintf("\n\nEnd_Times Don't Match\nEnd_Global    = %d\nEnd_time_bnds = %d\n\n",
               $end_time, $time_bnds[1]);
   }

print `cat $scrubberListingFile\n`;

sub get_variable_values {
    my ( $file, $variable) = @_;

    #figure out the type of the variable
    my $type = Giovanni::Data::NcFile::get_variable_type( $file, 0, $variable );
    my $printString = '%13.9f';
    if ( $type eq 'int' || $type eq 'long' ) {
        $printString = '%d';
    }

    # setup the command to get data values out.
    my $cmd = "ncks -s '$printString\\n' -C -H ";
    $cmd = $cmd . "-v $variable $file";

    my @out = `$cmd`;
    my $ret = $? >> 8;
    if ( $ret != 0 ) {
        return undef;
    }

    chomp(@out);

    # remove trailing empty lines
      pop(@out) until Giovanni::Data::NcFile::StringBoolean($out[-1]);
    return @out;
}

