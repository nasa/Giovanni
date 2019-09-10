#! /bin/env python
"""
Tests for g4_histogram.py
"""

__author__ = 'Daniel da Silva <daniel.dasilva@nasa.gov>'

import StringIO
import os
import shutil
import sys
import tempfile
import unittest

import netCDF4 as nc
import numpy as np

cur_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(cur_dir, '..', 'scripts'))

import g4_histogram as H


class MockOptions(object):
    """A Mock class for the return value of parse_cli_args()."""
    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)


class DatasetTestCase(unittest.TestCase):
    """TestCase base class with methods to generate datasets."""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.ds_counter = 0
        self.start_time = 1404226009  # start time is 1 Jul 2014
        
        self.attribs = {
            'product_version': '006',
            'coordinates': 'time lat lon',
            'long_name': "Ozone Total Column (Daytime/Ascending)",
            'standard_name': "toto3_a",
            'product_short_name': "AIRX3STD",
            'quantity_type': 'Ozone',
            'units': 'DU'
        }

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def make_dataset(self, data, time, lat, lon, z=None, z_pos=None,
                     var_name='data', fill_value=None):
        file_name = os.path.join(self.temp_dir, '%d.nc' % self.ds_counter)
        dataset = nc.Dataset(file_name, 'w')
        self.ds_counter += 1

        # lat: dimension, variable
        dataset.createDimension('lat', size=len(lat))
        var = dataset.createVariable('lat', 'f', ('lat',))
        var[:] = lat
        var.standard_name = "latitude"
        var.units = "degrees_north"

        # lon: dimension, variable
        dataset.createDimension('lon', size=len(lon))
        var = dataset.createVariable('lon', 'f', ('lon',))
        var[:] = lon
        var.standard_name = "longitude"
        var.units         = "degrees_east"

        # time: dimension (unlimited), variable
        dataset.createDimension('time')
        var = dataset.createVariable('time', 'i', ('time',))
        var[:] = time
        var.standard_name = "time"
        var.units = "seconds since 1970-01-01 00:00:00"

        # z, dimension, variable (if present)
        if z is not None:
            dataset.createDimension('pressure')
            var = dataset.createVariable('pressure', 'f', ('pressure',))
            var[:] = z
            var.standard_name = 'air_pressure'
            var.units = 'hPa'            
        
        # data: variable
        dims = ['time', 'lat', 'lon']

        if z is not None:
            if z_pos is None:
                dims.append('pressure')
            else:
                dims.insert(z_pos, 'pressure')
        
        var = dataset.createVariable(var_name, 'f', dims,
                                     fill_value=fill_value)
        var[:] = data

        for name, value in self.attribs.iteritems():
            var.setncattr(name, value)

        dataset.close()

        return file_name

    def make_lat(self, N):
        delta = 180. / N
        return [-90 + i * delta for i in range(N)]

    def make_lon(self, N):
        delta = 360. / N
        return [-180 + i * delta for i in range(N)]
    
    def make_time(self, N):
        return [self.start_time + 60 * i for i in range(N)]

    def make_pressure(self, N):
        return np.arange(N) * 100 + 10 * N


