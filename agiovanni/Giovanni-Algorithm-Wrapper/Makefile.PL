use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my @scripts = qw(
  scripts/g4_ex_area_avg_diff_time.pl
  scripts/g4_ex_time_averager.pl
  scripts/g4_ex_time_avg_diff_map.pl
  scripts/giovanni_wrapper.pl
);
WriteMakefile(
    NAME              => 'Giovanni::Algorithm::Wrapper',
    VERSION_FROM      => 'lib/Giovanni/Algorithm/Wrapper.pm', # finds $VERSION
    EXE_FILES         => \@scripts,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Giovanni/Algorithm/Wrapper.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Lynnes, NASA/GSFC') : ()),
);
