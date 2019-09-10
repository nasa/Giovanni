#!/bin/env python
"""
Tests for the searchUserData.py CGI script.
"""
__author__ = "Daniel da Silva <Daniel.daSilva@nasa.gov>"

import os
import shutil
import StringIO
import sys
import tempfile
import textwrap
import unittest
import xml.etree.ElementTree as ET

cur_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(cur_dir, ".."))
import searchUserData 


class ConfigEnvMock:
    """Mock for agiovanni.cfg.ConfigEnvironment"""

    def __init__(self, user_data_dir):
        self.user_data_dir = user_data_dir
        
    def get(self, var_name):
        if var_name == "$GIOVANNI::USER_DATA_DIR":
            return self.user_data_dir
        else:
            raise ValueError("Unexpected config_env.get() request")

            
class SearchUserDataTest(unittest.TestCase):
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.config_env = ConfigEnvMock(self.temp_dir)
        
    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def _make_file_list(self, file_list_path, file_list_contents):
        dir_path = os.path.dirname(file_list_path)
        os.makedirs(dir_path)
        
        file_list = open(file_list_path, "w")
        file_list.write(file_list_contents)
        file_list.close()

    def _do_test(self, 
                 qstring,
                 file_list_path,
                 file_list_contents):

        self._make_file_list(file_list_path,
                             file_list_contents)

        old_stdout = sys.stdout
        sys.stdout = StringIO.StringIO()
        
        try:
            searchUserData.main(config_env=self.config_env,
                                qstring=qstring,
                                skip_content_type=True)
        finally:
            sys.stdout.seek(0)
            output = sys.stdout.read()
            sys.stdout = old_stdout

        return output

    def _test_12_files(self, start, end):
        return self._do_test("user_id=dedasilv&dataset_id=data01&start="+start+"&end="+end,
                             "%s/dedasilv/data/data01/data01.txt" % self.temp_dir,
                             "2005-01-01T00:00:00Z,2005-01-31T00:00:00Z,/home/dedasilv/jan.nc\n"
                             "2005-02-01T00:00:00Z,2005-02-28T00:00:00Z,/home/dedasilv/feb.nc\n"
                             "2005-03-01T00:00:00Z,2005-03-31T00:00:00Z,/home/dedasilv/mar.nc\n"
                             "2005-04-01T00:00:00Z,2005-04-30T00:00:00Z,/home/dedasilv/apr.nc\n"
                             "2005-05-01T00:00:00Z,2005-05-31T00:00:00Z,/home/dedasilv/may.nc\n"
                             "2005-06-01T00:00:00Z,2005-06-30T00:00:00Z,/home/dedasilv/jun.nc\n"
                             "2005-07-01T00:00:00Z,2005-07-31T00:00:00Z,/home/dedasilv/jul.nc\n"
                             "2005-08-01T00:00:00Z,2005-08-31T00:00:00Z,/home/dedasilv/aug.nc\n"
                             "2005-09-01T00:00:00Z,2005-09-30T00:00:00Z,/home/dedasilv/sep.nc\n"
                             "2005-10-01T00:00:00Z,2005-10-31T00:00:00Z,/home/dedasilv/oct.nc\n"
                             "2005-11-01T00:00:00Z,2005-11-30T00:00:00Z,/home/dedasilv/nov.nc\n"
                             "2005-12-01T00:00:00Z,2005-12-31T00:00:00Z,/home/dedasilv/dec.nc\n")

    def test_12_files_small_subset(self):
        xml = self._test_12_files("2005-04-01T00:00:00", "2005-05-31T00:00:00")
        root = ET.fromstring(xml)
        download_urls = root.findall('downloadUrls/downloadUrl')

        self.assertEqual(len(download_urls), 2)
        self.assertEqual(download_urls[0].text, "/home/dedasilv/apr.nc")
        self.assertEqual(download_urls[0].attrib['label'], "apr.nc")
        self.assertEqual(download_urls[1].text, "/home/dedasilv/may.nc")
        self.assertEqual(download_urls[1].attrib['label'], "may.nc")

    def test_12_files_all_files_superset(self):
        xml = self._test_12_files("2004-04-01T00:00:00", "2006-06-01T00:00:00")
        root = ET.fromstring(xml)
        download_urls = root.findall('downloadUrls/downloadUrl')

        self.assertEqual(len(download_urls), 12)

        for i, mon_name in enumerate('jan feb mar apr may jun jul aug sep oct nov dec'.split()):        
            self.assertEqual(download_urls[i].text, "/home/dedasilv/" + mon_name + ".nc")
            self.assertEqual(download_urls[i].attrib['label'], mon_name + ".nc")

    def test_12_files_all_files_exact_range(self):
        xml = self._test_12_files("2005-01-01T00:00:00", "2005-12-31T00:00:00")
        root = ET.fromstring(xml)
        download_urls = root.findall('downloadUrls/downloadUrl')

        self.assertEqual(len(download_urls), 12)

        for i, mon_name in enumerate('jan feb mar apr may jun jul aug sep oct nov dec'.split()):        
            self.assertEqual(download_urls[i].text, "/home/dedasilv/" + mon_name + ".nc")
            self.assertEqual(download_urls[i].attrib['label'], mon_name + ".nc")

    def test_12_files_no_results_range_above(self):
        xml = self._test_12_files("2010-04-01T00:00:00", "2010-06-01T00:00:00")
        root = ET.fromstring(xml)
        download_urls = root.findall('downloadUrls/downloadUrl')
        self.assertEqual(len(download_urls), 0)

    def test_12_files_no_results_range_below(self):
        xml = self._test_12_files("2003-04-01T00:00:00", "2003-06-01T00:00:00")
        root = ET.fromstring(xml)
        download_urls = root.findall('downloadUrls/downloadUrl')
        self.assertEqual(len(download_urls), 0)
    
    def test_file_only_needs_to_overlap_range(self):
        start = '2005-03-01T00:00:00Z'
        end = '2005-08-01T00:00:00Z'

        xml = self._do_test("user_id=dedasilv&dataset_id=data01&start="+start+"&end="+end,
                            "%s/dedasilv/data/data01/data01.txt" % self.temp_dir,
                            "2004-01-01T00:00:00Z,2004-05-31T00:00:00Z,/home/dedasilv/invalid.nc\n"
                            "2005-01-01T00:00:00Z,2005-05-31T00:00:00Z,/home/dedasilv/valid.nc\n"
                            "2006-01-01T00:00:00Z,2006-05-31T00:00:00Z,/home/dedasilv/invalid.nc\n")

        root = ET.fromstring(xml)
        download_urls = root.findall('downloadUrls/downloadUrl')

        self.assertEqual(len(download_urls), 1)
        self.assertEqual(download_urls[0].text, '/home/dedasilv/valid.nc')
        self.assertEqual(download_urls[0].attrib['label'], 'valid.nc')

    def test_file_range_superset_provided_ranged(self):
        start = '2005-03-01T00:00:00Z'
        end = '2005-04-01T00:00:00Z'

        xml = self._do_test("user_id=dedasilv&dataset_id=data01&start="+start+"&end="+end,
                            "%s/dedasilv/data/data01/data01.txt" % self.temp_dir,
                            "2004-01-01T00:00:00Z,2004-05-31T00:00:00Z,/home/dedasilv/invalid.nc\n"
                            "2005-01-01T00:00:00Z,2005-05-31T00:00:00Z,/home/dedasilv/valid.nc\n"
                            "2006-01-01T00:00:00Z,2006-05-31T00:00:00Z,/home/dedasilv/invalid.nc\n")

        root = ET.fromstring(xml)
        download_urls = root.findall('downloadUrls/downloadUrl')

        self.assertEqual(len(download_urls), 1)
        self.assertEqual(download_urls[0].text, '/home/dedasilv/valid.nc')
        self.assertEqual(download_urls[0].attrib['label'], 'valid.nc')
        

if __name__ == "__main__":
    unittest.main()
