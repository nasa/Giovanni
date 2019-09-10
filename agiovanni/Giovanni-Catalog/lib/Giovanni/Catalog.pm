package Giovanni::Catalog;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use LWP::UserAgent;
use XML::LibXML;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Giovanni::Catalog ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
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

# Preloaded methods go here.

#Constructor
sub new {
    my ( $class, $input ) = @_;
    my $self = {};
    $self->{__URL} = $input->{URL} if defined $input->{URL};
    $self->{__XPATH} = {
        'specialFeatures'    => './arr[@name="dataProductSpecialFeatures"]',
        'osdd'               => './str[@name="dataProductOsddUrl"]',
        'sampleFile'         => './str[@name="dataProductSampleGranuleUrl"]',
        'sampleOpendap'      => './str[@name="dataProductOpendapUrl"]',
        'url'                => './str[@name="sswBaseSubsetUrl"]',
        'dataLocation'       => './str[@name="dataFieldDataLocation"]',
        'parameterDepth'     => './str[@name="dataFieldDepth"]',
        'parameterDepthUnit' => './str[@name="dataFieldDepthUnits"]',
        'sdsName'            => './str[@name="dataFieldSdsName"]',
        'quantity_type'      => './arr[@name="dataFieldMeasurement"]/str',
        'dataProductVersion' => './str[@name="dataProductVersion"]',
        'dataProductShortName' => './str[@name="dataProductShortName"]',
        'responseFormat'       => './str[@name="dataProductResponseFormat"]',
        'long_name'            => './str[@name="dataFieldLongName"]',
        'resolution' => './str[@name="dataProductSpatialResolution"]',
        'dataProductTimeFrequency' =>
            './int[@name="dataProductTimeFrequency"]',
        'dataProductTimeInterval' => './str[@name="dataProductTimeInterval"]',
        'dataProductStartTimeOffset' =>
            './int[@name="dataProductStartTimeOffset"]',
        'dataProductEndTimeOffset' =>
            './int[@name="dataProductEndTimeOffset"]',
        'dataProductBeginDateTime' =>
            './date[@name="dataProductBeginDateTime"]',
        'startTime' => './date[@name="dataProductBeginDateTime"]',
        'dataProductEndDateTime' => './date[@name="dataProductEndDateTime"]',
        'endTime'                => './date[@name="dataProductEndDateTime"]',
        'west'                   => './float[@name="dataProductWest"]',
        'south'                  => './float[@name="dataProductSouth"]',
        'east'                   => './float[@name="dataProductEast"]',
        'north'                  => './float[@name="dataProductNorth"]',
        'virtualDataFieldGenerator' =>
            './str[@name="virtualDataFieldGenerator"]',
        'vectorComponents' => './str[@name="dataFieldVectorComponentNames"]',
        'sld'              => './str[@name="dataFieldSldUrl"]',
        'accessFormat'     => './str[@name="dataFieldAccessFormat"]',
        'accessMethod'     => './str[@name="dataFieldAccessMethod"]',
        'accessName'       => './str[@name="dataFieldAccessName"]',
        'searchIntervalDays' =>
            './float[@name="dataProductSearchIntervalDays"]',
        'fillValueFieldName'  => './str[@name="dataFieldFillValueFieldName"]',
        'dataFieldUnitsValue' => './str[@name="dataFieldUnits"]',
        'dataFieldStandardName' => './str[@name="dataFieldStandardName"]',
        'zDimName'              => './str[@name="dataFieldZDimensionName"]',
        'zDimUnits'             => './str[@name="dataFieldZDimensionUnits"]',
        'zDimValues'            => './str[@name="dataFieldZDimensionValues"]',
        'deflationLevel'        => './int[@name="dataFieldDeflationLevel"]',
        'validMin'              => './*[@name="dataFieldMinValid"]',
        'validMax'              => './*[@name="dataFieldMaxValid"]',
        'nominalMax'            => './*[@name="dataFieldNominalMaxValue"]',
        'nominalMin'            => './*[@name="dataFieldNominalMinValue"]',
        'accumulatable'         => './bool[@name="dataFieldAccumulatable"]',
        'dataProductPlatformInstrument' =>
            './arr[@name="dataProductPlatformInstrument"]/str',
        'latitudeResolution' =>
            './*[@name="dataProductSpatialResolutionLatitude"]',
        'longitudeResolution' =>
            './*[@name="dataProductSpatialResolutionLongitude"]',
        'spatialResolutionUnits' =>
            './*[@name="dataProductSpatialResolutionUnits"]',
        'valuesDistribution' => './*[@name="dataFieldValuesDistribution"]',
        'searchFilter'       => './*[@name="dataFieldSearchFilter"]',
        'timeIntvRepPos'      => './*[@name="dataFieldTimeIntvRepPos"]',
        'oddxDims'           => './*[@name="dataProductOddxDims"]',
    };

    # Default values
    $self->{_DEFAULTS} = { 'timeIntvRepPos' => 'start', };

    # An anonymous sub to query AESIR and return XML doc
    $self->{__QUERY_CATALOG} = sub {
        my ($query) = @_;
        my $url     = $self->{__URL} . $query;
        my $agent   = LWP::UserAgent->new();
        $agent->env_proxy;
        my $response  = $agent->get($url);
        my $xmlParser = XML::LibXML->new();
        if ( $response->is_success() ) {
            my $inDom;
            eval {
                $inDom = $xmlParser->parse_string( $response->content() );
            } or do {

                # Handle XML parsing error
                return undef;
            };
            return $inDom;
        }
        return undef;
    };
    return bless( $self, $class );
}

