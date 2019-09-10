#$Id: Giovanni-Workflow_getProvenance.t,v 1.3 2013/07/15 20:10:07 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

# tests the Giovanni::Workflow::getProvenance().

# NOTE: This unit test requires that the environment variable

#########################

use Test::More tests => 5;
use File::Temp qw(tempdir);
use strict;
use Cwd 'abs_path';
use XML::LibXML;
use File::Basename;

BEGIN { use_ok('Giovanni::Workflow') }

#########################

# create a temporary directory
my $dir = tempdir( CLEANUP => 1 );

# there will be two targets
my @targets = ( "mfst.first.xml", "mfst.second.xml" );

# create provenance for them
my $firstProv = <<FIRST;
<step NAME="first step" ELAPSED_TIME="10">
  <inputs>
    <input NAME="input1" TYPE="PARAMETER">some input</input>
    <input NAME="input2" TYPE="PARAMETER">another input</input>
  </inputs>
  <outputs>
    <output NAME="output1" TYPE="PARAMETER">output</output>
    <output NAME="output2" TYPE="PARAMETER">another output</output>
  </outputs>
  <messages>
    <message>some message</message>
  </messages>
</step>
FIRST
writeTempFile( "$dir/prov.first.xml", $firstProv );

my $secondProv = <<SECOND;
<step NAME="second step" ELAPSED_TIME="10">
  <inputs>
    <input NAME="input1" TYPE="PARAMETER">some input</input>
  </inputs>
  <outputs>
    <output NAME="output1" TYPE="PARAMETER">output</output>
  </outputs>
  <messages>
    <message>some message</message>
  </messages>
</step>
SECOND
writeTempFile( "$dir/prov.second.xml", $secondProv );

# get the provenance
my $provXml = Giovanni::Workflow::getProvenance(
    "DIRECTORY" => $dir,
    "TARGETS"   => \@targets
);

# figure out where the schema is
my $currDir = dirname(abs_path($0));
my $schemaLoc = "$currDir/../../doc/xsd/provenance.xsd";

if ( !( -e $schemaLoc ) ) {
    die "Unable to find schema. Expected it to be in $schemaLoc.";
}

my $schema = XML::LibXML::Schema->new( location => $schemaLoc );
eval { $schema->validate($provXml) };
ok( !$@, "Provenance matches schema" );

# now run some xpaths to check to make sure the XML is reasonable
my @nodes = $provXml->findnodes("/provenance/step");
is_deeply(
    [ map( $_->getAttribute("NAME"), @nodes ) ],
    [ "first step", "second step" ],
    "Two steps with correct names"
);
@nodes = $provXml->findnodes(
    qq(/provenance/step[\@NAME="first step"]/inputs/input));
is( scalar(@nodes), 2, "First step two inputs." );
is( $provXml->findvalue(
        qq(/provenance/step[\@NAME="second step"]/outputs/output/\@NAME)),
    "output1",
    "Second step output correct"
);

sub writeTempFile {
    my ( $fileName, $string ) = @_;
    open( FILE, ">", $fileName ) or die $?;
    print FILE $string or die $?;
    close(FILE);
}
