#! /bin/env python

""" 
####################################################################
NAME
scatterPlot.py - Scatter plot using IDL

DESCRIPTION
This is an IDL wrapper for scatter plots.

SYNOPSIS
scatterPlot.py [-h] [--verbose] [--debug] -i <in.nc> -o <out.png> 
               -f <optionfile>

OPTIONS
-h         - Print usage info
--verbose  - Verbose mode
--debug    - Debug mode
in.nc      - Input nc file
out.png    - Output png file
optionfile - Plot options in a text file

DEPENDENCY
netCDF4

AUTHORS
Jianfu Pan, 09/15/2012, Initial version

VERSION
$Revision: 1.16 $
####################################################################
""" 

import sys
import os
import subprocess
import getopt
import fileinput
from netCDF4 import Dataset
import NcFile
import pdb
import re

#
# Environment setup
#

# Turn off stdout buffering
unbuffered = os.fdopen(sys.stdout.fileno(), 'w', 0)
sys.stdout = unbuffered

def usage():
    print "Usage: %s [-h] [--verbose] [--debug] -i <in.nc> -o <out.png> -f <optionfile>" % os.path.basename(sys.argv[0])

def get_plotoption(optionfile):
    options = {}
    for rec_str in fileinput.input(optionfile):
        rec_str = rec_str.strip()
        rec = rec_str.split('=')
        if len(rec) != 2:
            print "ERROR Invalid item %s in option file" % (rec)
            exit(-1)
        else:
            attrs = rec[0].split(':')
            if len(attrs) == 2:
                if options.has_key(attrs[0]):
                    options[attrs[0]].update({attrs[1] : rec[1]})
                else:
                    options[attrs[0]] = {attrs[1] : rec[1]}
            else:
                print "WARN Option item %s not recognized" % (rec[0])
    return options

def get_varnames(fh,has_attr=[]):
    dimnames = fh.dimensions.keys()
    vars = fh.variables
    varnames = vars.keys()

    varnames = list(set(varnames) - set(dimnames))
    varnames.sort()

    # The varnames that satisfy condition
    if has_attr:
        varnames_valid = []
        for vn in varnames:
            failed = 0
            for att in has_attr:
                try: vars[vn].getncattr(att)
                except:
                    print "WARN %s doesn't have attribute %s" % (vn,att)
                    failed = 1
                    break
            if failed: continue
            else:  varnames_valid.append(vn)
        varnames = varnames_valid

    print "INFO varnames: ", varnames
    if len(varnames) < 2:
        print "ERROR Not enough variables in infile"
        exit(-1)
    return varnames[0],varnames[1]

def main():
    mypath = os.path.dirname(sys.argv[0])
    # Command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hvdDi:o:f:")
    except:
        print "ERROR: Invalid options\n"
        usage()
        sys.exit(1)

    debug,verbose = 0,0
    infile,outfile,optionfile = None,None,None
    for o, v in opts:
        if o == "-h":
            usage()
            sys.exit(1)
        elif o == "-D":
            pdb.set_trace()
        elif o == "-v":
            verbose = 1
        elif o == "-d":
            debug = 1
        elif o == "-i":
            infile = v
        elif o == "-o":
            outfile = v
        elif o == "-f":
            optionfile = v
        else:
            print "ERROR: Invalid options\n"
            usage()
            sys.exit(1)

    if infile is None:
        print "ERROR: Input nc file missing"
        usage()
        sys.exit(1)
    if outfile is None:
        print "ERROR: Output file path is missing"
        usage()
        sys.exit(1)
    useroptions = {}
    if optionfile:
        useroptions = get_plotoption(optionfile)
        print "INFO Plot options =", useroptions

    outfile = outfile+".png"

    #
    # Get info from input nc file
    #


    fh = Dataset(infile)
    xvname, yvname = get_varnames(fh,['quantity_type'])
    fh.close()
    nc = NcFile.NcFile(infile)
    v_shape = nc.shape(xvname)
    #- region_label = nc.get_region_label()
    #- time_label = infile.split('.')[-3]
    xmin = nc.get_min_value(xvname)
    xmax = nc.get_max_value(xvname)
    ymin = nc.get_min_value(yvname)
    ymax = nc.get_max_value(yvname)
    xlongname = nc.get_attribute('long_name', xvname)
    ylongname = nc.get_attribute('long_name', yvname)
    xunits = nc.get_attribute('units', xvname)
    yunits = nc.get_attribute('units', yvname)
    xqtype = nc.get_attribute('quantity_type', xvname)
    yqtype = nc.get_attribute('quantity_type', yvname)
    title = nc.get_attribute('plot_hint_title')
    subtitle = re.sub( r'\n', '!C', nc.get_attribute('plot_hint_subtitle') )

    xplothintaxis = nc.get_attribute('plot_hint_axis_title', xvname)
    yplothintaxis = nc.get_attribute('plot_hint_axis_title', yvname)
    if xplothintaxis is None:
        if xlongname:  xplothintaxis = xlongname
        else:          xplothintaxis = xvname
    if yplothintaxis is None:
        if ylongname:  yplothintaxis = ylongname
        else:          yplothintaxis = yvname

    # --- Reset min/max to be the same for same units same qtype ---
    print "Data(x) %s:min/max=" % (xvname),xmin,xmax
    print "Data(y) %s:min/max=" % (yvname),ymin,ymax
    if xunits == yunits and xqtype == yqtype:
        if xmin < ymin:  ymin = xmin
        else:            xmin = ymin
        if xmax > ymax:  ymax = xmax
        else:            xmax = ymax
        print "Reset(x) %s:min/max=" % (xvname),xmin,xmax
        print "Reset(y) %s:min/max=" % (yvname),ymin,ymax

    # --- Plot options from data ---
    plotoptions = {xvname:{'min':xmin, 'max':xmax}, yvname:{'min':ymin,'max':ymax}}
    print "INFO Data min.max",xmin,xmax,ymin,ymax

    # --- Update plot options with user options ---
    plotoptions.update(useroptions)

    # --- Output plot options ---
    print "options=\n", \
          "%s:label=X:%s\n" % (xvname,xplothintaxis), \
          "%s:min=" % (xvname),plotoptions[xvname]['min'], "\n",\
          "%s:max=" % (xvname),plotoptions[xvname]['max'], "\n",\
          "%s:label=Y:%s\n" % (yvname,yplothintaxis), \
          "%s:min=" % (yvname),plotoptions[yvname]['min'], "\n",\
          "%s:max=" % (yvname),plotoptions[yvname]['max'], "\n",\
          "endOptions"

    xmin = float(plotoptions[xvname]['min'])
    xmax = float(plotoptions[xvname]['max'])
    ymin = float(plotoptions[yvname]['min'])
    ymax = float(plotoptions[yvname]['max'])

    cmd = "idl -rt=%s/scatterplot_main.sav -args 0 %s %s %s %s %s %f %f %f %f '%s' '%s' '%s' '%s'" % (mypath,infile,outfile,xvname,yvname,v_shape,xmin,xmax,ymin,ymax,title,subtitle,xplothintaxis,yplothintaxis)
    rc = os.system(cmd)
    print "INFO IDL command: ", cmd,rc
    if rc:
        print "ERROR: Fail to execute idl command"
        exit(-1)
    
    if not os.path.exists(outfile):
        #- os.system("touch " + outfile)
        print "WARN No output file produced"
    else:
        print "OUTPUT %s" % (outfile)

    exit(0)


if __name__ == "__main__":
    main()

