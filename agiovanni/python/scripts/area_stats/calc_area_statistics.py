#!/bin/env python
"""
Calculate area statistics on a single slice of data. By default, the min, max,
count of data points involved in the calculation, weighted average, and
standard deviation are calculated.

If no weights variable is specified, the code will automatically use cosine
latitude weighting.

If no variable is specified, the code will calculate statistics on the
variables that have a quantity_type attribute.

E.g. -

calc_area_statistics /path/to/input.nc /path/to/out.nc

calc_area_statistics /path/to/input.nc  /path/to/out.nc --weights weights_var \
  --variable my_var

calc_area_statistics /path/to/input.nc /path/to/out.nc --no-standard-deviation

"""

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import argparse
import sys
import tempfile
import os
import shutil

from netCDF4 import Dataset
import numpy as np
import numpy.ma as ma


from agiovanni.area_stats import compute_statistics


def main(argv):

    args = _parse_arguments(argv)

    # We get odd behavior if the input and output files are the same because
    # the code needs them to both be open at the same time. So, if input and
    # output files represent the same path, store the output in a temporary
    # until the input file can be closed.
    needs_temp_file = os.path.isfile(
        args.out) and os.path.samefile(
        args.data,
        args.out)

    out_file = args.out
    if needs_temp_file:
        (handle_, out_file) = tempfile.mkstemp(suffix="nc", prefix="averaged")
        os.close(handle_)

    # open the input file
    with Dataset(args.data, 'r') as in_nc:

        if len(args.variable) == 0:
            # if we didn't get any variables at the input, find everything in
            # the file with a quantity_type.
            variables = [
                var for var in in_nc.variables if 'quantity_type' in in_nc[var].ncattrs()]
        else:
            variables = args.variable

        # calculate the statistics for each variable
        stats = {}
        for var in variables:
            data_var = in_nc[var]
            lat_dim = data_var.dimensions.index('lat')
            lon_dim = data_var.dimensions.index('lon')
            if(args.weights is None):
                # no weights, so pass in latitudes
                lat = in_nc['lat'][:]
                stats[var] = compute_statistics(
                    data_var[:],
                    axis=(lat_dim, lon_dim),
                    lat=lat,
                    lat_dim=lat_dim,
                    avg=not args.no_mean,
                    min_=not args.no_min,
                    max_=not args.no_max,
                    stddev=not args.no_stddev,
                    count=not args.no_count)
            else:
                # get out weights variable
                weights = in_nc[args.weights][:]
                stats[var] = compute_statistics(data_var[:],
                                                axis=(lat_dim, lon_dim),
                                                weights=weights,
                                                avg=not args.no_mean,
                                                min_=not args.no_min,
                                                max_=not args.no_max,
                                                stddev=not args.no_stddev,
                                                count=not args.no_count)

        # create the output file
        _create_output(in_nc, out_file, variables, stats, ('lat', 'lon'))

    if needs_temp_file:
        # move out_file into the correct place
        shutil.move(out_file, args.out)


def _parse_arguments(argv):
    '''
    Parse all the input arguments
    '''

    description = """
    Calculate area statistics
    """
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument(
        "data",
        type=str,
        help="netcdf file")
    parser.add_argument("out",
                        type=str,
                        help="output file")

    parser.add_argument(
        "--variable",
        dest="variable",
        type=str,
        help="variable to calculate statistics on",
        action="append",
        default=[])

    parser.add_argument(
        "--no-standard-deviation",
        dest="no_stddev",
        action='store_true',
        help="don't calculate the standard deviation")

    parser.add_argument(
        "--no-mean",
        dest="no_mean",
        action='store_true',
        help="don't calculate the mean")

    parser.add_argument(
        "--no-min",
        dest="no_min",
        action='store_true',
        help="don't calculate the minimum value")

    parser.add_argument(
        "--no-max",
        dest="no_max",
        action='store_true',
        help="don't calculate the maximum value")

    parser.add_argument(
        "--no-count",
        dest="no_count",
        action='store_true',
        help="don't calculate the count")

    parser.add_argument(
        "--weights",
        type=str,
        help="weights variable. If not specified, will use longitude weighting.",
        default=None)

    args = parser.parse_args(argv)

    return args


