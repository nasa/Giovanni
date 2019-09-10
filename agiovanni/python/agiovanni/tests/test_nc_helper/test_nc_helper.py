import tempfile
import unittest
import shutil
import os

import numpy as np
from netCDF4 import Dataset

from agiovanni.nc_helper import remove_nans
from agiovanni.smartdiff import diff_nc


class IntegrationTest(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.curr_dir = os.path.abspath(os.path.dirname(__file__))

    def tearDown(self):
        shutil.rmtree(self.dir)

    def testSimple(self):
        """
        Run a simple test where the input file has a single NaN.
        """
        in_file = os.path.join(
            self.curr_dir,
            'SeaWiFS_L3m_CHL_2014_chlor_a.nc')
        correct_out = os.path.join(
            self.curr_dir,
            'SeaWiFS_L3m_CHL_2014_chlor_a_fixed.nc')
        out_file = os.path.join(self.dir, 'out.nc')
        variable = 'SeaWiFS_L3m_CHL_2014_chlor_a'

        self.runTest(in_file, out_file, variable, correct_out)

    def testSameFile(self):
        """
        Run a test where the input and output files are the same file
        """
        out_file = os.path.join(self.dir, 'out.nc')
        shutil.copy(
            os.path.join(
                self.curr_dir,
                'SeaWiFS_L3m_CHL_2014_chlor_a.nc'),
            out_file)
        variable = 'SeaWiFS_L3m_CHL_2014_chlor_a'

        self.runTest(out_file, out_file, variable)

    def testFileAlreadyExists(self):
        """
        Run a test where something already exists in the output path
        """
        out_file = os.path.join(self.dir, 'out.nc')
        in_file = os.path.join(
            self.curr_dir,
            'SeaWiFS_L3m_CHL_2014_chlor_a.nc')
        shutil.copy(in_file, out_file)
        variable = 'SeaWiFS_L3m_CHL_2014_chlor_a'

        self.runTest(in_file, out_file, variable)

    def testFileWithFillAndNan(self):
        """
        Run a test on an input netcdf file that has a nan value and has
        a fill value
        """
        in_file = os.path.join(
            self.curr_dir,
            'SeaWiFS_L3m_CHL_2014_chlor_a_with_fill.nc')
        correct_out = os.path.join(
            self.curr_dir,
            'SeaWiFS_L3m_CHL_2014_chlor_a_with_fill_fixed.nc')
        out_file = os.path.join(self.dir, 'out.nc')
        variable = 'SeaWiFS_L3m_CHL_2014_chlor_a'

        self.runTest(in_file, out_file, variable, correct_out)

    def testFileWithNoNaN(self):
        """
        Run a test where no changes need to be made.
        """
        correct_out = os.path.join(
            self.curr_dir,
            'no_change.nc')
        variable = 'SeaWiFS_L3m_CHL_2014_chlor_a'
        out_file = os.path.join(self.dir, 'out.nc')
        shutil.copy(correct_out, out_file)

        self.runTest(out_file, out_file, variable, correct_out)

    def runTest(self, in_file, out_file, variable, correct_out=None):

        remove_nans(in_file, out_file, variable)

        # make sure the output file was created
        self.assertTrue(os.path.exists(out_file), "Output file exists")

        # make sure there aren't any NaNs
        nc = Dataset(out_file)
        data = nc[variable][:]
        self.assertFalse(np.any(np.isnan(data)), "No NaN values in output")

        # make sure the output file matches the correct output
        if correct_out is not None:
            diff = diff_nc(out_file, correct_out)
            self.assertSequenceEqual(
                [],
                diff,
                "Output matches expected netcdf: %s" %
                "\n".join(diff))


if __name__ == "__main__":
    unittest.main()
