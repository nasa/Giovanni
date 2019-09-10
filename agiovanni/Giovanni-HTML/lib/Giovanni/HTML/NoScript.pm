#!/usr/bin/perl
package Giovanni::HTML::NoScript;

use XML::LibXML;
use XML::LibXSLT;
use XML::Simple;
use LWP::UserAgent;
use Giovanni::Catalog;
use Time::Local;
use DateTime;
use Date::Manip;
use JSON;
use File::Basename;
use File::Temp qw/ tempdir tempfile /;
use strict;

my $SubDir = "noscript";
my $ua     = LWP::UserAgent->new();
$ua->env_proxy;

my $PlotSelXSLT     = "NoScriptPlotSel.xsl";
my $ConstraintsXSLT = "Plot.xsl";
my $VarSelXSLT      = "NoScriptVarSel.xsl";
my $Var2SelXSLT     = "NoScriptVar2Sel.xsl";
my $PresentOptionXSLT  = "NoScriptOption.xsl";
my $VerticalOptionXSLT = "VerticalOption.xsl";

my $template    = "../../giovanni/noscriptTemplate.html";
my $servicesXml = "cfg/giovanni_services.xml";
my $XSLTPATH    = "www/xsl/";
our $VERSION = '0.01';

sub new {
    my ( $pkg, %params ) = @_;
    my $self         = bless \%params, $pkg;
    my $xs           = new XML::Simple();
    my $services_xml = $self->{path} . $servicesXml;
    print STDERR 'URL' . $ENV{SCRIPT_URI};

    $self->{services} = $xs->XMLin($services_xml);

    my @Links;

    foreach my $key ( keys %{ $self->{services}{service} } ) {
        my $link = $key;
        $link =~ s/ //g;
        push @Links, Giovanni::Util::createAbsUrl( $link . ".html" )
    }
    $self->{Links} = \@Links;
    $self->{Plots} = \%{ $self->{services}{service} };

    $self->{services} = $xs->XMLin($services_xml);
    my $catalog
        = Giovanni::Catalog->new( { URL => $GIOVANNI::DATA_CATALOG } );
    my $fieldHash = $catalog->getActiveDataFields();
    $self->{datafields} = $fieldHash;

    return $self;
}

sub getLabel {
    my $self     = shift;
    my $variable = shift;
    my $temp     = stripVarForRef($variable);
    my $text
        = $self->{datafields}{$temp}{long_name} . " "
        . $self->{datafields}{$temp}{dataProductShortName} . " " . "v"
        . $self->{datafields}{$temp}{dataProductVersion};
    return $text;
}

sub stripVarForRef {
    my $variable = shift;
    my $temp     = $variable;
    if ( $variable =~ /\(z=/ ) {
        my ( $stripped, $level ) = split( /\(z=/, $variable, 2 );
        $temp = $stripped;
    }
    return $temp;
}

# Step 1: Present the user with a list of variables.
sub CreateSelectVarPage {
    my $self          = shift;
    my $button_string = shift;

    $VarSelXSLT = $self->{path} . "$XSLTPATH" . $VarSelXSLT;

    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);

    my $doc = XML::LibXML::Document->createDocument( '1.0', 'UTF-8' );
    my $root = XML::LibXML::Element->new("root");
    $root->setAttribute( 'message',
        'Specify Space and Time Constraints. Select Variables.' );
    $root->setAttribute( 'buttonval', $button_string );
    $doc->setDocumentElement($root);
    my $PlotHeading = XML::LibXML::Element->new("PlotName");
    $root->appendChild($PlotHeading);
    my $serviceID = XML::LibXML::Element->new("PlotID");
    $root->appendChild($serviceID);


    foreach my $variable ( sort keys %{ $self->{datafields} } ) {
        if ( isit3D( $self, $variable ) ) {
            my $var = XML::LibXML::Element->new("D3Variable");
            my $text = getLabel( $self, $variable );
            $var->appendText($text);
            $var->setAttribute( "dataFieldName", $variable );
            $root->appendChild($var);
        }
        else {
            my $var = XML::LibXML::Element->new("Variable");
            my $text = getLabel( $self, $variable );
            $var->appendText($text);
            $var->setAttribute( "dataFieldName", $variable );
            $root->appendChild($var);
        }

    }

    my $Page = $self->DoTransform( $doc, $template, $VarSelXSLT );

}

# Step 2: Present the user with the option of either going straight to a single var
#         plot or choosing a second variable
sub PresentVarOptionPage {
    my $self            = shift;
    my $button_1_string = shift;
    my $button_2_string = shift;
    my $variable        = shift;

    $VarSelXSLT = $self->{path} . "$XSLTPATH" . $PresentOptionXSLT;

    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);

    my $doc = XML::LibXML::Document->createDocument( '1.0', 'UTF-8' );
    my $root = XML::LibXML::Element->new("root");
    $root->setAttribute( 'message',
        'Specify Space and Time Constraints. Select Variables.' );
    $root->setAttribute( 'buttonvalanother', $button_1_string );
    $root->setAttribute( 'buttonvaldoplot',  $button_2_string );
    $root->setAttribute( 'variable1',        $variable );
    $root->setAttribute( 'display1',         getLabel( $self, $variable ) );
    $doc->setDocumentElement($root);

    my $service = XML::LibXML::Element->new("Variable");
    $service->appendText($variable);
    $root->appendChild($service);

    my $Page = $self->DoTransform( $doc, $template, $VarSelXSLT );

}

