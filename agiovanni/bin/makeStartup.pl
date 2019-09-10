#!/usr/bin/perl

#$Id: makeStartup.pl,v 1.11 2015/03/31 21:07:05 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'lib/perl5/site_perl/' . sprintf( "%vd", $^V ) )
        if defined $rootPath;
}

use Giovanni::Util;
use Getopt::Long;

my ( $opt_h, $type, $outMfstFile, $inFile ) = ( '', '', '', '' );

# Get command line options
Getopt::Long::GetOptions(
    'type=s'     => \$type,
    'in-file=s'  => \$inFile,
    'out-file=s' => \$outMfstFile,
    'h'          => \$opt_h
);

# If -h is specified, provide synopsis
die "$0\n"
    . "--type data, bbox or time\n"
    . "--in-file Giovanni input.xml\n"
    . "--out-file Manifest (output) file name\n"
    if ( $opt_h or $type eq '' or $inFile eq '' or $outMfstFile eq '' );

my $inputDoc = Giovanni::Util::parseXMLDocument($inFile);
unless ( defined $inputDoc ) {
    print STDERR "Failed to parse $inFile\n";
    exit(1);
}
my $outProvFile = $outMfstFile;
$outProvFile =~ s/mfst\./prov\./;
my $logFile = $outMfstFile;
$logFile =~ s/\.[^.]+$/.log/;

my $mfstDoc = Giovanni::Util::createXMLDocument('manifest');
my $provDoc = Giovanni::Util::createXMLDocument('provenance');

if ( $type eq 'time' ) {
    my $t1   = $inputDoc->findvalue('//starttime/text()');
    my $t2   = $inputDoc->findvalue('//endtime/text()');
    my $node = XML::LibXML::Element->new('starttime');
    $node->appendText($t1);
    $mfstDoc->appendChild($node);
    $node = XML::LibXML::Element->new('endtime');
    $node->appendText($t2);
    $mfstDoc->appendChild($node);
}
elsif ( $type eq 'bbox' ) {
    my $bbox = $inputDoc->findvalue('//bbox/text()');
    my $node = XML::LibXML::Element->new('bbox');
    $node->appendText($bbox);
    $mfstDoc->appendChild($node);
}
elsif ( $type eq 'data' ) {
    my $data = ( $outMfstFile =~ /\+d(.+)\.xml/ ) ? $1 : undef;
    unless ( defined $data ) {
        print STDERR "Failed to find data field name\n";
        exit(1);
    }
    my $node = XML::LibXML::Element->new('data');
    $node->appendText($data);
    $mfstDoc->appendChild($node);
}
elsif ( $type eq 'zval' ) {
    my $data = ( $outMfstFile =~ /\+d(.+)\.xml/ ) ? $1 : undef;
    unless ( defined $data ) {
        print STDERR "Failed to find data field name\n";
        exit(1);
    }
    my ( $data, $zval ) = split( /\+z/, $data, 2 );
    my $zval
        = $inputDoc->findvalue( '//data[text()=' . "'$data'" . ']/@zValue' );
    $zval = 'NA' unless $zval;
    my $units
        = $inputDoc->findvalue( '//data[text()=' . "'$data'" . ']/@units' );
    $units = 'NA' unless $units;
    my $node = XML::LibXML::Element->new('data');
    $node->setAttribute( 'zValue', $zval );
    $node->setAttribute( 'units',  $units );
    $node->appendText($data);
    $mfstDoc->appendChild($node);
}
else {
    print STDERR
        "Non-supported type: $type (valids are=data, bbox, zval and time)\n";
    exit(1);
}

unless ( -f $outMfstFile ) {
    unless ( Giovanni::Util::writeFile( $outMfstFile, $mfstDoc->toString() ) )
    {
        print STDERR "Failed to write manifest file\n";
    }
}

unless ( -f $outProvFile ) {
    unless ( Giovanni::Util::writeFile( $outProvFile, $provDoc->toString() ) )
    {
        print STDERR "Failed to write provenance file\n";
    }
}

## to create a z value manifest file
sub createZvalMfstXMLDoc {
    my ( $mfstout, $inDoc ) = @_;
    my $doc  = Giovanni::Util::createXMLDocument('manifest');
    my $zval = ( $mfstout =~ /\+v(.+)\+d(.+)\.xml/ ) ? $1 : undef;
    my $data = ( $mfstout =~ /\+v(.+)\+d(.+)\.xml/ ) ? $2 : undef;
    unless ( defined $zval ) {
        print STDERR "Failed to find z field value\n";
        exit(1);
    }
    unless ( defined $data ) {
        print STDERR "Failed to find data field name\n";
        exit(1);
    }
    my $dnode = XML::LibXML::Element->new('data');
    my $znode = XML::LibXML::Element->new('zval');
    $znode->appendText($zval);
    $doc->appendChild($znode);
    $dnode->appendText($data);
    $doc->appendChild($dnode);

    return $doc;
}
__END__

=head1 NAME

makeStartup.pl - Script to create data, spatial bounding box, date range manifest files for make based workflows.

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

makeStartup.pl
[B<-t> Manifest type (data|bbox|time|zval)]
[B<--outfile> Manifest file name]
[B<--infile> Giovanni input.xml file name]
[B<-h>] 

=head1 DESCRIPTION

It is run before launching make based workflows (before make all) and generally as make init.

=head1 OPTIONS

=over 4

=item B<h>

Prints command synposis

=item B<t>

Type of the manifest file being created. Valids are data, bbox or time.

=item B<out-file>

Manifest file name

=item B<in-file>

Name of the Giovanni input.xml file 

=back

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

None

=head1 EXAMPLES

makeStartup.pl --out-file mfsd.data_info.xml --in-file input.xml -t data

=head1 AUTHOR

M. Hegde (Mahabaleshwa.S.Hegde@nasa.gov)

=head1 SEE ALSO

=cut

