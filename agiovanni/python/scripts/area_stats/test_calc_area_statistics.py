'''
Tests the calc_area_statics.py script
'''
__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import unittest
import tempfile
import shutil
import os
import numpy.ma as ma

from netCDF4 import Dataset

import calc_area_statistics as cas


class IntegrationTest(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.dir)

    def test_update_vars_and_dims(self):
        '''
        Runs tests against the "_update_vars_and_dims" function.
        '''

        # This first dictionary's data_var is not connected to the lat, lon,
        # or other_var variables or to the lat,lon dimensions.
        var_dict = {
            'data_var': {
                'dimensions': {'time'},
                'attributes': {
                    'coordinates': 'time'
                }
            },
            'time': {
                'dimensions': {'time'},
                'attributes': {
                    'bounds': 'time_bnds'
                }
            },
            'time_bnds': {
                'dimensions': {'time', 'bnds'},
                'attributes': {}
            },
            'lat': {
                'dimensions': {'lat'},
                'attributes': {}
            },
            'lon': {
                'dimensions': {'lon'},
                'attributes': {}
            },
            'other_var': {
                'dimensions': {'time', 'lat', 'lon'},
                'attributes': {'coordinates': 'time lat lon'}
            }
        }
        # start with data_var
        var_names = {'data_var'}
        # let it find all the dimensions
        dim_names = set()
        cas._update_vars_and_dims(var_dict, var_names, dim_names)
        self.assertSetEqual(
            var_names, {
                'data_var', 'time', 'time_bnds'}, "Didn't grab extra variables")
        self.assertSetEqual(
            dim_names, {
                'time', 'bnds'}, "Didn't grab extra dimensions")

        # This second dictionary's data_var uses coordinates that are different
        # from the dimension.
        var_dict = {
            'data_var': {
                'dimensions': {'x'},
                'attributes': {
                    'coordinates': 'lat lon'
                }
            },
            'lat': {
                'dimensions': {'x'},
                'attributes': {
                    'bounds': 'lat_bnds'
                }
            },
            'lon': {
                'dimensions': {'x'},
                'attributes': {
                    'bounds': 'lon_bnds'
                }
            },
            'lat_bnds': {
                'dimensions': {'lat', 'bnds'},
                'attributes': {}
            },
            'lon_bnds': {
                'dimensions': {'lon', 'bnds'},
                'attributes': {}
            }
        }
        # start with data_var
        var_names = {'data_var'}
        # let it find all the dimensions
        dim_names = set()
        cas._update_vars_and_dims(var_dict, var_names, dim_names)
        self.assertSetEqual(
            var_names, {
                'data_var', 'lat', 'lon', 'lat_bnds', 'lon_bnds'}, "Got all the coordinates and bounds")
        self.assertSetEqual(
            dim_names, {
                'x', 'bnds', 'lat', 'lon'}, "Got the bounds dimension")

    def testUnits(self):
        '''
        Run a test and make sure the units for the count variable are '1'.
        '''
        # copy the test file into the temporary directory
        curr_dir = os.path.dirname(__file__)
        test_filename = "subsetted.OMSO2e_003_ColumnAmountSO2_PBL.20050101.nc"
        shutil.copy(os.path.join(curr_dir, test_filename), self.dir)

        in_file = os.path.join(self.dir, test_filename)
        out_file = os.path.join(self.dir, "stats.nc")
        argv = [in_file, out_file]
        cas.main(argv)
        # make sure the output file was created
        self.assertTrue(os.path.exists(out_file), "Created output file")

        # read in the file
        nc = Dataset(out_file, 'r')
        self.assertEqual(
            nc["count_OMSO2e_003_ColumnAmountSO2_PBL"].units,
            '1',
            'Counts variable units set to 1')

    def testExtraVariables(self):
        '''
        Run a test against a file with an extra variable that should not be
        copied over into the output file.
        '''
        curr_dir = os.path.dirname(__file__)
        test_filename = "MAI3CPASM_5_2_0_RH.withHeight.nc"
        shutil.copy(os.path.join(curr_dir, test_filename), self.dir)

        in_file = os.path.join(self.dir, test_filename)
        out_file = os.path.join(self.dir, "stats.nc")
        argv = [in_file, out_file]
        cas.main(argv)
        # make sure the output file was created
        self.assertTrue(os.path.exists(out_file), "Created output file")

        # read out the data
        nc = Dataset(out_file, 'r')
        self.assertTrue(
            "Height" not in nc.variables.keys(),
            "Did not copy over the height variable")

    def testSinglePoint(self):
        '''
        Run a test where the input data is a single point that is a fill value.
        '''
        curr_dir = os.path.dirname(__file__)
        test_filename = "ss.180W_26N_180E_40N_scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20090101.x.nc"
        shutil.copy(os.path.join(curr_dir, test_filename), self.dir)

        in_file = os.path.join(self.dir, test_filename)
        out_file = os.path.join(self.dir, "stats.nc")
        argv = [in_file, out_file]
        cas.main(argv)
        # make sure the output file was created
        self.assertTrue(os.path.exists(out_file), "Created output file")

        # read out the data
        nc = Dataset(out_file, 'r')
        self.assertAlmostEqual(
            nc["MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][0],
            0.021,
            3,
            "Correct mean")
        self.assertEqual(
            nc["MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"].quantity_type,
            "Total Aerosol Optical Depth", "Correct quantity type for average")

        self.assertAlmostEqual(
            nc["min_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][0],
            0.021,
            3,
            "Correct min")
        self.assertEqual(
            nc["min_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"].quantity_type,
            "minimum of Total Aerosol Optical Depth", "Correct quantity type for minimum")

        self.assertAlmostEqual(
            nc["max_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][0],
            0.021,
            3,
            "Correct max")
        self.assertEqual(
            nc["max_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"].quantity_type,
            "maximum of Total Aerosol Optical Depth", "Correct quantity type for maximum")

        self.assertAlmostEqual(
            nc["stddev_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][0],
            0.0,
            2,
            "Correct stddev")
        self.assertEqual(
            nc["stddev_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"].quantity_type,
            "standard deviation of Total Aerosol Optical Depth", "Correct quantity type for standard deviation")

        self.assertAlmostEqual(
            nc["count_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][0],
            1,
            1,
            "Correct count")
        self.assertEqual(
            nc["count_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"].quantity_type,
            "count of Total Aerosol Optical Depth", "Correct quantity type for count")

    def testAllFill(self):
        '''
        Run a test where the input data is a single point that is a fill value.
        '''
        curr_dir = os.path.dirname(__file__)
        test_filename = "ss.180W_26N_180E_40N_scrubbed.MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean.20090103.x.nc"
        shutil.copy(os.path.join(curr_dir, test_filename), self.dir)

        in_file = os.path.join(self.dir, test_filename)
        out_file = os.path.join(self.dir, "stats.nc")
        argv = [in_file, out_file]
        cas.main(argv)
        # make sure the output file was created
        self.assertTrue(os.path.exists(out_file), "Created output file")

        # read out the data
        nc = Dataset(out_file, 'r')
        avg = nc["MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][:]
        self.assertTrue(avg[0] is ma.masked, "Correct mean")
        min_ = nc["min_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][:]
        self.assertTrue(min_[0] is ma.masked, "Correct min")
        max_ = nc["max_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][:]
        self.assertTrue(max_[0] is ma.masked, "Correct max")
        stddev = nc["stddev_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][:]
        self.assertTrue(stddev[0] is ma.masked, "Correct stddev")
        self.assertEqual(
            nc["count_MOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean"][0],
            0, "Correct count")

    def test3D(self):
        '''
        Run a test where the data has a vertical dimension
        '''
        # copy the test file into the temporary directory
        curr_dir = os.path.dirname(__file__)
        test_filename = "scrubbed.MAIMCPASM_5_2_0_RH.20150101000000.x.nc"
        shutil.copy(os.path.join(curr_dir, test_filename), self.dir)

        in_file = os.path.join(self.dir, test_filename)
        out_file = os.path.join(self.dir, "stats.nc")
        argv = [in_file, out_file]
        cas.main(argv)
        # make sure the output file was created
        self.assertTrue(os.path.exists(out_file), "Created output file")

    def testTimeBounds(self):
        '''
        Run a test where the data has time bounds
        '''
        # copy the test file into the temporary directory
        curr_dir = os.path.dirname(__file__)
        test_filename = "sub.MAI3CPASM_5_2_0_RH.198001010000.nc"
        shutil.copy(os.path.join(curr_dir, test_filename), self.dir)

        in_file = os.path.join(self.dir, test_filename)
        out_file = os.path.join(self.dir, "stats.nc")
        argv = [in_file, out_file]
        cas.main(argv)
        # make sure the output file was created
        self.assertTrue(os.path.exists(out_file), "Created output file")
        # make sure it has time_bnds!
        nc = Dataset(out_file, 'r')
        self.assertTrue(
            'time_bnds' in nc.variables.keys(),
            "Time bounds copied over")

    def testBasic(self):
        # copy the test file into the temporary directory
        curr_dir = os.path.dirname(__file__)
        test_filename = "subsetted.OMSO2e_003_ColumnAmountSO2_PBL.20050101.nc"
        shutil.copy(os.path.join(curr_dir, test_filename), self.dir)

        in_file = os.path.join(self.dir, test_filename)
        out_file = os.path.join(self.dir, "stats.nc")
        argv = [in_file, out_file]
        cas.main(argv)
        # make sure the output file was created
        self.assertTrue(os.path.exists(out_file), "Created output file")


if __name__ == "__main__":
    unittest.main()