# Step 3A The user has chose to select a single var plot, so show them
sub SelectSingleVarPlotPage {
    my $self        = shift;
    my $buttontitle = shift;
    my $variable    = shift;
    my $xmlParser   = XML::LibXML->new();
    $xmlParser->keep_blanks(0);

    my $doc = XML::LibXML::Document->createDocument( '1.0', 'UTF-8' );
    my $root = XML::LibXML::Element->new("root");
    $doc->setDocumentElement($root);
    my $serv = XML::LibXML::Element->new("Services");
    $root->setAttribute( 'display1', getLabel( $self, $variable ) );
    if ( $self->{variable}{name}{$variable}{level} )
    {    # a special hash only for 3D
        $variable
            .= "(z="
            . $self->{variable}{name}{$variable}{level}
            . ")";    # : -> (z=) for z-layers
    }
    $root->setAttribute( 'variable1', $variable );
    $root->appendChild($serv);
    foreach my $plot ( sort keys %{ $self->{services}{service} } ) {
        next if NoNoScriptPlotIsAvailable( $self, $plot, $variable );
        my $plot_info = get_catalog_info( $self, $plot );
        my $minimum_variables_needed
            = $plot_info->{constraint}{min_datafield_count};

        my $link
            = Giovanni::Util::createAbsUrl( $ENV{SCRIPT_NAME}
                . "?plot=$plot&variable1=$variable" );

        if ( $self->{datafields}{$variable}{zDimUnits}
            and !$self->{variable}{name}{$variable}{level} )
        {    # a special hash only for 3D
            if ( $plot eq "VtPf" ) {
                my $service = XML::LibXML::Element->new("Plot");
                $service->appendText($plot);
                $service->setAttribute( 'href', $link );
                $service->setAttribute( 'info', "../" .
                        $self->{services}{service}{$plot}{helplink} );
                $service->setAttribute( 'desc',
                    $self->{services}{service}{$plot}{description} );
                $service->setAttribute( 'label',
                    $self->{services}{service}{$plot}{label} );
                $serv->appendChild($service);
            }
        }
        elsif ( $minimum_variables_needed < 2 ) {
            my $service = XML::LibXML::Element->new("Plot");
            $service->appendText($plot);
            $service->setAttribute( 'href', $link );
            $service->setAttribute( 'info', "../" .
                    $self->{services}{service}{$plot}{helplink} );
            $service->setAttribute( 'desc',
                $self->{services}{service}{$plot}{description} );
            $service->setAttribute( 'label',
                $self->{services}{service}{$plot}{label} );
            $serv->appendChild($service);
        }
    }

    $PlotSelXSLT = $self->{path} . "$XSLTPATH" . $PlotSelXSLT;
    $self->DoTransform( $doc, $template, $PlotSelXSLT );
}

sub get_catalog_info {
    my $self = shift;
    my $plot = shift;
    my $plot_info;
    my $prefix;
    my $address = Giovanni::Util::createAbsUrl( "daac-bin/catalogServices.pl?service=" . $plot );

    my $response = $ua->get($address);
    if ( $response->is_success() ) {
        my $json = $response->content;
        $plot_info = decode_json $json;
    }
    else {
        Giovanni::Util::exit_with_error( $response->code() );
    }
    return $plot_info;
}

