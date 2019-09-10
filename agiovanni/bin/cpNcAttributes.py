#! /bin/env python
import pdb
""" 
###############################################################
NAME
cpNcAttribute.py - Copy attributes from one nc file to another

DESCRIPTION
This program copies both global and variable attributes from
one file to another.

SYNOPSIS
cpNcAttribute.py [-h] from.nc to.nc

OPTIONS
-h      - Print usage info
from.nc - Input nc file of attributes source
to.nc   - Output nc file where attributes will be modified by copying

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 08/30/2012, Initial version

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
    print "Usage: %s [-h] from.nc to.nc" % os.path.basename(sys.argv[0])

def main():
    # pdb.set_trace()
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
    if len(args) < 2:
        print "ERROR  Invalid command line options"
        usage()
        sys.exit(1)

    fromFile = args[0]
    toFile = args[1]


    # Open files
    fh_from = Dataset(fromFile)
    fh_to = Dataset(toFile, "a", format="NETCDF3_CLASSIC")

    #
    # Copy global attributes
    #
    global_attrs = fh_from.ncattrs()
    for attrname in global_attrs:
         attrvalue = fh_from.getncattr(attrname)
         fh_to.setncattr(attrname, attrvalue)
    # Remove global "comments" attribute
    fhto_attrs = fh_to.ncattrs()
    if "comments" in fhto_attrs:
        fh_to.delncattr("comments")
    

    #
    # Copy variable attributes
    # (1) Copy attributes
    # (2) Remove "comments" attributes
    #

    vars_from = fh_from.variables
    vars = fh_to.variables
    varnames = set(fh_to.variables.keys()) - set(fh_to.dimensions.keys())
    varnames_from = vars_from.keys()
    for vn in varnames:
        if vn not in varnames_from:
            sys.stderr.write("WARNING %s not in original file\n" % (vn))
        v = vars[vn]
        v_from = vars_from[vn]
        attrnames = v_from.ncattrs()
        for aname in attrnames:
            avalue = v_from.getncattr(aname)
            #- if aname == "_FillValue":  avalue = float(avalue)
            if aname == "add_offset":  continue
            if aname == "scale_factor":  continue
            v.setncattr(aname, avalue)
        # Delete "comments" attribute
        v_attrs = v.ncattrs()
        if "comments" in v_attrs:
            v.delncattr("comments")

    #
    # Renaming dimension names
    #
    if vars.has_key('latitude'):
        v = vars['latitude']
        v.setncattr('standard_name', 'latitude')
        fh_to.renameVariable('latitude', 'lat')
        fh_to.renameDimension('latitude', 'lat')
    if vars.has_key('longitude'):
        v = vars['longitude']
        v.setncattr('standard_name', 'longitude')
        fh_to.renameVariable('longitude', 'lon')
        fh_to.renameDimension('longitude', 'lon')

    fh_from.close()
    fh_to.close()
    exit(0)


if __name__ == "__main__":
    main()

