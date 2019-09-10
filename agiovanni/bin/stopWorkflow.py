#!/bin/env python

"""
Driver scripts to stop the workflow tasks in the queue

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import sys
import os
import argparse
import json 
from celery import signature
from celery import Celery

from agiovanni.queueUtilities import stop_workflow
from agiovanni.celeryGiovanni import app

if __name__ == "__main__":
    """
    Driver scripts to stop the workflow task in the queue

    Exit code:
    0: everything is ok
    1: exceptions
    """

    # parse input parameters
    parser = argparse.ArgumentParser(description="Stop workflow tasks in the queue")
    parser.add_argument("-w", "--WORKFLOW_FILE", type=str, help="workflow status file")
    args = parser.parse_args()

    # if the workflow task status file already exists
    workflowStateFile = args.WORKFLOW_FILE
    if os.path.isfile(workflowStateFile):
        # stop the workflow tasks from the existing workflow task status file
        try:
            stop_workflow(app, workflowStateFile)
        except:
            sys.exit(1)
