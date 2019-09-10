#! /usr/bin/perl -w

=head1 NAME
shift_longitude.pl - Shift longitude to make it monotonically increasing

=head1 PROJECT
Giovanni

=head1 SYNOPSIS
shift_longitude.pl [--help] [--verbose] in.nc out.nc

=head1 DESCRIPTION
This program reorders data along logitude so that longitudes are monotonically
increasing.

=head1 OPTIONS
=over 4

=item --help
Print a usage information

=item --verbose
Turn on verbose mode

=item in.nc
Input nc file

=item out.nc
Output nc file

=back

=head1 AUTHOR
Jianfu Pan (jianfu.pan@nasa.gov)

=cut

use lib ".";
use strict;
use Getopt::Long;
use File::Copy qw(copy);
use File::Temp;

our $self = "shift_longitude.pl";

print STDERR "Starting $self\n";

#
# Command line options
#

my $help;
my $debug_level = 0;
my $verbose;
my $opts = GetOptions(
    "help"      => \$help,
    "h"         => \$help,
    "verbose=s" => \$verbose
);
my $infile  = $ARGV[0];
my $outfile = $ARGV[1];

my $usage
    = "Usage: $0 [--help] [--verbose] in.nc out.nc\n"
    . "    --help           Print this help info\n"
    . "    --verbose        Print out lot of messages\n"
    . "    in.nc            Input nc file\n"
    . "    out.nc           Output nc file\n";

# Print usage and exit if that's all asked for
if ($help) {
    print STDERR $usage;
    exit(0);
}

# Verify options
die("ERROR Input nc file missing") unless -f $infile;

my $ncoFile = File::Temp->new();
my $ncoStr  = get_shifting($infile);
if ($ncoStr) {
    open( FILE, "> $ncoFile" );
    print FILE $ncoStr;
    close FILE;
    my $rc = do_shifting( $infile, $outfile, $ncoFile );
    die("ERROR do_shifting failed\n") unless $rc;
}
else {
    copy $infile, $outfile;
}

exit(0);

# get_shifting() - Create nco scripts for longitude shifting
# Inputs:
#   $in      - Input nc file
# Return:
#   nco      - NCO scripts in string when shifting is needed
#   undef    - No shifting needed
sub get_shifting {
    my ($in) = @_;

    #
    # Determine need for longitude shifting
    #

    # --- Get longitude data ---
    my $lon_str = `ncks -s "%f " -H -C -v lon $in`;
    chomp $lon_str;
    $lon_str =~ s/^\s|\s$//g;
    my @lon         = split( ' ', $lon_str );
    my $res_lon     = $lon[1] - $lon[0];
    my $nlon        = scalar(@lon);
    my $nlon_global = int( 360 / $res_lon );
    my $nlon_hole   = $nlon_global - $nlon;

    # --- Find the order reversing point (increasing becomes decreasing)
    # Important variables:
    #   $i_reverse : First point that starts to reverse the order
    # TBD: We assume in a -180 to 180 system so west is always less than east
    #      in normal cases.
    my $i_reverse = -1;
    for ( my $i = 1; $i < $nlon; $i++ ) {
        if ( $lon[$i] < $lon[ $i - 1 ] ) {
            print STDERR "INFO ($self) Order reversing at lon[$i]=$lon[$i]\n";
            $i_reverse = $i;
            last;
        }
    }

    if ( $i_reverse == -1 ) {
        ###  No shifting needed
        print STDERR "INFO ($self) No longitude shifting needed\n";
        return undef;
    }
    else {
        ### Get variable names
        my $vnames = get_vnames($infile);

        ### Create NCO scripts for reversing

        if ( scalar(@$vnames) == 0 ) {
            print STDERR
                "ERROR ($self) Fail to find variables: ncks -m $infile|grep 'RAM'|cut -d ' ' -f 1\n";
            return undef;
        }

        #
        # Create NCO script
        #

        my $n2     = $nlon - $i_reverse;     # length of the second segment
        my $n2_end = $n2 + $nlon_hole - 1;
        my $m1     = $nlon - 1;
        my $m2     = $n2 - 1;
        my $i1     = $i_reverse - 1;
        my $r0     = $n2 + $nlon_hole;
        my $r1     = $nlon_global - 1;
        my $nco
            = ''
            . "defdim(\"lon_new\", $nlon_global);\n"
            . 'lon_new[$lon_new] = 0.0;' . "\n"
            . "lon_new(0:$m2) = lon($i_reverse:$m1);\n"
            . "for (*i=0; i<$nlon_hole; i++)\n"
            . "    lon_new($n2+i) = lon_new($m2+i) + $res_lon;\n"
            . "lon_new($r0:$r1) = lon(0:$i1);\n"
            . 'lon_new@units=lon@units;' . "\n"
            . 'lon_new@standard_name=lon@standard_name;' . "\n"
            . 'lon_new@long_name="Longitude";' . "\n";

        foreach my $vn (@$vnames) {

# Determine number of dimensions
# TBD Currently we assume 2D is lat/lon and 3D is time/lat/lon.  This needs to be
#     more generalized.
            my $ndim = `ncks -m $in|grep $vn|grep "dimension "|wc -l`;
            chomp($ndim);

            if ( $ndim == 2 ) {
                $nco
                    .= "*fill = $vn.get_miss();\n"
                    . "*z = $vn;\n"
                    . '*znew[$lat,$lon_new] = z.get_miss();' . "\n"
                    . "znew(:,0:$m2) = z(:,$i_reverse:$m1);\n"
                    . "znew(:,$r0:$r1) = z(:,0:$i1);\n"
                    . "znew.set_miss(z.get_miss());\n"
                    . "$vn=znew;\n";
            }
            elsif ( $ndim == 3 ) {
                $nco
                    .= "*fill = $vn.get_miss();\n"
                    . "*z = $vn;\n"
                    . '*znew[$time,$lat,$lon_new] = z.get_miss();' . "\n"
                    . "znew(:,:,0:$m2) = z(:,:,$i_reverse:$m1);\n"
                    . "znew(:,:,$r0:$r1) = z(:,:,0:$i1);\n"
                    . "znew.set_miss(z.get_miss());\n"
                    . "$vn=znew;\n";
            }
            else {
                die
                    "ERROR unexpected number of dimensions ($ndim) for $vn in $in\n";
            }
        }

        return $nco;
    }
}

