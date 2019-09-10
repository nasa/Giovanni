use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
@scripts = qw(
    scripts/g4_run_gnuplot.pl
);
WriteMakefile(
    NAME              => 'Giovanni::Visualizer::Gnuplot',
    VERSION_FROM      => 'lib/Giovanni/Visualizer/Gnuplot.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    EXE_FILES         => \@scripts,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Giovanni/Visualizer/Gnuplot.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Lynnes <chris.lynnes@nasa.gov>') : ()),
);
