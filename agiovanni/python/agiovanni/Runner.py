#!/usr/bin/env python

'''
Functions and classes for running external commands in a pool of threads and logging the output of the commands. See run_cmd_and_log(cmd, logger) for more details.
'''


__author__ = 'Christine Smit <christine.e.smit@nasa.gov'


import argparse
import os
import sys
import logging
import uuid
import re
import tempfile
import shutil
import subprocess
import time
import threading


class MSUException(Exception):
    pass


def setup_logger(log_file):
    """
    Setup logging overall,
           to the log file,
           and to stdout
    :param log_file: location of log file
    :return: the logger
    """
    # make sure the logger has a unique name because we won't want cross-talk
    logger = logging.getLogger("%s.estimator" % str(uuid.uuid4()))
    logger.setLevel(logging.DEBUG)

    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')

    if log_file is not None:
        file_handler = logging.FileHandler(log_file)

        file_handler.setFormatter(formatter)
        file_handler.setLevel(logging.DEBUG)

        logger.addHandler(file_handler)

    # always write to stdout
    handler = logging.StreamHandler()

    handler.setFormatter(formatter)
    handler.setLevel(logging.DEBUG)

    logger.addHandler(handler)

    return logger


def run_cmd_and_log(cmd, logger):
    """
    Run and command and log its output. Returns
    :param cmd: command to run (list)
    :param logger: logger for command output
    """
    logger.debug("About to call %s" % cmd)

    # I can't seem to find a better way of doing this, which is irritating. Basically, the process running the
    # command will write stdout and stderr to files. Meanwhile, other code will read these files and write the stuff
    # in them out to a log. There doesn't seem to be a way to consume stderr and stdout streams directly from the
    # process unless you wait for the process to end first.
    dir_ = tempfile.mkdtemp(prefix="run_cmd")
    stdout_file = os.path.join(dir_, "stdout.txt")
    stderr_file = os.path.join(dir_, "stderr.txt")

    with open(stdout_file, 'w') as out:
        with open(stderr_file, 'w') as err:
            # start the process
            p = subprocess.Popen(
                cmd,
                stdout=out,
                stderr=err)

            _read_while_running(stdout_file, stderr_file, logger, p)
            ret = p.returncode

    shutil.rmtree(dir_)

    if ret != 0:
        logger.error("Command returned %d" % ret)
        raise MSUException("Command failed: %s" % " ".join(cmd))


def _read_while_running(stdout_file, stderr_file, logger, process):
    """
    Helper function to read a file with stdout and a file with stderr as they are being written by a process. Returns
    when process is finished.

    :param stdout_file: file the process is writing stdout to
    :param stderr_file: file the process is writing stderr to
    :param logger: logger for command output
    :param process: process that is running
    """
    # open the stdout and stderr files
    with open(stdout_file, 'r') as out_handle:
        with open(stderr_file, 'r') as err_handle:

            process_done = False
            while process_done is False:
                # try reading from stderr
                done_with_err = False
                while not done_with_err:
                    where_err = err_handle.tell()
                    line = err_handle.readline()
                    if not line:
                        done_with_err = True
                        err_handle.seek(where_err)
                    else:
                        logger.error(line[0:-1])

                # read from stdout
                done_with_out = False
                while not done_with_out:
                    where_out = out_handle.tell()
                    line = out_handle.readline()
                    if not line:
                        done_with_out = True
                        out_handle.seek(where_out)
                    else:
                        logger.debug(line[0:-1])

                # check to see if the process is finished
                if process.poll() is None:
                    # not done, so sleep
                    time.sleep(1)
                else:
                    # done!
                    process_done = True

            # read anything remaining out of the file
            for line in err_handle:
                logger.error(line[0:-1])

            for line in out_handle:
                logger.debug(line[0:-1])


class ThreadRunner:
    """
    Runs a bunch of commands in the specified number of threads.
    """

    def __init__(self, num_threads, logger):
        """
        :param num_threads: number of threads to use
        :param logger: logger for command output
        """
        self.num_threads = num_threads
        self.logger = logger

    def run(self, commands):
        """
        Run the commands using available threads. Return when done.
        :param commands: A list of commands. Each command should be a list. E.g. - [['ls','-l'],['pwd']]
        """
        threads = set()
        command_counter = 0

        # we are basically going to run the commands as threads become
        # available until all commands have run
        while command_counter < len(commands):
            # go through the threads and remove any that are done
            self._tidy_threads(threads, commands)

            # while there are commands to be run and there are threads
            # available, start new commands
            while command_counter < len(commands) and len(
                    threads) < self.num_threads:
                thread = CommandRunner(
                    command_counter + 1,
                    self.logger,
                    commands[command_counter])
                self.logger.debug(
                    "*** Started thread with command %d of %d: %s ***" %
                    (command_counter + 1, len(commands), commands[command_counter]))
                thread.start()
                threads.add(thread)
                command_counter += 1

            # give the threads a chance to do something
            time.sleep(1)

        # the last command has started. So wait until all the threads are done.
        while len(threads) > 0:
            self._tidy_threads(threads, commands)
            time.sleep(1)

    def _tidy_threads(self, threads, commands):
        done_threads = []
        for thread in threads:
            if not thread.isAlive():
                thread.join()
                done_threads.append(thread)

        for thread in done_threads:
            threads.remove(thread)
            self.logger.debug(
                "*** Thread finished with command %d of %d: %s ***" %
                (thread.id, len(commands), commands[thread.id - 1]))


class CommandRunner (threading.Thread):
    """
    Runs a command and logs it's output.
    """

    def __init__(self, id_, logger, command):
        """
        Create a runner.
        :param id_: id for log
        :param logger: log for command output and messages
        :param command: command to run
        """
        threading.Thread.__init__(self)
        self.id = id_
        self.logger = _ThreadLogger(id_, logger)
        self.command = command

    def run(self):
        run_cmd_and_log(self.command, self.logger)


class _ThreadLogger:
    """
    This is a stupid class that just pre-pends the command id to every log message for multi-threading. It feels to me
    as though there has to be a better way of doing this. This class feels very java-ish.
    """

    def __init__(self, id_, logger):
        self.id = id_
        self.logger = logger

    def _format(self, msg):
        return "-- Command %.3d -- %s" % (self.id, msg)

    def debug(self, msg):
        self.logger.debug(self._format(msg))

    def info(self, msg):
        self.logger.info(self._format(msg))

    def warn(self, msg):
        self.logger.warn(self._format(msg))

    def error(self, msg):
        self.logger.error(self._format(msg))