# Step 3B: The user wants to choose a second variable
sub CreateSelectSecondVarPage {
    my $self              = shift;
    my $button_string     = shift;
    my $previous_variable = shift;

    my $XSLT = $self->{path} . "$XSLTPATH" . $Var2SelXSLT;

    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);

    my $doc = XML::LibXML::Document->createDocument( '1.0', 'UTF-8' );
    my $root = XML::LibXML::Element->new("root");
    $root->setAttribute( 'message',
        'Specify Space and Time Constraints. Select Variables.' );
    $root->setAttribute( 'buttonval', $button_string );
    $root->setAttribute( 'previous_display',
        getLabel( $self, $previous_variable ) );
    if ( $self->{variable}{name}{$previous_variable}{level} )
    {    # a special hash only for 3D
        $root->setAttribute( 'previous_variable',
            $previous_variable . "(z="
                . $self->{variable}{name}{$previous_variable}{level}
                . ")" );
    }
    else {
        $root->setAttribute( 'previous_variable', $previous_variable );
    }
    $doc->setDocumentElement($root);
    my $PlotHeading = XML::LibXML::Element->new("PlotName");
    $root->appendChild($PlotHeading);
    my $serviceID = XML::LibXML::Element->new("PlotID");
    $root->appendChild($serviceID);

    foreach my $variable ( sort keys %{ $self->{datafields} } ) {
        if ( isit3D( $self, $variable ) ) {
            my $var = XML::LibXML::Element->new("D3Variable");
            my $text = getLabel( $self, $variable );
            $var->appendText($text);
            $var->setAttribute( "dataFieldName", $variable );
            $root->appendChild($var);
        }
        else {
            my $var = XML::LibXML::Element->new("Variable");
            my $text = getLabel( $self, $variable );
            $var->appendText($text);
            $var->setAttribute( "dataFieldName", $variable );
            $root->appendChild($var);
        }
    }

    my $Page = $self->DoTransform( $doc, $template, $XSLT );

}

# Step 4: Show the user the available 2 variable plots
sub SelectComparisonPlotPage {
    my $self        = shift;
    my $buttontitle = shift;
    my $variable    = shift;
    my $variable2   = shift;

    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);

    my $doc = XML::LibXML::Document->createDocument( '1.0', 'UTF-8' );
    my $root = XML::LibXML::Element->new("root");
    $doc->setDocumentElement($root);
    my $serv = XML::LibXML::Element->new("Services");
    $root->setAttribute( 'variable1', $variable );
    $root->setAttribute( 'display1', getLabel( $self, $variable ) );
    if ( length $variable2 > 1 ) {
        $root->setAttribute( 'display2', getLabel( $self, $variable2 ) );
        if ( $self->{variable}{name}{$variable2}{level} )
        {    # a special hash only for 3D
            $variable2
                .= "(z=" . $self->{variable}{name}{$variable2}{level} . ")";
        }
        $root->setAttribute( 'variable2', $variable2 );
    }
    $root->setAttribute( 'button', $buttontitle );
    $root->appendChild($serv);
    foreach my $plot ( sort keys %{ $self->{services}{service} } ) {
        next if NoNoScriptPlotIsAvailable( $self, $plot, $variable );
        my $name = $plot;
        $name =~ s/ //g;
        my $link
            = Giovanni::Util::createAbsUrl( $ENV{SCRIPT_NAME}
                . "?plot=$plot&variable1=$variable&variable2=$variable2" );
        my $plot_info = get_catalog_info( $self, $plot );
        my $minimum_variables_needed
            = $plot_info->{constraint}{min_datafield_count};
        if ( $minimum_variables_needed >= 2 ) {
            my $service = XML::LibXML::Element->new("Plot");
            $service->appendText($plot);
            $service->setAttribute( 'href', $link );
            $service->setAttribute( 'info', "../" .
                    $self->{services}{service}{$plot}{helplink} );
            $service->setAttribute( 'desc',
                $self->{services}{service}{$plot}{description} );
            $service->setAttribute( 'label',
                $self->{services}{service}{$plot}{label} );
            $serv->appendChild($service);
        }
    }

    $PlotSelXSLT = $self->{path} . "$XSLTPATH" . $PlotSelXSLT;
    $self->DoTransform( $doc, $template, $PlotSelXSLT );
}

