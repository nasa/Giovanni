#! /bin/env python

""" 
###############################################################
NAME
getNcFillValue.py - Get fill values from a nc file

DESCRIPTION
This script checks a nc file and print out a list of fill values.

SYNOPSIS
get_ncdimlist.py [-h] [-v vname] in.nc

OPTIONS
-h       - Print usage info
-v vname - Variable name, for retrieving fillvalue of the variable
in.nc    - Input nc file

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 04/09/2012, Initial version

VERSION
$Revision: 1.4 $
###############################################################
""" 

import sys
import os
import getopt
from netCDF4 import Dataset
import NcFile

def usage():
    print "Usage: %s [-h] [-v vname] in.nc" % os.path.basename(sys.argv[0])

def main():
    # Command line options
    vname = None
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hv:")
    except:
        print "ERROR: Invalid options\n"
        usage()
        sys.exit(1)

    for o, v in opts:
        if o == "-h":
            usage()
            sys.exit(1)
        elif o == "-v":
            vname = v
    if len(args) < 1:
        print "ERROR  Invalid command line options"
        usage()
        sys.exit(1)

    infile = args[0]

    #
    # Get fill values
    #

    ncfile = NcFile.NcFile(infile)
    fillvalue = ncfile.get_fillvalue(vname)

    print repr(fillvalue)

    exit(0)


if __name__ == "__main__":
    main()

