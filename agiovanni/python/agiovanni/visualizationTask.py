#!/bin/env python

"""
Visualization task module for celery queue submission

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import os
import xml.etree.ElementTree as ET
from datetime import datetime
import shlex
from subprocess import Popen, PIPE, STDOUT
import signal
import logging
from celery.exceptions import SoftTimeLimitExceeded
import agiovanni.cfg

from agiovanni.celeryGiovanni import app
from agiovanni.queueUtilities import queue_signal_handler, get_task_lock, kill_children_processes


def generate_dataFileList(sessionDir, manifestFileName):
    '''
    generate the flattened string for data file list
    NOTE '*' hard-coded for the linker by assuming this character never appears in a file name
    '''
    # parse the manifest file
    manifestFile = os.path.join(sessionDir, manifestFileName)
    tree = ET.parse(manifestFile)

    # get the data file list
    dataFileList = []
    root = tree.getroot()
    for node in  root.findall('fileList/file'):
        dataFileList.append(node.text)

    # return
    return '*'.join(dataFileList)

def run_visualize(cmd, env, plotLogFile):
    '''
    run the visualization command
    and record the stdout/stderr at real time
    '''
    old_umask = os.umask(0002)
    fo = open(plotLogFile,'a')
    datetime_now = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S,%f')[:-3]
    fo.write(datetime_now+' - [INFO ] - visualize - Running command: "%s" under environment "%s"\n'%(cmd,env)) # hacked log format for consistency
    proc = Popen(shlex.split(cmd), env=env, stdout=PIPE, stderr=STDOUT)
    while proc.poll() is None:
        datetime_now = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S,%f')[:-3]
        output = proc.stdout.readline()
        if not output:
            continue
        fo.write(datetime_now+" - [INFO ] - visualize - "+output)
    fo.close()
    os.umask(old_umask)

    # return code
    return proc.returncode

@app.task(bind=True)
def visualizationTask(self, cfgFile, sessionDir, manifestFileName, plotManifestFileName, plotType, outputDir, options=None, envJSON={}):
    """
    The visualization task

    referring to Giovanni::Util::getDataFilesFromManifest

    @type cfgFile: string
    @param cfgFile: giovanni.cfg file
    @type sessionDir: string
    @param sessionDir: session directory for target list and manifest files
    @type manifestFileName: string
    @param manifestFileName: manifest file name
    @type plotManifestFileName: string
    @param plotManifestFileName: plotManifest file name
    @type plotType: string
    @param plotType: plot type (required by Visualizer.pm)
    @type outputDir: string
    @param outputDir: output directory  (required by Visualizer.pm)
    @type options: string
    @param options: options (required by Visualizer.pm)
    @type envJSON: dict
    @param envJSON: user-provided environment variables in json format

    @return: {'state': internal_state, 'result': (plotManifestFileName , content(plotManifestFile))}
    """
    # set signal handler
    signal.signal(signal.SIGTERM, queue_signal_handler)
    signal.signal(signal.SIGINT, queue_signal_handler)
    signal.signal(signal.SIGQUIT, queue_signal_handler)
    
    try:
        # setup logger
        loggerName = 'Visualization task (celery task id: %s)'%(self.request.id)
        logger = logging.getLogger(loggerName)
        sessionLogFile = os.path.join(outputDir,'session.log')
        fh = logging.FileHandler(sessionLogFile)
        formatter = logging.Formatter('%(asctime)s - [%(levelname)s ] - %(name)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
        fh.setFormatter(formatter)
        fh.setLevel(logging.INFO)
        logger.addHandler(fh)
        logger.propagate = False
        logger.info("Started.")

        # See if we really need to run this task, or if it is already running.
        if not get_task_lock(self.request.id, outputDir, "visualizationTask"):
            # The task has already started, so there is no need to launch the
            # workflow again
            return {'state': 'ALREADYRUNNING'}

        # generate the flattened string for data file list
        dataFileListFlattened = generate_dataFileList(sessionDir, manifestFileName)

        # get the perl module directory and bin directory
        # and put them to the environment dictionary that will be passed to the visualizer
        os.environ['PATH'] = os.path.dirname(cfgFile)+'/../bin/:'+os.environ['PATH']
        config_env = agiovanni.cfg.ConfigEnvironment()
        bin_dir = config_env.get("$GIOVANNI::ENV{PATH}")
        perl_module_dir = config_env.get("$GIOVANNI::ENV{PERL5LIB}");
        env={'PATH': bin_dir, "PERL5LIB": perl_module_dir}

        # update the environment dictionary based on the user-provided environment dictionary in JSON format
        # NOTE: the user-provided environment variables will overwrite the env dictionary for existing keys
        if envJSON:
            env.update(envJSON)

        # convert no-string env values to string so that Popen won't complaint
        env = dict([k,str(v)] for k,v in env.iteritems())

        # run the visualization command
        # and record the stdout/stderr at real time
        cmd = "visualize.pl "\
              + " -c "+cfgFile\
              + " -m "+plotManifestFileName\
              + " -f "+dataFileListFlattened\
              + " -t "+plotType\
              + " -d "+outputDir
        if options:
            cmd += " -o '"+options+"'"; 
        plotLogFile = os.path.join(outputDir, plotManifestFileName[:-4]+".log")
        status_code = run_visualize(cmd, env, plotLogFile)
        logger.info("Succeeded." if status_code==0
                    else "Failed (status code: %s)"%status_code if status_code>0
                    else "Terminated by signal %s"%(-status_code))

        # close file handler for session.log
        fh.close()

        # return internal state and (plotManifestFileName , content(plotManifestFile))
        plotManifestFile = os.path.join(outputDir, plotManifestFileName)
        content_plotManifestFile = open(plotManifestFile).read()
        return {'state': 'SUCCESS', 'result': (plotManifestFileName, content_plotManifestFile)}

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
