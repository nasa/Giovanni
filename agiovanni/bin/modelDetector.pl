#!/usr/bin/perl
use strict;

use XML::LibXML;
use XML::LibXSLT;
use File::Basename;
use XML::Schematron::LibXSLT;

my $schematron = $ARGV[0];
my $ncml       = $ARGV[1];
my $key        = $ARGV[2];

my $modelVal = "";
my @status;

my $schematronHandler = XML::Schematron::LibXSLT->new();
$schematronHandler->schema($schematron);
eval {
    @status   = $schematronHandler->verify($ncml);
    $modelVal = $key;
};
if (@status) {
    ##$modelVal = "";
    print STDERR "ERROR: failed to pass the model: $key -- \n",
        join( "\n", @status ), "\n";
    exit(1);
}

print "$modelVal";
exit(0);

=head1 NAME

modelDetector.pl  -- a perl commandline utility used to find which data model the target netcdf file can meet

=head1 DESCRIPTION

This script is a commandline utility used to validate the ncml with namespace stripped off against the supported data models:

It accepts three arguments:

	1. a schematron file
	
	2. an ncml file with the namespace 'ncml' stripped off
	
	3. a model name to be validated against

It returns a model name, if the validation passes; otherwise, it returns empty.

=head1 SYNOPSIS

$E<gt>perl modelDetector.pl schematron_file ncml_file model_name
   

=head1 AUTHOR

Xiaopeng Hu, E<lt>xiaopeng.hu@nasa.govE<gt>
