#! /bin/env python

""" 
###############################################################
NAME
getNcDimList.py - Get dimension names from a nc file

DESCRIPTION
This script checks a nc file and print out a list of dimension
names, or a specific type of dimension to stdout. 

SYNOPSIS
get_ncdimlist.py [-h] [-t type] in.nc

OPTIONS
-h    - Print usage info
-t    - Type of the dimension to look up (default: all)
        "time" for getting the name of time dimension
        "lat" for getting the name of latitude dimension
        "lon" for getting the name of longitude dimension
in.nc - Input nc file

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 04/06/2012, Initial version

VERSION
$Revision: 1.3 $
###############################################################
""" 

import sys
import os
import getopt
from netCDF4 import Dataset
import NcFile

def usage():
    print "Usage: %s [-h] [-t lat|lon|time|z] in.nc" % os.path.basename(sys.argv[0])

def main():
    # Command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:], "ht:")
    except:
        print "ERROR: Invalid options\n"
        usage()
        sys.exit(1)

    type = None
    for o, v in opts:
        if o == "-h":
            usage()
            sys.exit(1)
        elif o == "-t":
            type = v
    if len(args) < 1:
        print "ERROR  Invalid command line options"
        usage()
        sys.exit(1)

    infile = args[0]

    #
    # Create NcFile object
    #

    ncfile = NcFile.NcFile(infile)

    #
    # Get dimension names
    #

    if type == "time":
        timename = ncfile.get_time_dimension()
        dimnames = [timename]
    elif type == "lat":
        latname = ncfile.get_latitude_dimension()
        dimnames = [latname]
    elif type == "lon":
        lonname = ncfile.get_longitude_dimension()
        dimnames = [lonname]
    elif type == "z":
        zname = ncfile.get_z_dimension()
        dimnames = [zname]
    else:
        dimnames = ncfile.get_all_dimensions()
    dimnames.sort()
    outstring = ""
    for dimnm in dimnames:
        if dimnm is not None:
            outstring = outstring + dimnm + " "
    print outstring

    exit(0)


if __name__ == "__main__":
    main()

