#!/bin/env python
import pdb
""" 
###############################################################
NAME
ncCompare.py - Compare two variables from two nc files

DESCRIPTION
This program compares two variables from two nc files for value
discrepancies.

SYNOPSIS
ncCompare.py [-h] [-b bbox] var1 file1 var2 file2

OPTIONS
-h      - Print usage info
-b bbox - Bounding box in the form of west,south,east,north
var1    - Variable 1 from file 1
file1   - File 1
var2    - Variable 2 from file 2
file2   - File 2

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 12/19/2012, Initial version

VERSION
$Revision: 1.7 $
###############################################################
""" 

import sys
import os
import getopt
import re
from subprocess import call
import numpy as np
from netCDF4 import Dataset


def usage():
    print "Usage: %s [-h] [-b bbox] var1 file1 var2 file2" % os.path.basename(sys.argv[0])

def main():
    latS,latN,lonW,lonE = None, None, None, None

    # Command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hDb:")
    except:
        print "ERROR: Invalid options\n"
        usage()
        sys.exit(1)

    for o, v in opts:
        if o == "-h":
            usage()
            sys.exit(1)
        elif o == "-D":
            pdb.set_trace()
        elif o == "-b":
            lonW,latS,lonE,latN = (float(x) for x in v.split(','))

    if len(args) < 4:
        print "ERROR  Invalid command line options"
        usage()
        sys.exit(1)

    vname1 = args[0]
    file1 = args[1]
    vname2 = args[2]
    file2 = args[3]

    file1_tmp = "/var/tmp/" + os.path.basename(file1) + ".tmp" + str(os.getpid())
    file2_tmp = "/var/tmp/" + os.path.basename(file2) + ".tmp" + str(os.getpid())

    # Subset file to given bounding box
    if None not in (latS,latN,lonW,lonE):
        bbox_lat = "lat,%s,%s" % (str(latS),str(latN))
        bbox_lon = "lon,%s,%s" % (str(lonW),str(lonE))
        rc = call(['ncks', '-O', '-d', bbox_lat, '-d', bbox_lon, file1, file1_tmp])
        if rc:
            sys.stderr.write("ERROR ncks failed(%s)\n" % ("ncks -O " + bbox + " " + file1 + " " + file1_tmp))
        rc = call(['ncks', '-O', '-d', bbox_lat, '-d', bbox_lon, file2, file2_tmp])
        if rc:
            sys.stderr.write("ERROR ncks failed(%s)\n" % ("ncks -O " + bbox + " " + file2 + " " + file2_tmp))

        file1 = file1_tmp
        file2 = file2_tmp

    # Open files and read in variables
    fh1 = Dataset(file1)
    fh2 = Dataset(file2)

    try:
        var1 = fh1.variables[vname1]
    except:
        sys.stderr.write("ERROR variable %s not found in %s\n" % (vname1, file1))
        exit(-1)
    try:
        var2 = fh2.variables[vname2]
    except:
        sys.stderr.write("ERROR variable %s not found in %s\n" % (vname2, file2))
        exit(-1)

    #
    # Getting data
    #

    data1 = var1[:]
    data2 = var2[:]

    # Get rid of first dimension if size is 1 (normally time)
    if data1.shape[0] == 1:
        fh1.close()
        rc = call(['ncwa', '-O', '-a', 'time', file1, file1_tmp])
        if rc:
            sys.stderr.write("ERROR ncks remove time failed(%s)\n" % ("ncks -O -a time " + file1 + " " + file1_tmp))
            exit(-1)
        file1 = file1_tmp
        fh1 = Dataset(file1)
        var1 = fh1.variables[vname1]
        data1 = var1[:]
    if data2.shape[0] == 1:
        fh2.close()
        rc = call(['ncwa', '-O', '-a', 'time', file2, file2_tmp])
        if rc:
            sys.stderr.write("ERROR ncks remove time failed(%s)\n" % ("ncwa -O -a time " + file2 + " " + file2_tmp))
            exit(-1)
        file2 = file2_tmp
        fh2 = Dataset(file2)
        var2 = fh2.variables[vname2]
        data2 = var2[:]

    # compare mask
    try:       mask1 = data1.mask
    except:    mask1 = None
    try:       mask2 = data2.mask
    except:    mask2 = None

# Check fill value pattern (TBD)
#    if mask1 is not None and mask2 is not None:
#            sys.stdout.write("Difference found: number of fill values\n")
#            exit(0)

    # Fill values
    try:
        fill1 = var1.getncattr("_FillValue")
    except:
        if np.min(data1) > -9999:    fill1 = -9999
        else:
            sys.stderr.write("ERROR Fail to set fill value for %s\n" % (vname1))
            exit(-1)
    try:
        fill2 = var2.getncattr("_FillValue")
    except:
        if np.min(data2) > -9999:    fill2 = -9999
        else:
            sys.stderr.write("ERROR Fail to set fill value for %s\n" % (vname2))
            exit(-1)

    # Make sure two arrays have compatible dimensions, meaning same ranks
    # and same dimension sizes.  However, order of dimensions can be 
    # different
    if sorted(data1.shape) != sorted(data2.shape):
        sys.stdout.write("%s and %s have different shapes.  Cannot compare.\n" % (vname1, vname2))
        fh1.close()
        fh2.close()
        exit(0)

    #
    # Reorder data to the first variable if dimension orders are not same
    #

    rank = len(data1.shape)

    # Get order of dimensions
    dimnames1 = var1.dimensions
    dimnames2 = var2.dimensions
    units = []
    for dname in dimnames1:
        u = str(fh1.variables[dname].getncattr('units'))
        if re.match("^seconds", u):     u = "time"
        elif re.match("^hours", u):  u = "time"
        elif re.match("^days", u):   u = "time"
        elif u in ["hour","day", "month"]:   u = "time"
        units.append(u)

    need_reorder = 0
    axes = []
    for i, dname in enumerate(dimnames2):
        u = str(fh2.variables[dname].getncattr('units'))
        if re.match("^seconds", u):     u = "time"
        elif re.match("^hours", u):  u = "time"
        elif re.match("^days", u):   u = "time"
        elif u in ["hour","day", "month"]:   u = "time"
        found_axis = 0
        if u != units[i]:
            need_reorder = 1
            # Find which index this units should go
            for k in range(rank):
                if u == units[k]:
                    axes.append(k)
                    found_axis = 1
                    break
            if not found_axis:
                sys.stderr.write("ERROR dimension units mismatch "+u)
                exit(-1)
        else:
            axes.append(i)
    

    if need_reorder:
        # Reorder data
        data2 = np.ma.transpose(data2, axes)

    #
    # Compare data
    #

    total_size = 1
    for x in data1.shape:
        total_size = total_size * x
    data1 = data1.reshape(total_size)
    data2 = data2.reshape(total_size)
    delta = data1 - data2
    sys.stdout.write("Min/Max difference: %s %s\n"%(str(np.min(delta)), str(np.max(delta))))

    fh1.close()
    fh2.close()
    exit(0)


if __name__ == "__main__":
    main()

