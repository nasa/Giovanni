#$Id: scrapeGSocial.pl,v 1.1 2012/08/31 18:23:11 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

use 5.008008;
use strict;
use warnings;
use Getopt::Long;

require Giovanni::GSocial::Scrape;

# get the command line options
my $htmlFile;
my $outFile;
my $helpFlag;
GetOptions(
    "htmlFile=s" => \$htmlFile,
    "outFile=s"  => \$outFile,
    "h"          => \$helpFlag,
);

# if this is the help flag, print out the command line arguments
if ( defined($helpFlag) ) {
    die "$0 --htmlFile 'gsocial html' --outFile 'test plan file'";
}

# check we got arguments
if ( !defined($htmlFile) ) {
    die("Missing required command line argument 'htmlFile'");
}

if ( !defined($outFile) ) {
    die("Missing required command line argument 'outFile'");
}

# read in the html file
open( FILE, $htmlFile ) or die "Couldn't open file $htmlFile";
my $htmlStr = join( "", <FILE> );
close(FILE);

Giovanni::GSocial::Scrape->createTestPlan( $htmlStr, $outFile );

=head1 NAME

scrape_gsocial - scrapes GSocial HTML for giovanni URLs and creates a test plan

=head1 SYNOPSIS

scrape_gsocial.pl --htmlFile "/path/to/file.html" --outFile "out.xml"
  
=head1 DESCRIPTION

Reads through the input html file, pulls out the giovanni URLs and scientists'
descriptions to create a test plan.

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