# Step 5. Show particular items about the plot and ask for time and space constraints.
# Provide button to finally start the plot
sub CreatePlotConstraintPage {
    my $self        = shift;
    my $buttontitle = shift;
    my $plot        = shift;
    my $variable    = shift;
    my $variable2   = shift;
    my $xmlParser   = XML::LibXML->new();
    $xmlParser->keep_blanks(0);

    my $doc = XML::LibXML::Document->createDocument( '1.0', 'UTF-8' );
    my $root = XML::LibXML::Element->new("root");
    $doc->setDocumentElement($root);
    my $serv = XML::LibXML::Element->new("Services");
    $root->setAttribute( 'variable1', $variable );
    $root->setAttribute( 'display1', getLabel( $self, $variable ) );
    $root->setAttribute( 'starttime1',
        $self->{datafields}{ stripVarForRef($variable) }{startTime} );
    $root->setAttribute(
        'endtime1',
        getProperEndTime(
            $self->{datafields}{ stripVarForRef($variable) }{endTime}
            )
    );
    $root->setAttribute( 'plot_description',
        $self->{services}{service}{$plot}{description} );

    if ( $self->{datafields}{ stripVarForRef($variable) }{zDimUnits}
        and $self->{services}{service}{$plot}{name} ne 'VtPf' )
    {
        $root->setAttribute( 'zDimUnits',
            $self->{datafields}{ stripVarForRef($variable) }{zDimUnits} );
    }

    my ( $strt, $end ) = getDefaultStartandEndTimes(
        $self,
        stripVarForRef($variable),
        stripVarForRef($variable2)
    );

    if ( length $variable2 > 1 ) {
        $root->setAttribute( 'variable2', $variable2 );
        $root->setAttribute( 'display2', getLabel( $self, $variable2 ) );
        $root->setAttribute( 'starttime2',
            $self->{datafields}{ stripVarForRef($variable2) }{startTime} );
        $root->setAttribute(
            'endtime2',
            getProperEndTime(
                $self->{datafields}{ stripVarForRef($variable2) }{endTime}
                )
        );
    }

    $root->setAttribute( 'defStart', $strt . "Z");
    $root->setAttribute( 'defEnd',   $end  . "Z");
    $root->setAttribute( 'service',  $plot );
    $root->appendChild($serv);

    # I don't think I need this:
    my $link
        = Giovanni::Util::createAbsUrl( $ENV{SCRIPT_NAME}
            . "?plot=$plot&variable1=$variable" );
    my $plot_info = get_catalog_info( $self, $plot );
    my $minimum_variables_needed
        = $plot_info->{constraint}{min_datafield_count};
    my $service = XML::LibXML::Element->new("Plot");
    $service->appendText($plot);
    $service->setAttribute( 'href', $link );
    $service->setAttribute( 'info', "../" .
            $self->{services}{service}{$plot}{helplink} );
    $service->setAttribute( 'desc',
        $self->{services}{service}{$plot}{description} );
    $serv->appendChild($service);

    $ConstraintsXSLT = $self->{path} . "$XSLTPATH" . $ConstraintsXSLT;
    $self->DoTransform( $doc, $template, $ConstraintsXSLT );
}

sub DoTransform {
    my $self             = shift;
    my $doc              = shift;
    my $templatelocation = $self->{scriptpath} . shift;
    my $styleFile        = shift;
    my $PAGE;
    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();

    my $styleDoc           = $parser->parse_file($styleFile);
    my $styleSheet         = $xslt->parse_stylesheet($styleDoc);
    my $resultsOfTransform = $styleSheet->transform($doc);
    $PAGE = $resultsOfTransform->toString(1);

    my $template;
    my $response = $ua->get($templatelocation);
    if ( $response->is_success() ) {
        $template = $response->content;
    }
    else {
        print STDERR "Could not do a ua->get() of $templatelocation\n";
        Giovanni::Util::exit_with_error( $response->code() );
    }
    print STDERR "Apparently I got: $templatelocation\n";

    # DisplayPage($self,$template,$PAGE);
    $self->{page}             = $PAGE;
    $self->{current_template} = $template;
}

