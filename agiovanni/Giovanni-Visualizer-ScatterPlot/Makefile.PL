#$Id: Makefile.PL,v 1.5 2013/04/23 14:16:12 mhegde Exp $Id: Makefile.PL,v 1.5 2013/04/23 14:16:12 mhegde Exp $
#-@@@ AEROSTAT, Version $Name:  $
use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'GIOVANNI-SCATTERPLOT',
    PM => {},
    EXE_FILES => [ qw(scatterplot_main.sav scatterplot.py) ],
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => '', # retrieve abstract from module
       AUTHOR         => 'Mahabaleshwara S. Hegde <Mahabaleshwa.S.Hegde@nasa.gov>') : ()),
);

sub MY::postamble {
return <<BLOCK;
scatterplot_main.sav: no_valid_data.pro scatterplot.pro scatterplot_main.pro
	@/bin/echo -e ".FULL_RESET_SESSION\\n.compile \$\^\\nRESOLVE_ALL\\nSAVE, /ROUTINES, FILE='\$\@'\\n" | /usr/local/itt/idl/bin/idl

idl: scatterplot_main.sav
        
BLOCK
}

