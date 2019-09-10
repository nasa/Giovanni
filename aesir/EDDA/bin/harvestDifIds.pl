#!/usr/bin/perl

my ($rootPath);
BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) )
      if defined $rootPath;
}

use strict;
use XML::LibXML;
use Getopt::Long;
use Safe;
#use Data::Dumper;

my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read configuration file $cfgFile\n";
}

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

die "Could not open $CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR : $!\n"
    unless opendir(DIR, $CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR);
my @prodFiles = grep { !/^\./ && -f "$CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR/$_" } readdir(DIR);
closedir(DIR);

my %entryIds;
foreach my $prodFile (@prodFiles) {
    my $prodFilePath = "$CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR/$prodFile";
    unless (-r $prodFilePath) {
        print STDERR "Readable file $prodFilePath not found\n";
        next;
    }
    my $dpDom;
    eval { $dpDom = $parser->parse_file( $prodFilePath ); };
    if ($@) {
        die "Could not read and parse $prodFilePath\n";
    }
    my $dpDoc = $dpDom->documentElement();
    my $node;
    ($node) = $dpDoc->findnodes( '/dataProduct/dataProductIdentifiers/value/dataProductGcmdEntryId' );
    if ($node) {
        my ($valueNode) = $node->findnodes( './value' );
        if ($valueNode) {
            my $value = $valueNode->textContent;
            $entryIds{$value} = 1 if $value;
        }
    }
}

my $outFile = $rootPath . 'cfg/EDDA/AESIR_GCMD_DIF_Entry_IDs.cfg';
open (OUT, "> $outFile") or die "Could not open $outFile for writing\n";
print OUT '%AESIR_GCMD_DIF_ENTRY_IDs = (', "\n";
foreach my $entryId (sort keys %entryIds) {
    print OUT "    '$entryId' => 1,\n";
}
print OUT ");\n\n1;\n";
print STDERR "Updated $outFile\n";

#print Dumper(\%entryIds);

exit 0;
