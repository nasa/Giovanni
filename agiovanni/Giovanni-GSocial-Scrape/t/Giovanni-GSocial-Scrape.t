#$Id: Giovanni-GSocial-Scrape.t,v 1.2 2012/09/04 17:03:41 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 DESCRIPTION
Tests Scrape.pm to make sure that it correctly creates a test plan. This 
test needs to find the test plan schema. The test first checks for the
schema under /tools/gdaac/TS2/cfg/giovanni/RegressionSchema.xsd. If the schema
isn't there, it expects and environment variable CVS_SANDBOX to be set so it 
can find the schema under 
$CVS_SANDBOX/aGiovanni/Giovanni-Regression/doc/RegressionSchema.xsd.
=cut

use strict;
use File::Temp;
use XML::LibXML;
use Test::More tests => 6;
BEGIN { use_ok('Giovanni::GSocial::Scrape') }

# check that we can convert the bookmarakable URLs into service manager URLs
my $newUrl
    = Giovanni::GSocial::Scrape->_createServiceManagerUrl(
    'http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=23D077CE-F204-11E1-891C-ECA3E963CC93&bbox=55,10,90,30&data=SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_ocean&variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&starttime=2007-01-01&endtime=2007-01-31T23:59:59Z&service=AEROSOLS_TIME_SERIES&portal=GIOVANNI'
    );

is( $newUrl,
    'http://giovanni.gsfc.nasa.gov/beta/daac-bin/giovanni/service_manager.pl?bbox=55,10,90,30&data=SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_ocean&variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&starttime=2007-01-01&endtime=2007-01-31T23:59:59Z&service=AEROSOLS_TIME_SERIES&portal=GIOVANNI',
    'Convert bookmarkable URL to service manager URL'
);

# test that we can get URLs correctly
my $htmlStr = readHtmlData();
my ( $urls, $descriptions ) = Giovanni::GSocial::Scrape->_getUrls($htmlStr);

is( scalar( @{$urls} ), 18, "Correct number of URLs" );

# now check that we can create the output XML file
my ( $handle, $file ) = File::Temp::tempfile( SUFFIX => '.xml' );
Giovanni::GSocial::Scrape->createTestPlan( $htmlStr, $file );

my $xsdFile = findTestPlanXsd();
my $schema  = XML::LibXML::Schema->new( location => $xsdFile );
my $parser  = XML::LibXML->new();
my $doc     = $parser->parse_file($file);

eval { $schema->validate($doc) };
ok( !$@, "Schema validated $@" );

# make sure there are 18 tests
my $xPathStr = "/giovanniRegressionTests/test";
my @nodes    = $doc->findnodes($xPathStr);
is( scalar(@nodes), 18, 'Correct number of tests in test plan' );

# this code looks for Giovanni-Regression.xsd
sub findTestPlanXsd {

    # first try under /tools/gdaac/TS2
    my $xsdFile = "/tools/gdaac/TS2/cfg/giovanni/RegressionSchema.xsd";
    if ( !( -f $xsdFile ) ) {

        # now try via an environment variable
        my $cvsRoot = $ENV{'CVS_SANDBOX'};
        $xsdFile
            = "$cvsRoot/aGiovanni/Giovanni-Regression/doc/RegressionSchema.xsd";
    }

    ok( -f $xsdFile, 'Found schema file' );
    return $xsdFile;
}

# read the gSocial data at the end of the file into a string.
sub readHtmlData {

    # read block at __DATA__
    my @htmldata;
    while (<DATA>) {
        push @htmldata, $_;
    }
    return ( join( '', @htmldata ) );
}

# Sample gSocial page
__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en" dir="ltr">
  <head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="alternate" type="application/rss+xml" title="Sprint-21-Tests (Pass)" href="/node/455/feed" />
<link rel="shortcut icon" href="/sites/default/files/favicon.ico" type="image/x-icon" />
    <title>Sprint-21-Tests (Pass) | Gsocial</title>
    <link type="text/css" rel="stylesheet" media="all" href="/modules/node/node.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/modules/system/defaults.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/modules/system/system.css?b" />

<link type="text/css" rel="stylesheet" media="all" href="/modules/system/system-menus.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/modules/user/user.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/sites/default/modules/cck/theme/content-module.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/sites/default/modules/filefield/filefield.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/sites/default/modules/og/theme/og.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/sites/default/modules/tagadelic/tagadelic.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/sites/default/modules/views/css/views.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/sites/default/modules/jquery_ui/jquery.ui/themes/default/ui.all.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/sites/default/modules/image_annotate.bak/tag.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/sites/default/themes/gsocial/fancybox/jquery.fancybox-1.3.4.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/modules/comment/comment.css?b" />
<link type="text/css" rel="stylesheet" media="all" href="/sites/default/themes/gsocial/style.css?b" />
<link type="text/css" rel="stylesheet" media="print" href="/sites/default/themes/gsocial/print.css?b" />
    <script type="text/javascript" src="/sites/default/modules/jquery_update/replace/jquery.min.js?b"></script>
<script type="text/javascript" src="/misc/drupal.js?b"></script>

<script type="text/javascript" src="/sites/default/modules/gsocial/gsocial.js?b"></script>
<script type="text/javascript" src="/sites/default/modules/og/og.js?b"></script>
<script type="text/javascript" src="/sites/default/modules/jquery_ui/jquery.ui/js/jquery-ui-1.7.3.custom.min.js?b"></script>
<script type="text/javascript" src="/sites/default/modules/jquery_ui/jquery.ui/ui/ui.core.js?b"></script>
<script type="text/javascript" src="/sites/default/modules/sharethis/sharethis/jquery.sharethis.js?b"></script>
<script type="text/javascript" src="/sites/default/modules/sharethis/sharethis.js?b"></script>
<script type="text/javascript" src="/misc/collapse.js?b"></script>
<script type="text/javascript" src="/sites/default/modules/jquery_ui/jquery.ui/ui/minified/ui.core.min.js?b"></script>
<script type="text/javascript" src="/sites/default/modules/jquery_ui/jquery.ui/ui/minified/ui.resizable.min.js?b"></script>

