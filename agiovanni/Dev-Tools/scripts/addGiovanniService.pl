#!/usr/bin/perl

# $Id: addGiovanniService.pl,v 1.34 2015/06/26 17:33:30 mpetrenk Exp $
# $Version$

use Getopt::Long;
use Data::Dumper;
use XML::LibXML;
use Safe;
use strict;

# Get command line options
my ( $specFile, $prefix, $opt_h, $verbose );
$verbose = 0;
Getopt::Long::GetOptions(
    'f=s'      => \$specFile,
    'prefix=s' => \$prefix,
    'h'        => \$opt_h,
    'verbose'  => \$verbose
);

# Print synopsis
if ( defined $opt_h ) {
    print STDERR "$0\n"
        . "    -f [Giovanni service specification file]\n"
        . "    --prefix [Installation dir]\n"
        . "    --verbose [Verbose switch]\n";
    exit(0);
}

# Check for existence of service spec file
unless ( defined $specFile ) {
    print STDERR "Specify -f [Service specification file]\n";
    exit(1);
}
unless ( -f $specFile ) {
    print STDERR "Service specification file, $specFile, doesn't exist\n";
    exit(1);
}

# Check for existence of target directory
unless ( defined $prefix ) {
    print STDERR "Specify -prefix [Installation dir]\n";
    exit(1);
}
unless ( -d $prefix ) {
    print STDERR "$prefix directory doesn't exist\n";
    exit(1);
}

# Read Giovanni service spec file
my %svcSpec = readGiovanniServiceSpec($specFile);

# Update giovanni_services.xml
my $flag = updateGiovanniServiceConfig( $prefix, \%svcSpec, $verbose );

# Update workflow.cfg
$flag &= updateGiovanniWorkflowConfig( $prefix, \%svcSpec, $verbose );

# Update GiovanniLineage.xsl
$flag &= updateGiovanniLineageStyleSheet( $prefix, \%svcSpec, $verbose );
exit( $flag ? 0 : 1 );

# Dumps the hash using Data::Dumper
sub dumpHash {
    my ( $hashName, %hash ) = @_;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Purity   = 1;
    my $str = Data::Dumper->Dump( [ \%hash ], [$hashName] );
    my ( $lhs, $rhs ) = split( /=/, $str, 2 );
    $lhs =~ s/^\$(\S+)/\%$1/;
    $rhs =~ s/^\s*\{/\(/;
    $rhs =~ s/\}(\s*;\s*)/\)$1/;
    $str = "$lhs=$rhs";
    return $str;
}

