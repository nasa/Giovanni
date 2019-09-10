#! /bin/env python
'''
Estimates how much space a list of variables will take in the cache. Does this 
by going to AESIR to get the product start, end time, and temporal resolution to
estimate how many granules there are. Then it calls giovanni for a simple map,
downloads a scrubbed file from lineage, and uses that for the entry size per
granule.

>> estimate_cache_size.py 'http://aesir.gesdisc.eosdis.nasa.gov/aesir_solr/' 'http://giovanni.gsfc.nasa.gov/giovanni/' list.txt

The file input file should have one AESIR id per line.

Script outputs the total number of megabytes to stdout. Intermediate status is written
to a log on stderr, unless a log file (--log-file) location is specified.

Use the --pickle option to specify a location to store intermediate results. If something
goes wrong, you can start back up again and not have to re-do all the variables you
already finished.
'''

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import sys
import json
import argparse
import urllib
import tempfile
import subprocess
import os
import requests
import datetime as dt
import calendar
from lxml import etree
import logging
import uuid
import shutil
import cPickle as pickle


class EstimateError(Exception):
    pass


def get_catalog_info(aesir_location, var_id):
    """
    Calls AESIR to get catalog information for variable var_id.
    """

    # https://aesir.gsfc.nasa.gov/aesir_solr/TS1/select/?q=*&fq=dataFieldId:%22OMTO3e_003_ColumnAmountO3%22&wt=json
    # https://aesir.gsfc.nasa.gov/aesir_solr/TS1/
    params = {'q': "*",
              'fq': 'dataFieldId:%s' % var_id,
              'wt': 'json'}

    r = requests.get("%s/select/" % aesir_location, params=params)
    return r.content


def _get_logger(log_file):
    # make sure the logger has a unique name because we won't want cross-talk
    logger = logging.getLogger("%s.estimator" % str(uuid.uuid4()))
    logger.setLevel(logging.DEBUG)

    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')

    handler = None
    if log_file is None:
        handler = logging.StreamHandler()
    else:
        handler = logging.FileHandler(log_file)

    handler.setFormatter(formatter)
    handler.setLevel(logging.DEBUG)

    logger.addHandler(handler)

    return logger


def get_file_size(base_url, start_time, end_time, var_id, logger=None):
    """
    Calls giovanniAgent.pl with a map URL and downloads the resulting data file
    to get file size.
    """
    url_query = {'service': 'TmAvMp',
                 'starttime': start_time,
                 'endtime': end_time,
                 'bbox': '-180,-90,180,90',
                 'data': var_id}
    url = "%s/#%s" % (
        base_url, urllib.urlencode(url_query))
    if logger is not None:
        logger.info("     Getting scrubbed files calling URL %s" % url)

    dir_ = tempfile.mkdtemp()
    cmd = ('giovanniAgent.pl', '--url', url,
           '--dir', dir_, '--type', 'lineage_xml')
    ret = subprocess.call(cmd)
    if ret != 0:
        raise EstimateError('Command returned non-zero: %s' % " ".join(cmd))

    xml_file = os.path.join(dir_, 'lineage.xml')

    scrubbed_files_info = get_scrubbed_urls(xml_file)

    shutil.rmtree(dir_)
    if len(scrubbed_files_info) == 0:
        raise EstimateError(
            "Unable to retrieve any scrubbed files out of the lineage")

    # download a scrubbed file
    r = requests.get(scrubbed_files_info[0])
    content = r.content
    return len(content)


def get_scrubbed_urls(lineage_file):
    doc = etree.parse(lineage_file)

    nodes = doc.xpath(
        '/provenance/group[@name="data_fetch"]/step/outputs/output')

    scrubbedUrls = [node.text for node in nodes]

    return scrubbedUrls


