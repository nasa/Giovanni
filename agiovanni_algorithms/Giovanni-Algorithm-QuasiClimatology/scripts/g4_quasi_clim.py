#!/usr/bin/env python
"""Quasi Climatology algorithm for G4.

Another term for quasi climatology is user-defined climatology. A climatology
comes in two flavors-- for a month or for a season.

The climatology over the month of January from 1990 to 2015 is defined as:
  Avg( Jan1990, Jan1991, ... Jan2015 )

The climatology over the season MAM (Mar, Apr, May) from 1990 to 2015 is
defined as:
  Avg( Mar1990, Apr1990, May1990,
       Mar1991, Apr1991, May1991,
       ...
       Mar2015, Apr2015, Apr2015 )

If any of the months in an instance of a season are missing, that entire
seasonal instance is excluded.
"""
__author__ = 'Daniel da Silva <Daniel.e.daSilva@nasa.gov>'

import subprocess
import sys
import tempfile

import agiovanni.alg
import agiovanni.mfst


def main(argv, stdout):
    """Main function of the algorithm."""
    opts = agiovanni.alg.parse_cli_args(argv)
    
    groupType, groupVal = opts.g.split('=')
    stdout.write('Preparing climatology for %s...' % groupVal)
    stdout.flush()

    # If group type is SEASON, drop collections of seasons that contain missing
    # months. This is outsources to seasonDropper.py which reads a file list and
    # writes another.
    # --------------------------------------------------------------------------
    if groupType == 'MONTH':
        fileList = opts.f
    elif groupType == 'SEASON':        
        fileListHandle = tempfile.NamedTemporaryFile()
        fileList = fileListHandle.name
        subprocess.check_call([
            'seasonDropper.py',
            '-f', opts.f,
            '-o', fileList,
            '-v', opts.v,
            '-g', opts.g
        ])
    else:
        raise RuntimeError('Invalid group type', groupType)
    
    # Call the time averaged map algorithm to perform the temporal averaging.
    # Reuse all arguments from this script, with replaced -f.
    # --------------------------------------------------------------------------
    args = argv[1:]
    args[args.index('-f') + 1] = fileList
    del args[args.index('-g'):args.index('-g')+2]
    
    pipe = subprocess.Popen(['g4_time_avg.pl'] + args,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    pipe.wait()
    out, err = pipe.communicate()
    sys.stdout.write(out)
    sys.stderr.write(err)

    if pipe.returncode:
        print >>sys.stderr, "g4_time_avg.pl call failed"
        print >>sys.stderr, "was: g4_time_avg.pl", ' '.join(args)
        raise SystemExit(1)
    
    
if __name__ == '__main__':
    main(sys.argv, sys.stdout)

