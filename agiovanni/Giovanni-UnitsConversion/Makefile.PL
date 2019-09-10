#$Id: Makefile.PL,v 1.3 2015/03/20 19:53:04 clynnes Exp $
#-@@@ Giovanni, Version $Name:  $
use 5.010001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my @scripts = qw(
    scripts/getUnitsArg.pl
);

WriteMakefile(
    NAME              => 'Giovanni::UnitsConversion',
    VERSION_FROM      => 'lib/Giovanni/UnitsConversion.pm', # finds $VERSION
    EXE_FILES         => \@scripts,
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Giovanni/UnitsConversion.pm', # retrieve abstract from module
       AUTHOR         => 'Christine E Smit <csmit@localdomain>') : ()),
);
