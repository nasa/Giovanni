package EDDA::Ingest;

use 5.008008;
use strict;
use warnings;
use XML::LibXML;
use File::Basename;
use File::Spec;
use File::Spec::Functions qw( tmpdir );
use Time::HiRes qw (gettimeofday);
use vars '$AUTOLOAD';

require Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use EDDA::Ingest ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.


sub new() {
    my ( $class, %input ) = @_;

    my $self = {};

    my $parser = XML::LibXML->new();
    $parser->keep_blanks(0);
    $self->{_PARSER} = $parser;

    unless (exists $input{ARCHIVE}) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Must provide ARCHIVE (file path to archive file)";
        return bless( $self, $class );
    }
    unless (-r $input{ARCHIVE}) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Could not read file " . $input{ARCHIVE};
        return bless( $self, $class );
    }
    $self->{_ARCHIVE} = $input{ARCHIVE};
    my @tarList = `/bin/gtar --list --file $input{ARCHIVE}`;
    if ($?) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Could not obtain contents of archive file " . $input{ARCHIVE};
        return bless( $self, $class );
    }
    chomp(@tarList);
    my @archiveContents;
    foreach my $item (@tarList) {
        my $fname = basename($item);
        next if ($fname eq '.');
        push @archiveContents, $fname;
    }
    unless (@archiveContents) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "No files found in archive file " . $input{ARCHIVE};
        return bless( $self, $class );
    }
    $self->{_ARCHIVE_FILES} = \@archiveContents;
    my $tmpDir = tmpdir();
    unless ($tmpDir) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Could not obtain tmpdir";
        return bless( $self, $class );
    }
    my $timeStamp = scalar(gettimeofday);
    $timeStamp =~ s/\./_/;
    my $dirName = 'ingestDataFieldInfo_' . $timeStamp;
    my $ingestDir = File::Spec->catfile($tmpDir, $dirName);
    unless (mkdir $ingestDir) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Error creating directory $ingestDir";
        return bless( $self, $class );
    }
    $self->{_INGEST_DIR} = $ingestDir;
    `/bin/gtar --extract -x --file $input{ARCHIVE} -C $ingestDir`;
    if ($?) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Could not extract contents of archive file " . $input{ARCHIVE};
        return bless( $self, $class );
    }
    # Make sure files can be read by everyone
    foreach my $f (@archiveContents) {
	my $path = File::Spec->catfile($self->{_INGEST_DIR}, $f);
	chmod 0644, $path if -f $path;
    }

    return bless( $self, $class );
}

sub validateSchema {
    my ($self, $schemaFile) = @_;

    unless (defined $schemaFile) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = (caller(0))[3] . " No schema file specified";
        return;
    }
    my $xmlschema;
    eval { $xmlschema = XML::LibXML::Schema->new( location => $schemaFile ); };
    if ($@) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Schema error: $@";
        return;
    }
    my $parser = $self->{_PARSER};
    foreach my $file ($self->ingestedFiles) {
        my $dom;
        eval { $dom = $parser->parse_file($file); };
        if ($@) {
            $self->{_ERROR_TYPE} = 1;
            $self->{_ERROR_MESSAGE} = "Could not read and parse $file";
            return;
        }
        eval { $xmlschema->validate( $dom ); };
        if ($@) {
            $self->{_ERROR_TYPE} = 1;
            $self->{_ERROR_MESSAGE} = "Validation of $file failed: $@";
            return;
        }
    }

    return 1;
}

sub validateSchematron {
    my ($self, $schematronFile) = @_;

    unless (defined $schematronFile) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = (caller(0))[3] . " No schematron file specified";
        return;
    }

    # Validate via schematron

    return;
}

sub validateRules {
    my ($self, $fileMapping) = @_;

    unless (defined $fileMapping) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "No field mapping specified";
        return;
    }
    unless ( (ref $fileMapping) eq 'HASH') {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = "Invalid field mapping";
        return;
    }

    my @guardedFields = ('dataFieldId', 'dataFieldG3Id');
    my $guardValue = 'CLONE_OF_';
    my @guardedPaths;
    my @errorMessages;
    foreach my $guardedField (@guardedFields) {
        if (exists $fileMapping->{$guardedField}) {
            push @guardedPaths, $fileMapping->{$guardedField} . '/value';
        } else {
            push @errorMessages, "No field mapping found for $guardedField";
        }
    }
    if (@errorMessages) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = join("\n", @errorMessages);
        return;
    }

    my $parser = $self->{_PARSER};
    foreach my $file ($self->ingestedFiles) {
        my $dom;
        eval { $dom = $parser->parse_file($file); };
        if ($@) {
            $self->{_ERROR_TYPE} = 1;
            $self->{_ERROR_MESSAGE} = "Could not read and parse $file";
            return;
        }
        my $fname = basename($file);
        my $doc = $dom->documentElement();
        foreach my $guardedPath (@guardedPaths) {
            my ($node) = $doc->findnodes($guardedPath);
            if (defined $node) {
                my $value = $node->textContent;
                if (defined $value) {
                    if ($value =~ /$guardValue/) {
                        push @errorMessages, "$fname: $guardedPath has unmodified value $value";
                    }
                }
            } else {
                push @errorMessages, "$fname: No element found at $guardedPath";
            }
        }
    }

    if (@errorMessages) {
        $self->{_ERROR_TYPE} = 1;
        $self->{_ERROR_MESSAGE} = join("\n", @errorMessages);
        return;
    }

    return 1;
}

sub safe_exec {
    my $cmd_str = join( ' ', map { qq('$_') } @_ );

    my $output;
    my $pid;
    die "$0 Cannot fork: $!" unless defined( $pid = open( CHILD, "-|" ) );
    if ( $pid == 0 ) {
        exec(@_) or die "Failed executing $cmd_str: $!";
    }
    else {
        local $/;
        $output = <CHILD>;
        close(CHILD);
    }

    my $status = $? ? ( $? >> 8 ) : $?;
    if ($status) {
        if ($output) {
#            print STDERR "Executed $cmd_str with status $status\n" if ($DEBUG);
            print $output;
            exit $status;
        }
        else {
            die "Failed executing $cmd_str: $!, status=$status";
        }
    }
#    print STDERR "Successfully executed $cmd_str\n" if ($DEBUG);

    return $output;
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    if ( $AUTOLOAD =~ /.*::someMethod/ ) {
    }
    elsif ( $AUTOLOAD =~ /.*::ingestedFileNames/ ) {
        return @{$self->{_ARCHIVE_FILES}}
    }
    elsif ( $AUTOLOAD =~ /.*::ingestedFiles/ ) {
        return map {File::Spec->catfile($self->{_INGEST_DIR}, $_)} @{$self->{_ARCHIVE_FILES}};

    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        return $self->{_ERROR_TYPE};
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE};
    }
    return;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

EDDA::Ingest - Module for ingesting EDDA data fields

=head1 SYNOPSIS

  use EDDA::Ingest;

=head1 DESCRIPTION

EDDA::Ingest provides a way to ingest EDDA data field files

=head2 EXPORT

None by default.



=head1 SEE ALSO


=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.gov<gt>


=cut
