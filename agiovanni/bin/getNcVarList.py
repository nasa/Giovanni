#! /bin/env python

""" 
####################################################################
NAME
getNcVarList.py - Get list of variable names from a nc file

DESCRIPTION
This script checks a nc file and print out a list of variable
names to stdout.  The list does not include coordinate variables.

SYNOPSIS
get_ncvarlist.py [-h] in.nc

OPTIONS
-h    - Print usage info
in.nc - Input nc file

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 04/06/2012, Initial version

VERSION
$Revision: 1.4 $
####################################################################
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
    # Get variable names
    #

    fh = Dataset(infile)
    dimnames = fh.dimensions.keys()
    varnames = fh.variables.keys()
    fh.close()

    varnames = list(set(varnames) - set(dimnames))
    varnames.sort()
    outstring = ""
    for nm in varnames:
        if nm in ['time_bnds','lat_bnds','lon_bnds']:  continue
        outstring = outstring + nm + " "
    outstring.strip()
    print outstring

    exit(0)


if __name__ == "__main__":
    main()

