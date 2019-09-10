#!/bin/env python

"""
Driver script to check the celery queue status

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import sys
import os
import argparse
from agiovanni.queueUtilities import check_queue_status
from agiovanni.celeryGiovanni import app

if __name__ == "__main__":
    """
    Driver script to check the celery queue status

    Exit code:
    0: queue available
    1: queue unavailable
    2: unknown exceptions
    """
    # parse input parameters
    parser = argparse.ArgumentParser(description="Check celery queue status")
    parser.add_argument("-v", "--verbose", action='store_true')
    args = parser.parse_args()
    verbose = args.verbose

    try:
        # check the queue status from the celeryconfig file
        status_ok = check_queue_status(app, all_hosts=False)

        # exit code 1 if queues were not found active
        if not status_ok:
            if verbose:
                sys.stderr.write("Queues are not available.\n")
            os._exit(1)

    # exit code 1 if an exception was rasied
    except:
        if verbose:
            sys.stderr.write("There is an unknown error while checking queue status.\n")
        os._exit(2)
