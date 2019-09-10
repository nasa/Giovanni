#! /bin/env python

""" 
###############################################################
NAME
getNcData1D.py - Get data of a vector variable

DESCRIPTION
This script gets the data values of a vector variable in a nc file

SYNOPSIS
getNcData1D.py [-h] -v vname in.nc

OPTIONS
-h       : Print usage info
-v vname : Name of the variable for getting its data
in.nc    : Input nc file

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 06/25/2012, Initial version

VERSION
$Revision: 1.2 $
###############################################################
""" 

import sys
import os
import getopt
from netCDF4 import Dataset
import NcFile

def usage():
    print "Usage: %s [-h] [-t dtype] -v vname in.nc" % os.path.basename(sys.argv[0])

def main():
    # Command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:], "[ht:]v:")
    except:
        print "ERROR: Invalid options\n"
        usage()
        sys.exit(1)

    vname = None
    dtype = None
    for o, v in opts:
        if o == "-h":
            usage()
            sys.exit(1)
        elif o == "-v":
            vname = v
        elif o == "-t":
            dtype = v
    if len(args) < 1:
        print "ERROR  Invalid command line options"
        usage()
        sys.exit(-1)
    infile = args[0]

    if vname is None:
        usage()
        sys.exit(-1)

    #
    # Get data values
    #

    nc = NcFile.NcFile(infile)
    datString = nc.get_data1D(vname, dtype)

    if datString is not None:
        print datString
    else:
        sys.stderr.write("ERROR Fail to find max for "+vname)
        sys.exit(-1)

    sys.exit(0)


if __name__ == "__main__":
    main()

