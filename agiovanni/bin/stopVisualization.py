#!/bin/env python

"""
Driver scripts to stop the visualization mangager/tasks

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import sys
import os
import argparse
import json 
from celery import signature
from celery import Celery

from agiovanni.queueUtilities import stop_visualization
from agiovanni.celeryGiovanni import app

if __name__ == "__main__":
    """
    Driver scripts to stop the visualization mangager/tasks

    Exit code:
    0: everything is ok
    1: exceptions
    """

    # parse input parameters
    parser = argparse.ArgumentParser(description="Stop visualization manager/tasks in the queue")
    parser.add_argument("-v", "--VIS_FILE", type=str, help="visualization status file")
    args = parser.parse_args()

    # if the visualizeFile (which save the visualization task history/status) already exists
    visualizeFile = args.VIS_FILE
    if os.path.isfile(visualizeFile):
        # stop the visualization tasks from the existing visualizeFile
        try:
            stop_visualization(app, visualizeFile)
        except:
            sys.exit(1)
