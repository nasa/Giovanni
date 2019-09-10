#$Id: extendLongitudeAcrossDateline.t,v 1.1 2014/11/06 20:45:07 clynnes Exp $
#-@@@ Giovanni, Version 4

=head1 SYNOPSIS
This tests the version of grid normalizer that simply "extends" lons across the dateline.
=cut

use strict;
use File::Temp qw/ tempfile tempdir /;
use Test::More tests => 5;
use Cwd 'abs_path';
use Giovanni::Data::NcFile;
use FindBin qw($Bin);

my $script = findScript("extendLongitude.pl");
ok( -r $script, "Found script" );

# create a temporary directory for everything

my $dir = ( exists $ENV{SAVEDIR} ) ? $ENV{SAVEDIR} : tempdir( CLEANUP => 1 );

# write the netcdf there
my $cdl = readCdlData();
my @cdl = ( $cdl =~ m/(netcdf.*?\})/sg );
my $inNcFile
    = "$dir/dimensionAveraged.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20080101-20080104.163E_14N_167W_20N.nc";
Giovanni::Data::NcFile::write_netcdf_file( $inNcFile, $cdl[0] ) or die $?;

# create the input manifest file
my $inManifest = "$dir/mfst.in+whatever.xml";
my $xml        = <<QUOTE;
<manifest >
  <fileList id="MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean">
    <file>$inNcFile</file>
  </fileList>
</manifest>
QUOTE
open( FILE, ">", $inManifest );
print FILE $xml;
close(FILE);

my $outManifest = "$dir/mfst.out+whatever.xml";
my $outNcFile
    = "$dir/dimensionAveragedWorldLon.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20080101-20080104.163E_14N_167W_20N.nc";

my $cmd
    = "$script --across-dateline --in-file $inManifest --out-file $outManifest";

my $ret = system($cmd);

ok( $ret == 0, "Command returned 0:$cmd" ) or die;

ok( -f $outManifest, "Output manifest file exists" ) or die;

# parse the output manifest file
my $parser   = XML::LibXML->new();
my $dom      = $parser->parse_file($outManifest);
my $xpDom    = XML::LibXML::XPathContext->new($dom);
my @outFiles = map( $_->nodeValue, $xpDom->findnodes("//file/text()") );

is_deeply( \@outFiles, [$outNcFile], "Correct output data file" ) or die;
ok( -f $outNcFile, "Output data file exists" ) or die;

sub findScript {
    my ($scriptName) = @_;

    # see if this is just next door (Christine's eclipse configuration)
    my $script = "../scripts/$scriptName";

    unless ( -f $script ) {

        # see if we can find the script relative to our current location
        $script = "blib/script/$scriptName";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script );
            $script = "../$script";
        }
    }

    return $script;
}

sub readCdlData {

    # read block at __DATA__ and write to a CDL file
    #(stolen from Chris...)
    my @cdldata;
    while (<DATA>) {
        push @cdldata, $_;
    }
    return ( join( '', @cdldata ) );
}

__DATA__
netcdf dimensionAveraged.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20080101-20080104.163E_14N_167W_20N {
dimensions:
	time = UNLIMITED ; // (4 currently)
	lon = 29 ;
variables:
	double MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lon) ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target)" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
	float lon(lon) ;
		lon:units = "degrees_east" ;
		lon:long_name = "Longitude" ;
		lon:standard_name = "longitude" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2008-01-01T00:00:00Z" ;
		:end_time = "2008-01-04T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Nov  5 19:53:22 2014: ncks -O -d lat,14.7656,20.3906 -d lon,163.8281,-167.3437 /var/tmp/www/TS2/giovanni/391007E0-6524-11E4-8589-22E0C063D817/564230C6-6525-11E4-A1B2-F42BC163D817/56424A84-6525-11E4-A1B2-F42BC163D817//scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20080101.nc scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20080101.nc.subset" ;
		:NCO = "4.3.1" ;
