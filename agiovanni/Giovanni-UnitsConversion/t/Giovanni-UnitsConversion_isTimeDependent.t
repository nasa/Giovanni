#$Id: Giovanni-UnitsConversion_isTimeDependent.t,v 1.2 2015/03/17 17:01:29 csmit Exp $
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

my $dir = tempdir( CLEANUP => 1 );

my $conversionCfg = <<XML;
<units>
    <linearConversions>
        <linearUnit source="mm/day" destination="mm/hr" scale_factor="1.0/24.0"
            add_offset="0" />
        <linearUnit source="mm/day" destination="inch/day"
            scale_factor="1.0/25.4" add_offset="0" />
    </linearConversions>
    <nonLinearConversions>
        <timeDependentUnit source="mm/hr" destination="mm/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation" />
    </nonLinearConversions>
</units>
XML
my $cfg = "$dir/cfg.xml";
open( CFG, ">", $cfg );
print CFG $conversionCfg;
close(CFG);

my $converter = Giovanni::UnitsConversion->new( config => $cfg, );
ok( $converter->isTimeDependent(
        sourceUnits      => 'mm/hr',
        destinationUnits => 'mm/month'
    ),
    'Is time dependent'
);

ok( !$converter->isTimeDependent(
        sourceUnits      => 'mm/day',
        destinationUnits => 'mm/hr'
    ),
    'Is not time dependent'
);

1;
