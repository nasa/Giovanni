'''
  test a read-only run of ScrubbingFramework class on AIRX3STM_006_TotH2OVap_A
'''

__author__ = 'Richard Strub <richard.f.strub@nasa.gov>'

import unittest
import os
import subprocess

import agiovanni.bbox as bb
from agiovanni import ScrubbingFramework


def createMyExe():
    '''
    In this case ncdump. Notice how we need to create myncdump to accomodate the arguments
    that are automatically passed to the script
    '''
    exe_file = os.path.join(os.environ['TMPDIR'], 'myncdump.csh')
    exe_fh = open(exe_file, 'w')
    exe_fh.write("""#!/bin/csh
        set file = $4
        ncdump -h $file | grep  lat_bnds
        """ )
    exe_fh.close()
    os.chmod(exe_file, 0o775)
    return exe_file


def runcmd(cmd):

    scmd = cmd.split(' ')
    p = subprocess.Popen(scmd, stdout=subprocess.PIPE)
    out = p.communicate()[0]
    return p.returncode


class Test(unittest.TestCase):

    def testNcDump(self):
        variable = 'AIRX3STM_006_Temperature_D'
        variable = 'AIRX3STM_006_TotH2OVap_A'
        nthreads = 10
        readonly = 1
        total = 3
        skip = None
        exe_file = createMyExe()

        this = ScrubbingFramework.ScrubbingFramework(
            variable, exe_file, nthreads, total, skip, readonly)

        this.run()

        log = os.path.join(os.environ['TMPDIR'],
                           'myncdump' + '_' + variable + '.log')

        myGrepCmd = 'grep lat_bnds ' + log
        status = runcmd(myGrepCmd)
        self.assertEqual(status, 0, "Found lat_bnds")

        this.cleanup()
        os.remove(exe_file)
        os.remove(log)


if __name__ == "__main__":
    unittest.main()
