#!/bin/env python
"""Tests for the serialize_ints.py script."""

__author__ = "Richard Strub  <richard.f.strub@nasa.gov>"

import os
import shutil
import StringIO
import tempfile
import unittest
import subprocess
import re


# Tests the serialize_ints.py code with and without bbox
# including missing data. Note this data is before InTs was 
# fixed to use the midpoint of start and end time.
# 
# @author rstrub


class TestSerializer(unittest.TestCase):
    
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        
    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def do_test(self, directory, expected, cmds = None, assert_fns = None):

        cpfiles = "cp " + directory + "/* " + self.temp_dir
        p = subprocess.Popen(cpfiles, shell=True, stdout = subprocess.PIPE)  
        out, err = p.communicate()

        cmd = "./serialize_ints.py " + self.temp_dir 

        # wait for the command to finish executing
        p = subprocess.Popen(cmd, shell=True, stdout = subprocess.PIPE)  
        out, err = p.communicate()
        csvProduced = out
        
        assertion = 'diff ' + csvProduced + ' ' + expected
        return_code = subprocess.call(assertion, shell=True)
        if (return_code != 0):
            raise Exception(csvProduced + " did not equal expected result file: " + expected)
         

    def test_global(self):
        self.setUp()
        directory  = "data/global"
        expected   = "data/global.csv.expected"
        self.do_test(directory, expected)
        
     
    def test_bbox(self):
        self.setUp()
        directory  =  "data/bbox"
        expected   = "data/bbox.csv.expected"
        self.do_test(directory, expected)

    def test_seasons(self):
        self.setUp()
        directory  =  "data/seasons"
        expected   = "data/seasons.csv.expected"
        self.do_test(directory, expected)


if __name__ == '__main__':
    unittest.main()
