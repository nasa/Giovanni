"""
Tests for the agiovanni.visualizationManager module.
"""
import unittest
import mock
from mock import MagicMock, patch
import os
import shutil
import filecmp
import random
import tempfile

from agiovanni import visualizationManager

class visualizationManager_unitTest(unittest.TestCase):
    '''
    unit test for visualizationManager module
    '''

    def setUp(self):
        '''
        set up
        '''
        self.outputDir = tempfile.mkdtemp()
        
    def test_visualizationManager(self):
        '''
        unit test for visualizationManager method
        '''
        # preparation
        cfgFile = 'dummy_cfgFile'
        sessionDir = self.outputDir
        targetListFileName = 'dummy_targetListFileName'
        visualizationHistoryFileName = 'dummy_visualizationHistoryFileName'
        plotType = 'dummy_plotType'
        options = 'dummy_options'
        outputDir = 'dummy_outputDir'
        targetListFileContent = "mfst.data_field_info+dOMAERUVd_003_FinalAerosolExtOpticalDepth388.xml\
mfst.result+sTmAvMp+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+zNA+uNA+t20120101000000_20130101235959+b180.0000W90.0000S180.0000E90.0000N.xml\
mfst.postprocess+sTmAvMp+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+zNA+uNA+t20120101000000_20130101235959+b180.0000W90.0000S180.0000E90.0000N.xml\
mfst.data_fetch+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+t20120101000000_20130101235959.xml\
mfst.shape_mask+sTmAvMp+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+zNA+uNA+t20120101000000_20130101235959+b180.0000W90.0000S180.0000E90.0000N.xml\
mfst.data_search+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+t20120101000000_20130101235959.xml\
mfst.postprocess"
        targetListFile = os.path.join(sessionDir, targetListFileName)
        with open(targetListFile,'w') as fo:
            fo.write(targetListFileContent)

        # mock up 
        visualizationManager.get_lookFor = MagicMock(return_value = 'mfst.postprocess')
        visualizationManager.signature.apply = MagicMock()

        # call
        visualizationManager.visualizationManager.apply(args=(cfgFile, sessionDir, targetListFileName, visualizationHistoryFileName, plotType, outputDir, options, True))

        # assert
        with open(targetListFile) as fin:
            lines = fin.readlines()
            manifestFileNameList = [line.strip() for line in lines]
        lookForPriorityList = ['mfst.combine', 'mfst.postprocess', 'mfst.result']
        visualizationManager.get_lookFor.assert_called_once_with(lookForPriorityList, manifestFileNameList)

        
    def test_get_lookFor(self):
        '''
        unit test for get_lookFor method
        '''
        # preparation
        lookForPriorityList = ['mfst.combine', 'mfst.postprocess', 'mfst.result']
        manifestFileNameList = ['mfst.data_field_info+dOMAERUVd_003_FinalAerosolExtOpticalDepth388.xml', 
                                'mfst.result+sTmAvMp+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+zNA+uNA+t20120101000000_20130101235959+b180.0000W90.0000S180.0000E90.0000N.xml', 
                                'mfst.postprocess+sTmAvMp+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+zNA+uNA+t20120101000000_20130101235959+b180.0000W90.0000S180.0000E90.0000N.xml', 
                                'mfst.data_fetch+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+t20120101000000_20130101235959.xml', 
                                'mfst.shape_mask+sTmAvMp+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+zNA+uNA+t20120101000000_20130101235959+b180.0000W90.0000S180.0000E90.0000N.xml', 
                                'mfst.data_search+dOMAERUVd_003_FinalAerosolExtOpticalDepth388+t20120101000000_20130101235959.xml'
                               ]

        # call
        result = visualizationManager.get_lookFor(lookForPriorityList, manifestFileNameList)

        # assert
        expected_result = 'mfst.postprocess'
        self.assertEqual(result, expected_result)

    def tearDown(self):
        '''
        clean up
        '''
        shutil.rmtree(self.outputDir)

if __name__ == '__main__':
    unittest.main()
