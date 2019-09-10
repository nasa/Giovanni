#!/usr/bin/perl
# $Id: addColorMap.pl,v 1.6 2013/09/06 15:57:23 mhegde Exp $
# -@@@ EDDA, Version $Name:  $
use Giovanni::Util;
use Giovanni::OGC::SLD;
use Getopt::Long;
use LWP::UserAgent;
use XML::LibXML;
use File::Basename;
use Safe;
use strict;

my $rootPath;
BEGIN{
    # Find the root path; by default, set to TS1
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : "/tools/gdaac/TS1/");
}
my ( $datafield, $colormap, $min, $max, $help );

# Get options
Getopt::Long::GetOptions( 'd=s'=>\$datafield, 'c=s'=>\$colormap, 'min=f'=>\$min, 'max=f'=>\$max, 'h'=>\$help );

# Print help if -h is specified
if ( $help ) {
    print $0, "\n",
    "\t-d   'data field id (from EDDA)'\n",
    "\t-c   'color map name' or do not specify to list available color maps\n",
    "\t-min 'minimum data value'\n",
    "\t-max 'maximum data value'\n";
    exit(0);
}

# Find the mode for use in URLs; by default, set to ts1 
my $mode = $rootPath =~ /TS2/ ? 'ts2': 'ts1';
# Color map configuration
my $cfgFile = $rootPath . "cfg/giovanni/colormap.cfg";
# Read generic colormaps
my $cpt = Safe->new('GIOVANNI');
unless ( $cpt->rdo($cfgFile) ) { 
    die "Failed to find color map file ($cfgFile)\n";
}
# Show available color maps
unless ( defined $colormap ){
    my @colorMapList = keys %GIOVANNI::SLD;
    print "Use -h for help\n\n";
    if ( @colorMapList ) {
        print "Available color palettes; supply color map name (see list below) with -c (ex: -c '$colorMapList[0]'):\n";
        my $i=1;
        foreach my $key ( @colorMapList ) {
            my $filler = ' 'x(length("$i")+2);
            print "$i) Name=$key\n",
                  "${filler}Title=$GIOVANNI::SLD{$key}{title}\n",
                  "${filler}URL=$GIOVANNI::SLD{$key}{url}\n";
            $i++;
        }
        print "\nExample: $0 -c '$colorMapList[0]' -d MOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean -min 0 -max 100\n";
    } else {
        die "Failed to find any generic color palettes\n";
    }
    exit(0);
}

die "Specify min (-min) and max (-max)" unless (defined $min && defined $max);
# Get the SLD
my $sldUrl=undef;
foreach my $key ( keys %GIOVANNI::SLD ) {
    next unless $key eq $colormap;
    $sldUrl = $GIOVANNI::SLD{$key}{url};
}
die "Failed to find $colormap color map\n" unless defined $sldUrl; 
my $sld=Giovanni::OGC::SLD->new(URL=>$sldUrl);

# Modify the SLD
die "Failed to update SLD; check whether $sldUrl is valid\n"
    unless $sld->modifyColorMap(MIN=>$min, MAX=>$max);
my $sldFile = "$rootPath/www/giovanni/sld/${datafield}_" . basename(URI->new($sldUrl)->path());
die "Failed to write $sldFile ($!)\n" unless Giovanni::Util::writeFile($sldFile, $sld->toString());
# Notation used in EDDA/AESIR for color maps
my $sldName = basename($sldFile) . ': ' . $colormap;

