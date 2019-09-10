# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DataAccess-Translator.t'

#########################

use Test::More tests => 2;
BEGIN { use_ok('DataAccess::Translator') }

#########################

my $dataUrl
    = qq(ftp://acdisc.gsfc.nasa.gov/data/s4pa///Aqua_AIRS_Level3/AIRX3STD.006/2006/AIRS.2006.01.01.L3.RetStd001.v6.0.9.0.G13140214834.hdf);
my $opendapUrl
    = qq(http://acdisc.gsfc.nasa.gov/opendap/Aqua_AIRS_Level3/AIRX3STD.006/2006/AIRS.2006.01.01.L3.RetStd001.v6.0.9.0.G13140214834.hdf.html);

my @inUrlList  = ($dataUrl);
my $translator = DataAccess::Translator->new(
    TARGET_URL => $opendapUrl,
    SOURCE_URL => $dataUrl
);
my @outUrlList = $translator->translate(@inUrlList);
is( $outUrlList[0], $opendapUrl, "Input URL mapped correctly" );
