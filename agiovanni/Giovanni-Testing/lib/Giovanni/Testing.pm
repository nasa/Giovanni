package Giovanni::Testing;

use 5.008008;
use strict;
use warnings;
use FindBin;
use File::Basename;

use Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Testing ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [qw( )] );

our $VERSION = '0.01';

# Preloaded methods go here.

1;

sub find_script_paths {
    my @scripts = @_;
    my @script_paths;
    foreach my $script (@scripts) {
        my $script_path = "blib/script/$script";
        foreach my $dir ( split( /\/+/, $FindBin::Bin ) ) {
            next if ( $dir =~ /^\s*$/ );
            last if ( -f $script_path );
            $script_path = "../$script_path";
        }
        push @script_paths, $script_path;
    }
    return @script_paths;
}

sub parse_data_block {
    my (@block_types) = @_;
    my $pattern;

    # Build up a regex from the different block types
    foreach my $regex (@block_types) {
        if ( $regex eq 'CDL' ) {
            $pattern .= '(netcdf.*?\n\}\n)';
        }
        elsif ( $regex eq 'UUE' ) {
            $pattern .= '(begin.*?\nend\n)';
        }
        else {
            warn("ERROR unknown data block type\n");
            return;
        }
    }

    # Read the whole data block
    no warnings qw(once);
    local ($/) = undef;
    my $data = <main::DATA>;
    close(main::DATA);
    warn "INFO read data\n";

    # Parse it
    my @blocks = ( $data =~ /$pattern/s );
    return @blocks;
}

sub uuencode {
    my ( $input_file, $output_file ) = @_;

    # Open and read input file
    unless ( open( IN, $input_file ) ) {
        warn "ERROR could not open input file $input_file: $!\n";
        return;
    }
    my $uue;
    $/ = undef;

    # Pack input bytes into uuencoded format
    while (<IN>) {
        $uue .= pack( "u", $_ );
    }
    close IN;

    # Write to output file
    unless ( open( OUT, '>', $output_file ) ) {
        warn "ERROR could not open output file $output_file: $!\n";
        return;
    }
    printf OUT "begin 0644 %s\n%s\`\nend\n", basename($output_file), $uue;
    close OUT;
    return 1;
}

sub uudecode_file {
    my ( $infile, $dir ) = @_;

    # Read in the uuencoded file
    unless ( open IN, $infile ) {
        warn "ERROR Could not open input file $infile: $!\n";
        return;
    }
    local ($/) = undef;
    my $uue = <IN>;
    close(IN);
    return uudecode_data( $uue, $dir );
}

sub uudecode_data {
    my ( $uue, $dir ) = @_;

    # Parse the uuencoded block
    my ( $perm, $file, $data )
        = ( $uue =~ /begin (\d+) (\S+)\n(.*)\`\nend/s );

    # Prepare to rite
    my $path = $dir . '/' . basename($file);
    open OUT, '>', $path or die "Cannot write to file $path: $!\n";
    print OUT unpack( "u", $data );
    close OUT;
    return $path;
}

__END__

=head1 NAME

Giovanni::Testing - support Giovanni unit and regression testing

=head1 SYNOPSIS

  use Giovanni::Testing;
  @script_paths = Giovanni::Testing::find_script_paths(@scripts);
  ($cdl, $uue) = Giovanni::Testing::parse_data_block('CDL', 'UUE');
  $rc = Giovanni::Testing::uuencode($input_file, $output_file);
  $path = Giovanni::Testing::uudecode_file($file, $output_dir);
  $path = Giovanni::Testing::uudecode_data($uue, $output_dir);

=head1 DESCRIPTION

=over 4

=item find_script_paths(@scripts)

Returns an array of script paths as they are instantiated for unit
testing.

=item parse_data_block(@block_types);

Parses a main::DATA block (__DATA__) into constituent blocks.  The two kinds supported are netCDF 'CDL'
and uuencoded ('UUE').  Returns an array of blocks, suitable for writing to individual files.

=item uuencode($input_file, $output_file)

Uuencodes a file into an output file.  This is useful for uuencoding binary files (e.g., GIF) into
a __DATA__ block of a test routine.

=item uudecode_file($file, $dir)

Decodes a file, writing the output file in the specified directory.
The output filename is that encoded in the uuencoded data.

=item uudecode_data($data, $dir)

Decodes a block of data (in memory), writing the output file in the specified directory. 
The output filename is that encoded in the uuencoded data.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Chris Lynnes, chris.lynnes@nasa.gov

=head1 COPYRIGHT AND LICENSE

TBD

=cut
