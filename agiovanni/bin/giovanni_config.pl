#!/usr/bin/perl

=head1 NAME

giovanni_config.pl

=head1 DESCRIPTION

A command line interface to the Giovanni configuration file. Allows non-Perl
programs to access the configuration file.

=head1 SYNOPSIS

giovanni_config.pl PERL_CONFIG_VAR

=head1 EXAMPLES

$ giovanni_config.pl '$GIOVANNI::CACHE_DIR'

$ giovanni_config.pl '$GIOVANNI::SHAPEFILES{down_sampling}{area_avg_time_series}'

=head1 AUTHOR

Daniel da Silva <daniel.daSilva@nasa.gov>

=cut

use Safe;

my $rootPath;

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5/' )
        if defined $rootPath;
}

my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
my $cpt     = Safe->new('GIOVANNI');

unless ( $cpt->rdo($cfgFile) ) {
    die 'Configuration Error';
}

if ( scalar(@ARGV) == 0 ) {
    print STDERR "Usage: giovanni_config.pl PERL_CONFIG_VAR\n\n";
    print STDERR "Example:\n";
    print STDERR "  giovanni_config.pl '\$GIOVANNI::CACHE_DIR'\n";
}
else {
    my $expr      = '';
    my $noNewline = 0;

    foreach my $arg (@ARGV) {
        if ( $arg eq '-n' ) {
            $noNewline = 1;
        }
        elsif ( $expr eq '' ) {
            $expr = $arg;
        }
    }

    print eval($expr);
    print "\n" unless ($noNewline);
}