# Get the data field metadata
my $eddaGetUrl = 'http://s4ptu-' . $mode . '.ecs.nasa.gov/daac-bin/AESIR/EDDA/getDataFieldInfo?format=xml&dataFieldId=' . $datafield;
my $xmlParser = XML::LibXML->new();
my ($content, $errorMessage) = download( $eddaGetUrl );
if ( defined $content ) {
    my $dom = $xmlParser->parse_string( $content );
    my $doc = $dom->documentElement();
    # Find valids for SLD
    my (@validSldNodeList) = $doc->findnodes('//dataFieldSld/valids/valid');
    # Check if the node with the SLD being customized already exists
    my $validSldNode = undef;
    foreach my $sldNode ( @validSldNodeList ) {
        next unless ( $sldName eq $sldNode->textContent() );
        $validSldNode = $sldNode;
        last;
    }
    # If SLD doesn't exist as a valid, add a new one
    unless ( defined $validSldNode ){
        $validSldNode = XML::LibXML::Element->new('valid');
        $validSldNode->appendText($sldName);
        my ($parentNode) = $doc->findnodes('//dataFieldSld/valids');
        $parentNode->appendChild($validSldNode) if defined $parentNode;
    }
    # Check whether the SLD being added is already selected for the data field
    my (@selSldNodeList) = $doc->findnodes('//dataFieldSld/value');
    my $selSldNode = undef;
    foreach my $sldNode ( @selSldNodeList ) {
        next unless ( $sldName eq $sldNode->textContent() );
        $selSldNode = $sldNode;
        last;
    }
    # If the SLD isn't selected, add a new one
    unless ( defined $selSldNode ){
        $selSldNode = XML::LibXML::Element->new('value');
        $selSldNode->appendText($sldName);
        my ($parentNode) = $doc->findnodes('//dataFieldSld');
        $parentNode->appendChild($selSldNode) if defined $parentNode;
    }
    # Upload data field metadata to EDDA
    my $eddaPostUrl = 'http://s4ptu-' . $mode . '.ecs.nasa.gov/daac-bin/AESIR/EDDA/updateDataFieldInfo';
    my $ua = LWP::UserAgent->new();
    my ($dataFieldNode) = $doc->findnodes('//dataField');
    my $request = HTTP::Request::Common::POST( $eddaPostUrl, Content_Type=>'application/xml', Content=>$dataFieldNode->toString() );
    my $response = $ua->request( $request );
    if ( $response->is_success ) {
        # Check the response from EDDA
        my $content = $response->content();
        my $dom = $xmlParser->parse_string($content);
        my $doc = $dom->documentElement();
        my ($statusNode)=$doc->findnodes('//status');
        my $status = defined $statusNode ? $statusNode->textContent() : undef;
        if (defined $status) {
            if ( $status == 1 ) {
                print "Color map '$colormap' added for $datafield in $mode\n";
            } else {
                die "Failed to add color map\n";
            }
        }
    }else {
        die "Failed to add color map\n";
    }
} else {
    die defined $errorMessage ? $errorMessage : "Failed to download $eddaGetUrl\n";
}

# A method to download URL; returns content (undef on failure) and message (undef on success)
sub download
{
    my ( $url ) = @_;
    my $ua = LWP::UserAgent->new();
    my $response = $ua->get($url);
    return $response->is_success() ? ($response->content(), undef) : (undef, $response->content());
}


__END__

=head1 NAME

addColorMap.pl - Script to set data range in generic color maps and add them to data fields in EDDA

=head1 PROJECT

EDDA

=head1 SYNOPSIS

addColorMap.pl
[B<-d> Data field ID (from EDDA)]
[B<-c> Color map name]
[B<-min> data min value]
[B<-max> data max value ]
[B<-h>] 

=head1 DESCRIPTION

Specified a data field ID, a color map and data range (min,max), the script will modify the color map
and add it to EDDA. Note that modifications to data field in EDDA will not be published automatically. 
Publication has to be done through EDDA.

=head1 OPTIONS

=over 4

=item B<-h>

Prints command synposis

=item B<-d>

Data field ID in EDDA

=item B<-c>

Color map name 

=item B<-min>

Minimum data value used in color map

=item B<-max>

Maximum data value used in color map

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

addColorMap.pl -d MOD08_D3_051_Angstrom_Exponent_1_Ocean_QA_Mean -c Difference -min 0 -max 10 

=head1 AUTHOR

M. Hegde (Mahabaleshwa.S.Hegde@nasa.gov)

=head1 SEE ALSO

=cut

