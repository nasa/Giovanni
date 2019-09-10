#!/usr/bin/perl -T

eval 'exec /usr/bin/perl -T -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

# But it can be run as a CGI script using list=google&keyword=all
# Author: Richard Strub
# $Id:

use vars qw($MODE);

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    if ( defined $rootPath ) {
        unshift( @INC, $rootPath . 'share/perl5/' );

        #foreach (@INC) { print $_,"\n"; }
    }
}

use Safe;
use CGI;
use XML::LibXML;
use XML::LibXSLT;
use Giovanni::HTML::NoScript;
use Giovanni::Util;
use Giovanni::CGI;
use strict;

# Read the configuration file
# This path must be absolute or config file won't be read
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';

my $error = Giovanni::Util::ingestGiovanniEnv( $cfgFile );
Giovanni::Util::exit_with_error($error) if (defined $error);

my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    ,
);


my $variable  = $cgi->param("variable"); 
my $variable  = $cgi->param("variable");
my $variable1 = $cgi->param("variable1");
my $variable2 = $cgi->param("variable2"); 
my $dataset   = $cgi->param("dataset");
my $versionid = $cgi->param("versionid");
my $levels    = $cgi->param("levels");
my $plot      = $cgi->param("plot");
my $plotFlag  = $cgi->param("GoToPlotSelection");
my $hdfFile   = $cgi->param("hdfFile");

my $PageName = "index.html";


my $cache_dir  = $GIOVANNI::CACHE_DIR;
my $scriptpath = $ENV{SCRIPT_URI};
$scriptpath =~ s/noscript.cgi//;

my $noScript = Giovanni::HTML::NoScript->new(
    PageName   => $PageName,
    path       => $rootPath,
    scriptpath => $scriptpath
);

if ($plot) {
    $noScript->CreatePlotConstraintPage( "Choose Constraints",
        $plot, $variable1, $variable2 );
}
elsif ($plotFlag) {

    # here you might have to set the first variable's levels:
    if ($levels) {
        $noScript->{variable}{name}{$variable}{level} = $levels;
    }
    $noScript->SelectSingleVarPlotPage( "Select Single Variable Plot",
        $variable );
}
elsif ( varIsArray( $cgi->param('variable') ) ) {

    # here you might have to set the second variable's levels:
    if ($levels) {
        $noScript->{variable}{name}{$variable}{level} = $levels;
    }
    $noScript->CreateSelectSecondVarPage( "Select Comparison Plot",
        $variable );
}
elsif ($variable2) {
    if ($levels) {
        $noScript->{variable}{name}{$variable2}{level} = $levels;
        $noScript->SelectComparisonPlotPage( "Plot", $variable, $variable2 );
    }

    # here the second variable might be 3d
    elsif ( $noScript->isit3D($variable2) ) {
        $noScript->PresentZLevelSelectionPage( $variable, $variable2, "1",
            "Select a Comparison Plot" );
    }
    else {
        $noScript->SelectComparisonPlotPage( "Plot", $variable, $variable2 );
    }
}
elsif ($variable) {

    # here the first variable might be 3d
    if ( $noScript->isit3D($variable) ) {
        $noScript->PresentZLevelSelectionPage(
            $variable, $variable2,
            "Select Comparison Variable",
            "Do Vertical Plot",
            "Plot a single dim"
        );
    }
    else {
        $noScript->PresentVarOptionPage( "Yes", "No", $variable,
            "variable1" );
    }
}
else {
    $noScript->CreateSelectVarPage("Next Step");
}

DisplayPage( $noScript, $cgi );

sub DisplayPage {
    my $noScript = shift;
    my $cgi      = shift;
    my $template = $noScript->{current_template};
    my $PAGE     = $noScript->{page};
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

sub varIsArray {
    my @var = @_;
    if ( $#var > 0 ) {
        return 1;
    }
    return undef;
}


sub acceptEntry {
    my $name       = shift;
    my $validation = shift;
    my $value;

    # This $name value is not assigned by user
    if ( $cgi->param($name) ) {
        $value = $cgi->param($name);
        if ( $value !~ /$validation/ ) {
            die " parm $name <$value> is invalid";
        }
        return $value;
    }
}

