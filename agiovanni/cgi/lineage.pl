#!/usr/bin/perl -T

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use strict;
use XML::LibXML;
use XML::LibXSLT;
use File::Temp;
use File::Basename;
use Safe;

$| = 1;

## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Get the Giovanni libraries
use Giovanni::Util;
use Giovanni::Status;
use Giovanni::CGI;

my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS => [ 'session', 'resultset', 'result' ],
);

my %input = $cgi->Vars();

# Holder for portal name
my $portal = undef;
my $sessionDir
    = qq($GIOVANNI::SESSION_LOCATION/$input{session}/$input{resultset}/$input{result});
my $inputFile = qq($sessionDir/input.xml);
my $xmlParser = XML::LibXML->new();
if ( -f $inputFile ) {
    my $userInputDoc = undef;
    eval { $userInputDoc = $xmlParser->parse_file($inputFile); };
    unless ($@) {
        my ($node) = $userInputDoc->findnodes('//portal');
        $portal = $node->textContent() if defined $node;
    }
}
my $maxUrlCount
    = defined $GIOVANNI::MAX_LINEAGE_URL_COUNT
    ? $GIOVANNI::MAX_LINEAGE_URL_COUNT
    : 10;
my $lineageDoc = getMakefileLineage( $sessionDir, $maxUrlCount );

