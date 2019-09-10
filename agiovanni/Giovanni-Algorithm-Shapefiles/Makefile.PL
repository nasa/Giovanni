use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
@scripts = qw(
  scripts/giovanni_shape_mask.py
  scripts/g4_shp_preprocess.py
  scripts/g4_shp_dump.py
  scripts/g4_shp_apply_state_dept_filter.py
  scripts/g4_shp_collapse.py
  scripts/g4_shp_concat.py
  scripts/g4_shp_casecorrect.py
  scripts/g4_shp_add_watershed.py
);

WriteMakefile(
    NAME              => 'GIOVANNI-ALGORITHM-SHAPEFILES',
    VERSION           => '1.0',
    EXE_FILES         => \@scripts,
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Shapefile Algorithms',
       AUTHOR         => 'Daniel da Silva <daniel.daSilva@nasa.gov>, ' . 
                         'Aaron Plave (summer intern)') : ()),
);
