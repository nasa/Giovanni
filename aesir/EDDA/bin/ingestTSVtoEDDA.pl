#!/usr/bin/perl

=head1 NAME

ingestTSVtoEDDA - Ingest a tab-separated text formatted file to an EDDA product or variable

=head1 PROJECT

AESIR EDDA

=head1 SYNOPSIS

ingestTSVtoEDDA --outdir <output file directory> filename

=head1 DESCRIPTION

Ingest a tab-separated text formatted file to an EDDA product or variable

=head1 OPTIONS

=over 4

=item format

Default is tsv (tab-separated values)

=back

=head1 AUTHOR

Ed Seiler, E<lt>Ed.Seiler@nasa.govE<gt>

=cut

my ($rootPath);

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
}

use strict;
use File::Basename;
use XML::LibXML;
use XML::LibXSLT;
use XML::Simple;

#use XML::XML2JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use URI;
use Getopt::Long;
use Safe;

my $usage = "Usage: $0 infile\n";
my $help;
my $quiet;

Getopt::Long::GetOptions( 'help' => \$help, 'quiet' => \$quiet );
if ($help) {
    print $usage;
    exit 0;
}

my $inArg = $ARGV[0];
die "First argument must be a readable file or directory\n$usage"
    unless -r $inArg;

#my $outDir = $ARGV[1];
#die "Second argument must be a writeable directory\n$usage" unless -d $outDir && -w $outDir;
#die "Output directory must not be the same as the input directory\n$usage" if ($outDir eq $inArg);

my $cfgFile = $rootPath . 'cfg/EDDA/edda.cfg';
my $cpt     = Safe->new('CFG');
unless ( $cpt->rdo($cfgFile) ) {
    die "Could not read EDDA configuration file $cfgFile\n";
}

my @inFiles;
if ( -d $inArg ) {
    die "Could not open directory $inArg for reading: $!\n"
        unless opendir( DIR, $inArg );
    @inFiles = grep { !/^\./ && -f "$inArg/$_" } readdir(DIR);
    closedir(DIR);
    @inFiles = map( "$inArg/$_", @inFiles );
}
else {
    @inFiles = ($inArg);
}

my $hSep = "\t";

#my $vSep = "\x0A";  # new line
#my $vSep = "\x0B";  # vertical tab
#my $vSep = "\x0C";  # form feed
#my $vSep = "\x0D";  # carriage return
my $vSep    = '|';
my $vSepPat = '\|';

my $parser = XML::LibXML->new();
$parser->keep_blanks(0);

