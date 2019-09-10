#!/bin/env python
"""Tests for the curtainPlot.py script."""

__author__ = 'Maksym Petrenko <maksym_petrenko@nasa.gov>'

import commands
import os
import shutil
import StringIO
import tempfile
import unittest
import simplejson as json
import random
import netCDF4 as nc
import numpy as np

import curtainPlot as CP


class TestCurtainPlot(unittest.TestCase):

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.ds_counter = 0
        self.var_name = 'my_var_name'
        
    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def make_dataset_lon(self, n_steps_Y, n_steps_X):
        file_name = os.path.join(self.temp_dir, '%d.nc' % self.ds_counter)
        dataset = nc.Dataset(file_name, 'w')
        self.ds_counter += 1
        
        dataset.plot_hint_title = 'Plot Title'
        dataset.plot_hint_subtitle = 'Plot Subtitle'

        dataset.createDimension('Height', n_steps_Y)
        var = dataset.createVariable('Height', 'f', ('Height',))
        var.long_name = 'Height'
        var.units = 'units'
        var[:] = np.linspace(0.1,1000,n_steps_Y)
        
        
        dataset.createDimension('lon', n_steps_X)
        var = dataset.createVariable('lon', 'f', ('lon',))
        var.long_name = 'Longitude'
        var.units = 'units'
        var[:] =  np.linspace(-150,150,n_steps_X)
       
        var = dataset.createVariable(self.var_name, 'f', ('Height','lon'), fill_value=-9999.)
        var_data = np.array([[random.random()*300 for i in range(n_steps_Y)] for j in range(n_steps_X)])
        var.long_name = 'LongName'
        var.units = 'Units'
        var[:]= var_data
        
        dataset.close()        

        return file_name
    
    def make_dataset_time(self, n_steps_Y, n_steps_X):
        file_name = os.path.join(self.temp_dir, '%d.nc' % self.ds_counter)
        dataset = nc.Dataset(file_name, 'w')
        self.ds_counter += 1
        
        time_steps = [1420070400.0,1422748800.0,1425168000.0,1427846400.0]
        time_bands= [[1420070400.0,1422748800.0],[1422748800.0,1425168000.0],[1425168000.0,1427846400.0],[1427846400.0,1430524800.0]]
        
        dataset.plot_hint_title = 'Plot Title'
        dataset.plot_hint_subtitle = 'Plot Subtitle'
        dataset.plot_hint_time_axis_values = '1420070400,1422748800,1425168000,1427846400,1430438400'
        dataset.plot_hint_time_axis_labels = '1 Jan~C~2015,1 Feb,1 Mar,1 Apr,1 May'

        dataset.createDimension('Height', n_steps_Y)
        var = dataset.createVariable('Height', 'f', ('Height',))
        var.long_name = 'Height'
        var.units = 'units'
        var[:] = np.linspace(0.1,1000,n_steps_Y)
        
        dataset.createDimension('time', len(time_steps))
        var = dataset.createVariable('time', 'f', ('time',))
        var.long_name = 'Time'
        var.units = 'units'
        var[:] =  time_steps
        
        dataset.createDimension('bnds', 2)
        var = dataset.createVariable('time_bnds', 'f', ('time','bnds'))
        var.long_name = 'Time bands'
        var.units = 'units'
        var[:] =  time_bands
       
        var = dataset.createVariable(self.var_name, 'f', ('time','Height'), fill_value=-9999.)
        var_data = np.array([[random.random()*300 for i in range(n_steps_Y)] for j in range(len(time_steps))])
        var.long_name = 'LongName'
        var.units = 'Units'
        var[:]= var_data
        
        dataset.close()        

        return file_name
    
    def do_test(self, n_steps_Y=1, n_steps_X=1, plot_type='lon'):
        if plot_type=='lon' or plot_type=='lat':
            input_file_name = self.make_dataset_lon(n_steps_Y, n_steps_X)
        elif plot_type=='time':
            input_file_name = self.make_dataset_time(n_steps_Y, n_steps_X)
        output_file_name = os.path.join(self.temp_dir, 'plot.png')
        output_stream = StringIO.StringIO()

        argv = [
            CP.__file__,
            '-i', input_file_name,
            '-o', output_file_name[:-4],
            '-v', self.var_name,
        ]

        CP.main(argv, output_stream=output_stream)

        self.assertTrue(os.path.exists(output_file_name))

        command = 'file ' + output_file_name
        file_type_test = commands.getoutput(command)        
        self.assertTrue('PNG image data' in file_type_test)

        output_stream.seek(0)
        output_json = output_stream.read()
        output_stream.close()
        output_obj = json.loads(output_json)
        self.assertTrue(output_file_name in output_obj['images'][0])

    def test_lon_plot(self):
        self.do_test(50,288,'lon')

   
    def test_time_plot(self):
        self.do_test(50,plot_type='time')


        
if __name__ == '__main__':
    unittest.main()
