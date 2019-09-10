#!/bin/env python

"""
Driver script to update the workflow status

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import sys
import argparse
from agiovanni.queueUtilities import update_workflow
from agiovanni.celeryGiovanni import app


if __name__ == "__main__":
    """
    Driver script to update the workflow status

    Exit code:
    0: everything is ok
    1: exceptions
    """
    # parse input parameters
    parser = argparse.ArgumentParser(description="Update the workflow status")
    parser.add_argument("-w", "--WORKFLOW_FILE", type=str, help="workflow status file")
    args = parser.parse_args()
    workflowFile = args.WORKFLOW_FILE

    #Update the workflowFile
    try:
        update_workflow(app, workflowFile)
    except:
        sys.exit(1)
