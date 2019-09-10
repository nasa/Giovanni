use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::XML2JSON',
    VERSION_FROM      => 'lib/XML/XML2JSON.pm', # finds $VERSION
#    PREREQ_PM         => { JSON::XS => "2.27" }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/XML2JSON.pm', # retrieve abstract from module
       AUTHOR         => 'Ed Seiler <eseiler@localdomain>') : ()),
);
