use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
@scripts = qw(
  scripts/g4_fast_animate.py
);

WriteMakefile(
    NAME              => 'Giovanni-Visualizer-Algorithm',
    EXE_FILES         => \@scripts,
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Animation Tools', # retrieve abstract from module
       AUTHOR         => 'Daniel da Silva <daniel.daSilva@nasa.gov>') : ()),
);
