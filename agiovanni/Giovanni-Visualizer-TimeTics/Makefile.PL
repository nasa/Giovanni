use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my @scripts = qw(
  scripts/set_plot_hint_time_axis.pl
);
WriteMakefile(
    NAME              => 'Giovanni::Visualizer::TimeTics',
    VERSION_FROM      => 'lib/Giovanni/Visualizer/TimeTics.pm', # finds $VERSION
    EXE_FILES         => \@scripts,
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Giovanni/Visualizer/TimeTics.pm', # retrieve abstract from module
       AUTHOR         => 'Christopher Lynnes <christopher.s.lynnes@nasa.gov>') : ()),
);
