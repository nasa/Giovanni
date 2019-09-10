package EDDA;

use 5.008008;
use strict;
use warnings;
use XML::LibXML;
use vars '$AUTOLOAD';

require Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use EDDA ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub getDataProductDataFieldIds {
    my ($dataProductDoc) = @_;


    my ($dataProductDataFieldIdsNode) = $dataProductDoc->findnodes('/dataProduct/dataProductDataFieldIds');
    my @dataFieldIdNodes = $dataProductDataFieldIdsNode->findnodes('./value');
    my $dataFieldIds;
    foreach my $dataFieldIdNode (@dataFieldIdNodes) {
        my $dataFieldId = $dataFieldIdNode->textContent;
        my $longId = $dataFieldIdNode->getAttribute('longId');
        if ($dataFieldId ne '') {
            if ($longId) {
                $dataFieldIds->{$longId} = $dataFieldId;
            } else {
                # For backwards compatibility, since longId is new
                $dataFieldIds->{$dataFieldId} = $dataFieldId;
            }
        }
    }

    return $dataFieldIds;
}

sub getPublishedBaselines {
    my ($dataFieldId, $mode, $baselines, $publishedDataFieldsDirs, $parser) = @_;

    # Obtain some data field information for each published baseline
    # by extracting it from the data field file in the published data fields
    # directory of each baseline
    my @dataFieldElementNames = ('dataFieldLastModified',
                                 'dataFieldLastPublished',
                                 'dataFieldActive');
    my $lowestBaseline;
    my $publishedBaselines;
    foreach my $baseline (@$baselines) {
        $lowestBaseline = $baseline if ($baseline eq $mode);
        next unless $lowestBaseline;
        my $publishedDataFieldsDir = $publishedDataFieldsDirs->{$baseline};
        my $fieldFile = "$publishedDataFieldsDir/$dataFieldId";
        if (-e $fieldFile) {
            my $dataFieldDom;
            eval { $dataFieldDom = $parser->parse_file( $fieldFile ); };
            if ($@) {
                print STDERR "Could not read and parse $fieldFile\n";
                next;
            }
            my $dataFieldDoc = $dataFieldDom->documentElement();
            foreach my $elementName (@dataFieldElementNames) {
                my ($node) = $dataFieldDoc->findnodes("/dataField/$elementName/value");
                my $value = $node->textContent if $node;
                $publishedBaselines->{$baseline}->{$elementName} = $value;
            }
        }
    }

    return $publishedBaselines;
}

sub createPublishedBaselineInfoNode {
    my ($baseline, $publishedBaselines) = @_;

    my ($modifiedDate, $publishedDate, $active);
    if (exists $publishedBaselines->{$baseline}) {
        $modifiedDate = $publishedBaselines->{$baseline}->{dataFieldLastModified}
            if exists ($publishedBaselines->{$baseline}->{dataFieldLastModified});
        $publishedDate = $publishedBaselines->{$baseline}->{dataFieldLastPublished}
            if exists ($publishedBaselines->{$baseline}->{dataFieldLastPublished});
        $active = $publishedBaselines->{$baseline}->{dataFieldActive}
            if exists ($publishedBaselines->{$baseline}->{dataFieldActive});
    }

    my $infoNode = XML::LibXML::Element->new('dataFieldPublishedBaselineInfo');
    $infoNode->appendTextChild( 'type', 'dataFieldPublishedBaselineInfo');

    my $baselineNode = XML::LibXML::Element->new('dataFieldPublishedBaseline');
    $baselineNode->appendTextChild( 'type', 'text');
    $baselineNode->appendTextChild( 'value', $baseline);

    my $modifiedDateNode = XML::LibXML::Element->new('dataFieldModifiedDate');
    $modifiedDateNode->appendTextChild( 'type', 'datetime');
    $modifiedDateNode->appendTextChild( 'value', $modifiedDate);

    my $publishedDateNode = XML::LibXML::Element->new('dataFieldPublishedDate');
    $publishedDateNode->appendTextChild( 'type', 'datetime');
    $publishedDateNode->appendTextChild( 'value', $publishedDate);

    my $activeNode = XML::LibXML::Element->new('dataFieldActive');
    $activeNode->appendTextChild( 'type', 'boolean');
    $activeNode->appendTextChild( 'value', $active);

    my $valueNode = XML::LibXML::Element->new('value');
    $valueNode->addChild($baselineNode);
    $valueNode->addChild($modifiedDateNode);
    $valueNode->addChild($publishedDateNode);
    $valueNode->addChild($activeNode);
    $infoNode->addChild($valueNode);

    return($infoNode);
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

EDDA - Module for EDDA

=head1 SYNOPSIS

  use EDDA;
  $dataFieldIds = getDataProductDataFieldIds($dataProductDoc)
  getPublishedBaselines($dataFieldId, $mode, \@baselines, $publishedDataFieldDir, $parser)
  createPublishedBaselineInfoNode()

=head1 DESCRIPTION

  getDataProductDataFieldIds($dataProductDoc) : returns reference to an array of dataFieldId values in the document $dataProductDoc

  getPublishedBaselines: returns a reference to a hash whose keys are baseline identifiers and whose values are a reference to a hash of attributes of publication information

  createPublishedBaselineInfoNode: returns an xml node containing publication information for a single baseline


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

Ed Seiler, E<lt>eseiler@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ed Seiler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