def _create_output(
        in_nc, out_file, variable_names, all_stats, dimensions_removed):
    '''
    Create the output file from the statistics.
    '''
    out_nc = Dataset(out_file, 'w', format="NETCDF3_CLASSIC")

    _setup_new_nc(in_nc, out_nc, dimensions_removed, variable_names)

    for variable_name in variable_names:
        stats = all_stats[variable_name]
        # If the variable is a float, we'll report statistics as floats. Otherwise,
        # we use doubles.
        if(in_nc[variable_name] == np.dtype("float32")):
            stats_data_type = np.dtype("float32")
        else:
            stats_data_type = np.dtype("double")

        # get the fill value for the variable
        fill = None
        if "_FillValue" in in_nc[variable_name].ncattrs():
            fill = in_nc[variable_name].getncattr("_FillValue")

        # figure out the dimensions for this variable in the correct order
        dimensions = [
            d for d in in_nc[variable_name].dimensions if d not in dimensions_removed]

        # figure out the coordinates
        if 'coordinates' in in_nc[variable_name].ncattrs():
            coordinates = in_nc[variable_name].coordinates.split()
            coordinates = [
                c for c in coordinates if c not in dimensions_removed]
            coordinates = " ".join(coordinates)
        else:
            coordinates = " ".join(dimensions)

        # Create the statistics variables
        possible_stats = {
            'avg': {
                'name': variable_name,
                'cell_methods': 'lat,lon: mean',
                'quantity_type': in_nc[variable_name].quantity_type},
            'min': {
                'name': 'min_%s' % variable_name,
                'cell_methods': 'lat,lon: minimum',
                'quantity_type': 'minimum of %s' % in_nc[variable_name].quantity_type},
            'max': {
                'name': 'max_%s' % variable_name,
                'cell_methods': 'lat,lon: maximum',
                'quantity_type': 'maximum of %s' % in_nc[variable_name].quantity_type},
            'stddev': {
                'name': 'stddev_%s' % variable_name,
                'cell_methods': 'lat,lon: standard deviation',
                'quantity_type': 'standard deviation of %s' % in_nc[variable_name].quantity_type},
        }

        for stat_name in stats:
            if stat_name == 'count':
                # the count variable is kind of different from the other
                # statistics
                new_var = out_nc.createVariable(
                    "count_%s" % variable_name,
                    'i',
                    dimensions=dimensions, fill_value=-999)
                # copy over the attributes
                _copy_attributes_and_set_values(
                    in_nc[variable_name],
                    new_var,
                    stats['count'])
                # set attributes to what we did
                new_var.coordinates = coordinates
                # set the quantity_type to something different for plot options
                new_var.quantity_type = "count of %s" % new_var.quantity_type
                # there is no 'cell_methods' for this count. Best we can do is
                # update the long name
                if 'cell_methods' in new_var.ncattrs():
                    new_var.delncattr('cell_methods')
                if 'long_name' in new_var.ncattrs():
                    new_var.long_name = "count of %s" % new_var.long_name
                else:
                    new_var.long_name = "count of %s" % variable_name
                # change the units to '1', indicating that this is a count
                new_var.units = '1'
            else:
                # create a new variable
                new_var = out_nc.createVariable(possible_stats[stat_name]['name'],
                                                stats_data_type,
                                                dimensions=dimensions,
                                                fill_value=fill)
                # set the value and copy all the attributes over from the
                # original data variable
                _copy_attributes_and_set_values(
                    in_nc[variable_name],
                    new_var,
                    stats[stat_name])

                new_var.coordinates = coordinates
                new_var.cell_methods = possible_stats[
                    stat_name]['cell_methods']
                new_var.quantity_type = possible_stats[
                    stat_name]['quantity_type']

    # copy over global attributes
    _copy_global_attributes(in_nc, out_nc)

    out_nc.close()


