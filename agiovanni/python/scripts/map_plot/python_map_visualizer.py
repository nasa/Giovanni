#!/bin/env python
"""
Visualize a netcdf file. Call:

    python_map_visualizer.py /path/to/data.nc /path/to/viz.png --sld /path/to/sld.xml --width 100 --height 100 --contour --world /path/to/viz.wld \
       --north 90 --south -90 --west -180 --east 180

Only the data file and output file are mandatory arguments.

"""

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import argparse
import sys
import agiovanni.map_plot as mp


def main(argv):
    description = """
    Visualize a netcdf map
    """
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument(
        "data", type=str, help="netcdf file")
    parser.add_argument("out", type=str, help="output file")
    parser.add_argument(
        "--sld", dest="sld", type=str, help="location of sld file",
        default=None)
    parser.add_argument(
        "--width", dest="width", type=int, help="image width in pixels",
        default=None)
    parser.add_argument(
        "--height", dest="height", type=int, help="image height in pixels",
        default=None)
    parser.add_argument("--north", dest="north", type=float,
                        help="north boundary of desired output bounding box.",
                        default=90)
    parser.add_argument("--south", dest="south", type=float,
                        help="south boundary of desired output bounding box.",
                        default=-90)
    parser.add_argument("--east", dest="east", type=float,
                        help="east boundary of desired output bounding box.",
                        default=180)
    parser.add_argument("--west", dest="west", type=float,
                        help="west boundary of desired output bounding box.",
                        default=-180)

    parser.add_argument(
        "--old",
        dest="old",
        action='store_true',
        help="Use the old imshow() function for visualizing.")

    parser.add_argument(
        "--contour", dest="contour", action='store_true',
        help="turn on filled contours")

    parser.add_argument(
        "--world", dest="world", type=str,
        help="output location for world file", default=None)

    parser.add_argument(
        "--variable", dest="variable_name", type=str,
        help="name of the variable to be visualized. Defaults to a plottable variable",
        default=None)

    parser.add_argument(
        "--inflation", dest="inflation_factor", type=int,
        help='factor by which each side of the image will be greater than the ' +
        'number of pixels. E.g. - if the input data file is 2x3 data points and ' +
        'the inflation is 2, the output image will be 4x6 pixels. Ignored if ' +
        'image height and/or width are set.', default=None)

    parser.add_argument(
        "--extend_for_map_server", dest="extend_for_map_server",
        action="store_true",
        help="extend the plot, if necessary, to make sure there is coverage from [-180,180)"
    )

    args = parser.parse_args(argv)

    v = mp.Visualize(
        data_file=args.data, sld=args.sld, width=args.width, height=args.height,
        variable_name=args.variable_name, north=args.north, south=args.south,
        east=args.east, west=args.west, inflation_factor=args.inflation_factor,
        extend_for_map_server=args.extend_for_map_server)

    if args.contour:
        v.contour(args.out)
    elif args.old:
        v.plot_imshow(args.out)
    else:
        v.plot(args.out)

    if args.world is not None:
        v.create_world_file(args.world)


if __name__ == "__main__":
    main(sys.argv[1:])
