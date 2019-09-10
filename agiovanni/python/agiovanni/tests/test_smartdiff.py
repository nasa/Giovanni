import unittest
import os
import agiovanni.smartdiff as df
import tempfile
import shutil


__author__ = "Christine Smit <christine.e.smit@nasa.gov>"


class SmartDiffTest(unittest.TestCase):

    def setUp(self):
        curr_dir = os.path.dirname(os.path.realpath(__file__))
        self.fileDir = os.path.join(curr_dir, "test_smartdiff")
        self.tempDir = tempfile.mkdtemp(prefix="test_diff")

    def tearDown(self):
        shutil.rmtree(self.tempDir)

    def testDiffWithAttributeOutOfOrder(self):
        """
        Perform a simple test where the diff should be empty because the
        files are the same, but the attributes are in slightly different orders.
        """

        first_file = os.path.join(self.fileDir, 'ref.nc')
        second_file = os.path.join(self.fileDir, 'test.nc')

        out = df.diff_nc(first_file, second_file, ignore_nco=True)
        self.assertTrue(len(out) == 0, 'Files are the same')

    def testDiffWithValueDifferences(self):
        """
        Perform a test where the diff should not be empty. The files are not
        the same.
        """

        first_file = os.path.join(self.fileDir, 'ref.nc')
        second_file = os.path.join(self.fileDir, 'test_different.nc')

        # copy into the temporary directory
        first_copy = os.path.join(self.tempDir, "file.nc")
        shutil.copy(first_file, first_copy)
        os.mkdir(os.path.join(self.tempDir, "diff"))
        second_copy = os.path.join(self.tempDir, "diff", "file.nc")
        shutil.copy(second_file, second_copy)

        out = df.diff_nc(first_copy, second_copy, ignore_nco=True)
        self.assertTrue(len(out) != 0, "Files are different")

if __name__ == "__main__":
    unittest.main()
