use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

@scripts = qw(
  scripts/areaAveragerNco.pl
);

WriteMakefile(
    NAME              => 'Giovanni::Algorithm::AreaAveragerNco',
    EXE_FILES         => [ 'scripts/areaAveragerNco.pl' ],
    VERSION_FROM      => 'lib/Giovanni/Algorithm/AreaAveragerNco.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Giovanni/Algorithm/AreaAveragerNco.pm', # retrieve abstract from module
       AUTHOR         => 'Mahabaleshwara S. Hegde <mhegde@localdomain>') : ()),
);