class IntegrationTest(DatasetTestCase):
    """Integration tests for the whole script."""

    def test_all_fill_in_memory(self):
        self.do_test(H.InMemoryFlow, all_fill=True)

    def test_all_fill_rolling_flow(self):
        self.do_test(H.RollingFlow, all_fill=True)        

    def test_ising_spin_with_subsetting_in_memory(self):
        self.do_test(H.InMemoryFlow)

    def test_ising_spin_with_subsetting_rolling_flow(self):
        self.do_test(H.RollingFlow)


    def test_ising_spin_with_subsetting_in_memory_zslice(self):
        self.do_test(H.InMemoryFlow, with_z=True)

    def test_ising_spin_with_subsetting_in_memory_zslice_variant(self):
        self.do_test(H.InMemoryFlow, with_z=True, z_pos_variant=True)

    def test_ising_spin_with_subsetting_rolling_zslice(self):
        self.do_test(H.RollingFlow, with_z=True)

    def test_ising_spin_with_subsetting_rolling_zslice_variant(self):
        self.do_test(H.RollingFlow, with_z=True, z_pos_variant=True)
    
    def do_test(self, flow, with_z=None, z_pos_variant=False, all_fill=False):
        # The z_pos_variant flag has the data built where it the 
        # dimensions are (time, pressure, lat, lon) in that order.        
        # By default, pressure is last. This is to test the ability
        # of the script to adapt to multiple orderings.
        NUM_FILES = 5 
        NUM_BINS = 50                              # Unconfigurable at...
                                                   # ...time of writing
        NX = 40
        NY = 50
        NT =  5                                    # Per file
        NZ = 10

        # Make the data
        file_names = []

        if with_z:
            if z_pos_variant:
                data = np.zeros((NT, NZ, NY, NX))
            else:
                data = np.zeros((NT, NY, NX, NZ))
        else:
            data = np.zeros((NT, NY, NX))

        time = self.make_time(NT)
        lat = self.make_lat(NY)
        lon = self.make_lon(NX)
        pressure = self.make_pressure(NZ)

        # This code is absurd.
        if all_fill:
            data = data - 999.0
            if with_z:
                data[0,0,0,0] = -1
                data[0,0,0,1] =  1
            else:
                data[0,0,0] = -1
                data[0,0,1] =  1                
        elif with_z:
            if z_pos_variant:
                switch = -1
                for i in range(NT):
                    for j in range(NZ):
                        for k in range(NY):
                            for l in range(NX):
                                data[i, j, k, l] = switch
                            switch *= -1
            else:
                switch = -1
                for i in range(NT):
                    for j in range(NY):
                        for k in range(NX):
                            for l in range(NZ):
                                data[i, j, k, l] = switch
                            switch *= -1
        else:                
            switch = -1
            for i in xrange(NT):
                for j in xrange(NY):
                    for k in xrange(NX):
                        data[i, j, k] = switch
                        switch *= -1
                        
        for _ in range(NUM_FILES):
            if all_fill:
                file_name = self.make_dataset(data, time, lat, lon,
                                              fill_value=-999.)
            elif with_z:
                if z_pos_variant:
                    file_name = self.make_dataset(data, time, lat, lon,
                                                  z=pressure, z_pos=1)
                else:
                    file_name = self.make_dataset(data, time, lat, lon,
                                                  z=pressure)
            else:
                file_name = self.make_dataset(data, time, lat, lon)

            file_names.append(file_name)

        # Write list of files
        file_list_file_name = os.path.join(self.temp_dir,
                                           'files.txt')

        f = open(file_list_file_name, 'w')

        for file_name in file_names:
            f.write(file_name + '\n')

        f.close()

        # Call the script
        out_file_name = os.path.join(self.temp_dir, 'histogram.nc')

        opts = {
            '-s': '2010-01-01T00:00:00Z',
            '-e': '2020-01-01T00:00:00Z',
            '-f': file_list_file_name,
            '-o': out_file_name,
            '-v': 'data',
        }

        if all_fill:
            opts['-b'] = '-180,-90,180,90'
        else:
            opts['-b'] = '-92.3,-23.4,102.3,25.5'

        if with_z:
            opts['-z'] = 'pressure=%dhPa' % int(pressure[5])

        argv = [H.__file__]

        for item in opts.iteritems():
            argv.extend(item)

        H.UiComm.set_quiet(True)

        try:
            H.main(argv, flow_override=flow)
        finally:
            H.UiComm.set_quiet(False)

        old_data = data

        # Verify
        # ------------------------------------------------
        self.assertTrue(os.path.exists(out_file_name))
        dataset = nc.Dataset(out_file_name)

        self.assertEqual(dataset.file_format, 'NETCDF4_CLASSIC')
        
        # bin_left
        self.assertTrue('bin_left' in dataset.dimensions)
        self.assertTrue('bin_left' in dataset.variables)

        dim = dataset.dimensions['bin_left']
        self.assertEqual(len(dim), NUM_BINS)
        
        var = dataset.variables['bin_left']
        data = var[:]
        self.assertEqual(len(data), NUM_BINS)

        # data
        self.assertTrue('data' in dataset.variables)

        var = dataset.variables['data']
        data = var[:]

        self.assertEqual(len(data), NUM_BINS)
        
        if all_fill:
            self.assertEqual(data[0], NUM_FILES)
            self.assertEqual(data[-1], NUM_FILES)
        else:
            self.assertEqual(data[0], 3850)
            self.assertEqual(data[-1], 3850)


        # Var attributes
        for attrib_name, attrib_value in self.attribs.iteritems():            
            self.assertEqual(getattr(var, attrib_name), attrib_value)

        for attrib_name in 'total mean std min max'.split():
            self.assertTrue(hasattr(var, attrib_name))

        if all_fill:
            self.assertEqual(var.total, 2*NUM_FILES)            

        if flow is H.InMemoryFlow:
            self.assertTrue(hasattr(var, 'med'))


