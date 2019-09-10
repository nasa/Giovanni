#$Id: Giovanni-UnitsConversion_getAllDestinationUnits.t,v 1.2 2015/04/09 19:20:31 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-UnitsConversion.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Giovanni::UnitsConversion') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use warnings;
use strict;
use Giovanni::Data::NcFile;
use File::Temp qq/tempdir/;
use List::MoreUtils qq/uniq/;

my $dir = tempdir( CLEANUP => 1 );

my $conversionCfg = <<XML;
<units>
    <linearConversions>
        <linearUnit source="mm/hr" destination="mm/day"
            scale_factor="24" add_offset="0" />
        <linearUnit source="mm/hr" destination="inch/hr"
            scale_factor="1.0/25.4" add_offset="0" />
        <linearUnit source="mm/hr" destination="inch/day"
            scale_factor="24.0/25.4" add_offset="0" />
        <linearUnit source="mm/day" destination="mm/hr"
            scale_factor="1.0/24.0" add_offset="0" />
        <linearUnit source="mm/day" destination="inch/day"
            scale_factor="1.0/25.4" add_offset="0" />
        <linearUnit source="kg/m^2" destination="mm" scale_factor="1"
            add_offset="0" />
        <linearUnit source="K" destination="C" scale_factor="1"
            add_offset="-273.15" />
        <linearUnit source="kg/m^2/s" destination="mm/s"
            scale_factor="1" add_offset="0" />
        <linearUnit source="molecules/cm^2" destination="DU"
            scale_factor="1.0/2.6868755e+16" add_offset="0" />
    </linearConversions>
    <nonLinearConversions>
        <timeDependentUnit source="mm/hr" destination="mm/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="24.0" temporalResolutions="monthly"/>
        <timeDependentUnit source="mm/hr" destination="inch/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="24.0/25.4" temporalResolutions="monthly"/>
        <timeDependentUnit source="mm/hr" destination="inch/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="86400.0" temporalResolutions="monthly"/>
    </nonLinearConversions>
    <fileFriendlyStrings>
        <destinationUnit original="mm/day" file="mmPday" />
        <destinationUnit original="inch/hr" file="inPhr" />
        <destinationUnit original="inch/day" file="inPday" />
        <destinationUnit original="mm/hr" file="mmPhr" />
        <destinationUnit original="mm" file="mm" />
        <destinationUnit original="mm/s" file="mmPs" />
        <destinationUnit original="DU" file="DU" />
        <destinationUnit original="mm/month" file="mmPmon" />
        <destinationUnit original="inch/month" file="inPmon" />
    </fileFriendlyStrings>
</units>
XML
my $cfg = "$dir/cfg.xml";
open( CFG, ">", $cfg );
print CFG $conversionCfg;
close(CFG);

my @destinationUnits
    = Giovanni::UnitsConversion::getAllDestinationUnits( config => $cfg );

# make sure destination units are unique
my @uniqueUnits = uniq(@destinationUnits);
is( scalar(@destinationUnits), scalar(@uniqueUnits), "Units are unique" );

my @correct = (
    'C',          'DU', 'inch/day', 'inch/hr',
    'inch/month', 'mm', 'mm/day',   'mm/hr',
    'mm/month',   'mm/s'
);

is_deeply( \@destinationUnits, \@correct, "Got the right destination units" );
1;
