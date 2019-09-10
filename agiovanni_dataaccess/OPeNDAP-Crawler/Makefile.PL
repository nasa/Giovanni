use 5.008008;
use ExtUtils::MakeMaker;
my @scripts = qw(scripts/crawlOpendap.pl);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'OPeNDAP::Crawler',
    VERSION_FROM      => 'lib/OPeNDAP/Crawler.pm', # finds $VERSION
    EXE_FILES         => \@scripts,
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/OPeNDAP/Crawler.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel da Silva <Daniel.daSilva@nasa.gov>') : ()),
);
