#$Id: Makefile.PL,v 1.56 2015/07/24 21:36:22 csmit Exp $
#-@@@ AEROSTAT, Version $Name:  $
use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME      => 'Scripts',
    PM        => {},
    EXE_FILES => [
        qw( NcFile.py
            checkQueueStatus.py
            compareData.pl
            compareGiovannis.pl
            cpNcAttributes.py
            dataPairingNco.pl
            dataValidator.pl 
            downloadRequestData.pl
            g4_isMyDataOK.pl
            getDataFieldInfo.pl
            getNcData1D.py
            getNcDimList.py
            getNcFillValue.py
            getNcGridinfo.py
            getNcMax.py
            getNcMin.py
            getNcRegionLabel.py
            getNcResolution.py
            getNcVarList.py
            getVariableInfo.pl
            giovanni_area_averager.pl
            giovanni_config.pl
            giovanni_correlation.pl
            giovanni_data_pairing.pl
            giovanni_regrid.pl
            makeStartup.pl
            ncCompare.py
            ncScrubber.pl
            regrid_lats4d.pl
            runCommandOnScrubbedFiles.py
            serialize_zonal_mean.py
            shift_longitude.pl
            spatialTemporalAverager.pl
            submitVisualizationManager.py
            submitWorkflow.py
            startQueue.py
            stopQueue.py
            stopVisualization.py
            stopWorkflow.py
            updateUserCatalog.pl
            timeBoundsScrubber.pl
            updateVisualization.py
            updateWorkflow.py
            updateScrubbedDataFile.pl
            visualize.pl
            workflow.pl)
    ],
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