<script type="text/javascript" src="/sites/default/modules/jquery_ui/jquery.ui/ui/minified/ui.draggable.min.js?b"></script>
<script type="text/javascript" src="/sites/default/modules/image_annotate.bak/tag.js?b"></script>
<script type="text/javascript" src="/sites/default/themes/gsocial/fancybox/jquery.fancybox-1.3.4.pack.js?b"></script>
<script type="text/javascript">
<!--//--><![CDATA[//><!--
jQuery.extend(Drupal.settings, { "basePath": "/", "imageAnnotate": [ { "nid": "479", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "479", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "479", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "479", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "479", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "479", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "479", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "479", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "479", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "479", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "478", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "477", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "476", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "475", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "474", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "473", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "471", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "470", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "468", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "467", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "466", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "465", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "464", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "462", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "461", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "459", "field": "field_plotimg10", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg2", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg3", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg4", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg5", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg6", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg7", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg8", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg9", "notes": [  ], "editable": true }, { "nid": "457", "field": "field_plotimg10", "notes": [  ], "editable": true } ], "og": { "group_context": { "nid": "455", "title": "Sprint-21-Tests (Pass)", "type": "group" } } });
//--><!]]>
</script>

    <script type="text/javascript" src="/sites/default/modules/gsocial/jquery.cookie.js"></script>

    <script type="text/javascript" src="/misc/collapse.js"></script>

  <!--[if lt IE 7]>
      <link type="text/css" rel="stylesheet" media="all" href="/sites/default/themes/gsocial/fix-ie.css" />    <![endif]-->

    <link type="text/css" rel="stylesheet" media="all" href="/sites/default/themes/gsocial/disc-common.css" />    
    <script type="text/javascript">
    $(document).ready(function() {
         });
    </script>

<!-- Piwik -->
<script type="text/javascript">
      var pkBaseURL = (("https:" == document.location.protocol) ? "https://gsocial.ecs.nasa.gov/_piwik/" : "http://gsocial.ecs.nasa.gov/_piwik/");
document.write(unescape("%3Cscript src='" + pkBaseURL + "piwik.js' type='text/javascript'%3E%3C/script%3E"));
</script><script type="text/javascript">
  try {
  var piwikTracker = Piwik.getTracker(pkBaseURL + "piwik.php", 1);
  piwikTracker.trackPageView();
  piwikTracker.enableLinkTracking();
} catch( err ) {}
</script><noscript><p><img src="http://gsocial.ecs.nasa.gov/_piwik/piwik.php?idsite=1" style="border:0" alt="" /></p></noscript>
<!-- End Piwik Tracking Code -->

  </head>

  <body class="sidebar-left">


<!-- BEGIN REPORT PROBLEM -->
   <div id="report-problem-box">
      Report Problem
   </div>

   <script type="text/javascript">
      $('#report-problem-box').click(function() {
        // Do not create a dialog if there is already one open
        if ($('#report-problem-dialog').length > 0) {
        return;
    }

        // Retrieve the template and display in a dialog. Attach
        // callback to submit button click handler.
        $.getJSON('/reportproblem/getform?url=' + escape(document.location), function(data) {
      var d = $('<div>');
          d.attr('id', 'report-problem-dialog');
          d.html(data.template);
      d.dialog({title: 'Report Problem', modal: true, width: 400, zIndex: 9999999999, close: function() {d.remove();}});

      var submitBtn = $('#report-problem-submit');
      submitBtn.click(function() {
        submitBtn.val('Sending...');
            submitBtn.attr('disabled', 'disabled');

        $.post('/reportproblem/submitform',
           {'url': $('#report-problem-url').val(),
                    'body': $('#report-problem-body').val()},
           function(data) {
             if (data.success) {
               d.html('Your problem report has been submitted. Thank you!');
             } else {
               d.html('There was an error sending your error report.');
             }
             setTimeout(function() {d.dialog('close');}, 3000);
           },
           'json');
      });
        });
      });
   </script>

<!-- END REPORT PROBLEM -->
    <div id="gs-wrapper"> 

      <div>

<div id="nasahead">
    <a href="http://www.nasa.gov" target="_blank"><img id="nasa_logo" src="/sites/default/themes/gsocial/images/nasa_logo_2.gif" alt="NASA Logo, National Aeronautics and Space Administration" width="240" height="65" /></a>
    <a href="http://disc.sci.gsfc.nasa.gov"><img id="gesdisc_logo" src="/sites/default/themes/gsocial/images/gesdisc_logo.gif" alt="GESDISC Goddard Earth Science Data and Information Center " width="235" height="37" /></a>
    
    <div class="hidden"><a href="#leftnav" title="Skip to Left Navigation" accesskey="2">Skip Navigation (press 2)</a></div>
    <div class="hidden"><a href="#maincontent" title="Skip to Main Content" accesskey="3">Skip Navigation (press 3)</a></div>

    <div id="searchbox" style="display: none">
    <h2><a href="http://disc.sci.gsfc.nasa.gov/daac-bin/search/executeSearch.pl?site=default_collection&amp;client=DISC_default&amp;output=xml_no_dtd&amp;proxystylesheet=DISC_default&amp;proxycustom=%3CHOME/%3E ">Search DISC</a></h2>

    <form method="get" action="http://disc.sci.gsfc.nasa.gov/daac-bin/search/executeSearch.pl">
    <label for="q" title="enter search string"> </label>
        <input type="text" id="q" name="q" size="17" maxlength="255" value=""/>
        <input name="image" type="image" class="submitit" src="/sites/default/themes/gsocial/images/go_button.gif" alt="Submit Search" />
        <input type="hidden" name="site" value="All_DISCs"/>                    <!-- Collection to search -->
        <input type="hidden" name="client" value="DISC_default"/>               <!-- Name of Frontend - Custom Look & Feel to use -->
        <input type="hidden" name="proxystylesheet" value="DISC_default"/>      <!-- XSLT file - Custom Look & Feel to use -->

        <input type="hidden" name="output" value="xml_no_dtd"/>                 <!-- return custom HTML -->
        <input type="hidden" name="proxyreload" value="1" />                    <!-- TESTING ONLY - force reload of cached XSLT stylesheet -->
    </form> 
    <h3><a href="http://disc.sci.gsfc.nasa.gov/daac-bin/search/executeSearch.pl?entqr=0&amp;access=p&amp;ud=1&amp;sort=date%3AD%3AL%3Ad1&amp;output=xml_no_dtd&amp;site=default_collection&amp;ie=UTF-8&amp;oe=UTF-8&amp;client=DISC_default&amp;proxystylesheet=DISC_default&amp;ip=128.183.162.191&amp;proxycustom=%3CADVANCED/%3E ">+ Advanced Search</a></h3>
    </div>
