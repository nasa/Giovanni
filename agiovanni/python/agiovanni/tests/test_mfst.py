"""
Tests for the agiovanni.mfst module.
"""

import os
import tempfile
import unittest

import agiovanni.mfst


class IntegrationTest(unittest.TestCase):
    """Tests writing a file list and then reading it back."""
    
    def setUp(self):
        _, self.mfst_file_name = tempfile.mkstemp()
    
    def tearDOwn(self):
        os.remove(self.mfst_file_name)

    def do_range(self, n):
        var_name = 'var_name'
        file_list = ['/tmp/filename%d.nc' % i for i in range(n)]

        agiovanni.mfst.write_file_list(self.mfst_file_name,
                                       var_name,
                                       file_list)
        
        got = agiovanni.mfst.read_file_list(self.mfst_file_name)
        got_var_name, got_file_list = got
        
        self.assertEqual(var_name, got_var_name)
        self.assertEqual(file_list, got_file_list)
        
    def test_empty_file_list(self):
        self.do_range(0)
        
    def test_one_element_list(self):
        self.do_range(1)
        
    def test_five_element_list(self):
        self.do_range(5)
        
    def test_hundred_element_list(self):
        self.do_range(100)
            

class ReadFileListTest(unittest.TestCase):
    """Tests for the mfst.read_file_list function.
    
    These tests write manifest files and test the function's ability
    to read them correctly.
    """
    def setUp(self):
        self.var_name = 'TRMM_3B42_daily_precipitation_V7'
        _, self.mfst_file_name = tempfile.mkstemp()

    def tearDown(self):
        os.remove(self.mfst_file_name)

    def test_empty_list(self):
        mfst_file = open(self.mfst_file_name, 'w')
        mfst_file.write("""<?xml version="1.0"?>
        <manifest>
          <fileList id="%s">
          </fileList>
        </manifest>
        """ % self.var_name)
        mfst_file.close()

        var_name, file_list = agiovanni.mfst.read_file_list(self.mfst_file_name)
        
        self.assertEqual(var_name, self.var_name)
        self.assertEqual(file_list, [])

    def test_five_element_list(self):
        mfst_file = open(self.mfst_file_name, 'w')
        mfst_file.write("""<?xml version="1.0"?>
        <manifest>
          <fileList id="%s">
            <file>/tmp/filename01.nc</file>
            <file>/tmp/filename02.nc</file>
            <file>/tmp/filename03.nc</file>
            <file>/tmp/filename04.nc</file>
            <file>/tmp/filename05.nc</file>
          </fileList>
        </manifest>
        """ % self.var_name)
        mfst_file.close()

        var_name, file_list = agiovanni.mfst.read_file_list(self.mfst_file_name)
        
        self.assertEqual(var_name, self.var_name)
        self.assertEqual(file_list, [
            '/tmp/filename01.nc',
            '/tmp/filename02.nc',
            '/tmp/filename03.nc',
            '/tmp/filename04.nc',
            '/tmp/filename05.nc',
        ])

if __name__ == '__main__':
    unittest.main()
