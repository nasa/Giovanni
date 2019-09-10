package Giovanni::Visualizer::TimeTics::Climatology;

use strict;
use warnings;
use Giovanni::Data::NcFile;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Visualizer::TimeTics ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
# our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# our @EXPORT = qw( );

our $VERSION = '0.02';

# Preloaded methods go here.

1;

=head1 NAME

Giovanni::Visualizer::TimeTics - compute nice tic marks, esp. for time axes

=head1 SYNOPSIS

use TimeTics::Climatology;

my $ra_time_bnds = Giovanni::Data::NcFile::get_time_bounds($ncfile);

$tics = new TimeTics::Climatology('time_bnds' => $ra_time_bnds);

$ra_tic_vals = $tics->values;

$ra_tic_labels = $tics->labels;

$ra_tic_minor = $tics->minor;

=head1 DESCRIPTION

Compute aesthetically pleasing tic values for time axes, for climatology
variables

=over 4

=item new('time_bnds' => \@time_bnds);

Computes the major and minor tic axis values in seconds since 1970-01-01.

=item values()

Returns a reference to an array of major tic mark epochal times 
(since 1970-01-01).

=item minor()

Returns a reference to an array of minor tic mark epochal times 
(since 1970-01-01).

=item labels()

Returns a reference to an array of major tic mark labels.

=head1 AUTHOR

Daniel da Silva

=cut

sub new {
    my ( $pkg, %params ) = @_;
    my $tics = bless \%params, $pkg;
    if ( $tics->time_bnds ) {
        $tics->compute_tics;
    }
    return $tics;
}

sub compute_tics {
    my $this      = shift;
    my @time_bnds = @{ $this->time_bnds };

    my ( @values, @labels );

    for ( my $i = 0; $i < scalar(@time_bnds) - 1; $i += 2 ) {
        my $start = $time_bnds[$i];
        my $mm    = DateTime->from_epoch( epoch => $start )->month();
        my $mon   = Giovanni::Visualizer::TimeTics::mm2mon( $mm - 1 );
        push( @values, $start );
        push( @labels, $mon );
    }

    $this->values( \@values );
    $this->labels( \@labels );
}

sub values {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'values'}
        = $_[0]
        : $this->{'values'};
}

sub labels {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'labels'}
        = $_[0]
        : $this->{'labels'};
}

sub minor {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'minor'}
        = $_[0]
        : $this->{'minor'};
}

sub time_bnds {
    my $this = shift;
    defined( $_[0] )
        ? $this->{'time_bnds'}
        = $_[0]
        : $this->{'time_bnds'};
}
