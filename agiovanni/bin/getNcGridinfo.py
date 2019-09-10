#! /bin/env python
""" 
###############################################################
NAME
getNcGridinfo.py - Get grid info of a dimension

DESCRIPTION
This script checks a nc file and print out start value, step size (resolution), and
number of grid points.

SYNOPSIS
getNcGridinfo.py [-h] -d <dimName> [-t lat|lon] in.nc

OPTIONS
-h           - Print usage info
-d <dimName> - Name of the dimension variable
-t <lat|lon> - Type of dimension (optional)
in.nc        - Input nc file

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 08/22/2012, Initial version

VERSION
$Revision: 1.2 $
###############################################################
""" 

import sys
import os
import getopt
from netCDF4 import Dataset
import NcFile
import pdb

def usage():
    print "Usage: %s [-h] -d dimName [-t lat|lon] in.nc" % os.path.basename(sys.argv[0])

def main():
    # Command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hDd:t:")
    except:
        print "ERROR: Invalid options\n"
        usage()
        sys.exit(1)

    dimName, dimType = None, None
    for o, v in opts:
        if o == "-h":
            usage()
            sys.exit(1)
        elif o == "-D":
            pdb.set_trace()
        elif o == "-d":
            dimName = v
        elif o == "-t":
            dimType = v

    if len(args) < 1:
        print "ERROR  Invalid command line options"
        usage()
        sys.exit(1)

    if dimName is None:
        print "ERROR  Dimension name missing"
        usage()
        sys.exit(1)

    if dimType not in (None, "lat", "lon"):
        sys.stderr.write("WARNING: Dimension type %s not recognized and will be ignored" % (dimType))

    infile = args[0]

    #
    # Get grid information
    #

    ncfile = NcFile.NcFile(infile)
    start,resolution,size = ncfile.gridinfo(dimName, dimType)

    if None in (start, resolution, size):
        sys.stderr.write("ERROR Fail to get grid info")
        exit(-1)
 
    print "%f,%f,%d" % (start, resolution, size)

    exit(0)


if __name__ == "__main__":
    main()