</div>
<!--
<div id="topNav">
    <table width="100%" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td nowrap="nowrap"><a id="tn_acdisc" href="http://disc.sci.gsfc.nasa.gov/acdisc/" title="Atmospheric Composition Portal" onclick="return ntptLinkTag(this, 'topNav=acdisc')"><img src="/sites/default/themes/gsocial/images/largeplus.gif" width="7" height="7" alt=""/>Atmos Composition<img src="/sites/default/themes/gsocial/images/spacer.gif" width="7" height="7" alt=""/></a></td>
            <td nowrap="nowrap"><a id="tn_hdisc" href="http://disc.sci.gsfc.nasa.gov/hydrology/" title="Hydrology Portal" onclick="return ntptLinkTag(this, 'topNav=hdisc')"><img src="/sites/default/themes/gsocial/images/largeplus.gif" width="7" height="7" alt=""/>Hydrology<img src="/sites/default/themes/gsocial/images/spacer.gif" width="7" height="7" alt=""/></a></td>
            <td nowrap="nowrap"><a id="tn_atdd" href="http://disc.sci.gsfc.nasa.gov/atdd/" title="A-Train Data Depot Portal" onclick="return ntptLinkTag(this, 'topNav=atrain')"><img src="/sites/default/themes/gsocial/images/largeplus.gif" width="7" height="7" alt=""/>A-Train<img src="/sites/default/themes/gsocial/images/spacer.gif" width="7" height="7" alt=""/></a></td>
            <td nowrap="nowrap"><a id="tn_airs" href="http://disc.sci.gsfc.nasa.gov/AIRS/" title="Atmospheric Infrared Sounder" onclick="return ntptLinkTag(this, 'topNav=airs')"><img src="/sites/default/themes/gsocial/images/largeplus.gif" width="7" height="7" alt=""/>AIRS<img src="/sites/default/themes/gsocial/images/spacer.gif" width="7" height="7" alt=""/></a></td>
            <td nowrap="nowrap"><a id="tn_hurricane" href="http://disc.sci.gsfc.nasa.gov/hurricane/" title="Hurricane Portal" onclick="return ntptLinkTag(this, 'topNav=hurricane')"><img src="/sites/default/themes/gsocial/images/largeplus.gif" width="7" height="7" alt=""/>HURRICANES<img src="/sites/default/themes/gsocial/images/spacer.gif" width="7" height="7" alt=""/></a></td>
            <td nowrap="nowrap"><a id="tn_neespi" href="http://neespi.sci.gsfc.nasa.gov/" title="Northern Eurasia Earth Science Partnership Portal" onclick="return ntptLinkTag(this, 'topNav=neespi')"><img src="/sites/default/themes/gsocial/images/largeplus.gif" width="7" height="7" alt=""/>NEESPI<img src="/sites/default/themes/gsocial/images/spacer.gif" width="7" height="7" alt=""/></a></td>
            <td nowrap="nowrap" style="border-right:none"><a id="tn_precip" href="http://disc.sci.gsfc.nasa.gov/precipitation/" title="Precipitation Portal" onclick="return ntptLinkTag(this, 'topNav=pdisc')"><img src="/sites/default/themes/gsocial/images/largeplus.gif" width="7" height="7" alt=""/>Precipitation<img src="/sites/default/themes/gsocial/images/spacer.gif" width="7" height="7" alt=""/></a></td>
        </tr>
    </table>
</div>
-->
</div>
<!-- Layout -->
  <div id="header-region" class="clear-block"></div>

    <div id="wrapper">
    <div id="container" class="clear-block">

      <div id="header">
        <div id="logo-floater">
        <h1 style="display: inline;"><a href="/" title="Gsocial"><span>Gsocial</span></a></h1>  <span id="header-search">
      <form action="/search/node"  accept-charset="UTF-8" method="post" id="search-form" style="display: inline;">
        <input type="text" maxlength="255" name="keys" id="edit-keys" size="25" value="" style="  -webkit-border-radius: 10px; -moz-border-radius: 10px; border-radius: 10px;"/>

        <input type="submit" name="op" value="Search" />
      </form>
        </span>

        </div>

    <div id="header-links">
      <ul>
        <li><a href="/about">About</a>

        <li><a href="/help">Help</a>
          </ul>
        </div>

                                                    
      </div> <!-- /header -->

              <div id="sidebar-left" class="sidebar">
                    <div id="block-user-1" class="clear-block block block-user">

  <h2>csmit</h2>

  <div class="content"><ul class="menu"><li class="leaf first"><a href="https://gsocial.ecs.nasa.gov/" title="">Public Newsfeed</a></li>
<li class="leaf"><a href="/group" title="">My Newsfeed</a></li>
<li class="leaf"><a href="/notebook/27">My Research Notebook</a></li>
<li class="leaf"><a href="/user/27" title="">My Profile</a></li>
<li class="leaf"><a href="/tagadelic">Tags</a></li>
<li class="collapsed"><a href="/og" title="">All Groups</a></li>

<li class="leaf"><a href="/help" title="">Help</a></li>
<li class="leaf"><a href="/feedback" title="">Providing Feedback</a></li>
<li class="leaf last"><a href="/logout">Log out</a></li>
</ul></div>
</div>
<div id="block-views-og_my-block_1" class="clear-block block block-views">

  <h2>My groups</h2>

  <div class="content"><div class="view view-og-my view-id-og_my view-display-id-block_1 view-dom-id-2">
    
  
  
      <div class="view-content">

      <table class="views-table cols-2">
    <thead>
    <tr>
              <th class="views-field views-field-title active">
          <a href="/node/455?order=title&amp;sort=desc" title="sort by Group" class="active">Group<img src="/misc/arrow-desc.png" alt="sort icon" title="sort descending" width="13" height="13" /></a>        </th>
              <th class="views-field views-field-post-count-new">
          New        </th>

          </tr>
  </thead>
  <tbody>
          <tr class="odd views-row-first views-row-last">
                  <td class="views-field views-field-title active">
            <a href="/node/455" class="active">Sprint-21-Tests (Pass)</a>          </td>
                  <td class="views-field views-field-post-count-new">
            18 <span class="marker">new</span>          </td>

              </tr>
      </tbody>
</table>
    </div>
  
  
      <div class="attachment attachment-after">
      <a href="/og/opml" class="opml-icon"><img src="/sites/default/modules/og/images/opml-icon-16x16.png" alt="OPML feed" title="OPML feed" width="16" height="16" /></a>    </div>
  
  
  
  
</div> </div>
</div>
        </div>

      
      <div id="center"><div id="squeeze"><div class="right-corner"><div class="left-corner">
          <div class="breadcrumb"><a href="/">Home</a> ��� <a href="/og">Groups</a></div>                              <h2>Sprint-21-Tests (Pass)</h2>                                                  <div class="clear-block">                                 
                          <script type="text/javascript">
          $('#sticky-close').click(function() {
             $('#sticky').hide('fast');
             var value = $.cookie('hideStickies');
             names = (value == null) ? [] : value.split(',');
             names.push('<?= $stickyName ?>');
             $.cookie('hideStickies', names.join(','))
          });

                  $(document).ready(function() {
             var value = $.cookie('hideStickies');
             var names = (value == null) ? [] : value.split(',');

             var wasHidden = false;
             for (var i=0; i < names.length; i++) {
               if (names[i] == '<?= $stickyName ?>') {
             wasHidden = true;
             break;
               }
             }
              
             if (wasHidden) {
               $('#sticky').hide();
             } else {
               $('#sticky').show();
             }
          });
              </script>

          

