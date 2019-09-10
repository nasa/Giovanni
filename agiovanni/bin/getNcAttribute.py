#! /bin/env python

""" 
###############################################################
NAME
getNcAttribute.py - Get fill values from a nc file

DESCRIPTION
Gets the value of an attribute in a nc file.

SYNOPSIS
getNcAttribute.py [-h] [-v varName] -a attrName in.nc

OPTIONS
-h          - Print usage info
-v varName  - Variable name (optional)
-a attrName - Attribute name
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
    print "Usage: %s [-h] [-v varName] -a attrName in.nc" % os.path.basename(sys.argv[0])

def main():
    # Command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hv:a:")
    except:
        print "ERROR: Invalid options\n"
        usage()
        sys.exit(1)

    varName = None
    attrName = None
    for o, v in opts:
        if o == "-h":
            usage()
            sys.exit(1)
        elif o == "-v":
            varName = v
        elif o == "-a":
            attrName = v
    if len(args) < 1:
        print "ERROR  Invalid command line options"
        usage()
        sys.exit(1)
    if attrName is None:
        print "ERROR  Attribute name missing"
        usage()
        sys.exit(1)

    infile = args[0]

    #
    # Get attribute value
    #

    ncfile = NcFile.NcFile(infile)
    attrValue = ncfile.get_attribute(attrName, varName)

    if attrValue is None:
        print ""
    else:
        print attrValue

    exit(0)


if __name__ == "__main__":
    main()

