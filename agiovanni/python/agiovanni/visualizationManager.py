"""
Visualization manager module for celery queue submission

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""
import os
import sys
import re
import time
import signal
from inspect import currentframe, getframeinfo
import logging
from celery import signature
from celery.exceptions import SoftTimeLimitExceeded

from agiovanni.celeryGiovanni import app
from agiovanni.queueUtilities import update_queue_stats, get_task_lock, kill_children_processes

def get_lookFor(lookForPriorityList, manifestFileNameList):
    '''
    get lookFor (refering to Result::gatherData)
    Prefer mfst.combine if it exists
    otherwise, mfst.postprocess if it exists
    otherwise, mfst.result
    '''
    for lkfr in lookForPriorityList:
        found = False
        for manifestFileName in manifestFileNameList:
            if re.compile(r"^%s.*"%lkfr).match(manifestFileName):
                lookFor = lkfr
                found = True
                break
        if found:
            break
    if not found:
        lookFor = lookForPriorityList[-1] # NOTE this is consistent with gatherData, but is this correct? How is error handled in giovanni?

    return lookFor

def get_task_priority(plotType):
    '''
    get task priority
    currently hardcoded since we don't have a priority list yet
    '''
    return 9


@app.task(bind=True)
def visualizationManager(self, giovanniCfgFile, workflowStatusFile, workflowQueueStateFile, sessionDir, targetListFileName, plotType, outputDir, options=None, sync=None, workflowQueryInterval=0.5, envJSON={}):
    """
    The visualization manager 

    referring to Result::gatherData
    
    @type giovanniCfgFile: string
    @param giovanniCfgFile: giovanni.cfg file
    @type workflowStatusFile: string
    @param workflowStatusFile: workflow status file (according to current implementation as of 9/24/2016, 0 for failed, non-0 for success)
    @type workflowQueueStateFile: string
    @param workflowQueueStateFile: file to save the workflow task status in the queue
    @type sessionDir: string
    @param sessionDir: session directory for target list and manifest files
    @type targetListFileName: string
    @param targetListFileName: targetList file name without path
    @type plotType: string
    @param plotType: plot type (required by Visualizer.pm)
    @type outputDir: string
    @param outputDir: output directory  (required by Visualizer.pm)
    @type options: string
    @param options: options (required by Visualizer.pm)
    @type sync: string
    @param sync: synchronous flag: None for asynchronous run
    @type envJSON: dict
    @param envJSON: user-provided environment variables in json format

    @return: the submitted visualization task information, including task id and menifest file name
    @rtype: dictionary
    """

    try:
        # setup logger
        loggerName = 'VisualizationManager (celery task id: %s)'%(self.request.id)
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
            update_queue_stats(app, queue, workDir, outTasks={self.request.id: None} )
        except:
            frameinfo = getframeinfo(currentframe())
            error = sys.exc_info()
            sys.stderr.write("Task %s[%s] error captured: %s %s -- %s\n"%(self.request.task, self.request.id, frameinfo.filename, frameinfo.lineno, str(error)))
            queueStatsFile = os.path.join(workDir, '%s.json'%queue)
            if os.path.isfile(queueStatsFile) and os.access(queueStatsFile, os.W_OK):
                os.remove(queueStatsFile)

        # See if we really need to run this task, or if it is already running.
        if not get_task_lock(self.request.id, outputDir, "visualizationManager"):
            # The task has already started, so there is no need to launch the
            # workflow again
            return {'state': 'ALREADYRUNNING'}

        # preparation
        dataList = []
        lookForPriorityList = ['mfst.combine', 'mfst.postprocess', 'mfst.result']
        targetListFile = os.path.join(sessionDir, targetListFileName)
        submittedVisualizationFiles = []
        submittedVisualizationTaskIds = []
        priority = get_task_priority(plotType)
        taskInfo = {}
        pattern_workflowTask = re.compile(r"Workflow task \(id: ([^\s]+)\) status: ([A-Z]+)\n")

        # periodically check for the target list and manifest file
        while True:

            # if workflowQueueStateFile has not been generated yet
            if not os.path.isfile(workflowQueueStateFile):
                # raise an exception because this should never happend
                raise RuntimeError

            # break if the workflow failed or had been revoked in the queue
            tstate = None
            for line in open(workflowQueueStateFile).readlines():
                if pattern_workflowTask.match(line):
                    (tid, tstate) = pattern_workflowTask.match(line).groups()
                    break
            if tstate in ['FAILURE', 'REVOKED', 'TIMEOUT']:
                break

            # break if workflow failed
            if os.path.isfile(workflowStatusFile) and not int(open(workflowStatusFile).read()):
                break

            # if target list file exist
            if os.path.isfile(targetListFile):

                # open the target list file
                with open(targetListFile) as fin:

                    # get the manifest file list from the target list file
                    lines = fin.readlines()
                    manifestFileNameList = [line.strip() for line in lines]

                    # get lookFor
                    lookFor = get_lookFor(lookForPriorityList, manifestFileNameList)

                    # get the manifest file set that the visualization task is looking for
                    matcher = re.compile(r"^%s.*"%lookFor)
                    manifestFileLookforSet = set([os.path.join(sessionDir, fileName) for fileName in manifestFileNameList if matcher.match(fileName)])

                    # loop over the manifest files for the visualization task
                    for manifestFile in manifestFileLookforSet:
                        
                            # if this manifestFile has been generately by the workflow
                            if os.path.isfile(manifestFile):

                                # check whether this manifestFile has been submitted for visualization or not
                                # and go to next one if it was already been submitted for visualization before
                                if manifestFile in submittedVisualizationFiles:
                                    continue

                                # push visualization task to the visualization tasks queue
                                manifestFileName = os.path.basename(manifestFile)
                                plotManifestFileName = manifestFileName.replace(lookFor, 'mfst.plot', 1)
                                if not sync:
                                    celerySignature= signature('agiovanni.visualizationTask.visualizationTask', args = [giovanniCfgFile, sessionDir, manifestFileName, plotManifestFileName, plotType, outputDir, options, envJSON])
                                    result_visualizationTask = celerySignature.apply_async(priority=priority)
                                else:
                                    from agiovanni import visualizationTask
                                    result_visualizationTask = visualizationTask.visualizationTask.apply(args=[giovanniCfgFile, sessionDir, manifestFileName, plotManifestFileName, plotType, outputDir, options, envJSON])

                                # record the submitted visualize task information right after submitting it (even asynchronously)
                                submittedVisualizationFiles.append(manifestFile)
                                submittedVisualizationTaskIds.append(result_visualizationTask.id)
                                taskInfo[result_visualizationTask.id] = plotManifestFileName
                                self.update_state(state='PROGRESS', meta=taskInfo)

                            # go to next manifest file if this one has not been generated by the workflow yet
                            else:
                                continue

                    # check whether all the manifest files has been submitted for visualization; quit the loop if yes
                    if set(submittedVisualizationFiles) == manifestFileLookforSet:
                        break

                # sleep for a time of workflowQueryInterval after reading the target list file
                time.sleep(workflowQueryInterval)

            # sleep for a time of workflowQueryInterval if targetListFile is not generated yet
            else:
                time.sleep(workflowQueryInterval)

        # return the submitted visualization task information
        logger.info("Finished.")

        # close file handler for session.log
        fh.close()

        return taskInfo

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