<div id="node-455" class="node">


  
  <div class="content clear-block">
    <div class="view view-og-ghp-ron view-id-og_ghp_ron view-display-id-default view-dom-id-1">
    
  
  
      <div class="view-content">
        <div class="views-row views-row-1 views-row-odd views-row-first">
    
<div id="node-479" class="node">


   <h2><a href="/node/479" title="SWDB_L310_HDF4.003: Aangstrom_exponent_stddev_ocean (2007-01-01 to 2007-01-31T23:59:59Z)">SWDB_L310_HDF4.003: Aangstrom_exponent_stddev_ocean (2007-01-01 to 2007-01-31T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 15:27 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/479#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/479" class="sharethis-link" title="SWDB_L310_HDF4.003: Aangstrom_exponent_stddev_ocean (2007-01-01 to 2007-01-31T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily angstrom exponent standard deviation, 1x1 deg ( ocean only). passed.</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=23D077CE-F204-11E1-891C-ECA3E963CC93&amp;bbox=55,10,90,30&amp;data=SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_ocean&amp;variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2007-01-01&amp;endtime=2007-01-31T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-479').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-479" style="display: none">

    
      <b>Bounding Box:</b> 55,10,90,30<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2007-01-01<br>
      <b>End Time:</b> 2007-01-31T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-479-1' rel='node-479-plots' href='#plotthumb-479-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20070101_v003-20111128T163140Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_stddev_ocean.aavg_130181346271893_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-479-1-fb'>    <span class='node-plot' id='field_plotimg-479'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="563" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20070101_v003-20111128T163140Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_stddev_ocean.aavg_130181346271893_0.gif?1346272020" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-479-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '479' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-2 views-row-even">
    
<div id="node-478" class="node">


   <h2><a href="/node/478" title="SWDB_L310_HDF4.003: Aangstrom_exponent_stddev_land (2007-01-01 to 2007-01-31T23:59:59Z)">SWDB_L310_HDF4.003: Aangstrom_exponent_stddev_land (2007-01-01 to 2007-01-31T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 15:24 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/478#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/478" class="sharethis-link" title="SWDB_L310_HDF4.003: Aangstrom_exponent_stddev_land (2007-01-01 to 2007-01-31T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily angstrom exponent standard deviation , 1x1 deg (land only).  passed. </p>
<p>One problem is that the dates ( x-axis) label is kind of difficult to read.</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=23D077CE-F204-11E1-891C-ECA3E963CC93&amp;bbox=55,10,90,30&amp;data=SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_land&amp;variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2007-01-01&amp;endtime=2007-01-31T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-478').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-478" style="display: none">
    
      <b>Bounding Box:</b> 55,10,90,30<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_land</li>
</ul></div><br>
      <b>Start Time:</b> 2007-01-01<br>

      <b>End Time:</b> 2007-01-31T23:59:59Z<br>
   </div>
    </p>
  </div>

  <a id='plotthumb-478-1' rel='node-478-plots' href='#plotthumb-478-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20070101_v003-20111128T163140Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_stddev_land.aavg_119091346271578_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-478-1-fb'>    <span class='node-plot' id='field_plotimg-478'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="563" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20070101_v003-20111128T163140Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_stddev_land.aavg_119091346271578_0.gif?1346271843" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-478-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '478' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>

    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });
</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-3 views-row-odd">
    
