package DataAccess::Translator;

use 5.008008;
use strict;
use warnings;
use URI;
use File::Spec;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

sub new {
    my ( $class, %input ) = @_;
    my $self = {};
    $self->{_TARGET}
        = exists $input{TARGET_URL} ? URI->new( $input{TARGET_URL} ) : undef;
    $self->{_SOURCE}
        = exists $input{SOURCE_URL} ? URI->new( $input{SOURCE_URL} ) : undef;
    return bless( $self, $class );
}

sub findTranslationRule {
    my ($self) = @_;

    return $self->{_TRANSLATION_RULE} if exists $self->{_TRANSLATION_RULE};

    my $tar = $self->{_TARGET};
    my $src = $self->{_SOURCE};

    # We want to do opendap translation first now.
    # So we need to be able to identify when we
    # can translate or not. The only case I could
    # find was MODISA SST4
    # Untranslatable seems to happen when all rule
    # types are either all strings or all indexes
    my $nStringType = 0;
    my $nIndexType  = 0;
    my $rule        = {};

    # Target URL protocol, host and port are used as they are
    $rule->{scheme} = $tar->scheme();
    $rule->{host}   = $tar->host();
    $rule->{port}   = $tar->port() if defined $tar->port();

    # Get dir/file in the path
    my @tarPathList = grep /\S+/, File::Spec->splitdir( $tar->path );
    my @srcPathList = grep /\S+/, File::Spec->splitdir( $src->path );

    # Mapping of file: last member in the path is the file name
    my $tarFile = pop(@tarPathList);
    my $srcFile = pop(@srcPathList);

 # File name in the target can have the source file name and other sub-strings
    $rule->{file} = [ split( $srcFile, $tarFile ) ];
    $rule->{path} = [];

    # Look for exact match first
    for ( my ( $i, $start ) = ( 0, 0 ); $i < @tarPathList; $i++ ) {
        my $found = 0;
        for ( my $j = $start; $j < @srcPathList && not $found; $j++ ) {
            if ( $tarPathList[$i] eq $srcPathList[$j] ) {
                $found = 1;
                $start = $j;
            }
        }

        if ($found) {
            ++$nIndexType;

            # For exact matches, note down the index in the source path list
            push( @{ $rule->{path} }, { type => 'index', value => $start } );
            $start++;
        }
        else {
            ++$nStringType;

            # Otherwise, copy the directory name as it is
            push(
                @{ $rule->{path} },
                { type => 'string', value => $tarPathList[$i] }
            );
        }
    }
    if ( $nStringType == 0 or $nIndexType == 0 ) {
        return;
    }
    $self->{_TRANSLATION_RULE} = $rule;
    return $self->{_TRANSLATION_RULE};
}

sub translate {
    my ( $self, @urlList ) = @_;
    my $rule = $self->findTranslationRule();
    return if ( !$rule );
    my @outUrlList = ();
    my $baseUri
        = $rule->{scheme} . '://'
        . $rule->{host}
        . ( $rule->{port} eq 80 ? '' : ":$rule->{port}" );

    # Map path
    foreach my $url (@urlList) {
        my $uri = URI->new($url);
        my @srcPathList = grep /\S+/, File::Spec->splitdir( $uri->path );

        # Mapping of file: last member in the path is the file name
        my $srcFile = pop(@srcPathList);
        my @path    = ();
        foreach my $item ( @{ $rule->{path} } ) {
            if ( $item->{type} eq 'index' ) {
                push( @path, $srcPathList[ $item->{value} ] );
            }
            elsif ( $item->{type} eq 'string' ) {
                push( @path, $item->{value} );
            }
        }
        push( @path, join( $srcFile, @{ $rule->{file} } ) );
        push( @outUrlList, $baseUri . '/' . File::Spec->catdir(@path) );
    }
    return @outUrlList;
}

1;
__END__

=head1 NAME

DataAccess::Translator - Encapsulates translation of data URL from one access method to another.

=head1 SYNOPSIS

  use DataAccess::Translator;
  $trans = DataAccess::Translator->new( SOURCE_URL => 'ftp://x.y.gov/data/abc/2006/xyz.hdf',
                                        TARGET_URL => 'http://x.y.gov/opendap/abc/2006/xyz.hdf.html' );

  @urlList = $trans->translate( 'ftp:/x.y.gov/data/abc/2007/test1.hdf',
                                'ftp:/x.y.gov/data/abc/2008/test2.hdf' );

=head1 DESCRIPTION

DataAccess::Translator encapsulates translation of data URL from one access method to another.
It expects a soure and a target URL as arguments to its constructor. A use case would be translating
from data file URL to corresponding OPeNDAP URL.

=head1 METHODS

=head2 new(SOURCE_URL=>$srcUrl, TARGET_URL=>$tarUrl)

Accepts SOURCE_URL and TARGET_URL as arguments to serve as the reference and target for mapping.

=head2 translate(@urlList)

Translates the input URLs based on the mapping rule

=head2 EXPORT

=head1 SEE ALSO

=head1 AUTHOR

Mahabaleshwara S. Hegde, E<lt>maha.hegde@nasa.gov<gt>

=cut
