use 5.008008;
use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.9 2014/01/31 21:39:55 mhegde Exp $
# aGiovani, $Name:  $

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Giovanni::Session',
    VERSION_FROM => 'lib/Giovanni/Session.pm',    # finds $VERSION
    PREREQ_PM    => {},                           # e.g., Module::Name => 1.1
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT => 'Abstraction of Giovanni Session',
            AUTHOR   => 'Mahabaleshwara S. Hegde <maha.hegde@nasa.gov>'
            )
        : ()
    ),
);
