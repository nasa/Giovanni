#! /bin/env python

""" 
###############################################################
NAME
getNcResolution.py - Get spatial resolution from a nc file

DESCRIPTION
Get spatial resolution from a nc file. The highest resolution is
returned by default, when x and y have different resolutions.

SYNOPSIS
getNcResolution.py [-h] in.nc

OPTIONS
-h    - Print usage info
in.nc - Input nc file

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 06/02/2012, Initial version

VERSION
$Revision: 1.1 $
###############################################################
""" 

import sys
import os
import getopt
from netCDF4 import Dataset
import NcFile

def usage():
    print "Usage: %s [-h] in.nc" % os.path.basename(sys.argv[0])

def main():
    # Command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:], "h")
    except:
        print "ERROR: Invalid options\n"
        usage()
        sys.exit(1)

    for o, v in opts:
        if o == "-h":
            usage()
            sys.exit(1)
    if len(args) < 1:
        print "ERROR  Invalid command line options"
        usage()
        sys.exit(1)

    infile = args[0]

    #
    # Get resolution
    #

    ncfile = NcFile.NcFile(infile)
    resolution = ncfile.get_resolution()

    print resolution

    exit(0)


if __name__ == "__main__":
    main()

