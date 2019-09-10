use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Giovanni::Agent',
    VERSION_FROM      => 'lib/Giovanni/Agent.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    EXE_FILES => [ qw(scripts/giovanniAgent.pl) ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Giovanni/Agent.pm', # retrieve abstract from module
       AUTHOR         => 'Ed Seiler <eseiler@localdomain>') : ()),
);