sub DisplayPage {
    my $self     = shift;
    my $template = shift;
    my $PAGE     = shift;
    my $cgi      = shift;
    print $cgi->header();

    my @SHELLTEMPLATE = split( /\n/, $template );
    foreach (@SHELLTEMPLATE) {
        if ( $_ =~ /INSERT_HERE/ ) {
            print $PAGE;
        }
        else {
            print $_;
        }
        print "\n";
    }

}

# No longer referenced:
sub WritePage {
    my $self     = shift;
    my $template = shift;
    my $PAGE     = shift;
    my $location
        = "/home/rstrub/public_html/giovanni/"
        . $SubDir . "/"
        . $self->{PageName};

    if ( open( HOMEPAGE, "> $location" ) ) {
        my @SHELLTEMPLATE = split( /\n/, $template );
        foreach (@SHELLTEMPLATE) {
            if ( $_ =~ /INSERT_HERE/ ) {
                print HOMEPAGE $PAGE;
            }
            else {
                print HOMEPAGE $_;
            }
            print HOMEPAGE "\n";
        }
        close(HOMEPAGE);
        print STDOUT "$location created successfully!\n";

    }
    else {
        print STDERR "Could not write to $location\n";
        exit(1);
    }
}

sub isit3D {
    my $self     = shift;
    my $variable = shift;
    if ( $self->{datafields}{$variable}{zDimUnits} ) {
        return 1;
    }
    return undef;
}

sub PresentZLevelSelectionPage {
    my $self            = shift;
    my $variable1       = shift;
    my $variable2       = shift;
    my $button_1_string = shift;
    my $button_2_string = shift;
    my $button_3_string = shift;

    $VerticalOptionXSLT = $self->{path} . "$XSLTPATH" . $VerticalOptionXSLT;

    my $xmlParser = XML::LibXML->new();
    $xmlParser->keep_blanks(0);

    my $doc = XML::LibXML::Document->createDocument( '1.0', 'UTF-8' );
    my $root = XML::LibXML::Element->new("root");
    $root->setAttribute( 'buttonvalanother',         $button_1_string );
    $root->setAttribute( 'buttonvaldoplot',          $button_2_string );
    $root->setAttribute( 'buttonvaldosinglevarplot', $button_3_string );
    $root->setAttribute( 'variable1',                $variable1 );
    $root->setAttribute( 'display1', getLabel( $self, $variable1 ) );
    my $service = XML::LibXML::Element->new("Variable");
    $service->appendText($variable1);
    $root->appendChild($service);

    if ($variable1) {
        my $vertinfoNode = XML::LibXML::Element->new("ThreeD");
        $vertinfoNode->setAttribute( 'name',
            $self->{datafields}{$variable1}{zDimName} );
        $vertinfoNode->setAttribute( 'units',
            $self->{datafields}{$variable1}{zDimUnits} );
        $root->appendChild($vertinfoNode);
        my $values = $self->{datafields}{$variable1}{zDimValues};
        my @values = split( /\s+/, $values );
        foreach (@values) {
            my $node = XML::LibXML::Element->new("level");
            $node->appendText($_);
            $vertinfoNode->appendChild($node);
        }
    }
    if ($variable2) {
        $root->setAttribute( 'variable2', $variable2 );
        $root->setAttribute( 'display2', getLabel( $self, $variable2 ) );
        my $service2 = XML::LibXML::Element->new("Variable2");
        $service2->appendText($variable2);
        $root->appendChild($service2);
        $root->setAttribute( 'message',
            'Because you chose a 3D Variable as a second variable you MUST select one of the levels listed below'
        );
        my $vertinfoNode = XML::LibXML::Element->new("ThreeD");
        $vertinfoNode->setAttribute( 'name',
            $self->{datafields}{$variable2}{zDimName} );
        $vertinfoNode->setAttribute( 'units',
            $self->{datafields}{$variable2}{zDimUnits} );
        $root->appendChild($vertinfoNode);
        my $values = $self->{datafields}{$variable2}{zDimValues};
        my @values = split( /\s+/, $values );

        foreach (@values) {
            my $node = XML::LibXML::Element->new("level");
            $node->appendText($_);
            $vertinfoNode->appendChild($node);
        }
    }
    else {
        $root->setAttribute( 'message',
            'Because you chose a 3D Variable you can either:' );
    }
    $doc->setDocumentElement($root);

    my $Page = $self->DoTransform( $doc, $template, $VerticalOptionXSLT );

}