def get_num_slices(start_date_time, end_date_time, temporal_resolution,
                   today=dt.datetime.today()):
    """
    Figure out approximately how many slices there are for a data product. Takes
    the start time, end time, and temporal resolution of the data
    """

    if(end_date_time > today):
        end_date_time = today

    if temporal_resolution == 'monthly':
        return 12 * (end_date_time.year - start_date_time.year + 1) \
            - (start_date_time.month - 1) - (12 - end_date_time.month)

    delta = end_date_time - start_date_time

    totalSeconds = delta.days * 24 * 60 * 60 + delta.seconds + 1
    if temporal_resolution == 'half-hourly':
        return int(2 * totalSeconds / (60.0 * 60.0))
    elif temporal_resolution == 'hourly':
        return int(totalSeconds / (60.0 * 60.0))
    elif temporal_resolution == '3-hourly':
        return int(totalSeconds / (60.0 * 60.0 * 3.0))
    elif temporal_resolution == 'daily':
        return delta.days + 1
    else:
        raise EstimateError(
            "Unknown temporal resolution %s" % temporal_resolution)


def get_one_slice_end_time(start_date_time, temporal_resolution):
    """
    Calculate a start and end time that should work with search and get us
    one file
    """
    if temporal_resolution == 'monthly':
        if start_date_time.month == 12:
            year = start_date_time.year + 1
            month = 1
        else:
            year = start_date_time.year
            month = start_date_time.month + 1

        end_day = calendar.monthrange(year, month)[1]
        if start_date_time.day > end_day:
            day = end_day
        else:
            day = start_date_time.day

        return dt.datetime(year, month, day, start_date_time.hour,
                           start_date_time.minute, start_date_time.second)

    elif temporal_resolution == 'daily':
        return start_date_time + dt.timedelta(days=1)
    elif temporal_resolution == '3-hourly':
        return start_date_time + dt.timedelta(hours=3)
    elif temporal_resolution == 'hourly':
        return start_date_time + dt.timedelta(hours=1)
    elif temporal_resolution == 'half-hourly':
        return start_date_time + dt.timedelta(minutes=30)
    else:
        raise EstimateError(
            "Unknown temporal resolution %s" % temporal_resolution)


def _do_one_variable(logger, args, var_id, info_getter, get_file_size):
    # get catalog info
    logger.info("  Getting catalog information from AESIR ...")
    try:
        aesir_info = info_getter(args.aesir_location, var_id)
        info = json.loads(aesir_info)
    except EstimateError:
        logger.error("*****************************")
        logger.error("Unable to get AESIR information")
        logger.error("*****************************")
        raise

    if len(info['response']['docs']) == 0:
        logger.error("*****************************")
        logger.error("Unable to get AESIR information for %s" % var_id)
        logger.error("*****************************")
        raise EstimateError("AESIR did not return results for %s" % var_id)

    logger.info("  ... Got catalog information from AESIR")

    # get out useful parameters
    start_time_string = info['response'][
        'docs'][0]['dataProductBeginDateTime']
    start_time_string = start_time_string[0:18]
    logger.info("    Start time: %s" % start_time_string)
    start_date_time = dt.datetime.strptime(
        start_time_string, '%Y-%m-%dT%H:%M:%S')

    end_time_string = info['response']['docs'][0]['dataProductEndDateTime']
    end_time_string = end_time_string[0:18]
    logger.info("    End time: %s" % end_time_string)
    end_date_time = dt.datetime.strptime(
        end_time_string, '%Y-%m-%dT%H:%M:%S')

    temporal_resolution = info['response'][
        'docs'][0]['dataProductTimeInterval']
    logger.info("    Temporal resolution: %s" % temporal_resolution)

    # figure out how many slices (approximately) of data there will be
    num_slices = get_num_slices(
        start_date_time, end_date_time, temporal_resolution)

    logger.info("    Number of slices calculated: %d" % num_slices)

    # bump up the start time by a day so we don't run into edge issues
    search_start_date_time = start_date_time + dt.timedelta(days=1)

    # figure out a time range that should be just a single time slice
    (search_end_date_time) = \
        get_one_slice_end_time(
            search_start_date_time, temporal_resolution)

    # convert times to strings
    search_start_string = "%04d-%02d-%02dT%02d:%02d:%02dZ" %\
        (search_start_date_time.year,
         search_start_date_time.month,
         search_start_date_time.day,
         search_start_date_time.hour,
         search_start_date_time.minute,
         search_start_date_time.second)

    search_end_string = "%04d-%02d-%02dT%02d:%02d:%02dZ" %\
        (search_end_date_time.year,
         search_end_date_time.month,
         search_end_date_time.day,
         search_end_date_time.hour,
         search_end_date_time.minute,
         search_end_date_time.second)

    logger.info("  About to run query for times %s - %s..." %
                (search_start_string, search_end_string))

    # figure out how big one scrubbed file is (approximately)
    try:
        bytes_ = get_file_size(
            args.giovanni_url, search_start_string, search_end_string, var_id,
            logger)
    except EstimateError:
        logger.error("*****************************")
        logger.error(
            "Unable to get download scrubbed file information for %s" % var_id)
        logger.error("*****************************")
        raise

    logger.info("  ... ran query")
    logger.info("    Got scrubbed file of size %d bytes" % bytes_)

    bytes_for_var = bytes_ * num_slices
    logger.info("  Total bytes for %s: %d" % (var_id, bytes_for_var))
    return bytes_for_var