# Reads Giovanni service spec file
sub readGiovanniServiceSpec {
    my ($file) = @_;
    my %specHash = ();
    local (*FH);
    if ( open( FH, $file ) ) {
        while ( my $str = <FH> ) {
            next if ( $str =~ /^#/ );
            my ( $lhs, $rhs ) = split( /=/, $str, 2 );
            next unless ( $lhs =~ /\S+/ );
            $lhs =~ s/^\s+|\s+$//g;
            $rhs =~ s/^\s+|\s+$//g;
            $rhs =~ s/^\"|\"+//g;
            $specHash{$lhs} = $rhs;
        }
        close(FH);
    }
    else {
    }
    return %specHash;
}

# Writes a file given file name and list of strings
sub writeFile {
    my ( $file, @strList ) = @_;
    local (*FH);
    if ( open( FH, '>', $file ) ) {
        print FH join( "\n", @strList ), "\n";
        return close(FH);
    }
    return 0;
}

# Updates giovanni_services.xml for the new service
sub updateGiovanniServiceConfig {
    my ( $prefix, $spec, $verbose ) = @_;

    # Mapping of service group to service label
    my %serviceGroup = (
        'timeseries' => 'Time Series',
        'comparison' => 'Comparisons',
        'vertical'   => 'Vertical',
        'maps'       => 'Maps',
        'Misc'       => 'Miscellaneous'
    );

    my %plotToServiceGroupMap = (
        'HOV_LAT'                  => 'timeseries',
        'INTERACTIVE_TIME_SERIES'  => 'timeseries',
        'MAP_ANIMATION'            => 'maps',
        'SCATTER_PLOT_GNU'         => 'comparison',
        'INTERACTIVE_SCATTER_PLOT' => 'comparison',
        'INTERACTIVE_MAP'          => 'maps',
        'INTERACTIVE_OVERLAY_MAP'  => 'maps',
        'HOV_LON'                  => 'timeseries',
        'VERTICAL_PROFILE'         => 'vertical',
        'VERTICAL_PROFILE_GNU'     => 'vertical',
        'TIME_SERIES'              => 'timeseries',
        'TIME_SERIES_GNU'          => 'timeseries',
        'TIME_SERIES_CURTAIN'      => 'vertical',
        'CURTAIN'                  => 'vertical'
    );

    my $svcXmlFile = "$prefix/cfg/giovanni_services.xml";
    my $xmlParser  = XML::LibXML->new();
    $xmlParser->keep_blanks(0);
    my $dom;
    print STDERR "Parsing $svcXmlFile\n" if $verbose;
    eval { $dom = $xmlParser->parse_file($svcXmlFile); };
    unless ( defined $dom ) {
        warn "Failed to parse $svcXmlFile";
        return 0;
    }
    my $doc = $dom->documentElement();

    # If the service exists already, delete it
    my @nodeList
        = $doc->findnodes(qq(//service[\@name='$spec->{SERVICE_NAME}']));
    foreach my $node (@nodeList) {
        $node->parentNode()->removeChild($node);
    }

    # Find group to which service belongs
    @nodeList
        = $doc->findnodes(qq(//service[\@plot_type='$spec->{PLOT_TYPE}']));
    my ( $groupName, $groupLabel );

    if ( exists $plotToServiceGroupMap{ $spec->{PLOT_TYPE} } ) {
        $groupName  = $plotToServiceGroupMap{ $spec->{PLOT_TYPE} };
        $groupLabel = $serviceGroup{$groupName};
    }
    elsif (@nodeList) {
        $groupName  = $nodeList[0]->getAttribute('group');
        $groupLabel = $nodeList[0]->getAttribute('groupLbl');
    }
    else {
        $groupName  = 'Misc';
        $groupLabel = 'Miscellaneous';
    }
    print STDERR "Adding the service under '$groupLabel' service group\n"
        if $verbose;

    # Add a new service
    my $svc = XML::LibXML::Element->new('service');
    $svc->setAttribute( 'name',        $spec->{SERVICE_NAME} );
    $svc->setAttribute( 'label',       $spec->{SERVICE_LABEL} );
    $svc->setAttribute( 'description', $spec->{SERVICE_DESCRIPTION} );
    $svc->setAttribute( 'helplink',    $spec->{SERVICE_HELP} );
    $svc->setAttribute( 'group',       $groupName );
    $svc->setAttribute( 'groupLbl',    $groupLabel );
    $svc->setAttribute( 'plot_type',   $spec->{PLOT_TYPE} );
    $svc->setAttribute( 'max_points',  $spec->{MAX_POINTS} )
        if defined $spec->{MAX_POINTS};
    $svc->setAttribute( 'max_points_guest',  $spec->{MAX_POINTS_GUEST} )
        if defined $spec->{MAX_POINTS_GUEST};
    $svc->setAttribute( 'max_frames', $spec->{MAX_FRAMES} )
        if defined $spec->{MAX_FRAMES};
    $svc->setAttribute( 'max_frames_guest', $spec->{MAX_FRAMES_GUEST} )
        if defined $spec->{MAX_FRAMES_GUEST};
    $svc->setAttribute( 'default', $spec->{DEFAULT} )
        if defined $spec->{DEFAULT};
    $svc->setAttribute( 'groupDefault', $spec->{GROUP_DEFAULT} )
        if defined $spec->{GROUP_DEFAULT};

    if ( $spec->{SERVICE_NAME} eq 'TmAvMp' ) {

        # Always place this service on top
        my @childNodes = $doc->childNodes();
        $doc->appendChild($svc) if !scalar @childNodes;
        $doc->insertBefore( $svc, $childNodes[0] ) if scalar @childNodes;
    }
    else {
        $doc->appendChild($svc);
    }

    # Write out file
    if ( writeFile( $svcXmlFile, $doc->toString(2) ) ) {
        print STDERR "Updated $svcXmlFile\n";
        return 1;
    }
    else {
        warn "Failed to update services configuration";
        return 0;
    }
}

sub updateGiovanniLineageStyleSheet {
    my ( $prefix, $spec, $verbose ) = @_;

    my $xslFile   = "$prefix/cfg/GiovanniLineage.xsl";
    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);
    my $dom;
    print STDERR "Parsing $xslFile\n" if $verbose;
    eval { $dom = $xmlParser->parse_file($xslFile); };
    unless ( defined $dom ) {
        warn "Failed to parse $xslFile";
        return 0;
    }
    my $doc = $dom->documentElement();

    # Find nodes where title for the service step needs to be added
    my @nodes = $doc->findnodes('//xsl:template[@match="group"]//xsl:choose');
    unless (@nodes) {
        warn "Failed to find node to insert in lineage stylesheet";
        return 0;
    }
    my $chooseNode = $nodes[0];

    # Get any preexisting nodes
    @nodes = $chooseNode->findnodes('./xsl:when');
    foreach my $node (@nodes) {
        next
            unless ( $node->getAttribute('test') eq
            qq(\@name="result+s$spec->{SERVICE_NAME}") );
        $chooseNode->removeChild($node);
    }

    my $groupNode = XML::LibXML::Element->new('xsl:when');
    $groupNode->setAttribute( 'test',
        '@name="result+s' . $spec->{SERVICE_NAME} . '"' );
    $groupNode->appendText( $spec->{SERVICE_LABEL} );

    my ($otherNode) = $chooseNode->findnodes('./xsl:otherwise');
    if ( defined $otherNode ) {
        $chooseNode->insertBefore( $groupNode, $otherNode );
    }
    else {
        $chooseNode->appendChild($groupNode);
    }

    print STDERR "Updating $xslFile\n" if $verbose;
    if ( writeFile( $xslFile, $doc->toString(1), "\n" ) ) {
        print STDERR "Updated $xslFile\n";
    }
    else {
        warn "Failed to update $xslFile";
        return 0;
    }
    return 1;
}

# Updates workflow.cfg after creating make include segment for the service
sub updateGiovanniWorkflowConfig {
    my ( $prefix, $spec, $verbose ) = @_;

#my @criticalFields = qw(SERVICE_NAME PLOT_TYPE SERVICE_LABEL SERVICE_DESCRIPTION ALGORITHM_CMD );

    my $wfCfgDir = "$prefix/cfg";

    # Read workflow.cfg
    my $wfCfgFile = "$wfCfgDir/workflow.cfg";
    my $cpt       = Safe->new('WORKFLOW');
    print "Reading $wfCfgFile\n" if $verbose;
    unless ( $cpt->rdo($wfCfgFile) ) {
        warn "Failed to read $wfCfgFile";
        return 0;
    }

    # Find workflows to be included
    my @wfFileList = qw(common.make);

    # Create service specific makefile segment
    my $svcWfFile    = lc( $spec->{SERVICE_NAME} );
    my $svcWfContent = "";
    foreach my $key (
        qw(ALGORITHM_CMD OUTPUT_FILE_ROOT DATELINE_METHOD COMPARISON SERVICE_LABEL SERVICE_DESCRIPTION SKIP_REGRID PLOT_TYPE MAX_POINTS MAX_POINTS_GUEST MAX_FRAMES MAX_FRAMES_GUEST CONVERT_UNITS_STEP COMBINE_OUTPUTS OUTPUT_TYPE LATITUDE_WEIGHTING_FUNCTION)
        )
    {
        $svcWfContent .= "$key = $spec->{$key}\n" if exists( $spec->{$key} );
    }
    print "Creating $svcWfFile.make\n" if $verbose;
    if ( writeFile( "$wfCfgDir/$svcWfFile.make", $svcWfContent ) ) {
        push( @wfFileList, $svcWfFile . '.make' );
    }
    else {
        warn "Failed to create $svcWfFile";
        return 0;
    }

    if ( exists $spec->{COMPARISON} and $spec->{COMPARISON} ne '' ) {
        push( @wfFileList, 'comparison.make' );
    }
    else {
        push( @wfFileList, 'singlefield.make' );
    }

    # Add service to giovanni_services.xml
    $WORKFLOW::WORKFLOW_MAP{ $spec->{SERVICE_NAME} } = {
        plot_type   => $spec->{PLOT_TYPE},
        label       => $spec->{SERVICE_LABEL},
        description => $spec->{SERVICE_DESCRIPTION},
        file        => \@wfFileList,
    };

    # Write wrofklow.cfg
    my $wfCfgFile = "$wfCfgDir/workflow.cfg";
    my $str1
        = Data::Dumper->Dump( [$WORKFLOW::WORKFLOW_DIR], [qw(WORKFLOW_DIR)] );
    my $str2 = dumpHash( 'WORKFLOW_MAP', %WORKFLOW::WORKFLOW_MAP );
    print STDERR "Adding service to $wfCfgFile\n" if $verbose;
    if ( writeFile( $wfCfgFile, $str1, $str2 ) ) {
        print STDERR "Updated $wfCfgFile\n";
    }
    else {
        warn "Failed to update $wfCfgFile";
        return 0;
    }
    return 1;
}

__END__

=head1 NAME

addGiovanniService.pl - Script to expose a service in Giovanni

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

addGiovanniService.pl
[B<-f> Giovanni service specification file]
[B<--prefix> Giovanni installation directory]
[B<--verbose> verbose flag (0 or 1)]
[B<-h>]

=head1 DESCRIPTION

Given a service specification file and the Giovanni installation directory, the script updates giovanni_services.xml and workflow.cfg. giovanni_services.xml exposes the newly added service in the user interface. workflow.cfg exposes the newly added service as a workflow.

=head1 OPTIONS

=over 4

=item B<h>

Prints command synposis

=item B<prefix>

Giovanni installation directory

=item B<f>

Giovanni service specification file

=item B<verbose>

Verbose flag to indicate the level of logging detail. Valids are 0 or 1. 0 (default) turns off detailed logging.

=back

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

None

=head1 EXAMPLES

perl addGiovanniService.pl -f /var/scratch/hegde/trunk/aGiovanni_Algorithms/Giovanni-Algorithm-Accumulate/ACCUMULATE.svc --prefix ~/public_html/ --verbose

=head1 AUTHOR

M. Hegde (Mahabaleshwa.S.Hegde@nasa.gov)

=head1 SEE ALSO

=cut

