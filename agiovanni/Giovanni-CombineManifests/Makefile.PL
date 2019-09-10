use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Giovanni::CombineManifests',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    EXE_FILES => [ qw(scripts/combineFileManifests.pl) ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => '', # retrieve abstract from module
       AUTHOR         => 'Christine E Smit <csmit@localdomain>') : ()),
);
