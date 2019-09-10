#!/usr/bin/python

import threading
import tempfile
import time
import sys
import os
import optparse
import shutil
import subprocess
from agiovanni import ScrubbingFramework


""" This client software invokes ScrubbingFramework.py and Runner.py to run an arbitrary command on every file in a cache region
(note region is the variable name)
For better or worse this framework does these things no matter what:
Reads giovanni.cfg for AESIR and CACHE_DIR
Creates a temporary directory
Copies the <region>.db file there
Creates a varinfo file from AESIR and puts it in the temp dir
Reads through the .db file: (using db_dump)
    Checks to see if the file exists
    if it exists it adds it to the list of files
    runs your program once for every file in this list
It runs whatever program you provide one the command line with these options:
<your exe> -variable region  -previouslyScrubbed <each scrubbed file> -workingdir <the tempdir it created>  -varinfo <tempdir/varinfo.xml>

It is invoked with:
runCommandOnScrubbedFiles.py -e <your exe> -n <nthreads> -v <region> -s <nfiles to skip>
examples:
python runCommandOnScrubbedFiles.py -e timeBoundsScrubber.pl -n 50 -v GLDAS_NOAH025_3H_2_0_Qsm_acc
python runCommandOnScrubbedFiles.py -e myncatted.csh -n 50 -v GLDAS_NOAH025_3H_2_0_Qsm_acc

The first example is a fairly interesting script which uses the varinfo information, temporary directory to update the scrubbed files.
As the second example implies, you can use this framework just to do a little update on every file.
However because of the built in command line arguments, you need to wrap your, in this case ncatted, command in a script:

#!/bin/csh

set variable = $2
set file = $4
ncatted -h -O -a "positive,$variable,o,c,up"  $file

This wrapper enables the command line parameters to be shoe-horned into the ncatted syntax::
   ncatted -h -O -a "positive,GLDAS_NOAH025_3H_2_0_Qsm_acc,o,c,up"  $file


Use cases:
   python runCommandOnScrubbedFiles.py -e timeBoundsScrubber.pl -n 50 -v GLDAS_NOAH025_3H_2_0_Qsm_acc
      This, among other things, adds a previously non-existent lat_bnds variable
      runCommandOnScrubbedFiles.py -e timeBoundsScrubber.pl -n 100 -v AIRX3STD_006_GPHeight_D

   python runCommandOnScrubbedFiles.py -e myncatted.csh -n 50 -v GLDAS_NOAH025_3H_2_0_Qsm_acc -r 1
          ncatted -h -O -a "positive,$variable,o,c,up"  $file

   python runCommandOnScrubbedFiles.py -e myncdump.csh -n 50 -v GLDAS_NOAH025_3H_2_0_Qsm_acc -r 1
      this script runs ncdump and prints all kinds of errors if lat_bnds does not exist
          set file = $4
          ncdump -h $file | grep lat_bnds
   python runCommandOnScrubbedFiles.py -e "myncdump.csh -h" -n 50 -v GLDAS_NOAH025_3H_2_0_Qsm_acc -r 1
      You can put your own parameters with your executable if enclosed in quotes
         set file = $5
         ncdump -h $file | grep lat_bnds

The logging:
   The logging is set up so that only the progress and the errors go to your screen. If you want to see everything,
   refer to the log: $TMPDIR/<executable>_<region>.log


EXAMPLE:
~/public_html/giovanni4/bin/runCommandOnScrubbedFiles.py -e timeBoundsScrubber.pl -n 100 -v AIRX3STD_006_GPHeight_D
(To enable this to run, my executable timeBoundsScrubber.pl is already in .../giovanni4/bin,
 my giovanni.cfg CACHE_DIR is pointing to /var/scratch/rstrub/cache which contains AIRX3STD_006_GPHeight_D and AIRX3STD_006_GPHeight_D.db
 copied over from giovann4sc)

 A slightly more flexible case can be run using the wrapper described above
~/public_html/giovanni4/bin/runCommandOnScrubbedFiles.py -e myncdump.csh -n 100 -v AIRX3STD_006_GPHeight_D -r 1

"""


def parse_cli_args(args):
    """Parses command line arguments.

    Returns
      options, an object whose attributes match the values of the
      specified in the command line. e.g. '-e xyz' <=> cli_opts.e
    Raises
      OptionError, error parsing options
      ValueError, invalid or missing argument
    """
    parser = optparse.OptionParser()

    parser.add_option("-s", metavar="SKIP", dest="s",
                      help="Start at ith file in .dbfile (int)", type='int')
    parser.add_option("-t", metavar="TOTAL", dest="t",
                      help="How many in total (must be greater than skipped or leave it out)", type='int')
    parser.add_option("-e", metavar="executable", dest="e",
                      help="The Script you would like to run on every file in a cache (variable) region")
    parser.add_option("-n", metavar="THREADS", dest="n", type='int',
                      help="How many concurrent threads")
    parser.add_option("-v", metavar="VARIABLE", dest="v",
                      help="Variable name in input dataset")
    parser.add_option("-r", metavar="READONLY", dest="r",
                      help="I'm doing a read only operation (toggle flag)")

    cli_opts, _ = parser.parse_args(args)

    # Verify required are present and not empty
    for required_opt in "nve":
        if not getattr(cli_opts, required_opt, None):
            parser.print_help()
            raise ValueError("-%s missing" % required_opt)

    return cli_opts


# This is a little thing I found which prints out a log of info about any
# object you pass it
def info(object, spacing=10, collapse=1):
    """Print methods and doc strings.

    Takes module, class, list, dictionary, or string."""
    methodList = [
        method for method in dir(object) if callable(
            getattr(
                object,
                method))]
    processFunc = collapse and (lambda s: " ".join(s.split())) or (lambda s: s)
    print "\n".join(["%s %s" %
                     (method.ljust(spacing),
                      processFunc(str(getattr(object, method).__doc__)))
                     for method in methodList])


def main(argv, output_stream=sys.stdout):
    cli_opts = parse_cli_args(argv[1:])
    variable = cli_opts.v
    exe = cli_opts.e
    nthreads = cli_opts.n
    skip = cli_opts.s
    total = cli_opts.t
    readonly = cli_opts.r

    this = ScrubbingFramework.ScrubbingFramework(
        variable, exe, nthreads, total, skip, readonly)
    # this.showstuff()

    this.run()
    this.cleanup()


if __name__ == '__main__':
    main(sys.argv)
