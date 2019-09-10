#!/usr/bin/perl -T
#$Id: getDestinationUnits.pl,v 1.4 2015/04/20 13:59:08 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

use strict;
use Safe;
use warnings;
use XML::LibXML;

# Establish the root path based on the script name
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}
$| = 1;


## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

use Giovanni::Util;
# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

use Giovanni::UnitsConversion;

my $unitsCfgFile = $rootPath . 'cfg/unitsCfg.xml';
if ( !( -e $unitsCfgFile ) ) {
    print STDERR
        "Error: unable to find units configuration file. Expected it to be $unitsCfgFile.";
    exit(1);
}

my @units = Giovanni::UnitsConversion::getAllDestinationUnits(
    config => $unitsCfgFile );

my $doc  = XML::LibXML::Document->createDocument();
my $root = $doc->createElement("valids");
$doc->setDocumentElement($root);

for my $unit (@units) {
    my $unitElement = $doc->createElement("valid");
    $root->addChild($unitElement);
    $unitElement->appendTextNode($unit);
}

print "Content-type: application/xml\n\n";
print $doc->toString(1);

=head1 NAME

getDestinationUnits.pl - get a list of all the destination units for units 
conversion.

=head1 SYNOPSYS

perl /opt/giovanni4/cgi-bin/getDestinationUnits.pl

=head1 DESCRIPTION

Returns a simple XML string with the units. E.g. -

  <?xml version="1.0"?>
  <valids>
    <valid>C</valid>
    <valid>DU</valid>
    <valid>inch/day</valid>
    <valid>inch/hr</valid>
    <valid>inch/month</valid>
    <valid>mm</valid>
    <valid>mm/day</valid>
    <valid>mm/hr</valid>
    <valid>mm/month</valid>
    <valid>mm/s</valid>
  </valids>

=cut
