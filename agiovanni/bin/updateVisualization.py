#!/bin/env python

"""
Driver script to update the visualization status and plot menifest file when a visualization task is done

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import sys
import argparse
from agiovanni.queueUtilities import update_visualization
from agiovanni.celeryGiovanni import app


if __name__ == "__main__":
    """
    Driver script to update the visualization status and plot menifest file when a visualization task is done

    Exit code:
    0: everything is ok
    1: exceptions
    """
    # parse input parameters
    parser = argparse.ArgumentParser(description="Update the visualization status and plot menifest file when a visualization task is done")
    parser.add_argument("-v", "--VIS_FILE", type=str, help="visualization status file")
    args = parser.parse_args()
    visualizeFile = args.VIS_FILE

    #Update the visualizeFile and the plot menifestfile when a visualization task is done
    try:
        update_visualization(app, visualizeFile)
    except:
        sys.exit(1)