<div id="node-477" class="node">


   <h2><a href="/node/477" title="SWDB_L310_HDF4.003: Aangstrom_exponent_stddev_land_ocean (2007-01-01 to 2007-01-31T23:59:59Z)">SWDB_L310_HDF4.003: Aangstrom_exponent_stddev_land_ocean (2007-01-01 to 2007-01-31T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 15:18 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/477#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/477" class="sharethis-link" title="SWDB_L310_HDF4.003: Aangstrom_exponent_stddev_land_ocean (2007-01-01 to 2007-01-31T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily angstrom exponent, 1x1 deg (land and ocean).  Data values matched G3, passed.</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=23D077CE-F204-11E1-891C-ECA3E963CC93&amp;bbox=55,10,90,30&amp;data=SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_land_ocean&amp;variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2007-01-01&amp;endtime=2007-01-31T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-477').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-477" style="display: none">

    
      <b>Bounding Box:</b> 55,10,90,30<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aangstrom_exponent_stddev_land_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2007-01-01<br>
      <b>End Time:</b> 2007-01-31T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-477-1' rel='node-477-plots' href='#plotthumb-477-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20070101_v003-20111128T163140Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_stddev_land_ocean.aavg_107931346271158_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-477-1-fb'>    <span class='node-plot' id='field_plotimg-477'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="563" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20070101_v003-20111128T163140Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_stddev_land_ocean.aavg_107931346271158_0.gif?1346271510" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-477-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '477' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-4 views-row-even">
    
<div id="node-476" class="node">


   <h2><a href="/node/476" title="SWDB_L310_HDF4.003: Aangstrom_exponent_ocean (2007-12-01 to 2007-12-20T23:59:59Z)">SWDB_L310_HDF4.003: Aangstrom_exponent_ocean (2007-12-01 to 2007-12-20T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 15:03 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/476#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/476" class="sharethis-link" title="SWDB_L310_HDF4.003: Aangstrom_exponent_ocean (2007-12-01 to 2007-12-20T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily angstrom exponent, 1x1 deg (ocean only). passed</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=23D077CE-F204-11E1-891C-ECA3E963CC93&amp;bbox=55,10,90,30&amp;data=SWDB_L310_HDF4.003%3Aangstrom_exponent_ocean&amp;variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2007-12-01&amp;endtime=2007-12-20T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-476').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-476" style="display: none">

    
      <b>Bounding Box:</b> 55,10,90,30<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aangstrom_exponent_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2007-12-01<br>
      <b>End Time:</b> 2007-12-20T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-476-1' rel='node-476-plots' href='#plotthumb-476-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20071201_v003-20111128T173648Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_ocean.aavg_96161346270444_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-476-1-fb'>    <span class='node-plot' id='field_plotimg-476'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="560" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20071201_v003-20111128T173648Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_ocean.aavg_96161346270444_0.gif?1346270638" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-476-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '476' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-5 views-row-odd">
    
<div id="node-475" class="node">


   <h2><a href="/node/475" title="SWDB_L310_HDF4.003: Aangstrom_exponent_land (2007-12-01 to 2007-12-20T23:59:59Z)">SWDB_L310_HDF4.003: Aangstrom_exponent_land (2007-12-01 to 2007-12-20T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 15:00 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/475#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/475" class="sharethis-link" title="SWDB_L310_HDF4.003: Aangstrom_exponent_land (2007-12-01 to 2007-12-20T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily angstrom exponent, 1x1 degree (land only).  passed</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=23D077CE-F204-11E1-891C-ECA3E963CC93&amp;bbox=55,10,90,30&amp;data=SWDB_L310_HDF4.003%3Aangstrom_exponent_land&amp;variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2007-12-01&amp;endtime=2007-12-20T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-475').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-475" style="display: none">

    
      <b>Bounding Box:</b> 55,10,90,30<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aangstrom_exponent_land</li>
</ul></div><br>
      <b>Start Time:</b> 2007-12-01<br>
      <b>End Time:</b> 2007-12-20T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-475-1' rel='node-475-plots' href='#plotthumb-475-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20071201_v003-20111128T173648Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_land.aavg_87311346269967_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-475-1-fb'>    <span class='node-plot' id='field_plotimg-475'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="560" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20071201_v003-20111128T173648Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_land.aavg_87311346269967_0.gif?1346270405" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-475-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '475' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-6 views-row-even">
    
<div id="node-474" class="node">


   <h2><a href="/node/474" title="SWDB_L310_HDF4.003: Aangstrom_exponent_land_ocean (2007-12-01 to 2007-12-20T23:59:59Z)">SWDB_L310_HDF4.003: Aangstrom_exponent_land_ocean (2007-12-01 to 2007-12-20T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 14:50 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/474#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/474" class="sharethis-link" title="SWDB_L310_HDF4.003: Aangstrom_exponent_land_ocean (2007-12-01 to 2007-12-20T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily angstrom exponent, 1x1 deg. passed</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=23D077CE-F204-11E1-891C-ECA3E963CC93&amp;bbox=55,10,90,30&amp;data=SWDB_L310_HDF4.003%3Aangstrom_exponent_land_ocean&amp;variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3AAngstrom%20Exponent%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2007-12-01&amp;endtime=2007-12-20T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-474').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-474" style="display: none">

    
      <b>Bounding Box:</b> 55,10,90,30<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aangstrom_exponent_land_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2007-12-01<br>
      <b>End Time:</b> 2007-12-20T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-474-1' rel='node-474-plots' href='#plotthumb-474-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20071201_v003-20111128T173648Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_land_ocean.aavg_67761346265050_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-474-1-fb'>    <span class='node-plot' id='field_plotimg-474'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="560" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20071201_v003-20111128T173648Z.hdf_.ncmlSWDB_L310_HDF4.003_angstrom_exponent_land_ocean.aavg_67761346265050_0.gif?1346269843" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-474-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '474' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-7 views-row-odd">
    
<div id="node-473" class="node">


   <h2><a href="/node/473" title="SWDB_L310_HDF4.003: Aaerosol_optical_thickness_550_ocean (2007-12-01 to 2007-12-20T23:59:59Z)">SWDB_L310_HDF4.003: Aaerosol_optical_thickness_550_ocean (2007-12-01 to 2007-12-20T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 13:27 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/473#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/473" class="sharethis-link" title="SWDB_L310_HDF4.003: Aaerosol_optical_thickness_550_ocean (2007-12-01 to 2007-12-20T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOT,  1x1 deg (ocean only).  Passed.</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=23D077CE-F204-11E1-891C-ECA3E963CC93&amp;bbox=-180,-90,180,90&amp;data=SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_ocean&amp;variableFacets=dataProductPlatformShortName%3AOrbView-2%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2007-12-01&amp;endtime=2007-12-20T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-473').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-473" style="display: none">

    
      <b>Bounding Box:</b> -180,-90,180,90<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2007-12-01<br>
      <b>End Time:</b> 2007-12-20T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-473-1' rel='node-473-plots' href='#plotthumb-473-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20071201_v003-20111128T173648Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_ocean.aavg_58841346264423_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-473-1-fb'>    <span class='node-plot' id='field_plotimg-473'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="563" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20071201_v003-20111128T173648Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_ocean.aavg_58841346264423_0.gif?1346264835" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-473-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '473' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-8 views-row-even">
    
<div id="node-471" class="node">


   <h2><a href="/node/471" title="SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_ocean (2004-04-03 to 2004-04-30T23:59:59Z)">SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_ocean (2004-04-03 to 2004-04-30T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 10:38 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/471#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/471" class="sharethis-link" title="SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_ocean (2004-04-03 to 2004-04-30T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOT, 0.5x0.5 deg (ocean only). passed</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=1CFFBA1C-F1D3-11E1-8108-9E6FB0A50CE9&amp;bbox=-180,-90,180,0&amp;data=SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_ocean&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A0.5%20x%200.5%20deg.%3B&amp;starttime=2004-04-03&amp;endtime=2004-04-30T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-471').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-471" style="display: none">

    
      <b>Bounding Box:</b> -180,-90,180,0<br>   
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-03<br>
      <b>End Time:</b> 2004-04-30T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-471-1' rel='node-471-plots' href='#plotthumb-471-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-0.5_L3_20040403_v003-20111128T024356Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_ocean.aavg_321321346253580_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-471-1-fb'>    <span class='node-plot' id='field_plotimg-471'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="572" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-0.5_L3_20040403_v003-20111128T024356Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_ocean.aavg_321321346253580_0.gif?1346254685" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-471-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '471' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-9 views-row-odd">
    
<div id="node-470" class="node">


   <h2><a href="/node/470" title="SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_land (2004-04-01 to 2004-04-30T23:59:59Z)">SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_land (2004-04-01 to 2004-04-30T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 10:13 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/470#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/470" class="sharethis-link" title="SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_land (2004-04-01 to 2004-04-30T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOT, 0.5x0.5 deg (land only). passed</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=1CFFBA1C-F1D3-11E1-8108-9E6FB0A50CE9&amp;bbox=-180,-90,180,0&amp;data=SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_land&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A0.5%20x%200.5%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-30T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-470').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-470" style="display: none">

    
      <b>Bounding Box:</b> -180,-90,180,0<br>   
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_land</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>
      <b>End Time:</b> 2004-04-30T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-470-1' rel='node-470-plots' href='#plotthumb-470-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_land.aavg_293191346249972_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-470-1-fb'>    <span class='node-plot' id='field_plotimg-470'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="572" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_land.aavg_293191346249972_0.gif?1346253208" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-470-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '470' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-10 views-row-even">
    
<div id="node-468" class="node">


   <h2><a href="/node/468" title="SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_land_ocean (2004-04-01 to 2004-04-30T23:59:59Z)">SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_land_ocean (2004-04-01 to 2004-04-30T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 09:18 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/468#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/468" class="sharethis-link" title="SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_land_ocean (2004-04-01 to 2004-04-30T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOT, 0.5x0.5 deg (land and ocean). passed.</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=1CFFBA1C-F1D3-11E1-8108-9E6FB0A50CE9&amp;bbox=-180,-90,180,0&amp;data=SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_land_ocean&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A0.5%20x%200.5%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-30T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-468').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-468" style="display: none">

    
      <b>Bounding Box:</b> -180,-90,180,0<br>   
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_land_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>
      <b>End Time:</b> 2004-04-30T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-468-1' rel='node-468-plots' href='#plotthumb-468-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_land_ocean.aavg_281221346249085_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-468-1-fb'>    <span class='node-plot' id='field_plotimg-468'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="572" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_land_ocean.aavg_281221346249085_0.gif?1346249899" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-468-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '468' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-11 views-row-odd">
    
<div id="node-467" class="node">


   <h2><a href="/node/467" title="SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_stddev_ocean (2004-04-01 to 2004-04-25T23:59:59Z)">SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_stddev_ocean (2004-04-01 to 2004-04-25T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 09:02 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/467#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/467" class="sharethis-link" title="SWDB_L305_HDF4.003: Aaerosol_optical_thickness_550_stddev_ocean (2004-04-01 to 2004-04-25T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOT standard deviation, 0.5x0,5 deg resolution (ocean only). passed</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=1CFFBA1C-F1D3-11E1-8108-9E6FB0A50CE9&amp;bbox=-180,-90,180,90&amp;data=SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_stddev_ocean&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A0.5%20x%200.5%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-25T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-467').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-467" style="display: none">

    
      <b>Bounding Box:</b> -180,-90,180,90<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_stddev_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>
      <b>End Time:</b> 2004-04-25T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-467-1' rel='node-467-plots' href='#plotthumb-467-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_stddev_ocean.aavg_270101346248797_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-467-1-fb'>    <span class='node-plot' id='field_plotimg-467'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="572" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_stddev_ocean.aavg_270101346248797_0.gif?1346248976" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-467-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '467' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-12 views-row-even">
    
<div id="node-466" class="node">


   <h2><a href="/node/466" title="SWDB_L305_HDF4.003: 3Aaerosol_optical_thickness_550_stddev_land (2004-04-01 to 2004-04-25T23:59:59Z)">SWDB_L305_HDF4.003: 3Aaerosol_optical_thickness_550_stddev_land (2004-04-01 to 2004-04-25T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 08:58 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/466#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/466" class="sharethis-link" title="SWDB_L305_HDF4.003: 3Aaerosol_optical_thickness_550_stddev_land (2004-04-01 to 2004-04-25T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOD standard deviation, 0.5x0.5 resolution (land only). Passed</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=1CFFBA1C-F1D3-11E1-8108-9E6FB0A50CE9&amp;bbox=-180,-90,180,90&amp;data=SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_stddev_land&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A0.5%20x%200.5%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-25T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-466').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-466" style="display: none">

    
      <b>Bounding Box:</b> -180,-90,180,90<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_stddev_land</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>
      <b>End Time:</b> 2004-04-25T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-466-1' rel='node-466-plots' href='#plotthumb-466-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_stddev_land.aavg_249101346245174_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-466-1-fb'>    <span class='node-plot' id='field_plotimg-466'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="572" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_stddev_land.aavg_249101346245174_0.gif?1346248719" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-466-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '466' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-13 views-row-odd">
    
<div id="node-465" class="node">


   <h2><a href="/node/465" title="SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_stddev_land_ocean (2004-04-01 to 2004-04-25T23:59:59Z)">SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_stddev_land_ocean (2004-04-01 to 2004-04-25T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 07:57 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/465#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/465" class="sharethis-link" title="SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_stddev_land_ocean (2004-04-01 to 2004-04-25T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOT, 0.5x0.5 deg, across dateline.  passed.</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=1CFFBA1C-F1D3-11E1-8108-9E6FB0A50CE9&amp;bbox=170,0,-170,90&amp;data=SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_stddev_land_ocean&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A0.5%20x%200.5%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-25T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-465').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-465" style="display: none">

    
      <b>Bounding Box:</b> 170,0,-170,90<br>    
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L305_HDF4.003%3Aaerosol_optical_thickness_550_stddev_land_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>
      <b>End Time:</b> 2004-04-25T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-465-1' rel='node-465-plots' href='#plotthumb-465-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_stddev_land_ocean.aavg_239621346244829_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-465-1-fb'>    <span class='node-plot' id='field_plotimg-465'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="572" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-0.5_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L305_HDF4.003_aerosol_optical_thickness_550_stddev_land_ocean.aavg_239621346244829_0.gif?1346245070" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-465-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '465' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-14 views-row-even">
    
<div id="node-464" class="node">


   <h2><a href="/node/464" title="SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land (2004-04-01 to 2004-04-25T23:59:59Z)">SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land (2004-04-01 to 2004-04-25T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 07:44 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/464#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/464" class="sharethis-link" title="SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land (2004-04-01 to 2004-04-25T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOT, 1x1 deg resolution (land only).   Passed.</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=1CFFBA1C-F1D3-11E1-8108-9E6FB0A50CE9&amp;bbox=-180,0,180,90&amp;data=SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-25T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-464').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-464" style="display: none">

    
      <b>Bounding Box:</b> -180,0,180,90<br>    
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>
      <b>End Time:</b> 2004-04-25T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-464-1' rel='node-464-plots' href='#plotthumb-464-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_land.aavg_225911346244098_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-464-1-fb'>    <span class='node-plot' id='field_plotimg-464'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="563" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_land.aavg_225911346244098_0.gif?1346244252" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-464-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '464' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-15 views-row-odd">
    
<div id="node-462" class="node">


   <h2><a href="/node/462" title="SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land_ocean (2004-04-01 to 2004-04-25T23:59:59Z)">SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land_ocean (2004-04-01 to 2004-04-25T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 07:33 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/462#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/462" class="sharethis-link" title="SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land_ocean (2004-04-01 to 2004-04-25T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOT, 1x1 deg resolution. passed.</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=1CFFBA1C-F1D3-11E1-8108-9E6FB0A50CE9&amp;bbox=-20,0,90,45&amp;data=SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land_ocean&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-25T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-462').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-462" style="display: none">

    
      <b>Bounding Box:</b> -20,0,90,45<br>  
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_land_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>
      <b>End Time:</b> 2004-04-25T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-462-1' rel='node-462-plots' href='#plotthumb-462-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_land_ocean.aavg_212561346243412_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-462-1-fb'>    <span class='node-plot' id='field_plotimg-462'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="563" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_land_ocean.aavg_212561346243412_0.gif?1346243581" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-462-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '462' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-16 views-row-even">
    
<div id="node-461" class="node">


   <h2><a href="/node/461" title="SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_stddev_ocean (2004-04-01 to 2004-04-25T23:59:59Z)">SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_stddev_ocean (2004-04-01 to 2004-04-25T23:59:59Z)</a></h2>

  <span class="submitted">Wed, 08/29/2012 - 07:27 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/461#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/461" class="sharethis-link" title="SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_stddev_ocean (2004-04-01 to 2004-04-25T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test of SWDB daily AOT standard deviation, 1x1 deg resolution over south Asia (ocean only).  passed.</p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=1CFFBA1C-F1D3-11E1-8108-9E6FB0A50CE9&amp;bbox=65,8,90,30&amp;data=SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_stddev_ocean&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-25T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-461').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-461" style="display: none">

    
      <b>Bounding Box:</b> 65,8,90,30<br>   
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4.003%3Aaerosol_optical_thickness_550_stddev_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>
      <b>End Time:</b> 2004-04-25T23:59:59Z<br>

   </div>
    </p>
  </div>

  <a id='plotthumb-461-1' rel='node-461-plots' href='#plotthumb-461-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_stddev_ocean.aavg_209141346242816_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-461-1-fb'>    <span class='node-plot' id='field_plotimg-461'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="560" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_stddev_ocean.aavg_209141346242816_0.gif?1346243259" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-461-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '461' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>
    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });

</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-17 views-row-odd">
    
<div id="node-459" class="node">


   <h2><a href="/node/459" title="SWDB_L310_HDF4_003:aerosol_optical_thickness_550_stddev_land (2004-04-01 to 2004-04-25T23:59:59Z)">SWDB_L310_HDF4_003:aerosol_optical_thickness_550_stddev_land (2004-04-01 to 2004-04-25T23:59:59Z)</a></h2>

  <span class="submitted">Tue, 08/28/2012 - 14:41 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/459#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/459" class="sharethis-link" title="SWDB_L310_HDF4_003:aerosol_optical_thickness_550_stddev_land (2004-04-01 to 2004-04-25T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test SWDB daily AOD standard deviation (land) over Indian. Good.<br />
G3 plot:<br />
<a href="http://gdata1.sci.gsfc.nasa.gov/daac-bin/G3/results.cgi?wsid=134618268819131&amp;app=timeseries&amp;instance_id=SWDB_daily&amp;sid=134618214915668&amp;gsid=SWDB_daily_128.183.164.38_1346179607&amp;selectedMap=Blue%20Marble&amp;overridePreferences=1" title="http://gdata1.sci.gsfc.nasa.gov/daac-bin/G3/results.cgi?wsid=134618268819131&amp;app=timeseries&amp;instance_id=SWDB_daily&amp;sid=134618214915668&amp;gsid=SWDB_daily_128.183.164.38_1346179607&amp;selectedMap=Blue%20Marble&amp;overridePreferences=1">http://gdata1.sci.gsfc.nasa.gov/daac-bin/G3/results.cgi?wsid=13461826881...</a></p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=05B4B64C-F146-11E1-894B-87CA2BD5910A&amp;bbox=65,8,90,30&amp;data=SWDB_L310_HDF4_003_aerosol_optical_thickness_550_stddev_land&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-25T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-459').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-459" style="display: none">
    
      <b>Bounding Box:</b> 65,8,90,30<br>   
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4_003_aerosol_optical_thickness_550_stddev_land</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>

      <b>End Time:</b> 2004-04-25T23:59:59Z<br>
   </div>
    </p>
  </div>

  <a id='plotthumb-459-1' rel='node-459-plots' href='#plotthumb-459-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4_003_aerosol_optical_thickness_550_stddev_land.aavg_229551346182732_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-459-1-fb'>    <span class='node-plot' id='field_plotimg-459'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="563" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4_003_aerosol_optical_thickness_550_stddev_land.aavg_229551346182732_0.gif?1346182915" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-459-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '459' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>

    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });
</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
  <div class="views-row views-row-18 views-row-even views-row-last">
    
<div id="node-457" class="node">


   <h2><a href="/node/457" title="SWDB_L310_HDF4_003: aerosol_optical_thickness_550_stddev_land_ocean (2004-04-01 to 2004-04-24T23:59:59Z)">SWDB_L310_HDF4_003: aerosol_optical_thickness_550_stddev_land_ocean (2004-04-01 to 2004-04-24T23:59:59Z)</a></h2>

  <span class="submitted">Tue, 08/28/2012 - 14:23 &mdash; <a href="/profile/36">sshen55</a></span>
    <div class="meta">
          <div class="terms">Tags:<ul class="links inline"><li class="taxonomy_term_92 first last"><a href="/taxonomy/term/92" rel="tag" title="">SWDB Daily</a></li>
</ul></div>
        </div>

  <br><br>

  <div class="clear-block">
        
      <br>
      <div class="mylinks">
     <ul class="links inline"><li class="comment_add first"><a href="/node/457#node-form" title="Add a new comment to this page.">Add new comment</a></li>
<li class="sharethis_link last"><a href="https://gsocial.ecs.nasa.gov/node/457" class="sharethis-link" title="SWDB_L310_HDF4_003: aerosol_optical_thickness_550_stddev_land_ocean (2004-04-01 to 2004-04-24T23:59:59Z)" rel="nofollow">ShareThis</a></li>
</ul>      </div>
<br>
      </div>

  <div>
    <p><p>Test time series for SWDB Level 3 daily AOT standard deviation at 550nm over Indian<br />
Same plot in G3:<br />
<a href="http://gdata1.sci.gsfc.nasa.gov/daac-bin/G3/results.cgi?wsid=134618042726845&amp;app=timeseries&amp;instance_id=SWDB_daily&amp;sid=134618042026742&amp;gsid=SWDB_daily_128.183.164.38_1346179607&amp;selectedMap=Blue%20Marble&amp;" title="http://gdata1.sci.gsfc.nasa.gov/daac-bin/G3/results.cgi?wsid=134618042726845&amp;app=timeseries&amp;instance_id=SWDB_daily&amp;sid=134618042026742&amp;gsid=SWDB_daily_128.183.164.38_1346179607&amp;selectedMap=Blue%20Marble&amp;">http://gdata1.sci.gsfc.nasa.gov/daac-bin/G3/results.cgi?wsid=13461804272...</a></p>
</p>
    <p>
      <a href="http://giovanni.gsfc.nasa.gov/beta/giovanni/#session=8405A044-F13F-11E1-BE52-AE1B49DA92C4&amp;bbox=65,8,90,30&amp;data=SWDB_L310_HDF4_003_aerosol_optical_thickness_550_stddev_land_ocean&amp;variableFacets=dataProductInstrumentShortName%3ASEAWIFS%3BparameterMeasurement%3ATotal%20Aerosol%20Optical%20Depth%3BdataProductSpatialResolution%3A1%20x%201%20deg.%3B&amp;starttime=2004-04-01&amp;endtime=2004-04-24T23:59:59Z&amp;service=AEROSOLS_TIME_SERIES&amp;portal=GIOVANNI" target="_blank" rel="nofollow">Load this Result and Modify Criteria</a><br>
          <a style="cursor: pointer;" onclick="$('#node-criteria-457').toggle('fast');">Show/Hide criteria</a><br>

    <div id="node-criteria-457" style="display: none">
    
      <b>Bounding Box:</b> 65,8,90,30<br>   
    <b>Variables:</b> <div class="item-list"><ul><li class="first last">SWDB_L310_HDF4_003_aerosol_optical_thickness_550_stddev_land_ocean</li>
</ul></div><br>
      <b>Start Time:</b> 2004-04-01<br>

      <b>End Time:</b> 2004-04-24T23:59:59Z<br>
   </div>
    </p>
  </div>

  <a id='plotthumb-457-1' rel='node-457-plots' href='#plotthumb-457-1-fb'><img src="https://gsocial.ecs.nasa.gov/sites/default/files/imagecache/plot-thumbs/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_stddev_land_ocean.aavg_202031346180208_0.gif" alt="" title=""  class="imagecache imagecache-plot-thumbs" width="100" height="100" /></a><div style='display: none;'>  <div id='plotthumb-457-1-fb'>    <span class='node-plot' id='field_plotimg-457'><img  class="imagefield imagefield-field_plotimg image-annotate-field_plotimg" width="563" height="544" alt="" src="https://gsocial.ecs.nasa.gov/sites/default/files/formatted_DeepBlue-SeaWiFS-1.0_L3_20040401_v003-20111128T024332Z.hdf_.ncmlSWDB_L310_HDF4.003_aerosol_optical_thickness_550_stddev_land_ocean.aavg_202031346180208_0.gif?1346181795" /><hr>     </span>  </div></div>      <script type="text/javascript">
      $('#plotthumb-457-1').fancybox({
      'onComplete': function() {
        for (var i=0; i<Drupal.settings.imageAnnotate.length; i++) {
          var o = Drupal.settings.imageAnnotate[i];
          if (o.nid == '457' && o.field == 'field_plotimg') {
        annotativeImage = new Drupal.annotativeImage(o);
          }
        }
       },
      'onClose': function() {
        $('.image-annotate-edit-close').click();  
       }
    });
      </script>

    


<script type="text/javascript">
   $(document).ready(function () {
        $('.comment_add').css('margin-left', '50px');
        $('.comment_comments').css('margin-left', '50px');
   });
</script>                             

  <div class="frontpage-comments-block">
  </div>
</div>

  </div>
    </div>
  
  
  
  
  
  
</div>   </div>

  <div class="clear-block">

    <div class="meta">
        </div>

          <div class="links"><ul class="links inline"><li class="comment_add first last"><a href="/comment/reply/455#comment-form" title="Share your thoughts and opinions related to this posting.">Add new comment</a></li>
</ul></div>
      </div>

</div>

          </div>
          <a href="/node/455/feed" class="feed-icon"><img src="/misc/feed.png" alt="Syndicate content" title="Sprint-21-Tests (Pass)" width="16" height="16" /></a>          <div id="footer"></div>

      </div></div></div></div> <!-- /.left-corner, /.right-corner, /#squeeze, /#center -->

      
    </div> <!-- /container -->
  </div>
<!-- /layout -->

    <div>  <!--Outer div pair added because PIP script strips first div pair it encounters-->
    <div id="nasafoot">
        <a href="http://www.nasa.gov/" target="_blank"><img src="/sites/default/themes/gsocial/images/footer_nasa_logo.gif" style="margin:15px" width="52" height="42" alt="NASA Logo - nasa.gov" /></a>

        <div id="nasafootleft">
            <ul>
            <!-- <li>Note: This site uses persistant cookies.<br><br> -->
                <li>NASA Official: <a href="mailto:christopher.s.lynnes@nasa.gov" class="footerLnk">Christopher Lynnes</a></li>
                <li>Website Curator: <a href="mailto:daniel.e.dasilva@nasa.gov" class="footerLnk">Daniel da Silva</a><br />
                  <br /></li>
            </ul>

        </div>
    
        <div id="nasafootright">
            <ul>
                <li>+ <a href="http://www.nasa.gov/about/highlights/HP_Privacy.html" target="_blank">NASA Privacy Policy and Important Notices </a></li>
                <li><a href="http://disc.sci.gsfc.nasa.gov/contact.shtml" class="footerLnk">+ Contact Us</a></li>
            </ul>
                 <br />

            <ul>
                <li><!--#config timefmt="%B %d, %Y  %T %Z" -->Last updated: <!--#echo var="LAST_MODIFIED" --></li>
            </ul>
        </div>
        <!-- BEGIN: Use this section to set page specific variables for the NetTracker Page Tag -->
        <script type="text/javascript" language="JavaScript">
        // var NTPT_PGEXTRA = '';
        // var NTPT_PGREFTOP = false;
        // var NTPT_NOINITIALTAG = false;
        </script>
        <noscript>&#160;</noscript>

        <!-- END: Use this section to set page specific variables for the NetTracker Page Tag -->
        
        <!-- BEGIN: NetTracker Page Tag -->
        <!-- Copyright 2004 Sane Solutions, LLC.  All rights reserved. -->
        <script type="text/javascript" language="JavaScript" src="/common/js/ntpagetag.js">&#160;</script>
        <noscript>
        <img src="http://ws1.ems.eosdis.nasa.govhttp://disc.sci.gsfc.nasa.gov/images/ntpagetag.gif?js=0" height="1" width="1" border="0" hspace="0" vspace="0" alt="" />
        </noscript>
        <!-- END: NetTracker Page Tag -->
    </div>
</div>    </div>

  </body>
</html>
