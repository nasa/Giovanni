#!/usr/bin/perl -T
#$Id: netcdf_serializer_general.pl,v 1.2 2015/02/02 22:51:23 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

use strict;
use CGI;
use Safe;
use warnings;

# Establish the root path based on the script name
my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5' )
        if defined $rootPath;
}
$| = 1;

# Following packages should be used after @INC is set above
use Giovanni::Util;

## clean env and path
$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

my $cgi = new CGI->new();

# Read the configuration file
my $cfgFile = $rootPath . 'cfg/giovanni.cfg';

# response is hash{success,message}
my $response = Giovanni::Util::ingestGiovanniDomainLookup($cfgFile);

# I want to return the error message (or successful json of course)
# to the javascript code so it handle it (which it so capably does)
# instead of returning 500:
print "Content-type: text/html\n\n";
print $response->{message};

=head1 NAME

getGiovanniDomainLookup - this cgi script returns GIOVANNI::DOMAIN_LOOKUP from giovanni.cfg in a similar way to how
ingestGiovanniEnv retrieves GIOVANNI::ENV. It converts it to a JSON string before returning.

=head1 SYNOPSYS

perl -T I /tools/gdaac/TS2/lib/perl5/site_perl/5.8.8 /tools/gdaac/TS2/cgi-bin/giovanni/getGiovanniDomainLookup.pl  <no query string>

=head1 DESCRIPTION

returns JSON string of giovanni.cfg GIOVANNI::DOMAIN_LOOKUP
 
=head2 Parameters

NONE

=over

=back


=cut
