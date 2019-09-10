#$Id: Makefile.PL,v 1.43 2015/04/09 20:53:39 csmit Exp $
#-@@@ Giovanni, Version $Name:  $

use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME      => 'Giovanni-CGI',
    PM        => {},
    EXE_FILES => [
        'service_manager.pl',            'serializer.pl',
        'lineage.pl',
        'catalogServices.pl',            'netcdf_serializer.pl',
                                         'getNewsItems.pl',
        'agmap.pl',                      'downloadAnimation.pl',
        'downloadMap.pl',                'downloadPlot.pl',
        'getGiovanniScatterPlotInfo.pl', 'filterScatterPlotData.pl',
        'getAnimationFrame.pl',         
        'netcdf_json_serializer.pl',     
        'wms_ag4',                       'lineageText.pl',
        'noscript.cgi',                  'getSupportedBrowsers.pl',
        'aesir_proxy.pl',                'getDestinationUnits.pl',
        'checkUnitsConversion.pl',       'getGiovanniDomainLookup.pl',
        'wcs_ag4',                             
        'getMapConfig.pl',
        'getGiovanniConfig.pl',          'earthdataLogin.pl',
        'getSummarySession.pl',
        'profileLogout.pl',              'profileLoggedIn.pl',
        'updateUserSessions.pl',
    ],
    INSTALLDIRS   => 'perl',
    INST_SCRIPT   => 'blib/cgi-bin',
    INSTALLSCRIPT => '$(PREFIX)/cgi-bin',
    PREREQ_PM     => {},                    # e.g., Module::Name => 1.1
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT => '',    # retrieve abstract from module
            AUTHOR =>
                'Mahabaleshwara S. Hegde <Mahabaleshwa.S.Hegde@nasa.gov>'
            )
        : ()
    ),
);
