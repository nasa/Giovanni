#!/bin/env python
"""Tests for the net_cdf_serializer.py script."""

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import os
import shutil
import StringIO
import tempfile
import unittest
import subprocess
import re
import net_cdf_serializer as serializer


# Tests the NetCdfSerializer code with 3-hourly data.
# 
# @author csmit

class TestSerializer(unittest.TestCase):
    
    test_files_base_path = "./tests/data/"
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        
    def tearDown(self):
        shutil.rmtree(self.temp_dir)
        #ncFile.delete()

    # This is a pretty fragile compare. It makes sure that the ascii in
    # correctFile and in testString are the same, ignoring all white space.
    # 
    # @param correctFile
    # @param testString
    # @throws Exception
    def compareStrings(self, correctString, testString):
        correctString = re.sub(r"\s", "", correctString)
        testString = re.sub(r"\s", "", testString)

        # literally just check to see if these are identical...
        if correctString != testString:
            print "-------------- Failed comparison -----------------------"
            print "Expected:"
            print correctString
            print "Received:"
            print testString
        self.assertTrue(correctString == testString)
        
        
   
    def do_test(self, cdl_file_name, significant_digits, test_json_file, cmds = None, assert_fns = None):
        # Generate test nc file from CDL
        nc_file_name = os.path.join(self.temp_dir, cdl_file_name.split('/')[-1].replace('.cdl', '.nc'))
        # we need to convert to the .cdl files to .nc files for testing
        cmd = "ncgen -o" + nc_file_name + " -x " + cdl_file_name
        # wait for the command to finish executing
        return_code = subprocess.call(cmd, shell=True)  
        if (return_code != 0):
            raise Exception("Unable to convert cdl file")
        
        # Run additional NCO transforms
        if cmds != None:
            for cmd in cmds:
                return_code = subprocess.call(cmd % nc_file_name, shell=True)  
                if (return_code != 0):
                    raise Exception("Unable to execute %s" % (cmd % nc_file_name))
        
        # Get tested JSON
        output_stream = StringIO.StringIO()
        argv = [
            serializer.__file__,
            '--file', nc_file_name,
            '--significantDigits', str(significant_digits)
        ]
        serializer.main(argv, output_stream)
        testJson = output_stream.getvalue()
        
        # Get correct json
        if test_json_file != None:
            f = open(test_json_file, 'r')
            correctJson = ''.join(f.readlines())
            f.close()
        
        #print testJson
        #print correctJson
        
        if assert_fns == None:
            # Compare the two jsons
            self.compareStrings(correctJson, testJson)
        else:
            for assert_fn in assert_fns:
                self.assertTrue(assert_fn(testJson))

    def test_3_hourly(self):
        # Location of the cdl file for testing
        cdlFile = os.path.join(self.test_files_base_path, "pairedData.TRMM_3B42_007_precipitation+TRMM_3B42_long_shortname_007_precipitation.20030101T0000-20030101T0000.77W_38N_76W_39N.cdl")
        # This file was hand checked for accuracy.
        jsonFile = os.path.join(self.test_files_base_path, "pairedData.TRMM_3B42_007_precipitation+TRMM_3B42_long_shortname_007_precipitation.20030101T0000-20030101T0000.77W_38N_76W_39N.json")
        self.do_test(cdlFile, 5, jsonFile)
        
     
    def test_hourly(self):
        # Location of the hourly file for testing
        cdlFile = os.path.join(self.test_files_base_path, "pairedData.NLDAS_NOAH0125_H_002_soilm0_10cm+NLDAS_NOAH0125_H_002_soilm0_100cm.20030101T0000-20030101T0200.76W_38N_75W_38N.cdl")
        # This file was hand checked for accuracy.
        jsonFile = os.path.join(self.test_files_base_path, "pairedData.NLDAS_NOAH0125_H_002_soilm0_10cm+NLDAS_NOAH0125_H_002_soilm0_100cm.20030101T0000-20030101T0200.76W_38N_75W_38N.json")
        self.do_test(cdlFile, 5, jsonFile)


    def test_daily(self):
        # Location of the daily file for testing
        cdlFile = os.path.join(self.test_files_base_path, "pairedData.TRMM_3B42_daily_precipitation_V6+TRMM_3B42_daily_precipitation_V7.20030101-20030102.79W_35N_77W_36N.cdl")
        # This file was hand checked for accuracy.
        jsonFile = os.path.join(self.test_files_base_path, "pairedData.TRMM_3B42_daily_precipitation_V6+TRMM_3B42_daily_precipitation_V7.20030101-20030102.79W_35N_77W_36N.json")
        self.do_test(cdlFile, 5, jsonFile)
        
    def test_monthly(self):
        # Location of the monthly file for testing. I altered one of the time
        # dimension times so that it doesn't align exactly with the data month.
        cdlFile = os.path.join(self.test_files_base_path, "pairedData.GSSTFM_3_SET1_INT_E+GSSTFM_3_SET1_INT_H.20030101-20030201.76W_37N_75W_40N.cdl")
        # This file was hand checked for accuracy.
        jsonFile = os.path.join(self.test_files_base_path, "pairedData.GSSTFM_3_SET1_INT_E+GSSTFM_3_SET1_INT_H.20030101-20030201.76W_37N_75W_40N.json")
        self.do_test(cdlFile, 5, jsonFile)
        
    def test_no_fill_value(self):
        # Location of the test file.
        cdlFile = os.path.join(self.test_files_base_path, "g4.iascatter.MODISA_L3m_SST_2014_sst+MODISA_L3m_SST_2014_sst4.20050101-20050131.71W_32N_71W_32N.cdl")
        # This file was hand checked for accuracy.
        jsonFile = os.path.join(self.test_files_base_path, "g4.iascatter.MODISA_L3m_SST_2014_sst+MODISA_L3m_SST_2014_sst4.20050101-20050131.71W_32N_71W_32N.json")
        self.do_test(cdlFile, 5, jsonFile)
    
    def test_serializer(self):
        # Location of the test file.
        cdlFile = os.path.join(self.test_files_base_path, "scrubbed.MOD08_D3_051_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101.1.paired.cdl")
        # This file was hand checked for accuracy.
        jsonFile = os.path.join(self.test_files_base_path, "scrubbed.MOD08_D3_051_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101.1.paired.json")
        self.do_test(cdlFile, 4, jsonFile)
        
    def test_cloud_fraction(self):
        # Location of the test file.
        cdlFile = os.path.join(self.test_files_base_path, "pairedData.AIRX3STD_006_CloudFrc_A+AIRX3STD_006_CloudFrc_D.20090501-20090501.123W_36N_110W_46N.cdl")
        # This file was hand checked for accuracy.
        jsonFile = os.path.join(self.test_files_base_path, "pairedData.AIRX3STD_006_CloudFrc_A+AIRX3STD_006_CloudFrc_D.20090501-20090501.123W_36N_110W_46N.json")
        self.do_test(cdlFile, 5, jsonFile)
    
    def no_time_condition(self, testJson):
        return "[ \"2003-01\"]" in testJson
    
    def test_no_time(self):
        # Location of the test file.
        cdlFile = os.path.join(self.test_files_base_path, "correlation.GSSTFM_3_SET1_INT_E+GSSTFM_3_SET1_INT_H.20030101-20030201.76W_37N_75W_40N.cdl")
        # This file was hand checked for accuracy.
        jsonFile = os.path.join(self.test_files_base_path, "correlation.GSSTFM_3_SET1_INT_E+GSSTFM_3_SET1_INT_H.20030101-20030201.76W_37N_75W_40N.json")
        self.do_test(cdlFile, 5, jsonFile)
        cmd = "ncatted -a input_temporal_resolution,global,o,c,monthly %s"
        self.do_test(cdlFile, 5, jsonFile, cmds = [cmd], assert_fns = [self.no_time_condition])
    
    def nan_test_condition(self, testJson):
        return "null," in testJson
    
    def test_nan(self):
        # Location of the test file.
        cdlFile = os.path.join(self.test_files_base_path, "pairedData.AIRNOW_PM_001_pmfine+MYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20030101-20030101.93W_32N_80W_39N.cdl")
        self.do_test(cdlFile, 5, None, assert_fns = [self.nan_test_condition])    

if __name__ == '__main__':
    unittest.main()
