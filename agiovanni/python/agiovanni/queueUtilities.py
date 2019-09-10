#!/bin/env python

"""
Celery utilities

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import sys
import re
import os
import glob
import shlex
import signal
import time
import redis
import socket
from urlparse import urlparse
import dateutil.parser
import json
import collections
from celery.task.control import inspect, revoke
from celery.result import AsyncResult
from subprocess import Popen, PIPE, STDOUT
from datetime import datetime
import fcntl, errno
import psutil
import locale


class LockError(IOError):
    """
    Exception associated with trying to lock a file.
    """
    pass

def kill_children_processes(pid):
    """
    recursively kill all the children processes
    NOTE: error should be handled by the caller

    @type pid: int
    @param pid: process id whose children need to be killed

    @return: None
    """
    parent = psutil.Process(pid)
    for child in parent.children(recursive=True):
        child.kill()

def queue_signal_handler(signum, frame):
    """
    queue signal handler
    NOTE: error should be handled by the caller

    @type signum: int
    @param signum: signal number
    @type frame: object
    @param frame: stack frame where interruption was caught

    @return: None
    """
    parent_pid = os.getpid()
    kill_children_processes(parent_pid)


def lock_file(fin, max_tries=100, retry_interval=0.5):
    """
    lock a opened file
    NOTE: error should be handled by the caller

    @type fin: file object
    @param fin: opened file object
    @type max_tries: int
    @param max_tries: maximum number of times to try getting the lock.
    Defaults to 100
    @type retry_interval: double
    @param retry_interval: seconds to wait between trying to get the lock.
    Defaults to 0.5

    @return: None
    """
    count = 0
    while True:
        try:
            fcntl.lockf(fin, fcntl.LOCK_EX | fcntl.LOCK_NB)
            break
        except IOError as e:
            if e.errno != errno.EAGAIN:
                raise LockError('Failed to lock file: %' % fin)
            else:
                time.sleep(retry_interval)
        count += 1
        if count > max_tries:
            raise LockError(35, 'Tried too many times to lock file: %s' % fin)


def unlock_file(fin):
    """
    unlock an opened file

    @type file object
    @param fin: opened file object
    @return: None
    """
    fcntl.lockf(fin, fcntl.LOCK_UN)


def update_individual_queue_stats(queue, pendingTasks):
    """
    Update the queue stats for each individual session
    NOTE: error should be handled by the caller

    @type queue: string
    @type queue: name of the queue to be updated
    @type pendingTasks: dictionary
    @param pendingTasks: pending tasks -- { $(task_id):  {"CREATION_TIME: $(creation_time), "SESSION_DIR": $(session_dir)} }

    @return: None
    """

    # get UNIX epoch
    epoch = datetime.utcfromtimestamp(0)

    # sort pending tasks by creation time from earliest to latest
    sorted_pendingTasks = sorted( pendingTasks.items(), key=lambda v: dateutil.parser.parse(v[1]["CREATION_TIME"]) )

    # for each pending task (sorted by creation time from earliest to latest)
    num_pending_tasks = 0
    tot_time = (epoch-epoch)
    for (pending_task, pending_task_attrib) in sorted_pendingTasks:

        # get the pending task creation time
        creation_time = dateutil.parser.parse(pending_task_attrib['CREATION_TIME'])

        # update session queue stats file
        session_dir = pending_task_attrib['SESSION_DIR']
        queueStatsFile = os.path.join(session_dir, '%s.json'%queue)
        fin = open(queueStatsFile, 'w')
        lock_file(fin)
        if num_pending_tasks:
            stats = {'AVE_CREATION_TIME': ave_creation_time.isoformat(), 'NUM_PENDING_TASKS': num_pending_tasks}
        else:
            stats = {'AVE_CREATION_TIME': epoch.isoformat(), 'NUM_PENDING_TASKS': num_pending_tasks, 'CURRENT_CREATION_TIME': creation_time.isoformat()}
        json.dump(stats, fin, indent=4)
        unlock_file(fin)
        fin.close()

        # update the total time/number of pending tasks
        # and compute the average creation time so far
        num_pending_tasks += 1
        tot_time += (creation_time - epoch)
        ave_creation_time = (tot_time/num_pending_tasks) + epoch

def update_queue_stats(app, queue, workDir, inTasks={}, outTasks={}, houseKeeping=False):
    """
    Update the queue stats, which is saved in a json file that contains the following info:
        Current average creation time for pending tasks: <e.g. 2018-01-01T00:00:00>
        Total number of pending tasks in the queue: <e.g. 8>
        List of pending tasks and their creation time
    NOTE: error should be handled by the caller

    @type app: Celery application
    @param app: Celery application instance
    @type queue: string
    @type queue: name of the queue to be updated
    @type workDir: string
    @type workDir: directory where queue stats file is located
    @type inTasks: dictionary
    @param inTasks: tasks to be created -- { $(task_id):  {"CREATION_TIME: $(creation_time), "SESSION_DIR": $(session_dir)} } (celery client call)
    @type outTasks: dictionary
    @param outTasks: tasks to be removed -- { $(task_id): None } (celery worker call)
    @type houseKeeping: boolean
    @param houseKeeping: flag to remove non-pending tasks in queueStatsFile

    @return: None
    """

    # get the json file that saves the queue stats info
    #   assuming the json file name takes the form of {queue_name}.json
    queueStatsFile = os.path.join(workDir, '%s.json'%queue)

    # skip this method if queueStatsFile does not exist or is not writable
    #   when tasks are to be removed by celery worker
    if outTasks and not ( os.path.isfile(queueStatsFile) and os.access(queueStatsFile, os.W_OK) ):
        return

    # get UNIX epoch
    epoch = datetime.utcfromtimestamp(0)

    # open/lock queueStatsFile
    fin = open(queueStatsFile, 'a+')
    lock_file(fin)

    # get queue statistics
    fin.seek(0)
    if not os.stat(queueStatsFile).st_size:
        stats = {'AVE_CREATION_TIME': epoch.isoformat(), 'NUM_PENDING_TASKS': 0, 'TASKS': {}}
    else:
        stats = json.load(fin)
    ave_creation_time = dateutil.parser.parse(stats['AVE_CREATION_TIME'])
    num_pending_tasks = int(stats['NUM_PENDING_TASKS'])
    tot_time = (ave_creation_time-epoch)*num_pending_tasks
    tasks = stats['TASKS']

    # process incoming tasks
    for (task, task_attrib) in inTasks.iteritems():
        if AsyncResult(task).status == 'PENDING':
            creation_time = dateutil.parser.parse(task_attrib['CREATION_TIME'])
            creation_time_since_epoch = creation_time - epoch
            tot_time += creation_time_since_epoch
            tasks[task] = task_attrib
            num_pending_tasks += 1

    # process outgoing tasks
    for task in outTasks:
        if task in tasks:
            tot_time -= (dateutil.parser.parse(tasks[task]['CREATION_TIME']) - epoch)
            del tasks[task]
            num_pending_tasks -= 1

    # house keeping upon request
    #   it will clear the tasks in the stats file
    #   except for the queued tasks from redis-cli and reserved tasks from celery
    if houseKeeping:
        queueURL = app.conf[u'BROKER_URL']
        url = urlparse(queueURL)
        url_hostname = url.hostname
        port = url.port
        redis_client = redis.Redis(url_hostname, port=port)
        redis_queued = []
        for redis_task in redis_client.lrange(queue,0,-1):
            queue_info = json.loads(redis_task)
            redis_queued.append(queue_info[u'properties'][u'correlation_id'])
        celery_reserved = []
        celery_node = '%s@%s'%(queue,get_hostname(url_hostname))
        celery_tasks = inspect(destination=[celery_node]).reserved()[celery_node]
        for celery_task in celery_tasks:
            celery_reserved.append(celery_task['id'])
        for task in tasks.keys():
            if task not in celery_reserved + redis_queued:
                tot_time -= (dateutil.parser.parse(tasks[task]['CREATION_TIME']) - epoch)
                del tasks[task]
                num_pending_tasks -= 1

    # update queue statistics
    if num_pending_tasks:
        ave_creation_time = (tot_time/num_pending_tasks) + epoch
    else:
        ave_creation_time = epoch
    stats = {'AVE_CREATION_TIME': ave_creation_time.isoformat(), 'NUM_PENDING_TASKS': num_pending_tasks, 'TASKS': tasks}
        
    # update queueStatsFile
    fin.seek(0)
    fin.truncate()
    json.dump(stats, fin, indent=4)

    # unlock/close queueStatsFile
    unlock_file(fin)
    fin.close()

    # update the queue stats for each individual session
    update_individual_queue_stats(queue, pendingTasks=tasks)
    

def update_workflow(app, workflowStateFile):
    """
    Update the workflowStateFile
    NOTE: error should be handled by the caller

    @type app: Celery application
    @param app: Celery application instance
    @type workflowStateFile: string
    @param workflowStateFile: name of the workflowStatus file that stores the workflow task id's and its updated status
    """
    # return if workflowStateFile has been generated yet
    if not os.path.isfile(workflowStateFile):
        return

    # extract previously saved workflow status and update times information
    workflowTask_preState = {}
    updateTimes = None
    pattern_workflowTask = re.compile(r"Workflow task \(id: ([^\s]+)\) status: ([A-Z]+)\n")
    pattern_updateTimes = re.compile(r"Update times: ([0-9]+)\n")
    for line in open(workflowStateFile).readlines():
        if pattern_workflowTask.match(line):
            (tid, tstate) = pattern_workflowTask.match(line).groups()
            workflowTask_preState[tid] = (tstate)
        if pattern_updateTimes.match(line):
            updateTimes = pattern_updateTimes.match(line).groups()[0]
            updateTimes = locale.atoi(updateTimes)

    # if the workflowTask was not found
    if not workflowTask_preState or updateTimes is None:
        # raise an exception because this should never happend (submitWorkflow.py should write the file already)
        raise RuntimeError

    # clear the workflow status file
    open(workflowStateFile, 'w').close()
    fout = open(workflowStateFile, 'a')

    # for each workflow task
    for tid, (tstate) in workflowTask_preState.items():
        
        # collect workflow task async result
        workflowTask_asyncResult = AsyncResult(tid)

        # if the internal status from workflow task was returned
        workflowTask_result = workflowTask_asyncResult.result
        if isinstance(workflowTask_result, collections.Iterable) and 'state' in workflowTask_result:
            # get workflow internal task status
            workflowTask_state = workflowTask_result['state']

        # otherwise
        else:
            # get the workflow task status from celery
            workflowTask_state = workflowTask_asyncResult.state

        # save the workflow task status in workflowStatus file
        fout.write("Workflow task (id: %s) status: %s\n"%(tid, workflowTask_state))

    # save the update times information
    fout.write("Update times: %s\n"%(updateTimes+1))

    # close workflow state file
    fout.close()


def update_visualization(app, visualizerFile):
    """
    Update the visualizerFile
        and the plot menifest file when a visualization task is done
    NOTE: error should be handled by the caller

    @type app: Celery application
    @param app: Celery application instance
    @type visualizerFile: string
    @param visualizerFile: name of the visualizationStatus file that stores the visualization manager/task id's and its updated status
    """
    # return if visualizerFile has been generated yet
    if not os.path.isfile(visualizerFile):
        return

    # extract previously saved visualization status and update times information
    visualizationManager_preState = {}
    visualizationTask_preState = {}
    updateTimes = None
    pattern_visMgr = re.compile(r"Visualization manager \(id: ([^\s]+), options: (.+)\) status: ([A-Z]+)\n")
    pattern_visTsk = re.compile(r"Visualization task \(id: ([^\s]+), options: (.+), file: ([^\s]+)\) status: ([A-Z]+)\n")
    pattern_updateTimes = re.compile(r"Update times: ([0-9]+)\n")
    for line in open(visualizerFile).readlines():
        if pattern_visMgr.match(line):
            (mid, moptions, mstate) = pattern_visMgr.match(line).groups()
            visualizationManager_preState[mid] = (mstate, moptions)
        if pattern_visTsk.match(line):
            (tid, toptions, tfile, tstate) = pattern_visTsk.match(line).groups()
            visualizationTask_preState[tid] = (tstate, tfile)
        if pattern_updateTimes.match(line):
            updateTimes = pattern_updateTimes.match(line).groups()[0]
            updateTimes = locale.atoi(updateTimes)

    # if the visualizationManager was not found
    if not visualizationManager_preState or updateTimes is None:
        # raise an exception because this should never happend
        raise RuntimeError

    # clear the visualization status file
    open(visualizerFile, 'w').close()
    fout = open(visualizerFile, 'a')

    # for each visualization manager (with or without options)
    for mid, (mstate, moptions) in visualizationManager_preState.items():
        
        # get the visualizationManger state
        visMgr_asyncResult = AsyncResult(mid)
        visMgr_result = visMgr_asyncResult.result
        if isinstance(visMgr_result, collections.Iterable) and 'state' in visMgr_result:
            visMgr_state = visMgr_result['state']
        else:
            visMgr_state = visMgr_asyncResult.state

        # save the visualization manager status in visualizationStatus file
        fout.write("Visualization manager (id: %s, options: %s) status: %s\n"%(mid, moptions, visMgr_state))

        # if the visualization manager is pending, failed, or timeout
        #    or the visualization manager is an unkown status other than finishd or in progress
        if visMgr_state in ['PENDING', 'FAILURE', 'RETRY', 'REVOKED', 'TIMEOUT', 'ALREADYRUNNING'] or visMgr_state not in ['PROGRESS', 'SUCCESS']:
            # break, because there will be no further update for visualization status
            break

        # collect the current visualization task information
        visualizationTask_info = AsyncResult(mid).result

        # update the plot menifest files for the completed visualization tasks
        session_dir = os.path.dirname(visualizerFile)

        # loop over the submitted visualization tasks
        for (visualizationTask_id, plotManifestFileName) in visualizationTask_info.iteritems():

            # get the visualizationTask task state and internal result
            visTsk_state, visTsk_internal_result = None, None
            visTsk_asyncResult = AsyncResult(visualizationTask_id)
            visTsk_result = visTsk_asyncResult.result
            if isinstance(visTsk_result, collections.Iterable) and 'state' in visTsk_result:
                visTsk_state = visTsk_result['state']
                if 'result' in visTsk_result:
                    visTsk_internal_result = visTsk_result['result']
            else:
                visTsk_state = visTsk_asyncResult.state

            # if this visualization task was not previously submitted
            #    and it succeeded and returned internal result (plotManifestFileName, plotManifestFile_content)
            if visualizationTask_id not in visualizationTask_preState and visTsk_state == 'SUCCESS' and visTsk_internal_result:
                # save the plot menifest file
                (plotManifestFileName, plotManifestFile_content) = visTsk_internal_result
                plotManifestFile = os.path.join(session_dir, plotManifestFileName)
                if (not os.path.isfile(plotManifestFile)):
                    open(plotManifestFile, 'w').write(plotManifestFile_content)
            # save this visualization task status in visualizationStatus file
            fout.write("Visualization task (id: %s, options: %s, file: %s) status: %s\n"%(visualizationTask_id, moptions, plotManifestFileName, visTsk_state))

    # save the update times information
    fout.write("Update times: %s\n"%(updateTimes+1))

    # close visualization state file
    fout.close()


def cleanUp_for_plotOptions(sessionDir, options):
    """
    Clean up the session directory when plot option changes are requested
    Currently it only removes the plot manifest files based on the variable "name"s from "options"
    This is necessary for aysnchronous visualization
        because otherwise the subsequent service request may return the previous visualization results
    NOTE: error should be handled by the caller

    @type sessionDir: string
    @param sessionDir: session directory
    @type options: string
    @param options: plot options
    """
    # extract the variable names from the "options"
    names = re.compile(r'name:([\w]+)').findall(options)

    # find all plot manifest files matching the variable names
    mfst_files = []
    for name in names:
        mfst_files += glob.glob(os.path.join(sessionDir, r'mfst.plot*%s*.xml'%name))

    # remove the plot manifest files
    for mfst_file in mfst_files:
        os.remove(mfst_file)


def get_task_lock(taskId, sessionDir, postfix):
    """
    Look in a session directory and determine if the task is already running
    by looking for a file called <taskId>.<postfix>.lock. If the file is not
    there, it create the file and write 'running\n'.
    @type str
    @param taskId: celery task id
    @type str
    @param sessionDir: session directory
    @type str
    @param postfix: postfix for lock and running file
    @type bool
    @return: False if the task was already running and True otherwise
    """
    lockPath = os.path.join(sessionDir,"%s.%s.lock" % (taskId, postfix))
    ret = True
    with open(lockPath,'a+') as lockHandle:
        # obtain the lock
        lock_file(lockHandle)
        # go to the beginning of the file
        lockHandle.seek(0,0)
        line = lockHandle.readline().strip()
        if line == 'running':
            # the running message is already here, so return False
            ret = False
        else:
            # write that we are running to the file
            lockHandle.write('running\n')

        # release the lock
        unlock_file(lockHandle)

    return ret


def stop_workflow(app, workflowStateFile):
    """
    Clean workflow tasks from the workflowStateFile
    It basically terminates all the running/pending tasks from the workflowStateFile
    NOTE: error should be handled by the caller

    @type app: Celery application
    @param app: Celery application instance
    @type workflowStateFile: string
    @param workflowStateFile: name of the workflow state file that stores the workflow task id's and its updated status
    """
    # return if workflowStateFile has been generated yet
    if not os.path.isfile(workflowStateFile):
        return

    # extract previously saved workflow task status
    workflowTask_preState = {}
    pattern_workflowTask = re.compile(r"Workflow task \(id: ([^\s]+)\) status: ([A-Z]+)\n")
    for line in open(workflowStateFile).readlines():
        if pattern_workflowTask.match(line):
            (tid, tstate) = pattern_workflowTask.match(line).groups()
            workflowTask_preState[tid] = (tstate)

    # if the previous workflow task status was not found
    if not workflowTask_preState:
        # raise an exception because this should never happend
        raise RuntimeError

    # for each workflow task
    for tid, (tstate) in workflowTask_preState.items():

        # get the current workflow task status
        workflowTask_state = AsyncResult(tid).state

        # kill the workflow task if possible
        if workflowTask_state in ['PENDING', 'STARTED', 'ALREADYRUNNING', 'SUCCESS']:
            revoke(tid, terminate=True)


def stop_visualization(app, visualizerFile, optOnly=False):
    """
    Clean visualization tasks from the visualizerFile
    It basically terminates all the running/pending tasks from the visualizerFile
    When optOnly==True, if only terminates the running/pending tasks that was started from plot options changing requests
    NOTE: error should be handled by the caller

    @type app: Celery application
    @param app: Celery application instance
    @type visualizerFile: string
    @param visualizerFile: name of the visualizationStatus file that stores the visualization manager/task id's and its updated status
    @type optOnly: bool
    @param optOnly: flag indicating whether only terminates the running/pending tasks that was started from plot options changing requests
    """
    # return if visualizerFile has been generated yet
    if not os.path.isfile(visualizerFile):
        return

    # extract previously saved visualization status
    visualizationManager_preState = {}
    visualizationTask_preState = {}
    pattern_visMgr = re.compile(r"Visualization manager \(id: ([^\s]+), options: (.+)\) status: ([A-Z]+)\n")
    pattern_visTsk = re.compile(r"Visualization task \(id: ([^\s]+), options: (.+), file: ([^\s]+)\) status: ([A-Z]+)\n")
    for line in open(visualizerFile).readlines():
        if pattern_visMgr.match(line):
            (mid, moptions, mstate) = pattern_visMgr.match(line).groups()
            visualizationManager_preState[mid] = (mstate, moptions)
        if pattern_visTsk.match(line):
            (tid, toptions, tfile, tstate) = pattern_visTsk.match(line).groups()
            visualizationTask_preState[tid] = (tstate, tfile)

    # if the visualizationManager was not found
    if not visualizationManager_preState:
        # raise an exception because this should never happend
        raise RuntimeError

    # for each visualization manager (with or without options)
    for mid, (mstate, moptions) in visualizationManager_preState.items():

        # skip visualization for None options when requested
        if optOnly and moptions=='None': continue        

        # get the current visualization manager status
        visMgr_state = AsyncResult(mid).state

        # collect the current visualization task information when necessary
        visualizationTask_info = {}
        if visMgr_state in ['PROGRESS', 'SUCCESS']:
            visualizationTask_info = AsyncResult(mid).result

        # kill the visualization manager if possible
        if visMgr_state in ['PENDING', 'STARTED', 'PROGRESS']:
            revoke(mid, terminate=True)

        # kill the visualization tasks if any
        for (visualizationTask_id, plotManifestFileName) in visualizationTask_info.iteritems():
            visTsk_state = AsyncResult(visualizationTask_id).state
            if visTsk_state in ['PENDING', 'STARTED']:
                revoke(visualizationTask_id, terminate=True)


def get_hostname(url_hostname):
    '''
    get the machine hostname from a url host

    @type url_hostname: string
    @param url_hostname: url host section (could be either a hostname, or ip, or 'localhost')

    @return: the machine hostname
    '''
    # translate a host name to ip (NOTE IPv4 address format only)
    ip = socket.gethostbyname(url_hostname)

    # get the hostname by ip
    if ip == '127.0.0.1':
        hostname = socket.gethostname()
    else:
        hostname = socket.gethostbyaddr(ip)[0]

    # return the machine host name
    return hostname

def get_active_queues(celery_hostname=None):
    """
    Get the active queues in "celery_hostname" that are found by celery

    @type celery_hostname: string
    @param celery_hostname: name of the requested host machine 
                            if not provided, get all active queues

    @return: the set of active queues from in the host machine
    """
    set_active_queues = set([])

    # if celery_hostname is given
    if celery_hostname:
        active_queues = inspect(destination=[celery_hostname]).active_queues()
        if active_queues:
            for queue in active_queues[celery_hostname]:
                set_active_queues.add(queue[u'name'])

    # otherwise, get all active_queues
    else:
        active_queues = inspect().active_queues()
        if active_queues:
            for queues in active_queues.values():
                for queue in queues:
                    set_active_queues.add(queue[u'name'])

    # return the set of active queues
    return set_active_queues

def check_queue_status(app, all_hosts=True):
    """
    Check whether the target queues from celeryConfigFile are available
    NOTE: error should be handled by the caller

    @type app: Celery application
    @param app: Celery application instance
    @type all_hosts: boolean
    @param all_hosts: if False, check for active queues only from host names specified in celeryConfigFile

    @return: True if queues were found active in hostname from celeryConfigFile
             False otherwise
    """
    # get url hostname and port
    broker_url = app.conf.get('BROKER_URL')
    url = urlparse(broker_url)
    url_hostname = url.hostname
    port = url.port

    # try to ping the requested port
    redis_srv = redis.Redis(url_hostname, port=port)
    try:
        redis_srv.ping()
    # if failed
    except:
        # return False
        return False

    # get target queues
    set_target_queues = set(app.conf.get("CELERY_QUEUES"))

    # get the user who started the celery worker (hack currently)
    r = re.compile(r'visualizationManager_(\w+)')
    for queue in set_target_queues:
        m = r.match(queue)
        if m:
            user = m.group(1)

    # get active queues
    if all_hosts:
        set_active_queues = get_active_queues()
    else:
        # get active queues
        # NOTE not verified for the remote host
        set_active_queues = set([])
        for queue_name in app.conf[u'CELERY_QUEUES']:
           celery_node = '%s@%s'%(queue_name,get_hostname(url_hostname))
           active_queues = get_active_queues(celery_node)
           set_active_queues = set_active_queues.union(active_queues)

    # check whether all the target queues are available
    if set_target_queues.issubset(set_active_queues):
        return True
    else:
        return False

def check_queue_status_patiently(app, all_hosts=True, max_waiting=3, interval=1):
    '''
    Patiently check whether the target queues from celeryConfigFile are available
    This is useful when celery worker tries to make reconnection to the broker

    @type app: Celery application
    @param app: Celery application instance
    @type all_hosts: boolean
    @param all_hosts: if False, check for active queues only from host names specified in celeryConfigFile
    @type max_waiting: float
    @param max_waiting: maximum waiting time
    @type interval: float
    @param interval: time interval to check queue status

    @return: True if queues were found active in hostname from celeryConfigFile
             False otherwise
    '''
    total_waiting = 0
    while total_waiting <= max_waiting:
        status_ok = check_queue_status(app, all_hosts)
        if status_ok:
            break
        time.sleep(interval)
        total_waiting += interval
    return status_ok

def start_redis_server(redisconfigFile, hostname, port, max_waiting=10., interval=0.2):
    '''
    start redis server

    @type redisconfigFile: string
    @param redisconfigFile: name of the celeryconfig file (json format)
    @type hostname: string
    @param hostname: machine host name
    @type port: int
    @param port: port number requested for redis server
    @type max_waiting: float
    @param max_waiting: maximum waiting time
    @type interval: float
    @param interval: time interval to check redis server connection status

    @return: True if redis server started successfully
             False otherwise
    '''

    # start redis server in background
    cmd = 'redis-server %s --bind %s --port %s'%(redisconfigFile, hostname, port)
    process = Popen(cmd.split(), stdout=PIPE, stderr=PIPE)

    # make sure redis server is ready
    total_waiting = 0
    redis_conn = redis.connection.Connection(hostname, port=port, socket_timeout=5)
    while total_waiting<max_waiting:
        try:
            redis_conn.connect()
        except:
            status_ok = False
            time.sleep(interval)
            total_waiting += interval
        else:
            status_ok = True
            break

    # return
    return status_ok

def stop_redis_server(hostname, port, verbose=False):
    '''
    stop redis server

    @type hostname: string
    @param hostname: machine host name
    @type port: int
    @param port: port number requested for redis server

    @return: status of the system call
    '''
    # write some info
    if verbose:
        sys.stdout.write("Stopping redis-server on %s:%s ... "%(hostname,port))
        sys.stdout.flush()

    # start redis server in background
    cmd = 'redis-cli -h %s -p %s shutdown'%(hostname, port)
    ps = Popen(cmd.split(), stdout=PIPE, stderr=STDOUT)
    output = ps.communicate()[0]

    # return
    return ps.returncode


def start_celery_worker(app, celeryWorkerDir, celery_owner_group=None, env={}, max_waiting=10., interval=0.2):
    '''
    start celery worker

    @type app: Celery application
    @param app: Celery application instance
    @type celeryWorkerDir: string
    @param celeryWorkerDir: celery worker directory where the log and pid files will be saved
    @type celery_hostname: string
    @param celery_hostname: celery host name (maybe different from the machine host name)
    @type celery_owner_group: string
    @param celery_owner_group: celery worker owner group after detaching
    @type max_waiting: float
    @param max_waiting: maximum waiting time
    @type interval: float
    @param interval: time interval to check queue status

    @return: True if celery worker started sucessfully
             False otherwise
    '''
    # get the queue names and number of workers from the list of celery configuration files
    queues_and_workers = {}
    queue_specs = app.conf[u'CELERY_QUEUES']
    for queue_name, queue_spec in queue_specs.iteritems():
        queues_and_workers[queue_name] = (queue_spec[u'min_number_of_workers'], queue_spec[u'max_number_of_workers'])

    # build the command to start celery worker
    queue_names = ' '.join(queues_and_workers.keys())
    cmd = "celery multi start %s -A agiovanni.celeryGiovanni -l info --without-mingle --without-heartbeat --without-gossip -Ofair --umask=002 --logfile=%s/celery_worker_%%n.log"%(queue_names, celeryWorkerDir)
    for queue_name, (min_number_of_workers, max_number_of_workers) in queues_and_workers.iteritems():
        cmd += ' -Q:%s %s -c:%s %s'%(queue_name, queue_name, queue_name, max_number_of_workers)
        cmd += ' --time-limit:%s=%s --soft-time-limit:%s=%s'%(queue_name, queue_specs[queue_name][u'time-limit'], queue_name, queue_specs[queue_name][u'soft-time-limit'])
    if celery_owner_group:
        cmd += ' --gid=%s'%celery_owner_group

    # run the command to start celery worker
    process = Popen(shlex.split(cmd), env=env, stdout=PIPE, stderr=PIPE)
    stdout, stderr = process.communicate()

    # return status
    return True


def stop_celery_worker(app, celery_nodes, verbose=False):
    '''
    stop celery worker

    @type app: Celery application
    @param app: Celery application instance
    @type celery_nodes: list of string
    @param celery_nodes: list of celery node names

    @return: None
    '''
    # write some info
    if verbose:
        sys.stdout.write("Stopping celery worker %s ... "%celery_nodes)
        sys.stdout.flush()

    # stop celery worker
    for celery_node in celery_nodes:
        app.control.broadcast('shutdown', destination=[celery_node])

def stop_celery_worker_brute_force(verbose=False):
    '''
    use the brute force method listed in celery doc to kill the celery workers (http://docs.celeryproject.org/en/latest/userguide/workers.html#stopping-the-worker)
    '''
    # write some info
    if verbose:
        sys.stdout.write("Kill the celery workers by pids (http://docs.celeryproject.org/en/latest/userguide/workers.html#stopping-the-worker) ... ")
        sys.stdout.flush()

    # stop celery worker
    process = Popen("ps ux".split(), stdout=PIPE, stderr=PIPE)
    stdout, stderr = process.communicate()
    pids = [item.split()[1] for item in stdout.split('\n') if 'celery worker' in item]
    if not pids:
        if verbose:
            sys.stdout.write("No active celery worker found ...")
            sys.stdout.flush()
    for pid in pids:
        os.kill(int(pid), signal.SIGTERM)
