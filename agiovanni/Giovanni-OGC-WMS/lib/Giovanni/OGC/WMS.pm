package Giovanni::OGC::WMS;

use 5.008008;
use strict;
use warnings;

#use URI;
#use URI::QueryParam;
use JSON qw( decode_json );
use LWP::UserAgent;
use Giovanni::Agent;
use Giovanni::Util;
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

#Constructor
sub new {
    my ( $class, $request ) = @_;
    my $self = {};
    bless( $self, $class );

    $self->{_AG_HOST} = $request->{'baseUrl'};
    my $parameters = $request->{'options'};
    $self->{_TIME_OUT} = $request->{'time_out'};

    # make the keys lowercase
    for my $key ( grep { lc($_) ne $_ } keys %$parameters ) {
        my $newkey = lc $key;
        $parameters->{$newkey} = $parameters->{$key};
        delete $parameters->{$key};
    }
    $self->{_OGC_PARA} = $parameters;
    my @layerList = split( /\,/, $parameters->{"layers"} );
    foreach my $layer (@layerList) {
        my @tString = split( /\./, $layer );
        my $data = $tString[1];
        $data =~ s/\+/\,/g;
        $self->{_LAYERS} .= $data . ",";
        if ( not defined $self->{_AG_SM_REQUEST} ) {

      # "layers" is <service>.<data field 1>[+<data field 2>+...<data fieldn>]
            my $service
                = $tString[0] =~ m/Time-Averaged/i ? "TmAvMp" : $tString[0];
            my $startTime = $parameters->{"starttime"};
            my $endTime   = $parameters->{"endtime"};
            my $bbox      = $parameters->{"bbox"};
            if ( $layer =~ /contour/i ) {
                $data =~ s/_contour//;
            }

            if ( defined $parameters->{"vert_slice"} ) {

                my $zStr = "\(z\=" . $parameters->{"vert_slice"} . "\)";
                $data .= $zStr;
            }

            # generate service manager request
            $self->{_AG_SM_REQUEST} = 
            Giovanni::Util::createAbsUrl("/giovanni/daac-bin/service_manager.pl?service=$service&data=$data&starttime=$startTime&endtime=$endTime&bbox=$bbox&portal=GIOVANNI&format=xml");

            # SLD is provided in 'getMap' request
            if ( defined $parameters->{"sld"} ) {
               $self->{_AG_SM_REQUEST}
                    .= "&options=[{\"options\":{\"name\":\"$tString[1]\",\"sld\":\""
                    . $parameters->{"sld"} . "\"}}]";
            }
        }
    }
    $self->{_LAYERS} = substr( $self->{_LAYERS}, 0, -1 );
    $self->{_SLD} = $parameters->{"sld"};
    return $self;
}

# submit and monitor service manager request, then submit getGiovanniMapInfo and agmap request to print WMS image
sub submitRequest () {

    my ($self) = @_;
    print STDERR $self->{_AG_SM_REQUEST} . "\n";

    # invoke service manager
    my $agent = Giovanni::Agent->new( URL => $self->{_AG_SM_REQUEST} );
    my $requestResponse = $agent->submit_request( $self->{_TIME_OUT} );
    if ( $requestResponse->errorMessage ) {
        return ogcErrorMessage( $requestResponse->errorMessage );
    }

    # submit getGiovanniInfo request
    my ($mapInfoUrl) = $requestResponse->abs_image_urls;
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    my $response = $ua->get("$mapInfoUrl");
    if ( $response->is_success ) {

        # parse the response of getGiovanniMapInfo
        my ($mapInfoString) = $response->content;
        my $mapInfo         = decode_json($mapInfoString);
        my $session         = $mapInfo->{"layers"}{"session"};
        my $resultset       = $mapInfo->{"layers"}{"resultset"};
        my $result          = $mapInfo->{"layers"}{"result"};
        my $mapfile         = $mapInfo->{"layers"}{"mapfile"};
        my @layers          = @{ $mapInfo->{"layers"}{"layer"} };
        my $sld;

        foreach my $layer (@layers) {
            if ( $layer->{type} eq "map" ) {
                my @sldInfo = @{ $layer->{"variable_sld"} };

                # select the first SLD
                $sld = $sldInfo[0]->{"url"};
            }
        }
        
        #encode format
        $self->{_OGC_PARA}{'format'} =~ s/\+/%2B/g;
        $self->{_OGC_PARA}{'format'} =~ s/image\/png; mode=8bit/image%2Fpng%3B%20mode%3D8bit/g;
        #generate agmap getMap request
        my $agMapReq = 
        Giovanni::Util::createAbsUrl("daac-bin/agmap.pl?service=wms&request=getmap&srs=epsg:4326&format=$self->{_OGC_PARA}{'format'}&transparent=true&layers=$self->{_LAYERS}&sld=$sld&mapfile=$mapfile&session=$session&resultset=$resultset&result=$result&bbox=$self->{_OGC_PARA}{'bbox'}&width=$self->{_OGC_PARA}{'width'}&height=$self->{_OGC_PARA}{'height'}&version=$self->{_OGC_PARA}{'version'}");
        print STDERR "request is $agMapReq \n";

        #invoke agmap getMap request
        my $ua1 = LWP::UserAgent->new;
        $ua1->env_proxy;
        my $response1 = $ua1->get("$agMapReq");
        if ( $response1->is_success ) {

            # print WMS image
            $self->{_IS_SUCCESS} = 1;    #print $agMapReq."\n";
            return $response1;           #->content;
        }
        else {
            return ogcErrorMessage( $response1->status_line );
        }
    }
    else {
        return ogcErrorMessage( $response->status_line );
    }
}

# print OGC error message in XML
sub ogcErrorMessage {
    my ($message) = @_;
    $message = defined $message ? $message : "AG WMS error";
    my $doc = XML::LibXML::Document->new('1.0', 'ISO-8859-1');
    my $root = $doc->createElement("ServiceExceptionReport");
    $root->setAttribute("version","1.1.1");
    my $node = $doc->createElement("ServiceException");
    $node->appendTextNode($message);
    $root->appendChild($node);
    $doc->setDocumentElement($root);
    my $ogcError = "Content-Type: text/xml\n\n";
    $ogcError .= $doc->toString();

}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Giovanni::OGC::WMS - Class for creating a WMS interface for AG

=head1 SYNOPSIS

  use Giovanni::OGC::WMS;
  my $ogc = Giovanni::OGC::WMS->new($hash);
  $ogc->submitRequest;
  
=head1 DESCRIPTION

Giovanni::OGC::WMS provides a OGC WMS interface for AG. It accepts WMS request and translates it into AG requests, and invokes AG workflow to prints image to stdout.
 

=head1 CONSTRUCTOR

=over 4

=item new($hash_baseUrl_options)

The constructor for Giovanni::OGC::WMS accepts a hash including  base URL for WMS and a hash for parameters, and translates it into service manager request.

=back

=head1 METHODS

=over 4

=item submitRequest

submitRequest() submits and monitors service manager request. If the request is successful, then submits getGiovanniMapInfo request, and parses its response to build and submit agMap request to print WMS image. 

=back

=head1 METHODS

=over 4

=item ogcErrorMessage("message")

ogcErrorMessage() prints OGC error message in XML

=back


=head1 EXPORT

All.

=head1 SEE ALSO

=head1 AUTHOR

Peisheng Zhao, E<lt>peisheng.zhao-1@nasa.gov<gt>

=cut
