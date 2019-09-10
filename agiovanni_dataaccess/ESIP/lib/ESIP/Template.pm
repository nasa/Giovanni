#$Id: Template.pm,v 1.4 2014/11/25 15:19:39 csmit Exp $
#-@@@ Giovanni, Version $Name:  $
package ESIP::Template;

use URI;
use URI::Escape;
use CGI;

sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    # need parameter
    if ( !$self->{template} ) {
        die "'template' is a required parameter";
    }
    if ( !$self->{localNameToUri} ) {
        die "'localNameToUri' is a required parameter";
    }

    my $uriToLocalName = {};
    for my $localName ( keys %{ $self->{localNameToUri} } ) {
        my $uri = $self->{localNameToUri}->{$localName};
        $uriToLocalName->{$uri} = $localName;
    }

    $self->{uriToLocalName} = $uriToLocalName;

    $self->_parseTemplate();

    return $self;
}

# Parse out the template to find all the mandatory and optional parameters
sub _parseTemplate {
    my ($self) = @_;

    my @templateParams = ( $self->{template} =~ m/({.*?})/g );

    # Go through all the query elements. These will be divided into three
    # categories: (1) mandatory template element, (2) optional template
    # elements, and (3) non-templated elements
    for my $templateParam (@templateParams) {
        if ( $templateParam =~ /^{(.*)[?]}$/ ) {

            # this is an optional template element
            my ( $uri, $opensearchParameter )
                = $self->_getUriAndParameter($1);
            $self->{optionalParameters}->{$uri}->{$opensearchParameter} = 1;

        }
        elsif ( $templateParam =~ /^{(.*)}$/ ) {

            # this is a mandatory template element
            my ( $uri, $opensearchParameter )
                = $self->_getUriAndParameter($1);
            $self->{mandatoryParameters}->{$uri}->{$opensearchParameter} = 1;
        }
    }
}

# if this is, for example, gio:box, return
# "http://a9.com/-/opensearch/extensions/geo/1.0/" and box. Basically translate
# the local name into a uri.
sub _getUriAndParameter {
    my ( $self, $templateElement ) = @_;

    my @pieces = split( ':', $templateElement );
    if ( scalar(@pieces) == 1 ) {

        # we need the global uri
        return ( $self->{localNameToUri}->{""}, $pieces[0] );
    }
    else {
        return ( $self->{localNameToUri}->{ $pieces[0] }, $pieces[1] );
    }
}

# Checks to see if the template has a particular parameter and whether or not
# it is mandatory.
sub hasParameter {
    my ( $self, $uri, $openSearchParameter ) = @_;
    my $hasParam    = 0;
    my $isMandatory = 0;
    if ( $self->{optionalParameters}->{$uri}->{$openSearchParameter} ) {
        $hasParam = 1;
    }
    elsif ( $self->{mandatoryParameters}->{$uri}->{$openSearchParameter} ) {
        $hasParam    = 1;
        $isMandatory = 1;
    }
    return ( $hasParam, $isMandatory );
}

sub getMandatoryParameters {
    my ($self) = @_;
    return $self->{mandatoryParameters};
}

sub getOptionalParameters {
    my ($self) = @_;
    return $self->{optionalParameters};
}

sub fillTemplate {

    # params
    # params{"uri"}->{"opensearchparameter"}=value;
    my ( $self, $beStrict, %params ) = @_;

    my $outputUrl = $self->{template};

    # put in the optional stuff
    for my $uri ( keys %{ $self->{optionalParameters} } ) {
        for my $opensearchParameter (
            keys %{ $self->{optionalParameters}->{$uri} } )
        {
            if ( $params{$uri} && $params{$uri}->{$opensearchParameter} ) {
                my $prefix = $self->{uriToLocalName}->{$uri};
                $value = uri_escape( $params{$uri}->{$opensearchParameter} );
                if ( $prefix eq "" ) {

                    # this is the default namespace, so no prefix
                    $outputUrl =~ s/{$opensearchParameter[?]}/$value/;
                }
                else {
                    $outputUrl =~ s/{$prefix:$opensearchParameter[?]}/$value/;
                }
            }

        }
    }

    # now the mandatory stuff
    for my $uri ( keys %{ $self->{mandatoryParameters} } ) {
        for my $opensearchParameter (
            keys %{ $self->{mandatoryParameters}->{$uri} } )
        {
            if ( $params{$uri} && $params{$uri}->{$opensearchParameter} ) {
                my $prefix = $self->{uriToLocalName}->{$uri};
                $value = uri_escape( $params{$uri}->{$opensearchParameter} );

                if ( $prefix eq "" ) {

                    # this is the default namespace, so no prefix
                    $outputUrl =~ s/{$opensearchParameter}/$value/;
                }
                else {
                    $outputUrl =~ s/{$prefix:$opensearchParameter}/$value/;
                }

            }
            elsif ($beStrict) {
                die
                    "Template requires mandatory parameter: '$uri',$opensearchParameter";
            }
        }
    }

    # remove any other template parameters that haven't been filled in
    $outputUrl =~ s/{.*?}//g;

    return $outputUrl;
}

