use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Dev::Tools',
    VERSION_FROM      => 'lib/Dev/Tools.pm', # finds $VERSION
    EXE_FILES => [ qw(
        scripts/addGiovanniService.pl
        scripts/convertGiovanniUrlToDir.pl
        scripts/copyGiovanniSession.pl
        scripts/createGiovanniSandbox.pl
        scripts/listGiovanniCacheDb.pl
        scripts/deleteCache.pl
        scripts/cleanCacheDb.pl
        scripts/correctCacheKeys.pl
        scripts/estimate_cache_size.py
        scripts/deleteCacheFiles.pl
        scripts/checkCacheDb.pl
    ) ],
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Dev/Tools.pm', # retrieve abstract from module
       AUTHOR         => 'Christine E Smit <csmit@localdomain>') : ()),
);
