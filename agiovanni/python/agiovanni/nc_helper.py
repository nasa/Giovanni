"""
This package contains helper functions for netcdf files
"""
__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import shutil
import os
import numpy as np
import numpy.ma as ma
from netCDF4 import Dataset


def remove_nans(in_file, out_file, variable):
    """
    Remove the NaN values in a variable
    :param in_file: input netcdf file path
    :param out_file: output netcdf file path
    :param variable: variable to change
    """
    # copy the input file over
    if not (os.path.exists(out_file) and os.path.samefile(out_file, in_file)):
        shutil.copy(in_file, out_file)

    # open the file
    with Dataset(out_file, 'a') as nc:
        var = nc[variable]
        data = var[:]
        nan_mask = np.isnan(data)
        fill_value = var.getncattr('_FillValue')
        if not np.any(nan_mask):
            # if there are no NaN values, so there is nothing to do
            return

        # figure out what our new mask should look like
        old_mask = ma.getmaskarray(data)
        new_mask = np.logical_or(nan_mask, old_mask)

        # create a new masked variable
        masked_data = ma.array(data=data, mask=new_mask, fill_value=fill_value)
        # set the variable to this value
        var[:] = masked_data
