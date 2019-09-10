# $Id: Makefile.PL,v 1.1 2015/04/17 23:07:19 eseiler Exp $

use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
@scripts = qw(
  scripts/g4_map_animation.pl
);
WriteMakefile(
    NAME              => 'Giovanni-Algorithm-MapAnimation',
    VERSION           => '1.0',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    EXE_FILES         => \@scripts,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => '',
       AUTHOR         => 'Edward Seiler <Ed.Seiler@nasa.gov>') : ()),
);

sub MY::postamble
{
return <<BLOCK;
cfg: 
	for filename in *.svc;\\
	do \\
		addGiovanniService.pl -f \$\$filename -prefix \$(PREFIX) --verbose 1; \\
	done 
BLOCK
}
