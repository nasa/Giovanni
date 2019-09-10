#$Id: Giovanni-Logger-InputOutput.t,v 1.2 2013/07/09 18:54:35 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# This file tests the logging aspects of Giovanni::Logger::InputOutput

use strict;
use XML::LibXML;

use Test::More tests => 4;
BEGIN { use_ok('Giovanni::Logger::InputOutput') }

my $input = Giovanni::Logger::InputOutput->new(
    name  => "my input",
    value => "input value",
    type  => "PARAMETER"
);

my $doc = XML::LibXML->createDocument();

my $element = $doc->createElement("INPUT");

$input->add_attributes($element);

is( $element->getAttribute("NAME"),   "my input",    "correct name" );
is( $element->firstChild->getValue(), "input value", "correct value" );
is( $element->getAttribute("TYPE"),   "PARAMETER",   "correct type" );

