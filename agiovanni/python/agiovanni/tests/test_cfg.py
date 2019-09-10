"""
Tests for the agiovanni.cfg module.
"""

import os
import shutil
import tempfile
import unittest

from agiovanni import cfg


class ConfigEnvironmentTest(unittest.TestCase):
    """Tests for the ConfigEnvironment Class.
    
    These tests create a fake giovanni_config.pl in a temp directory
    and set it to the highest precendence in the PATH. 
    """

    def setUp(self):
        # We put the temporary directory in the current directory
        # and not /tmp, because we are running giovanni_config.pl
        # from this directory and /tmp may be mounted with the 
        # noexec option.
        self.temp_dir = tempfile.mkdtemp(prefix=os.getcwd() + '/')
        self.orig_path = os.environ['PATH']
        os.environ['PATH'] = self.temp_dir + ':' + self.orig_path

        self.config_env = cfg.ConfigEnvironment()
    
    def tearDown(self):
        shutil.rmtree(self.temp_dir)
        os.environ['PATH'] = self.orig_path

    def _write_giovanni_config_pl(self, contents):
        file_path = os.path.join(self.temp_dir, 'giovanni_config.pl')
        fh = open(file_path, 'w')
        fh.write(contents)
        fh.close()

        os.chmod(file_path, 500)

    def test_get_passes_target(self):
        # Have script echo back target
        self._write_giovanni_config_pl("""#/bin/bash
        echo $1
        """)

        target = "$GIOVANNI::FOOBAR"
        config_value = self.config_env.get(target)
        self.assertEqual(config_value, target)

    def test_get_simple_echo(self):
        self._write_giovanni_config_pl("""#/bin/bash
        echo myvalue
        """)
        
        config_value = self.config_env.get("mytarget")
        self.assertEqual(config_value, "myvalue")
    
    def test_getAATSDownSamplingFactor(self):
        self._write_giovanni_config_pl("""#!/bin/bash
        
        if [ $1 == '$GIOVANNI::SHAPEFILES{down_sampling}{area_avg_time_series}' ]; then
          echo 4.5
        else
          echo -1
        fi
        """)
        
        config_value = self.config_env.getAATSDownSamplingFactor()
        self.assertEqual(config_value, 4.5)

    def test_getTAMDownSamplingFactor(self):
        self._write_giovanni_config_pl("""#!/bin/bash
        
        if [ $1 == '$GIOVANNI::SHAPEFILES{down_sampling}{time_avg_map}' ]; then
          echo 4.5
        else
          echo -1
        fi
        """)
        
        config_value = self.config_env.getTAMDownSamplingFactor()
        self.assertEqual(config_value, 4.5)


if __name__ == '__main__':
    unittest.main()
