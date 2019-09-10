"""
Tests for the agiovanni.visualizationTask module.
"""
import unittest
import mock
from mock import MagicMock, patch
import os
import shutil
import filecmp
import random
import tempfile

from agiovanni import visualizationTask

class visualizationTask_unitTest(unittest.TestCase):
    '''
    unit test for visualizationTask module
    '''

    def setUp(self):
        '''
        set up
        '''
        self.outputDir = tempfile.mkdtemp()
        
    def test_visualizationTask(self):
        '''
        unit test for visualizationTask method
        '''
        # preparation
        cfgFile = 'dummy_cfgFile'
        sessionDir = 'dummy_sessionDir'
        manifestFileName = 'dummy_manifestFileName'
        plotManifestFileName = 'dummy_plotManifestFileName'
        visualizationHistoryFileName = 'dummy_visualizationHistoryFileName'
        plotType = 'dummy_plotType'
        options = 'dummy_options'
        outputDir = 'dummy_outputDir'

        # mock up 
        dataFileList = 'dummy_dataFileList'
        visualizationTask.run_visualize = MagicMock()
        visualizationTask.generate_dataFileList = MagicMock(return_value = dataFileList)
        visualizationTask.open = MagicMock()

        # call
        visualizationTask.visualizationTask.apply(args=(cfgFile, sessionDir, manifestFileName, plotManifestFileName, visualizationHistoryFileName, plotType, outputDir, options))

        # assert
        cmd = 'visualize.pl  -c %s -m %s -f %s -t %s -d %s -o %s'%(cfgFile, plotManifestFileName, dataFileList, plotType, outputDir, options)
        plotLogFile = os.path.join(outputDir, plotManifestFileName[:-4]+".log")
        visualizationTask.generate_dataFileList.assert_called_once_with(sessionDir, manifestFileName)
        visualizationTask.run_visualize.assert_called_once_with(cmd, plotLogFile)

        
    def test_generate_dataFileList(self):
        '''
        unit test for generate_dataFileList method
        '''
        # preparation
        sessionDir = self.outputDir
        manifestFileName = 'dummy_manifestFileName.txt'
        manifestFile_files = ('/var/giovanni/session/F5A8694A-4F76-11E6-9521-C83B8E8C7669/F700164E-4F76-11E6-943A-F83B8E8C7669/F7002D5A-4F76-11E6-943A-F83B8E8C7669/g4.timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth388.20120101-20130101.180W_90S_180E_90N.nc',)
        manifestFileContent = "<?xml version='1.0' encoding='UTF-8'?>\
    <manifest>\
      <fileList>\
        <file>%s</file>\
      </fileList>\
    </manifest>"%manifestFile_files
        manifestFile = os.path.join(sessionDir, manifestFileName)
        with open(manifestFile,'w') as fo:
            fo.write(manifestFileContent)

        # mock up 
        # python xml's different return types from parsing a file and a string makes mocking difficult

        # call
        result = visualizationTask.generate_dataFileList(sessionDir, manifestFileName)

        # assert
        assert result == '*'.join(manifestFile_files)

    def test_run_visualize(self):
        '''
        unit test for run_visualize method
        '''
        # preparation
        cmd = 'dummy_command dummy_args'
        plotLogFile = os.path.join(self.outputDir, 'dummy_plotLogFile.log')

        # mock up
        from subprocess import Popen, PIPE, STDOUT
        def dummy_Popen(cmd, stdout, stderr):
            return Popen('echo', stdout=PIPE, stderr=STDOUT)
        visualizationTask.Popen = MagicMock(side_effect = dummy_Popen)

        # call
        result = visualizationTask.run_visualize(cmd, plotLogFile)

        # assert
        visualizationTask.Popen.assert_called_once_with(cmd.split(), stdout=PIPE, stderr=STDOUT)

    def tearDown(self):
        '''
        clean up
        '''
        shutil.rmtree(self.outputDir)

if __name__ == '__main__':
    unittest.main()