def _setup_new_nc(in_nc, out_nc, dim_names_removed, averaged_var_names):
    '''
    Basically copies over everything that needs to be copied other than the
    averaged variables.
    '''

    # Create a dictionary about the input variables, but take into account
    # that we want to get rid of the dimensions we averaged over
    var_dict = {}
    for v in in_nc.variables:
        var_dict[v] = {'attributes': {}}
        for attr in in_nc[v].ncattrs():
            if attr == 'coordinates' and v in averaged_var_names:
                # if the coordinates are the same as the dimensions we
                # averaged over, remove them
                coordinates = in_nc[v].getncattr(attr).split()
                coordinates = [
                    c for c in coordinates if c not in dim_names_removed]
                var_dict[v]['attributes'][
                    'coordinates'] = " ".join(coordinates)

            else:
                var_dict[v]['attributes'][attr] = in_nc[v].getncattr(attr)

        var_dict[v]['dimensions'] = set(in_nc[v].dimensions)

        if v in averaged_var_names:
            # If we averaged this variable over these dimensions, then the
            # averaged result doesn't need these dimensions.
            var_dict[v]['dimensions'] -= set(dim_names_removed)

    # Start with the averaged variables.
    out_var_names = set(averaged_var_names)
    # Set the output dimensions to empty set. This will get updated.
    out_dim_names = set()
    # This function will figure out all the dependent variables and dimensions
    _update_vars_and_dims(var_dict, out_var_names, out_dim_names)
    # Remove the averaged variables because those will be added later
    out_var_names -= set(averaged_var_names)

    # create dimensions in the output file
    for d in out_dim_names:
        if(in_nc.dimensions[d].isunlimited()):
            out_nc.createDimension(d, size=None)
        else:
            out_nc.createDimension(d, size=len(in_nc.dimensions[d]))

    # copy over all the supporting variables
    for v in out_var_names:
        in_variable = in_nc[v]
        # create the variable for this dimension
        out_variable = out_nc.createVariable(
            v,
            in_variable.dtype,
            dimensions=in_variable.dimensions)
        # copy over attributes and values from the input file
        _copy_attributes_and_set_values(
            in_variable,
            out_variable,
            in_variable[:])


def _update_vars_and_dims(
        var_dict, var_names, dim_names):
    '''
    Updates var_names and dim_names. Adds coordinate variables, dimensions,
    dimension variables, and bounds variables associated with var_names.

    INPUTS:
        var_dict - a dictionary with the variable information. Each key is
            a variable name. Each variable name should map to another
            dictionary with two keys: dimensions and attributes. The dimension
            key should map to a set of dimension names for this variable. The
            attributes key should map to a dictionary of the string attribute
            names and values. (Note: the code only looks for 'coordinates'
            and 'bounds' attributes.)
        var_names - a set of variable that should definitely be kept. Will be
            added to.
        dim_names - pass in an empty set. Will be added to based on var_names.
    '''
    made_a_change = False
    for v in list(var_names):
        # look for dimensions
        dims = var_dict[v]['dimensions']
        if not dims.issubset(dim_names):
            # add these dimensions to our list
            dim_names |= dims
            made_a_change = True
            for d in dims:
                # check to see if these dimensions have dimension variables
                if d in var_dict:
                    # this dimension has a dimension variable, so add it to
                    # the variables we will copy over
                    var_names.add(d)

        # look for a coordinates attribute
        if 'coordinates' in var_dict[v]['attributes']:
            coordinates = set(var_dict[v]['attributes']['coordinates'].split())
            if not coordinates.issubset(var_names):
                var_names |= coordinates
                made_a_change = True

        # and finally, look for bounds
        if 'bounds' in var_dict[v]['attributes']:
            if not var_dict[v]['attributes']['bounds'] in var_names:
                var_names.add(var_dict[v]['attributes']['bounds'])
                made_a_change = True

    if made_a_change:
        _update_vars_and_dims(var_dict, var_names, dim_names)


def _copy_global_attributes(in_nc, out_nc):
    '''
    Copy over all the global attributes from the input file except the history
    stuff.
    '''
    for att in in_nc.ncattrs():
        if att != 'history' and att != 'history_of_appended_files':
            out_nc.setncattr(att, in_nc.getncattr(att))


def _copy_attributes_and_set_values(in_var, out_var, values):
    '''
    Copy over the attributes from the source variable
    '''
    # copy everything except the fill value over
    for att in in_var.ncattrs():
        if att != '_FillValue':
            out_var.setncattr(att, in_var.getncattr(att))

    # get the data out
    data = ma.getdata(values)

    if '_FillValue' in in_var.ncattrs():
        # get the mask out
        mask = ma.getmaskarray(values)
        data[mask] = out_var._FillValue

    out_var[:] = data

if __name__ == "__main__":
    main(sys.argv[1:])
