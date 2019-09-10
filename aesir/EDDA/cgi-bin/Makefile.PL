#$Id: Makefile.PL,v 1.8 2015/01/13 02:11:39 eseiler Exp $
#-@@@ AESIR EDDA, Version $Name:  $

use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'EDDA-CGI',
    PM => {},
    EXE_FILES         => [ createNewDataField, createNewDataProduct,
                           customizeColorMap, deleteDataField,
                           deleteDataProduct, downloadDataFieldInfo,
                           getDataFieldInfo, getDataFields,
                           getDataFieldsStatus,
                           getDataProductInfo, getDataProducts,
                           getNewDataFieldInfo, getNewDataProductInfo,
                           updateDataFieldInfo, updateDataProductInfo,
                           DIFEntryIdList ],
    INSTALLDIRS       => 'perl',
    INST_BIN          => 'blib/bin',
    INST_SCRIPT       => 'blib/cgi-bin/AESIR/EDDA',
    INSTALLSCRIPT     => '$(PREFIX)/cgi-bin/AESIR/EDDA',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => '', # retrieve abstract from module
       AUTHOR         => 'Edward J. Seiler <Ed.Seiler@nasa.gov>') : ()),
);
