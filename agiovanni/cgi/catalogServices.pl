#!/usr/bin/perl -T
#$Id: catalogServices.pl,v 1.31 2015/05/19 18:16:23 kbryant Exp $
#-@@@ Giovanni, Version $Name:  $

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use strict;
use CGI;
use XML::LibXML;
use XML::LibXSLT;
use File::Temp;
use Giovanni::Util;
use LWP::UserAgent;
use JSON;
use Safe;
use Giovanni::CGI;

$| = 1;

$ENV{PATH} = '';

my $cfgFile = ( defined $rootPath ? $rootPath : './' ) . 'cfg/giovanni.cfg';

# Read the configuration file
my $error = Giovanni::Util::ingestGiovanniEnv($cfgFile);
if ( defined $error ) {
    print STDERR "$error\n";
    exit_with_error(
        CGI->new(),
        "500 Internal server error",
        "Error reading configuration"
    );
}
unless ( defined $GIOVANNI::DATA_CATALOG ) {
    exit_with_error(
        CGI->new(),
        "500 Internal server error",
        "Data catalog not defined"
    );
}

# Create a CGI object. The PREQUIRED_PARAMS is optional.
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    PROXY_PARAMS    => [
        "q",           "fq",   "version", "sort",
        "indent",      "wt",   "facet",   "facet.sort",
        "facet.field", "rows", "start"
    ]
);
my %input = $cgi->Vars();

my $json       = JSON->new();
my $constraint = {};
$constraint->{min_datafield_count} = 1;
if ( $input{service} =~ /^(..Sc|Co..|Co....|....Sc|DiTmAvMp)$/ ) {
    $constraint->{min_datafield_count}        = 2;
    $constraint->{max_datafield_count}        = 2;
    $constraint->{equal_datafield_attr}       = 'dataProductTimeInterval';
    $constraint->{equal_datafield_attr_label} = 'Temporal Resolution';
}
elsif ( $input{service} =~ /^(MpAn)$/ ) {
    $constraint->{max_datafield_count} = 1;
}
elsif ( $input{service} =~ /^(VtPf|CrLt|CrLn|CrTm)$/ ) {
    $constraint->{has_datafield_attr}       = 'dataFieldZDimensionType';
    $constraint->{has_datafield_attr_label} = 'Vertical Dimension';
    $constraint->{has_datafield_attr_msg}
        = 'Please select variables with a vertical dimension';
}
elsif ($input{service} =~ /^(QuCl)$/
    || $input{service} =~ /^(InTs)$/
    || $input{service} =~ /^(InTs)$/ )
{
    $constraint->{max_datafield_count}      = 1;
    $constraint->{has_datafield_attr}       = 'dataProductTimeInterval';
    $constraint->{has_datafield_attr_label} = 'Time Interval';
    $constraint->{has_datafield_attr_value} = 'monthly';
    $constraint->{has_datafield_attr_msg} = 'Please select monthly variables';
}
elsif ( $input{service} =~ /^(AcMp)$/ ) {
    $constraint->{has_datafield_attr}       = 'dataFieldAccumulatable';
    $constraint->{has_datafield_attr_label} = 'Accumulatable';
    $constraint->{has_datafield_attr_value} = 'true';
    $constraint->{has_datafield_attr_msg}
        = 'Please select accumulatable variables';
}
elsif ( $input{service} =~ /^(DiArAvTs)/ ) {
    $constraint->{min_datafield_count} = 2;
    $constraint->{max_datafield_count} = 2;
    $constraint->{equal_datafield_attr}
        = 'dataFieldUnits,dataProductTimeInterval';
    $constraint->{equal_datafield_attr_label} = 'Units,Temporal Resolution';
}
if ( scalar( keys %input ) == 1 && exists $input{service} ) {

    # If only asking for service info, supply constraints
    print $cgi->header( -type => 'application/json' );
    my $perlScalar = { constraint => $constraint };
    print $json->encode($perlScalar);
}
else {

    # Otherwise, supply constraints along with catalog response
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;
    my $response = $ua->get(
        $GIOVANNI::DATA_CATALOG . '/select/?' . $ENV{QUERY_STRING} );
    if ( $response->is_success() ) {
        print $cgi->header( -type => 'application/json' );
        my $perlScalar = $json->decode( $response->content() );
        $perlScalar->{constraint} = $constraint;
        if ( defined $perlScalar ) {
            print $json->encode($perlScalar);
        }
        else {
            print $cgi->header( -type => $response->header('Content-Type') );
            print $response->content();
        }
    }
    else {
        exit_with_error(
            $cgi,
            "500 Internal Server Error",
            "Failed to access data catalog:" . $response->code() );
    }
}

sub exit_with_error {
    my ( $cgi, $error, $message ) = @_;
    print $cgi->header( { -type => 'text/plain', -status => $error } );
    print "$message\n" if defined $message;
    exit(0);
}
