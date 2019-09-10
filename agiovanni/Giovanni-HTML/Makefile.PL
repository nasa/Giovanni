use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# Note: The XSL files needed for this project need to be built separately in ../xsl
WriteMakefile(
    NAME              => 'Giovanni::HTML',
    VERSION_FROM      => 'lib/Giovanni/HTML/NoScript.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	

);

