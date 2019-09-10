#!/bin/env python
"""Tests for the histogramPlot.py script."""

__author__ = 'Daniel da Silva <daniel.dasilva@nasa.gov>'

import commands
import os
import shutil
import StringIO
import tempfile
import unittest
import simplejson as json
import netCDF4 as nc
import numpy as np
from time import sleep

import histogramPlot as HP


class TestHistogramPlot(unittest.TestCase):

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.ds_counter = 0
        self.var_name = 'my_var_name'
        
    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def make_dataset(self, bin_left, bin_width, var_data):
        file_name = os.path.join(self.temp_dir, '%d.nc' % self.ds_counter)
        dataset = nc.Dataset(file_name, 'w')
        self.ds_counter += 1

        dataset.plot_hint_title = 'Plot Title'
        dataset.plot_hint_subtitle = 'Plot Subtitle'

        dataset.createDimension('bin_left', size=len(bin_left))
        var = dataset.createVariable('bin_left', 'f', ('bin_left',))
        var[:] = bin_left
        
        dataset.createDimension('bin_width', size=len(bin_width))
        var = dataset.createVariable('bin_width', 'f', ('bin_width',))
        var[:] = bin_width
        
        var = dataset.createVariable(self.var_name, 'f', ('bin_left',))
        var.product_short_name = 'ProdShortName'
        var.product_version = 'ProdVersion'
        var.long_name = 'LongName'
        var.units = 'Units'
        var.total = 1000
        var.mean = 5.0
        var.std = 2.5
        var.med_left = 1.0
        var.med_right = 1.0
        var.max = 1.0
        var.min = 1.0
        var.num_fill = 5
        var[:]= var_data
        
        dataset.close()        

        return file_name
    
    def do_test(self, bin_left, bin_width, var_data):
        input_file_name = self.make_dataset(bin_left, bin_width, var_data)
        output_file_name = os.path.join(self.temp_dir, 'plot.png')
        output_stream = StringIO.StringIO()

        argv = [
            HP.__file__,
            '-i', input_file_name,
            '-o', output_file_name[:-4],
            '-v', self.var_name,
        ]

        HP.main(argv, output_stream=output_stream)

        self.assertTrue(os.path.exists(output_file_name))

        command = 'file ' + output_file_name
        file_type_test = commands.getoutput(command)        
        self.assertTrue('PNG image data' in file_type_test)

        output_stream.seek(0)
        output_json = output_stream.read()
        output_stream.close()
        output_obj = json.loads(output_json)
        self.assertTrue(output_file_name in output_obj['images'][0])

    def test_constant_data(self, n=30):
        self.do_test(np.arange(n), np.ones(n), 5*np.ones(n))

    def test_log_data(self, n=30):
        self.do_test(np.arange(n), np.ones(n), np.logspace(0, 10, n))

    def test_linear_data(self, n=30):
        self.do_test(np.arange(n), np.ones(n), np.arange(n))

    def test_quadratic_data(self, n=30):
        self.do_test(np.arange(n), np.ones(n), np.arange(n)**2)


class FormatNumberTest(unittest.TestCase):

    def test_nan(self):
        self.assertEqual('nan', HP.format_number(float('nan')))

    def test_inf(self):
        self.assertEqual('inf', HP.format_number(float('inf')))

    def test_small_int(self):
        for num in range(-10, 10):
            self.assertEqual(str(num), HP.format_number(num))

    def test_small_npint32(self):
        num = np.int32(6)
        self.assertEqual(str(num), HP.format_number(num))

    def test_small_long(self):
        for num in range(-10, 10):
            as_long = long(num)
            self.assertEqual(str(as_long), HP.format_number(as_long))

    def test_small_pos_float(self):        
        self.assertEqual('1.00', HP.format_number(1.0))

    def test_small_neg_float(self):
        self.assertEqual('-1.00', HP.format_number(-1.0))        

    def test_large_pos_float_is_in_sci_not(self):
        formatted = HP.format_number(1e6)
        self.assertTrue('e' in formatted.lower())

    def test_large_neg_float_is_in_sci_not(self):
        formatted = HP.format_number(-1e6)
        self.assertTrue('e' in formatted.lower())

    def test_large_float(self):
        self.assertEqual('1.00e+06', HP.format_number(1e6))

    def test_large_npfloat32(self):
        num = np.float32(1e6)
        self.assertEqual('1.00e+06', HP.format_number(num))

    def test_large_npfloat64(self):
        num = np.float64(1e6)
        self.assertEqual('1.00e+06', HP.format_number(num))

        
if __name__ == '__main__':
    unittest.main()
