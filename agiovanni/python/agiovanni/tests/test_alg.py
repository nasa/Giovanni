"""
Tests for the agiovanni.alg module.
"""
import tempfile
import unittest

import agiovanni.alg


class FileListIntegration(unittest.TestCase):

    def setUp(self):
        self.fileList = tempfile.NamedTemporaryFile()
        
    def test_roundtrip(self):
        files = map(str, range(100))
        files.reverse()

        agiovanni.alg.write_file_list(self.fileList.name, files)
        filesGot = agiovanni.alg.read_file_list(self.fileList.name)

        self.assertEqual(files, filesGot)


if __name__ == '__main__':
    unittest.main()
            
        
