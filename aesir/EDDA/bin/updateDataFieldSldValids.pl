#!/usr/bin/perl
################################################################################
# $Id: updateDataFieldSldValids.pl,v 1.3 2013/09/30 15:18:50 eseiler Exp $
# -@@@ EDDA Version: $Name:  $
################################################################################
#
# Script for updating the list of SLDs that are valid for a new data field
#

my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
     if (defined $rootPath) {
#         push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) );
         push( @INC, $rootPath . 'lib/perl5/' );
     }
}

use strict;
use XML::LibXML;
use Getopt::Long;
use Safe;

# Get options
my $help;
Getopt::Long::GetOptions( 'h' => \$help );

my $usage = "usage: $0 [-h] newDataFieldSldValid\n  e.g. $0 'divergent_rdbu_10_sld.xml: divergent_rdbu_10'";

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
unless ( -r $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC ) {
    die "Could not find readable valids file '$CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC'";
}
unless ( -w $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC ) {
    die "Valids file '$CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC' is not writeable";
}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

my $validsDom;
eval { $validsDom = $parser->parse_file( $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC ); };
if ($@) {
    die "Could not read and parse $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC\n";
}
my $validsDoc = $validsDom->documentElement();

my $newValid = $ARGV[0];
unless (defined $newValid) {
    print STDERR "$usage\n";
    exit 1;
}
unless ($newValid =~ /\w+/) {
    print STDERR "Illegal value '$newValid' for new valid\n";
    exit 2;
}
my %valids;
my $validPath = '/valids/valid';
my @validNodes = $validsDoc->findnodes($validPath);
unless (@validNodes) {
    print STDERR "Did not find any $validPath in $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC";
    exit 3;
}

# Save the existing values in a hash to detect duplication
foreach my $validNode (@validNodes) {
    my $valid = $validNode->textContent;
    $valids{$valid} = 1;
}

# Add the new valid to the hash and sort the valids
if (exists $valids{$newValid}) {
    # If valid already exists, there is no need to update the valids file
    exit 0;
}

$valids{$newValid} = 1;
my $newRoot = XML::LibXML::Element->new('valids');
foreach my $valid (sort keys %valids) {
    $newRoot->appendTextChild( 'valid', $valid );
}

unless ( open(OUT, "> $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC")) {
    print STDERR "Could not open $CFG::AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC for writing\n";
    exit 4;
}
print OUT $newRoot->toString(1), "\n";
close(OUT);

exit 0;



__END__

=head1 NAME

updateDataFieldSldValids.pl - Script to update the list of valid dataFieldSld
values for new data fields that are added to EDDA

=head1 PROJECT

EDDA

=head1 SYNOPSIS

updateDataFieldSldValids.pl [B<-h>] newDataFieldSldValid

=head1 DESCRIPTION

EDDA provides the capability to create new SLDs by customizing a generic SLD.
When these new SLDs are created, they are available for selection when EDDA
is used to add a new data field. This script updates the list of valid
dataFieldSld values for new data fields by adding the new SLD to the list.

=head1 OPTIONS

=over 4

=item B<-h>

Prints command synposis

=back

=head1 CONFIGURATION

Looks for a configuration file: /tools/gdaac/[TS2,TS1]/cfg/giovanni/colormap.cfg.
It contains the mapping of color map name to SLD title and URL. For example:

%SLD = ( 
          sequential_ylgnbu_9 => { title=>"Sequential, Yellow-Green-Blue, 9-Step", url=>'http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/sequential_ylgnbu_9_sld.xml' }
          divergent_rdbu_10 => { title=>'Divergent, Red-Blue, 10-Step', url=>'http://s4ptu-ts2.ecs.nasa.gov/giovanni/sld/divergent_rdbu_10_sld.xml' }
          );

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

None

=head1 EXAMPLES

updateDataFieldSldValids.pl 'divergent_rdbu_10_sld.xml: divergent_rdbu_10'

=head1 AUTHOR

E. Seiler (Ed.Seiler@nasa.gov)

=head1 SEE ALSO

=cut

