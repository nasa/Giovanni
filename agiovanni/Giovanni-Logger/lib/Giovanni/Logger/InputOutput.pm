#!/usr/bin/perl -w

#$Id: InputOutput.pm,v 1.3 2013/07/17 19:10:25 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

package Giovanni::Logger::InputOutput;

use 5.008008;
use strict;
use warnings;
use XML::LibXML;

# Constructor takes name, value, type, inout. The type must be PARAMETER, URL,
# or FILE.
sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;

    # make sure we got everything
    my @mandatoryArgs = qw(name value type);
    for my $arg (@mandatoryArgs) {
        if ( !( exists $params{$arg} ) ) {
            die "Missing mandatory argument '$arg'";
        }
    }

    # make sure that the type is PARAMETER, URL, or FILE
    if (   ( $self->{type} ne "PARAMETER" )
        && ( $self->{type} ne "URL" )
        && ( $self->{type} ne "FILE" ) )
    {
        die "Parameter type must be PARAMETER, URL, or FILE";
    }

    return $self;
}

# Helper function for logger.
sub add_attributes() {
    my ( $self, $element ) = @_;

    $element->setAttribute( "NAME", $self->{name} );
    $element->setAttribute( "TYPE", $self->{type} );
    $element->appendTextNode( $self->{value} );

    return $element;
}

1;

__END__

=head1 NAME

Giovanni::Logger::InputOutput - Perl module for lineage inputs and outputs

=head1 ABSTRACT

Helper class for keeping track of a single input or output.

=head1 SYNOPSIS

  use Giovanni::Logger;
  use Giovanni::Logger::InputOutput;
  

  my $util = Giovanni::Logger->new(session_dir=>".",name=>"my_task");
  
  my $input = Giovanni::Logger::InputOutput->new(name=>"file",
                value=>"/path/to/interesting.nc",type=>"FILE");

  my $output = Giovanni::Logger::InputOutput->new(name=>"file",
                value=>"/path/to/evenmoreinteresting.nc",type=>"FILE");
  
  $util->write_lineage(name=>"step name",inputs=>[$input],outputs=>[$output],
     messages=>["lovely message", "another message"]);
  

  
=head1 DESCRIPTION

This code provides utilities for aG logging.

=head2 CONSTRUCTOR

The constructor takes three arguments:

name - the name of the input or output

value - the value. If a file path, it should be a full path.

type - URL (will become an html link), FILE (file path will be translated to an
       html link), PARAMETER (no translation performed)

=head1 AUTHOR

Christine E Smit, E<lt>christine.e.smit@nasa.govE<gt>

=cut
