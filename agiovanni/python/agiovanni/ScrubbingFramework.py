#!/usr/bin/python

'''
  A class for running a script in a multi-threaded fashion on files in the Giovanni cache.
  and logging the output of the commands. See run_cmd_and_log(cmd, logger) for more details.

  You may notice this invokes Runner.py which carries out the multi-threading
  This class creates the optionally needed varinfo file and copies and reads the <region>.db file

   typical invokation

   this = ScrubbingFramework.ScrubbingFramework(
        variable (region),
        exe (your script to run against every file in a region),
        nthreads (number of threads to use),
        [total] (subset of files you want to process (defaults to all)),
        [skip] (perhaps you ran into an error after many thousands of files were already processed),
        [readonly] (by default this class tries to change the perms on every file)
        )

    this.run()
    this.cleanup()

    Note: If you need to use an alternate cache location to what is in giovanni.cfg, 
          set the environment variable MY_CACHE
'''

__author__ = 'Richard Strub <richard.f.strub@nasa.gov>'

import threading
import tempfile
import time
import sys
import os
import re
import optparse
import shutil
import subprocess
from Runner import ThreadRunner
import logging
import uuid

exitFlag = 0


class ScrubbingFramework:

    def __init__(self, variable, exe, nthreads, total, skip, readonly):
        '''this gather's all of the various items scrubbing often needs.
        '''

        self.variable = variable  # variable to be rescrubbed
        self.exe = exe      # executable/script to be run
        self.nthreads = int(nthreads)
        self.readonly = False
        if readonly:
            self.readonly = True

        if skip is None:
            skip = 0
        # perhaps not start on the first file in the db file
        self.skip = int(skip)
        if total is None:
            total = 0
        self.total = int(total)  # only do this many altogether for now

        from agiovanni.cfg import ConfigEnvironment
        self.config_env = ConfigEnvironment()
        # Sometimes we want to point to a temporarily
        # mounted cache other than /var/giovanni/cache or whatever
        # giovanni.cfg happens to point to
        if ('MY_CACHE' in os.environ.keys()):
            self.cachedir = os.environ['MY_CACHE'] 
        else:
            self.cachedir = self.config_env.get('$GIOVANNI::CACHE_DIR')

        self.AESIR = self.config_env.get('$GIOVANNI::DATA_CATALOG')
        self.dbfile = os.path.join(self.cachedir, variable + ".db")

    # create temporary directory:
        self.workingdir = tempfile.mkdtemp()
        self.localdb = os.path.join(self.workingdir, variable + ".db")
        self._setuplogger()
    # previously scrubbed list :
        self.prevScrubbedFiles = self._getFilesUnderRegion()

    # create var info file
        self._createVarInfo()

    def _runcmd(self, cmd):
        ''' for prepatory. pre-threadrunner system cmds'''

        scmd = cmd.split(' ')
        p = subprocess.Popen(scmd, stdout=subprocess.PIPE)
        out = p.communicate()[0]
        if p.returncode == 0:
            return out.splitlines()
        else:
            print ("Unable to run command: %s" % " ", cmd)
            sys.exit(1)

    def info(object, spacing=10, collapse=1):
        """Print methods and doc strings.

        Takes module, class, list, dictionary, or string."""
        methodList = [
            method for method in dir(object) if callable(
                getattr(
                    object,
                    method))]
        processFunc = collapse and (
            lambda s: " ".join(
                s.split())) or (
            lambda s: s)
        print "\n".join(["%s %s" %
                         (method.ljust(spacing),
                          processFunc(str(getattr(object, method).__doc__)))
                         for method in methodList])


    def _getFilesUnderRegion(self):

        files = []
        topdir = self.cachedir + os.path.sep + self.variable
        cmd = "find " + topdir + " -name \\*.nc"
        files = self._shell_cmd(cmd)
        return files 

    def _shell_cmd(self,cmd):
       p = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
       out = p.communicate()[0]
       if p.returncode == 0:
          return out.splitlines()
       else:
          print ("Unable to run command: %s" % " ", cmd)
          sys.exit(1)

    def _getPreviouslyScrubbedList(self):
        ''' uses the Berkeley DB utility db_dump instead of the Perl module
            to read the <variable>.db file'''

        outlist = []
        self
    # Get db file
        shutil.copy(self.dbfile, self.localdb)

    # Get list of files in .dbfile
        self.logger.warn('ingesting ' + self.localdb + "...\n...\n")
        dumpCMD = "db_dump -p " + self.localdb
        prevScrubbedFiles = self._runcmd(dumpCMD)
        uhash = {}
        self.logger.debug( 'input list length: ' + str(len(prevScrubbedFiles)) + "\n")
        for file in prevScrubbedFiles:
            file = file.lstrip()
            jfname = os.path.basename(file)
            if not re.match(".*search.*", file):
                if file.startswith(self.variable):
                    if jfname  not in uhash.keys():
                        outlist.append(os.path.join(self.cachedir, file.rstrip()))
                        fileappears  = {jfname : 1 }
                        uhash.update(fileappears)

                    if not self.readonly:
                        status = self._adjustPermissions(outlist[-1], 'before')
                        if (status == 'remove'):
                            del outlist[-1]
        self.logger.debug( 'output list length: ' + str(len(outlist)) + "\n")
        return outlist

    def _adjustPermissions(self, scrubbedFile, context):
        ''' in addition to adjusting the permissions, this lets the files that are in the
            .db file, but not on disk slide.  This often occurs in the giovanni cache
            so it might be useful info for someone but not for scrubbed file updaters'''

        if (context == 'before'):
            try:
                os.chmod(scrubbedFile, 0o664)  # make rw
            except OSError as e:
                if e.errno == 2:
                    self.logger.info(
                        scrubbedFile +
                        " is missing which may or not be our problem\n")
                    return 'remove'
                else:
                    self.logger.error(
                        'Unable to change permissions to rw on file:' + scrubbedFile + "\n")
                    sys.exit(1)
        else:
            try:
                os.chmod(scrubbedFile, 0o444)  # restore read only
            except OSError as e:
                if e.errno == 2:
                    self.logger.info(
                        scrubbedFile +
                        " is missing which may or not be our problem\n")
                else:
                    self.logger.error(
                        'Unable to restore permissions to read only  on file:' +
                        scrubbedFile +
                        "\n")
                    sys.exit(1)

    def _restorePermissions(self, finishedRescrubbingList):
        ''' scrubbed files are usually stored as 444, so to
            update them we need to change and restore their perms'''

        for eachFile in finishedRescrubbingList:
            if not self.readonly:
                self._adjustPermissions(eachFile, 'after')

    def _createVarInfo(self):
        ''' this creates a giovanni system produced file that sometimes has
            important information for scrubbing processes
            Note it uses getDataFieldInfo.pl'''

        self.varinfo = os.path.join(self.workingdir, "varinfo.xml")
        mfst = os.path.join(self.workingdir, "mfst.data.field.xml")
    # Create manifest file:
        try:
            f = open(mfst, 'w')
            line = "<manifest><data>" + self.variable + "</data></manifest>"
            f.write(line)
            f.close()
        except:
            sys.stderr.write(
                "Unable to open " +
                mfst +
                " for write of varInfo file\n\n")
            sys.exit(1)

        cmd = "getDataFieldInfo.pl -user --user-dir /var/tmp/www/TS2/giovanni/users --in-xml-file " + \
              mfst + "  --aesir " + self.AESIR + " --datafield-info-file " + self.varinfo

        status = self._runcmd(cmd)

    def cat(self, file):
        ''' for convenience in debugging'''

        f = open(file, 'r')
        print f.readlines()
        f.close()

    def showstuff(self):
        ''' for convenience in debugging'''

        self.cat(self.varinfo)
        for file in self.prevScrubbedFiles:
            print file

    def _buildcmd(self, file):
        '''default behavior of subprocess is like system()
           in that it wants the command line as an array'''

        cmd = self.exe.split(' ')
        cmd.append('-variable')
        cmd.append(self.variable)
        cmd.append('-previouslyScrubbed')
        cmd.append(file)
        cmd.append('-workingdir')
        cmd.append(self.workingdir)
        cmd.append('-varinfo')
        cmd.append(self.varinfo)

        return cmd

    def _setuplogger(self):
        ''' the extra logging stuff like
            the name and location of the log file'''

        tmpdir = os.getenv('TMPDIR')
        loggername = os.path.basename(self.exe)
        try:
            l = loggername.index(".")
            if (l > 0):
                loggername = loggername[0:l]
        except ValueError as e:
            sys.stderr.write("that's ok if " + self.exe + " has no dot(.)\n")

        loggername += "_" + self.variable + ".log"

        loggername = os.path.join(tmpdir, loggername)
        self._setup_logger(loggername)
        print loggername

    def _setup_logger(self, log_file):
        """
        Setup logger to file and stdout
        :param log_file: location of log file
        :return: the logger
        This setup sends everything to the $TMPDIR/<exe>_<var>.log
        and only the progress and the errors to the shell
        """

        # make sure the logger has a unique name because we won't want
        # cross-talk
        logger = logging.getLogger("%s.estimator" % str(uuid.uuid4()))
        # This one, seems to
        # if set to debug, allows command STDOUT messages through, ie it
        # handdles the command's stderr/stdout output
        logger.setLevel(logging.DEBUG)

        formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s')

        if log_file is not None:
            file_handler = logging.FileHandler(log_file)

            file_handler.setFormatter(formatter)
            # this controls the log file messages
            file_handler.setLevel(logging.DEBUG)

            logger.addHandler(file_handler)

        # always write to stdout
        handler = logging.StreamHandler()

        # this controls the stdout messages
        handler.setFormatter(formatter)
        handler.setLevel(logging.WARN)

        logger.addHandler(handler)

        self.logger = logger

    def run(self):
        ''' this is the MAIN LOOP
            It builds the command from the exe passed in by the user
            as well as the default arguments
            It passes n number of commands for n number of threads
            to the threadrunner
        '''

        threadrunner = ThreadRunner(self.nthreads, self.logger)
        cmds = []
        shortlist = []
        if (self.total == 0 or self.total > len(self.prevScrubbedFiles)):
            self.total = len(self.prevScrubbedFiles)

        # If there are only a few files and the user doesn't realize:
        if (len(self.prevScrubbedFiles) < self.nthreads):
            self.nthreads = len(self.prevScrubbedFiles) - 1

        self.starttime = time.time()
        self.previoustime = self.starttime
        self.thistime = time.time()
        # Using skip and total you can do any range you want or the whole list

        for i in range(self.skip, self.total):
            cmds.append(self._buildcmd(self.prevScrubbedFiles[i]))
            shortlist.append(self.prevScrubbedFiles[i])

        threadrunner.run(cmds)

    def _handle_progress_messages(self, curr):
        ''' This provides entertaining process time information for the
            operator'''

        units = ' hours'
        sofartime = self.thistime - self.starttime
        message =  "Processed " + self.variable  + " files %3d" % (curr - self.nthreads) + \
                   " through " + "%3d" % curr + \
                   " of " + "%8d" % self.total
        message += ". time: " + \
            "%4.1f" % (self.thistime - self.previoustime) + " seconds. "
        secondsleft = (((self.total - curr) / self.nthreads)
                       * (self.thistime - self.previoustime))
        if (secondsleft > 3600 + 1800):
            secondsleft /= 3600
        elif (secondsleft > 120):
            secondsleft /= 60
            units = ' minutes'
        else:
            units = ' seconds'
        message += ("Time remaining:" + "%6d" % (int(secondsleft)) + units)
        self.logger.warn(message)

    def cleanup(self):
        ''' leaving cleanup optional for the user'''

        shutil.rmtree(self.workingdir)
