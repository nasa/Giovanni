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
    parser.add_argument("-wc", "--WORKFLOW_CFGFILE", type=str, help="workflow cfg file")
    parser.add_argument("-srv", "--SERVICE", type=str, help="giovanni service type")
    parser.add_argument("-d", "--OUTPUT_DIR", type=str, help="output dir")
    parser.add_argument("-w", "--WORKFLOW_QUEUESTATEFILE", type=str, help="workflow history file name")
    parser.add_argument("-s", "--WORKFLOW_STATUSFILE", type=str, help="workflow status file name")
    parser.add_argument("-sync", "--SYNC", type=bool, default=False, help="synchronous options")
    parser.add_argument("-env", "--ENV", type=json.loads, help="user-provided environment variables in json format string")
    args = parser.parse_args()

    # local parameters
    giovanniCfgFile = args.GIOVANNI_CFGFILE
    workFlowConfigFile = args.WORKFLOW_CFGFILE
    giovanniService = args.SERVICE
    outputDir = args.OUTPUT_DIR
    workflowQueueStateFile = args.WORKFLOW_QUEUESTATEFILE
    workflowStatusFile = args.WORKFLOW_STATUSFILE
    giovanniEnv = args.ENV

    # if asynchronous running
    if not args.SYNC:
        # submit the visualization mananger to the queue
        celerySignature= signature('agiovanni.workflow.workflow', args = [giovanniCfgFile, workFlowConfigFile, giovanniService, outputDir, workflowStatusFile, giovanniEnv])
        result_workflow = celerySignature.apply_async()
        # update task in queue stats file
        workDir = os.path.abspath(os.path.join(outputDir, '..', '..', '..'))
        queue = app.conf['CELERY_ROUTES']['agiovanni.workflow.workflow']['queue']
        try:
            current_time = datetime.utcnow()
            inTask = { result_workflow.id: {'CREATION_TIME': current_time.isoformat(), 'SESSION_DIR': outputDir} }
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
        from agiovanni import workflow
        result_workflow = workflow.workflow.apply(args = [giovanniCfgFile, workFlowConfigFile, giovanniService, outputDir, workflowStatusFile, giovanniEnv])


    # save visualization manager id to the workflowQueueStateFile
    task_id = result_workflow.id
    status = result_workflow.status
    open(workflowQueueStateFile, 'w').write("Workflow task (id: %s) status: %s\nUpdate times: 0\n"%(task_id,status))
