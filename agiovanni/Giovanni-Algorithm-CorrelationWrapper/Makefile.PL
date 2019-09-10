use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my @scripts = qw(
  scripts/correlation_wrapper.pl
);
WriteMakefile(
    NAME              => 'Giovanni::Algorithm::CorrelationWrapper',
    VERSION_FROM      => 'lib/Giovanni/Algorithm/CorrelationWrapper.pm', # finds $VERSION
    EXE_FILES         => \@scripts,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Giovanni/Algorithm/CorrelationWrapper.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Lynnes, NASA/GSFC') : ()),
);
