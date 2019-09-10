#$Id: Giovanni-UnitsConversion_valuesConversion.t,v 1.5 2015/04/07 17:30:55 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-UnitsConversion.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Giovanni::UnitsConversion') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

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
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="24.0" />
    </nonLinearConversions>
</units>
XML
my $cfg = "$dir/cfg.xml";
open( CFG, ">", $cfg );
print CFG $conversionCfg;
close(CFG);

my @values = ( 24.0, 48.0 );

my %ret = Giovanni::UnitsConversion::valuesConvert(
    config           => $cfg,
    sourceUnits      => "mm/day",
    destinationUnits => "mm/hr",
    "values"         => \@values
);

ok( $ret{"success"}, 'Linear conversion happened' );
is_deeply( $ret{"values"}, [ 1.0, 2.0 ], "Conversion correct" );

%ret = Giovanni::UnitsConversion::valuesConvert(
    config           => $cfg,
    sourceUnits      => 'mm/hr',
    destinationUnits => 'mm/month',
    "values"         => [ 1.0, 2.0 ]
);

ok( $ret{"success"}, 'Monthly conversion happened' );
is_deeply( $ret{"values"}, [ 720.0, 1440.0 ], 'Monthly conversion correct' );

# now do a conversion that should fail
%ret = Giovanni::UnitsConversion::valuesConvert(
    config           => $cfg,
    sourceUnits      => 'mm/hr',
    destinationUnits => 'not a real unit',
    "values"         => [ 1.0, 2.0 ]
);
ok( !$ret{"success"}, "Failed conversion" );

1;
