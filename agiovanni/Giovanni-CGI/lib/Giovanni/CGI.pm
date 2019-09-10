package Giovanni::CGI;

use 5.010001;
use strict;
use warnings;

use CGI;
use Switch;
use List::Util;

use Giovanni::Untaint;

our @ISA = ("CGI");

sub new {
    my ( $pkg, %params ) = @_;

    # call CGI constructor
    my $self;
    if ( $params{QUERY} ) {
        $self = $pkg->SUPER::new( $params{QUERY} );
    }
    else {
        $self = $pkg->SUPER::new();
    }

    # see if the code should die if validation fails
    $self->{DONT_DIE_ON_VALIDATION_ERROR}
        = $params{DONT_DIE_ON_VALIDATION_ERROR};

    # define all the regular expression the code will use to validate inputs
    my $input_regex = {
        bbox         => qr/^([\+\-\d.NSEW, ]*)$/,
        boolean      => qr/^(true|false)$/i,
        data         => qr/^([A-Za-z \d_=.,:(){}\[\]\^\-\/]+)$/,
        data_keyword => qr/^([\w\s\-\(\)\._,]+)$/,
        filename     => qr/^([\d\w\_\-\.\+]+)$/,
        flag         => qr/^([1])$/,
        format =>
            qr/^(image\/png|image\/jpeg|image\/png; mode=8bit|application\/x-pdf|image\/svg\+xml|image\/tiff|application\/vnd.google-earth.kml\+xml|application\/vnd.google-earth.kmz|netcdf|tiff|asc|png|kmz|geotiff|xml|json)$/i,
        g_config   => qr/^(EARTHDATA_LOGIN|APPLICATION)$/,
        hex_color  => qr/^(0x[0-9a-fA-F]{6})$/,
        months     => qr/^([\d,]+)$/,
        number     => qr/^([\d.\-\+eE]+)$/,
        oauth_code => qr/^([a-f0-9]+)$/,

        # NOTE: plot_text is ONLY to be used for caption, title, and subtitle,
        # where we allow any text. DO NOT USE for ANYTHING else without
        # discussion.
        plot_text  => qr/(.*)/,
        portal     => qr/^(AEROSTAT|MAPSS|YOTC|MULTISENSOR|GIOVANNI)$/,
        projection => qr/^(epsg:3031|epsg:3413|epsg:4326)$/i,
        request =>
            qr/^(getcapabilities|describecoverage|getcoverage|getmap|getlegendgraphic)$/i,
        seasons => qr/^([DJFMASON,]+)$/,
        service =>
            qr/^([wW][cCmM][sS]|DiArAvTs|CrLt|HvLt|CrTm|HiGm|TmAvSc|CoMp|ArAvTs|TmAvMp|MpAn|CACHE|TmAvOvMp|StSc|VtPf|HvLn|QuCl|InTs|ZnMn|CrLn|DiTmAvMp|IaSc|AcMp|ArAvSc)$/,
        shape  => qr|^(\w+/shp_\d+)?$|,
        step   => qr/([A-Za-z0-9-+_]+)/,
        styles => qr/^(default|)$/,
        temporal_resolution =>
            qr/^(minutely|5-minutely|6-minutely|49-minutely|98-minutely|100-minutely|half-hourly|hourly|3-hourly|daily|5-daily|8-daily|16-daily|weekly|monthly|yearly)$/,
        time  => qr/^([\d\-:TZ]+)$/,
        units => qr/^([\%A-Za-z0-9\/\s\-^,]+)$/,
        url =>
            qr/^([\w|\-|\.|\:|\/|\?|#|\[|\]|@|!|$|&|'|\(|\)|\*|\+|,|;|=|%|~]+)$/,
        uuid            => qr/^([A-Za-z\d\-]+)$/,
        variable_facets => qr@([\w\- ]+:[/\w\-,. ]+;)@,
        version         => qr/^(\d+[.]\d+[.]\d+)$/,
        wcs_coverage =>
            qr/^(Time[-]Averaged[.][A-Za-z \d_=.,:(){}\[\]\^\-\/]+)$/,
    };

    # create an untainter object to untaint parameters
    my $untainter = Giovanni::Untaint->new( INPUT_REGEX => $input_regex );

    # make sure we have INPUT_TYPES input parameter
    if ( !defined( $params{INPUT_TYPES} ) ) {
        die "INPUT_TYPES required to untaint parameters";
    }

    # make sure we have TRUSTED_SERVERS input parameter
    if ( !defined( $params{TRUSTED_SERVERS} ) ) {
        die "TRUSTED_SERVERS required to untaint parameters";
    }

    $self->{INPUT_TYPES}     = $params{INPUT_TYPES};
    $self->{INPUT_REGEX}     = $input_regex;
    $self->{TRUSTED_SERVERS} = $params{TRUSTED_SERVERS};
    $self->{NAMESPACE}       = $params{NAMESPACE};
    $self->{untainter}       = $untainter;
    $self->{REQUIRED_PARAMS}
        = $params{REQUIRED_PARAMS}
        ? $params{REQUIRED_PARAMS}
        : [];

    # see if there are any proxy parameters
    $self->{PROXY_PARAMS} = {};
    if ( defined( $params{PROXY_PARAMS} ) ) {
        for my $param ( @{ $params{PROXY_PARAMS} } ) {
            $self->{PROXY_PARAMS}{ lc($param) } = 1;
        }

    }

    # check and untaint parameters
    $self->_check_params();

    return $self;
}

sub status {
    my ($self) = @_;
    if ( $self->{SUCCESS} ) {
        return ( SUCCESS => 1 );
    }
    else {
        return (
            SUCCESS       => 0,
            PARAMETER     => $self->{PARAMETER},
            ERROR_MESSAGE => $self->{ERROR_MESSAGE}
        );
    }
}

##
# Check for required parameters and then untaints.
##
sub _check_params {
    my ($self) = @_;

    $self->{SUCCESS} = 0;

    if ( $self->{DONT_DIE_ON_VALIDATION_ERROR} ) {
        eval('$self->_check_for_required_params();');
        if ($@) {

            # failure
            $self->{ERROR_MESSAGE} = $@;
            return;
        }

        eval('$self->_untaint();');
        if ($@) {

            # failure
            $self->{ERROR_MESSAGE} = $@;
            return;
        }
    }
    else {

        # these will die if they fail
        $self->_check_for_required_params();
        $self->_untaint();
    }

    # success!
    $self->{SUCCESS} = 1;

}

##
# Check to make sure that all the required parameters are present.
##
sub _check_for_required_params {
    my ($self) = @_;

    my @all_params = $self->SUPER::all_parameters;
    my %hash       = ();
    for my $param (@all_params) {
        $hash{ lc($param) } = 1;
    }

    for my $required ( @{ $self->{REQUIRED_PARAMS} } ) {
        if ( !$hash{ lc($required) } ) {
            $self->{PARAMETER} = $required;
            die
                "Mandatory parameter '$required' missing from input query string.";
        }
    }
}

##
# Untaint cgi query parameters
##
sub _untaint {
    my ($self) = @_;

    # Go through all the parameters
    my @all_params = $self->SUPER::all_parameters;
    for my $param (@all_params) {

        # only untaint parameters that are not proxy parameters
        if ( !$self->{PROXY_PARAMS}{ lc($param) } ) {

            if ( $self->{DONT_DIE_ON_VALIDATION_ERROR} ) {
                eval('$self->_untaint_one_param($param)');
                if ($@) {

                    # set which parameter caused the problem
                    $self->{PARAMETER} = $param;

                    # Die again with the same message. This will be picked up
                    # by the calling function.
                    die $@;
                }
            }
            else {
                $self->_untaint_one_param($param);
            }
        }
    }
}

##
# Figure out the parameter type.
##
sub _get_type {
    my ( $self, $param ) = @_;

    my $lc_param = lc($param);

    if ( defined( $self->{NAMESPACE} ) ) {

        # see if the parameter is here..
        if ( $self->{INPUT_TYPES}->{ $self->{NAMESPACE} }->{$lc_param} ) {
            return $self->{INPUT_TYPES}->{ $self->{NAMESPACE} }->{$lc_param};
        }
    }

    # otherwise, use the default namespace
    return $self->{INPUT_TYPES}->{default}->{$lc_param};
}

sub _untaint_one_param {
    my ( $self, $param ) = @_;

    # only untaint parameters that are not proxy parameters
    if ( !$self->{PROXY_PARAMS}{ lc($param) } ) {

        # make sure we have a type for this
        my $type = $self->_get_type($param);
        if ( !defined($type) ) {
            die "Unable to find valid type for '$param' in INPUT_TYPES";
        }

        # get the tainted values out
        my @values = $self->SUPER::param($param);

        # set the parameter to nothing
        $self->param( -name => $param, -value => [] );

        # untaint!
        if ( !$self->_do_special_untainting( $param, @values ) ) {
            $self->_do_regular_untainting( $param, @values );
        }
    }
}

##
# Untaint parameter values with a regular expression.
##
sub _do_regular_untainting {
    my ( $self, $param, @values ) = @_;

    # figure out what type of parameter this is
    my $type = $self->_get_type($param);

    # get the regular expression for this type of parameter
    my $regex = $self->{INPUT_REGEX}->{$type};
    if ( !defined($regex) ) {
        die "Unknown parameter type '$type' for '$param'.";
    }

    # loop through and untaint parameters
    my @all_untainted = ();
    for my $value (@values) {
        if ( $value =~ $regex ) {
            push( @all_untainted, $1 );
        }
        else {
            die "Parameter '$param' did not pass its regular expression.";
        }
    }

    # set the parameter to the untainted values
    $self->SUPER::param( -name => $param, -value => \@all_untainted );
}

##
# Untaint parameters that require more than a regular expression.
##
sub _do_special_untainting {
    my ( $self, $param, @values ) = @_;

    # find out what type this parameter is
    my $type = $self->_get_type($param);

    # assume this parameter requires special untainting
    my $did_untaint = 1;

    # Ick, ick ick. This is ugly. For-loops inside case statements that all
    # look almost identical? Not elegant, but it does get the job done.
    my @all_untainted = ();
    switch ($type) {
        case "uuid" {
            for my $value (@values) {
                my ( $success, $untainted )
                    = $self->{untainter}->UUID($value);
                if ( !$success ) {
                    die "Unable to untaint UUID parameter '$param'";
                }
                else {
                    push( @all_untainted, $untainted );
                }
            }
        }
        case "bbox" {
            for my $value (@values) {
                my ( $success, $untainted )
                    = $self->{untainter}->bbox($value);
                if ( !$success ) {
                    die "Unable to untaint bounding box parameter '$param'";
                }
                else {
                    push( @all_untainted, $untainted );
                }
            }
        }
        case "filename" {
            for my $value (@values) {
                my ( $success, $untainted )
                    = $self->{untainter}->filename($value);
                if ( !$success ) {
                    die "Unable to untaint filename parameter '$param'";
                }
                else {
                    push( @all_untainted, $untainted );
                }
            }
        }
        case "url" {
            for my $value (@values) {
                my ( $success, $untainted )
                    = $self->{untainter}
                    ->url( $value, $self->{TRUSTED_SERVERS} );
                if ( !$success ) {
                    die "Unable to untaint url parameter '$param'";
                }
                else {
                    push( @all_untainted, $untainted );
                }
            }
        }
        case "time" {
            for my $value (@values) {
                my ( $success, $untainted )
                    = $self->{untainter}->time($value);
                if ( !$success ) {
                    die "Unable to untaint time parameter '$param'";
                }
                else {
                    push( @all_untainted, $untainted );
                }
            }
        }
        case "number" {
            for my $value (@values) {
                my ( $success, $untainted )
                    = $self->{untainter}->number($value);
                if ( !$success ) {
                    die "Unable to untaint number parameter '$param'";
                }
                else {
                    push( @all_untainted, $untainted );
                }
            }
        }
        case "json" {
            for my $value (@values) {
                my ( $success, $untainted )
                    = $self->{untainter}->json($value);
                if ( !$success ) {
                    die "Unable to untaint json parameter '$param'";
                }
                else {
                    push( @all_untainted, $untainted );
                }
            }
        }
        case "layers" {
            for my $value (@values) {
                my ( $success, $untainted )
                    = $self->{untainter}->layers($value);
                if ( !$success ) {
                    die "Unable to untaint layers parameter '$param'";
                }
                else {
                    push( @all_untainted, $untainted );
                }
            }
        }
        else { $did_untaint = 0; }
    }

    if ($did_untaint) {

        # if this code did in fact untaint the parameter values, set
        # the parameter to the untainted strings
        $self->SUPER::param( -name => $param, -value => \@all_untainted );
    }

    return $did_untaint;
}

1;

__END__

=head1 NAME

Giovanni::CGI - Perl extension for untainting Giovanni inputs

=head1 SYNOPSIS

  use Safe;

  # Establish the root path based on the script name
  my ($rootPath);

  BEGIN {
      $rootPath = ( $0 =~ /(.+\/)cgi-bin\/.+/ ? $1 : undef );
      push( @INC, $rootPath . 'share/perl5' )
          if defined $rootPath;
  }
  $| = 1;

  # Following packages should be used after @INC is set above
  use Giovanni::Util;
  use Giovanni::CGI;
  # clean env and path
  $ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin:/usr/local/pkg/ncl/bin';
  delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

  # Read the configuration file
  my $cfgFile = $rootPath . 'cfg/giovanni.cfg';
  my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
  Giovanni::Util::exit_with_error($error) if ( defined $error );

  # Create CGI object, which will also untaint the parameters
  my $cgi = Giovanni::CGI->new(
    INPUT_TYPES    => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
  );
  
  # You can specify which parameters are mandatory and give the query string 
  # directly:  
  $cgi = Giovanni::CGI->new(
    INPUT_TYPES    => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    REQUIRED_PARAMS => ['fabulous'],
  );
  
  # You can give the query string directly:  
  $cgi = Giovanni::CGI->new(
    INPUT_TYPES    => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    QUERY => $ENV{QUERY_STRING},
  );
  
  # You can specify that certain parameters are proxy parameters that
  # do not need to be untainted because they will be passed through 
  # directly into a different URL's query string.
  $cgi = Giovanni::CGI->new(
    INPUT_TYPES    => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    PROXY_PARAMS => ['width','height'],
  );
  
  # You can specify a type namespace, where Giovanni::CGI will look first
  # before looking under the default namespace.
  $cgi = Giovanni::CGI->new(
    INPUT_TYPES    => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    NAMESPACE => 'special_cgi',
  );

  # Start using the cgi parameters! No further untainting should be needed.
  my $fabulous = $cgi->param('fabulous');
  
  # Alternatively, if you want to handle errors more gracefully than just
  # dying in the call to new, specify DONT_DIE_ON_VALIDATION_ERROR.
  
  $cgi = Giovanni::CGI->new(
    INPUT_TYPES    => \%GIOVANNI::INPUT_TYPES,
    TRUSTED_SERVERS => \@GIOVANNI::TRUSTED_SERVERS,
    DONT_DIE_ON_VALIDATION_ERROR => 1,
  );
  
  my $status = $cgi->status();
  if ( !$status{'SUCCESS} ) {
      my $error_message = $status{ERROR_MESSAGE};
      my $problem_parameter = $status{PARAMETER};
      
      # Do something here...
  }

=head1 DESCRIPTION

 Inherits from CGI and untaints parameters in the constructor. 

=head2 CONSTRUCTOR Giovanni::CGI->new(%params);
 
 Constructor for Giovanni::CGI with inputs INPUT_TYPES, TRUSTED_SERVERS,
 REQUIRED_PARAMS, QUERY (optional), PROXY_PARAMS (optional), 
 DONT_DIE_ON_VALIDATION (optional)
 
=head3 INPUT_TYPES
 
 %INPUT_TYPES must describe what type each parameter is so that they can be 
 untainted. For example, if your script takes session, resultset, result, and a 
 time input called my_time, then %INPUT_TYPES in giovanni.cfg must have the 
 following hash entries:

  %INPUT_TYPES = (
      default => {
          result    => 'uuid',
          resultset => 'uuid',
          session   => 'uuid',
          my_time   => 'time',
          data      => 'url',
      },
      other_namespace => {
          data => 'data',
      }
  );


 Valid types are:

  bbox - bounding box
  boolean - true or false (case insensitive)  
  data - variable/data/aesir id
  data_keyword - giovanni search keywords
  filename - filename (no paths allowed!)
  flag - something that can only be '1'
  format - download format. Currently image/png, image/jpeg, netcdf, tiff, asc, png, kmz, geotiff, xml, json.
  g_config - name of a configuration parameter in giovanni.cfg. Currently, only
    EARTHDATA_LOGIN and APPLICATION are permitted.
  hex_color - hexadecimal representation of color. E.g. - 0x7b7b91.
  json - a valid json string
  months - 01, 02, 03, ..., 12
  number - floating point numbers
  oauth_code - OAuth authorization code
  portal - GIOVANNI, etc.
  plot_text - currently used for caption, title, and subtitle. This regular
    expression allows everything through, so DO NOT USE without discussion.
  portal - AEROSTAT|MAPSS|YOTC|MULTISENSOR|GIOVANNI
  projection - epsg:3031|epsg:3413|epsg:4326
  request - wcs/wms request. Currently getcapabilities|describecoverage|getcoverage|getmap|getlegendgraphic
  seasons - comma-separated seasons. E.g. - 'DJF,MAM,JJA,SON'
  service - Giovanni plot types and wms/wcs. E.g. - 'TmAvOvMp'
  shape - Giovanni shape parameter
  step - Giovanni step. E.g. - 'data_fetch'
  styles - WMS request styles ('default' or empty)
  temporal_resolution - monthly, daily, etc.
  time - time. YYYY-MM-DDThh:mm:ssZ format and YYYY-MM-DD format both work.
  units - variable units. E.g. - 'mm/hr', 'mm s-2'
  url - URL at trusted server
  uuid - UUID
  variable_facets - giovanni UI variable facets
  version - <number>.<number>.<number> E.g. - '1.2.0'
  wcs_coverage - the string 'Time-Averaged.' followed by a variable/data/aesir
    id

=head3 TRUSTED_SERVERS

  The TRUSTED_SERVERS array is for validating urls. See Giovanni::Untaint for
  more details.

=head3 REQUIRED_PARAMS (optional)

  The REQUIRED_PARAMS array is optional. It contains the list of parameters that
  should always be in the query string.

=head3 QUERY (optional)

  The QUERY input is optional. It contains the query string. If the query string
  is not passed in, CGI gets it from the environment variable QUERY_STRING.

=head3 PROXY_PARAMS (optional)

  The PROXY_PARAMS array is optional. It contains a list of parameters that will
  not be untainted because they are going to be sent as is in a query string
  for another URL. Default behavior is to validate all parameters in the query
  string.

=head3 DONT_DIE_ON_VALIDATION_ERROR (optional)

  The DONT_DIE_ON_VALIDATION_ERROR parameter is optional. If true, new() will
  return even if a parameter is invalid. Call $cgi->status() to determine if
  validation was successful and to get error messages. Default behavior is to 
  die if validation fails.

=head3 TYPE_NAMESPACE
 
 The NAMESPACE input is optional. By default, the code will look in INPUT_TYPES
 under 'default'. If a namespace is specified, the code will look under that
 namespace first for parameter types and then look under 'default'.

=head2 STATUS $cgi->status();

Provides status of parameter validation during the call to new(). Returns a
hash with keys SUCCESS, PARAMETER, and ERROR_MESSAGE. If SUCCESS is false,
validation failed. PARAMETER is the name of the parameter whose validation
failed. ERROR_MESSAGE is the error that occurred.



=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govnE<gt>

=cut
