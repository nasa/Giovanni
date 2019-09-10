#$Id: $
#-@@@ EDDA, Version $Name:  $
use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME      => 'EDDA-bin',
    PM        => {},
    EXE_FILES => [ qw(createSldList.pl generateDataFieldSldValids.pl ingestDataFieldInfo.pl setupEddaCatalogDirs.pl updateSolrCatalogAddDocFromEdda.pl convertEDDAtoTSV.pl ingestTSVtoEDDA.pl deleteEddaDataFieldFromSolrCatalogAddDoc.pl promoteDataField.pl) ],
    INSTALLDIRS       => 'perl',
    INST_SCRIPT       => 'blib/bin/AESIR/EDDA',
    INSTALLSCRIPT     => '$(PREFIX)/bin/AESIR/EDDA',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => '', # retrieve abstract from module
       AUTHOR         => 'Edward Seiler <Ed.Seiler@nasa.gov>') : ()),
);
