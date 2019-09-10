#!/usr/bin/perl -T

use strict;
use CGI;
use Safe;
use XML::LibXML;
use warnings;

# Establish the root path based on the script name
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}
$| = 1;

# Following packages should be used after @INC is set above
use Giovanni::Util;
use Giovanni::CGI;
use Giovanni::UnitsConversion;

## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS =>
        [ 'temporalResolution', 'sourceUnits', 'destinationUnits' ]
    ,
);

# Get the units configuration file
my $unitsCfgFile = $rootPath . 'cfg/unitsCfg.xml';
if ( !( -e $unitsCfgFile ) ) {
    print STDERR
        "Error: unable to find units configuration file. Expected it to be $unitsCfgFile.";
    exit(1);
}

# get the parameters
my $sourceUnits        = $cgi->param("sourceUnits");
my $destinationUnits   = $cgi->param("destinationUnits");
my $temporalResolution = $cgi->param("temporalResolution");

my @destUnitsArray = split( ",", $destinationUnits );

my %out = Giovanni::UnitsConversion::checkConversions(
    config             => $unitsCfgFile,
    sourceUnits        => $sourceUnits,
    temporalResolution => $temporalResolution,
    destinationUnits   => \@destUnitsArray
);

my $doc  = XML::LibXML::Document->createDocument();
my $root = $doc->createElement("response");
$doc->setDocumentElement($root);

if ( !$out{allOkay} ) {
    my $message = $doc->createElement("message");
    $root->addChild($message);
    $message->appendTextNode( $out{message} );
}

print "Content-type: application/xml\n\n";
print $doc->toString();

=head1 NAME

checkUnitsConversion.pl - checks to see if one or more units conversions are valid

=head1 SYNOPSYS

perl /opt/giovanni4/cgi-bin/checkUnitsConversion.pl "sourceUnits=mm/hr&destinationUnits=mm/month&temporalResolution=monthly"

=head1 DESCRIPTION

Returns an XML string. If all the conversions are okay, the XML is:

  <response />

If one or more of the conversions have a problem, the XML will have a message.
E.g. - 

  <?xml version="1.0"?>
  <response>
    <message>The following conversions are not available for mm/hr with daily temporal resolution: mm/month.</message>
  </response>
  

=head2 Parameters

=over 12

=item sourceUnits

The source units of the variable

=item destinationUnits

One or more destination units, comma separated

=item temporalResolution

The temporal resolution of the variable

=back


=cut