# do_shifting() - Perform longitude shifting
# Inputs:
#   $infile  - Input nc file
#   $outfile - Output nc file
#   $nco     - NCO script file
# Return:
#   1  - success
#   0  - fail
sub do_shifting {
    my ( $infile, $outfile, $nco ) = @_;

    # shifting
    `ncap2 -S $nco -O $infile $outfile`;
    if ($?) {
        print STDERR
            "ERROR ($self) Shifting failed (ncap2 -S $nco -O $infile $outfile) $!\n";
        return 0;
    }

    # Clean up the output nc file
    my $vnames = get_vnames($infile);
    my $vn_str = join( ',', @$vnames );
    `ncks -4 -h -O -v $vn_str $outfile $outfile.tmp`;
    if ($?) {
        print STDERR
            "ERROR ($self) ncks failed (ncks -O -v $vn_str $outfile $outfile) $!\n";
        return 0;
    }

    #- `ncrename -h -O -d lon_new,lon -v lon_new,lon $outfile $outfile`;
    `ncrename -h -O -d lon_new,lon $outfile.tmp`;
    if ($?) {
        print STDERR
            "ERROR ($self) ncrename failed (ncrename -O -d lon_new,lon $outfile) $!\n";
        return 0;
    }
    else {
        `nccopy -k 1 $outfile.tmp $outfile`;
    }

    return 1;
}

sub get_vnames {
    my ($infile) = @_;

    my @vnames_tmp = `ncks -m $infile|grep "RAM"|cut -d ' ' -f 1`;
    if ($?) {
        print STDERR
            "ERROR ($self) Fail to get var names: (ncks -m $infile|grep 'RAM'|cut -d ' ' -f 1) $!\n";
        return [];
    }
    my @vnames  = ();
    my $dataday = undef;
    foreach my $vn (@vnames_tmp) {
        chomp($vn);
        if ( $vn eq "dataday" or $vn eq "datamonth" or $vn eq "datahour" ) {
            $dataday = $vn;
        }
        else {
            push( @vnames, $vn )
                unless $vn eq "time"
                    or $vn eq "time1"
                    or $vn eq "lat"
                    or $vn eq "lon";
        }
    }

    return \@vnames;
}
