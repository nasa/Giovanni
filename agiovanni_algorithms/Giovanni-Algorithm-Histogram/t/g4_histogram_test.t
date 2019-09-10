#!/usr/bin/perl -w
#
# This is a wrapper around g4_histogram_test.py. It exists because the
# build/test system is only capable of running Perl tests.

use strict;

use Cwd 'abs_path';
use File::Basename;
use Test::Simple tests => 1;

print "\n";

my $path    = dirname( abs_path($0) ) . '/g4_histogram_test.py';
my $rc      = system("python $path -v");
my $success = ( $rc == 0 );

ok($success);
