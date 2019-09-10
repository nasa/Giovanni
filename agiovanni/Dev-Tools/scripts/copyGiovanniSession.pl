#!/usr/bin/perl

#$Id: copyGiovanniSession.pl,v 1.2 2015/06/22 15:38:19 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

=head1 NAME

copyGiovanniSession.pl - copies all the files needed to run a session

=head1 SYNOPSIS

copyGiovanniSession.pl /var/tmp/www/TS2/giovanni/D0189774-4563-11E3-8F1B-FC409CC6DBD3/DC98C104-4563-11E3-BC0F-06419CC6DBD3/DC98DA2C-4563-11E3-BC0F-06419CC6DBD3/ /var/tmp/csmit/session/

=head1 DESCRIPTION



=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut

use 5.008008;
use strict;
use warnings;

use Cwd 'abs_path';
use File::Copy;

if ( scalar(@ARGV) == 0 ) {
    print STDERR "Usage: $0 <start directory> <end directory>\n";
    exit(0);
}

my $startPath = $ARGV[0];
my $endPath   = $ARGV[1];

if ( !( -d $startPath ) ) {
    die "Can't find directory $startPath";
}
if ( !( -d $endPath ) ) {
    die "Can't find directory $endPath";
}

print("Copying session $startPath to $endPath.\n");

$startPath = abs_path($startPath);
$endPath   = abs_path($endPath);

my @filenames = ( "Makefile", "input.xml" );
opendir( DIR, $startPath ) or die "Unable to read directory: $!";
while ( my $file = readdir(DIR) ) {

    # skip directories
    next if ( -d "$startPath/$file" );

    # get all the .make files
    if ( $file =~ m/[.]make$/ ) {
        push( @filenames, $file );
    }
}

# copy files
for my $file (@filenames) {
    print("Copying $file to $endPath.\n");
    copy( "$startPath/$file", "$endPath/$file" ) or die "Copy fails: $!";
}

# now edit Makefile
open( FILE, "$endPath/Makefile" ) or die "$!";
my @lines = <FILE>;
close(FILE);

my $makefile = join( "", @lines );

$makefile =~ s/SESSION_DIR = .*/SESSION_DIR = $endPath/;

open( FILE, ">", "$endPath/Makefile" ) or die "$!";
print FILE $makefile;
close(FILE);

1;
