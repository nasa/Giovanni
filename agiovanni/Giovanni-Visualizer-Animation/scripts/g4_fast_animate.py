#!/bin/env python
"""Concatenate multiple PNGs to form an animated GIF.

Run with --help for usage information.
"""
from __future__ import division

import math
import multiprocessing
import optparse
import os
import shutil
import subprocess
import sys
import tempfile

__author__ = "Daniel da Silva <Daniel.e.daSilva@nasa.gov>"

GROUP_SIZE =   8       # max number of frames to join at a time
POOL_SIZE  =   8       # max number of child processes to run at a time


def merge(args):
    groupFiles, delay, tempDir = args    
    outputFile = os.path.join(tempDir, '%d.gif' % hash(''.join(groupFiles)))

    argv = ['convert', '-delay', str(delay), '-loop', '0', '-dispose', 'Previous']
    argv.extend(groupFiles)
    argv.append(outputFile)
    subprocess.check_call(argv)
    
    return outputFile
    

def main(argv):
    delay, frameFiles, outputFile = parse_args(argv)
    
    tempDir = tempfile.mkdtemp()
    pool = multiprocessing.Pool(POOL_SIZE)
    levelInputs = None
    levelOutputs = frameFiles
    
    while len(levelOutputs) > 1:
        levelInputs = levelOutputs
        levelOutputs = []
        # Group the frames on this level into groups. Each group will be GROUP_SIZE
        # frames long, except for possibly the last.
        numGroups = int(math.ceil(len(levelInputs)/GROUP_SIZE))
        groups = []

        for j in range(numGroups):
            start = GROUP_SIZE * j
            end   = GROUP_SIZE * (j + 1)
            groups.append(levelInputs[start:end])

        # Convert groups into arguments that can be passed to merge function calls.
        args = []

        for groupFiles in groups:
            args.append((groupFiles, delay, tempDir))
        
        # Use the processing pool to merge each group into a smaller set of frames
        # for the next level.
        sys.stderr.write('Processing new level (%d joins)\n' % len(groups))
        sys.stderr.flush()

        levelOutputs.extend(pool.map(merge, args))

    assert len(levelOutputs) == 1    
    shutil.copyfile(levelOutputs[0], outputFile)
    shutil.rmtree(tempDir)
    
    
def parse_args(argv):
    usage = "%prog [--delay DELAY] PNG [PNG [...]] GIF"
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('--delay', dest='delay', default=20, type=int,
                      help='Pause time between frames (hundredths of a second)')
    opts, args = parser.parse_args()

    if len(args) < 2:
        parser.print_help()
        sys.exit(1)
        
    return opts.delay, args[:-1], args[-1]


if __name__ == '__main__':
    main(sys.argv)
