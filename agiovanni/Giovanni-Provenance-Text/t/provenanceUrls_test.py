#! /bin/env python
# $Id: provenanceUrls_test.py,v 1.4 2015/02/02 15:19:22 csmit Exp $
# -@@@ Giovanni, Version $Name:  $

import unittest;
import tempfile;
import shutil;
import os;
import sys;

curr_dir = os.path.dirname(os.path.realpath(__file__));
sys.path.insert(0,os.path.join(curr_dir, '..', 'src'));

import provenanceUrls as PU

class TestProvenanceUrls(unittest.TestCase):
    def setUp(self):
        self.tempDir = tempfile.mkdtemp();

        
    def tearDown(self):
        shutil.rmtree(self.tempDir);
    
    def testLineageUrls(self):
        '''
        Do a basic test to make sure that we can find the two provenance files
        in this Giovanni-Provenance-Text/t directory, get out the file paths,
        and translate them into URLs.
        '''
        outFile = "%s/out.txt" % self.tempDir;
        argv = [
                PU.__file__,
                '--dir', curr_dir,
                '--step', 'algorithm',
                '--out', outFile,
                '--lookup',
                "/var/tmp/www/TS2/giovanni=>http://s4ptu-ts2.ecs.nasa.gov/WWW-TMP/giovanni"
                ];
        PU.main(argv);
        self.assertTrue(os.path.isfile(outFile));
        
        # see what is in the file
        f = open(outFile, 'r');
        lines = f.readlines();
        f.close();
        correctLines = [
            "http://s4ptu-ts2.ecs.nasa.gov/WWW-TMP/giovanni/198FA02A-0E8E-11E4-AF8C-6BCCF8C70651/5F93102A-0E8E-11E4-B4A6-E9CFF8C70651/5F9329C0-0E8E-11E4-B4A6-E9CFF8C70651/timeAvg.TRMM_3B42_daily_precipitation_V6.20030101-20030101.180W_50S_180E_50N.nc\n",
            "http://s4ptu-ts2.ecs.nasa.gov/WWW-TMP/giovanni/198FA02A-0E8E-11E4-AF8C-6BCCF8C70651/4ED404B8-0E90-11E4-9316-06E8F8C70651/4ED41FE8-0E90-11E4-9316-06E8F8C70651/timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.180W_50S_180E_50N.nc\n"
        ];
        self.assertEqual(len(lines), len(correctLines), "Same number of lines");
        for i in range(0, len(correctLines)):
            self.assertEqual(lines[i], correctLines[i], "Line %d matches" % i);
        
    def testLineageUrlsWindows(self):
        '''
        Do a test to make sure that the code can handle creating windows-style
        text files (\r\n vs. \n).
        '''
        outFile = "%s/out.txt" % self.tempDir;
        argv = [
                PU.__file__,
                '--dir', curr_dir,
                '--step', 'algorithm',
                '--out', outFile,
                '--lookup',
                "/var/tmp/www/TS2/giovanni=>http://s4ptu-ts2.ecs.nasa.gov/WWW-TMP/giovanni",
                '--windowsOutput'
                ];
        PU.main(argv);
        self.assertTrue(os.path.isfile(outFile));
        
        # see what is in the file
        f = open(outFile, 'r');
        lines = f.readlines();
        f.close();
        correctLines = [
            "http://s4ptu-ts2.ecs.nasa.gov/WWW-TMP/giovanni/198FA02A-0E8E-11E4-AF8C-6BCCF8C70651/5F93102A-0E8E-11E4-B4A6-E9CFF8C70651/5F9329C0-0E8E-11E4-B4A6-E9CFF8C70651/timeAvg.TRMM_3B42_daily_precipitation_V6.20030101-20030101.180W_50S_180E_50N.nc\r\n",
            "http://s4ptu-ts2.ecs.nasa.gov/WWW-TMP/giovanni/198FA02A-0E8E-11E4-AF8C-6BCCF8C70651/4ED404B8-0E90-11E4-9316-06E8F8C70651/4ED41FE8-0E90-11E4-9316-06E8F8C70651/timeAvg.TRMM_3B42_daily_precipitation_V7.20030101-20030101.180W_50S_180E_50N.nc\r\n"
        ];
        self.assertEqual(len(lines), len(correctLines), "Same number of lines");
        for i in range(0, len(correctLines)):
            self.assertEqual(lines[i], correctLines[i], "Line %d matches" % i);
               
def main():
    unittest.main();
               
if __name__ == '__main__':
    unittest.main();
