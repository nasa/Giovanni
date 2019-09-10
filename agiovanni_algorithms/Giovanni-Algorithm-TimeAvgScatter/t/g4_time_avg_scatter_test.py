#!/bin/env python

import os
import sys
import tempfile
import unittest

import isodate
import netCDF4
from numpy.testing import assert_almost_equal

cur_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(cur_dir, '..', 'scripts'))

import g4_time_avg_scatter as S


class IntegrationTest(unittest.TestCase):

    def setUp(self):
        self.opt_f = tempfile.mkstemp()[1]
        self.opt_l = tempfile.mkstemp()[1]
        self.opt_o = tempfile.mkstemp()[1]

    def tearDown(self):
        os.remove(self.opt_f)
        os.remove(self.opt_l)

        if os.path.exists(self.opt_o):
            os.remove(self.opt_o)
    
    def test_001_trmm_3b42_daily_v6_v7(self):
        # Testing Phase
        # --------------------------------------------------------------
        data = [
            ('d/001/scrubbed.TRMM_3B42_daily_precipitation_V6.20050101.nc',
             'd/001/scrubbed.TRMM_3B42_daily_precipitation_V7.20050101.nc')
        ]
            
        with open(self.opt_f, 'w') as fh:
            for x_file, y_file in data:
                fh.write(os.path.join(cur_dir, x_file))
                fh.write(' ')
                fh.write(os.path.join(cur_dir, y_file))
                fh.write('\n')

        S.main([
            S.__name__,
            '-b', '-102.6562,23.3203,-73.8281,43.0078',
            '-s', '2005-01-01T00:00:00Z',
            '-e', '2005-01-01T23:59:59Z',
            '-x', 'TRMM_3B42_daily_precipitation_V6',
            '-y', 'TRMM_3B42_daily_precipitation_V7',
            '-f', self.opt_f,
            '-o', self.opt_o,
            '-l', self.opt_l,
        ], open('/dev/null', 'w'))

        # Verification Phase
        # --------------------------------------------------------------
        self.assertTrue(os.path.exists(self.opt_o))

        dataset = netCDF4.Dataset(self.opt_o)
        var_x = dataset.variables.get('x_TRMM_3B42_daily_precipitation_V6')
        var_y = dataset.variables.get('y_TRMM_3B42_daily_precipitation_V7')

        self.assertTrue(var_x)
        self.assertTrue(var_y)
        self.assertTrue('lon' in dataset.variables)
        self.assertTrue('lat' in dataset.variables)        
        self.assertTrue('sum_x' not in dataset.variables)
        self.assertTrue('sum_y' not in dataset.variables)
        self.assertTrue('correlation' not in dataset.variables)
        self.assertTrue('time_matched_difference' not in dataset.variables)
        self.assertTrue('offset' not in dataset.variables)
        self.assertTrue('slope' not in dataset.variables)
        self.assertTrue('n_samples' not in dataset.variables)
        
        assert_almost_equal(var_x[:].mean(), 0.85407738666696897)
        assert_almost_equal(var_y[:].mean(), 0.62942020454917991)

        isodate.parse_time(dataset.matched_start_time)
        isodate.parse_time(dataset.matched_end_time)
        self.assertEqual('daily', dataset.input_temporal_resolution)


class VarSpecTest(unittest.TestCase):
    """Tests for the VarSpec class"""
    def test_nozslice(self):
        opt_x = 'TRMM_3B42_daily_precipitation_V6'
        x = S.VarSpec(opt_x)
        self.assertEqual(x.var_name, opt_x)
        self.assertEqual(x.z_name, None)
        self.assertEqual(x.z_val, None)
        self.assertEqual(x.z_units, None)

    def test_zslice(self):
        opt_x = 'AIRX3STD_006_Temperature_A,TempPrsLvls_A=1000hPa'
        x = S.VarSpec(opt_x)
        self.assertEqual(x.var_name, 'AIRX3STD_006_Temperature_A')
        self.assertEqual(x.z_name, 'TempPrsLvls_A')
        assert_almost_equal(x.z_val, 1000.)
        self.assertEqual(x.z_units, 'hPa')

        
if __name__ == '__main__':
    unittest.main()
