"""
Tests for the gpm world file issue
"""

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import unittest
import tempfile
import shutil
import os
from textwrap import dedent
import numpy as np
import numpy.testing as npt

import agiovanni.map_plot as mp


class IntegrationTest(unittest.TestCase):

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.curr_dir = os.path.dirname(os.path.realpath(__file__))

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def testGpm(self):
        nc_file = os.path.join(
            self.curr_dir,
            "g4.timeAvgMap.GPM_3IMERGHH_05_precipitationCal.20141001-20141001.180W_90S_180E_90N.nc")

        v = mp.Visualize(nc_file)

        world_file = os.path.join(self.temp_dir, 'test.wld')
        v.create_world_file(world_file)

        self.assertTrue(os.path.exists(world_file))

        correct_wld = dedent("""\
            0.1
            0
            0
            -0.1
            -179.95
            89.95
            """)
        with open(world_file, 'r') as wld:
            out_wld = wld.read()

        IntegrationTest.check_wld_is_close(correct_wld, out_wld)

    @staticmethod
    def check_wld_is_close(correct_wld, test_wld):
        # Break up the world file by end of line. Ditch the last empty line.
        # Parse as floats.
        correct_values = [np.double(val)
                          for val in correct_wld.split("\n")[0:-1]]
        test_values = [np.double(val) for val in test_wld.split("\n")[0:-1]]

        # The resolution values were the ones causing the problem.
        npt.assert_array_almost_equal(correct_values[0:4], test_values[0:4], 8)
        # The upper left pixel location was less of an issue.
        npt.assert_array_almost_equal(correct_values[4:], test_values[4:], 4)