# Gets data field(s) info from the catalog
sub getDataFieldInfo {
    my ( $self, $input ) = @_;

    # A hash ref to hold return value: primary keys are data field IDs and
    # secondary keys are data field attributes
    my $output = {};

    # Create an LWP agent to query catalog
    my $agent = LWP::UserAgent->new();
    $agent->env_proxy;

    # Create a DOM parser for XML
    my $xmlParser = XML::LibXML->new();

 #  Xpath to parse XML response from the catalog and its mapping to attributes
 # used in Giovanni; candidate for configuration item in future
    my $fieldsXpath = $self->{__XPATH};

    # Make a copy of list of data fields; don't want to affect the copy in
    # caller
    my @dataFieldList = @{ $input->{FIELDS} };

    # Loop for each field and find its metadata
DATA_FIELD: foreach my $dataField (@dataFieldList) {
        $dataField =~ s/^\s+|\s+$//g;

        # Form the query for data field in question
        my $url
            = $self->{__URL}
            . '/select/?q=*&fq=dataFieldId:'
            . qq("$dataField");

        # Query the catalog
        my $response = $agent->get($url);
        if ( $response->is_success() ) {

            # If the query is successful, continue to parse the result
            my $inDom;
            eval {
                $inDom = $xmlParser->parse_string( $response->content() );
            } or do {
                # Handle XML parsing error
                next DATA_FIELD;
            };
            my $inDoc = $inDom->documentElement();

            # Find number of hits and proceed further if it is greater than 1
            my $numDoc = $inDoc->findvalue(
                '/response/result[@name="response"]/@numFound');
            next DATA_FIELD unless ( defined $numDoc and $numDoc >= 1 );

        XPATH_LOOP: foreach my $key ( keys %$fieldsXpath ) {
                my @nodeList = $inDoc->findnodes(
                    '/response/result/doc/' . $fieldsXpath->{$key} );
                if ( not @nodeList ) {

                # If the attribute doesn't exist, use default value if defined
                    $output->{$dataField}{$key} = $self->{_DEFAULTS}{$key}
                        if exists $self->{_DEFAULTS}{$key};
                    next XPATH_LOOP unless @nodeList;
                }
                elsif ( $key eq 'specialFeatures' ) {

                    # Set the climatology flag
                    foreach my $node (@nodeList) {
                        $output->{$dataField}{climatology} = "true"
                            if (
                            lc( $node->textContent() ) eq 'climatology' );
                    }
                }

                # Create a comma separated list of data sources
                elsif ( $key eq 'dataProductPlatformInstrument' ) {
                    $output->{$dataField}{dataProductPlatformInstrument}
                        = join( ', ', map( $_->textContent(), @nodeList ) );
                }
                else {
                    $output->{$dataField}{$key} = $nodeList[0]->textContent();
                }
            }

            # Concatenate variable depth value and unit
            if (   exists $output->{$dataField}
                && exists $output->{$dataField}{parameterDepth}
                && $output->{$dataField}{parameterDepth} ne '' )
            {
                $output->{$dataField}{parameterDepth}
                    .= ' ' . $output->{$dataField}{parameterDepthUnits}
                    if exists $output->{$dataField}{parameterDepthUnits};
                $output->{$dataField}{quantity_type}
                    .= ' ' . $output->{$dataField}{parameterDepth};
            }

            # Set the searchIntervalDays based on the temporal resolution,
            # if it hasn't been set already
            if ( not exists $output->{$dataField}{searchIntervalDays} ) {
                my $timeResolution = $output->{$dataField}{dataProductTimeInterval};

                # Default time search chunk length is a year for daily data
                my $searchIntervalDays = '365.0';

                # Reduce or increase the chunk size so we get approximately
                # 365 results per chunk
                if ( $timeResolution eq 'half-hourly' ) {
                    $searchIntervalDays = '7.0';
                }
                elsif ( $timeResolution eq 'hourly' ) {
                    $searchIntervalDays = '15.0';
                }
                elsif ( $timeResolution eq '3-hourly' ) {
                    $searchIntervalDays = '46.0';
                }
                elsif ( $timeResolution eq '8-daily' ) {
                    $searchIntervalDays = '2920.0';
                }
                elsif ( $timeResolution eq 'monthly' ) {
                    $searchIntervalDays = '10000.0';
                }

                $output->{$dataField}{searchIntervalDays} = $searchIntervalDays;
            }
        }
        else {

            # Catalog query fails; handle the error
        }
    }
    return $output;
}