foreach my $inFile (@inFiles) {

    # Open input file for reading
    open( IN, "< $inFile" ) or die "Could not open $inFile for reading\n";

    # Read first line of file. Expect it to contain the names of the
    # AESIR fields, separated by the field separator
    my $header = <IN>;
    chomp($header);
    my @inputFieldNames = split( $hSep, $header );

    # Determine the table type (data product or data field) by the name of the
    # first field, and select the corresponding stylesheet for constructing
    # the full EDDA xml
    my $type;
    my $styleSheetFile;
    my $styleSheet;
    my $xslt = XML::LibXSLT->new();
    if ( $inputFieldNames[0] =~ /^dataField/ ) {
        $type           = 'dataField';
        $styleSheetFile = "$CFG::EDDA_CFG_DIR/edda_df_basic_to_full.xsl";
    }
    elsif ( $inputFieldNames[0] =~ /^dataProduct/ ) {
        $type           = 'dataProduct';
        $styleSheetFile = "$CFG::EDDA_CFG_DIR/edda_dp_basic_to_full.xsl";
    }
    else {
        $type = 'unknown';
    }
    if ($styleSheetFile) {
        eval { $styleSheet = $xslt->parse_stylesheet_file($styleSheetFile); };
        if ($@) {
            die "Error parsing stylesheet $styleSheetFile: $@";
        }
    }

    # Process/ingest each line of the table
    while ( my $inLine = <IN> ) {
        chomp($inLine);
        my %newFields;
        my @fieldVals = split( $hSep, $inLine );

        # Convert the table line to a simple xml tree, with each node name
        # equal to the value found in the corresponding element of the header
        # line
        my $root = XML::LibXML::Element->new($type);
        foreach my $fieldName (@inputFieldNames) {
            $newFields{$fieldName} = shift @fieldVals;
        }

        # If there is a mismatch between the number of fields/columns in the
        # header line and the number of fields/columns in a table line,
        # skip the line.
        if (@fieldVals) {
            print STDERR scalar(@fieldVals),
                " values too many in table line: $inLine\n";
            next;
        }

        # Ingest the full or updated EDDA xml
        my $baseUrl = $CFG::BASELINE_CONFIG->{$CFG::EDDA_BASELINE}
            ->{EDDA_CGI_BASE_URL};
        my @outputFieldNames = @inputFieldNames;
        if ( $type eq 'dataProduct' ) {
            my $id = $newFields{'dataProductId'};

            my $dataProductsDir = "$CFG::AESIR_CATALOG_DATA_PRODUCTS_DIR";
            my $productFile     = join( '/', $dataProductsDir, $id );
            my $existingHash    = {};
            my $verb            = 'create';
            if ( -f $productFile ) {

               # A dataProduct file already exists for this dataProductId,
               # so update the existing dataProduct with values from the table
                $verb = 'update';
                $baseUrl .= 'updateDataProductInfo';
                my $existingDom;
                eval { $existingDom = $parser->parse_file($productFile); };
                if ($@) {
                    print STDERR "Error parsing $productFile: $@\n";
                    next;
                }
                my $existingDoc = $existingDom->documentElement();
                my @existingFieldNames;

                # Store values found in existing dataProduct file into a hash
                extract( $existingDoc, $vSep, \@existingFieldNames,
                    $existingHash );

                # In order to update, the dataProductLastModified value in
                # the updated content must match the value in the existing
                # file
                my $existingLastMod
                    = $existingHash->{dataProductLastModified};
                if ($existingLastMod) {
                    $newFields{dataProductLastModified} = $existingLastMod;
                }

                # Allow the input table to contain new field names to be
                # added to the existing names
                @outputFieldNames = @existingFieldNames;
                foreach my $fieldName (@inputFieldNames) {
                    push @outputFieldNames, $fieldName
                        unless exists $existingHash->{$fieldName};
                }
            }
            else {
                $baseUrl .= 'createNewDataProduct';
            }

            my %newHash;
            foreach my $fieldName (@outputFieldNames) {
                if ( exists $existingHash->{$fieldName} ) {
                    if ( ( exists $newFields{$fieldName} )
                        && $existingHash->{$fieldName} ne
                        $newFields{$fieldName} )
                    {

                        # Update existing values with new values
                        # if they are different
                        $newHash{$fieldName} = $newFields{$fieldName};
                        unless ($quiet) {
                            print "$fieldName changed from ",
                                $existingHash->{$fieldName}, " to ",
                                $newFields{$fieldName}, "\n";
                        }
                    }
                    else {

                        # Keep existing values if they have not changed
                        $newHash{$fieldName} = $existingHash->{$fieldName};
                    }
                }
                else {

                    # Add new fields
                    $newHash{$fieldName} = $newFields{$fieldName};
                }
            }

            # Transform from a hash to a simple xml tree to the full EDDA xml
            foreach my $fieldName (@outputFieldNames) {
                my $node = XML::LibXML::Element->new($fieldName);

            # Handle multi-valued fields, which have values separated by $vSep
                my @vals = split( $vSepPat, $newHash{$fieldName} );
                if (@vals) {
                    foreach my $val (@vals) {
                        $node->appendTextChild( 'value', $val );
                    }
                }
                else {
                    $node->appendTextChild( 'value', '' );
                }

                $root->addChild($node);
            }
            my $transform_string;
            if ($styleSheet) {
                my $transform = $styleSheet->transform($root);
                $transform_string = $styleSheet->output_string($transform);

                #                print $transform_string;
                unless ($transform_string) {
                    print STDERR "Unexpected input line: $inLine\n";
                }
            }

            # POST a request to ingest or update the full EDDA xml
            my $uri    = URI->new($baseUrl);
            my $params = {};
            $params->{comment} = "$0 Ingested $id from $inFile";
            $uri->query_form($params);
            my $ingestUrl = $uri->as_string;
            my $request   = HTTP::Request::Common::POST(
                $ingestUrl,
                Content_Type => 'application/xml',
                Content      => $transform_string
            );
            my $ua       = LWP::UserAgent->new();
            my $response = $ua->request($request);

            unless ( $response->is_success ) {
                print STDERR "Failed to $verb product with id $id\n";
                if ( $response->content ) {
                    print STDERR '  ', $response->content, "\n";
                }
                next;
            }
            else {
                my $dom = $parser->parse_string( $response->content );
                my $doc = $dom->documentElement();
                my ($statusNode)
                    = $doc->findnodes('/createNewDataProductResponse/status');
                if ( $statusNode && $statusNode->textContent ne '1' ) {
                    print STDERR "Failed to $verb product with id $id\n";
                    my ($errorCodeNode)
                        = $doc->findnodes(
                        '/createNewDataProductResponse/errorCode');
                    my ($errorMessageNode)
                        = $doc->findnodes(
                        '/createNewDataProductResponse/errorMessage');
                    if ($errorMessageNode) {
                        print STDERR '  ', $errorMessageNode->textContent,
                            "\n";
                    }
                    next;
                }
                else {
                    print "${verb}d product with id $id\n";
                }
            }
        }
        elsif ( $type eq 'dataField' ) {
            my $id = $newFields{'dataFieldId'};
            my $descriptionString
                = 'Product id='
                . $newFields{'dataFieldProductId'}
                . ' Access name='
                . $newFields{'dataFieldAccessName'};

            my $dataFieldsDir = "$CFG::AESIR_CATALOG_DATA_FIELDS_DIR";
            my $fieldFile     = join( '/', $dataFieldsDir, $id );
            my $existingHash  = {};
            if ( -f $fieldFile ) {

                # A dataField file already exists for this dataFieldId,
                # so update the existing dataField with values from the table
                $baseUrl .= 'updateDataFieldInfo';
                my $existingDom;
                eval { $existingDom = $parser->parse_file($fieldFile); };
                if ($@) {
                    print STDERR "Error parsing $fieldFile: $@\n";
                    next;
                }
                my $existingDoc = $existingDom->documentElement();
                my @existingFieldNames;

                # Store values found in existing dataField file into a hash
                extract( $existingDoc, $vSep, \@existingFieldNames,
                    $existingHash );

                # In order to update, the dataFieldLastModified value in
                # the updated content must match the value in the existing
                # file
                my $existingLastMod = $existingHash->{dataFieldLastModified};
                if ($existingLastMod) {
                    $newFields{dataFieldLastModified} = $existingLastMod;
                }

                # Allow the input table to contain new field names to be
                # added to the existing names
                @outputFieldNames = @existingFieldNames;
                foreach my $fieldName (@inputFieldNames) {
                    push @outputFieldNames, $fieldName
                        unless exists $existingHash->{$fieldName};
                }
            }
            else {
                $baseUrl .= 'createNewDataField';
            }

            my %newHash;
            foreach my $fieldName (@outputFieldNames) {
                if ( exists $existingHash->{$fieldName} ) {
                    if ( ( exists $newFields{$fieldName} )
                        && $existingHash->{$fieldName} ne
                        $newFields{$fieldName} )
                    {

                        # Update existing values with new values
                        # if they are different
                        $newHash{$fieldName} = $newFields{$fieldName};
                        unless ($quiet) {
                            print "$fieldName changed from ",
                                $existingHash->{$fieldName}, " to ",
                                $newFields{$fieldName}, "\n";
                        }
                    }
                    else {

                        # Keep existing values if they have not changed
                        $newHash{$fieldName} = $existingHash->{$fieldName};
                    }
                }
                else {

                    # Add new fields
                    $newHash{$fieldName} = $newFields{$fieldName};
                }
            }

            # Transform from a hash to a simple xml tree to the full EDDA xml
            foreach my $fieldName (@outputFieldNames) {
                my $node = XML::LibXML::Element->new($fieldName);

            # Handle multi-valued fields, which have values separated by $vSep
                my @vals = split( $vSepPat, $newHash{$fieldName} );
                if (@vals) {
                    foreach my $val (@vals) {
                        $node->appendTextChild( 'value', $val );
                    }
                }
                else {
                    $node->appendTextChild( 'value', '' );
                }

                $root->addChild($node);
            }
            my $transform_string;
            if ($styleSheet) {
                my $transform = $styleSheet->transform($root);
                $transform_string = $styleSheet->output_string($transform);

                #                print $transform_string;
                unless ($transform_string) {
                    print STDERR "Unexpected input line: $inLine\n";
                }
            }

            # POST a request to ingest or update the full EDDA xml
            my $uri    = URI->new($baseUrl);
            my $params = {};
            $params->{comment} = "$0 Ingested $id from $inFile";
            $uri->query_form($params);
            my $ingestUrl = $uri->as_string;
            my $request   = HTTP::Request::Common::POST(
                $ingestUrl,
                Content_Type => 'application/xml',
                Content      => $transform_string
            );
            my $ua       = LWP::UserAgent->new();
            my $response = $ua->request($request);

            unless ( $response->is_success ) {
                print STDERR
                    "Failed to create dataField for $descriptionString\n";
                if ( $response->content ) {
                    print STDERR $response->content, "\n";
                }
                next;
            }
            else {
                my $dom = $parser->parse_string( $response->content );
                my $doc = $dom->documentElement();
                if ( $baseUrl =~ /createNewDataField/ ) {
                    my ($statusNode)
                        = $doc->findnodes(
                        '/createNewDataFieldResponse/status');
                    my $createdId;
                    my ($idNode)
                        = $doc->findnodes(
                        '/createNewDataFieldResponse/result/dataField/dataFieldId/value'
                        );
                    if ($idNode) {
                        $createdId = $idNode->textContent;
                    }
                    if ( $statusNode && $statusNode->textContent ne '1' ) {
                        unless ($id) {
                            $id = $descriptionString;
                        }
                        print STDERR
                            "Failed to create dataField with id $id\n";
                        my ($errorCodeNode)
                            = $doc->findnodes(
                            '/createNewDataFieldResponse/errorCode');
                        my ($errorMessageNode)
                            = $doc->findnodes(
                            '/createNewDataFieldResponse/errorMessage');
                        if ($errorMessageNode) {
                            print STDERR '  ', $errorMessageNode->textContent,
                                "\n";
                        }
                        next;
                    }
                    else {
                        if ($createdId) {
                            print "Created dataField with id $createdId\n";
                            if ( $id && ( $id ne $createdId ) ) {
                                print "  (Id in table was $id)\n";
                            }
                        }
                        else {
                            print
                                "Created dataField but no dataFieldId found in response for $descriptionString\n";
                        }
                    }
                }
                else {
                    my ($statusNode)
                        = $doc->findnodes('/updateResponse/status');
                    my $updatedId;
                    my ($idNode)
                        = $doc->findnodes(
                        '/updateResponse/result/dataField/dataFieldId/value');
                    if ($idNode) {
                        $updatedId = $idNode->textContent;
                    }
                    if ( $statusNode && $statusNode->textContent ne '1' ) {
                        my ($errorCodeNode)
                            = $doc->findnodes('/updateResponse/errorCode');
                        my ($errorMessageNode)
                            = $doc->findnodes('/updateResponse/errorMessage');
                        unless ($id) {
                            $id = $descriptionString;
                        }
                        print STDERR
                            "Failed to update dataField with id $id\n";
                        if ($errorMessageNode) {
                            print STDERR '  ', $errorMessageNode->textContent,
                                "\n";
                        }
                        next;
                    }
                    else {
                        if ($updatedId) {
                            print "Updated dataField with id $updatedId\n";
                            if ( $id && ( $id ne $updatedId ) ) {
                                print "  (Id in table was $id)\n";
                            }
                        }
                        else {
                            print
                                "Updated dataField but no dataFieldId found in response for $descriptionString\n";
                        }
                        unless ($quiet) { print "\n"; }
                    }
                }
            }
        }
    }
}

