#!/bin/env python
import sys
import argparse

from agiovanni.nc_helper import remove_nans


def main(argv):
    args = parse_args(argv)
    remove_nans(args.in_file, args.out_file, args.variable)


def parse_args(argv):
    description = """
    Replace NaN values in variable with _FillValue
    """
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument(
        "in_file", type=str, help="input netcdf file")
    parser.add_argument("out_file", type=str, help="output netcdf file")
    parser.add_argument("variable", type=str, help="variable to modify")

    return parser.parse_args(argv)


if __name__ == "__main__":
    main(sys.argv[1:])
