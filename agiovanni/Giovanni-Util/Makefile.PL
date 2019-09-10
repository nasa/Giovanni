#$Id: Makefile.PL,v 1.3 2014/01/24 17:06:31 mhegde Exp $
#-@@@ Giovanni, Version $Name:  $

use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Giovanni::Util',
    VERSION_FROM      => 'lib/Giovanni/Util.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Contains Giovanni utility methods', # retrieve abstract from module
       AUTHOR         => 'Mahabaleshwara S. Hegde <mhegde@localdomain>') : ()),
);