my $lineageStyleSheet = $GIOVANNI::LINEAGE_XSL;
if ( defined $lineageDoc ) {
    my $downloadScript = dirname( $ENV{SCRIPT_NAME} ) . "/lineageText.pl";
    print STDERR "---$downloadScript\n";
    my $doc = $lineageDoc->documentElement();
    foreach my $node ( $doc->findnodes('//*[@TYPE="FILE"]') ) {
        my $file = $node->textContent();
        $file =~ s/^\s+|\s+$//g;

        # Assume the file is located in session directory if full path is
        # not specified
        my $dir = dirname($file);
        $file = qq($sessionDir/$file)
            unless ( $dir =~ /^\// );
        my $url = Giovanni::Util::convertFilePathToUrl( $file,
            \%GIOVANNI::URL_LOOKUP, $portal );
        if ( defined $url ) {
            $node->setAttribute( 'LABEL', basename($file) );
            $node->setAttribute( 'TYPE',  'URL' );
            $node->removeChildNodes();
            $node->appendText($url);
        }
    }

    # get the total elapsed time
    unless ( $doc->getAttribute('ELAPSED_TIME') ) {
        my $timeout          = $GIOVANNI::SESSION_TIMEOUT;
        my $status           = Giovanni::Status->new( $sessionDir, $timeout );
        my $totalElapsedTime = $status->getElapsedTime();
        $doc->setAttribute( 'ELAPSED_TIME', "$totalElapsedTime" );
    }
    if ( exists $input{type} && ( uc( $input{type} ) eq 'XML' ) ) {
        print $cgi->header( -type => 'text/xml' );
        print $lineageDoc->toString(2);
    }
    else {
        my $xslt       = XML::LibXSLT->new();
        my $styleDoc   = $xmlParser->parse_file($lineageStyleSheet);
        my $styleSheet = $xslt->parse_stylesheet($styleDoc);
        my $output     = $styleSheet->transform(
            $lineageDoc,
            XML::LibXSLT::xpath_to_string(
                maxUrlCount    => $maxUrlCount,
                downloadScript => $downloadScript,
                session        => $input{session},
                result         => $input{result},
                resultset      => $input{resultset}
            )
        );
        print $cgi->header( -type => 'text/html' );
        print $output->toString(2);
    }
}
else {
    print $cgi->header( -type => 'text/plain' ),
        "Failed to parse data lineage";
}

sub exit_with_error {
    my ($message) = @_;
    warn $message;
    print $cgi->header( -type => 'text/plain' ),
        "Failed to find data lineage";
    exit(0);
}

# Get the lineage for make based workflows
sub getMakefileLineage {
    my ( $sessionDir, $maxUrlCount ) = @_;

    # Create an XML document to hold consolidated provenance
    my $lineageDoc = Giovanni::Util::createXMLDocument('provenance');

    # Look for target file
    my $targetFile = qq($sessionDir/targets.txt);
    my @targetList = Giovanni::Util::readFile($targetFile);
    chomp @targetList if @targetList;

    # Get provenance groups
    my $provGroupFile = qq($sessionDir/provenance_group.txt);
    my @provGroupList = Giovanni::Util::readFile($provGroupFile);
    chomp @provGroupList;
    my $totalElapsedTime = 0;
    my %provNodeHash     = ();

    # For each target, get provenance
    foreach my $target (@targetList) {
        my $provFile = $target;
        $provFile =~ s/^mfst/prov/;
        $provFile = qq($sessionDir/$provFile);
        next unless -e $provFile;
        my $provDoc = Giovanni::Util::parseXMLDocument($provFile);
        next unless defined $provDoc;
        my @nodeList = $provDoc->findnodes('//step');
        foreach my $node (@nodeList) {

            # For each step,  add up elapsed time
            my $stepElapsedTime = $node->getAttribute('ELAPSED_TIME');
            $totalElapsedTime += $stepElapsedTime if defined $stepElapsedTime;

            # Remove input nodes as they are not displayed in lineage
            my ($inputNode) = $node->getChildrenByTagName('inputs');
            $inputNode->parentNode()->removeChild($inputNode)
                if defined $inputNode;

            # Keep only a preset number of output nodes
            $maxUrlCount++;
            my (@outputNodeList)
                = $node->findnodes(
                './outputs/output[position() <= ' . "$maxUrlCount]" );
            if ( @outputNodeList == $maxUrlCount ) {
                my $outParentNode = $outputNodeList[0]->parentNode();
                $outParentNode->removeChildNodes();
                foreach my $node (@outputNodeList) {
                    $outParentNode->appendChild($node);
                }
            }
        }
        my $targetType = ( $target =~ /mfst\.(.+?)\+d/ ) ? $1 : undef;
        next unless defined $targetType;
        $provNodeHash{$targetType}{$target} = []
            unless exists $provNodeHash{$targetType}{$target};
        push( @{ $provNodeHash{$targetType}{$target} }, @nodeList );
    }

    # Aggregate steps based on provenance groups
    foreach my $group (@provGroupList) {
        next unless keys %{ $provNodeHash{$group} };
        my $groupNode = XML::LibXML::Element->new('group');
        $groupNode->setAttribute( 'name', $group );
        my $groupElapsedTime = 0;
        foreach my $target ( keys %{ $provNodeHash{$group} } ) {
            foreach my $node ( @{ $provNodeHash{$group}{$target} } ) {
                $groupNode->appendChild($node);
                my $stepElapsedTime = $node->getAttribute('ELAPSED_TIME');
                $groupElapsedTime += $stepElapsedTime;
            }
        }
        $groupElapsedTime = formatTime($groupElapsedTime);
        $groupNode->setAttribute( 'ELAPSED_TIME', $groupElapsedTime );
        $lineageDoc->appendChild($groupNode);
    }
    $totalElapsedTime = formatTime($totalElapsedTime);
    $lineageDoc->setAttribute( 'ELAPSED_TIME', $totalElapsedTime );
    return $lineageDoc->parentNode();
}

sub formatTime {
    my ($timeStr) = @_;
    my ( $intStr, $decStr ) = split( /\./, sprintf( "%.2f", $timeStr ), 2 );
    if ( $decStr =~ /\S+/ ) {
        if ( $decStr =~ /^\d+$/ ) {
            $decStr =~ s/0+$//;
        }
        return ( $intStr . '.' . $decStr );
    }
    else {
        return $intStr;
    }
    return undef;
}


=head1 NAME

lineage.pl - returns lineage XML

=head1 SYNOPSYS

    export SCRIPT_NAME=/opt/giovanni4/cgi-bin/lineage.pl
    perl -T /home/csmit/public_html/giovanni4/cgi-bin/lineage.pl "session=D97FAB62-1840-11E9-8C02-DF271205CF9E&resultset=FA72D786-1840-11E9-A057-AC281205CF9E&result=FA74FCDC-1840-11E9-A057-AC281205CF9E"

=head1 DESCRIPTION

Returns an XML string with the lineage

=head2 Parameters

=over 12

=item session

Session UUID

=item resultset

Resultset UUID

=item result

result UUID

=back


=cut
