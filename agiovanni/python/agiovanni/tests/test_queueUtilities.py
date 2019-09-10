"""
Tests for the agiovanni.queueUtilities module.
"""

import unittest
import tempfile
import shutil
import os
from textwrap import dedent
from subprocess import check_call, CalledProcessError

import agiovanni.queueUtilities as qu


class IntegrationTest(unittest.TestCase):

    """test_netcdf.py: Test the netcdf library functionality."""

    def setUp(self):
        self.dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.dir)

    def test_lock_and_unlock(self):
        """
        Test locking and unlocking. To do this test, I have to run a python
        script in a different process to lock the file.
        """

        lock_file_path = os.path.join(self.dir, "file.txt")

        # create a simple python script file that
        script_path = os.path.join(self.dir, 'script.py')
        with open(script_path, 'w') as f:
            f.write(dedent("""
           import os
           from agiovanni.queueUtilities import lock_file,unlock_file

           f_handle = open('%s','a+')
           lock_file(f_handle,1)
           unlock_file(f_handle)
           f_handle.close()
           exit(0)
           """ % lock_file_path))

        cmd = ['python', script_path]

        devnull_stream = open(os.devnull, 'w')
        check_call(cmd, stdout=devnull_stream, stderr=devnull_stream)

        # now lock the file
        f1 = open(lock_file_path, 'a+')
        qu.lock_file(f1)

        # run the command again. It should fail
        with self.assertRaises(CalledProcessError):
            check_call(cmd, stdout=devnull_stream, stderr=devnull_stream)

        qu.unlock_file(f1)

        # and now it should succeed
        check_call(cmd, stdout=devnull_stream, stderr=devnull_stream)

        f1.close()

    def test_get_task_lock(self):
        """
        Tests the get_task_lock function
        """

        task_id = "task"
        postfix = "test"

        # the first time, we should get a lock
        self.assertTrue(
            qu.get_task_lock(
                task_id,
                self.dir,
                postfix),
            "Get task lock")

        # the second time, we shouldn't
        self.assertFalse(qu.get_task_lock(task_id, self.dir, postfix),
                         "Task lock no longer available")


if __name__ == "__main__":
    unittest.main()
