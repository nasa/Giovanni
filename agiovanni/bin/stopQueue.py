#!/bin/env python

"""
Driver script to stop celery queue worker

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
@date: 10/13/2016
"""

import os
import sys
import argparse
from urlparse import urlparse
import redis
import xml.etree.ElementTree as ET

from agiovanni import celeryconfigBase
from agiovanni.queueUtilities import stop_redis_server, get_hostname, stop_celery_worker, stop_celery_worker_brute_force
from agiovanni.celeryGiovanni import app

if __name__ == "__main__":
    """
    Driver script to stop redis server/celery worker
        that was started during sandbox deployement

    This script exit with the following error code:
        1 -- bad port number
        2 -- un-supported broker other then redis
        3 -- failed to stop redis server
        4 -- failed to start celery worker
    """

    # get the pre-assigned port numbers
    xml_file = os.path.join(os.path.dirname(__file__),'..','cfg','redis_port.xml') # NOTE relative path assumed
    tree = ET.parse(xml_file)
    userPort_map = {}
    for item in tree.findall('port'):
        user = item.attrib['user']
        port = item.attrib['port']
        userPort_map[user] = int(port)

    # parse input parameters
    parser = argparse.ArgumentParser(description="Stop celery queue worker")
    parser.add_argument("-q", "--QUEUEURL", type=str, help="queue url")
    args = parser.parse_args()

    #local variables
    queueURL = args.QUEUEURL
    if not queueURL:
        queueURL = app.conf[u'BROKER_URL']
    url = urlparse(queueURL)
    scheme = url.scheme
    url_hostname = url.hostname
    port = url.port
    user = os.environ['USER']

    if not port:
        # use the pre-assigned port number if not specified
        port = userPort_map[user]
        sys.stdout.write("Port number not provided.\nThe pre-assigned port number (%s) will be used!\n"%port)
    elif port <= 0:
        # exit with code 1 if a bad port number is provided
        sys.stderr.write("Port number you provided (%s) is not valid!\n"%port)
        sys.exit(1)
    elif port != userPort_map[user]:
        # exit with code 1 if a not-preassigned port number is provided
        sys.stderr.write("Port number you provided (%s) is not what you have been pre-assigned (%s)!\nQuit now since you may close port that is currently being used by other people!\n"%(port, userPort_map[user]))
        sys.exit(1)


    # set default scheme and hostname if not provided
    if not scheme:
        scheme = 'redis'
    if not url_hostname:
        url_hostname = 'localhost'
    queueUrl = url._replace(scheme=scheme, netloc=':'.join([url_hostname,str(port)])).geturl()
    
    # currently only support redis
    # exit with code 2 if non-redis broker was requested
    if scheme != 'redis':
        sys.stderr.write("The broker provided/defaulted (%s) is not supported!\n"%scheme)
        sys.exit(2)

    # try to ping the requested port
    redis_srv = redis.Redis(url_hostname, port=port)
    try:
        redis_srv.ping()
    except:
        # if redis-server seems already shutdown
        sys.stderr.write("redis-sever may have already been shutdown for this port!\n")
        # use the brute force method to kill the celery worker
        try:
            stop_celery_worker_brute_force()
        except:
            sys.stderr.write("Failed to stop celery worker by brute force!\n")
            sys.exit(4)
        else:
            sys.stderr.write("Successful!\n")
            sys.exit(0)

    # stop celery worker on the request hostname and port
    try:
        celery_nodes = []
        for queue_name in app.conf[u'CELERY_QUEUES']:
           celery_nodes.append('%s@%s'%(queue_name,get_hostname(url_hostname)))
        stop_celery_worker(app, celery_nodes)
    except:
        # exit with code 4 if failed to stop celery worker
        sys.stderr.write("Failed to stop celery worker!\n")
        sys.exit(4)
    else:
        sys.stderr.write("Successful!\n")

    # stop redis server on the requested hostname and port
    status = stop_redis_server(url_hostname, port)
    if status:
        # exit with code 3 if failed to stop redis server
        sys.stderr.write("Failed to stop redis server!\n")
        sys.exit(3)
    else:
        sys.stderr.write("Successful!\n")