def main(argv, stdout, info_getter=get_catalog_info, get_file_size=get_file_size):
    """
    Implements main.
    """

    description = """
    Calculate the approximate number of bytes needed to cache variables
    """
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument(
        "aesir_location", type=str,
        help="base path to AESIR catalog. " +
        "E.g. - 'http://aesir.gesdisc.eosdis.nasa.gov/aesir_solr/TS2/'")
    parser.add_argument(
        "giovanni_url", type=str, help="location of giovanni")
    parser.add_argument(
        "input_file", type=str,
        help="location of text file with variable list, one AESIR id per line")
    parser.add_argument("--pickle-file", dest="pickle", default=None,
                        help='location of pickle file with partial results')
    parser.add_argument("--log-file", dest='log_file', default=None,
                        help='location of optional log file, which will get intermediate status')

    args = parser.parse_args(argv)

    logger = _get_logger(args.log_file)
    logger.info("Using AESIR location %s" % args.aesir_location)
    logger.info("Using giovanni %s" % args.giovanni_url)

    # parse the input file
    handle = open(args.input_file, "r")
    var_ids = handle.readlines()
    handle.close()

    var_ids = [var_id.rstrip() for var_id in var_ids]

    if args.pickle is not None and os.path.exists(args.pickle):
        handle = open(args.pickle, 'r')
        partialResults = pickle.load(handle)
        handle.close()
        total_megabytes = sum(partialResults.itervalues())
        logger.info("-----------------------------------------")
        logger.info('Total megabytes from pickle: %d' % total_megabytes)
        logger.info("-----------------------------------------")

    else:
        partialResults = {}
        total_megabytes = 0.0

    for i in range(len(var_ids)):

        var_id = var_ids[i]
        logger.info(
            "Processing variable %s (%d of %d)" % (var_id, i + 1, len(var_ids)))

        if var_id not in partialResults:
            try:
                bytes_for_var = _do_one_variable(
                    logger, args, var_id, info_getter, get_file_size)

                megabytes = bytes_for_var / (1.0e6)
                partialResults[var_id] = megabytes

                if args.pickle is not None:
                    handle = open(args.pickle, 'w')
                    pickle.dump(partialResults, handle)

                total_megabytes += megabytes
                logger.info("-----------------------------------------")
                logger.info('Total megabytes so far: %d' % total_megabytes)
                logger.info("-----------------------------------------")
            except EstimateError:
                logger.error("Unable to process %s" % var_id)

    stdout.write("%G\n" % total_megabytes)

if __name__ == "__main__":
    main(argv=sys.argv[1:], stdout=sys.stdout)
