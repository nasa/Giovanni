#! /usr/bin/env perl
# $Id: getUnitsArg.pl,v 1.7 2015/04/09 19:46:35 clynnes Exp $
# -@@@ aGiovanni, Version $Name:  $

=head1 NAME

getUnitsArg.pl - Makefile utility to transform makefile variables and manifest files into G4 --units argument

=head1 SYNOPSIS

getUnitsArg.pl [-v] 
   $mfst[,$mfst] 
   (ALGORITHM|POST),$(CONVERT_UNITS_STEP)
   $(UNITS_CFG)
   [data manifest file]

=head1 DESCRIPTION

getUnitsArg.pl is designed to be used in Makefiles to transform the information the Makefile has into
a --units units1,units2,units_cfg argument in a call to either the algorithm or the post processing step.
It takes 4 arguments:

=over 4

=item -v

Verbose option.  Echo args and found units attributes to stderr.

=item arg #1 

Either one DATA_FIELD_SLICE file, or a commma-separated list of 2 files (for comparisons)

=item arg #2

This is a comma-separated list of:

1 - which step is being run here.

2 - which step units conversion should be done in for this algorithm for linear conversions

3 - which step units conversion should be done in for this algorithm for time-dependent conversions (optional)

Valid values are: WRAPPER (pre-algorithm), ALGORITHM, or POST (post-algorithm).  This typically comes from
the algorithm service specification (.svc) file, in the CONVERT_UNITS_STEP variable.

=item arg #3

Full path to the units config file, supplied by service manager in the Makefile as $(UNITS_CFG).
If this is not specified, exit 0 with no output.

=item arg #4

Full path to the data manifest file. This is needed to check for time-dependent conversions.
This is needed only if two conditions are filled:
 (1) a time-dependent step is included in arg #2.
 (2) this step is ALGORITHM

=back

The output will normally be of the form:

  --units units1,units2,units_cfg

For time-dependent conversions occurring in the ALGORITHM step,
an additional argument is appended to give the wrapper a hint as
to exactly where the conversion will be:

  --units units1,units2,units_cfg,WRAPPER

or

  --units units1,units2,units_cfg,ALGORITHM

The destintion units strings are obtained from the manifest file where they are 
described as an attribute named units, e.g. 

 <manifest><data units="mm/day" zValue="NA">TRMM_3B42_rainfall</data></manifest>

If no units conversion is to be done, then units will be set to "NA".
If this happens for a comparison, that space will be left blank in the comma-separated argument, e.g.,

  --units units1,,units_cfg

If no conversions are being requested, nothing will be output and the code will exit 0.

=head1 AUTHOR

Chris Lynnes

=cut

use strict;
use vars qw($opt_v);
use Getopt::Std;
use XML::LibXML;
use Giovanni::Util;

getopts('v');
my ( $manifests, $match_step, $units_cfg, $data_mfst ) = @ARGV;
if ($opt_v) {
    warn("getUnitsArg.pl $manifests $match_step $units_cfg $data_mfst\n");
}

# No units config file, nothing to see here, move along...
exit(0) unless ($units_cfg);

# Check to see if this is the right step for units conversion
# Arguments are this_step, normal_conversion_step, time-dependent conversion step
# If this_step is not the normal conversion step and no time-dependent step is given
# then exit with no output
my ( $this_step, $which_step, $which_td_step ) = split( ',', $match_step );

# Decompose into whether it is this step and whether we really mean the Wrapper
$which_td_step ||= $which_step;
my @really_in_wrapper
    = map { $_ eq 'WRAPPER' } ( $which_step, $which_td_step );
my @which_step = map { ( $_ eq 'WRAPPER' ) ? 'ALGORITHM' : $_ }
    ( $which_step, $which_td_step );

# Definitely not this step: exit silently
exit(0)
    if ( ( $this_step ne $which_step[0] )
    && ( $this_step ne $which_step[1] ) );

# Get destination units and see if there is anything to be done
my @dest_units = get_all_dest_units($manifests);

# Exit silently if no units conversion is specified
exit(0) unless @dest_units;

# Definitely this step (no need to check time-dependence)
my $convert_here
    = ( $this_step eq $which_step[0] ) && ( $this_step eq $which_step[1] );

# Need to determine if time-dependent or not
my $time_dependent = 0;

# If they are both the same, it doesn't matter, no need to check
unless ( $which_step eq $which_td_step ) {
    $time_dependent = got_time_dependent_conversion( $data_mfst, $units_cfg,
        @dest_units );
    exit(0) unless ( $this_step eq $which_step[$time_dependent] );
}

