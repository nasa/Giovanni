"""
CGI utilities for python CGI scripts.
"""

import os
import sys
import urlparse
import subprocess


def patch_path():
    # Python Path
    cur_dir = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(
        cur_dir,
        '..',
        'lib/python%s/site-packages' %
        sys.version[
            :3])
    sys.path.append(path)

    # System Path
    bin_dir = cur_dir
    while 'bin' not in os.listdir(bin_dir):
        bin_dir = os.path.join(bin_dir, '..')
    bin_dir = os.path.join(bin_dir, 'bin')

    os.environ['PATH'] = bin_dir + ':' + os.environ.get("PATH")


class UntaintError(Exception):
    """
    Class for errors associated with untainting the cgi query string.
    """
    pass


def get_query_params(qstring=None):
    """
    Parse the cgi query string and untaint parameters
    :param qstring: the  query string. If not specified, will use CGI
    environment variable QUERY_STRING.
    :return: dict of parameters and their untainted values
    """

    # make sure QUERY_STRING environment variable is set
    if qstring is not None:
        os.environ['QUERY_STRING'] = qstring

    # the perl CGI library looks for QUERY_STRING and REQUEST_METHOD to be set
    if 'REQUEST_METHOD' not in os.environ:
        os.environ['REQUEST_METHOD'] = 'GET'

    # command to untaint
    cmd = ['cgi_untaint.pl']

    # call...
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    stdout, stderr = p.communicate()

    if p.returncode != 0:
        # not good!
        raise UntaintError(
            "Command '%s' returned %d.\nSTDOUT:\n%s\nSTDERR: %s" %
            (" ".join(cmd), p.returncode, stdout, stderr))

    # the untainted query string is in stdout
    return urlparse.parse_qs(stdout)
