"""
Tests for the agiovanni.visualizationManager module.
"""
import unittest
import mock
from mock import patch
import os
import shutil
import filecmp
import random
import tempfile

from agiovanni import visualizationManager


class visualizationManagerTest(unittest.TestCase):

    def setUp(self):
        '''
        get the giovanni cfg file
        make a temporary directory to save the output
        '''
        self.cfgFile = os.path.join(os.getcwd(),'data','giovanni.cfg')
        self.targetListFileName = 'targets.txt'
        self.visualizationHistoryFileName = 'visualizer.txt'
        self.outputDir = tempfile.mkdtemp()
        
    def test_TmAvMp(self):
        '''
        test URL: http://dev.gesdisc.eosdis.nasa.gov/giovanni/#service=TmAvMp&starttime=2012-01-01T00:00:00Z&endtime=2013-01-01T23:59:59Z&bbox=-180,-90,180,90&data=OMAERUVd_003_FinalAerosolExtOpticalDepth388&dataKeyword=aod
        '''
        sessionDir = '/var/giovanni/session/F5A8694A-4F76-11E6-9521-C83B8E8C7669/F700164E-4F76-11E6-943A-F83B8E8C7669/F7002D5A-4F76-11E6-943A-F83B8E8C7669/'
        plotManifestFileName = 'mfst.plot+sTmAvMp+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+zNA+uNA+t20120101000000_20130101235959+b180.0000W90.0000S180.0000E90.0000N.xml'
        plotType = 'INTERACTIVE_MAP'
        options = None
        visualizationManager.visualizationManager.apply(args=(self.cfgFile, sessionDir, self.targetListFileName, self.visualizationHistoryFileName, plotType, self.outputDir, options, True))
        expected_plotManifestFile = os.path.join(sessionDir,plotManifestFileName)
        actual_plotManifestFile = os.path.join(self.outputDir,plotManifestFileName)
        self.assertTrue(filecmp.cmp(expected_plotManifestFile,actual_plotManifestFile))

    def tearDown(self):
        '''
        clean up
        '''
        shutil.rmtree(self.outputDir)


if __name__ == '__main__':
    unittest.main()
            
        
