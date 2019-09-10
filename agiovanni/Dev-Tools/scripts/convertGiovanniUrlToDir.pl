#!/usr/bin/perl

#$Id: convertGiovanniUrlToDir.pl,v 1.3 2015/02/05 15:28:26 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

use strict;
use URI;
use Safe;
use CGI;
use File::Basename;

# Parser URL
my $uri = URI->new( $ARGV[0] );
die "Failed to parse URL" unless defined $uri;

# Find the URL host and path
my $path = $uri->path();
my $host = $uri->host();

# Try to find out the base UNIX directory for URL's document root
my $baseDir = undef;
if ( $path =~ /~([^\/]+)/ ) {

    # If path contains the pattern, '~<user>', it is a user sandbox URL
    $baseDir = dirname( $ENV{HOME} ) . '/' . $1 . '/public_html/';
}
elsif ( $host =~ /-(TS[1-2])/i ) {

    # Look for TS2/TS1 in the URL
    my $mode = uc($1);
    if ( $mode eq 'TS2' ) {
        $baseDir = '/tools/gdaac/TS2/';
    }
    elsif ( $mode eq 'TS1' ) {
        $baseDir = '/tools/gdaac/TS1/';
    }
}
elsif ( $host =~ /^giovanni\.*/ ) {

    # Case of ops or beta
    $baseDir = '/tools/gdaac/OPS/';
}
else {
    $baseDir = '/opt/';
}

# Based on the root path, read the Giovanni confiuration file which
# contains session location and URL mappings
my $cfgFile = "$baseDir/giovanni4/cfg/giovanni.cfg";
my $cpt     = Safe->new('GIOVANNI');
die "Failed to read $cfgFile" unless ( $cpt->rdo($cfgFile) );

my $sessionDir = undef;

# Determine whether the specified URL is a CGI script or a static file
if ( $path =~ /daac-bin/ ) {

    # Case of CGI scripts
    my $cgi = CGI->new( $uri->query() );
    my $var = {};

    # Parse the query string
    $var = $cgi->Vars();
    if ( exists $var->{session} ) {

        # Construct session directory
        $sessionDir = $GIOVANNI::SESSION_LOCATION . '/' . $var->{session};
        if ( exists $var->{resultset} ) {
            $sessionDir .= '/' . $var->{resultset};
            if ( exists $var->{result} ) {
                $sessionDir .= '/' . $var->{result};
            }
        }
    }
}
else {

    # Case of regular path
    $sessionDir
        = dirname( convertUrlToFilePath( $ARGV[0], \%GIOVANNI::URL_LOOKUP ) );
}

# IF session directory is defined, print it
if ( defined $sessionDir ) {
    print $sessionDir, "\n";
}
else {
    die "Failed to determine session directory";
}

# Convert URL to UNIX file path
# Inputs: URL to be converted to UNIX file path and a hash ref whose keys
# are file paths and values are corresponding URLs.
sub convertUrlToFilePath {
    my ( $url, $urlMap ) = @_;
    my $matchedItem = undef;

    # Go through file path to URL mapping
    foreach my $key ( sort keys %$urlMap ) {

        # If an item matches the specified URL, use corresponding file
        # path to deduce the UNIX directory
        if ( $url =~ /$urlMap->{$key}/ ) {
            $matchedItem = $url;
            $matchedItem =~ s/$urlMap->{$key}/$key/;
        }
    }
    return $matchedItem;
}

=pod

=head1 Description

Script figures out the session directory given a Giovanni URL. It prints 
out the UNIX directory where the session is located to stdout.

=head1 Example

`convertGiovanniUrlToDir.pl "http://s4ptu-ts1.ecs.nasa.gov/daac-bin/giovanni/service_manager.pl?session=A71A098A-1984-11E3-923F-34FE7F7E30AE&resultset=B41CD7C0-1984-11E3-BBED-44FE7F7E30AE&result=B41CF106-1984-11E3-BBED-44FE7F7E30AE&portal=GIOVANNI&format=json"`

=cut