class ParseCliArgsTest(unittest.TestCase):
    """Tests for the parse_cli_args() function."""

    def set_args(self, with_=None, without=None):
        if with_ is None:
            with_ = {}

        if without is None:
            without = []

        self.opts = {
            '-s': '1997-01-01T00:00:00Z',
            '-e': '1998-01-01T00:00:00Z',
            '-b': '-92.3,-23.4,102.3,25.5',
            '-f': 'input.txt',
            '-o': 'output.txt',
            '-v': 'var_name',
        }

        for opt_name, opt_value in with_.iteritems():
            self.opts[opt_name] = opt_value

        self.args = []

        for opt_name, opt_value in self.opts.iteritems():
            if opt_name not in without:
                self.args.append(opt_name)
                self.args.append(opt_value)
        
    def test_all_valid(self):
        # Tests the parse_cli_args() function with all valid args.
        self.set_args()
        options = H.parse_cli_args(self.args)        

        for opt_name, opt_value in self.opts.iteritems():
            self.assertEqual(getattr(options, opt_name[1:]), opt_value)

    def test_missing_start_time(self):
        self.set_args(without=['-s'])
        self.assertRaises(ValueError, H.parse_cli_args, self.args)

    def test_missing_end_time(self):
        self.set_args(without=['-e'])
        self.assertRaises(ValueError, H.parse_cli_args, self.args)

    def test_missing_bbox(self):
        self.set_args(without=['-b'])
        self.assertRaises(ValueError, H.parse_cli_args, self.args)
    
    def test_missing_var(self):
        self.set_args(without=['-v'])
        self.assertRaises(ValueError, H.parse_cli_args, self.args)

    def test_invalid_start_time(self):
        self.set_args(with_={'-s': 'broken'})
        self.assertRaises(ValueError, H.parse_cli_args, self.args)

    def test_invalid_end_time(self):
        self.set_args(with_={'-e': 'broken'})
        self.assertRaises(ValueError, H.parse_cli_args, self.args)

    def test_invalid_bbox(self):
        self.set_args(with_={'-b': 'broken'})
        self.assertRaises(ValueError, H.parse_cli_args, self.args)

    def test_invalid_bbox_two(self):
        self.set_args(with_={'-b': '10.0,10.0,2.0'})
        self.assertRaises(ValueError, H.parse_cli_args, self.args)


class UiCommTest(unittest.TestCase):
    """Tests for the UiComm class."""

    def test_set_quiet_prevents_writes(self):
        msg = 'my line'
        funcs = [
            H.UiComm.user_info,
            H.UiComm.error,
            H.UiComm.debug,
            H.UiComm.percent_done,
        ]

        H.UiComm.set_quiet(True)

        for func in funcs:
            stream = StringIO.StringIO()
            func(msg, stream)
            self.assertEqual('', stream.read())

        H.UiComm.set_quiet(False)

    def test_user_info_writes_expected(self):
        msg = 'status line'
        stream = StringIO.StringIO()
        H.UiComm.user_info(msg, stream)
        stream.seek(0)
        contents = stream.read()
        desired_contents = 'USER_INFO ' + msg + '\n'
        self.assertEqual(contents, desired_contents)

    def test_error_writes_expected(self):
        msg = 'error line'
        stream = StringIO.StringIO()
        H.UiComm.error(msg, stream)
        stream.seek(0)
        contents = stream.read()
        desired_contents = 'ERROR ' + msg + '\n'
        self.assertEqual(contents, desired_contents)

    def test_debug_writes_expected(self):
        msg = 'debug line'
        stream = StringIO.StringIO()
        H.UiComm.debug(msg, stream)
        stream.seek(0)
        contents = stream.read()
        desired_contents = 'DEBUG ' + msg + '\n'
        self.assertEqual(contents, desired_contents)

    def test_percent_done_writes_expected(self):
        amount = 50
        stream = StringIO.StringIO()
        H.UiComm.percent_done(amount, stream)
        stream.seek(0)
        contents = stream.read()
        desired_contents = 'PERCENT_DONE %d\n' % amount
        self.assertEqual(contents, desired_contents)        

    def test_should_update_first_iteration(self):
        self.assertTrue(H.UiComm.should_update(0))


class InMemoryFlowTest(unittest.TestCase):
    """Tests for the InMemoryFlow class"""
    
    def test_calc_stats_all_zeros(self):
        # Tests using a dataset with all zero values.
        N = 100
        all_data = np.zeros(N)
        flow = H.InMemoryFlow(None, None)
        stats = flow.calc_stats(all_data, 0, 0)

        self.assertEqual(N, stats.total)
        self.assertEqual(0.0, stats.min_value)
        self.assertEqual(0.0, stats.max_value)
        self.assertEqual(0.0, stats.mean)
        self.assertEqual(0.0, stats.std)
    
    def test_calc_stats_alt_zero_ones(self):
        # Tests using a dataset with alternating values of 0 and 1.
        N = 2**7
        all_data = np.array([0, 1])
        for _ in range(6):
            all_data = np.concatenate((all_data, all_data))

        flow = H.InMemoryFlow(None, None)
        stats = flow.calc_stats(all_data, 0, 0)
        self.assertEqual(N, stats.total)
        self.assertEqual(0.0, stats.min_value)
        self.assertEqual(1.0, stats.max_value)
        self.assertEqual(0.5, stats.mean)
        self.assertEqual(0.5, stats.std)
    
    def test_calc_histogram_uniform(self):
        # Tests InMemoryFlow.calc_histogram() with uniformly dist data.
        NUM_BINS = 20
        all_data = np.arange(20)

        options = MockOptions(num_bins=NUM_BINS)
        flow = H.InMemoryFlow(None, options)
        hist, bin_edges = flow.calc_histogram(all_data)

        self.assertEqual(len(set(hist[:-1])), 1)
        self.assertEqual(len(hist), options.num_bins)
        self.assertEqual(len(bin_edges), NUM_BINS + 1)
    

if __name__ == '__main__':
    unittest.main()
