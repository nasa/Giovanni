use 5.010001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Giovanni::Untaint',
    VERSION_FROM      => 'lib/Giovanni/Untaint.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    EXE_FILES         => [ qw() ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Giovanni/Untaint.pm', # retrieve abstract from module
       AUTHOR         => 'Christine E Smit <christine.e.smit@nasa.gov>') : ()),
);

