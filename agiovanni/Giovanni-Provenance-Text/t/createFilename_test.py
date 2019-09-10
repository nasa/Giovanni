#! /bin/env python
# $Id: createFilename_test.py,v 1.3 2015/01/30 20:50:24 csmit Exp $
# -@@@ Giovanni, Version $Name:  $

import os;
import sys;
import unittest;

cur_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0,os.path.join(cur_dir, '..', 'src'));


import provenanceUrls as PU

class TestCreateFilename(unittest.TestCase):
    '''
    Tests the code to create a reasonable filename for the downloaded provenance.
    '''
    def testSimple(self):
        filenames = ["prov.algorithm+sINTERACTIVE_MAP+dMOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml"];
        outname = PU.createFilename(filenames);
        self.assertEqual(outname, "prov.algorithm+sINTERACTIVE_MAP+dMYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+dMOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.txt", "Correct output");       

    def testLong(self):
        filenames = ["prov.algorithm+sINTERACTIVE_MAP+dMOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMAD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMBD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMCD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMDD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMED08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMFD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMGD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml",
                     "prov.algorithm+sINTERACTIVE_MAP+dMHD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml"];
        outname = PU.createFilename(filenames);
        self.assertEqual(outname, "prov.341f12975d9c4c3388f02b9267d2ceb3.txt", "Correct output");       


if __name__ == '__main__':
    unittest.main();
