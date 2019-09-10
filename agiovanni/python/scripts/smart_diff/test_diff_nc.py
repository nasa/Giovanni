import unittest
import os
import diff_nc
import StringIO
import tempfile
import shutil
from subprocess import check_call

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"


class SmartDiffTest(unittest.TestCase):

    def setUp(self):
        curr_dir = os.path.dirname(os.path.realpath(__file__))
        self.fileDir = os.path.join(curr_dir, "tests")
        self.tempDir = tempfile.mkdtemp(prefix="test_sort")

    def tearDown(self):
        shutil.rmtree(self.tempDir)

    def testDiff(self):
        test_nc = os.path.join(self.fileDir, "test.nc")
        # remove some attributes
        new_nc = os.path.join(self.tempDir, "new.nc")
        cmd = [
            "ncatted",
            "-h",
            "-a",
            "start_time,global,d,,,",
            "-a",
            "standard_name,stddev_AIRX3STD_006_Temperature_A,d,,,",
            "-a",
            "long_name,stddev_AIRX3STD_006_Temperature_A,d,,,",
            "-a",
            "end_time,global,d,,,",
            test_nc,
            new_nc]
        check_call(cmd)

        # first do a regular diff
        out = StringIO.StringIO()
        argv = [test_nc, new_nc]
        diff_nc.main(argv, out)
        self.assertTrue(out.getvalue() != "",
                        "Difference due to attribute: %s" %
                        "\n".join(out.getvalue()))

        # now ignore 'Conventions'
        out = StringIO.StringIO()
        argv = [
            test_nc,
            new_nc,
            "-i",
            "/start_time",
            "-i",
            "/end_time",
            "-i",
            "stddev_AIRX3STD_006_Temperature_A/standard_name",
            "-i",
            "stddev_AIRX3STD_006_Temperature_A/long_name"]
        diff_nc.main(argv, out)
        self.assertTrue(
            out.getvalue() == "",
            "No difference: %s" % out.getvalue())

    def testDiffNoDiff(self):
        test_nc = os.path.join(self.fileDir, "test.nc")
        ref_nc = os.path.join(self.fileDir, "ref.nc")

        out = StringIO.StringIO()

        argv = [test_nc, ref_nc, "--ignore-nco"]
        diff_nc.main(argv, out)

        self.assertTrue(
            out.getvalue() == "",
            "No difference: %s" % out.getvalue())


if __name__ == "__main__":
    unittest.main()