1;
__END__

=head1 NAME

ESIP::OpenSearch - Perl extension for filling an opensearch template

=head1 SYNOPSIS

  use ESIP::Template;

  ...
  
  # the opensearch template string
  my $templateStr
      = "https://www.whatever.com:80/something?param=one&templateBox={geo:box}&templateCount={count?}&startTime={time:start}&endTime={time:end?}#stuff";
  
  # mapping from template namespaces to URIs. (Information contained in OSDD)
  my $localNameToUri = {};
  $localNameToUri->{"geo"}  = "http://a9.com/-/opensearch/extensions/geo/1.0/";
  $localNameToUri->{"time"} = "http://a9.com/-/opensearch/extensions/time/1.0/";
  $localNameToUri->{""}     = "http://a9.com/-/spec/opensearch/1.1/";

  # create a new template
  my $template = ESIP::Template->new(
      template       => $templateStr,
      localNameToUri => $localNameToUri
  );
  
  # fill in the bounding box
  %fills = ();
  $fills{"http://a9.com/-/opensearch/extensions/geo/1.0/"}->{box} = "-180,-90,180,90";
  my $url = $template->fillTemplate(0,%fills);

=head1 DESCRIPTION

This class fills in templates from an OSDD. It is used by ESIP::OSDD.

=head2 new

  # the opensearch template string
  my $templateStr
      = "https://www.whatever.com:80/something?param=one&templateBox={geo:box}&templateCount={count?}&startTime={time:start}&endTime={time:end?}#stuff";
  
  # mapping from template namespaces to URIs. (Information contained in OSDD)
  my $localNameToUri = {};
  $localNameToUri->{"geo"}  = "http://a9.com/-/opensearch/extensions/geo/1.0/";
  $localNameToUri->{"time"} = "http://a9.com/-/opensearch/extensions/time/1.0/";
  $localNameToUri->{""}     = "http://a9.com/-/spec/opensearch/1.1/";

  # create a new template
  my $template = ESIP::Template->new(
      template       => $templateStr,
      localNameToUri => $localNameToUri
  );


Create a template class. Inputs (hash):

=over 4

=item I<template> - the template URL string

=item I<localNameToUri> - a hash of the local name (e.g. the 'geo' in {geo:box})
to a URI. 

=back


=head2 fillTemplate

  %fills = ();
  $fills{"http://a9.com/-/opensearch/extensions/geo/1.0/"}->{box} = "-180,-90,180,90";
  my $url = $template->fillTemplate(0,%fills);

Fills the OSDD template and returns the resulting URL. Inputs:

=over 4

=item I<strict> - if set to a true value, the code will fail if mandatory elements
are not specified.

=item I<fills> - two layer hash from URI to parameter to value. E.g. - if the
template has a parameter {localName:parameter}, where 'localName' maps to URI
'http://myuri.com', then you will need to set 
$fills{'http://myuri.com'}-E<gt>{parameter}=$value.

=back


=head2 hasParameter

  my ( $hasParam, $isMandatory )
    = $template->hasParameter( "http://a9.com/-/opensearch/extensions/geo/1.0/", "box" );

Tells you if the template contains a particular parameter. Inputs:

=over 4

=item I<uri> - URI of parameter.

=item I<parameter> - the parameter.

=back

Returns a two element array:

=over 4

=item I<hasParam> - set to 1 if the template contains this parameter

=item I<isMandatory> - set to 1 if this is a mandatory template parameter

=back

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>


=cut
