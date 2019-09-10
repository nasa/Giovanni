# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Giovanni-OGC-SLD.t'

#########################

use Test::More tests => 74;
use File::Basename;
BEGIN { use_ok('Giovanni::OGC::SLD') }

#########################

use strict;
use warnings;

########
# Test Giovanni::OGC::SLD::_calculateThresholds
########
my @thresholds;

@thresholds = Giovanni::OGC::SLD::_calculateThresholds(
    MIN       => 0,
    MAX       => 9,
    SCALETYPE => 'linear',
    NCLASS    => 9
);
check_arr(
    \@thresholds,
    [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
    "simple linear thresholds"
);

@thresholds = Giovanni::OGC::SLD::_calculateThresholds(
    MIN       => 1,
    MAX       => 4,
    SCALETYPE => 'linear',
    NCLASS    => 6
);
check_arr(
    \@thresholds,
    [ 1, 1.5, 2, 2.5, 3, 3.5, 4 ],
    "simple linear thresholds"
);

@thresholds = Giovanni::OGC::SLD::_calculateThresholds(
    MIN       => 1,
    MAX       => 1000,
    SCALETYPE => 'log',
    NCLASS    => 3
);
check_arr( \@thresholds, [ 1, 10, 100, 1000 ], "simple log thresholds" );

@thresholds = Giovanni::OGC::SLD::_calculateThresholds(
    MIN       => 1,
    MAX       => 100,
    SCALETYPE => 'log',
    NCLASS    => 4
);
check_arr(
    \@thresholds,
    [ 1, 10**0.5, 10, 10**1.5, 100 ],
    "simple log thresholds"
);

########
# Test the Giovanni::OGC::SLD::_rounding function
########
is( Giovanni::OGC::SLD::_round(1.3),  1,  'Basic rounding: 1.3' );
is( Giovanni::OGC::SLD::_round(-1.3), -1, 'Basic rounding: -1.3' );
is( Giovanni::OGC::SLD::_round( -1.3, TYPE => 'floor' ),
    -2, 'floor rounding: -1.3' );
is( Giovanni::OGC::SLD::_round( -1.3, TYPE => 'ceil' ),
    -1, 'ceiling rounding: -1.3' );
is( Giovanni::OGC::SLD::_round( 1.1234, TYPE => 'ceil', POSITION => -2 ),
    1.13, 'ceiling 1/hundreds rounding: 1.13' );
is( Giovanni::OGC::SLD::_round( 1234.1234, TYPE => 'floor', POSITION => 2 ),
    1200, 'floor hundreds rounding: 1234.1234' );

########
# Test Giovanni::OGC::SLD::_findMostSigFig function
########
is( Giovanni::OGC::SLD::_findMostSigFig(3),     0,  "Sig fig: 3" );
is( Giovanni::OGC::SLD::_findMostSigFig(52),    1,  "Sig fig: 1" );
is( Giovanni::OGC::SLD::_findMostSigFig(0.456), -1, "Sig fig: -1" );
is( Giovanni::OGC::SLD::_findMostSigFig(0.023), -2, "Sig fig: -2" );
is( Giovanni::OGC::SLD::_findMostSigFig(-0.023),
    -2, "Sig fig: -2, negative number" );

########
# Test Giovanni::OGC::SLD::_getMantissa
########
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 1234,
        NDIGIT   => 5,
        EXPONENT => 2,
        ROUND    => 'nearest'
    ),
    "12.34",
    "mantissa: 12.34x10^2"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 1234,
        NDIGIT   => 3,
        EXPONENT => 2,
        ROUND    => 'nearest'
    ),
    "12.3",
    "mantissa: 12.3x10^2"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 1234,
        NDIGIT   => 3,
        EXPONENT => 2,
        ROUND    => 'ceil'
    ),
    "12.4",
    "mantissa: 12.4x10^2"
);

is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 1234,
        NDIGIT   => 3,
        EXPONENT => 2,
        ROUND    => 'nearest'
    ),
    "12.3",
    "mantissa: 12.3x10^2"
);

is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 0,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'ceil'
    ),
    "0",
    "mantissa: 0 (ceil)"
);

is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => -1.2345,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'ceil'
    ),
    "-1.234",
    "mantissa: -1.234 (ceil)"
);

# This next set of _getMantissa tests basically slides the same number
# (123456)to the right to make sure we start rounding where we should start
# rounding.

is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 12345.6,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'floor'
    ),
    "XXXX",
    "mantissa (weird request): XXXX"
);

