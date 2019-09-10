import tempfile
import unittest
import shutil
import os

import numpy as np
from netCDF4 import Dataset

import remove_nans


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
        out_file = os.path.join(self.dir, 'out.nc')
        variable = 'SeaWiFS_L3m_CHL_2014_chlor_a'

        self.runTest(in_file, out_file, variable)

    def runTest(self, in_file, out_file, variable):

        remove_nans.main([in_file, out_file, variable])

        # make sure the output file was created
        self.assertTrue(os.path.exists(out_file), "Output file exists")

        # make sure there aren't any NaNs
        nc = Dataset(out_file)
        data = nc[variable][:]
        self.assertFalse(np.any(np.isnan(data)), "No NaN values in output")


if __name__ == "__main__":
    unittest.main()