# OK, got to convert some units
print '--units "' . join( ',', @dest_units, $units_cfg ) . '"';

# No need for a hint if POST
exit(0) if ( $this_step eq 'POST' );

# Only get here if we are converting this step and it's the ALGORITHM step
# Need to append a hint on ALGORITHM v. WRAPPER
my $where_hint
    = ( $really_in_wrapper[$time_dependent] ? 'WRAPPER' : 'ALGORITHM' );
print ",$where_hint";
exit(0);

sub get_all_dest_units {
    my $manifests = shift;
    my $got_units = 0;

    # Split argument on comma
    my @manifests = split( ',', $manifests );

    foreach my $mfst (@manifests) {
        my $dest_units = get_dest_units($mfst);
        if ( $dest_units eq 'NA' ) {
            $dest_units = '';
        }
        $got_units = 1 if ($dest_units);

        # Push on array, even if blank...
        push @dest_units, $dest_units;
    }

    # ...but return only if there are some units to convert
    return ( $got_units ? @dest_units : () );
}

sub get_dest_units {
    my $mfst = shift;

    # read the XML
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file($mfst);
    my $xpc    = XML::LibXML::XPathContext->new($dom);

    #  Extract units node
    my ($units_node) = $xpc->findnodes("/manifest/data/\@units");
    my $units = $units_node->nodeValue();

    warn("getUnitsArg.pl: units in $mfst=$units\n") if $opt_v;
    return $units;
}

sub got_time_dependent_conversion {
    require Giovanni::Data::NcFile;
    require Giovanni::UnitsConversion;
    my ( $mfst, $config, @dest_units ) = @_;

#   <fileList id="TRMM_3B42_daily_precipitation_V6"><file>/var/giovanni/session/84AC5454-CF34-11E4-9092-4C014319ED9B/B9A83AB4-CF4E-11E4-BAB8-4D864319ED9B/B9A84B76-CF4E-11E4-BAB8-4D864319ED9B//scrubbed.TRMM_3B42_daily_precipitation_V6.20090101.nc</file>

    # Read data manifest
    die "getUnitsArg.pl:  ERROR no data manifest file in args\n" unless $mfst;
    my $parser = XML::LibXML->new();
    my $dom    = $parser->parse_file($mfst);
    my $xpc    = XML::LibXML::XPathContext->new($dom);

    # get the variable ids
    my @id_nodes = $xpc->findnodes(qq|/manifest/fileList/\@id|);
    my @var_ids = map( $_->nodeValue, @id_nodes );
    for my $var (@var_ids) {

        # get the file nodes
        my $xp         = qq |/manifest/fileList[\@id="$var"]/file/text()|;
        my @file_nodes = $xpc->findnodes($xp);
        my @files      = map( $_->nodeValue(), @file_nodes );
        for my $file (@files) {
            Giovanni::Util::trim($file);

            # Do we care for this one? Check destination units
            my $dest_units = shift @dest_units;
            unless ( $dest_units && $dest_units ne 'NA' ) {
                warn
                    "getUnitsArg.pl: dest_units=$dest_units for $var so no conversion\n"
                    if $opt_v;
                next;
            }

            # Get source units from data file
            my ($rh_att)
                = Giovanni::Data::NcFile::get_variable_attributes( $file, 0,
                $var );
            unless ( exists( $rh_att->{units} ) && $rh_att->{units} ) {
                warn
                    "getUnitsArg.pl: no source units for $var so no conversion\n"
                    if $opt_v;
                next;
            }

            # Finally, check conversion for time dependency
            my $vartype
                = Giovanni::Data::NcFile::get_variable_type( $file, 1, $var );
            my $converter = new Giovanni::UnitsConversion(
                variable => $var,
                type     => $vartype,
                config   => $units_cfg
            );
            die "ERROR Cannot get converter\n" unless $converter;
            if ($converter->isTimeDependent(
                    sourceUnits      => $rh_att->{units},
                    destinationUnits => $dest_units
                )
                )
            {
                warn
                    "getUnitsArg.pl: Conversion of $var from $rh_att->{units} to $dest_units is time dependent\n"
                    if $opt_v;
                return 1;
            }
            else {
                warn
                    "getUnitsArg.pl: Conversion of $rh_att->{units} to $dest_units is not time dependent\n"
                    if $opt_v;
            }
        }
    }
    return 0;
}

# Simple read_file to avoid cross dependency with other modules
sub read_file {
    my $file = shift;
    die "getUnitsArg.pl: Cannot open $file: $!\n" unless open( IN, $file );
    $/ = undef;
    my $string = <IN>;
    close IN;
    return $string;
}
