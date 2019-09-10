#!/bin/env python

""" 
###############################################################
NAME
getNcMin.py - Get min value of a variable

DESCRIPTION
This script gets the minimum value of a variable in a nc file

SYNOPSIS
getNcMin.py [-h] in.nc

OPTIONS
-h    - Print usage info
in.nc - Input nc file

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 06/22/2012, Initial version

VERSION
$Revision: 1.3 $
###############################################################
""" 

import pdb
import sys
import os
import getopt
from netCDF4 import Dataset

sys.path.append(os.path.dirname(os.path.realpath(__file__)))
import NcFile

def usage():
    print "Usage: %s [-h] [-v varname] in.nc" % os.path.basename(sys.argv[0])

def main():
    # Command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hv:D")
    except:
        print "ERROR: Invalid options\n"
        usage()
        sys.exit(1)

    vname = None
    for o, v in opts:
        if o == "-h":
            usage()
            sys.exit(1)
        elif o == "-D":
            pdb.set_trace()
        elif o == "-v":
            vname = v
    if len(args) < 1:
        print "ERROR  Invalid command line options"
        usage()
        sys.exit(-1)
    infile = args[0]

    if vname is None:
        usage()
        sys.exit(-1)

    #
    # Get min value
    #

    nc = NcFile.NcFile(infile)
    minValue = nc.get_min_value(vname)

    if minValue is not None:
        print minValue
    else:
        sys.stderr.write("ERROR Fail to find min for "+vname)
        sys.exit(-1)

    sys.exit(0)


if __name__ == "__main__":
    main()

