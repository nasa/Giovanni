use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GiovanniDataAccess',
    VERSION           => '1.0', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    DIR               => [qw(DataAccess-Translator ESIP DataAccess-OPeNDAP OPeNDAP-Crawler)],
    PERM_RWX          => 0775,
    PERM_RW           => 0664,
    INST_BIN          => 'blib/bin',
    INSTALLBIN        => '$(PREFIX)/bin/giovanni',
    INST_SCRIPT       => 'blib/script',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => '', # retrieve abstract from module
       AUTHOR         => 'Mahabaleshwara S. Hegde <mhegde@localdomain>') : ()),
);