sub extract {
    my ( $doc, $vSep, $fieldNames, $docHash ) = @_;

    foreach my $node ( $doc->childNodes ) {
        my $name  = $node->nodeName;
        my $field = XMLin( $node->toString );
        my $type  = $field->{type};

        #        my $multiplicity = $field->{multiplicity};
        my $value = $field->{value};
        if ( $type eq 'container' ) {

          # A container contains other fields, and has a field name we will
          # not include in the list of field names. Recursively call extract()
          # the extract field information from the container's value node
            ( my $childNode ) = $node->getChildrenByTagName('value');
            extract( $childNode, $vSep, $fieldNames, $docHash );
        }
        else {
            if ( ref($value) eq 'HASH' ) {

                # This should only happen if value has attributes.
                # Expect attributes only for longId in dataProduct.
                $docHash->{$name} = $value->{longId};
            }
            elsif ( ref($value) eq 'ARRAY' ) {

                # Multi-valued fields are converted to a string of values
                # separated by $vSep.
                my @vals;
                foreach my $val (@$value) {
                    if ( ref($val) eq 'HASH' ) {

                        # This should only happen if value has attributes.
                        # Expect attributes only for longId in dataProduct.
                        push @vals, $val->{longId};
                    }
                    else {
                        push @vals, $val;
                    }
                }
                $docHash->{$name} = join( $vSep, @vals );
            }
            else {

                # Single-valued field
                $docHash->{$name} = $value;
            }
            push @$fieldNames, $name;
        }
    }
}

exit 0;
