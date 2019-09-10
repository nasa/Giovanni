# $Id: SLD.pm,v 1.68 2015/08/10 14:05:15 mhegde Exp $
# $Version$
package Giovanni::OGC::SLD;

use 5.008008;
use strict;
use warnings;
use XML::LibXML;
use LWP::UserAgent;
use File::Temp;
use Giovanni::Util;
use POSIX qw/ceil/;
use POSIX qw/floor/;
use List::Util;
use URI;
use HTTP::Request;
use HTTP::Response;
use Scalar::Util qw/looks_like_number/;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(
            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '1.00';

sub new() {
    my ( $class, %input ) = @_;
    my $self = {};
    bless( $self, $class );
    $self->{dom}    = undef;
    $self->{layers} = {};

    if ( exists $input{NDIGITS} ) {
        $self->{nDigitsLabel} = $input{NDIGITS};
    }
    else {

        # use 4 digits in the labels by default
        $self->{nDigitsLabel} = 4;
    }

    if ( exists $input{FILE} ) {
        if ( -f $input{FILE} ) {
            $self->parseFile( $input{FILE} );
        }
        else {
            print STDERR "$input{FILE} doesn't exist\n";
        }
    }
    elsif ( exists $input{STRING} ) {
        $self->parseString( $input{STRING} );
    }
    elsif ( exists $input{URL} ) {
        $self->parseFile( $input{URL} );
    }
    return $self;
}

# Parses XML file or URL
sub parseFile() {
    my ( $self, $file ) = @_;
    my $parser = XML::LibXML->new();
    my $uri    = URI->new($file);
    if (    defined $uri
        and defined $uri->scheme()
        and $uri->scheme() eq 'https' )
    {

        # If the protocol is https, download the URL first due to lack
        # of https support in XML::LibXML
        my $agent    = LWP::UserAgent->new();
        my $response = $agent->get($file);
        if ( $response->is_success() ) {
            eval {
                $self->{dom} = $parser->load_xml(
                    string => $response->content(),
                    { no_blanks => 1 }
                );
            };
        }
        else {
            print STDERR "Failed to download SLD: $file";
            return 0;
        }
    }
    else {
        eval {
            $self->{dom}
                = $parser->load_xml( location => $file, { no_blanks => 1 } );
        };
    }
    unless ( defined $self->{dom} ) {
        print STDERR "Failed to parse SLD: $file\n";
        return 0;
    }
    return $self->_dom2hash();
}

# Parses XML string
sub parseString() {
    my ( $self, $str ) = @_;
    my $parser = XML::LibXML->new();
    eval {
        $self->{dom}
            = $parser->load_xml( location => $str, { no_blanks => 1 } );
    };
    unless ( defined $self->{dom} ) {
        print STDERR "Failed to parse SLD text\n";
        return 0;
    }
    return $self->_dom2hash();
}

# Gets the XPath context with all namespaces registered and default namespace
# prefix is set to 'default'
sub getXPathContext {
    my ($self) = @_;

    my $doc = $self->{dom}->documentElement();

    # Get and register namespaces
    my $xpc = XML::LibXML::XPathContext->new($doc);

    # A holder to avoid duplicates
    my %nameSpace = ();
    foreach my $nsNode ( $doc->findnodes('//namespace::*') ) {
        my $prefix = $nsNode->getLocalName();
        $prefix = 'default' unless defined $prefix;
        my $uri = $nsNode->getData();
        $nameSpace{$prefix} = $uri;
    }
    foreach my $prefix ( keys %nameSpace ) {
        $xpc->registerNs( $prefix, $nameSpace{$prefix} );
    }
    return $xpc;
}

# Converts SLD DOM to internal hash:
# layers=>{ <layer n> => { colors=>[], labels=>[], thresholds=>[] } }
sub _dom2hash() {
    my ($self) = @_;

    return 0 unless defined $self->{dom};

    # Get XPATH context and register namespaces
    my $xpc = $self->getXPathContext();
    foreach my $layerNode (
        $xpc->findnodes('/default:StyledLayerDescriptor/default:NamedLayer') )
    {
        my $layerName = $xpc->findvalue( './se:Name', $layerNode );
        my $userStyleName
            = $xpc->findvalue( './default:UserStyle/se:Name', $layerNode );
        my $unitInfo
            = $xpc->findvalue(
            './default:UserStyle/se:FeatureTypeStyle/se:Rule/se:Name',
            $layerNode );
        my $fillColor = $xpc->findvalue(
            './default:UserStyle/se:FeatureTypeStyle/se:Rule/se:RasterSymbolizer/se:ColorMap/se:Categorize/@fallbackValue',
            $layerNode
        );
        my ( $colorList, $labelList, $thresholdList ) = ( [], [], [] );
        foreach my $colorNode (
            $xpc->findnodes(
                '//se:RasterSymbolizer//se:ColorMap//se:Value', $layerNode
            )
            )
        {
            my $color = $colorNode->textContent();
            push( @$colorList, $color );
            my $thresholdNode = $colorNode->nextNonBlankSibling();
            if ( defined $thresholdNode
                and $thresholdNode->getLocalName() eq 'Threshold' )
            {
                push( @$thresholdList, $thresholdNode->textContent() );
            }
        }
        $self->{layers}{$layerName}{userstyle}  = $userStyleName;
        $self->{layers}{$layerName}{colors}     = $colorList;
        $self->{layers}{$layerName}{labels}     = $labelList;
        $self->{layers}{$layerName}{thresholds} = $thresholdList;
        $self->{layers}{$layerName}{fillColor}  = $fillColor;
        $self->{layers}{$layerName}{sldUnit}    = $unitInfo;

        # By default, we assume a layer is for float data, not integer data,
        # for the purpose of creating legend values.
        $self->{layers}{$layerName}{intData} = 0;

        if ( looks_like_number( $thresholdList->[0] ) ) {

            # if this SLD had threshold values, setup the legend values
            $self->_updateLegendValues($layerName);
        }
    }
    return 1;
}

# Returns label array given a layer name
sub getLabels() {
    my ( $self, $name ) = @_;

    # If the layer name is not supplied, use one from the list of layers
    ($name) = keys %{ $self->{layers} } unless defined $name;
    if ( defined $name ) {
        return
            exists $self->{layers}{$name}
            ? @{ $self->{layers}{$name}{labels} }
            : ();
    }
    return ();
}

sub getLegendScale() {
    my ( $self, $name ) = @_;

    # If the layer name is not supplied, use one from the list of layers
    ($name) = keys %{ $self->{layers} } unless defined $name;
    if ( defined $name ) {
        return
            exists $self->{layers}{$name}
            ? $self->{layers}{$name}{legendScale}
            : undef;
    }
    return undef;

}

# Returns colors array given layer name
sub getColors() {
    my ( $self, $name ) = @_;

    # If the layer name is not supplied, use one from the list of layers
    ($name) = keys %{ $self->{layers} } unless defined $name;
    if ( defined $name ) {
        return
            exists $self->{layers}{$name}
            ? @{ $self->{layers}{$name}{colors} }
            : ();
    }
    return ();
}

# Returns the fill color
sub getFillColor() {
    my ( $self, $name ) = @_;

    # If the layer name is not supplied, use one from the list of layers
    ($name) = keys %{ $self->{layers} } unless defined $name;
    if ( defined $name ) {
        return
            exists $self->{layers}{$name}
            ? $self->{layers}{$name}{fillColor}
            : undef;
    }
    return undef;
}

# Returns thresholds array given layer name
sub getThresholds() {
    my ( $self, $name ) = @_;

    # If the layer name is not supplied, use one from the list of layers
    ($name) = keys %{ $self->{layers} } unless defined $name;
    if ( defined $name ) {
        return
            exists $self->{layers}{$name}
            ? @{ $self->{layers}{$name}{thresholds} }
            : ();
    }
    return ();
}

# Set whether or not an SLD layer is for integer data. Triggers an update to
# the labels because integer data only gets integer colorbar legend labels.
sub setIntData() {
    my ( $self, $intData, $name ) = @_;

    ($name) = keys %{ $self->{layers} } unless defined $name;
    if ( defined($name) ) {
        $self->{layers}{$name}{intdata} = $intData;

        # If there are thresholds, update the legend values
        if ( looks_like_number( $self->{layers}->{$name}{thresholds}->[0] ) )
        {
            $self->_updateLegendValues($name);
        }

        return 1;
    }
    else {
        return 0;
    }

}

# Return whether or not an SLD layer is for integer data.
sub getIntData() {
    my ( $self, $name ) = @_;
    ($name) = keys %{ $self->{layers} } unless defined $name;
    if ( defined($name)
        && looks_like_number( $self->{layers}->{$name}{thresholds}->[0] ) )
    {
        return $self->{layers}{$name}{intdata};
    }
    else {
        return ();
    }

}

# Set the thresholds for a layer in this SLD. Triggers a change to legends as
# well.
sub setThresholds() {
    my ( $self, $values, $name ) = @_;

    # If the layer name is not supplied, use one from the list of layers
    ($name) = keys %{ $self->{layers} } unless defined $name;
    if ( defined $name && $values ) {
        $self->{layers}{$name}{thresholds} = $values;
        $self->_updateLegendValues($name);
    }

}

# update the legend values in the object to reflect the current thresholds
sub _updateLegendValues() {
    my ( $self, $name ) = @_;

    # If the layer name is not supplied, use one from the list of layers
    ($name) = keys %{ $self->{layers} } unless defined $name;

    # get the threshold values
    my @thresholds = $self->getThresholds($name);

    # figure out how best to represent the thresholds
    my ( $mantissas, $exponents ) = _convertToFiniteRepresentation(
        THRESHOLDS => \@thresholds,
        NDIGIT     => $self->{nDigitsLabel}
    );

    my @labels = ();
    my $legendExponent;

    if ( scalar( @{$exponents} ) == 1 ) {

        # we have one exponent for all the mantissas
        @labels         = @{$mantissas};
        $legendExponent = $exponents->[0];
    }
    else {

        # we have one exponent per mantissa.
        for ( my $i = 0; $i < scalar( @{$exponents} ); $i++ ) {

            # print this threshold has <mantissa>e<exponent. E.g. - "10e+02"
            # unless the exponent is zero.
            if ( $exponents->[$i] == 0 ) {
                push( @labels, $mantissas->[$i] );
            }
            else {
                push( @labels,
                    sprintf( "%se%+.2d", $mantissas->[$i], $exponents->[$i] )
                );
            }
        }

        $legendExponent = 0;
    }

    # Set the legend scale
    $self->{layers}{$name}{legendScale} = 10**$legendExponent;

    # There is one more color than there are thresholds
    my $numColors = scalar(@thresholds) + 1;

    # Calculate how many labels are duplicated to avoid duplicate labels
    my $labelIncrement1 = 1;
    my $duplicate       = 1;
    for ( my $i = 0; $i < $numColors - 2; $i++ ) {
        if ( $labels[$i] == $labels[ $i + 1 ] ) {
            $duplicate++;
            $labelIncrement1
                = $duplicate > $labelIncrement1
                ? $duplicate
                : $labelIncrement1;
        }
        else {
            $duplicate = 1;
        }

    }
    my $labelIncrement2 = $labelIncrement1 > 2 ? $labelIncrement1 : 2;

    my $labelInterval = int( $numColors / 5 );

    my $min = $thresholds[0];
    my $max = $thresholds[-1];

    # set the labels
    for ( my $i = 0; $i < $numColors - 1; $i++ ) {
        if (( $numColors <= 12 && $i % $labelIncrement1 == 0 )
            || (   $numColors > 12
                && $numColors <= 24
                && $i % $labelIncrement2 == 0 )
            || ( $numColors > 24 && ( $i % $labelInterval == 0 ) )
            || $i == 0
            || $i == $numColors - 2
            )
        {
            $self->{layers}{$name}{labels}[$i] = $labels[$i];
            if ( $self->{layers}{$name}{intdata}
                && ( $labels[$i] != int( $labels[$i] ) ) )
            {
                if ( ( $max - $min ) < $numColors ) {
                    $self->{layers}{$name}{labels}[$i] = "";
                }
                else {
                    $self->{layers}{$name}{labels}[$i] = int( $labels[$i] );
                }
            }
            if (   ( $labels[$i] == $labels[ $numColors - 2 ] )
                && ( $i != $numColors - 2 ) )
            {
                $self->{layers}{$name}{labels}[$i] = "";
            }
        }
        else {
            $self->{layers}{$name}{labels}[$i] = "";
        }

    }

}

#Returns SLD data range
sub getDataRange() {
    my ( $self, $name ) = @_;

    # If the layer name is not supplied, use one from the list of layers
    ($name) = keys %{ $self->{layers} } unless defined $name;
    my @thresholds = $self->getThresholds($name);
    return () unless ( @thresholds > 1 );
    return ( $thresholds[0], $thresholds[-1] )
        if ( ( $thresholds[0] ne '' ) and ( $thresholds[-1] ne '' ) );
    return ();
}

sub getUnit() {
    my ( $self, $name ) = @_;
    ($name) = keys %{ $self->{layers} } unless defined $name;
    return $self->{layers}{$name}{sldUnit}
        if defined $self->{layers}{$name}{sldUnit};
    return 1;
}

sub setUnit () {
    my ( $self, $unit, $name ) = @_;
    ($name) = keys %{ $self->{layers} } unless defined $name;
    $self->{layers}{$name}{sldUnit} = $unit;
}

# Returns layer name
sub getLayerName() {
    my ($self) = @_;
    return unless defined wantarray;
    my @nameList = keys %{ $self->{layers} };
    return wantarray ? @nameList : ( @nameList ? $nameList[0] : undef );
}

# Sets the layer name given the old and the new name
sub setLayerName() {
    my ( $self, @options ) = @_;

    # If no arguments specified, return false
    return 0 unless @options;
    my %nameMap = ();
    if ( @options == 1 ) {

# If only one argument is specified, assume that first layer needs to be renamed
        my ($oldName) = $self->getLayerName();
        return 0 unless defined $oldName;
        $nameMap{$oldName} = $options[0];
    }
    elsif ( @options % 2 == 0 ) {

        # Case of old/new name pairs specified
        %nameMap = @options;
    }
    else {

        # Case of not specifying name pairs
        return 0;
    }

    my $xpc = $self->getXPathContext();

    # Rename layer names
    while ( my ( $oldName, $newName ) = each %nameMap ) {
        my ($layerNameNode)
            = $xpc->findnodes(
            '//default:StyledLayerDescriptor/default:NamedLayer/se:Name[text()='
                . qq("$oldName")
                . ']' );
        $layerNameNode->removeChildNodes();
        $layerNameNode->appendText($newName);
        $self->{layers}{$newName} = $self->{layers}{$oldName};
    }

    # Delete old layer names
    foreach my $oldName ( keys %nameMap ) {
        delete $self->{layers}{$oldName};
    }
    return 1;
}

# Sets the user style name
sub setUserStyleName() {
    my ( $self, $styleName ) = @_;
    my $layer;
    ($layer) = keys %{ $self->{layers} } unless defined $layer;
    $self->{layers}{$layer}{userstyle} = $styleName;
}

# Get the user style name (used in colormap thumbnail)
sub getUserStyleName() {
    my ($self) = @_;
    return unless defined wantarray;
    my @nameList
        = map { $self->{layers}{$_}{userstyle} } keys %{ $self->{layers} };
    return wantarray ? @nameList : ( @nameList ? $nameList[0] : undef );
}

# Creates thumbnail
sub createThumbnail() {
    my ( $self, %input ) = @_;

    # Color bar default height and width in pixels
    my $colorBarHeight = exists $input{HEIGHT} ? $input{HEIGHT} : 12;
    my $colorBarWidth  = exists $input{WIDTH}  ? $input{WIDTH}  : 64;
    my $pngFile        = exists $input{FILE}   ? $input{FILE}   : undef;
    my @colorList      = $self->getColors();

    # Create SVG document
    my $parser = XML::LibXML->new();
    my $svgDom
        = $parser->parse_string(
        qq(<svg width="$colorBarWidth" height="$colorBarHeight" xmlns="http://www.w3.org/2000/svg"><g></g></svg>)
        );
    my $svgDoc = $svgDom->documentElement();
    my $xc     = XML::LibXML::XPathContext->new($svgDoc);
    $xc->registerNs( 'svg', "http://www.w3.org/2000/svg" );

    # Get the group node in SVG
    my ($gNode) = $xc->findnodes('//svg:g');

    # Find the individual color cell width
    my $colorCellWidth
        = $colorBarWidth * 1.0 / ( @colorList > 0 ? @colorList : 1 );

    # Variables to hold X position and a counter
    my ( $x, $i ) = ( 0, 0 );
    foreach my $color (@colorList) {
        my $node = XML::LibXML::Element->new('rect');
        $node->setAttribute( 'id',     'svg_' . $i );
        $node->setAttribute( 'height', $colorBarHeight );
        $node->setAttribute( 'width',
            $colorCellWidth + $colorCellWidth * .01 );
        $node->setAttribute( 'y',            0 );
        $node->setAttribute( 'x',            $x );
        $node->setAttribute( 'stroke-width', 0 );
        $node->setAttribute( 'fill',         $color );
        $gNode->appendChild($node);
        $x += $colorCellWidth;
        $i++;
    }

    # Write SVG file
    my $fh = File::Temp->new( SUFFIX => '.svg' );
    print $fh $svgDoc->toString(2);
    close($fh);

    # Convert SVG to PNG
    `convert $fh $pngFile`;
    if ($?) {
        return 0;
    }
    return 1;
}

# Converts to SLD 1.1 XML string
sub toString() {
    my ($self) = @_;
    unless ( defined $self->{dom} ) {
    }
    my $xpc = $self->getXPathContext();
    foreach my $layer ( keys %{ $self->{layers} } ) {
        my ($layerNode)
            = $xpc->findnodes(
            '//default:StyledLayerDescriptor/default:NamedLayer/se:Name[text()='
                . qq("$layer")
                . ']/..' );
        my ($catNode)
            = $xpc->findnodes(
            '//se:RasterSymbolizer/se:ColorMap/se:Categorize', $layerNode );

        foreach my $node (
            $xpc->findnodes(
                './*[name()="se:Value" or name()="se:Threshold"]', $catNode
            ),
            $xpc->findnodes(
                './node()[self::text()[not(normalize-space())]]', $catNode
            )
            )
        {
            $node->parentNode()->removeChild($node);
        }

        my @colorList     = $self->getColors();
        my @thresholdList = $self->getThresholds();
        for ( my $i = 0; $i < @colorList; $i++ ) {
            my $valueNode = XML::LibXML::Element->new('se:Value');
            $valueNode->appendText( $colorList[$i] );
            $catNode->appendChild($valueNode);
            if ( $i < @thresholdList ) {
                my $thresholdNode = XML::LibXML::Element->new('se:Threshold');
                $thresholdNode->appendText( $thresholdList[$i] );
                $catNode->appendChild($thresholdNode);
            }
        }
    }
    return defined $self->{dom} ? $self->{dom}->toString(1) : '';
}

# Returns the color table in NCL supported format
# See http://www.ncl.ucar.edu/Document/Graphics/create_color_table.shtml for details
sub getNclColorTable() {
    my ($self) = @_;

    # Get colors
    my @colorList = $self->getColors();
    return undef unless @colorList;

    my $colorTableStr = "ncolors=" . @colorList . "\n" . "# r g b\n";
    my $hexToInt      = sub {
        my ($hexStr) = @_;
        my $intVal = sprintf( "%d", hex($hexStr) );
        my $len = length($intVal);
        $intVal .= ' ' x ( 4 - $len );
        return $intVal;
    };
    foreach my $color (@colorList) {
        if ( $color =~ /^#/ ) {

            # Case of HTML hex colors
            my ( $red, $green, $blue ) = (
                $hexToInt->( substr( $color, 1, 2 ) ),
                $hexToInt->( substr( $color, 3, 2 ) ),
                $hexToInt->( substr( $color, 5, 2 ) ),
            );
            $colorTableStr .= "$red $green $blue\n";
        }
    }
    return $colorTableStr;
}

# Convert hex rgb to individual R, G and B values
sub hexStringToRGB {
    my $s = $_[0];
    map { hex( '0x' . substr( $s, $_, 2 ) ) } ( 1, 3, 5 );
}

# Return GrADS statements to set up a color table corresponding to an SLD spec
sub getGrADSColorSettings() {
    my ( $self, $name ) = @_;
    my @colorList = $self->getColors();
    ($name) = keys %{ $self->{layers} } unless defined $name;
    my @levelsList = $self->getThresholds($name);

    # Start beyond the GrADS default colors
    my $offset = 16;
    my ( $i, @settings );
    my $n_colors = scalar(@colorList);
    for ( $i = 0; $i < $n_colors; $i++ ) {
        my ( $red, $green, $blue ) = hexStringToRGB( $colorList[$i] );

        # e.g, set rgb 17 235 235 235
        push @settings,
            sprintf(
            "set rgb %d %d %d %d",
            $i + $offset,
            $red, $green, $blue
            );
    }
    my ( $red1, $green1, $blue1 ) = hexStringToRGB( $self->getFillColor() );
    my $backGroundSetting
        = sprintf( "set rgb %d %d %d %d", $i + $offset, $red1, $green1,
        $blue1 );
    push @settings,
        join( " ", "set ccols", $offset .. $offset + $n_colors - 1 );
    push @settings, join( " ", "set clevs", @levelsList );
    return ( \@settings, $backGroundSetting );
}

# Returns the color table in Ferret supported format
# (see http://ferret.pmel.noaa.gov/Ferret/documentation/users-guide/customizing-plots/COLOR for more info)
sub getFerretColorTable() {
    my ($self) = @_;

    # Get colors
    my @colorNodeList   = $self->getColorNodes();
    my $colorTableStr   = "RGB_Mapping By_value\n";
    my $hexToPercentage = sub {
        my ($hexStr) = @_;
        my $hexVal = sprintf( "%.2f", hex($hexStr) * 100.0 / 255.0 );
        my $len = length($hexVal);
        $hexVal .= ' ' x ( 6 - $len );
        return $hexVal;
    };
    foreach my $colorNode (@colorNodeList) {
        my $val   = $colorNode->getAttribute('quantity');
        my $color = $colorNode->getAttribute('color');
        if ( $color =~ /^#/ ) {

            # Case of HTML hex colors
            my ( $red, $green, $blue ) = (
                $hexToPercentage->( substr( $color, 1, 2 ) ),
                $hexToPercentage->( substr( $color, 3, 2 ) ),
                $hexToPercentage->( substr( $color, 5, 2 ) ),
            );
            $colorTableStr .= "$val $red $green $blue\n";
        }
    }
    return $colorTableStr;
}

# Creates color legend
sub createColorLegend {
    my ( $self, %options ) = @_;

    # Set default options: type=number type, height/width=legend height/width
    my %defaultOptions = (
        type   => 'real',
        height => 400,
        width  => 75,
        units  => undef,
        scale  => undef
    );
    foreach my $key ( keys %defaultOptions ) {
        $options{$key} = $defaultOptions{$key} unless exists $options{$key};
    }

    # Need a file to write the color legend
    unless ( defined $options{file} ) {
        print STDERR "Output file not specified\n";
        return 0;
    }

    # By default, all SLDs have gutter values
    my $gutterColors = 1;

    # Create SVG
    my $parser = XML::LibXML->new();
    my $svgStr = <<SVG_ROOT;
    <svg width="$options{width}" height="$options{height}"
        xmlns="http://www.w3.org/2000/svg">
       <g />
    </svg>
SVG_ROOT
    my $svgDom = $parser->parse_string($svgStr);
    my $svgDoc = $svgDom->documentElement();
    my $gNode  = XML::LibXML::Element->new('g');
    $svgDoc->appendChild($gNode);

    # Get colors and corresponding labels
    my @colorList = $self->getColors();
    my @valueList = $self->getLabels();
    @valueList = map { $_ =~ /([-\w\.\+]+)/ ? $1 : undef } @valueList;

    # Label list: same length as colors
    my @labelTextList = map {undef} @valueList;
    my @labelSizeList = map { [ undef, undef ] } @valueList;

    # Index of start and stop color
    my ( $startIndex, $endIndex )
        = $gutterColors ? ( 1, @colorList - 2 ) : ( 0, @colorList - 1 );
    my $numColors         = $endIndex - $startIndex + 1;
    my $maxEndLabelHeight = 0;
    my $maxEndLabelWidth  = 0;
    my $maxNLabel         = "";
    foreach my $index ( 0, -1 ) {
        next unless defined $valueList[$index];
        $labelTextList[$startIndex] = $valueList[$index];
        $labelSizeList[$startIndex]
            = [ Giovanni::Util::getLabelSize( $valueList[$index] ) ];
        $maxEndLabelHeight = $labelSizeList[$startIndex][1]
            if ( $labelSizeList[$startIndex][1] > $maxEndLabelHeight );
        if ( $labelSizeList[$startIndex][0] > $maxEndLabelWidth ) {
            $maxEndLabelWidth = $labelSizeList[$startIndex][0];
            $maxNLabel        = $labelTextList[$startIndex];
        }
    }

    # xOff: X offset
    # yOff: Y offset for the color bar (excluding edge colors)
    #       Y offset should be large enough to fit the start/end color labels
    my $xOff = 5;
    my $yOff = ( .1 * $options{height} > 25 ) ? 25 : .1 * $options{height};
    $yOff = $maxEndLabelHeight / 2 + 5
        if ( $yOff < ( $maxEndLabelHeight / 2 + 5 ) );
    my $barWidth = $options{width} - $xOff - $maxEndLabelWidth;

    # Maximum bar width
    $barWidth = .23 * $options{width}
        if ( $barWidth > .19 * $options{width} );

    # Minimum bar width
    $barWidth = $barWidth < 10 ? 10 : $barWidth;
    my $barHeight  = $options{height} - 2 * $yOff;
    my $cellHeight = $barHeight * 1.0 / $numColors;

    # 5 is tick and space
    my $labelWidth = $options{width} - $barWidth - $xOff - 5;
    my $labelFontSize
        = Giovanni::Util::getFontSize( $labelWidth, $maxNLabel );

    # Creates SVG polygon given vertices and options (mostly for styling)
    my $createLine = sub {
        my ( $x1, $x2, $y1, $y2, %options ) = @_;
        my $node = XML::LibXML::Element->new('line');
        $node->setAttribute( 'x1', $x1 );
        $node->setAttribute( 'x2', $x2 );
        $node->setAttribute( 'y1', $y1 );
        $node->setAttribute( 'y2', $y2 );
        my $style = '';
        foreach my $key ( keys %options ) {
            $style .= "$key:$options{$key};" if exists $options{$key};
        }
        $node->setAttribute( 'style', $style );
        return $node;
    };

    # Creates SVG polygon given vertices and options (mostly for styling)
    my $createPolygon = sub {
        my ( $points, %options ) = @_;
        my $node = XML::LibXML::Element->new('polygon');
        $node->setAttribute( 'points', join( ",", @$points ) );
        my $style = '';
        foreach my $key ( keys %options ) {
            $style .= "$key:$options{$key};" if exists $options{$key};
        }
        $node->setAttribute( 'style', $style );
        return $node;
    };

    # Creates gutter legends; two triangles at the edges of color legend
    my $createGutterLegends = sub {
        my ( $gNode, $startColor, $endColor, $xOff, $yOff, $barWidth,
            $barHeight )
            = @_;
        my $gap    = 3;              # Gap between gutter legend and color bar
        my $height = $yOff - $gap;
        my $gutterHeight = $yOff - $gap;

        # Restrict the gutter legend height to 25px
        $gutterHeight = 25 if $gutterHeight > 25;
        my @points = (
            $xOff, $gutterHeight, $xOff + $barWidth,
            $gutterHeight, $xOff + $barWidth / 2, 0
        );
        my %options
            = ( fill => $endColor, stroke => 'black', 'stroke-width' => 1 );
        $gNode->appendChild( $createPolygon->( \@points, %options ) );
        $options{fill} = $startColor;
        @points = (
            $xOff,
            $yOff + $barHeight + $gap,
            $xOff + $barWidth,
            $yOff + $barHeight + $gap,
            $xOff + $barWidth / 2,
            $yOff + $barHeight + $gap + $gutterHeight
        );
        $gNode->appendChild( $createPolygon->( \@points, %options ) );
    };

    # Create the color bar itself
    my $createColorBar = sub {
        my ( $gNode, $colorList, $xOff, $yOff, $barWidth, $barHeight,
            $cellHeight )
            = @_;
        my $i = 0;
        foreach my $color ( reverse @$colorList ) {
            my $x1      = $xOff;
            my $x2      = $x1 + $barWidth;
            my $y1      = $yOff + $i * $cellHeight - .5;
            my $y2      = $yOff + ( $i + 1 ) * $cellHeight + .5;
            my @points  = ( $x1, $y1, $x2, $y1, $x2, $y2, $x1, $y2 );
            my %options = ( fill => $color );
            $gNode->appendChild( $createPolygon->( \@points, %options ) );
            $i++;
        }
        my @points = (
            $xOff, $yOff, $xOff + $barWidth,
            $yOff,
            $xOff + $barWidth,
            $yOff + $barHeight,
            $xOff, $yOff + $barHeight
        );
        $gNode->appendChild(
            $createPolygon->(
                \@points,
                ( fill => 'none', stroke => 'black', 'stroke-width' => 1 )
            )
        );
    };

    my $createText = sub {
        my ( $label, $x, $y, %options ) = @_;
        $options{qq(font-size)} = 14 unless exists $options{qq(font-size)};

        #$options{qq(font-size)} = 10 if length($label) >= 7;
        $options{qq(font-family)} = 'Helvetica'
            unless exists $options{qq(font-family)};
        my $textNode = XML::LibXML::Element->new('text');
        $textNode->setAttribute( 'x',           $x );
        $textNode->setAttribute( 'y',           $y );
        $textNode->setAttribute( 'fill',        'black' );
        $textNode->setAttribute( 'font-size',   $options{qq(font-size)} );
        $textNode->setAttribute( 'font-family', $options{qq(font-family)} );
        $textNode->appendText($label);
        return $textNode;
    };

    # Create text legends
    my $createTextLegends = sub {
        my ( $gNode, $labelList, $xOff, $yOff, $barWidth, $barHeight,
            $cellHeight, $fontSize )
            = @_;
        my $tickLen = 2;
        my $y0      = $yOff + $barHeight;
        my $x       = $xOff + $barWidth;
        for ( my $i = 0; $i < @$labelList; $i++ ) {
            my $label = $labelList->[$i];
            next if ( qq($label) eq '' );
            my $y = $y0 - $i * $cellHeight;
            $gNode->appendChild(
                $createLine->(
                    $x,
                    $x + $tickLen,
                    $y, $y,
                    (   fill           => 'none',
                        stroke         => 'black',
                        'stroke-width' => 1
                    )
                )
            );
            $gNode->appendChild(
                $createText->(
                    $label, $x + $tickLen + 3,
                    $y, ( 'font-size' => $fontSize )
                )
            );
        }
    };

    if ($gutterColors) {
        $createGutterLegends->(
            $gNode, $colorList[0], $colorList[-1], $xOff, $yOff, $barWidth,
            $barHeight
        );
    }
    $createColorBar->(
        $gNode, [ @colorList[ $startIndex .. $endIndex ] ],
        $xOff, $yOff, $barWidth, $barHeight, $cellHeight
    );
    $createTextLegends->(
        $gNode, [@valueList], $xOff, $yOff, $barWidth, $barHeight,
        $cellHeight, $labelFontSize
    );
    if (   defined $options{scale}
        && $options{scale} > 0
        && $options{scale} != 1 )
    {
        my $exp = log( $options{scale} ) / log(10);
        my $scaleLabel
            = sprintf( "x%.3ge%g", $options{scale} / 10**floor($exp), $exp );
        $gNode->appendChild(
            $createText->(
                $scaleLabel,
                $xOff + $barWidth,
                $yOff * 2 + $barHeight - 1
            )
        );
    }

    # Write SVG file
    my $fh = File::Temp->new( SUFFIX => '.svg' );
    print $fh $svgDoc->toString(2);
    close($fh);

    my $pngFile = $options{file};
    $pngFile = ( $pngFile =~ /(.+)/ ? $1 : undef );

    # Convert SVG to PNG
    `convert $fh $pngFile`;
    if ($?) {
        print STDERR "Failed to convert from SVG to PNG ($!)\n";
        return 0;
    }
    return 1;
}

# Modifies color map based on supplied min/max
sub modifyColorMap() {
    my ( $self, %input, $name ) = @_;
    ($name) = keys %{ $self->{layers} } unless defined $name;
    my $min       = $input{MIN};
    my $max       = $input{MAX};
    my $scaleType = $input{SCALETYPE};    # 'log' or 'linear'

    if ( !defined($scaleType) ) {
        $scaleType = 'linear';
    }

    # Get the number of color map entries
    my @colors = $self->getColors($name);

    my $len = scalar(@colors);
    return () unless $len > 3;

    my @thresholds = _calculateThresholds(
        MIN       => $min,
        MAX       => $max,
        SCALETYPE => $scaleType,
        NCLASS    => $len - 2
    );

    $self->setThresholds( \@thresholds, $name );

    return 1;
}

sub invertPalette {
    my ( $self, $name ) = @_;

    ($name) = keys %{ $self->{layers} } unless defined $name;
    if ( exists $self->{layers}{$name}{colors} ) {
        $self->{layers}{$name}{colors}
            = [ reverse( @{ $self->{layers}{$name}{colors} } ) ];
        return 1;
    }
    return 0;
}

# This function converts all the thresholds to use at most nDigit digits. To
# accomplish this, thresholds will be rounded (if necessary) to a maximum of
# nDigit digits and we will use scientific notation [mantissa x 10^exponent] if
# necessary.
#
# The code will first see if we can pick a single exponent for all the
# thresholds. E.g. - thresholds [0.0000001, 0.0000002, 0.0000023] becomes
# [1, 2, 23] x 10^-6.
# If this won't work because it would require too many digits, each threshold
# will have its own exponent. E.g. - thresholds [0.00001 5000000] becomes
# [1 x 10^-5, 5 x 10^6 ].
#
# In order to make sure that all the data stays within the range of the lowest
# and highest threshold, the upper threshold will be rounded up
# (E.g. - 1.2345678 becomes 1.235 for nDigit=4) and the lower threshold will be
# rounded down (E.g. - 1.2345678 becomes 1.234 for nDigit=4). Other thresholds
# will be rounded to the closest nDigit representation.
sub _convertToFiniteRepresentation {
    my (%params)   = @_;
    my $thresholds = $params{THRESHOLDS};
    my $nDigit     = $params{NDIGIT};

    my $numThresholds = scalar( @{$thresholds} );

    # Figure out if we need to have one exponent per threshold or if we can
    # get away with one exponent for all the thresholds.
    my $needsIndividualExponents;
    my $singleExponent;
    if ( $thresholds->[0] == 0 || $thresholds->[-1] == 0 ) {

        # Clearly, if one of the end thresholds is 0, we can set the exponent
        # to fit the non-zero end.
        $needsIndividualExponents = 0;
        if ( $thresholds->[0] != 0 ) {
            $singleExponent = _getBestExponent(
                NUMBER => $thresholds->[0],
                NDIGIT => $nDigit
            );
        }
        elsif ( $thresholds->[-1] != 0 ) {
            $singleExponent = _getBestExponent(
                NUMBER => $thresholds->[-1],
                NDIGIT => $nDigit
            );
        }
        else {

            # Why are the top and bottom thresholds both 0????
            $singleExponent = 0;
        }
    }
    else {

        # Calculate how many digits we'd need to express both the min and the
        # max value's most significant digits using a single power/exponent.
        # E.g - if the max is 1234.0 and the min is 0.05, we could express
        # them as 123400 x 10^-2 and 5 x 10^-2 if we can use 6 digits for the
        # matissas. See where the most significant digit is for the min and
        # max.
        my $exponentForMax  = _findMostSigFig( $thresholds->[-1] );
        my $exponentForMin  = _findMostSigFig( $thresholds->[0] );
        my $numDigitsNeeded = $exponentForMax - $exponentForMin + 1;
        $needsIndividualExponents = ( $numDigitsNeeded > $nDigit );

        if ( !$needsIndividualExponents ) {
            $singleExponent = $exponentForMin;
        }
    }

    # Calculate the mantissas and exponents
    my @mantissas;
    my @exponents = ();
    for ( my $i = 0; $i < $numThresholds; $i++ ) {
        my $round;
        if ( $i == 0 ) {

            # round the first mantissa down
            $round = 'floor';
        }
        elsif ( $i == ( scalar( @{$thresholds} ) - 1 ) ) {

            # round the top mantissa up
            $round = 'ceil';
        }
        else {

            # round all the other mantissas to the nearest value
            $round = 'nearest';
        }

        my $exponent
            = $needsIndividualExponents
            ? _getBestExponent(
            NUMBER => $thresholds->[$i],
            NDIGIT => $nDigit
            )
            : $singleExponent;
        push( @exponents, $exponent );

        $mantissas[$i] = _getMantissa(
            NUMBER   => $thresholds->[$i],
            NDIGIT   => $nDigit,
            EXPONENT => $exponent,
            ROUND    => $round,
        );
    }

    if ($needsIndividualExponents) {
        return ( \@mantissas, \@exponents );
    }
    else {

        # the exponents are all the same, so just return one
        return ( \@mantissas, [$singleExponent] );
    }
}

# Get the best exponent for a number.
sub _getBestExponent {
    my (%params) = @_;
    my $num      = $params{NUMBER};
    my $nDigit   = $params{NDIGIT};
    if ( $num == 0 ) {
        return 0;
    }

    my $mostSigFig = _findMostSigFig($num);
    if ( $mostSigFig > 0 && $mostSigFig < $nDigit ) {
        return 0;
    }
    else {
        return $mostSigFig;
    }
}

# Figure out the mantissa for a number given the exponent, the number of digits
# to use, and the kind of rounding we are trying to do.
sub _getMantissa {
    my (%params) = @_;

    # $num, $exponent, $nDigit, $typeOfRounding ) =
    my $num            = $params{NUMBER};
    my $nDigit         = $params{NDIGIT};
    my $exponent       = $params{EXPONENT};
    my $typeOfRounding = $params{ROUND};

    # nothing to do...
    if ( $num == 0 ) {
        return "0";
    }

    # Take out the exponent. E.g. - 1234 becomes 12.34 if $exponent is 2
    my $mantissa = $num / 10**$exponent;

    my $locationOfMostSigFig = _findMostSigFig($mantissa);

    if ( $locationOfMostSigFig < $nDigit ) {

        # We can represent this number in the given number of digits.

        # Figure out where we need to round off. E.g. - if $mantissa is
        # 12.34 and $nDigit is 3, we need to round to the closest 10th.
        my $locationOfLeastSigFig = $locationOfMostSigFig - $nDigit + 1;

      # But we won't want the rounding location to be less than 1-$nDigit. E.g
      # - if $mantissa is 0.0123 and $nDigit is 3, we need to round to the
      # closest one-hundredth place to get 0.01.
        if ( $locationOfLeastSigFig < 1 - $nDigit ) {
            $locationOfLeastSigFig = 1 - $nDigit;
        }

        # Round to this least significant digit so we will print the right
        # thing.
        $mantissa = _round(
            $mantissa,
            POSITION => $locationOfLeastSigFig,
            TYPE     => $typeOfRounding,
        );
    }
    else {

        # ( $locationOfMostSigFig >= $nDigit )

        # Suppose we have a large number, like 123456. If $exponent is 1 and
        # $nDigit is 4, the largest numbers we can represent will be in the
        # thousandths place. E.g. - 9999. There is nothing reasonable we can
        # do in this case, so we'll put up a warning and return an obviously
        # wrong string. NOTE: this case should never happen if we calculate a
        # reasonable exponent.
        warn(
            "Unable to represent a mantissa for $num with exponent $exponent and $nDigit digits."
        );
        return "X" x $nDigit;
    }

    # print the mantissa to the correct number of digits
    my $printSpec = "%.$nDigit" . "g";
    return sprintf( $printSpec, $mantissa );

}

# Calculate where the most significant digit is for a number. This is the power
# of 10. E.g. - the most significant digit for the number 1234 is the thousands
# place, which is 10^3. So this function would return 3.
sub _findMostSigFig {
    my ($num) = @_;
    my $log10 = _log10( abs($num) );

   # Ideally, we would just say $power = floor($log10). Unfortunately, perl
   # seems to have some floating point issues. E.g. - floor(log(1000)/log(10))
   # is 2, not 3. Go figure. This is a work around.
    if ( abs( _round($log10) - $log10 ) < 1e-14 ) {

        # The rounded value of $log10 is very very close to the actual value,
        # so just use the rounded value to avoid floating point problems.
        return _round($log10);
    }
    else {
        return floor($log10);
    }

}

# Calculates the log base 10 of a number.
sub _log10 {
    my ($num) = @_;
    return log($num) / log(10);
}

# Round a number to a certain position.
#
#      my $ret = _round(1234.56,position=>2,type=>'nearest');
#      print $ret; # prints 1200
#
# position - the 10s position we are rounding to. E.g. - 2 (10^2) rounds to the
#   hundreds position. Defaults to 0.
#
# type - the type of rounding to do. Valid inputs are 'nearest', 'ceil', and
#   'floor'. Defaults to 'nearest'.
sub _round {
    my ( $num, %params ) = @_;
    my $type;
    if ( !defined( $params{TYPE} ) ) {
        $type = 'nearest';
    }
    else {
        $type = $params{TYPE};
    }
    my $position;
    if ( !defined( $params{POSITION} ) ) {

        # round to the integer position
        $position = 0;
    }
    else {
        $position = $params{POSITION};
    }

    # move the number by the number of positions
    my $moved = $num / ( 10**$position );

    my $rounded;
    if ( $type eq 'nearest' ) {
        if ( $moved > 0 ) {
            $rounded = int( $moved + 0.5 );
        }
        else {
            $rounded = int( $moved - 0.5 );
        }
    }
    elsif ( $type eq 'ceil' ) {
        $rounded = ceil($moved);

    }
    elsif ( $type eq 'floor' ) {
        $rounded = floor($moved);
    }

    # move back
    return $rounded * ( 10**$position );
}

# Calculate what the thresholds should be given the min (lowest threshold),
# max (highest threshold), and type of scale. If scaleType is linear, the
# increment between thresholds will be fixed. E.g. - (1,1.5,2,2.5,3). If the
# scaleType is log, the increment between thresholds be fixed in the log based
# 10 domain. E.g. - (1, 10, 100, 1000).
#
#
# MIN - lowest threshold
# MAX - highest threshold
# SCALETYPE - 'log' or 'linear'
# NCLASS - number of classes. 1 less than the number of expected thresholds.
sub _calculateThresholds {
    my (%params)  = @_;
    my $min       = $params{MIN};
    my $max       = $params{MAX};
    my $scaleType = $params{SCALETYPE};
    my $nClass    = $params{NCLASS};

    # calculate the thresholds
    my @thresholds = ();
    if ( $scaleType eq 'linear' ) {

        # 'linear' thresholds
        my $increment = ( $max - $min ) / $nClass;
        for ( my $i = 0; $i <= $nClass; $i++ ) {
            $thresholds[$i] = $min + $i * $increment;
        }
    }
    elsif ( $scaleType eq 'log' ) {

        # 'log' thresholds
        my $logMin    = log($min) / log(10);
        my $logMax    = log($max) / log(10);
        my $increment = ( $logMax - $logMin ) / $nClass;
        for ( my $i = 0; $i <= $nClass; $i++ ) {
            my $logThreshold = $logMin + $i * $increment;
            $thresholds[$i] = 10**$logThreshold;
        }
    }
    else {
        die "Unrecognized scale type $scaleType.";
    }

    return @thresholds;
}

1;
__END__

=head1 NAME

Giovanni::OGC::SLD - Perl extension for getting information about a SLD and also modify its color map

=head1 SYNOPSIS

  use Giovanni::OGC::SLD;

  $sld = new Giovanni::OGC::SLD(FILE => $pathname);
  $sld = new Giovanni::OGC::SLD(URL => $sld_url);
  $sld = new Giovanni::OGC::SLD(STRING => $s);

  @colors = $sld->getColors([$layer]);

  @thresholds = $sld->getThresholds([$layer]);

  @settings = $sld->getGrADSColorSettings([$layer]);

=head1 DESCRIPTION

Provides information about the SLD's color map and data range. Allows to modify the color map entries
based on a linear scale provided a MIN and MAX value. 

It also provides transformations for various graphics programs, such as GrADS.

=head2 EXPORT

None by default.

=head1 AUTHOR

Mahabaleshwara S. Hegde, E<lt>mhegde@localdomainE<gt>

=cut
