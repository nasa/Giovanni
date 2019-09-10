package Giovanni::Cache::Metadata;
use strict;
use warnings;

# Create a new Metadata
sub new {
    my ( $class, %input ) = @_;
    my $defaultDelimiter = "\0";
    my $self             = {
        columns   => $input{COLUMNS},
        delimiter => (
            exists $input{DELIMITER} ? $input{DELIMITER} : $defaultDelimiter
        ),
    };
    return bless( $self, $class );
}

# Parses a metadata string
sub decode {
    my ( $self, $str ) = @_;

    # split up the string
    my @elements = split( quotemeta( $self->{delimiter} ), $str );

    # The split function doesn't bother to put empty strings on the end of the
    # array. We want the output hash to have an empty string for empty
    # columns, so initialize the hash for all the columns to an empty string.
    my %outHash = map { $_ => '' } @{ $self->{columns} };

    # Set values. If there are more @elements than columns, only set the
    # columns that were requested. If there are more columns than elements,
    # only set the elements we have.
    my $numEntries = scalar(@elements) < scalar(@{$self->{columns}}) ?
        scalar(@elements) : scalar(@{$self->{columns}});
    for ( my $i = 0; $i < $numEntries; $i++ ) {
        $outHash{ $self->{columns}->[$i] } = $elements[$i];
    }
    return \%outHash;
}

# encode the columns
sub encode {
    my ( $self, %input ) = @_;

    my $out = '';
    for my $column ( @{ $self->{columns} } ) {
        my $val = exists( $input{$column} ) ? $input{$column} : '';
        $out = $out . $val . $self->{delimiter};
    }

    return substr( $out, 0, length($out) - length( $self->{delimiter} ) );
}

1
__END__

=head1 NAME

Giovanni::Cache::Metadata - Manages metadata in cache .db file

=head1 SYNOPSIS

 use Giovanni::Cache::Metadata

 my $columns
        = [ "PATH", "STARTTIME", "ENDTIME", "TIME", "DATAMONTH", "DATADAY" ];
 my $meta = Giovanni::Cache::Metadata->new(COLUMNS=>$columns);

 my $infoHash = {
     PATH      => "/var/path",
     STARTTIME => "1507918619",
     ENDTIME   => "1507918619",
     TIME      => "1507918619",
     DATAMONTH => '',
     DATADAY   => '',
 };
 my $encoded = $meta->hashToString( %{$infoHash} );
 my $decoded = $meta->stringToHash($encoded);

 # prints "/var/path"
 print $decoded->{PATH}."\n";

=head1 DESCRIPTION

constructor -- new()

  INPUTS:

    COLUMNS an array of column headers.

encode()

  INPUTS:

    inputHash - hash of column headers to string values. Unrecognized column
      headers are ignored.

  returns:

    an encoded string


decode()

  INPUTS:

    str - encoded string


  returns:

    a hash reference with the fields from the encoded string


=head1 AUTHOR

Christine Smit, E<lt>christine.e.smit@nasa.gov:w<gt>

=cut