# Return today's date if end time is in future (2038)
sub getProperEndTime {
    my $etime = shift;
    my $epoch = string2epoch($etime);
    if ( $epoch > time() ) {
        return DateTime->from_epoch( epoch => time() );
    }
    return $etime;
}

# Fill the user's temporal constraints with latest
# data - 3 units or so...
sub getDefaultStartandEndTimes {
    my $self       = shift;
    my $var1       = shift;
    my $var2       = shift;
    my $backInTime = 3 * 1440 * 60;    # 3 days in min*60
    my $start_epoch;
    my $end_epoch;
    if ( $var1 =~ /:\d+/ ) {           # not needed after stripVarForRef
        $var1 =~ s/:\d+//;  # Do I need to change this for new z-layer syntax?
    }

    my $interval = $self->{datafields}{$var1}{dataProductTimeInterval};

    if ( $interval eq 'monthly' ) {
        $backInTime = 92 * 1440 * 60;    # 3  months in sec
    }
    elsif ( $interval eq 'daily' ) {
        $backInTime = 3 * 1440 * 60;     # 3  days in sec
    }
    elsif ( $interval eq 'hourly' ) {
        $backInTime = 3 * 60 * 60;       # 3  hours in sec
    }
    elsif ( $interval eq '3 hourly' ) {
        $backInTime = 3 * 1440 * 60;     # 3  days in sec
    }
    else {
        $backInTime = 3 * 1440 * 60;     # 3  days in sec
    }

    if ($var2) {
        if ( $var2 =~ /:\d+/ ) {
            $var2 =~ s/:\d+//
                ;    # Do I need to change this for new z-layer syntax?
        }
        my $var1end_epoch = string2epoch(
            $self->{datafields}{$var1}{dataProductEndDateTime} );
        my $var2end_epoch = string2epoch(
            $self->{datafields}{$var2}{dataProductEndDateTime} );
        $end_epoch
            = $var1end_epoch <= $var2end_epoch
            ? $var1end_epoch
            : $var2end_epoch;
    }
    else {
        $end_epoch = string2epoch(
            $self->{datafields}{$var1}{dataProductEndDateTime} );
    }

    # Some datasets have weird ending dates:
    if ( $end_epoch > time() ) {
        $end_epoch = time() - $backInTime;
    }

    my $start_epoch = $end_epoch - $backInTime;
    return (
        DateTime->from_epoch( epoch => $start_epoch ),
        DateTime->from_epoch( epoch => $end_epoch )
    );
}

sub string2epoch {
    my @s = split( /[\-: TZ]/, $_[0] );

    # Perl 5.8.8 timegm() does not handle early dates well.
    # (Keep the numbers positive just for safety.)
    # However, it is faster, so we want to use it most of the time
    # TODO:  take this if loop out when we get to 5.12 or higher
    if ( $s[0] >= 1970 ) {
        return timegm( $s[5], $s[4], $s[3], $s[2], $s[1] - 1, $s[0] );
    }
    else {
        return Date::Manip::Date_SecsSince1970GMT( $s[1], $s[2], $s[0], $s[3],
            $s[4], $s[5] );
    }
}

# This is a list services whose visualizations tested correctly:
# Why there are so few plot types:
# Single (2):
#   HOV_LON -> HOV_LON
#   HOV_LAT -> HOV_LAT
#   HISTOGRAM -> -- no plot type --
#   AREA_AVG_TIME_SERIES -> -- no plot type --
# Double: (1)
#   SCATTER_PLOT -> SCATTER_PLOT
#   AREA_AVG_DIFF_TIME_SERIES -> -- no plot type --
#   AREA_AVG_SCATTER -> -- no plot type --
# Special 3D Case:(1)
#   VERTICAL_PROFILE -> VERTICAL_PROFILE

# However, some of them didn't have a plot_type in any of the giovanni_services.xml that I could find on s4pt.

