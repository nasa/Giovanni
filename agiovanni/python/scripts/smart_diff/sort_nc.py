#!/usr/bin/env python

"""
Sorts a netcdf file so the variables and attributes are in a consistent
alphabetical order. Useful for comparison if you don't care about order.
"""

import argparse
import sys
from agiovanni import smartdiff

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"


def main(argv):
    parser = argparse.ArgumentParser(
        description="Creates a sorted netcdf file")
    parser.add_argument("in_nc", help="input netcdf file")
    parser.add_argument("out_nc", help="output netcdf file")
    parser.add_argument(
        "--remove-nco",
        "-n",
        dest="remove_nco",
        action="store_true",
        help="Remove NCO metadata (history, NCO version, etc.) while sorting")
    desc = "Remove attribute from output file. Format is " +\
        "-r 'var_name/attribute_name' or -r '/global_attribute_name'."
    parser.add_argument("--remove-attribute", '-r', dest="attribute",
                        action='append', help=desc, default=[])

    args = parser.parse_args(argv)

    remove = {}
    for att in args.attribute:
        if "/" not in att:
            raise Exception(
                "Expected removed attribute string to include '/'. Got '%s'." %
                att)
        key, value = att.split("/")
        if key in remove:
            remove[key].append(value)
        else:
            remove[key] = [value]

    smartdiff.sort_nc(args.in_nc, args.out_nc, remove_nco=args.remove_nco,
                      remove=remove)

if __name__ == "__main__":
    main(sys.argv[1:])
