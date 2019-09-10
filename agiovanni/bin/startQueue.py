#!/bin/env python

"""
Driver script to start celery queue worker

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import os
import sys
import argparse
from urlparse import urlparse
import redis
import json

from agiovanni import celeryconfigBase
from agiovanni.queueUtilities import start_redis_server, check_queue_status_patiently, get_hostname, start_celery_worker, stop_celery_worker
from agiovanni.celeryGiovanni import app

if __name__ == "__main__":
    """
    Driver script to start the celery worker

    This script does not catch any exception in general

    This script exits with the following error code:
        1 -- bad port number
        2 -- un-supported broker other then redis
        3 -- failed to start redis server
        4 -- failed to start celery worker or stop the running celery worker
        5 -- do not have write permission in output_dir
    """

    # parse input parameters
    parser = argparse.ArgumentParser(description="Start celery queue worker")
    parser.add_argument("-q", "--QUEUEURL", type=str, help="queue url")
    parser.add_argument("-r", "--REDISCFGFILE", type=str, help="redis config file")
    parser.add_argument("-d", "--OUTPUT_DIR", type=str, help="output dir")
    parser.add_argument("-e", "--ENV", type=json.loads, help="user-provided environment variables in json format string")
    parser.add_argument('--local-worker', dest='local_worker', action='store_true')
    parser.add_argument('--remote-worker', dest='local_worker', action='store_false')
    parser.set_defaults(local_worker=True)
    parser.add_argument("-g", "--CELERY_OWNER_GROUP", type=str, help="celery worker owner group after detaching")
    args = parser.parse_args()

    #local variables
    queueURL = args.QUEUEURL
    redisconfigFile = args.REDISCFGFILE
    if not queueURL:
        queueURL = app.conf[u'BROKER_URL']
    output_dir = args.OUTPUT_DIR
    local_worker = args.local_worker
    url = urlparse(queueURL)
    scheme = url.scheme
    url_hostname = url.hostname
    port = url.port
    user = os.environ['USER']
    celery_owner_group = args.CELERY_OWNER_GROUP

    # if the sandbox creater does not have written permission to output_dir
    if not os.access(output_dir, os.W_OK):
        # exit with code 5
        sys.exit(5)

    # exit with code 1 if a bad port number is provided
    if port <= 0:
        sys.exit(1)

    # set default scheme and hostname if not provided
    if not scheme:
        scheme = 'redis'
    if not url_hostname:
        url_hostname = 'localhost'
    
    # currently only support redis
    # exit with code 2 if non-redis broker was requested
    if scheme != 'redis':
        sys.exit(2)

    # try to ping the requested port
    redis_srv = redis.Redis(url_hostname, port=port)
    try:
        redis_srv.ping()
    # if failed
    except:
        # try to start redis server on the requested port
        try:
            redis_status_ok = start_redis_server(redisconfigFile, url_hostname, port)
            # exit with code 3 if failed to start redis server
            if not redis_status_ok:
                sys.exit(3)
        # if failed
        except:
            # exit with code 3
            sys.exit(3)



    # if local worker requested
    if local_worker:

        # stop celery worker on the request hostname and port
        # this will remove the overhead from the check_queue_status_patiently in the original code
        # anyway, a reconnected celery worker may not be reliable if there is a library change
        try:
            celery_nodes = []
            for queue_name in app.conf[u'CELERY_QUEUES']:
               celery_nodes.append('%s@%s'%(queue_name,get_hostname(url_hostname)))
            stop_celery_worker(app, celery_nodes)
        except:
            # exit with code 4 if failed to stop celery worker
            sys.exit(4)

        # try to start celery worker
        try:
            celery_status_ok = start_celery_worker(app, output_dir, celery_owner_group, args.ENV)
            # exit with code 4 if failed to start celery worker
            if not celery_status_ok:
                sys.exit(4)
        # if failed
        except:
            # exit with code 4
            sys.exit(4)
