#!/usr/bin/perl -T
#$Id: downloadPlot.pl,v 1.10 2015/04/23 22:40:31 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use strict;
use Safe;
use File::Basename;
use Giovanni::Util;
use Giovanni::CGI;
use Giovanni::Plot;

# Disable output buffering
$| = 1;

# Unset PATH and ENV (needed for taint mode)
$ENV{PATH} = undef;
$ENV{ENV}  = undef;

# Configuration file for Giovanni: contains environment variables and input validation rules
my $cfgFile = ( defined $rootPath ? $rootPath : '/opt/giovanni4/' )
    . 'cfg/giovanni.cfg';

# Read the configuration file
my $error = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# Create a CGI object
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS =>
        [ 'image' ]
    ,
);

# Validate user input; first to satisfy taint mode and later with stricter rules
my $caption = $cgi->param('caption');
$caption = $caption =~ /^(.+)$/ ? quotemeta($1) : undef;
my $title = $cgi->param('title');
$title = $title =~ /^(.+)$/ ? quotemeta($1) : undef;
my $image = $cgi->param('image');

# We check for an existing image file later; hence, it is safe to let any value through
$image = $image =~ /^(.+)$/ ? $1 : undef;

# Convert image URL to local path
my $imgFile
    = Giovanni::Util::convertUrlToFilePath( $image, \%GIOVANNI::URL_LOOKUP );
exit_with_error("Image file not found") unless ( -f $imgFile );
my $plot = Giovanni::Plot->new();
$plot->addCaption($caption) if ( defined $caption && $caption =~ /\S+/ );
$plot->addTitle($title) if ( defined $title && $title =~ /\S+/ );
$plot->addImage($imgFile) if ( defined $imgFile );
my $outFile = $plot->renderPNG();
my $outType = 'image/png';
my $outName = 'GIOVANNI-' . basename($outFile);

print $cgi->header(
    -status                      => 200,
    -type                        => $outType,
    -cache_control               => 'no-cache',
    -'Content-Disposition'       => 'attachment; filename="' . $outName . '"',
    -'Content-Transfer-Encoding' => 'binary',
    -'Accept-Ranges'             => 'bytes'
);
print `/bin/cat $outFile`;
exit;

# A method to exit with 404 HTTP header with appropriate message
sub exit_with_error {
    my ($message) = @_;
    print $cgi->header(
        -status        => 404,
        -type          => 'text/plain',
        -cache_control => 'no-cache'
    );
    print $message;
    exit;
}
