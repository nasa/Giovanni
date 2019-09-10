#!/usr/bin/perl

=head1 NAME

downloadRequestData.pl - Download data from a G4 request url

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

downloadRequestData.pl [--help] requestUrl downloadDir

=head1 DESCRIPTION

This program downloads the data files produced by the G4 request url specified
in the first argument to a directory specified in the second argument.

=head1 OPTIONS

=over 4

=item --help
Print usage information

=back

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=cut

use strict;
use Getopt::Long;
use Giovanni::Agent;

$| = 1;
my $help;
my $debug;
my $download_data;
my $download_images;
my $download_lineage;

my $result = Getopt::Long::GetOptions(
    "help"    => \$help,
    "debug"   => \$debug,
    "data"    => \$download_data,
    "images"  => \$download_images,
    "lineage" => \$download_lineage
);

my $usage
    = "Usage: $0 [--help] requestUrl downloadDir\n"
    . "       --data     Download data files.\n"
    . "       --images   Download image files.\n"
    . "       --lineage  Download lineage files.\n"
    . "       --debug    Display debugging and progress information.\n"
    . "       --help     Display this help and exit.\n";

if ($help) {
    print STDERR $usage;
    exit 0;
}

my $request_url  = $ARGV[0];
my $download_dir = $ARGV[1];

die "$usage" unless $request_url && $download_dir;
die "Writeable directory $download_dir not found\n"
    unless ( -d $download_dir ) && ( -w $download_dir );

unless ( $download_data || $download_images || $download_lineage ) {
    die "At least one download option (--data, --images, --lineage)"
        . "must be specified\n$usage";
}

my $agent = Giovanni::Agent->new( URL => $request_url, DEBUG => $debug );
die "Agent not created\n" unless $agent;
die "Error creating agent: ", $agent->errorMessage, "\n" if $agent->onError;

my $requestResponse = $agent->submit_request;
my $downloadResponse;
die $requestResponse->message . "\n"
    unless $requestResponse->is_success;
if ($download_data) {
    $downloadResponse = $requestResponse->download_data_files(
        DIR   => $download_dir,
        DEBUG => $debug
    );
    die $downloadResponse->message . "\n"
        unless $downloadResponse->is_success;
}
if ($download_images) {
    $downloadResponse = $requestResponse->download_image_files(
        DIR   => $download_dir,
        DEBUG => $debug
    );
    die $downloadResponse->message . "\n"
        unless $downloadResponse->is_success;
}
if ($download_lineage) {
    $downloadResponse = $requestResponse->download_lineage_files(
        DIR   => $download_dir,
        DEBUG => $debug
    );
    die $downloadResponse->message . "\n"
        unless $downloadResponse->is_success;
}

exit 0;