# These are a list of services whose visualizations failed:
# ACCUMULATE -> can't
# TIME_AVERAGED_SCATTER_PLOT -> INTERACTIVE_SCATTER_PLOT
# INTERACTIVE_SCATTER_PLOT -> INTERACTIVE_SCATTER_PLOT
# CORRELATION_MAP -> INTERACTIVE_MAP
# INTERACTIVE_MAP -> INTERACTIVE_MAP
# DIFF_TIME_AVG_MAP -> can't
# QUASI_CLIMATOLOGY -> INTERACTIVE_MAP
# MAP_ANIMATION -> MAP_ANIMATION
# INTERANNUAL_TIME_SERIES -> INTERACTIVE_TIME_SERIES
# INTERANNUAL_MAPS -> INTERACTIVE_MAP

#So a list of the plot types that I CAN DO:
#HOV_LON|VERTICAL_PROFILE|SCATTER_PLOT|HOV_LAT
#So a list of the plot types that I CANNOT DO:
#INTERACTIVE_SCATTER_PLOT|INTERACTIVE_MAP|MAP_ANIMATION|INTERACTIVE_TIME_SERIES
#Thankfully they are mutually exclusive...
# VERTICAL_PROFILE IS A SPECIAL CASE AND IS NOT HANDLED HERE
sub NoNoScriptPlotIsAvailable {
    my $self     = shift;
    my $plot     = shift;
    my $variable = shift;

    if ( $self->{services}{service}{$plot}{plot_type} eq "HOV_LON"
        or $self->{services}{service}{$plot}{plot_type} eq "HOV_LAT"
        or $self->{services}{service}{$plot}{plot_type} eq "HISTOGRAM"
        or $self->{services}{service}{$plot}{plot_type} eq "TIME_SERIES_GNU"
        or $self->{services}{service}{$plot}{plot_type} eq "TIME_SERIES"
        or $self->{services}{service}{$plot}{plot_type} eq
        "SCATTER_PLOT_GNU" )
    {
        return undef;
    }
    elsif (
        $self->{services}{service}{$plot}{plot_type} =~ 'VERTICAL_PROFILE' )
    {
        if ( $self->{datafields}{$variable}{zDimUnits}
            and !$self->{variable}{name}{$variable}{level} )
        {    # a special hash only for 3D
            return undef;
        }
        return 1;
    }
    elsif ( $self->{services}{service}{$plot}{plot_type}
        =~ /INTERACTIVE_SCATTER_PLOT|INTERACTIVE_MAP|MAP_ANIMATION|INTERACTIVE_TIME_SERIES/
        )
    {
        return 1;
    }
    else {
        print STDERR
            sprintf( "%s: does not have a plot_type assigned to it: <%s>\n",
            $plot, $self->{services}{service}{$plot}{plot_type} );
        return 1;
    }
}

sub formFullyQualifiedUrl {
    my (@urlList)     = @_;
    my (@fullUrlList) = ();
    foreach my $url (@urlList) {
        my $uri = Giovanni::Util::createAbsUrl( $ENV{SCRIPT_NAME} );
        my $str = $uri->as_string();
        $str =~ s/daac-bin//;
        push( @fullUrlList, $str );
    }
    return @fullUrlList;
}

__END__

=head1 NAME

Giovanni::HTML::NoScript- Creates the Non-Javascript pages for G4.

=head1 DESCRIPTION

 This module provides methods for to transform createNonJscript.pl's XML output into various static pages:
 A 'top' level plot selection page 
 A variable selection page for each type of plot.

Some of the methods:

    CreateSelectVarPage  - Step 1: Present the user with a list of variables.
    PresentVarOptionPage - plot or choosing a second variable
    SelectSingleVarPlotPage   - Step 3A The user has chose to select a single var plot, so show them
    CreateSelectSecondVarPage - Step 3B: The user wants to choose a second variable
    SelectComparisonPlotPage  - Step 4: Show the user the available 2 variable plots
    CreatePlotConstraintPage  - Provide button to finally start the plot
    DoTransform               - does the XSL transform, imports the template
    get_catalog_info          - queries AESIR

=head1 SYNOPSIS

use Giovanni::HTML::NoScript;

noscript.cgi  This is the endpoint client for  this module, a multipage Web application so there are no specific arguments or outputs


=head1 AUTHOR

Richard Strub, F E<lt>richard.f.strub@nasa.govE<gt>

=cut


