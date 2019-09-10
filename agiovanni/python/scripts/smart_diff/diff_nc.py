#!/usr/bin/env python
"""
Differences two netcdf files. Ignores variables and attribute order in the
files.
"""

import argparse
from agiovanni import smartdiff
import sys

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"


def main(argv, out):
    parser = argparse.ArgumentParser(description="Diffs two netcdf files")
    parser.add_argument("first_nc", help="input netcdf file")
    parser.add_argument("second_nc", help="input netcdf file")
    parser.add_argument(
        "--ignore-nco", "-n",
        dest="ignore_nco",
        action="store_true",
        help="Ignore nco metadata during during comparisons "
             + "(history, NCO version, etc.)")
    desc = "Ignore attributes during diff. Format is " +\
        "-i 'var_name/attribute_name' or -i '/global_attribute_name'."
    parser.add_argument("--ignore-attribute", '-i', dest="attribute",
                        action='append', help=desc, default=[])

    args = parser.parse_args(argv)

    ignore = {}
    for att in args.attribute:
        if "/" not in att:
            raise Exception(
                "Expected ignored attribute string to include '/'. Got '%s'." %
                att)
        key, value = att.split("/")
        if key in ignore:
            ignore[key].append(value)
        else:
            ignore[key] = [value]

    diff_out = smartdiff.diff_nc(
        args.first_nc,
        args.second_nc,
        ignore_nco=args.ignore_nco,
        ignore=ignore)

    for line in diff_out:
        out.write("%s\n" % line)


if __name__ == "__main__":
    main(sys.argv[1:], sys.stdout)
