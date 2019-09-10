#!/bin/env python
"""Drops incomplete seasons from a file list.

Seasonal algorithms operate on one season at a time, and should not include
instances of a season where one of the months is missing. This script removes
such instances.
"""
__author__ = 'Daniel da Silva <Daniel.e.daSilva@nasa.gov>'

import optparse
import sys

import netCDF4 as nc

import agiovanni.alg


def getMonthAndYear(ncFile):
    dataset = nc.Dataset(ncFile)
    datamonth = dataset.variables['datamonth'][0]
    year = str(datamonth)[0:4]
    month = str(datamonth)[-2:]
    dataset.close()

    return {'month': month, 'year': year}


def main(argv, stdout, stderr, getMonthAndYear=getMonthAndYear):
    """Returns number of files dropped"""
    # Parse command line arguments and assert none are missing.
    parser = optparse.OptionParser()
    parser.add_option('-f', metavar='INPUT', dest='f',
                      help='Input file list')
    parser.add_option('-g', metavar='GROUP', dest='g',
                      help="Group in TYPE=VAL form")
    parser.add_option('-o', metavar='OUTPUT', dest='o',
                      help='Output file list')
    parser.add_option('-v', metavar='VARIABLE', dest='v',
                      help='Variable')

    opts = parser.parse_args(argv)[0]

    if not all([opts.g, opts.f, opts.o]):
        raise RuntimeError('Missing options')

    # read inputs
    ncInputs = agiovanni.alg.read_file_list(opts.f)

    # figure out what kind of groups we are dealing with
    groupType, groupValRaw = opts.g.split('=')

    if groupType == 'MONTH':
        # don't need to filter months
        agiovanni.alg.write_file_list(opts.o, ncInputs)
        stderr.write('Done, dropped 0')
        stderr.flush()
        return 0

    ncOutputs = []
    ncHold = {}
    for ncInput in ncInputs:
        # get the year and month
        dateInfo = getMonthAndYear(ncInput)

        if groupValRaw == 'DJF' and dateInfo['month'] == '12':
            # put this in the next year's bin
            year = str(int(dateInfo['year']) + 1)
        else:
            year = dateInfo['year']

        if year not in ncHold:
            ncHold[year] = [ncInput]
        else:
            ncHold[year].append(ncInput)

        # see if we've gotten all the files for this year
        if len(ncHold[year]) == 3:
            ncOutputs.extend(ncHold[year])
            del ncHold[year]

    # count how many entries never had complete years
    numDropped = 0
    for year in ncHold:
        numDropped += len(ncHold[year])

    agiovanni.alg.write_file_list(opts.o, ncOutputs)

    stderr.write('Done, dropped %d' % numDropped)
    stderr.flush()

    return numDropped


if __name__ == '__main__':
    main(sys.argv, sys.stdout, sys.stderr)
