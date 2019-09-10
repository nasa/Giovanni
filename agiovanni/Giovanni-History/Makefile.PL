use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Giovanni::History',
    VERSION_FROM      => 'lib/Giovanni/History.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Class to represent Giovanni visualization history', # retrieve abstract from module
       AUTHOR         => 'Mahabaleshwara S. Hegde <mhegde@localdomain>') : ()),
);