data:

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, 0.14, 0.167911772396702, 0.163772923766195, 0.169324505546324, 
    0.211319383407316, 0.212649980637135, 0.207340663717038, 
    0.194333106040302, 0.228828366612868, 0.24210377475414, 
    0.235747563746719, 0.249817869609899, 0.238718424723698, 
    0.234260408222318, 0.196, _, _, 0.236793248192802, 0.21242474272828, 
    0.213528464012371, 0.206783715525546, 0.202666002366106, 
    0.187018763928827, 0.205335770838711, _, 0.180583830033686, 
    0.162005681671481, 0.158112136690654,
  0.159989622446739, 0.166833506346195, 0.179119898351206, 0.202109041725154, 
    0.189, _, _, _, 0.213594254874607, 0.201920419925401, 0.185880331934238, 
    0.184623612008031, 0.190862364221996, 0.197665845191167, _, _, 
    0.165816733527943, 0.181221925857285, 0.206057243108082, 
    0.218735991574315, 0.237975506701219, 0.242062090486644, 
    0.24001389783862, 0.234961673924221, 0.230485603981412, 
    0.224998830699143, 0.232516042104593, 0.222023205941501, 0.218227636344478,
  _, _, _, _, 0.107, 0.121479692916702, 0.127606255982104, 0.17494010309092, 
    0.196306026553709, 0.173955297363357, 0.175356042383606, 
    0.184428384330352, 0.214186583402099, 0.205050940320311, 
    0.213087180664057, 0.219051213554783, 0.217369247155293, 
    0.197636467690034, 0.208, _, _, _, 0.210331160154021, 0.239735187543854, 
    0.200051935111033, 0.190378400503092, 0.173823484616464, 
    0.138383676624468, _,
  0.133924553311863, 0.134525449302208, 0.129079141134775, 0.125096355839009, 
    0.11103222682625, 0.0989623002208994, 0.0779809595188982, 
    0.098963941181391, _, _, _, 0.127335161557474, 0.145016860204755, 0.192, 
    0.197, 0.237, _, _, _, _, _, _, _, 0.256443479688978, 0.202228466528405, 
    0.195316946281907, 0.246339142507281, 0.213885521100224, 0.189489677979047 ;

 lon = 164.5, 165.5, 166.5, 167.5, 168.5, 169.5, 170.5, 171.5, 172.5, 173.5, 
    174.5, 175.5, 176.5, 177.5, 178.5, 179.5, -179.5, -178.5, -177.5, -176.5, 
    -175.5, -174.5, -173.5, -172.5, -171.5, -170.5, -169.5, -168.5, -167.5 ;

 time = 1199145600, 1199232000, 1199318400, 1199404800 ;
}
netcdf acrossDateline {
dimensions:
	lon = 29 ;
	time = UNLIMITED ; // (4 currently)
variables:
	float lon(lon) ;
		lon:long_name = "Longitude" ;
		lon:standard_name = "longitude" ;
		lon:units = "degrees_east" ;
	double MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean(time, lon) ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:_FillValue = -9999. ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:long_name = "Aerosol Optical Depth 550 nm (Dark Target)" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:units = "1" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Level_2_Pixel_Values_Read_As = "Real" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Derived_From_Level_2_Data_Set = "Optical_Depth_Land_And_Ocean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Included_Level_2_Nighttime_Data = "False" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Quality_Assurance_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Statistic_Type = "Simple" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:Aggregation_Data_Set = "None" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:standard_name = "optical_depth_land_and_ocean_mean" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:quantity_type = "Total Aerosol Optical Depth" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_short_name = "MOD08_D3" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:product_version = "051" ;
		MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean:coordinates = "time lat lon" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:start_time = "2008-01-01T00:00:00Z" ;
		:end_time = "2008-01-04T23:59:59Z" ;
		:temporal_resolution = "daily" ;
		:nco_openmp_thread_number = 1 ;
		:history = "Wed Nov  5 19:58:47 2014: ncap2 -s where (lon < 0.) lon = lon + 360. dimensionAveraged.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20080101-20080104.163E_14N_167W_20N.nc out.nc\n",
			"Wed Nov  5 19:53:22 2014: ncks -O -d lat,14.7656,20.3906 -d lon,163.8281,-167.3437 /var/tmp/www/TS2/giovanni/391007E0-6524-11E4-8589-22E0C063D817/564230C6-6525-11E4-A1B2-F42BC163D817/56424A84-6525-11E4-A1B2-F42BC163D817//scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20080101.nc scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20080101.nc.subset" ;
		:NCO = "4.3.1" ;
data:

 lon = 164.5, 165.5, 166.5, 167.5, 168.5, 169.5, 170.5, 171.5, 172.5, 173.5, 
    174.5, 175.5, 176.5, 177.5, 178.5, 179.5, 180.5, 181.5, 182.5, 183.5, 
    184.5, 185.5, 186.5, 187.5, 188.5, 189.5, 190.5, 191.5, 192.5 ;

 MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean =
  _, 0.14, 0.167911772396702, 0.163772923766195, 0.169324505546324, 
    0.211319383407316, 0.212649980637135, 0.207340663717038, 
    0.194333106040302, 0.228828366612868, 0.24210377475414, 
    0.235747563746719, 0.249817869609899, 0.238718424723698, 
    0.234260408222318, 0.196, _, _, 0.236793248192802, 0.21242474272828, 
    0.213528464012371, 0.206783715525546, 0.202666002366106, 
    0.187018763928827, 0.205335770838711, _, 0.180583830033686, 
    0.162005681671481, 0.158112136690654,
  0.159989622446739, 0.166833506346195, 0.179119898351206, 0.202109041725154, 
    0.189, _, _, _, 0.213594254874607, 0.201920419925401, 0.185880331934238, 
    0.184623612008031, 0.190862364221996, 0.197665845191167, _, _, 
    0.165816733527943, 0.181221925857285, 0.206057243108082, 
    0.218735991574315, 0.237975506701219, 0.242062090486644, 
    0.24001389783862, 0.234961673924221, 0.230485603981412, 
    0.224998830699143, 0.232516042104593, 0.222023205941501, 0.218227636344478,
  _, _, _, _, 0.107, 0.121479692916702, 0.127606255982104, 0.17494010309092, 
    0.196306026553709, 0.173955297363357, 0.175356042383606, 
    0.184428384330352, 0.214186583402099, 0.205050940320311, 
    0.213087180664057, 0.219051213554783, 0.217369247155293, 
    0.197636467690034, 0.208, _, _, _, 0.210331160154021, 0.239735187543854, 
    0.200051935111033, 0.190378400503092, 0.173823484616464, 
    0.138383676624468, _,
  0.133924553311863, 0.134525449302208, 0.129079141134775, 0.125096355839009, 
    0.11103222682625, 0.0989623002208994, 0.0779809595188982, 
    0.098963941181391, _, _, _, 0.127335161557474, 0.145016860204755, 0.192, 
    0.197, 0.237, _, _, _, _, _, _, _, 0.256443479688978, 0.202228466528405, 
    0.195316946281907, 0.246339142507281, 0.213885521100224, 0.189489677979047 ;

 time = 1199145600, 1199232000, 1199318400, 1199404800 ;
}
