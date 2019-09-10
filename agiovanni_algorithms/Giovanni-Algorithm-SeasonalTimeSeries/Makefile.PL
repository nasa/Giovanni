use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Giovanni::Algorithm::SeasonalTimeSeries',
    VERSION_FROM      => 'lib/Giovanni/Algorithm/SeasonalTimeSeries.pm', # finds $VERSION
    EXE_FILES         => [ qw(scripts/seasonalTimeSeries.pl) ],
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Giovanni/Algorithm/SeasonalTimeSeries.pm', # retrieve abstract from module
       AUTHOR         => 'Christine E Smit <csmit@localdomain>') : ()),
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
