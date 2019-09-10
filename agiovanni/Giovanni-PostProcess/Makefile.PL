use 5.008008;
use ExtUtils::MakeMaker;

my @scripts = qw(scripts/giovanni_postprocess.pl);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Giovanni::PostProcess',
    VERSION           => '0.1', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    EXE_FILES         => [ @scripts ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Algorithm PostProcessing Step', 
       AUTHOR         => 'Daniel da Silva <Daniel.daSilva@nasa.gov>') : ()),
);
