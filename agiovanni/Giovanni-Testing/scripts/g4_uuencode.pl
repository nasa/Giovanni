#!/usr/bin/env perl

=head1 NAME

g4_uuencode.pl - uuencode a file

=head1 SYNOPSIS

g4_uuencode.pl infile outfile

=head1 DESCRIPTION

Uuencode a file. This is useful for transforming binary files, such as GIF, to an ASCII
form that can be safely saved in CVS as part of a test program.

=head1 AUTHOR

Chris Lynnes

=cut

use strict;
use Giovanni::Testing;

my $input_file  = shift @ARGV or usage();
my $output_file = shift @ARGV or usage();
my $rc = Giovanni::Testing::uuencode( $input_file, $output_file );
exit !$rc;

sub usage {
    die "Usage: $0 infile outfile\n";
}
