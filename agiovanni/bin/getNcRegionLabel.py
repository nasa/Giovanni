#! /bin/env python

""" 
###############################################################
NAME
getNcRegionLabel.py - Get a region label from a nc file

DESCRIPTION
Creates a region label for plot display of region information

SYNOPSIS
getNcRegionLabel.py [-h] in.nc

OPTIONS
-h    - Print usage info
in.nc - Input nc file

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 04/25/2012, Initial version

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
    # Get region label
    #

    ncfile = NcFile.NcFile(infile)
    regionLabel = ncfile.get_region_label()

    print regionLabel

    exit(0)


if __name__ == "__main__":
    main()

