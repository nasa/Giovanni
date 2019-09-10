'''
Created on Jul 9, 2015

Utility functions built on ncgen and ncdump.

@author: csmit
'''


import subprocess
from subprocess import CalledProcessError
from lxml import etree
import tempfile
import shutil
import nco
import difflib


class NetCDFError(Exception):

    """An exception thrown when unable to perform the an operation on
    netcdf
    """
    pass


def ncgen(cdl_file, nc_file):
    '''
    Calls ncgen to create a netcdf file
    '''
    subprocess.check_call(['ncgen', '-o', nc_file, cdl_file])


def ncdump(nc_file, *args, **kwargs):
    '''
    Calls ncdump and returns the resulting string. Supports all the switches.
    If the '-x' switch is used, the code will parse the resulting XML and
    return a libxml2 xmlDoc.
    '''
    if '-x' in args:
        return_xml = True
    else:
        return_xml = False

    cmd = ['ncdump', nc_file]

    for arg in args:
        cmd.append(arg)

    for key, value in kwargs.iteritems():
        cmd.append(key)
        cmd.append(value)

    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (out, err) = p.communicate()
    if p.returncode != 0:
        cmdStr = " ".join(cmd)
        msg = "Command '%s' returned %d. Error: %s" % (
            cmdStr, p.returncode, err)
        raise CalledProcessError(msg)

    if return_xml:
        return etree.fromstring(out)
    else:
        return out


def diff_nc_files(first, second, ignore_history=True):
    '''
    Dumps two netcdf files after removing history if ignore_history is set to
    true. Does a simple diff, but ignores the filename.
    '''
    dir_ = tempfile.mkdtemp()

    firstCdl = _get_file_cdl_for_diff(first, dir_, ignore_history)
    secondCdl = _get_file_cdl_for_diff(second, dir_, ignore_history)

    shutil.rmtree(dir_)

    differ = difflib.Differ()
    diff = differ.compare(firstCdl, secondCdl)

    lines = []
    # go through the diff and see if anything is different
    are_different = False
    for line in diff:
        lines.append(line)
        if line.startswith('-') or line.startswith('+'):
            are_different = True

    if are_different:
        return (True, lines)
    else:
        return (False, [])


def _get_file_cdl_for_diff(nc_file, dir_, ignore_history):

    if ignore_history:
        file_ = tempfile.mkstemp(".nc", "file", dir_)
        nco.delete_history(
            nc_file,
            file_[1],
            overwrite=True,
            stderr=subprocess.PIPE,
            stdout=subprocess.PIPE)
        nc_file = file_[1]

    txt = ncdump(nc_file, **{'-n': 'FILENAME'})
    return txt.splitlines()


def get_attribute(nc_file, att_name, *args):
    '''
    Gets an attribute out of the XML header dump of the file
    '''

    xml = ncdump(nc_file, '-x')
    namespaces = {
        "nc": "http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2"}

    if len(args) > 0:
        xpath = '/nc:netcdf/nc:variable[@name="%s"]/nc:attribute[@name="%s"]' % (
            args[0], att_name)
    else:
        xpath = '/nc:netcdf/nc:attribute[@name="%s"]' % att_name

    result = xml.xpath(xpath, namespaces=namespaces)

    if len(result) == 0:
        msg = "Unable to find attribute %s in file %s" % (att_name, nc_file)
        if len(args) > 0:
            msg = "%s for variable %s" % args[0]
        raise NetCDFError(msg)

    return result[0].get('value')
