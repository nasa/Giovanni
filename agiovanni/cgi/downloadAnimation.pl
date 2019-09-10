#!/usr/bin/perl -T

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}

use strict;
use Safe;
use Giovanni::CGI;
use URI;
use File::Basename;
use Giovanni::Plot;

# Disable output buffering
$| = 1;
## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };
# Configuration file for Giovanni: contains environment variables and input validation rules
my $cfgFile = ( defined $rootPath ? $rootPath : '/opt/giovanni4/' )
    . 'cfg/giovanni.cfg';
# Read the configuration file
my $error = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );


# Get user input
my $cgi = Giovanni::CGI->new(
    INPUT_TYPES     => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    QUERY => $ENV{'QUERY_STRING'},
);
my $sessionId = $cgi->param('session');
my $resultSetId = $cgi->param('resultset');
my $resultId = $cgi->param('result');

# Image directory is session directory
my $imgDir = $GIOVANNI::SESSION_LOCATION . '/'
    . join( '/', $sessionId, $resultSetId, $resultId );

# Set up download file name
(my $downloadFile) = glob("$imgDir/*animation.json");
$downloadFile = defined $downloadFile ? basename($downloadFile) : "downloadImages";
$downloadFile = ($downloadFile =~ /^((\w|-)+)/ ) ? $1 : 'downloadImages';

my $outType = 'application/x-download';

# If image array exists then zip up the image files

    zipFrames($downloadFile);


# Print cgi as type 'application/x-download'
print $cgi->header(
    -status                => 200,
    -type                  => $outType,
    -cache_control         => 'no-cache',
    -'Content-Disposition' => 'attachment; filename="'
        . "$downloadFile.zip" . '"',
    -'Content-Transfer-Encoding' => 'binary',
    -'Accept-Ranges'             => 'bytes'
);
print `/bin/cat $imgDir/$downloadFile.zip`;

exit;

sub zipFrames {
    my ($zipName) = @_;
    # Create zip compressed file containing images
    `zip -j /$imgDir/$zipName /$imgDir/*_frame.png`;

    # Gets rid of archive entries that contain "/$imgDir/session/*"
    `zip -d /$imgDir/$zipName $GIOVANNI::SESSION_LOCATION/* /$imgDir/session/*`;

}

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

=head1 NAME

downloadAnimation - this cgi script produces a zip file containing images (png) for the user requested animation frames

=head1 SYNOPSIS

perl -T downloadAnimation.pl 'data=&caption=&title=&delay=&SESSION=&RESULTSET=&RESULT=&SLD=&LAYERS=&TIME='

=head1 DESCRIPTION

This script looks for images in the session directory and if they do not exist, builds them. Finally, the script produces a zip aarchive of the image files.

=head2 Parameters

=over 10

=item caption

The plot caption.

=item title

The plot title.

=item delay

The animation delay in seconds (optional)

=item SESSION

The session directory name.

=item RESULT

The result directory name.

=item RESULTSET

The result set directory name.

=item SLD

The name of the SLD file used to render the colorbar image.

=item LAYERS

The layer variable name of the plot image.

=item TIME

The timestamp of the image.

=back

=cut

