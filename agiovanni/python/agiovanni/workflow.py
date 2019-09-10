#!/bin/env python

"""
Module for giovanni workflow submission to the queue

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import os
import sys
from datetime import datetime
import shlex
from subprocess import Popen, PIPE, STDOUT
import signal
from inspect import currentframe, getframeinfo
import logging
import agiovanni.cfg
import agiovanni.prov
from celery.exceptions import SoftTimeLimitExceeded

from agiovanni.celeryGiovanni import app
from agiovanni.queueUtilities import update_queue_stats, queue_signal_handler, kill_children_processes, \
    get_task_lock


def run_workflow(cmd, env, workflowLogFile):
    '''
    run the workflow command
    and record the stdout/stderr at real time
    '''
    # set umask and open the log file
    old_umask = os.umask(0002)
    fo = open(workflowLogFile, 'a')

    # write header
    datetime_now = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S,%f')[:-3]
    fo.write(
        datetime_now +
        ' - [INFO ] - workflow - Running command: "%s" under environment "%s"\n' %
        (cmd,
         env))  # hacked log format for consistency

    # run command and capture output
    proc = Popen(shlex.split(cmd), env=env, stdout=PIPE, stderr=STDOUT)
    while proc.poll() is None:
        output = proc.stdout.readline()
        if not output:
            continue
        fo.write(output)
        fo.flush()

    # close the log file and reset umask
    fo.close()
    os.umask(old_umask)

    # return code
    return proc.returncode


@app.task(bind=True)
def workflow(self, cfgFile, workFlowConfigFile, giovanniService,
             outputDir, workflowStatusFile, envJSON={}):
    """
    The workflow task

    referring to Giovanni::Util::getDataFilesFromManifest

    @type cfgFile: string
    @param cfgFile: giovanni.cfg file
    @type workFlowConfigFile: string
    @param workFlowConfigFile: workflow.cfg file
    @type giovanniService: string
    @param giovanniService: giovanni service type
    @type outputDir: string
    @param outputDir: output directory  (required by Workflow.pm)
    @type workflowStatusFile: string
    @param workflowStatusFile: Workflow status file : 0 for failed, non-0 for success
    @type envJSON: dict
    @param envJSON: user-provided environment variables in json format

    @return: None if success.
    """
    # set signal handler
    signal.signal(signal.SIGTERM, queue_signal_handler)
    signal.signal(signal.SIGINT, queue_signal_handler)
    signal.signal(signal.SIGQUIT, queue_signal_handler)

    # Call method write_workflow queue_time which calculates the
    # workflow queue wait time and writes that time to a provenance file.
    # Note: We need the current system time before we call this method
    curr_time = datetime.now()
    agiovanni.prov.write_workflow_queue_time(curr_time, outputDir)

    try:
        # setup logger
        loggerName = 'Workflow (celery task id: %s)'%(self.request.id)
        logger = logging.getLogger(loggerName)
        sessionLogFile = os.path.join(outputDir,'session.log')
        fh = logging.FileHandler(sessionLogFile)
        formatter = logging.Formatter('%(asctime)s - [%(levelname)s ] - %(name)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
        fh.setFormatter(formatter)
        fh.setLevel(logging.INFO)
        logger.addHandler(fh)
        logger.propagate = False
        logger.info("Started.")

        # remove task for queue stats file
        queue = self.request.hostname.split('@')[0]
        workDir = os.path.abspath(os.path.join(outputDir, '..', '..', '..'))
        try:
            update_queue_stats(
                app, queue, workDir, outTasks={
                    self.request.id: None})
        except:
            frameinfo = getframeinfo(currentframe())
            error = sys.exc_info()
            sys.stderr.write(
                "Task %s[%s] error captured: %s %s -- %s\n" %
                (self.request.task,
                 self.request.id,
                 frameinfo.filename,
                 frameinfo.lineno,
                 str(error)))
            queueStatsFile = os.path.join(workDir, '%s.json' % queue)
            if os.path.isfile(queueStatsFile) and os.access(
                    queueStatsFile, os.W_OK):
                os.remove(queueStatsFile)

        # See if we really need to run this task, or if it is already running.
        if not get_task_lock(self.request.id, outputDir, "workflow"):
            # The task has already started, so there is no need to launch the
            # workflow again
            return {'state': 'ALREADYRUNNING'}

        # get the perl module directory and bin directory
        # and put them to the environment dictionary that will be passed to the
        # workflow
        os.environ['PATH'] = os.path.dirname(
            cfgFile) + '/../bin/:' + os.environ['PATH']
        config_env = agiovanni.cfg.ConfigEnvironment()
        bin_dir = config_env.get("$GIOVANNI::ENV{PATH}")
        perl_module_dir = config_env.get("$GIOVANNI::ENV{PERL5LIB}")
        env = {'PATH': bin_dir, "PERL5LIB": perl_module_dir}

        # update the environment dictionary based on the user-provided environment dictionary in JSON format
        # NOTE: the user-provided environment variables will overwrite the env
        # dictionary for existing keys
        if envJSON:
            env.update(envJSON)

        # convert no-string env values to string so that Popen won't complaint
        env = dict([k, str(v)] for k, v in env.iteritems())

        # run the workflow
        # and record the stdout/stderr at real time
        workflowLogFile = os.path.join(outputDir, "workflow.log")
        cmd = "workflow.pl "\
              + " -c " + cfgFile\
              + " -f " + workFlowConfigFile\
              + " -s " + giovanniService \
              + " -d " + outputDir\
              + " -w " + workflowStatusFile
        status_code = run_workflow(cmd, env, workflowLogFile)
        logger.info("Succeeded." if status_code==0
                    else "Failed (status code: %s)"%status_code if status_code>0
                    else "Terminated by signal %s"%(-status_code))

        # close file handler for session.log
        fh.close()

        # if workflow failed
        if status_code:
            # raise an run-time exception
            # this will be caught and reported by celery worker
            raise RuntimeError

    # catch soft timeout exception
    except SoftTimeLimitExceeded:

        # logging
        logger.info("Celery worker time out.")

        # kill children processes
        pid = os.getpid()
        kill_children_processes(pid)

        # send SIGTERM again to kill zombies (possible due to celery bug)
        os.kill(pid, signal.SIGTERM)

        # return internal state
        return {'state': 'TIMEOUT'}
