#!/usr/bin/perl
################################################################################
# $Id: generateDataFieldSldValids.pl,v 1.4 2015/06/30 17:18:51 eseiler Exp $
# -@@@ EDDA Version: $Name:  $
################################################################################
#
# Script for generating the list of valid SLD names, obtained from the SLD index
#

my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    if (defined $rootPath) {
         push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) );
        push( @INC, $rootPath . 'lib/perl5/' );
    }
}

use strict;
use XML::LibXML;
#use XML::XML2JSON;
use Tie::IxHash;
use JSON;
use Getopt::Long;
use Safe;

# Get options
my $help;
Getopt::Long::GetOptions( 'h' => \$help );

my $usage = "usage: $0 [-h]\n";

if ($help) {
    print "$usage\n";
    exit 0;
}

my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read configuration file $cfgFile\n";
}
unless ( defined $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC ) {
    die "Could not find \$AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC in $cfgFile";
}
#unless ( -r $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC ) {
#    die "Could not find readable valids file '$CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC'";
#}
#unless ( -w $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC ) {
#    die "Valids file '$CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC' is not writeable";
#}

unless ( defined $CFG::SLD_LOCATION ) {
    die "Could not find \$SLD_LOCATION in $cfgFile";
}
my $sldIndexFile = $CFG::SLD_LOCATION . "/sld_list.json";

#my $sldIndexFile = $ARGV[0];
#unless (defined $sldIndexFile) {
#    print STDERR "$usage\n";
#    exit 1;
#}

unless ( -r $sldIndexFile ) {
    die "Could not find readable SLD index file '$sldIndexFile'";
}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

#my $valids = extractValidsfromJson($sldIndexFile);
#my $valids = extractValidsfromJson2($sldIndexFile);
my $valids = extractValidsfromJson3($sldIndexFile);

my $newRoot = XML::LibXML::Element->new('valids');
#foreach my $valid (sort keys %{$valids}) {
foreach my $valid (keys %{$valids}) {
    $newRoot->appendTextChild( 'valid', $valid );
}

#print $newRoot->toString(1), "\n";

unless ( open(OUT, "> $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC")) {
    print STDERR "Could not open $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC for writing\n";
    exit 4;
}
print OUT $newRoot->toString(1), "\n";
close(OUT);
chmod 0666, $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC;

exit 0;

sub extractValidsfromJson {
    my ($sldIndexFile) = @_;

    open(IN, "< $sldIndexFile") or die "Could not open $sldIndexFile for reading\n";
    my $json;
    {
        local $/;
        $json = <IN>;
    }
    close(IN);

    my $noJsonAttrPrefix = 1;
    my $JsonContentKeyIsValue = 1;
    my $forceJSONarray = 1;
    my $prettyJSON = 1;
    my $content_key = ($JsonContentKeyIsValue) ? 'value' : undef;
    my $prefix = ($noJsonAttrPrefix) ? '' : '@';
    my $xml2jsonObj = XML::XML2JSON->new( module => 'JSON::XS',
                                          pretty => $prettyJSON,
                                          attribute_prefix => $prefix,
                                          content_key => $content_key,
                                          force_array => $forceJSONarray,
                                          private_attributes => ['encoding', 'version']);
    my $xml = $xml2jsonObj->json2xml($json);

    my $validsDom;
    eval { $validsDom = $parser->parse_string( $xml ); };
    if ($@) {
        die "Could not parse xml obtained from $sldIndexFile\n";
    }
    my $validsDoc = $validsDom->documentElement();

    my @nodes = $validsDoc->findnodes('/sldList/sld');
    unless (@nodes) {
        die "Expected to find sldList/sld elements, but none found\n";
    }

    my %valids;
    tie %valids, 'Tie::IxHash';
    foreach my $node (@nodes) {
        my $name = $node->getAttribute('name');
        $valids{$name} = 1;
    }

    return \%valids;
}

sub extractValidsfromJson2 {
    my ($sldIndexFile) = @_;

    open(IN, "< $sldIndexFile") or die "Could not open $sldIndexFile for reading\n";
    my @json;
    @json = <IN>;
    close(IN);
    chomp(@json);

    my @names = grep {/"name"\s:/} @json;

    my %valids;
    tie %valids, 'Tie::IxHash';
    foreach my $name (@names) {
        my $value = $1 if $name =~ /:\s*"(.+)"/;
        $valids{$value} = 1;
    }

    return \%valids;
}

sub extractValidsfromJson3 {
    my ($sldIndexFile) = @_;

    open(IN, "< $sldIndexFile") or die "Could not open $sldIndexFile for reading\n";
    my $json;
    {
        local $/;
        $json = <IN>;
    }
    close(IN);

    my $sldList = from_json($json);

    my %valids;
    tie %valids, 'Tie::IxHash';
    foreach my $sld (@{$sldList->{sldList}->{sld}}) {
        my $name = $sld->{'name'};
        $valids{$name} = 1;
    }

    return \%valids;
}

__END__

=head1 NAME

generateDataFieldSldValids.pl - Script to generate the list of valid
dataFieldSld names, obtained from the SLD index

=head1 PROJECT

EDDA

=head1 SYNOPSIS

generateDataFieldSldValids.pl [B<-h>]

=head1 DESCRIPTION

An index file stores the name, title, filename, range minimum, range maximum,
and thumbnail name for each SLD. This script extracts the SLD name values
from the index files and writes an XML file that is used by EDDA to specify
the set of valid SLD names that can be selected for a data field.

=head1 OPTIONS

=over 4

=item B<-h>

Prints command synposis

=back

=head1 CONFIGURATION

Reads the configuration file edda.cfg.

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

None

=head1 AUTHOR

E. Seiler (Ed.Seiler@nasa.gov)

=head1 SEE ALSO

=cut

