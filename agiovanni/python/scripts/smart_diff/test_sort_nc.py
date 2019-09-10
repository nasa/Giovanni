import unittest
import tempfile
import shutil
import os
import sort_nc
import agiovanni.smartdiff as sd

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"


class SmartDiffTest(unittest.TestCase):

    def setUp(self):
        self.tempDir = tempfile.mkdtemp(prefix="test_sort")
        curr_dir = os.path.dirname(os.path.realpath(__file__))
        self.fileDir = os.path.join(curr_dir, "tests")

    def tearDown(self):
        shutil.rmtree(self.tempDir)

    def testSort(self):
        test_nc = os.path.join(self.fileDir, "test.nc")
        correct_nc = os.path.join(self.fileDir, "test_sorted.nc")
        out_nc = os.path.join(self.tempDir,"test_sorted.nc")

        argv = [test_nc,out_nc]
        sort_nc.main(argv)

        self.assertTrue(os.path.exists(out_nc), "Output file created")
        df = sd.diff_nc(out_nc,correct_nc)
        self.assertTrue(len(df) == 0, "No differences")



if __name__ == "__main__":
    unittest.main()