# Gets all active data field(s) from the catalog
sub getActiveDataFields {
    my ( $self, @attrList ) = @_;

    # By default, get all known fields
    @attrList = keys %{ $self->{__XPATH} } unless @attrList;

    # Hash ref to store data field information
    my $output = {};

    # Query the catalog for number of items
    my $query = '/select?q=*&fq=dataFieldActive:True&rows=0';
    my $inDom = $self->{__QUERY_CATALOG}($query);
    return $output unless defined $inDom;
    my $numFound = $inDom->documentElement()
        ->findvalue('/response/result[@name="response"]/@numFound');
    return $output unless $numFound;

    # Reform the query once you know how many rows to request
    $query = '/select?q=*&fq=dataFieldActive:True&rows=' . $numFound;
    $inDom = $self->{__QUERY_CATALOG}($query);
    return $output unless defined $inDom;
    my $inDoc = $inDom->documentElement();
    foreach my $doc ( $inDoc->findnodes('/response/result/doc') ) {
        my $dataField = $doc->findvalue('./str[@name="dataFieldId"]');
        foreach my $attr (@attrList) {
            my ($node) = $doc->findnodes( $self->{__XPATH}{$attr} );
            next unless defined $node;
            $output->{$dataField}{$attr} = $node->textContent();
        }
    }
    return $output;
}

# Gets all active  - non monthly datafields (not used in caching)
sub getActiveNonMonthlyDataFields{
    my ( $self, @attrList ) = @_;

    # By default, get all known fields
    @attrList = keys %{ $self->{__XPATH} } unless @attrList;

    # Hash ref to store data field information
    my $output = {};

    # Query the catalog for number of items
    my $query = '/select?q=*&fq=(dataFieldActive:true%20and%20NOT%20(dataProductTimeInterval:monthly%20))&rows=0';
    my $inDom = $self->{__QUERY_CATALOG}($query);
    return $output unless defined $inDom;
    my $numFound = $inDom->documentElement()
        ->findvalue('/response/result[@name="response"]/@numFound');
    return $output unless $numFound;

    # Reform the query once you know how many rows to request
    $query = '/select?q=*&fq=(dataFieldActive:true%20and%20NOT%20(dataProductTimeInterval:monthly%20))&rows=' . $numFound;
    $inDom = $self->{__QUERY_CATALOG}($query);
    return $output unless defined $inDom;
    my $inDoc = $inDom->documentElement();
    foreach my $doc ( $inDoc->findnodes('/response/result/doc') ) {
        my $dataField = $doc->findvalue('./str[@name="dataFieldId"]');
        foreach my $attr (@attrList) {
            my ($node) = $doc->findnodes( $self->{__XPATH}{$attr} );
            next unless defined $node;
            $output->{$dataField}{$attr} = $node->textContent();
        }
    }
    return $output;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Giovanni::Catalog - Class for interaction with Giovanni's data catalog.

=head1 SYNOPSIS

 use Giovanni::Catalog;
 my $catalog=Giovanni::Catalog->new({URL=>"http://s4ptu-ts2/solr/"});
 my $fieldHash=$catalog->getDataFieldInfo({FIELDS=>[qw(MOD08)]);

=head1 DESCRIPTION

Giovanni::Catalog encapsulates Giovanni's data catalog. Data catalog has
information about data fields including its name, URL for accessing the field
etc.

=head1 CONSTRUCTOR

=over 4

=item new({URL=>"URL for catalog"})

The constructor for Giovanni::Catalog accepts a hash ref as argument. The
hash value indicated by hash key C<URL> points to the URL for the catalog.

=back

=head1 METHODS

=over 4

=item getDataFieldInfo({FIELDS=>[field IDs]})

getDataFieldInfo() accepts a hash ref as argument. The hash value indicated by
hash key C<FIELDS> is a ref to array containing data field IDs. It returns a
hash ref whose first level keys are field IDs and second level keys are field ID
attributes with corresponding attribute values.

=back

=over 4

=item getActiveDataFields([{attr1=>xpath1,...}])

getActiveDataFields() optionally accepts a hash as argument. To extract
standard attributes, ones used by Giovanni, no argument needs to be
passed. The hash keys are attributes
to be extracted. Corresponding values are XPATH expressions to be used in
extracting them from Solr response. It returns a hash ref whose first level
keys are field IDs and second level keys are field ID
attributes with corresponding attribute values.

=back

=head1 EXPORT

All.

=head1 SEE ALSO


=head1 AUTHOR

Mahabaleshwara S. Hegde, E<lt>Mahabaleshwa.S.Hegde@nasa.gov<gt>

=cut