is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 1234.56,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'floor'
    ),
    "1234",
    "mantissa: 1234"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 123.456,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'floor'
    ),
    "123.4",
    "mantissa: 123.4"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 12.3456,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'floor'
    ),
    "12.34",
    "mantissa: 12.34"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 1.23456,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'floor'
    ),
    "1.234",
    "mantissa: 1.234"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => .123456,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'floor'
    ),
    "0.123",
    "mantissa: 0.123"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => .0123456,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'floor'
    ),
    "0.012",
    "mantissa: 1234"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 0.00123456,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'floor'
    ),
    "0.001",
    "mantissa: 0.001"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 0.000123456,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'floor'
    ),
    "0",
    "mantissa: 0"
);
is( Giovanni::OGC::SLD::_getMantissa(
        NUMBER   => 0.000123456,
        NDIGIT   => 4,
        EXPONENT => 0,
        ROUND    => 'ceil'
    ),
    "0.001",
    "mantissa: 0.001 (ceil)"
);

########
# Test Giovanni::OGC::SLD::_getBestExponent
########
is( Giovanni::OGC::SLD::_getBestExponent( NUMBER => 12345.6, NDIGIT => 4 ),
    4, "12345.6 exponent" );
is( Giovanni::OGC::SLD::_getBestExponent( NUMBER => 1234.56, NDIGIT => 4 ),
    0, "1234.56 exponent" );
is( Giovanni::OGC::SLD::_getBestExponent( NUMBER => 123.456, NDIGIT => 4 ),
    0, "123.456 exponent" );
is( Giovanni::OGC::SLD::_getBestExponent( NUMBER => 12.3456, NDIGIT => 4 ),
    0, "12.3456 exponent" );
is( Giovanni::OGC::SLD::_getBestExponent( NUMBER => 1.23456, NDIGIT => 4 ),
    0, "1.23456 exponent" );
is( Giovanni::OGC::SLD::_getBestExponent( NUMBER => .123456, NDIGIT => 4 ),
    -1, ".123456 exponent" );
is( Giovanni::OGC::SLD::_getBestExponent( NUMBER => .0123456, NDIGIT => 4 ),
    -2, ".0123456 exponent" );
is( Giovanni::OGC::SLD::_getBestExponent( NUMBER => .00123456, NDIGIT => 4 ),
    -3,
    ".00123456 exponent"
);

########
# Test Giovanni::OGC::SLD::_convertToFiniteRepresentation
########
my ( $mantissas, $exponents );

( $mantissas, $exponents )
    = Giovanni::OGC::SLD::_convertToFiniteRepresentation(
    THRESHOLDS => [ 0, 1, 2 ],
    NDIGIT     => 3
    );
is_deeply(
    $mantissas,
    [ "0", "1", "2" ],
    "Simple threshold conversion: mantissas " . join( " ", @{$mantissas} )
);
is_deeply( $exponents, [0],
    "Simple threshold conversion: exponents " . join( " ", @{$exponents} ) );

( $mantissas, $exponents )
    = Giovanni::OGC::SLD::_convertToFiniteRepresentation(
    THRESHOLDS => [ 0.0000001, 1, 2 ],
    NDIGIT     => 3
    );
is_deeply(
    $mantissas,
    [ "1", "1", "2" ],
    "Threshold conversion: mantissas " . join( " ", @{$mantissas} )
);
is_deeply(
    $exponents,
    [ -7, 0, 0 ],
    "Threshold conversion: exponents " . join( " ", @{$exponents} )
);

# first number should round down, middle numbers should round to nearest, top
# number should round up.
( $mantissas, $exponents )
    = Giovanni::OGC::SLD::_convertToFiniteRepresentation(
    THRESHOLDS => [ 1.777, 50.785, 90.342, 300.0000001 ],
    NDIGIT     => 3
    );
is_deeply(
    $mantissas,

    [ "1.77", "50.8", "90.3", "301" ],
    "Threshold conversion: mantissas " . join( " ", @{$mantissas} )
);
is_deeply( $exponents, [0],
    "Threshold conversion: exponents " . join( " ", @{$exponents} ) );

# make sure this works for negative numbers
( $mantissas, $exponents )
    = Giovanni::OGC::SLD::_convertToFiniteRepresentation(
    THRESHOLDS => [ -10000.02, -7800.80923, -3074, 10056 ],
    NDIGIT     => 3
    );
is_deeply(
    $mantissas,

    [ "-1.01", "-0.78", "-0.31", "1.01" ],
    "Threshold conversion: mantissas " . join( " ", @{$mantissas} )
);
is_deeply( $exponents, [4],
    "Threshold conversion: exponents " . join( " ", @{$exponents} ) )
    ;

sub check_arr {
    my ( $test, $correct, $testName ) = @_;

    my $acceptableDiff = 1e-4;

    if (!is(scalar( @{$test} ),
            scalar( @{$correct} ),
            "$testName: arrays are different lengths"
        )
        )
    {
        return;
    }
    for ( my $i = 0; $i < scalar( @{$test} ); $i++ ) {
        ok( abs( $test->[$i] - $correct->[$i] ) <= $acceptableDiff,
            "$testName: index $i correct (got $test->[$i], expected $correct->[$i])"
        );
    }

}

