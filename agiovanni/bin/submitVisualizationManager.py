#!/bin/env python

"""
Driver scripts for visualization mangager

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import sys
import os
import argparse
import json 
from datetime import datetime
from inspect import currentframe, getframeinfo
from celery import signature
from celery import Celery

from agiovanni.queueUtilities import stop_visualization, cleanUp_for_plotOptions, update_queue_stats
from agiovanni.celeryGiovanni import app

if __name__ == "__main__":
    """
    driver scripts for visualization mangager

    this script does not catch any exception in general
    """

    # parse input parameters
    parser = argparse.ArgumentParser(description="Submit visualization manager for a session")
    parser.add_argument("-c", "--GIOVANNI_CFGFILE", type=str, help="giovanni cfg file")
    parser.add_argument("-ws", "--WORKFLOW_STATUSFILE", type=str, help="workflow status file name")
    parser.add_argument("-wq", "--WORKFLOW_QUEUESTATEFILE", type=str, help="workflow queue state file name")
    parser.add_argument("-s", "--SESSION_DIR", type=str, help="sesssion directory")
    parser.add_argument("-f", "--TARGETS_FILENAME", type=str, help="target file name")
    parser.add_argument("-v", "--VIS_FILENAME", type=str, help="visualization status file name")
    parser.add_argument("-t", "--PLOT_TYPE", type=str, help="plot type")
    parser.add_argument("-d", "--OUTPUT_DIR", type=str, help="output dir")
    parser.add_argument("-o", "--OPTIONS", type=str, help="options")
    parser.add_argument("-sync", "--SYNC", type=bool, default=False, help="synchronous options")
    parser.add_argument("-tv", "--TASKQUERY_INTERVAL", type=float, default=0.5, help="time interval to query workflow output")
    parser.add_argument("-env", "--ENV", type=json.loads, help="user-provided environment variables in json format string")
    args = parser.parse_args()

    # if the visualizerFile (which save the visualization task history/status) already exists
    visualizerFile = os.path.join(args.OUTPUT_DIR, args.VIS_FILENAME)
    if os.path.isfile(visualizerFile):
        # stop the visualization tasks from the existing visualizerFile
        if args.OPTIONS:
            stop_visualization(app, visualizerFile, True)
            # and clean up the previous visualization results if plot option change is requested from UI
            cleanUp_for_plotOptions(args.OUTPUT_DIR, args.OPTIONS)
        else:
            stop_visualization(app, visualizerFile)

    # if asynchronous running
    if not args.SYNC:
        # submit the visualization mananger to the queue
        celerySignature= signature('agiovanni.visualizationManager.visualizationManager', args = [args.GIOVANNI_CFGFILE, args.WORKFLOW_STATUSFILE, args.WORKFLOW_QUEUESTATEFILE, args.SESSION_DIR, args.TARGETS_FILENAME, args.PLOT_TYPE, args.OUTPUT_DIR, args.OPTIONS, args.SYNC, args.TASKQUERY_INTERVAL, args.ENV])
        result_visualizationManager = celerySignature.apply_async()
        # update task in queue stats file
        workDir = os.path.abspath(os.path.join(args.OUTPUT_DIR, '..', '..', '..'))
        queue = app.conf['CELERY_ROUTES']['agiovanni.visualizationManager.visualizationManager']['queue']
        try:
            current_time = datetime.utcnow()
            inTask = { result_visualizationManager.id: {'CREATION_TIME': current_time.isoformat(), 'SESSION_DIR': args.OUTPUT_DIR} }
            update_queue_stats(app, queue, workDir, inTasks=inTask, houseKeeping=True)
        except:
            frameinfo = getframeinfo(currentframe())
            error = sys.exc_info()
            sys.stderr.write("%s %s: %s\n"%(frameinfo.filename, frameinfo.lineno, str(error)))
            queueStatsFile = os.path.join(workDir, '%s.json'%queue)
            if os.path.isfile(queueStatsFile) and os.access(queueStatsFile, os.W_OK):
                os.remove(queueStatsFile)
    # if synchronous running
    else:
        # run the task synchronously
        from agiovanni import visualizationManager
        result_visualizationManager = visualizationManager.visualizationManager.apply(args=[args.GIOVANNI_CFGFILE, args.WORKFLOW_STATUSFILE, args.WORKFLOW_QUEUESTATEFILE, args.SESSION_DIR, args.TARGETS_FILENAME, args.PLOT_TYPE, args.OUTPUT_DIR, args.OPTIONS, args.SYNC, args.TASKQUERY_INTERVAL, args.ENV])


    # save visualization manager id to the visualizerFile
    task_id = result_visualizationManager.id
    status = result_visualizationManager.status
    if args.OPTIONS:
        open(visualizerFile, 'w').write("Visualization manager (id: %s, options: %s) status: %s\nUpdate times: 0\n"%(task_id, args.OPTIONS, status))
    else:
        open(visualizerFile, 'w').write("Visualization manager (id: "+task_id+", options: None) status: "+status+"\nUpdate times: 0\n")
